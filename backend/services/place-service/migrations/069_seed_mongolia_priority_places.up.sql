-- Priority Mongolia destination places seed.
-- The seed covers Ulaanbaatar, Central Mongolia, the Gobi, Khuvsgul, Altai and eastern steppe routes.

DROP TABLE IF EXISTS seed_mongolia_resolved_places;
DROP TABLE IF EXISTS seed_mongolia_priority_places;

CREATE TEMP TABLE seed_mongolia_priority_places (
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

INSERT INTO seed_mongolia_priority_places (
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
    ('chinggis-khaan-national-museum', 'ulaanbaatar', 'MUSEUM', 2, 'HOURS', 4.8, 'Национальный музей Чингисхана', 'Chinggis Khaan National Museum', 'Шыңғыс хан ұлттық музейі', 47.92070000, 106.91500000, 'Chinggis Khaan National Museum Ulaanbaatar Mongolia', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Chinggis Khaan National Museum Mongolia.jpg', ARRAY['indoor']::text[]),
    ('sukhbaatar-square', 'ulaanbaatar', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Сухэ-Батора', 'Sukhbaatar Square', 'Сүхбаатар алаңы', 47.91890000, 106.91760000, 'Sukhbaatar Square Ulaanbaatar Mongolia', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Sukhbaatar Square Ulaanbaatar.jpg', ARRAY['city-symbol']::text[]),
    ('gandantegchinlen-monastery', 'ulaanbaatar', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Гандан', 'Gandantegchinlen Monastery', 'Гандан Тэгчинлин монастыры', 47.92290000, 106.89430000, 'Gandantegchinlen Monastery Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Gandantegchinlen Monastery Ulaanbaatar.jpg', ARRAY['buddhist-heritage']::text[]),
    ('national-museum-mongolia', 'ulaanbaatar', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Монголии', 'National Museum of Mongolia', 'Моңғолия ұлттық музейі', 47.92070000, 106.91560000, 'National Museum of Mongolia Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'National Museum of Mongolia.jpg', ARRAY['indoor']::text[]),
    ('choijin-lama-temple-museum', 'ulaanbaatar', 'TEMPLE', 2, 'HOURS', 4.7, 'Музей-храм Чойжин-ламы', 'Choijin Lama Temple Museum', 'Чойжин лам ғибадатхана музейі', 47.91560000, 106.91800000, 'Choijin Lama Temple Museum Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Choijin Lama Temple Museum.jpg', ARRAY['indoor', 'buddhist-heritage']::text[]),
    ('bogd-khaan-palace-museum', 'ulaanbaatar', 'MUSEUM', 2, 'HOURS', 4.7, 'Дворец-музей Богдо-хана', 'Bogd Khaan Palace Museum', 'Богд хан сарай музейі', 47.89700000, 106.90700000, 'Bogd Khaan Palace Museum Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Bogd Khan Palace Museum.jpg', ARRAY['indoor']::text[]),
    ('zanabazar-fine-arts-museum', 'ulaanbaatar', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей изобразительных искусств имени Дзанабазара', 'Fine Arts Zanabazar Museum', 'Дзанабазар бейнелеу өнері музейі', 47.91930000, 106.90740000, 'Fine Arts Zanabazar Museum Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Zanabazar Museum of Fine Arts.jpg', ARRAY['indoor', 'art']::text[]),
    ('zaisan-memorial', 'ulaanbaatar', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мемориал Зайсан', 'Zaisan Memorial', 'Зайсан мемориалы', 47.88460000, 106.91590000, 'Zaisan Memorial Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Zaisan Memorial Ulaanbaatar.jpg', ARRAY['viewpoint']::text[]),
    ('national-garden-park', 'ulaanbaatar', 'PARK', 2, 'HOURS', 4.6, 'Национальный садовый парк', 'National Garden Park', 'Ұлттық бақ саябағы', 47.90030000, 106.94330000, 'National Garden Park Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Ulaanbaatar National Garden Park.jpg', ARRAY['family']::text[]),
    ('national-amusement-park-mongolia', 'ulaanbaatar', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Национальный парк развлечений', 'National Amusement Park Mongolia', 'Моңғолия ұлттық ойын-сауық саябағы', 47.91200000, 106.92070000, 'National Amusement Park Ulaanbaatar Mongolia', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'National Amusement Park Ulaanbaatar.jpg', ARRAY['family']::text[]),
    ('narantuul-market', 'ulaanbaatar', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Нарантуул', 'Narantuul Market', 'Нарантуул базары', 47.90870000, 106.95300000, 'Narantuul Market Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Narantuul Market Ulaanbaatar.jpg', ARRAY['local-market']::text[]),
    ('state-department-store', 'ulaanbaatar', 'SHOPPING', 2, 'HOURS', 4.5, 'Государственный универмаг', 'State Department Store', 'Мемлекеттік әмбебап дүкен', 47.91670000, 106.90580000, 'State Department Store Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'State Department Store Ulaanbaatar.jpg', ARRAY['cashmere', 'souvenirs']::text[]),
    ('shangri-la-mall-ulaanbaatar', 'ulaanbaatar', 'SHOPPING', 2, 'HOURS', 4.6, 'ТРЦ Shangri-La Улан-Батор', 'Shangri-La Mall Ulaanbaatar', 'Shangri-La Mall Улан-Батор', 47.91380000, 106.92230000, 'Shangri-La Mall Ulaanbaatar', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Shangri-La Ulaanbaatar.jpg', ARRAY['indoor']::text[]),
    ('seoul-street-dining-area', 'ulaanbaatar', 'FOOD', 2, 'HOURS', 4.5, 'Улица Сеул и ресторанный квартал', 'Seoul Street Dining Area', 'Сеул көшесі және мейрамхана ауданы', 47.91300000, 106.91000000, 'Seoul Street Ulaanbaatar restaurants', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Ulaanbaatar city center.jpg', ARRAY['evening']::text[]),
    ('sky-resort-ulaanbaatar', 'ulaanbaatar', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Горнолыжный курорт Sky Resort', 'Sky Resort Ulaanbaatar', 'Sky Resort Улан-Батор', 47.87800000, 107.03600000, 'Sky Resort Ulaanbaatar Mongolia', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], 'Ulaanbaatar Bogd Khan Mountain.jpg', ARRAY['winter', 'family']::text[]),

    ('gorkhi-terelj-national-park', 'gorkhi-terelj', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Горхи-Тэрэлж', 'Gorkhi-Terelj National Park', 'Горхи-Тэрэлж ұлттық паркі', 47.98400000, 107.47500000, 'Gorkhi Terelj National Park Mongolia', ARRAY['gorkhi-terelj']::text[], ARRAY['ulaanbaatar', 'gorkhi-terelj']::text[], 'Gorkhi-Terelj National Park Mongolia.jpg', ARRAY['day-trip', 'nature']::text[]),
    ('turtle-rock-terelj', 'gorkhi-terelj', 'NATURE', 1, 'HOURS', 4.7, 'Скала Черепаха', 'Turtle Rock Terelj', 'Тасбақа жартасы Терэлж', 47.90770000, 107.42100000, 'Turtle Rock Terelj Mongolia', ARRAY['gorkhi-terelj']::text[], ARRAY['ulaanbaatar', 'gorkhi-terelj']::text[], 'Turtle Rock Terelj Mongolia.jpg', ARRAY['photo-stop']::text[]),
    ('aryabal-meditation-temple', 'gorkhi-terelj', 'TEMPLE', 2, 'HOURS', 4.7, 'Медитационный храм Арьяабал', 'Aryabal Meditation Temple', 'Арьяабал медитация ғибадатханасы', 47.89600000, 107.43200000, 'Aryabal Meditation Temple Terelj Mongolia', ARRAY['gorkhi-terelj']::text[], ARRAY['ulaanbaatar', 'gorkhi-terelj']::text[], 'Aryabal Meditation Temple.jpg', ARRAY['buddhist-heritage']::text[]),
    ('chinggis-khaan-statue-complex', 'tsonjin-boldog', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Комплекс конной статуи Чингисхана', 'Chinggis Khaan Statue Complex', 'Шыңғыс хан ескерткіші кешені', 47.80790000, 107.52900000, 'Chinggis Khaan Statue Complex Tsonjin Boldog', ARRAY['tsonjin-boldog']::text[], ARRAY['ulaanbaatar', 'tsonjin-boldog']::text[], 'Genghis Khan Equestrian Statue.jpg', ARRAY['day-trip', 'city-symbol']::text[]),
    ('manzushir-monastery', 'zuunmod', 'TEMPLE', 3, 'HOURS', 4.6, 'Монастырь Манзушир', 'Manzushir Monastery', 'Манзушир монастыры', 47.76000000, 106.98500000, 'Manzushir Monastery Mongolia', ARRAY['zuunmod']::text[], ARRAY['ulaanbaatar', 'zuunmod']::text[], 'Manzushir Monastery Mongolia.jpg', ARRAY['day-trip', 'hiking']::text[]),
    ('khustai-national-park', 'khustai', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Хустай', 'Khustai National Park', 'Хустай ұлттық паркі', 47.70000000, 105.90000000, 'Khustai National Park Mongolia', ARRAY['khustai']::text[], ARRAY['ulaanbaatar', 'khustai']::text[], 'Przewalski horse Hustai National Park.jpg', ARRAY['wildlife', 'day-trip']::text[]),

    ('orkhon-valley-cultural-landscape', 'orkhon-valley', 'NATURE', 8, 'HOURS', 4.9, 'Культурный ландшафт долины Орхона', 'Orkhon Valley Cultural Landscape', 'Орхон аңғарының мәдени ландшафты', 47.20000000, 102.80000000, 'Orkhon Valley Cultural Landscape Mongolia', ARRAY['orkhon-valley', 'kharkhorin']::text[], ARRAY['ulaanbaatar', 'kharkhorin', 'orkhon-valley']::text[], 'Orkhon Valley Mongolia.jpg', ARRAY['unesco', 'scenic-road']::text[]),
    ('erdene-zuu-monastery', 'kharkhorin', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Эрдэнэ-Зуу', 'Erdene Zuu Monastery', 'Эрдэнэ-Зуу монастыры', 47.20000000, 102.84000000, 'Erdene Zuu Monastery Kharkhorin Mongolia', ARRAY['kharkhorin', 'orkhon-valley']::text[], ARRAY['kharkhorin', 'ulaanbaatar']::text[], 'Erdene Zuu Monastery.jpg', ARRAY['unesco', 'buddhist-heritage']::text[]),
    ('ancient-karakorum-ruins', 'kharkhorin', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Руины древнего Каракорума', 'Ancient Karakorum Ruins', 'Ежелгі Қарақорым қалдықтары', 47.20000000, 102.84000000, 'Karakorum ruins Kharkhorin Mongolia', ARRAY['kharkhorin', 'orkhon-valley']::text[], ARRAY['kharkhorin']::text[], 'Karakorum Mongolia.jpg', ARRAY['unesco', 'history']::text[]),
    ('karakorum-museum', 'kharkhorin', 'MUSEUM', 1, 'HOURS', 4.7, 'Музей Хархорума', 'Karakorum Museum', 'Қарақорым музейі', 47.20000000, 102.82000000, 'Karakorum Museum Kharkhorin Mongolia', ARRAY['kharkhorin']::text[], ARRAY['kharkhorin']::text[], 'Karakorum Museum Mongolia.jpg', ARRAY['indoor']::text[]),
    ('tuvkhun-monastery', 'tuvkhun', 'TEMPLE', 4, 'HOURS', 4.8, 'Монастырь Тувхун', 'Tuvkhun Monastery', 'Тувхун монастыры', 47.02000000, 102.27000000, 'Tuvkhun Monastery Mongolia', ARRAY['tuvkhun', 'orkhon-valley']::text[], ARRAY['kharkhorin', 'tuvkhun']::text[], 'Tuvkhun Monastery Mongolia.jpg', ARRAY['unesco', 'hiking']::text[]),
    ('orkhon-waterfall', 'orkhon-valley', 'NATURE', 4, 'HOURS', 4.8, 'Водопад Орхон', 'Orkhon Waterfall Ulaan Tsutgalan', 'Орхон сарқырамасы', 46.79000000, 101.96000000, 'Orkhon Waterfall Ulaan Tsutgalan Mongolia', ARRAY['orkhon-valley']::text[], ARRAY['kharkhorin', 'orkhon-valley']::text[], 'Orkhon Waterfall Mongolia.jpg', ARRAY['hiking']::text[]),
    ('zaya-gegeen-monastery-arkhangai-museum', 'tsetserleg', 'MUSEUM', 2, 'HOURS', 4.6, 'Монастырь Зая Гэгээн и музей Архангай', 'Zaya Gegeen Monastery and Arkhangai Museum', 'Зая Гэгээн монастыры және Архангай музейі', 47.47000000, 101.45000000, 'Zaya Gegeen Monastery Tsetserleg Mongolia', ARRAY['tsetserleg']::text[], ARRAY['tsetserleg']::text[], 'Tsetserleg Mongolia.jpg', ARRAY['indoor']::text[]),
    ('taikhar-rock', 'tsetserleg', 'NATURE', 1, 'HOURS', 4.6, 'Скала Тайхар', 'Taikhar Rock', 'Тайхар жартасы', 47.56000000, 101.17000000, 'Taikhar Rock Mongolia', ARRAY['tsetserleg']::text[], ARRAY['tsetserleg']::text[], 'Taikhar Rock Mongolia.jpg', ARRAY['photo-stop']::text[]),
    ('tsenkher-hot-springs', 'tsenkher', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Горячие источники Цэнхэр', 'Tsenkher Hot Springs', 'Цэнхэр ыстық бұлақтары', 47.32000000, 101.65000000, 'Tsenkher Hot Springs Mongolia', ARRAY['tsenkher', 'tsetserleg']::text[], ARRAY['tsetserleg', 'tsenkher']::text[], 'Tsenkher Hot Springs Mongolia.jpg', ARRAY['wellness']::text[]),
    ('khorgo-terkhiin-tsagaan-nuur-national-park', 'khorgo-terkhiin-tsagaan-nuur', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Хорго-Тэрхийн-Цагаан-Нуур', 'Khorgo-Terkhiin Tsagaan Nuur National Park', 'Хорго-Тэрхийн-Цагаан-Нуур ұлттық паркі', 48.16000000, 99.85000000, 'Khorgo Terkhiin Tsagaan Nuur National Park Mongolia', ARRAY['khorgo-terkhiin-tsagaan-nuur']::text[], ARRAY['tsetserleg', 'khorgo-terkhiin-tsagaan-nuur']::text[], 'Terkhiin Tsagaan Lake Mongolia.jpg', ARRAY['volcano', 'lake']::text[]),

    ('khuvsgul-lake-national-park', 'khuvsgul', 'NATURE', 8, 'HOURS', 4.9, 'Национальный парк озера Хубсугул', 'Khuvsgul Lake National Park', 'Хөвсгөл көлі ұлттық паркі', 51.11000000, 100.85000000, 'Khuvsgul Lake National Park Mongolia', ARRAY['khuvsgul', 'khatgal']::text[], ARRAY['murun', 'khuvsgul', 'khatgal']::text[], 'Lake Khuvsgul Mongolia.jpg', ARRAY['biosphere', 'lake']::text[]),
    ('khatgal-lake-shore', 'khatgal', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Хатгал и берег Хубсугула', 'Khatgal Village and Lake Shore', 'Хатгал және Хөвсгөл жағалауы', 50.43000000, 100.15000000, 'Khatgal Khuvsgul Mongolia', ARRAY['khatgal', 'khuvsgul']::text[], ARRAY['murun', 'khatgal']::text[], 'Khatgal Khuvsgul Mongolia.jpg', ARRAY['lake', 'base-camp']::text[]),
    ('khuvsgul-aimag-museum', 'murun', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей аймака Хубсугул', 'Khuvsgul Aimag Museum', 'Хөвсгөл аймағы музейі', 49.63000000, 100.16000000, 'Khuvsgul Aimag Museum Murun Mongolia', ARRAY['murun']::text[], ARRAY['murun']::text[], 'Murun Mongolia.jpg', ARRAY['indoor']::text[]),
    ('murun-black-market', 'murun', 'MARKET', 1, 'HOURS', 4.3, 'Мурунский рынок', 'Murun Black Market', 'Мөрөн базары', 49.63000000, 100.17000000, 'Murun market Mongolia', ARRAY['murun']::text[], ARRAY['murun']::text[], 'Murun Mongolia.jpg', ARRAY['local-market']::text[]),
    ('amarbayasgalant-monastery', 'amarbayasgalant', 'TEMPLE', 3, 'HOURS', 4.8, 'Монастырь Амарбаясгалант', 'Amarbayasgalant Monastery', 'Амарбаясгалант монастыры', 49.47000000, 105.09000000, 'Amarbayasgalant Monastery Mongolia', ARRAY['amarbayasgalant']::text[], ARRAY['darkhan', 'erdenet', 'amarbayasgalant']::text[], 'Amarbayasgalant Monastery Mongolia.jpg', ARRAY['buddhist-heritage']::text[]),
    ('darkhan-central-market', 'darkhan', 'MARKET', 1, 'HOURS', 4.2, 'Центральный рынок Дархана', 'Darkhan Central Market', 'Дархан орталық базары', 49.48600000, 105.92200000, 'Darkhan Central Market Mongolia', ARRAY['darkhan']::text[], ARRAY['darkhan']::text[], 'Darkhan Mongolia.jpg', ARRAY['local-market']::text[]),
    ('erdenet-mining-museum', 'erdenet', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей Эрдэнэтийн горно-обогатительного комбината', 'Erdenet Mining Museum', 'Эрдэнэт тау-кен музейі', 49.02700000, 104.04500000, 'Erdenet Mining Museum Mongolia', ARRAY['erdenet']::text[], ARRAY['erdenet']::text[], 'Erdenet Mongolia.jpg', ARRAY['indoor']::text[]),

    ('gobi-gurvansaikhan-national-park', 'dalanzadgad', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Гоби-Гурвансайхан', 'Gobi Gurvansaikhan National Park', 'Гоби-Гурвансайхан ұлттық паркі', 43.65000000, 104.00000000, 'Gobi Gurvansaikhan National Park Mongolia', ARRAY['dalanzadgad']::text[], ARRAY['dalanzadgad']::text[], 'Gobi Gurvansaikhan National Park.jpg', ARRAY['gobi', 'wildlife']::text[]),
    ('gobi-museum-nature-history', 'dalanzadgad', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей природы и истории Гоби', 'The Gobi Museum of Nature and History', 'Гоби табиғат және тарих музейі', 43.57000000, 104.43000000, 'Gobi Museum of Nature and History Dalanzadgad', ARRAY['dalanzadgad']::text[], ARRAY['dalanzadgad']::text[], 'Dalanzadgad Mongolia.jpg', ARRAY['indoor', 'dinosaurs']::text[]),
    ('yolyn-am-gorge', 'yolyn-am', 'NATURE', 4, 'HOURS', 4.8, 'Ущелье Ёлын-Ам', 'Yolyn Am Gorge', 'Ёлын-Ам шатқалы', 43.48000000, 104.07000000, 'Yolyn Am Gorge Mongolia', ARRAY['yolyn-am', 'dalanzadgad']::text[], ARRAY['dalanzadgad', 'yolyn-am']::text[], 'Yolyn Am Mongolia.jpg', ARRAY['gobi', 'hiking']::text[]),
    ('khongoryn-els-sand-dunes', 'khongoryn-els', 'NATURE', 5, 'HOURS', 4.9, 'Дюны Хонгорын-Элс', 'Khongoryn Els Sand Dunes', 'Хонгорын-Элс құм төбелері', 43.82000000, 102.28000000, 'Khongoryn Els Sand Dunes Mongolia', ARRAY['khongoryn-els']::text[], ARRAY['dalanzadgad', 'khongoryn-els']::text[], 'Khongoryn Els Mongolia.jpg', ARRAY['gobi', 'camel-riding']::text[]),
    ('bayanzag-flaming-cliffs', 'bayanzag', 'NATURE', 3, 'HOURS', 4.8, 'Баянзаг Пылающие скалы', 'Bayanzag Flaming Cliffs', 'Баянзаг жалынды жартастары', 44.15000000, 103.72000000, 'Bayanzag Flaming Cliffs Mongolia', ARRAY['bayanzag']::text[], ARRAY['dalanzadgad', 'bayanzag']::text[], 'Flaming Cliffs Bayanzag Mongolia.jpg', ARRAY['gobi', 'dinosaurs']::text[]),
    ('tsagaan-suvarga-white-stupa', 'tsagaan-suvarga', 'NATURE', 2, 'HOURS', 4.7, 'Цагаан-Суварга Белая ступа', 'Tsagaan Suvarga White Stupa', 'Цагаан-Суварга ақ ступасы', 44.58000000, 105.76000000, 'Tsagaan Suvarga White Stupa Mongolia', ARRAY['tsagaan-suvarga']::text[], ARRAY['ulaanbaatar', 'tsagaan-suvarga', 'dalanzadgad']::text[], 'Tsagaan Suvarga Mongolia.jpg', ARRAY['gobi', 'photo-stop']::text[]),
    ('baga-gazriin-chuluu', 'baga-gazriin-chuluu', 'NATURE', 3, 'HOURS', 4.6, 'Бага-Газрын-Чулуу', 'Baga Gazriin Chuluu', 'Бага-Газрын-Чулуу', 46.18000000, 106.01000000, 'Baga Gazriin Chuluu Mongolia', ARRAY['baga-gazriin-chuluu']::text[], ARRAY['ulaanbaatar', 'baga-gazriin-chuluu']::text[], 'Baga Gazriin Chuluu Mongolia.jpg', ARRAY['gobi', 'hiking']::text[]),
    ('khamaryn-khiid-monastery', 'khamaryn-khiid', 'TEMPLE', 3, 'HOURS', 4.7, 'Монастырь Хамарын-Хийд', 'Khamaryn Khiid Monastery', 'Хамарын-Хийд монастыры', 44.60000000, 110.18000000, 'Khamaryn Khiid Monastery Mongolia', ARRAY['khamaryn-khiid', 'sainshand']::text[], ARRAY['sainshand', 'khamaryn-khiid']::text[], 'Khamaryn Khiid Mongolia.jpg', ARRAY['pilgrimage', 'gobi']::text[]),
    ('danzanravjaa-museum', 'sainshand', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Данзанравжаа', 'Danzanravjaa Museum', 'Данзанравжаа музейі', 44.89000000, 110.14000000, 'Danzanravjaa Museum Sainshand Mongolia', ARRAY['sainshand']::text[], ARRAY['sainshand']::text[], 'Sainshand Mongolia.jpg', ARRAY['indoor']::text[]),
    ('khermen-tsav-canyon', 'khermen-tsav', 'NATURE', 6, 'HOURS', 4.8, 'Каньон Хэрмэн-Цав', 'Khermen Tsav Canyon', 'Хэрмэн-Цав каньоны', 43.45000000, 100.50000000, 'Khermen Tsav Canyon Mongolia', ARRAY['khermen-tsav']::text[], ARRAY['dalanzadgad', 'khermen-tsav']::text[], 'Khermen Tsav Mongolia.jpg', ARRAY['gobi', 'remote']::text[]),

    ('altai-tavan-bogd-national-park', 'altai-tavan-bogd', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Алтай-Таван-Богд', 'Altai Tavan Bogd National Park', 'Алтай-Таван-Богд ұлттық паркі', 48.90000000, 88.00000000, 'Altai Tavan Bogd National Park Mongolia', ARRAY['altai-tavan-bogd', 'ulgii']::text[], ARRAY['ulgii', 'altai-tavan-bogd']::text[], 'Altai Tavan Bogd National Park.jpg', ARRAY['remote', 'mountains']::text[]),
    ('petroglyphic-complexes-mongolian-altai', 'ulgii', 'MUSEUM', 4, 'HOURS', 4.9, 'Петроглифы Монгольского Алтая', 'Petroglyphic Complexes of the Mongolian Altai', 'Моңғол Алтайының петроглифтері', 49.33000000, 88.25000000, 'Petroglyphic Complexes of the Mongolian Altai', ARRAY['ulgii', 'altai-tavan-bogd']::text[], ARRAY['ulgii', 'altai-tavan-bogd']::text[], 'Mongolian Altai petroglyphs.jpg', ARRAY['unesco', 'remote']::text[]),
    ('olgii-aimag-museum', 'ulgii', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей аймака Баян-Улгий', 'Ulgii Aimag Museum', 'Өлгий аймақ музейі', 48.97000000, 89.97000000, 'Ulgii Aimag Museum Mongolia', ARRAY['ulgii']::text[], ARRAY['ulgii']::text[], 'Olgii Mongolia.jpg', ARRAY['indoor']::text[]),
    ('ulgii-bazaar', 'ulgii', 'MARKET', 1, 'HOURS', 4.4, 'Базар Улгия', 'Ulgii Bazaar Central Market', 'Өлгий орталық базары', 48.97000000, 89.96000000, 'Ulgii Bazaar Mongolia', ARRAY['ulgii']::text[], ARRAY['ulgii']::text[], 'Olgii Bazaar Mongolia.jpg', ARRAY['local-market']::text[]),
    ('golden-eagle-festival', 'ulgii', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Фестиваль беркутчи', 'Golden Eagle Festival', 'Бүркітшілер фестивалі', 48.98000000, 89.97000000, 'Golden Eagle Festival Ulgii Mongolia', ARRAY['ulgii']::text[], ARRAY['ulgii']::text[], 'Golden Eagle Festival Mongolia.jpg', ARRAY['seasonal', 'culture']::text[]),
    ('dornod-aimag-museum', 'choibalsan', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей и галерея Дорнода', 'Dornod Aimag Museum and Gallery', 'Дорнод аймақ музейі және галереясы', 48.08000000, 114.54000000, 'Dornod Aimag Museum Choibalsan Mongolia', ARRAY['choibalsan']::text[], ARRAY['choibalsan']::text[], 'Choibalsan Mongolia.jpg', ARRAY['indoor']::text[]),
    ('choibalsan-local-market', 'choibalsan', 'MARKET', 1, 'HOURS', 4.2, 'Местный рынок Чойбалсана', 'Choibalsan Local Market', 'Чойбалсан жергілікті базары', 48.07000000, 114.54000000, 'Choibalsan local market Mongolia', ARRAY['choibalsan']::text[], ARRAY['choibalsan']::text[], 'Choibalsan Mongolia.jpg', ARRAY['local-market']::text[]),
    ('khalkh-gol-memorial-complex', 'khalkh-gol', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Мемориальный комплекс Халхин-Гол', 'Khalkh Gol Memorial Complex', 'Халхин-Гол мемориал кешені', 47.76000000, 118.58000000, 'Khalkh Gol Victory Monument Mongolia', ARRAY['khalkh-gol']::text[], ARRAY['choibalsan', 'khalkh-gol']::text[], 'Khalkhin Gol Memorial Mongolia.jpg', ARRAY['history']::text[]),
    ('ikh-burkhant-complex', 'khalkh-gol', 'TEMPLE', 2, 'HOURS', 4.5, 'Комплекс Их Бурхант', 'Ikh Burkhant Complex', 'Их Бурхант кешені', 47.75000000, 118.35000000, 'Ikh Burkhant Complex Mongolia', ARRAY['khalkh-gol']::text[], ARRAY['choibalsan', 'khalkh-gol']::text[], 'Ikh Burkhant Mongolia.jpg', ARRAY['spiritual']::text[]),
    ('baldan-bereeven-monastery', 'binder', 'TEMPLE', 3, 'HOURS', 4.7, 'Монастырь Балдан-Бэрээвэн', 'Baldan Bereeven Monastery', 'Балдан-Бэрээвэн монастыры', 49.45000000, 109.45000000, 'Baldan Bereeven Monastery Mongolia', ARRAY['binder']::text[], ARRAY['ulaanbaatar', 'binder']::text[], 'Baldan Bereeven Monastery.jpg', ARRAY['remote', 'buddhist-heritage']::text[]);

CREATE TEMP TABLE seed_mongolia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-mongolia-place:' || seed.slug) AS place_hash,
        md5('id-mongolia-media:' || seed.slug) AS media_hash
    FROM seed_mongolia_priority_places seed
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
    ARRAY['mongolia', city_id, slug, lower(category), 'mongolia-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Монголии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Mongolia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Моңғолия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'MN',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20000::numeric
        ELSE 10000::numeric
    END,
    'MNT',
    duration_value,
    duration_unit,
    rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    tags,
    NOW(),
    NOW()
FROM seed_mongolia_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
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
SELECT id, 'ru', title_ru, description_ru, NOW(), NOW()
FROM seed_mongolia_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_mongolia_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_mongolia_resolved_places
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
FROM seed_mongolia_resolved_places seed
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
FROM seed_mongolia_resolved_places
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
    'MN',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_mongolia_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'MN',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_mongolia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_mongolia_resolved_places;
DROP TABLE IF EXISTS seed_mongolia_priority_places;
