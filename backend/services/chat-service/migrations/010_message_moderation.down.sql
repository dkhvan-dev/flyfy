DROP INDEX IF EXISTS idx_messages_moderation_reviewed;
DROP INDEX IF EXISTS idx_messages_moderation_queue;

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS chk_messages_moderation_status;

ALTER TABLE messages
    DROP COLUMN IF EXISTS moderation_revision,
    DROP COLUMN IF EXISTS moderation_internal_comment,
    DROP COLUMN IF EXISTS moderation_public_comment,
    DROP COLUMN IF EXISTS moderation_reviewed_by,
    DROP COLUMN IF EXISTS moderation_reviewed_at,
    DROP COLUMN IF EXISTS moderation_triggered_at,
    DROP COLUMN IF EXISTS moderation_risk_score,
    DROP COLUMN IF EXISTS moderation_reason_codes,
    DROP COLUMN IF EXISTS moderation_status;
