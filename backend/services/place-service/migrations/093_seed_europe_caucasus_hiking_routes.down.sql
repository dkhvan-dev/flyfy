DELETE FROM place_city_links
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['europe-caucasus-hiking-v1']::text[]
);

DELETE FROM place_media
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['europe-caucasus-hiking-v1']::text[]
);

DELETE FROM place_translations
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE tags @> ARRAY['europe-caucasus-hiking-v1']::text[]
);

DELETE FROM places
WHERE tags @> ARRAY['europe-caucasus-hiking-v1']::text[];
