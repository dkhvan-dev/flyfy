ALTER TABLE excursion_offers
    DROP COLUMN IF EXISTS description,
    DROP COLUMN IF EXISTS summary,
    DROP COLUMN IF EXISTS title;
