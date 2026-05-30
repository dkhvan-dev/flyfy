DROP INDEX IF EXISTS idx_notification_user_reads_user_read_at;
DROP INDEX IF EXISTS idx_notification_requests_category_created;
DROP INDEX IF EXISTS idx_notification_requests_recipient_user_ids_gin;

DROP TABLE IF EXISTS notification_user_reads;
