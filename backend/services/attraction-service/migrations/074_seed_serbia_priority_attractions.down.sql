-- Remove only the deterministic Serbia priority attractions introduced by 074.

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'RS'
      AND tags @> ARRAY['serbia-seed-v1']::text[]
)
DELETE FROM attraction_city_links links
USING seed_attractions seed
WHERE links.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'RS'
      AND tags @> ARRAY['serbia-seed-v1']::text[]
)
DELETE FROM attraction_media media
USING seed_attractions seed
WHERE media.attraction_id = seed.id;

WITH seed_attractions AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'RS'
      AND tags @> ARRAY['serbia-seed-v1']::text[]
)
DELETE FROM attraction_translations translations
USING seed_attractions seed
WHERE translations.attraction_id = seed.id;

DELETE FROM attractions
WHERE country_code = 'RS'
  AND tags @> ARRAY['serbia-seed-v1']::text[];
