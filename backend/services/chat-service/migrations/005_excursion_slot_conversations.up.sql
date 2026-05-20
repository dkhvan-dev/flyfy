ALTER TABLE conversations
    ADD COLUMN IF NOT EXISTS excursion_schedule_slot_id UUID;

CREATE INDEX IF NOT EXISTS idx_conversations_excursion_schedule_slot_id
    ON conversations (excursion_schedule_slot_id)
    WHERE excursion_schedule_slot_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_excursion_schedule_slot_id
    ON conversations (excursion_schedule_slot_id)
    WHERE excursion_schedule_slot_id IS NOT NULL;
