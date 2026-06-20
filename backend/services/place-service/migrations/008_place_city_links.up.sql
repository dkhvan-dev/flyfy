CREATE TABLE IF NOT EXISTS place_city_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    kind VARCHAR(16) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    city_id VARCHAR(64) NOT NULL,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_place_city_links_kind
        CHECK (kind IN ('ACCESS', 'DEPARTURE')),
    CONSTRAINT uq_place_city_links_kind_city
        UNIQUE (place_id, kind, city_id)
);

CREATE INDEX IF NOT EXISTS idx_place_city_links_lookup
    ON place_city_links(kind, country_code, city_id, place_id);

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE deleted_at IS NULL
  AND TRIM(COALESCE(country_code, '')) <> ''
  AND TRIM(COALESCE(city_id, '')) <> ''
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
