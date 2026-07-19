-- Collection titles are normalized by COLLECTION_TITLE_NORMALIZATION_V1 in the
-- application. PostgreSQL stores and compares the resulting key byte-for-byte;
-- changing that algorithm requires a separate expand/contract migration.
CREATE TABLE saved_collections (
    id UUID PRIMARY KEY,
    owner_user_id UUID NOT NULL,
    client_creation_id UUID NOT NULL,
    title TEXT,
    normalized_title_key TEXT,
    lifecycle_state TEXT NOT NULL DEFAULT 'ACTIVE',
    lifecycle_version BIGINT NOT NULL DEFAULT 1,
    metadata_version BIGINT NOT NULL DEFAULT 1,
    items_version BIGINT NOT NULL DEFAULT 0,
    active_item_count BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    organized_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    purge_eligible_at TIMESTAMPTZ,

    CONSTRAINT saved_collections_owner_client_creation_key
        UNIQUE (owner_user_id, client_creation_id),
    CONSTRAINT saved_collections_owner_id_key
        UNIQUE (owner_user_id, id),
    CONSTRAINT saved_collections_lifecycle_state_check
        CHECK (lifecycle_state IN ('ACTIVE', 'DELETED')),
    CONSTRAINT saved_collections_title_shape_check
        CHECK (
            title IS NULL
            OR (
                char_length(title) BETWEEN 1 AND 80
                AND octet_length(title) <= 320
                AND title = btrim(title)
                AND title !~ '[[:cntrl:]]'
            )
        ),
    CONSTRAINT saved_collections_normalized_title_shape_check
        CHECK (
            normalized_title_key IS NULL
            OR (
                char_length(normalized_title_key) BETWEEN 1 AND 80
                AND octet_length(normalized_title_key) <= 320
                AND normalized_title_key !~ '[[:cntrl:]]'
            )
        ),
    CONSTRAINT saved_collections_versions_and_count_check
        CHECK (
            lifecycle_version > 0
            AND metadata_version > 0
            AND items_version >= 0
            AND active_item_count >= 0
            AND active_item_count <= items_version
        ),
    CONSTRAINT saved_collections_lifecycle_check
        CHECK (
            (
                lifecycle_state = 'ACTIVE'
                AND title IS NOT NULL
                AND normalized_title_key IS NOT NULL
                AND deleted_at IS NULL
                AND purge_eligible_at IS NULL
            )
            OR (
                lifecycle_state = 'DELETED'
                AND lifecycle_version > 1
                AND title IS NULL
                AND normalized_title_key IS NULL
                AND active_item_count = 0
                AND deleted_at IS NOT NULL
                AND isfinite(deleted_at)
                AND purge_eligible_at IS NOT NULL
                AND isfinite(purge_eligible_at)
                AND purge_eligible_at = deleted_at + INTERVAL '14 days'
            )
        ),
    CONSTRAINT saved_collections_timestamps_check
        CHECK (
            isfinite(created_at)
            AND isfinite(organized_at)
            AND isfinite(updated_at)
            AND organized_at >= created_at
            AND updated_at >= organized_at
            AND (
                deleted_at IS NULL
                OR (deleted_at >= created_at AND updated_at >= deleted_at)
            )
        )
);

CREATE UNIQUE INDEX idx_saved_collections_active_title
    ON saved_collections (
        owner_user_id,
        normalized_title_key COLLATE "C"
    )
    WHERE lifecycle_state = 'ACTIVE';

CREATE INDEX idx_saved_collections_owner_organized
    ON saved_collections (
        owner_user_id,
        lifecycle_state,
        organized_at DESC,
        id DESC
    );

-- A DELETED parent is discovered first, then its children are removed in
-- bounded batches. Child rows remain protected by RESTRICT until cleanup ends.
CREATE INDEX idx_saved_collections_deleted_cleanup
    ON saved_collections (deleted_at, id)
    WHERE lifecycle_state = 'DELETED';

CREATE INDEX idx_saved_collections_deleted_retention
    ON saved_collections (purge_eligible_at, owner_user_id, id)
    WHERE lifecycle_state = 'DELETED';

