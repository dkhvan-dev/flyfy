CREATE INDEX idx_excursion_reviews_guide_rating_created
    ON excursion_reviews(guide_user_id, rating DESC, created_at DESC, id ASC);
