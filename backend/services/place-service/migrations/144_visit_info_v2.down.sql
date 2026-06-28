-- Revert openingHours objects that only carry the generated "check current hours"
-- summary back to the legacy string sentinel. Rows with richer per-place hours are
-- left as objects (the legacy schema cannot represent them).

UPDATE places
SET
    visit_info = jsonb_set(visit_info, '{openingHours}', '"CHECK_CURRENT"'::jsonb, true),
    updated_at = NOW()
WHERE jsonb_typeof(visit_info -> 'openingHours') = 'object'
  AND (visit_info -> 'openingHours') - 'summary' = '{}'::jsonb
  AND (visit_info -> 'openingHours' -> 'summary' -> 'en') = '"Check current hours"'::jsonb;
