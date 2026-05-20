ALTER TABLE excursion_reviews
    DROP CONSTRAINT IF EXISTS chk_excursion_reviews_comment,
    ADD CONSTRAINT chk_excursion_reviews_comment
        CHECK (length(comment) <= 2000);

ALTER TABLE guide_reviews
    DROP CONSTRAINT IF EXISTS chk_guide_reviews_comment,
    ADD CONSTRAINT chk_guide_reviews_comment
        CHECK (length(comment) <= 2000);
