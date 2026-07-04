UPDATE staff_user_roles
SET revoked_at = NOW()
WHERE staff_user_id = '95ab5149-33f4-4bb8-b413-51647e65bc16'
  AND role_code = 'SUPER_ADMIN'
  AND revoked_at IS NULL;

DELETE FROM staff_users
WHERE id = '95ab5149-33f4-4bb8-b413-51647e65bc16'
  AND LOWER(email) = 'dkhvan.developer@gmail.com'
  AND NOT EXISTS (
      SELECT 1
      FROM staff_sessions
      WHERE staff_sessions.staff_user_id = staff_users.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM audit_log
      WHERE audit_log.actor_staff_id = staff_users.id
         OR audit_log.entity_id = staff_users.id
  );
