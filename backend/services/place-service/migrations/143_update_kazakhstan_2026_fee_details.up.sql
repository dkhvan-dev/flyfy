-- Replace generic imported Kazakhstan fee hints with concrete 2026 visitor-facing price details.
-- Fee sources are intentionally not persisted in visit_info.

CREATE TEMP TABLE seed_kazakhstan_oopt_fee_patterns (
    pattern text PRIMARY KEY
);

INSERT INTO seed_kazakhstan_oopt_fee_patterns (pattern) VALUES
    ('aksu-jabagly'),
    ('aksu-zhabagly'),
    ('altyn-emel'),
    ('alma-arasan'),
    ('bayanaul'),
    ('big-almaty'),
    ('buiratau'),
    ('burabay'),
    ('charyn'),
    ('ile-alatau'),
    ('kaindy'),
    ('katon-karagay'),
    ('karkaraly'),
    ('kimasar'),
    ('kokshetau-national-park'),
    ('kolsai'),
    ('korgalzhyn'),
    ('furmanov'),
    ('gorelnik'),
    ('naurzum'),
    ('sairam-ugam'),
    ('shymbulak'),
    ('tarbagatai'),
    ('tuyuk-su'),
    ('turgen'),
    ('ugam'),
    ('west-altai');

UPDATE places p
SET
    visit_info = COALESCE(p.visit_info, '{}'::jsonb) - 'feeDetails',
    updated_at = NOW()
WHERE p.country_code = 'KZ'
  AND p.source = 'IMPORT'
  AND COALESCE(p.visit_info, '{}'::jsonb) ? 'feeDetails'
  AND EXISTS (
      SELECT 1
      FROM jsonb_array_elements(COALESCE(p.visit_info, '{}'::jsonb)->'feeDetails') AS fee(item)
      WHERE (
          (fee.item->>'sortOrder') ~ '^[0-9]+$'
          AND (
              (fee.item->>'sortOrder')::int = 10
              OR (fee.item->>'sortOrder')::int BETWEEN 1000 AND 1399
          )
      )
      OR fee.item->'title'->>'ru' IN (
          'ООПТ-сбор за посетителя',
          'Вход бесплатный',
          'Билет на смотровую площадку',
          'Билет на сеанс катания',
          'Канатная дорога или ски-пасс',
          'Билет на канатную дорогу',
          'Входной билет в музей или объект наследия',
          'Билет на аттракцион или шоу',
          'Платная часть посещения'
      )
      OR fee.item->'title'->>'en' IN (
          'Protected area visitor fee',
          'Free entry',
          'Observation deck ticket',
          'Skating session ticket',
          'Cable car or ski pass',
          'Cable car ticket',
          'Museum or heritage ticket',
          'Attraction or show ticket',
          'Paid part of the visit'
      )
  );

-- Per-park group fees (2026 MRP = 4 325 KZT, src: Тарифы_2026 Inflap sheet).
-- Groups: ile-alatau 650/1300, kokshetau-np 650/1750, altyn-emel 900/3900,
--          bayanaul-group 900/1750, reserve-group 900/3050, default 900/2600.
-- Burabay excluded here (pedestrian free): caught by UPDATE 3 below; car fee
-- appended in the fix-up UPDATE at the end of this migration.
CREATE TEMP TABLE seed_kz_oopt_group (
    tag_match    text,
    person_fee   numeric,
    car_fee      numeric,
    moto_fee     numeric,
    minibus_fee  numeric,
    bus_le32_fee numeric,
    bus_gt32_fee numeric
);

INSERT INTO seed_kz_oopt_group
    (tag_match, person_fee, car_fee, moto_fee, minibus_fee, bus_le32_fee, bus_gt32_fee)
