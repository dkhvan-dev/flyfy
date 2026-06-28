-- Seed Turkmenistan visit-planning details from the 2026 attractions workbook.
CREATE TEMP TABLE seed_turkmenistan_visit_planning (
    title_ru text PRIMARY KEY,
    price_amount numeric NULL,
    visit_info jsonb NOT NULL
);

INSERT INTO seed_turkmenistan_visit_planning (title_ru, price_amount, visit_info)
VALUES
    ('Тропа предгорий Копетдага', 0, $${"bestTime":"EARLY_MORNING","season":{"months":[3,4,5,6,7,8,9,10,11],"note":{"ru":"март–май, сентябрь–ноябрь; летом сильная жара","en":"Best in Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov; check local weather, holidays and crowd levels","kk":"Қолайлы айлар: наурыз, сәуір, мамыр, маусым, шілде, тамыз, қыркүйек, қазан, қараша; ауа райы, мереке және адам көптігін тексеріңіз"}},"openingHours":{"summary":{"ru":"только световой день; заповедные зоны и пограничные/горные участки по разрешениям и погоде","en":"Plan for daylight hours; check access before departure.","kk":"Күндізгі уақытқа жоспарлаңыз; жолға шығарда қолжетімділікті тексеріңіз."}},"priceNote":{"ru":"публичные предгорные прогулки как baseline 0 TMT; заповедные зоны Копетдага требуют разрешений/организованного доступа, официальные данные ограничены","en":"Base entry is free. Extra costs may include transport, parking, food, booking or activities.","kk":"Негізгі кіру тегін. Қосымша шығынға көлік, тұрақ, тамақ, бронь немесе белсенділік кіруі мүмкін."},"timeOnSite":{"minMinutes":180,"maxMinutes":300,"note":{"ru":"3–5 ч","en":"3 h-5 h","kk":"3 сағ-5 сағ"}},"carTravelTime":{"minMinutes":30,"maxMinutes":60,"note":{"ru":"30–60 мин из Ашхабада","en":"30 min-1 h by car","kk":"30 мин-1 сағ көлікпен"}},"roadCondition":"MIXED","feeItems":[{"type":"ENTRANCE","title":{"ru":"Вход / базовый билет","en":"Entrance / base ticket","kk":"Кіру / негізгі билет"},"description":{"ru":"публичные предгорные прогулки как baseline 0 TMT; заповедные зоны Копетдага требуют разрешений/организованного доступа, официальные данные ограничены","en":"Base entry is free. Extra costs may include transport, parking, food, booking or activities.","kk":"Негізгі кіру тегін. Қосымша шығынға көлік, тұрақ, тамақ, бронь немесе белсенділік кіруі мүмкін."},"minAmount":0,"maxAmount":0,"currency":"TMT","unit":"PERSON","required":false,"isApproximate":true,"note":{"ru":"публичные предгорные прогулки как baseline 0 TMT; заповедные зоны Копетдага требуют разрешений/организованного доступа, официальные данные ограничены","en":"Base entry is free. Extra costs may include transport, parking, food, booking or activities.","kk":"Негізгі кіру тегін. Қосымша шығынға көлік, тұрақ, тамақ, бронь немесе белсенділік кіруі мүмкін."},"sortOrder":10},{"type":"TRANSPORT","title":{"ru":"Доп. транспорт","en":"Additional transport","kk":"Қосымша көлік"},"description":{"ru":"0","en":"Parking, vehicle access or local transport may be paid separately.","kk":"Тұрақ, көлікпен кіру немесе жергілікті көлік бөлек төленуі мүмкін."},"minAmount":0,"maxAmount":0,"currency":"TMT","unit":"CAR","required":false,"isApproximate":true,"note":{"ru":"0","en":"Parking, vehicle access or local transport may be paid separately.","kk":"Тұрақ, көлікпен кіру немесе жергілікті көлік бөлек төленуі мүмкін."},"sortOrder":20}],"feeDetails":[{"title":{"ru":"Вход / базовый билет","en":"Entrance / base ticket","kk":"Кіру / негізгі билет"},"description":{"ru":"публичные предгорные прогулки как baseline 0 TMT; заповедные зоны Копетдага требуют разрешений/организованного доступа, официальные данные ограничены","en":"Base entry is free. Extra costs may include transport, parking, food, booking or activities.","kk":"Негізгі кіру тегін. Қосымша шығынға көлік, тұрақ, тамақ, бронь немесе белсенділік кіруі мүмкін."},"amount":0,"currency":"TMT","unit":"PERSON","isApproximate":true,"sortOrder":10},{"title":{"ru":"Доп. транспорт","en":"Additional transport","kk":"Қосымша көлік"},"description":{"ru":"0","en":"Parking, vehicle access or local transport may be paid separately.","kk":"Тұрақ, көлікпен кіру немесе жергілікті көлік бөлек төленуі мүмкін."},"amount":0,"currency":"TMT","unit":"CAR","isApproximate":true,"sortOrder":20}],"accessOptions":[{"transportType":"CAR","durationMinMinutes":30,"durationMaxMinutes":60,"routeHint":{"ru":"ashgabat; Ашхабад → предгорья Копетдага / выбранная точка маршрута; 30–60 мин из Ашхабада","en":"from the listed base point; check traffic, parking and access on the visit day","kk":"көрсетілген бастапқы нүктеден; сапар күні жол, тұрақ және қолжетімділікті тексеріңіз"},"roadCondition":"MIXED","requires4x4":false,"parkingNote":{"ru":"Парковку, пробки и сезонные ограничения лучше проверить заранее.","en":"Check parking, traffic and seasonal limits before leaving.","kk":"Тұрақ, жол қозғалысы және маусымдық шектеуді алдын ала тексеріңіз."},"note":{"ru":"30–60 мин из Ашхабада","en":"30 min-1 h by car","kk":"30 мин-1 сағ көлікпен"},"sortOrder":10}],"practicalNotes":[{"noteType":"GENERAL","title":{"ru":"Практическое примечание","en":"Practical note","kk":"Практикалық ескерту"},"body":{"ru":"Официальная online-информация ограничена: планировать через местного оператора/госисточник, иметь воду и не заходить в закрытые зоны.","en":"Check current rules, hours and crowd levels before visiting.","kk":"Барар алдында ереже, жұмыс уақыты және адам көптігін тексеріңіз."},"priority":"IMPORTANT","sortOrder":10}],"recommendedItems":[{"itemType":"WATER","title":{"ru":"Вода","en":"Water","kk":"Су"},"importance":"REQUIRED","sortOrder":10,"note":{"ru":"вода 2–3 л","en":"water","kk":"су"}},{"itemType":"SPF","title":{"ru":"SPF/головной убор","en":"SPF and hat","kk":"SPF және бас киім"},"importance":"RECOMMENDED","sortOrder":20,"note":{"ru":"головной убор","en":"sun protection","kk":"күннен қорғаныс"}},{"itemType":"SPF","title":{"ru":"SPF/головной убор","en":"SPF and hat","kk":"SPF және бас киім"},"importance":"RECOMMENDED","sortOrder":30,"note":{"ru":"SPF","en":"sun protection","kk":"күннен қорғаныс"}},{"itemType":"SHOES","title":{"ru":"Удобная обувь","en":"Comfortable shoes","kk":"Ыңғайлы аяқ киім"},"importance":"REQUIRED","sortOrder":40,"note":{"ru":"треккинговая обувь","en":"comfortable footwear","kk":"ыңғайлы аяқ киім"}},{"itemType":"CASH","title":{"ru":"Карта/наличные","en":"Card or cash","kk":"Қолма-қол ақша"},"importance":"RECOMMENDED","sortOrder":50,"note":{"ru":"офлайн-карта","en":"card or cash","kk":"қолма-қол ақша немесе карта"}},{"itemType":"DOCUMENTS","title":{"ru":"Документы","en":"Documents","kk":"Жеке құжат"},"importance":"REQUIRED","sortOrder":60,"note":{"ru":"документ","en":"documents or booking confirmation","kk":"құжат немесе бронь растауы"}},{"itemType":"OTHER","title":{"ru":"Подготовка","en":"Preparation","kk":"Дайындық"},"importance":"RECOMMENDED","sortOrder":70,"note":{"ru":"разрешение при необходимости","en":"prepare for local conditions","kk":"жергілікті жағдайға дайындалыңыз"}}]}$$::jsonb);


