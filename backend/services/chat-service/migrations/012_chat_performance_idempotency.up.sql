ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS client_message_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS uq_messages_client_message_id
    ON messages (conversation_id, sender_user_id, client_message_id)
    WHERE client_message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_messages_conversation_sent_id_desc
    ON messages (conversation_id, sent_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_sent_id_asc
    ON messages (conversation_id, sent_at ASC, id ASC);

CREATE INDEX IF NOT EXISTS idx_cp_active_user_conversation
    ON conversation_participants (user_id, conversation_id)
    WHERE left_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_conversations_last_activity_id_desc
    ON conversations (last_activity_at DESC, id DESC);
