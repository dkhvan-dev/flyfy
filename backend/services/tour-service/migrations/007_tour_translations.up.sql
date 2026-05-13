CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE tours
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS product_translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE tour_products
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE tour_offers
    ADD COLUMN IF NOT EXISTS translations JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tours_translations_trgm
    ON tours USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tours_product_translations_trgm
    ON tours USING GIN (LOWER(COALESCE(product_translations::text, '')) gin_trgm_ops)
    WHERE product_translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tour_products_translations_trgm
    ON tour_products USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tour_offers_translations_trgm
    ON tour_offers USING GIN (LOWER(COALESCE(translations::text, '')) gin_trgm_ops)
    WHERE translations <> '{}'::jsonb;
