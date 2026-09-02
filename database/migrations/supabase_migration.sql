-- =============================================================================
-- SUPABASE MIGRATION: Denormalized Counts + Auto-Maintenance Triggers
-- =============================================================================
-- Run once in Supabase SQL Editor.
-- Adds ref_count, children_count, and total_ref_count columns to artists,
-- genres, and descriptors. Populates initial values, then creates triggers
-- to keep them in sync automatically.
-- =============================================================================


-- =============================================================================
-- 1. ADD COLUMNS
-- =============================================================================

ALTER TABLE artists
  ADD COLUMN IF NOT EXISTS ref_count INT NOT NULL DEFAULT 0;

ALTER TABLE genres
  ADD COLUMN IF NOT EXISTS ref_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS children_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_ref_count INT NOT NULL DEFAULT 0;

ALTER TABLE descriptors
  ADD COLUMN IF NOT EXISTS ref_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS children_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_ref_count INT NOT NULL DEFAULT 0;


-- =============================================================================
-- 2. HELPER FUNCTIONS (ancestor traversal)
-- =============================================================================

-- Returns all ancestor IDs of a given genre (walks up the tree)
CREATE OR REPLACE FUNCTION get_genre_ancestors(p_genre_id INT)
RETURNS TABLE(genre_id INT) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE ancestors AS (
    SELECT gh.parent_genre_id AS genre_id
    FROM genre_hierarchy gh
    WHERE gh.child_genre_id = p_genre_id
    UNION
    SELECT gh.parent_genre_id
    FROM genre_hierarchy gh
    JOIN ancestors a ON a.genre_id = gh.child_genre_id
  )
  SELECT DISTINCT a.genre_id FROM ancestors a;
END;
$$ LANGUAGE plpgsql STABLE;

-- Returns all ancestor IDs of a given descriptor (walks up the tree)
CREATE OR REPLACE FUNCTION get_descriptor_ancestors(p_descriptor_id INT)
RETURNS TABLE(descriptor_id INT) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE ancestors AS (
    SELECT dh.parent_descriptor_id AS descriptor_id
    FROM descriptor_hierarchy dh
    WHERE dh.child_descriptor_id = p_descriptor_id
    UNION
    SELECT dh.parent_descriptor_id
    FROM descriptor_hierarchy dh
    JOIN ancestors a ON a.descriptor_id = dh.child_descriptor_id
  )
  SELECT DISTINCT a.descriptor_id FROM ancestors a;
END;
$$ LANGUAGE plpgsql STABLE;


-- =============================================================================
-- 3. POPULATE INITIAL ref_count
-- =============================================================================

-- Artists: count direct record-artists links
WITH counts AS (
  SELECT artist_id, COUNT(*) AS ref_count
  FROM record_artists
  GROUP BY artist_id
)
UPDATE artists a
SET ref_count = COALESCE(c.ref_count, 0)
FROM counts c
WHERE a.artist_id = c.artist_id;

-- Genres: count direct record-genres links
WITH counts AS (
  SELECT genre_id, COUNT(*) AS ref_count
  FROM record_genres
  GROUP BY genre_id
)
UPDATE genres g
SET ref_count = COALESCE(c.ref_count, 0)
FROM counts c
WHERE g.genre_id = c.genre_id;

-- Descriptors: count direct record-descriptors links
WITH counts AS (
  SELECT descriptor_id, COUNT(*) AS ref_count
  FROM record_descriptors
  GROUP BY descriptor_id
)
UPDATE descriptors d
SET ref_count = COALESCE(c.ref_count, 0)
FROM counts c
WHERE d.descriptor_id = c.descriptor_id;


-- =============================================================================
-- 4. POPULATE INITIAL children_count
-- =============================================================================

-- Genres: count all descendants for each genre via recursive CTE
WITH RECURSIVE subtree AS (
  SELECT parent_genre_id AS root, child_genre_id
  FROM genre_hierarchy
  UNION ALL
  SELECT s.root, gh.child_genre_id
  FROM genre_hierarchy gh
  JOIN subtree s ON s.child_genre_id = gh.parent_genre_id
),
counts AS (
  SELECT root AS genre_id, COUNT(DISTINCT child_genre_id) AS children_count
  FROM subtree
  GROUP BY root
)
UPDATE genres g
SET children_count = COALESCE(c.children_count, 0)
FROM counts c
WHERE g.genre_id = c.genre_id;

