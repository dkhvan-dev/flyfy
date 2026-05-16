DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'guide_profiles'
          AND column_name = 'is_tour_guide_available'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'guide_profiles'
          AND column_name = 'is_excursion_guide_available'
    ) THEN
        ALTER TABLE guide_profiles
            RENAME COLUMN is_tour_guide_available TO is_excursion_guide_available;
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'guide_profiles'
          AND column_name = 'is_tour_guide_available'
    ) AND EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'guide_profiles'
          AND column_name = 'is_excursion_guide_available'
    ) THEN
        UPDATE guide_profiles
        SET is_excursion_guide_available = is_excursion_guide_available OR is_tour_guide_available;

        ALTER TABLE guide_profiles
            DROP COLUMN is_tour_guide_available;
    END IF;
END $$;

ALTER TABLE guide_profiles
    ALTER COLUMN is_excursion_guide_available SET DEFAULT FALSE,
    ALTER COLUMN is_excursion_guide_available SET NOT NULL;
