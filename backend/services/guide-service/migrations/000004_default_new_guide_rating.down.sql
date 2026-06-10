ALTER TABLE guide_profiles
    ALTER COLUMN rating_avg SET DEFAULT 0;

UPDATE guide_profiles
SET rating_avg = 0,
    updated_at = NOW()
WHERE reviews_count = 0
  AND rating_avg = 5.00;
