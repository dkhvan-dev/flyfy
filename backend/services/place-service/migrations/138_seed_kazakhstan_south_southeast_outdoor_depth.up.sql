-- Kazakhstan south and southeast outdoor depth seed.
-- Adds non-duplicate places suggested by regional coverage review for southern and southeastern hubs.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_south_southeast_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_south_southeast_outdoor_depth_places;

CREATE TEMP TABLE seed_kazakhstan_south_southeast_outdoor_depth_places (
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

INSERT INTO seed_kazakhstan_south_southeast_outdoor_depth_places (
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
    ('KZ', 'KZT', 'baum-grove-walk', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.5, 'Прогулка рощи Баума', 'Baum Grove Walk', 'Баум тоғайы серуені', 'Городской природный маршрут Алматы по старой роще, тенистым аллеям и тихим зеленым участкам, отличающийся от горных троп Иле-Алатау.', 'An urban nature route in Almaty through an old grove, shaded alleys and quiet green pockets, distinct from the Ile-Alatau mountain trails.', 'Іле Алатауының тау соқпақтарынан бөлек Алматыдағы ескі тоғай, көлеңкелі аллеялар және тыныш жасыл бөліктер арқылы өтетін қалалық табиғи бағыт.', 43.30610000, 76.94780000, ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty','baum-grove','urban-nature','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'sayramsu-lake-trail', 'shymkent', 'NATURE', 650, 8, 'HOURS', 4.7, 'Тропа к озеру Сайрамсу', 'Sayramsu Lake Trail', 'Сайрамсу көлі соқпағы', 'Высокогорный маршрут Сайрам-Угамской зоны к озеру, альпийским лугам и длинным видам Западного Тянь-Шаня для подготовленного дня.', 'A highland Sayram-Ugam area route toward a lake, alpine meadows and long Western Tian Shan views for a prepared day.', 'Дайын күндік сапарға арналған Сайрам-Өгем аймағындағы биіктау бағыты: көл, альпілік шалғын және Батыс Тянь-Шаньның кең көріністері.', 42.15000000, 70.32000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','sayramsu','lake','hiking']::text[]),
    ('KZ', 'KZT', 'makpal-lake-route', 'shymkent', 'NATURE', 650, 2, 'DAYS', 4.8, 'Маршрут к озеру Макпал', 'Makpal Lake Route', 'Мақпал көлі маршруты', 'Двухдневный горный маршрут Сайрам-Угамского нацпарка к удаленному озеру, перевальным участкам и насыщенному южному треккингу.', 'A two-day Sayram-Ugam National Park mountain route toward a remote lake, pass terrain and a rich southern trekking plan.', 'Сайрам-Өгем ұлттық паркінің екі күндік тау бағыты: шалғай көл, асулы бөліктер және оңтүстіктің толық треккинг жоспары.', 42.02000000, 70.55000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','makpal','lake','trekking']::text[]),
    ('KZ', 'KZT', 'kaskasu-susingen-lake-route', 'shymkent', 'NATURE', 650, 9, 'HOURS', 4.7, 'Маршрут Каскасу - озеро Сусинген', 'Kaskasu-Susingen Lake Route', 'Қасқасу - Сусіңген көлі маршруты', 'Маршрут из района Каскасу к озеру Сусинген через горные склоны, ручьи и открытые участки Западного Тянь-Шаня.', 'A route from the Kaskasu area toward Susingen Lake across mountain slopes, streams and open Western Tian Shan sections.', 'Қасқасу ауданынан Сусіңген көліне апаратын бағыт: тау беткейлері, бұлақтар және Батыс Тянь-Шаньның ашық бөліктері.', 42.18000000, 70.49000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','kaskasu','susingen','lake','hiking']::text[]),
    ('KZ', 'KZT', 'saryaygyr-gorge-trail', 'shymkent', 'NATURE', 650, 8, 'HOURS', 4.7, 'Тропа ущелья Сарыайгыр', 'Saryaygyr Gorge Trail', 'Сарыайғыр шатқалы соқпағы', 'Южный маршрут по ущелью Сарыайгыр с горной водой, зелеными склонами и длинным форматом активного дня из Шымкента.', 'A southern route through Saryaygyr Gorge with mountain water, green slopes and a long active-day format from Shymkent.', 'Шымкенттен белсенді ұзақ күнге арналған Сарыайғыр шатқалы бағыты: тау суы, жасыл беткейлер және оңтүстік табиғат.', 42.22000000, 70.32000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','saryaygyr','gorge','hiking']::text[]),
    ('KZ', 'KZT', 'ptichiy-bazar-view-trail', 'shymkent', 'NATURE', 650, 4, 'HOURS', 4.6, 'Видовая тропа Птичий базар', 'Ptichiy Bazar View Trail', 'Құс базары көрініс бағыты', 'Короткий видовой маршрут Сайрам-Угамского района к скальным точкам и панорамам ущелья без полноценного дневного трека.', 'A short viewpoint route in the Sayram-Ugam area toward rocky points and gorge panoramas without a full-day trek.', 'Толық күндік трексіз шатқал панорамалары мен тасты нүктелерге апаратын Сайрам-Өгем аймағындағы қысқа көрініс бағыты.', 42.23000000, 70.31000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','viewpoint','rock','walking']::text[]),
    ('KZ', 'KZT', 'boztorgay-stream-walk', 'shymkent', 'NATURE', 650, 3, 'HOURS', 4.5, 'Прогулка ручья Бозторгай', 'Boztorgay Stream Walk', 'Бозторғай бұлағы серуені', 'Легкий горный сценарий рядом с маршрутами Сайрам-Угама: ручей, зеленые берега и короткая природная пауза для семейного формата.', 'An easy mountain option near the Sayram-Ugam routes, with a stream, green banks and a short nature pause for a family format.', 'Сайрам-Өгем бағыттарына жақын жеңіл тау сценарийі: бұлақ, жасыл жағалау және отбасылық форматқа арналған қысқа табиғи үзіліс.', 42.21000000, 70.35000000, ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','sayram-ugam','boztorgay','stream','walking']::text[]),
    ('KZ', 'KZT', 'shumsky-glacier-view-trail', 'taldykorgan', 'NATURE', 1000, 8, 'HOURS', 4.7, 'Тропа к виду на ледник Шумского', 'Shumsky Glacier View Trail', 'Шумский мұздығы көрініс соқпағы', 'Маршрут Жонгарского Алатау к высокогорным видам, моренным участкам и ледниковому горизонту, расширяющий выбор Талдыкоргана.', 'A Dzungarian Alatau route toward high mountain views, moraine sections and a glacier horizon, widening Taldykorgan choices.', 'Талдықорған таңдауларын кеңейтетін Жоңғар Алатауы бағыты: биіктау көріністері, мореналық бөліктер және мұздық көкжиегі.', 45.11000000, 80.18000000, ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','dzungarian-alatau','shumsky','glacier-view','hiking']::text[]),
    ('KZ', 'KZT', 'sarkand-forest-walk', 'taldykorgan', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Прогулка Сарканского леса', 'Sarkand Forest Walk', 'Сарқан орманы серуені', 'Зеленый маршрут Жетісу по лесным участкам у Саркана, мягким склонам и прохладным долинам без сложного горного набора.', 'A green Zhetysu route through forest sections near Sarkand, gentle slopes and cool valleys without difficult mountain gain.', 'Күрделі тау көтерілуінсіз Сарқан маңындағы орман бөліктері, жұмсақ беткейлер және салқын аңғарлар арқылы өтетін Жетісудың жасыл бағыты.', 45.42000000, 79.92000000, ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','sarkand','forest','walking']::text[]),
    ('KZ', 'KZT', 'sievers-apple-forest-eco-trail', 'taldykorgan', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Экотропа яблони Сиверса', 'Sievers Apple Forest Eco Trail', 'Сиверс алмасы экосоқпағы', 'Экологическая прогулка Жетісу по участкам дикой яблони Сиверса, предгорным склонам и ботаническому контексту региона.', 'A Zhetysu eco walk through wild Sievers apple sections, foothill slopes and the region botanical context.', 'Жетісудағы жабайы Сиверс алмасы учаскелері, тау етегі беткейлері және өңірдің ботаникалық контексті арқылы өтетін экосеруен.', 45.35000000, 79.80000000, ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','sievers-apple','eco-trail','walking']::text[]),
    ('KZ', 'KZT', 'teris-ashybulak-reservoir-shore-walk', 'taraz', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка Терис-Ащыбулакского водохранилища', 'Teris-Ashybulak Reservoir Shore Walk', 'Теріс-Ащыбұлақ су қоймасы жағалауы серуені', 'Короткий выезд из Тараза к водохранилищу, открытой воде и мягкому южному рельефу, отличающийся от горных ущелий Жамбылской области.', 'A short outing from Taraz to a reservoir, open water and gentle southern terrain, distinct from Zhambyl Region mountain gorges.', 'Жамбыл облысының тау шатқалдарынан бөлек Тараздан су қоймасына, ашық суға және жұмсақ оңтүстік бедерге шығатын қысқа бағыт.', 42.68530000, 70.91030000, ARRAY['taraz','shymkent']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','teris-ashybulak','reservoir','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'moiynkum-desert-edge-walk', 'taraz', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка края пустыни Мойынкум', 'Moiynkum Desert Edge Walk', 'Мойынқұм шөлі жиегі серуені', 'Маршрут из Тараза к песчаному краю Мойынкума, сухим грядам и открытому горизонту, добавляющий пустынный сценарий к горным местам региона.', 'A route from Taraz to the sandy edge of Moiynkum, dry ridges and open horizon, adding a desert scenario to the region mountain places.', 'Өңірдің тау орындарына шөл сценарийін қосатын Тараздан Мойынқұмның құмды жиегіне, құрғақ жоталарға және ашық көкжиекке апаратын бағыт.', 43.65000000, 72.60000000, ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','moiynkum','desert-edge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'aksumbe-karatau-tower-view-walk', 'turkestan', 'NATURE', 0, 2, 'HOURS', 4.5, 'Видовая прогулка у башни Аксумбе', 'Aksumbe Karatau Tower View Walk', 'Ақсүмбе мұнарасы көрініс серуені', 'Короткий маршрут Каратау к исторической башне, сухим склонам и широкой степной панораме для легкого выезда из Туркестана.', 'A short Karatau route toward a historic tower, dry slopes and a wide steppe panorama for an easy outing from Turkestan.', 'Түркістаннан жеңіл шығуға арналған Қаратау бағыты: тарихи мұнара, құрғақ беткейлер және кең дала панорамасы.', 44.44920000, 67.53830000, ARRAY['turkestan','kyzylorda']::text[], ARRAY['turkestan']::text[], ARRAY['kazakhstan','karatau','aksumbe','tower','viewpoint','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'aralkum-desert-view-walk', 'kyzylorda', 'NATURE', 0, 4, 'HOURS', 4.5, 'Видовая прогулка пустыни Аралкум', 'Aralkum Desert View Walk', 'Аралқұм шөлі көрініс серуені', 'Приаральский маршрут к новым песчаным ландшафтам бывшего морского дна, сухим ветрам и широкому горизонту Аралкума.', 'An Aral-side route toward new sandy landscapes of the former seabed, dry winds and the wide Aralkum horizon.', 'Бұрынғы теңіз түбінің жаңа құмды ландшафттарына, құрғақ желге және Аралқұмның кең көкжиегіне апаратын Арал маңы бағыты.', 45.00000000, 60.50000000, ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','kyzylorda-region','aralkum','desert','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_south_southeast_outdoor_depth_resolved_places AS
SELECT
    ('138d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-south-southeast-outdoor-depth-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_south_southeast_outdoor_depth_places;

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
FROM seed_kazakhstan_south_southeast_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_south_southeast_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_south_southeast_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_south_southeast_outdoor_depth_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_south_southeast_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_south_southeast_outdoor_depth_places;
