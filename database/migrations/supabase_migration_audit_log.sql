-- =============================================================================
-- SUPABASE MIGRATION: Audit Log Triggers (Phase B)
-- =============================================================================
-- Run once in Supabase SQL Editor. This is the "logging ON" stage.
--
-- Adds origin_tab + device columns to audit_log, creates the SECURITY DEFINER
-- trigger function fn_audit_log(), and attaches AFTER triggers to every data
-- table.
--
-- SCOPE OF THIS TRIGGER (updated):
--   * LOGGED here — single-entity edits done in Manage only: artists, genres,
--     descriptors, and the genre/descriptor hierarchy link tables. One row per
--     entity change, with the full before/after state and a friendly name for
--     hierarchy rows.
--   * NOT logged here — records and the record junction tables
--     (record_artists / record_genres / record_descriptors /
--     record_streaming). Those are logged by the APP (RecordAuditLogger) as ONE
--     entry per whole-record commit with the full tuple, which a per-row DB
--     trigger fundamentally cannot produce. The triggers stay attached so a
--     later phase can repurpose them, but the function skips these tables.
--
-- INTENDED SEQUENCING:
--   1. Run THIS file now. It does NOT lock permissions, so you can test freely
--      and inspect/debug logs. (RLS is intentionally NOT enabled here.)
--   2. Run supabase_migration_audit_log_rls.sql LATER, only after the
--      verify_audit_log.dart probe confirms logging is correct. That file
--      hard-locks audit_log (INSERT-only) so logs can never be edited/deleted.
--
-- The trigger is FAIL-SOFT: if logging ever fails it raises a WARNING and lets
-- the underlying data write proceed, so the app is never bricked. The
-- verify_audit_log.dart harness is what catches any missed log.
--
-- IDEMPOTENT: safe to re-run (uses IF NOT EXISTS / DROP IF EXISTS).
-- =============================================================================


-- =============================================================================
-- 1. EXTEND audit_log WITH CONTEXT COLUMNS
-- =============================================================================
-- origin_tab = which flow the action was done in (insert / search / db / manage)
-- device      = which platform (web / mobile). app_boot carries device only.
ALTER TABLE audit_log
  ADD COLUMN IF NOT EXISTS origin_tab TEXT,
  ADD COLUMN IF NOT EXISTS device TEXT;


-- =============================================================================
-- 2. CORE TRIGGER FUNCTION fn_audit_log()
-- =============================================================================
-- SECURITY DEFINER: runs as the function owner, so once RLS is turned on in the
-- follow-up migration, the trigger can STILL write logs (owner bypasses RLS)
-- while direct client UPDATE/DELETE on audit_log is blocked.
--
-- Reads the client-supplied context headers (x-origin-tab, x-device) from
-- PostgREST's current_setting('request.headers') and stores them on the row.
-- Captures the full before/after row state in the JSONB details column.
CREATE OR REPLACE FUNCTION fn_audit_log()
RETURNS TRIGGER AS $$
DECLARE
  request_headers JSONB;
  origin_tab      TEXT;
  device          TEXT;
  subject_id      INT;
  log_details     JSONB;
  name_key        TEXT;
  friend_name     TEXT;
