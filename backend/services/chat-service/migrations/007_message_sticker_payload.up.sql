ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS sticker_payload JSONB;

CREATE INDEX IF NOT EXISTS idx_messages_sticker_payload_pack
    ON messages ((sticker_payload->>'packId'))
    WHERE sticker_payload IS NOT NULL;
