-- More Kazakhstan route-level hiking and outdoor depth.
-- This layer adds concrete trail cards that complement broad anchors and previously seeded routes.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_depth_places;

CREATE TEMP TABLE seed_kazakhstan_more_outdoor_depth_places (
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

INSERT INTO seed_kazakhstan_more_outdoor_depth_places (
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
    ('alpengrad-high-camp-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.8, 'Тропа к высокогорному лагерю Альпенград', 'Alpengrad High Camp Trail', 'Альпенград биіктау лагеріне соқпақ', 'Высотный маршрут из зоны Шымбулака к альпийскому лагерному формату, моренным участкам и открытым видам Малой Алматинки.', 'A high mountain route from the Shymbulak side toward an alpine camp setting, moraine sections and open Little Almatinka views.', 'Шымбұлақ жақтан альпілік лагерь аймағына, мореналық бөліктерге және Кіші Алматының ашық көріністеріне апаратын биік тау бағыты.', 43.09000000, 77.09000000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','alpengrad','alpine','trekking']::text[]),
    ('mayakovsky-peak-view-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.8, 'Тропа к виду на пик Маяковского', 'Mayakovsky Peak View Trail', 'Маяковский шыңы көрінісіне соқпақ', 'Спортивный маршрут в высокогорье Заилийского Алатау к каменным склонам, снежным видам и сильной панораме альпийского узла.', 'A sporty high mountain route in the Ile Alatau toward rocky slopes, snowline views and a strong panorama of the alpine node.', 'Іле Алатауының биіктауындағы спорттық бағыт: тасты беткейлер, қар сызығы көріністері және альпілік тораптың кең панорамасы.', 43.07800000, 77.10300000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','summit-view','trekking']::text[]),
    ('tourist-peak-approach-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 6, 'HOURS', 4.7, 'Подходная тропа к пику Турист', 'Tourist Peak Approach Trail', 'Турист шыңына жақындау соқпағы', 'Маршрут от района Большого Алматинского озера к сухим гребням, каменистым участкам и видам на высокогорную долину.', 'A route from the Big Almaty Lake area toward dry ridges, rocky sections and views over a high mountain valley.', 'Үлкен Алматы көлі аймағынан құрғақ жоталарға, тасты бөліктерге және биіктау аңғарының көріністеріне апаратын бағыт.', 43.05300000, 76.98500000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','big-almaty-area','summit-approach','hiking']::text[]),
    ('ozerny-peak-moraine-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.7, 'Моренная тропа пика Озерный', 'Ozerny Peak Moraine Trail', 'Озерный шыңы морена соқпағы', 'Высокогорный маршрут к моренным полям и озерным видам южнее Алматы, рассчитанный на подготовленный дневной треккинг.', 'A high mountain route to moraine fields and lake views south of Almaty, suited for prepared day trekking.', 'Алматының оңтүстігіндегі морена алқаптары мен көл көріністеріне апаратын биік тау бағыты, дайын күндік треккингке лайық.', 43.06200000, 76.97400000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','moraine','trekking']::text[]),
    ('shukur-gorge-hut-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.6, 'Тропа к горным приютам ущелья Шукур', 'Shukur Gorge Hut Trail', 'Шүкір шатқалы тау паналарына соқпақ', 'Лесной маршрут к менее перегруженному ущелью с ручьями, хвойными склонами и форматом безопасного горного дня рядом с Алматы.', 'A forest route to a quieter gorge with streams, spruce slopes and a safe mountain-day format near Almaty.', 'Алматы маңындағы тынышырақ шатқалға апаратын орманды бағыт: бұлақтар, шыршалы беткейлер және қауіпсіз тау күні форматы.', 43.14600000, 76.91600000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','gorge','hiking']::text[]),
    ('kimasar-pass-ridge-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.7, 'Жотная тропа перевала Кимасар', 'Kimasar Pass Ridge Trail', 'Кімасар асуы жота соқпағы', 'Маршрут над Медеу к лесному перевалу и открытым гребням, который дает больше панорам, чем короткая прогулка по нижнему ущелью.', 'A route above Medeu toward a forest pass and open ridges, giving more panoramas than a short lower-gorge walk.', 'Медеу үстінен орманды асуға және ашық жоталарға апаратын бағыт, төменгі шатқалдағы қысқа серуенге қарағанда көбірек панорама береді.', 43.15800000, 77.02000000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','pass','ridge','day-hike']::text[]),
    ('prohodnaya-river-waterfall-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.7, 'Тропа к водопадам реки Проходная', 'Prohodnaya River Waterfall Trail', 'Проходная өзені сарқырамаларына соқпақ', 'Маршрут в зоне Алма-Арасана вдоль горной реки к водопадным участкам, камням и прохладному лесному микроклимату.', 'A route in the Alma-Arasan area along a mountain river toward waterfall sections, stones and a cool forest microclimate.', 'Алма-Арасан аймағындағы тау өзені бойымен сарқырама бөліктеріне, тастарға және салқын орман микроклиматына апаратын бағыт.', 43.08600000, 76.92000000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','alma-arasan-area','waterfall','day-hike']::text[]),
    ('karash-ridge-turgen-trail', 'KZ', 'almaty', 'NATURE', 1000, 'KZT', 6, 'HOURS', 4.7, 'Тропа жоты Караш в Тургене', 'Karash Ridge Turgen Trail', 'Түргендегі Қараш жотасы соқпағы', 'Маршрут восточнее Алматы к дикому яблоневому поясу, открытым склонам и длинной линии хребта над Тургенской долиной.', 'A route east of Almaty toward wild apple foothills, open slopes and a long ridge line above the Turgen valley.', 'Алматының шығысындағы жабайы алма белдеуіне, ашық беткейлерге және Түрген аңғары үстіндегі ұзын жота сызығына апаратын бағыт.', 43.29500000, 77.78500000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','turgen','ridge','hiking']::text[]),
    ('besqaynar-forest-trail', 'KZ', 'almaty', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.6, 'Лесная тропа Бескайнар', 'Besqaynar Forest Trail', 'Бесқайнар орман соқпағы', 'Короткий предгорный маршрут над Алматы с хвойным лесом, мягким набором высоты и удобным форматом для семейной прогулки.', 'A short foothill route above Almaty with conifer forest, gentle elevation gain and an easy format for a family walk.', 'Алматы үстіндегі қысқа тау етегі бағыты: қылқанды орман, жұмсақ биіктік жинау және отбасылық серуенге ыңғайлы формат.', 43.22000000, 77.10000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-foothills','forest','free-entry','walking']::text[]),
    ('tamgaly-tas-climber-path', 'KZ', 'almaty', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.7, 'Скалолазная тропа Тамгалы-Тас', 'Tamgaly-Tas Climber Path', 'Таңбалы-Тас жартасты соқпағы', 'Маршрут вдоль скальных стен и берега Или, где короткая пешая логистика соединяется с петроглифами и скальными маршрутами.', 'A route along Ili river cliffs where short walking logistics combine petroglyph context and climbing walls.', 'Іле жағасындағы жартастар бойымен өтетін бағыт, қысқа жаяу логистика петроглиф контекстімен және жартасты маршруттармен байланысады.', 43.81200000, 76.99000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ili-river','cliffs','free-entry','hiking']::text[]),
    ('maral-lake-altai-trail', 'KZ', 'ust-kamenogorsk', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.8, 'Алтайская тропа к озеру Маралье', 'Maral Lake Altai Trail', 'Алтайдағы Марал көліне соқпақ', 'Маршрут Восточного Казахстана к горному озеру, хвойным склонам и спокойному алтайскому пейзажу вдали от городского ритма.', 'An East Kazakhstan route to a mountain lake, spruce slopes and a calm Altai landscape far from the city rhythm.', 'Шығыс Қазақстандағы тау көліне, шыршалы беткейлерге және қала ырғағынан алыс тыныш Алтай ландшафтына апаратын бағыт.', 49.20500000, 85.60400000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','lake','trekking']::text[]),
    ('kokkol-mine-heritage-trail', 'KZ', 'ust-kamenogorsk', 'NATURE', 1000, 'KZT', 6, 'HOURS', 4.7, 'Историческая тропа рудника Кокколь', 'Kokkol Mine Heritage Trail', 'Көккөл кен орны тарихи соқпағы', 'Алтайский маршрут к высокогорной индустриальной истории, каменным долинам и суровым видам Катон-Карагайской зоны.', 'An Altai route to high mountain industrial heritage, stone valleys and rugged Katon-Karagay area views.', 'Алтайдағы биіктау өндірістік мұрасына, тасты аңғарларға және Қатонқарағай аймағының қатал көріністеріне апаратын бағыт.', 49.32500000, 86.11000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','heritage','hiking']::text[]),
    ('sarymsakty-ridge-trail', 'KZ', 'ust-kamenogorsk', 'NATURE', 1000, 'KZT', 7, 'HOURS', 4.7, 'Тропа Сарымсактинского хребта', 'Sarymsakty Ridge Trail', 'Сарымсақты жотасы соқпағы', 'Горный маршрут Катон-Карагая по лесистым склонам и открытым гребням, подходящий для сильного дня в Алтае.', 'A Katon-Karagay mountain route across forested slopes and open ridges, suited for a strong Altai day.', 'Қатонқарағайдағы орманды беткейлер мен ашық жоталар арқылы өтетін тау бағыты, Алтайдағы белсенді күнге лайық.', 49.21000000, 85.34000000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','ridge','trekking']::text[]),
    ('zhasybai-toraigyr-traverse', 'KZ', 'pavlodar', 'NATURE', 1000, 'KZT', 5, 'HOURS', 4.7, 'Траверс Жасыбай - Торайгыр', 'Zhasybai to Toraigyr Traverse', 'Жасыбайдан Торайғырға траверс', 'Баянаульский маршрут между озерными ландшафтами, соснами и гранитными обзорными точками для полноценного outdoor-дня.', 'A Bayanaul route between lake landscapes, pines and granite viewpoints for a complete outdoor day.', 'Баянауылдағы көл ландшафттары, қарағайлар және гранитті көрініс нүктелері арасындағы толық outdoor күнге арналған бағыт.', 50.81700000, 75.66500000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','lake-link','hiking']::text[]),
    ('naizatas-rock-trail', 'KZ', 'pavlodar', 'NATURE', 1000, 'KZT', 4, 'HOURS', 4.6, 'Тропа скал Найзатас', 'Naizatas Rock Trail', 'Найзатас жартастары соқпағы', 'Короткая тропа Баянаула к выразительным каменным формам, сосновому воздуху и спокойным видовым площадкам.', 'A short Bayanaul trail to expressive stone forms, pine air and calm viewpoints.', 'Баянауылдағы айқын тас пішіндеріне, қарағайлы ауаға және тыныш көрініс алаңдарына апаратын қысқа соқпақ.', 50.78800000, 75.70500000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','rocks','hiking']::text[]),
    ('borovushka-forest-loop', 'KZ', 'kokshetau', 'NATURE', 1000, 'KZT', 3, 'HOURS', 4.6, 'Лесная петля Боровушки', 'Borovushka Forest Loop', 'Боровушка орман ілмегі', 'Легкая северная прогулка среди сосен Бурабайской зоны, озерного воздуха и коротких троп без сложного рельефа.', 'An easy northern walk among Burabay-area pines, lake air and short trails without difficult terrain.', 'Бурабай аймағының қарағайлары, көл ауасы және күрделі бедерсіз қысқа соқпақтары арасындағы жеңіл солтүстік серуен.', 53.08300000, 70.26500000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','forest','walking']::text[]),
    ('senek-dune-field-walk', 'KZ', 'aktau', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.7, 'Прогулка песчаного поля Сенек', 'Senek Dune Field Walk', 'Сенек құмды алқабы серуені', 'Мангистауский маршрут к мягким песчаным грядам, пустынному горизонту и спокойной съемке на рассвете или закате.', 'A Mangystau route to soft sand ridges, desert horizon and calm sunrise or sunset photo stops.', 'Маңғыстаудағы жұмсақ құм жоталарына, шөл көкжиегіне және таңғы не кешкі тыныш фото аялдамаларына апаратын бағыт.', 43.33800000, 53.14300000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','dunes','free-entry','walking']::text[]),
    ('tuyesu-sands-trail', 'KZ', 'aktau', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.7, 'Тропа песков Туесу', 'Tuyesu Sands Trail', 'Түйесу құмдары соқпағы', 'Пустынный маршрут по светлым пескам и сухим ложбинам Мангистау, где важны ранний старт, вода и мягкий темп.', 'A desert route across pale sands and dry hollows of Mangystau, where an early start, water and a gentle pace matter.', 'Маңғыстаудың ашық құмдары мен құрғақ ойпаңдары арқылы өтетін шөл бағыты, ерте бастау, су және жұмсақ қарқын маңызды.', 43.21000000, 53.65000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','sand','free-entry','hiking']::text[]),
    ('bozjira-western-escarpment-walk', 'KZ', 'aktau', 'NATURE', 0, 'KZT', 5, 'HOURS', 4.8, 'Прогулка западного уступа Бозжиры', 'Bozjira Western Escarpment Walk', 'Бозжыра батыс кертпеші серуені', 'Маршрут по краю плато с белыми стенами, сухими руслами и широкими видами пустынного Мангистау.', 'A route along a plateau edge with pale walls, dry washes and wide views of desert Mangystau.', 'Ақшыл қабырғалары, құрғақ сайлары және шөлді Маңғыстаудың кең көріністері бар үстірт жиегімен өтетін бағыт.', 43.41500000, 54.06000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','plateau','free-entry','hiking']::text[]),
    ('granite-labyrinth-loop-near-bektauata', 'KZ', 'balkhash', 'NATURE', 0, 'KZT', 4, 'HOURS', 4.7, 'Гранитная петля лабиринтов у Бектауата', 'Granite Labyrinth Loop near Bektauata', 'Бектауата маңындағы гранит лабиринт ілмегі', 'Маршрут Центрального Казахстана среди округлых гранитных форм, скальных ниш и открытого степного горизонта у Балхаша.', 'A central Kazakhstan route among rounded granite forms, rocky niches and the open steppe horizon near Balkhash.', 'Балқаш маңындағы дөңгелек гранит пішіндері, жартасты қуыстар және ашық дала көкжиегі арасындағы Орталық Қазақстан бағыты.', 47.44300000, 74.75200000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash','karaganda']::text[], ARRAY['balkhash','karaganda']::text[], ARRAY['kazakhstan','central-kazakhstan','granite','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_more_outdoor_depth_resolved_places AS
SELECT
    ('102d0000-0000-4000-8000-' || substr(md5(slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-more-outdoor-depth-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_more_outdoor_depth_places;

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
FROM seed_kazakhstan_more_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_more_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_more_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_more_outdoor_depth_resolved_places
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
FROM seed_kazakhstan_more_outdoor_depth_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_depth_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_depth_places;