VALUES
    ('ile-alatau',              650,  1300,  865, 3250,  7000, 11250),
    ('big-almaty',              650,  1300,  865, 3250,  7000, 11250),
    ('bao',                     650,  1300,  865, 3250,  7000, 11250),
    ('alma-arasan',             650,  1300,  865, 3250,  7000, 11250),
    ('kimasar',                 650,  1300,  865, 3250,  7000, 11250),
    ('furmanov',                650,  1300,  865, 3250,  7000, 11250),
    ('gorelnik',                650,  1300,  865, 3250,  7000, 11250),
    ('tuyuk-su',                650,  1300,  865, 3250,  7000, 11250),
    ('turgen',                  650,  1300,  865, 3250,  7000, 11250),
    ('kokshetau-national-park', 650,  1750,  865, 3250,  7000, 11250),
    ('charyn',                  900,  2600, 1300, 8650, 12975, 21625),
    ('kolsai',                  900,  2600, 1300, 8650, 12975, 21625),
    ('kaindy',                  900,  2600, 1300, 8650, 12975, 21625),
    ('katon-karagay',           900,  2600, 1300, 8650, 12975, 21625),
    ('karkaraly',               900,  2600, 1300, 8650, 12975, 21625),
    ('tarbagatai',              900,  2600, 1300, 8650, 12975, 21625),
    ('west-altai',              900,  2600, 1300, 8650, 12975, 21625),
    ('altyn-emel',              900,  3900, 2600,15150, 30300, 45450),
    ('bayanaul',                900,  1750, 1300, 8650, 12975, 21625),
    ('buiratau',                900,  1750, 1300, 8650, 12975, 21625),
    ('sairam-ugam',             900,  1750, 1300, 8650, 12975, 21625),
    ('ugam',                    900,  1750, 1300, 8650, 12975, 21625),
    ('aksu-jabagly',            900,  3050, 2050, 8650, 12975, 21625),
    ('aksu-zhabagly',           900,  3050, 2050, 8650, 12975, 21625),
    ('korgalzhyn',              900,  3050, 2050, 8650, 12975, 21625),
    ('naurzum',                 900,  3050, 2050, 8650, 12975, 21625);

