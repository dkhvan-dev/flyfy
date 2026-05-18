ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_user_profiles_public_country
    ON user_profiles ((UPPER(country_code)), user_id)
    WHERE is_public = TRUE AND country_code IS NOT NULL;
