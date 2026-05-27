DELETE FROM attraction_city_links
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM attraction_visit_info
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM attraction_media
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM attraction_translations
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM attraction_locations
WHERE attraction_id IN (
    SELECT id
    FROM attractions
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM attractions
WHERE country_code = 'TJ'
  AND tags @> ARRAY['tajikistan-seed-v1']::text[];
