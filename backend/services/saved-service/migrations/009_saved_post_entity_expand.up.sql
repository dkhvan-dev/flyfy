-- Expand the closed Saved target scope without validating historical rows
-- while holding an ACCESS EXCLUSIVE lock.
SET LOCAL lock_timeout = '5s';

ALTER TABLE saved_content_projections
    ADD CONSTRAINT saved_content_projections_supported_type_v4_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')) NOT VALID;

ALTER TABLE saved_items
    ADD CONSTRAINT saved_items_supported_type_v4_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')) NOT VALID;

ALTER TABLE saved_outbox
    ADD CONSTRAINT saved_outbox_supported_type_v4_check
        CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')) NOT VALID;
