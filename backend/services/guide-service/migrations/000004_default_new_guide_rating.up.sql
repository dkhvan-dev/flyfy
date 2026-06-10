ALTER TABLE guide_profiles
    ALTER COLUMN rating_avg SET DEFAULT 5.00;

UPDATE guide_profiles
SET rating_avg = 5.00,
    updated_at = NOW()
WHERE reviews_count = 0
  AND rating_avg = 0;
