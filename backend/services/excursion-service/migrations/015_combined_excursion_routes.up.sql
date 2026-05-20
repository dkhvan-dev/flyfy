ALTER TABLE excursion_products
    ADD COLUMN route_kind TEXT NOT NULL DEFAULT 'SINGLE_ATTRACTION',
    ADD COLUMN route_fingerprint TEXT NULL,
    ADD COLUMN attraction_ids UUID[] NULL,
    ADD COLUMN attraction_names TEXT[] NULL,
    ADD COLUMN stop_count INT NOT NULL DEFAULT 0,
    ADD COLUMN transport_mode TEXT NOT NULL DEFAULT 'WALKING',
    ADD COLUMN route_theme TEXT NULL,
    ADD COLUMN duration_bucket TEXT NULL,
    ADD CONSTRAINT chk_excursion_products_route_kind
        CHECK (route_kind IN ('SINGLE_ATTRACTION', 'COMBINED_ROUTE')),
    ADD CONSTRAINT chk_excursion_products_stop_count
        CHECK (stop_count BETWEEN 0 AND 12),
    ADD CONSTRAINT chk_excursion_products_transport_mode
        CHECK (transport_mode IN ('WALKING', 'CAR', 'TRANSIT', 'MIXED')),
    ADD CONSTRAINT chk_excursion_products_attraction_ids_cardinality
        CHECK (attraction_ids IS NULL OR CARDINALITY(attraction_ids) = stop_count),
    ADD CONSTRAINT chk_excursion_products_attraction_names_cardinality
        CHECK (attraction_names IS NULL OR CARDINALITY(attraction_names) <= stop_count),
    ADD CONSTRAINT chk_excursion_products_single_attraction_shape
        CHECK (route_kind <> 'SINGLE_ATTRACTION' OR attraction_ids IS NULL OR CARDINALITY(attraction_ids) = 1),
    ADD CONSTRAINT chk_excursion_products_combined_route_shape
        CHECK (route_kind <> 'COMBINED_ROUTE' OR attraction_ids IS NULL OR CARDINALITY(attraction_ids) >= 2);

UPDATE excursion_products
SET
    route_kind = CASE
        WHEN landmark_id IS NULL THEN 'COMBINED_ROUTE'
        ELSE 'SINGLE_ATTRACTION'
    END,
    route_fingerprint = canonical_key,
    attraction_ids = CASE
        WHEN landmark_id IS NULL THEN NULL
        ELSE ARRAY[landmark_id]::UUID[]
    END,
    attraction_names = CASE
        WHEN landmark_id IS NULL OR landmark_name IS NULL OR BTRIM(landmark_name) = '' THEN NULL
        ELSE ARRAY[BTRIM(landmark_name)]::TEXT[]
    END,
    stop_count = CASE
        WHEN landmark_id IS NULL THEN 0
        ELSE 1
    END,
    route_theme = category_slug,
    duration_bucket = CASE
        WHEN duration_minutes IS NULL THEN NULL
        WHEN duration_minutes < 120 THEN 'SHORT'
        WHEN duration_minutes < 360 THEN 'HALF_DAY'
        WHEN duration_minutes < 720 THEN 'FULL_DAY'
        ELSE 'MULTI_DAY'
    END
WHERE route_fingerprint IS NULL;

CREATE UNIQUE INDEX uq_excursion_products_route_fingerprint
    ON excursion_products(route_fingerprint)
    WHERE route_fingerprint IS NOT NULL;

CREATE INDEX idx_excursion_products_public_route_kind
    ON excursion_products(route_kind, updated_at DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';

CREATE INDEX idx_excursion_products_attraction_ids
    ON excursion_products USING GIN (attraction_ids)
    WHERE attraction_ids IS NOT NULL;

ALTER TABLE excursion_itinerary_items
    ADD COLUMN attraction_id UUID NULL,
    ADD COLUMN attraction_name VARCHAR(180) NULL,
    ADD COLUMN latitude NUMERIC(10,7) NULL,
    ADD COLUMN longitude NUMERIC(10,7) NULL,
    ADD COLUMN travel_from_previous_minutes INT NULL,
    ADD CONSTRAINT chk_excursion_itinerary_items_travel_from_previous
        CHECK (travel_from_previous_minutes IS NULL OR travel_from_previous_minutes >= 0);

CREATE INDEX idx_excursion_itinerary_items_attraction_id
    ON excursion_itinerary_items(attraction_id)
    WHERE attraction_id IS NOT NULL;
