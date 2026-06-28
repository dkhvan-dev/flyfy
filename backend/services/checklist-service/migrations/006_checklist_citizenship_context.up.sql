ALTER TABLE checklist_instances
    ADD COLUMN citizenship_country_code TEXT NOT NULL DEFAULT '';

ALTER TABLE checklist_instances
    ADD CONSTRAINT checklist_instances_citizenship_country_code_format
    CHECK (
        citizenship_country_code = ''
        OR citizenship_country_code = upper(citizenship_country_code)
    );
