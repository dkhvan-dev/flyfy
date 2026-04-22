ALTER TABLE conversations
    ADD COLUMN IF NOT EXISTS messaging_available_until TIMESTAMPTZ;
