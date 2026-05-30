CREATE TABLE IF NOT EXISTS trust_profiles (
    user_id UUID PRIMARY KEY,
    score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 1000),
    band TEXT NOT NULL,
    status TEXT NOT NULL,
    calculated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT trust_profiles_band_check CHECK (band IN ('NEW', 'LOW', 'NORMAL', 'TRUSTED', 'RISKY', 'BLOCKED')),
    CONSTRAINT trust_profiles_status_check CHECK (status IN ('ACTIVE', 'UNDER_REVIEW', 'RESTRICTED'))
);

CREATE TABLE IF NOT EXISTS runtime_restrictions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    case_id UUID NULL,
    restriction_code TEXT NOT NULL,
    status TEXT NOT NULL,
    reason_code TEXT NOT NULL,
    source_event_id UUID NOT NULL,
    created_by_staff_id UUID NULL,
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL,
    lifted_at TIMESTAMPTZ NULL,
    lifted_by_staff_id UUID NULL,
    CONSTRAINT runtime_restrictions_status_check CHECK (status IN ('ACTIVE', 'LIFTED', 'EXPIRED')),
    CONSTRAINT runtime_restrictions_code_check CHECK (restriction_code IN ('CHAT', 'ACTIVITY_CREATION', 'TOUR_PUBLISHING', 'FILE_UPLOAD', 'PAYOUT', 'GUIDE_APPLICATION', 'ACCOUNT_SUSPENSION'))
);

CREATE TABLE IF NOT EXISTS processed_trust_events (
    event_id UUID PRIMARY KEY,
    event_type TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trust_events (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    source_service TEXT NOT NULL,
    source_id TEXT NOT NULL,
    weight INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS policy_decisions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL DEFAULT '',
    resource_id TEXT NOT NULL DEFAULT '',
    idempotency_key TEXT NOT NULL DEFAULT '',
    decision TEXT NOT NULL,
    reason_code TEXT NOT NULL DEFAULT '',
    public_message_key TEXT NOT NULL DEFAULT '',
    internal_message TEXT NOT NULL DEFAULT '',
    trust_band TEXT NOT NULL,
    score INTEGER NOT NULL,
    restriction_ids UUID[] NOT NULL DEFAULT ARRAY[]::UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT policy_decisions_decision_check CHECK (decision IN ('ALLOW', 'DENY', 'REVIEW', 'QUARANTINE', 'PENDING')),
    CONSTRAINT policy_decisions_action_check CHECK (action IN ('ACTIVITY_CREATE', 'TOUR_PUBLISH', 'CHAT_SEND', 'FILE_UPLOAD', 'FILE_BIND', 'PAYOUT_REQUEST', 'GUIDE_APPLICATION_SUBMIT'))
);

CREATE INDEX IF NOT EXISTS runtime_restrictions_user_active_idx
    ON runtime_restrictions(user_id, status, expires_at);

CREATE INDEX IF NOT EXISTS runtime_restrictions_user_created_idx
    ON runtime_restrictions(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS policy_decisions_user_created_idx
    ON policy_decisions(user_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS policy_decisions_idempotency_idx
    ON policy_decisions(user_id, action, idempotency_key)
    WHERE idempotency_key <> '';
