DROP INDEX CONCURRENTLY IF EXISTS idx_excursion_itinerary_items_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_excursion_offer_included_items_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_excursion_included_items_translations_trgm;

ALTER TABLE excursion_itinerary_items
    DROP COLUMN IF EXISTS translations;

ALTER TABLE excursion_offer_included_items
    DROP COLUMN IF EXISTS translations;

ALTER TABLE excursion_included_items
    DROP COLUMN IF EXISTS translations;
