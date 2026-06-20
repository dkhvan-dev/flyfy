-- Remove only the deterministic Estonia priority places introduced by 083.

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'EE'
      AND tags @> ARRAY['estonia-seed-v1']::text[]
)
DELETE FROM place_city_links links
USING seed_places seed
WHERE links.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'EE'
      AND tags @> ARRAY['estonia-seed-v1']::text[]
)
DELETE FROM place_media media
USING seed_places seed
WHERE media.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'EE'
      AND tags @> ARRAY['estonia-seed-v1']::text[]
)
DELETE FROM place_translations translations
USING seed_places seed
WHERE translations.place_id = seed.id;

DELETE FROM places
WHERE country_code = 'EE'
  AND tags @> ARRAY['estonia-seed-v1']::text[];
