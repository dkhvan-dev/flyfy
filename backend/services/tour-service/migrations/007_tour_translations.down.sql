DROP INDEX CONCURRENTLY IF EXISTS idx_tour_offers_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_tour_products_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_tours_product_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_tours_translations_trgm;

ALTER TABLE tour_offers
    DROP COLUMN IF EXISTS translations;

ALTER TABLE tour_products
    DROP COLUMN IF EXISTS translations;

ALTER TABLE tours
    DROP COLUMN IF EXISTS product_translations,
    DROP COLUMN IF EXISTS translations;
