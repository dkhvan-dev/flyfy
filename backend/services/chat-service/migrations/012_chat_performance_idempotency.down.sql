DROP INDEX IF EXISTS idx_conversations_last_activity_id_desc;
DROP INDEX IF EXISTS idx_cp_active_user_conversation;
DROP INDEX IF EXISTS idx_messages_conversation_sent_id_asc;
DROP INDEX IF EXISTS idx_messages_conversation_sent_id_desc;
DROP INDEX IF EXISTS uq_messages_client_message_id;

ALTER TABLE messages
    DROP COLUMN IF EXISTS client_message_id;
