ALTER TABLE activities
    DROP CONSTRAINT chk_activities_moderation_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_moderation_status
        CHECK (moderation_status IN ('NOT_REQUIRED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED'));

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_status
        CHECK (status IN (
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
