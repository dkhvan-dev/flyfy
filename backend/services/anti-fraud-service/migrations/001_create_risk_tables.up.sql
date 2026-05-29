CREATE TABLE IF NOT EXISTS risk_events (
    id UUID PRIMARY KEY,
    action VARCHAR(80) NOT NULL,
    actor_user_id UUID,
    subject_type VARCHAR(80) NOT NULL DEFAULT '',
    subject_id UUID,
    source_service VARCHAR(80) NOT NULL DEFAULT '',
    idempotency_key VARCHAR(160) NOT NULL DEFAULT '',
    amount_minor BIGINT,
    currency CHAR(3) NOT NULL DEFAULT '',
    signal_hashes JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_risk_events_action_created_at
    ON risk_events (action, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_risk_events_actor_action_created_at
    ON risk_events (actor_user_id, action, created_at DESC)
    WHERE actor_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_risk_events_subject_created_at
    ON risk_events (subject_type, subject_id, created_at DESC)
    WHERE subject_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_risk_events_signal_hashes_gin
    ON risk_events USING GIN (signal_hashes);

CREATE INDEX IF NOT EXISTS idx_risk_events_phone_signal_created_at
    ON risk_events (action, (signal_hashes ->> 'phone'), created_at DESC)
    WHERE signal_hashes ? 'phone';

CREATE INDEX IF NOT EXISTS idx_risk_events_ip_signal_created_at
    ON risk_events (action, (signal_hashes ->> 'ip'), created_at DESC)
    WHERE signal_hashes ? 'ip';

CREATE INDEX IF NOT EXISTS idx_risk_events_device_signal_created_at
    ON risk_events (action, (signal_hashes ->> 'device'), created_at DESC)
    WHERE signal_hashes ? 'device';

CREATE TABLE IF NOT EXISTS risk_assessments (
    id UUID PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES risk_events(id) ON DELETE CASCADE,
    action VARCHAR(80) NOT NULL,
    actor_user_id UUID,
    subject_type VARCHAR(80) NOT NULL DEFAULT '',
    subject_id UUID,
    decision VARCHAR(24) NOT NULL,
    risk_score INTEGER NOT NULL DEFAULT 0,
    reasons TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    policy_version VARCHAR(80) NOT NULL,
    shadow_mode BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT risk_assessments_decision_chk
        CHECK (decision IN ('ALLOW', 'CHALLENGE', 'REVIEW', 'BLOCK')),
    CONSTRAINT risk_assessments_score_chk
        CHECK (risk_score >= 0 AND risk_score <= 100)
);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_decision_created_at
    ON risk_assessments (decision, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_actor_created_at
    ON risk_assessments (actor_user_id, created_at DESC)
    WHERE actor_user_id IS NOT NULL;
