UPDATE activity_participants
SET
    status = 'CHECKED_IN',
    checked_in_at = COALESCE(checked_in_at, attended_at, updated_at),
    updated_at = NOW()
WHERE status = 'ATTENDED';

ALTER TABLE activity_participants
    DROP CONSTRAINT chk_activity_participants_status;

ALTER TABLE activity_participants
    ADD CONSTRAINT chk_activity_participants_status
        CHECK (status IN (
            'INVITED',
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
            'NO_SHOW'
        ));

ALTER TABLE activity_participants
    DROP COLUMN attended_at;
