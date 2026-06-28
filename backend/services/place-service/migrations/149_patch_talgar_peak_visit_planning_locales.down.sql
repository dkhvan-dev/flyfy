-- Intentionally left irreversible: this migration repairs localized Talgar Peak
-- visit-planning data after an earlier Russian-only seed. Reverting would
-- restore incorrect user-facing content, so rollback is a no-op.

SELECT 1;
