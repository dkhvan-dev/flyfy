CREATE TABLE IF NOT EXISTS chat_notification_outbox (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(32) NOT NULL,
    conversation_id UUID        NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    message_id      UUID        NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    actor_user_id   UUID        NOT NULL,
    reaction_emoji  VARCHAR(32),
    attempts        INTEGER     NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    locked_at       TIMESTAMPTZ,
    processed_at    TIMESTAMPTZ,
    failed_at       TIMESTAMPTZ,
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_notification_outbox_event
    ON chat_notification_outbox (
        event_type,
        conversation_id,
        message_id,
        actor_user_id,
        COALESCE(reaction_emoji, '')
    );

CREATE INDEX IF NOT EXISTS idx_chat_notification_outbox_due
    ON chat_notification_outbox (next_attempt_at, created_at)
    WHERE processed_at IS NULL AND failed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_notification_outbox_message
    ON chat_notification_outbox (message_id);
