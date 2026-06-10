ALTER TABLE stories
    ADD COLUMN IF NOT EXISTS format TEXT NOT NULL DEFAULT 'STORY',
    ADD COLUMN IF NOT EXISTS content_schema_version INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS content_blocks JSONB NULL,
    ADD COLUMN IF NOT EXISTS content_plain_text TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS last_autosaved_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'NOT_REQUIRED';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_stories_format'
            AND conrelid = 'stories'::regclass
    ) THEN
        ALTER TABLE stories
            ADD CONSTRAINT chk_stories_format
            CHECK (format IN ('STORY', 'GUIDE', 'PHOTO_ESSAY', 'ARTICLE', 'CULINARY'))
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_stories_moderation_status'
            AND conrelid = 'stories'::regclass
    ) THEN
        ALTER TABLE stories
            ADD CONSTRAINT chk_stories_moderation_status
            CHECK (moderation_status IN ('NOT_REQUIRED', 'PENDING', 'APPROVED', 'REJECTED', 'HIDDEN'))
            NOT VALID;
    END IF;
END $$;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stories_owner_workspace
    ON stories(author_user_id, status, updated_at DESC, id DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stories_public_feed_content_engine
    ON stories(format, category, place_country_code, place_city_id, published_at DESC, created_at DESC, id DESC)
    WHERE deleted_at IS NULL
        AND archived_at IS NULL
        AND status = 'PUBLISHED'
        AND moderation_status IN ('NOT_REQUIRED', 'APPROVED');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stories_content_plain_text_search
    ON stories USING GIN(to_tsvector('simple', content_plain_text))
    WHERE deleted_at IS NULL
        AND archived_at IS NULL
        AND status = 'PUBLISHED'
        AND moderation_status IN ('NOT_REQUIRED', 'APPROVED');
