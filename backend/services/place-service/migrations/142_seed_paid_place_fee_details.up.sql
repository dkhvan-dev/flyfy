WITH paid_place_fee_profiles AS (
    SELECT
        id,
        price_amount,
        UPPER(price_currency) AS price_currency,
        CASE
            WHEN category IN ('MUSEUM')
                OR tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology']::text[]
                THEN 'Museum or heritage ticket'
            WHEN category IN ('ENTERTAINMENT')
                OR tags && ARRAY['amusement-park','rides','zoo','cable-car','skating','ski','snowboard','show','theme-park']::text[]
                THEN 'Attraction ticket'
            WHEN category IN ('FOOD','MARKET')
                OR tags && ARRAY['food','market','coffee','tasting','village']::text[]
                THEN 'Tasting or experience ticket'
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Natural area access'
            ELSE 'Entry or basic access'
        END AS title_en,
        CASE
            WHEN category IN ('MUSEUM')
                OR tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology']::text[]
                THEN 'Билет в музей или объект наследия'
            WHEN category IN ('ENTERTAINMENT')
                OR tags && ARRAY['amusement-park','rides','zoo','cable-car','skating','ski','snowboard','show','theme-park']::text[]
                THEN 'Билет на аттракцион или площадку'
            WHEN category IN ('FOOD','MARKET')
                OR tags && ARRAY['food','market','coffee','tasting','village']::text[]
                THEN 'Билет на дегустацию или опыт'
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Доступ к природной территории'
            ELSE 'Вход или базовый доступ'
        END AS title_ru,
        CASE
            WHEN category IN ('MUSEUM')
                OR tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology']::text[]
                THEN 'Музейге немесе мұра нысанына билет'
            WHEN category IN ('ENTERTAINMENT')
                OR tags && ARRAY['amusement-park','rides','zoo','cable-car','skating','ski','snowboard','show','theme-park']::text[]
                THEN 'Аттракционға немесе алаңға билет'
            WHEN category IN ('FOOD','MARKET')
                OR tags && ARRAY['food','market','coffee','tasting','village']::text[]
                THEN 'Дегустацияға немесе тәжірибеге билет'
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Табиғи аумаққа кіру'
            ELSE 'Кіру немесе негізгі қолжетімділік'
        END AS title_kk,
        CASE
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Approximate starting access cost; transport, parking, guides, permits, and seasonal services may be charged separately'
            ELSE 'Approximate starting cost for the paid part of the visit; extras and seasonal services may be charged separately'
        END AS description_en,
        CASE
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Примерная стартовая стоимость доступа; транспорт, парковка, гиды, разрешения и сезонные услуги могут оплачиваться отдельно'
            ELSE 'Примерная стартовая стоимость платной части визита; дополнительные и сезонные услуги могут оплачиваться отдельно'
        END AS description_ru,
        CASE
            WHEN category IN ('NATURE','PARK')
                OR tags && ARRAY['nature','park','national-park','hiking','trekking','walking','canyon','lake','waterfall','forest','gorge']::text[]
                THEN 'Кірудің шамамен бастапқы құны; көлік, тұрақ, гидтер, рұқсаттар және маусымдық қызметтер бөлек төленуі мүмкін'
            ELSE 'Сапардың ақылы бөлігіне шамамен бастапқы құн; қосымша және маусымдық қызметтер бөлек төленуі мүмкін'
        END AS description_kk,
        CASE
            WHEN category IN ('ENTERTAINMENT')
                OR tags && ARRAY['amusement-park','rides','zoo','cable-car','skating','ski','snowboard','show','theme-park']::text[]
                THEN 'TICKET'
            ELSE 'PERSON'
        END AS unit
    FROM places
    WHERE deleted_at IS NULL
      AND price_amount IS NOT NULL
      AND price_amount > 0
      AND price_currency IS NOT NULL
      AND TRIM(price_currency) <> ''
      AND NOT (visit_info ? 'feeDetails')
)
UPDATE places p
SET
    visit_info = jsonb_set(
        COALESCE(p.visit_info, '{}'::jsonb),
        '{feeDetails}',
        jsonb_build_array(
            jsonb_build_object(
                'title', jsonb_build_object(
                    'en', paid.title_en,
                    'ru', paid.title_ru,
                    'kk', paid.title_kk
                ),
                'description', jsonb_build_object(
                    'en', paid.description_en,
                    'ru', paid.description_ru,
                    'kk', paid.description_kk
                ),
                'amount', paid.price_amount,
                'currency', paid.price_currency,
                'unit', paid.unit,
                'isApproximate', true,
                'sortOrder', 10
            )
        ),
        true
    ),
    updated_at = NOW()
FROM paid_place_fee_profiles paid
WHERE p.id = paid.id;
