CREATE TABLE notification_user_reads (
  user_id UUID NOT NULL,
  request_id UUID NOT NULL REFERENCES notification_requests(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, request_id)
);

CREATE INDEX idx_notification_requests_recipient_user_ids_gin
  ON notification_requests USING GIN (recipient_user_ids);

CREATE INDEX idx_notification_requests_category_created
  ON notification_requests (
    (COALESCE(NULLIF(BTRIM(category), ''), 'general')),
    created_at DESC,
    id DESC
  );

CREATE INDEX idx_notification_user_reads_user_read_at
  ON notification_user_reads (user_id, read_at DESC);