UPDATE places p
SET
    price_amount   = g.person_fee,
    price_currency = 'KZT',
    visit_info = jsonb_set(
        COALESCE(p.visit_info, '{}'::jsonb),
        '{feeDetails}',
        jsonb_build_array(
            jsonb_build_object(
                'title', jsonb_build_object('en','Protected area visitor fee','ru','ООПТ-сбор за посетителя','kk','ЕҚТА келуші алымы'),
                'description', jsonb_build_object(
                    'en','Covers only area entry per person per day. Transfer, vehicle entry, cable cars, rentals, guide services and lodging are separate',
                    'ru','Это только посещение территории на 1 человека в сутки. Проезд, въезд транспорта, канатка, прокат, гид и проживание оплачиваются отдельно',
                    'kk','Бұл тек 1 адамның тәулігіне аумаққа кіруі. Жол ақысы, көлікпен кіру, аспалы жол, жалға алу, гид және тұру бөлек төленеді'
                ),
                'amount', g.person_fee, 'currency','KZT','unit','PERSON','isApproximate',true,'sortOrder',1000
            ),
            jsonb_build_object(
                'title', jsonb_build_object('en','Passenger car entry','ru','Въезд легкового автомобиля','kk','Жеңіл автокөлікпен кіру'),
                'description', jsonb_build_object(
                    'en','Checkpoint fee when the route enters the protected area by passenger car',
                    'ru','Сбор на КПП, если маршрут проходит через территорию на легковом автомобиле',
                    'kk','Бағыт қорғалатын аумаққа жеңіл автокөлікпен кіргенде алынатын КПП алымы'
                ),
                'amount', g.car_fee, 'currency','KZT','unit','CAR','isApproximate',true,'sortOrder',1010
            ),
            jsonb_build_object(
                'title', jsonb_build_object('en','Motorcycle entry','ru','Въезд мотоцикла','kk','Мотоциклмен кіру'),
                'description', jsonb_build_object(
                    'en','Checkpoint fee for a motorcycle, moped or quad bike',
                    'ru','Сбор на КПП для мотоцикла, мопеда или квадроцикла',
                    'kk','Мотоцикл, мопед немесе квадроцикл үшін КПП алымы'
                ),
                'amount', g.moto_fee, 'currency','KZT','unit','MOTORCYCLE','isApproximate',true,'sortOrder',1020
            ),
            jsonb_build_object(
                'title', jsonb_build_object('en','Minibus or truck entry','ru','Въезд микроавтобуса или грузового авто','kk','Микроавтобус немесе жүк көлігімен кіру'),
                'description', jsonb_build_object(
                    'en','Checkpoint fee for a minibus up to 16 seats or a truck',
                    'ru','Сбор на КПП для микроавтобуса до 16 мест или грузового автомобиля',
                    'kk','16 орынға дейінгі микроавтобус немесе жүк көлігі үшін КПП алымы'
                ),
                'amount', g.minibus_fee, 'currency','KZT','unit','','isApproximate',true,'sortOrder',1030
            ),
            jsonb_build_object(
                'title', jsonb_build_object('en','Bus entry up to 32 seats','ru','Въезд автобуса до 32 мест','kk','32 орынға дейінгі автобуспен кіру'),
                'description', jsonb_build_object(
                    'en','Checkpoint fee for a bus with up to 32 seats',
                    'ru','Сбор на КПП для автобуса вместимостью до 32 мест',
                    'kk','32 орынға дейінгі автобус үшін КПП алымы'
                ),
                'amount', g.bus_le32_fee, 'currency','KZT','unit','','isApproximate',true,'sortOrder',1040
            ),
            jsonb_build_object(
                'title', jsonb_build_object('en','Bus entry over 32 seats','ru','Въезд автобуса свыше 32 мест','kk','32 орыннан асатын автобуспен кіру'),
                'description', jsonb_build_object(
                    'en','Checkpoint fee for a bus with more than 32 seats',
                    'ru','Сбор на КПП для автобуса вместимостью свыше 32 мест',
                    'kk','32 орыннан асатын автобус үшін КПП алымы'
                ),
                'amount', g.bus_gt32_fee, 'currency','KZT','unit','','isApproximate',true,'sortOrder',1050
            )
        ),
        true
    ),
    updated_at = NOW()
FROM (
    SELECT
        p2.id,
        MAX(COALESCE(grp.person_fee,    900)) AS person_fee,
        MAX(COALESCE(grp.car_fee,      2600)) AS car_fee,
        MAX(COALESCE(grp.moto_fee,     1300)) AS moto_fee,
        MAX(COALESCE(grp.minibus_fee,  8650)) AS minibus_fee,
        MAX(COALESCE(grp.bus_le32_fee,12975)) AS bus_le32_fee,
        MAX(COALESCE(grp.bus_gt32_fee,21625)) AS bus_gt32_fee
    FROM places p2
    LEFT JOIN seed_kz_oopt_group grp ON p2.tags && ARRAY[grp.tag_match]::text[]
    WHERE p2.country_code = 'KZ'
      AND p2.source = 'IMPORT'
      AND p2.deleted_at IS NULL
      AND NOT (p2.tags && ARRAY['free-entry','burabay']::text[])
      AND (
          p2.category = 'NATURE'
          OR p2.tags && ARRAY['national-park','reserve']::text[]
      )
      AND (
          p2.tags && ARRAY['national-park','reserve']::text[]
          OR EXISTS (
              SELECT 1
              FROM unnest(p2.tags) AS place_tag(tag)
              JOIN seed_kazakhstan_oopt_fee_patterns pattern
                ON place_tag.tag = pattern.pattern
                OR place_tag.tag LIKE pattern.pattern || '-%'
                OR place_tag.tag LIKE '%-' || pattern.pattern
                OR place_tag.tag LIKE '%-' || pattern.pattern || '-%'
          )
      )
    GROUP BY p2.id
) g
WHERE p.id = g.id;

