CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS conversations (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type             VARCHAR(10)  NOT NULL CHECK (type IN ('group', 'direct')),
    title            VARCHAR(255),
    avatar_file_id   VARCHAR(255),
    activity_id      UUID,
    excursion_schedule_slot_id UUID,
    pinned_message_id UUID,
    messaging_available_until TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_activity_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_conversations_activity_id ON conversations (activity_id) WHERE activity_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_excursion_schedule_slot_id ON conversations (excursion_schedule_slot_id) WHERE excursion_schedule_slot_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_excursion_schedule_slot_id ON conversations (excursion_schedule_slot_id) WHERE excursion_schedule_slot_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_type ON conversations (type);

CREATE TABLE IF NOT EXISTS conversation_participants (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id  UUID         NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    user_id          UUID         NOT NULL,
    role             VARCHAR(20)  NOT NULL CHECK (role IN ('member', 'admin')),
    last_read_msg_id UUID,
    muted_until      TIMESTAMPTZ,
    joined_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    left_at          TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_cp_active ON conversation_participants (conversation_id, user_id) WHERE left_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_cp_user_id ON conversation_participants (user_id, left_at);
CREATE INDEX IF NOT EXISTS idx_cp_user_conversations ON conversation_participants (user_id, left_at) INCLUDE (conversation_id);

CREATE TABLE IF NOT EXISTS messages (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id      UUID         NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    sender_user_id       UUID         NOT NULL,
    type                 VARCHAR(20)  NOT NULL CHECK (type IN ('text', 'file', 'system')),
    content              TEXT         NOT NULL,
    reply_to_message_id  UUID,
    edited_at            TIMESTAMPTZ,
    deleted_at           TIMESTAMPTZ,
    sent_at              TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_sent ON messages (conversation_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id_desc ON messages (conversation_id, id DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages (sender_user_id);

ALTER TABLE IF EXISTS conversations
    DROP CONSTRAINT IF EXISTS fk_conversations_pinned_message;

ALTER TABLE IF EXISTS conversations
    ADD CONSTRAINT fk_conversations_pinned_message
    FOREIGN KEY (pinned_message_id) REFERENCES messages (id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS message_files (
    message_id UUID         NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    file_id    VARCHAR(255) NOT NULL,
    position   SMALLINT     NOT NULL DEFAULT 0,
    PRIMARY KEY (message_id, file_id)
);
