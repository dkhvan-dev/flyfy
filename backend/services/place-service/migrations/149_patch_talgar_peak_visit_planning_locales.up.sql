-- Forward patch for databases where 147 was already applied before
-- Talgar Peak visit-planning text gained en/kk localized values.

CREATE TEMP TABLE seed_talgar_peak_visit_planning (
    slug text PRIMARY KEY,
    price_amount numeric NULL,
    visit_info jsonb NOT NULL
);

INSERT INTO seed_talgar_peak_visit_planning (slug, price_amount, visit_info)
VALUES (
    'talgar-peak-base-trail',
    650,
    $${
        "bestTime": "MORNING",
        "season": {
            "months": [7, 8, 9],
            "note": {
                "ru": "июль–сентябрь; только при устойчивой погоде",
                "en": "July-September; only in stable weather",
                "kk": "Шілде-қыркүйек; тек тұрақты ауа райында"
            }
        },
        "openingHours": {
            "summary": {
                "ru": "КПП/офис: обычно 09:00–18:00; маршруты — в световой день",
                "en": "Checkpoint/office: usually 09:00-18:00; routes in daylight",
                "kk": "Бекет/кеңсе: әдетте 09:00-18:00; маршруттар күндізгі уақытта"
            }
        },
        "priceNote": {
            "ru": "пешеход 0,15 МРП/сутки; легковой авто 0,3 МРП; округлено вверх до 50 ₸",
            "en": "Pedestrian 0.15 MCI per day; passenger car 0.3 MCI; rounded up to the nearest 50 ₸",
            "kk": "Жаяу келуші күніне 0,15 АЕК; жеңіл авто 0,3 АЕК; 50 ₸-ге дейін жоғары дөңгелектелген"
        },
        "timeOnSite": {
            "note": {
                "ru": "6–10+ ч пешком; полный день",
                "en": "6-10+ h on foot; full day",
                "kk": "6-10+ сағ жаяу; толық күн"
            }
        },
        "carTravelTime": {
            "minMinutes": 30,
            "maxMinutes": 90,
            "note": {
                "ru": "30–90 мин до старта",
                "en": "30-90 min to trailhead",
                "kk": "Бастау нүктесіне дейін 30-90 мин"
            }
        },
        "roadCondition": "MOUNTAIN",
        "feeItems": [
            {
                "type": "ENTRANCE",
                "title": {
                    "ru": "Вход / базовый билет",
                    "en": "Entrance / base ticket",
                    "kk": "Кіру / негізгі билет"
                },
                "description": {
                    "ru": "пешеход 0,15 МРП/сутки; легковой авто 0,3 МРП; округлено вверх до 50 ₸",
                    "en": "Pedestrian 0.15 MCI per day; passenger car 0.3 MCI; rounded up to the nearest 50 ₸",
                    "kk": "Жаяу келуші күніне 0,15 АЕК; жеңіл авто 0,3 АЕК; 50 ₸-ге дейін жоғары дөңгелектелген"
                },
                "minAmount": 650,
                "maxAmount": 650,
                "currency": "KZT",
                "unit": "PERSON",
                "required": true,
                "isApproximate": true,
                "note": {
                    "ru": "пешеход 0,15 МРП/сутки; легковой авто 0,3 МРП; округлено вверх до 50 ₸",
                    "en": "Pedestrian 0.15 MCI per day; passenger car 0.3 MCI; rounded up to the nearest 50 ₸",
                    "kk": "Жаяу келуші күніне 0,15 АЕК; жеңіл авто 0,3 АЕК; 50 ₸-ге дейін жоғары дөңгелектелген"
                },
                "sortOrder": 10
            },
            {
                "type": "TRANSPORT",
                "title": {
                    "ru": "Авто / доп. транспорт",
                    "en": "Car / additional transport",
                    "kk": "Авто / қосымша көлік"
                },
                "description": {
                    "ru": "Дополнительный транспорт, въезд авто, канатная дорога или местный трансфер по маршруту",
                    "en": "Additional transport, vehicle entry, cable car or local transfer on the route",
                    "kk": "Бағыттағы қосымша көлік, автокөлікпен кіру, аспалы жол немесе жергілікті трансфер"
                },
                "minAmount": 1300,
                "maxAmount": 1300,
                "currency": "KZT",
                "unit": "CAR",
                "required": false,
                "isApproximate": true,
                "note": {
                    "ru": "пешеход 0,15 МРП/сутки; легковой авто 0,3 МРП; округлено вверх до 50 ₸",
                    "en": "Pedestrian 0.15 MCI per day; passenger car 0.3 MCI; rounded up to the nearest 50 ₸",
                    "kk": "Жаяу келуші күніне 0,15 АЕК; жеңіл авто 0,3 АЕК; 50 ₸-ге дейін жоғары дөңгелектелген"
                },
                "sortOrder": 20
            }
        ],
        "feeDetails": [
            {
                "title": {
                    "ru": "Вход / базовый билет",
                    "en": "Entrance / base ticket",
                    "kk": "Кіру / негізгі билет"
                },
                "description": {
                    "ru": "пешеход 0,15 МРП/сутки; легковой авто 0,3 МРП; округлено вверх до 50 ₸",
                    "en": "Pedestrian 0.15 MCI per day; passenger car 0.3 MCI; rounded up to the nearest 50 ₸",
                    "kk": "Жаяу келуші күніне 0,15 АЕК; жеңіл авто 0,3 АЕК; 50 ₸-ге дейін жоғары дөңгелектелген"
                },
                "amount": 650,
                "currency": "KZT",
                "unit": "PERSON",
                "isApproximate": true,
                "sortOrder": 10
            },
            {
                "title": {
                    "ru": "Авто / доп. транспорт",
                    "en": "Car / additional transport",
                    "kk": "Авто / қосымша көлік"
                },
                "description": {
                    "ru": "Дополнительный транспорт, въезд авто, канатная дорога или местный трансфер по маршруту",
                    "en": "Additional transport, vehicle entry, cable car or local transfer on the route",
                    "kk": "Бағыттағы қосымша көлік, автокөлікпен кіру, аспалы жол немесе жергілікті трансфер"
                },
                "amount": 1300,
                "currency": "KZT",
                "unit": "CAR",
                "isApproximate": true,
                "sortOrder": 20
            }
        ],
        "accessOptions": [
            {
                "transportType": "CAR",
                "durationMinMinutes": 30,
                "durationMaxMinutes": 90,
                "routeHint": {
                    "ru": "к ближайшему входу Иле-Алатауского НП",
                    "en": "to the nearest Ile-Alatau NP entrance",
                    "kk": "Іле-Алатау ҰП жақын кіреберісіне"
                },
                "roadCondition": "MOUNTAIN",
                "requires4x4": false,
                "note": {
                    "ru": "30–90 мин до старта",
                    "en": "30-90 min to trailhead",
                    "kk": "Бастау нүктесіне дейін 30-90 мин"
                },
                "sortOrder": 10
            }
        ],
        "practicalNotes": [
            {
                "noteType": "GENERAL",
                "title": {
                    "ru": "Практическое примечание",
                    "en": "Practical note",
                    "kk": "Практикалық ескерту"
                },
                "body": {
                    "ru": "только при хорошей погоде; нужен опыт горных маршрутов; оплатить пропуск/сбор до выхода на маршрут; не сходить с троп",
                    "en": "only in good weather; mountain route experience needed; pay permit/fee before the route; stay on trails",
                    "kk": "тек жақсы ауа райында; тау маршруты тәжірибесі керек; маршрутқа дейін рұқсат/алым төлеу; соқпақтан шықпау"
                },
                "priority": "IMPORTANT",
                "sortOrder": 10
            }
        ],
        "recommendedItems": [
            {
                "itemType": "SHOES",
                "title": {
                    "ru": "Удобная обувь",
                    "en": "Comfortable shoes",
                    "kk": "Ыңғайлы аяқ киім"
                },
                "importance": "REQUIRED",
                "sortOrder": 10,
                "note": {
                    "ru": "Треккинговые ботинки",
                    "en": "Trekking boots",
                    "kk": "Треккинг ботинкалары"
                }
            },
            {
                "itemType": "OTHER",
                "title": {
                    "ru": "Подготовка",
                    "en": "Preparation",
                    "kk": "Дайындық"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 20,
                "note": {
                    "ru": "1",
                    "en": "Take this item based on season and route conditions",
                    "kk": "Бұл затты маусым мен маршрут жағдайына қарай алыңыз"
                }
            },
            {
                "itemType": "WATER",
                "title": {
                    "ru": "Вода",
                    "en": "Water",
                    "kk": "Су"
                },
                "importance": "REQUIRED",
                "sortOrder": 30,
                "note": {
                    "ru": "5–2 л воды",
                    "en": "1.5-2 L of water",
                    "kk": "1,5-2 л су"
                }
            },
            {
                "itemType": "WARM_CLOTHES",
                "title": {
                    "ru": "Тёплая одежда",
                    "en": "Warm clothes",
                    "kk": "Жылы киім"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 40,
                "note": {
                    "ru": "ветровка/флис",
                    "en": "windbreaker/fleece",
                    "kk": "жел күртесі/флис"
                }
            },
            {
                "itemType": "RAIN",
                "title": {
                    "ru": "Дождевик",
                    "en": "Rain jacket",
                    "kk": "Жаңбырлық"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 50,
                "note": {
                    "ru": "дождевик",
                    "en": "rain jacket",
                    "kk": "жаңбырлық"
                }
            },
            {
                "itemType": "SPF",
                "title": {
                    "ru": "SPF/головной убор",
                    "en": "SPF and hat",
                    "kk": "SPF және бас киім"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 60,
                "note": {
                    "ru": "SPF/очки",
                    "en": "SPF/sunglasses",
                    "kk": "SPF/көзілдірік"
                }
            },
            {
                "itemType": "FOOD",
                "title": {
                    "ru": "Еда",
                    "en": "Food",
                    "kk": "Тамақ"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 70,
                "note": {
                    "ru": "перекус",
                    "en": "snack",
                    "kk": "жеңіл тамақ"
                }
            },
            {
                "itemType": "MAP",
                "title": {
                    "ru": "Офлайн-карта",
                    "en": "Offline map",
                    "kk": "Офлайн карта"
                },
                "importance": "RECOMMENDED",
                "sortOrder": 80,
                "note": {
                    "ru": "офлайн-карта",
                    "en": "offline map",
                    "kk": "офлайн карта"
                }
            }
        ]
    }$$::jsonb
);

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
)
UPDATE places p
SET
    price_amount = COALESCE(m.price_amount, p.price_amount),
    price_currency = CASE WHEN m.price_amount IS NULL THEN p.price_currency ELSE 'KZT' END,
    visit_info = jsonb_strip_nulls(
        COALESCE(p.visit_info, '{}'::jsonb)
        || m.visit_info
        || jsonb_build_object('lastVerifiedAt', '2026-06-27')
    ),
    updated_at = NOW()
FROM matched_places m
WHERE p.id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
)
INSERT INTO place_visit_info (
    place_id,
    best_season_months,
    opening_hours,
    time_on_site_min_minutes,
    time_on_site_max_minutes,
    car_travel_time_min_minutes,
    car_travel_time_max_minutes,
    car_route_hint,
    road_condition,
    price_note,
    planning_note,
    last_verified_at
)
SELECT
    m.place_id,
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(COALESCE(m.visit_info #> '{season,months}', '[]'::jsonb))::smallint), '{}'),
    COALESCE(m.visit_info -> 'openingHours', '{}'::jsonb),
    NULLIF(m.visit_info #>> '{timeOnSite,minMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{timeOnSite,maxMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{carTravelTime,minMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{carTravelTime,maxMinutes}', '')::int,
    COALESCE(m.visit_info #> '{accessOptions,0,routeHint}', '{}'::jsonb),
    COALESCE(m.visit_info ->> 'roadCondition', ''),
    COALESCE(m.visit_info -> 'priceNote', '{}'::jsonb),
    COALESCE(m.visit_info #> '{timeOnSite,note}', '{}'::jsonb),
    DATE '2026-06-27'
FROM matched_places m
ON CONFLICT (place_id) DO UPDATE SET
    best_season_months = EXCLUDED.best_season_months,
    opening_hours = EXCLUDED.opening_hours,
    time_on_site_min_minutes = EXCLUDED.time_on_site_min_minutes,
    time_on_site_max_minutes = EXCLUDED.time_on_site_max_minutes,
    car_travel_time_min_minutes = EXCLUDED.car_travel_time_min_minutes,
    car_travel_time_max_minutes = EXCLUDED.car_travel_time_max_minutes,
    car_route_hint = EXCLUDED.car_route_hint,
    road_condition = EXCLUDED.road_condition,
    price_note = EXCLUDED.price_note,
    planning_note = EXCLUDED.planning_note,
    last_verified_at = EXCLUDED.last_verified_at,
    updated_at = NOW();

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
), fee_rows AS (
    SELECT
        m.place_id,
        fee.value AS item,
        COALESCE((fee.value ->> 'sortOrder')::int, fee.ordinality::int * 10) AS sort_order
    FROM matched_places m
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'feeItems', '[]'::jsonb)) WITH ORDINALITY AS fee(value, ordinality)
)
INSERT INTO place_fee_items (
    place_id,
    fee_type,
    title,
    description,
    amount_min,
    amount_max,
    currency,
    unit,
    is_required,
    is_approximate,
    note,
    sort_order
)
SELECT
    place_id,
    lower(COALESCE(item ->> 'type', 'other')),
    COALESCE(item -> 'title', '{}'::jsonb),
    COALESCE(item -> 'description', '{}'::jsonb),
    NULLIF(item ->> 'minAmount', '')::numeric,
    NULLIF(item ->> 'maxAmount', '')::numeric,
    COALESCE(item ->> 'currency', ''),
    COALESCE(item ->> 'unit', ''),
    COALESCE((item ->> 'required')::boolean, false),
    COALESCE((item ->> 'isApproximate')::boolean, false),
    COALESCE(item -> 'note', '{}'::jsonb),
    sort_order
FROM fee_rows
ON CONFLICT (place_id, fee_type, sort_order) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    amount_min = EXCLUDED.amount_min,
    amount_max = EXCLUDED.amount_max,
    currency = EXCLUDED.currency,
    unit = EXCLUDED.unit,
    is_required = EXCLUDED.is_required,
    is_approximate = EXCLUDED.is_approximate,
    note = EXCLUDED.note,
    updated_at = NOW();

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
), access_rows AS (
    SELECT
        m.place_id,
        access.value AS item,
        COALESCE((access.value ->> 'sortOrder')::int, access.ordinality::int * 10) AS sort_order
    FROM matched_places m
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'accessOptions', '[]'::jsonb)) WITH ORDINALITY AS access(value, ordinality)
)
INSERT INTO place_access_options (
    place_id,
    transport_type,
    duration_min_minutes,
    duration_max_minutes,
    route_hint,
    road_condition,
    requires_4x4,
    parking_note,
    last_segment_note,
    note,
    sort_order
)
SELECT
    place_id,
    lower(COALESCE(item ->> 'transportType', 'car')),
    NULLIF(item ->> 'durationMinMinutes', '')::int,
    NULLIF(item ->> 'durationMaxMinutes', '')::int,
    COALESCE(item -> 'routeHint', '{}'::jsonb),
    COALESCE(item ->> 'roadCondition', ''),
    COALESCE((item ->> 'requires4x4')::boolean, false),
    COALESCE(item -> 'parkingNote', '{}'::jsonb),
    COALESCE(item -> 'lastSegmentNote', '{}'::jsonb),
    COALESCE(item -> 'note', '{}'::jsonb),
    sort_order
FROM access_rows
ON CONFLICT (place_id, transport_type, sort_order) DO UPDATE SET
    duration_min_minutes = EXCLUDED.duration_min_minutes,
    duration_max_minutes = EXCLUDED.duration_max_minutes,
    route_hint = EXCLUDED.route_hint,
    road_condition = EXCLUDED.road_condition,
    requires_4x4 = EXCLUDED.requires_4x4,
    parking_note = EXCLUDED.parking_note,
    last_segment_note = EXCLUDED.last_segment_note,
    note = EXCLUDED.note,
    updated_at = NOW();

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
), note_rows AS (
    SELECT
        m.place_id,
        note.value AS item,
        COALESCE((note.value ->> 'sortOrder')::int, note.ordinality::int * 10) AS sort_order
    FROM matched_places m
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'practicalNotes', '[]'::jsonb)) WITH ORDINALITY AS note(value, ordinality)
)
INSERT INTO place_practical_notes (
    place_id,
    note_type,
    title,
    body,
    priority,
    sort_order
)
SELECT
    place_id,
    lower(COALESCE(item ->> 'noteType', 'general')),
    COALESCE(item -> 'title', '{}'::jsonb),
    COALESCE(item -> 'body', '{}'::jsonb),
    lower(COALESCE(item ->> 'priority', '')),
    sort_order
