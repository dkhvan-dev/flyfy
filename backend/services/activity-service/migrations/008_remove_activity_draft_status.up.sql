UPDATE activities
SET status = CASE
        WHEN moderation_status IN ('PENDING_REVIEW', 'REJECTED') THEN 'REVIEW_REQUIRED'
        ELSE 'ENROLLMENT_OPEN'
    END,
    moderation_status = CASE
        WHEN moderation_status IN ('PENDING_REVIEW', 'REJECTED') THEN moderation_status
        ELSE 'APPROVED'
    END,
    published_at = CASE
        WHEN moderation_status IN ('PENDING_REVIEW', 'REJECTED') THEN published_at
        ELSE COALESCE(published_at, NOW())
    END,
    updated_at = NOW()
WHERE status = 'DRAFT';

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
