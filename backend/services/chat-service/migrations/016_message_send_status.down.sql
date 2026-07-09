ALTER TABLE messages
    DROP CONSTRAINT IF EXISTS chk_messages_send_status,
    DROP COLUMN IF EXISTS send_status;

