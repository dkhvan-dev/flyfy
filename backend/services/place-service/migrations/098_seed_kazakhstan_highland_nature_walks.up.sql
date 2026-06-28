-- Extra Kazakhstan route-level hiking and nature walks.
-- This layer adds more concrete outdoor choices without duplicating already seeded broad parks, gorges and landmark anchors.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_highland_nature_walks_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_highland_nature_walks_places;

CREATE TEMP TABLE seed_kazakhstan_highland_nature_walks_places (
    slug varchar(96) PRIMARY KEY,
    country_code varchar(2) NOT NULL,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    price_amount numeric(12,2) NOT NULL,
    price_currency varchar(3) NOT NULL,
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

INSERT INTO seed_kazakhstan_highland_nature_walks_places (
    slug,
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
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
    ('bukreev-peak-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.8, 'Тропа на пик Букреева', 'Bukreev Peak Trail', 'Букреев шыңына соқпақ', 'Спортивный маршрут над горной зоной Алматы с открытым гребнем, набором высоты и сильной панорамой Заилийского Алатау.', 'A sporty route above Almaty mountain belt with an open ridge, meaningful elevation gain and a strong Ile Alatau panorama.', 'Алматы тау белдеуінің үстіндегі спорттық бағыт: ашық жота, биіктік жинау және Іле Алатауына кең панорама.', 43.10300000, 77.02800000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','summit','trekking']::text[]),
    ('japanese-road-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.7, 'Тропа Японской дороги', 'Japanese Road Trail', 'Жапон жолы соқпағы', 'Лесной маршрут в горах Алматы по старой серпантинной дороге, где удобно идти к обзорным точкам без технического рельефа.', 'A forest route in the Almaty mountains along an old switchback road, convenient for viewpoints without technical terrain.', 'Алматы тауларындағы ескі бұралаң жол бойымен өтетін орманды бағыт, техникалық қиындықсыз көрініс нүктелеріне ыңғайлы.', 43.12200000, 76.96900000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','forest-road','day-hike']::text[]),
    ('kim-asar-waterfall-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 4, 'HOURS', 4.7, 'Тропа к водопаду Ким-Асар', 'Kim-Asar Waterfall Trail', 'Кім-Асар сарқырамасына соқпақ', 'Короткий горный маршрут с ручьем, хвойным воздухом и водопадным участком рядом с популярными стартами Алматы.', 'A short mountain route with a stream, spruce air and a waterfall section near popular Almaty trailheads.', 'Алматыдағы танымал бастау нүктелеріне жақын бұлағы, шыршалы ауасы және сарқырама бөлігі бар қысқа тау бағыты.', 43.15400000, 77.04700000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','waterfall','day-hike']::text[]),
    ('batan-meadows-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 6, 'HOURS', 4.7, 'Тропа к полянам Батан', 'Batan Meadows Trail', 'Батан алаңдарына соқпақ', 'Зеленый маршрут восточнее Алматы к лесным полянам и прохладной долине, хорошо подходящий для спокойного дня на природе.', 'A green route east of Almaty toward forest meadows and a cool valley, well suited for a calm outdoor day.', 'Алматының шығысындағы орман алаңдары мен салқын аңғарға апаратын жасыл бағыт, табиғаттағы тыныш күнге қолайлы.', 43.23500000, 77.71200000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','meadows','hiking']::text[]),
    ('sazanata-gorge-trail', 'KZ', 'shymkent', 'NATURE', 0, 'KZT', 5, 'HOURS', 4.6, 'Тропа ущелья Сазаната', 'Sazanata Gorge Trail', 'Сазаната шатқалы соқпағы', 'Южный маршрут в предгорьях Каратау с сухими склонами, каменными стенками и форматом легкого выезда из Шымкента.', 'A southern Karatau foothill route with dry slopes, rocky walls and an easy departure format from Shymkent.', 'Қаратаудың оңтүстік тау етегіндегі құрғақ беткейлері, тасты қабырғалары және Шымкенттен жеңіл шығу форматы бар бағыт.', 42.50500000, 69.63000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','karatau','gorge','free-entry','hiking']::text[]),
    ('merke-gorge-trail', 'KZ', 'taraz', 'NATURE', 0, 'KZT', 6, 'HOURS', 4.6, 'Тропа Меркенского ущелья', 'Merke Gorge Trail', 'Меркі шатқалы соқпағы', 'Маршрут из Тараза к зеленому западно-тяньшанскому ущелью с ручьями, пастбищами и мягким горным рельефом.', 'A route from Taraz toward a green Western Tian Shan gorge with streams, pastures and gentle mountain terrain.', 'Тараздан Батыс Тянь-Шаньның жасыл шатқалына апаратын бағыт: бұлақтар, жайылымдар және жұмсақ тау бедері.', 42.83500000, 73.21000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','western-tian-shan','free-entry','hiking']::text[]),
    ('korgalzhyn-reedbed-birding-trail', 'KZ', 'astana', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.8, 'Камышовая тропа Коргалжына', 'Korgalzhyn Reedbed Birding Trail', 'Қорғалжын қамысты құсбақылау соқпағы', 'Степной природный маршрут из Астаны к озерным камышам, наблюдению за птицами и широкому горизонту северной степи.', 'A steppe nature route from Astana toward lake reedbeds, birdwatching and the wide northern steppe horizon.', 'Астанадан көл қамыстарына, құс бақылауға және солтүстік даланың кең көкжиегіне апаратын табиғи бағыт.', 50.58400000, 69.21000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana']::text[], ARRAY['astana']::text[], ARRAY['kazakhstan','akmola-region','wetlands','birdwatching','hiking']::text[]),
    ('zheke-batyr-mountain-trail', 'KZ', 'kokshetau', 'NATURE', 1000, 'KZT', 4, 'HOURS', 4.7, 'Тропа горы Жеке-Батыр', 'Zheke-Batyr Mountain Trail', 'Жеке-Батыр тауына соқпақ', 'Северный маршрут среди сосен и гранитных форм Бурабайской зоны с коротким подъемом и видом на озера.', 'A northern route among pine forest and granite forms of the Burabay area, with a short climb and lake views.', 'Бурабай аймағындағы қарағайлы орман мен гранит пішіндері арасындағы солтүстік бағыт, қысқа көтерілу және көл көріністері бар.', 53.01600000, 70.38600000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','granite','hiking']::text[]),
    ('kyzylkup-rainbow-hills-trail', 'KZ', 'aktau', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.8, 'Тропа Радужных холмов Кызылкуп', 'Kyzylkup Rainbow Hills Trail', 'Қызылқұп түрлі түсті қыраттары соқпағы', 'Пустынный маршрут Мангистау среди цветных глинистых холмов, сухих русел и широких точек для фото на закате.', 'A Mangystau desert route among colored clay hills, dry washes and wide sunset photo viewpoints.', 'Маңғыстаудағы түрлі түсті сазды қыраттар, құрғақ сайлар және күн батардағы кең фото нүктелері арасындағы шөл бағыты.', 43.76000000, 53.76000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','rainbow-hills','free-entry','walking']::text[]),
    ('sultan-epe-valley-walk', 'KZ', 'aktau', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.6, 'Прогулка долины Султан-Эпе', 'Sultan-Epe Valley Walk', 'Сұлтан-Епе аңғары серуені', 'Маршрут по сухой долине Мангистау с известняковыми склонами, тишиной плато и культурным контекстом пустынного края.', 'A dry Mangystau valley walk with limestone slopes, plateau silence and cultural context of the desert region.', 'Маңғыстаудың құрғақ аңғарымен өтетін серуен: әктас беткейлер, үстірт тыныштығы және шөл өңірінің мәдени контексті.', 44.61000000, 51.20000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','valley','free-entry','walking']::text[]),
    ('akkegershin-chalk-canyon-trail', 'KZ', 'atyrau', 'NATURE', 0, 'KZT', 5, 'HOURS', 4.7, 'Тропа мелового каньона Аккегершин', 'Akkegershin Chalk Canyon Trail', 'Ақкегершін борлы каньоны соқпағы', 'Маршрут западного Казахстана к светлым меловым формам, сухим оврагам и редкому для региона пейзажу.', 'A western Kazakhstan route to pale chalk formations, dry gullies and a landscape that feels rare for the region.', 'Батыс Қазақстандағы ақшыл борлы пішіндерге, құрғақ жыраларға және өңір үшін сирек ландшафтқа апаратын бағыт.', 47.89000000, 54.21000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['atyrau','aktau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','west-kazakhstan','chalk-canyon','free-entry','hiking']::text[]),
    ('aulie-cave-granite-trail', 'KZ', 'balkhash', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.6, 'Гранитная тропа пещеры Аулие', 'Aulie Cave Granite Trail', 'Әулие үңгірі гранит соқпағы', 'Короткий маршрут у гранитного массива возле Балхаша к скальным гротам, обзорным камням и степному горизонту.', 'A short route at the granite massif near Balkhash toward rocky grottoes, viewpoint stones and the steppe horizon.', 'Балқаш маңындағы гранитті массивтегі қысқа бағыт: жартасты үңгірлерге, көрініс тастарына және дала көкжиегіне апарады.', 46.79000000, 74.98200000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash','karaganda']::text[], ARRAY['balkhash','karaganda']::text[], ARRAY['kazakhstan','balkhash','granite','free-entry','walking']::text[]),
    ('terekty-aulie-petroglyph-trail', 'KZ', 'zhezkazgan', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.7, 'Тропа петроглифов Теректы-Аулие', 'Terekty Aulie Petroglyph Trail', 'Теректі-Әулие петроглифтері соқпағы', 'Маршрут Улытауской степи к скальным плитам с петроглифами, открытым просторам и спокойной пешей логистике.', 'A Ulytau steppe route to rock slabs with petroglyphs, open spaces and simple walking logistics.', 'Ұлытау даласындағы петроглифтері бар тас тақталарға, ашық кеңістікке және жеңіл жаяу логистикаға апаратын бағыт.', 48.18300000, 67.36000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['zhezkazgan']::text[], ARRAY['zhezkazgan']::text[], ARRAY['kazakhstan','ulytau','petroglyphs','free-entry','walking']::text[]),
    ('ubagan-river-valley-walk', 'KZ', 'kostanay', 'NATURE', 0, 'KZT', 3, 'HOURS', 4.4, 'Прогулка долины реки Убаган', 'Ubagan River Valley Walk', 'Обаған өзені аңғары серуені', 'Спокойный северный маршрут у Костаная с речной долиной, луговыми участками и мягкой природной остановкой без сложного рельефа.', 'A calm northern route near Kostanay with a river valley, meadow sections and an easy nature stop without difficult terrain.', 'Қостанай маңындағы тыныш солтүстік бағыт: өзен аңғары, шалғынды бөліктер және күрделі бедерсіз жеңіл табиғи аялдама.', 52.29000000, 63.65000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','river-valley','free-entry','walking']::text[]),
    ('semey-irtysh-island-trail', 'KZ', 'semey', 'NATURE', 0, 'KZT', 3, 'HOURS', 4.4, 'Тропа иртышского острова в Семее', 'Semey Irtysh Island Trail', 'Семейдегі Ертіс аралы соқпағы', 'Легкий городской outdoor-маршрут вдоль Иртыша с песчаными берегами, пойменной зеленью и спокойным форматом прогулки.', 'An easy urban outdoor route along the Irtysh with sandy banks, floodplain greenery and a calm walking format.', 'Ертіс бойындағы жеңіл қалалық outdoor бағыты: құмды жағалау, жайылма жасылдығы және тыныш серуен форматы.', 50.41100000, 80.24400000, 'Atyrau footbridge across Ural River.jpg', ARRAY['semey']::text[], ARRAY['semey']::text[], ARRAY['kazakhstan','abai-region','irtysh','free-entry','walking']::text[]),
    ('kushum-river-floodplain-walk', 'KZ', 'oral', 'NATURE', 0, 'KZT', 3, 'HOURS', 4.4, 'Пойменная прогулка реки Кушум', 'Kushum River Floodplain Walk', 'Көшім өзені жайылмасы серуені', 'Западноказахстанский маршрут к речной пойме, ивовым участкам и тихой степной воде для короткого выезда из Орала.', 'A West Kazakhstan route to river floodplain, willow sections and quiet steppe water for a short escape from Oral.', 'Оралдан қысқа шығуға арналған Батыс Қазақстан бағыты: өзен жайылмасы, талды бөліктер және тыныш дала суы.', 50.92000000, 51.39000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','river','free-entry','walking']::text[]),
    ('arpa-uzen-petroglyph-ridge-trail', 'KZ', 'turkestan', 'NATURE', 0, 'KZT', 5, 'HOURS', 4.6, 'Тропа петроглифов Арпа-Узен', 'Arpa-Uzen Petroglyph Ridge Trail', 'Арпа-Өзен петроглифтері жотасы соқпағы', 'Южный маршрут по Каратау к древним наскальным изображениям, каменистым гребням и сухому степному ландшафту.', 'A southern Karatau route toward ancient rock art, stony ridges and a dry steppe landscape.', 'Қаратаудағы көне жартас суреттеріне, тасты жоталарға және құрғақ дала ландшафтына апаратын оңтүстік бағыт.', 43.61000000, 68.53000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','karatau','petroglyphs','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_highland_nature_walks_resolved_places AS
SELECT
    ('98ad0000-0000-4000-8000-' || substr(md5(slug), 1, 12))::uuid AS id,
    slug,
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
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
    ARRAY['kazakhstan-highland-nature-walks-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_highland_nature_walks_places;

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
FROM seed_kazakhstan_highland_nature_walks_resolved_places
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
FROM seed_kazakhstan_highland_nature_walks_resolved_places
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
FROM seed_kazakhstan_highland_nature_walks_resolved_places
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
FROM seed_kazakhstan_highland_nature_walks_resolved_places
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
FROM seed_kazakhstan_highland_nature_walks_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
