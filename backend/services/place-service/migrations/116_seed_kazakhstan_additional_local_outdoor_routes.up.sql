-- Additional local Kazakhstan route-level outdoor/hiking seed.
-- Adds useful non-duplicate trails, lake walks, steppe walks and ridge routes after the deeper Kazakhstan layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_additional_local_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_local_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_additional_local_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_additional_local_outdoor_routes_places (
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
    ('KZ', 'KZT', 'kokbulak-forest-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Лесная тропа Кокбулака', 'Kokbulak Forest Trail', 'Көкбұлақ орман соқпағы', 'Короткий горный маршрут в талгарской стороне предгорий с лесом, ручьями и мягким набором высоты для спокойного выезда из Алматы.', 'A short mountain route on the Talgar side of the foothills with forest, streams and gentle elevation gain for an easy escape from Almaty.', 'Алматыдан жеңіл шығуға арналған Талғар жақ беткейлеріндегі қысқа тау бағыты: орман, бұлақтар және жұмсақ биіктік жинау.', 43.25500000, 77.18800000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','talgar-side','forest','hiking']::text[]),
    ('KZ', 'KZT', 'panorama-peak-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.8, 'Тропа на пик Панорама', 'Panorama Peak Trail', 'Панорама шыңы соқпағы', 'Высотный маршрут над Медеу и Шымбулаком к открытому гребню, где хорошо видны городская чаша и снежные линии Заилийского Алатау.', 'A high route above Medeu and Shymbulak toward an open ridge with strong views of the city bowl and snowy Trans-Ili Alatau lines.', 'Медеу мен Шымбұлақ үстіндегі ашық жотаға апаратын биіктау бағыты, қала аңғары мен Іле Алатауының қарлы сызықтары жақсы көрінеді.', 43.09600000, 77.09200000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','summit','ridge','trekking']::text[]),
    ('KZ', 'KZT', 'besshatyr-mounds-steppe-walk', 'taldykorgan', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Степная прогулка курганов Бесшатыр', 'Besshatyr Mounds Steppe Walk', 'Бесшатыр қорғандары дала серуені', 'Маршрут Алтын-Эмеля по открытой степи, древним сакским курганам и сухим холмам для легкого природно-исторического сценария.', 'An Altyn-Emel route across open steppe, ancient Saka mounds and dry hills for an easy nature-and-history plan.', 'Алтын-Емелдегі ашық дала, көне сақ қорғандары және құрғақ төбелер арқылы өтетін жеңіл табиғи-тарихи бағыт.', 43.92200000, 78.20500000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan','almaty']::text[], ARRAY['taldykorgan','almaty']::text[], ARRAY['kazakhstan','altyn-emel','steppe','heritage','walking']::text[]),
    ('KZ', 'KZT', 'tuzkol-salt-lake-shore-walk', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.7, 'Береговая прогулка соленого озера Тузколь', 'Tuzkol Salt Lake Shore Walk', 'Тұзкөл тұзды көлі жағалау серуені', 'Маршрут Кегенской стороны к соленому озеру, сухой степи и открытым видам на хребты, особенно сильный на рассвете и закате.', 'A Kegen-side route to a salt lake, dry steppe and open mountain views, especially strong at sunrise and sunset.', 'Кеген жақтағы тұзды көлге, құрғақ далаға және тауларға ашық көрініске апаратын бағыт, таң мен күн батарда ерекше әсерлі.', 42.44100000, 79.90600000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','kegen','salt-lake','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'koksu-river-gorge-trail', 'taldykorgan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья реки Коксу', 'Koksu River Gorge Trail', 'Көксу өзені шатқалы соқпағы', 'Жетысуский маршрут вдоль горной реки, зеленых склонов и каменных участков для дневного выхода из Талдыкоргана.', 'A Zhetysu route along a mountain river, green slopes and rocky sections for a day trip from Taldykorgan.', 'Талдықорғаннан күндік шығуға арналған Жетісу бағыты: тау өзені, жасыл беткейлер және тасты бөліктер.', 44.94500000, 78.53600000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','river-gorge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'tarbagatai-manrak-ridge-trail', 'semey', 'NATURE', 0, 6, 'HOURS', 4.6, 'Тропа хребта Манырак в Тарбагатае', 'Tarbagatai Manrak Ridge Trail', 'Тарбағатай Маңырақ жотасы соқпағы', 'Восточноказахстанский маршрут по сухим гребням, степным склонам и длинным видам Тарбагатайского пояса.', 'An eastern Kazakhstan route across dry ridges, steppe slopes and long views of the Tarbagatai belt.', 'Шығыс Қазақстандағы құрғақ жоталар, дала беткейлері және Тарбағатай белдеуінің ұзақ көріністері арқылы өтетін бағыт.', 47.54800000, 81.13500000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','tarbagatai','ridge','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'imantau-lake-hills-trail', 'kokshetau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа холмов озера Имантау', 'Imantau Lake Hills Trail', 'Имантау көлі төбелері соқпағы', 'Северный маршрут по лесистым холмам и береговым видам Имантау, добавляющий к Бурабаю более тихий озерный сценарий.', 'A northern route across forested hills and Imantau lake views, adding a quieter lake scenario beyond Burabay.', 'Бурабайдан бөлек тынышырақ көл сценарийін қосатын солтүстік бағыт: орманды төбелер және Имантау көліне көріністер.', 53.25000000, 68.38000000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kazakhstan','north-kazakhstan','imantau','lake','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'donyztau-escarpment-walk', 'aktobe', 'NATURE', 0, 5, 'HOURS', 4.6, 'Прогулка уступов Донызтау', 'Donyztau Escarpment Walk', 'Донызтау кертпештері серуені', 'Западноказахстанский маршрут по сухим уступам, меловым формам и широкому пустынному горизонту между Актобе и Прикаспием.', 'A western Kazakhstan route across dry escarpments, chalk forms and a wide desert horizon between Aktobe and the Caspian steppe.', 'Ақтөбе мен Каспий маңы даласы арасындағы құрғақ кертпештер, борлы пішіндер және кең шөл көкжиегі арқылы өтетін бағыт.', 47.92000000, 56.12000000, 'Sherkala_Mountain.jpg', ARRAY['aktobe','atyrau']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','west-kazakhstan','escarpment','free-entry','geotrail','hiking']::text[]),
    ('KZ', 'KZT', 'kamystybas-lake-shore-trail', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая тропа озера Камыстыбас', 'Kamystybas Lake Shore Trail', 'Қамыстыбас көлі жағалау соқпағы', 'Приаральская прогулка у воды, камышей и песчаных берегов, удобная как мягкая природная остановка из Кызылорды.', 'An Aral-side walk by water, reeds and sandy shores, useful as a gentle nature stop from Kyzylorda.', 'Қызылордадан шығатын жұмсақ табиғи аялдамаға ыңғайлы Арал маңы серуені: су, қамыс және құмды жағалар.', 46.06400000, 61.85800000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','aral-region','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kaskasu-juniper-trail', 'shymkent', 'NATURE', 0, 5, 'HOURS', 4.6, 'Арчовая тропа Каскасу', 'Kaskasu Juniper Trail', 'Қасқасу аршалы соқпағы', 'Маршрут западного Тянь-Шаня к арчовым склонам, пастбищам и прохладным предгорным видам для активного дня из Шымкента.', 'A Western Tian Shan route to juniper slopes, pastures and cool foothill views for an active day from Shymkent.', 'Шымкенттен белсенді күнге арналған Батыс Тянь-Шань бағыты: аршалы беткейлер, жайылымдар және салқын тау етегі көріністері.', 42.29200000, 70.43800000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','western-tian-shan','juniper','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'daubaba-canyon-trail', 'taraz', 'NATURE', 0, 5, 'HOURS', 4.5, 'Тропа каньона Даубаба', 'Daubaba Canyon Trail', 'Дәубаба каньоны соқпағы', 'Южный маршрут через сухие стенки каньона, ручейные участки и предгорный рельеф для спокойного выезда из Тараза или Шымкента.', 'A southern route through dry canyon walls, stream sections and foothill terrain for a calm outing from Taraz or Shymkent.', 'Тараздан не Шымкенттен тыныш шығуға арналған оңтүстік бағыт: құрғақ каньон қабырғалары, бұлақ бөліктері және тау етегі бедері.', 42.54800000, 70.04500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz','shymkent']::text[], ARRAY['taraz','shymkent']::text[], ARRAY['kazakhstan','south-kazakhstan','canyon','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'irgiz-turgay-steppe-walk', 'aktobe', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная прогулка Иргиз-Тургая', 'Irgiz-Turgay Steppe Walk', 'Ырғыз-Торғай дала серуені', 'Маршрут по открытой степи, сезонным водоемам и птицам Иргиз-Тургайской системы для спокойного природного сценария Западного Казахстана.', 'A route across open steppe, seasonal water and birdlife of the Irgiz-Turgay system for a calm western Kazakhstan nature plan.', 'Батыс Қазақстандағы тыныш табиғи сценарийге арналған Ырғыз-Торғай жүйесінің ашық даласы, маусымдық сулары және құстары арқылы өтетін бағыт.', 48.61600000, 61.26500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe','kostanay']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','steppe','birdwatching','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'mynaral-balkhash-shore-walk', 'balkhash', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка Мынарала на Балхаше', 'Mynaral Balkhash Shore Walk', 'Мынарал Балқаш жағалауы серуені', 'Центральноказахстанский маршрут у открытого берега Балхаша с ветром, водой и спокойной остановкой на длинном дорожном пути.', 'A central Kazakhstan route by the open Balkhash shore with wind, water and a calm stop on a long road trip.', 'Орталық Қазақстандағы Балқаштың ашық жағалауымен өтетін бағыт: жел, су және ұзақ жолдағы тыныш аялдама.', 46.86000000, 73.25000000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash']::text[], ARRAY['balkhash','karaganda']::text[], ARRAY['kazakhstan','balkhash','lake-shore','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_additional_local_outdoor_routes_resolved_places AS
SELECT
    ('116d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-additional-local-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_additional_local_outdoor_routes_places;

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
FROM seed_kazakhstan_additional_local_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_local_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_local_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_local_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_local_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_additional_local_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_local_outdoor_routes_places;
