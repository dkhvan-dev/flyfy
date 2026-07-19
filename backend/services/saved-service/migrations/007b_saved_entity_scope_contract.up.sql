-- Replace the original four-type constraints only after all rows satisfy the
-- final three-type contract. These metadata operations are intentionally kept
-- separate from validation so the ACCESS EXCLUSIVE lock remains short.
SET LOCAL lock_timeout = '5s';

ALTER TABLE saved_content_projections
    DROP CONSTRAINT saved_content_projections_entity_type_check;
ALTER TABLE saved_content_projections
    RENAME CONSTRAINT saved_content_projections_supported_type_v2_check
        TO saved_content_projections_entity_type_check;

ALTER TABLE saved_items
    DROP CONSTRAINT saved_items_entity_type_check;
ALTER TABLE saved_items
    RENAME CONSTRAINT saved_items_supported_type_v2_check
        TO saved_items_entity_type_check;

ALTER TABLE saved_outbox
    DROP CONSTRAINT saved_outbox_entity_type_check;
ALTER TABLE saved_outbox
    RENAME CONSTRAINT saved_outbox_supported_type_v2_check
        TO saved_outbox_entity_type_check;
