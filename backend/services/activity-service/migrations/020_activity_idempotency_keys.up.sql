CREATE TABLE IF NOT EXISTS activity_idempotency_keys (
    key text PRIMARY KEY,
    source_service text NOT NULL,
    source_resource_type text DEFAULT 'post' NOT NULL,
    source_resource_id text NOT NULL,
    host_user_id uuid NOT NULL,
    request_hash text NOT NULL,
    activity_id uuid REFERENCES activities(id) ON DELETE SET NULL,
    status text DEFAULT 'IN_PROGRESS' NOT NULL,
    last_error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT chk_activity_idempotency_keys_status CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED')),
    CONSTRAINT chk_activity_idempotency_keys_source CHECK (btrim(source_service) <> '' AND btrim(source_resource_type) <> '' AND btrim(source_resource_id) <> ''),
    CONSTRAINT chk_activity_idempotency_keys_request_hash CHECK (btrim(request_hash) <> '')
);

CREATE INDEX IF NOT EXISTS idx_activity_idempotency_keys_activity
    ON activity_idempotency_keys(activity_id)
    WHERE activity_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_activity_idempotency_keys_source
    ON activity_idempotency_keys(source_service, source_resource_type, source_resource_id);
