ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_city_id_reference;

ALTER TABLE activities
    ALTER COLUMN city_id TYPE VARCHAR(64)
    USING NULLIF(city_id::text, '');

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_city_id_reference
        CHECK (city_id IS NULL OR city_id ~ '^[a-z0-9][a-z0-9-]{0,63}$');
