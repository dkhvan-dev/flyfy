DROP INDEX IF EXISTS idx_user_profiles_public_country;

ALTER TABLE user_profiles
    DROP COLUMN IF EXISTS is_public;
