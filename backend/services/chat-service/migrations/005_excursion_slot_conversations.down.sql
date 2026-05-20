DROP INDEX IF EXISTS uq_conversations_excursion_schedule_slot_id;
DROP INDEX IF EXISTS idx_conversations_excursion_schedule_slot_id;

ALTER TABLE conversations
    DROP COLUMN IF EXISTS excursion_schedule_slot_id;
