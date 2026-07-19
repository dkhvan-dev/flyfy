-- Migration 008 rebased GUIDE projection revisions into the user-service
-- namespace, but legacy avatar revisions remained in the guide-service
-- namespace. A later USER save could therefore look like a media rollback.
-- Drop only those expired legacy references and let user-service repopulate
-- the current avatar on the next save or reconciliation pass.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '5min';

UPDATE saved_content_projections
SET media_reference = NULL,
    media_reference_revision = NULL,
    media_valid_until = NULL,
    reconciliation_next_attempt_at = LEAST(
        COALESCE(reconciliation_next_attempt_at, CURRENT_TIMESTAMP),
        CURRENT_TIMESTAMP
    ),
    updated_at = GREATEST(updated_at, CURRENT_TIMESTAMP)
WHERE entity_type = 'USER'
  AND source_service = 'user-service'
  AND source_revision = 1
  AND projection_revision = 1
  AND visibility_revision = 1
  AND media_reference LIKE 'user-avatar:' || entity_id || ':%'
  AND media_reference_revision > 1;
