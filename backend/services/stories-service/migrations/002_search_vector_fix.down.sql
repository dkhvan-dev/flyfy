DROP INDEX IF EXISTS idx_stories_search_vector;
DROP TRIGGER IF EXISTS trg_stories_search_vector_refresh ON stories;
DROP FUNCTION IF EXISTS stories_search_vector_refresh();
ALTER TABLE stories DROP COLUMN IF EXISTS search_vector;
