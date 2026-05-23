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

ALTER TABLE excursions
    ADD COLUMN IF NOT EXISTS departure_city_id VARCHAR(64) NULL,
    ADD COLUMN IF NOT EXISTS publishing_decision VARCHAR(32) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS guide_trust_score INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS publish_risk_score INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS moderation_reason_codes TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS submitted_for_review_at TIMESTAMPTZ NULL,
    ADD CONSTRAINT chk_excursions_publishing_decision
        CHECK (publishing_decision IN ('', 'AUTO_PUBLISH', 'NEEDS_REVIEW')),
    ADD CONSTRAINT chk_excursions_publishing_scores
        CHECK (
            guide_trust_score BETWEEN 0 AND 100
            AND publish_risk_score BETWEEN 0 AND 100
        );

ALTER TABLE excursion_products
    ADD COLUMN IF NOT EXISTS departure_city_id VARCHAR(64) NULL;

CREATE INDEX IF NOT EXISTS idx_excursions_departure_city
    ON excursions(departure_city_id, status, visibility, updated_at DESC)
    WHERE deleted_at IS NULL AND departure_city_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_excursions_pending_review
    ON excursions(submitted_for_review_at ASC, updated_at ASC)
    WHERE status = 'PENDING_REVIEW' AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_excursion_products_departure_city_public
    ON excursion_products(departure_city_id, updated_at DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC' AND departure_city_id IS NOT NULL;
