DROP INDEX IF EXISTS idx_excursion_offers_product_experience;
DROP INDEX IF EXISTS idx_excursion_offers_product_rating;

ALTER TABLE excursion_offers
    DROP CONSTRAINT IF EXISTS chk_excursion_offers_guide_experience_years,
    DROP CONSTRAINT IF EXISTS chk_excursion_offers_guide_reviews_count,
    DROP CONSTRAINT IF EXISTS chk_excursion_offers_guide_rating_avg;

ALTER TABLE excursion_offers
    DROP COLUMN IF EXISTS guide_experience_years,
    DROP COLUMN IF EXISTS guide_reviews_count,
    DROP COLUMN IF EXISTS guide_rating_avg;
