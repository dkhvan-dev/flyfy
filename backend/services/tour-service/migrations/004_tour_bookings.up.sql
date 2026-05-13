CREATE TABLE tour_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id UUID NOT NULL REFERENCES tour_products(id) ON DELETE RESTRICT,
    offer_id UUID NOT NULL REFERENCES tour_offers(id) ON DELETE RESTRICT,
    legacy_tour_id UUID NULL REFERENCES tours(id) ON DELETE SET NULL,

    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,
    tourist_user_id UUID NOT NULL,

    scheduled_for TIMESTAMPTZ NOT NULL,
    adults INT NOT NULL,
    children INT NOT NULL DEFAULT 0,
    total_seats INT NOT NULL,

    unit_price_amount NUMERIC(12,2) NOT NULL,
    service_fee_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_price_amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    idempotency_key VARCHAR(120) NULL,
    cancelled_at TIMESTAMPTZ NULL,
    cancel_reason TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_tour_bookings_guests
        CHECK (adults >= 1 AND children >= 0 AND total_seats = adults + children),
    CONSTRAINT chk_tour_bookings_price
        CHECK (unit_price_amount >= 0 AND service_fee_amount >= 0 AND total_price_amount >= 0),
    CONSTRAINT chk_tour_bookings_status
        CHECK (status IN ('REQUESTED', 'CANCELLED'))
);

CREATE INDEX idx_tour_bookings_tourist_created
    ON tour_bookings(tourist_user_id, created_at DESC);

CREATE INDEX idx_tour_bookings_guide_scheduled
    ON tour_bookings(guide_user_id, scheduled_for DESC);

CREATE INDEX idx_tour_bookings_offer_scheduled
    ON tour_bookings(offer_id, scheduled_for DESC);

CREATE UNIQUE INDEX idx_tour_bookings_tourist_idempotency
    ON tour_bookings(tourist_user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
