DROP INDEX IF EXISTS idx_excursion_translation_jobs_locked;
DROP INDEX IF EXISTS idx_excursion_translation_jobs_excursion;
DROP INDEX IF EXISTS idx_excursion_translation_jobs_pending;
DROP INDEX IF EXISTS ux_excursion_translation_jobs_source;

DROP TABLE IF EXISTS excursion_translation_jobs;

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS excursions_translation_status_check,
    DROP CONSTRAINT IF EXISTS excursions_source_language_check;

ALTER TABLE excursions
    DROP COLUMN IF EXISTS translation_status,
    DROP COLUMN IF EXISTS source_language;

