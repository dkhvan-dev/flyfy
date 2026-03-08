CREATE TABLE IF NOT EXISTS file_bindings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID NOT NULL REFERENCES files(id),
    owner_type VARCHAR(64) NOT NULL,
    owner_id UUID NOT NULL,
    purpose VARCHAR(64) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    created_by_user_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_file_bindings_file_id
    ON file_bindings(file_id);

CREATE INDEX IF NOT EXISTS idx_file_bindings_owner
    ON file_bindings(owner_type, owner_id);

CREATE INDEX IF NOT EXISTS idx_file_bindings_owner_purpose
    ON file_bindings(owner_type, owner_id, purpose);

CREATE UNIQUE INDEX IF NOT EXISTS uq_file_bindings_live_unique
    ON file_bindings(file_id, owner_type, owner_id, purpose)
    WHERE is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS uq_file_bindings_live_primary
    ON file_bindings(owner_type, owner_id, purpose)
    WHERE is_primary = TRUE AND is_deleted = FALSE;

CREATE TABLE IF NOT EXISTS file_idempotency_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation VARCHAR(128) NOT NULL,
    idempotency_key VARCHAR(255) NOT NULL,
    request_fingerprint VARCHAR(128) NOT NULL,

    response_status_code INTEGER,
    response_body JSONB,

    resource_type VARCHAR(64),
    resource_id UUID,

    created_by_user_id UUID,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_file_idempotency_keys_operation_key
    ON file_idempotency_keys(operation, idempotency_key);

CREATE INDEX IF NOT EXISTS idx_file_idempotency_keys_expires_at
    ON file_idempotency_keys(expires_at);

DROP TRIGGER IF EXISTS trg_file_bindings_set_updated_at ON file_bindings;
CREATE TRIGGER trg_file_bindings_set_updated_at
BEFORE UPDATE ON file_bindings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_file_idempotency_keys_set_updated_at ON file_idempotency_keys;
CREATE TRIGGER trg_file_idempotency_keys_set_updated_at
BEFORE UPDATE ON file_idempotency_keys
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();