CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE notification_device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  provider TEXT NOT NULL CHECK (provider IN ('fcm', 'apns', 'hms')),
  environment TEXT NOT NULL CHECK (environment IN ('sandbox', 'production')),
  app_bundle_id TEXT NOT NULL,
  app_version TEXT NOT NULL DEFAULT '',
  device_model TEXT NOT NULL DEFAULT '',
  manufacturer TEXT NOT NULL DEFAULT '',
  locale TEXT NOT NULL DEFAULT 'en',
  timezone TEXT NOT NULL DEFAULT '',
  token_hash TEXT NOT NULL,
  token_ciphertext TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  invalidated_at TIMESTAMPTZ,
  invalidation_reason TEXT NOT NULL DEFAULT '',
  UNIQUE (provider, environment, token_hash)
);

CREATE INDEX idx_notification_device_tokens_user_active
  ON notification_device_tokens (user_id, provider, environment)
  WHERE enabled = TRUE AND invalidated_at IS NULL;

CREATE TABLE notification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key TEXT NOT NULL,
  source_service TEXT NOT NULL,
  recipient_user_ids UUID[] NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  priority TEXT NOT NULL CHECK (priority IN ('normal', 'high')),
  title TEXT NOT NULL DEFAULT '',
  body TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  deep_link TEXT NOT NULL DEFAULT '',
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  collapse_key TEXT NOT NULL DEFAULT '',
  ttl_seconds BIGINT NOT NULL DEFAULT 86400,
  status TEXT NOT NULL DEFAULT 'accepted',
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fanout_completed_at TIMESTAMPTZ,
  total_deliveries INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX idx_notification_requests_source_idempotency
  ON notification_requests (source_service, idempotency_key);

CREATE INDEX idx_notification_requests_status_scheduled
  ON notification_requests (status, scheduled_at, created_at);

CREATE TABLE notification_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES notification_requests(id) ON DELETE CASCADE,
  device_token_id UUID NOT NULL REFERENCES notification_device_tokens(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  provider TEXT NOT NULL CHECK (provider IN ('fcm', 'apns', 'hms')),
  environment TEXT NOT NULL CHECK (environment IN ('sandbox', 'production')),
  priority TEXT NOT NULL CHECK (priority IN ('normal', 'high')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'succeeded', 'retry_scheduled', 'failed', 'invalid_token')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 8,
  next_attempt_at TIMESTAMPTZ DEFAULT NOW(),
  provider_message_id TEXT NOT NULL DEFAULT '',
  last_error_code TEXT NOT NULL DEFAULT '',
  last_error TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (request_id, device_token_id)
);

CREATE INDEX idx_notification_deliveries_due
  ON notification_deliveries (provider, status, next_attempt_at)
  WHERE status IN ('pending', 'retry_scheduled');

CREATE INDEX idx_notification_deliveries_user_created
  ON notification_deliveries (user_id, created_at DESC);

CREATE TABLE notification_delivery_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES notification_deliveries(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  status TEXT NOT NULL,
  provider_message_id TEXT NOT NULL DEFAULT '',
  error_code TEXT NOT NULL DEFAULT '',
  error_message TEXT NOT NULL DEFAULT '',
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_delivery_attempts_delivery
  ON notification_delivery_attempts (delivery_id, attempted_at DESC);
