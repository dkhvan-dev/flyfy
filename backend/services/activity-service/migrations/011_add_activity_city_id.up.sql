ALTER TABLE activities
    ADD COLUMN city_id VARCHAR(64) NULL;

CREATE INDEX idx_activities_country_city_id
    ON activities(country_code, city_id);

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_city_id_reference
        CHECK (city_id IS NULL OR city_id ~ '^[a-z0-9][a-z0-9-]{0,63}$');

ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_location_mode;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_location_mode
        CHECK (
            (format = 'ONLINE' AND meeting_url IS NOT NULL)
            OR
            (format = 'OFFLINE' AND (
                country_code IS NOT NULL
                OR city_id IS NOT NULL
                OR city_name IS NOT NULL
                OR address_text IS NOT NULL
                OR map_url IS NOT NULL
            ))
            OR
            (format = 'HYBRID')
        );
