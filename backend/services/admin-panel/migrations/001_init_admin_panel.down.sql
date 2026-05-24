DROP TRIGGER IF EXISTS trg_audit_log_no_update ON audit_log;
DROP FUNCTION IF EXISTS prevent_audit_log_mutation();

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS moderation_decisions;
DROP TABLE IF EXISTS moderation_cases;
DROP TABLE IF EXISTS staff_login_attempts;
DROP TABLE IF EXISTS staff_sessions;
DROP TABLE IF EXISTS staff_user_roles;
DROP TABLE IF EXISTS staff_role_permissions;
DROP TABLE IF EXISTS staff_permissions;
DROP TABLE IF EXISTS staff_roles;
DROP TABLE IF EXISTS staff_users;
