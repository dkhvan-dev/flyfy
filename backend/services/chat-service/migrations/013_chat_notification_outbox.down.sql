DROP INDEX IF EXISTS idx_chat_notification_outbox_message;
DROP INDEX IF EXISTS idx_chat_notification_outbox_due;
DROP INDEX IF EXISTS uq_chat_notification_outbox_event;

DROP TABLE IF EXISTS chat_notification_outbox;
