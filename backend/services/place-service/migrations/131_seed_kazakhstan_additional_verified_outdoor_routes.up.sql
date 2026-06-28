-- Additional verified Kazakhstan outdoor route seed.
-- Adds a final compact batch of non-duplicate Charyn, Ile Alatau and Saryarka nature routes.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_additional_verified_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_verified_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_additional_verified_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_additional_verified_outdoor_routes_places (
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
    ('KZ', 'KZT', 'chinturgen-moss-spruce-forest-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка моховых ельников Чинтургена', 'Chinturgen Moss Spruce Forest Walk', 'Шынтүрген мүкті шыршалы орманы серуені', 'Тихий маршрут восточнее Алматы к реликтовым моховым ельникам, прохладному ущелью и мягкой лесной тропе рядом с Тургенским направлением.', 'A quiet route east of Almaty toward relic mossy spruce forest, a cool gorge and a gentle woodland trail near the Turgen direction.', 'Алматының шығысындағы реликті мүкті шыршалы орманға, салқын шатқалға және Түрген бағыты маңындағы жұмсақ орман соқпағына апаратын тыныш бағыт.', 43.28800000, 77.64500000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','chinturgen','mossy-spruce','forest','hiking','walking']::text[]),
    ('KZ', 'KZT', 'charyn-valley-of-castles-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.8, 'Прогулка по Долине Замков Чарына', 'Charyn Valley of Castles Walk', 'Шарын Қамалдар аңғары серуені', 'Классический пеший сценарий Чарынского каньона по красным стенам, смотровым точкам и руслу долины без ухода в более дальние участки парка.', 'A classic Charyn Canyon walking scenario through red walls, viewpoints and the valley floor without committing to the park more remote sections.', 'Шарын каньонының қызыл қабырғалары, көрініс нүктелері және аңғар табаны арқылы өтетін классикалық жаяу сценарийі, парктің алыс бөліктеріне бармай-ақ.', 43.35000000, 79.08000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn','valley-of-castles','canyon','walking']::text[]),
    ('KZ', 'KZT', 'kurtogay-canyon-view-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Видовая прогулка каньона Куртогай', 'Kurtogay Canyon View Walk', 'Құртоғай каньоны көрініс серуені', 'Более камерный маршрут Чарынской зоны к сухим стенкам, открытым обзорным точкам и спокойному каньонному пейзажу вдали от главной тропы.', 'A smaller Charyn-area route toward dry walls, open viewpoints and a calm canyon landscape away from the main trail.', 'Негізгі соқпақтан алыс құрғақ қабырғаларға, ашық көрініс нүктелеріне және тыныш каньон ландшафтына апаратын Шарын аймағындағы ықшам бағыт.', 43.44600000, 79.24200000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn-area','kurtogay','canyon','viewpoint','walking']::text[]),
    ('KZ', 'KZT', 'tengiz-lake-flamingo-shore-walk', 'astana', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Береговая прогулка озера Тенгиз с фламинго', 'Tengiz Lake Flamingo Shore Walk', 'Теңіз көлі қоқиқаз жағалауы серуені', 'Степной birdwatching-маршрут из Астаны к берегам Тенгиза, открытой воде, солончаковым линиям и сезонным фламинго Коргалжынской системы.', 'A steppe birdwatching route from Astana toward Tengiz shore, open water, salt-flat lines and seasonal flamingos of the Korgalzhyn system.', 'Астанадан Теңіз жағалауына, ашық суға, сор сызықтарына және Қорғалжын жүйесінің маусымдық қоқиқаздарына апаратын далалық birdwatching бағыты.', 50.43000000, 69.18000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana']::text[], ARRAY['astana']::text[], ARRAY['kazakhstan','akmola-region','tengiz-lake','korgalzhyn','flamingo','birdwatching','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_additional_verified_outdoor_routes_resolved_places AS
SELECT
    ('131d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-additional-verified-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_additional_verified_outdoor_routes_places;

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
FROM seed_kazakhstan_additional_verified_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_verified_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_verified_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_verified_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_verified_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_additional_verified_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_verified_outdoor_routes_places;
