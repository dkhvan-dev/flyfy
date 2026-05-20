DROP INDEX IF EXISTS idx_guide_reviews_tourist_created;
DROP INDEX IF EXISTS idx_guide_reviews_guide_rating_created;
DROP INDEX IF EXISTS idx_guide_reviews_guide_created;
DROP INDEX IF EXISTS idx_guide_reviews_booking;
DROP TABLE IF EXISTS guide_reviews;

DROP INDEX IF EXISTS idx_excursion_reviews_booking;

CREATE UNIQUE INDEX IF NOT EXISTS idx_excursion_reviews_booking
    ON excursion_reviews(booking_id);

ALTER TABLE excursion_reviews
    DROP COLUMN IF EXISTS deleted_at;
