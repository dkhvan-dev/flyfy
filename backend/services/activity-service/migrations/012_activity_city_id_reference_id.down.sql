ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_city_id_reference;

DROP INDEX IF EXISTS idx_activities_country_city_id;

ALTER TABLE activities
    ALTER COLUMN city_id TYPE UUID
    USING CASE
        WHEN city_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN city_id::uuid
        ELSE NULL
    END;

CREATE INDEX idx_activities_country_city_id
    ON activities(country_code, city_id);
