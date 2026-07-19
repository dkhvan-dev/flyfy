-- Removing POST from the closed scope is safe only before any POST data exists.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM saved_content_projections WHERE entity_type = 'POST')
        OR EXISTS (SELECT 1 FROM saved_items WHERE entity_type = 'POST')
        OR EXISTS (SELECT 1 FROM saved_outbox WHERE entity_type = 'POST') THEN
        RAISE EXCEPTION USING
            ERRCODE = 'check_violation',
            MESSAGE = 'migration 009b is irreversible while POST Saved data exists';
    END IF;
END;
$$;

SET LOCAL lock_timeout = '5s';

ALTER TABLE saved_content_projections
    DROP CONSTRAINT saved_content_projections_entity_type_check,
    ADD CONSTRAINT saved_content_projections_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;
ALTER TABLE saved_items
    DROP CONSTRAINT saved_items_entity_type_check,
    ADD CONSTRAINT saved_items_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;
ALTER TABLE saved_outbox
    DROP CONSTRAINT saved_outbox_entity_type_check,
    ADD CONSTRAINT saved_outbox_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID;

ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_entity_type_check;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_entity_type_check;
ALTER TABLE saved_outbox
    VALIDATE CONSTRAINT saved_outbox_entity_type_check;
