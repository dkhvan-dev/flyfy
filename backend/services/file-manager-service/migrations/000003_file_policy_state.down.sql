DROP INDEX IF EXISTS files_policy_status_idx;

ALTER TABLE files
    DROP CONSTRAINT IF EXISTS files_policy_status_check;

ALTER TABLE files
    DROP COLUMN IF EXISTS policy_decision_id,
    DROP COLUMN IF EXISTS policy_reason_code,
    DROP COLUMN IF EXISTS policy_status;
