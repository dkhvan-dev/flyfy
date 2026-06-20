CREATE TABLE IF NOT EXISTS place_rating_sources (
    place_id UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    source VARCHAR(64) NOT NULL,
    rating_sum NUMERIC(12,2) NOT NULL DEFAULT 0,
    review_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, source),
    CONSTRAINT chk_place_rating_sources_source
        CHECK (length(trim(source)) > 0),
    CONSTRAINT chk_place_rating_sources_rating_sum
        CHECK (rating_sum >= 0),
    CONSTRAINT chk_place_rating_sources_review_count
        CHECK (review_count >= 0)
);

CREATE INDEX IF NOT EXISTS idx_place_rating_sources_place
    ON place_rating_sources(place_id);
