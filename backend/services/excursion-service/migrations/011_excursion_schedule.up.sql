CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE excursion_schedule_series (
    id UUID PRIMARY KEY,
    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES excursion_products(id) ON DELETE CASCADE,
    legacy_excursion_id UUID NULL REFERENCES excursions(id) ON DELETE RESTRICT,
    timezone TEXT NOT NULL,
    recurrence_type TEXT NOT NULL,
    weekdays SMALLINT[] NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NULL,
    occurrence_limit INTEGER NULL,
    default_start_time TIME NOT NULL,
    default_capacity INTEGER NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_excursion_schedule_series_recurrence
        CHECK (recurrence_type IN ('NONE', 'WEEKLY')),
    CONSTRAINT chk_excursion_schedule_series_status
        CHECK (status IN ('ACTIVE', 'PAUSED', 'CANCELLED')),
    CONSTRAINT chk_excursion_schedule_series_timezone
        CHECK (BTRIM(timezone) <> ''),
    CONSTRAINT chk_excursion_schedule_series_interval
        CHECK (ends_on IS NULL OR ends_on >= starts_on),
    CONSTRAINT chk_excursion_schedule_series_capacity
        CHECK (default_capacity IS NULL OR default_capacity > 0),
    CONSTRAINT chk_excursion_schedule_series_occurrence_limit
        CHECK (occurrence_limit IS NULL OR occurrence_limit > 0),
    CONSTRAINT chk_excursion_schedule_series_weekdays
        CHECK (
            recurrence_type <> 'WEEKLY'
            OR (
                array_length(weekdays, 1) IS NOT NULL
                AND weekdays <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::SMALLINT[]
            )
        )
);

CREATE TABLE excursion_schedule_slots (
    id UUID PRIMARY KEY,
    series_id UUID NULL REFERENCES excursion_schedule_series(id) ON DELETE SET NULL,
    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES excursion_products(id) ON DELETE CASCADE,
    legacy_excursion_id UUID NULL REFERENCES excursions(id) ON DELETE RESTRICT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    timezone TEXT NOT NULL,
    capacity INTEGER NOT NULL,
    booked_seats INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL,
    cancel_reason TEXT NULL,
    closed_at TIMESTAMPTZ NULL,
    cancelled_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_excursion_schedule_slots_status
        CHECK (status IN ('AVAILABLE', 'BOOKED', 'FULL', 'CLOSED', 'CANCELLED')),
    CONSTRAINT chk_excursion_schedule_slots_timezone
        CHECK (BTRIM(timezone) <> ''),
    CONSTRAINT chk_excursion_schedule_slots_interval
        CHECK (end_at > start_at),
    CONSTRAINT chk_excursion_schedule_slots_capacity
        CHECK (capacity > 0 AND booked_seats >= 0 AND booked_seats <= capacity),
    CONSTRAINT excursion_schedule_slots_no_guide_overlap
        EXCLUDE USING GIST (
            guide_user_id WITH =,
            tstzrange(start_at, end_at, '[)') WITH &&
        )
        WHERE (status IN ('AVAILABLE', 'BOOKED', 'FULL', 'CLOSED'))
);

ALTER TABLE excursion_bookings
    ADD COLUMN schedule_slot_id UUID NULL,
    ADD CONSTRAINT fk_excursion_bookings_schedule_slot
        FOREIGN KEY (schedule_slot_id)
        REFERENCES excursion_schedule_slots(id)
        ON DELETE RESTRICT;

CREATE INDEX idx_excursion_schedule_slots_guide_range
    ON excursion_schedule_slots USING GIST (guide_user_id, tstzrange(start_at, end_at, '[)'));

CREATE INDEX idx_excursion_schedule_slots_offer_start
    ON excursion_schedule_slots(offer_id, start_at);

CREATE INDEX idx_excursion_schedule_slots_series_start
    ON excursion_schedule_slots(series_id, start_at);

CREATE INDEX idx_excursion_schedule_slots_status_start
    ON excursion_schedule_slots(status, start_at);

CREATE INDEX idx_excursion_bookings_schedule_slot
    ON excursion_bookings(schedule_slot_id)
    WHERE schedule_slot_id IS NOT NULL;
