ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE user_profiles
SET is_profile_completed = (
    COALESCE(NULLIF(BTRIM(first_name), ''), '') <> ''
    AND COALESCE(NULLIF(BTRIM(last_name), ''), '') <> ''
);