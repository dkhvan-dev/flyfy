DROP INDEX IF EXISTS idx_messages_forwarded_from;

ALTER TABLE messages
    DROP COLUMN IF EXISTS forward_count,
    DROP COLUMN IF EXISTS forwarded_from_sender_name,
    DROP COLUMN IF EXISTS forwarded_from_sender_user_id,
    DROP COLUMN IF EXISTS forwarded_from_message_id;
