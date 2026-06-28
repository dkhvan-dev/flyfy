-- Priority Belarus destination places seed.
-- The seed covers Minsk, Minsk region, Brest, Grodno, Mir, Nesvizh, Vitebsk, Polotsk, Mogilev, Gomel, national parks and lake resorts.

DROP TABLE IF EXISTS seed_belarus_resolved_places;
DROP TABLE IF EXISTS seed_belarus_priority_places;

CREATE TEMP TABLE seed_belarus_priority_places (
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

INSERT INTO seed_belarus_priority_places (
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
    ('national-art-museum-belarus', 'minsk', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный художественный музей Беларуси', 'National Art Museum of Belarus', 'Беларусь ұлттық өнер музейі', 53.89940000, 27.56030000, 'National Art Museum of Belarus Minsk', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'National_Art_Museum_of_Belarus.jpg', ARRAY['art', 'indoor']::text[]),
    ('great-patriotic-war-museum-minsk', 'minsk', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей истории Великой Отечественной войны', 'Belarusian State Museum of the Great Patriotic War', 'Ұлы Отан соғысы тарихы музейі', 53.91610000, 27.53840000, 'Belarusian State Museum of the Great Patriotic War Minsk', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Belarusian_Great_Patriotic_War_Museum.jpg', ARRAY['history', 'indoor']::text[]),
    ('national-library-belarus', 'minsk', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Национальная библиотека Беларуси', 'National Library of Belarus', 'Беларусь ұлттық кітапханасы', 53.93180000, 27.64660000, 'National Library of Belarus Minsk', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'National_Library_of_Belarus.jpg', ARRAY['viewpoint', 'city-symbol']::text[]),
    ('trinity-suburb-minsk', 'minsk', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Троицкое предместье', 'Trinity Suburb', 'Троицк маңы', 53.90950000, 27.55630000, 'Trinity Suburb Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Trinity_Suburb_Minsk.jpg', ARRAY['old-town', 'walk']::text[]),
    ('upper-town-minsk-city-hall', 'minsk', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Верхний город и Минская ратуша', 'Upper Town and Minsk City Hall', 'Жоғарғы қала және Минск ратушасы', 53.90400000, 27.55670000, 'Upper Town Minsk City Hall Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Minsk_City_Hall.jpg', ARRAY['old-town', 'walk']::text[]),
    ('victory-square-minsk', 'minsk', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Победы в Минске', 'Victory Square Minsk', 'Минск Жеңіс алаңы', 53.90990000, 27.57540000, 'Victory Square Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Victory_Square_Minsk.jpg', ARRAY['memorial', 'city-symbol']::text[]),
    ('island-of-tears-minsk', 'minsk', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Остров слез', 'Island of Tears', 'Көз жасы аралы', 53.91160000, 27.55480000, 'Island of Tears Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Island_of_Tears_Minsk.jpg', ARRAY['memorial', 'riverfront']::text[]),
    ('holy-spirit-cathedral-minsk', 'minsk', 'TEMPLE', 1, 'HOURS', 4.7, 'Кафедральный собор Сошествия Святого Духа', 'Holy Spirit Cathedral Minsk', 'Минск Қасиетті Рух кафедралы', 53.90470000, 27.55740000, 'Holy Spirit Cathedral Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Holy_Spirit_Cathedral_Minsk.jpg', ARRAY['cathedral']::text[]),
    ('central-botanical-garden-minsk', 'minsk', 'PARK', 2, 'HOURS', 4.7, 'Центральный ботанический сад Беларуси', 'Central Botanical Garden Minsk', 'Минск орталық ботаникалық бағы', 53.91670000, 27.61250000, 'Central Botanical Garden Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Central_Botanical_Garden_Minsk.jpg', ARRAY['garden', 'family']::text[]),
    ('victory-park-minsk', 'minsk', 'PARK', 2, 'HOURS', 4.7, 'Парк Победы в Минске', 'Victory Park Minsk', 'Минск Жеңіс саябағы', 53.92480000, 27.53450000, 'Victory Park Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Victory_Park_Minsk.jpg', ARRAY['green-space', 'riverfront']::text[]),
    ('gorky-park-minsk', 'minsk', 'PARK', 2, 'HOURS', 4.6, 'Парк Горького в Минске', 'Gorky Park Minsk', 'Минск Горький саябағы', 53.90260000, 27.57320000, 'Gorky Park Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Gorky_Park_Minsk.jpg', ARRAY['family', 'amusement']::text[]),
    ('minsk-zoo', 'minsk', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Минский зоопарк и Динопарк', 'Minsk Zoo and DinoPark', 'Минск зообағы және Динопарк', 53.84290000, 27.62670000, 'Minsk Zoo DinoPark Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Minsk_Zoo.jpg', ARRAY['family', 'zoo']::text[]),
    ('waterpark-lebyazhy', 'minsk', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Аквапарк Лебяжий', 'Waterpark Lebyazhy', 'Лебяжий аквапаркі', 53.95350000, 27.45200000, 'Waterpark Lebyazhy Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Waterpark_Lebyazhy.jpg', ARRAY['family', 'waterpark']::text[]),
    ('komarovsky-market', 'minsk', 'MARKET', 1, 'HOURS', 4.6, 'Комаровский рынок', 'Komarovsky Market', 'Комаров базары', 53.91680000, 27.57800000, 'Komarovsky Market Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Komarovsky_Market_Minsk.jpg', ARRAY['local-market', 'food']::text[]),
    ('pesochnitsa-food-yard', 'minsk', 'FOOD', 2, 'HOURS', 4.5, 'Песочница', 'Pesochnitsa Food Yard', 'Песочница фуд-корты', 53.91200000, 27.54450000, 'Pesochnitsa Food Yard Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Pesochnitsa_Minsk.jpg', ARRAY['food-yard', 'evening']::text[]),
    ('dana-mall', 'minsk', 'SHOPPING', 2, 'HOURS', 4.5, 'ТРЦ Dana Mall', 'Dana Mall', 'Dana Mall сауда орталығы', 53.93400000, 27.65120000, 'Dana Mall Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Dana_Mall_Minsk.jpg', ARRAY['mall', 'indoor']::text[]),
    ('galleria-minsk', 'minsk', 'SHOPPING', 2, 'HOURS', 4.5, 'ТРЦ Galleria Minsk', 'Galleria Minsk', 'Galleria Minsk сауда орталығы', 53.90820000, 27.54900000, 'Galleria Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Galleria_Minsk.jpg', ARRAY['mall', 'indoor']::text[]),
    ('zamok-mall-minsk', 'minsk', 'SHOPPING', 2, 'HOURS', 4.5, 'ТРЦ Замок', 'Zamok Mall', 'Замок сауда орталығы', 53.93540000, 27.48290000, 'Zamok Mall Minsk Belarus', ARRAY['minsk']::text[], ARRAY['minsk']::text[], 'Zamok_Mall_Minsk.jpg', ARRAY['mall', 'indoor']::text[]),

    ('dudutki-museum', 'dudutki', 'MUSEUM', 3, 'HOURS', 4.7, 'Музейный комплекс Дудутки', 'Dudutki Museum', 'Дудутки музей кешені', 53.59620000, 27.68290000, 'Dudutki Museum Complex Belarus', ARRAY['dudutki']::text[], ARRAY['minsk', 'dudutki']::text[], 'Dudutki_Museum.jpg', ARRAY['crafts', 'family']::text[]),
    ('sula-history-park', 'sula', 'MUSEUM', 3, 'HOURS', 4.7, 'Парк истории Сула', 'Sula History Park', 'Сула тарих паркі', 53.74210000, 26.87740000, 'Sula History Park Belarus', ARRAY['sula']::text[], ARRAY['minsk', 'sula']::text[], 'Sula_History_Park.jpg', ARRAY['history', 'interactive']::text[]),
    ('silichi-ski-resort', 'silichi', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Горнолыжный центр Силичи', 'Silichi Ski Resort', 'Силичи тау шаңғы орталығы', 54.15670000, 27.83330000, 'Silichi Ski Resort Belarus', ARRAY['silichi', 'logoisk']::text[], ARRAY['minsk', 'silichi', 'logoisk']::text[], 'Silichi_Ski_Resort.jpg', ARRAY['ski', 'outdoor']::text[]),
    ('logoisk-ski-complex', 'logoisk', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Горнолыжный комплекс Логойск', 'Logoisk Ski Complex', 'Логойск тау шаңғы кешені', 54.18350000, 27.81090000, 'Logoisk Ski Complex Belarus', ARRAY['logoisk']::text[], ARRAY['minsk', 'logoisk']::text[], 'Logoisk_Ski_Complex.jpg', ARRAY['ski', 'outdoor']::text[]),
    ('zaslavl-museum-reserve', 'zaslavl', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей-заповедник Заславль', 'Zaslavl Museum Reserve', 'Заславль музей-қорығы', 54.01100000, 27.26900000, 'Zaslavl Museum Reserve Belarus', ARRAY['zaslavl']::text[], ARRAY['minsk', 'zaslavl']::text[], 'Zaslavl_Museum_Reserve.jpg', ARRAY['history', 'heritage']::text[]),
    ('khatyn-memorial', 'khatyn', 'OTHER', 2, 'HOURS', 4.8, 'Мемориальный комплекс Хатынь', 'Khatyn Memorial Complex', 'Хатынь мемориалдық кешені', 54.33470000, 27.94300000, 'Khatyn Memorial Complex Belarus', ARRAY['khatyn']::text[], ARRAY['minsk', 'khatyn']::text[], 'Khatyn_Memorial.jpg', ARRAY['memorial', 'history']::text[]),
    ('stalin-line-historical-complex', 'stalin-line', 'MUSEUM', 3, 'HOURS', 4.6, 'Исторический комплекс Линия Сталина', 'Stalin Line Historical Complex', 'Сталин желісі тарихи кешені', 54.05700000, 27.29300000, 'Stalin Line Historical Complex Belarus', ARRAY['stalin-line', 'zaslavl']::text[], ARRAY['minsk', 'stalin-line', 'zaslavl']::text[], 'Stalin_Line_Belarus.jpg', ARRAY['military-history', 'outdoor']::text[]),

    ('mir-castle', 'mir', 'MUSEUM', 2, 'HOURS', 4.9, 'Мирский замок', 'Mir Castle', 'Мир қамалы', 53.45130000, 26.47270000, 'Mir Castle Belarus', ARRAY['mir']::text[], ARRAY['minsk', 'mir']::text[], 'Mir_Castle_Belarus.jpg', ARRAY['castle', 'unesco']::text[]),
    ('mir-castle-park', 'mir', 'PARK', 1, 'HOURS', 4.6, 'Парк Мирского замка', 'Mir Castle Park and Pond', 'Мир қамалы саябағы', 53.45100000, 26.47400000, 'Mir Castle Park Belarus', ARRAY['mir']::text[], ARRAY['mir']::text[], 'Mir_Castle_Park.jpg', ARRAY['castle-park', 'walk']::text[]),
    ('nesvizh-palace', 'nesvizh', 'MUSEUM', 3, 'HOURS', 4.9, 'Несвижский дворцово-парковый ансамбль', 'Nesvizh Palace', 'Несвиж сарай-саябақ ансамблі', 53.22260000, 26.69140000, 'Nesvizh Palace Belarus', ARRAY['nesvizh']::text[], ARRAY['minsk', 'nesvizh']::text[], 'Nesvizh_Palace.jpg', ARRAY['palace', 'unesco']::text[]),
    ('nesvizh-town-hall', 'nesvizh', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Несвижская ратуша', 'Nesvizh Town Hall', 'Несвиж ратушасы', 53.21990000, 26.67900000, 'Nesvizh Town Hall Belarus', ARRAY['nesvizh']::text[], ARRAY['nesvizh']::text[], 'Nesvizh_Town_Hall.jpg', ARRAY['old-town']::text[]),
    ('corpus-christi-church-nesvizh', 'nesvizh', 'TEMPLE', 1, 'HOURS', 4.6, 'Костел Божьего Тела в Несвиже', 'Corpus Christi Church Nesvizh', 'Несвиж Құдай денесі костелі', 53.21880000, 26.68150000, 'Corpus Christi Church Nesvizh Belarus', ARRAY['nesvizh']::text[], ARRAY['nesvizh']::text[], 'Corpus_Christi_Church_Nesvizh.jpg', ARRAY['church']::text[]),
    ('slutsk-gate-nesvizh', 'nesvizh', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Слуцкая брама', 'Slutsk Gate', 'Слуцк қақпасы', 53.21750000, 26.68410000, 'Slutsk Gate Nesvizh Belarus', ARRAY['nesvizh']::text[], ARRAY['nesvizh']::text[], 'Slutsk_Gate_Nesvizh.jpg', ARRAY['gate', 'old-town']::text[]),

    ('brest-fortress', 'brest', 'MUSEUM', 3, 'HOURS', 4.9, 'Брестская крепость-герой', 'Brest Fortress', 'Брест қамалы', 52.08360000, 23.65690000, 'Brest Fortress Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Brest_Fortress.jpg', ARRAY['memorial', 'history']::text[]),
    ('berestye-archaeological-museum', 'brest', 'MUSEUM', 1, 'HOURS', 4.6, 'Археологический музей Берестье', 'Berestye Archaeological Museum', 'Берестье археологиялық музейі', 52.08450000, 23.65380000, 'Berestye Archaeological Museum Brest Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Berestye_Archaeological_Museum.jpg', ARRAY['archaeology', 'indoor']::text[]),
    ('brest-railway-museum', 'brest', 'MUSEUM', 1, 'HOURS', 4.6, 'Брестский музей железнодорожной техники', 'Brest Railway Museum', 'Брест теміржол техникасы музейі', 52.08890000, 23.66400000, 'Brest Railway Museum Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Brest_Railway_Museum.jpg', ARRAY['family', 'transport']::text[]),
    ('sovetskaya-street-brest', 'brest', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Улица Советская и Аллея фонарей', 'Sovetskaya Street and Lantern Alley', 'Советская көшесі және шамдар аллеясы', 52.09290000, 23.68850000, 'Sovetskaya Street Brest Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Sovetskaya_Street_Brest.jpg', ARRAY['walk', 'evening']::text[]),
    ('brest-central-market', 'brest', 'MARKET', 1, 'HOURS', 4.4, 'Центральный Брестский рынок', 'Brest Central Market', 'Брест орталық базары', 52.09480000, 23.69380000, 'Brest Central Market Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Brest_Central_Market.jpg', ARRAY['local-market']::text[]),
    ('brest-city-park', 'brest', 'PARK', 1, 'HOURS', 4.5, 'Брестский парк культуры и отдыха', 'Brest City Park of Culture and Recreation', 'Брест мәдениет және демалыс саябағы', 52.09070000, 23.68100000, 'Brest City Park Belarus', ARRAY['brest']::text[], ARRAY['brest']::text[], 'Brest_City_Park.jpg', ARRAY['green-space', 'family']::text[]),
    ('belovezhskaya-pushcha-national-park', 'belovezhskaya-pushcha', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Беловежская пуща', 'Belovezhskaya Pushcha National Park', 'Беловеж пущасы ұлттық паркі', 52.57060000, 23.80370000, 'Belovezhskaya Pushcha National Park Belarus', ARRAY['belovezhskaya-pushcha']::text[], ARRAY['brest', 'belovezhskaya-pushcha']::text[], 'Belovezhskaya_Pushcha.jpg', ARRAY['unesco', 'forest']::text[]),
    ('belovezhskaya-pushcha-nature-museum', 'belovezhskaya-pushcha', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей природы Беловежской пущи', 'Nature Museum Belovezhskaya Pushcha', 'Беловеж пущасы табиғат музейі', 52.57100000, 23.80500000, 'Nature Museum Belovezhskaya Pushcha Belarus', ARRAY['belovezhskaya-pushcha']::text[], ARRAY['brest', 'belovezhskaya-pushcha']::text[], 'Belovezhskaya_Pushcha_Nature_Museum.jpg', ARRAY['nature', 'indoor']::text[]),
    ('father-frost-estate-belovezhskaya-pushcha', 'belovezhskaya-pushcha', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Поместье Деда Мороза', 'Father Frost Estate', 'Аяз ата мекені', 52.59000000, 23.91000000, 'Father Frost Estate Belovezhskaya Pushcha Belarus', ARRAY['belovezhskaya-pushcha']::text[], ARRAY['brest', 'belovezhskaya-pushcha']::text[], 'Father_Frost_Estate_Belovezhskaya_Pushcha.jpg', ARRAY['family', 'seasonal']::text[]),

    ('grodno-old-castle', 'grodno', 'MUSEUM', 2, 'HOURS', 4.7, 'Старый замок в Гродно', 'Grodno Old Castle', 'Гродно ескі қамалы', 53.67770000, 23.82590000, 'Old Grodno Castle Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Old_Grodno_Castle.jpg', ARRAY['castle', 'history']::text[]),
    ('new-grodno-castle', 'grodno', 'MUSEUM', 1, 'HOURS', 4.5, 'Новый замок в Гродно', 'New Grodno Castle', 'Гродно жаңа қамалы', 53.67810000, 23.82790000, 'New Grodno Castle Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'New_Grodno_Castle.jpg', ARRAY['palace', 'history']::text[]),
    ('kalozha-church', 'grodno', 'TEMPLE', 1, 'HOURS', 4.8, 'Коложская церковь', 'Kalozha Church', 'Каложа шіркеуі', 53.68140000, 23.81990000, 'Kalozha Church Grodno Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Kalozha_Church_Grodno.jpg', ARRAY['church', 'heritage']::text[]),
    ('great-choral-synagogue-grodno', 'grodno', 'TEMPLE', 1, 'HOURS', 4.6, 'Большая хоральная синагога Гродно', 'Great Choral Synagogue of Grodno', 'Гродно үлкен хорал синагогасы', 53.67970000, 23.82740000, 'Great Choral Synagogue Grodno Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Great_Choral_Synagogue_Grodno.jpg', ARRAY['synagogue', 'heritage']::text[]),
    ('gilibert-park-grodno', 'grodno', 'PARK', 1, 'HOURS', 4.5, 'Парк Жилибера', 'Gilibert Park', 'Жилибер саябағы', 53.68400000, 23.83600000, 'Gilibert Park Grodno Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Gilibert_Park_Grodno.jpg', ARRAY['green-space']::text[]),
    ('grodno-zoo', 'grodno', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Гродненский зоопарк', 'Grodno Zoo', 'Гродно зообағы', 53.68130000, 23.84690000, 'Grodno Zoo Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Grodno_Zoo.jpg', ARRAY['family', 'zoo']::text[]),
    ('triniti-grodno', 'grodno', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ TRINITI', 'TRINITI Shopping and Entertainment Center', 'TRINITI сауда-ойын-сауық орталығы', 53.65080000, 23.85190000, 'TRINITI Shopping Center Grodno Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'TRINITI_Grodno.jpg', ARRAY['mall', 'indoor']::text[]),
    ('augustow-canal-belarus', 'grodno', 'NATURE', 3, 'HOURS', 4.6, 'Августовский канал', 'Augustow Canal Belarusian Section', 'Августов каналы', 53.86100000, 23.81700000, 'Augustow Canal Belarus', ARRAY['grodno']::text[], ARRAY['grodno']::text[], 'Augustow_Canal_Belarus.jpg', ARRAY['canal', 'nature']::text[]),
    ('lida-castle', 'lida', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Лидский замок', 'Lida Castle', 'Лида қамалы', 53.88710000, 25.30270000, 'Lida Castle Belarus', ARRAY['lida']::text[], ARRAY['grodno', 'lida']::text[], 'Lida_Castle.jpg', ARRAY['castle']::text[]),
    ('museum-belarusian-polesie', 'pinsk', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Белорусского Полесья', 'Museum of Belarusian Polesie', 'Беларусь Полесьесі музейі', 52.11360000, 26.10270000, 'Museum of Belarusian Polesie Pinsk', ARRAY['pinsk']::text[], ARRAY['pinsk']::text[], 'Museum_of_Belarusian_Polesie.jpg', ARRAY['regional-history']::text[]),
    ('pinsk-riverfront', 'pinsk', 'PARK', 1, 'HOURS', 4.5, 'Набережная Пинска', 'Pinsk Riverfront', 'Пинск жағалауы', 52.11600000, 26.10300000, 'Pinsk Riverfront Belarus', ARRAY['pinsk']::text[], ARRAY['pinsk']::text[], 'Pinsk_Riverfront.jpg', ARRAY['riverfront', 'walk']::text[]),

    ('marc-chagall-art-center', 'vitebsk', 'MUSEUM', 2, 'HOURS', 4.7, 'Арт-центр Марка Шагала', 'Marc Chagall Art Center', 'Марк Шагал өнер орталығы', 55.19500000, 30.20700000, 'Marc Chagall Art Center Vitebsk Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Marc_Chagall_Art_Center.jpg', ARRAY['art', 'indoor']::text[]),
    ('marc-chagall-house-museum', 'vitebsk', 'MUSEUM', 1, 'HOURS', 4.6, 'Дом-музей Марка Шагала', 'Marc Chagall House Museum', 'Марк Шагал үй-музейі', 55.19400000, 30.18600000, 'Marc Chagall House Museum Vitebsk Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Marc_Chagall_House_Museum.jpg', ARRAY['art', 'history']::text[]),
    ('vitebsk-town-hall', 'vitebsk', 'MUSEUM', 1, 'HOURS', 4.6, 'Витебская ратуша', 'Vitebsk Town Hall', 'Витебск ратушасы', 55.19400000, 30.20400000, 'Vitebsk Town Hall Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Vitebsk_Town_Hall.jpg', ARRAY['regional-history']::text[]),
    ('summer-amphitheatre-vitebsk', 'vitebsk', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Летний амфитеатр Витебска', 'Summer Amphitheatre Vitebsk', 'Витебск жазғы амфитеатры', 55.19130000, 30.21010000, 'Summer Amphitheatre Vitebsk Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Summer_Amphitheatre_Vitebsk.jpg', ARRAY['concerts', 'evening']::text[]),
    ('vitebsk-botanical-garden', 'vitebsk', 'PARK', 1, 'HOURS', 4.4, 'Ботанический сад Витебска', 'Vitebsk Botanical Garden', 'Витебск ботаникалық бағы', 55.19100000, 30.20200000, 'Vitebsk Botanical Garden Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Vitebsk_Botanical_Garden.jpg', ARRAY['garden']::text[]),
    ('marko-city-mall-vitebsk', 'vitebsk', 'SHOPPING', 1, 'HOURS', 4.3, 'ТРЦ Марко-Сити', 'Marko City Mall', 'Марко-Сити сауда орталығы', 55.19000000, 30.20500000, 'Marko City Mall Vitebsk Belarus', ARRAY['vitebsk']::text[], ARRAY['vitebsk']::text[], 'Marko_City_Mall_Vitebsk.jpg', ARRAY['mall', 'indoor']::text[]),
    ('saint-sophia-cathedral-polotsk', 'polotsk', 'TEMPLE', 1, 'HOURS', 4.8, 'Софийский собор в Полоцке', 'Saint Sophia Cathedral Polotsk', 'Полоцк София соборы', 55.48700000, 28.75800000, 'Saint Sophia Cathedral Polotsk Belarus', ARRAY['polotsk']::text[], ARRAY['vitebsk', 'polotsk']::text[], 'Saint_Sophia_Cathedral_Polotsk.jpg', ARRAY['cathedral', 'heritage']::text[]),
    ('saint-euphrosyne-monastery', 'polotsk', 'TEMPLE', 1, 'HOURS', 4.7, 'Спасо-Евфросиниевский монастырь', 'Saint Euphrosyne Monastery', 'Әулие Ефросиния монастырі', 55.49800000, 28.78600000, 'Saint Euphrosyne Monastery Polotsk Belarus', ARRAY['polotsk']::text[], ARRAY['vitebsk', 'polotsk']::text[], 'Saint_Euphrosyne_Monastery_Polotsk.jpg', ARRAY['monastery']::text[]),
    ('museum-belarusian-book-printing', 'polotsk', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей белорусского книгопечатания', 'Museum of Belarusian Book Printing', 'Беларусь кітап басу музейі', 55.48600000, 28.76900000, 'Museum of Belarusian Book Printing Polotsk', ARRAY['polotsk']::text[], ARRAY['polotsk']::text[], 'Museum_of_Belarusian_Book_Printing.jpg', ARRAY['books', 'indoor']::text[]),

    ('mogilev-city-hall', 'mogilev', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Могилевская ратуша', 'Mogilev City Hall', 'Могилев ратушасы', 53.90100000, 30.33400000, 'Mogilev City Hall Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Mogilev_City_Hall.jpg', ARRAY['viewpoint', 'old-town']::text[]),
    ('mogilev-local-lore-museum', 'mogilev', 'MUSEUM', 1, 'HOURS', 4.5, 'Могилевский областной краеведческий музей', 'Mogilev Regional Local Lore Museum', 'Могилев өлкетану музейі', 53.90100000, 30.33600000, 'Mogilev Regional Local Lore Museum Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Mogilev_Local_Lore_Museum.jpg', ARRAY['regional-history']::text[]),
    ('buinichi-field-memorial', 'mogilev', 'OTHER', 1, 'HOURS', 4.6, 'Мемориальный комплекс Буйничское поле', 'Buinichi Field Memorial', 'Буйничи даласы мемориалы', 53.84500000, 30.26200000, 'Buinichi Field Memorial Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Buinichi_Field_Memorial.jpg', ARRAY['memorial', 'history']::text[]),
    ('mogilev-zoosad', 'mogilev', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Могилевский зоосад', 'Mogilev Zoosad', 'Могилев зообағы', 53.84000000, 30.26000000, 'Mogilev Zoosad Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Mogilev_Zoosad.jpg', ARRAY['family', 'zoo']::text[]),
    ('mogilev-central-market', 'mogilev', 'MARKET', 1, 'HOURS', 4.3, 'Центральный рынок Могилева', 'Mogilev Central Market', 'Могилев орталық базары', 53.90400000, 30.34200000, 'Mogilev Central Market Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Mogilev_Central_Market.jpg', ARRAY['local-market']::text[]),
    ('atrium-mogilev', 'mogilev', 'SHOPPING', 1, 'HOURS', 4.3, 'ТРЦ Атриум', 'Atrium Shopping and Entertainment Center', 'Атриум сауда-ойын-сауық орталығы', 53.89800000, 30.33500000, 'Atrium Shopping Center Mogilev Belarus', ARRAY['mogilev']::text[], ARRAY['mogilev']::text[], 'Atrium_Mogilev.jpg', ARRAY['mall', 'indoor']::text[]),

    ('gomel-palace-park-ensemble', 'gomel', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Гомельский дворцово-парковый ансамбль', 'Gomel Palace and Park Ensemble', 'Гомель сарай-саябақ ансамблі', 52.42500000, 31.01500000, 'Gomel Palace and Park Ensemble Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Gomel_Palace_and_Park_Ensemble.jpg', ARRAY['palace', 'park']::text[]),
    ('gomel-palace-park', 'gomel', 'PARK', 2, 'HOURS', 4.7, 'Дворцовый парк Гомеля', 'Palace Park of Gomel', 'Гомель сарай саябағы', 52.42400000, 31.01700000, 'Palace Park Gomel Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Gomel_Palace_Park.jpg', ARRAY['green-space', 'riverfront']::text[]),
    ('peter-and-paul-cathedral-gomel', 'gomel', 'TEMPLE', 1, 'HOURS', 4.6, 'Петропавловский собор в Гомеле', 'Peter and Paul Cathedral Gomel', 'Гомель Петропавл соборы', 52.42400000, 31.01600000, 'Peter and Paul Cathedral Gomel Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Peter_and_Paul_Cathedral_Gomel.jpg', ARRAY['cathedral']::text[]),
    ('gomel-military-glory-museum', 'gomel', 'MUSEUM', 1, 'HOURS', 4.5, 'Гомельский музей военной славы', 'Gomel Regional Museum of Military Glory', 'Гомель әскери даңқ музейі', 52.43100000, 31.00800000, 'Gomel Regional Museum of Military Glory Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Gomel_Museum_of_Military_Glory.jpg', ARRAY['military-history']::text[]),
    ('gomel-state-circus', 'gomel', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Гомельский государственный цирк', 'Gomel State Circus', 'Гомель мемлекеттік циркі', 52.43000000, 31.00000000, 'Gomel State Circus Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Gomel_State_Circus.jpg', ARRAY['family', 'show']::text[]),
    ('gomel-central-market', 'gomel', 'MARKET', 1, 'HOURS', 4.3, 'Гомельский центральный рынок', 'Gomel Central Market', 'Гомель орталық базары', 52.43300000, 30.99300000, 'Gomel Central Market Belarus', ARRAY['gomel']::text[], ARRAY['gomel']::text[], 'Gomel_Central_Market.jpg', ARRAY['local-market']::text[]),

    ('braslav-lakes-national-park', 'braslav', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Браславские озера', 'Braslav Lakes National Park', 'Браслав көлдері ұлттық паркі', 55.64100000, 27.00000000, 'Braslav Lakes National Park Belarus', ARRAY['braslav']::text[], ARRAY['vitebsk', 'braslav']::text[], 'Braslav_Lakes_National_Park.jpg', ARRAY['lakes', 'nature']::text[]),
    ('lake-drivyaty', 'braslav', 'BEACH', 3, 'HOURS', 4.6, 'Озеро Дривяты', 'Lake Drivyaty Recreation Area', 'Дривяты көлі демалыс аймағы', 55.63500000, 27.04500000, 'Lake Drivyaty Braslav Belarus', ARRAY['braslav']::text[], ARRAY['braslav']::text[], 'Lake_Drivyaty.jpg', ARRAY['lake', 'summer']::text[]),
    ('naroch-national-park', 'naroch', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Нарочанский', 'Naroch National Park', 'Нарочь ұлттық паркі', 54.87500000, 26.73000000, 'Naroch National Park Belarus', ARRAY['naroch']::text[], ARRAY['minsk', 'naroch']::text[], 'Naroch_National_Park.jpg', ARRAY['lake', 'nature']::text[]),
    ('lake-naroch-resort-area', 'naroch', 'BEACH', 3, 'HOURS', 4.6, 'Курортная зона озера Нарочь', 'Lake Naroch Resort Area', 'Нарочь көлі курорт аймағы', 54.91000000, 26.70800000, 'Lake Naroch Resort Area Belarus', ARRAY['naroch']::text[], ARRAY['minsk', 'naroch']::text[], 'Lake_Naroch.jpg', ARRAY['lake', 'summer']::text[]),
    ('pripyatsky-national-park', 'pripyatsky', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Припятский', 'Pripyatsky National Park', 'Припять ұлттық паркі', 52.11300000, 27.88000000, 'Pripyatsky National Park Belarus', ARRAY['pripyatsky', 'turov']::text[], ARRAY['gomel', 'pripyatsky', 'turov']::text[], 'Pripyatsky_National_Park.jpg', ARRAY['wetlands', 'wildlife']::text[]),
    ('turov-meadow', 'turov', 'NATURE', 2, 'HOURS', 4.5, 'Туровский луг', 'Turov Meadow', 'Туров шалғыны', 52.07000000, 27.73500000, 'Turov Meadow Belarus', ARRAY['turov', 'pripyatsky']::text[], ARRAY['gomel', 'turov', 'pripyatsky']::text[], 'Turov_Meadow.jpg', ARRAY['birds', 'wetlands']::text[]);

CREATE TEMP TABLE seed_belarus_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-belarus-place:' || seed.slug) AS place_hash,
        md5('id-belarus-media:' || seed.slug) AS media_hash
    FROM seed_belarus_priority_places seed
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
    ARRAY['belarus', city_id, slug, lower(category), 'belarus-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Беларуси: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Belarus tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Беларусь туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'BY',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20::numeric
        ELSE 10::numeric
    END,
    'BYN',
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
FROM seed_belarus_resolved_places
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
FROM seed_belarus_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_belarus_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_belarus_resolved_places
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
FROM seed_belarus_resolved_places seed
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
FROM seed_belarus_resolved_places
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
    'BY',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_belarus_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'BY',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_belarus_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_belarus_resolved_places;
DROP TABLE IF EXISTS seed_belarus_priority_places;
