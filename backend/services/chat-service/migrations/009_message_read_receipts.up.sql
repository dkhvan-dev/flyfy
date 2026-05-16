CREATE TABLE IF NOT EXISTS message_read_receipts (
    message_id UUID        NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL,
    read_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_read_receipts_message_read_at
    ON message_read_receipts (message_id, read_at DESC);

CREATE INDEX IF NOT EXISTS idx_message_read_receipts_user
    ON message_read_receipts (user_id, read_at DESC);
