ALTER TABLE stories
    ADD COLUMN IF NOT EXISTS search_vector TSVECTOR NULL;

CREATE OR REPLACE FUNCTION stories_search_vector_refresh() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(NEW.excerpt, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(NEW.content, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(NEW.place_name, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(array_to_string(NEW.tags, ' '), '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_stories_search_vector_refresh ON stories;

CREATE TRIGGER trg_stories_search_vector_refresh
    BEFORE INSERT OR UPDATE OF title, excerpt, content, place_name, tags
    ON stories
    FOR EACH ROW
    EXECUTE FUNCTION stories_search_vector_refresh();

UPDATE stories
SET search_vector =
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(excerpt, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(content, '')), 'C') ||
    setweight(to_tsvector('simple', coalesce(place_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(array_to_string(tags, ' '), '')), 'C')
WHERE search_vector IS NULL;

DROP INDEX IF EXISTS idx_stories_search_document;

CREATE INDEX IF NOT EXISTS idx_stories_search_vector
    ON stories USING GIN(search_vector);
