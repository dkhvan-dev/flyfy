ALTER TABLE attractions
    ADD COLUMN IF NOT EXISTS visit_info JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_attractions_visit_info
    ON attractions USING GIN (visit_info)
    WHERE deleted_at IS NULL;

UPDATE attractions
SET visit_info = jsonb_strip_nulls(jsonb_build_object(
    'bestTime',
        CASE
            WHEN category IN ('BEACH', 'PARK') THEN 'MORNING'
            WHEN category IN ('ARCHITECTURE', 'ENTERTAINMENT', 'FOOD', 'SHOPPING') THEN 'AFTERNOON'
            ELSE 'EARLY_MORNING'
        END,
    'accessibility',
        CASE
            WHEN category IN ('ARCHITECTURE', 'MUSEUM', 'TEMPLE', 'ENTERTAINMENT', 'FOOD', 'SHOPPING') THEN 'GOOD'
            ELSE 'LIMITED'
        END,
    'bookingRequired',
        CASE
            WHEN category IN ('NATURE', 'BEACH') OR duration_unit = 'DAYS' THEN to_jsonb(TRUE)
            ELSE to_jsonb(FALSE)
        END,
    'openingHours', 'CHECK_CURRENT',
    'amenities',
        CASE
            WHEN category IN ('ARCHITECTURE', 'MUSEUM', 'TEMPLE', 'ENTERTAINMENT', 'FOOD', 'SHOPPING') THEN '["RESTROOMS","CAFE_NEARBY"]'::jsonb
            WHEN category IN ('BEACH', 'PARK') THEN '["RESTROOMS","PARKING"]'::jsonb
            ELSE '["PARKING","GUIDE_RECOMMENDED"]'::jsonb
        END,
    'audience',
        CASE
            WHEN category IN ('MUSEUM', 'TEMPLE', 'ARCHITECTURE') THEN '["HISTORY","PHOTO"]'::jsonb
            WHEN category IN ('ENTERTAINMENT', 'FOOD', 'SHOPPING') THEN '["FAMILY","COUPLES"]'::jsonb
            ELSE '["OUTDOOR","PHOTO"]'::jsonb
        END,
    'safetyNotes',
        CASE
            WHEN category IN ('NATURE', 'BEACH') OR duration_unit = 'DAYS' THEN '["CHECK_WEATHER","BRING_WATER"]'::jsonb
            ELSE '["CHECK_HOURS"]'::jsonb
        END,
    'nearbyIds', '[]'::jsonb,
    'localizedTips',
        CASE
            WHEN category IN ('NATURE', 'BEACH') OR duration_unit = 'DAYS' THEN jsonb_build_object(
                'en', 'Plan transport and weather before you go; guided routes are usually safer and more predictable.',
                'ru', 'Заранее проверьте транспорт и погоду: с гидом маршрут обычно безопаснее и предсказуемее.',
                'kk', 'Жолға шығар алдында көлік пен ауа райын тексеріңіз: гидпен бағыт әдетте қауіпсіз әрі болжамды.'
            )
            WHEN category IN ('MUSEUM', 'TEMPLE', 'ARCHITECTURE') THEN jsonb_build_object(
                'en', 'Come earlier in the day for calmer photos and leave time for nearby cultural stops.',
                'ru', 'Приходите пораньше: будет спокойнее для фото, а рядом останется время на культурные точки.',
                'kk', 'Ертерек келіңіз: фотоға ыңғайлырақ, әрі жақын мәдени орындарға уақыт қалады.'
            )
            ELSE jsonb_build_object(
                'en', 'Check current hours and combine this stop with nearby activities to avoid losing time in transit.',
                'ru', 'Проверьте актуальное расписание и совместите локацию с соседними активностями, чтобы не терять время на дорогу.',
                'kk', 'Ағымдағы кестені тексеріп, жолға уақыт жоғалтпау үшін жақын белсенділіктермен біріктіріңіз.'
            )
        END
))
WHERE visit_info = '{}'::jsonb;
