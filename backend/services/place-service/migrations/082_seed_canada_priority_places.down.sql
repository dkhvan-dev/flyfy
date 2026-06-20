-- Remove only the deterministic Canada priority places introduced by 082.

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'CA'
      AND tags @> ARRAY['canada-seed-v1']::text[]
)
DELETE FROM place_city_links links
USING seed_places seed
WHERE links.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'CA'
      AND tags @> ARRAY['canada-seed-v1']::text[]
)
DELETE FROM place_media media
USING seed_places seed
WHERE media.place_id = seed.id;

WITH seed_places AS (
    SELECT id
    FROM places
    WHERE country_code = 'CA'
      AND tags @> ARRAY['canada-seed-v1']::text[]
)
DELETE FROM place_translations translations
USING seed_places seed
WHERE translations.place_id = seed.id;

DELETE FROM places
WHERE country_code = 'CA'
  AND tags @> ARRAY['canada-seed-v1']::text[];
