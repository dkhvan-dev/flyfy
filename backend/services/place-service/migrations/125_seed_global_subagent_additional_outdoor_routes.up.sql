-- Additional global subagent outdoor route seed.
-- Adds non-duplicate route-level places for city hubs surfaced by parallel enrichment review.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_global_subagent_additional_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_subagent_additional_outdoor_routes_places;

CREATE TEMP TABLE seed_global_subagent_additional_outdoor_routes_places (
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

INSERT INTO seed_global_subagent_additional_outdoor_routes_places (
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
    ('CA', 'CAD', 'mer-bleue-bog-boardwalk', 'ottawa', 'NATURE', 0, 2, 'HOURS', 4.7, 'Настил болота Mer Bleue', 'Mer Bleue Bog Boardwalk', 'Mer Bleue батпағы тақтай жолы', 'Легкий маршрут у Оттавы по северному болотному ландшафту, сосновым участкам и смотровым площадкам для спокойной природной паузы.', 'An easy Ottawa-area route through northern bog scenery, pine pockets and viewing decks for a calm nature break.', 'Оттава маңындағы солтүстік батпақ көріністері, қарағайлы бөліктер және тыныш табиғи үзіліске арналған қарау алаңдары бар жеңіл бағыт.', 45.40400000, -75.51200000, 'Rideau_Canal_Ottawa.jpg', ARRAY['ottawa']::text[], ARRAY['ottawa']::text[], ARRAY['canada','ottawa','wetland','boardwalk','free-entry','walking']::text[]),
    ('PT', 'EUR', 'ponta-de-sao-lourenco-trail', 'madeira', 'NATURE', 0, 4, 'HOURS', 4.9, 'Тропа Понта-де-Сан-Лоренсу', 'Ponta de Sao Lourenco Trail', 'Понта-де-Сан-Лоренсу соқпағы', 'Прибрежный маршрут Мадейры по сухому полуострову, океанским обрывам и ветреным точкам с видом на восточный край острова.', 'A Madeira coastal route across a dry peninsula, ocean cliffs and windy viewpoints over the island eastern edge.', 'Мадейраның құрғақ түбегі, мұхит жартастары және аралдың шығыс шетіне ашылатын желді нүктелері арқылы өтетін жағалық бағыт.', 32.74300000, -16.70100000, 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg', ARRAY['madeira','funchal']::text[], ARRAY['madeira','funchal']::text[], ARRAY['portugal','madeira','coastal','cliff','free-entry','hiking']::text[]),
    ('MX', 'MXN', 'barranca-de-huentitan-trail', 'guadalajara', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа каньона Барранка-де-Уэнтитан', 'Barranca de Huentitan Trail', 'Барранка-де-Уэнтитан каньоны соқпағы', 'Маршрут у Гвадалахары к глубокому каньону, сухим склонам и смотровым точкам, добавляющий городу сильный outdoor-сценарий.', 'A Guadalajara route toward a deep canyon, dry slopes and viewpoints, adding a strong outdoor plan to the city hub.', 'Гвадалахара маңындағы терең каньонға, құрғақ беткейлерге және көрініс нүктелеріне апаратын, қала хабына мықты outdoor сценарий қосатын бағыт.', 20.73200000, -103.30300000, 'Catedral de Guadalajara.jpg', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], ARRAY['mexico','guadalajara','canyon','free-entry','hiking']::text[]),
    ('MX', 'MXN', 'huitepec-cloud-forest-trail', 'san-cristobal-de-las-casas', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа облачного леса Уитепек', 'Huitepec Cloud Forest Trail', 'Уитепек бұлтты орманы соқпағы', 'Прохладный маршрут над Сан-Кристобалем по влажному лесу, папоротникам и мягким горным тропам без долгого трансфера.', 'A cool route above San Cristobal through cloud forest, ferns and gentle mountain paths without a long transfer.', 'Сан-Кристобаль үстіндегі бұлтты орман, қырыққұлақтар және ұзақ трансферсіз жұмсақ тау жолдары арқылы өтетін салқын бағыт.', 16.73900000, -92.67600000, 'Chichen Itza El Castillo.JPG', ARRAY['san-cristobal-de-las-casas']::text[], ARRAY['san-cristobal-de-las-casas']::text[], ARRAY['mexico','chiapas','cloud-forest','free-entry','hiking']::text[]),
    ('AE', 'AED', 'wadi-shawka-dam-loop', 'ras-al-khaimah', 'NATURE', 0, 3, 'HOURS', 4.7, 'Кольцо дамбы Вади-Шавка', 'Wadi Shawka Dam Loop', 'Вади-Шавка бөгеті айналма жолы', 'Маршрут Хаджарских гор у водохранилища, сухих русел и невысоких каменных гряд для короткого активного выезда из Рас-эль-Хаймы.', 'A Hajar Mountains route by the dam, dry wadis and low rocky ridges for a short active outing from Ras Al Khaimah.', 'Рас-эль-Хаймадан қысқа белсенді шығуға арналған Хаджар тауларындағы бөгет, құрғақ вади және аласа тас жоталар бағыты.', 25.10800000, 56.05400000, 'Jebel_Jais_Ras_Al_Khaimah.jpg', ARRAY['ras-al-khaimah','dubai']::text[], ARRAY['ras-al-khaimah','dubai']::text[], ARRAY['uae','hajar','wadi','free-entry','hiking']::text[]),
    ('GE', 'GEL', 'hatsvali-zuruldi-ridge-trail', 'mestia', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа гряды Хацвали-Зурулди', 'Hatsvali Zuruldi Ridge Trail', 'Хацвали-Зурулди жотасы соқпағы', 'Сванетский маршрут над Местией к открытой гряде, видам на Ушбу и удобному летнему сценарию рядом с канатной зоной.', 'A Svaneti route above Mestia toward an open ridge, Ushba views and an easy summer plan near the lift area.', 'Местия үстіндегі ашық жотаға, Ушба көріністеріне және аспалы жол аймағына жақын ыңғайлы жазғы сценарийге апаратын Сванетия бағыты.', 43.03100000, 42.72800000, 'Kutaisi,_Georgia.jpg', ARRAY['mestia']::text[], ARRAY['mestia']::text[], ARRAY['georgia','svaneti','ridge','free-entry','hiking']::text[]),
    ('IT', 'EUR', 'sartorius-craters-trail', 'catania', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа кратеров Сарториус', 'Sartorius Craters Trail', 'Сарториус кратерлері соқпағы', 'Этнейский маршрут по старым лавовым конусам, черным склонам и сосновым участкам для понятного вулканического дня из Катании.', 'An Etna route across old lava cones, black slopes and pine sections for a clear volcanic day from Catania.', 'Катаниядан шығатын түсінікті жанартаулық күнге арналған Этнадағы ескі лава конустары, қара беткейлер және қарағайлы бөліктер бағыты.', 37.79200000, 15.04300000, 'Colosseum_in_Rome,_Italy_-_April_2007.jpg', ARRAY['catania']::text[], ARRAY['catania']::text[], ARRAY['italy','sicily','etna','volcanic','free-entry','walking']::text[]),
    ('BR', 'BRL', 'utinga-state-park-trail', 'belem', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа парка Утинга', 'Utinga State Park Trail', 'Утинга мемлекеттік паркі соқпағы', 'Зеленый маршрут Белена по охраняемому лесу, водоемам и тенистым дорожкам, который добавляет Амазонии доступный городской outdoor-формат.', 'A Belem route through protected forest, lakes and shaded paths, adding an accessible urban outdoor plan in the Amazon region.', 'Белендегі қорғалатын орман, көлдер және көлеңкелі жолдар арқылы өтетін, Амазонияға қолжетімді қалалық outdoor формат қосатын бағыт.', -1.42400000, -48.43700000, 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg', ARRAY['belem']::text[], ARRAY['belem']::text[], ARRAY['brazil','belem','forest','lake','free-entry','walking']::text[]),
    ('AU', 'AUD', 'cape-byron-walking-track', 'byron-bay', 'NATURE', 0, 3, 'HOURS', 4.8, 'Пешеходная тропа Кейп-Байрон', 'Cape Byron Walking Track', 'Кейп-Байрон жаяу жолы', 'Прибрежная петля Байрон-Бея через маяк, лесные участки и океанские смотровые точки для мягкого, но насыщенного маршрута.', 'A Byron Bay coastal loop through the lighthouse area, forest sections and ocean viewpoints for a gentle but rich route.', 'Байрон-Бейдегі маяк аймағы, орманды бөліктер және мұхит көрініс нүктелері арқылы өтетін жұмсақ әрі мазмұнды жағалық айналма жол.', -28.64100000, 153.63600000, 'Exterior_of_Sydney_Opera_House.jpg', ARRAY['byron-bay']::text[], ARRAY['byron-bay']::text[], ARRAY['australia','byron-bay','coastal','free-entry','walking']::text[]),
    ('AU', 'AUD', 'cataract-gorge-basin-loop', 'launceston', 'NATURE', 0, 2, 'HOURS', 4.7, 'Кольцо чаши Cataract Gorge', 'Cataract Gorge Basin Loop', 'Cataract шатқалы бассейні айналма жолы', 'Короткий тасманийский маршрут в черте Лонсестона по скалам, мостам, тенистым участкам и берегам ущелья.', 'A short Tasmanian route inside Launceston across rocks, bridges, shaded sections and gorge edges.', 'Лонсестон ішіндегі тастар, көпірлер, көлеңкелі бөліктер және шатқал жағалары арқылы өтетін қысқа Тасмания бағыты.', -41.44600000, 147.11900000, 'Hobart_Tasmania_Salamanca_Place.jpg', ARRAY['launceston']::text[], ARRAY['launceston','hobart']::text[], ARRAY['australia','tasmania','gorge','free-entry','walking']::text[]),
    ('AU', 'AUD', 'wadjemup-bidi-coastal-trail', 'rottnest-island', 'NATURE', 0, 5, 'HOURS', 4.8, 'Прибрежная тропа Wadjemup Bidi', 'Wadjemup Bidi Coastal Trail', 'Wadjemup Bidi жағалық соқпағы', 'Островной маршрут Роттнеста по бухтам, низким дюнам и океанским видам, связывающий пляжи в полноценный пешеходный день.', 'A Rottnest Island route across bays, low dunes and ocean views, linking beaches into a complete walking day.', 'Роттнест аралындағы бухталар, аласа құмдар және мұхит көріністері арқылы өтетін, жағажайларды толық жаяу күнге біріктіретін бағыт.', -32.01200000, 115.51000000, 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg', ARRAY['rottnest-island','perth']::text[], ARRAY['rottnest-island','perth']::text[], ARRAY['australia','rottnest-island','coastal','free-entry','walking']::text[]),
    ('MV', 'MVR', 'dhigurah-sandbank-walk', 'dhigurah', 'NATURE', 0, 2, 'HOURS', 4.8, 'Прогулка песчаной косы Дигура', 'Dhigurah Sandbank Walk', 'Дигура құм қайыры серуені', 'Мягкий островной маршрут по длинной песчаной линии, мелководью и открытому горизонту Южного Ари, отдельный от пляжной карточки.', 'A gentle island route along a long sand line, shallow water and the open South Ari horizon, separate from the beach card.', 'Оңтүстік Ари көкжиегі, тайыз су және ұзын құм сызығы бойымен өтетін, жағажай карточкасынан бөлек жұмсақ арал бағыты.', 3.52700000, 72.92500000, 'Maldives_island_beach_2.jpg', ARRAY['dhigurah']::text[], ARRAY['dhigurah']::text[], ARRAY['maldives','dhigurah','sandbank','free-entry','walking']::text[]),
    ('TR', 'TRY', 'butterfly-valley-faralya-view-trail', 'fethiye', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа вида на Долину бабочек из Фаральи', 'Butterfly Valley Faralya View Trail', 'Фаральядан Көбелектер аңғары көрініс соқпағы', 'Прибрежный маршрут Ликийской дороги у Фаральи к видам на долину, обрывам и светлому морскому горизонту.', 'A Lycian Way coastal route near Faralya toward valley views, cliffs and a bright sea horizon.', 'Фаралья маңындағы Ликия жолының жағалық бағыты: аңғар көріністеріне, жартастарға және ашық теңіз көкжиегіне апарады.', 36.49500000, 29.13000000, 'Kaputas_Beach.jpg', ARRAY['fethiye','oludeniz']::text[], ARRAY['fethiye','oludeniz']::text[], ARRAY['turkey','lycian-way','coastal','free-entry','hiking']::text[]),
    ('CH', 'CHF', 'riffelsee-gornergrat-panorama-trail', 'zermatt', 'NATURE', 0, 4, 'HOURS', 4.9, 'Панорамная тропа Риффельзее-Горнерграт', 'Riffelsee Gornergrat Panorama Trail', 'Риффельзее-Горнерграт панорама соқпағы', 'Альпийский маршрут Церматта между озерными отражениями Маттерхорна, открытыми гребнями и удобной связкой с Горнергратом.', 'A Zermatt alpine route between Matterhorn lake reflections, open ridges and an easy connection with Gornergrat.', 'Церматтағы Маттерхорнның көлдегі шағылыстары, ашық жоталар және Горнергратпен ыңғайлы байланыс арқылы өтетін альпілік бағыт.', 45.99400000, 7.78900000, 'Matterhorn Riffelsee 2005-06-11.jpg', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], ARRAY['switzerland','zermatt','alpine-lake','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'chimgan-gulkam-gorge-trail', 'chimgan', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа ущелья Гулькам в Чимгане', 'Chimgan Gulkam Gorge Trail', 'Шымған Гүлкам шатқалы соқпағы', 'Горный маршрут Чимгана к узкому ущелью, каменным стенкам и прохладной воде, отдельный от широких обзорных маршрутов Чарвака.', 'A Chimgan mountain route toward a narrow gorge, rocky walls and cool water, distinct from broad Charvak viewpoint routes.', 'Шымғандағы тар шатқалға, тас қабырғаларға және салқын суға апаратын, Чарвактың кең көрініс маршруттарынан бөлек тау бағыты.', 41.57300000, 70.01900000, 'Chimgan Uzbekistan.jpg', ARRAY['chimgan','tashkent']::text[], ARRAY['tashkent','chimgan']::text[], ARRAY['uzbekistan','chimgan','gorge','free-entry','trekking']::text[]),
    ('SC', 'SCR', 'dans-gallas-trail', 'beau-vallon', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа Данс-Галлас', 'Dans Gallas Trail', 'Данс-Галлас соқпағы', 'Короткий маршрут на Маэ над Бо-Валлоном к лесной гряде, видам на бухту и более активному сценарию между пляжными днями.', 'A short Mahe route above Beau Vallon toward a forested ridge, bay views and a more active plan between beach days.', 'Бо-Валлон үстіндегі Маэ бағыты: орманды жотаға, бухта көріністеріне және жағажай күндері арасындағы белсендірек сценарийге апарады.', -4.60300000, 55.43500000, 'Beau Vallon Beach (11177463746).jpg', ARRAY['beau-vallon','victoria']::text[], ARRAY['beau-vallon','victoria']::text[], ARRAY['seychelles','mahe','ridge','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_global_subagent_additional_outdoor_routes_resolved_places AS
SELECT
    ('125d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['global-subagent-additional-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_global_subagent_additional_outdoor_routes_places;

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
FROM seed_global_subagent_additional_outdoor_routes_resolved_places
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
FROM seed_global_subagent_additional_outdoor_routes_resolved_places
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
FROM seed_global_subagent_additional_outdoor_routes_resolved_places
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
FROM seed_global_subagent_additional_outdoor_routes_resolved_places
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
FROM seed_global_subagent_additional_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_global_subagent_additional_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_subagent_additional_outdoor_routes_places;
