-- Remove only the deterministic United States priority attractions introduced by 078.

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM attraction_city_links links
USING seed_attractions seed
WHERE links.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM attraction_media media
USING seed_attractions seed
WHERE media.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'US'
      AND tags @> ARRAY['united-states-seed-v1']::text[]
)
DELETE FROM attraction_translations translations
USING seed_attractions seed
WHERE translations.attraction_id = seed.id;

DELETE FROM attractions
WHERE country_code = 'US'
  AND tags @> ARRAY['united-states-seed-v1']::text[];
