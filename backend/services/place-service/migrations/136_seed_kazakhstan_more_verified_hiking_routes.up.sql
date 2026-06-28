-- More verified Kazakhstan hiking and outdoor route seed.
-- Adds a compact non-duplicate layer after the broad Kazakhstan hiking enrichment batches.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_more_verified_hiking_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_verified_hiking_routes_places;

CREATE TEMP TABLE seed_kazakhstan_more_verified_hiking_routes_places (
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

INSERT INTO seed_kazakhstan_more_verified_hiking_routes_places (
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
    ('KZ', 'KZT', 'maralsay-gorge-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа ущелья Маралсай', 'Maralsay Gorge Trail', 'Маралсай шатқалы соқпағы', 'Западный маршрут Иле-Алатауского парка к лесному ущелью, ручьям и тихим склонам, хорошо дополняющий Аксайскую сторону Алматы.', 'A western Ile-Alatau park route toward a forested gorge, streams and quiet slopes, complementing the Aksai side of Almaty.', 'Алматының Ақсай жағын толықтыратын Іле Алатауы паркінің батыс бағыты: орманды шатқал, бұлақтар және тыныш беткейлер.', 43.09000000, 76.73500000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','maralsay','gorge','hiking']::text[]),
    ('KZ', 'KZT', 'prosveshchenets-pass-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Тропа перевала Просвещенец', 'Prosveshchenets Pass Trail', 'Просвещенец асуы соқпағы', 'Горный маршрут южнее Алматы к перевальному рельефу, каменным участкам и видам Большого Алматинского ущелья для подготовленного дневного выхода.', 'A mountain route south of Almaty toward pass terrain, rocky sections and Big Almaty Gorge views for a prepared day hike.', 'Алматының оңтүстігіндегі асу бедеріне, тасты бөліктерге және Үлкен Алматы шатқалы көріністеріне апаратын дайын күндік бағыт.', 43.05500000, 76.97000000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','big-almaty-gorge','pass','trekking']::text[]),
    ('KZ', 'KZT', 'pogrebetsky-glacier-view-trail', 'almaty', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Тропа к виду на ледник Погребецкого', 'Pogrebetsky Glacier View Trail', 'Погребецкий мұздығы көрініс соқпағы', 'Высотный маршрут в узле Туюк-Су к моренным полям, холодным ручьям и видам ледниковой зоны без технического восхождения.', 'A high mountain route in the Tuyuk-Su area toward moraine fields, cold streams and glacier-zone views without a technical ascent.', 'Тұйық-Су аймағындағы мореналық алқаптарға, салқын бұлақтарға және техникалық өрмелеусіз мұздық аймағы көріністеріне апаратын биіктау бағыты.', 43.07000000, 77.10500000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','tuyuk-su','glacier-view','moraine','trekking']::text[]),
    ('KZ', 'KZT', 'tuyuk-su-gate-moraine-walk', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Моренная прогулка ворот Туюк-Су', 'Tuyuk-Su Gate Moraine Walk', 'Тұйық-Су қақпасы морена серуені', 'Более короткий высокогорный сценарий из зоны Шымбулака к моренным формам и скальным воротам Туюк-Су без ухода к дальнему леднику.', 'A shorter highland route from the Shymbulak area toward moraine forms and the rocky Tuyuk-Su gate without continuing to the distant glacier.', 'Шымбұлақ аймағынан мореналық пішіндерге және Тұйық-Судың тасты қақпасына апаратын, алыс мұздыққа шықпайтын қысқалау биіктау бағыты.', 43.08300000, 77.08400000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','tuyuk-su','moraine','walking']::text[]),
    ('KZ', 'KZT', 'butakovka-pass-forest-trail', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Лесная тропа Бутаковского перевала', 'Butakovka Pass Forest Trail', 'Бутаковка асуы орман соқпағы', 'Маршрут выше Бутаковского ущелья к лесному перевалу, еловым участкам и спокойным видам восточной стороны Алматы.', 'A route above Butakovka Gorge toward a forest pass, spruce sections and calm views on Almaty eastern side.', 'Бутаковка шатқалынан жоғары орманды асуға, шыршалы бөліктерге және Алматының шығыс жағының тыныш көріністеріне апаратын бағыт.', 43.18000000, 77.10500000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','butakovka','pass','forest','hiking']::text[]),
    ('KZ', 'KZT', 'kumbel-pass-ridge-walk', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Гребневая прогулка перевала Кумбель', 'Kumbel Pass Ridge Walk', 'Күмбел асуы жота серуені', 'Связующий маршрут между медеускими тропами и верхними склонами Кумбеля: лес, открытый гребень и быстрые панорамы города.', 'A linking route between the Medeu-side trails and upper Kumbel slopes, with forest, open ridge and quick city panoramas.', 'Медеу жақ соқпақтары мен Күмбелдің жоғарғы беткейлерін байланыстыратын бағыт: орман, ашық жота және қала панорамалары.', 43.13700000, 76.98900000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kumbel','pass','ridge','walking']::text[]),
    ('KZ', 'KZT', 'kyrkkyz-ridge-trail', 'shymkent', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа хребта Кырккыз', 'Kyrkkyz Ridge Trail', 'Қырыққыз жотасы соқпағы', 'Южный маршрут к сухим гребням и предгорным видам Западного Тянь-Шаня, расширяющий выбор активных выездов из Шымкента.', 'A southern route to dry ridges and Western Tian Shan foothill views, widening active day choices from Shymkent.', 'Шымкенттен белсенді шығу таңдауларын кеңейтетін оңтүстік бағыт: құрғақ жоталар және Батыс Тянь-Шань тау етегі көріністері.', 42.51500000, 70.07500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','south-kazakhstan','western-tian-shan','ridge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'ordabasy-hill-steppe-walk', 'shymkent', 'NATURE', 0, 3, 'HOURS', 4.5, 'Степная прогулка холма Ордабасы', 'Ordabasy Hill Steppe Walk', 'Ордабасы төбесі дала серуені', 'Короткий маршрут по открытым южным холмам с ветром, степным горизонтом и историческим контекстом для легкого выезда из Шымкента.', 'A short route across open southern hills with wind, steppe horizon and historical context for an easy outing from Shymkent.', 'Шымкенттен жеңіл шығуға арналған ашық оңтүстік төбелер бағыты: жел, дала көкжиегі және тарихи контекст.', 42.73400000, 69.34500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','ordabasy','steppe-hill','heritage','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kenderli-kayasan-cliff-walk', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка обрывов Кендерли-Каясан', 'Kenderli-Kayasan Cliff Walk', 'Кендірлі-Қаясан жартастары серуені', 'Мангистауский маршрут у южной каспийской стороны к сухим обрывам, морскому ветру и редкому сочетанию пустыни с береговой линией.', 'A southern Mangystau Caspian-side route toward dry cliffs, sea wind and a rare mix of desert with shoreline.', 'Оңтүстік Маңғыстаудағы Каспий жақ бағыты: құрғақ жартастар, теңіз желі және шөл мен жағалаудың сирек үйлесімі.', 42.65000000, 52.74500000, 'Pedestrian walkway along the Caspian Sea waterfront promenade in Aktau, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','kenderli-kayasan','caspian','cliffs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'syrdarya-delta-reed-walk', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.4, 'Камышовая прогулка дельты Сырдарьи', 'Syrdarya Delta Reed Walk', 'Сырдария атырауы қамыс серуені', 'Приаральский маршрут к камышовым участкам, воде и птицам нижней Сырдарьи, который отличается от городских и тугайных прогулок Кызылорды.', 'An Aral-side route toward reeds, water and birdlife of the lower Syrdarya, distinct from Kyzylorda urban and tugai walks.', 'Қызылорданың қалалық және тоғайлы серуендерінен бөлек, төменгі Сырдарияның қамысына, суына және құстарына апаратын Арал маңы бағыты.', 45.82000000, 62.12000000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','kyzylorda-region','syrdarya-delta','reedbed','birdwatching','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_more_verified_hiking_routes_resolved_places AS
SELECT
    ('136d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-more-verified-hiking-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_more_verified_hiking_routes_places;

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
FROM seed_kazakhstan_more_verified_hiking_routes_resolved_places
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
FROM seed_kazakhstan_more_verified_hiking_routes_resolved_places
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
FROM seed_kazakhstan_more_verified_hiking_routes_resolved_places
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
FROM seed_kazakhstan_more_verified_hiking_routes_resolved_places
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
FROM seed_kazakhstan_more_verified_hiking_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_more_verified_hiking_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_verified_hiking_routes_places;
