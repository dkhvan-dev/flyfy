CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_message_files_message_position
    ON message_files (message_id, position);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_messages_unread_active_conversation_sent_id
    ON messages (conversation_id, sent_at, id)
    WHERE deleted_at IS NULL AND type <> 'system';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cp_active_conversation_joined
    ON conversation_participants (conversation_id, joined_at)
    INCLUDE (id, user_id, role, last_read_msg_id, muted_until)
    WHERE left_at IS NULL;
