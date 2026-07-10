CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE excursions
    ADD COLUMN IF NOT EXISTS source_language TEXT NOT NULL DEFAULT 'ru',
    ADD COLUMN IF NOT EXISTS translation_status TEXT NOT NULL DEFAULT 'NONE';

ALTER TABLE excursions
    DROP CONSTRAINT IF EXISTS excursions_source_language_check,
    DROP CONSTRAINT IF EXISTS excursions_translation_status_check;

ALTER TABLE excursions
    ADD CONSTRAINT excursions_source_language_check
        CHECK (source_language IN ('ru', 'kk', 'en')) NOT VALID,
    ADD CONSTRAINT excursions_translation_status_check
        CHECK (translation_status IN ('NONE', 'PENDING', 'PARTIAL', 'COMPLETED', 'FAILED', 'DISABLED')) NOT VALID;

ALTER TABLE excursions VALIDATE CONSTRAINT excursions_source_language_check;
ALTER TABLE excursions VALIDATE CONSTRAINT excursions_translation_status_check;

CREATE TABLE IF NOT EXISTS excursion_translation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    source_language TEXT NOT NULL,
    target_language TEXT NOT NULL,
    source_fields JSONB NOT NULL,
    source_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 5,
    next_run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_at TIMESTAMPTZ NULL,
    locked_by TEXT NULL,
    last_error TEXT NULL,
    provider TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ NULL,
    CONSTRAINT excursion_translation_jobs_entity_type_check
        CHECK (entity_type IN ('itinerary_item')),
    CONSTRAINT excursion_translation_jobs_source_language_check
        CHECK (source_language IN ('ru', 'kk', 'en')),
    CONSTRAINT excursion_translation_jobs_target_language_check
        CHECK (target_language IN ('ru', 'kk', 'en')),
    CONSTRAINT excursion_translation_jobs_distinct_languages_check
        CHECK (source_language <> target_language),
    CONSTRAINT excursion_translation_jobs_source_fields_check
        CHECK (jsonb_typeof(source_fields) = 'object'),
    CONSTRAINT excursion_translation_jobs_source_hash_check
        CHECK (source_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT excursion_translation_jobs_status_check
        CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'STALE', 'CANCELLED')),
    CONSTRAINT excursion_translation_jobs_attempts_check
        CHECK (attempts >= 0 AND max_attempts > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_excursion_translation_jobs_source
    ON excursion_translation_jobs (entity_type, entity_id, target_language, source_hash);

CREATE INDEX IF NOT EXISTS idx_excursion_translation_jobs_pending
    ON excursion_translation_jobs (next_run_at, created_at)
    WHERE status = 'PENDING';

CREATE INDEX IF NOT EXISTS idx_excursion_translation_jobs_excursion
    ON excursion_translation_jobs (excursion_id, status, target_language);

CREATE INDEX IF NOT EXISTS idx_excursion_translation_jobs_locked
    ON excursion_translation_jobs (locked_at)
    WHERE status = 'PROCESSING';

