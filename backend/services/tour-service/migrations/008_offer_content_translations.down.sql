DROP INDEX CONCURRENTLY IF EXISTS idx_tour_itinerary_items_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_tour_offer_included_items_translations_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_tour_included_items_translations_trgm;

ALTER TABLE tour_itinerary_items
    DROP COLUMN IF EXISTS translations;

ALTER TABLE tour_offer_included_items
    DROP COLUMN IF EXISTS translations;

ALTER TABLE tour_included_items
    DROP COLUMN IF EXISTS translations;
