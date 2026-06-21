ALTER TABLE checklist_instances
    ADD COLUMN transport_modes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN activity_slugs TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN has_children BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX idx_checklist_instances_user_start_at
    ON checklist_instances (user_id, start_at, updated_at DESC)
    WHERE start_at IS NOT NULL;
