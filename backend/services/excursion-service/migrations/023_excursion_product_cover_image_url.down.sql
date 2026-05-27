ALTER TABLE excursion_products
    DROP CONSTRAINT IF EXISTS chk_excursion_products_cover_image_url;

ALTER TABLE excursion_products
    DROP COLUMN IF EXISTS cover_image_url;
