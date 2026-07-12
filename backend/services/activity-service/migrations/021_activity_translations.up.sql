ALTER TABLE activities
    ADD COLUMN source_language VARCHAR(5) NOT NULL DEFAULT 'ru',
    ADD COLUMN translation_status VARCHAR(16) NOT NULL DEFAULT 'NONE',
    ADD COLUMN translations JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_source_language
        CHECK (source_language IN ('ru', 'kk', 'en')),
    ADD CONSTRAINT chk_activities_translation_status
        CHECK (translation_status IN ('NONE', 'PENDING', 'PARTIAL', 'COMPLETED', 'FAILED', 'DISABLED')),
    ADD CONSTRAINT chk_activities_translations_object
        CHECK (jsonb_typeof(translations) = 'object');

UPDATE activities
SET source_language = CASE LOWER(SPLIT_PART(REPLACE(language_code, '_', '-'), '-', 1))
        WHEN 'en' THEN 'en'
        WHEN 'kk' THEN 'kk'
        WHEN 'ru' THEN 'ru'
        ELSE 'ru'
    END;

UPDATE activities
SET translations = jsonb_build_object(
        source_language,
        jsonb_build_object('title', title, 'description', description)
    )
WHERE translations = '{}'::jsonb;

CREATE TABLE activity_translation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    source_language VARCHAR(5) NOT NULL,
    target_language VARCHAR(5) NOT NULL,
    source_fields JSONB NOT NULL,
    source_hash CHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    next_run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_at TIMESTAMPTZ NULL,
    locked_by VARCHAR(200) NULL,
    last_error VARCHAR(512) NULL,
    provider VARCHAR(100) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_activity_translation_jobs_languages
        CHECK (
            source_language IN ('ru', 'kk', 'en')
            AND target_language IN ('ru', 'kk', 'en')
            AND source_language <> target_language
        ),
    CONSTRAINT chk_activity_translation_jobs_source_fields
        CHECK (jsonb_typeof(source_fields) = 'object'),
    CONSTRAINT chk_activity_translation_jobs_source_hash
        CHECK (source_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT chk_activity_translation_jobs_status
        CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'STALE', 'CANCELLED')),
    CONSTRAINT chk_activity_translation_jobs_attempts
        CHECK (attempts >= 0 AND max_attempts > 0)
);

CREATE UNIQUE INDEX uq_activity_translation_jobs_source
    ON activity_translation_jobs(activity_id, target_language, source_hash);

CREATE INDEX idx_activity_translation_jobs_due
    ON activity_translation_jobs(next_run_at, created_at)
    WHERE status = 'PENDING';

CREATE INDEX idx_activity_translation_jobs_processing_lock
    ON activity_translation_jobs(locked_at)
    WHERE status = 'PROCESSING';

CREATE INDEX idx_activity_translation_jobs_activity
    ON activity_translation_jobs(activity_id, created_at);
