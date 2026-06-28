-- Final Kazakhstan microgap outdoor route seed.
-- Adds a small set of non-duplicate route-level hiking and walking places around existing Kazakhstan city hubs.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_final_microgap_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_final_microgap_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_final_microgap_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_final_microgap_outdoor_routes_places (
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
    ('KZ', 'KZT', 'qotyrbulaq-forest-valley-walk', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Прогулка лесной долины Котырбулак', 'Qotyrbulaq Forest Valley Walk', 'Қотырбұлақ орман аңғары серуені', 'Тихий маршрут восточной части Малой Алматинки к лесной долине, ручьям и мягким склонам без ухода в технический треккинг.', 'A quiet Small Almatinka side route toward a forest valley, streams and gentle slopes without moving into technical trekking.', 'Кіші Алматының шығыс жағындағы орман аңғарына, бұлақтарға және жеңіл беткейлерге апаратын техникалық треккингсіз тыныш бағыт.', 43.16400000, 77.06700000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','qotyrbulaq','forest-valley','walking']::text[]),
    ('KZ', 'KZT', 'kuigensai-moraine-lakes-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Тропа моренных озер Куйгенсая', 'Kuigensai Moraine Lakes Trail', 'Күйгенсай мореналық көлдері соқпағы', 'Более верхний маршрут долины Куйгенсай к моренным участкам, холодным ручьям и альпийскому рельефу над зоной Медеу.', 'A higher Kuigensai valley route toward moraine sections, cold streams and alpine terrain above the Medeu area.', 'Медеу аймағынан жоғары Күйгенсай аңғарының мореналық бөліктеріне, салқын бұлақтарына және альпілік бедеріне апаратын бағыт.', 43.11300000, 77.06600000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','kuigensai','moraine-lakes','trekking']::text[]),
    ('KZ', 'KZT', 'narynkol-khan-tengri-view-walk', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка Нарынкола с видом на Хан-Тенгри', 'Narynkol Khan Tengri View Walk', 'Нарынқолдан Хан-Тәңірі көрінісіне серуен', 'Дальний маршрут Райымбекского района к открытым пастбищам, горному горизонту и редкому виду на самый высокий узел Казахстана.', 'A remote Raiymbek District route toward open pastures, mountain horizon and a rare view line to the highest alpine node of Kazakhstan.', 'Райымбек ауданындағы ашық жайылымдарға, тау көкжиегіне және Қазақстанның ең биік альпілік торабына сирек көрініске апаратын алыс бағыт.', 42.72690000, 80.16530000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','narynkol','khan-tengri','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'bayankol-glacier-valley-trail', 'almaty', 'NATURE', 0, 7, 'HOURS', 4.8, 'Тропа ледниковой долины Баянкола', 'Bayankol Glacier Valley Trail', 'Баянқол мұздық аңғары соқпағы', 'Высокогорный маршрут в сторону Баянкола к речной долине, открытым моренным видам и сильному ощущению дальнего Тянь-Шаня.', 'A high mountain route toward Bayankol with a river valley, open moraine views and a strong remote Tian Shan feel.', 'Баянқол бағытына, өзен аңғарына, ашық мореналық көріністерге және алыс Тянь-Шань әсеріне апаратын биіктау бағыты.', 42.36500000, 80.20500000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','bayankol','glacier-valley','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'ketmen-pass-caravan-trail', 'almaty', 'NATURE', 0, 6, 'HOURS', 4.6, 'Караванная тропа перевала Кетмен', 'Ketmen Pass Caravan Trail', 'Кетпен асуы керуен соқпағы', 'Маршрут Кегенской стороны по старому перевальному направлению с пастбищами, сухими гребнями и видами на восточные хребты.', 'A Kegen-side route along an old pass direction with pastures, dry ridges and views of the eastern ranges.', 'Кеген жағындағы ескі асу бағыты: жайылымдар, құрғақ жоталар және шығыс жоталарына көріністер арқылы өтеді.', 42.92500000, 79.74000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty','taldykorgan']::text[], ARRAY['kazakhstan','almaty-region','ketmen-pass','caravan-trail','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'upper-aksu-gorge-view-trail', 'shymkent', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Верхняя видовая тропа ущелья Аксу', 'Upper Aksu Gorge View Trail', 'Ақсу шатқалының жоғарғы көрініс соқпағы', 'Южный маршрут Аксу-Жабаглы к верхним обзорным точкам ущелья, где каньонный рельеф читается глубже и спокойнее.', 'A southern Aksu-Zhabagly route toward upper gorge viewpoints where the canyon landform reads deeper and calmer.', 'Ақсу-Жабағылыдағы шатқалдың жоғарғы көрініс нүктелеріне апаратын оңтүстік бағыт, каньон бедері терең әрі тыныш ашылады.', 42.39200000, 70.52600000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','aksu-zhabagly','upper-gorge','viewpoint','hiking']::text[]),
    ('KZ', 'KZT', 'tersek-karagay-pine-walk', 'kostanay', 'NATURE', 0, 3, 'HOURS', 4.5, 'Сосновая прогулка Терсек-Карагая', 'Tersek-Karagay Pine Walk', 'Терсек-Қарағай қарағайлы серуені', 'Северный маршрут Наурзумской зоны по сосновому кластеру, степным полянам и тихим участкам наблюдения за птицами.', 'A northern Naurzum-area route through a pine cluster, steppe glades and quiet birdwatching sections.', 'Наурызым аймағындағы қарағайлы кластер, дала алаңдары және құс бақылауға қолайлы тыныш бөліктер арқылы өтетін солтүстік бағыт.', 51.56000000, 64.51000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','naurzum','tersek-karagay','free-entry','walking','birdwatching']::text[]);

CREATE TEMP TABLE seed_kazakhstan_final_microgap_outdoor_routes_resolved_places AS
SELECT
    ('128d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-final-microgap-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_final_microgap_outdoor_routes_places;

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
FROM seed_kazakhstan_final_microgap_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_final_microgap_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_final_microgap_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_final_microgap_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_final_microgap_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_final_microgap_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_final_microgap_outdoor_routes_places;
