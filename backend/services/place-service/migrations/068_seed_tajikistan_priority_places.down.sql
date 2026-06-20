DELETE FROM place_city_links
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM place_media
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM place_translations
WHERE place_id IN (
    SELECT id
    FROM places
    WHERE country_code = 'TJ'
      AND tags @> ARRAY['tajikistan-seed-v1']::text[]
);

DELETE FROM places
WHERE country_code = 'TJ'
  AND tags @> ARRAY['tajikistan-seed-v1']::text[];
