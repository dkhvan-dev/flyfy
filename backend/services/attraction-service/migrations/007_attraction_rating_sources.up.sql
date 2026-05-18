CREATE TABLE attraction_rating_sources (
    attraction_id UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
    source VARCHAR(64) NOT NULL,
    rating_sum NUMERIC(12,2) NOT NULL DEFAULT 0,
    review_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (attraction_id, source),
    CONSTRAINT chk_attraction_rating_sources_source
        CHECK (length(trim(source)) > 0),
    CONSTRAINT chk_attraction_rating_sources_rating_sum
        CHECK (rating_sum >= 0),
    CONSTRAINT chk_attraction_rating_sources_review_count
        CHECK (review_count >= 0)
);

CREATE INDEX idx_attraction_rating_sources_attraction
    ON attraction_rating_sources(attraction_id);
