-- Remove only the deterministic Mongolia priority attractions introduced by 069.

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'MN'
      AND tags @> ARRAY['mongolia-seed-v1']::text[]
)
DELETE FROM attraction_city_links links
USING seed_attractions seed
WHERE links.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'MN'
      AND tags @> ARRAY['mongolia-seed-v1']::text[]
)
DELETE FROM attraction_media media
USING seed_attractions seed
WHERE media.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'MN'
      AND tags @> ARRAY['mongolia-seed-v1']::text[]
)
DELETE FROM attraction_translations translations
USING seed_attractions seed
WHERE translations.attraction_id = seed.id;

DELETE FROM attractions
WHERE country_code = 'MN'
  AND tags @> ARRAY['mongolia-seed-v1']::text[];
