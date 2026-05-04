DROP INDEX IF EXISTS idx_attractions_location;

ALTER TABLE attractions
    DROP CONSTRAINT IF EXISTS chk_attractions_location_source_url,
    DROP CONSTRAINT IF EXISTS chk_attractions_longitude,
    DROP CONSTRAINT IF EXISTS chk_attractions_latitude,
    DROP CONSTRAINT IF EXISTS chk_attractions_location_pair,
    DROP COLUMN IF EXISTS location_source_url,
    DROP COLUMN IF EXISTS longitude,
    DROP COLUMN IF EXISTS latitude;
