-- Global near-completion outdoor route seed.
-- Closes high-signal city hub gaps in countries that were already close to complete route coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_global_near_completion_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_near_completion_outdoor_routes_places;

CREATE TEMP TABLE seed_global_near_completion_outdoor_routes_places (
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

INSERT INTO seed_global_near_completion_outdoor_routes_places (
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
    ('IN', 'INR', 'sanjay-van-ridge-forest-trail', 'delhi', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная тропа хребта Sanjay Van', 'Sanjay Van Ridge Forest Trail', 'Sanjay Van жоталы орман соқпағы', 'Зеленый маршрут Дели по Аравалли с лесными участками, каменными грядами и тихим форматом городской природы.', 'A green Delhi route across the Aravalli ridge with forest sections, rocky ground and a quiet city-nature format.', 'Делидегі Аравалли жотасы арқылы өтетін жасыл бағыт: орман бөліктері, тасты жерлер және тыныш қалалық табиғат форматы.', 28.52600000, 77.15800000, 'Delhi_Red_fort.jpg', ARRAY['delhi']::text[], ARRAY['delhi']::text[], ARRAY['india','delhi','aravalli-ridge','urban-forest','free-entry','walking']::text[]),
    ('KG', 'KGS', 'sulaiman-too-southern-slope-walk', 'osh', 'NATURE', 0, 2, 'HOURS', 4.7, 'Южная прогулка склонов Сулайман-Тоо', 'Sulaiman-Too Southern Slope Walk', 'Сулайман-Тоо оңтүстік беткейі серуені', 'Короткий городской подъем в Оше по каменным склонам, обзорным площадкам и сухому южному ландшафту.', 'A short urban climb in Osh across rocky slopes, viewpoints and a dry southern landscape.', 'Оштағы тасты беткейлер, қарау алаңдары және құрғақ оңтүстік ландшафт арқылы өтетін қысқа қалалық көтерілу.', 40.52860000, 72.78330000, 'Сулайман-Тоо музей.jpg', ARRAY['osh']::text[], ARRAY['osh']::text[], ARRAY['kyrgyzstan','osh','urban-hill','free-entry','walking']::text[]),
    ('CY', 'EUR', 'athalassa-forest-park-loop', 'nicosia', 'NATURE', 0, 2, 'HOURS', 4.5, 'Лесная петля парка Athalassa', 'Athalassa Forest Park Loop', 'Athalassa орман саябағы ілмегі', 'Городская природная петля Никосии вокруг сосен, сухих лугов и озерных участков на краю столицы.', 'A Nicosia city-nature loop around pines, dry meadows and lake sections on the edge of the capital.', 'Никосиядағы қарағай, құрғақ шалғын және көл бөліктері арқылы өтетін астана шетіндегі қалалық табиғи ілмек.', 35.13200000, 33.40200000, 'Nicosia_01-2017_img28_Cyprus_Museum.jpg', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], ARRAY['cyprus','nicosia','forest-park','free-entry','walking']::text[]),
    ('CY', 'EUR', 'akamas-aphrodite-trail', 'paphos', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа Афродиты на Акамасе', 'Akamas Aphrodite Trail', 'Акамас Афродита соқпағы', 'Прибрежно-горный маршрут из района Пафоса к видам Акамаса, морским обрывам и средиземноморской растительности.', 'A coastal-and-hill route from the Paphos area toward Akamas views, sea cliffs and Mediterranean vegetation.', 'Пафос аймағынан Акамас көріністеріне, теңіз жартастарына және Жерорта теңізі өсімдіктеріне апаратын жағалау-таулы бағыт.', 35.05600000, 32.34700000, 'Pegeia,_Cyprus,_Avakas_Gorge,_limestone.jpg', ARRAY['paphos','polis','peyia']::text[], ARRAY['paphos']::text[], ARRAY['cyprus','paphos','akamas','coastal','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'uushgiin-uver-deer-stones-walk', 'murun', 'NATURE', 0, 2, 'HOURS', 4.6, 'Степная прогулка оленьих камней Уушгийн-Увэр', 'Uushgiin Uver Deer Stones Walk', 'Уушгийн-Үвэр бұғы тастары серуені', 'Короткий маршрут у Муруна по северомонгольской степи к древним каменным памятникам и открытому горизонту Хубсугула.', 'A short route near Murun across northern Mongolian steppe toward ancient stone monuments and the open Khuvsgul horizon.', 'Мөрөн маңындағы солтүстік Моңғолия даласы арқылы ежелгі тас ескерткіштерге және Хөвсгөлдің ашық көкжиегіне апаратын қысқа бағыт.', 49.71700000, 100.14400000, 'Murun Mongolia.jpg', ARRAY['murun']::text[], ARRAY['murun']::text[], ARRAY['mongolia','murun','deer-stones','steppe','free-entry','walking']::text[]),
    ('MN', 'MNT', 'taikhar-rock-steppe-loop', 'tsetserleg', 'NATURE', 0, 2, 'HOURS', 4.6, 'Степная петля скалы Тайхар', 'Taikhar Rock Steppe Loop', 'Тайхар жартасы дала ілмегі', 'Легкая прогулка из Цэцэрлэга к гранитной скале, берегу Тамир и открытому степному пейзажу Архангайского аймака.', 'An easy Tsetserleg-area walk toward the granite rock, Tamir riverbank and open Arkhangai steppe scenery.', 'Цэцэрлэг маңындағы гранит жартасқа, Тамир өзені жағасына және Архангайдың ашық даласына апаратын жеңіл серуен.', 47.56000000, 101.17000000, 'Taikhar Rock Mongolia.jpg', ARRAY['tsetserleg']::text[], ARRAY['tsetserleg']::text[], ARRAY['mongolia','arkhangai','taikhar','riverbank','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'ishkashim-panj-river-terrace-walk', 'ishkashim', 'NATURE', 0, 3, 'HOURS', 4.6, 'Террасная прогулка Пянджа у Ишкашима', 'Ishkashim Panj River Terrace Walk', 'Ишкошим Пяндж террасасы серуені', 'Памирский маршрут у Ишкашима по речным террасам, полям и видам на горы за Пянджем.', 'A Pamir route near Ishkashim across river terraces, fields and mountain views beyond the Panj.', 'Ишкошим маңындағы Памир бағыты: өзен террасалары, егістіктер және Пяндж арғы жағындағы тау көріністері арқылы өтеді.', 36.72400000, 71.61100000, 'Ishkashim Tajikistan.jpg', ARRAY['ishkashim','wakhan-valley']::text[], ARRAY['ishkashim','khorog']::text[], ARRAY['tajikistan','ishkashim','pamir','panj-river','gbao-permit','walking']::text[]),
    ('TJ', 'TJS', 'dashti-jum-reserve-ridge-trail', 'kulob', 'NATURE', 0, 5, 'HOURS', 4.7, 'Гребневая тропа заповедника Дашти-Джум', 'Dashti-Jum Reserve Ridge Trail', 'Дашти-Жум қорығы жота соқпағы', 'Южный маршрут из Куляба к предгорьям Хазрати-Шоха с сухими гребнями, речными долинами и редкой природой Хатлона.', 'A southern route from Kulob toward Hazrati Shoh foothills with dry ridges, river valleys and rare Khatlon nature.', 'Күлобтан Хазрати-Шох тау етегіне апаратын оңтүстік бағыт: құрғақ жоталар, өзен аңғарлары және Хатлонның сирек табиғаты.', 38.03000000, 70.05000000, 'Childukhtaron Tajikistan.jpg', ARRAY['kulob','muminobod']::text[], ARRAY['kulob']::text[], ARRAY['tajikistan','khatlon','dashti-jum','reserve','free-entry','hiking']::text[]),
    ('AE', 'AED', 'al-zorah-mangrove-lagoon-walk', 'ajman', 'NATURE', 0, 2, 'HOURS', 4.6, 'Мангровая прогулка лагуны Аль-Зора', 'Al Zorah Mangrove Lagoon Walk', 'Әл-Зора мангр лагунасы серуені', 'Спокойный маршрут Аджмана у лагуны, мангровых зарослей и мест наблюдения за птицами без дальнего выезда из эмирата.', 'A calm Ajman route by the lagoon, mangrove stands and birdwatching points without a long transfer from the emirate.', 'Аджмандағы лагуна, мангр тоғайлары және құс бақылау нүктелері жанындағы тыныш бағыт, әмірліктен алыс шықпай-ақ.', 25.42610000, 55.47490000, 'Al_Zorah_Nature_Reserve.jpg', ARRAY['ajman','sharjah']::text[], ARRAY['ajman']::text[], ARRAY['uae','ajman','mangrove','lagoon','free-entry','walking']::text[]),
    ('AE', 'AED', 'mleiha-fossil-rock-trail', 'sharjah', 'NATURE', 25, 4, 'HOURS', 4.7, 'Тропа Fossil Rock в Млейхе', 'Mleiha Fossil Rock Trail', 'Млейха Fossil Rock соқпағы', 'Пустынный маршрут Шарджи к известным скальным формам, археологическому ландшафту и открытому виду центрального региона.', 'A Sharjah desert route toward known rock forms, an archaeological landscape and open views of the central region.', 'Шарджадағы белгілі тас пішіндерге, археологиялық ландшафтқа және орталық өңірдің ашық көріністеріне апаратын шөл бағыты.', 25.13700000, 55.84600000, 'Hatta_Dam_-_UAE.jpg', ARRAY['sharjah','mleiha']::text[], ARRAY['sharjah']::text[], ARRAY['uae','sharjah','mleiha','desert','fossil-rock','hiking']::text[]),
    ('AE', 'AED', 'umm-al-quwain-mangrove-lagoon-walk', 'umm-al-quwain', 'NATURE', 0, 2, 'HOURS', 4.5, 'Лагунная прогулка мангров Умм-эль-Кувейна', 'Umm Al Quwain Mangrove Lagoon Walk', 'Умм-эль-Кувейн мангр лагунасы серуені', 'Легкая прогулка у мангров и тихой воды Умм-эль-Кувейна с птицами, песчаными берегами и мягким вечерним форматом.', 'An easy walk by Umm Al Quwain mangroves and calm water with birds, sandy edges and a gentle evening format.', 'Умм-эль-Кувейн мангрлары мен тынық суы жанындағы жеңіл серуен: құстар, құмды жағалар және жұмсақ кешкі формат.', 25.54440000, 55.57710000, 'Umm_Al_Quwain_mangroves_(7267363924).jpg', ARRAY['umm-al-quwain','ajman']::text[], ARRAY['umm-al-quwain']::text[], ARRAY['uae','umm-al-quwain','mangrove','lagoon','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'ankhor-canal-green-walk', 'tashkent', 'NATURE', 0, 2, 'HOURS', 4.5, 'Зеленая прогулка канала Анхор', 'Ankhor Canal Green Walk', 'Анхор каналы жасыл серуені', 'Городской маршрут Ташкента вдоль воды, парков и спокойных зеленых участков для короткой прогулки между музеями и рынками.', 'A Tashkent city route along water, parks and quiet green sections for a short walk between museums and markets.', 'Ташкенттегі су, саябақтар және тыныш жасыл бөліктер бойымен өтетін, музейлер мен базарлар арасындағы қысқа серуен бағыты.', 41.31500000, 69.25500000, 'Tashkent Botanical Garden.jpg', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], ARRAY['uzbekistan','tashkent','canal','urban-green','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'aral-sea-ustyurt-cliff-walk', 'aral-sea', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка утесов Устюрта у Арала', 'Aral Sea Ustyurt Cliff Walk', 'Арал маңы Үстірт жартастары серуені', 'Суровый маршрут Приаралья к обрывам Устюрта, сухому морскому горизонту и экологическому контексту исчезающей воды.', 'A stark Aral-side route toward Ustyurt cliffs, a dry sea horizon and the ecological context of disappearing water.', 'Арал маңындағы Үстірт жартастарына, құрғақ теңіз көкжиегіне және тартылып бара жатқан судың экологиялық контекстіне апаратын қатал бағыт.', 44.52000000, 58.92000000, 'Aral Sea Uzbekistan.jpg', ARRAY['aral-sea','muynak']::text[], ARRAY['nukus','muynak','aral-sea']::text[], ARRAY['uzbekistan','aral-sea','ustyurt','cliff','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'kyzyl-kala-fortress-steppe-walk', 'urgench', 'NATURE', 0, 3, 'HOURS', 4.6, 'Степная прогулка крепости Кызыл-Кала', 'Kyzyl-Kala Fortress Steppe Walk', 'Қызылқала бекінісі дала серуені', 'Хорезмский маршрут из Ургенча к древней крепости, сухим равнинам и открытому пустынному горизонту рядом с оазисом.', 'A Khorezm route from Urgench toward an ancient fortress, dry plains and an open desert horizon near the oasis.', 'Үргеніштен көне бекініске, құрғақ жазықтарға және оазис маңындағы ашық шөл көкжиегіне апаратын Хорезм бағыты.', 41.92000000, 60.82000000, 'Ayaz Kala Uzbekistan.jpg', ARRAY['urgench','khiva']::text[], ARRAY['urgench','khiva']::text[], ARRAY['uzbekistan','khorezm','fortress-landscape','desert','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_global_near_completion_outdoor_routes_resolved_places AS
SELECT
    ('130d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['global-near-completion-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_global_near_completion_outdoor_routes_places;

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
FROM seed_global_near_completion_outdoor_routes_resolved_places
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
FROM seed_global_near_completion_outdoor_routes_resolved_places
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
FROM seed_global_near_completion_outdoor_routes_resolved_places
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
FROM seed_global_near_completion_outdoor_routes_resolved_places
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
FROM seed_global_near_completion_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_global_near_completion_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_near_completion_outdoor_routes_places;
