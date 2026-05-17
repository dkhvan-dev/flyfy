CREATE UNIQUE INDEX IF NOT EXISTS uq_excursions_active_guide_landmark
    ON excursions(guide_user_id, landmark_id)
    WHERE landmark_id IS NOT NULL
      AND deleted_at IS NULL
      AND status <> 'ARCHIVED';
