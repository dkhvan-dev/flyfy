SET lock_timeout = '5s';
SET statement_timeout = '30s';

ALTER TABLE saved_content_projections
    DROP CONSTRAINT IF EXISTS saved_content_projections_reconciliation_fail_closed_v1_check,
    DROP CONSTRAINT IF EXISTS saved_content_projections_public_title_check;

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_public_title_check
        CHECK (
            visibility_status <> 'PUBLIC'
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
    DROP CONSTRAINT IF EXISTS saved_content_projections_reconciliation_quarantine_v1_check,
    DROP CONSTRAINT IF EXISTS saved_content_projections_reconciliation_schedule_v1_check,
    DROP CONSTRAINT IF EXISTS saved_content_projections_reconciliation_lease_v1_check,
    DROP COLUMN IF EXISTS reconciliation_fail_closed_reason,
    DROP COLUMN IF EXISTS reconciliation_fail_closed_at,
    DROP COLUMN IF EXISTS reconciliation_quarantine_reason,
    DROP COLUMN IF EXISTS reconciliation_quarantined_at,
    DROP COLUMN IF EXISTS reconciliation_failure_kind,
    DROP COLUMN IF EXISTS reconciliation_failure_count,
    DROP COLUMN IF EXISTS reconciliation_next_attempt_at,
    DROP COLUMN IF EXISTS reconciliation_last_attempt_at,
    DROP COLUMN IF EXISTS reconciliation_lease_expires_at,
    DROP COLUMN IF EXISTS reconciliation_lease_token;
