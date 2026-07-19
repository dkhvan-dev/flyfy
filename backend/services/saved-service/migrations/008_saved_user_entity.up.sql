-- GUIDE targets have always used the guide's user_id. Canonicalize them to
-- USER before the universal profile-saving client is enabled, so one profile
-- cannot exist twice in a user's Saved list under different entity types.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30min';

DO $saved_user_entity_precondition$
BEGIN
    IF EXISTS (
        SELECT 1 FROM saved_content_projections WHERE entity_type = 'USER'
        UNION ALL
        SELECT 1 FROM saved_items WHERE entity_type = 'USER'
        UNION ALL
        SELECT 1 FROM saved_outbox WHERE entity_type = 'USER'
        LIMIT 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '55000',
            MESSAGE = 'USER Saved rows exist before migration 008; audit duplicate profile identities before retrying';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM saved_content_projections
        WHERE entity_type = 'GUIDE'
          AND (
              entity_id = '00000000-0000-0000-0000-000000000000'
              OR entity_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          )
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '55000',
            MESSAGE = 'non-canonical GUIDE user_id exists before migration 008; audit target identity before retrying';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM saved_content_projections
        WHERE entity_type = 'GUIDE'
          AND media_reference IS NOT NULL
          AND media_reference !~ (
              '^guide-avatar:' || entity_id ||
              ':[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:[1-9][0-9]*$'
          )
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '55000',
            MESSAGE = 'malformed GUIDE avatar reference exists before migration 008; audit media identity before retrying';
    END IF;
END
$saved_user_entity_precondition$;

ALTER TABLE saved_items
    DROP CONSTRAINT saved_items_projection_fkey;

ALTER TABLE saved_content_projections
    DROP CONSTRAINT saved_content_projections_entity_type_check;
ALTER TABLE saved_items
    DROP CONSTRAINT saved_items_entity_type_check;
ALTER TABLE saved_outbox
    DROP CONSTRAINT saved_outbox_entity_type_check;

UPDATE saved_content_projections
SET entity_type = 'USER',
    source_service = 'user-service',
    -- Revisions from guide-service and user-service are different source
    -- namespaces. Rebase to a positive floor so current cards stay readable
    -- while the next user-service timestamp revision always advances them.
    source_revision = 1,
    projection_revision = 1,
    visibility_revision = 1,
    media_reference = CASE
        WHEN media_reference IS NULL THEN NULL
        ELSE 'user-avatar:' || substr(
            media_reference,
            char_length('guide-avatar:') + 1
        )
    END,
    canonical_detail_route = CASE
        WHEN canonical_detail_route IS NULL THEN NULL
        ELSE '/users/' || entity_id || '/profile'
    END,
    reconciliation_lease_token = NULL,
    reconciliation_lease_expires_at = NULL,
    reconciliation_last_attempt_at = NULL,
    reconciliation_next_attempt_at = CURRENT_TIMESTAMP,
    reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL,
    updated_at = GREATEST(updated_at, CURRENT_TIMESTAMP)
WHERE entity_type = 'GUIDE';

UPDATE saved_items
SET entity_type = 'USER',
    updated_at = GREATEST(updated_at, CURRENT_TIMESTAMP)
WHERE entity_type = 'GUIDE';

UPDATE saved_outbox
SET entity_type = 'USER',
    updated_at = GREATEST(updated_at, CURRENT_TIMESTAMP)
WHERE entity_type = 'GUIDE';

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;
ALTER TABLE saved_items
    ADD CONSTRAINT saved_items_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;
ALTER TABLE saved_outbox
    ADD CONSTRAINT saved_outbox_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;

ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_entity_type_check;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_entity_type_check;
ALTER TABLE saved_outbox
    VALIDATE CONSTRAINT saved_outbox_entity_type_check;

ALTER TABLE saved_items
    ADD CONSTRAINT saved_items_projection_fkey
        FOREIGN KEY (entity_type, entity_id)
        REFERENCES saved_content_projections (entity_type, entity_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
        NOT VALID;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_projection_fkey;
