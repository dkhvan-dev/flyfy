CREATE TABLE IF NOT EXISTS staff_users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PASSWORD_RESET_REQUIRED',
    timezone TEXT NOT NULL DEFAULT 'Asia/Almaty',
    failed_login_count INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ NULL,
    last_login_at TIMESTAMPTZ NULL,
    password_changed_at TIMESTAMPTZ NULL,
    created_by_staff_id UUID NULL REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    disabled_at TIMESTAMPTZ NULL,
    CONSTRAINT chk_staff_users_status
        CHECK (status IN ('ACTIVE', 'PASSWORD_RESET_REQUIRED', 'LOCKED', 'DISABLED')),
    CONSTRAINT chk_staff_users_timezone_not_blank
        CHECK (btrim(timezone) <> '')
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staff_users_email_lower
    ON staff_users (LOWER(email));

CREATE INDEX IF NOT EXISTS idx_staff_users_status
    ON staff_users(status, updated_at DESC);

CREATE TABLE IF NOT EXISTS staff_roles (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    is_system BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staff_permissions (
    code TEXT PRIMARY KEY,
    domain TEXT NOT NULL,
    action TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staff_role_permissions (
    role_code TEXT NOT NULL REFERENCES staff_roles(code) ON DELETE CASCADE,
    permission_code TEXT NOT NULL REFERENCES staff_permissions(code) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_code, permission_code)
);

CREATE TABLE IF NOT EXISTS staff_user_roles (
    staff_user_id UUID NOT NULL REFERENCES staff_users(id) ON DELETE CASCADE,
    role_code TEXT NOT NULL REFERENCES staff_roles(code) ON DELETE RESTRICT,
    assigned_by UUID NULL REFERENCES staff_users(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staff_user_roles_active
    ON staff_user_roles(staff_user_id, role_code)
    WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS staff_sessions (
    id UUID PRIMARY KEY,
    staff_user_id UUID NOT NULL REFERENCES staff_users(id) ON DELETE CASCADE,
    session_hash TEXT NOT NULL UNIQUE,
    csrf_token_hash TEXT NOT NULL,
    ip_address_hash TEXT NOT NULL DEFAULT '',
    user_agent_hash TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    absolute_expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_staff_sessions_staff_active
    ON staff_sessions(staff_user_id, expires_at DESC)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_staff_sessions_expires
    ON staff_sessions(expires_at);

CREATE TABLE IF NOT EXISTS staff_login_attempts (
    id UUID PRIMARY KEY,
    email_hash TEXT NOT NULL DEFAULT '',
    ip_address_hash TEXT NOT NULL DEFAULT '',
    success BOOLEAN NOT NULL DEFAULT FALSE,
    failure_reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_login_attempts_email_time
    ON staff_login_attempts(email_hash, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_staff_login_attempts_ip_time
    ON staff_login_attempts(ip_address_hash, created_at DESC);

CREATE TABLE IF NOT EXISTS moderation_cases (
    id UUID PRIMARY KEY,
    target_type TEXT NOT NULL,
    target_id UUID NOT NULL,
    source_service TEXT NOT NULL,
    source_revision INT NOT NULL,
    status TEXT NOT NULL,
    priority INT NOT NULL DEFAULT 0,
    reason TEXT NOT NULL DEFAULT '',
    snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    assigned_admin_id UUID NULL REFERENCES staff_users(id),
    opened_by UUID NULL REFERENCES staff_users(id),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_at TIMESTAMPTZ NULL,
    resolved_at TIMESTAMPTZ NULL,
    lock_version INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_moderation_cases_target_type
        CHECK (target_type IN ('EXCURSION', 'ACTIVITY', 'CHAT_MESSAGE', 'STORY')),
    CONSTRAINT chk_moderation_cases_status
        CHECK (status IN ('OPEN', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'CHANGES_REQUESTED', 'ESCALATED', 'CANCELLED'))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_moderation_cases_active_revision
    ON moderation_cases(target_type, target_id, source_revision)
    WHERE status IN ('OPEN', 'IN_REVIEW', 'ESCALATED');

CREATE INDEX IF NOT EXISTS idx_moderation_cases_queue
    ON moderation_cases(status, priority DESC, due_at ASC, opened_at ASC)
    WHERE status IN ('OPEN', 'IN_REVIEW', 'ESCALATED');

CREATE INDEX IF NOT EXISTS idx_moderation_cases_assignee
    ON moderation_cases(assigned_admin_id, status, updated_at DESC)
    WHERE assigned_admin_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_moderation_cases_target
    ON moderation_cases(target_type, target_id, source_revision DESC);

CREATE TABLE IF NOT EXISTS moderation_decisions (
    id UUID PRIMARY KEY,
    case_id UUID NOT NULL REFERENCES moderation_cases(id) ON DELETE CASCADE,
    decision_type TEXT NOT NULL,
    source_revision INT NOT NULL,
    reason_codes TEXT[] NOT NULL DEFAULT '{}',
    public_comment TEXT NOT NULL DEFAULT '',
    internal_comment TEXT NOT NULL DEFAULT '',
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    idempotency_key TEXT NOT NULL UNIQUE,
    decided_by UUID NOT NULL REFERENCES staff_users(id),
    apply_status TEXT NOT NULL DEFAULT 'PENDING',
    applied_at TIMESTAMPTZ NULL,
    source_response JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_moderation_decisions_type
        CHECK (decision_type IN ('APPROVE', 'REJECT', 'REQUEST_CHANGES', 'ESCALATE')),
    CONSTRAINT chk_moderation_decisions_apply_status
        CHECK (apply_status IN ('PENDING', 'APPLIED', 'FAILED'))
);

CREATE INDEX IF NOT EXISTS idx_moderation_decisions_case_created
    ON moderation_decisions(case_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS ux_moderation_decisions_case_revision_active
    ON moderation_decisions(case_id, source_revision)
    WHERE apply_status IN ('PENDING', 'APPLIED');

CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY,
    actor_staff_id UUID NULL REFERENCES staff_users(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID NULL,
    request_id TEXT NOT NULL DEFAULT '',
    ip_address_hash TEXT NOT NULL DEFAULT '',
    user_agent_hash TEXT NOT NULL DEFAULT '',
    before_json JSONB NULL,
    after_json JSONB NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_actor_time
    ON audit_log(actor_staff_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_log_entity_time
    ON audit_log(entity_type, entity_id, created_at DESC);

CREATE OR REPLACE FUNCTION prevent_audit_log_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is append-only';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_log_no_update ON audit_log;
CREATE TRIGGER trg_audit_log_no_update
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('SUPER_ADMIN', 'Super admin', 'Full access to staff, audit and moderation', TRUE),
    ('MODERATION_LEAD', 'Moderation lead', 'Can manage moderation queues and decisions', TRUE),
    ('EXCURSION_MODERATOR', 'Excursion moderator', 'Can review and decide excursion moderation cases', TRUE),
    ('ACTIVITY_MODERATOR', 'Activity moderator', 'Can review activity moderation cases', TRUE),
    ('CHAT_MODERATOR', 'Chat moderator', 'Can review chat moderation cases', TRUE),
    ('SUPPORT_VIEWER', 'Support viewer', 'Can read dashboard and moderation queues', TRUE),
    ('READ_ONLY_AUDITOR', 'Read-only auditor', 'Can read audit logs', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system;

INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('dashboard.read', 'dashboard', 'read', 'Read admin dashboard'),
    ('staff.manage', 'staff', 'manage', 'Create and manage staff users'),
    ('audit.read', 'audit', 'read', 'Read audit log'),
    ('moderation.read', 'moderation', 'read', 'Read moderation queues and cases'),
    ('moderation.assign', 'moderation', 'assign', 'Assign moderation cases'),
    ('excursion.moderate', 'excursion', 'moderate', 'Approve or reject excursion cases'),
    ('activity.moderate', 'activity', 'moderate', 'Approve or reject activity cases'),
    ('chat.moderate', 'chat', 'moderate', 'Moderate chat cases'),
    ('attraction.manage', 'attraction', 'manage', 'Create and edit attraction content')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code)
SELECT 'SUPER_ADMIN', code FROM staff_permissions
ON CONFLICT DO NOTHING;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('MODERATION_LEAD', 'dashboard.read'),
    ('MODERATION_LEAD', 'moderation.read'),
    ('MODERATION_LEAD', 'moderation.assign'),
    ('MODERATION_LEAD', 'excursion.moderate'),
    ('MODERATION_LEAD', 'activity.moderate'),
    ('MODERATION_LEAD', 'chat.moderate'),
    ('EXCURSION_MODERATOR', 'dashboard.read'),
    ('EXCURSION_MODERATOR', 'moderation.read'),
    ('EXCURSION_MODERATOR', 'excursion.moderate'),
    ('ACTIVITY_MODERATOR', 'dashboard.read'),
    ('ACTIVITY_MODERATOR', 'moderation.read'),
    ('ACTIVITY_MODERATOR', 'activity.moderate'),
    ('CHAT_MODERATOR', 'dashboard.read'),
    ('CHAT_MODERATOR', 'moderation.read'),
    ('CHAT_MODERATOR', 'chat.moderate'),
    ('SUPPORT_VIEWER', 'dashboard.read'),
    ('SUPPORT_VIEWER', 'moderation.read'),
    ('READ_ONLY_AUDITOR', 'dashboard.read'),
    ('READ_ONLY_AUDITOR', 'audit.read')
ON CONFLICT DO NOTHING;
