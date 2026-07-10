BEGIN;

ALTER TABLE excursion_products
    ALTER COLUMN route_kind SET DEFAULT 'SINGLE_PLACE',
    DROP CONSTRAINT IF EXISTS chk_excursion_products_route_kind,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_place_ids_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_place_names_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_single_place_shape,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_combined_route_shape,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_attraction_ids_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_attraction_names_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_single_attraction_shape;

-- Early deployments used attraction_* names. Keep the columns for rollback
-- compatibility, but move their data into the current place_* contract.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'excursion_products'::regclass
          AND attname = 'attraction_ids'
          AND NOT attisdropped
    ) THEN
        EXECUTE $sql$
            UPDATE excursion_products
            SET place_ids = attraction_ids
            WHERE (place_ids IS NULL OR CARDINALITY(place_ids) = 0)
              AND attraction_ids IS NOT NULL
              AND CARDINALITY(attraction_ids) > 0
        $sql$;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'excursion_products'::regclass
          AND attname = 'attraction_names'
          AND NOT attisdropped
    ) THEN
        EXECUTE $sql$
            UPDATE excursion_products
            SET place_names = attraction_names
            WHERE (place_names IS NULL OR CARDINALITY(place_names) = 0)
              AND attraction_names IS NOT NULL
              AND CARDINALITY(attraction_names) > 0
        $sql$;
    END IF;
END $$;

UPDATE excursion_products
SET route_kind = 'SINGLE_PLACE'
WHERE route_kind = 'SINGLE_ATTRACTION';

UPDATE excursion_products
SET place_ids = ARRAY[landmark_id]::UUID[]
WHERE route_kind = 'SINGLE_PLACE'
  AND landmark_id IS NOT NULL
  AND (place_ids IS NULL OR CARDINALITY(place_ids) = 0);

UPDATE excursion_products
SET place_names = ARRAY[BTRIM(landmark_name)]::TEXT[]
WHERE route_kind = 'SINGLE_PLACE'
  AND landmark_name IS NOT NULL
  AND BTRIM(landmark_name) <> ''
  AND (place_names IS NULL OR CARDINALITY(place_names) = 0);

UPDATE excursion_products
SET stop_count = CARDINALITY(place_ids)
WHERE place_ids IS NOT NULL
  AND CARDINALITY(place_ids) > 0
  AND stop_count <> CARDINALITY(place_ids);

ALTER TABLE excursion_products
    ADD CONSTRAINT chk_excursion_products_route_kind
        CHECK (route_kind IN ('SINGLE_PLACE', 'COMBINED_ROUTE')) NOT VALID,
    ADD CONSTRAINT chk_excursion_products_place_ids_cardinality
        CHECK (place_ids IS NULL OR CARDINALITY(place_ids) = stop_count) NOT VALID,
    ADD CONSTRAINT chk_excursion_products_place_names_cardinality
        CHECK (place_names IS NULL OR CARDINALITY(place_names) <= stop_count) NOT VALID,
    ADD CONSTRAINT chk_excursion_products_single_place_shape
        CHECK (route_kind <> 'SINGLE_PLACE' OR place_ids IS NULL OR CARDINALITY(place_ids) = 1) NOT VALID,
    ADD CONSTRAINT chk_excursion_products_combined_route_shape
        CHECK (route_kind <> 'COMBINED_ROUTE' OR place_ids IS NULL OR CARDINALITY(place_ids) >= 2) NOT VALID;

ALTER TABLE excursion_products
    VALIDATE CONSTRAINT chk_excursion_products_route_kind,
    VALIDATE CONSTRAINT chk_excursion_products_place_ids_cardinality,
    VALIDATE CONSTRAINT chk_excursion_products_place_names_cardinality,
    VALIDATE CONSTRAINT chk_excursion_products_single_place_shape,
    VALIDATE CONSTRAINT chk_excursion_products_combined_route_shape;

COMMIT;
