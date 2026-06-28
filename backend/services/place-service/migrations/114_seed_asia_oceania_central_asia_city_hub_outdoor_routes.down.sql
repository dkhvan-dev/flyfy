DELETE FROM place_city_links
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['asia-oceania-central-asia-city-hub-outdoor-routes-v1']::text[]
);

DELETE FROM place_media
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['asia-oceania-central-asia-city-hub-outdoor-routes-v1']::text[]
);

DELETE FROM place_translations
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['asia-oceania-central-asia-city-hub-outdoor-routes-v1']::text[]
);

DELETE FROM places
WHERE tags @> ARRAY['asia-oceania-central-asia-city-hub-outdoor-routes-v1']::text[];
