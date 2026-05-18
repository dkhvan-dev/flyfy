DROP INDEX IF EXISTS idx_excursion_bookings_schedule_slot;
DROP INDEX IF EXISTS idx_excursion_schedule_slots_status_start;
DROP INDEX IF EXISTS idx_excursion_schedule_slots_series_start;
DROP INDEX IF EXISTS idx_excursion_schedule_slots_offer_start;
DROP INDEX IF EXISTS idx_excursion_schedule_slots_guide_range;

ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS fk_excursion_bookings_schedule_slot,
    DROP COLUMN IF EXISTS schedule_slot_id;

DROP TABLE IF EXISTS excursion_schedule_slots;
DROP TABLE IF EXISTS excursion_schedule_series;
