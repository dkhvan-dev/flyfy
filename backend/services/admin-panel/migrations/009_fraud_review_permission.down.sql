DELETE FROM staff_role_permissions
WHERE permission_code = 'fraud.review';

DELETE FROM staff_permissions
WHERE code = 'fraud.review';
