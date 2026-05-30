DROP INDEX IF EXISTS policy_decisions_idempotency_idx;
DROP INDEX IF EXISTS policy_decisions_user_created_idx;
DROP INDEX IF EXISTS runtime_restrictions_user_created_idx;
DROP INDEX IF EXISTS runtime_restrictions_user_active_idx;

DROP TABLE IF EXISTS policy_decisions;
DROP TABLE IF EXISTS trust_events;
DROP TABLE IF EXISTS processed_trust_events;
DROP TABLE IF EXISTS runtime_restrictions;
DROP TABLE IF EXISTS trust_profiles;
