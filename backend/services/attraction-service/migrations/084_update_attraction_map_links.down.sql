UPDATE attractions
SET
  location_source_url = '',
  updated_at = NOW()
WHERE location_source_url LIKE 'https://inflap.app/map?lat=%';
