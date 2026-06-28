-- Last hidden Kazakhstan outdoor route seed.
-- Adds non-duplicate hiking and walking places around existing Kazakhstan city hubs.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_last_hidden_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_hidden_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_last_hidden_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_last_hidden_outdoor_routes_places (
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
    ('KZ', 'KZT', 'kazachka-waterfall-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа к водопаду Казачка', 'Kazachka Waterfall Trail', 'Казачка сарқырамасына соқпақ', 'Короткий горный маршрут западной части Заилийского Алатау к тенистому ущелью, водопадному участку и прохладному лесному воздуху.', 'A short western Trans-Ili Alatau route toward a shaded gorge, waterfall section and cool forest air.', 'Іле Алатауының батыс бөлігіндегі көлеңкелі шатқалға, сарқырама бөлігіне және салқын орман ауасына апаратын қысқа тау бағыты.', 43.15100000, 76.65200000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','waterfall','hiking']::text[]),
    ('KZ', 'KZT', 'amangeldy-peak-approach-trail', 'almaty', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Подходная тропа к пику Амангельды', 'Amangeldy Peak Approach Trail', 'Амангелді шыңына жақындау соқпағы', 'Высотный маршрут из района Туюк-Су к каменным подходам, моренным полям и видам на классический альпинистский узел Алматы.', 'A high mountain route from the Tuyuk-Su area toward rocky approaches, moraine fields and views of Almaty classic alpine node.', 'Тұйық-Су аймағынан тасты жақындауларға, мореналық алқаптарға және Алматының классикалық альпілік торабына көрініс беретін биіктау бағыты.', 43.07400000, 77.09000000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','tuyuk-su','summit-approach','trekking']::text[]),
    ('KZ', 'KZT', 'kokpekty-river-gorge-trail', 'almaty', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья реки Кокпекты', 'Kokpekty River Gorge Trail', 'Көкпекті өзені шатқалы соқпағы', 'Менее загруженный маршрут Алматинской области по речной долине, кустарниковым склонам и спокойным предгорным видам.', 'A less crowded Almaty Region route along a river valley, shrub slopes and calm foothill views.', 'Алматы облысындағы өзен аңғары, бұталы беткейлер және тыныш тау етегі көріністері арқылы өтетін сиректеу бағыт.', 43.26800000, 77.56000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','river-gorge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'keregetas-rocks-walk', 'taldykorgan', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прогулка скал Керегетас', 'Keregetas Rocks Walk', 'Керегетас жартастары серуені', 'Жетысуский маршрут к выразительным каменным формам, сухим склонам и открытому степному горизонту для спокойной остановки в пути.', 'A Zhetysu route toward expressive rock forms, dry slopes and an open steppe horizon for a calm road-trip stop.', 'Жетісудағы айқын тас пішіндерге, құрғақ беткейлерге және жолдағы тыныш аялдамаға арналған ашық дала көкжиегіне апаратын бағыт.', 44.26000000, 78.18000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan','almaty']::text[], ARRAY['taldykorgan','almaty']::text[], ARRAY['kazakhstan','zhetysu','rock-formations','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shilikty-valley-heritage-walk', 'semey', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка долины Шиликти', 'Shilikty Valley Heritage Walk', 'Шілікті аңғары серуені', 'Восточноказахстанский маршрут по широкой долине, степным видам и археологическому ландшафту между Тарбагатаем и Алтаем.', 'An East Kazakhstan route across a wide valley, steppe views and archaeological landscape between Tarbagatai and Altai.', 'Тарбағатай мен Алтай арасындағы кең аңғар, дала көріністері және археологиялық ландшафт арқылы өтетін Шығыс Қазақстан бағыты.', 48.78000000, 84.69000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','shilikty','heritage','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shalkar-imantau-shore-walk', 'kokshetau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Береговая прогулка Шалкар-Имантау', 'Shalkar-Imantau Shore Walk', 'Шалқар-Имантау жағалау серуені', 'Северный маршрут по озерной зоне Шалкар-Имантау с сосновыми участками, мягким берегом и более тихим форматом отдыха у воды.', 'A northern route across the Shalkar-Imantau lake area with pine pockets, a gentle shoreline and a quieter water-side outdoor format.', 'Шалқар-Имантау көл аймағындағы қарағайлы бөліктер, жұмсақ жағалау және су маңындағы тынышырақ outdoor форматы бар солтүстік бағыт.', 53.27600000, 68.42000000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kokshetau','petropavlovsk']::text[], ARRAY['kazakhstan','north-kazakhstan','shalkar-imantau','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kokshetau-blue-bay-forest-walk', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Лесная прогулка Голубого залива Кокшетау', 'Kokshetau Blue Bay Forest Walk', 'Көкшетау Көгілдір шығанағы орман серуені', 'Короткая бурабайская прогулка среди сосен, гранитных выходов и видов на воду, подходящая как легкий северный outdoor-сценарий.', 'A short Burabay walk among pines, granite outcrops and water views, suited as an easy northern outdoor plan.', 'Қарағайлар, гранитті жерлер және су көріністері арасындағы қысқа Бурабай серуені, жеңіл солтүстік outdoor сценарийіне лайық.', 53.08800000, 70.30500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','blue-bay','forest','walking']::text[]),
    ('KZ', 'KZT', 'sherkala-north-ridge-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прогулка северного гребня Шеркалы', 'Sherkala North Ridge Walk', 'Шерқала солтүстік жотасы серуені', 'Мангистауский маршрут вокруг северной стороны горы с сухими склонами, дальними видами плато и выразительным силуэтом Шеркалы.', 'A Mangystau route around the northern side of the mountain with dry slopes, distant plateau views and Sherkala signature silhouette.', 'Таудың солтүстік жағымен өтетін Маңғыстау бағыты: құрғақ беткейлер, үстірттің алыс көріністері және Шерқаланың айқын сұлбасы.', 44.26200000, 52.00200000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','sherkala','ridge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'baskamyr-steppe-valley-walk', 'zhezkazgan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная прогулка Баскамыра', 'Baskamyr Steppe Valley Walk', 'Басқамыр дала аңғары серуені', 'Улытауский маршрут по сухой долине, низким сопкам и историческому ландшафту, который хорошо дополняет культурные поездки из Жезказгана.', 'A Ulytau route through a dry valley, low hills and historical landscape that pairs well with cultural trips from Zhezkazgan.', 'Жезқазғаннан мәдени сапарларды толықтыратын Ұлытау бағыты: құрғақ аңғар, аласа шоқылар және тарихи ландшафт.', 48.18000000, 66.87000000, 'Dzhuchi khan mausoleum.jpg', ARRAY['zhezkazgan']::text[], ARRAY['zhezkazgan']::text[], ARRAY['kazakhstan','ulytau','steppe-valley','heritage','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'berkara-gorge-trail', 'taraz', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья Беркара', 'Berkara Gorge Trail', 'Берқара шатқалы соқпағы', 'Жамбылский маршрут к зеленому ущелью, родниковым участкам и более тихому западнотяньшанскому рельефу для выезда из Тараза.', 'A Zhambyl route toward a green gorge, spring-fed sections and a quieter Western Tian Shan landscape for a Taraz outing.', 'Тараздан шығатын Жамбыл бағыты: жасыл шатқал, бұлақты бөліктер және тынышырақ Батыс Тянь-Шань бедері.', 42.91600000, 72.76000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz','shymkent']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','berkara','gorge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'borolday-petroglyph-gorge-walk', 'turkestan', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка петроглифов Боралдая', 'Borolday Petroglyph Gorge Walk', 'Боралдай петроглиф шатқалы серуені', 'Южноказахстанский маршрут по сухому ущелью, каменным плитам и древнему наскальному контексту Каратау.', 'A southern Kazakhstan route through a dry gorge, stone slabs and ancient Karatau rock-art context.', 'Оңтүстік Қазақстандағы құрғақ шатқал, тас тақталар және Қаратаудың көне жартас суреттері контексті арқылы өтетін бағыт.', 43.25500000, 69.01000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','karatau','petroglyphs','gorge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'turgay-geoglyph-steppe-walk', 'kostanay', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная прогулка Тургайских геоглифов', 'Turgay Geoglyph Steppe Walk', 'Торғай геоглифтері дала серуені', 'Североказахстанский степной маршрут к открытым плато, археологическому ландшафту и редкому формату медленной прогулки по древним линиям.', 'A northern Kazakhstan steppe route toward open plateaus, archaeological landscape and a rare slow-walk format across ancient lines.', 'Солтүстік Қазақстандағы ашық үстірттерге, археологиялық ландшафтқа және көне сызықтар бойымен баяу серуендеу форматына апаратын дала бағыты.', 50.10000000, 65.60000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','turgay','geoglyphs','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_last_hidden_outdoor_routes_resolved_places AS
SELECT
    ('127d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-last-hidden-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_last_hidden_outdoor_routes_places;

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
FROM seed_kazakhstan_last_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_last_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_last_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_last_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_last_hidden_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_last_hidden_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_last_hidden_outdoor_routes_places;
