-- Remove only the deterministic South Korea seed imported by 031.

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'KR'
      AND tags @> ARRAY['south-korea-seed-v1']::text[]
)
DELETE FROM attraction_media
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'KR'
      AND tags @> ARRAY['south-korea-seed-v1']::text[]
)
DELETE FROM attraction_city_links
WHERE attraction_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
    SELECT id
    FROM attractions
    WHERE country_code = 'KR'
      AND tags @> ARRAY['south-korea-seed-v1']::text[]
)
DELETE FROM attraction_translations
WHERE attraction_id IN (SELECT id FROM seed_ids);

DELETE FROM attractions
WHERE country_code = 'KR'
  AND tags @> ARRAY['south-korea-seed-v1']::text[];
