package repository

const configureSavedReconciliationTxSQL = `
SELECT set_config('statement_timeout', '5s', TRUE),
       set_config('lock_timeout', '1s', TRUE),
       set_config('idle_in_transaction_session_timeout', '10s', TRUE)`

const claimSavedReconciliationSQL = `
WITH db_clock AS MATERIALIZED (
    SELECT clock_timestamp() AS claimed_at
),
candidate AS (
    SELECT projection.entity_type,
           projection.entity_id,
           db_clock.claimed_at
    FROM saved_content_projections AS projection
    CROSS JOIN db_clock
    WHERE projection.ever_referenced = TRUE
      AND projection.gc_candidate_at IS NULL
      AND projection.reconciliation_quarantined_at IS NULL
      AND projection.entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')
      AND (
          (
              projection.reconciliation_next_attempt_at IS NULL
              AND (
                  projection.visibility_validated_at IS NULL
                  OR projection.visibility_validated_at <=
                     db_clock.claimed_at - ($1::bigint * INTERVAL '1 microsecond')
              )
          )
          OR projection.reconciliation_next_attempt_at <= db_clock.claimed_at
      )
      AND (
          projection.reconciliation_lease_token IS NULL
          OR projection.reconciliation_lease_expires_at <= db_clock.claimed_at
      )
      AND EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
            AND item.relationship_state = 'ACTIVE'
      )
    ORDER BY GREATEST(
                 COALESCE(
                     projection.reconciliation_next_attempt_at,
                     projection.visibility_validated_at,
                     projection.created_at
                 ),
                 COALESCE(
                     projection.reconciliation_last_attempt_at,
                     projection.created_at
                 )
             ) ASC,
             projection.entity_type ASC,
             projection.entity_id ASC
    LIMIT 1
    FOR UPDATE OF projection SKIP LOCKED
)
UPDATE saved_content_projections AS projection
SET reconciliation_lease_token = $3,
    reconciliation_lease_expires_at =
        candidate.claimed_at + ($2::bigint * INTERVAL '1 microsecond'),
    reconciliation_last_attempt_at = candidate.claimed_at
FROM candidate
WHERE projection.entity_type = candidate.entity_type
  AND projection.entity_id = candidate.entity_id
RETURNING projection.entity_type,
          projection.entity_id,
          projection.source_service,
          projection.source_revision,
          projection.projection_revision,
          projection.visibility_revision,
          projection.visibility_status,
          projection.visibility_validated_at,
          projection.reconciliation_fail_closed_at,
          COALESCE(projection.reconciliation_failure_count, 0),
          projection.reconciliation_failure_kind,
          projection.reconciliation_last_attempt_at,
          projection.reconciliation_lease_expires_at`

const hasDueSavedReconciliationSQL = `
WITH db_clock AS MATERIALIZED (
    SELECT clock_timestamp() AS checked_at
)
SELECT EXISTS (
    SELECT 1
    FROM saved_content_projections AS projection
    CROSS JOIN db_clock
    WHERE projection.ever_referenced = TRUE
      AND projection.gc_candidate_at IS NULL
      AND projection.reconciliation_quarantined_at IS NULL
      AND projection.entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')
      AND (
          (
              projection.reconciliation_next_attempt_at IS NULL
              AND (
                  projection.visibility_validated_at IS NULL
                  OR projection.visibility_validated_at <=
                     db_clock.checked_at - ($1::bigint * INTERVAL '1 microsecond')
              )
          )
          OR projection.reconciliation_next_attempt_at <= db_clock.checked_at
      )
      AND (
          projection.reconciliation_lease_token IS NULL
          OR projection.reconciliation_lease_expires_at <= db_clock.checked_at
      )
      AND EXISTS (
          SELECT 1
          FROM saved_items AS item
          WHERE item.entity_type = projection.entity_type
            AND item.entity_id = projection.entity_id
            AND item.relationship_state = 'ACTIVE'
      )
    LIMIT 1
)`

