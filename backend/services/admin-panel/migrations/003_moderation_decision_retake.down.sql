DROP INDEX IF EXISTS ux_moderation_decisions_case_revision_pending;

UPDATE moderation_decisions
SET apply_status = 'APPLIED'
WHERE apply_status = 'SUPERSEDED';

ALTER TABLE moderation_decisions
    DROP CONSTRAINT IF EXISTS chk_moderation_decisions_apply_status;

ALTER TABLE moderation_decisions
    ADD CONSTRAINT chk_moderation_decisions_apply_status
        CHECK (apply_status IN ('PENDING', 'APPLIED', 'FAILED'));

CREATE UNIQUE INDEX IF NOT EXISTS ux_moderation_decisions_case_revision_active
    ON moderation_decisions(case_id, source_revision)
    WHERE apply_status IN ('PENDING', 'APPLIED');
