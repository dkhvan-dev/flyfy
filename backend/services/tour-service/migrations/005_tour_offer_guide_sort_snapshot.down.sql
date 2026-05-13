DROP INDEX IF EXISTS idx_tour_offers_product_experience;
DROP INDEX IF EXISTS idx_tour_offers_product_rating;

ALTER TABLE tour_offers
    DROP CONSTRAINT IF EXISTS chk_tour_offers_guide_experience_years,
    DROP CONSTRAINT IF EXISTS chk_tour_offers_guide_reviews_count,
    DROP CONSTRAINT IF EXISTS chk_tour_offers_guide_rating_avg;

ALTER TABLE tour_offers
    DROP COLUMN IF EXISTS guide_experience_years,
    DROP COLUMN IF EXISTS guide_reviews_count,
    DROP COLUMN IF EXISTS guide_rating_avg;
