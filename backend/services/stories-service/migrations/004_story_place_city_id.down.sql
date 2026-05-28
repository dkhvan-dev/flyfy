DROP INDEX IF EXISTS idx_stories_place_city_published;

ALTER TABLE stories
    DROP COLUMN IF EXISTS place_city_id;
