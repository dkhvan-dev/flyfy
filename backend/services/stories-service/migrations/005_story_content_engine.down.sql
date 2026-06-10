DROP INDEX CONCURRENTLY IF EXISTS idx_stories_content_plain_text_search;
DROP INDEX CONCURRENTLY IF EXISTS idx_stories_public_feed_content_engine;
DROP INDEX CONCURRENTLY IF EXISTS idx_stories_owner_workspace;

ALTER TABLE stories
    DROP CONSTRAINT IF EXISTS chk_stories_moderation_status,
    DROP CONSTRAINT IF EXISTS chk_stories_format;

ALTER TABLE stories
    DROP COLUMN IF EXISTS moderation_status,
    DROP COLUMN IF EXISTS archived_at,
    DROP COLUMN IF EXISTS last_autosaved_at,
    DROP COLUMN IF EXISTS revision,
    DROP COLUMN IF EXISTS content_plain_text,
    DROP COLUMN IF EXISTS content_blocks,
    DROP COLUMN IF EXISTS content_schema_version,
    DROP COLUMN IF EXISTS format;
