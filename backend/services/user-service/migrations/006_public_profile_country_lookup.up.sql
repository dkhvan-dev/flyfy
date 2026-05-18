CREATE INDEX IF NOT EXISTS idx_user_profiles_country
    ON user_profiles ((UPPER(country_code)), user_id)
    WHERE country_code IS NOT NULL;
