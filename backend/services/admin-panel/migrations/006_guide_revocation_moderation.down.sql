ALTER TABLE moderation_decisions
    DROP CONSTRAINT IF EXISTS chk_moderation_decisions_type;

ALTER TABLE moderation_decisions
    ADD CONSTRAINT chk_moderation_decisions_type
        CHECK (decision_type IN ('APPROVE', 'REJECT', 'REQUEST_CHANGES', 'ESCALATE'));

UPDATE moderation_cases
SET status = 'REJECTED'
WHERE status = 'REVOKED';

ALTER TABLE moderation_cases
    DROP CONSTRAINT IF EXISTS chk_moderation_cases_status;

ALTER TABLE moderation_cases
    ADD CONSTRAINT chk_moderation_cases_status
        CHECK (status IN ('OPEN', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'ESCALATED', 'CANCELLED'));
