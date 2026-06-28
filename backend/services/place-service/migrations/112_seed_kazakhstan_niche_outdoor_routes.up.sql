-- Niche Kazakhstan route-level outdoor/hiking seed.
-- Adds useful non-duplicate routes after the broad Kazakhstan hiking coverage layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_niche_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_niche_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_niche_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_niche_outdoor_routes_places (
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
    ('KZ', 'KZT', 'big-shymbulak-falls-trail', 'almaty', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа к Большому Шымбулакскому водопаду', 'Big Shymbulak Falls Trail', 'Үлкен Шымбұлақ сарқырамасы соқпағы', 'Маршрут западной части Заилийского Алатау к узкому скальному каньону, холодной воде и дикому формату однодневного выхода.', 'A western Trans-Ili Alatau route toward a narrow rocky canyon, cold water and a wilder day-hike format.', 'Іле Алатауының батыс бөлігіндегі тар жартасты каньонға, суық суға және жабайырақ күндік форматқа апаратын бағыт.', 43.15300000, 76.65000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','waterfall','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'four-brothers-rocks-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа к скалам Четыре брата', 'Four Brothers Rocks Trail', 'Төрт ағайынды жартастары соқпағы', 'Горная прогулка над Алматы к выразительным скалам, хвойному воздуху и открытым видам без длинного альпийского дня.', 'A mountain walk above Almaty toward expressive rocks, spruce air and open views without a long alpine day.', 'Алматы үстіндегі айқын жартастарға, шыршалы ауаға және ұзақ альпілік күнсіз ашық көріністерге апаратын тау серуені.', 43.12200000, 76.95800000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','rocks','day-hike','hiking']::text[]),
    ('KZ', 'KZT', 'uzun-kargaly-waterfall-trail', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа к Узун-Каргалинскому водопаду', 'Uzun-Kargaly Waterfall Trail', 'Ұзын-Қарғалы сарқырамасы соқпағы', 'Предгорный маршрут западнее Алматы по сухим склонам, кустарниковому ущелью и водопадной точке для весеннего или осеннего выезда.', 'A foothill route west of Almaty across dry slopes, a shrub canyon and a waterfall point for spring or autumn outings.', 'Алматының батысындағы құрғақ беткейлер, бұталы шатқал және көктемгі не күзгі сапарға арналған сарқырама нүктесі бар тау етегі бағыты.', 43.15500000, 76.63700000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','waterfall','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'chukotka-ridge-trail', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа хребта Чукотка', 'Chukotka Ridge Trail', 'Чукотка жотасы соқпағы', 'Гребневой маршрут в горной зоне Алматы с лесными стартами, каменными участками и быстрым выходом к панорамам города и хребтов.', 'A ridge route in Almaty mountain belt with forest starts, rocky sections and quick access to city and range panoramas.', 'Алматы тау белдеуіндегі жоталық бағыт: орманды бастау, тасты бөліктер және қала мен жоталар панорамаларына жылдам шығу.', 43.12900000, 76.98800000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','ridge','trekking']::text[]),
    ('KZ', 'KZT', 'kyzyl-kent-monastery-trail', 'karaganda', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа монастыря Кызыл-Кент', 'Kyzyl Kent Monastery Trail', 'Қызыл-Кент монастыры соқпағы', 'Сарыаркинский маршрут к красным руинам среди гранитных склонов, сосновых участков и тихого исторического ландшафта.', 'A Saryarka route to red ruins among granite slopes, pine pockets and a quiet historical landscape.', 'Сарыарқадағы гранит беткейлері, қарағайлы бөліктер және тыныш тарихи ландшафт арасындағы қызыл қирандыларға апаратын бағыт.', 49.15400000, 75.84200000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','saryarka','karkaraly','heritage','hiking']::text[]),
    ('KZ', 'KZT', 'aktolagay-chalk-plateau-trail', 'aktobe', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа мелового плато Актолагай', 'Aktolagay Chalk Plateau Trail', 'Ақтолағай борлы үстірті соқпағы', 'Западноказахстанский геомаршрут по светлым меловым стенам, сухим ложбинам и редкому ландшафту Актюбинской области.', 'A western Kazakhstan geotrail across pale chalk walls, dry hollows and a rare Aktobe Region landscape.', 'Ақтөбе облысының ақшыл борлы қабырғалары, құрғақ ойпаңдары және сирек ландшафты арқылы өтетін Батыс Қазақстан геобағыты.', 47.35500000, 56.63000000, 'Sherkala_Mountain.jpg', ARRAY['aktobe','atyrau']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','chalk','free-entry','geotrail','hiking']::text[]),
    ('KZ', 'KZT', 'kendirli-bay-spit-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прогулка косы залива Кендерли', 'Kendirli Bay Spit Walk', 'Кендірлі шығанағы қайыры серуені', 'Каспийская прогулка по открытой береговой линии, ветреной косе и редкому морскому ландшафту южного Мангистау.', 'A Caspian walk along open shoreline, a windy spit and a rare marine landscape in southern Mangystau.', 'Оңтүстік Маңғыстаудағы ашық жағалау, желді қайыр және сирек теңіз ландшафты арқылы өтетін Каспий серуені.', 42.65200000, 52.72000000, 'Pedestrian walkway along the Caspian Sea waterfront promenade in Aktau, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','caspian','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'greater-barsuki-dune-walk', 'aktobe', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка дюн Больших Барсуков', 'Greater Barsuki Dune Walk', 'Үлкен Борсық құмды серуені', 'Пустынный маршрут Актюбинской области по песчаным грядам, сухому ветру и открытому североаральскому горизонту.', 'An Aktobe Region desert route across sandy ridges, dry wind and an open North Aral horizon.', 'Ақтөбе облысындағы құмды жоталар, құрғақ жел және Солтүстік Аралдың ашық көкжиегі арқылы өтетін шөл бағыты.', 47.58000000, 59.58000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe','kyzylorda']::text[], ARRAY['aktobe','kyzylorda']::text[], ARRAY['kazakhstan','aktobe-region','desert','dunes','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'imankara-cave-hill-trail', 'atyrau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа пещерного холма Иманкара', 'Imankara Cave Hill Trail', 'Иманқара үңгірлі төбесі соқпағы', 'Маршрут Прикаспийской степи к известняковому холму, сухим оврагам и пещерному рельефу для короткого геологического выезда.', 'A Caspian steppe route toward a limestone hill, dry gullies and cave landforms for a short geologic outing.', 'Каспий маңы даласындағы әктас төбеге, құрғақ жыраларға және үңгірлі бедерге апаратын қысқа геологиялық бағыт.', 47.14500000, 54.25800000, 'Sherkala_Mountain.jpg', ARRAY['atyrau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','atyrau-region','cave','free-entry','geotrail','walking']::text[]),
    ('KZ', 'KZT', 'sauskandyk-petroglyph-gorge-trail', 'turkestan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья петроглифов Саускандык', 'Sauskandyk Petroglyph Gorge Trail', 'Саусқандық петроглиф шатқалы соқпағы', 'Южноказахстанский маршрут по Каратау к каменным плитам, древним рисункам и сухим гребням с сильным культурным контекстом.', 'A southern Kazakhstan Karatau route to stone slabs, ancient drawings and dry ridges with strong cultural context.', 'Оңтүстік Қазақстандағы Қаратау бағыты: тас тақталарға, көне суреттерге және мәдени контексті күшті құрғақ жоталарға апарады.', 43.70500000, 68.36500000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','karatau','petroglyphs','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'boraldaytau-rock-art-trail', 'shymkent', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа наскального искусства Боралдайтау', 'Boraldaytau Rock Art Trail', 'Боралдайтау жартас суреттері соқпағы', 'Маршрут хребта Боралдайтау к каменным выходам, сухим склонам и археологическому ландшафту недалеко от Шымкента.', 'A Boraldaytau range route to rock outcrops, dry slopes and an archaeological landscape near Shymkent.', 'Шымкент маңындағы Боралдайтау жотасында тасты жерлерге, құрғақ беткейлерге және археологиялық ландшафтқа апаратын бағыт.', 42.72500000, 69.72200000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','south-kazakhstan','rock-art','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_niche_outdoor_routes_resolved_places AS
SELECT
    ('112d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-niche-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_niche_outdoor_routes_places;

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
FROM seed_kazakhstan_niche_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_niche_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_niche_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_niche_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_niche_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_niche_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_niche_outdoor_routes_places;