-- Descriptors: count all descendants for each descriptor via recursive CTE
WITH RECURSIVE subtree AS (
  SELECT parent_descriptor_id AS root, child_descriptor_id
  FROM descriptor_hierarchy
  UNION ALL
  SELECT s.root, dh.child_descriptor_id
  FROM descriptor_hierarchy dh
  JOIN subtree s ON s.child_descriptor_id = dh.parent_descriptor_id
),
counts AS (
  SELECT root AS descriptor_id, COUNT(DISTINCT child_descriptor_id) AS children_count
  FROM subtree
  GROUP BY root
)
UPDATE descriptors d
SET children_count = COALESCE(c.children_count, 0)
FROM counts c
WHERE d.descriptor_id = c.descriptor_id;


-- =============================================================================
-- 5. POPULATE INITIAL total_ref_count
-- =============================================================================

-- Genres: walk UP from each tagged genre to all ancestors, count distinct records
WITH RECURSIVE refs AS (
  SELECT genre_id, record_id FROM record_genres
  UNION
  SELECT gh.parent_genre_id, r.record_id
  FROM refs r
  JOIN genre_hierarchy gh ON r.genre_id = gh.child_genre_id
),
counts AS (
  SELECT genre_id, COUNT(DISTINCT record_id) AS total_ref_count
  FROM refs
  GROUP BY genre_id
)
UPDATE genres g
SET total_ref_count = COALESCE(c.total_ref_count, 0)
FROM counts c
WHERE g.genre_id = c.genre_id;

-- Descriptors: walk UP from each tagged descriptor to all ancestors, count distinct records
WITH RECURSIVE refs AS (
  SELECT descriptor_id, record_id FROM record_descriptors
  UNION
  SELECT dh.parent_descriptor_id, r.record_id
  FROM refs r
  JOIN descriptor_hierarchy dh ON r.descriptor_id = dh.child_descriptor_id
),
counts AS (
  SELECT descriptor_id, COUNT(DISTINCT record_id) AS total_ref_count
  FROM refs
  GROUP BY descriptor_id
)
UPDATE descriptors d
SET total_ref_count = COALESCE(c.total_ref_count, 0)
FROM counts c
WHERE d.descriptor_id = c.descriptor_id;


-- =============================================================================
-- 6. TRIGGER FUNCTIONS
-- =============================================================================

-- Artists: update ref_count when record-artists links change
CREATE OR REPLACE FUNCTION fn_record_artists_ref_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE artists SET ref_count = ref_count + 1 WHERE artist_id = NEW.artist_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE artists SET ref_count = ref_count - 1 WHERE artist_id = OLD.artist_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Genres: update ref_count when record-genres links change (direct only)
CREATE OR REPLACE FUNCTION fn_record_genres_ref_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE genres SET ref_count = ref_count + 1 WHERE genre_id = NEW.genre_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE genres SET ref_count = ref_count - 1 WHERE genre_id = OLD.genre_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Genres: update children_count when hierarchy edges change
CREATE OR REPLACE FUNCTION fn_genre_hierarchy_children()
RETURNS TRIGGER AS $$
DECLARE
  aid INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    FOR aid IN
      SELECT genre_id FROM get_genre_ancestors(NEW.parent_genre_id)
      UNION SELECT NEW.parent_genre_id
    LOOP
      UPDATE genres SET children_count = children_count + 1 WHERE genre_id = aid;
    END LOOP;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    FOR aid IN
      SELECT genre_id FROM get_genre_ancestors(OLD.parent_genre_id)
      UNION SELECT OLD.parent_genre_id
    LOOP
      UPDATE genres SET children_count = children_count - 1 WHERE genre_id = aid;
    END LOOP;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Genres: update total_ref_count when record-genre links change
CREATE OR REPLACE FUNCTION fn_record_genres_refs()
RETURNS TRIGGER AS $$
DECLARE
  gid INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    FOR gid IN
      SELECT genre_id FROM get_genre_ancestors(NEW.genre_id)
      UNION SELECT NEW.genre_id
    LOOP
      UPDATE genres SET total_ref_count = total_ref_count + 1 WHERE genre_id = gid;
    END LOOP;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    FOR gid IN
      SELECT genre_id FROM get_genre_ancestors(OLD.genre_id)
      UNION SELECT OLD.genre_id
    LOOP
      UPDATE genres SET total_ref_count = total_ref_count - 1 WHERE genre_id = gid;
    END LOOP;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Descriptors: update ref_count when record-descriptors links change (direct only)
