UPDATE places p
SET
    visit_info = (
        CASE
            WHEN COALESCE(p.visit_info, '{}'::jsonb) -> 'practicalNotes' @> '[{"marker":"TEMPORARY_PLACEHOLDER"}]'::jsonb
                THEN COALESCE(p.visit_info, '{}'::jsonb) - 'practicalNotes'
            ELSE COALESCE(p.visit_info, '{}'::jsonb)
        END
    ),
    updated_at = NOW()
WHERE p.country_code <> 'KZ'
  AND p.deleted_at IS NULL;

UPDATE places p
SET
    visit_info = (
        CASE
            WHEN COALESCE(p.visit_info, '{}'::jsonb) -> 'recommendedItems' @> '[{"marker":"TEMPORARY_PLACEHOLDER"}]'::jsonb
                THEN COALESCE(p.visit_info, '{}'::jsonb) - 'recommendedItems'
            ELSE COALESCE(p.visit_info, '{}'::jsonb)
        END
    ),
    updated_at = NOW()
WHERE p.country_code <> 'KZ'
  AND p.deleted_at IS NULL;

UPDATE places p
SET
    visit_info = COALESCE(p.visit_info, '{}'::jsonb) - 'priceNote',
    updated_at = NOW()
WHERE p.country_code <> 'KZ'
  AND p.deleted_at IS NULL
  AND COALESCE(p.visit_info, '{}'::jsonb) -> 'priceNote' = jsonb_build_object(
      'ru', 'Проверьте актуальные часы, цену и правила посещения перед поездкой',
      'en', 'Check current opening hours, prices and visit rules before the trip',
      'kk', 'Сапар алдында өзекті жұмыс уақытын, бағаны және келу ережелерін тексеріңіз'
  );