FROM note_rows
ON CONFLICT (place_id, note_type, sort_order) DO UPDATE SET
    title = EXCLUDED.title,
    body = EXCLUDED.body,
    priority = EXCLUDED.priority,
    updated_at = NOW();

WITH matched_places AS (
    SELECT DISTINCT ON (p.id)
        p.id AS place_id,
        seed.visit_info
    FROM seed_talgar_peak_visit_planning seed
    JOIN places p
      ON p.country_code = 'KZ'
     AND p.deleted_at IS NULL
     AND p.tags @> ARRAY[seed.slug]::text[]
    ORDER BY p.id
), item_rows AS (
    SELECT
        m.place_id,
        rec.value AS item,
        COALESCE((rec.value ->> 'sortOrder')::int, rec.ordinality::int * 10) AS sort_order
    FROM matched_places m
    CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'recommendedItems', '[]'::jsonb)) WITH ORDINALITY AS rec(value, ordinality)
)
INSERT INTO place_recommended_items (
    place_id,
    item_type,
    title,
    importance,
    season,
    note,
    sort_order
)
SELECT
    place_id,
    lower(COALESCE(item ->> 'itemType', 'other')),
    COALESCE(item -> 'title', '{}'::jsonb),
    lower(COALESCE(item ->> 'importance', 'recommended')),
    lower(COALESCE(item ->> 'season', '')),
    COALESCE(item -> 'note', '{}'::jsonb),
    sort_order
FROM item_rows
ON CONFLICT (place_id, item_type, sort_order) DO UPDATE SET
    title = EXCLUDED.title,
    importance = EXCLUDED.importance,
    season = EXCLUDED.season,
    note = EXCLUDED.note,
    updated_at = NOW();

DROP TABLE seed_talgar_peak_visit_planning;
