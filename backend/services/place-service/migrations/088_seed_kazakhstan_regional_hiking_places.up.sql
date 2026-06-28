-- Additional regional Kazakhstan hiking/day-hike places.
-- This layer strengthens city hubs that previously had mostly urban, culture or broad national-place coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_regional_hiking_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_regional_hiking_places;

CREATE TEMP TABLE seed_kazakhstan_regional_hiking_places (
    slug varchar(96) PRIMARY KEY,
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
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_kazakhstan_regional_hiking_places (
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
    (
        'kargaly-reservoir-shore-trail',
        'aktobe',
        'NATURE',
        0,
        4,
        'HOURS',
        4.5,
        'Береговая тропа Каргалинского водохранилища',
        'Kargaly Reservoir Shore Trail',
        'Қарғалы су қоймасы жағалауы соқпағы',
        'Спокойный маршрут у крупнейшего водохранилища рядом с Актобе: открытая степь, вода, ветреные берега и формат короткого выезда за город.',
        'A calm route by the largest reservoir near Aktobe, with open steppe, water, windy shores and an easy short escape from the city.',
        'Ақтөбе маңындағы ең ірі су қоймасы жанындағы тыныш бағыт: ашық дала, су, желді жағалау және қаладан қысқа шығуға ыңғайлы формат.',
        50.44500000,
        57.62000000,
        'Sunset in Korgalzhyn Nature Reserve.jpg',
        ARRAY['aktobe']::text[],
        ARRAY['aktobe']::text[],
        ARRAY['kazakhstan','aktobe-region','reservoir','steppe','free-entry','day-hike']::text[]
    ),
    (
        'aksu-zhabagly-foothill-trail',
        'taraz',
        'NATURE',
        1000,
        7,
        'HOURS',
        4.8,
        'Предгорная тропа Аксу-Жабаглы',
        'Aksu-Zhabagly Foothill Trail',
        'Ақсу-Жабағылы тау етегі соқпағы',
        'Дневной маршрут из Тараза к западному Тянь-Шаню: можжевеловые склоны, весенние тюльпаны, виды на предгорья и ощущение старейшего заповедника региона.',
        'A day route from Taraz toward the Western Tian Shan with juniper slopes, spring tulips, foothill views and the atmosphere of the region oldest reserve.',
        'Тараздан Батыс Тянь-Шаньға бағытталған күндік маршрут: аршалы беткейлер, көктемгі қызғалдақтар, тау етегі көріністері және өңірдегі ең көне қорықтың әсері.',
        42.41600000,
        70.47600000,
        'Aksu-Zhabagly Nature Reserve.jpg',
        ARRAY['taraz']::text[],
        ARRAY['taraz','shymkent']::text[],
        ARRAY['kazakhstan','zhambyl-region','western-tian-shan','reserve','trekking']::text[]
    ),
    (
        'semey-pine-belt-trail',
        'semey',
        'NATURE',
        0,
        4,
        'HOURS',
        4.5,
        'Тропа ленточного бора Семея',
        'Semey Pine Belt Trail',
        'Семей қарағайлы белдеуі соқпағы',
        'Легкий природный маршрут вокруг Семея среди сосновых участков Прииртышья, песчаных почв и спокойных троп для прогулки без сложного рельефа.',
        'An easy nature route around Semey through Irtysh-side pine sections, sandy soil and calm paths without difficult elevation.',
        'Семей маңындағы Ертіс бойы қарағайлы бөліктері, құмды топырақ және күрделі биіктіксіз тыныш жолдар арқылы өтетін жеңіл табиғи бағыт.',
        50.42600000,
        80.26700000,
        'Beautiful view of the mountains (Katon-Karagay).jpg',
        ARRAY['semey']::text[],
        ARRAY['semey']::text[],
        ARRAY['kazakhstan','abai-region','irtysh','pine-forest','free-entry','walking']::text[]
    ),
    (
        'akzhaiyk-delta-eco-trail',
        'atyrau',
        'NATURE',
        0,
        3,
        'HOURS',
        4.5,
        'Экотропа дельты Акжайык',
        'Akzhaiyk Delta Eco Trail',
        'Ақжайық атырауы экосоқпағы',
        'Природный маршрут у Атырау по пойменным ландшафтам Урала и каспийской дельты, где хорошо работают наблюдение за птицами и неспешная прогулка у воды.',
        'A nature route near Atyrau through Ural River floodplain and Caspian delta landscapes, well suited for birdwatching and an unhurried walk by the water.',
        'Атырау маңындағы Жайық жайылмасы мен Каспий атырауы ландшафттары арқылы өтетін табиғи бағыт, құстарды бақылауға және су бойындағы жай серуенге ыңғайлы.',
        47.05000000,
        51.90000000,
        'Atyrau footbridge across Ural River.jpg',
        ARRAY['atyrau']::text[],
        ARRAY['atyrau']::text[],
        ARRAY['kazakhstan','atyrau-region','ural-river','delta','birdwatching','free-entry']::text[]
    ),
    (
        'naurzum-pine-and-lake-trail',
        'kostanay',
        'NATURE',
        1000,
        7,
        'HOURS',
        4.7,
        'Тропа сосен и озер Наурзума',
        'Naurzum Pine and Lake Trail',
        'Наурызым қарағайы мен көлдері соқпағы',
        'Маршрут из Костаная к степным озерам и южным сосновым борам Наурзума, где можно увидеть редкий для степи контраст леса, воды и открытого горизонта.',
        'A route from Kostanay to Naurzum steppe lakes and southern pine groves, showing the rare steppe contrast of forest, water and open horizon.',
        'Қостанайдан Наурызымның дала көлдері мен оңтүстіктегі қарағайлы ормандарына апаратын бағыт, орман, су және ашық көкжиектің далаға тән сирек үйлесімін көрсетеді.',
        51.48000000,
        64.36000000,
        'Sunset in Korgalzhyn Nature Reserve.jpg',
        ARRAY['kostanay']::text[],
        ARRAY['kostanay']::text[],
        ARRAY['kazakhstan','kostanay-region','naurzum','unesco','lakes','forest','hiking']::text[]
    ),
    (
        'kamyslybas-lake-shore-trail',
        'kyzylorda',
        'NATURE',
        0,
        4,
        'HOURS',
        4.4,
        'Береговая тропа озера Камыстыбас',
        'Kamyslybas Lake Shore Trail',
        'Қамыстыбас көлі жағалауы соқпағы',
        'Маршрут из Кызылорды к озерной системе у Арала: камыши, рыбацкие берега, степной воздух и мягкий формат природной остановки по дороге к северному Приаралью.',
        'A route from Kyzylorda to the lake system near the Aral area, with reeds, fishing shores, steppe air and a gentle nature stop toward the northern Aral region.',
        'Қызылордадан Арал маңындағы көлдер жүйесіне баратын бағыт: қамыс, балықшылар жағалауы, дала ауасы және Солтүстік Арал өңіріне барар жолдағы жеңіл табиғи аялдама.',
        46.16000000,
        61.93000000,
        'Balkhash lake, september 2020.jpg',
        ARRAY['kyzylorda']::text[],
        ARRAY['kyzylorda','aral-sea']::text[],
        ARRAY['kazakhstan','kyzylorda-region','kamyslybas','lake','free-entry','birdwatching']::text[]
    ),
    (
        'ural-river-floodplain-trail',
        'oral',
        'NATURE',
        0,
        3,
        'HOURS',
        4.5,
        'Пойменная тропа реки Урал',
        'Ural River Floodplain Trail',
        'Жайық өзені жайылмасы соқпағы',
        'Зеленый маршрут в Орале вдоль пойменных участков Урала с ивами, речными видами и спокойным сценарием для короткой прогулки на природе.',
        'A green route in Oral along Ural River floodplain sections with willows, river views and a calm plan for a short nature walk.',
        'Оралдағы Жайық өзенінің жайылма бөліктерімен өтетін жасыл бағыт: талдар, өзен көріністері және табиғаттағы қысқа серуенге арналған тыныш сценарий.',
        51.22000000,
        51.37000000,
        'Atyrau footbridge across Ural River.jpg',
        ARRAY['oral']::text[],
        ARRAY['oral']::text[],
        ARRAY['kazakhstan','west-kazakhstan','ural-river','city-nature','free-entry','walking']::text[]
    ),
    (
        'karatau-foothill-trail',
        'turkestan',
        'NATURE',
        1000,
        6,
        'HOURS',
        4.6,
        'Предгорная тропа Каратау',
        'Karatau Foothill Trail',
        'Қаратау тау етегі соқпағы',
        'Маршрут из Туркестана к сухим предгорьям Каратау с каменистыми склонами, весенними растениями и контрастом пустыни и низких гор.',
        'A route from Turkestan to the dry Karatau foothills, with rocky slopes, spring plants and the contrast between desert and low mountains.',
        'Түркістаннан Қаратаудың құрғақ тау етегіне апаратын бағыт: тасты беткейлер, көктемгі өсімдіктер және шөл мен аласа таудың қарама-қайшылығы.',
        43.65000000,
        68.69000000,
        'Aksu-Zhabagly Nature Reserve.jpg',
        ARRAY['turkestan']::text[],
        ARRAY['turkestan','shymkent']::text[],
        ARRAY['kazakhstan','turkestan-region','karatau','foothills','hiking']::text[]
    ),
    (
        'ulytau-akmeshit-ridge-trail',
        'zhezkazgan',
        'NATURE',
        0,
        6,
        'HOURS',
        4.7,
        'Тропа хребта Акмешит в Улытау',
        'Ulytau Akmeshit Ridge Trail',
        'Ұлытау Ақмешіт жотасы соқпағы',
        'Активный маршрут из Жезказгана к гранитным склонам Улытау, где природный поход легко соединяется с историей Великой степи и панорамами Сарыарки.',
        'An active route from Zhezkazgan to Ulytau granite slopes, where a nature hike connects naturally with Great Steppe history and Saryarka panoramas.',
        'Жезқазғаннан Ұлытаудың гранитті беткейлеріне апаратын белсенді бағыт, мұнда табиғи жорық Ұлы дала тарихымен және Сарыарқа панорамаларымен үйлеседі.',
        48.65500000,
        66.99000000,
        'Dzhuchi khan mausoleum.jpg',
        ARRAY['zhezkazgan']::text[],
        ARRAY['zhezkazgan']::text[],
        ARRAY['kazakhstan','ulytau','saryarka','ridge','free-entry','hiking']::text[]
    );

CREATE TEMP TABLE seed_kazakhstan_regional_hiking_resolved_places AS
SELECT
    ('88ad0000-0000-4000-8000-' || substr(md5(slug), 1, 12))::uuid AS id,
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
        substr(md5(slug || ':media'), 1, 8) || '-' ||
        substr(md5(slug || ':media'), 9, 4) || '-4' ||
        substr(md5(slug || ':media'), 14, 3) || '-8' ||
        substr(md5(slug || ':media'), 18, 3) || '-' ||
        substr(md5(slug || ':media'), 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(media_file, ' ', '%20') || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || replace(media_file, ' ', '_') AS media_source_url,
    ARRAY['kazakhstan-regional-hiking-v1', 'KZ', 'kz', city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_regional_hiking_places;

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
    'KZ',
    city_id,
    category,
    price_amount,
    'KZT',
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
FROM seed_kazakhstan_regional_hiking_resolved_places
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
FROM seed_kazakhstan_regional_hiking_resolved_places
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
FROM seed_kazakhstan_regional_hiking_resolved_places
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
FROM seed_kazakhstan_regional_hiking_resolved_places
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
FROM seed_kazakhstan_regional_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
