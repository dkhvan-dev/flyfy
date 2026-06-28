INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('SUPPORT_AGENT', 'Support agent', 'Can read support tickets and reply to users', TRUE),
    ('SUPPORT_LEAD', 'Support lead', 'Can manage support assignments and ticket lifecycle', TRUE),
    ('SUPPORT_ADMIN', 'Support admin', 'Can manage support operations and help content publishing', TRUE),
    ('HELP_CONTENT_EDITOR', 'Help content editor', 'Can edit Help Center articles and translations', TRUE),
    ('HELP_CONTENT_PUBLISHER', 'Help content publisher', 'Can publish Help Center articles', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system;

INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('support.read', 'support', 'read', 'Read support inbox and tickets'),
    ('support.reply', 'support', 'reply', 'Reply to support tickets and add internal notes'),
    ('support.manage', 'support', 'manage', 'Assign, resolve and reopen support tickets'),
    ('help_content.edit', 'help_content', 'edit', 'Create and edit Help Center articles'),
    ('help_content.publish', 'help_content', 'publish', 'Publish Help Center articles')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('SUPER_ADMIN', 'support.read'),
    ('SUPER_ADMIN', 'support.reply'),
    ('SUPER_ADMIN', 'support.manage'),
    ('SUPER_ADMIN', 'help_content.edit'),
    ('SUPER_ADMIN', 'help_content.publish'),
    ('ADMIN', 'support.read'),
    ('SUPPORT_VIEWER', 'support.read'),
    ('SUPPORT_AGENT', 'dashboard.read'),
    ('SUPPORT_AGENT', 'support.read'),
    ('SUPPORT_AGENT', 'support.reply'),
    ('SUPPORT_LEAD', 'dashboard.read'),
    ('SUPPORT_LEAD', 'support.read'),
    ('SUPPORT_LEAD', 'support.reply'),
    ('SUPPORT_LEAD', 'support.manage'),
    ('SUPPORT_ADMIN', 'dashboard.read'),
    ('SUPPORT_ADMIN', 'support.read'),
    ('SUPPORT_ADMIN', 'support.reply'),
    ('SUPPORT_ADMIN', 'support.manage'),
    ('SUPPORT_ADMIN', 'help_content.edit'),
    ('SUPPORT_ADMIN', 'help_content.publish'),
    ('HELP_CONTENT_EDITOR', 'dashboard.read'),
    ('HELP_CONTENT_EDITOR', 'help_content.edit'),
    ('HELP_CONTENT_PUBLISHER', 'dashboard.read'),
    ('HELP_CONTENT_PUBLISHER', 'help_content.edit'),
    ('HELP_CONTENT_PUBLISHER', 'help_content.publish')
ON CONFLICT DO NOTHING;
