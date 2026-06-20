-- Remove only the deterministic Greece priority places introduced by 075.

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'GR'
      AND tags @> ARRAY['greece-seed-v1']::text[]
)
DELETE FROM place_city_links links
USING seed_places seed
WHERE links.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'GR'
      AND tags @> ARRAY['greece-seed-v1']::text[]
)
DELETE FROM place_media media
USING seed_places seed
WHERE media.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'GR'
      AND tags @> ARRAY['greece-seed-v1']::text[]
)
DELETE FROM place_translations translations
USING seed_places seed
WHERE translations.place_id = seed.id;

DELETE FROM places
WHERE country_code = 'GR'
  AND tags @> ARRAY['greece-seed-v1']::text[];
