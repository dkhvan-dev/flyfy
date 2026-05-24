DROP INDEX IF EXISTS idx_excursions_guide_search_text_trgm;
DROP INDEX IF EXISTS idx_excursions_guide_nickname_trgm;
DROP INDEX IF EXISTS idx_excursions_guide_display_name_trgm;

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS chk_excursions_guide_snapshot,
    DROP COLUMN IF EXISTS guide_search_text,
    DROP COLUMN IF EXISTS guide_last_name,
    DROP COLUMN IF EXISTS guide_first_name,
    DROP COLUMN IF EXISTS guide_nickname,
    DROP COLUMN IF EXISTS guide_display_name,
    DROP COLUMN IF EXISTS guide_experience_years,
    DROP COLUMN IF EXISTS guide_reviews_count,
    DROP COLUMN IF EXISTS guide_rating_avg;
