CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE tour_offers
    ADD COLUMN guide_display_name VARCHAR(180) NOT NULL DEFAULT '',
    ADD COLUMN guide_search_text TEXT NOT NULL DEFAULT '';

UPDATE tour_offers
SET guide_search_text = trim(concat_ws(' ', guide_display_name, guide_user_id::text, guide_profile_id::text))
WHERE guide_search_text = '';

CREATE INDEX idx_tour_offers_guide_display_name_trgm
    ON tour_offers USING GIN (LOWER(guide_display_name) gin_trgm_ops)
    WHERE deleted_at IS NULL AND guide_display_name <> '';

CREATE INDEX idx_tour_offers_guide_search_text_trgm
    ON tour_offers USING GIN (LOWER(guide_search_text) gin_trgm_ops)
    WHERE deleted_at IS NULL AND guide_search_text <> '';
