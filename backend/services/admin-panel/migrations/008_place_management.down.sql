DELETE FROM staff_role_permissions
WHERE permission_code = 'place.manage';

DELETE FROM staff_permissions
WHERE code = 'place.manage';
