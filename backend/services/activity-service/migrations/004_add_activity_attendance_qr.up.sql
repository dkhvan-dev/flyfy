CREATE TABLE activity_attendance_qr_issues (
    jti UUID PRIMARY KEY,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    host_user_id UUID NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    usable_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_attendance_qr_issues_activity_id
    ON activity_attendance_qr_issues(activity_id);

CREATE INDEX idx_activity_attendance_qr_issues_usable_until
    ON activity_attendance_qr_issues(usable_until);

CREATE TABLE activity_attendance_sync_attempts (
    scan_id UUID PRIMARY KEY,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    participant_user_id UUID NOT NULL,
    qr_jti UUID NOT NULL,
    installation_id VARCHAR(160) NOT NULL,
    scanned_at_device TIMESTAMPTZ NULL,
    result_status VARCHAR(30) NOT NULL,
    failure_code VARCHAR(60) NULL,
    failure_message TEXT NULL,
    checked_in_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_activity_attendance_sync_attempts_status
        CHECK (result_status IN ('ACCEPTED', 'ALREADY_CHECKED_IN', 'REJECTED'))
);

CREATE INDEX idx_activity_attendance_sync_attempts_activity_participant
    ON activity_attendance_sync_attempts(activity_id, participant_user_id);

CREATE INDEX idx_activity_attendance_sync_attempts_qr_jti
    ON activity_attendance_sync_attempts(qr_jti);
