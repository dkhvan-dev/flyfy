ALTER TABLE files
    ADD COLUMN IF NOT EXISTS policy_status TEXT NOT NULL DEFAULT 'ALLOWED',
    ADD COLUMN IF NOT EXISTS policy_reason_code TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS policy_decision_id TEXT NOT NULL DEFAULT '';

ALTER TABLE files
    DROP CONSTRAINT IF EXISTS files_policy_status_check;

ALTER TABLE files
    ADD CONSTRAINT files_policy_status_check
    CHECK (policy_status IN ('ALLOWED', 'QUARANTINED', 'DENIED', 'PENDING'));

CREATE INDEX IF NOT EXISTS files_policy_status_idx
    ON files(policy_status, created_at DESC)
    WHERE policy_status <> 'ALLOWED';
