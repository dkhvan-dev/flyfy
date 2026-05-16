ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS forwarded_from_message_id UUID REFERENCES messages (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS forwarded_from_sender_user_id UUID,
    ADD COLUMN IF NOT EXISTS forwarded_from_sender_name TEXT,
    ADD COLUMN IF NOT EXISTS forward_count INT NOT NULL DEFAULT 0 CHECK (forward_count >= 0);

CREATE INDEX IF NOT EXISTS idx_messages_forwarded_from
    ON messages (forwarded_from_message_id)
    WHERE forwarded_from_message_id IS NOT NULL;
