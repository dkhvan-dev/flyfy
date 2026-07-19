-- This rollback is intentionally conservative. It must run before deploying
-- binaries that no longer understand private collections, and only after the
-- application has verified/drained every row introduced by migration 002.
DO $saved_collections_rollback_guard$
BEGIN
    IF EXISTS (SELECT 1 FROM saved_collection_items LIMIT 1)
        OR EXISTS (SELECT 1 FROM saved_collection_usage LIMIT 1)
        OR EXISTS (SELECT 1 FROM saved_collections LIMIT 1) THEN
        RAISE EXCEPTION
            'cannot roll back migration 002 while private collection data exists'
            USING ERRCODE = '55000';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM saved_operations
        WHERE operation_kind IN (
            'SET_TARGET_COLLECTIONS',
            'CREATE_COLLECTION',
            'RENAME_COLLECTION',
            'DELETE_COLLECTION'
        )
        OR outcome_code IN (
            'SAVED_COLLECTION_NOT_FOUND',
            'SAVED_COLLECTION_DELETED',
            'SAVED_COLLECTION_TITLE_INVALID',
            'SAVED_COLLECTION_TITLE_CONFLICT',
            'SAVED_COLLECTION_LIMIT_REACHED',
            'SAVED_COLLECTION_ITEM_LIMIT_REACHED',
            'SAVED_MEMBERSHIP_LIMIT_REACHED'
        )
        OR observed_dependent_membership_version IS NOT NULL
        OR observed_collection_metadata_version IS NOT NULL
        OR observed_collection_lifecycle_version IS NOT NULL
        OR applied_dependent_membership_version IS NOT NULL
        OR applied_collection_id IS NOT NULL
        OR applied_collection_metadata_version IS NOT NULL
        OR applied_collection_lifecycle_version IS NOT NULL
        LIMIT 1
    ) THEN
        RAISE EXCEPTION
            'cannot roll back migration 002 while collection operation receipts exist'
            USING ERRCODE = '55000';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM saved_subject_purge_operations
        WHERE phase IN ('COLLECTION_ITEMS', 'COLLECTIONS', 'COLLECTION_USAGE')
        LIMIT 1
    ) THEN
        RAISE EXCEPTION
            'cannot roll back migration 002 while a purge uses collection phases'
            USING ERRCODE = '55000';
    END IF;
END
$saved_collections_rollback_guard$;

-- Child data is removed before its parents; no DROP uses CASCADE.
DROP TABLE saved_collection_items;
DROP TABLE saved_collection_usage;
DROP TABLE saved_collections;

ALTER TABLE saved_operations
    DROP CONSTRAINT saved_operations_kind_check,
    DROP CONSTRAINT saved_operations_outcome_code_check,
    DROP CONSTRAINT saved_operations_versions_check,
    DROP CONSTRAINT saved_operations_collection_kind_check,
    DROP CONSTRAINT saved_operations_applied_versions_status_check,
    DROP CONSTRAINT saved_operations_status_lifecycle_check;

ALTER TABLE saved_operations
    DROP COLUMN observed_dependent_membership_version,
    DROP COLUMN observed_collection_metadata_version,
    DROP COLUMN observed_collection_lifecycle_version,
    DROP COLUMN applied_dependent_membership_version,
    DROP COLUMN applied_collection_id,
    DROP COLUMN applied_collection_metadata_version,
    DROP COLUMN applied_collection_lifecycle_version;

ALTER TABLE saved_operations
    ADD CONSTRAINT saved_operations_kind_check
        CHECK (operation_kind IN ('SAVE_TARGET', 'UNSAVE_TARGET')),
    ADD CONSTRAINT saved_operations_outcome_code_check
        CHECK (
            (status = 'PENDING' AND outcome_code IS NULL)
            OR (
                status = 'SUCCEEDED'
                AND outcome_code IN ('APPLIED', 'NO_OP')
            )
            OR (
                status = 'REJECTED'
                AND outcome_code IN (
                    'SAVED_TARGET_TYPE_UNSUPPORTED',
                    'SAVED_TARGET_UNAVAILABLE',
                    'SAVED_DEPENDENCY_UNAVAILABLE',
                    'SAVED_MUTATION_STALE',
                    'SAVED_MUTATION_REPLAY_MISMATCH',
                    'SAVED_ITEM_LIMIT_REACHED',
                    'SAVED_RATE_LIMITED',
                    'SAVED_TEMPORARILY_UNAVAILABLE',
                    'PLATFORM_PERSONAL_DATA_LOCKED'
                )
            )
            OR (status = 'EXPIRED' AND outcome_code = 'EXPIRED')
        ),
    ADD CONSTRAINT saved_operations_versions_check
        CHECK (
            (observed_relationship_version IS NULL OR observed_relationship_version >= 0)
            AND (applied_relationship_version IS NULL OR applied_relationship_version > 0)
            AND (applied_user_usage_version IS NULL OR applied_user_usage_version >= 0)
            AND (
                (applied_relationship_generation IS NULL AND applied_relationship_version IS NULL)
                OR (
                    applied_relationship_generation IS NOT NULL
                    AND applied_relationship_version IS NOT NULL
                )
            )
        ),
    ADD CONSTRAINT saved_operations_applied_versions_status_check
        CHECK (
            status = 'SUCCEEDED'
            OR (
                applied_relationship_version IS NULL
                AND applied_relationship_generation IS NULL
                AND applied_user_usage_version IS NULL
            )
        ),
    ADD CONSTRAINT saved_operations_status_lifecycle_check
        CHECK (
            (
                status = 'PENDING'
                AND outcome_code IS NULL
                AND outcome_retryable IS NULL
                AND refresh_scope = 'NONE'
                AND observed_relationship_version IS NULL
                AND applied_relationship_version IS NULL
                AND applied_user_usage_version IS NULL
                AND completed_at IS NULL
                AND retention_expires_at IS NULL
            )
            OR (
                status IN ('SUCCEEDED', 'REJECTED', 'EXPIRED')
                AND outcome_code IS NOT NULL
                AND outcome_retryable IS NOT NULL
                AND (status <> 'SUCCEEDED' OR outcome_retryable = FALSE)
                AND (status <> 'EXPIRED' OR outcome_retryable = FALSE)
                AND completed_at IS NOT NULL
                AND isfinite(completed_at)
                AND completed_at >= created_at
                AND retention_expires_at IS NOT NULL
                AND isfinite(retention_expires_at)
                AND retention_expires_at = completed_at + INTERVAL '14 days'
            )
        );

ALTER TABLE saved_subject_purge_operations
    DROP CONSTRAINT saved_subject_purge_operations_phase_check,
    ADD CONSTRAINT saved_subject_purge_operations_phase_check
        CHECK (
            phase IN (
                'OUTBOX',
                'SAVED_ITEMS',
                'OPERATIONS',
                'USER_USAGE',
                'COMPLETED'
            )
        );
