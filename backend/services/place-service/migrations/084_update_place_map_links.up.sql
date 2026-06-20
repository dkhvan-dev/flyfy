UPDATE places
SET
  location_source_url =
    'https://inflap.app/map?lat=' ||
    trim(to_char(latitude, 'FM999999990.000000')) ||
    '&lon=' ||
    trim(to_char(longitude, 'FM999999990.000000')),
  updated_at = NOW()
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND (
    location_source_url IS NULL
    OR trim(location_source_url) = ''
    OR location_source_url LIKE 'https://www.openstreetmap.org/%'
  );
