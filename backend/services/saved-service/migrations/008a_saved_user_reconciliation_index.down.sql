DROP INDEX CONCURRENTLY IF EXISTS idx_saved_content_projections_reconciliation_due_v1;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_saved_content_projections_reconciliation_due_v1
    ON saved_content_projections (
        (GREATEST(
            COALESCE(
                reconciliation_next_attempt_at,
                visibility_validated_at,
                created_at
            ),
            COALESCE(
                reconciliation_last_attempt_at,
                created_at
            )
        )),
        entity_type,
        entity_id
    )
    INCLUDE (reconciliation_lease_expires_at)
    WHERE ever_referenced = TRUE
      AND gc_candidate_at IS NULL
      AND reconciliation_quarantined_at IS NULL
      AND entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE');
