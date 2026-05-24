DELETE FROM staff_role_permissions
WHERE role_code = 'ADMIN';

UPDATE staff_user_roles
SET revoked_at = NOW()
WHERE role_code = 'ADMIN'
  AND revoked_at IS NULL;

DELETE FROM staff_roles
WHERE code = 'ADMIN';
