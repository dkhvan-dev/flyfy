ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_author_location_snapshot,
    DROP CONSTRAINT IF EXISTS chk_activities_author_city_id_reference;

DROP INDEX IF EXISTS idx_activities_author_country_city;

ALTER TABLE activities
    DROP COLUMN IF EXISTS author_location_captured_at,
    DROP COLUMN IF EXISTS author_city_name,
    DROP COLUMN IF EXISTS author_city_id,
    DROP COLUMN IF EXISTS author_country_code;
