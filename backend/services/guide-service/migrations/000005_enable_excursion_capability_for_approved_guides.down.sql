-- Intentional no-op: this migration repairs approved profiles whose original
-- capability intent was not persisted, so reverting it could revoke valid access.
SELECT 1;
