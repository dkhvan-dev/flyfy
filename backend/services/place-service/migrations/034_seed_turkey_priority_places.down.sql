-- Remove only the deterministic Turkey seed imported by 034.

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'TR'
      AND tags @> ARRAY['turkey-seed-v1']::text[]
)
DELETE FROM place_media
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'TR'
      AND tags @> ARRAY['turkey-seed-v1']::text[]
)
DELETE FROM place_city_links
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'TR'
      AND tags @> ARRAY['turkey-seed-v1']::text[]
)
DELETE FROM place_translations
WHERE place_id IN (SELECT id FROM seed_ids);

DELETE FROM places
WHERE country_code = 'TR'
  AND tags @> ARRAY['turkey-seed-v1']::text[];
