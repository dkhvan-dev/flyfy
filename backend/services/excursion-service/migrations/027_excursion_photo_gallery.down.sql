ALTER TABLE excursion_offers
    DROP COLUMN IF EXISTS photo_file_ids;

ALTER TABLE excursion_products
    DROP COLUMN IF EXISTS photo_image_urls,
    DROP COLUMN IF EXISTS photo_file_ids;

DROP TABLE IF EXISTS excursion_photos;
