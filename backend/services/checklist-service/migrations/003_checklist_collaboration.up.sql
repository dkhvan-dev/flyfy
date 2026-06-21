ALTER TABLE checklist_instances
    ADD COLUMN start_at TIMESTAMPTZ,
    ADD COLUMN end_at TIMESTAMPTZ,
    ADD COLUMN destination JSONB;

ALTER TABLE checklist_instance_items
    ADD COLUMN assigned_user_id TEXT;

CREATE INDEX idx_checklist_instances_start_at
    ON checklist_instances (start_at)
    WHERE start_at IS NOT NULL;

CREATE INDEX idx_checklist_instance_items_assignee
    ON checklist_instance_items (instance_id, assigned_user_id)
    WHERE assigned_user_id IS NOT NULL;
