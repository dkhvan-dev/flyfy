DROP TRIGGER IF EXISTS trg_user_reputation_set_updated_at ON user_reputation;
DROP TRIGGER IF EXISTS trg_user_settings_set_updated_at ON user_settings;
DROP TRIGGER IF EXISTS trg_user_profiles_set_updated_at ON user_profiles;
DROP TRIGGER IF EXISTS trg_users_set_updated_at ON users;

DROP INDEX IF EXISTS idx_user_system_roles_role;
DROP INDEX IF EXISTS idx_user_system_roles_user_id;
DROP INDEX IF EXISTS idx_user_profiles_display_name;
DROP INDEX IF EXISTS idx_users_is_deleted;
DROP INDEX IF EXISTS idx_users_created_at;
DROP INDEX IF EXISTS idx_users_status;
DROP INDEX IF EXISTS uq_user_system_roles_user_role;

DROP TABLE IF EXISTS user_reputation;
DROP TABLE IF EXISTS user_system_roles;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;