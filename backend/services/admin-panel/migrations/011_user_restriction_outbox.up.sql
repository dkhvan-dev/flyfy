CREATE TABLE IF NOT EXISTS user_restriction_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    aggregate_id UUID NOT NULL,
    user_id UUID NOT NULL,
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at TIMESTAMPTZ NULL,
    CONSTRAINT user_restriction_outbox_event_type_check CHECK (event_type IN ('USER_RESTRICTION_CREATED', 'USER_RESTRICTION_LIFTED')),
    CONSTRAINT user_restriction_outbox_status_check CHECK (status IN ('PENDING', 'DELIVERED', 'DEAD'))
);

CREATE INDEX IF NOT EXISTS user_restriction_outbox_due_idx
    ON user_restriction_outbox(status, next_attempt_at, created_at);

CREATE INDEX IF NOT EXISTS user_restriction_outbox_user_created_idx
    ON user_restriction_outbox(user_id, created_at DESC);
