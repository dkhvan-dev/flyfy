CREATE TABLE IF NOT EXISTS user_moderation_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_user_id UUID NOT NULL,
    source TEXT NOT NULL,
    reason_code TEXT NOT NULL,
    priority TEXT NOT NULL,
    status TEXT NOT NULL,
    assigned_staff_id UUID NULL REFERENCES staff_users(id),
    decision TEXT NULL,
    staff_comment TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ NULL,
    CONSTRAINT user_moderation_cases_source_check
        CHECK (source IN ('STAFF', 'REPORT', 'FRAUD', 'PAYMENT', 'GUIDE_VERIFICATION', 'FILE_SCAN', 'SYSTEM')),
    CONSTRAINT user_moderation_cases_priority_check
        CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL')),
    CONSTRAINT user_moderation_cases_status_check
        CHECK (status IN ('OPEN', 'IN_REVIEW', 'WAITING_USER', 'ESCALATED', 'RESOLVED', 'DISMISSED')),
    CONSTRAINT user_moderation_cases_decision_check
        CHECK (decision IS NULL OR decision IN (
            'NO_ACTION',
            'INTERNAL_NOTE',
            'WARNING',
            'REQUEST_VERIFICATION',
            'RESTRICT',
            'SUSPEND',
            'PERMANENT_BLOCK',
            'REMOVE_RESTRICTION',
            'ESCALATE'
        ))
);

CREATE TABLE IF NOT EXISTS user_moderation_case_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES user_moderation_cases(id) ON DELETE CASCADE,
    actor_staff_id UUID NOT NULL REFERENCES staff_users(id),
    event_type TEXT NOT NULL,
    from_status TEXT NULL,
    to_status TEXT NULL,
    decision TEXT NULL,
    reason_code TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_manual_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    case_id UUID NULL REFERENCES user_moderation_cases(id) ON DELETE SET NULL,
    restriction_code TEXT NOT NULL,
    status TEXT NOT NULL,
    reason_code TEXT NOT NULL,
    staff_comment TEXT NOT NULL,
    created_by_staff_id UUID NOT NULL REFERENCES staff_users(id),
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    lifted_at TIMESTAMPTZ NULL,
    lifted_by_staff_id UUID NULL REFERENCES staff_users(id),
    CONSTRAINT user_manual_restrictions_status_check
        CHECK (status IN ('ACTIVE', 'LIFTED', 'EXPIRED')),
    CONSTRAINT user_manual_restrictions_code_check
        CHECK (restriction_code IN (
            'CHAT',
            'ACTIVITY_CREATION',
            'TOUR_PUBLISHING',
            'FILE_UPLOAD',
            'PAYOUT',
            'GUIDE_APPLICATION',
            'ACCOUNT_SUSPENSION'
        ))
);

CREATE INDEX IF NOT EXISTS user_moderation_cases_user_status_idx
    ON user_moderation_cases(target_user_id, status);

CREATE INDEX IF NOT EXISTS user_moderation_cases_queue_idx
    ON user_moderation_cases(status, priority, created_at DESC);

CREATE INDEX IF NOT EXISTS user_moderation_case_events_case_created_idx
    ON user_moderation_case_events(case_id, created_at DESC);

CREATE INDEX IF NOT EXISTS user_manual_restrictions_user_status_idx
    ON user_manual_restrictions(user_id, status, expires_at);

INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('users.read', 'users', 'read', 'Read masked application user profiles'),
    ('users.moderate', 'users', 'moderate', 'Create and resolve user moderation cases'),
    ('users.restrict', 'users', 'restrict', 'Create and lift manual user restrictions'),
    ('users.sensitive.read', 'users', 'sensitive.read', 'Reveal sensitive user details with audit')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('ADMIN', 'Admin', 'Operational admin with broad moderation access', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = TRUE;

INSERT INTO staff_role_permissions(role_code, permission_code)
SELECT 'SUPER_ADMIN', code
FROM staff_permissions
WHERE code IN ('users.read', 'users.moderate', 'users.restrict', 'users.sensitive.read')
ON CONFLICT DO NOTHING;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('ADMIN', 'users.read'),
    ('ADMIN', 'users.moderate'),
    ('ADMIN', 'users.restrict'),
    ('ADMIN', 'users.sensitive.read'),
    ('MODERATION_LEAD', 'users.read'),
    ('MODERATION_LEAD', 'users.moderate'),
    ('MODERATION_LEAD', 'users.restrict'),
    ('EXCURSION_MODERATOR', 'users.read'),
    ('EXCURSION_MODERATOR', 'users.moderate'),
    ('ACTIVITY_MODERATOR', 'users.read'),
    ('ACTIVITY_MODERATOR', 'users.moderate'),
    ('GUIDE_MODERATOR', 'users.read'),
    ('GUIDE_MODERATOR', 'users.moderate'),
    ('CHAT_MODERATOR', 'users.read'),
    ('CHAT_MODERATOR', 'users.moderate'),
    ('SUPPORT_VIEWER', 'users.read')
ON CONFLICT DO NOTHING;
