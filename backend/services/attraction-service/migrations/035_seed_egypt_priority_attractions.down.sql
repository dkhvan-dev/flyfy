-- Remove only the deterministic Egypt seed imported by 035.

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'EG'
      AND tags @> ARRAY['egypt-seed-v1']::text[]
)
DELETE FROM attraction_media
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'EG'
      AND tags @> ARRAY['egypt-seed-v1']::text[]
)
DELETE FROM attraction_city_links
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'EG'
      AND tags @> ARRAY['egypt-seed-v1']::text[]
)
DELETE FROM attraction_translations
WHERE attraction_id IN (SELECT id FROM seed_ids);

DELETE FROM attractions
WHERE country_code = 'EG'
  AND tags @> ARRAY['egypt-seed-v1']::text[];
