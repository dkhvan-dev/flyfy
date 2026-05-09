ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS sticker_id UUID,
    ADD COLUMN IF NOT EXISTS sticker_file_id VARCHAR(255);

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS messages_type_check;

ALTER TABLE messages
    ADD CONSTRAINT messages_type_check
    CHECK (type IN ('text', 'file', 'system', 'sticker'));

ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS chk_messages_sticker_payload;

ALTER TABLE messages
    ADD CONSTRAINT chk_messages_sticker_payload
    CHECK (
        (
            type = 'sticker'
            AND sticker_id IS NOT NULL
            AND length(trim(sticker_file_id)) > 0
        )
        OR (
            type <> 'sticker'
            AND sticker_id IS NULL
            AND sticker_file_id IS NULL
        )
    );

CREATE INDEX IF NOT EXISTS idx_messages_sticker_id
    ON messages (sticker_id)
    WHERE sticker_id IS NOT NULL;