BEGIN
  -- --- Parse client context headers (fail-safe: never throw to caller) -------
  request_headers := '{}'::jsonb;
  origin_tab := NULL;
  device := NULL;
  BEGIN
    request_headers := COALESCE(
      NULLIF(current_setting('request.headers', true), '')::jsonb,
      '{}'::jsonb
    );
    origin_tab := NULLIF(request_headers->>'x-origin-tab', '');
    device     := NULLIF(request_headers->>'x-device', '');
  EXCEPTION WHEN OTHERS THEN
    request_headers := '{}'::jsonb;
    origin_tab := NULL;
    device := NULL;
  END;

  -- --- SKIP record + junction tables (client-owned logging) ---------------
  -- Record operations (insert/update/delete of a whole record AND its
  -- artist/genre/descriptor/streaming links) are logged by the APP as a single
  -- full-tuple entry per commit (see RecordAuditLogger). The per-row DB trigger
  -- would otherwise flood the log with one link row per relation and never
  -- capture the whole tuple. So we skip records and every junction table
  -- entirely here. The triggers stay attached (Stage 2 repurposes them as a
  -- detector) but this function is what decides to log nothing for them.
  IF TG_TABLE_NAME IN (
      'records',
      'record_artists',
      'record_genres',
      'record_descriptors',
      'record_streaming'
  ) THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;

  -- --- Resolve the subject id (which entity the change happened to) and a
  -- --- human-readable name for junction/hierarchy rows (so the Log viewer
  -- --- can show *names*, not ids which are never surfaced). ----------------
  name_key := NULL;
  friend_name := NULL;
  CASE TG_TABLE_NAME
    WHEN 'records'              THEN subject_id := COALESCE(NEW.record_id, OLD.record_id);
    WHEN 'artists'              THEN subject_id := COALESCE(NEW.artist_id, OLD.artist_id);
    WHEN 'genres'               THEN subject_id := COALESCE(NEW.genre_id, OLD.genre_id);
    WHEN 'descriptors'          THEN subject_id := COALESCE(NEW.descriptor_id, OLD.descriptor_id);
    WHEN 'record_artists'       THEN
      subject_id := COALESCE(NEW.record_id, OLD.record_id);
      name_key := 'artist_name';
      friend_name := (SELECT artist_name FROM artists WHERE artist_id = COALESCE(NEW.artist_id, OLD.artist_id));
    WHEN 'record_genres'        THEN
      subject_id := COALESCE(NEW.record_id, OLD.record_id);
      name_key := 'genre_name';
      friend_name := (SELECT genre_name FROM genres WHERE genre_id = COALESCE(NEW.genre_id, OLD.genre_id));
    WHEN 'record_descriptors'   THEN
      subject_id := COALESCE(NEW.record_id, OLD.record_id);
      name_key := 'descriptor_name';
      friend_name := (SELECT descriptor_name FROM descriptors WHERE descriptor_id = COALESCE(NEW.descriptor_id, OLD.descriptor_id));
    WHEN 'record_streaming'     THEN
      subject_id := COALESCE(NEW.record_id, OLD.record_id);
      name_key := 'service_name';
      friend_name := COALESCE(NEW.service_name, OLD.service_name);
    WHEN 'genre_hierarchy'      THEN
      subject_id := COALESCE(NEW.child_genre_id, OLD.child_genre_id);
      name_key := 'genre_name';
      friend_name := (SELECT genre_name FROM genres WHERE genre_id = COALESCE(NEW.child_genre_id, OLD.child_genre_id));
    WHEN 'descriptor_hierarchy' THEN
      subject_id := COALESCE(NEW.child_descriptor_id, OLD.child_descriptor_id);
      name_key := 'descriptor_name';
      friend_name := (SELECT descriptor_name FROM descriptors WHERE descriptor_id = COALESCE(NEW.child_descriptor_id, OLD.child_descriptor_id));
    ELSE subject_id := NULL;
  END CASE;

  -- --- Build the before/after/inserted/deleted details -----------------------
  IF TG_OP = 'INSERT' THEN
    log_details := jsonb_build_object('inserted', to_jsonb(NEW));
  ELSIF TG_OP = 'UPDATE' THEN
    -- Skip logging when the ONLY changed columns are the derived counters
    -- (ref_count / total_ref_count / children_count) that the maintenance
    -- triggers recompute on link insert/delete. Those rows are pure noise in
    -- the audit trail; a REAL edit to any other column still logs normally.
    -- The `- 'key'` JSONB removal is a no-op for tables lacking the column,
    -- so this is safe for every table the trigger is attached to.
    IF (to_jsonb(OLD) - 'ref_count' - 'total_ref_count' - 'children_count') =
       (to_jsonb(NEW) - 'ref_count' - 'total_ref_count' - 'children_count') THEN
      RETURN NEW;
    END IF;
    log_details := jsonb_build_object('before', to_jsonb(OLD), 'after', to_jsonb(NEW));
  ELSE -- DELETE
    log_details := jsonb_build_object('deleted', to_jsonb(OLD));
  END IF;

  -- Attach the friendly name to junction/hierarchy rows so the viewer has
  -- something readable (ids are hidden by the app and would otherwise leave
  -- those rows blank / non-attributable).
  IF name_key IS NOT NULL AND friend_name IS NOT NULL AND friend_name <> '' THEN
    IF TG_OP = 'INSERT' THEN
      log_details := jsonb_build_object('inserted', to_jsonb(NEW) || jsonb_build_object(name_key, friend_name));
    ELSIF TG_OP = 'UPDATE' THEN
      log_details := jsonb_build_object(
        'before', to_jsonb(OLD) || jsonb_build_object(name_key, friend_name),
        'after',  to_jsonb(NEW) || jsonb_build_object(name_key, friend_name)
      );
    ELSE -- DELETE
      log_details := jsonb_build_object('deleted', to_jsonb(OLD) || jsonb_build_object(name_key, friend_name));
    END IF;
  END IF;

  -- --- Write the audit row ----------------------------------------------------
  INSERT INTO audit_log (action, table_name, record_id, origin_tab, device, details)
  VALUES (lower(TG_OP), TG_TABLE_NAME, subject_id, origin_tab, device, log_details);

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;

