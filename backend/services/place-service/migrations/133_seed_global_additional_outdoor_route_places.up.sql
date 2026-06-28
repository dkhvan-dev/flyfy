-- Additional global outdoor route place seed.
-- Adds non-duplicate route-level hikes and walks for already seeded destination hubs.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_global_additional_outdoor_route_places_resolved_places;
DROP TABLE IF EXISTS seed_global_additional_outdoor_route_places;

CREATE TEMP TABLE seed_global_additional_outdoor_route_places (
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

INSERT INTO seed_global_additional_outdoor_route_places (
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
    ('US', 'USD', 'inwood-hill-park-forest-trail', 'new-york', 'NATURE', 0, 2, 'HOURS', 4.6, 'Лесная тропа Inwood Hill Park', 'Inwood Hill Park Forest Trail', 'Inwood Hill Park орман соқпағы', 'Северный маршрут Манхэттена по холмам, старому лесу и видам на Гудзон, который дает Нью-Йорку отдельную природную trail-карточку.', 'A northern Manhattan route through hills, old forest and Hudson views, giving New York a distinct nature trail card.', 'Манхэттеннің солтүстігіндегі төбелер, көне орман және Гудзон көріністері арқылы өтетін, Нью-Йоркке бөлек табиғи trail-карточка беретін бағыт.', 40.87200000, -73.92500000, 'Central_Park_New_York_City_New_York_23.jpg', ARRAY['new-york']::text[], ARRAY['new-york']::text[], ARRAY['united-states','new-york','urban-forest','hudson','free-entry','walking']::text[]),
    ('US', 'USD', 'theodore-roosevelt-island-loop-trail', 'washington-dc', 'NATURE', 0, 2, 'HOURS', 4.7, 'Кольцевая тропа острова Теодора Рузвельта', 'Theodore Roosevelt Island Loop Trail', 'Теодор Рузвельт аралының айналма соқпағы', 'Лесная петля на острове Потомака рядом с центром Вашингтона: настилы, тенистые участки и спокойный природный контраст к мемориальной оси.', 'A forest loop on a Potomac island near central Washington DC, with boardwalks, shaded sections and a calm nature contrast to the memorial axis.', 'Вашингтон орталығына жақын Потомак аралындағы орман ілмегі: тақтайжолдар, көлеңкелі бөліктер және мемориалдық оське табиғи тыныш контраст.', 38.89700000, -77.06400000, 'National_Mall_Washington_DC.jpg', ARRAY['washington-dc']::text[], ARRAY['washington-dc']::text[], ARRAY['united-states','washington-dc','potomac','island-loop','free-entry','walking']::text[]),
    ('US', 'USD', 'forest-park-wildwood-trail-segment', 'portland', 'NATURE', 0, 3, 'HOURS', 4.8, 'Участок Wildwood Trail в Forest Park', 'Forest Park Wildwood Trail Segment', 'Forest Park ішіндегі Wildwood Trail бөлігі', 'Зеленый маршрут Портленда по хвойному лесу и мягкому рельефу Wildwood Trail, отдельный от городской карточки Washington Park.', 'A Portland green route through conifer forest and gentle Wildwood Trail terrain, distinct from the broad Washington Park card.', 'Портлендтегі қылқанжапырақты орман мен Wildwood Trail-дің жұмсақ бедері арқылы өтетін, Washington Park жалпы карточкасынан бөлек жасыл бағыт.', 45.56800000, -122.75900000, 'Washington_Park_Portland_Oregon.jpg', ARRAY['portland']::text[], ARRAY['portland']::text[], ARRAY['united-states','portland','forest-park','wildwood','free-entry','hiking']::text[]),
    ('US', 'USD', 'torrey-pines-beach-trail-loop', 'san-diego', 'NATURE', 0, 3, 'HOURS', 4.8, 'Пляжная петля Torrey Pines', 'Torrey Pines Beach Trail Loop', 'Torrey Pines жағажай ілмегі', 'Прибрежная петля Сан-Диего по песчаниковым обрывам, соснам и спуску к океану, отдельная от пляжных карточек Ла-Хойи.', 'A San Diego coastal loop across sandstone bluffs, pines and an ocean descent, separate from the La Jolla beach cards.', 'Сан-Диегодағы құмтас жарлар, қарағайлар және мұхитқа түсетін жол арқылы өтетін, Ла-Хойя жағажай карточкаларынан бөлек жағалау ілмегі.', 32.92100000, -117.25500000, 'La_Jolla_Cove_2018.jpg', ARRAY['san-diego']::text[], ARRAY['san-diego']::text[], ARRAY['united-states','san-diego','torrey-pines','coastal','free-entry','hiking']::text[]),
    ('MX', 'MXN', 'punta-sur-lagoon-boardwalk', 'cozumel', 'NATURE', 350, 3, 'HOURS', 4.7, 'Настил лагуны Punta Sur', 'Punta Sur Lagoon Boardwalk', 'Punta Sur лагуна тақтайжолы', 'Островной маршрут Косумеля по лагуне, мангровым видам и наблюдению за птицами внутри зоны Punta Sur, не повторяющий рифовую карточку.', 'A Cozumel island route along lagoon boardwalks, mangrove views and birdwatching inside the Punta Sur area, not duplicating the reef card.', 'Косумельдегі Punta Sur аймағындағы лагуна тақтайжолдары, мангр көріністері және құс бақылауы арқылы өтетін, риф карточкасын қайталамайтын арал бағыты.', 20.29900000, -87.02100000, 'Hotel Zone in Cancun, Mexico.jpg', ARRAY['cozumel']::text[], ARRAY['cozumel','playa-del-carmen']::text[], ARRAY['mexico','cozumel','punta-sur','lagoon','boardwalk','walking']::text[]),
    ('SC', 'SCR', 'morne-seychellois-summit-trail', 'mahe', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа на вершину Morne Seychellois', 'Morne Seychellois Summit Trail', 'Morne Seychellois шыңы соқпағы', 'Горный маршрут Маэ к высшей точке Сейшел: влажный лес, гранитный рельеф и видовой финал над западным побережьем.', 'A Mahe mountain route toward the Seychelles high point, with humid forest, granite terrain and a summit view over the west coast.', 'Маэ аралындағы Сейшелдің ең биік нүктесіне апаратын тау бағыты: ылғалды орман, гранит бедері және батыс жағалауға көрініс.', -4.65300000, 55.43200000, 'Beau Vallon Beach (11177463746).jpg', ARRAY['mahe','victoria']::text[], ARRAY['mahe','victoria']::text[], ARRAY['seychelles','mahe','summit','granite','free-entry','trekking']::text[]),
    ('GE', 'GEL', 'kojori-udzo-monastery-ridge-trail', 'tbilisi', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа Коджори - монастырь Удзо', 'Kojori to Udzo Monastery Ridge Trail', 'Қоджориден Удзо монастырына жота соқпағы', 'Маршрут из зеленой зоны над Тбилиси по лесу и открытому гребню к монастырской смотровой точке, отдельный от городских парков.', 'A route from the green belt above Tbilisi through forest and open ridge toward a monastery viewpoint, separate from the city park cards.', 'Тбилиси үстіндегі жасыл белдеуден орман мен ашық жота арқылы монастырь көрініс нүктесіне апаратын, қалалық парк карточкаларынан бөлек бағыт.', 41.64100000, 44.67300000, 'Tbilisi,_Georgia.jpg', ARRAY['tbilisi']::text[], ARRAY['tbilisi']::text[], ARRAY['georgia','tbilisi','kojori','ridge','free-entry','hiking']::text[]),
    ('CZ', 'CZK', 'gabriela-sandstone-balcony-trail', 'bohemian-switzerland', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа Габриэлы по песчаниковым балконам', 'Gabriela Sandstone Balcony Trail', 'Габриэла құмтас балконы соқпағы', 'Пешеходный маршрут Чешской Швейцарии по лесу и песчаниковым балконам, который добавляет route-level сценарий рядом с Правчицкими воротами.', 'A Bohemian Switzerland walking route through forest and sandstone balconies, adding a route-level scenario near Pravcicka Gate.', 'Чешская Швейцариядағы орман мен құмтас балкондары арқылы өтетін, Правчиц қақпасы маңына route-level сценарий қосатын жаяу бағыт.', 50.88400000, 14.28400000, 'Bohemian Switzerland National Park.jpg', ARRAY['bohemian-switzerland']::text[], ARRAY['bohemian-switzerland','prague']::text[], ARRAY['czechia','bohemian-switzerland','sandstone','forest','free-entry','hiking']::text[]),
    ('EE', 'EUR', 'oandu-beaver-forest-trail', 'lahemaa', 'NATURE', 0, 2, 'HOURS', 4.7, 'Лесная тропа бобров Оанду', 'Oandu Beaver Forest Trail', 'Оанду құндыз орман соқпағы', 'Короткая лесная прогулка Лахемаа вокруг ручьев, следов бобров и мягкой северной зелени, отдельная от болотных настилов.', 'A short Lahemaa forest walk around streams, beaver traces and soft northern greenery, distinct from the bog boardwalk routes.', 'Лахемаадағы бұлақтар, құндыз іздері және жұмсақ солтүстік жасыл желек арқылы өтетін, батпақ тақтайжолдарынан бөлек қысқа орман серуені.', 59.57700000, 26.10300000, 'Lahemaa_National_Park.jpg', ARRAY['lahemaa']::text[], ARRAY['lahemaa','tallinn']::text[], ARRAY['estonia','lahemaa','oandu','forest','free-entry','walking']::text[]),
    ('FI', 'EUR', 'kilpisjarvi-border-fell-walk', 'kilpisjarvi', 'NATURE', 0, 4, 'HOURS', 4.6, 'Пограничная сопочная прогулка Килписъярви', 'Kilpisjarvi Border Fell Walk', 'Килписъярви шекара қырқасы серуені', 'Северная прогулка по открытой сопочной зоне Килписъярви к пограничным пейзажам и арктическому горизонту без повторения Сааны.', 'A northern walk through open Kilpisjarvi fell terrain toward border landscapes and the Arctic horizon without duplicating Saana Fell.', 'Килписъярвидің ашық қырқалы жерімен шекара пейзаждарына және арктикалық көкжиекке апаратын, Саананы қайталамайтын солтүстік серуен.', 69.05500000, 20.65000000, 'Three-Country_Cairn.jpg', ARRAY['kilpisjarvi']::text[], ARRAY['kilpisjarvi']::text[], ARRAY['finland','lapland','kilpisjarvi','fell','free-entry','walking']::text[]),
    ('LU', 'EUR', 'berdorf-wanterbaach-rock-trail', 'berdorf', 'NATURE', 0, 3, 'HOURS', 4.7, 'Скальная тропа Вантербаах в Бердорфе', 'Berdorf Wanterbaach Rock Trail', 'Бердорф Вантербаах жартас соқпағы', 'Маршрут Маленькой Швейцарии по песчаниковым стенам, узким проходам и лесным участкам Бердорфа, не повторяющий общую Mullerthal Trail.', 'A Little Switzerland route through sandstone walls, narrow passages and Berdorf forest sections, not duplicating the broad Mullerthal Trail.', 'Кіші Швейцариядағы Бердорф орманы, құмтас қабырғалар және тар өткелдер арқылы өтетін, жалпы Mullerthal Trail карточкасын қайталамайтын бағыт.', 49.82100000, 6.34500000, 'Mullerthal.jpg', ARRAY['berdorf']::text[], ARRAY['berdorf','echternach']::text[], ARRAY['luxembourg','berdorf','sandstone','forest','free-entry','hiking']::text[]),
    ('FR', 'EUR', 'sugiton-belvedere-trail', 'marseille', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа к бельведеру Сюжитон', 'Sugiton Belvedere Trail', 'Сюжитон көрініс соқпағы', 'Короткий маршрут Каланков к смотровой точке Сюжитон с белыми скалами, соснами и морской перспективой рядом с Марселем.', 'A short Calanques route to the Sugiton viewpoint with white cliffs, pines and a sea perspective near Marseille.', 'Марсель маңындағы ақ жартастар, қарағайлар және теңіз көрінісі бар Сюжитон смотроваясына апаратын қысқа Каланктар бағыты.', 43.22000000, 5.45400000, 'Calanques National Park.jpg', ARRAY['marseille']::text[], ARRAY['marseille']::text[], ARRAY['france','marseille','calanques','coastal','free-entry','hiking']::text[]),
    ('AU', 'AUD', 'nawurlandja-lookout-walk', 'kakadu', 'NATURE', 40, 2, 'HOURS', 4.7, 'Прогулка к смотровой Nawurlandja', 'Nawurlandja Lookout Walk', 'Nawurlandja көрінісіне серуен', 'Короткий маршрут Какаду по каменному склону к открытой смотровой над равнинами и скальными массивами Нурланги.', 'A short Kakadu route across a rocky slope to an open lookout above plains and Nourlangie rock formations.', 'Какадудағы тасты беткей арқылы жазықтар мен Нурланги жартастары үстіндегі ашық көрініске апаратын қысқа бағыт.', -12.86100000, 132.80000000, 'Kakadu_(AU),_Kakadu_National_Park,_Nadap_Lookout_--_2019_--_4200.jpg', ARRAY['kakadu']::text[], ARRAY['kakadu','darwin']::text[], ARRAY['australia','kakadu','lookout','rock-country','walking']::text[]),
    ('NZ', 'NZD', 'mercer-bay-loop-track', 'waitakere-ranges', 'NATURE', 0, 2, 'HOURS', 4.7, 'Петля Mercer Bay', 'Mercer Bay Loop Track', 'Mercer Bay ілмек соқпағы', 'Береговая петля Уаитакере над диким западным побережьем Окленда: обрывы, лесные участки и быстрые океанские виды.', 'A Waitakere coastal loop above Auckland wild west coast, with cliffs, forest sections and quick ocean views.', 'Оклендтің жабайы батыс жағалауы үстіндегі Уаитакере жағалау ілмегі: жарлар, орман бөліктері және мұхит көріністері.', -36.96000000, 174.47600000, 'Waitakere_Ranges_New_Zealand.jpg', ARRAY['waitakere-ranges','auckland']::text[], ARRAY['auckland','waitakere-ranges']::text[], ARRAY['new-zealand','waitakere','coastal-cliff','free-entry','walking']::text[]),
    ('JP', 'JPY', 'kanmangafuchi-abyss-riverside-walk', 'nikko', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка вдоль ущелья Канмангафути', 'Kanmangafuchi Abyss Riverside Walk', 'Канмангафути шатқалы жағалау серуені', 'Тихая прогулка Никко вдоль реки, каменных фигур и вулканического русла, отдельная от храмовой карточки Toshogu.', 'A quiet Nikko walk along the river, stone figures and volcanic channel, separate from the Toshogu shrine card.', 'Никкодағы өзен, тас мүсіндер және жанартаулық арна бойымен өтетін, Toshogu ғибадатхана карточкасынан бөлек тыныш серуен.', 36.75500000, 139.59400000, 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg', ARRAY['nikko']::text[], ARRAY['nikko','tokyo']::text[], ARRAY['japan','nikko','river-gorge','free-entry','walking']::text[]),
    ('KR', 'KRW', 'hallasan-eorimok-trail', 'jeju', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа Eorimok на Халласан', 'Hallasan Eorimok Trail', 'Халласан Eorimok соқпағы', 'Альтернативный маршрут Халласана через лес, лавовые склоны и высокогорную растительность, отдельный от общей карточки национального парка.', 'An alternative Hallasan route through forest, lava slopes and alpine vegetation, separate from the broad national park card.', 'Халласандағы орман, лава беткейлері және биіктау өсімдігі арқылы өтетін, ұлттық парк жалпы карточкасынан бөлек балама бағыт.', 33.37000000, 126.49500000, 'Hallasan_Above.jpg', ARRAY['jeju']::text[], ARRAY['jeju']::text[], ARRAY['south-korea','jeju','hallasan','volcano','free-entry','trekking']::text[]),
    ('CN', 'CNY', 'huangshi-village-loop-trail', 'zhangjiajie', 'NATURE', 225, 4, 'HOURS', 4.8, 'Петля деревни Huangshi', 'Huangshi Village Loop Trail', 'Huangshi Village ілмек соқпағы', 'Верхняя петля Чжанцзяцзе по каменным площадкам, лесу и видам на столбы, отличная от маршрута по ручью Golden Whip.', 'An upper Zhangjiajie loop across stone viewpoints, forest and pillar views, distinct from the Golden Whip Stream route.', 'Чжанцзяцзедегі тас алаңдар, орман және баған жартастар көріністері арқылы өтетін, Golden Whip Stream бағытын қайталамайтын жоғарғы ілмек.', 29.33400000, 110.44000000, 'Zhangjiajie_National_Forest_Park.jpg', ARRAY['zhangjiajie']::text[], ARRAY['zhangjiajie']::text[], ARRAY['china','zhangjiajie','huangshi-village','forest','hiking']::text[]),
    ('MY', 'MYR', 'mount-santubong-summit-trail', 'kuching', 'NATURE', 10, 5, 'HOURS', 4.7, 'Тропа на вершину Mount Santubong', 'Mount Santubong Summit Trail', 'Сантубонг тауы шың соқпағы', 'Тропический маршрут рядом с Кучингом к лесной вершине Сантубонга, отдельный от Бако и культурной деревни Саравака.', 'A tropical route near Kuching toward the forested Santubong summit, separate from Bako and Sarawak Cultural Village cards.', 'Кучинг маңындағы орманды Сантубонг шыңына апаратын тропикалық бағыт, Бако мен Саравак мәдени ауылынан бөлек.', 1.74300000, 110.33000000, 'Sarawak_Cultural_Village.jpg', ARRAY['kuching']::text[], ARRAY['kuching']::text[], ARRAY['malaysia','sarawak','kuching','summit','rainforest','trekking']::text[]);

CREATE TEMP TABLE seed_global_additional_outdoor_route_places_resolved_places AS
SELECT
    ('133d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['global-additional-outdoor-route-places-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_global_additional_outdoor_route_places;

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
FROM seed_global_additional_outdoor_route_places_resolved_places
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
FROM seed_global_additional_outdoor_route_places_resolved_places
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
FROM seed_global_additional_outdoor_route_places_resolved_places
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
FROM seed_global_additional_outdoor_route_places_resolved_places
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
FROM seed_global_additional_outdoor_route_places_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_global_additional_outdoor_route_places_resolved_places;
DROP TABLE IF EXISTS seed_global_additional_outdoor_route_places;
