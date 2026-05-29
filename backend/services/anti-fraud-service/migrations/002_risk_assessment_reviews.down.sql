DROP INDEX IF EXISTS idx_risk_assessments_subject_review_created_at;

ALTER TABLE risk_assessments
    DROP CONSTRAINT IF EXISTS risk_assessments_review_status_chk,
    DROP COLUMN IF EXISTS updated_at,
    DROP COLUMN IF EXISTS reviewed_at,
    DROP COLUMN IF EXISTS review_comment,
    DROP COLUMN IF EXISTS review_reason_codes,
    DROP COLUMN IF EXISTS reviewed_by_staff_id,
    DROP COLUMN IF EXISTS review_status;
