-- Expand only: nullable metadata and NOT VALID checks avoid a table rewrite or
-- an unbounded validation scan while old application versions keep working.
SET lock_timeout = '5s';
SET statement_timeout = '30s';

ALTER TABLE saved_content_projections
    ADD COLUMN IF NOT EXISTS reconciliation_lease_token UUID,
    ADD COLUMN IF NOT EXISTS reconciliation_lease_expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reconciliation_last_attempt_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reconciliation_next_attempt_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reconciliation_failure_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reconciliation_failure_kind TEXT,
    ADD COLUMN IF NOT EXISTS reconciliation_quarantined_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reconciliation_quarantine_reason TEXT,
    ADD COLUMN IF NOT EXISTS reconciliation_fail_closed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS reconciliation_fail_closed_reason TEXT;

-- A local fail-closed row intentionally preserves source-owned PUBLIC state
-- while all exposable payload bytes are absent.
ALTER TABLE saved_content_projections
    DROP CONSTRAINT IF EXISTS saved_content_projections_public_title_check;

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_public_title_check
        CHECK (
            visibility_status <> 'PUBLIC'
            OR reconciliation_fail_closed_at IS NOT NULL
            OR (
                source_default_locale IS NOT NULL
                AND (
                    (source_default_locale = 'EN' AND title_en IS NOT NULL)
                    OR (source_default_locale = 'RU' AND title_ru IS NOT NULL)
                    OR (source_default_locale = 'KK' AND title_kk IS NOT NULL)
                )
            )
        ) NOT VALID;

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_reconciliation_lease_v1_check
        CHECK (
            (reconciliation_lease_token IS NULL) =
            (reconciliation_lease_expires_at IS NULL)
        ) NOT VALID,
    ADD CONSTRAINT saved_content_projections_reconciliation_schedule_v1_check
        CHECK (
            (reconciliation_lease_expires_at IS NULL OR isfinite(reconciliation_lease_expires_at))
            AND (reconciliation_last_attempt_at IS NULL OR isfinite(reconciliation_last_attempt_at))
            AND (reconciliation_next_attempt_at IS NULL OR isfinite(reconciliation_next_attempt_at))
            AND COALESCE(reconciliation_failure_count, 0) BETWEEN 0 AND 32767
            AND (
                (
                    COALESCE(reconciliation_failure_count, 0) = 0
                    AND reconciliation_failure_kind IS NULL
                )
                OR (
                    reconciliation_failure_count IS NOT NULL
                    AND reconciliation_failure_count BETWEEN 1 AND 32767
                    AND reconciliation_failure_kind IS NOT NULL
                    AND reconciliation_failure_kind IN (
                        'TRANSIENT', 'INVARIANT', 'UNSUPPORTED'
                    )
                )
            )
        ) NOT VALID,
    ADD CONSTRAINT saved_content_projections_reconciliation_quarantine_v1_check
        CHECK (
            (
                reconciliation_quarantined_at IS NULL
                AND reconciliation_quarantine_reason IS NULL
            )
            OR (
                reconciliation_quarantined_at IS NOT NULL
                AND isfinite(reconciliation_quarantined_at)
                AND reconciliation_quarantine_reason IS NOT NULL
                AND reconciliation_quarantine_reason IN ('INVARIANT', 'UNSUPPORTED')
                AND reconciliation_failure_kind IS NOT NULL
                AND reconciliation_failure_kind = reconciliation_quarantine_reason
                AND COALESCE(reconciliation_failure_count, 0) > 0
                AND reconciliation_next_attempt_at IS NULL
                AND reconciliation_lease_token IS NULL
            )
        ) NOT VALID,
    ADD CONSTRAINT saved_content_projections_reconciliation_fail_closed_v1_check
        CHECK (
            (
                reconciliation_fail_closed_at IS NULL
                AND reconciliation_fail_closed_reason IS NULL
            )
            OR (
                reconciliation_fail_closed_at IS NOT NULL
                AND isfinite(reconciliation_fail_closed_at)
                AND reconciliation_fail_closed_reason IS NOT NULL
                AND reconciliation_fail_closed_reason = 'UNVERSIONED_NOT_FOUND'
                AND num_nonnulls(
                    source_default_locale,
                    title_en, title_ru, title_kk,
                    subtitle_en, subtitle_ru, subtitle_kk,
                    city_en, city_ru, city_kk,
                    country_en, country_ru, country_kk,
                    display_location_en, display_location_ru, display_location_kk,
                    normalized_search_document_en,
                    normalized_search_document_ru,
                    normalized_search_document_kk,
                    search_title_en_v1, search_title_ru_v1, search_title_kk_v1,
                    search_city_en_v1, search_city_ru_v1, search_city_kk_v1,
                    search_country_en_v1, search_country_ru_v1, search_country_kk_v1,
                    media_reference, media_reference_revision, media_valid_until,
                    rating_value, rating_count, rating_scale_max,
                    price_summary, availability_summary,
                    summary_as_of, summary_valid_until,
                    canonical_detail_route
                ) = 0
            )
        ) NOT VALID;
