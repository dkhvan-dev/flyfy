UPDATE activities
SET status = 'ENROLLMENT_OPEN'
WHERE status IN ('REGISTRATION_CLOSED', 'CONFIRMATION_PENDING', 'CONFIRMED');

UPDATE activity_participants
SET status = 'CANCELLED'
WHERE status IN ('LATE_CANCELLED', 'CANCELLED_BY_ACTIVITY');

DROP INDEX IF EXISTS idx_activities_registration_deadline_status;

ALTER TABLE activity_participants
    DROP CONSTRAINT chk_activity_participants_status;

ALTER TABLE activity_participants
    ADD CONSTRAINT chk_activity_participants_status
        CHECK (status IN (
            'REQUESTED',
            'APPROVED',
            'WAITLISTED',
            'PENDING_PAYMENT',
            'CONFIRMED',
            'DECLINED',
            'CANCELLED',
            'EXPIRED',
            'CHECKED_IN',
            'ATTENDED',
            'NO_SHOW'
        ));

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_status
        CHECK (status IN (
            'DRAFT',
            'REVIEW_REQUIRED',
            'PUBLISHED',
            'ENROLLMENT_OPEN',
            'FULL',
            'STARTED',
            'COMPLETED',
            'CANCELLED',
            'ARCHIVED'
        ));

ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_cancellation_source;

ALTER TABLE activities
    DROP COLUMN IF EXISTS cancelled_by_user_id,
    DROP COLUMN IF EXISTS cancellation_source;
