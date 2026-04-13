CREATE UNIQUE INDEX IF NOT EXISTS uq_user_profiles_display_name_ci
    ON user_profiles (LOWER(BTRIM(display_name)))
    WHERE display_name IS NOT NULL AND BTRIM(display_name) <> '';
