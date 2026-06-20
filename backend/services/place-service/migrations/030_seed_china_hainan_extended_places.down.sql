-- Remove only the deterministic Hainan seed imported by 030.

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM place_media
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM place_city_links
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-hainan-seed-v1']::text[]
)
DELETE FROM place_translations
WHERE place_id IN (SELECT id FROM seed_ids);

DELETE FROM places
WHERE country_code = 'CN'
  AND tags @> ARRAY['china-hainan-seed-v1']::text[];

UPDATE places
SET
    tags = array_remove(tags, 'hainan'),
    updated_at = NOW()
WHERE country_code = 'CN'
  AND city_id = 'sanya'
  AND tags @> ARRAY['china-seed-v1']::text[]
  AND tags @> ARRAY['hainan']::text[];
