-- Final Kazakhstan route-level outdoor/hiking seed.
-- Adds non-duplicate hiking, ridge, lake, salt-flat and heritage-walk choices.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_final_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_final_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_final_outdoor_routes_places (
    country_code varchar(2) NOT NULL,
    price_currency varchar(3) NOT NULL,
    slug varchar(96) NOT NULL,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    price_amount numeric(12,2) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL DEFAULT 'HOURS',
    rating numeric(2,1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    description_kk text NOT NULL,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    media_file text NOT NULL,
    access_city_ids text[] NOT NULL,
    departure_city_ids text[] NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[],
    PRIMARY KEY (country_code, slug)
);

INSERT INTO seed_kazakhstan_final_outdoor_routes_places (
    country_code,
    price_currency,
    slug,
    city_id,
    category,
    price_amount,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    media_file,
    access_city_ids,
    departure_city_ids,
    extra_tags
) VALUES
    ('KZ', 'KZT', 'ushkonyr-plateau-ridge-walk', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.6, 'Гребневая прогулка плато Ушконыр', 'Ushkonyr Plateau Ridge Walk', 'Үшқоңыр үстірті жотасы серуені', 'Спокойный предгорный маршрут западнее Алматы по открытым гребням, сухим склонам и широким видам на равнину и Заилийский Алатау.', 'A calm foothill route west of Almaty across open ridges, dry slopes and wide views toward the plain and Trans-Ili Alatau.', 'Алматының батысындағы тау етегі бағыты: ашық жоталар, құрғақ беткейлер және жазық пен Іле Алатауына кең көріністер.', 43.20500000, 76.58500000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','ushkonyr','plateau','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'eshkiolmes-petroglyph-hill-walk', 'taldykorgan', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка холмов петроглифов Ешкиольмес', 'Eshkiolmes Petroglyph Hill Walk', 'Ешкіөлмес петроглифтері төбе серуені', 'Жетысуский маршрут по невысоким холмам с древними наскальными рисунками, сухими гребнями и видом на переход от равнины к горам.', 'A Zhetysu route across low hills with ancient rock art, dry ridges and views where the plain rises toward the mountains.', 'Жетісудағы аласа төбелер арқылы өтетін бағыт: көне жартас суреттері, құрғақ жоталар және жазықтан тауға ауысатын көріністер.', 44.95500000, 78.33500000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','eshkiolmes','petroglyphs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kapal-arasan-foothill-walk', 'taldykorgan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Предгорная прогулка Капал-Арасана', 'Kapal-Arasan Foothill Walk', 'Қапал-Арасан тау етегі серуені', 'Мягкий маршрут Жетысу у минеральных источников, зеленых склонов и спокойной горной атмосферы без сложного набора высоты.', 'A gentle Zhetysu route near mineral springs, green slopes and a calm mountain atmosphere without difficult elevation gain.', 'Минералды бұлақтар, жасыл беткейлер және күрделі биіктік жинаусыз тыныш тау атмосферасы бар Жетісу бағыты.', 45.02400000, 79.21000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','kapal-arasan','springs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shyngystau-ridge-steppe-trail', 'semey', 'NATURE', 0, 5, 'HOURS', 4.6, 'Степная тропа хребта Шынгыстау', 'Shyngystau Ridge Steppe Trail', 'Шыңғыстау жотасы дала соқпағы', 'Маршрут области Абай по сухим гребням, ковыльной степи и открытым видам, где природный выход легко соединяется с литературным контекстом края.', 'An Abai Region route across dry ridges, feather-grass steppe and open views, where a nature outing connects with the region literary context.', 'Абай облысындағы құрғақ жоталар, бозды дала және ашық көріністер арқылы өтетін бағыт, табиғат сапары өңірдің әдеби контекстімен байланысады.', 49.12000000, 78.58500000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['semey']::text[], ARRAY['semey']::text[], ARRAY['kazakhstan','abai-region','shyngystau','ridge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'ulba-river-foothill-trail', 'ust-kamenogorsk', 'NATURE', 0, 4, 'HOURS', 4.5, 'Предгорная тропа реки Ульба', 'Ulba River Foothill Trail', 'Үлбі өзені тау етегі соқпағы', 'Короткий восточноказахстанский маршрут вдоль речной долины, лесных участков и мягких склонов рядом с Усть-Каменогорском.', 'A short East Kazakhstan route along a river valley, forest sections and gentle slopes near Oskemen.', 'Өскемен маңындағы өзен аңғары, орманды бөліктер және жұмсақ беткейлер бойымен өтетін қысқа Шығыс Қазақстан бағыты.', 50.20200000, 82.68800000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','ulba','river-valley','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'syrymbet-ridge-forest-walk', 'petropavlovsk', 'NATURE', 0, 4, 'HOURS', 4.6, 'Лесная прогулка хребта Сырымбет', 'Syrymbet Ridge Forest Walk', 'Сырымбет жотасы орман серуені', 'Северный маршрут по лесостепным склонам и мягким гребням Айыртауской зоны с соснами, озерным воздухом и спокойным рельефом.', 'A northern route across forest-steppe slopes and gentle ridges of the Aiyrtau area with pines, lake air and easy terrain.', 'Айыртау аймағындағы орманды-дала беткейлері мен жұмсақ жоталар арқылы өтетін солтүстік бағыт: қарағай, көл ауасы және жеңіл бедер.', 53.32500000, 68.34500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['petropavlovsk']::text[], ARRAY['petropavlovsk','kokshetau']::text[], ARRAY['kazakhstan','north-kazakhstan','syrymbet','forest-steppe','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'akkol-lake-pine-walk', 'astana', 'NATURE', 0, 3, 'HOURS', 4.5, 'Сосновая прогулка озера Акколь', 'Akkol Lake Pine Walk', 'Ақкөл көлі қарағай серуені', 'Легкий выезд из Астаны к северному озеру, сосновым участкам и спокойному формату прогулки на природе без сложной логистики.', 'An easy outing from Astana toward a northern lake, pine pockets and a calm nature-walk format without complex logistics.', 'Астанадан солтүстік көлге, қарағайлы бөліктерге және күрделі логистикасыз табиғаттағы тыныш серуен форматына арналған жеңіл бағыт.', 52.00200000, 70.94500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana','kokshetau']::text[], ARRAY['astana','kokshetau']::text[], ARRAY['kazakhstan','akmola-region','akkol','lake','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kapkansor-salt-flat-walk', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка солончака Капкансор', 'Kapkansor Salt Flat Walk', 'Қапқансор сор жазығы серуені', 'Мангистауский маршрут по светлому солончаку, сухим уступам и открытой пустынной перспективе для раннего старта или заката.', 'A Mangystau route across a pale salt flat, dry edges and open desert perspective for an early start or sunset walk.', 'Маңғыстаудағы ашық сор жазығы, құрғақ кертпештер және ерте бастауға не күн батар серуеніне арналған кең шөл көрінісі.', 43.65200000, 54.35200000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','kapkansor','salt-flat','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'oytau-chalk-hills-trail', 'aktau', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа меловых холмов Ойтау', 'Oytau Chalk Hills Trail', 'Ойтау борлы қыраттары соқпағы', 'Пустынный маршрут Мангистау среди светлых меловых холмов, сухих ложбин и выразительных линий рельефа вдали от популярных точек.', 'A Mangystau desert route among pale chalk hills, dry hollows and expressive relief lines away from the most popular stops.', 'Маңғыстаудағы ақшыл борлы қыраттар, құрғақ ойпаңдар және танымал нүктелерден алыстағы айқын бедер сызықтары арасындағы бағыт.', 43.79000000, 53.57000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','oytau','chalk-hills','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'karzhantau-ridge-view-trail', 'shymkent', 'NATURE', 0, 6, 'HOURS', 4.7, 'Видовая тропа хребта Каржантау', 'Karzhantau Ridge View Trail', 'Қаржантау жотасы көрініс соқпағы', 'Южный маршрут из Шымкента к сухим горным склонам, арчовым участкам и видам на западный Тянь-Шань.', 'A southern route from Shymkent toward dry mountain slopes, juniper sections and Western Tian Shan views.', 'Шымкенттен құрғақ тау беткейлеріне, аршалы бөліктерге және Батыс Тянь-Шань көріністеріне апаратын оңтүстік бағыт.', 42.21400000, 69.93500000, 'Aksu-Zhabagly_Nature_Reserve.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','south-kazakhstan','karzhantau','ridge','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'kelinshektau-ridge-trail', 'turkestan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа хребта Келиншектау', 'Kelinshektau Ridge Trail', 'Келіншектау жотасы соқпағы', 'Каратауский маршрут по сухим склонам, каменным ребрам и открытым степным панорамам, который расширяет природные сценарии Туркестанской области.', 'A Karatau route across dry slopes, rocky ribs and open steppe panoramas, expanding nature plans in Turkestan Region.', 'Қаратаудың құрғақ беткейлері, тасты қырлары және ашық дала панорамалары арқылы өтетін бағыт, Түркістан облысындағы табиғи сценарийлерді кеңейтеді.', 43.35500000, 68.57500000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','turkestan-region','kelinshektau','karatau','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'tekturmas-hill-walk', 'taraz', 'NATURE', 0, 2, 'HOURS', 4.5, 'Прогулка холма Тектурмас', 'Tekturmas Hill Walk', 'Тектұрмас төбесі серуені', 'Короткий маршрут в Таразе к холму над долиной Таласа, где городская история сочетается с легкой природной прогулкой и открытым видом.', 'A short Taraz route to a hill above the Talas valley, where city history meets an easy nature walk and an open view.', 'Тараздағы Талас аңғары үстіндегі төбеге апаратын қысқа бағыт, қала тарихы жеңіл табиғи серуенмен және ашық көрініспен ұштасады.', 42.88600000, 71.40100000, 'Model of Ancient Taraz (5611934896).jpg', ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','taraz','tekturmas','city-nature','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_final_outdoor_routes_resolved_places AS
SELECT
    ('109d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
    country_code,
    price_currency,
    slug,
    city_id,
    category,
    price_amount,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    media_file,
    access_city_ids,
    departure_city_ids,
    (
        substr(md5(country_code || ':' || slug || ':media'), 1, 8) || '-' ||
        substr(md5(country_code || ':' || slug || ':media'), 9, 4) || '-4' ||
        substr(md5(country_code || ':' || slug || ':media'), 14, 3) || '-8' ||
        substr(md5(country_code || ':' || slug || ':media'), 18, 3) || '-' ||
        substr(md5(country_code || ':' || slug || ':media'), 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(media_file, ' ', '%20') || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || replace(media_file, ' ', '_') AS media_source_url,
    ARRAY['kazakhstan-final-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_final_outdoor_routes_places;

INSERT INTO places (
    id,
    author_user_id,
    default_locale,
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
    duration_value,
    duration_unit,
    rating,
    review_count,
    spots,
    source,
    status,
    tags,
    latitude,
    longitude,
    location_source_url,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
    duration_value,
    duration_unit,
    rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    tags,
    latitude,
    longitude,
    'https://inflap.app/map?lat=' || trim(to_char(latitude, 'FM999999990.000000')) || '&lon=' || trim(to_char(longitude, 'FM999999990.000000')),
    NOW(),
    NOW()
FROM seed_kazakhstan_final_outdoor_routes_resolved_places
ON CONFLICT (id) DO UPDATE SET
    author_user_id = EXCLUDED.author_user_id,
    default_locale = EXCLUDED.default_locale,
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    spots = EXCLUDED.spots,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location_source_url = EXCLUDED.location_source_url,
    updated_at = NOW();

INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    id,
    locale,
    title,
    description,
    NOW(),
    NOW()
FROM seed_kazakhstan_final_outdoor_routes_resolved_places
CROSS JOIN LATERAL (
    VALUES
        ('ru', title_ru, description_ru),
        ('en', title_en, description_en),
        ('kk', title_kk, description_kk)
) AS localized(locale, title, description)
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

INSERT INTO place_media (
    id,
    place_id,
    file_id,
    external_url,
    source_url,
    credit,
    license,
    media_type,
    position,
    created_at
)
SELECT
    media_id,
    id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    media_url,
    media_source_url,
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM seed_kazakhstan_final_outdoor_routes_resolved_places
ON CONFLICT (id) DO UPDATE SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO place_city_links (
    place_id,
    city_id,
    kind,
    sort_order
)
SELECT
    id,
    access_city.city_id,
    'ACCESS',
    access_city.ord::int - 1
FROM seed_kazakhstan_final_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

INSERT INTO place_city_links (
    place_id,
    city_id,
    kind,
    sort_order
)
SELECT
    id,
    departure_city.city_id,
    'DEPARTURE',
    departure_city.ord::int - 1
FROM seed_kazakhstan_final_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_final_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_final_outdoor_routes_places;
