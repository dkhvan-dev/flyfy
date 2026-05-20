UPDATE excursion_reviews
SET comment = '(rating only)'
WHERE length(trim(comment)) = 0;

ALTER TABLE excursion_reviews
    DROP CONSTRAINT IF EXISTS chk_excursion_reviews_comment,
    ADD CONSTRAINT chk_excursion_reviews_comment
        CHECK (length(trim(comment)) > 0 AND length(comment) <= 2000);

UPDATE guide_reviews
SET comment = '(rating only)'
WHERE length(trim(comment)) = 0;

ALTER TABLE guide_reviews
    DROP CONSTRAINT IF EXISTS chk_guide_reviews_comment,
    ADD CONSTRAINT chk_guide_reviews_comment
        CHECK (length(trim(comment)) > 0 AND length(comment) <= 2000);
