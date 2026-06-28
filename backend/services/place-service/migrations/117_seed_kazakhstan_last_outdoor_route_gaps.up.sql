-- Last small Kazakhstan route-level outdoor seed.
-- Adds only non-duplicate trail/walk cards found after the broad Kazakhstan enrichment layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_last_outdoor_route_gaps_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_outdoor_route_gaps_places;

CREATE TEMP TABLE seed_kazakhstan_last_outdoor_route_gaps_places (
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

INSERT INTO seed_kazakhstan_last_outdoor_route_gaps_places (
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
    ('KZ', 'KZT', 'charyn-ash-grove-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка реликтовой ясеневой рощи Чарына', 'Charyn Ash Grove Walk', 'Шарын шаған тоғайы серуені', 'Отдельный маршрут Чарынского парка по пойменной роще, тени старых ясеней и мягкому береговому рельефу, который отличается от каньонных смотровых.', 'A separate Charyn park route through a floodplain grove, old ash shade and gentle river terrain, distinct from the canyon viewpoints.', 'Шарын паркінің каньон көріністерінен бөлек бағыты: өзен жайылмасындағы тоғай, көне шаған көлеңкесі және жұмсақ жағалау бедері.', 43.34900000, 79.08700000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn','ash-grove','riverbank','walking']::text[]),
    ('KZ', 'KZT', 'sogety-plateau-ridge-walk', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка гряды плато Согеты', 'Sogety Plateau Ridge Walk', 'Сөгеті үстірті жотасы серуені', 'Сухой маршрут восточнее Алматы по ветреным грядам, полупустынным склонам и видам между Бартогаем, Богуты и Чарынской стороной.', 'A dry route east of Almaty across windy ridges, semi-desert slopes and views between Bartogai, Boguty and the Charyn side.', 'Алматының шығысындағы желді жоталар, шөлейт беткейлер және Бартоғай, Бөгеті мен Шарын жаққа ашық көріністер арқылы өтетін құрғақ бағыт.', 43.49800000, 78.62200000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','sogety','plateau','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'baceen-lake-stone-trail', 'karaganda', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Каменная тропа озера Бассейн', 'Baceen Lake Stone Trail', 'Бассейн көлі тас соқпағы', 'Каркаралинская экотропа к небольшому озеру среди гранитных форм, сосен и тихих участков леса для спокойного дневного выхода.', 'A Karkaraly eco-trail to a small lake among granite forms, pines and quiet forest sections for a calm day outing.', 'Қарқаралыдағы шағын көлге апаратын экосоқпақ: гранит пішіндері, қарағайлар және тыныш орман бөліктері бар күндік бағыт.', 49.42100000, 75.44000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','baceen-lake','eco-trail','hiking']::text[]),
    ('KZ', 'KZT', 'saryesik-atyrau-desert-edge-walk', 'balkhash', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка по краю пустыни Сарыесик-Атырау', 'Saryesik-Atyrau Desert Edge Walk', 'Сарыесік-Атырау шөлі жиегі серуені', 'Маршрут южнее Балхаша по песчаным участкам, редким озерцам и открытому горизонту для мягкой пустынной остановки в дороге.', 'A route south of Balkhash across sandy sections, small seasonal lakes and an open horizon for a gentle desert stop on the road.', 'Балқаштың оңтүстігіндегі құмды бөліктер, шағын маусымдық көлдер және жолдағы жеңіл шөл аялдамасына арналған ашық көкжиек бағыты.', 45.90000000, 76.10000000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash','taldykorgan']::text[], ARRAY['balkhash','taldykorgan']::text[], ARRAY['kazakhstan','balkhash-alakol','desert-edge','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_last_outdoor_route_gaps_resolved_places AS
SELECT
    ('117d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-last-outdoor-route-gaps-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_last_outdoor_route_gaps_places;

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
FROM seed_kazakhstan_last_outdoor_route_gaps_resolved_places
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
FROM seed_kazakhstan_last_outdoor_route_gaps_resolved_places
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
FROM seed_kazakhstan_last_outdoor_route_gaps_resolved_places
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
FROM seed_kazakhstan_last_outdoor_route_gaps_resolved_places
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
FROM seed_kazakhstan_last_outdoor_route_gaps_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_last_outdoor_route_gaps_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_outdoor_route_gaps_places;
