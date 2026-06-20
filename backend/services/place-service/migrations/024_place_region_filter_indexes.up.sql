CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_tags_gin
    ON places USING GIN (tags)
    WHERE deleted_at IS NULL;
