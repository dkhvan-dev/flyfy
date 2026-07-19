-- USER covers guides and non-guides, so an automatic USER -> GUIDE rewrite
-- would corrupt identity semantics. A rollback is safe only before USER data
-- exists; otherwise keep the compatible application deployed and roll forward.
SET LOCAL lock_timeout = '5s';

DO $saved_user_entity_down_precondition$
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
            MESSAGE = 'migration 008 is irreversible while USER Saved data exists';
    END IF;
END
$saved_user_entity_down_precondition$;

ALTER TABLE saved_content_projections
    DROP CONSTRAINT saved_content_projections_entity_type_check,
    ADD CONSTRAINT saved_content_projections_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;
ALTER TABLE saved_items
    DROP CONSTRAINT saved_items_entity_type_check,
    ADD CONSTRAINT saved_items_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;
ALTER TABLE saved_outbox
    DROP CONSTRAINT saved_outbox_entity_type_check,
    ADD CONSTRAINT saved_outbox_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;

ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_entity_type_check;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_entity_type_check;
ALTER TABLE saved_outbox
    VALIDATE CONSTRAINT saved_outbox_entity_type_check;
