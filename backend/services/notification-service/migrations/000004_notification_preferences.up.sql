CREATE TABLE notification_preferences (
  user_id UUID PRIMARY KEY,
  push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  activity_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  excursion_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  chat_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  marketing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_start_minutes INTEGER NOT NULL DEFAULT 1320
    CHECK (quiet_hours_start_minutes >= 0 AND quiet_hours_start_minutes < 1440),
  quiet_hours_end_minutes INTEGER NOT NULL DEFAULT 480
    CHECK (quiet_hours_end_minutes >= 0 AND quiet_hours_end_minutes < 1440),
  timezone TEXT NOT NULL DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_preferences_push_enabled
  ON notification_preferences (push_enabled)
  WHERE push_enabled = TRUE;
