WITH target_places AS (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['kazakhstan-weak-hub-outdoor-depth-v1']::text[]
)
DELETE FROM place_city_links
WHERE place_id IN (SELECT id FROM target_places);

WITH target_places AS (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['kazakhstan-weak-hub-outdoor-depth-v1']::text[]
)
DELETE FROM place_media
WHERE place_id IN (SELECT id FROM target_places);

WITH target_places AS (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['kazakhstan-weak-hub-outdoor-depth-v1']::text[]
)
DELETE FROM place_translations
WHERE place_id IN (SELECT id FROM target_places);

DELETE FROM places
WHERE tags @> ARRAY['kazakhstan-weak-hub-outdoor-depth-v1']::text[];
