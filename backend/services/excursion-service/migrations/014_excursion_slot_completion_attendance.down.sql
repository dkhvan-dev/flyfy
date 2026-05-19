DROP TABLE IF EXISTS excursion_attendance_sync_attempts;
DROP TABLE IF EXISTS excursion_attendance_qr_issues;

ALTER TABLE excursion_bookings
    DROP COLUMN IF EXISTS checked_in_at;

ALTER TABLE excursion_schedule_slots
    DROP CONSTRAINT chk_excursion_schedule_slots_status,
    ADD CONSTRAINT chk_excursion_schedule_slots_status
        CHECK (status IN ('AVAILABLE', 'BOOKED', 'FULL', 'CLOSED', 'CANCELLED'));

ALTER TABLE excursion_schedule_slots
    DROP COLUMN IF EXISTS completion_reason,
    DROP COLUMN IF EXISTS completed_at;
