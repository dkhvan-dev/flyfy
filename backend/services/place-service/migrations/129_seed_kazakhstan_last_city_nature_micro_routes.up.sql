-- Last Kazakhstan city-nature micro route seed.
-- Adds non-duplicate local walking and light hiking places after the broad Kazakhstan outdoor enrichment layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_last_city_nature_micro_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_city_nature_micro_routes_places;

CREATE TEMP TABLE seed_kazakhstan_last_city_nature_micro_routes_places (
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

INSERT INTO seed_kazakhstan_last_city_nature_micro_routes_places (
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
    ('KZ', 'KZT', 'bukpa-hill-city-trail', 'kokshetau', 'NATURE', 0, 2, 'HOURS', 4.6, 'Городская тропа холма Букпа', 'Bukpa Hill City Trail', 'Бұқпа төбесі қалалық соқпағы', 'Короткий городской подъем в Кокшетау к панорамам города, лесостепи и северного горизонта без выезда в дальний Бурабай.', 'A short city climb in Kokshetau toward views of the city, forest-steppe and northern horizon without a full trip to Burabay.', 'Көкшетаудағы қала, орманды дала және солтүстік көкжиек көріністеріне апаратын қысқа қалалық көтерілу, алыс Бурабай сапарынсыз.', 53.28800000, 69.37500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau']::text[], ARRAY['kokshetau']::text[], ARRAY['kazakhstan','kokshetau','bukpa','city-hill','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'arykbalyk-lake-forest-trail', 'kokshetau', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Лесная тропа озера Арыкбалык', 'Arykbalyk Lake Forest Trail', 'Арықбалық көлі орман соқпағы', 'Северный маршрут Кокшетауского природного кластера по лесистым берегам, низким грядам и тихому озерному пейзажу.', 'A northern route in the Kokshetau nature cluster across forested shores, low ridges and a quiet lake landscape.', 'Көкшетау табиғи кластеріндегі орманды жағалар, аласа жоталар және тыныш көл ландшафты арқылы өтетін солтүстік бағыт.', 53.10500000, 68.01500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kazakhstan','kokshetau-national-park','arykbalyk','lake','forest','hiking']::text[]),
    ('KZ', 'KZT', 'tutybulak-cave-tugai-walk', 'turkestan', 'NATURE', 0, 3, 'HOURS', 4.5, 'Тугайная прогулка к пещере Тутыбулак', 'Tutybulak Cave Tugai Walk', 'Тұттыбұлақ үңгірі тоғай серуені', 'Маршрут Сырдарья-Туркестанского парка к природно-археологической пещере, тугайным участкам и спокойному южному ландшафту.', 'A Syrdarya-Turkestan park route toward a nature-and-archaeology cave, tugai sections and a calm southern landscape.', 'Сырдария-Түркістан паркінің табиғи-археологиялық үңгірге, тоғайлы бөліктерге және тыныш оңтүстік ландшафтқа апаратын бағыты.', 42.92000000, 68.62000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','turkestan-region','syrdarya-turkestan','tugai','cave','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'daryalyktakyr-takyr-plain-walk', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.4, 'Прогулка такырной равнины Дарьялыктақыр', 'Daryalyktakyr Takyr Plain Walk', 'Дариялықтақыр тақыр жазығы серуені', 'Спокойный геомаршрут Кызылординской области по древнему руслу, солончаковым пятнам и открытому пустынному горизонту.', 'A calm Kyzylorda Region geotrail across an ancient channel, salt-flat patches and an open desert horizon.', 'Қызылорда облысындағы көне арна, сорлы бөліктер және ашық шөл көкжиегі арқылы өтетін тыныш геобағыт.', 45.28000000, 65.85000000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','kyzylorda-region','takyr','ancient-channel','desert','free-entry','geotrail','walking']::text[]),
    ('KZ', 'KZT', 'ural-chagan-riverbank-walk', 'oral', 'NATURE', 0, 2, 'HOURS', 4.5, 'Береговая прогулка Урала и Чагана', 'Ural-Chagan Riverbank Walk', 'Жайық пен Шаған жағалауы серуені', 'Легкий западноказахстанский маршрут по городским берегам Урала и Чагана с водой, пойменной зеленью и мягким вечерним форматом.', 'An easy West Kazakhstan route along the urban banks of the Ural and Chagan rivers with water, floodplain greenery and a gentle evening format.', 'Батыс Қазақстандағы Жайық пен Шағанның қалалық жағалары арқылы өтетін жеңіл бағыт, суы, жайылма жасылдығы және кешкі жұмсақ форматы бар.', 51.22500000, 51.37400000, 'Atyrau footbridge across Ural River.jpg', ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','ural-river','chagan','riverbank','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karatomar-reservoir-shore-walk', 'kostanay', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка Каратомарского водохранилища', 'Karatomar Reservoir Shore Walk', 'Қаратомар су қоймасы жағалау серуені', 'Северный маршрут к водохранилищу на Тоболе с открытой водой, степным ветром и спокойной природной паузой из Костаная.', 'A northern route to the Tobol reservoir with open water, steppe wind and a calm nature pause from Kostanay.', 'Қостанайдан Тобылдағы су қоймасына апаратын солтүстік бағыт: ашық су, дала желі және тыныш табиғи үзіліс.', 52.95000000, 62.31000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','karatomar','reservoir','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_last_city_nature_micro_routes_resolved_places AS
SELECT
    ('129d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-last-city-nature-micro-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_last_city_nature_micro_routes_places;

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
FROM seed_kazakhstan_last_city_nature_micro_routes_resolved_places
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
FROM seed_kazakhstan_last_city_nature_micro_routes_resolved_places
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
FROM seed_kazakhstan_last_city_nature_micro_routes_resolved_places
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
FROM seed_kazakhstan_last_city_nature_micro_routes_resolved_places
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
FROM seed_kazakhstan_last_city_nature_micro_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_last_city_nature_micro_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_city_nature_micro_routes_places;
