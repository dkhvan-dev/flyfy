DROP INDEX IF EXISTS idx_checklist_instance_items_assignee;
DROP INDEX IF EXISTS idx_checklist_instances_start_at;

ALTER TABLE checklist_instance_items
    DROP COLUMN IF EXISTS assigned_user_id;

ALTER TABLE checklist_instances
    DROP COLUMN IF EXISTS destination,
    DROP COLUMN IF EXISTS end_at,
    DROP COLUMN IF EXISTS start_at;
