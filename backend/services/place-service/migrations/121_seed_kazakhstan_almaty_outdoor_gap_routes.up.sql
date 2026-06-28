-- Almaty-area Kazakhstan outdoor gap seed.
-- Adds route-level places requested by local hiking scenarios while avoiding already seeded route families.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_almaty_outdoor_gap_routes_places;

CREATE TEMP TABLE seed_kazakhstan_almaty_outdoor_gap_routes_places (
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

INSERT INTO seed_kazakhstan_almaty_outdoor_gap_routes_places (
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
    ('KZ', 'KZT', 'alma-arasan-spring-valley-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка долины источников Алма-Арасан', 'Alma-Arasan Spring Valley Walk', 'Алма-Арасан бұлақтар аңғары серуені', 'Спокойный маршрут по долине Алма-Арасана к горной реке, хвойным склонам и зоне теплых источников без ухода в длинный перевальный трек.', 'A calm Alma-Arasan valley route toward the mountain river, spruce slopes and warm-spring area without committing to a long pass trek.', 'Алма-Арасан аңғарындағы тау өзеніне, шыршалы беткейлерге және жылы бұлақтар аймағына апаратын, ұзақ асу трегінсіз тыныш бағыт.', 43.08800000, 76.91800000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','alma-arasan','springs','ile-alatau','walking']::text[]),
    ('KZ', 'KZT', 'aksai-skete-gorge-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка к Аксайскому скиту', 'Aksai Skete Gorge Walk', 'Ақсай скитіне шатқал серуені', 'Западный маршрут Иле-Алатауского парка к Аксайскому скиту, лесной лестничной тропе, горному воздуху и сильному культурному контексту.', 'A western Ile-Alatau park route to the Aksai Skete, forest stair trail, mountain air and a strong cultural context.', 'Іле Алатауы паркінің батыс бөлігіндегі Ақсай скитіне, орманды сатылы соқпаққа, тау ауасына және мәдени контекстке апаратын бағыт.', 43.07900000, 76.74400000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','aksai-gorge','skete','ile-alatau','heritage','walking']::text[]),
    ('KZ', 'KZT', 'gorelnik-waterfalls-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.8, 'Тропа к водопадам Горельника', 'Gorelnik Waterfalls Trail', 'Горельник сарқырамаларына соқпақ', 'Маршрут из зоны Медеу вверх по долине Горельника к водопадным участкам, еловому лесу и прохладному ущелью Малой Алматинки.', 'A route from the Medeu area up the Gorelnik valley toward waterfall sections, spruce forest and the cool Little Almatinka gorge.', 'Медеу аймағынан Горельник аңғарымен сарқырама бөліктеріне, шыршалы орманға және Кіші Алматының салқын шатқалына апаратын бағыт.', 43.13800000, 77.05600000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','gorelnik','waterfalls','medeu','ile-alatau','hiking']::text[]),
    ('KZ', 'KZT', 'furmanov-peak-ridge-trail', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.8, 'Гребневая тропа на пик Фурманова', 'Furmanov Peak Ridge Trail', 'Фурманов шыңы жота соқпағы', 'Популярный маршрут от Медеу через Кимасарские склоны к открытой вершине, панораме города и быстрым видам Заилийского Алатау.', 'A popular route from Medeu through the Kimasar slopes to an open summit, city panorama and quick Trans-Ili Alatau views.', 'Медеуден Кімасар беткейлері арқылы ашық шыңға, қала панорамасына және Іле Алатауының тез ашылатын көріністеріне апаратын танымал бағыт.', 43.15100000, 77.01500000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','furmanov-peak','kimasar','medeu','ridge','hiking']::text[]),
    ('KZ', 'KZT', 'kara-kungey-ridge-trail', 'almaty', 'NATURE', 0, 6, 'HOURS', 4.7, 'Тропа хребта Кара-Кунгей', 'Kara-Kungey Ridge Trail', 'Қара-Күнгей жотасы соқпағы', 'Высокогорный маршрут восточнее Алматы к открытым склонам Кунгейской стороны, сухим гребням и широким видам Кегенского направления.', 'A highland route east of Almaty toward open Kungey-side slopes, dry ridges and wide Kegen-direction views.', 'Алматының шығысындағы Күнгей жақтың ашық беткейлеріне, құрғақ жоталарға және Кеген бағытының кең көріністеріне апаратын биіктау бағыты.', 42.84600000, 78.98000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kara-kungey','kungey-alatau','almaty-region','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'kumbel-peak-ridge-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.8, 'Гребневая тропа на пик Кумбель', 'Kumbel Peak Ridge Trail', 'Күмбел шыңы жота соқпағы', 'Маршрут над Медеу к гребню Кумбеля с лесными участками, открытыми склонами и видом на городскую чашу Алматы.', 'A route above Medeu toward the Kumbel ridge, with forest sections, open slopes and views of the Almaty city bowl.', 'Медеу үстінен Күмбел жотасына апаратын бағыт: орманды бөліктер, ашық беткейлер және Алматы қалалық аңғарына көрініс.', 43.13200000, 76.97800000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kumbel','medeu','ridge','ile-alatau','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places AS
SELECT
    ('121d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-almaty-outdoor-gap-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_almaty_outdoor_gap_routes_places;

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
FROM seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_almaty_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_almaty_outdoor_gap_routes_places;
