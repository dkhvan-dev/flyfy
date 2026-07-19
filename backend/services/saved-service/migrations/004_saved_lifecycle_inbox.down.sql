ALTER TABLE saved_inbox_dedup
    DROP CONSTRAINT saved_inbox_dedup_source_service_check,
    DROP CONSTRAINT saved_inbox_dedup_event_id_v4_check,
    DROP CONSTRAINT saved_inbox_dedup_subject_check,
    DROP CONSTRAINT saved_inbox_dedup_schema_check,
    DROP CONSTRAINT saved_inbox_dedup_target_entity_type_check,
    DROP CONSTRAINT saved_inbox_dedup_subject_source_check,
    DROP CONSTRAINT saved_inbox_dedup_fingerprint_check,
    DROP CONSTRAINT saved_inbox_dedup_event_type_check,
    DROP CONSTRAINT saved_inbox_dedup_revision_check,
    DROP CONSTRAINT saved_inbox_dedup_processing_state_check,
    DROP CONSTRAINT saved_inbox_dedup_outcome_shape_check,
    DROP CONSTRAINT saved_inbox_dedup_retention_check;

UPDATE saved_inbox_dedup
SET processing_state = CASE processing_state
    WHEN 'IGNORED_UNKNOWN_TARGET' THEN 'IGNORED_UNKNOWN_TARGET'
    WHEN 'IGNORED_STALE_REVISION' THEN 'IGNORED_STALE_REVISION'
    WHEN 'IGNORED_PUBLIC_PAYLOAD_ABSENT' THEN 'IGNORED_STALE_REVISION'
    ELSE 'APPLIED'
END;

ALTER TABLE saved_inbox_dedup
    DROP COLUMN subject,
    DROP COLUMN schema_version,
    DROP COLUMN target_entity_type,
    DROP COLUMN envelope_fingerprint,
    DROP COLUMN source_revision,
    DROP COLUMN projection_revision,
    DROP COLUMN visibility_revision,
    DROP COLUMN source_applied,
    DROP COLUMN projection_applied,
    DROP COLUMN visibility_applied,
    ALTER COLUMN event_id TYPE TEXT USING event_id::TEXT;

ALTER TABLE saved_inbox_dedup
    ADD CONSTRAINT saved_inbox_dedup_source_service_check
        CHECK (
            octet_length(source_service) BETWEEN 1 AND 64
            AND source_service ~ '^[a-z][a-z0-9-]*$'
        ),
    ADD CONSTRAINT saved_inbox_dedup_event_id_check
        CHECK (
            octet_length(event_id) BETWEEN 1 AND 128
            AND event_id !~ '^[[:space:]]'
            AND event_id !~ '[[:space:]]$'
        ),
    ADD CONSTRAINT saved_inbox_dedup_event_type_check
        CHECK (
            event_type IN (
                'content.published',
                'content.updated',
                'content.unavailable',
                'content.visibility_changed',
                'content.deleted'
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_processing_state_check
        CHECK (
            processing_state IN (
                'APPLIED',
                'IGNORED_UNKNOWN_TARGET',
                'IGNORED_STALE_REVISION'
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_retention_check
        CHECK (
            isfinite(processed_at)
            AND isfinite(retention_expires_at)
            AND retention_expires_at = processed_at + INTERVAL '14 days'
        );
