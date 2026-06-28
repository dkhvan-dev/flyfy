ALTER TABLE checklist_instances
    DROP CONSTRAINT IF EXISTS checklist_instances_citizenship_country_code_format;

ALTER TABLE checklist_instances
    DROP COLUMN IF EXISTS citizenship_country_code;
