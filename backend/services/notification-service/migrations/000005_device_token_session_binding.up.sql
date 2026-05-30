ALTER TABLE notification_device_tokens
    ADD COLUMN session_id TEXT NOT NULL DEFAULT '',
    ADD COLUMN device_installation_id TEXT NOT NULL DEFAULT '';

CREATE INDEX idx_notification_device_tokens_active_session
    ON notification_device_tokens (user_id, session_id)
    WHERE enabled = true
      AND invalidated_at IS NULL
      AND session_id <> '';

CREATE INDEX idx_notification_device_tokens_installation
    ON notification_device_tokens (user_id, device_installation_id)
    WHERE device_installation_id <> '';
