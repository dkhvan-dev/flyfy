package repository

const claimDueSavedOutboxSQL = `
WITH candidates AS MATERIALIZED (
    SELECT id
    FROM saved_outbox
    WHERE status = 'PENDING'
      AND locked_at IS NULL
      AND attempt_count < $2
      AND next_attempt_at <= $1
    ORDER BY next_attempt_at, created_at, id
    LIMIT $3
    FOR UPDATE SKIP LOCKED
), claimed AS (
    UPDATE saved_outbox AS outbox
    SET locked_at = $1,
        attempt_count = outbox.attempt_count + 1,
        updated_at = $1
    FROM candidates
    WHERE outbox.id = candidates.id
      AND outbox.status = 'PENDING'
      AND outbox.locked_at IS NULL
      AND outbox.attempt_count < $2
      AND outbox.next_attempt_at <= $1
    RETURNING outbox.id,
              outbox.event_schema_version,
              outbox.event_type,
              outbox.entity_type,
              outbox.created_at,
              outbox.attempt_count,
              outbox.locked_at,
              outbox.next_attempt_at
)
SELECT id,
       event_schema_version,
       event_type,
       entity_type,
       created_at,
       attempt_count,
       locked_at
FROM claimed
ORDER BY next_attempt_at, created_at, id`

const recoverStaleSavedOutboxLeasesSQL = `
WITH candidates AS MATERIALIZED (
    SELECT id
    FROM saved_outbox
    WHERE status = 'PENDING'
      AND created_at <= $1::timestamptz
      AND next_attempt_at <= $1::timestamptz
      AND (
          (locked_at IS NOT NULL AND locked_at <= $2::timestamptz)
          OR (locked_at IS NULL AND attempt_count >= $3::integer)
      )
    ORDER BY next_attempt_at, created_at, id
    LIMIT $4::integer
    FOR UPDATE SKIP LOCKED
), recovered AS (
    UPDATE saved_outbox AS outbox
    SET status = CASE
            WHEN outbox.attempt_count >= $3::integer THEN 'DEAD'
            ELSE 'PENDING'
        END,
        next_attempt_at = $1::timestamptz,
        locked_at = NULL,
        delivered_at = NULL,
        dead_at = CASE
            WHEN outbox.attempt_count >= $3::integer THEN $1::timestamptz
            ELSE NULL::timestamptz
        END,
        last_error_code = CASE
            WHEN outbox.attempt_count >= $3::integer THEN $6::text
            ELSE $7::text
        END,
        retention_expires_at = CASE
            WHEN outbox.attempt_count >= $3::integer THEN $5::timestamptz
            ELSE NULL::timestamptz
        END,
        updated_at = $1::timestamptz
    FROM candidates
    WHERE outbox.id = candidates.id
      AND outbox.status = 'PENDING'
    RETURNING outbox.status
)
SELECT count(*) FILTER (WHERE status = 'PENDING')::bigint,
       count(*) FILTER (WHERE status = 'DEAD')::bigint
FROM recovered`

const markSavedOutboxDeliveredSQL = `
UPDATE saved_outbox
SET status = 'DELIVERED',
    next_attempt_at = $4,
    locked_at = NULL,
    delivered_at = $4,
    dead_at = NULL,
    last_error_code = NULL,
    retention_expires_at = $5,
    updated_at = $4
WHERE id = $1
  AND status = 'PENDING'
  AND locked_at = $2
  AND attempt_count = $3`

const markSavedOutboxFailedSQL = `
UPDATE saved_outbox
SET status = CASE
        WHEN $9::boolean OR attempt_count >= $7::integer THEN 'DEAD'
        ELSE 'PENDING'
    END,
    next_attempt_at = CASE
        WHEN $9::boolean OR attempt_count >= $7::integer THEN $4::timestamptz
        ELSE $5::timestamptz
    END,
    locked_at = NULL,
    delivered_at = NULL,
    dead_at = CASE
        WHEN $9::boolean OR attempt_count >= $7::integer THEN $4::timestamptz
        ELSE NULL::timestamptz
    END,
    last_error_code = $8::text,
    retention_expires_at = CASE
        WHEN $9::boolean OR attempt_count >= $7::integer THEN $6::timestamptz
        ELSE NULL::timestamptz
    END,
    updated_at = $4::timestamptz
WHERE id = $1::uuid
  AND status = 'PENDING'
  AND locked_at = $2::timestamptz
  AND attempt_count = $3::integer
RETURNING status`

const deleteExpiredSavedOutboxSQL = `
WITH candidates AS MATERIALIZED (
    SELECT id
    FROM saved_outbox
    WHERE status IN ('DELIVERED', 'DEAD')
      AND retention_expires_at <= $1
    ORDER BY retention_expires_at, owner_user_id, id
    LIMIT $2
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM saved_outbox AS outbox
    USING candidates
    WHERE outbox.id = candidates.id
      AND outbox.status IN ('DELIVERED', 'DEAD')
      AND outbox.retention_expires_at <= $1
    RETURNING outbox.id
)
SELECT count(*)::bigint FROM deleted`
