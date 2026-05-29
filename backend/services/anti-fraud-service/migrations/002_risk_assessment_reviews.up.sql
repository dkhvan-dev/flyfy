ALTER TABLE risk_assessments
    ADD COLUMN IF NOT EXISTS review_status VARCHAR(32) NOT NULL DEFAULT 'OPEN',
    ADD COLUMN IF NOT EXISTS reviewed_by_staff_id UUID,
    ADD COLUMN IF NOT EXISTS review_reason_codes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN IF NOT EXISTS review_comment TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'risk_assessments_review_status_chk'
    ) THEN
        ALTER TABLE risk_assessments
            ADD CONSTRAINT risk_assessments_review_status_chk
            CHECK (review_status IN ('OPEN', 'CONFIRMED_FRAUD', 'FALSE_POSITIVE', 'ESCALATED'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_risk_assessments_subject_review_created_at
    ON risk_assessments (subject_type, review_status, created_at DESC);
