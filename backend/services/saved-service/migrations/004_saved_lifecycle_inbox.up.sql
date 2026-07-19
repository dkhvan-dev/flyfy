-- No runtime consumer exists before this migration. Refuse to invent semantic
-- fingerprints for legacy rows: a manual audit is safer than reapplying an
-- event whose immutable envelope can no longer be proven.
DO $saved_lifecycle_inbox_precondition$
BEGIN
    IF EXISTS (SELECT 1 FROM saved_inbox_dedup LIMIT 1) THEN
        RAISE EXCEPTION USING
            ERRCODE = '55000',
            MESSAGE = 'saved lifecycle inbox must be empty before migration 004';
    END IF;
END
$saved_lifecycle_inbox_precondition$;

ALTER TABLE saved_inbox_dedup
    DROP CONSTRAINT saved_inbox_dedup_source_service_check,
    DROP CONSTRAINT saved_inbox_dedup_event_id_check,
    DROP CONSTRAINT saved_inbox_dedup_event_type_check,
    DROP CONSTRAINT saved_inbox_dedup_processing_state_check,
    DROP CONSTRAINT saved_inbox_dedup_retention_check;

ALTER TABLE saved_inbox_dedup
    ALTER COLUMN event_id TYPE UUID USING event_id::UUID,
    ADD COLUMN subject TEXT NOT NULL,
    ADD COLUMN schema_version SMALLINT NOT NULL,
    ADD COLUMN target_entity_type TEXT NOT NULL,
    ADD COLUMN envelope_fingerprint BYTEA NOT NULL,
    ADD COLUMN source_revision BIGINT NOT NULL,
    ADD COLUMN projection_revision BIGINT NOT NULL,
    ADD COLUMN visibility_revision BIGINT NOT NULL,
    ADD COLUMN source_applied BOOLEAN NOT NULL,
    ADD COLUMN projection_applied BOOLEAN NOT NULL,
    ADD COLUMN visibility_applied BOOLEAN NOT NULL;

ALTER TABLE saved_inbox_dedup
    ADD CONSTRAINT saved_inbox_dedup_source_service_check
        CHECK (source_service IN ('activity-service', 'place-service', 'guide-service')),
    ADD CONSTRAINT saved_inbox_dedup_event_id_v4_check
        CHECK (
            (get_byte(uuid_send(event_id), 6) >> 4) = 4
            AND (get_byte(uuid_send(event_id), 8) >> 6) = 2
        ),
    ADD CONSTRAINT saved_inbox_dedup_subject_check
        CHECK (
            subject IN (
                'saved.source.activity.lifecycle.v1',
                'saved.source.attraction.lifecycle.v1',
                'saved.source.guide.lifecycle.v1'
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_schema_check
        CHECK (schema_version = 1),
    ADD CONSTRAINT saved_inbox_dedup_target_entity_type_check
        CHECK (target_entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')),
    ADD CONSTRAINT saved_inbox_dedup_subject_source_check
        CHECK (
            (
                subject = 'saved.source.activity.lifecycle.v1'
                AND source_service = 'activity-service'
                AND target_entity_type = 'ACTIVITY'
            )
            OR (
                subject = 'saved.source.attraction.lifecycle.v1'
                AND source_service = 'place-service'
                AND target_entity_type = 'ATTRACTION'
            )
            OR (
                subject = 'saved.source.guide.lifecycle.v1'
                AND source_service = 'guide-service'
                AND target_entity_type = 'GUIDE'
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_fingerprint_check
        CHECK (octet_length(envelope_fingerprint) = 32),
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
    ADD CONSTRAINT saved_inbox_dedup_revision_check
        CHECK (
            source_revision > 0
            AND projection_revision > 0
            AND visibility_revision > 0
        ),
    ADD CONSTRAINT saved_inbox_dedup_processing_state_check
        CHECK (
            processing_state IN (
                'APPLIED',
                'APPLIED_SOURCE_ONLY',
                'IGNORED_UNKNOWN_TARGET',
                'IGNORED_STALE_REVISION',
                'IGNORED_PUBLIC_PAYLOAD_ABSENT'
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_outcome_shape_check
        CHECK (
            (
                processing_state = 'APPLIED'
                AND (projection_applied OR visibility_applied)
            )
            OR (
                processing_state = 'APPLIED_SOURCE_ONLY'
                AND source_applied
                AND NOT projection_applied
                AND NOT visibility_applied
            )
            OR (
                processing_state IN (
                    'IGNORED_UNKNOWN_TARGET',
                    'IGNORED_STALE_REVISION',
                    'IGNORED_PUBLIC_PAYLOAD_ABSENT'
                )
                AND NOT source_applied
                AND NOT projection_applied
                AND NOT visibility_applied
            )
        ),
    ADD CONSTRAINT saved_inbox_dedup_retention_check
        CHECK (
            isfinite(processed_at)
            AND isfinite(retention_expires_at)
            AND retention_expires_at = processed_at + INTERVAL '14 days'
        );

COMMENT ON COLUMN saved_inbox_dedup.envelope_fingerprint IS
    'SHA-256 of canonical subject plus deterministic protobuf; raw event payload is never retained';
