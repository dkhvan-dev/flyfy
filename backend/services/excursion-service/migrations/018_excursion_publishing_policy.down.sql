DROP INDEX IF EXISTS idx_excursion_products_departure_city_public;
DROP INDEX IF EXISTS idx_excursions_pending_review;
DROP INDEX IF EXISTS idx_excursions_departure_city;

UPDATE excursion_offers
SET status = 'DRAFT'
WHERE status IN ('PENDING_REVIEW', 'REJECTED');

UPDATE excursion_products
SET status = 'DRAFT'
WHERE status IN ('PENDING_REVIEW', 'REJECTED');

UPDATE excursions
SET status = 'DRAFT'
WHERE status IN ('PENDING_REVIEW', 'REJECTED');

ALTER TABLE excursion_products
    DROP COLUMN IF EXISTS departure_city_id;

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS chk_excursions_publishing_scores,
    DROP CONSTRAINT IF EXISTS chk_excursions_publishing_decision,
    DROP COLUMN IF EXISTS submitted_for_review_at,
    DROP COLUMN IF EXISTS moderation_reason_codes,
    DROP COLUMN IF EXISTS publish_risk_score,
    DROP COLUMN IF EXISTS guide_trust_score,
    DROP COLUMN IF EXISTS publishing_decision,
    DROP COLUMN IF EXISTS departure_city_id;

ALTER TABLE excursion_offers
    DROP CONSTRAINT IF EXISTS chk_excursion_offers_status;
ALTER TABLE excursion_offers
    ADD CONSTRAINT chk_excursion_offers_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED'));

ALTER TABLE excursion_products
    DROP CONSTRAINT IF EXISTS chk_excursion_products_status;
ALTER TABLE excursion_products
    ADD CONSTRAINT chk_excursion_products_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED'));

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS chk_excursions_status;
ALTER TABLE excursions
    ADD CONSTRAINT chk_excursions_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED'));
