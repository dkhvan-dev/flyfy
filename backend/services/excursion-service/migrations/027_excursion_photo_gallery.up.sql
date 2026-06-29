CREATE TABLE IF NOT EXISTS excursion_photos (
    id UUID PRIMARY KEY,
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_excursion_photos_excursion_file UNIQUE (excursion_id, file_id)
);

CREATE INDEX IF NOT EXISTS idx_excursion_photos_excursion_sort
    ON excursion_photos(excursion_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_excursion_photos_file_id
    ON excursion_photos(file_id);

INSERT INTO excursion_photos (id, excursion_id, file_id, sort_order, created_at)
SELECT gen_random_uuid(), excursion_id, file_id, 0, created_at
FROM excursion_covers
ON CONFLICT (excursion_id, file_id) DO NOTHING;

ALTER TABLE excursion_products
    ADD COLUMN IF NOT EXISTS photo_file_ids UUID[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS photo_image_urls TEXT[] NOT NULL DEFAULT '{}';

UPDATE excursion_products
SET photo_file_ids = ARRAY[cover_file_id]::UUID[]
WHERE cover_file_id IS NOT NULL
  AND cardinality(photo_file_ids) = 0;

UPDATE excursion_products
SET photo_image_urls = ARRAY[cover_image_url]::TEXT[]
WHERE cover_image_url IS NOT NULL
  AND BTRIM(cover_image_url) <> ''
  AND cardinality(photo_image_urls) = 0;

ALTER TABLE excursion_offers
    ADD COLUMN IF NOT EXISTS photo_file_ids UUID[] NOT NULL DEFAULT '{}';

UPDATE excursion_offers
SET photo_file_ids = ARRAY[cover_file_id]::UUID[]
WHERE cover_file_id IS NOT NULL
  AND cardinality(photo_file_ids) = 0;
