ALTER TABLE excursion_products
    ADD COLUMN IF NOT EXISTS cover_image_url TEXT NULL;

ALTER TABLE excursion_products
    DROP CONSTRAINT IF EXISTS chk_excursion_products_cover_image_url;

ALTER TABLE excursion_products
    ADD CONSTRAINT chk_excursion_products_cover_image_url
    CHECK (
        cover_image_url IS NULL
        OR (char_length(cover_image_url) <= 2048 AND cover_image_url ~ '^https://')
    );
