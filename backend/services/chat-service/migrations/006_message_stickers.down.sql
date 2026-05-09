DROP INDEX IF EXISTS idx_messages_sticker_id;

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS chk_messages_sticker_payload;

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS messages_type_check;

ALTER TABLE messages
    ADD CONSTRAINT messages_type_check
    CHECK (type IN ('text', 'file', 'system'));

ALTER TABLE messages
    DROP COLUMN IF EXISTS sticker_file_id,
    DROP COLUMN IF EXISTS sticker_id;
