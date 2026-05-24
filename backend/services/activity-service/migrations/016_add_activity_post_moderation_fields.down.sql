DROP INDEX IF EXISTS idx_activities_moderation_queue;

UPDATE activities
SET moderation_status = 'APPROVED',
    moderation_risk_score = 0,
    moderation_reason_codes = '{}',
    moderation_triggered_at = NULL,
    moderation_reviewed_at = NOW(),
    updated_at = NOW()
WHERE moderation_status IN ('FLAGGED', 'IN_REVIEW');

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_moderation_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_moderation_status
        CHECK (moderation_status IN ('NOT_REQUIRED', 'APPROVED', 'REJECTED'));

ALTER TABLE activities
    DROP COLUMN IF EXISTS moderation_reviewed_at,
    DROP COLUMN IF EXISTS moderation_triggered_at,
    DROP COLUMN IF EXISTS moderation_reason_codes,
    DROP COLUMN IF EXISTS moderation_risk_score;
