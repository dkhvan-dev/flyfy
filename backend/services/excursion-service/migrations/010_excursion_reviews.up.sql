CREATE TABLE excursion_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    booking_id UUID NOT NULL REFERENCES excursion_bookings(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES excursion_products(id) ON DELETE RESTRICT,
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE RESTRICT,
    legacy_excursion_id UUID NULL REFERENCES excursions(id) ON DELETE SET NULL,
    landmark_id UUID NULL,
    landmark_name TEXT NULL,

    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,
    guide_display_name TEXT NOT NULL DEFAULT '',
    tourist_user_id UUID NOT NULL,

    rating NUMERIC(2,1) NOT NULL,
    comment TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_excursion_reviews_rating
        CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_excursion_reviews_comment
        CHECK (length(trim(comment)) > 0 AND length(comment) <= 2000)
);

CREATE UNIQUE INDEX idx_excursion_reviews_booking
    ON excursion_reviews(booking_id);

CREATE INDEX idx_excursion_reviews_product_created
    ON excursion_reviews(product_id, created_at DESC);

CREATE INDEX idx_excursion_reviews_landmark_created
    ON excursion_reviews(landmark_id, created_at DESC)
    WHERE landmark_id IS NOT NULL;

CREATE INDEX idx_excursion_reviews_guide_created
    ON excursion_reviews(guide_user_id, created_at DESC);
