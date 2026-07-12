CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_author_created_rate_limit
    ON posts (author_user_id, created_at DESC)
    WHERE deleted_at IS NULL;

DROP INDEX CONCURRENTLY IF EXISTS idx_posts_author_published_rate_limit;
