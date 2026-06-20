-- Remove only the deterministic China seed imported by 029.

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-seed-v1']::text[]
)
DELETE FROM place_media
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-seed-v1']::text[]
)
DELETE FROM place_city_links
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'CN'
      AND tags @> ARRAY['china-seed-v1']::text[]
)
DELETE FROM place_translations
WHERE place_id IN (SELECT id FROM seed_ids);

DELETE FROM places
WHERE country_code = 'CN'
  AND tags @> ARRAY['china-seed-v1']::text[];
