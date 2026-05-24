CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE excursions
    ADD COLUMN IF NOT EXISTS guide_rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS guide_reviews_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS guide_experience_years INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS guide_display_name VARCHAR(180) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS guide_nickname VARCHAR(180) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS guide_first_name VARCHAR(120) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS guide_last_name VARCHAR(120) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS guide_search_text TEXT NOT NULL DEFAULT '',
    ADD CONSTRAINT chk_excursions_guide_snapshot
        CHECK (
            guide_rating_avg >= 0
            AND guide_reviews_count >= 0
            AND guide_experience_years >= 0
        );

UPDATE excursions
SET guide_search_text = trim(concat_ws(
    ' ',
    NULLIF(guide_display_name, ''),
    NULLIF(guide_nickname, ''),
    NULLIF(guide_first_name, ''),
    NULLIF(guide_last_name, ''),
    guide_user_id::text,
    guide_profile_id::text
))
WHERE guide_search_text = '';

CREATE INDEX idx_excursions_guide_display_name_trgm
    ON excursions USING GIN (LOWER(guide_display_name) gin_trgm_ops)
    WHERE deleted_at IS NULL AND guide_display_name <> '';

CREATE INDEX idx_excursions_guide_nickname_trgm
    ON excursions USING GIN (LOWER(guide_nickname) gin_trgm_ops)
    WHERE deleted_at IS NULL AND guide_nickname <> '';

CREATE INDEX idx_excursions_guide_search_text_trgm
    ON excursions USING GIN (LOWER(guide_search_text) gin_trgm_ops)
    WHERE deleted_at IS NULL AND guide_search_text <> '';
