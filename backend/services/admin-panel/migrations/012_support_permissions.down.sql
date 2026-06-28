DELETE FROM staff_role_permissions
WHERE permission_code IN (
    'support.read',
    'support.reply',
    'support.manage',
    'help_content.edit',
    'help_content.publish'
)
OR role_code IN (
    'SUPPORT_AGENT',
    'SUPPORT_LEAD',
    'SUPPORT_ADMIN',
    'HELP_CONTENT_EDITOR',
    'HELP_CONTENT_PUBLISHER'
);

DELETE FROM staff_permissions
WHERE code IN (
    'support.read',
    'support.reply',
    'support.manage',
    'help_content.edit',
    'help_content.publish'
);

DELETE FROM staff_roles
WHERE code IN (
    'SUPPORT_AGENT',
    'SUPPORT_LEAD',
    'SUPPORT_ADMIN',
    'HELP_CONTENT_EDITOR',
    'HELP_CONTENT_PUBLISHER'
);
