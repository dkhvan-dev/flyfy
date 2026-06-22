DROP INDEX IF EXISTS idx_user_routes_moderation_updated;

DROP INDEX IF EXISTS idx_user_routes_public_city_updated;

CREATE INDEX IF NOT EXISTS idx_user_routes_public_city_updated
    ON user_routes (city_code, updated_at DESC, id)
    WHERE visibility = 'public';

ALTER TABLE user_routes
    DROP CONSTRAINT IF EXISTS user_routes_moderation_status_check;

ALTER TABLE user_routes
    DROP COLUMN IF EXISTS moderated_at,
    DROP COLUMN IF EXISTS moderated_by_user_id,
    DROP COLUMN IF EXISTS moderation_reason,
    DROP COLUMN IF EXISTS moderation_status;
