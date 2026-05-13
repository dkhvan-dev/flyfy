ALTER TABLE tour_offers
    ADD COLUMN guide_rating_avg NUMERIC(4,2) NOT NULL DEFAULT 0,
    ADD COLUMN guide_reviews_count INT NOT NULL DEFAULT 0,
    ADD COLUMN guide_experience_years INT NOT NULL DEFAULT 0;

ALTER TABLE tour_offers
    ADD CONSTRAINT chk_tour_offers_guide_rating_avg
        CHECK (guide_rating_avg >= 0 AND guide_rating_avg <= 5),
    ADD CONSTRAINT chk_tour_offers_guide_reviews_count
        CHECK (guide_reviews_count >= 0),
    ADD CONSTRAINT chk_tour_offers_guide_experience_years
        CHECK (guide_experience_years >= 0);

CREATE INDEX idx_tour_offers_product_rating
    ON tour_offers(product_id, guide_rating_avg DESC, guide_reviews_count DESC, price_amount ASC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC' AND deleted_at IS NULL;

CREATE INDEX idx_tour_offers_product_experience
    ON tour_offers(product_id, guide_experience_years DESC, guide_rating_avg DESC, guide_reviews_count DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC' AND deleted_at IS NULL;