EXCEPTION WHEN OTHERS THEN
  -- Fail-soft: never let a logging problem break the actual data write.
  RAISE WARNING 'audit_log trigger failed on %.% (%): %',
    TG_TABLE_NAME, TG_OP, SQLSTATE, SQLERRM;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- 3. VERIFICATION HELPER (read-only)
-- =============================================================================
-- Returns, for every expected data table, whether the fn_audit_log trigger is
-- attached and how many audit rows currently exist for that table. Called by
-- tools/verify_audit_log.dart via PostgREST rpc(). SECURITY DEFINER lets the
-- anonymous role read the catalogs; it performs no writes.
CREATE OR REPLACE FUNCTION fn_verify_audit_triggers()
RETURNS TABLE(table_name TEXT, has_trigger BOOLEAN, rows_in_audit BIGINT) AS $$
DECLARE
  t   TEXT;
  expected TEXT[] := ARRAY[
    'records','artists','genres','descriptors',
    'record_artists','record_genres','record_descriptors',
    'record_streaming','genre_hierarchy','descriptor_hierarchy'
  ];
BEGIN
  FOREACH t IN ARRAY expected LOOP
    table_name := t;

    SELECT EXISTS (
      SELECT 1
      FROM pg_trigger trg
      JOIN pg_class c   ON c.oid = trg.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_proc p    ON p.oid = trg.tgfoid
      WHERE n.nspname = 'public'
        AND c.relname = t
        AND p.proname = 'fn_audit_log'
        AND trg.tgname LIKE 'trg_audit_%'
    ) INTO has_trigger;

    SELECT COUNT(*) INTO rows_in_audit
    FROM public.audit_log a WHERE a.table_name = t;

    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================================
-- 4. ATTACH TRIGGERS TO EVERY DATA TABLE
-- =============================================================================
-- Main entity tables can be updated (rename, status, record fields), so they
-- get INSERT OR UPDATE OR DELETE. Junction tables are written as insert/delete
-- in the app, but attaching all three ops is harmless and guarantees nothing is
-- ever missed regardless of how the write happens.

DROP TRIGGER IF EXISTS trg_audit_records ON records;
CREATE TRIGGER trg_audit_records
  AFTER INSERT OR UPDATE OR DELETE ON records
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_artists ON artists;
CREATE TRIGGER trg_audit_artists
  AFTER INSERT OR UPDATE OR DELETE ON artists
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_genres ON genres;
CREATE TRIGGER trg_audit_genres
  AFTER INSERT OR UPDATE OR DELETE ON genres
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_descriptors ON descriptors;
CREATE TRIGGER trg_audit_descriptors
  AFTER INSERT OR UPDATE OR DELETE ON descriptors
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_record_artists ON record_artists;
CREATE TRIGGER trg_audit_record_artists
  AFTER INSERT OR UPDATE OR DELETE ON record_artists
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_record_genres ON record_genres;
CREATE TRIGGER trg_audit_record_genres
  AFTER INSERT OR UPDATE OR DELETE ON record_genres
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_record_descriptors ON record_descriptors;
CREATE TRIGGER trg_audit_record_descriptors
  AFTER INSERT OR UPDATE OR DELETE ON record_descriptors
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_record_streaming ON record_streaming;
CREATE TRIGGER trg_audit_record_streaming
  AFTER INSERT OR UPDATE OR DELETE ON record_streaming
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_genre_hierarchy ON genre_hierarchy;
CREATE TRIGGER trg_audit_genre_hierarchy
  AFTER INSERT OR UPDATE OR DELETE ON genre_hierarchy
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

DROP TRIGGER IF EXISTS trg_audit_descriptor_hierarchy ON descriptor_hierarchy;
CREATE TRIGGER trg_audit_descriptor_hierarchy
  AFTER INSERT OR UPDATE OR DELETE ON descriptor_hierarchy
  FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
