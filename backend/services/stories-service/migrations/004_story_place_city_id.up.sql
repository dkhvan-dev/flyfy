ALTER TABLE stories
    ADD COLUMN IF NOT EXISTS place_city_id TEXT NULL;

CREATE INDEX IF NOT EXISTS idx_stories_place_city_published
    ON stories(place_country_code, place_city_id, published_at DESC, created_at DESC)
    WHERE deleted_at IS NULL AND status = 'PUBLISHED';
