-- Kazakhstan weak-hub outdoor depth seed.
-- Adds non-duplicate route-level places for Kazakhstan hubs with lighter current nature coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_weak_hub_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_weak_hub_outdoor_depth_places;

CREATE TEMP TABLE seed_kazakhstan_weak_hub_outdoor_depth_places (
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
    access_city_ids text[] NOT NULL,
    departure_city_ids text[] NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[],
    PRIMARY KEY (country_code, slug)
);

INSERT INTO seed_kazakhstan_weak_hub_outdoor_depth_places (
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
    access_city_ids,
    departure_city_ids,
    extra_tags
) VALUES
    ('KZ', 'KZT', 'sergeyev-reservoir-shore-walk', 'petropavlovsk', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка Сергеевского водохранилища', 'Sergeyev Reservoir Shore Walk', 'Сергеев су қоймасы жағалауы серуені', 'Северный маршрут у Петропавловска к широкому зеркалу водохранилища на Есиле, песчаным берегам и спокойному формату лесостепной прогулки.', 'A northern route from Petropavlovsk toward the wide reservoir on the Yesil River, sandy shores and a calm forest-steppe walking format.', 'Петропавлдан Есілдегі кең су қоймасына, құмды жағалауға және тыныш орманды-дала серуеніне апаратын солтүстік бағыт.', 53.87800000, 67.42000000, ARRAY['petropavlovsk']::text[], ARRAY['petropavlovsk']::text[], ARRAY['kazakhstan','north-kazakhstan','sergeyev-reservoir','yesil','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shalkarteniz-salt-flat-walk', 'aktobe', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка солончака Шалкартениз', 'Shalkarteniz Salt Flat Walk', 'Шалқартеніз сорлы жазығы серуені', 'Маршрут Актюбинской области к солончаковым берегам, сухому горизонту и редкому озерно-степному пейзажу, отличающийся от меловых и горных маршрутов.', 'An Aktobe Region route to salt-flat shores, dry horizons and a rare lake-steppe landscape, distinct from chalk and hill routes.', 'Борлы және қыратты бағыттардан бөлек Ақтөбе облысындағы сорлы жағалауларға, құрғақ көкжиекке және сирек көл-дала ландшафтына апаратын маршрут.', 48.15000000, 61.12000000, ARRAY['aktobe','kostanay']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','shalkarteniz','salt-flat','lake-steppe','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kigach-delta-reed-walk', 'atyrau', 'NATURE', 0, 3, 'HOURS', 4.5, 'Камышовая прогулка дельты Кигача', 'Kigach Delta Reed Walk', 'Қиғаш атырауы қамыс серуені', 'Юго-западный маршрут Атырауской области по протокам, камышам и тихим водным участкам Кигача, расширяющий выбор за пределами Урала и Акжайыка.', 'A southwestern Atyrau Region route through Kigach channels, reeds and quiet waters, widening the choice beyond the Ural and Akzhaiyk routes.', 'Жайық пен Ақжайық бағыттарынан бөлек Қиғаш тармақтары, қамыс және тыныш су бөліктері арқылы өтетін Атырау облысының оңтүстік-батыс маршруты.', 46.55500000, 49.30000000, ARRAY['atyrau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','atyrau-region','kigach','delta','reedbed','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'aksuat-lake-reed-walk', 'kostanay', 'NATURE', 0, 3, 'HOURS', 4.5, 'Камышовая прогулка озера Аксуат', 'Aksuat Lake Reed Walk', 'Ақсуат көлі қамыс серуені', 'Северный природный маршрут Костанайской области к озерным камышам, птицам и открытому степному воздуху, не повторяющий Наурзумскую сосновую тропу.', 'A northern Kostanay Region nature route toward lake reeds, birds and open steppe air, not repeating the Naurzum pine route.', 'Наурызым қарағайлы бағытын қайталамайтын Қостанай облысының солтүстік табиғи бағыты: көл қамысы, құстар және ашық дала ауасы.', 51.54500000, 64.19000000, ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','aksuat','lake','reedbed','free-entry','birdwatching','walking']::text[]),
    ('KZ', 'KZT', 'aral-karakum-dune-walk', 'kyzylorda', 'NATURE', 0, 4, 'HOURS', 4.5, 'Дюнная прогулка Приаральских Каракумов', 'Aral Karakum Dune Walk', 'Арал Қарақұмы құмды серуені', 'Приаральский маршрут по песчаным грядам, сухим ложбинам и широкому горизонту Каракумов, отличающийся от озерных и дельтовых мест Кызылорды.', 'An Aral-side route across sandy ridges, dry hollows and the wide Karakum horizon, distinct from Kyzylorda lake and delta places.', 'Қызылорданың көл және атырау орындарынан бөлек Арал маңындағы құмды жоталар, құрғақ ойпаңдар және кең Қарақұм көкжиегі арқылы өтетін бағыт.', 46.69000000, 63.02000000, ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','kyzylorda-region','aral-karakum','dunes','desert','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'aralsor-salt-lake-walk', 'oral', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка соленого озера Аралсор', 'Aralsor Salt Lake Walk', 'Аралсор тұзды көлі серуені', 'Западноказахстанский маршрут из Орала к светлой соленой чаше, сухим берегам и открытому степному горизонту вместо очередной прогулки вдоль Жайыка.', 'A West Kazakhstan route from Oral toward a pale salt-lake basin, dry shores and open steppe horizon instead of another Ural River walk.', 'Жайық бойындағы тағы бір серуеннің орнына Оралдан ақшыл тұзды көлге, құрғақ жағалауға және ашық дала көкжиегіне апаратын бағыт.', 50.61000000, 50.17000000, ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','aralsor','salt-lake','steppe','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'tokrau-dry-delta-walk', 'balkhash', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка сухой дельты Токрау', 'Tokrau Dry Delta Walk', 'Тоқырау құрғақ атырауы серуені', 'Маршрут у северной стороны Балхаша по сухим руслам, камышовым пятнам и переходу степи к озерной кромке, отделенный от Бектау-Ата.', 'A route on the northern side of Balkhash through dry channels, reed patches and the transition from steppe to lake edge, separate from Bektau-Ata.', 'Бектау-Атадан бөлек Балқаштың солтүстік жағындағы құрғақ арналар, қамыс бөліктері және даланың көл жиегіне ауысуы арқылы өтетін бағыт.', 46.82000000, 75.18000000, ARRAY['balkhash']::text[], ARRAY['balkhash']::text[], ARRAY['kazakhstan','balkhash','tokrau','dry-delta','lake-edge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karsakpai-steppe-heritage-walk', 'zhezkazgan', 'NATURE', 0, 3, 'HOURS', 4.5, 'Степная прогулка Карсакпая', 'Karsakpai Steppe Heritage Walk', 'Қарсақпай дала мұрасы серуені', 'Короткий маршрут Улытауской области по степному поселковому ландшафту, водной кромке и индустриально-историческому контексту рядом с Жезказганом.', 'A short Ulytau Region route through a steppe settlement landscape, water edge and industrial heritage context near Zhezkazgan.', 'Жезқазған маңындағы Ұлытау облысының қысқа бағыты: дала елді мекені, су жиегі және индустриялық-тарихи контекст.', 47.82500000, 66.74000000, ARRAY['zhezkazgan']::text[], ARRAY['zhezkazgan']::text[], ARRAY['kazakhstan','ulytau','karsakpai','steppe','heritage','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_weak_hub_outdoor_depth_resolved_places AS
SELECT
    ('137d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    access_city_ids,
    departure_city_ids,
    ARRAY['kazakhstan-weak-hub-outdoor-depth-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_weak_hub_outdoor_depth_places;

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
FROM seed_kazakhstan_weak_hub_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_weak_hub_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_weak_hub_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_weak_hub_outdoor_depth_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_weak_hub_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_weak_hub_outdoor_depth_places;
