-- Migration 008 also retained guide-service search document revisions while
-- rebasing the source vector to user-service. Exclude that legacy document
-- until user-service writes a canonical USER projection.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '5min';

UPDATE saved_content_projections
SET search_document_version = 0,
    normalized_search_document_en = NULL,
    normalized_search_document_ru = NULL,
    normalized_search_document_kk = NULL,
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
  AND search_document_version > 1;
