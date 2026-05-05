ALTER TABLE activities
    ADD COLUMN cancellation_source VARCHAR(30) NULL,
    ADD COLUMN cancelled_by_user_id UUID NULL;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_cancellation_source
        CHECK (
            cancellation_source IS NULL
            OR cancellation_source IN ('SYSTEM', 'ADMIN', 'HOST', 'PAYMENT_SYSTEM')
        );

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
            'REGISTRATION_CLOSED',
            'CONFIRMATION_PENDING',
            'CONFIRMED',
            'STARTED',
            'COMPLETED',
            'CANCELLED',
            'ARCHIVED'
        ));

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
            'LATE_CANCELLED',
            'CANCELLED_BY_ACTIVITY',
            'EXPIRED',
            'CHECKED_IN',
            'ATTENDED',
            'NO_SHOW'
        ));

CREATE INDEX idx_activities_registration_deadline_status
    ON activities(registration_deadline, status);
