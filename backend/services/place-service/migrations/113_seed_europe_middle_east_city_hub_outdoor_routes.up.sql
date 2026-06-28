-- Europe and Middle East city-hub outdoor route seed.
-- Adds route-level walks and hikes for reference hubs that still lacked concrete outdoor coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_europe_middle_east_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_europe_middle_east_city_hub_outdoor_routes_places;

CREATE TEMP TABLE seed_europe_middle_east_city_hub_outdoor_routes_places (
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

INSERT INTO seed_europe_middle_east_city_hub_outdoor_routes_places (
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
    ('AE', 'AED', 'jubail-mangrove-boardwalk', 'abu-dhabi', 'NATURE', 15, 2, 'HOURS', 4.6, 'Настил мангров Джубейла', 'Jubail Mangrove Boardwalk', 'Джубейл мангр тақтайжолы', 'Спокойный маршрут Абу-Даби по деревянным настилам среди мангров, мелководья и птиц для мягкого природного перерыва в городе.', 'A calm Abu Dhabi route on wooden decks through mangroves, shallow water and birdlife for an easy nature break in the city.', 'Абу-Дабидегі мангрлар, тайыз су және құстар арасындағы ағаш тақтайжолмен өтетін тыныш табиғи үзіліс бағыты.', 24.54400000, 54.43300000, 'Abu_Dhabi_Mangroves.jpg', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi','dubai']::text[], ARRAY['uae','abu-dhabi','mangrove','boardwalk','walking']::text[]),
    ('AE', 'AED', 'ras-al-khor-flamingo-boardwalk', 'dubai', 'NATURE', 0, 1, 'HOURS', 4.5, 'Фламинговый настил Рас-эль-Хора', 'Ras Al Khor Flamingo Boardwalk', 'Рас-әл-Хор қоқиқаз тақтайжолы', 'Короткий городской маршрут Дубая к наблюдательным точкам у лагун, где удобно увидеть птиц и водный ландшафт без дальней поездки.', 'A short Dubai city route to lagoon viewing points, convenient for seeing birds and wetland scenery without a long transfer.', 'Дубайдағы лагуна көрініс нүктелеріне апаратын қысқа қалалық бағыт, құстар мен сулы ландшафтты алысқа бармай көруге қолайлы.', 25.19100000, 55.32700000, 'Ras_Al_Khor_Wildlife_Sanctuary.jpg', ARRAY['dubai']::text[], ARRAY['dubai']::text[], ARRAY['uae','dubai','wetlands','birdwatching','free-entry','walking']::text[]),
    ('AM', 'AMD', 'sevan-peninsula-monastery-walk', 'sevan', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка по Севанскому полуострову', 'Sevan Peninsula Monastery Walk', 'Севан түбегі монастырь серуені', 'Озерная прогулка по склонам полуострова с каменными ступенями, ветром, видом на воду и мягким культурным контекстом.', 'A lakeside walk on peninsula slopes with stone steps, wind, water views and a light cultural context.', 'Түбек беткейлеріндегі тас баспалдақтар, жел, көл көрінісі және жеңіл мәдени контексті бар серуен.', 40.56400000, 45.01100000, 'Lake_Sevan,_Armenia.jpg', ARRAY['sevan']::text[], ARRAY['sevan','yerevan']::text[], ARRAY['armenia','sevan','lake-view','free-entry','walking']::text[]),
    ('AZ', 'AZN', 'gobustan-mud-volcanoes-ridge-walk', 'gobustan', 'NATURE', 0, 3, 'HOURS', 4.6, 'Гребневая прогулка грязевых вулканов Гобустана', 'Gobustan Mud Volcanoes Ridge Walk', 'Гобустан лай жанартаулары жота серуені', 'Полупустынный маршрут по холмам Гобустана к грязевым конусам, сухим грядам и открытым видам Апшеронского ландшафта.', 'A semi-desert Gobustan route over hills toward mud cones, dry ridges and open views of the Absheron landscape.', 'Гобустан төбелері арқылы лай конустарына, құрғақ жоталарға және Апшерон ландшафтының ашық көріністеріне апаратын жартылай шөл бағыты.', 40.09500000, 49.38200000, 'Gobustan rock art Azerbaijan.jpg', ARRAY['gobustan']::text[], ARRAY['baku','gobustan']::text[], ARRAY['azerbaijan','gobustan','mud-volcanoes','free-entry','geotrail','walking']::text[]),
    ('AZ', 'AZN', 'tufandag-mountain-ridge-trail', 'gabala', 'NATURE', 0, 5, 'HOURS', 4.7, 'Горная тропа хребта Туфандаг', 'Tufandag Mountain Ridge Trail', 'Туфандаг тау жотасы соқпағы', 'Маршрут Габалы к горным склонам, лесным переходам и открытым видам Большого Кавказа для активного дня.', 'A Gabala route to mountain slopes, forest traverses and open Greater Caucasus views for an active day.', 'Габаладағы тау беткейлеріне, орман өткелдеріне және Үлкен Кавказдың ашық көріністеріне апаратын белсенді күн бағыты.', 40.97600000, 47.86500000, 'Tufandag Azerbaijan.jpg', ARRAY['gabala']::text[], ARRAY['gabala','baku']::text[], ARRAY['azerbaijan','gabala','caucasus','free-entry','trekking']::text[]),
    ('GE', 'GEL', 'likani-lomismta-trail', 'borjomi', 'NATURE', 0, 6, 'HOURS', 4.7, 'Тропа Ликани - Ломисмта', 'Likani to Lomismta Trail', 'Ликаниден Ломисмтаға соқпақ', 'Боржомский маршрут через лес, родники и затяжной подъем к высокому гребню для полноценного природного дня.', 'A Borjomi route through forest, springs and a sustained climb toward a high ridge for a full nature day.', 'Боржомидегі орман, бұлақтар және биік жотаға созылыңқы көтерілу арқылы өтетін толық табиғи күн бағыты.', 41.82300000, 43.33800000, 'Kutaisi,_Georgia.jpg', ARRAY['borjomi']::text[], ARRAY['borjomi','tbilisi']::text[], ARRAY['georgia','borjomi','forest','free-entry','trekking']::text[]),
    ('GR', 'EUR', 'samaria-gorge-trail', 'chania', 'NATURE', 5, 6, 'HOURS', 4.9, 'Тропа ущелья Самарья', 'Samaria Gorge Trail', 'Самарья шатқалы соқпағы', 'Критский маршрут из гор к морю через длинное известняковое ущелье, сосны, каменные стены и выход к южному побережью.', 'A Crete mountain-to-sea route through a long limestone gorge, pines, stone walls and an exit to the southern coast.', 'Криттегі таудан теңізге түсетін бағыт: ұзын әктас шатқал, қарағайлар, тас қабырғалар және оңтүстік жағалауға шығу.', 35.30700000, 23.96200000, 'Balos_Lagoon_Crete.jpg', ARRAY['chania']::text[], ARRAY['chania']::text[], ARRAY['greece','crete','gorge','trekking']::text[]),
    ('GR', 'EUR', 'santorini-fira-oia-caldera-walk', 'santorini', 'NATURE', 0, 4, 'HOURS', 4.8, 'Кальдерная прогулка Фира - Ия', 'Santorini Fira to Oia Caldera Walk', 'Санторини Фирадан Ияға кальдера серуені', 'Пешеходный маршрут Санторини по кромке кальдеры с белыми поселками, вулканическими склонами и морскими видами.', 'A Santorini walking route along the caldera rim with white villages, volcanic slopes and sea views.', 'Санторини кальдера жиегімен өтетін жаяу бағыт: ақ ауылдар, жанартаулық беткейлер және теңіз көріністері.', 36.42500000, 25.42800000, 'Santorini_Caldera_Greece.jpg', ARRAY['santorini']::text[], ARRAY['santorini']::text[], ARRAY['greece','santorini','caldera','free-entry','walking']::text[]),
    ('GR', 'EUR', 'meteora-monastery-ridge-walk', 'meteora', 'NATURE', 0, 3, 'HOURS', 4.8, 'Жотная прогулка Метеоры', 'Meteora Monastery Ridge Walk', 'Метеора монастырь жотасы серуені', 'Маршрут между скальными башнями Метеоры по тропам, смотровым точкам и тихим участкам над равниной Фессалии.', 'A route among Meteora rock towers across footpaths, viewpoints and quiet sections above the Thessaly plain.', 'Метеора жартас мұнаралары арасындағы соқпақтар, көрініс нүктелері және Фессалия жазығы үстіндегі тыныш бөліктер арқылы өтетін бағыт.', 39.72100000, 21.63100000, 'Meteora_Monasteries_Greece.jpg', ARRAY['meteora']::text[], ARRAY['meteora','thessaloniki']::text[], ARRAY['greece','meteora','ridge','free-entry','walking']::text[]),
    ('ES', 'EUR', 'montserrat-sant-jeroni-trail', 'montserrat', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа Сан-Жерони в Монсеррате', 'Montserrat Sant Jeroni Trail', 'Монсеррат Сан-Жерони соқпағы', 'Каталонский маршрут по скальным иглам Монсеррата к высшей обзорной точке, лесным переходам и панораме предгорий.', 'A Catalonia route through Montserrat rock needles toward the highest viewpoint, forest traverses and foothill panorama.', 'Каталониядағы Монсеррат жартас инелері арқылы ең биік көрініс нүктесіне, орман өткелдеріне және тау етегі панорамасына апаратын бағыт.', 41.59400000, 1.81200000, 'Sagrada_Familia_01.jpg', ARRAY['montserrat']::text[], ARRAY['barcelona','montserrat']::text[], ARRAY['spain','catalonia','summit','free-entry','trekking']::text[]),
    ('IT', 'EUR', 'busatte-tempesta-trail', 'lake-garda', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа Бузатте - Темпеста', 'Busatte Tempesta Trail', 'Бузатте - Темпеста соқпағы', 'Маршрут озера Гарда по склонам и металлическим лестницам с видами на воду, скалы и северную часть озера.', 'A Lake Garda route across slopes and metal stairways with views of water, cliffs and the northern lake.', 'Гарда көліндегі беткейлер мен металл баспалдақтар арқылы өтетін бағыт, суға, жартастарға және көлдің солтүстігіне көріністер береді.', 45.86800000, 10.87500000, 'Milan_Cathedral_from_Piazza_del_Duomo.jpg', ARRAY['lake-garda']::text[], ARRAY['lake-garda','verona']::text[], ARRAY['italy','lake-garda','lake-view','free-entry','walking']::text[]),
    ('IT', 'EUR', 'greenway-del-lago-di-como-walk', 'lake-como', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка Greenway del Lago di Como', 'Greenway del Lago di Como Walk', 'Комо көлі Greenway серуені', 'Итальянская озерная прогулка через деревни, виллы, сады и береговые виды западной стороны Комо.', 'An Italian lake walk through villages, villas, gardens and shoreline views on the western side of Como.', 'Комоның батыс жағындағы ауылдар, виллалар, бақтар және жағалау көріністері арқылы өтетін италиялық көл серуені.', 45.98500000, 9.20700000, 'Milan_Cathedral_from_Piazza_del_Duomo.jpg', ARRAY['lake-como']::text[], ARRAY['lake-como','milan']::text[], ARRAY['italy','lake-como','villages','free-entry','walking']::text[]),
    ('PT', 'EUR', 'arrabida-coastal-ridge-trail', 'setubal', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прибрежная тропа хребта Аррабида', 'Arrabida Coastal Ridge Trail', 'Аррабида жағалау жотасы соқпағы', 'Маршрут у Сетубала по известняковым склонам, средиземноморской зелени и видам на Атлантику и бухты.', 'A Setubal-area route across limestone slopes, Mediterranean greenery and views of the Atlantic and coves.', 'Сетубал маңындағы әктас беткейлер, жерортатеңіздік жасылдық және Атлант пен қойнауларға көріністер арқылы өтетін бағыт.', 38.48400000, -8.98500000, 'PRAIA_DE_GALAPOS_ARRABIDA.jpg', ARRAY['setubal']::text[], ARRAY['setubal','lisbon']::text[], ARRAY['portugal','setubal','coastal-ridge','free-entry','hiking']::text[]),
    ('TR', 'TRY', 'belgrad-forest-neset-suyu-trail', 'istanbul', 'NATURE', 0, 3, 'HOURS', 4.5, 'Тропа Нешет-Сую в Белградском лесу', 'Belgrad Forest Neset Suyu Trail', 'Белград орманы Нешет-Сую соқпағы', 'Лесной маршрут Стамбула по тенистым дорожкам, водоемам и мягкому рельефу для активного отдыха без выезда далеко из города.', 'An Istanbul forest route along shaded paths, reservoirs and gentle terrain for active time without leaving the city far behind.', 'Стамбұлдағы көлеңкелі жолдар, су айдындары және қала сыртына ұзақ шықпай белсенді демалуға арналған жұмсақ бедерлі орман бағыты.', 41.18400000, 28.98600000, 'Gulhane_Park.jpg', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], ARRAY['turkey','istanbul','forest','free-entry','walking']::text[]),
    ('EG', 'EGP', 'wadi-degla-canyon-trail', 'cairo', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа каньона Вади-Дегла', 'Wadi Degla Canyon Trail', 'Уади Дегла каньоны соқпағы', 'Каменистый маршрут на окраине Каира по сухому руслу, известняковым стенам и пустынному свету для короткого outdoor-дня.', 'A rocky route on the edge of Cairo through a dry wadi, limestone walls and desert light for a short outdoor day.', 'Каир шетіндегі құрғақ уади, әктас қабырғалар және қысқа outdoor күнге арналған шөл жарығы арқылы өтетін тасты бағыт.', 29.97400000, 31.34500000, 'Al-Azhar_Park.jpg', ARRAY['cairo']::text[], ARRAY['cairo']::text[], ARRAY['egypt','cairo','wadi','free-entry','hiking']::text[]),
    ('RS', 'RSD', 'fruska-gora-iriski-venac-trail', 'fruska-gora', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа Иришки-Венац на Фрушка-Горе', 'Fruska Gora Iriski Venac Trail', 'Фрушка-Гора Иришки-Венац соқпағы', 'Сербский лесной маршрут по мягким гребням, монастырским дорогам и зеленым участкам над равниной Воеводины.', 'A Serbian forest route over gentle ridges, monastery roads and green sections above the Vojvodina plain.', 'Сербиядағы жұмсақ жоталар, монастырь жолдары және Воеводина жазығы үстіндегі жасыл бөліктер арқылы өтетін орман бағыты.', 45.16000000, 19.85300000, 'Fruska_Gora_National_Park.jpg', ARRAY['fruska-gora']::text[], ARRAY['novi-sad','fruska-gora','belgrade']::text[], ARRAY['serbia','fruska-gora','forest','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_europe_middle_east_city_hub_outdoor_routes_resolved_places AS
SELECT
    ('113d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['europe-middle-east-city-hub-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_europe_middle_east_city_hub_outdoor_routes_places;

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
FROM seed_europe_middle_east_city_hub_outdoor_routes_resolved_places
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
FROM seed_europe_middle_east_city_hub_outdoor_routes_resolved_places
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
FROM seed_europe_middle_east_city_hub_outdoor_routes_resolved_places
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
FROM seed_europe_middle_east_city_hub_outdoor_routes_resolved_places
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
FROM seed_europe_middle_east_city_hub_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_europe_middle_east_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_europe_middle_east_city_hub_outdoor_routes_places;
