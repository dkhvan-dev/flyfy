-- Remove only the deterministic Denmark priority places introduced by 080.

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'DK'
      AND tags @> ARRAY['denmark-seed-v1']::text[]
)
DELETE FROM place_city_links links
USING seed_places seed
WHERE links.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'DK'
      AND tags @> ARRAY['denmark-seed-v1']::text[]
)
DELETE FROM place_media media
USING seed_places seed
WHERE media.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'DK'
      AND tags @> ARRAY['denmark-seed-v1']::text[]
)
DELETE FROM place_translations translations
USING seed_places seed
WHERE translations.place_id = seed.id;

DELETE FROM places
WHERE country_code = 'DK'
  AND tags @> ARRAY['denmark-seed-v1']::text[];