UPDATE places p
SET
    price_amount = 0,
    price_currency = 'KZT',
    visit_info = jsonb_set(
        COALESCE(p.visit_info, '{}'::jsonb),
        '{feeDetails}',
        jsonb_build_array(
            jsonb_build_object(
                'title', jsonb_build_object(
                    'en', 'Free entry',
                    'ru', 'Вход бесплатный',
                    'kk', 'Кіру тегін'
                ),
                'description', jsonb_build_object(
                    'en', 'No entry ticket is expected for the place itself. Personal expenses and optional on-site services are paid separately',
                    'ru', 'За сам вход билет обычно не нужен. Личные расходы и дополнительные сервисы на месте оплачиваются отдельно',
                    'kk', 'Нысанға кіру үшін әдетте билет қажет емес. Жеке шығындар мен қосымша қызметтер бөлек төленеді'
                ),
                'amount', 0,
                'currency', 'KZT',
                'unit', 'PERSON',
                'isApproximate', false,
                'sortOrder', 1200
            )
        ),
        true
    ),
    updated_at = NOW()
WHERE p.country_code = 'KZ'
  AND p.source = 'IMPORT'
  AND p.deleted_at IS NULL
  AND (
      p.price_amount = 0
      OR p.tags && ARRAY['free-entry']::text[]
      OR NOT (
          (
              p.category = 'NATURE'
              OR p.tags && ARRAY['national-park','reserve']::text[]
          )
          AND (
              p.tags && ARRAY['national-park','reserve']::text[]
              OR EXISTS (
                  SELECT 1
                  FROM unnest(p.tags) AS place_tag(tag)
                  JOIN seed_kazakhstan_oopt_fee_patterns pattern
                    ON place_tag.tag = pattern.pattern
                    OR place_tag.tag LIKE pattern.pattern || '-%'
                    OR place_tag.tag LIKE '%-' || pattern.pattern
                    OR place_tag.tag LIKE '%-' || pattern.pattern || '-%'
              )
          )
      )
  )
  AND (
      p.price_amount = 0
      OR p.category IN ('BEACH','MARKET','SHOPPING','PARK','TEMPLE')
      OR p.tags && ARRAY[
          'free-entry',
          'beach',
          'market',
          'shopping',
          'promenade',
          'embankment',
          'seafront',
          'caspian-sea',
          'mosque',
          'memorial',
          'city',
          'bozjyra',
          'ustyurt',
          'sherkala',
          'rocky-trail',
          'geoglyphs',
          'steppe-valley'
      ]::text[]
  )
  AND (
      p.price_amount = 0
      OR p.tags && ARRAY['free-entry']::text[]
      OR NOT (
          p.category IN ('MUSEUM','ENTERTAINMENT')
          OR p.tags && ARRAY[
              'bayterek',
              'tower',
              'kok-tobe',
              'cable-car',
              'medeu',
              'skating',
              'shymbulak',
              'ski',
              'snowboard',
              'zoo',
              'amusement-park',
              'rides',
              'museum',
              'flying-theatre'
          ]::text[]
      )
  );

