-- =============================================================================
-- SUPABASE MIGRATION: release_date display-granularity mask
-- =============================================================================
-- Run once in Supabase SQL Editor (SQL Editor -> New query -> paste -> Run).
--
-- WHAT THIS DOES
--   Adds records.release_date_mask, a 3-bit SMALLINT recording WHICH
--   components of the release date the user actually volunteered when the
--   record was created or edited. The separate release_date column stays a
--   full canonical DATE (YYYY-MM-DD) so Postgres math, sorting, grouping and
--   statistics keep working unchanged. The mask only drives DISPLAY so the
--   app can faithfully reproduce the typed granularity.
--
-- MASK ENCODING (day*4 + month*2 + year)
--   0 = empty (no date volunteer)
--   1 = year only                -> app displays "YYYY"
--   3 = year + month             -> app displays "MM-YYYY"
--   7 = year + month + day       -> app displays "DD-MM-YYYY"
--
-- The app guarantees only 0/1/3/7 ever occur (a day implies a month, and a
-- month implies a year). Existing rows always hold full dates, so they are
-- backfilled to 7 (full) below.
-- =============================================================================

-- 1. ADD COLUMN (idempotent)
ALTER TABLE records
  ADD COLUMN IF NOT EXISTS release_date_mask SMALLINT NOT NULL DEFAULT 0;

-- 2. BACKFILL: every existing row already stores a full date, so mark it as
--    providing day + month + year (mask 7).
UPDATE records
  SET release_date_mask = 7
  WHERE release_date IS NOT NULL AND release_date_mask = 0;

-- Optional sanity check (should report 0 rows after the backfill):
--   SELECT count(*) FROM records WHERE release_date_mask NOT IN (0,1,3,7);
