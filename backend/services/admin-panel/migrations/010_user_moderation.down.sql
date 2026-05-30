DELETE FROM staff_role_permissions
WHERE permission_code IN (
    'users.read',
    'users.moderate',
    'users.restrict',
    'users.sensitive.read'
);

DELETE FROM staff_permissions
WHERE code IN (
    'users.read',
    'users.moderate',
    'users.restrict',
    'users.sensitive.read'
);

DROP TABLE IF EXISTS user_manual_restrictions;
DROP TABLE IF EXISTS user_moderation_case_events;
DROP TABLE IF EXISTS user_moderation_cases;
