CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS translation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    source_language TEXT NOT NULL,
    target_language TEXT NOT NULL,
    glossary_version TEXT NOT NULL DEFAULT '',
    source_hash TEXT NOT NULL,
    normalized_source_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    provider_model_label TEXT NOT NULL DEFAULT '',
    quality_status TEXT NOT NULL DEFAULT 'machine',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT translation_cache_source_language_check
        CHECK (source_language IN ('en', 'ru', 'kk')),
    CONSTRAINT translation_cache_target_language_check
        CHECK (target_language IN ('en', 'ru', 'kk')),
    CONSTRAINT translation_cache_source_hash_check
        CHECK (source_hash ~ '^[a-f0-9]{64}$'),
    CONSTRAINT translation_cache_quality_status_check
        CHECK (quality_status IN ('machine', 'reviewed')),
    UNIQUE (provider, source_language, target_language, glossary_version, source_hash)
);

CREATE INDEX IF NOT EXISTS idx_translation_cache_lookup
    ON translation_cache(provider, source_language, target_language, glossary_version, source_hash);

CREATE INDEX IF NOT EXISTS idx_translation_cache_updated
    ON translation_cache(updated_at DESC);

CREATE TABLE IF NOT EXISTS translation_usage_monthly (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    environment TEXT NOT NULL,
    year_month CHAR(7) NOT NULL,
    source_language TEXT NOT NULL,
    target_language TEXT NOT NULL,
    content_type TEXT NOT NULL,
    billing_mode TEXT NOT NULL DEFAULT 'free_only',
    reserved_characters BIGINT NOT NULL DEFAULT 0,
    billed_characters BIGINT NOT NULL DEFAULT 0,
    request_count BIGINT NOT NULL DEFAULT 0,
    monthly_limit BIGINT NOT NULL DEFAULT 0,
    warning_threshold NUMERIC(5, 4) NOT NULL DEFAULT 0.8000,
    critical_threshold NUMERIC(5, 4) NOT NULL DEFAULT 0.9500,
    warning_reached BOOLEAN NOT NULL DEFAULT false,
    critical_reached BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT translation_usage_monthly_language_check
        CHECK (source_language IN ('en', 'ru', 'kk') AND target_language IN ('en', 'ru', 'kk')),
    CONSTRAINT translation_usage_monthly_content_type_check
        CHECK (content_type IN ('attraction', 'excursion', 'activity', 'guide_profile', 'help_article', 'admin_public')),
    CONSTRAINT translation_usage_monthly_billing_mode_check
        CHECK (billing_mode IN ('free_only', 'paid_allowed', 'disabled')),
    CONSTRAINT translation_usage_monthly_environment_check
        CHECK (environment <> ''),
    CONSTRAINT translation_usage_monthly_year_month_check
        CHECK (year_month ~ '^[0-9]{4}-[0-9]{2}$'),
    CONSTRAINT translation_usage_monthly_non_negative_check
        CHECK (
            reserved_characters >= 0
            AND billed_characters >= 0
            AND request_count >= 0
            AND monthly_limit >= 0
        ),
    UNIQUE (provider, environment, year_month, source_language, target_language, content_type)
);

CREATE INDEX IF NOT EXISTS idx_translation_usage_monthly_provider_month
    ON translation_usage_monthly(provider, environment, year_month);

CREATE TABLE IF NOT EXISTS translation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key TEXT NOT NULL UNIQUE,
    source_language TEXT NOT NULL,
    target_languages TEXT[] NOT NULL,
    content_type TEXT NOT NULL,
    texts JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    result JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_code TEXT,
    error_message TEXT,
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,

    CONSTRAINT translation_jobs_source_language_check
        CHECK (source_language IN ('en', 'ru', 'kk')),
    CONSTRAINT translation_jobs_content_type_check
        CHECK (content_type IN ('attraction', 'excursion', 'activity', 'guide_profile', 'help_article', 'admin_public')),
    CONSTRAINT translation_jobs_status_check
        CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    CONSTRAINT translation_jobs_attempt_count_check
        CHECK (attempt_count >= 0)
);

CREATE INDEX IF NOT EXISTS idx_translation_jobs_due
    ON translation_jobs(next_attempt_at, created_at)
    WHERE status IN ('pending', 'failed');

CREATE INDEX IF NOT EXISTS idx_translation_jobs_status_created
    ON translation_jobs(status, created_at DESC);
