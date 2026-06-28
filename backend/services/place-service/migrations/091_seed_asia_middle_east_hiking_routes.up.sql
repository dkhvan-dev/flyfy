-- Route-level hiking/day-hike enrichment for Asia, the Middle East and Southeast Asia hubs.
-- These rows avoid duplicating broad place seeds and add concrete trail scenarios instead.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_asia_middle_east_hiking_resolved_places;
DROP TABLE IF EXISTS seed_asia_middle_east_hiking_places;

CREATE TEMP TABLE seed_asia_middle_east_hiking_places (
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

INSERT INTO seed_asia_middle_east_hiking_places (
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
    ('AE', 'AED', 'al-rabi-hiking-trail', 'khor-fakkan', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Аль-Раби', 'Al Rabi Hiking Trail', 'Әл-Раби жаяу соқпағы', 'Короткий горный маршрут над Хор-Факканом с видом на залив, город и склоны Хаджарских гор, удобный для утреннего подъема.', 'A short mountain route above Khor Fakkan with views over the bay, city and Hajar slopes, ideal for a morning climb.', 'Хор-Факкан үстіндегі қысқа тау бағыты: шығанаққа, қалаға және Хаджар беткейлеріне көрініс береді, таңғы көтерілуге ыңғайлы.', 25.34600000, 56.34300000, 'Khor_Fakkan_Beach.jpg', ARRAY['khor-fakkan','fujairah','sharjah']::text[], ARRAY['khor-fakkan','fujairah','sharjah']::text[], ARRAY['united-arab-emirates','hajar-mountains','viewpoint','free-entry','day-hike']::text[]),
    ('AE', 'AED', 'wadi-wurayah-trail', 'fujairah', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа Вади Вурайя', 'Wadi Wurayah Trail', 'Уади Вурайя соқпағы', 'Горный маршрут Фуджейры по охраняемой долине с каменными руслами, водными чашами и редким для ОАЭ зеленым ландшафтом.', 'A Fujairah mountain route through a protected wadi with rocky channels, pools and a rare green landscape for the UAE.', 'Фуджейрадағы қорғалатын уади арқылы өтетін тау бағыты: тасты арналары, су шұңқырлары және БАӘ үшін сирек жасыл ландшафты бар.', 25.39000000, 56.28000000, 'Fujairah_Mountains.jpg', ARRAY['fujairah','khor-fakkan']::text[], ARRAY['fujairah','khor-fakkan']::text[], ARRAY['united-arab-emirates','fujairah','wadi','protected-area','hiking']::text[]),
    ('EG', 'EGP', 'gabal-el-medawara-trail', 'fayoum', 'NATURE', 50, 3, 'HOURS', 4.7, 'Тропа горы Эль-Медавара', 'Gabal El Medawara Trail', 'Габал әл-Медавара соқпағы', 'Пустынный маршрут Фаюма к смотровой над озерами Вади-эль-Райян, песчаными склонами и мягким форматом короткого хайка.', 'A Fayoum desert route to a viewpoint above Wadi El Rayan lakes, sandy slopes and an approachable short-hike format.', 'Фаюмдағы шөл бағыты: Вади-эль-Райян көлдеріне, құмды беткейлерге көрініс беретін қысқа хайк форматы.', 29.21000000, 30.36000000, 'Wadi_El_Rayan_Egypt.jpg', ARRAY['fayoum','cairo']::text[], ARRAY['fayoum','cairo']::text[], ARRAY['egypt','fayoum','desert','viewpoint','day-hike']::text[]),
    ('EG', 'EGP', 'gebel-dakrur-trail', 'siwa', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа горы Дакрур', 'Gebel Dakrur Trail', 'Гебель Дакрур соқпағы', 'Короткий маршрут в Сиве к холму с панорамой оазиса, соленых озер и пальмовых рощ без сложной логистики.', 'A short Siwa route to a hill with views over the oasis, salt lakes and palm groves without difficult logistics.', 'Сивадағы қысқа бағыт: оазиске, тұзды көлдерге және пальма тоғайларына көрініс беретін төбеге апарады.', 29.18500000, 25.55500000, 'Siwa_Oasis_Egypt.jpg', ARRAY['siwa']::text[], ARRAY['siwa']::text[], ARRAY['egypt','siwa','oasis','salt-lakes','free-entry','walking']::text[]),
    ('IN', 'INR', 'sinhagad-fort-trek', 'pune', 'NATURE', 50, 4, 'HOURS', 4.8, 'Трек к форту Синхагад', 'Sinhagad Fort Trek', 'Синхагад фортына трек', 'Классический подъем из Пуны к горному форту с обзорными точками, западными Гатами и понятным активным сценарием на полдня.', 'A classic climb from Pune to a hill fort with viewpoints, Western Ghats scenery and a clear half-day active plan.', 'Пунадан тау фортына баратын классикалық көтерілу: көрініс нүктелері, Батыс Гаттар және жарты күндік белсенді сценарий.', 18.36600000, 73.75500000, 'Gateway_of_India,_Mumbai.jpg', ARRAY['pune','mumbai']::text[], ARRAY['pune','mumbai']::text[], ARRAY['india','pune','fort','western-ghats','trekking']::text[]),
    ('IN', 'INR', 'nandi-hills-sunrise-trail', 'bengaluru', 'NATURE', 50, 4, 'HOURS', 4.7, 'Рассветная тропа Нанди-Хиллс', 'Nandi Hills Sunrise Trail', 'Нанди-Хиллс таңғы соқпағы', 'Популярный выезд из Бангалора к холмам, рассветным видам и легкому маршруту по гребню для городского outdoor-дня.', 'A popular Bengaluru escape to hills, sunrise views and an easy ridge walk for an urban outdoor day.', 'Бенгалурудан холмдарға, таңғы көріністерге және қалалық outdoor күніне ыңғайлы жеңіл жота серуеніне шығатын бағыт.', 13.37000000, 77.68300000, 'Lalbagh Botanical Garden in Bangalore 2024 10.jpg', ARRAY['bengaluru']::text[], ARRAY['bengaluru','mysuru']::text[], ARRAY['india','bengaluru','sunrise','hills','day-hike']::text[]),
    ('IN', 'INR', 'meesapulimala-day-trek', 'munnar', 'NATURE', 100, 8, 'HOURS', 4.9, 'Дневной трек Мисапулимала', 'Meesapulimala Day Trek', 'Мисапулимала күндік трегі', 'Высокогорный маршрут Муннара среди чайных склонов, травянистых гребней и прохладного воздуха Западных Гат.', 'A highland Munnar route through tea slopes, grassy ridges and cool Western Ghats air.', 'Муннардың биік таулы бағыты: шай беткейлері, шөпті жоталар және Батыс Гаттардың салқын ауасы.', 10.14000000, 77.25000000, 'Fort_Kochi_Chinese_fishing_nets.jpg', ARRAY['munnar','kochi']::text[], ARRAY['munnar','kochi']::text[], ARRAY['india','kerala','western-ghats','tea-country','trekking']::text[]),
    ('CN', 'CNY', 'baiyun-mountain-trail', 'guangzhou', 'NATURE', 5, 4, 'HOURS', 4.7, 'Тропа горы Байюнь', 'Baiyun Mountain Trail', 'Байюнь тауы соқпағы', 'Городской горный маршрут Гуанчжоу с лесными дорожками, обзорными площадками и быстрым переходом от мегаполиса к природе.', 'An urban mountain route in Guangzhou with forest paths, viewpoints and a quick shift from metropolis to nature.', 'Гуанчжоудағы қалалық тау бағыты: орман жолдары, көрініс алаңдары және мегаполистен табиғатқа тез ауысу.', 23.18800000, 113.29800000, 'Canton_Tower,_Guangzhou.jpg', ARRAY['guangzhou']::text[], ARRAY['guangzhou']::text[], ARRAY['china','guangzhou','urban-hike','viewpoint','hiking']::text[]),
    ('CN', 'CNY', 'wutong-mountain-trail', 'shenzhen', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа горы Утун', 'Wutong Mountain Trail', 'Утун тауы соқпағы', 'Главный природный подъем Шэньчжэня к лесным склонам, морским видам и полноценному hiking-сценарию рядом с городом.', 'Shenzhen core nature climb with forested slopes, sea views and a complete hiking scenario close to the city.', 'Шэньчжэньнің негізгі табиғи көтерілуі: орманды беткейлер, теңіз көріністері және қалаға жақын толық hiking-сценарий.', 22.58000000, 114.21000000, 'Window_of_the_World,_Shenzhen.jpg', ARRAY['shenzhen']::text[], ARRAY['shenzhen','guangzhou']::text[], ARRAY['china','shenzhen','mountain','free-entry','trekking']::text[]),
    ('JP', 'JPY', 'mount-takao-trail', 'tokyo', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа горы Такао', 'Mount Takao Trail', 'Такао тауы соқпағы', 'Классический маршрут рядом с Токио: лес, храмовые точки, виды на город и гора Фудзи в ясную погоду.', 'A classic route near Tokyo with forest, temple stops, city views and Mount Fuji visibility in clear weather.', 'Токио маңындағы классикалық бағыт: орман, храм аялдамалары, қала көріністері және ашық күнде Фудзи тауы көрінеді.', 35.62500000, 139.24300000, '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg', ARRAY['tokyo','yokohama']::text[], ARRAY['tokyo','yokohama']::text[], ARRAY['japan','tokyo','mount-takao','free-entry','hiking']::text[]),
    ('KR', 'KRW', 'bukhansan-baegundae-trail', 'seoul', 'NATURE', 0, 6, 'HOURS', 4.9, 'Тропа Бэгундэ в Букхансане', 'Bukhansan Baegundae Trail', 'Букхансан Бэгундэ соқпағы', 'Самый сильный городской трек Сеула к гранитной вершине, крепостной стене и широким видам на столицу.', 'Seoul strongest urban trek to a granite summit, fortress wall and wide capital views.', 'Сеулдің ең әсерлі қалалық трегі: гранит шыңға, қамал қабырғасына және астанаға кең көріністерге апарады.', 37.65800000, 126.97700000, 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg', ARRAY['seoul','suwon','incheon']::text[], ARRAY['seoul','suwon','incheon']::text[], ARRAY['south-korea','seoul','bukhansan','summit','free-entry','trekking']::text[]),
    ('TH', 'THB', 'dragon-crest-mountain-trail', 'krabi', 'NATURE', 200, 5, 'HOURS', 4.8, 'Тропа горы Dragon Crest', 'Dragon Crest Mountain Trail', 'Dragon Crest тауы соқпағы', 'Лесной подъем Краби к панораме известняковых островов, бухт и Андаманского моря, добавляющий региону настоящий hiking-день.', 'A Krabi forest climb to panoramic views of limestone islands, bays and the Andaman Sea, adding a true hiking day to the region.', 'Крабидегі орманды көтерілу: әктас аралдарға, шығанақтарға және Андаман теңізіне панорама беріп, өңірге нағыз hiking күні қосады.', 8.08300000, 98.75000000, 'Railay Beach 2.jpg', ARRAY['krabi']::text[], ARRAY['krabi']::text[], ARRAY['thailand','krabi','viewpoint','limestone','trekking']::text[]),
    ('TH', 'THB', 'kew-mae-pan-nature-trail', 'chiang-mai', 'NATURE', 300, 3, 'HOURS', 4.8, 'Природная тропа Кью Мэй Пан', 'Kew Mae Pan Nature Trail', 'Кью Мэй Пан табиғи соқпағы', 'Высокогорная тропа возле Дой Интханон с туманными лесами, открытыми гребнями и прохладным климатом северного Таиланда.', 'A highland trail near Doi Inthanon with misty forest, open ridges and northern Thailand cool climate.', 'Дой Интханон маңындағы биік таулы соқпақ: тұманды орман, ашық жоталар және Солтүстік Таиландтың салқын климаты.', 18.55800000, 98.48000000, 'Doi_Inthanon_National_Park.jpg', ARRAY['chiang-mai']::text[], ARRAY['chiang-mai']::text[], ARRAY['thailand','chiang-mai','doi-inthanon','nature-trail','hiking']::text[]),
    ('PH', 'PHP', 'mount-hibok-hibok-trail', 'camiguin', 'NATURE', 100, 6, 'HOURS', 4.9, 'Тропа вулкана Хибок-Хибок', 'Mount Hibok-Hibok Trail', 'Хибок-Хибок жанартауы соқпағы', 'Вулканический маршрут Камигина от горячих источников к кратеру, тропическому лесу и видам на остров и море.', 'A Camiguin volcano route from hot springs toward the crater, tropical forest and island-and-sea views.', 'Камигиндегі жанартаулы бағыт: ыстық бұлақтардан кратерге, тропикалық орманға және арал мен теңіз көріністеріне апарады.', 9.20300000, 124.67300000, 'White_Island_Camiguin.jpg', ARRAY['camiguin']::text[], ARRAY['camiguin']::text[], ARRAY['philippines','camiguin','volcano','permit','trekking']::text[]),
    ('PH', 'PHP', 'mount-ulap-trail', 'baguio', 'NATURE', 100, 7, 'HOURS', 4.8, 'Тропа горы Улап', 'Mount Ulap Trail', 'Улап тауы соқпағы', 'Популярный кордильерский трек из Багио с травянистыми гребнями, сосновыми участками и видом на горные деревни.', 'A popular Cordillera trek from Baguio with grassy ridges, pine sections and mountain village views.', 'Багиодан шығатын танымал Кордильера трегі: шөпті жоталар, қарағайлы бөліктер және тау ауылдарына көріністер.', 16.32700000, 120.63100000, 'Mines_View_Park_Baguio.jpg', ARRAY['baguio']::text[], ARRAY['baguio']::text[], ARRAY['philippines','baguio','cordillera','ridge','trekking']::text[]),
    ('MY', 'MYR', 'broga-hill-trail', 'selangor', 'NATURE', 5, 4, 'HOURS', 4.7, 'Тропа холма Брога', 'Broga Hill Trail', 'Брога төбесі соқпағы', 'Рассветный маршрут Селангора по открытым холмам с мягкой сложностью, травянистыми гребнями и видами на окрестности Куала-Лумпура.', 'A Selangor sunrise route over open hills with friendly difficulty, grassy ridges and views around Kuala Lumpur.', 'Селангордағы таңғы бағыт: ашық төбелер, жеңіл күрделілік, шөпті жоталар және Куала-Лумпур маңына көріністер.', 2.93800000, 101.90000000, 'FRIM_01.jpg', ARRAY['selangor','kuala-lumpur']::text[], ARRAY['selangor','kuala-lumpur']::text[], ARRAY['malaysia','selangor','sunrise','ridge','hiking']::text[]),
    ('LK', 'LKR', 'knuckles-mini-worlds-end-trail', 'kandy', 'NATURE', 1000, 6, 'HOURS', 4.8, 'Тропа Mini World''s End в Наклс', $$Knuckles Mini World's End Trail$$, 'Наклс Mini World''s End соқпағы', 'Маршрут из Канди к хребту Наклс с облачными лесами, резкими обрывами и горными деревнями центральной Шри-Ланки.', 'A route from Kandy toward the Knuckles Range with cloud forest, sharp escarpments and central Sri Lanka mountain villages.', 'Кандиден Наклс жотасына баратын бағыт: бұлтты орман, тік жарлар және Орталық Шри-Ланканың тау ауылдары.', 7.45000000, 80.80000000, 'Temple_of_the_Tooth_Kandy.jpg', ARRAY['kandy']::text[], ARRAY['kandy']::text[], ARRAY['sri-lanka','knuckles-range','cloud-forest','trekking']::text[]),
    ('TR', 'TRY', 'kackar-pokut-plateau-trail', 'rize', 'NATURE', 0, 6, 'HOURS', 4.9, 'Тропа плато Покут в Качкаре', 'Kackar Pokut Plateau Trail', 'Качкар Покут жайлауы соқпағы', 'Зеленый черноморский маршрут Ризе к высокогорным плато, туманным лесам и деревянным домам Качкарских гор.', 'A green Black Sea route from Rize toward high plateaus, misty forest and wooden highland houses of the Kackar Mountains.', 'Ризеден биік жайлауларға, тұманды ормандарға және Качкар тауларының ағаш үйлеріне апаратын жасыл Қара теңіз бағыты.', 40.98000000, 40.88000000, 'Ayder_Plateau.jpg', ARRAY['rize','uzungol','trabzon']::text[], ARRAY['rize','trabzon']::text[], ARRAY['turkey','kackar','black-sea','plateau','free-entry','hiking']::text[]),
    ('AM', 'AMD', 'mount-aragats-kari-lake-trail', 'byurakan', 'NATURE', 1000, 7, 'HOURS', 4.9, 'Тропа Арагаца к озеру Кари', 'Mount Aragats Kari Lake Trail', 'Арагац Кари көлі соқпағы', 'Высокогорный маршрут от Бюракана к озеру Кари и склонам Арагаца, где исторические остановки получают полноценный mountain-day.', 'A high mountain route from Byurakan toward Kari Lake and Aragats slopes, turning historic stops into a full mountain day.', 'Бюраканнан Кари көлі мен Арагац беткейлеріне апаратын биік таулы бағыт, тарихи аялдамаларды толық mountain-day сценарийіне айналдырады.', 40.47300000, 44.18400000, 'Yerevan,_Armenia.jpg', ARRAY['byurakan','yerevan']::text[], ARRAY['byurakan','yerevan']::text[], ARRAY['armenia','aragats','kari-lake','highland','trekking']::text[]),
    ('AZ', 'AZN', 'khinalig-to-galakhudat-trail', 'khinalig', 'NATURE', 0, 6, 'HOURS', 4.9, 'Тропа из Хыналыга в Галахудат', 'Khinalig to Galakhudat Trail', 'Хыналыгтан Галахудатқа соқпақ', 'Горный маршрут Большого Кавказа между высокогорными селами, пастбищами и видами на северный Азербайджан.', 'A Greater Caucasus route between highland villages, pastures and views across northern Azerbaijan.', 'Үлкен Кавказдағы биік тау ауылдары, жайылымдар және Солтүстік Әзербайжан көріністері арасындағы бағыт.', 41.18500000, 48.12000000, 'Khinalig Azerbaijan.jpg', ARRAY['khinalig','quba']::text[], ARRAY['quba','khinalig']::text[], ARRAY['azerbaijan','greater-caucasus','village-trail','free-entry','trekking']::text[]);

CREATE TEMP TABLE seed_asia_middle_east_hiking_resolved_places AS
SELECT
    ('91ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['asia-me-hiking-v1', lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_asia_middle_east_hiking_places;

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
FROM seed_asia_middle_east_hiking_resolved_places
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
FROM seed_asia_middle_east_hiking_resolved_places
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
FROM seed_asia_middle_east_hiking_resolved_places
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
FROM seed_asia_middle_east_hiking_resolved_places
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
FROM seed_asia_middle_east_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
