DROP TABLE IF EXISTS seed_indonesia_down_ids;

CREATE TEMP TABLE seed_indonesia_down_ids AS
SELECT id AS attraction_id
FROM attractions
WHERE source = 'IMPORT'
    AND country_code = 'ID'
    AND tags @> ARRAY['indonesia-seed-v1']::text[];

DELETE FROM attraction_media
WHERE attraction_id IN (
    SELECT attraction_id
    FROM seed_indonesia_down_ids
);

DELETE FROM attraction_city_links
WHERE attraction_id IN (
    SELECT attraction_id
    FROM seed_indonesia_down_ids
);

DELETE FROM attraction_translations
WHERE attraction_id IN (
    SELECT attraction_id
    FROM seed_indonesia_down_ids
);

DELETE FROM attractions
WHERE id IN (
    SELECT attraction_id
    FROM seed_indonesia_down_ids
)
AND source = 'IMPORT';

DROP TABLE IF EXISTS seed_indonesia_down_ids;
