DELETE FROM attraction_media
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'GE'
        AND tags @> ARRAY['georgia-seed-v1']::text[]
);

DELETE FROM attraction_city_links
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'GE'
        AND tags @> ARRAY['georgia-seed-v1']::text[]
);

DELETE FROM attraction_translations
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'GE'
        AND tags @> ARRAY['georgia-seed-v1']::text[]
);

DELETE FROM attractions
WHERE country_code = 'GE'
    AND tags @> ARRAY['georgia-seed-v1']::text[];
