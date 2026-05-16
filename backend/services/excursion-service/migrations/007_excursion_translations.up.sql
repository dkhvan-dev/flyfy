CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE excursions
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS product_translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE excursion_products
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE excursion_offers
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursions_translations_trgm
    ON excursions USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursions_product_translations_trgm
    ON excursions USING GIN (LOWER(COALESCE(product_translations::text, '')) gin_trgm_ops)
    WHERE product_translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursion_products_translations_trgm
    ON excursion_products USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_excursion_offers_translations_trgm
    ON excursion_offers USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;
