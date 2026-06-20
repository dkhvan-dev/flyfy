-- Remove only the deterministic United States priority places introduced by 078.

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM place_city_links links
USING seed_places seed
WHERE links.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM place_media media
USING seed_places seed
WHERE media.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM place_translations translations
USING seed_places seed
WHERE translations.place_id = seed.id;

DELETE FROM places
WHERE country_code = 'US'
  AND tags @> ARRAY['united-states-seed-v1']::text[];