DO $$
BEGIN
    IF EXISTS (
        WITH candidate_matches AS (
            SELECT
                seed.title_ru,
                COUNT(DISTINCT p.id) AS match_count
            FROM seed_turkmenistan_visit_planning seed
            LEFT JOIN place_translations pt
              ON pt.locale = 'ru'
             AND pt.title = seed.title_ru
            LEFT JOIN places p
              ON p.id = pt.place_id
             AND p.country_code = 'TM'
             AND p.deleted_at IS NULL
             AND p.source = 'IMPORT'
            GROUP BY seed.title_ru
        )
        SELECT 1
        FROM candidate_matches
        WHERE match_count <> 1
    ) THEN
        RAISE EXCEPTION 'Turkmenistan visit-planning seed has missing or ambiguous place matches';
    END IF;
END $$;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
DELETE FROM place_fee_items f
USING matched_places m
WHERE f.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
DELETE FROM place_access_options a
USING matched_places m
WHERE a.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
DELETE FROM place_practical_notes pn
USING matched_places m
WHERE pn.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
DELETE FROM place_recommended_items ri
USING matched_places m
WHERE ri.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
UPDATE places p
SET
    price_amount = COALESCE(m.price_amount, p.price_amount),
    price_currency = CASE WHEN m.price_amount IS NULL THEN p.price_currency ELSE 'TMT' END,
    visit_info = jsonb_strip_nulls(
        COALESCE(p.visit_info, '{}'::jsonb)
        || m.visit_info
        || jsonb_build_object('lastVerifiedAt', '2026-06-28')
    ),
    updated_at = NOW()
