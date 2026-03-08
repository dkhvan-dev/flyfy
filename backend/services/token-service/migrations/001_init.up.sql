-- 001_init.up.sql
-- Token Service Schema
-- PostgreSQL 16+

BEGIN;

-- Service accounts table
CREATE TABLE IF NOT EXISTS service_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id      VARCHAR(64) UNIQUE NOT NULL,
    service_secret  VARCHAR(256) NOT NULL,  -- bcrypt hash
    display_name    VARCHAR(128),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Service roles / permissions
CREATE TABLE IF NOT EXISTS service_roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES service_accounts(id) ON DELETE CASCADE,
    role            VARCHAR(64) NOT NULL,
    granted_at      TIMESTAMPTZ DEFAULT now(),
    granted_by      VARCHAR(64) DEFAULT 'system',
    UNIQUE(account_id, role)
);

CREATE INDEX idx_service_roles_account ON service_roles(account_id);

-- Audit log for inter-service auth events
CREATE TABLE IF NOT EXISTS service_auth_audit (
    id              BIGSERIAL PRIMARY KEY,
    caller_id       VARCHAR(64) NOT NULL,
    target_action   VARCHAR(128) NOT NULL,
    result          VARCHAR(16) NOT NULL,  -- 'granted' | 'denied' | 'not_found' | 'inactive' | 'bad_credentials'
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_caller     ON service_auth_audit(caller_id, created_at DESC);
CREATE INDEX idx_audit_denied     ON service_auth_audit(result) WHERE result = 'denied';
CREATE INDEX idx_audit_created    ON service_auth_audit(created_at DESC);

-- Key metadata (for tracking rotation history)
CREATE TABLE IF NOT EXISTS signing_keys (
    id              VARCHAR(32) PRIMARY KEY,
    algorithm       VARCHAR(16) NOT NULL DEFAULT 'RS256',
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now(),
    rotated_at      TIMESTAMPTZ
);

CREATE INDEX idx_keys_active ON signing_keys(is_active) WHERE is_active = true;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_service_accounts_updated
    BEFORE UPDATE ON service_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================
-- Seed: initial service accounts for development
-- Secrets are bcrypt hashes of the service_id + "-secret"
-- e.g. "auth-service-secret" → hash below
-- In production, use vault / proper secret management
-- =============================================================

-- auth-service: orchestrator with full auth roles
INSERT INTO service_accounts (service_id, service_secret, display_name, is_active) VALUES
    ('auth-service',    '$2y$10$dGjmTHXbxEEqaHvNYLU2cuUVXHHHtoNJ7XDK/hYxD5MC617nvsF4.%', 'Auth Service Orchestrator', true),
    ('api-gateway',     '$2a$10$placeholder.hash.api.gateway',  'API Gateway',               true),
    ('otp-service',     '$2a$10$placeholder.hash.otp.service',  'OTP Service',               true),
    ('user-service',    '$2a$10$placeholder.hash.user.service', 'User Service',              true)
ON CONFLICT (service_id) DO NOTHING;

-- Assign roles
-- auth-service: max privileges for auth orchestration
INSERT INTO service_roles (account_id, role) 
SELECT sa.id, r.role FROM service_accounts sa
CROSS JOIN (VALUES 
    ('otp:send'), ('otp:verify'), 
    ('token:generate'), ('token:validate'), ('token:revoke'),
    ('user:create'), ('user:read')
) AS r(role)
WHERE sa.service_id = 'auth-service'
ON CONFLICT (account_id, role) DO NOTHING;

-- api-gateway: only validate tokens
INSERT INTO service_roles (account_id, role) 
SELECT sa.id, r.role FROM service_accounts sa
CROSS JOIN (VALUES ('token:validate')) AS r(role)
WHERE sa.service_id = 'api-gateway'
ON CONFLICT (account_id, role) DO NOTHING;

-- otp-service: own operations + sms
INSERT INTO service_roles (account_id, role) 
SELECT sa.id, r.role FROM service_accounts sa
CROSS JOIN (VALUES ('otp:send'), ('otp:verify'), ('sms:send')) AS r(role)
WHERE sa.service_id = 'otp-service'
ON CONFLICT (account_id, role) DO NOTHING;

-- user-service
INSERT INTO service_roles (account_id, role) 
SELECT sa.id, r.role FROM service_accounts sa
CROSS JOIN (VALUES ('user:read'), ('user:write'), ('token:validate')) AS r(role)
WHERE sa.service_id = 'user-service'
ON CONFLICT (account_id, role) DO NOTHING;

COMMIT;