ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_location_mode;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_location_mode
        CHECK (
            (format = 'ONLINE' AND meeting_url IS NOT NULL)
            OR
            (format = 'OFFLINE' AND (country_code IS NOT NULL OR city_name IS NOT NULL OR address_text IS NOT NULL OR map_url IS NOT NULL))
            OR
            (format = 'HYBRID')
        );

DROP INDEX IF EXISTS idx_activities_country_city_id;

ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_city_id_reference;

ALTER TABLE activities
    DROP COLUMN IF EXISTS city_id;
