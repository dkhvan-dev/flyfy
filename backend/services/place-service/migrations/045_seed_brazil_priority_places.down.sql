-- Remove only the deterministic Brazil seed imported by 045.

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'BR'
      AND tags @> ARRAY['brazil-seed-v1']::text[]
)
DELETE FROM place_media
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'BR'
      AND tags @> ARRAY['brazil-seed-v1']::text[]
)
DELETE FROM place_city_links
WHERE place_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM places
    WHERE country_code = 'BR'
      AND tags @> ARRAY['brazil-seed-v1']::text[]
)
DELETE FROM place_translations
WHERE place_id IN (SELECT id FROM seed_ids);

DELETE FROM places
WHERE country_code = 'BR'
  AND tags @> ARRAY['brazil-seed-v1']::text[];