CREATE TABLE saved_collection_items (
    id UUID PRIMARY KEY,
    owner_user_id UUID NOT NULL,
    collection_id UUID NOT NULL,
    saved_item_id UUID NOT NULL,
    membership_state TEXT NOT NULL DEFAULT 'ACTIVE',
    membership_version BIGINT NOT NULL DEFAULT 1,
    saved_at_snapshot TIMESTAMPTZ NOT NULL,
    removal_reason TEXT,
    added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    removed_at TIMESTAMPTZ,
    purge_eligible_at TIMESTAMPTZ,

    CONSTRAINT saved_collection_items_owner_membership_key
        UNIQUE (owner_user_id, collection_id, saved_item_id),
    CONSTRAINT saved_collection_items_owner_id_key
        UNIQUE (owner_user_id, id),
    CONSTRAINT saved_collection_items_collection_fkey
        FOREIGN KEY (owner_user_id, collection_id)
        REFERENCES saved_collections (owner_user_id, id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT saved_collection_items_saved_item_fkey
        FOREIGN KEY (owner_user_id, saved_item_id)
        REFERENCES saved_items (owner_user_id, id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT saved_collection_items_state_check
        CHECK (membership_state IN ('ACTIVE', 'REMOVED')),
    CONSTRAINT saved_collection_items_version_check
        CHECK (membership_version > 0),
    CONSTRAINT saved_collection_items_removal_reason_check
        CHECK (
            removal_reason IS NULL
            OR (
                octet_length(removal_reason) BETWEEN 1 AND 64
                AND removal_reason ~ '^[A-Z][A-Z0-9_]*$'
            )
        ),
    CONSTRAINT saved_collection_items_lifecycle_check
        CHECK (
            (
                membership_state = 'ACTIVE'
                AND removal_reason IS NULL
                AND removed_at IS NULL
                AND purge_eligible_at IS NULL
            )
            OR (
                membership_state = 'REMOVED'
                AND membership_version > 1
                AND removal_reason IS NOT NULL
                AND removed_at IS NOT NULL
                AND isfinite(removed_at)
                AND removed_at >= added_at
                AND purge_eligible_at IS NOT NULL
                AND isfinite(purge_eligible_at)
                AND purge_eligible_at = removed_at + INTERVAL '14 days'
            )
        ),
    CONSTRAINT saved_collection_items_timestamps_check
        CHECK (
            isfinite(saved_at_snapshot)
            AND isfinite(added_at)
            AND isfinite(updated_at)
            AND saved_at_snapshot <= added_at
            AND updated_at >= added_at
            AND (removed_at IS NULL OR updated_at >= removed_at)
        )
);

-- This one index defines collection item order and the first-card derived
-- preview: the server reads its first row and never stores separate cover data.
CREATE INDEX idx_saved_collection_items_active_list
    ON saved_collection_items (
        owner_user_id,
        collection_id,
        saved_at_snapshot DESC,
        saved_item_id DESC
    )
    WHERE membership_state = 'ACTIVE';

CREATE INDEX idx_saved_collection_items_owner_item_picker
    ON saved_collection_items (
        owner_user_id,
        saved_item_id,
        collection_id
    )
    WHERE membership_state = 'ACTIVE';

CREATE INDEX idx_saved_collection_items_parent_cleanup
    ON saved_collection_items (owner_user_id, collection_id, id)
    WHERE membership_state = 'ACTIVE';

CREATE INDEX idx_saved_collection_items_removed_retention
    ON saved_collection_items (purge_eligible_at, owner_user_id, id)
    WHERE membership_state = 'REMOVED';

CREATE TABLE saved_collection_usage (
    owner_user_id UUID PRIMARY KEY,
    active_collections_count BIGINT NOT NULL DEFAULT 0,
    active_memberships_count BIGINT NOT NULL DEFAULT 0,
    usage_version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT saved_collection_usage_values_check
        CHECK (
            active_collections_count >= 0
            AND active_memberships_count >= 0
            AND usage_version >= 0
            AND (
                (active_collections_count = 0 AND active_memberships_count = 0)
                OR usage_version > 0
            )
        ),
    CONSTRAINT saved_collection_usage_timestamps_check
        CHECK (
            isfinite(created_at)
            AND isfinite(updated_at)
            AND updated_at >= created_at
        )
);

-- Extend the payload-free receipt with typed precondition and result versions.
-- No collection title, desired set, query, or request payload is persisted.
ALTER TABLE saved_operations
    DROP CONSTRAINT saved_operations_kind_check,
    DROP CONSTRAINT saved_operations_outcome_code_check,
    DROP CONSTRAINT saved_operations_versions_check,
    DROP CONSTRAINT saved_operations_applied_versions_status_check,
    DROP CONSTRAINT saved_operations_status_lifecycle_check;

ALTER TABLE saved_operations
    ADD COLUMN observed_dependent_membership_version BIGINT,
    ADD COLUMN observed_collection_metadata_version BIGINT,
    ADD COLUMN observed_collection_lifecycle_version BIGINT,
    ADD COLUMN applied_dependent_membership_version BIGINT,
    ADD COLUMN applied_collection_id UUID,
    ADD COLUMN applied_collection_metadata_version BIGINT,
    ADD COLUMN applied_collection_lifecycle_version BIGINT;

ALTER TABLE saved_operations
    ADD CONSTRAINT saved_operations_kind_check
        CHECK (
            operation_kind IN (
                'SAVE_TARGET',
                'UNSAVE_TARGET',
                'SET_TARGET_COLLECTIONS',
                'CREATE_COLLECTION',
                'RENAME_COLLECTION',
                'DELETE_COLLECTION'
            )
        ),
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
                    'SAVED_COLLECTION_NOT_FOUND',
                    'SAVED_COLLECTION_DELETED',
                    'SAVED_COLLECTION_TITLE_INVALID',
                    'SAVED_COLLECTION_TITLE_CONFLICT',
                    'SAVED_COLLECTION_LIMIT_REACHED',
                    'SAVED_COLLECTION_ITEM_LIMIT_REACHED',
                    'SAVED_MEMBERSHIP_LIMIT_REACHED',
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
            AND (
                observed_dependent_membership_version IS NULL
                OR observed_dependent_membership_version >= 0
            )
            AND (
                observed_collection_metadata_version IS NULL
                OR observed_collection_metadata_version >= 0
            )
            AND (
                observed_collection_lifecycle_version IS NULL
                OR observed_collection_lifecycle_version >= 0
            )
            AND (applied_relationship_version IS NULL OR applied_relationship_version > 0)
            AND (applied_user_usage_version IS NULL OR applied_user_usage_version >= 0)
            AND (
                applied_dependent_membership_version IS NULL
                OR applied_dependent_membership_version >= 0
            )
            AND (
                applied_collection_metadata_version IS NULL
                OR applied_collection_metadata_version >= 0
            )
            AND (
                applied_collection_lifecycle_version IS NULL
                OR applied_collection_lifecycle_version >= 0
            )
            AND (
                (applied_relationship_generation IS NULL AND applied_relationship_version IS NULL)
                OR (
                    applied_relationship_generation IS NOT NULL
                    AND applied_relationship_version IS NOT NULL
                )
            )
            AND (
                applied_collection_id IS NULL
                AND applied_collection_metadata_version IS NULL
                AND applied_collection_lifecycle_version IS NULL
                OR
                applied_collection_id IS NOT NULL
                AND applied_collection_metadata_version IS NOT NULL
                AND applied_collection_lifecycle_version IS NOT NULL
            )
        ),
    ADD CONSTRAINT saved_operations_collection_kind_check
        CHECK (
            (
                observed_dependent_membership_version IS NULL
                OR operation_kind = 'SET_TARGET_COLLECTIONS'
            )
            AND (
                observed_collection_metadata_version IS NULL
                OR operation_kind IN ('RENAME_COLLECTION', 'DELETE_COLLECTION')
            )
            AND (
                observed_collection_lifecycle_version IS NULL
                OR operation_kind = 'DELETE_COLLECTION'
            )
            AND (
                observed_collection_lifecycle_version IS NULL
                OR observed_collection_metadata_version IS NOT NULL
            )
            AND (
                applied_dependent_membership_version IS NULL
                OR operation_kind IN ('UNSAVE_TARGET', 'SET_TARGET_COLLECTIONS')
            )
            AND (
                applied_collection_id IS NULL
                OR operation_kind IN (
                    'SET_TARGET_COLLECTIONS',
                    'CREATE_COLLECTION',
                    'RENAME_COLLECTION',
                    'DELETE_COLLECTION'
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
                AND applied_dependent_membership_version IS NULL
                AND applied_collection_id IS NULL
                AND applied_collection_metadata_version IS NULL
                AND applied_collection_lifecycle_version IS NULL
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
                AND observed_dependent_membership_version IS NULL
                AND observed_collection_metadata_version IS NULL
                AND observed_collection_lifecycle_version IS NULL
                AND applied_relationship_version IS NULL
                AND applied_relationship_generation IS NULL
                AND applied_user_usage_version IS NULL
                AND applied_dependent_membership_version IS NULL
                AND applied_collection_id IS NULL
                AND applied_collection_metadata_version IS NULL
                AND applied_collection_lifecycle_version IS NULL
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

-- Canonical account-purge order after this migration:
-- OUTBOX -> COLLECTION_ITEMS -> COLLECTIONS -> SAVED_ITEMS -> OPERATIONS ->
-- COLLECTION_USAGE -> USER_USAGE -> COMPLETED.
ALTER TABLE saved_subject_purge_operations
    DROP CONSTRAINT saved_subject_purge_operations_phase_check,
    ADD CONSTRAINT saved_subject_purge_operations_phase_check
        CHECK (
            phase IN (
                'OUTBOX',
                'COLLECTION_ITEMS',
                'COLLECTIONS',
                'SAVED_ITEMS',
                'OPERATIONS',
                'COLLECTION_USAGE',
                'USER_USAGE',
                'COMPLETED'
            )
        );
