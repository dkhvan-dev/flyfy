UPDATE activities
SET status = 'CANCELLED',
    cancellation_source = COALESCE(cancellation_source, 'ADMIN'),
    cancellation_reason = COALESCE(cancellation_reason, 'MODERATION_REJECTED'),
    cancelled_at = COALESCE(cancelled_at, NOW()),
    updated_at = NOW()
WHERE moderation_status = 'REJECTED'
  AND status NOT IN ('COMPLETED', 'CANCELLED', 'ARCHIVED');

UPDATE activities
SET status = 'ENROLLMENT_OPEN',
    moderation_status = 'APPROVED',
    published_at = COALESCE(published_at, NOW()),
    updated_at = NOW()
WHERE moderation_status = 'PENDING_REVIEW'
   OR (status = 'REVIEW_REQUIRED' AND moderation_status <> 'REJECTED');

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_status
        CHECK (status IN (
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

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_moderation_status;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_moderation_status
        CHECK (moderation_status IN ('NOT_REQUIRED', 'APPROVED', 'REJECTED'));
