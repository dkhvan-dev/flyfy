DROP TRIGGER IF EXISTS trg_file_idempotency_keys_set_updated_at ON file_idempotency_keys;
DROP TRIGGER IF EXISTS trg_file_bindings_set_updated_at ON file_bindings;

DROP INDEX IF EXISTS uq_file_idempotency_keys_operation_key;
DROP INDEX IF EXISTS idx_file_idempotency_keys_expires_at;

DROP TABLE IF EXISTS file_idempotency_keys;

DROP INDEX IF EXISTS uq_file_bindings_live_primary;
DROP INDEX IF EXISTS uq_file_bindings_live_unique;
DROP INDEX IF EXISTS idx_file_bindings_owner_purpose;
DROP INDEX IF EXISTS idx_file_bindings_owner;
DROP INDEX IF EXISTS idx_file_bindings_file_id;

DROP TABLE IF EXISTS file_bindings;