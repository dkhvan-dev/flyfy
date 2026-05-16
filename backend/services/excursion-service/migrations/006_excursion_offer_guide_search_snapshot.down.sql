DROP INDEX IF EXISTS idx_excursion_offers_guide_search_text_trgm;
DROP INDEX IF EXISTS idx_excursion_offers_guide_display_name_trgm;

ALTER TABLE excursion_offers
    DROP COLUMN IF EXISTS guide_search_text,
    DROP COLUMN IF EXISTS guide_display_name;
