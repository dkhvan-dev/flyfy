-- Additional Kazakhstan hiking gap seed.
-- Adds a small non-duplicate layer of route-level places after the dense Kazakhstan outdoor enrichment.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_additional_hiking_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_hiking_gap_routes_places;

CREATE TEMP TABLE seed_kazakhstan_additional_hiking_gap_routes_places (
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

INSERT INTO seed_kazakhstan_additional_hiking_gap_routes_places (
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
    ('KZ', 'KZT', 'kishi-turgen-gorge-walk', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Прогулка ущелья Киши-Турген', 'Kishi Turgen Gorge Walk', 'Кіші Түрген шатқалы серуені', 'Зеленый маршрут восточнее Алматы по более тихой части Тургенской долины, с ручьями, лесными участками и мягким набором высоты.', 'A green route east of Almaty through a quieter part of the Turgen valley, with streams, forest sections and gentle elevation gain.', 'Алматының шығысындағы Түрген аңғарының тынышырақ бөлігімен өтетін жасыл бағыт: бұлақтар, орманды бөліктер және жұмсақ биіктік жинау.', 43.30000000, 77.82000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','kishi-turgen','gorge','walking']::text[]),
    ('KZ', 'KZT', 'kolsai-sary-bulak-pass-trek', 'almaty', 'NATURE', 1000, 8, 'HOURS', 4.8, 'Трек через перевал Сары-Булак у Кольсая', 'Kolsai Sary-Bulak Pass Trek', 'Көлсай Сары-Бұлақ асуы трегі', 'Более спортивный кольсайский маршрут к открытому перевалу, еловым склонам и высокогорным видам для подготовленного дневного треккинга.', 'A stronger Kolsai route toward an open pass, spruce slopes and highland views for prepared day trekking.', 'Көлсайдағы ашық асуға, шыршалы беткейлерге және биіктау көріністеріне апаратын дайын саяхатшыларға арналған белсендірек бағыт.', 42.93500000, 78.42000000, 'Kolsai lake.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kolsai','sary-bulak','pass','trekking']::text[]),
    ('KZ', 'KZT', 'charyn-tazbas-tract-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка урочища Тазбас в Чарыне', 'Charyn Tazbas Tract Walk', 'Шарын Тазбас шатқалы серуені', 'Отдельный сценарий Чарынского парка к сухим стенкам, каменным останцам и тихим точкам, которые разгружают основной каньонный маршрут.', 'A separate Charyn park outing toward dry walls, stone outcrops and quieter points that reduce pressure on the main canyon route.', 'Шарын паркінің негізгі каньон бағытын жеңілдететін бөлек сценарийі: құрғақ қабырғалар, тас мүсіндер және тынышырақ нүктелер.', 43.34800000, 79.11400000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn','tazbas','canyon','walking']::text[]),
    ('KZ', 'KZT', 'ulken-buguty-hills-walk', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка холмов Улькен-Бугуты', 'Ulken Buguty Hills Walk', 'Үлкен Бөгеті төбелері серуені', 'Полупустынный маршрут восточнее Алматы по мягким холмам, сухим логам и широким видам между Чарыном, Богуты и предгорьями.', 'A semi-desert route east of Almaty across soft hills, dry gullies and wide views between Charyn, Buguty and the foothills.', 'Алматының шығысындағы Шарын, Бөгеті және тау етегі арасындағы жұмсақ төбелер, құрғақ сайлар және кең көріністер арқылы өтетін шөлейт бағыт.', 43.55500000, 78.76000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','ulken-buguty','semi-desert','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'ashutas-clay-hills-walk', 'semey', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка глинистых холмов Ащутаса', 'Ashutas Clay Hills Walk', 'Ащутас сазды қыраттары серуені', 'Восточноказахстанский геомаршрут по цветным глинам, сухим гребням и открытым видам Зайсанской стороны без тяжелого треккинга.', 'An eastern Kazakhstan geotrail across colored clays, dry ridges and open Zaysan-side views without heavy trekking.', 'Шығыс Қазақстандағы түрлі түсті саздар, құрғақ жоталар және Зайсан жағының ашық көріністері арқылы өтетін жеңіл геобағыт.', 48.25000000, 84.22000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','ashutas','clay-hills','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karalma-gorge-trail', 'taraz', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа ущелья Каралма', 'Karalma Gorge Trail', 'Қаралма шатқалы соқпағы', 'Маршрут западного Тянь-Шаня к прохладному ущелью, орехово-плодовым участкам и горному формату дня рядом с Аксуским направлением.', 'A Western Tian Shan route toward a cool gorge, fruit-and-walnut pockets and a mountain-day format near the Aksu side.', 'Батыс Тянь-Шаньдағы салқын шатқалға, жаңғақ-жеміс учаскелеріне және Ақсу бағытына жақын таулы күн форматына апаратын маршрут.', 42.42900000, 70.53900000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz','shymkent']::text[], ARRAY['taraz','shymkent']::text[], ARRAY['kazakhstan','western-tian-shan','karalma','gorge','hiking']::text[]),
    ('KZ', 'KZT', 'zhabagly-plateau-walk', 'shymkent', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Прогулка плато Жабаглы', 'Zhabagly Plateau Walk', 'Жабағылы үстірті серуені', 'Мягкий маршрут у предгорий Жабаглы с открытыми травянистыми участками, видами на западный Тянь-Шань и удобным стартом из южных хабов.', 'A gentle route near the Zhabagly foothills with open grassland, Western Tian Shan views and an easy start from southern hubs.', 'Жабағылы тау етегіндегі ашық шалғындары, Батыс Тянь-Шань көріністері және оңтүстік хабтардан ыңғайлы басталатын жұмсақ бағыт.', 42.43700000, 70.47600000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent','taraz']::text[], ARRAY['kazakhstan','zhabagly','western-tian-shan','plateau','walking']::text[]),
    ('KZ', 'KZT', 'aiyrtau-rock-ridge-walk', 'kokshetau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка скальных гряд Айыртау', 'Aiyrtau Rock Ridge Walk', 'Айыртау жартасты жотасы серуені', 'Северный маршрут по лесостепным грядам Айыртауской зоны, где гранитные формы, озерный воздух и сосны дают спокойный outdoor-день.', 'A northern route across the forest-steppe ridges of the Aiyrtau area, where granite forms, lake air and pines shape a calm outdoor day.', 'Айыртау аймағының орманды-дала жоталары арқылы өтетін солтүстік бағыт, гранит пішіндері, көл ауасы және қарағайлар тыныш outdoor күн береді.', 53.27000000, 68.33000000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kazakhstan','north-kazakhstan','aiyrtau','granite','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'tasmola-stone-ridge-walk', 'karaganda', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка каменной гряды Тасмолы', 'Tasmola Stone Ridge Walk', 'Тасмола тас жотасы серуені', 'Короткий центральноказахстанский маршрут по сухим сопкам, каменным грядам и степному археологическому ландшафту рядом с Карагандой.', 'A short central Kazakhstan route across dry low hills, stone ridges and a steppe archaeological landscape near Karaganda.', 'Қарағанды маңындағы құрғақ шоқылар, тас жоталар және далалық археологиялық ландшафт арқылы өтетін қысқа Орталық Қазақстан бағыты.', 49.75000000, 73.15000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','central-kazakhstan','tasmola','stone-ridge','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_additional_hiking_gap_routes_resolved_places AS
SELECT
    ('124d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-additional-hiking-gap-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_additional_hiking_gap_routes_places;

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
FROM seed_kazakhstan_additional_hiking_gap_routes_resolved_places
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
FROM seed_kazakhstan_additional_hiking_gap_routes_resolved_places
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
FROM seed_kazakhstan_additional_hiking_gap_routes_resolved_places
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
FROM seed_kazakhstan_additional_hiking_gap_routes_resolved_places
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
FROM seed_kazakhstan_additional_hiking_gap_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_additional_hiking_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_hiking_gap_routes_places;
