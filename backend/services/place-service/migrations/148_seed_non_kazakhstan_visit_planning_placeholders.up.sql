-- Temporary visit-planning placeholders for non-Kazakhstan imported places.
-- These rows are deliberately generic and marked so country-specific migrations can replace them later.

UPDATE places p
SET
    visit_info = jsonb_set(
        jsonb_set(
            jsonb_set(
                COALESCE(p.visit_info, '{}'::jsonb),
                '{priceNote}',
                CASE
                    WHEN COALESCE(p.visit_info, '{}'::jsonb) ? 'priceNote'
                        THEN p.visit_info -> 'priceNote'
                    ELSE jsonb_build_object(
                        'ru', 'Проверьте актуальные часы, цену и правила посещения перед поездкой',
                        'en', 'Check current opening hours, prices and visit rules before the trip',
                        'kk', 'Сапар алдында өзекті жұмыс уақытын, бағаны және келу ережелерін тексеріңіз'
                    )
                END,
                true
            ),
            '{practicalNotes}',
            CASE
                WHEN COALESCE(p.visit_info, '{}'::jsonb) ? 'practicalNotes'
                    THEN p.visit_info -> 'practicalNotes'
                ELSE jsonb_build_array(
                    jsonb_build_object(
                        'marker', 'TEMPORARY_PLACEHOLDER',
                        'noteType', 'TEMPORARY_PLACEHOLDER',
                        'title', jsonb_build_object(
                            'ru', 'Временная памятка',
                            'en', 'Temporary note',
                            'kk', 'Уақытша ескерту'
                        ),
                        'body', jsonb_build_object(
                            'ru', 'Проверьте актуальные часы, цену и правила посещения перед поездкой',
                            'en', 'Check current opening hours, prices and visit rules before the trip',
                            'kk', 'Сапар алдында өзекті жұмыс уақытын, бағаны және келу ережелерін тексеріңіз'
                        ),
                        'priority', 'IMPORTANT',
                        'sortOrder', 10
                    )
                )
            END,
            true
        ),
        '{recommendedItems}',
        CASE
            WHEN COALESCE(p.visit_info, '{}'::jsonb) ? 'recommendedItems'
                THEN p.visit_info -> 'recommendedItems'
            ELSE jsonb_build_array(
                jsonb_build_object(
                    'marker', 'TEMPORARY_PLACEHOLDER',
                    'itemType', 'WATER',
                    'title', jsonb_build_object('ru', 'Вода', 'en', 'Water', 'kk', 'Су'),
                    'importance', 'RECOMMENDED',
                    'sortOrder', 10
                ),
                jsonb_build_object(
                    'marker', 'TEMPORARY_PLACEHOLDER',
                    'itemType', 'SHOES',
                    'title', jsonb_build_object('ru', 'Удобная обувь', 'en', 'Comfortable shoes', 'kk', 'Ыңғайлы аяқ киім'),
                    'importance', 'RECOMMENDED',
                    'sortOrder', 20
                ),
                jsonb_build_object(
                    'marker', 'TEMPORARY_PLACEHOLDER',
                    'itemType', 'POWERBANK',
                    'title', jsonb_build_object('ru', 'Powerbank', 'en', 'Power bank', 'kk', 'Powerbank'),
                    'importance', 'RECOMMENDED',
                    'sortOrder', 30
                )
            )
        END,
        true
    ),
    updated_at = NOW()
WHERE p.country_code <> 'KZ'
  AND p.deleted_at IS NULL;
