-- VALIDATE CONSTRAINT permits normal reads and writes while scanning rows.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30min';

ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_supported_type_v4_check;
ALTER TABLE saved_items
    VALIDATE CONSTRAINT saved_items_supported_type_v4_check;
ALTER TABLE saved_outbox
    VALIDATE CONSTRAINT saved_outbox_supported_type_v4_check;
