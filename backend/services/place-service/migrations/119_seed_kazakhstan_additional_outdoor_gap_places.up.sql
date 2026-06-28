-- Additional Kazakhstan outdoor place seed.
-- Adds distinct route-level places after the dense Kazakhstan hiking/outdoor seed layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_additional_outdoor_gap_places_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_outdoor_gap_places;

CREATE TEMP TABLE seed_kazakhstan_additional_outdoor_gap_places (
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

INSERT INTO seed_kazakhstan_additional_outdoor_gap_places (
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
    ('KZ', 'KZT', 'kenesary-cave-pine-walk', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Сосновая прогулка к пещере Кенесары', 'Kenesary Cave Pine Walk', 'Кенесары үңгіріне қарағайлы серуен', 'Короткий маршрут в Бурабае через сосновые участки, гранитные камни и историческую пещеру с мягким подъемом для семейного дня.', 'A short Burabay route through pine sections, granite stones and a historic cave with a gentle climb for a family day.', 'Бурабайдағы қарағайлы бөліктер, гранит тастар және тарихи үңгір арқылы өтетін, отбасылық күнге қолайлы жеңіл көтерілуі бар қысқа бағыт.', 53.08300000, 70.26500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','kenesary-cave','pine-forest','walking']::text[]),
    ('KZ', 'KZT', 'peak-of-courage-toraygir-trail', 'pavlodar', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа Пика Смелых у Торайгыра', 'Peak of Courage Toraygir Trail', 'Торайғырдағы Батылдар шыңы соқпағы', 'Баянаульский маршрут от озера Торайгыр к гранитным склонам, соснам и открытой обзорной точке без тяжелого набора высоты.', 'A Bayanaul route from Toraygir Lake toward granite slopes, pines and an open viewpoint without a heavy elevation gain.', 'Торайғыр көлінен гранит беткейлерге, қарағайларға және ауыр биіктік жинамайтын ашық көрініс нүктесіне апаратын Баянауыл бағыты.', 50.80600000, 75.87200000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','toraygir','granite','hiking']::text[]),
    ('KZ', 'KZT', 'gromotukha-gorge-forest-trail', 'ust-kamenogorsk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Лесная тропа ущелья Громотухи', 'Gromotukha Gorge Forest Trail', 'Громотуха шатқалы орман соқпағы', 'Алтайский маршрут в районе Риддера вдоль прохладной реки, хвойных склонов и тихих лесных участков для насыщенного дневного выхода.', 'An Altai route near Ridder along a cool river, conifer slopes and quiet forest sections for a rich day outing.', 'Риддер маңындағы салқын өзен, қылқанды беткейлер және тыныш орман бөліктері бойымен өтетін Алтай бағыты.', 50.34400000, 83.55600000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','ridder','gorge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'akkergeshen-chalk-plateau-walk', 'atyrau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка мелового плато Аккергешен', 'Akkergeshen Chalk Plateau Walk', 'Ақкергешен борлы үстірті серуені', 'Западноказахстанский геомаршрут к светлым меловым уступам, сухим ложбинам и открытому степному горизонту для короткого выезда из Атырау.', 'A western Kazakhstan geotrail to pale chalk escarpments, dry hollows and an open steppe horizon for a short outing from Atyrau.', 'Атыраудан қысқа сапарға арналған Батыс Қазақстан бағыты: ақшыл борлы кертпештер, құрғақ сайлар және ашық дала көкжиегі.', 47.63500000, 53.81800000, 'Atyrau footbridge across Ural River.jpg', ARRAY['atyrau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','atyrau-region','chalk','geotrail','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kokaral-aral-shore-walk', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка берега Арала у Кокарала', 'Kokaral Aral Shore Walk', 'Көкарал маңындағы Арал жағалауы серуені', 'Приаральский маршрут к открытому берегу, сухому ветру и пейзажу Северного Арала, который хорошо дополняет Камбаш и степные остановки региона.', 'An Aral-side route toward open shore, dry wind and North Aral scenery, complementing Kambash and regional steppe stops.', 'Қамбаш пен өңірдің далалық аялдамаларын толықтыратын, ашық жағалауға, құрғақ желге және Солтүстік Арал көрінісіне апаратын бағыт.', 46.52000000, 61.09000000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','aral-region','kokaral','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'tekes-river-meadow-trail', 'taldykorgan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Луговая тропа реки Текес', 'Tekes River Meadow Trail', 'Текес өзені шалғын соқпағы', 'Маршрут Кегенской стороны по речным лугам, сухим склонам и широким видам на восточные хребты для спокойного outdoor-дня.', 'A Kegen-side route across river meadows, dry slopes and wide views of eastern ranges for a calm outdoor day.', 'Кеген жақтағы өзен шалғындары, құрғақ беткейлер және шығыс жоталарға кең көріністер арқылы өтетін тыныш outdoor бағыты.', 42.74000000, 79.98000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['taldykorgan','almaty']::text[], ARRAY['almaty','taldykorgan']::text[], ARRAY['kazakhstan','almaty-region','kegen','tekes','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'shalkode-high-pasture-walk', 'almaty', 'NATURE', 0, 5, 'HOURS', 4.6, 'Прогулка высоких пастбищ Шалкуде', 'Shalkode High Pasture Walk', 'Шалкөде биік жайлауы серуені', 'Высокогорная прогулка восточнее Алматы по пастбищам, ручьям и открытым видам Кегенского направления без технического альпинизма.', 'A highland walk east of Almaty across pastures, streams and open Kegen-side views without technical mountaineering.', 'Алматының шығысындағы жайылымдар, бұлақтар және Кеген бағытының ашық көріністері арқылы өтетін, техникалық альпинизмсіз биіктау серуені.', 42.56000000, 80.25000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','kegen','pasture','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_additional_outdoor_gap_places_resolved_places AS
SELECT
    ('119d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-additional-outdoor-gap-places-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_additional_outdoor_gap_places;

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
FROM seed_kazakhstan_additional_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_additional_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_additional_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_additional_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_additional_outdoor_gap_places_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_additional_outdoor_gap_places_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_outdoor_gap_places;
