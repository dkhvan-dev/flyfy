DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'excursions'
          AND column_name = 'departure_city_id'
          AND udt_name = 'uuid'
    ) THEN
        ALTER TABLE excursions
            ALTER COLUMN departure_city_id TYPE VARCHAR(64)
            USING departure_city_id::text;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'excursion_products'
          AND column_name = 'departure_city_id'
          AND udt_name = 'uuid'
    ) THEN
        ALTER TABLE excursion_products
            ALTER COLUMN departure_city_id TYPE VARCHAR(64)
            USING departure_city_id::text;
    END IF;
END $$;

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS chk_excursions_status;
ALTER TABLE excursions
    ADD CONSTRAINT chk_excursions_status
        CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REJECTED'));

ALTER TABLE excursion_products
    DROP CONSTRAINT IF EXISTS chk_excursion_products_status;
ALTER TABLE excursion_products
    ADD CONSTRAINT chk_excursion_products_status
        CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REJECTED'));

ALTER TABLE excursion_offers
    DROP CONSTRAINT IF EXISTS chk_excursion_offers_status;
ALTER TABLE excursion_offers
    ADD CONSTRAINT chk_excursion_offers_status
        CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'PUBLISHED', 'ARCHIVED', 'REJECTED'));