FROM matched_places m
WHERE p.id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
INSERT INTO place_visit_info (
    place_id, best_season_months, opening_hours, time_on_site_min_minutes, time_on_site_max_minutes,
    car_travel_time_min_minutes, car_travel_time_max_minutes, car_route_hint, road_condition,
    price_note, planning_note, last_verified_at
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
    DATE '2026-06-28'
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
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
INSERT INTO place_fee_items (
    place_id, fee_type, title, description, amount_min, amount_max, currency, unit, is_required, is_approximate, note, sort_order
)
SELECT
    m.place_id,
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
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'feeItems', '[]'::jsonb)) WITH ORDINALITY AS fee(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
INSERT INTO place_access_options (
    place_id, transport_type, duration_min_minutes, duration_max_minutes, route_hint, road_condition, requires_4x4,
    parking_note, last_segment_note, note, sort_order
)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'transportType', 'car')),
    NULLIF(item ->> 'durationMinMinutes', '')::int,
    NULLIF(item ->> 'durationMaxMinutes', '')::int,
    COALESCE(item -> 'routeHint', '{}'::jsonb),
    COALESCE(item ->> 'roadCondition', ''),
    COALESCE((item ->> 'requires4x4')::boolean, false),
    COALESCE(item -> 'parkingNote', '{}'::jsonb),
    COALESCE(item -> 'lastSegmentNote', '{}'::jsonb),
    COALESCE(item -> 'note', '{}'::jsonb),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'accessOptions', '[]'::jsonb)) WITH ORDINALITY AS access(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
INSERT INTO place_practical_notes (place_id, note_type, title, body, priority, sort_order)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'noteType', 'general')),
    COALESCE(item -> 'title', '{}'::jsonb),
    COALESCE(item -> 'body', '{}'::jsonb),
    lower(COALESCE(item ->> 'priority', '')),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'practicalNotes', '[]'::jsonb)) WITH ORDINALITY AS note(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_turkmenistan_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'TM'
     AND p.deleted_at IS NULL
     AND p.source = 'IMPORT'
)
INSERT INTO place_recommended_items (place_id, item_type, title, importance, season, note, sort_order)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'itemType', 'other')),
    COALESCE(item -> 'title', '{}'::jsonb),
    lower(COALESCE(item ->> 'importance', 'recommended')),
    lower(COALESCE(item ->> 'season', '')),
    COALESCE(item -> 'note', '{}'::jsonb),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'recommendedItems', '[]'::jsonb)) WITH ORDINALITY AS rec(item, ordinality);

DROP TABLE seed_turkmenistan_visit_planning;
