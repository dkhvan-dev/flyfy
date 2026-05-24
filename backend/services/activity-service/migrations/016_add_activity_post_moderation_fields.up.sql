ALTER TABLE activities
    DROP CONSTRAINT chk_activities_moderation_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_moderation_status
        CHECK (moderation_status IN ('NOT_REQUIRED', 'FLAGGED', 'IN_REVIEW', 'APPROVED', 'REJECTED'));

ALTER TABLE activities
    ADD COLUMN IF NOT EXISTS moderation_risk_score INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS moderation_reason_codes TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS moderation_triggered_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS moderation_reviewed_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_activities_moderation_queue
    ON activities(moderation_status, moderation_risk_score DESC, moderation_triggered_at ASC, created_at DESC)
    WHERE moderation_status IN ('FLAGGED', 'IN_REVIEW');
