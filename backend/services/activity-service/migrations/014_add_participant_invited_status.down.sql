UPDATE activity_participants
SET status = 'CANCELLED',
    cancelled_at = COALESCE(cancelled_at, NOW()),
    updated_at = NOW()
WHERE status = 'INVITED';

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

DROP INDEX IF EXISTS uq_activity_participants_active_user;

CREATE UNIQUE INDEX uq_activity_participants_active_user
    ON activity_participants(activity_id, user_id)
    WHERE status IN (
        'REQUESTED',
        'APPROVED',
        'WAITLISTED',
        'PENDING_PAYMENT',
        'CONFIRMED',
        'CHECKED_IN'
    );
