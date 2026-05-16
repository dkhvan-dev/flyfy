DROP INDEX CONCURRENTLY IF EXISTS idx_excursion_offers_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_excursion_products_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_excursions_product_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_excursions_translations_trgm;

ALTER TABLE excursion_offers
    DROP COLUMN IF EXISTS translations;

ALTER TABLE excursion_products
    DROP COLUMN IF EXISTS translations;

ALTER TABLE excursions
    DROP COLUMN IF EXISTS product_translations,
    DROP COLUMN IF EXISTS translations;
