INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('attraction.manage', 'attraction', 'manage', 'Create and edit attraction content')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('SUPER_ADMIN', 'attraction.manage'),
    ('ADMIN', 'attraction.manage')
ON CONFLICT DO NOTHING;
