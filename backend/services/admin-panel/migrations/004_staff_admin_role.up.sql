INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('ADMIN', 'Admin', 'Can manage non-superadmin staff accounts', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('ADMIN', 'dashboard.read'),
    ('ADMIN', 'staff.manage')
ON CONFLICT DO NOTHING;
