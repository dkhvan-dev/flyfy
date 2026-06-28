-- Remove externally seeded Wiki/Wikimedia placeholder media from places.
-- Places stay published, but start image-less until media is uploaded through MinIO.

DELETE FROM place_media
WHERE file_id = '00000000-0000-0000-0000-000000000000'::uuid
  AND (
      external_url ILIKE '%commons.wikimedia.org%'
      OR external_url ILIKE '%upload.wikimedia.org%'
      OR external_url ILIKE '%wikipedia.org%'
      OR source_url ILIKE '%commons.wikimedia.org%'
      OR source_url ILIKE '%upload.wikimedia.org%'
      OR source_url ILIKE '%wikipedia.org%'
      OR credit ILIKE '%Wikimedia%'
      OR license ILIKE '%Wikimedia%'
  );
