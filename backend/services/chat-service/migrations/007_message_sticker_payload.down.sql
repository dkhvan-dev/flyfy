DROP INDEX IF EXISTS idx_messages_sticker_payload_pack;

ALTER TABLE messages
    DROP COLUMN IF EXISTS sticker_payload;
