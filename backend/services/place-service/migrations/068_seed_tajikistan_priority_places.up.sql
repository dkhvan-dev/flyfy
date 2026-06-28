-- Priority Tajikistan destination places seed.
-- The seed covers Dushanbe day trips, Sughd and Fann Mountains, Pamir/GBAO, and southern Khatlon heritage.

DROP TABLE IF EXISTS seed_tajikistan_resolved_places;
DROP TABLE IF EXISTS seed_tajikistan_priority_places;

CREATE TEMP TABLE seed_tajikistan_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_query text NOT NULL,
    access_city_ids text[] NOT NULL,
    departure_city_ids text[] NOT NULL,
    media_file text NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_tajikistan_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    latitude,
    longitude,
    location_query,
    access_city_ids,
    departure_city_ids,
    media_file,
    extra_tags
) VALUES
    ('rudaki-park', 'dushanbe', 'PARK', 2, 'HOURS', 4.8, 'Парк Рудаки', 'Rudaki Park', 'Рудаки саябағы', 38.57690000, 68.78690000, 'Rudaki Park Dushanbe Tajikistan', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Rudaki Park Dushanbe.jpg', ARRAY['city-walk']::text[]),
    ('national-museum-tajikistan', 'dushanbe', 'MUSEUM', 2, 'HOURS', 4.8, 'Национальный музей Таджикистана', 'National Museum of Tajikistan', 'Тәжікстан ұлттық музейі', 38.57350000, 68.77860000, 'National Museum of Tajikistan Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'National Museum of Tajikistan Dushanbe.jpg', ARRAY['indoor']::text[]),
    ('national-museum-antiquities', 'dushanbe', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей древностей Таджикистана', 'Tajikistan National Museum of Antiquities', 'Тәжікстан көне жәдігерлер музейі', 38.57530000, 68.77330000, 'National Museum of Antiquities Tajikistan Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Sleeping Buddha Tajikistan.jpg', ARRAY['indoor']::text[]),
    ('kokhi-navruz', 'dushanbe', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Кохи Навруз', 'Kokhi Navruz', 'Кохи Навруз', 38.58210000, 68.76610000, 'Kokhi Navruz Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Kokhi Navruz Dushanbe.jpg', ARRAY['architecture']::text[]),
    ('national-flag-park', 'dushanbe', 'PARK', 1, 'HOURS', 4.7, 'Парк Государственного флага', 'National Flag Park', 'Мемлекеттік ту саябағы', 38.57300000, 68.77960000, 'National Flag Park Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Dushanbe Flagpole.jpg', ARRAY['city-walk']::text[]),
    ('ismoil-somoni-monument', 'dushanbe', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Памятник Исмоилу Сомони', 'Ismoil Somoni Monument', 'Исмоил Сомони ескерткіші', 38.57390000, 68.78640000, 'Ismoil Somoni Monument Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Ismail Samani Monument Dushanbe.jpg', ARRAY['city-symbol']::text[]),
    ('rohat-tea-house', 'dushanbe', 'FOOD', 1, 'HOURS', 4.6, 'Чайхана Рохат', 'Rohat Tea House', 'Рохат шайханасы', 38.57330000, 68.78750000, 'Rohat Tea House Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Dushanbe Teahouse.jpg', ARRAY['local-food']::text[]),
    ('mehrgon-bazaar', 'dushanbe', 'MARKET', 2, 'HOURS', 4.6, 'Базар Мехргон', 'Mehrgon Bazaar', 'Мехргон базары', 38.58310000, 68.76470000, 'Mehrgon Bazaar Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Dushanbe Bazaar.jpg', ARRAY['local-market']::text[]),
    ('siyoma-mall', 'dushanbe', 'SHOPPING', 2, 'HOURS', 4.5, 'ТРЦ Siyoma Mall', 'Siyoma Mall', 'Siyoma Mall', 38.58900000, 68.78600000, 'Siyoma Mall Dushanbe', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Dushanbe Tajikistan.jpg', ARRAY['indoor']::text[]),
    ('capital-park-dushanbe', 'dushanbe', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Столичный парк Душанбе', 'Capital Park Dushanbe', 'Душанбе астаналық саябағы', 38.57960000, 68.78470000, 'Capital Park Dushanbe Tajikistan', ARRAY['dushanbe']::text[], ARRAY['dushanbe']::text[], 'Dushanbe Park.jpg', ARRAY['family']::text[]),
    ('hisor-fortress', 'hisor', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Гиссарская крепость', 'Hisor Fortress', 'Гиссар қамалы', 38.52400000, 68.55100000, 'Hisor Fortress Tajikistan', ARRAY['hisor']::text[], ARRAY['dushanbe', 'hisor']::text[], 'Hisor Fortress Tajikistan.jpg', ARRAY['day-trip']::text[]),
    ('varzob-gorge', 'varzob', 'NATURE', 4, 'HOURS', 4.7, 'Варзобское ущелье', 'Varzob Gorge', 'Варзоб шатқалы', 38.79300000, 68.81700000, 'Varzob Gorge Tajikistan', ARRAY['varzob']::text[], ARRAY['dushanbe', 'varzob']::text[], 'Varzob Gorge Tajikistan.jpg', ARRAY['day-trip']::text[]),
    ('safed-dara-ski-resort', 'safed-dara', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Горнолыжный курорт Сафед-Дара', 'Safed-Dara Ski Resort', 'Сафед-Дара тау шаңғы курорты', 38.84080000, 68.92910000, 'Safed Dara Ski Resort Tajikistan', ARRAY['safed-dara', 'varzob']::text[], ARRAY['dushanbe', 'safed-dara']::text[], 'Safed Dara Tajikistan.jpg', ARRAY['mountain-resort']::text[]),
    ('nurek-reservoir', 'norak', 'NATURE', 4, 'HOURS', 4.7, 'Нурекское водохранилище', 'Nurek Reservoir', 'Нурек су қоймасы', 38.38170000, 69.32390000, 'Nurek Reservoir Tajikistan', ARRAY['norak']::text[], ARRAY['dushanbe', 'norak']::text[], 'Nurek Dam Tajikistan.jpg', ARRAY['day-trip']::text[]),

    ('khujand-fortress', 'khujand', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Худжандская крепость', 'Khujand Fortress Historical Complex', 'Худжанд қамалы тарихи кешені', 40.28330000, 69.62220000, 'Khujand Fortress Tajikistan', ARRAY['khujand']::text[], ARRAY['khujand']::text[], 'Khujand Fortress.jpg', ARRAY['silk-road']::text[]),
    ('historical-museum-sughd', 'khujand', 'MUSEUM', 2, 'HOURS', 4.7, 'Исторический музей Согда', 'Historical Museum of Sughd', 'Соғды тарихи музейі', 40.28370000, 69.62170000, 'Historical Museum of Sughd Khujand', ARRAY['khujand']::text[], ARRAY['khujand']::text[], 'Khujand Museum.jpg', ARRAY['indoor']::text[]),
    ('panjshanbe-bazaar', 'khujand', 'MARKET', 2, 'HOURS', 4.8, 'Базар Панджшанбе', 'Panjshanbe Bazaar', 'Панджшанбе базары', 40.28460000, 69.62400000, 'Panjshanbe Bazaar Khujand', ARRAY['khujand']::text[], ARRAY['khujand']::text[], 'Panjshanbe Bazaar Khujand.jpg', ARRAY['local-market']::text[]),
    ('sheikh-muslihiddin-complex', 'khujand', 'TEMPLE', 1, 'HOURS', 4.7, 'Комплекс Шейха Муслихиддина', 'Sheikh Muslihiddin Mosque and Mausoleum', 'Шейх Муслихиддин мешіті мен кесенесі', 40.28500000, 69.62350000, 'Sheikh Muslihiddin Mosque Khujand', ARRAY['khujand']::text[], ARRAY['khujand']::text[], 'Sheikh Muslihiddin Mosque.jpg', ARRAY['heritage']::text[]),
    ('kayrakkum-reservoir', 'guliston-qayraqqum', 'NATURE', 4, 'HOURS', 4.6, 'Кайраккумское водохранилище', 'Kayrakkum Reservoir Tajik Sea', 'Қайраққұм су қоймасы', 40.30600000, 69.81000000, 'Kayrakkum Reservoir Tajikistan', ARRAY['guliston-qayraqqum']::text[], ARRAY['khujand', 'guliston-qayraqqum']::text[], 'Kayrakkum Reservoir Tajikistan.jpg', ARRAY['waterfront']::text[]),
    ('mug-teppa-fortress', 'istaravshan', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Крепость Муг-Теппа', 'Mug Teppa Fortress', 'Муг-Теппа қамалы', 39.91390000, 69.00390000, 'Mug Teppa Fortress Istaravshan', ARRAY['istaravshan']::text[], ARRAY['khujand', 'istaravshan']::text[], 'Istaravshan Tajikistan.jpg', ARRAY['silk-road']::text[]),
    ('kok-gumbaz-mosque', 'istaravshan', 'TEMPLE', 1, 'HOURS', 4.7, 'Мечеть Кок-Гумбаз', 'Kok-Gumbaz Mosque Istaravshan', 'Көк-Гумбаз мешіті', 39.91210000, 69.00540000, 'Kok Gumbaz Mosque Istaravshan', ARRAY['istaravshan']::text[], ARRAY['khujand', 'istaravshan']::text[], 'Kok Gumbaz Istaravshan.jpg', ARRAY['heritage']::text[]),
    ('hazrati-shoh-complex', 'istaravshan', 'TEMPLE', 1, 'HOURS', 4.6, 'Комплекс Хазрати Шох', 'Hazrati Shoh Complex', 'Хазрати Шох кешені', 39.91300000, 69.00600000, 'Hazrati Shoh Complex Istaravshan', ARRAY['istaravshan']::text[], ARRAY['istaravshan']::text[], 'Istaravshan Tajikistan.jpg', ARRAY['pilgrimage']::text[]),
    ('ancient-panjakent', 'panjakent', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Древний Пенджикент', 'Ancient Panjakent', 'Ежелгі Пенджикент', 39.49500000, 67.61600000, 'Ancient Panjakent Tajikistan', ARRAY['panjakent']::text[], ARRAY['panjakent']::text[], 'Ancient Panjakent.jpg', ARRAY['silk-road']::text[]),
    ('rudaki-museum-panjakent', 'panjakent', 'MUSEUM', 2, 'HOURS', 4.6, 'Исторический музей имени Рудаки', 'Rudaki Historical Museum Panjakent', 'Рудаки тарихи музейі', 39.49590000, 67.61150000, 'Rudaki Museum Panjakent', ARRAY['panjakent']::text[], ARRAY['panjakent']::text[], 'Panjakent Museum.jpg', ARRAY['indoor']::text[]),
    ('proto-urban-site-sarazm', 'sarazm', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Протогородище Саразм', 'Proto-urban Site of Sarazm', 'Саразм протоқаласы', 39.51500000, 67.46000000, 'Proto urban Site of Sarazm Tajikistan', ARRAY['sarazm', 'panjakent']::text[], ARRAY['panjakent', 'sarazm']::text[], 'Sarazm Tajikistan.jpg', ARRAY['unesco']::text[]),
    ('rudaki-mausoleum', 'panjrud', 'TEMPLE', 2, 'HOURS', 4.7, 'Мавзолей Рудаки', 'Rudaki Mausoleum', 'Рудаки кесенесі', 39.44260000, 67.89050000, 'Rudaki Mausoleum Panjrud', ARRAY['panjrud']::text[], ARRAY['panjakent', 'panjrud']::text[], 'Rudaki Mausoleum.jpg', ARRAY['heritage']::text[]),
    ('seven-lakes-haft-kul', 'seven-lakes', 'NATURE', 6, 'HOURS', 4.9, 'Семь озер Хафт-Кул', 'Seven Lakes Haft Kul', 'Жеті көл Хафт-Кул', 39.24000000, 67.82000000, 'Seven Lakes Haft Kul Tajikistan', ARRAY['seven-lakes', 'fann-mountains']::text[], ARRAY['panjakent', 'seven-lakes']::text[], 'Seven Lakes Tajikistan.jpg', ARRAY['trekking']::text[]),
    ('fann-mountains', 'fann-mountains', 'NATURE', 8, 'HOURS', 4.9, 'Фанские горы', 'Fann Mountains', 'Фан таулары', 39.22000000, 68.18000000, 'Fann Mountains Tajikistan', ARRAY['fann-mountains']::text[], ARRAY['dushanbe', 'panjakent', 'fann-mountains']::text[], 'Fann Mountains Tajikistan.jpg', ARRAY['trekking']::text[]),
    ('kulikalon-lakes', 'kulikalon', 'NATURE', 6, 'HOURS', 4.8, 'Куликалонские озера', 'Kulikalon Lakes', 'Куликалон көлдері', 39.25500000, 68.15300000, 'Kulikalon Lakes Tajikistan', ARRAY['kulikalon', 'fann-mountains']::text[], ARRAY['panjakent', 'fann-mountains']::text[], 'Kulikalon Lakes Tajikistan.jpg', ARRAY['trekking']::text[]),
    ('alauddin-lakes', 'alauddin', 'NATURE', 6, 'HOURS', 4.8, 'Алаудинские озера', 'Alauddin Lakes', 'Алаудин көлдері', 39.27500000, 68.25000000, 'Alauddin Lakes Tajikistan', ARRAY['alauddin', 'fann-mountains']::text[], ARRAY['panjakent', 'fann-mountains']::text[], 'Alauddin Lakes Tajikistan.jpg', ARRAY['trekking']::text[]),
    ('iskanderkul-lake', 'iskanderkul', 'NATURE', 5, 'HOURS', 4.9, 'Озеро Искандеркуль', 'Iskanderkul Lake', 'Ескендіркөл көлі', 39.08000000, 68.37000000, 'Iskanderkul Lake Tajikistan', ARRAY['iskanderkul', 'fann-mountains']::text[], ARRAY['dushanbe', 'iskanderkul']::text[], 'Iskanderkul Tajikistan.jpg', ARRAY['day-trip']::text[]),

    ('pamir-botanical-garden', 'khorog', 'PARK', 2, 'HOURS', 4.8, 'Памирский ботанический сад', 'Pamir Botanical Garden', 'Памир ботаникалық бағы', 37.48950000, 71.54800000, 'Pamir Botanical Garden Khorog', ARRAY['khorog']::text[], ARRAY['khorog']::text[], 'Pamir Botanical Garden Khorog.jpg', ARRAY['gbao-permit']::text[]),
    ('khorog-regional-museum', 'khorog', 'MUSEUM', 1, 'HOURS', 4.5, 'Региональный музей Хорога', 'Khorog Regional Museum', 'Хорог өңірлік музейі', 37.48900000, 71.55300000, 'Khorog Regional Museum Tajikistan', ARRAY['khorog']::text[], ARRAY['khorog']::text[], 'Khorog Tajikistan.jpg', ARRAY['gbao-permit', 'indoor']::text[]),
    ('khorog-bazaar', 'khorog', 'MARKET', 1, 'HOURS', 4.6, 'Хорогский базар', 'Khorog Bazaar', 'Хорог базары', 37.49050000, 71.55200000, 'Khorog Bazaar Tajikistan', ARRAY['khorog']::text[], ARRAY['khorog']::text[], 'Khorog Bazaar.jpg', ARRAY['gbao-permit', 'local-market']::text[]),
    ('garm-chashma-hot-spring', 'garm-chashma', 'NATURE', 2, 'HOURS', 4.8, 'Горячий источник Гарм-Чашма', 'Garm Chashma Hot Spring', 'Гарм-Чашма ыстық бұлағы', 37.03200000, 71.52300000, 'Garm Chashma Hot Spring Tajikistan', ARRAY['garm-chashma']::text[], ARRAY['khorog', 'garm-chashma']::text[], 'Garm Chashma Tajikistan.jpg', ARRAY['gbao-permit', 'wellness']::text[]),
    ('jelondy-hot-springs', 'jelondy', 'NATURE', 1, 'HOURS', 4.5, 'Горячие источники Джелонды', 'Jelondy Hot Springs', 'Джелонды ыстық бұлақтары', 37.68700000, 72.57500000, 'Jelondy Hot Springs Tajikistan', ARRAY['jelondy']::text[], ARRAY['khorog', 'murghab', 'jelondy']::text[], 'Pamir Highway Tajikistan.jpg', ARRAY['gbao-permit', 'remote']::text[]),
    ('ishkashim-border-market', 'ishkashim', 'MARKET', 1, 'HOURS', 4.4, 'Приграничный базар Ишкашима', 'Ishkashim Afghan Border Market', 'Ишкашим шекара базары', 36.72400000, 71.61100000, 'Ishkashim Afghan Border Market Tajikistan', ARRAY['ishkashim']::text[], ARRAY['khorog', 'ishkashim']::text[], 'Ishkashim Tajikistan.jpg', ARRAY['gbao-permit', 'border-zone', 'seasonal-access']::text[]),
    ('wakhan-valley-road', 'wakhan-valley', 'NATURE', 8, 'HOURS', 4.9, 'Ваханская долина', 'Wakhan Valley Road', 'Вахан аңғары жолы', 36.80000000, 72.20000000, 'Wakhan Valley Tajikistan', ARRAY['wakhan-valley', 'ishkashim']::text[], ARRAY['khorog', 'ishkashim', 'wakhan-valley']::text[], 'Wakhan Valley Tajikistan.jpg', ARRAY['gbao-permit', 'border-zone', 'scenic-road']::text[]),
    ('yamchun-fortress', 'yamchun', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Крепость Ямчун', 'Yamchun Fortress', 'Ямчун қамалы', 36.96400000, 72.22200000, 'Yamchun Fortress Tajikistan', ARRAY['yamchun', 'wakhan-valley']::text[], ARRAY['ishkashim', 'wakhan-valley', 'yamchun']::text[], 'Yamchun Fortress Tajikistan.jpg', ARRAY['gbao-permit', 'border-zone']::text[]),
    ('bibi-fatima-hot-springs', 'yamchun', 'NATURE', 1, 'HOURS', 4.7, 'Горячие источники Биби Фатима', 'Bibi Fatima Hot Springs', 'Биби Фатима ыстық бұлақтары', 36.96700000, 72.21500000, 'Bibi Fatima Hot Springs Tajikistan', ARRAY['yamchun']::text[], ARRAY['ishkashim', 'wakhan-valley', 'yamchun']::text[], 'Bibi Fatima Springs Tajikistan.jpg', ARRAY['gbao-permit', 'wellness', 'border-zone']::text[]),
    ('vrang-buddhist-stupa', 'vrang', 'TEMPLE', 1, 'HOURS', 4.6, 'Буддийская ступа Вранга', 'Vrang Buddhist Stupa', 'Вранг будда ступасы', 36.97000000, 72.49000000, 'Vrang Buddhist Stupa Tajikistan', ARRAY['vrang', 'wakhan-valley']::text[], ARRAY['ishkashim', 'wakhan-valley', 'vrang']::text[], 'Vrang Buddhist Stupa.jpg', ARRAY['gbao-permit', 'border-zone']::text[]),
    ('langar-petroglyphs', 'langar', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Петроглифы Лангара', 'Langar Petroglyphs', 'Лангар петроглифтері', 37.00000000, 72.66000000, 'Langar Petroglyphs Tajikistan', ARRAY['langar', 'wakhan-valley']::text[], ARRAY['ishkashim', 'wakhan-valley', 'langar']::text[], 'Langar Petroglyphs Tajikistan.jpg', ARRAY['gbao-permit', 'border-zone']::text[]),
    ('yashilkul-bulunkul-lakes', 'bulunkul', 'NATURE', 5, 'HOURS', 4.8, 'Озера Яшилькуль и Булункуль', 'Yashilkul and Bulunkul Lakes', 'Яшылкөл және Бұланкөл көлдері', 37.72000000, 72.95000000, 'Yashilkul Bulunkul Lakes Tajikistan', ARRAY['bulunkul']::text[], ARRAY['khorog', 'murghab', 'bulunkul']::text[], 'Yashilkul Tajikistan.jpg', ARRAY['gbao-permit', 'remote']::text[]),
    ('karakul-lake', 'karakul', 'NATURE', 4, 'HOURS', 4.9, 'Озеро Каракуль', 'Lake Karakul', 'Қаракөл көлі', 39.01670000, 73.46670000, 'Lake Karakul Tajikistan', ARRAY['karakul']::text[], ARRAY['murghab', 'karakul']::text[], 'Lake Karakul Tajikistan.jpg', ARRAY['gbao-permit', 'remote', 'border-zone']::text[]),
    ('murghab-bazaar', 'murghab', 'MARKET', 1, 'HOURS', 4.4, 'Базар Мургаба', 'Murghab Bazaar', 'Мурғаб базары', 38.17000000, 73.96600000, 'Murghab Bazaar Tajikistan', ARRAY['murghab']::text[], ARRAY['murghab']::text[], 'Murghab Tajikistan.jpg', ARRAY['gbao-permit', 'remote', 'local-market']::text[]),
    ('pamir-highway-khorog-murghab', 'pamir-highway', 'NATURE', 8, 'HOURS', 4.9, 'Памирский тракт Хорог - Мургаб', 'Pamir Highway Khorog to Murghab', 'Памир тас жолы Хорог - Мурғаб', 37.95000000, 72.50000000, 'Pamir Highway Khorog Murghab Tajikistan', ARRAY['pamir-highway', 'khorog', 'murghab']::text[], ARRAY['khorog', 'murghab', 'pamir-highway']::text[], 'Pamir Highway Tajikistan.jpg', ARRAY['gbao-permit', 'remote', 'scenic-road']::text[]),

    ('avesta-regional-museum', 'bokhtar', 'MUSEUM', 1, 'HOURS', 4.5, 'Региональный музей Авеста', 'Avesta Regional Museum', 'Авеста өңірлік музейі', 37.83640000, 68.78030000, 'Avesta Regional Museum Bokhtar', ARRAY['bokhtar']::text[], ARRAY['bokhtar']::text[], 'Bokhtar Tajikistan.jpg', ARRAY['indoor']::text[]),
    ('ajina-teppa-buddhist-monastery', 'vakhsh', 'TEMPLE', 2, 'HOURS', 4.7, 'Буддийский монастырь Аджина-Теппа', 'Ajina-Teppa Buddhist Monastery', 'Аджина-Теппа будда монастыры', 37.82600000, 68.87000000, 'Ajina Teppa Buddhist Monastery Tajikistan', ARRAY['vakhsh', 'bokhtar']::text[], ARRAY['bokhtar', 'vakhsh']::text[], 'Ajina Teppa Tajikistan.jpg', ARRAY['ancient-khuttal']::text[]),
    ('hulbuk-fortress', 'vose-hulbuk', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Крепость Хулбук', 'Hulbuk Fortress', 'Хулбук қамалы', 37.80100000, 69.64400000, 'Hulbuk Fortress Tajikistan', ARRAY['vose-hulbuk']::text[], ARRAY['kulob', 'vose-hulbuk']::text[], 'Hulbuk Fortress Tajikistan.jpg', ARRAY['ancient-khuttal']::text[]),
    ('hulbuk-museum-reserve', 'vose-hulbuk', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей-заповедник Хулбук', 'Hulbuk Museum-Reserve', 'Хулбук музей-қорығы', 37.80130000, 69.64430000, 'Hulbuk Museum Reserve Tajikistan', ARRAY['vose-hulbuk']::text[], ARRAY['kulob', 'vose-hulbuk']::text[], 'Hulbuk Tajikistan.jpg', ARRAY['indoor']::text[]),
    ('mir-sayyid-ali-hamadani-mausoleum', 'kulob', 'TEMPLE', 1, 'HOURS', 4.8, 'Мавзолей Мир Сайида Али Хамадони', 'Mir Sayyid Ali Hamadani Mausoleum', 'Мир Сайид Али Хамадони кесенесі', 37.91450000, 69.78180000, 'Mir Sayyid Ali Hamadani Mausoleum Kulob', ARRAY['kulob']::text[], ARRAY['kulob']::text[], 'Kulob Tajikistan.jpg', ARRAY['pilgrimage']::text[]),
    ('kulob-2700-anniversary-center', 'kulob', 'MUSEUM', 1, 'HOURS', 4.5, 'Музейный комплекс 2700-летия Куляба', 'Kulob 2700th Anniversary Center', 'Куляб 2700 жылдық орталығы', 37.91400000, 69.78300000, 'Kulob 2700th Anniversary Center Tajikistan', ARRAY['kulob']::text[], ARRAY['kulob']::text[], 'Kulob Tajikistan.jpg', ARRAY['city-history']::text[]),
    ('sari-khosor-waterfall', 'sari-khosor', 'NATURE', 5, 'HOURS', 4.8, 'Водопад Сары-Хосор', 'Sari Khosor Waterfall', 'Сары-Хосор сарқырамасы', 38.25500000, 69.95500000, 'Sari Khosor Waterfall Tajikistan', ARRAY['sari-khosor', 'baljuvon']::text[], ARRAY['kulob', 'sari-khosor']::text[], 'Sari Khosor Tajikistan.jpg', ARRAY['seasonal-access', 'off-road']::text[]),
    ('tigrovaya-balka-nature-reserve', 'dusti', 'NATURE', 6, 'HOURS', 4.9, 'Заповедник Тигровая Балка', 'Tigrovaya Balka Nature Reserve', 'Тигровая Балка қорығы', 37.15000000, 68.45000000, 'Tigrovaya Balka Nature Reserve Tajikistan', ARRAY['dusti']::text[], ARRAY['bokhtar', 'dusti']::text[], 'Tigrovaya Balka Tajikistan.jpg', ARRAY['unesco', 'permit', 'border-zone']::text[]),
    ('khoja-mashhad-mausoleum', 'shahrituz', 'TEMPLE', 2, 'HOURS', 4.8, 'Мавзолей и медресе Ходжа Машхад', 'Khoja Mashhad Mausoleum and Madrasa', 'Қожа Машхад кесенесі мен медресесі', 37.22600000, 68.13800000, 'Khoja Mashhad Mausoleum Shahrituz Tajikistan', ARRAY['shahrituz']::text[], ARRAY['bokhtar', 'shahrituz']::text[], 'Khoja Mashhad Tajikistan.jpg', ARRAY['ancient-khuttal']::text[]),
    ('chiluchor-chashma-springs', 'nosiri-khusrav', 'NATURE', 2, 'HOURS', 4.7, 'Чилучор Чашма', 'Chiluchor Chashma Springs', 'Чилучор Чашма бұлақтары', 37.10100000, 68.31000000, 'Chiluchor Chashma Tajikistan', ARRAY['nosiri-khusrav']::text[], ARRAY['bokhtar', 'nosiri-khusrav']::text[], 'Chiluchor Chashma Tajikistan.jpg', ARRAY['pilgrimage']::text[]),
    ('takhti-sangin-oxus-temple', 'qubodiyon', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Тахти Сангин храм Окса', 'Takhti Sangin Oxus Temple', 'Тахти Сангин Окс ғибадатханасы', 37.10400000, 68.13900000, 'Takhti Sangin Oxus Temple Tajikistan', ARRAY['qubodiyon']::text[], ARRAY['bokhtar', 'qubodiyon']::text[], 'Takhti Sangin Tajikistan.jpg', ARRAY['border-zone', 'ancient-khuttal']::text[]),
    ('childukhtaron-mountain', 'muminobod', 'NATURE', 5, 'HOURS', 4.8, 'Гора Чилдухтарон', 'Childukhtaron Mountain', 'Чилдухтарон тауы', 38.02500000, 70.05000000, 'Childukhtaron Mountain Tajikistan', ARRAY['muminobod']::text[], ARRAY['kulob', 'muminobod']::text[], 'Childukhtaron Tajikistan.jpg', ARRAY['scenic']::text[]);

CREATE TEMP TABLE seed_tajikistan_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-tajikistan-place:' || seed.slug) AS place_hash,
        md5('id-tajikistan-media:' || seed.slug) AS media_hash
    FROM seed_tajikistan_priority_places seed
)
SELECT
    (
        substr(place_hash, 1, 8) || '-' ||
        substr(place_hash, 9, 4) || '-4' ||
        substr(place_hash, 14, 3) || '-8' ||
        substr(place_hash, 18, 3) || '-' ||
        substr(place_hash, 21, 12)
    )::uuid AS id,
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    ARRAY['tajikistan', city_id, slug, lower(category), 'tajikistan-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Таджикистана: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Tajikistan tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Тәжікстан туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
    access_city_ids,
    departure_city_ids,
    (
        substr(media_hash, 1, 8) || '-' ||
        substr(media_hash, 9, 4) || '-4' ||
        substr(media_hash, 14, 3) || '-8' ||
        substr(media_hash, 18, 3) || '-' ||
        substr(media_hash, 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || media_file || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || media_file AS source_url
FROM hashed;

INSERT INTO places (
    id,
    author_user_id,
    country_code,
    city_id,
    category,
    default_locale,
    source,
    status,
    duration_value,
    duration_unit,
    price_amount,
    price_currency,
    rating,
    tags,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'TJ',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 60::numeric
        ELSE 30::numeric
    END,
    'TJS',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_tajikistan_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    default_locale = EXCLUDED.default_locale,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    rating = EXCLUDED.rating,
    tags = EXCLUDED.tags,
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
    'ru',
    title_ru,
    description_ru,
    NOW(),
    NOW()
FROM seed_tajikistan_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
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
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_tajikistan_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
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
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_tajikistan_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE places a
SET
    latitude = seed.latitude,
    longitude = seed.longitude,
    location_source_url = seed.location_source_url,
    updated_at = NOW()
FROM seed_tajikistan_resolved_places seed
WHERE a.id = seed.id;

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
    source_url,
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM seed_tajikistan_resolved_places
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
    id,
    place_id,
    kind,
    country_code,
    city_id,
    position,
    created_at
)
SELECT
    gen_random_uuid(),
    id,
    'ACCESS',
    'TJ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_tajikistan_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

INSERT INTO place_city_links (
    id,
    place_id,
    kind,
    country_code,
    city_id,
    position,
    created_at
)
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'TJ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_tajikistan_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
