DROP INDEX IF EXISTS ux_moderation_decisions_case_revision_active;

ALTER TABLE moderation_decisions
    DROP CONSTRAINT IF EXISTS chk_moderation_decisions_apply_status;

ALTER TABLE moderation_decisions
    ADD CONSTRAINT chk_moderation_decisions_apply_status
        CHECK (apply_status IN ('PENDING', 'APPLIED', 'FAILED', 'SUPERSEDED'));

CREATE UNIQUE INDEX IF NOT EXISTS ux_moderation_decisions_case_revision_pending
    ON moderation_decisions(case_id, source_revision)
    WHERE apply_status = 'PENDING';
