CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_tags_gin
    ON attractions USING GIN (tags)
    WHERE deleted_at IS NULL;
