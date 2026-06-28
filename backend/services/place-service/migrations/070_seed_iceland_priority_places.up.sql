-- Priority Iceland destination places seed.
-- The seed covers Reykjavik, the Golden Circle, South Coast, West Iceland, Westfjords, North Iceland and East Iceland.

DROP TABLE IF EXISTS seed_iceland_resolved_places;
DROP TABLE IF EXISTS seed_iceland_priority_places;

CREATE TEMP TABLE seed_iceland_priority_places (
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

INSERT INTO seed_iceland_priority_places (
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
    ('hallgrimskirkja', 'reykjavik', 'TEMPLE', 1, 'HOURS', 4.8, 'Церковь Хадльгримскиркья', 'Hallgrimskirkja', 'Хадльгримскиркья шіркеуі', 64.14170000, -21.92660000, 'Hallgrimskirkja Reykjavik Iceland', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Hallgrimskirkja Reykjavik Iceland.jpg', ARRAY['city-symbol', 'viewpoint']::text[]),
    ('harpa-concert-hall', 'reykjavik', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Концертный зал Харпа', 'Harpa Concert Hall and Conference Centre', 'Harpa концерт залы', 64.15030000, -21.93260000, 'Harpa Concert Hall Reykjavik Iceland', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Harpa Concert Hall Reykjavik.jpg', ARRAY['city-symbol', 'indoor']::text[]),
    ('sun-voyager', 'reykjavik', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Скульптура Солнечный странник', 'Sun Voyager', 'Күн саяхатшысы мүсіні', 64.14760000, -21.92230000, 'Sun Voyager Reykjavik Iceland', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Sun Voyager Reykjavik Iceland.jpg', ARRAY['photo-stop']::text[]),
    ('settlement-exhibition-reykjavik', 'reykjavik', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Поселение Рейкьявик 871 плюс-минус 2', 'The Settlement Exhibition', 'Рейкьявик қонысы музейі', 64.14740000, -21.94260000, 'The Settlement Exhibition Reykjavik Iceland', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'The Settlement Exhibition Reykjavik.jpg', ARRAY['indoor', 'history']::text[]),
    ('national-museum-iceland', 'reykjavik', 'MUSEUM', 2, 'HOURS', 4.8, 'Национальный музей Исландии', 'National Museum of Iceland', 'Исландия ұлттық музейі', 64.14100000, -21.94870000, 'National Museum of Iceland Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'National Museum of Iceland.jpg', ARRAY['indoor']::text[]),
    ('perlan-wonders-of-iceland', 'reykjavik', 'MUSEUM', 2, 'HOURS', 4.8, 'Перлан — Чудеса Исландии', 'Perlan - Wonders of Iceland', 'Перлан - Исландия ғажайыптары', 64.12920000, -21.91890000, 'Perlan Wonders of Iceland Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Perlan Reykjavik Iceland.jpg', ARRAY['indoor', 'viewpoint', 'family']::text[]),
    ('whales-of-iceland', 'reykjavik', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Киты Исландии', 'Whales of Iceland', 'Исландия киттері музейі', 64.15140000, -21.94860000, 'Whales of Iceland Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Whales of Iceland Reykjavik.jpg', ARRAY['indoor', 'family']::text[]),
    ('flyover-iceland', 'reykjavik', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Аттракцион FlyOver Iceland', 'FlyOver Iceland', 'FlyOver Iceland аттракционы', 64.15100000, -21.94970000, 'FlyOver Iceland Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Reykjavik Old Harbour Iceland.jpg', ARRAY['indoor', 'family']::text[]),
    ('laugavegur-shopping-street', 'reykjavik', 'SHOPPING', 2, 'HOURS', 4.6, 'Торговая улица Лёйгавегюр', 'Laugavegur Shopping Street', 'Лёйгавегюр сауда көшесі', 64.14560000, -21.92720000, 'Laugavegur Reykjavik Iceland', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Laugavegur Reykjavik Iceland.jpg', ARRAY['shopping-street']::text[]),
    ('kolaportid-flea-market', 'reykjavik', 'MARKET', 1, 'HOURS', 4.5, 'Блошиный рынок Колапортид', 'Kolaportid Flea Market', 'Колапортид барахолкасы', 64.14970000, -21.94020000, 'Kolaportid Flea Market Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Kolaportid Reykjavik.jpg', ARRAY['local-market', 'weekend']::text[]),
    ('hafnartorg-gallery', 'reykjavik', 'SHOPPING', 2, 'HOURS', 4.5, 'Хафнарторг Галерея', 'Hafnartorg Gallery', 'Hafnartorg Gallery', 64.14940000, -21.93390000, 'Hafnartorg Gallery Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Reykjavik city centre Iceland.jpg', ARRAY['indoor']::text[]),
    ('hlemmur-matholl', 'reykjavik', 'FOOD', 1, 'HOURS', 4.6, 'Фуд-холл Хлеммюр', 'Hlemmur Matholl', 'Hlemmur Matholl фуд-холлы', 64.14380000, -21.91450000, 'Hlemmur Matholl Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Hlemmur Reykjavik Iceland.jpg', ARRAY['food-hall', 'evening']::text[]),
    ('nautholsvik-geothermal-beach', 'reykjavik', 'BEACH', 2, 'HOURS', 4.6, 'Геотермальный пляж Нёйтхольсвик', 'Nautholsvik Geothermal Beach', 'Нёйтхольсвик геотермал жағажайы', 64.12260000, -21.92900000, 'Nautholsvik Geothermal Beach Reykjavik', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], 'Nautholsvik Reykjavik.jpg', ARRAY['geothermal', 'summer']::text[]),
    ('sky-lagoon', 'kopavogur', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Геотермальная лагуна Sky Lagoon', 'Sky Lagoon', 'Sky Lagoon геотермал лагунасы', 64.10080000, -21.94320000, 'Sky Lagoon Kopavogur Iceland', ARRAY['kopavogur', 'reykjavik']::text[], ARRAY['reykjavik', 'kopavogur']::text[], 'Sky Lagoon Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('smaralind-shopping-mall', 'kopavogur', 'SHOPPING', 2, 'HOURS', 4.4, 'Торговый центр Смаралинд', 'Smaralind Shopping Mall', 'Smaralind сауда орталығы', 64.10250000, -21.88330000, 'Smaralind Shopping Mall Kopavogur', ARRAY['kopavogur', 'reykjavik']::text[], ARRAY['reykjavik', 'kopavogur']::text[], 'Kopavogur Iceland.jpg', ARRAY['indoor']::text[]),
    ('grotta-lighthouse', 'seltjarnarnes', 'NATURE', 1, 'HOURS', 4.7, 'Маяк Гротта', 'Grotta Lighthouse', 'Гротта маягы', 64.16430000, -22.02190000, 'Grotta Lighthouse Seltjarnarnes Iceland', ARRAY['seltjarnarnes', 'reykjavik']::text[], ARRAY['reykjavik', 'seltjarnarnes']::text[], 'Grotta Lighthouse Iceland.jpg', ARRAY['birdwatching', 'photo-stop']::text[]),
    ('hellisgerdi-park', 'hafnarfjordur', 'PARK', 1, 'HOURS', 4.5, 'Парк Хеллисгерди', 'Hellisgerdi Park', 'Хеллисгерди саябағы', 64.06950000, -21.95510000, 'Hellisgerdi Park Hafnarfjordur Iceland', ARRAY['hafnarfjordur', 'reykjavik']::text[], ARRAY['reykjavik', 'hafnarfjordur']::text[], 'Hafnarfjordur Iceland.jpg', ARRAY['family']::text[]),
    ('bessastadir', 'gardabaer', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Бессастадир, резиденция президента Исландии', 'Bessastadir', 'Бессастадир', 64.10320000, -22.01780000, 'Bessastadir Iceland', ARRAY['gardabaer', 'reykjavik']::text[], ARRAY['reykjavik', 'gardabaer']::text[], 'Bessastadir Iceland.jpg', ARRAY['history']::text[]),
    ('gljufrasteinn-laxness-museum', 'mosfellsbaer', 'MUSEUM', 2, 'HOURS', 4.6, 'Гльюврастейн — музей Халльдоура Лакснесса', 'Gljufrasteinn - Laxness Museum', 'Гльюврастейн - Лакснесс музейі', 64.18160000, -21.62430000, 'Gljufrasteinn Laxness Museum Iceland', ARRAY['mosfellsbaer', 'reykjavik']::text[], ARRAY['reykjavik', 'mosfellsbaer']::text[], 'Gljufrasteinn Iceland.jpg', ARRAY['indoor', 'literature']::text[]),
    ('blue-lagoon', 'reykjanes', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Голубая лагуна', 'Blue Lagoon', 'Көк лагуна', 63.88040000, -22.44950000, 'Blue Lagoon Iceland', ARRAY['reykjanes']::text[], ARRAY['reykjavik', 'reykjanes']::text[], 'Blue Lagoon Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),

    ('thingvellir-national-park', 'thingvellir', 'PARK', 4, 'HOURS', 4.9, 'Национальный парк Тингведлир', 'Thingvellir National Park', 'Тингведлир ұлттық паркі', 64.25590000, -21.12950000, 'Thingvellir National Park Iceland', ARRAY['thingvellir']::text[], ARRAY['reykjavik', 'thingvellir']::text[], 'Thingvellir National Park Iceland.jpg', ARRAY['unesco', 'golden-circle']::text[]),
    ('geysir-geothermal-area', 'geysir', 'NATURE', 2, 'HOURS', 4.8, 'Геотермальная зона Гейсир', 'Geysir Geothermal Area', 'Гейсир геотермал аймағы', 64.31370000, -20.29960000, 'Geysir Geothermal Area Iceland', ARRAY['geysir']::text[], ARRAY['reykjavik', 'geysir']::text[], 'Geysir Iceland.jpg', ARRAY['golden-circle', 'geothermal']::text[]),
    ('gullfoss-waterfall', 'gullfoss', 'NATURE', 2, 'HOURS', 4.9, 'Водопад Гюдльфосс', 'Gullfoss Waterfall', 'Гюдльфосс сарқырамасы', 64.32710000, -20.11990000, 'Gullfoss Waterfall Iceland', ARRAY['gullfoss']::text[], ARRAY['reykjavik', 'gullfoss']::text[], 'Gullfoss Iceland.jpg', ARRAY['golden-circle', 'waterfall']::text[]),
    ('kerid-crater', 'selfoss', 'NATURE', 1, 'HOURS', 4.6, 'Кратер Керид', 'Kerid Crater', 'Керид кратері', 64.04130000, -20.88510000, 'Kerid Crater Iceland', ARRAY['selfoss']::text[], ARRAY['reykjavik', 'selfoss']::text[], 'Kerid Crater Iceland.jpg', ARRAY['golden-circle', 'volcano']::text[]),
    ('fridheimar-tomato-farm', 'selfoss', 'FOOD', 2, 'HOURS', 4.7, 'Томатная ферма Фридхеймар', 'Fridheimar Tomato Farm', 'Фридхеймар қызанақ фермасы', 64.17640000, -20.44950000, 'Fridheimar Tomato Farm Iceland', ARRAY['selfoss']::text[], ARRAY['reykjavik', 'selfoss']::text[], 'Fridheimar Iceland.jpg', ARRAY['greenhouse', 'food']::text[]),
    ('laugarvatn-fontana', 'thingvellir', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Геотермальные купальни Лёйгарватн Фонтана', 'Laugarvatn Fontana', 'Лёйгарватн Фонтана', 64.21520000, -20.73120000, 'Laugarvatn Fontana Iceland', ARRAY['thingvellir']::text[], ARRAY['reykjavik', 'thingvellir']::text[], 'Laugarvatn Fontana Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('selfoss-old-dairy-food-hall', 'selfoss', 'FOOD', 1, 'HOURS', 4.5, 'Центр Сельфосса и фуд-холл Old Dairy', 'Selfoss Town Centre and Old Dairy Food Hall', 'Сельфосс орталығы және Old Dairy фуд-холлы', 63.93350000, -20.99710000, 'Selfoss Iceland town centre', ARRAY['selfoss']::text[], ARRAY['reykjavik', 'selfoss']::text[], 'Selfoss Iceland.jpg', ARRAY['food-hall']::text[]),
    ('reykjadalur-hot-spring-river', 'hveragerdi', 'NATURE', 4, 'HOURS', 4.8, 'Термальная река Рейкьядалюр', 'Reykjadalur Hot Spring Thermal River', 'Рейкьядалюр ыстық бұлағы', 64.02210000, -21.21190000, 'Reykjadalur Hot Spring Thermal River Iceland', ARRAY['hveragerdi']::text[], ARRAY['reykjavik', 'hveragerdi']::text[], 'Reykjadalur Iceland.jpg', ARRAY['geothermal', 'hiking']::text[]),
    ('the-greenhouse-hveragerdi', 'hveragerdi', 'FOOD', 1, 'HOURS', 4.5, 'The Greenhouse в Хверагерди', 'The Greenhouse Hveragerdi', 'Хверагерди The Greenhouse', 64.00040000, -21.18850000, 'The Greenhouse Hveragerdi Iceland', ARRAY['hveragerdi']::text[], ARRAY['reykjavik', 'hveragerdi']::text[], 'Hveragerdi Iceland.jpg', ARRAY['food-hall', 'shopping']::text[]),
    ('seljalandsfoss-waterfall', 'seljalandsfoss', 'NATURE', 2, 'HOURS', 4.9, 'Водопад Сельяландсфосс', 'Seljalandsfoss Waterfall', 'Сельяландсфосс сарқырамасы', 63.61560000, -19.98860000, 'Seljalandsfoss Waterfall Iceland', ARRAY['seljalandsfoss']::text[], ARRAY['reykjavik', 'seljalandsfoss']::text[], 'Seljalandsfoss Iceland.jpg', ARRAY['south-coast', 'waterfall']::text[]),
    ('skogafoss-waterfall', 'skogar', 'NATURE', 2, 'HOURS', 4.9, 'Водопад Скоугафосс', 'Skogafoss Waterfall', 'Скоугафосс сарқырамасы', 63.53210000, -19.51140000, 'Skogafoss Waterfall Iceland', ARRAY['skogar']::text[], ARRAY['reykjavik', 'skogar']::text[], 'Skogafoss Iceland.jpg', ARRAY['south-coast', 'waterfall']::text[]),
    ('skogar-museum', 'skogar', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Скоугар', 'Skogar Museum', 'Скоугар музейі', 63.52620000, -19.49300000, 'Skogar Museum Iceland', ARRAY['skogar']::text[], ARRAY['reykjavik', 'skogar']::text[], 'Skogar Museum Iceland.jpg', ARRAY['indoor', 'heritage']::text[]),
    ('reynisfjara-black-sand-beach', 'vik', 'BEACH', 2, 'HOURS', 4.9, 'Чёрный пляж Рейнисфьяра', 'Reynisfjara Black Sand Beach', 'Рейнисфьяра қара құм жағажайы', 63.40430000, -19.04440000, 'Reynisfjara Black Sand Beach Iceland', ARRAY['vik']::text[], ARRAY['reykjavik', 'vik']::text[], 'Reynisfjara Iceland.jpg', ARRAY['south-coast', 'black-sand']::text[]),
    ('dyrholaey-promontory', 'vik', 'NATURE', 2, 'HOURS', 4.8, 'Мыс Дирхоулаэй', 'Dyrholaey Promontory', 'Дирхоулаэй мүйісі', 63.39930000, -19.12690000, 'Dyrholaey Iceland', ARRAY['vik']::text[], ARRAY['reykjavik', 'vik']::text[], 'Dyrholaey Iceland.jpg', ARRAY['south-coast', 'birdwatching']::text[]),
    ('vik-church-viewpoint', 'vik', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Церковь и смотровая площадка Вик', 'Vik Church and Village Viewpoint', 'Вик шіркеуі және көрініс алаңы', 63.41970000, -19.00670000, 'Vik Church Iceland', ARRAY['vik']::text[], ARRAY['reykjavik', 'vik']::text[], 'Vik Church Iceland.jpg', ARRAY['photo-stop']::text[]),
    ('skaftafell-vatnajokull-national-park', 'skaftafell', 'PARK', 5, 'HOURS', 4.9, 'Скафтафетль, национальный парк Ватнайёкюдль', 'Skaftafell, Vatnajokull National Park', 'Скафтафетль, Ватнайёкюдль ұлттық паркі', 64.01670000, -16.96670000, 'Skaftafell Vatnajokull National Park Iceland', ARRAY['skaftafell']::text[], ARRAY['reykjavik', 'skaftafell']::text[], 'Skaftafell Iceland.jpg', ARRAY['glacier', 'hiking']::text[]),
    ('jokulsarlon-glacier-lagoon', 'jokulsarlon', 'NATURE', 2, 'HOURS', 4.9, 'Ледниковая лагуна Йёкюльсаурлоун', 'Jokulsarlon Glacier Lagoon', 'Йёкюльсаурлоун мұздық лагунасы', 64.07840000, -16.23060000, 'Jokulsarlon Glacier Lagoon Iceland', ARRAY['jokulsarlon']::text[], ARRAY['reykjavik', 'jokulsarlon']::text[], 'Jokulsarlon Iceland.jpg', ARRAY['glacier', 'south-coast']::text[]),
    ('diamond-beach', 'jokulsarlon', 'BEACH', 1, 'HOURS', 4.8, 'Даймонд-Бич', 'Diamond Beach', 'Даймонд-Бич', 64.04390000, -16.17780000, 'Diamond Beach Iceland', ARRAY['jokulsarlon']::text[], ARRAY['reykjavik', 'jokulsarlon']::text[], 'Diamond Beach Iceland.jpg', ARRAY['glacier', 'black-sand']::text[]),

    ('hraunfossar-waterfalls', 'borgarnes', 'NATURE', 2, 'HOURS', 4.8, 'Водопады Хрёйнфоссар', 'Hraunfossar Lava Waterfalls', 'Хрёйнфоссар сарқырамалары', 64.70280000, -20.97770000, 'Hraunfossar Waterfalls Iceland', ARRAY['borgarnes']::text[], ARRAY['reykjavik', 'borgarnes']::text[], 'Hraunfossar Iceland.jpg', ARRAY['west-iceland', 'waterfall']::text[]),
    ('the-settlement-center-borgarnes', 'borgarnes', 'MUSEUM', 2, 'HOURS', 4.6, 'Центр заселения Исландии', 'The Settlement Center Borgarnes', 'Боргарнес қоныстану орталығы', 64.53570000, -21.92320000, 'The Settlement Center Borgarnes Iceland', ARRAY['borgarnes']::text[], ARRAY['reykjavik', 'borgarnes']::text[], 'Borgarnes Iceland.jpg', ARRAY['indoor', 'history']::text[]),
    ('snaefellsjokull-national-park', 'snaefellsnes', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Снайфедльсйёкюдль', 'Snaefellsjokull National Park', 'Снайфедльсйёкюдль ұлттық паркі', 64.80500000, -23.77000000, 'Snaefellsjokull National Park Iceland', ARRAY['snaefellsnes']::text[], ARRAY['reykjavik', 'snaefellsnes']::text[], 'Snaefellsjokull National Park Iceland.jpg', ARRAY['volcano', 'glacier']::text[]),
    ('kirkjufell-mountain', 'snaefellsnes', 'NATURE', 2, 'HOURS', 4.9, 'Гора Киркьюфетль', 'Kirkjufell Mountain', 'Киркьюфетль тауы', 64.94070000, -23.30630000, 'Kirkjufell Mountain Iceland', ARRAY['snaefellsnes']::text[], ARRAY['reykjavik', 'snaefellsnes']::text[], 'Kirkjufell Iceland.jpg', ARRAY['photo-stop', 'west-iceland']::text[]),
    ('djupalonssandur-beach', 'snaefellsnes', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Дьюпалонссандур', 'Djupalonssandur Beach', 'Дьюпалонссандур жағажайы', 64.75200000, -23.90230000, 'Djupalonssandur Beach Iceland', ARRAY['snaefellsnes']::text[], ARRAY['reykjavik', 'snaefellsnes']::text[], 'Djupalonssandur Iceland.jpg', ARRAY['black-sand', 'west-iceland']::text[]),
    ('budir-black-church', 'snaefellsnes', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Будир и чёрная церковь Будюкиркья', 'Budir Black Church', 'Будир қара шіркеуі', 64.82290000, -23.38460000, 'Budir Black Church Iceland', ARRAY['snaefellsnes']::text[], ARRAY['reykjavik', 'snaefellsnes']::text[], 'Budir Black Church Iceland.jpg', ARRAY['photo-stop']::text[]),
    ('norwegian-house-stykkisholmur', 'stykkisholmur', 'MUSEUM', 1, 'HOURS', 4.5, 'Норвежский дом в Стиккисхоульмюре', 'The Norwegian House Stykkisholmur', 'Стиккисхоульмюр Норвег үйі', 65.07500000, -22.72800000, 'The Norwegian House Stykkisholmur Iceland', ARRAY['stykkisholmur', 'snaefellsnes']::text[], ARRAY['reykjavik', 'stykkisholmur']::text[], 'Stykkisholmur Iceland.jpg', ARRAY['indoor', 'heritage']::text[]),
    ('dynjandi-waterfall', 'isafjordur', 'NATURE', 3, 'HOURS', 4.9, 'Водопад Диньянди', 'Dynjandi Waterfall', 'Диньянди сарқырамасы', 65.73280000, -23.19980000, 'Dynjandi Waterfall Iceland', ARRAY['isafjordur']::text[], ARRAY['isafjordur']::text[], 'Dynjandi Iceland.jpg', ARRAY['westfjords', 'waterfall']::text[]),
    ('latrabjarg-cliffs', 'latrabjarg', 'NATURE', 2, 'HOURS', 4.8, 'Скалы Лаутрабьярг', 'Latrabjarg Cliffs', 'Лаутрабьярг жартастары', 65.50240000, -24.52970000, 'Latrabjarg Cliffs Iceland', ARRAY['latrabjarg']::text[], ARRAY['isafjordur', 'latrabjarg']::text[], 'Latrabjarg Iceland.jpg', ARRAY['westfjords', 'birdwatching']::text[]),
    ('raudisandur-beach', 'latrabjarg', 'BEACH', 2, 'HOURS', 4.7, 'Красный пляж Рёйдасандур', 'Raudisandur Beach', 'Рёйдасандур қызыл жағажайы', 65.47440000, -23.96010000, 'Raudisandur Beach Iceland', ARRAY['latrabjarg']::text[], ARRAY['isafjordur', 'latrabjarg']::text[], 'Raudisandur Iceland.jpg', ARRAY['westfjords', 'beach']::text[]),

    ('akureyri-botanical-garden', 'akureyri', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Акюрейри', 'Akureyri Botanical Garden', 'Акюрейри ботаникалық бағы', 65.67880000, -18.10170000, 'Akureyri Botanical Garden Iceland', ARRAY['akureyri']::text[], ARRAY['akureyri']::text[], 'Akureyri Botanical Garden Iceland.jpg', ARRAY['family']::text[]),
    ('akureyri-church', 'akureyri', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Церковь Акюрейри', 'Akureyri Church', 'Акюрейри шіркеуі', 65.68150000, -18.09060000, 'Akureyri Church Iceland', ARRAY['akureyri']::text[], ARRAY['akureyri']::text[], 'Akureyri Church Iceland.jpg', ARRAY['city-symbol']::text[]),
    ('akureyri-museum', 'akureyri', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Акюрейри', 'Akureyri Museum', 'Акюрейри музейі', 65.66670000, -18.09470000, 'Akureyri Museum Iceland', ARRAY['akureyri']::text[], ARRAY['akureyri']::text[], 'Akureyri Museum Iceland.jpg', ARRAY['indoor']::text[]),
    ('forest-lagoon', 'akureyri', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Лесная лагуна', 'Forest Lagoon', 'Орман лагунасы', 65.67020000, -18.04310000, 'Forest Lagoon Akureyri Iceland', ARRAY['akureyri']::text[], ARRAY['akureyri']::text[], 'Forest Lagoon Akureyri Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('christmas-garden-akureyri', 'akureyri', 'SHOPPING', 1, 'HOURS', 4.5, 'Рождественский сад Акюрейри', 'Christmas Garden Akureyri', 'Акюрейри Рождество бағы', 65.61700000, -18.09400000, 'Christmas Garden Akureyri Iceland', ARRAY['akureyri']::text[], ARRAY['akureyri']::text[], 'Akureyri Christmas Garden Iceland.jpg', ARRAY['souvenirs', 'family']::text[]),
    ('husavik-whale-museum', 'husavik', 'MUSEUM', 1, 'HOURS', 4.7, 'Музей китов в Хусавике', 'Husavik Whale Museum', 'Хусавик киттер музейі', 66.04680000, -17.34470000, 'Husavik Whale Museum Iceland', ARRAY['husavik']::text[], ARRAY['akureyri', 'husavik']::text[], 'Husavik Whale Museum Iceland.jpg', ARRAY['indoor', 'family']::text[]),
    ('husavik-whale-watching', 'husavik', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Наблюдение за китами из гавани Хусавика', 'Whale Watching from Husavik Harbour', 'Хусавик айлағынан кит бақылау', 66.04700000, -17.34400000, 'Whale Watching Husavik Iceland', ARRAY['husavik']::text[], ARRAY['akureyri', 'husavik']::text[], 'Husavik Harbour Iceland.jpg', ARRAY['wildlife', 'sea']::text[]),
    ('geosea-geothermal-sea-baths', 'husavik', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Геотермальные морские купальни GeoSea', 'GeoSea Geothermal Sea Baths', 'GeoSea геотермал теңіз моншалары', 66.05610000, -17.33830000, 'GeoSea Husavik Iceland', ARRAY['husavik']::text[], ARRAY['akureyri', 'husavik']::text[], 'GeoSea Husavik Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('lake-myvatn', 'myvatn', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Миватн', 'Lake Myvatn', 'Миватн көлі', 65.60000000, -17.00000000, 'Lake Myvatn Iceland', ARRAY['myvatn']::text[], ARRAY['akureyri', 'myvatn']::text[], 'Lake Myvatn Iceland.jpg', ARRAY['north-iceland', 'lake']::text[]),
    ('dimmuborgir', 'myvatn', 'NATURE', 2, 'HOURS', 4.8, 'Диммуборгир', 'Dimmuborgir', 'Диммуборгир', 65.59210000, -16.90800000, 'Dimmuborgir Iceland', ARRAY['myvatn']::text[], ARRAY['akureyri', 'myvatn']::text[], 'Dimmuborgir Iceland.jpg', ARRAY['lava-field', 'hiking']::text[]),
    ('hverir-namafjall', 'myvatn', 'NATURE', 1, 'HOURS', 4.8, 'Геотермальная зона Хверир и Намафьядль', 'Hverir Namafjall Geothermal Area', 'Хверир Намафьядль геотермал аймағы', 65.64130000, -16.80800000, 'Hverir Namafjall Iceland', ARRAY['myvatn']::text[], ARRAY['akureyri', 'myvatn']::text[], 'Hverir Iceland.jpg', ARRAY['geothermal', 'north-iceland']::text[]),
    ('myvatn-nature-baths', 'myvatn', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Природные купальни Миватн', 'Myvatn Nature Baths', 'Миватн табиғи моншалары', 65.63070000, -16.84750000, 'Myvatn Nature Baths Iceland', ARRAY['myvatn']::text[], ARRAY['akureyri', 'myvatn']::text[], 'Myvatn Nature Baths Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('dettifoss-waterfall', 'dettifoss', 'NATURE', 2, 'HOURS', 4.9, 'Водопад Деттифосс', 'Dettifoss Waterfall', 'Деттифосс сарқырамасы', 65.81430000, -16.38440000, 'Dettifoss Waterfall Iceland', ARRAY['dettifoss']::text[], ARRAY['akureyri', 'myvatn', 'dettifoss']::text[], 'Dettifoss Iceland.jpg', ARRAY['waterfall', 'north-iceland']::text[]),
    ('asbyrgi-canyon', 'dettifoss', 'PARK', 3, 'HOURS', 4.8, 'Каньон Асбирги', 'Asbyrgi Canyon', 'Асбирги каньоны', 66.02560000, -16.49600000, 'Asbyrgi Canyon Iceland', ARRAY['dettifoss', 'husavik']::text[], ARRAY['akureyri', 'husavik', 'dettifoss']::text[], 'Asbyrgi Iceland.jpg', ARRAY['hiking', 'north-iceland']::text[]),

    ('east-iceland-heritage-museum', 'egilsstadir', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей наследия Восточной Исландии', 'East Iceland Heritage Museum', 'Шығыс Исландия мұра музейі', 65.26260000, -14.39640000, 'East Iceland Heritage Museum Egilsstadir', ARRAY['egilsstadir']::text[], ARRAY['egilsstadir']::text[], 'Egilsstadir Iceland.jpg', ARRAY['indoor']::text[]),
    ('vok-baths', 'egilsstadir', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Купальни Vok', 'Vok Baths', 'Vok моншалары', 65.30340000, -14.44620000, 'Vok Baths Iceland', ARRAY['egilsstadir']::text[], ARRAY['egilsstadir']::text[], 'Vok Baths Iceland.jpg', ARRAY['geothermal', 'wellness']::text[]),
    ('hengifoss-waterfall', 'egilsstadir', 'NATURE', 3, 'HOURS', 4.8, 'Водопад Хенгифосс', 'Hengifoss Waterfall', 'Хенгифосс сарқырамасы', 65.09240000, -14.88530000, 'Hengifoss Waterfall Iceland', ARRAY['egilsstadir']::text[], ARRAY['egilsstadir']::text[], 'Hengifoss Iceland.jpg', ARRAY['waterfall', 'east-iceland']::text[]),
    ('studlagil-canyon', 'egilsstadir', 'NATURE', 3, 'HOURS', 4.8, 'Каньон Студлагиль', 'Studlagil Canyon', 'Студлагиль каньоны', 65.16230000, -15.30810000, 'Studlagil Canyon Iceland', ARRAY['egilsstadir']::text[], ARRAY['egilsstadir']::text[], 'Studlagil Canyon Iceland.jpg', ARRAY['basalt', 'east-iceland']::text[]),
    ('seydisfjordur-rainbow-street', 'seydisfjordur', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Радужная улица и церковь Сейдисфьордюра', 'Seydisfjordur Rainbow Street', 'Сейдисфьордюр кемпірқосақ көшесі', 65.26050000, -14.00970000, 'Seydisfjordur Rainbow Street Iceland', ARRAY['seydisfjordur']::text[], ARRAY['egilsstadir', 'seydisfjordur']::text[], 'Seydisfjordur Iceland.jpg', ARRAY['photo-stop', 'east-iceland']::text[]),
    ('technical-museum-east-iceland', 'seydisfjordur', 'MUSEUM', 1, 'HOURS', 4.5, 'Технический музей Восточной Исландии', 'Technical Museum of East Iceland', 'Шығыс Исландия техникалық музейі', 65.26610000, -13.99120000, 'Technical Museum of East Iceland Seydisfjordur', ARRAY['seydisfjordur']::text[], ARRAY['egilsstadir', 'seydisfjordur']::text[], 'Technical Museum East Iceland.jpg', ARRAY['indoor']::text[]),
    ('hafnarholmi-puffin-colony', 'borgarfjordur-eystri', 'NATURE', 2, 'HOURS', 4.8, 'Колония тупиков Хабнархольми', 'Hafnarholmi Puffin Colony', 'Хабнархольми тупиктер колониясы', 65.54210000, -13.75480000, 'Hafnarholmi Puffin Colony Iceland', ARRAY['borgarfjordur-eystri']::text[], ARRAY['egilsstadir', 'borgarfjordur-eystri']::text[], 'Borgarfjordur Eystri Iceland.jpg', ARRAY['wildlife', 'birdwatching']::text[]);

CREATE TEMP TABLE seed_iceland_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-iceland-place:' || seed.slug) AS place_hash,
        md5('id-iceland-media:' || seed.slug) AS media_hash
    FROM seed_iceland_priority_places seed
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
    ARRAY['iceland', city_id, slug, lower(category), 'iceland-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Исландии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Iceland tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Исландия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'IS',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 3000::numeric
        ELSE 1500::numeric
    END,
    'ISK',
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
FROM seed_iceland_resolved_places
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
FROM seed_iceland_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_iceland_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_iceland_resolved_places
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
FROM seed_iceland_resolved_places seed
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
FROM seed_iceland_resolved_places
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
    'IS',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_iceland_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'IS',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_iceland_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_iceland_resolved_places;
DROP TABLE IF EXISTS seed_iceland_priority_places;
