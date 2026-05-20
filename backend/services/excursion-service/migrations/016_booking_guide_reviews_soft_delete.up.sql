ALTER TABLE excursion_reviews
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

DROP INDEX IF EXISTS idx_excursion_reviews_booking;

CREATE UNIQUE INDEX IF NOT EXISTS idx_excursion_reviews_booking
    ON excursion_reviews(booking_id)
    WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS guide_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    booking_id UUID NOT NULL REFERENCES excursion_bookings(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES excursion_products(id) ON DELETE RESTRICT,
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE RESTRICT,

    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,
    tourist_user_id UUID NOT NULL,

    rating NUMERIC(2,1) NOT NULL,
    comment TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_guide_reviews_rating
        CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_guide_reviews_comment
        CHECK (length(trim(comment)) > 0 AND length(comment) <= 2000)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_guide_reviews_booking
    ON guide_reviews(booking_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_guide_reviews_guide_created
    ON guide_reviews(guide_user_id, created_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_guide_reviews_guide_rating_created
    ON guide_reviews(guide_user_id, rating DESC, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_guide_reviews_tourist_created
    ON guide_reviews(tourist_user_id, created_at DESC)
    WHERE deleted_at IS NULL;
