DROP INDEX IF EXISTS idx_tour_offers_guide_search_text_trgm;
DROP INDEX IF EXISTS idx_tour_offers_guide_display_name_trgm;

ALTER TABLE tour_offers
    DROP COLUMN IF EXISTS guide_search_text,
    DROP COLUMN IF EXISTS guide_display_name;
