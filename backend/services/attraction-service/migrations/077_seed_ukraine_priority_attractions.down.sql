-- Remove only the deterministic Ukraine priority attractions introduced by 077.

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'UA'
      AND tags @> ARRAY['ukraine-seed-v1']::text[]
)
DELETE FROM attraction_city_links links
USING seed_attractions seed
WHERE links.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'UA'
      AND tags @> ARRAY['ukraine-seed-v1']::text[]
)
DELETE FROM attraction_media media
USING seed_attractions seed
WHERE media.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'UA'
      AND tags @> ARRAY['ukraine-seed-v1']::text[]
)
DELETE FROM attraction_translations translations
USING seed_attractions seed
WHERE translations.attraction_id = seed.id;

DELETE FROM attractions
WHERE country_code = 'UA'
  AND tags @> ARRAY['ukraine-seed-v1']::text[];
