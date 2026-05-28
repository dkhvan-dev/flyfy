ALTER TABLE activities
    ADD COLUMN author_country_code VARCHAR(10) NULL,
    ADD COLUMN author_city_id VARCHAR(64) NULL,
    ADD COLUMN author_city_name VARCHAR(150) NULL,
    ADD COLUMN author_location_captured_at TIMESTAMPTZ NULL;

CREATE INDEX idx_activities_author_country_city
    ON activities(author_country_code, author_city_id);

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_author_city_id_reference
        CHECK (author_city_id IS NULL OR author_city_id ~ '^[a-z0-9][a-z0-9-]{0,63}$'),
    ADD CONSTRAINT chk_activities_author_location_snapshot
        CHECK (
            (
                author_country_code IS NULL
                AND author_city_id IS NULL
                AND author_city_name IS NULL
                AND author_location_captured_at IS NULL
            )
            OR
            (
                author_location_captured_at IS NOT NULL
                AND (
                    author_country_code IS NOT NULL
                    OR author_city_id IS NOT NULL
                    OR author_city_name IS NOT NULL
                )
            )
        );
