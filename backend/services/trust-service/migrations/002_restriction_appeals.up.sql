CREATE TABLE IF NOT EXISTS restriction_appeals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    restriction_id UUID NOT NULL REFERENCES runtime_restrictions(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    reason_code TEXT NOT NULL,
    user_message TEXT NOT NULL,
    idempotency_key TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    decided_at TIMESTAMPTZ NULL,
    decided_by_staff_id UUID NULL,
    decision_reason_code TEXT NOT NULL DEFAULT '',
    staff_comment TEXT NOT NULL DEFAULT '',
    CONSTRAINT restriction_appeals_status_check CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE UNIQUE INDEX IF NOT EXISTS restriction_appeals_idempotency_idx
    ON restriction_appeals(user_id, restriction_id, idempotency_key)
    WHERE idempotency_key <> '';

CREATE INDEX IF NOT EXISTS restriction_appeals_user_status_created_idx
    ON restriction_appeals(user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS restriction_appeals_restriction_created_idx
    ON restriction_appeals(restriction_id, created_at DESC);
