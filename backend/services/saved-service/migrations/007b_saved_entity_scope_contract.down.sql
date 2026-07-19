SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30min';

ALTER TABLE saved_content_projections
    RENAME CONSTRAINT saved_content_projections_entity_type_check
        TO saved_content_projections_supported_type_v2_check;
ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'EXCURSION', 'GUIDE')) NOT VALID;
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_entity_type_check;

ALTER TABLE saved_items
    RENAME CONSTRAINT saved_items_entity_type_check
        TO saved_items_supported_type_v2_check;
ALTER TABLE saved_items
    ADD CONSTRAINT saved_items_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'EXCURSION', 'GUIDE')) NOT VALID;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_entity_type_check;

ALTER TABLE saved_outbox
    RENAME CONSTRAINT saved_outbox_entity_type_check
        TO saved_outbox_supported_type_v2_check;
ALTER TABLE saved_outbox
    ADD CONSTRAINT saved_outbox_entity_type_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'EXCURSION', 'GUIDE')) NOT VALID;
ALTER TABLE saved_outbox
    VALIDATE CONSTRAINT saved_outbox_entity_type_check;
