INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('place.manage', 'place', 'manage', 'Create and edit place content')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('SUPER_ADMIN', 'place.manage'),
    ('ADMIN', 'place.manage')
ON CONFLICT DO NOTHING;
