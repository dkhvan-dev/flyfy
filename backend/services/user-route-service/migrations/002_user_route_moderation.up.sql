ALTER TABLE user_routes
    ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'approved',
    ADD COLUMN IF NOT EXISTS moderation_reason TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS moderated_by_user_id TEXT,
    ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

ALTER TABLE user_routes
    DROP CONSTRAINT IF EXISTS user_routes_moderation_status_check;

ALTER TABLE user_routes
    ADD CONSTRAINT user_routes_moderation_status_check
        CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'hidden'));

CREATE INDEX IF NOT EXISTS idx_user_routes_moderation_updated
    ON user_routes (moderation_status, updated_at DESC, id);

DROP INDEX IF EXISTS idx_user_routes_public_city_updated;

CREATE INDEX IF NOT EXISTS idx_user_routes_public_city_updated
    ON user_routes (city_code, updated_at DESC, id)
    WHERE visibility = 'public' AND moderation_status = 'approved';
