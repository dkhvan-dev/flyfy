ALTER TABLE excursion_offers
    ADD COLUMN IF NOT EXISTS title VARCHAR(160) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS summary VARCHAR(240) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';

UPDATE excursion_offers o
SET
    title = t.title,
    summary = t.summary,
    description = t.description,
    updated_at = NOW()
FROM excursions t
WHERE o.legacy_excursion_id = t.id
  AND (
      o.title = ''
      OR o.summary = ''
      OR o.description = ''
  );

UPDATE excursion_products
SET
    title = trim(landmark_name),
    summary = 'Compare guide offers for ' || trim(landmark_name) || '.',
    description = 'Choose a guide, language, price, meeting point, and included options before booking.',
    cover_file_id = NULL,
    updated_at = NOW()
WHERE landmark_name IS NOT NULL
  AND trim(landmark_name) <> '';
