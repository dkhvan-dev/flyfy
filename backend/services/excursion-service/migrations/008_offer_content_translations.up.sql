ALTER TABLE excursion_included_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE excursion_offer_included_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE excursion_itinerary_items
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursion_included_items_translations_trgm
    ON excursion_included_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursion_offer_included_items_translations_trgm
    ON excursion_offer_included_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursion_itinerary_items_translations_trgm
    ON excursion_itinerary_items USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;
