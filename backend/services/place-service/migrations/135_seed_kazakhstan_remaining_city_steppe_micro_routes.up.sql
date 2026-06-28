-- Remaining Kazakhstan city and steppe micro outdoor route seed.
-- Adds non-duplicate public walks for Kazakhstan hubs that still lacked a lightweight outdoor place.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remaining_city_steppe_micro_routes_places;

CREATE TEMP TABLE seed_kazakhstan_remaining_city_steppe_micro_routes_places (
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

INSERT INTO seed_kazakhstan_remaining_city_steppe_micro_routes_places (
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
    ('KZ', 'KZT', 'talas-riverbank-walk', 'taraz', 'NATURE', 0, 2, 'HOURS', 4.4, 'Прогулка вдоль Таласа', 'Talas Riverbank Walk', 'Талас жағалауы серуені', 'Легкий маршрут в Таразе вдоль Таласа: вода, зеленые участки и спокойный формат прогулки после исторического центра.', 'An easy Taraz route along the Talas River, with water, green pockets and a calm walk after the historic centre.', 'Тараздағы Талас бойындағы жеңіл бағыт: су, жасыл бөліктер және тарихи орталықтан кейінгі тыныш серуен форматы.', 42.89700000, 71.36500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','taraz','talas-river','riverbank','city-nature','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'badam-river-green-walk', 'shymkent', 'NATURE', 0, 2, 'HOURS', 4.4, 'Зеленая прогулка вдоль Бадама', 'Badam River Green Walk', 'Бадам өзені жасыл серуені', 'Короткий городской outdoor-маршрут в Шымкенте вдоль Бадама: русло реки, тень, южный воздух и простой сценарий без выезда к дальним ущельям.', 'A short urban outdoor route in Shymkent along the Badam River, with the river channel, shade, southern air and a simple option without driving to distant gorges.', 'Шымкенттегі Бадам өзені бойындағы қысқа қалалық outdoor бағыты: өзен арнасы, көлеңке, оңтүстік ауа және алыс шатқалдарға шықпайтын жеңіл сценарий.', 42.30000000, 69.61500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','shymkent','badam-river','riverbank','urban-green','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'sazdy-reservoir-shore-walk', 'aktobe', 'NATURE', 0, 2, 'HOURS', 4.4, 'Береговая прогулка Саздинского водохранилища', 'Sazdy Reservoir Shore Walk', 'Сазды су қоймасы жағалауы серуені', 'Короткий выезд из Актобе к Саздинскому водохранилищу: вода, степной воздух и спокойный прогулочный формат без сложной логистики.', 'A short outing from Aktobe to Sazdy Reservoir, with water, steppe air and a calm walking format without complex logistics.', 'Ақтөбеден Сазды су қоймасына шығатын қысқа бағыт: су, дала ауасы және күрделі логистикасыз тыныш серуен форматы.', 50.22500000, 57.10500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe','sazdy-reservoir','shore','steppe-city','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'yesil-riverside-walk', 'astana', 'NATURE', 0, 2, 'HOURS', 4.5, 'Прогулка вдоль Есиля', 'Yesil Riverside Walk', 'Есіл жағалауы серуені', 'Городской outdoor-маршрут в Астане вдоль Есиля: набережные, островные участки, открытое небо и быстрый природный перерыв между городскими точками.', 'An urban outdoor route in Astana along the Yesil River, with embankments, island sections, open sky and a quick nature break between city stops.', 'Астанадағы Есіл бойындағы қалалық outdoor бағыты: жағалаулар, аралдық бөліктер, ашық аспан және қалалық нүктелер арасында тез табиғи үзіліс.', 51.12800000, 71.43000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana']::text[], ARRAY['astana']::text[], ARRAY['kazakhstan','astana','yesil','ishim','riverside','city-nature','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kapchagay-reservoir-shore-walk', 'almaty', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка Капчагайского водохранилища', 'Kapchagay Reservoir Shore Walk', 'Қапшағай су қоймасы жағалауы серуені', 'Легкий выезд из Алматы к берегу Капчагайского водохранилища: открытая вода, сухие склоны и формат спокойной прогулки без привязки к пляжному отдыху.', 'An easy outing from Almaty to the Kapchagay Reservoir shore, with open water, dry slopes and a calm walking format beyond beach leisure.', 'Алматыдан Қапшағай су қоймасы жағалауына шығатын жеңіл бағыт: ашық су, құрғақ беткейлер және жағажай демалысына байланып қалмайтын тыныш серуен форматы.', 43.86600000, 77.50000000, 'Balkhash lake, september 2020.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','kapchagay','reservoir','shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'zhambyl-massif-steppe-ridge-walk', 'taraz', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка степной гряды массива Жамбыл', 'Zhambyl Massif Steppe Ridge Walk', 'Жамбыл массиві дала жотасы серуені', 'Редкий геоприродный маршрут Жамбылской области по сухим грядам, каменистым выходам и широкому степному горизонту для поездки из Тараза.', 'A rare geo-nature route in Zhambyl Region across dry ridges, rocky outcrops and a wide steppe horizon for a Taraz outing.', 'Жамбыл облысындағы сирек геотабиғи бағыт: құрғақ жоталар, тасты жерлер және Тараздан шығуға ыңғайлы кең дала көкжиегі.', 44.76700000, 73.00000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['taraz','balkhash']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','zhambyl-massif','steppe-ridge','geotrail','free-entry','hiking','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places AS
SELECT
    ('135d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-remaining-city-steppe-micro-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_places;

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
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places
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
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places
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
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places
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
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places
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
FROM seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_remaining_city_steppe_micro_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remaining_city_steppe_micro_routes_places;
