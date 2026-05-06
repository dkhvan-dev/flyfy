-- 002_user_sessions.down.sql

BEGIN;

DROP TABLE IF EXISTS user_session_audit;
DROP TABLE IF EXISTS refresh_token_history;
DROP TABLE IF EXISTS user_sessions;

COMMIT;
