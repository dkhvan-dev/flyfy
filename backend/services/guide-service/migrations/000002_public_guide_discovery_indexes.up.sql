CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_guide_profiles_public_rating
    ON guide_profiles(status, rating_avg DESC, reviews_count DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_public_experience
    ON guide_profiles(status, experience_years DESC, rating_avg DESC, reviews_count DESC);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_headline_trgm
    ON guide_profiles USING GIN (headline gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_about_trgm
    ON guide_profiles USING GIN (about gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_guide_languages_lower_code_profile
    ON guide_languages((LOWER(language_code)), guide_profile_id);

CREATE INDEX IF NOT EXISTS idx_guide_specializations_lower_code_profile
    ON guide_specializations((LOWER(specialization_code)), guide_profile_id);
