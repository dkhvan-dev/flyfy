-- Extra Kazakhstan local outdoor gap seed.
-- Adds distinct route-level places after the dense Kazakhstan hiking/outdoor seed layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_local_outdoor_gap_routes_places;

CREATE TEMP TABLE seed_kazakhstan_extra_local_outdoor_gap_routes_places (
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

INSERT INTO seed_kazakhstan_extra_local_outdoor_gap_routes_places (
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
    ('KZ', 'KZT', 'terisbutak-gorge-descent-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Спусковая тропа ущелья Терисбутак', 'Terisbutak Gorge Descent Trail', 'Терісбұтақ шатқалы түсу соқпағы', 'Маршрут от зоны Кок-Жайляу к долине Большой Алматинки по Терисбутаку, с лесными участками, ручьем и спокойным выходом из популярного плато.', 'A route from the Kok-Zhailau area toward the Big Almaty valley via Terisbutak, with forest sections, a stream and a calmer exit from the popular plateau.', 'Көк-Жайлау аймағынан Терісбұтақ арқылы Үлкен Алматы аңғарына түсетін бағыт: орманды бөліктер, бұлақ және танымал үстірттен тынышырақ шығу.', 43.12500000, 76.94000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kok-zhailau','terisbutak','ile-alatau','hiking']::text[]),
    ('KZ', 'KZT', 'kamenskiy-ridge-ak-kain-traverse', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Траверс хребта Каменского к Ак-Каину', 'Kamenskiy Ridge Ak-Kain Traverse', 'Каменский жотасынан Ақ-Қайыңға траверс', 'Видовой маршрут от Кок-Жайляу по Каменскому гребню к стороне Ак-Каина, где прогулка становится более протяженной и панорамной без технического альпинизма.', 'A scenic route from Kok-Zhailau along the Kamenskiy ridge toward the Ak-Kain side, turning the walk into a longer panoramic traverse without technical climbing.', 'Көк-Жайлаудан Каменский жотасымен Ақ-Қайың жағына өтетін көріністі бағыт, техникалық альпинизмсіз ұзақ әрі панорамалы серуенге айналады.', 43.11900000, 76.96500000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kok-zhailau','kamenskiy-ridge','ak-kain','trekking']::text[]),
    ('KZ', 'KZT', 'tuyuk-su-crag-approach-walk', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Подходная прогулка к скалам Туюк-Су', 'Tuyuk-Su Crag Approach Walk', 'Тұйық-Су жартастарына жақындау серуені', 'Короткий высокогорный маршрут из зоны Шымбулака к скальным участкам Туюк-Су, подходящий для наблюдения альпийского рельефа без ухода на ледник.', 'A short high-mountain route from the Shymbulak area toward Tuyuk-Su crag sections, useful for seeing alpine terrain without continuing onto the glacier.', 'Шымбұлақ аймағынан Тұйық-Су жартастарына апаратын қысқа биіктау бағыты, мұздыққа шықпай-ақ альпілік бедерді көруге қолайлы.', 43.08600000, 77.08100000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','tuyuk-su','crags','shymbulak','walking']::text[]),
    ('KZ', 'KZT', 'upper-butakovka-falls-trail', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа к верхним водопадам Бутаковки', 'Upper Butakovka Falls Trail', 'Бутаковканың жоғарғы сарқырамаларына соқпақ', 'Более глубокий маршрут по Бутаковскому ущелью выше популярного нижнего водопада, с еловыми склонами, тенью и тихими верхними каскадами.', 'A deeper Butakovka Gorge route above the popular lower waterfall, with spruce slopes, shade and quieter upper cascades.', 'Танымал төменгі сарқырамадан жоғары Бутаковка шатқалымен өтетін тереңірек бағыт: шыршалы беткейлер, көлеңке және тыныш жоғарғы каскадтар.', 43.17600000, 77.09400000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','butakovka','upper-falls','ile-alatau','hiking']::text[]),
    ('KZ', 'KZT', 'kara-koba-river-valley-trail', 'ust-kamenogorsk', 'NATURE', 0, 6, 'HOURS', 4.7, 'Тропа долины реки Кара-Коба', 'Kara-Koba River Valley Trail', 'Қара-Қоба өзені аңғары соқпағы', 'Алтайский маршрут по долине Кара-Кобы к луговым участкам, лесным склонам и спокойному сценарию Катон-Карагая вдали от городских маршрутов.', 'An Altai route along the Kara-Koba valley toward meadow sections, forest slopes and a calm Katon-Karagay scenario far from city routes.', 'Қара-Қоба аңғарымен шалғындарға, орманды беткейлерге және қалалық бағыттардан алыс тыныш Қатонқарағай сценарийіне апаратын Алтай бағыты.', 49.23000000, 86.12000000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','katon-karagay','kara-koba','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'burabay-climber-rocks-walk', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Прогулка скалолазных камней Бурабая', 'Burabay Climber Rocks Walk', 'Бурабай өрмелеу жартастары серуені', 'Короткий маршрут по гранитным выходам Бурабайской зоны, где лес, озерный воздух и скальные формы дают активный сценарий без длинного трека.', 'A short route across Burabay granite outcrops where forest, lake air and rock forms create an active plan without a long trek.', 'Бурабай аймағындағы гранитті жерлермен өтетін қысқа бағыт, орман, көл ауасы және жартастар ұзақ трексіз белсенді сценарий береді.', 53.08300000, 70.30500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','granite','climber-rocks','walking']::text[]),
    ('KZ', 'KZT', 'bayanaul-stone-head-ridge-walk', 'pavlodar', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Гребневая прогулка к Каменной голове Баянаула', 'Bayanaul Stone Head Ridge Walk', 'Баянауыл Тас бас жотасы серуені', 'Баянаульская прогулка к выразительным гранитным формам и коротким гребням, дополняющая озерные маршруты более фактурным скальным сценарием.', 'A Bayanaul walk toward expressive granite forms and short ridges, complementing lake routes with a more textured rocky scenario.', 'Баянауылдағы айқын гранит пішіндері мен қысқа жоталарға апаратын серуен, көл бағыттарын жартасты сценариймен толықтырады.', 50.78400000, 75.69800000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','stone-head','granite','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places AS
SELECT
    ('123d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-extra-local-outdoor-gap-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_places;

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
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_extra_local_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_local_outdoor_gap_routes_places;
