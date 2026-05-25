-- Remove only the deterministic Hainan seed imported by 030.

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM attraction_media
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM attraction_city_links
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM attraction_translations
WHERE attraction_id IN (SELECT id FROM seed_ids);

DELETE FROM attractions
WHERE country_code = 'CN'
  AND tags @> ARRAY['china-hainan-seed-v1']::text[];

UPDATE attractions
SET
    tags = array_remove(tags, 'hainan'),
    updated_at = NOW()
WHERE country_code = 'CN'
  AND city_id = 'sanya'
  AND tags @> ARRAY['china-seed-v1']::text[]
  AND tags @> ARRAY['hainan']::text[];
