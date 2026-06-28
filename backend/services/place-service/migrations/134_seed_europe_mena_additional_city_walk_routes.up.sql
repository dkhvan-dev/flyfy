-- Additional Europe and MENA city-walk route seed.
-- Adds non-duplicate urban nature routes suggested by regional duplicate review.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_europe_mena_additional_city_walk_routes_resolved_places;
DROP TABLE IF EXISTS seed_europe_mena_additional_city_walk_routes;

CREATE TEMP TABLE seed_europe_mena_additional_city_walk_routes (
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

INSERT INTO seed_europe_mena_additional_city_walk_routes (
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
    ('FR', 'EUR', 'coulee-verte-rene-dumont-walk', 'paris', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка Coulée Verte René-Dumont', 'Coulee Verte Rene-Dumont Walk', 'Coulée Verte René-Dumont серуені', 'Зеленый линейный маршрут Парижа по бывшей железной дороге с виадуками, садами и спокойным городским ритмом вдали от главных парков.', 'A Paris linear green route on a former railway with viaducts, gardens and a calm city rhythm away from the main park cards.', 'Париждегі бұрынғы теміржол бойымен өтетін жасыл сызықтық бағыт: виадуктар, бақтар және негізгі парк карточкаларынан бөлек тыныш қалалық ырғақ.', 48.84400000, 2.38600000, 'Jardin du Luxembourg Paris.jpg', ARRAY['paris']::text[], ARRAY['paris']::text[], ARRAY['france','paris','linear-park','free-entry','walking']::text[]),
    ('GB', 'GBP', 'parkland-walk', 'london', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка Parkland Walk', 'Parkland Walk', 'Parkland Walk серуені', 'Северолондонский зеленый маршрут по бывшей железнодорожной линии, лесным коридорам и тихим квартальным участкам, отдельный от Гайд-парка.', 'A north London green route along a former railway, wooded corridors and quiet neighbourhood sections, distinct from Hyde Park.', 'Солтүстік Лондондағы бұрынғы теміржол, орманды дәліздер және тыныш кварталдар арқылы өтетін, Гайд-парктен бөлек жасыл бағыт.', 51.57600000, -0.13000000, 'Hyde Park London.jpg', ARRAY['london']::text[], ARRAY['london']::text[], ARRAY['united-kingdom','london','railway-walk','free-entry','walking']::text[]),
    ('DE', 'EUR', 'havelhoehenweg-grunewald-trail', 'berlin', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа Havelhöhenweg в Груневальде', 'Havelhoehenweg Grunewald Trail', 'Груневальдтағы Havelhoehenweg соқпағы', 'Берлинский лесной маршрут вдоль высоких берегов Хафеля, сосен и озерных видов, не повторяющий городскую карточку Тиргартена.', 'A Berlin forest route along the high Havel banks, pines and lake views, not duplicating the Tiergarten city park card.', 'Берлиндегі Хафельдің биік жағалары, қарағайлар және көл көріністері арқылы өтетін, Тиргартен қалалық паркін қайталамайтын орман бағыты.', 52.47500000, 13.18500000, 'Brandenburger_Tor_morgens.jpg', ARRAY['berlin']::text[], ARRAY['berlin']::text[], ARRAY['germany','berlin','grunewald','havel','free-entry','hiking']::text[]),
    ('ES', 'EUR', 'carretera-de-les-aigues-walk', 'barcelona', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прогулка Carretera de les Aigües', 'Carretera de les Aigues Walk', 'Carretera de les Aigues серуені', 'Панорамный маршрут Барселоны по склонам Кольсеролы с видом на город и море, отдельный от парка Гуэль и городских достопримечательностей.', 'A Barcelona panoramic route along the Collserola slopes with city and sea views, separate from Park Guell and city landmark cards.', 'Барселонадағы Кольсерола беткейлері бойымен қала мен теңіз көріністерін ашатын, Гуэль паркі мен қалалық орындардан бөлек панорамалық бағыт.', 41.41400000, 2.10000000, 'Sagrada_Familia_01.jpg', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], ARRAY['spain','barcelona','collserola','panorama','free-entry','walking']::text[]),
    ('CZ', 'CZK', 'divoka-sarka-valley-trail', 'prague', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа долины Дивока Шарка', 'Divoka Sarka Valley Trail', 'Дивока Шарка аңғары соқпағы', 'Пражский природный маршрут по скалам, лесу и ручью Дивока Шарка, добавляющий outdoor-сценарий за пределами исторического центра.', 'A Prague nature route through Divoka Sarka rocks, forest and stream, adding an outdoor scenario beyond the historic centre.', 'Прагадағы Дивока Шарканың жартастары, орманы және бұлағы арқылы өтетін, тарихи орталықтан тыс outdoor сценарий қосатын бағыт.', 50.10400000, 14.31900000, 'Petrin Tower Prague.jpg', ARRAY['prague']::text[], ARRAY['prague']::text[], ARRAY['czechia','prague','valley','rocks','free-entry','hiking']::text[]),
    ('PT', 'EUR', 'monsanto-forest-park-loop', 'lisbon', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная петля парка Монсанту', 'Monsanto Forest Park Loop', 'Монсанту орман паркі ілмегі', 'Городской лесной маршрут Лиссабона по Монсанту с тенистыми тропами, холмами и видами на город, отдельный от исторических карточек Белена.', 'A Lisbon urban forest route through Monsanto with shaded paths, hills and city views, separate from Belem historic cards.', 'Лиссабондағы Монсанту арқылы өтетін қалалық орман бағыты: көлеңкелі соқпақтар, төбелер және Белен тарихи карточкаларынан бөлек қала көріністері.', 38.73100000, -9.19400000, 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], ARRAY['portugal','lisbon','monsanto','urban-forest','free-entry','walking']::text[]),
    ('AE', 'AED', 'palm-jumeirah-boardwalk', 'dubai', 'NATURE', 0, 2, 'HOURS', 4.5, 'Настил Palm Jumeirah', 'Palm Jumeirah Boardwalk', 'Palm Jumeirah тақтайжолы', 'Прогулочный маршрут Дубая по внешнему кольцу Palm Jumeirah с морским видом, городским силуэтом и простым форматом без пляжной карточки.', 'A Dubai walking route along the outer Palm Jumeirah crescent with sea views, skyline and an easy format without duplicating beach cards.', 'Дубайдағы Palm Jumeirah сыртқы айы бойымен өтетін теңіз көрінісі, қала силуэті және жағажай карточкаларын қайталамайтын жеңіл серуен.', 25.12900000, 55.11300000, 'Atlantis_The_Palm_Dubai.jpg', ARRAY['dubai']::text[], ARRAY['dubai']::text[], ARRAY['uae','dubai','palm-jumeirah','boardwalk','free-entry','walking']::text[]),
    ('NL', 'EUR', 'amsterdamse-bos-walking-loop', 'amsterdam', 'NATURE', 0, 3, 'HOURS', 4.6, 'Пешеходная петля Amsterdamse Bos', 'Amsterdamse Bos Walking Loop', 'Amsterdamse Bos жаяу ілмегі', 'Большая зеленая петля Амстердама по лесу, воде и луговым участкам, отдельная от музейного центра и городских каналов.', 'A large Amsterdam green loop through forest, water and meadow sections, distinct from museum-centre and canal cards.', 'Амстердамдағы орман, су және шалғын бөліктері арқылы өтетін, музей орталығы мен канал карточкаларынан бөлек үлкен жасыл ілмек.', 52.31200000, 4.82400000, 'Rijksmuseum Amsterdam.jpg', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], ARRAY['netherlands','amsterdam','forest','free-entry','walking']::text[]),
    ('FI', 'EUR', 'paloheina-central-park-trail', 'helsinki', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа Пало-хейна в Центральном парке', 'Paloheina Central Park Trail', 'Пало-хейна орталық парк соқпағы', 'Северный зеленый маршрут Хельсинки по лесным дорожкам Центрального парка, подходящий для прогулки или легкого хайкинга без выезда из города.', 'A northern Helsinki green route through Central Park forest paths, suitable for a walk or light hike without leaving the city.', 'Хельсинкидің солтүстігіндегі Орталық парк орман жолдары арқылы өтетін, қаладан шықпай серуендеуге немесе жеңіл хайкингке ыңғайлы жасыл бағыт.', 60.25300000, 24.92200000, 'Esplanadi_Park_Helsinki.jpg', ARRAY['helsinki']::text[], ARRAY['helsinki']::text[], ARRAY['finland','helsinki','central-park','forest','free-entry','walking']::text[]),
    ('SE', 'SEK', 'nackareservatet-hellasgarden-loop', 'stockholm', 'NATURE', 0, 3, 'HOURS', 4.7, 'Петля Nackareservatet у Hellasgården', 'Nackareservatet Hellasgarden Loop', 'Nackareservatet Hellasgarden ілмегі', 'Стокгольмский маршрут по заповеднику Nackareservatet: озера, хвойный лес и скальные участки рядом с Hellasgården.', 'A Stockholm route through Nackareservatet reserve with lakes, conifer forest and rocky sections near Hellasgarden.', 'Стокгольмдегі Nackareservatet қорығы арқылы өтетін бағыт: көлдер, қылқанжапырақты орман және Hellasgarden маңындағы жартасты бөліктер.', 59.28900000, 18.15800000, 'Långholmen Stockholm 2006.jpg', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], ARRAY['sweden','stockholm','nackareservatet','lake','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_europe_mena_additional_city_walk_routes_resolved_places AS
SELECT
    ('134d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['europe-mena-additional-city-walk-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_europe_mena_additional_city_walk_routes;

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
FROM seed_europe_mena_additional_city_walk_routes_resolved_places
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
FROM seed_europe_mena_additional_city_walk_routes_resolved_places
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
FROM seed_europe_mena_additional_city_walk_routes_resolved_places
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
FROM seed_europe_mena_additional_city_walk_routes_resolved_places
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
FROM seed_europe_mena_additional_city_walk_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_europe_mena_additional_city_walk_routes_resolved_places;
DROP TABLE IF EXISTS seed_europe_mena_additional_city_walk_routes;
