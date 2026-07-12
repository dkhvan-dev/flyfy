DROP TABLE IF EXISTS activity_translation_jobs;

ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_translations_object,
    DROP CONSTRAINT IF EXISTS chk_activities_translation_status,
    DROP CONSTRAINT IF EXISTS chk_activities_source_language,
    DROP COLUMN IF EXISTS translations,
    DROP COLUMN IF EXISTS translation_status,
    DROP COLUMN IF EXISTS source_language;
