ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'VISIBLE',
    ADD COLUMN IF NOT EXISTS moderation_reason_codes TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    ADD COLUMN IF NOT EXISTS moderation_risk_score INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS moderation_triggered_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS moderation_reviewed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS moderation_reviewed_by UUID,
    ADD COLUMN IF NOT EXISTS moderation_public_comment TEXT,
    ADD COLUMN IF NOT EXISTS moderation_internal_comment TEXT,
    ADD COLUMN IF NOT EXISTS moderation_revision INTEGER NOT NULL DEFAULT 1;

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS chk_messages_moderation_status;

ALTER TABLE messages
    ADD CONSTRAINT chk_messages_moderation_status
    CHECK (moderation_status IN ('VISIBLE', 'FLAGGED', 'CLEARED', 'HIDDEN_BY_MODERATION'));

CREATE INDEX IF NOT EXISTS idx_messages_moderation_queue
    ON messages (moderation_status, moderation_risk_score DESC, sent_at DESC, id DESC)
    WHERE moderation_status = 'FLAGGED';

CREATE INDEX IF NOT EXISTS idx_messages_moderation_reviewed
    ON messages (moderation_reviewed_at DESC, id DESC)
    WHERE moderation_reviewed_at IS NOT NULL;
