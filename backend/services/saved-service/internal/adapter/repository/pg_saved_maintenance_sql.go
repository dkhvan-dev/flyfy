package repository

// Pending-operation usage is represented by status = PENDING and its partial
// index in the current schema, not by a denormalized counter. The CAS update
// therefore releases pending capacity exactly once with the terminal receipt.
const expirePendingSavedOperationsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT subject, session_generation, operation_id, operation_kind
    FROM saved_operations
    WHERE status = 'PENDING'
      AND commit_deadline <= $1
    ORDER BY commit_deadline, subject, session_generation, operation_id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), expired AS (
    UPDATE saved_operations AS operation
    SET status = 'EXPIRED',
        outcome_code = 'EXPIRED',
        outcome_retryable = FALSE,
        refresh_scope = CASE candidates.operation_kind
            WHEN 'SAVE_TARGET' THEN 'SAVED_ITEMS'
            WHEN 'UNSAVE_TARGET' THEN 'BOTH'
            WHEN 'SET_TARGET_COLLECTIONS' THEN 'BOTH'
            WHEN 'CREATE_COLLECTION' THEN 'COLLECTIONS'
            WHEN 'RENAME_COLLECTION' THEN 'COLLECTIONS'
            WHEN 'DELETE_COLLECTION' THEN 'BOTH'
            ELSE 'NONE'
        END,
        completed_at = $1,
        retention_expires_at = $2
    FROM candidates
    WHERE operation.subject = candidates.subject
      AND operation.session_generation = candidates.session_generation
      AND operation.operation_id = candidates.operation_id
      AND operation.status = 'PENDING'
      AND operation.commit_deadline <= $1
    RETURNING operation.operation_id
)
SELECT count(*)::bigint FROM expired`

const purgeTerminalSavedOperationsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT subject, session_generation, operation_id
    FROM saved_operations
    WHERE status IN ('SUCCEEDED', 'REJECTED', 'EXPIRED')
      AND retention_expires_at <= $1
      AND completed_at <= $2
    ORDER BY retention_expires_at, subject, session_generation, operation_id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_operations AS operation
    USING candidates
    WHERE operation.subject = candidates.subject
      AND operation.session_generation = candidates.session_generation
      AND operation.operation_id = candidates.operation_id
      AND operation.status IN ('SUCCEEDED', 'REJECTED', 'EXPIRED')
      AND operation.retention_expires_at <= $1
      AND operation.completed_at <= $2
    RETURNING operation.operation_id
)
SELECT count(*)::bigint FROM deleted`

const purgeTerminalSavedOutboxSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_outbox
    WHERE status IN ('DELIVERED', 'DEAD')
      AND retention_expires_at <= $1
    ORDER BY retention_expires_at, owner_user_id, id
    LIMIT $2
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_outbox AS outbox
    USING candidates
    WHERE outbox.owner_user_id = candidates.owner_user_id
      AND outbox.id = candidates.id
      AND outbox.status IN ('DELIVERED', 'DEAD')
      AND outbox.retention_expires_at <= $1
    RETURNING outbox.id
)
SELECT count(*)::bigint FROM deleted`

const purgeSavedInboxDedupSQL = `
WITH candidates AS MATERIALIZED (
    SELECT source_service, event_id
    FROM saved_inbox_dedup
    WHERE retention_expires_at <= $1
    ORDER BY retention_expires_at, source_service, event_id
    LIMIT $2
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_inbox_dedup AS inbox
    USING candidates
    WHERE inbox.source_service = candidates.source_service
      AND inbox.event_id = candidates.event_id
      AND inbox.retention_expires_at <= $1
    RETURNING inbox.event_id
)
SELECT count(*)::bigint FROM deleted`

const cleanupDeletedCollectionChildrenSQL = `
WITH candidates AS MATERIALIZED (
    SELECT item.owner_user_id, item.id
    FROM saved_collection_items AS item
    JOIN saved_collections AS collection
      ON collection.owner_user_id = item.owner_user_id
     AND collection.id = item.collection_id
    WHERE collection.lifecycle_state = 'DELETED'
    ORDER BY collection.deleted_at, collection.id, item.id
    LIMIT $1
    FOR UPDATE OF item SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collection_items AS item
    USING candidates
    WHERE item.owner_user_id = candidates.owner_user_id
      AND item.id = candidates.id
    RETURNING item.id
)
SELECT count(*)::bigint FROM deleted`

const purgeRemovedCollectionItemsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_collection_items
    WHERE membership_state = 'REMOVED'
      AND purge_eligible_at <= $1
    ORDER BY purge_eligible_at, owner_user_id, id
    LIMIT $2
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collection_items AS item
    USING candidates
    WHERE item.owner_user_id = candidates.owner_user_id
      AND item.id = candidates.id
      AND item.membership_state = 'REMOVED'
      AND item.purge_eligible_at <= $1
    RETURNING item.id
)
SELECT count(*)::bigint FROM deleted`

const purgeDeletedSavedCollectionsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT collection.owner_user_id, collection.id
    FROM saved_collections AS collection
    WHERE collection.lifecycle_state = 'DELETED'
      AND collection.purge_eligible_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_collection_items AS item
          WHERE item.owner_user_id = collection.owner_user_id
            AND item.collection_id = collection.id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM saved_operations AS operation
          WHERE operation.applied_collection_id = collection.id
      )
    ORDER BY collection.purge_eligible_at, collection.owner_user_id, collection.id
    LIMIT $2
    FOR UPDATE OF collection SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collections AS collection
    USING candidates
    WHERE collection.owner_user_id = candidates.owner_user_id
      AND collection.id = candidates.id
      AND collection.lifecycle_state = 'DELETED'
      AND collection.purge_eligible_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_collection_items AS item
          WHERE item.owner_user_id = collection.owner_user_id
            AND item.collection_id = collection.id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM saved_operations AS operation
          WHERE operation.applied_collection_id = collection.id
      )
    RETURNING collection.id
)
SELECT count(*)::bigint FROM deleted`

const purgeRemovedSavedItemsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT item.owner_user_id, item.id
    FROM saved_items AS item
    WHERE item.relationship_state = 'REMOVED'
      AND item.purge_eligible_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_collection_items AS membership
          WHERE membership.owner_user_id = item.owner_user_id
            AND membership.saved_item_id = item.id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM saved_outbox AS outbox
          WHERE outbox.owner_user_id = item.owner_user_id
            AND outbox.saved_item_id = item.id
      )
    ORDER BY item.purge_eligible_at, item.owner_user_id, item.id
    LIMIT $2
    FOR UPDATE OF item SKIP LOCKED
), deleted AS (
    DELETE FROM saved_items AS item
    USING candidates
    WHERE item.owner_user_id = candidates.owner_user_id
      AND item.id = candidates.id
      AND item.relationship_state = 'REMOVED'
      AND item.purge_eligible_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_collection_items AS membership
          WHERE membership.owner_user_id = item.owner_user_id
            AND membership.saved_item_id = item.id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM saved_outbox AS outbox
          WHERE outbox.owner_user_id = item.owner_user_id
            AND outbox.saved_item_id = item.id
      )
    RETURNING item.id
)
SELECT count(*)::bigint FROM deleted`

// Outbox rows cannot survive without a saved_items row because their tenant-safe
// FK is RESTRICT. Inbox rows contain no entity ID after migration 004. A pending
// first-save is protected through shell_expires_at > commit_deadline, while a
// re-save/final projection write serializes on the same projection row lock.
const markSavedProjectionGCCandidatesSQL = `
WITH candidates AS MATERIALIZED (
    SELECT projection.entity_type, projection.entity_id
    FROM saved_content_projections AS projection
    WHERE projection.ever_referenced = TRUE
      AND projection.gc_candidate_at IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    ORDER BY projection.entity_type, projection.entity_id
    LIMIT $2
    FOR UPDATE OF projection SKIP LOCKED
), marked AS (
    UPDATE saved_content_projections AS projection
    SET gc_candidate_at = $1,
        updated_at = GREATEST(projection.updated_at, $1)
    FROM candidates
    WHERE projection.entity_type = candidates.entity_type
      AND projection.entity_id = candidates.entity_id
      AND projection.ever_referenced = TRUE
      AND projection.gc_candidate_at IS NULL
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    RETURNING projection.entity_id
)
SELECT count(*)::bigint FROM marked`

const purgeEphemeralSavedProjectionsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT projection.entity_type, projection.entity_id
    FROM saved_content_projections AS projection
    WHERE projection.ever_referenced = FALSE
      AND projection.shell_expires_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    ORDER BY projection.shell_expires_at, projection.entity_type, projection.entity_id
    LIMIT $2
    FOR UPDATE OF projection SKIP LOCKED
), deleted AS (
    DELETE FROM saved_content_projections AS projection
    USING candidates
    WHERE projection.entity_type = candidates.entity_type
      AND projection.entity_id = candidates.entity_id
      AND projection.ever_referenced = FALSE
      AND projection.shell_expires_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    RETURNING projection.entity_id
)
SELECT count(*)::bigint FROM deleted`

const purgeStandardSavedProjectionsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT projection.entity_type, projection.entity_id
    FROM saved_content_projections AS projection
    WHERE projection.ever_referenced = TRUE
      AND projection.gc_candidate_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    ORDER BY projection.gc_candidate_at, projection.entity_type, projection.entity_id
    LIMIT $2
    FOR UPDATE OF projection SKIP LOCKED
), deleted AS (
    DELETE FROM saved_content_projections AS projection
    USING candidates
    WHERE projection.entity_type = candidates.entity_type
      AND projection.entity_id = candidates.entity_id
      AND projection.ever_referenced = TRUE
      AND projection.gc_candidate_at <= $1
      AND NOT EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
      )
    RETURNING projection.entity_id
)
SELECT count(*)::bigint FROM deleted`

const purgeCompletedSubjectPurgesSQL = `
WITH candidates AS MATERIALIZED (
    SELECT operation_id
    FROM saved_subject_purge_operations
    WHERE phase = 'COMPLETED'
      AND retention_expires_at <= $1
    ORDER BY retention_expires_at, operation_id
    LIMIT $2
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_subject_purge_operations AS purge
    USING candidates
    WHERE purge.operation_id = candidates.operation_id
      AND purge.phase = 'COMPLETED'
      AND purge.retention_expires_at <= $1
    RETURNING purge.operation_id
)
SELECT count(*)::bigint FROM deleted`
