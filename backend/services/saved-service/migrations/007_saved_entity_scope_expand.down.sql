SET LOCAL lock_timeout = '5s';

ALTER TABLE saved_outbox
    DROP CONSTRAINT IF EXISTS saved_outbox_supported_type_v2_check;
ALTER TABLE saved_items
    DROP CONSTRAINT IF EXISTS saved_items_supported_type_v2_check;
ALTER TABLE saved_content_projections
    DROP CONSTRAINT IF EXISTS saved_content_projections_supported_type_v2_check;
