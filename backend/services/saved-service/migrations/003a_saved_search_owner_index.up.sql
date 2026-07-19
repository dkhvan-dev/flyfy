-- One statement only: CREATE INDEX CONCURRENTLY must not run in a transaction.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_saved_items_active_owner_search_v1
    ON saved_items (owner_user_id, saved_at DESC, id DESC)
    INCLUDE (entity_type, entity_id)
    WHERE relationship_state = 'ACTIVE';
