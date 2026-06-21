DROP INDEX IF EXISTS idx_checklist_instances_user_start_at;

ALTER TABLE checklist_instances
    DROP COLUMN IF EXISTS has_children,
    DROP COLUMN IF EXISTS activity_slugs,
    DROP COLUMN IF EXISTS transport_modes;