CREATE OR REPLACE FUNCTION fn_record_descriptors_ref_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE descriptors SET ref_count = ref_count + 1 WHERE descriptor_id = NEW.descriptor_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE descriptors SET ref_count = ref_count - 1 WHERE descriptor_id = OLD.descriptor_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Descriptors: update children_count when hierarchy edges change
CREATE OR REPLACE FUNCTION fn_descriptor_hierarchy_children()
RETURNS TRIGGER AS $$
DECLARE
  aid INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    FOR aid IN
      SELECT descriptor_id FROM get_descriptor_ancestors(NEW.parent_descriptor_id)
      UNION SELECT NEW.parent_descriptor_id
    LOOP
      UPDATE descriptors SET children_count = children_count + 1 WHERE descriptor_id = aid;
    END LOOP;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    FOR aid IN
      SELECT descriptor_id FROM get_descriptor_ancestors(OLD.parent_descriptor_id)
      UNION SELECT OLD.parent_descriptor_id
    LOOP
      UPDATE descriptors SET children_count = children_count - 1 WHERE descriptor_id = aid;
    END LOOP;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Descriptors: update total_ref_count when record-descriptor links change
CREATE OR REPLACE FUNCTION fn_record_descriptors_refs()
RETURNS TRIGGER AS $$
DECLARE
  did INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    FOR did IN
      SELECT descriptor_id FROM get_descriptor_ancestors(NEW.descriptor_id)
      UNION SELECT NEW.descriptor_id
    LOOP
      UPDATE descriptors SET total_ref_count = total_ref_count + 1 WHERE descriptor_id = did;
    END LOOP;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    FOR did IN
      SELECT descriptor_id FROM get_descriptor_ancestors(OLD.descriptor_id)
      UNION SELECT OLD.descriptor_id
    LOOP
      UPDATE descriptors SET total_ref_count = total_ref_count - 1 WHERE descriptor_id = did;
    END LOOP;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- 7. ATTACH TRIGGERS
-- =============================================================================

-- ref_count triggers (direct record links)
DROP TRIGGER IF EXISTS trg_record_artists_ref_count ON record_artists;
CREATE TRIGGER trg_record_artists_ref_count
  AFTER INSERT OR DELETE ON record_artists
  FOR EACH ROW EXECUTE FUNCTION fn_record_artists_ref_count();

DROP TRIGGER IF EXISTS trg_record_genres_ref_count ON record_genres;
CREATE TRIGGER trg_record_genres_ref_count
  AFTER INSERT OR DELETE ON record_genres
  FOR EACH ROW EXECUTE FUNCTION fn_record_genres_ref_count();

DROP TRIGGER IF EXISTS trg_record_descriptors_ref_count ON record_descriptors;
CREATE TRIGGER trg_record_descriptors_ref_count
  AFTER INSERT OR DELETE ON record_descriptors
  FOR EACH ROW EXECUTE FUNCTION fn_record_descriptors_ref_count();

-- children_count triggers (hierarchy edges)
DROP TRIGGER IF EXISTS trg_genre_hierarchy_children ON genre_hierarchy;
CREATE TRIGGER trg_genre_hierarchy_children
  AFTER INSERT OR DELETE ON genre_hierarchy
  FOR EACH ROW EXECUTE FUNCTION fn_genre_hierarchy_children();

DROP TRIGGER IF EXISTS trg_descriptor_hierarchy_children ON descriptor_hierarchy;
CREATE TRIGGER trg_descriptor_hierarchy_children
  AFTER INSERT OR DELETE ON descriptor_hierarchy
  FOR EACH ROW EXECUTE FUNCTION fn_descriptor_hierarchy_children();

-- total_ref_count triggers (record links + hierarchy walk)
DROP TRIGGER IF EXISTS trg_record_genres_refs ON record_genres;
CREATE TRIGGER trg_record_genres_refs
  AFTER INSERT OR DELETE ON record_genres
  FOR EACH ROW EXECUTE FUNCTION fn_record_genres_refs();

DROP TRIGGER IF EXISTS trg_record_descriptors_refs ON record_descriptors;
CREATE TRIGGER trg_record_descriptors_refs
  AFTER INSERT OR DELETE ON record_descriptors
  FOR EACH ROW EXECUTE FUNCTION fn_record_descriptors_refs();
