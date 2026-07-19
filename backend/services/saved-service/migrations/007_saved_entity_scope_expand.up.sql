-- Add the final three-type Saved scope without rewriting tables or changing
-- already-applied migration checksums. NOT VALID still rejects new unsupported
-- rows immediately; validation is isolated in the next migration.
SET LOCAL lock_timeout = '5s';

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_supported_type_v2_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;

ALTER TABLE saved_items
    ADD CONSTRAINT saved_items_supported_type_v2_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;

ALTER TABLE saved_outbox
    ADD CONSTRAINT saved_outbox_supported_type_v2_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID;
