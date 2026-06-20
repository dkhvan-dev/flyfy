DROP TABLE IF EXISTS seed_indonesia_down_ids;

CREATE TEMP TABLE seed_indonesia_down_ids AS
SELECT id AS place_id
FROM places
WHERE source = 'IMPORT'
    AND country_code = 'ID'
    AND tags @> ARRAY['indonesia-seed-v1']::text[];

DELETE FROM place_media
WHERE place_id IN (
    SELECT place_id
    FROM seed_indonesia_down_ids
);

DELETE FROM place_city_links
WHERE place_id IN (
    SELECT place_id
    FROM seed_indonesia_down_ids
);

DELETE FROM place_translations
WHERE place_id IN (
    SELECT place_id
    FROM seed_indonesia_down_ids
);

DELETE FROM places
WHERE id IN (
    SELECT place_id
    FROM seed_indonesia_down_ids
)
AND source = 'IMPORT';

DROP TABLE IF EXISTS seed_indonesia_down_ids;
