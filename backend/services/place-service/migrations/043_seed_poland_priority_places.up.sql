-- Priority Poland destination places seed.
-- Poland is seeded as a broad country destination with city-like tourist hubs
-- for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_poland_resolved_places;
DROP TABLE IF EXISTS seed_poland_priority_places;

CREATE TEMP TABLE seed_poland_priority_places (
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
    media_file text NOT NULL
);

INSERT INTO seed_poland_priority_places (
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
    media_file
) VALUES
    ('warsaw-old-town', 'warsaw', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Старый город Варшавы', 'Warsaw Old Town', 'Варшава ескі қаласы', 52.24980000, 21.01220000, 'Warsaw Old Town Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('royal-castle-warsaw', 'warsaw', 'MUSEUM', 2, 'HOURS', 4.8, 'Королевский замок в Варшаве', 'Royal Castle in Warsaw', 'Варшава корольдік қамалы', 52.24770000, 21.01410000, 'Royal Castle in Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'RoyalCastleWarsaw.jpg'),
    ('lazienki-park', 'warsaw', 'PARK', 3, 'HOURS', 4.9, 'Королевские Лазенки', 'Lazienki Park', 'Лазенки корольдік саябағы', 52.21470000, 21.03290000, 'Lazienki Park Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Palace on the Isle (21895p).jpg'),
    ('wilanow-palace', 'warsaw', 'MUSEUM', 2, 'HOURS', 4.8, 'Дворец-музей в Вилянуве', 'Wilanow Palace Museum', 'Вилянув сарай музейі', 52.16510000, 21.09020000, 'Wilanow Palace Museum Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'RoyalCastleWarsaw.jpg'),
    ('palace-culture-science-warsaw', 'warsaw', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Дворец культуры и науки', 'Palace of Culture and Science', 'Мәдениет және ғылым сарайы', 52.23180000, 21.00600000, 'Palace of Culture and Science Warsaw', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Palace of Culture and Science-Warsaw.jpg'),
    ('polin-museum', 'warsaw', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей POLIN истории польских евреев', 'POLIN Museum', 'POLIN поляк еврейлері тарихы музейі', 52.24930000, 20.99300000, 'POLIN Museum Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'POLIN Muzeum Historii Żydów Polskich 004.jpg'),
    ('warsaw-rising-museum', 'warsaw', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Варшавского восстания', 'Warsaw Rising Museum', 'Варшава көтерілісі музейі', 52.23240000, 20.98110000, 'Warsaw Rising Museum Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Warsaw Rising Museum.JPG'),
    ('copernicus-science-centre', 'warsaw', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Научный центр Коперник', 'Copernicus Science Centre', 'Коперник ғылым орталығы', 52.24170000, 21.02860000, 'Copernicus Science Centre Warsaw', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Centrum Nauki Kopernik - Planetarium - Warszawa (1).jpg'),
    ('university-library-roof-garden', 'warsaw', 'PARK', 1, 'HOURS', 4.6, 'Сад на крыше библиотеки Варшавского университета', 'University of Warsaw Library Roof Garden', 'Варшава университеті кітапханасының шатыр бағы', 52.24200000, 21.02470000, 'University of Warsaw Library roof garden', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('vistula-boulevards', 'warsaw', 'PARK', 2, 'HOURS', 4.6, 'Вислинские бульвары', 'Vistula Boulevards', 'Висла бульварлары', 52.24290000, 21.02990000, 'Vistula Boulevards Warsaw', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('poniatowka-beach', 'warsaw', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Понятувка', 'Poniatowka Beach', 'Понятувка жағажайы', 52.23940000, 21.04400000, 'Poniatowka Beach Warsaw', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('hala-koszyki', 'warsaw', 'MARKET', 2, 'HOURS', 4.6, 'Hala Koszyki', 'Hala Koszyki', 'Hala Koszyki', 52.22250000, 21.01500000, 'Hala Koszyki Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('elektrownia-powisle', 'warsaw', 'FOOD', 2, 'HOURS', 4.5, 'Elektrownia Powisle', 'Elektrownia Powisle', 'Elektrownia Powisle', 52.24080000, 21.02690000, 'Elektrownia Powisle Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Old Town Market Square, Warsaw 16.jpg'),
    ('fabryka-norblina', 'warsaw', 'FOOD', 2, 'HOURS', 4.5, 'Fabryka Norblina', 'Fabryka Norblina', 'Fabryka Norblina', 52.23240000, 20.99270000, 'Fabryka Norblina Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Fabryka Norblina, ul. Żelazna, Warszawa (1).jpg'),
    ('zlote-tarasy', 'warsaw', 'SHOPPING', 2, 'HOURS', 4.5, 'Zlote Tarasy', 'Zlote Tarasy', 'Zlote Tarasy', 52.23020000, 21.00150000, 'Zlote Tarasy Warsaw Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'Palace of Culture and Science-Warsaw.jpg'),
    ('kampinos-national-park', 'warsaw', 'NATURE', 4, 'HOURS', 4.7, 'Кампиносский национальный парк', 'Kampinos National Park', 'Кампинос ұлттық паркі', 52.29950000, 20.81740000, 'Kampinos National Park Poland', ARRAY['warsaw']::text[], ARRAY['warsaw']::text[], 'POL Kampinos National Park (6).JPG'),

    ('krakow-main-market-square', 'krakow', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Главная рыночная площадь Кракова', 'Krakow Main Market Square', 'Краков басты базар алаңы', 50.06170000, 19.93730000, 'Krakow Main Market Square Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('cloth-hall-krakow', 'krakow', 'MARKET', 2, 'HOURS', 4.7, 'Суконные ряды', 'Cloth Hall Krakow', 'Краков сукно қатарлары', 50.06170000, 19.93750000, 'Cloth Hall Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('st-marys-basilica-krakow', 'krakow', 'TEMPLE', 1, 'HOURS', 4.8, 'Мариацкий костел', 'St Mary''s Basilica Krakow', 'Краков Мария базиликасы', 50.06170000, 19.93920000, 'St Mary Basilica Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('wawel-royal-castle', 'krakow', 'MUSEUM', 3, 'HOURS', 4.9, 'Королевский замок Вавель', 'Wawel Royal Castle', 'Вавель корольдік қамалы', 50.05400000, 19.93520000, 'Wawel Royal Castle Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('wawel-cathedral', 'krakow', 'TEMPLE', 1, 'HOURS', 4.8, 'Вавельский кафедральный собор', 'Wawel Cathedral', 'Вавель кафедралды соборы', 50.05450000, 19.93560000, 'Wawel Cathedral Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('kazimierz', 'krakow', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Казимеж', 'Kazimierz', 'Казимеж', 50.05140000, 19.94490000, 'Kazimierz Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('schindler-factory', 'krakow', 'MUSEUM', 2, 'HOURS', 4.7, 'Фабрика Шиндлера', 'Schindler Factory Museum', 'Шиндлер фабрикасы музейі', 50.04740000, 19.96170000, 'Schindler Factory Museum Krakow', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('mocak-krakow', 'krakow', 'MUSEUM', 2, 'HOURS', 4.5, 'MOCAK', 'MOCAK Museum of Contemporary Art', 'MOCAK заманауи өнер музейі', 50.04760000, 19.96120000, 'MOCAK Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('planty-park-krakow', 'krakow', 'PARK', 2, 'HOURS', 4.7, 'Парк Планты', 'Planty Park Krakow', 'Краков Планты саябағы', 50.06270000, 19.93680000, 'Planty Park Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('galeria-krakowska', 'krakow', 'SHOPPING', 2, 'HOURS', 4.4, 'Galeria Krakowska', 'Galeria Krakowska', 'Galeria Krakowska', 50.06760000, 19.94620000, 'Galeria Krakowska Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('tauron-arena-krakow', 'krakow', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'TAURON Arena Krakow', 'TAURON Arena Krakow', 'TAURON Arena Krakow', 50.06720000, 19.99130000, 'TAURON Arena Krakow Poland', ARRAY['krakow']::text[], ARRAY['krakow']::text[], 'Wawel castle.jpg'),
    ('wieliczka-salt-mine', 'wieliczka', 'MUSEUM', 4, 'HOURS', 4.9, 'Соляная шахта Величка', 'Wieliczka Salt Mine', 'Величка тұз шахтасы', 49.98330000, 20.05400000, 'Wieliczka Salt Mine Poland', ARRAY['wieliczka', 'krakow']::text[], ARRAY['wieliczka', 'krakow']::text[], 'Wieliczka Salt Mine (35322151183).jpg'),
    ('auschwitz-birkenau-memorial', 'oswiecim', 'MUSEUM', 4, 'HOURS', 4.9, 'Мемориал и музей Аушвиц-Биркенау', 'Auschwitz-Birkenau Memorial and Museum', 'Аушвиц-Биркенау мемориалы және музейі', 50.03460000, 19.18130000, 'Auschwitz Birkenau Memorial Museum Oswiecim Poland', ARRAY['oswiecim', 'krakow']::text[], ARRAY['oswiecim', 'krakow']::text[], 'Auschwitz-Birkenau gate.jpg'),
    ('zakopane-krupowki', 'zakopane', 'MARKET', 2, 'HOURS', 4.5, 'Улица Крупувки', 'Krupowki Street', 'Крупувки көшесі', 49.29460000, 19.95260000, 'Krupowki Street Zakopane Poland', ARRAY['zakopane']::text[], ARRAY['zakopane', 'krakow']::text[], 'MORSKIE OKO.jpg'),
    ('tatra-national-park', 'zakopane', 'NATURE', 5, 'HOURS', 4.9, 'Татранский национальный парк', 'Tatra National Park', 'Татра ұлттық паркі', 49.25000000, 19.93330000, 'Tatra National Park Poland Zakopane', ARRAY['zakopane']::text[], ARRAY['zakopane']::text[], 'MORSKIE OKO.jpg'),
    ('morskie-oko', 'zakopane', 'NATURE', 5, 'HOURS', 4.9, 'Морское Око', 'Morskie Oko', 'Морске-Око көлі', 49.20170000, 20.07030000, 'Morskie Oko Poland', ARRAY['zakopane']::text[], ARRAY['zakopane']::text[], 'MORSKIE OKO.jpg'),
    ('gubalowka', 'zakopane', 'NATURE', 3, 'HOURS', 4.6, 'Губалувка', 'Gubalowka', 'Губалувка', 49.30610000, 19.93590000, 'Gubalowka Zakopane Poland', ARRAY['zakopane']::text[], ARRAY['zakopane']::text[], 'MORSKIE OKO.jpg'),

    ('gdansk-old-town', 'gdansk', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Старый город Гданьска', 'Gdansk Old Town', 'Гданьск ескі қаласы', 54.34800000, 18.65300000, 'Gdansk Old Town Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('neptune-fountain-gdansk', 'gdansk', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Фонтан Нептуна', 'Neptune Fountain Gdansk', 'Гданьск Нептун фонтаны', 54.34860000, 18.65340000, 'Neptune Fountain Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('st-marys-basilica-gdansk', 'gdansk', 'TEMPLE', 1, 'HOURS', 4.8, 'Базилика Святой Марии в Гданьске', 'St Mary''s Basilica Gdansk', 'Гданьск Әулие Мария базиликасы', 54.34990000, 18.65300000, 'St Mary Basilica Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('gdansk-crane', 'gdansk', 'MUSEUM', 1, 'HOURS', 4.7, 'Журав над Мотлавой', 'Gdansk Crane', 'Гданьск краны', 54.35090000, 18.65740000, 'Gdansk Crane Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('museum-second-world-war-gdansk', 'gdansk', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Второй мировой войны', 'Museum of the Second World War Gdansk', 'Гданьск Екінші дүниежүзілік соғыс музейі', 54.35600000, 18.65910000, 'Museum of the Second World War Gdansk', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('european-solidarity-centre', 'gdansk', 'MUSEUM', 2, 'HOURS', 4.7, 'Европейский центр солидарности', 'European Solidarity Centre', 'Еуропалық ынтымақ орталығы', 54.36140000, 18.64910000, 'European Solidarity Centre Gdansk', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('oliwa-park-cathedral', 'gdansk', 'PARK', 2, 'HOURS', 4.7, 'Оливский парк и кафедральный собор', 'Oliwa Park and Cathedral', 'Олива саябағы және соборы', 54.41100000, 18.56050000, 'Oliwa Park Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('brzezno-beach-pier', 'gdansk', 'BEACH', 3, 'HOURS', 4.6, 'Пляж и пирс Бжезьно', 'Brzezno Beach and Pier', 'Бжезьно жағажайы және пирсі', 54.41160000, 18.62420000, 'Brzezno Pier Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('hala-targowa-gdansk', 'gdansk', 'MARKET', 1, 'HOURS', 4.4, 'Хала Таргова', 'Hala Targowa Gdansk', 'Гданьск Хала Таргова', 54.35360000, 18.65320000, 'Hala Targowa Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('forum-gdansk', 'gdansk', 'SHOPPING', 2, 'HOURS', 4.4, 'Forum Gdansk', 'Forum Gdansk', 'Forum Gdansk', 54.35050000, 18.64540000, 'Forum Gdansk Poland', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('montownia-food-hall', 'gdansk', 'FOOD', 2, 'HOURS', 4.5, 'Food Hall Montownia', 'Food Hall Montownia', 'Food Hall Montownia', 54.36190000, 18.65710000, 'Food Hall Montownia Gdansk', ARRAY['gdansk']::text[], ARRAY['gdansk']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('sopot-pier', 'sopot', 'BEACH', 2, 'HOURS', 4.8, 'Сопотский пирс', 'Sopot Pier', 'Сопот пирсі', 54.44790000, 18.56870000, 'Sopot Pier Poland', ARRAY['sopot', 'gdansk']::text[], ARRAY['sopot']::text[], 'Sopot pier.jpg'),
    ('sopot-beach', 'sopot', 'BEACH', 4, 'HOURS', 4.7, 'Центральный пляж Сопота', 'Sopot Central Beach', 'Сопот орталық жағажайы', 54.44700000, 18.57000000, 'Sopot Beach Poland', ARRAY['sopot']::text[], ARRAY['sopot']::text[], 'Sopot pier.jpg'),
    ('sopot-monte-cassino', 'sopot', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Улица Монте-Кассино', 'Monte Cassino Street Sopot', 'Сопот Монте-Кассино көшесі', 54.44450000, 18.56450000, 'Monte Cassino Street Sopot Poland', ARRAY['sopot']::text[], ARRAY['sopot']::text[], 'Sopot pier.jpg'),
    ('gdynia-orlowo-cliff', 'gdynia', 'NATURE', 2, 'HOURS', 4.7, 'Орловский клиф', 'Orlowo Cliff', 'Орлово жарқабағы', 54.47380000, 18.56150000, 'Orlowo Cliff Gdynia Poland', ARRAY['gdynia', 'sopot']::text[], ARRAY['gdynia']::text[], 'Sopot pier.jpg'),
    ('gdynia-dar-pomorza', 'gdynia', 'MUSEUM', 1, 'HOURS', 4.6, 'Корабль-музей Дар Поморья', 'Dar Pomorza Museum Ship', 'Дар Поморья музей кемесі', 54.51860000, 18.55180000, 'Dar Pomorza Gdynia Poland', ARRAY['gdynia']::text[], ARRAY['gdynia']::text[], 'Sopot pier.jpg'),
    ('gdynia-aquarium', 'gdynia', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Гдыньский аквариум', 'Gdynia Aquarium', 'Гдыня аквариумы', 54.51890000, 18.55600000, 'Gdynia Aquarium Poland', ARRAY['gdynia']::text[], ARRAY['gdynia']::text[], 'Sopot pier.jpg'),
    ('malbork-castle', 'malbork', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Замок Тевтонского ордена в Мальборке', 'Malbork Castle', 'Мальборк қамалы', 54.03990000, 19.02800000, 'Malbork Castle Poland', ARRAY['malbork', 'gdansk']::text[], ARRAY['malbork', 'gdansk']::text[], 'Malbork Castle from Nogat.jpg'),
    ('torun-old-town', 'torun', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Средневековый старый город Торуня', 'Torun Old Town', 'Торунь ортағасырлық ескі қаласы', 53.01000000, 18.60400000, 'Torun Old Town Poland', ARRAY['torun']::text[], ARRAY['torun']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('torun-copernicus-house', 'torun', 'MUSEUM', 1, 'HOURS', 4.6, 'Дом Николая Коперника', 'Nicolaus Copernicus House', 'Николай Коперник үйі', 53.00940000, 18.60420000, 'Nicolaus Copernicus House Torun Poland', ARRAY['torun']::text[], ARRAY['torun']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),
    ('torun-gingerbread-museum', 'torun', 'FOOD', 2, 'HOURS', 4.7, 'Музей торуньского пряника', 'Museum of Torun Gingerbread', 'Торунь пряник музейі', 53.01150000, 18.60800000, 'Museum of Torun Gingerbread Poland', ARRAY['torun']::text[], ARRAY['torun']::text[], 'Fontanna_Neptuna_Gdansk.jpg'),

    ('wroclaw-market-square', 'wroclaw', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Рыночная площадь Вроцлава', 'Wroclaw Market Square', 'Вроцлав базар алаңы', 51.10970000, 17.03080000, 'Wroclaw Market Square Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('wroclaw-town-hall', 'wroclaw', 'MUSEUM', 1, 'HOURS', 4.7, 'Старая ратуша Вроцлава', 'Wroclaw Old Town Hall', 'Вроцлав ескі ратушасы', 51.10940000, 17.03120000, 'Wroclaw Old Town Hall Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('ostrow-tumski-wroclaw', 'wroclaw', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Острув-Тумский', 'Ostrow Tumski Wroclaw', 'Вроцлав Острув-Тумский', 51.11410000, 17.04610000, 'Ostrow Tumski Wroclaw Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('centennial-hall', 'wroclaw', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Зал Столетия', 'Centennial Hall', 'Жүзжылдық залы', 51.10690000, 17.07700000, 'Centennial Hall Wroclaw Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('wroclaw-zoo-afrykarium', 'wroclaw', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Вроцлавский зоопарк и Африкариум', 'Wroclaw Zoo and Afrykarium', 'Вроцлав зоопаркі және Африкариум', 51.10480000, 17.07410000, 'Wroclaw Zoo Afrykarium Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('hala-targowa-wroclaw', 'wroclaw', 'MARKET', 1, 'HOURS', 4.4, 'Хала Таргова Вроцлава', 'Hala Targowa Wroclaw', 'Вроцлав Хала Таргова', 51.11200000, 17.03900000, 'Hala Targowa Wroclaw Poland', ARRAY['wroclaw']::text[], ARRAY['wroclaw']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('poznan-old-market-square', 'poznan', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый рынок Познани', 'Poznan Old Market Square', 'Познань ескі базар алаңы', 52.40830000, 16.93420000, 'Poznan Old Market Square Poland', ARRAY['poznan']::text[], ARRAY['poznan']::text[], 'Poznań-Old Market Square.jpg'),
    ('poznan-croissant-museum', 'poznan', 'FOOD', 1, 'HOURS', 4.7, 'Музей познаньского рогалика', 'Poznan Croissant Museum', 'Познань рогалик музейі', 52.40870000, 16.93460000, 'Poznan Croissant Museum Poland', ARRAY['poznan']::text[], ARRAY['poznan']::text[], 'Poznań-Old Market Square.jpg'),
    ('poznan-cathedral-island', 'poznan', 'TEMPLE', 2, 'HOURS', 4.7, 'Тумский остров в Познани', 'Poznan Cathedral Island', 'Познань Тумский аралы', 52.41180000, 16.94710000, 'Poznan Cathedral Island Poland', ARRAY['poznan']::text[], ARRAY['poznan']::text[], 'Poznań-Old Market Square.jpg'),
    ('stary-browar', 'poznan', 'SHOPPING', 2, 'HOURS', 4.6, 'Stary Browar', 'Stary Browar', 'Stary Browar', 52.40190000, 16.92910000, 'Stary Browar Poznan Poland', ARRAY['poznan']::text[], ARRAY['poznan']::text[], 'Poznań-Old Market Square.jpg'),
    ('malta-lake-poznan', 'poznan', 'PARK', 3, 'HOURS', 4.6, 'Озеро Мальта', 'Malta Lake Poznan', 'Познань Мальта көлі', 52.40500000, 16.97300000, 'Malta Lake Poznan Poland', ARRAY['poznan']::text[], ARRAY['poznan']::text[], 'Poznań-Old Market Square.jpg'),
    ('manufaktura-lodz', 'lodz', 'SHOPPING', 3, 'HOURS', 4.7, 'Manufaktura Lodz', 'Manufaktura Lodz', 'Manufaktura Lodz', 51.77900000, 19.44800000, 'Manufaktura Lodz Poland', ARRAY['lodz']::text[], ARRAY['lodz']::text[], 'Poznań-Old Market Square.jpg'),
    ('piotrkowska-street', 'lodz', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Улица Пётрковская', 'Piotrkowska Street', 'Пётрковская көшесі', 51.75920000, 19.45600000, 'Piotrkowska Street Lodz Poland', ARRAY['lodz']::text[], ARRAY['lodz']::text[], 'Poznań-Old Market Square.jpg'),
    ('ec1-lodz', 'lodz', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'EC1 Lodz', 'EC1 Lodz', 'EC1 Lodz', 51.76890000, 19.46940000, 'EC1 Lodz Poland', ARRAY['lodz']::text[], ARRAY['lodz']::text[], 'Poznań-Old Market Square.jpg'),
    ('ms2-lodz', 'lodz', 'MUSEUM', 2, 'HOURS', 4.5, 'ms2 Музей искусства', 'ms2 Museum of Art Lodz', 'Лодзь ms2 өнер музейі', 51.77910000, 19.45180000, 'ms2 Museum Lodz Poland', ARRAY['lodz']::text[], ARRAY['lodz']::text[], 'Poznań-Old Market Square.jpg'),
    ('katowice-nikiszowiec', 'katowice', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Никишовец', 'Nikiszowiec', 'Никишовец', 50.24290000, 19.08200000, 'Nikiszowiec Katowice Poland', ARRAY['katowice']::text[], ARRAY['katowice']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('silesian-museum', 'katowice', 'MUSEUM', 2, 'HOURS', 4.7, 'Силезский музей', 'Silesian Museum Katowice', 'Силезия музейі', 50.26480000, 19.03990000, 'Silesian Museum Katowice Poland', ARRAY['katowice']::text[], ARRAY['katowice']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('spodek', 'katowice', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Сподек', 'Spodek', 'Сподек', 50.26630000, 19.02540000, 'Spodek Katowice Poland', ARRAY['katowice']::text[], ARRAY['katowice']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('silesia-city-center', 'katowice', 'SHOPPING', 2, 'HOURS', 4.5, 'Silesia City Center', 'Silesia City Center', 'Silesia City Center', 50.27050000, 19.00460000, 'Silesia City Center Katowice Poland', ARRAY['katowice']::text[], ARRAY['katowice']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('silesian-park', 'chorzow', 'PARK', 4, 'HOURS', 4.7, 'Силезский парк', 'Silesian Park', 'Силезия саябағы', 50.28870000, 18.98730000, 'Silesian Park Chorzow Poland', ARRAY['chorzow', 'katowice']::text[], ARRAY['chorzow', 'katowice']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('lublin-old-town', 'lublin', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Люблина', 'Lublin Old Town', 'Люблин ескі қаласы', 51.24860000, 22.56800000, 'Lublin Old Town Poland', ARRAY['lublin']::text[], ARRAY['lublin']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('lublin-castle', 'lublin', 'MUSEUM', 2, 'HOURS', 4.7, 'Люблинский замок', 'Lublin Castle', 'Люблин қамалы', 51.25060000, 22.57220000, 'Lublin Castle Poland', ARRAY['lublin']::text[], ARRAY['lublin']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('bialowieza-national-park', 'bialowieza', 'NATURE', 4, 'HOURS', 4.9, 'Беловежский национальный парк', 'Bialowieza National Park', 'Беловежа ұлттық паркі', 52.70000000, 23.86670000, 'Bialowieza National Park Poland', ARRAY['bialowieza', 'bialystok']::text[], ARRAY['bialowieza', 'bialystok']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('branicki-palace-bialystok', 'bialystok', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Браницких', 'Branicki Palace Bialystok', 'Белосток Браницкий сарайы', 53.13250000, 23.16460000, 'Branicki Palace Bialystok Poland', ARRAY['bialystok']::text[], ARRAY['bialystok']::text[], '2019-07-02 Wroclaw market square.jpg'),
    ('jasna-gora-monastery', 'czestochowa', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Ясна Гура', 'Jasna Gora Monastery', 'Ясна Гура монастыры', 50.81200000, 19.09770000, 'Jasna Gora Monastery Czestochowa Poland', ARRAY['czestochowa']::text[], ARRAY['czestochowa']::text[], 'Wawel castle.jpg'),
    ('zamosc-old-town', 'zamosc', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Замосця', 'Zamosc Old Town', 'Замосць ескі қаласы', 50.71700000, 23.25240000, 'Zamosc Old Town Poland', ARRAY['zamosc', 'lublin']::text[], ARRAY['zamosc', 'lublin']::text[], 'Wawel castle.jpg'),
    ('szczecin-pomeranian-dukes-castle', 'szczecin', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок померанских князей', 'Pomeranian Dukes Castle Szczecin', 'Щецин померан герцогтері қамалы', 53.42570000, 14.56020000, 'Pomeranian Dukes Castle Szczecin Poland', ARRAY['szczecin']::text[], ARRAY['szczecin']::text[], 'Sopot pier.jpg'),
    ('szczecin-bulwar-piastowski', 'szczecin', 'PARK', 2, 'HOURS', 4.5, 'Пястовский бульвар', 'Piastowski Boulevard Szczecin', 'Щецин Пястовский бульвары', 53.42440000, 14.56400000, 'Piastowski Boulevard Szczecin Poland', ARRAY['szczecin']::text[], ARRAY['szczecin']::text[], 'Sopot pier.jpg');

CREATE TEMP TABLE seed_poland_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-poland-place:' || seed.slug) AS place_hash,
        md5('id-poland-media:' || seed.slug) AS media_hash
    FROM seed_poland_priority_places seed
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
    ARRAY['poland', city_id, slug, lower(category), 'poland-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Польши: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Poland tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Польша туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'PL',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 60::numeric
        ELSE 30::numeric
    END,
    'PLN',
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
FROM seed_poland_resolved_places
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
FROM seed_poland_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_poland_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_poland_resolved_places
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
FROM seed_poland_resolved_places seed
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
FROM seed_poland_resolved_places
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
    'PL',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_poland_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'PL',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_poland_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_poland_resolved_places;
DROP TABLE IF EXISTS seed_poland_priority_places;
