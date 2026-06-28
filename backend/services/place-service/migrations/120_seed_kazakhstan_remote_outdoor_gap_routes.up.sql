-- Remote Kazakhstan outdoor gap seed.
-- Adds a few distinct route-level places that are not covered by the dense Kazakhstan hiking/outdoor layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_remote_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remote_outdoor_gap_routes_places;

CREATE TEMP TABLE seed_kazakhstan_remote_outdoor_gap_routes_places (
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

INSERT INTO seed_kazakhstan_remote_outdoor_gap_routes_places (
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
    ('KZ', 'KZT', 'komissarovka-forester-house-walk', 'karaganda', 'NATURE', 1000, 2, 'HOURS', 4.6, 'Прогулка к дому лесничего в Комиссаровке', 'Komissarovka Forester House Walk', 'Комиссаровка орманшы үйіне серуен', 'Короткая лесная прогулка Каркаралы к историческому деревянному дому лесничего, соснам и спокойным участкам национального парка.', 'A short Karkaraly forest walk to the historic wooden forester house, pine sections and quiet national-park paths.', 'Қарқаралыдағы тарихи ағаш орманшы үйіне, қарағайлы бөліктерге және ұлттық парктің тыныш соқпақтарына апаратын қысқа орман серуені.', 49.40400000, 75.46500000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','komissarovka','heritage','walking']::text[]),
    ('KZ', 'KZT', 'kyzyl-kensh-palace-valley-trail', 'karaganda', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа долины дворца Кызыл-Кениш', 'Kyzyl-Kensh Palace Valley Trail', 'Қызыл-Кеніш сарайы аңғары соқпағы', 'Маршрут в Кентских горах к руинам Кызыл-Кениш, каменным склонам, тихой долине и природно-историческому сценарию Каркаралы.', 'A Kent Mountains route toward the Kyzyl-Kensh ruins, rocky slopes, a quiet valley and a nature-plus-history Karkaraly scenario.', 'Кент тауларындағы Қызыл-Кеніш қирандыларына, тасты беткейлерге, тыныш аңғарға және Қарқаралының табиғи-тарихи сценарийіне апаратын бағыт.', 49.21000000, 75.68000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','kent-mountains','kyzyl-kensh','heritage','hiking']::text[]),
    ('KZ', 'KZT', 'sauyr-muztau-foothill-trail', 'semey', 'NATURE', 0, 7, 'HOURS', 4.7, 'Предгорная тропа Саур-Музтау', 'Sauyr Muztau Foothill Trail', 'Сауыр-Мұзтау тау етегі соқпағы', 'Восточноказахстанский маршрут к предгорьям Саура с дальними видами на Музтау, сухими долинами и ощущением редкого пограничного ландшафта.', 'An eastern Kazakhstan route toward the Saur foothills with distant Muztau views, dry valleys and a rare borderland landscape feel.', 'Шығыс Қазақстандағы Сауыр тау етегіне апаратын бағыт: алыстан Мұзтау көріністері, құрғақ аңғарлар және сирек шекаралық ландшафт әсері.', 47.10000000, 85.65000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','saur','muztau','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'tarbagatai-wild-fruit-ridge-trail', 'semey', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Тропа диких плодовых склонов Тарбагатая', 'Tarbagatai Wild Fruit Ridge Trail', 'Тарбағатай жабайы жеміс жотасы соқпағы', 'Маршрут Тарбагатайского национального парка по горно-степным склонам, диким плодовым участкам и длинным видам Восточного Казахстана.', 'A Tarbagatai National Park route across mountain-steppe slopes, wild-fruit sections and long views of eastern Kazakhstan.', 'Тарбағатай ұлттық паркінің тау-дала беткейлері, жабайы жеміс учаскелері және Шығыс Қазақстанның кең көріністері арқылы өтетін бағыты.', 47.20000000, 81.60000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey']::text[], ARRAY['kazakhstan','tarbagatai','national-park','wild-fruit','hiking']::text[]),
    ('KZ', 'KZT', 'zaysan-lake-steppe-shore-walk', 'ust-kamenogorsk', 'NATURE', 0, 3, 'HOURS', 4.5, 'Степная прогулка берега Зайсана', 'Zaysan Lake Steppe Shore Walk', 'Зайсан көлі дала жағалауы серуені', 'Спокойная прогулка у большого восточноказахстанского озера с открытым берегом, степным ветром и мягкой остановкой на маршруте к Алтаю и Тарбагатаю.', 'A calm walk by the large eastern Kazakhstan lake, with open shore, steppe wind and an easy stop on routes toward Altai and Tarbagatai.', 'Шығыс Қазақстандағы үлкен көлдің ашық жағалауы, дала желі және Алтай мен Тарбағатай бағытындағы жеңіл аялдамаға арналған тыныш серуен.', 47.47000000, 84.87000000, 'Balkhash lake, september 2020.jpg', ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['kazakhstan','east-kazakhstan','zaysan','lake-shore','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_remote_outdoor_gap_routes_resolved_places AS
SELECT
    ('120d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-remote-outdoor-gap-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_remote_outdoor_gap_routes_places;

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
FROM seed_kazakhstan_remote_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_remote_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_remote_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_remote_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_remote_outdoor_gap_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_remote_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remote_outdoor_gap_routes_places;
