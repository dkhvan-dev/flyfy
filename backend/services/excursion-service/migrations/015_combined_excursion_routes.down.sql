DROP INDEX IF EXISTS idx_excursion_itinerary_items_place_id;

ALTER TABLE excursion_itinerary_items
    DROP CONSTRAINT IF EXISTS chk_excursion_itinerary_items_travel_from_previous,
    DROP COLUMN IF EXISTS travel_from_previous_minutes,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude,
    DROP COLUMN IF EXISTS place_name,
    DROP COLUMN IF EXISTS place_id;

DROP INDEX IF EXISTS idx_excursion_products_place_ids;
DROP INDEX IF EXISTS idx_excursion_products_public_route_kind;
DROP INDEX IF EXISTS uq_excursion_products_route_fingerprint;

ALTER TABLE excursion_products
    DROP CONSTRAINT IF EXISTS chk_excursion_products_combined_route_shape,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_single_place_shape,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_place_names_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_place_ids_cardinality,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_transport_mode,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_stop_count,
    DROP CONSTRAINT IF EXISTS chk_excursion_products_route_kind,
    DROP COLUMN IF EXISTS duration_bucket,
    DROP COLUMN IF EXISTS route_theme,
    DROP COLUMN IF EXISTS transport_mode,
    DROP COLUMN IF EXISTS stop_count,
    DROP COLUMN IF EXISTS place_names,
    DROP COLUMN IF EXISTS place_ids,
    DROP COLUMN IF EXISTS route_fingerprint,
    DROP COLUMN IF EXISTS route_kind;
