DROP INDEX IF EXISTS idx_notification_device_tokens_installation;
DROP INDEX IF EXISTS idx_notification_device_tokens_active_session;

ALTER TABLE notification_device_tokens
    DROP COLUMN IF EXISTS device_installation_id,
    DROP COLUMN IF EXISTS session_id;
