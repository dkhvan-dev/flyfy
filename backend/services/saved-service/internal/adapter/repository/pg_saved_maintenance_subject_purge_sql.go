package repository

const purgeSubjectOutboxSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_outbox
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_outbox AS outbox
    USING candidates
    WHERE outbox.owner_user_id = candidates.owner_user_id
      AND outbox.id = candidates.id
      AND outbox.owner_user_id = $1
    RETURNING outbox.id
)
SELECT count(*)::bigint FROM deleted`

const subjectOutboxRemainsSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_outbox WHERE owner_user_id = $1
) AND $2 <> ''`

const purgeSubjectCollectionItemsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_collection_items
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collection_items AS item
    USING candidates
    WHERE item.owner_user_id = candidates.owner_user_id
      AND item.id = candidates.id
      AND item.owner_user_id = $1
    RETURNING item.id
)
SELECT count(*)::bigint FROM deleted`

const subjectCollectionItemsRemainSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_collection_items WHERE owner_user_id = $1
) AND $2 <> ''`

const purgeSubjectCollectionsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_collections
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collections AS collection
    USING candidates
    WHERE collection.owner_user_id = candidates.owner_user_id
      AND collection.id = candidates.id
      AND collection.owner_user_id = $1
    RETURNING collection.id
)
SELECT count(*)::bigint FROM deleted`

const subjectCollectionsRemainSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_collections WHERE owner_user_id = $1
) AND $2 <> ''`

const purgeSubjectSavedItemsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id, id
    FROM saved_items
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_items AS item
    USING candidates
    WHERE item.owner_user_id = candidates.owner_user_id
      AND item.id = candidates.id
      AND item.owner_user_id = $1
    RETURNING item.id
)
SELECT count(*)::bigint FROM deleted`

const subjectSavedItemsRemainSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_items WHERE owner_user_id = $1
) AND $2 <> ''`

const purgeSubjectOperationsSQL = `
WITH candidates AS MATERIALIZED (
    SELECT subject, session_generation, operation_id
    FROM saved_operations
    WHERE subject = $2
      AND $1 IS NOT NULL
    ORDER BY session_generation, operation_id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_operations AS operation
    USING candidates
    WHERE operation.subject = candidates.subject
      AND operation.session_generation = candidates.session_generation
      AND operation.operation_id = candidates.operation_id
      AND operation.subject = $2
    RETURNING operation.operation_id
)
SELECT count(*)::bigint FROM deleted`

const subjectOperationsRemainSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_operations WHERE subject = $2
) AND $1 IS NOT NULL`

const purgeSubjectCollectionUsageSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id
    FROM saved_collection_usage
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY owner_user_id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_collection_usage AS usage
    USING candidates
    WHERE usage.owner_user_id = candidates.owner_user_id
      AND usage.owner_user_id = $1
    RETURNING usage.owner_user_id
)
SELECT count(*)::bigint FROM deleted`

const subjectCollectionUsageRemainsSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_collection_usage WHERE owner_user_id = $1
) AND $2 <> ''`

const purgeSubjectUserUsageSQL = `
WITH candidates AS MATERIALIZED (
    SELECT owner_user_id
    FROM saved_user_usage
    WHERE owner_user_id = $1
      AND $2 <> ''
    ORDER BY owner_user_id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_user_usage AS usage
    USING candidates
    WHERE usage.owner_user_id = candidates.owner_user_id
      AND usage.owner_user_id = $1
    RETURNING usage.owner_user_id
)
SELECT count(*)::bigint FROM deleted`

const subjectUserUsageRemainsSQL = `
SELECT EXISTS (
    SELECT 1 FROM saved_user_usage WHERE owner_user_id = $1
) AND $2 <> ''`
