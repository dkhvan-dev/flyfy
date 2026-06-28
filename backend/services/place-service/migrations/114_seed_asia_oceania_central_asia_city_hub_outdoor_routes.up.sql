-- Asia, Oceania and Central Asia city-hub outdoor route seed.
-- Adds route-level walks and hikes for remaining reference hubs after the broad hiking enrichment layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_asia_oceania_central_asia_city_hub_outdoor_routes_places;

CREATE TEMP TABLE seed_asia_oceania_central_asia_city_hub_outdoor_routes_places (
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

INSERT INTO seed_asia_oceania_central_asia_city_hub_outdoor_routes_places (
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
    ('KG', 'KGS', 'balykchy-lakeside-promenade-walk', 'balykchy', 'NATURE', 0, 2, 'HOURS', 4.4, 'Прогулка набережной Балыкчы у озера', 'Balykchy Lakeside Promenade Walk', 'Балықшы көл жағалауы серуені', 'Легкая прогулка у западного Иссык-Куля с ветром, открытой водой и спокойным стартом для маршрутов вокруг озера.', 'An easy walk by western Issyk-Kul with wind, open water and a calm starting point for routes around the lake.', 'Батыс Ыстықкөл жағасындағы желі, ашық суы және көл маңындағы бағыттарға тыныш бастауы бар жеңіл серуен.', 42.45500000, 76.18000000, 'Lake Issyk-Kul, Kyrgyzstan.jpg', ARRAY['balykchy']::text[], ARRAY['bishkek','balykchy']::text[], ARRAY['kyrgyzstan','issyk-kul','lakeside','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'varzob-riverside-mountain-trail', 'varzob', 'NATURE', 0, 4, 'HOURS', 4.6, 'Горная тропа вдоль реки Варзоб', 'Varzob Riverside Mountain Trail', 'Варзоб өзені тау соқпағы', 'Маршрут недалеко от Душанбе вдоль горной реки, каменных склонов и прохладных участков для короткого природного дня.', 'A route near Dushanbe along a mountain river, rocky slopes and cool sections for a short nature day.', 'Душанбе маңындағы тау өзені, тасты беткейлер және қысқа табиғи күнге арналған салқын бөліктер бойымен өтетін бағыт.', 38.79100000, 68.78400000, 'Varzob_Gorge_Tajikistan.jpg', ARRAY['varzob']::text[], ARRAY['dushanbe','varzob']::text[], ARRAY['tajikistan','varzob','river','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'wakhan-valley-panj-river-walk', 'wakhan-valley', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прогулка вдоль Пянджа в Ваханской долине', 'Wakhan Valley Panj River Walk', 'Вахан аңғары Пяндж өзені серуені', 'Памирская прогулка по речным террасам, открытым видам на Афганский берег и спокойному ритму Вахана.', 'A Pamir walk along river terraces, open views toward the Afghan side and the calm rhythm of Wakhan.', 'Памирдегі өзен террасалары, Ауғанстан жағына ашық көріністер және Ваханның тыныш ырғағы арқылы өтетін серуен.', 37.04800000, 72.69000000, 'Wakhan_Valley_Tajikistan.jpg', ARRAY['wakhan-valley','langar']::text[], ARRAY['ishkashim','wakhan-valley']::text[], ARRAY['tajikistan','pamir','wakhan','free-entry','walking']::text[]),
    ('MN', 'MNT', 'khuvsgul-west-shore-forest-trail', 'khuvsgul', 'NATURE', 5000, 4, 'HOURS', 4.8, 'Лесная тропа западного берега Хубсугула', 'Khuvsgul West Shore Forest Trail', 'Хөвсгөл батыс жағалауы орман соқпағы', 'Северомонгольский маршрут вдоль лесного берега, прозрачной воды и мягких склонов с видом на большое озеро.', 'A northern Mongolia route along a forested shore, clear water and gentle slopes overlooking the great lake.', 'Солтүстік Моңғолиядағы орманды жағалау, мөлдір су және үлкен көлге қарайтын жұмсақ беткейлер арқылы өтетін бағыт.', 50.74800000, 100.16600000, 'Lake_Khuvsgul_Mongolia.jpg', ARRAY['khuvsgul','khatgal']::text[], ARRAY['khatgal','murun','khuvsgul']::text[], ARRAY['mongolia','khuvsgul','lake-shore','forest','hiking']::text[]),
    ('MN', 'MNT', 'malchin-peak-base-trail', 'altai-tavan-bogd', 'NATURE', 5000, 6, 'HOURS', 4.8, 'Тропа к подножию пика Малчин', 'Malchin Peak Base Trail', 'Малчин шыңы етегі соқпағы', 'Алтайский маршрут к базовому району заснеженного массива, ледниковым видам и высокогорной степи западной Монголии.', 'An Altai route toward the base area of a snowy massif, glacier views and western Mongolia high steppe.', 'Батыс Моңғолиядағы қарлы массив етегіне, мұздық көріністеріне және биік таулы далаға апаратын Алтай бағыты.', 49.15400000, 87.81600000, 'Altai_Tavan_Bogd_National_Park.jpg', ARRAY['altai-tavan-bogd','ulgii']::text[], ARRAY['ulgii','altai-tavan-bogd']::text[], ARRAY['mongolia','altai','summit-base','trekking']::text[]),
    ('AU', 'AUD', 'burleigh-head-oceanview-circuit', 'gold-coast', 'NATURE', 0, 2, 'HOURS', 4.7, 'Океанский круг Бёрли-Хед', 'Burleigh Head Oceanview Circuit', 'Берли-Хед мұхит көрінісі ілмегі', 'Короткий маршрут Голд-Коста через прибрежный лес, скальные точки и виды на серфовую линию океана.', 'A short Gold Coast route through coastal forest, rocky points and ocean surf-line views.', 'Голд-Косттағы жағалау орманы, тасты нүктелер және мұхит толқынына көріністер арқылы өтетін қысқа бағыт.', -28.09100000, 153.45700000, 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg', ARRAY['gold-coast']::text[], ARRAY['gold-coast','brisbane']::text[], ARRAY['australia','gold-coast','coastal-forest','free-entry','walking']::text[]),
    ('NZ', 'NZD', 'te-ara-hura-coastal-walk', 'waiheke-island', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прибрежная прогулка Те-Ара-Хура', 'Te Ara Hura Coastal Walk', 'Те-Ара-Хура жағалау серуені', 'Островной маршрут у Окленда по бухтам, виноградным склонам и открытым морским видам Waiheke.', 'An Auckland island route through bays, vineyard slopes and open Waiheke sea views.', 'Окленд маңындағы арал бағыты: қойнаулар, жүзімдік беткейлері және Вайхеке теңізіне ашық көріністер.', -36.79000000, 175.08500000, 'Waiheke_Island_New_Zealand.jpg', ARRAY['waiheke-island']::text[], ARRAY['auckland','waiheke-island']::text[], ARRAY['new-zealand','waiheke','coastal-walk','free-entry','walking']::text[]),
    ('NZ', 'NZD', 'kitekite-falls-track', 'waitakere-ranges', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа к водопаду Китеките', 'Kitekite Falls Track', 'Китеките сарқырамасы соқпағы', 'Маршрут западнее Окленда через влажный лес, ручьи и водопадные каскады недалеко от черного песчаного побережья.', 'A route west of Auckland through wet forest, streams and waterfall cascades near the black-sand coast.', 'Оклендтің батысындағы ылғалды орман, бұлақтар және қара құмды жағалауға жақын сарқырама каскадтары арқылы өтетін бағыт.', -36.95800000, 174.47000000, 'Waitakere_Ranges_New_Zealand.jpg', ARRAY['waitakere-ranges']::text[], ARRAY['auckland','waitakere-ranges']::text[], ARRAY['new-zealand','auckland-region','waterfall','free-entry','hiking']::text[]),
    ('CN', 'CNY', 'xihai-grand-canyon-trail', 'huangshan', 'NATURE', 190, 5, 'HOURS', 4.9, 'Тропа Большого каньона Сихай', 'Xihai Grand Canyon Trail', 'Сихай Үлкен каньоны соқпағы', 'Горный маршрут Хуаншаня по каменным лестницам, облачным видам и глубоким гранитным стенам западного моря.', 'A Huangshan mountain route across stone stairs, cloud views and deep granite walls of the western sea area.', 'Хуаншаньдағы тас баспалдақтар, бұлт көріністері және батыс теңіз аймағының терең гранит қабырғалары арқылы өтетін тау бағыты.', 30.14500000, 118.16100000, 'Huangshan_pic_4.jpg', ARRAY['huangshan']::text[], ARRAY['huangshan','hangzhou','shanghai']::text[], ARRAY['china','huangshan','canyon','trekking']::text[]),
    ('CN', 'CNY', 'haba-snow-mountain-high-trail', 'lijiang', 'NATURE', 45, 7, 'HOURS', 4.9, 'Верхняя тропа Снежной горы Хаба', 'Haba Snow Mountain High Trail', 'Хаба қарлы тауының жоғарғы соқпағы', 'Юньнаньский маршрут над бурной рекой Янцзы с деревнями, террасами и мощными стенами Снежной горы Хаба.', 'A Yunnan route above the rushing Yangtze with villages, terraces and powerful walls of Haba Snow Mountain.', 'Юньнаньдағы Янцзы өзені үстіндегі ауылдар, террасалар және Хаба қарлы тауының қуатты қабырғалары арқылы өтетін бағыт.', 27.18700000, 100.10700000, 'Old_Town_of_Lijiang.jpg', ARRAY['lijiang']::text[], ARRAY['lijiang','shangri-la']::text[], ARRAY['china','yunnan','gorge','trekking']::text[]),
    ('JP', 'JPY', 'hakone-old-tokaido-cedar-avenue-walk', 'hakone', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прогулка по старой дороге Токайдо в Хаконе', 'Hakone Old Tokaido Cedar Avenue Walk', 'Хаконе ескі Токайдо самырсын жолы серуені', 'Историко-природная прогулка Хаконе по каменным дорожкам, кедровым аллеям и участкам старого тракта у горного озера.', 'A Hakone heritage-nature walk over stone paths, cedar avenues and old road sections near the mountain lake.', 'Хаконедегі тас жолдар, самырсын аллеялары және тау көлі маңындағы ескі жол бөліктері арқылы өтетін тарихи-табиғи серуен.', 35.20000000, 139.01800000, 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG', ARRAY['hakone']::text[], ARRAY['tokyo','hakone']::text[], ARRAY['japan','hakone','historic-road','free-entry','walking']::text[]),
    ('KR', 'KRW', 'hallasan-seongpanak-trail', 'jeju', 'NATURE', 0, 8, 'HOURS', 4.9, 'Тропа Сонпанак на Халласан', 'Hallasan Seongpanak Trail', 'Халласан Сонпанак соқпағы', 'Длинный маршрут Чеджу через лесные пояса, вулканические склоны и подъем к главной вершине острова.', 'A long Jeju route through forest belts, volcanic slopes and the ascent toward the island main summit.', 'Чеджудегі орман белдеулері, жанартаулық беткейлер және аралдың басты шыңына көтерілу арқылы өтетін ұзын бағыт.', 33.38500000, 126.61900000, 'Hallasan_Above.jpg', ARRAY['jeju']::text[], ARRAY['jeju']::text[], ARRAY['south-korea','jeju','volcano','free-entry','trekking']::text[]),
    ('TH', 'THB', 'pai-red-ridge-loop', 'pai', 'NATURE', 0, 2, 'HOURS', 4.6, 'Красная гребневая петля Пая', 'Pai Red Ridge Loop', 'Пай қызыл жота ілмегі', 'Короткий северотаиландский маршрут по узким красным гребням, сухим склонам и закатным точкам вокруг Пая.', 'A short northern Thailand route over narrow red ridges, dry slopes and sunset points around Pai.', 'Пай маңындағы тар қызыл жоталар, құрғақ беткейлер және күн батар нүктелері арқылы өтетін Солтүстік Таиландтың қысқа бағыты.', 19.30600000, 98.45200000, 'Pai_canyon_1.jpg', ARRAY['pai']::text[], ARRAY['chiang-mai','pai']::text[], ARRAY['thailand','pai','canyon','free-entry','walking']::text[]),
    ('MY', 'MYR', 'lambir-hills-latak-waterfall-trail', 'miri', 'NATURE', 20, 3, 'HOURS', 4.7, 'Тропа к водопаду Латак в холмах Ламбир', 'Lambir Hills Latak Waterfall Trail', 'Ламбир төбелері Латак сарқырамасы соқпағы', 'Саравакский маршрут из Мири через влажный тропический лес, корни, ручьи и водопадную чашу.', 'A Sarawak route from Miri through humid rainforest, roots, streams and a waterfall pool.', 'Мириден шығатын Саравак бағыты: ылғалды тропикалық орман, тамырлар, бұлақтар және сарқырама тоғаны.', 4.19700000, 114.03900000, 'Lambir_Hills_National_Park.jpg', ARRAY['miri']::text[], ARRAY['miri']::text[], ARRAY['malaysia','sarawak','rainforest','waterfall','hiking']::text[]),
    ('LK', 'LKR', 'pidurangala-sunrise-rock-trail', 'sigiriya', 'NATURE', 1000, 2, 'HOURS', 4.8, 'Рассветная тропа на скалу Пидурангала', 'Pidurangala Sunrise Rock Trail', 'Пидурангала күншығыс жартасы соқпағы', 'Короткий подъем у Сигирии к скальному виду на равнину, джунгли и силуэт знаменитой крепости на рассвете.', 'A short Sigiriya-area climb to a rock viewpoint over plains, jungle and the famous fortress silhouette at sunrise.', 'Сигирия маңындағы жазыққа, джунглиге және таңғы әйгілі қамал силуэтіне қарайтын жартас көрінісіне қысқа көтерілу.', 7.96600000, 80.76000000, 'Pidurangala_Rock.jpg', ARRAY['sigiriya']::text[], ARRAY['sigiriya','dambulla','kandy']::text[], ARRAY['sri-lanka','sigiriya','rock-viewpoint','sunrise','hiking']::text[]);

CREATE TEMP TABLE seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places AS
SELECT
    ('114d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['asia-oceania-central-asia-city-hub-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_places;

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
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places
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
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places
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
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places
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
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places
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
FROM seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_asia_oceania_central_asia_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_asia_oceania_central_asia_city_hub_outdoor_routes_places;