WITH paid_kazakhstan_fee_profiles AS (
    SELECT
        p.id,
        p.price_amount,
        CASE
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Observation deck ticket'
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Skating session ticket'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Cable car or ski pass'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Cable car ticket'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Zoo entry ticket'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Museum or heritage ticket'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Attraction or show ticket'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Event or guided tour ticket'
            ELSE 'Paid part of the visit'
        END AS title_en,
        CASE
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Билет на смотровую площадку'
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Билет на сеанс катания'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Канатная дорога или ски-пасс'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Билет на канатную дорогу'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Входной билет в зоопарк'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Входной билет в музей или объект наследия'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Билет на аттракцион или шоу'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Билет на мероприятие или экскурсию'
            ELSE 'Платная часть посещения'
        END AS title_ru,
        CASE
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Көрініс алаңына билет'
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Коньки тебу сеансына билет'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Аспалы жол немесе ски-пасс'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Аспалы жол билеті'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Хайуанаттар бағына кіру билеті'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Музейге немесе мұра нысанына кіру билеті'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Аттракционға немесе шоуға билет'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Іс-шараға немесе экскурсияға билет'
            ELSE 'Сапардың ақылы бөлігі'
        END AS title_kk,
        CASE
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Approximate base skating session ticket. Skate rental, lockers and other complex services are separate'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Approximate base cable-car or resort ticket. Ski pass, rental, instructor and paid parking use separate tariffs'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Approximate base cable-car ticket. Attractions, cafes and paid services on the hill are separate'
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Approximate base adult ticket to the observation level. Child, concession and group tariffs may differ'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Approximate base entry ticket. Child, concession and seasonal tariffs may differ'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Approximate base adult ticket. Guided tours, temporary exhibitions and concessions are calculated separately'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Approximate base ticket. Separate rides, shows, rentals and seasonal services may have their own tariffs'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Approximate base event or guided-tour ticket. Performance category and seat price can differ'
            ELSE 'Approximate paid component of the visit. Optional services and seasonal tariffs may differ'
        END AS description_en,
        CASE
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Ориентир за базовый билет на сеанс катания. Прокат коньков, камеры хранения и другие услуги комплекса считаются отдельно'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Ориентир за базовый билет на канатную дорогу или курорт. Ски-пасс, прокат, инструктор и платная стоянка идут по отдельным тарифам'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Ориентир за базовый билет на канатную дорогу. Аттракционы, кафе и платные услуги на горе считаются отдельно'
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Ориентир за базовый взрослый билет на смотровой уровень. Детские, льготные и групповые тарифы могут отличаться'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Ориентир за базовый входной билет. Детские, льготные и сезонные тарифы могут отличаться'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Ориентир за базовый взрослый билет. Экскурсии, временные выставки и льготы считаются отдельно'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Ориентир за базовый билет. Отдельные аттракционы, шоу, прокат и сезонные услуги могут иметь свои тарифы'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Ориентир за билет на мероприятие или экскурсию. Категория спектакля и место в зале могут менять цену'
            ELSE 'Ориентир за платную часть визита. Дополнительные сервисы и сезонные тарифы могут отличаться'
        END AS description_ru,
        CASE
            WHEN p.tags && ARRAY['medeu','skating']::text[]
                THEN 'Коньки тебу сеансының базалық билетіне бағдар. Коньки жалға алу, сақтау камералары және басқа қызметтер бөлек есептеледі'
            WHEN p.tags && ARRAY['shymbulak','ski','snowboard']::text[]
                THEN 'Аспалы жолға немесе курортқа базалық билет бағдары. Ски-пасс, жалға алу, нұсқаушы және ақылы тұрақ бөлек тарифпен жүреді'
            WHEN p.tags && ARRAY['kok-tobe','cable-car']::text[]
                THEN 'Аспалы жолдың базалық билетіне бағдар. Төбедегі аттракциондар, кафе және ақылы қызметтер бөлек есептеледі'
            WHEN p.tags && ARRAY['bayterek','tower']::text[]
                THEN 'Көрініс деңгейіне ересек адамға базалық билет бағдары. Балалар, жеңілдіктер және топтық тарифтер өзгеше болуы мүмкін'
            WHEN p.tags && ARRAY['zoo']::text[]
                THEN 'Базалық кіру билетіне бағдар. Балалар, жеңілдіктер және маусымдық тарифтер өзгеше болуы мүмкін'
            WHEN p.category = 'MUSEUM'
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history']::text[]
                THEN 'Ересек адамға базалық билет бағдары. Экскурсиялар, уақытша көрмелер және жеңілдіктер бөлек есептеледі'
            WHEN p.category = 'ENTERTAINMENT'
                OR p.tags && ARRAY['amusement-park','rides','show','theme-park','flying-theatre','family']::text[]
                THEN 'Базалық билет бағдары. Жеке аттракциондар, шоу, жалға алу және маусымдық қызметтер бөлек тарифпен болуы мүмкін'
            WHEN p.tags && ARRAY['theatre','opera']::text[]
                THEN 'Іс-шараға немесе экскурсияға билет бағдары. Қойылым санаты және залдағы орын бағаны өзгертуі мүмкін'
            ELSE 'Сапардың ақылы бөлігіне бағдар. Қосымша қызметтер мен маусымдық тарифтер өзгеше болуы мүмкін'
        END AS description_kk,
        CASE
            WHEN p.tags && ARRAY['medeu','skating','shymbulak','ski','snowboard','kok-tobe','cable-car','bayterek','tower','zoo']::text[]
                OR p.category IN ('MUSEUM','ENTERTAINMENT')
                OR p.tags && ARRAY['museum','gallery','heritage','history','unesco','petroglyphs','archaeology','museum-reserve','local-history','theatre','opera']::text[]
                THEN 'TICKET'
            ELSE 'PERSON'
        END AS unit
    FROM places p
    WHERE p.country_code = 'KZ'
      AND p.source = 'IMPORT'
      AND p.deleted_at IS NULL
      AND p.price_amount IS NOT NULL
      AND p.price_amount > 0
      AND NOT (COALESCE(p.visit_info, '{}'::jsonb) ? 'feeDetails')
      AND NOT (
          (
              p.category = 'NATURE'
              OR p.tags && ARRAY['national-park','reserve']::text[]
          )
          AND (
              p.tags && ARRAY['national-park','reserve']::text[]
              OR EXISTS (
                  SELECT 1
                  FROM unnest(p.tags) AS place_tag(tag)
                  JOIN seed_kazakhstan_oopt_fee_patterns pattern
                    ON place_tag.tag = pattern.pattern
                    OR place_tag.tag LIKE pattern.pattern || '-%'
                    OR place_tag.tag LIKE '%-' || pattern.pattern
                    OR place_tag.tag LIKE '%-' || pattern.pattern || '-%'
              )
          )
      )
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
                'currency', 'KZT',
                'unit', paid.unit,
                'isApproximate', true,
                'sortOrder', 1300
            )
        ),
        true
    ),
    updated_at = NOW()
