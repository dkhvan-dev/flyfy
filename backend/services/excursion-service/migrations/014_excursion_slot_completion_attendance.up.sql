ALTER TABLE excursion_schedule_slots
    ADD COLUMN completed_at TIMESTAMPTZ NULL,
    ADD COLUMN completion_reason TEXT NULL;

ALTER TABLE excursion_schedule_slots
    DROP CONSTRAINT chk_excursion_schedule_slots_status,
    ADD CONSTRAINT chk_excursion_schedule_slots_status
        CHECK (status IN ('AVAILABLE', 'BOOKED', 'FULL', 'CLOSED', 'CANCELLED', 'COMPLETED'));

ALTER TABLE excursion_bookings
    ADD COLUMN checked_in_at TIMESTAMPTZ NULL;

CREATE TABLE excursion_attendance_qr_issues (
    jti UUID PRIMARY KEY,
    schedule_slot_id UUID NOT NULL REFERENCES excursion_schedule_slots(id) ON DELETE CASCADE,
    guide_user_id UUID NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    usable_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_excursion_attendance_qr_issues_time_range
        CHECK (expires_at > issued_at AND usable_until > expires_at)
);

CREATE INDEX idx_excursion_attendance_qr_issues_slot_id
    ON excursion_attendance_qr_issues(schedule_slot_id);

CREATE INDEX idx_excursion_attendance_qr_issues_usable_until
    ON excursion_attendance_qr_issues(usable_until);

CREATE TABLE excursion_attendance_sync_attempts (
    scan_id UUID PRIMARY KEY,
    schedule_slot_id UUID NOT NULL REFERENCES excursion_schedule_slots(id) ON DELETE CASCADE,
    tourist_user_id UUID NOT NULL,
    qr_jti UUID NOT NULL REFERENCES excursion_attendance_qr_issues(jti) ON DELETE RESTRICT,
    installation_id TEXT NOT NULL,
    scanned_at_device TIMESTAMPTZ NULL,
    result_status TEXT NOT NULL,
    failure_code TEXT NULL,
    failure_message TEXT NULL,
    checked_in_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_excursion_attendance_sync_attempts_installation
        CHECK (BTRIM(installation_id) <> ''),
    CONSTRAINT chk_excursion_attendance_sync_attempts_status
        CHECK (result_status IN ('ACCEPTED', 'ALREADY_CHECKED_IN', 'REJECTED'))
);

CREATE INDEX idx_excursion_attendance_sync_attempts_slot_tourist
    ON excursion_attendance_sync_attempts(schedule_slot_id, tourist_user_id);

CREATE INDEX idx_excursion_attendance_sync_attempts_qr_jti
    ON excursion_attendance_sync_attempts(qr_jti);
