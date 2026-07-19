BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '5min';

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM guide_saved_lifecycle_outbox
        WHERE status IN ('PENDING', 'PROCESSING', 'DEAD')
    ) THEN
        RAISE EXCEPTION 'cannot remove Saved lifecycle outbox with undelivered or dead events'
            USING ERRCODE = '55000';
    END IF;
    IF EXISTS (SELECT 1 FROM guide_profiles WHERE deleted_at IS NOT NULL) THEN
        RAISE EXCEPTION 'cannot remove Saved lifecycle schema while soft-deleted guides exist'
            USING ERRCODE = '55000';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_guide_saved_outbox_no_delete_before_terminal ON guide_saved_lifecycle_outbox;
DROP TRIGGER IF EXISTS trg_guide_saved_outbox_semantics_immutable ON guide_saved_lifecycle_outbox;
DROP TRIGGER IF EXISTS trg_guide_saved_verification_deleted ON guide_verification_requests;
DROP TRIGGER IF EXISTS trg_guide_saved_verification_updated ON guide_verification_requests;
DROP TRIGGER IF EXISTS trg_guide_saved_verification_inserted ON guide_verification_requests;
DROP TRIGGER IF EXISTS trg_guide_saved_profile_deleting ON guide_profiles;
DROP TRIGGER IF EXISTS trg_guide_saved_profile_updated ON guide_profiles;
DROP TRIGGER IF EXISTS trg_guide_saved_profile_inserted ON guide_profiles;
DROP TRIGGER IF EXISTS trg_guide_saved_emit_state_event ON guide_saved_lifecycle_state;
DROP TRIGGER IF EXISTS trg_guide_saved_prepare_state ON guide_saved_lifecycle_state;

DROP FUNCTION IF EXISTS guide_saved_outbox_no_delete_before_terminal();
DROP FUNCTION IF EXISTS guide_saved_outbox_semantics_immutable();
DROP FUNCTION IF EXISTS guide_saved_verification_lifecycle_changed();
DROP FUNCTION IF EXISTS guide_saved_profile_deleting();
DROP FUNCTION IF EXISTS guide_saved_profile_lifecycle_changed();
DROP FUNCTION IF EXISTS guide_saved_emit_state_event();
DROP FUNCTION IF EXISTS guide_saved_prepare_state();
DROP FUNCTION IF EXISTS guide_saved_effective_visibility(UUID, BOOLEAN, TEXT, BOOLEAN, BOOLEAN);
DROP FUNCTION IF EXISTS guide_saved_revision_floor(TIMESTAMPTZ);

DROP TABLE IF EXISTS guide_saved_lifecycle_outbox;
DROP TABLE IF EXISTS guide_saved_lifecycle_state;

ALTER TABLE guide_profiles
    DROP COLUMN IF EXISTS deleted_at;

COMMIT;
