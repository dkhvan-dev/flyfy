-- visit_info v2: convert openingHours from a string code to a structured object.
-- The unmarshaller now expects an object; any remaining string value would break reads.
-- New v2 fields (season, gettingThere, included, excluded, links) are additive and
-- populated per-place by the content backfill, not here.

UPDATE places
SET
    visit_info = jsonb_set(
        visit_info,
        '{openingHours}',
        jsonb_build_object(
            'summary', jsonb_build_object(
                'en', 'Check current hours',
                'ru', 'Уточняйте актуальные часы',
                'kk', 'Ағымдағы жұмыс уақытын нақтылаңыз'
            )
        ),
        true
    ),
    updated_at = NOW()
WHERE jsonb_typeof(visit_info -> 'openingHours') = 'string';