// Completion first acquires the projection row in a separate statement. This
// makes the lease-expiry predicate below observe the database clock after any
// row-lock wait, instead of accepting a lease that expired while waiting.
const lockSavedReconciliationCompletionRowSQL = `
SELECT TRUE
FROM saved_content_projections
WHERE entity_type = $1
  AND entity_id = $2
  AND reconciliation_lease_token = $3
FOR UPDATE`

const savedReconciliationCompletionCAS = `
WHERE projection.entity_type = @entity_type
  AND projection.entity_id = @entity_id
  AND projection.reconciliation_lease_token = @lease_token
  AND projection.reconciliation_lease_expires_at > clock_timestamp()
  AND projection.source_service = @expected_source_service
  AND projection.source_revision = @expected_source_revision
  AND projection.projection_revision = @expected_projection_revision
  AND projection.visibility_revision = @expected_visibility_revision
  AND projection.visibility_status = @expected_visibility
  AND projection.visibility_validated_at IS NOT DISTINCT FROM @expected_visibility_validated_at
  AND projection.reconciliation_fail_closed_at IS NOT DISTINCT FROM @expected_fail_closed_at
  AND COALESCE(projection.reconciliation_failure_count, 0) = @expected_failure_count
  AND projection.reconciliation_failure_kind IS NOT DISTINCT FROM @expected_failure_kind
  AND projection.ever_referenced = TRUE
  AND projection.gc_candidate_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM saved_items AS item
      WHERE item.entity_type = projection.entity_type
        AND item.entity_id = projection.entity_id
        AND item.relationship_state = 'ACTIVE'
  )`

