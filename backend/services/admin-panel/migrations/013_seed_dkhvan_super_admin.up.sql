INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('SUPER_ADMIN', 'Super admin', 'Full access to staff, audit and moderation', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system;

INSERT INTO staff_role_permissions(role_code, permission_code)
SELECT 'SUPER_ADMIN', code
FROM staff_permissions
ON CONFLICT DO NOTHING;

WITH seeded_staff AS (
    INSERT INTO staff_users (
        id,
        email,
        display_name,
        password_hash,
        status,
        timezone,
        failed_login_count,
        created_at,
        updated_at
    )
    VALUES (
        '95ab5149-33f4-4bb8-b413-51647e65bc16',
        'dkhvan.developer@gmail.com',
        'Denis Khvan',
        '$argon2id$v=19$m=65536,t=3,p=2$W3srmJ61c3cB7A1OoEQzMQ$lOav6cib4hqin/nNgvPIk6UI1i3xczQ4xs535+ae9/E',
        'PASSWORD_RESET_REQUIRED',
        'Asia/Almaty',
        0,
        NOW(),
        NOW()
    )
    ON CONFLICT (LOWER(email)) DO UPDATE
    SET display_name = CASE
            WHEN btrim(staff_users.display_name) = '' OR LOWER(staff_users.display_name) = LOWER(staff_users.email)
                THEN EXCLUDED.display_name
            ELSE staff_users.display_name
        END,
        status = CASE
            WHEN staff_users.status = 'DISABLED' THEN 'PASSWORD_RESET_REQUIRED'
            ELSE staff_users.status
        END,
        timezone = COALESCE(NULLIF(btrim(staff_users.timezone), ''), EXCLUDED.timezone),
        updated_at = NOW()
    RETURNING id
)
INSERT INTO staff_user_roles(staff_user_id, role_code, assigned_by, assigned_at)
SELECT id, 'SUPER_ADMIN', NULL, NOW()
FROM seeded_staff
ON CONFLICT DO NOTHING;
