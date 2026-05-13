ALTER TABLE tour_included_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE tour_offer_included_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE tour_itinerary_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tour_included_items_translations_trgm
    ON tour_included_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tour_offer_included_items_translations_trgm
    ON tour_offer_included_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tour_itinerary_items_translations_trgm
    ON tour_itinerary_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;
