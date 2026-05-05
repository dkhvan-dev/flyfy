CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key TEXT NOT NULL UNIQUE,

    subject_type VARCHAR(40) NOT NULL,
    subject_id UUID NOT NULL,
    purpose VARCHAR(50) NOT NULL,

    payer_user_id UUID NOT NULL,
    requested_by_user_id UUID NULL,

    operation_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    provider VARCHAR(20) NOT NULL,

    provider_transaction_id TEXT NULL,
    parent_transaction_id UUID NULL REFERENCES payment_transactions(id),

    amount_minor BIGINT NOT NULL,
    currency CHAR(3) NOT NULL,
    description TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    failure_code TEXT NULL,
    failure_message TEXT NULL,
    completed_at TIMESTAMPTZ NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_payment_transactions_subject_type
        CHECK (subject_type ~ '^[A-Z][A-Z0-9_]{1,39}$'),

    CONSTRAINT chk_payment_transactions_purpose
        CHECK (purpose ~ '^[A-Z][A-Z0-9_]{1,49}$'),

    CONSTRAINT chk_payment_transactions_operation_type
        CHECK (operation_type IN ('AUTHORIZE', 'CHARGE', 'CAPTURE', 'REFUND', 'VOID')),

    CONSTRAINT chk_payment_transactions_status
        CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),

    CONSTRAINT chk_payment_transactions_provider
        CHECK (provider IN ('MOCK')),

    CONSTRAINT chk_payment_transactions_amount
        CHECK (amount_minor >= 0),

    CONSTRAINT chk_payment_transactions_currency
        CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_subject
    ON payment_transactions(subject_type, subject_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_payer
    ON payment_transactions(payer_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_parent
    ON payment_transactions(parent_transaction_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_status
    ON payment_transactions(status, created_at DESC);

CREATE TABLE IF NOT EXISTS payment_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
    event_type VARCHAR(80) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_events_transaction
    ON payment_events(transaction_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_payment_events_type
    ON payment_events(event_type, created_at DESC);
