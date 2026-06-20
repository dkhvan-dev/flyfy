DROP INDEX IF EXISTS idx_places_location;

ALTER TABLE places
    DROP CONSTRAINT IF EXISTS chk_places_location_source_url,
    DROP CONSTRAINT IF EXISTS chk_places_longitude,
    DROP CONSTRAINT IF EXISTS chk_places_latitude,
    DROP CONSTRAINT IF EXISTS chk_places_location_pair,
    DROP COLUMN IF EXISTS location_source_url,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude;
