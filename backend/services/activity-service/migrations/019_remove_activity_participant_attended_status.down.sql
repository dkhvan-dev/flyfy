ALTER TABLE activity_participants
    ADD COLUMN attended_at TIMESTAMPTZ NULL;

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
            'ATTENDED',
            'NO_SHOW'
        ));
