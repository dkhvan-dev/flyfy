ALTER TABLE excursion_products
    ADD COLUMN IF NOT EXISTS route_kind TEXT NOT NULL DEFAULT 'SINGLE_PLACE',
    ADD COLUMN IF NOT EXISTS route_fingerprint TEXT NULL,
    ADD COLUMN IF NOT EXISTS place_ids UUID[] NULL,
    ADD COLUMN IF NOT EXISTS place_names TEXT[] NULL,
    ADD COLUMN IF NOT EXISTS stop_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS transport_mode TEXT NOT NULL DEFAULT 'WALKING',
    ADD COLUMN IF NOT EXISTS route_theme TEXT NULL,
    ADD COLUMN IF NOT EXISTS duration_bucket TEXT NULL;

UPDATE excursion_products
SET
    route_kind = CASE
        WHEN landmark_id IS NULL THEN 'COMBINED_ROUTE'
        ELSE COALESCE(NULLIF(route_kind, ''), 'SINGLE_PLACE')
    END,
    route_fingerprint = COALESCE(NULLIF(route_fingerprint, ''), canonical_key),
    place_ids = CASE
        WHEN place_ids IS NULL AND landmark_id IS NOT NULL THEN ARRAY[landmark_id]::UUID[]
        ELSE place_ids
    END,
    place_names = CASE
        WHEN place_names IS NULL
            AND landmark_id IS NOT NULL
            AND landmark_name IS NOT NULL
            AND BTRIM(landmark_name) <> ''
        THEN ARRAY[BTRIM(landmark_name)]::TEXT[]
        ELSE place_names
    END,
    stop_count = CASE
        WHEN landmark_id IS NOT NULL AND stop_count = 0 THEN 1
        ELSE stop_count
    END,
    transport_mode = COALESCE(NULLIF(transport_mode, ''), 'WALKING'),
    route_theme = COALESCE(NULLIF(route_theme, ''), category_slug),
    duration_bucket = COALESCE(
        NULLIF(duration_bucket, ''),
        CASE
            WHEN duration_minutes < 120 THEN 'SHORT'
            WHEN duration_minutes < 360 THEN 'HALF_DAY'
            WHEN duration_minutes < 720 THEN 'FULL_DAY'
            ELSE 'MULTI_DAY'
        END
    );

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_route_kind'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_route_kind
            CHECK (route_kind IN ('SINGLE_PLACE', 'COMBINED_ROUTE'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_stop_count'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_stop_count
            CHECK (stop_count BETWEEN 0 AND 12);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_transport_mode'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_transport_mode
            CHECK (transport_mode IN ('WALKING', 'CAR', 'TRANSIT', 'MIXED'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_place_ids_cardinality'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_place_ids_cardinality
            CHECK (place_ids IS NULL OR CARDINALITY(place_ids) = stop_count);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_place_names_cardinality'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_place_names_cardinality
            CHECK (place_names IS NULL OR CARDINALITY(place_names) <= stop_count);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_single_place_shape'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_single_place_shape
            CHECK (route_kind <> 'SINGLE_PLACE' OR place_ids IS NULL OR CARDINALITY(place_ids) = 1);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_products_combined_route_shape'
    ) THEN
        ALTER TABLE excursion_products
            ADD CONSTRAINT chk_excursion_products_combined_route_shape
            CHECK (route_kind <> 'COMBINED_ROUTE' OR place_ids IS NULL OR CARDINALITY(place_ids) >= 2);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_excursion_products_route_fingerprint
    ON excursion_products(route_fingerprint)
    WHERE route_fingerprint IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_excursion_products_public_route_kind
    ON excursion_products(route_kind, updated_at DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';

CREATE INDEX IF NOT EXISTS idx_excursion_products_place_ids
    ON excursion_products USING GIN (place_ids)
    WHERE place_ids IS NOT NULL;

ALTER TABLE excursion_itinerary_items
    ADD COLUMN IF NOT EXISTS place_id UUID NULL,
    ADD COLUMN IF NOT EXISTS place_name VARCHAR(180) NULL,
    ADD COLUMN IF NOT EXISTS latitude NUMERIC(10,7) NULL,
    ADD COLUMN IF NOT EXISTS longitude NUMERIC(10,7) NULL,
    ADD COLUMN IF NOT EXISTS travel_from_previous_minutes INT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_excursion_itinerary_items_travel_from_previous'
    ) THEN
        ALTER TABLE excursion_itinerary_items
            ADD CONSTRAINT chk_excursion_itinerary_items_travel_from_previous
            CHECK (travel_from_previous_minutes IS NULL OR travel_from_previous_minutes >= 0);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_excursion_itinerary_items_place_id
    ON excursion_itinerary_items(place_id)
    WHERE place_id IS NOT NULL;
