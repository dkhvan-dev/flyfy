CREATE TABLE IF NOT EXISTS message_reactions (
    message_id UUID        NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL,
    emoji      VARCHAR(32) NOT NULL CHECK (length(trim(emoji)) > 0),
    reacted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_reactions_message
    ON message_reactions (message_id, reacted_at DESC);

