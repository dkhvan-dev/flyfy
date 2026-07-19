-- One statement only: CREATE INDEX CONCURRENTLY must not run in a transaction.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_saved_content_projections_public_search_target_v1
    ON saved_content_projections (entity_type, entity_id)
    WHERE visibility_status = 'PUBLIC' AND search_document_version > 0;
