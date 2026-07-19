-- Deleted-parent cleanup removes every child state. The migration-002 partial
-- index intentionally covers ACTIVE reads only and cannot drive this all-state
-- compliance/retention cursor.
CREATE INDEX idx_saved_collection_items_deleted_parent_cleanup
    ON saved_collection_items (owner_user_id, collection_id, id);

-- A retained terminal receipt is a logical dependency of a collection
-- tombstone even though no FK is used for payload-free operation outcomes.
CREATE INDEX idx_saved_operations_collection_dependency
    ON saved_operations (applied_collection_id, retention_expires_at)
    WHERE applied_collection_id IS NOT NULL;

-- Subject purge removes all outbox states for one owner in deterministic ID
-- batches; delivery/retention indexes are status-first and do not cover it.
CREATE INDEX idx_saved_outbox_owner_purge
    ON saved_outbox (owner_user_id, id);

-- Recovery scanning must find standard projections that have not yet received
-- a gc_candidate_at without walking the entire shared projection primary key.
CREATE INDEX idx_saved_content_projections_gc_discovery
    ON saved_content_projections (entity_type, entity_id)
    WHERE ever_referenced = TRUE AND gc_candidate_at IS NULL;

