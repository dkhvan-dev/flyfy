WITH parsed AS (
    SELECT
        staff_id,
        regexp_split_to_array(btrim(display_name), '\s+') AS parts
    FROM support_agents
    WHERE btrim(display_name) <> ''
      AND array_length(regexp_split_to_array(btrim(display_name), '\s+'), 1) >= 2
)
UPDATE support_agents AS agent
SET
    first_name = parsed.parts[2],
    last_name = parsed.parts[1],
    middle_name = CASE
        WHEN btrim(agent.middle_name) = ''
            THEN COALESCE(NULLIF(array_to_string(parsed.parts[3:], ' '), ''), '')
        ELSE agent.middle_name
    END
FROM parsed
WHERE agent.staff_id = parsed.staff_id
  AND btrim(agent.first_name) = parsed.parts[1]
  AND btrim(agent.last_name) = parsed.parts[2];