const completeSavedReconciliationNoopSQL = `
UPDATE saved_content_projections AS projection
SET reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const updateSavedReconciliationMetadataSQL = `
UPDATE saved_content_projections AS projection
SET source_revision = @source_revision,
    projection_revision = @projection_revision,
    visibility_revision = @visibility_revision,
    visibility_status = @visibility,
    visibility_validated_at = @visibility_validated_at,
    search_document_version = @projection_revision,
    updated_at = GREATEST(updated_at, clock_timestamp()),
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const refreshSavedReconciliationPublicMetadataSQL = `
UPDATE saved_content_projections AS projection
SET source_revision = @source_revision,
    projection_revision = @projection_revision,
    visibility_revision = @visibility_revision,
    visibility_status = @visibility,
    visibility_validated_at = @visibility_validated_at,
    media_reference = @media_reference,
    media_reference_revision = @media_reference_revision,
    media_valid_until = @media_valid_until,
    search_document_version = @projection_revision,
    updated_at = GREATEST(updated_at, clock_timestamp()),
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const applySavedReconciliationPublicSQL = `
UPDATE saved_content_projections AS projection
SET source_revision = @source_revision,
    projection_revision = @projection_revision,
    visibility_revision = @visibility_revision,
    visibility_status = 'PUBLIC',
    visibility_validated_at = @visibility_validated_at,
    source_default_locale = @source_default_locale,
    title_en = @title_en,
    title_ru = @title_ru,
    title_kk = @title_kk,
    subtitle_en = @subtitle_en,
    subtitle_ru = @subtitle_ru,
    subtitle_kk = @subtitle_kk,
    city_en = @city_en,
    city_ru = @city_ru,
    city_kk = @city_kk,
    country_en = @country_en,
    country_ru = @country_ru,
    country_kk = @country_kk,
    display_location_en = @display_location_en,
    display_location_ru = @display_location_ru,
    display_location_kk = @display_location_kk,
    search_document_version = @projection_revision,
    normalized_search_document_en = @search_document_en,
    normalized_search_document_ru = @search_document_ru,
    normalized_search_document_kk = @search_document_kk,
    media_reference = @media_reference,
    media_reference_revision = @media_reference_revision,
    media_valid_until = @media_valid_until,
    rating_value = @rating_value,
    rating_count = @rating_count,
    rating_scale_max = @rating_scale_max,
    price_summary = CAST(@price_summary AS JSONB),
    availability_summary = CAST(@availability_summary AS JSONB),
    summary_as_of = @summary_as_of,
    summary_valid_until = @summary_valid_until,
    canonical_detail_route = @canonical_detail_route,
    updated_at = GREATEST(updated_at, clock_timestamp()),
    reconciliation_fail_closed_at = NULL,
    reconciliation_fail_closed_reason = NULL,
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const applySavedReconciliationDenySQL = `
UPDATE saved_content_projections AS projection
SET source_revision = @source_revision,
    projection_revision = @projection_revision,
    visibility_revision = @visibility_revision,
    visibility_status = @visibility,
    visibility_validated_at = @visibility_validated_at,
    source_default_locale = NULL,
    title_en = NULL,
    title_ru = NULL,
    title_kk = NULL,
    subtitle_en = NULL,
    subtitle_ru = NULL,
    subtitle_kk = NULL,
    city_en = NULL,
    city_ru = NULL,
    city_kk = NULL,
    country_en = NULL,
    country_ru = NULL,
    country_kk = NULL,
    display_location_en = NULL,
    display_location_ru = NULL,
    display_location_kk = NULL,
    search_document_version = @projection_revision,
    normalized_search_document_en = NULL,
    normalized_search_document_ru = NULL,
    normalized_search_document_kk = NULL,
    media_reference = NULL,
    media_reference_revision = NULL,
    media_valid_until = NULL,
    rating_value = NULL,
    rating_count = NULL,
    rating_scale_max = NULL,
    price_summary = NULL,
    availability_summary = NULL,
    summary_as_of = NULL,
    summary_valid_until = NULL,
    canonical_detail_route = NULL,
    updated_at = GREATEST(updated_at, clock_timestamp()),
    reconciliation_fail_closed_at = NULL,
    reconciliation_fail_closed_reason = NULL,
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const applySavedReconciliationFailClosedSQL = `
UPDATE saved_content_projections AS projection
SET source_default_locale = NULL,
    title_en = NULL,
    title_ru = NULL,
    title_kk = NULL,
    subtitle_en = NULL,
    subtitle_ru = NULL,
    subtitle_kk = NULL,
    city_en = NULL,
    city_ru = NULL,
    city_kk = NULL,
    country_en = NULL,
    country_ru = NULL,
    country_kk = NULL,
    display_location_en = NULL,
    display_location_ru = NULL,
    display_location_kk = NULL,
    normalized_search_document_en = NULL,
    normalized_search_document_ru = NULL,
    normalized_search_document_kk = NULL,
    media_reference = NULL,
    media_reference_revision = NULL,
    media_valid_until = NULL,
    rating_value = NULL,
    rating_count = NULL,
    rating_scale_max = NULL,
    price_summary = NULL,
    availability_summary = NULL,
    summary_as_of = NULL,
    summary_valid_until = NULL,
    canonical_detail_route = NULL,
    updated_at = GREATEST(updated_at, clock_timestamp()),
    reconciliation_fail_closed_at = clock_timestamp(),
    reconciliation_fail_closed_reason = 'UNVERSIONED_NOT_FOUND',
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond'),
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL
` + savedReconciliationCompletionCAS

const completeSavedReconciliationFailureSQL = `
UPDATE saved_content_projections AS projection
SET reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at = CASE
        WHEN @quarantine::boolean THEN NULL
        ELSE clock_timestamp() +
             (@next_attempt_delay_us::bigint * INTERVAL '1 microsecond')
    END,
    reconciliation_failure_count = CASE
        WHEN reconciliation_failure_kind IS NOT DISTINCT FROM @failure_kind::text
        THEN LEAST(COALESCE(reconciliation_failure_count, 0) + 1, 32767)
        ELSE 1
    END,
    reconciliation_failure_kind = @failure_kind,
    reconciliation_quarantined_at = CASE
        WHEN @quarantine::boolean THEN clock_timestamp()
        ELSE NULL
    END,
    reconciliation_quarantine_reason = CASE
        WHEN @quarantine::boolean THEN @quarantine_reason
        ELSE NULL
    END
` + savedReconciliationCompletionCAS

const releaseLostSavedReconciliationLeaseSQL = `
UPDATE saved_content_projections
SET reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_next_attempt_at =
        clock_timestamp() + ($4::bigint * INTERVAL '1 microsecond')
WHERE entity_type = $1
  AND entity_id = $2
  AND reconciliation_lease_token = $3`
