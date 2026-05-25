DELETE FROM staff_role_permissions
WHERE permission_code = 'attraction.manage';

DELETE FROM staff_permissions
WHERE code = 'attraction.manage';
