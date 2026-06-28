ALTER TABLE support_agents
    ADD COLUMN IF NOT EXISTS first_name TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS last_name TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS middle_name TEXT NOT NULL DEFAULT '';

UPDATE support_agents
SET
    first_name = CASE
        WHEN first_name = '' THEN COALESCE(NULLIF(split_part(btrim(display_name), ' ', 2), ''), '')
        ELSE first_name
    END,
    last_name = CASE
        WHEN last_name = '' THEN COALESCE(NULLIF(split_part(btrim(display_name), ' ', 1), ''), '')
        ELSE last_name
    END,
    middle_name = CASE
        WHEN middle_name = '' THEN COALESCE(NULLIF(array_to_string((regexp_split_to_array(btrim(display_name), '\s+'))[3:], ' '), ''), '')
        ELSE middle_name
    END
WHERE btrim(display_name) <> ''
  AND array_length(regexp_split_to_array(btrim(display_name), '\s+'), 1) >= 2;