FROM paid_kazakhstan_fee_profiles paid
WHERE p.id = paid.id;

-- Burabay NP fix-up: pedestrian entry is free (set by UPDATE 3 above),
-- but cars pay 1750 KZT at the checkpoint — append that as a second feeDetail.
UPDATE places p
SET
    visit_info = jsonb_set(
        COALESCE(p.visit_info, '{}'::jsonb),
        '{feeDetails}',
        COALESCE(p.visit_info->'feeDetails', '[]'::jsonb) || jsonb_build_array(
            jsonb_build_object(
                'title', jsonb_build_object(
                    'en','Passenger car entry',
                    'ru','Въезд легкового автомобиля',
                    'kk','Жеңіл автокөлікпен кіру'
                ),
                'description', jsonb_build_object(
                    'en','Burabay NP checkpoint fee when entering by passenger car; pedestrian entry is free',
                    'ru','КПП Бурабай НП при въезде на легковом авто; вход для пешеходов бесплатный',
                    'kk','Бурабай ҰПА КПП жеңіл автокөлікпен кіргенде; жаяу кіру тегін'
                ),
                'amount', 1750,
                'currency', 'KZT',
                'unit', 'CAR',
                'isApproximate', true,
                'sortOrder', 1010
            )
        ),
        true
    ),
    updated_at = NOW()
WHERE p.id = '114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid
  AND p.source = 'IMPORT'
  AND p.deleted_at IS NULL;

DROP TABLE IF EXISTS seed_kz_oopt_group;
DROP TABLE IF EXISTS seed_kazakhstan_oopt_fee_patterns;
