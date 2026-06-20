-- Priority Serbia destination places seed.
-- The seed covers Belgrade, Vojvodina, south/east Serbia and west/central nature resorts.

DROP TABLE IF EXISTS seed_serbia_resolved_places;
DROP TABLE IF EXISTS seed_serbia_priority_places;

CREATE TEMP TABLE seed_serbia_priority_places (
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

INSERT INTO seed_serbia_priority_places (
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
    ('belgrade-fortress', 'belgrade', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Белградская крепость', 'Belgrade Fortress', 'Белград қамалы', 44.82300000, 20.45090000, 'Belgrade Fortress Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Belgrade_Fortress_Kalemegdan.jpg', ARRAY['fortress', 'kalemegdan']::text[]),
    ('kalemegdan-park', 'belgrade', 'PARK', 2, 'HOURS', 4.8, 'Парк Калемегдан', 'Kalemegdan Park', 'Калемегдан саябағы', 44.82360000, 20.45030000, 'Kalemegdan Park Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Kalemegdan_Park_Belgrade.jpg', ARRAY['green-space', 'viewpoint']::text[]),
    ('republic-square-belgrade', 'belgrade', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Площадь Республики в Белграде', 'Republic Square Belgrade', 'Белград Республика алаңы', 44.81630000, 20.46000000, 'Republic Square Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Republic_Square_Belgrade.jpg', ARRAY['city-center', 'walk']::text[]),
    ('knez-mihailova-street', 'belgrade', 'SHOPPING', 1, 'HOURS', 4.7, 'Улица князя Михаила', 'Knez Mihailova Street', 'Князь Михаил көшесі', 44.81760000, 20.45680000, 'Knez Mihailova Street Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Knez_Mihailova_Street_Belgrade.jpg', ARRAY['shopping-street', 'walk']::text[]),
    ('skadarlija', 'belgrade', 'FOOD', 2, 'HOURS', 4.7, 'Скадарлия', 'Skadarlija', 'Скадарлия', 44.81790000, 20.46430000, 'Skadarlija Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Skadarlija_Belgrade.jpg', ARRAY['bohemian-quarter', 'evening']::text[]),
    ('saint-sava-temple', 'belgrade', 'TEMPLE', 1, 'HOURS', 4.8, 'Храм Святого Саввы', 'Saint Sava Temple', 'Әулие Сава храмы', 44.79810000, 20.46860000, 'Saint Sava Temple Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Church_of_Saint_Sava_Belgrade.jpg', ARRAY['orthodox', 'landmark']::text[]),
    ('national-museum-serbia', 'belgrade', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Сербии', 'National Museum of Serbia', 'Сербия ұлттық музейі', 44.81630000, 20.45990000, 'National Museum of Serbia Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'National_Museum_of_Serbia_Belgrade.jpg', ARRAY['art', 'history']::text[]),
    ('nikola-tesla-museum', 'belgrade', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей Николы Теслы', 'Nikola Tesla Museum', 'Никола Тесла музейі', 44.80520000, 20.47030000, 'Nikola Tesla Museum Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Nikola_Tesla_Museum_Belgrade.jpg', ARRAY['science', 'family']::text[]),
    ('museum-of-yugoslavia', 'belgrade', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Югославии', 'Museum of Yugoslavia', 'Югославия музейі', 44.78670000, 20.45140000, 'Museum of Yugoslavia Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Museum_of_Yugoslavia_Belgrade.jpg', ARRAY['history']::text[]),
    ('ethnographic-museum-belgrade', 'belgrade', 'MUSEUM', 1, 'HOURS', 4.5, 'Этнографический музей Белграда', 'Ethnographic Museum Belgrade', 'Белград этнография музейі', 44.81970000, 20.45680000, 'Ethnographic Museum Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Ethnographic_Museum_Belgrade.jpg', ARRAY['culture', 'indoor']::text[]),
    ('museum-contemporary-art-belgrade', 'belgrade', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей современного искусства Белграда', 'Museum of Contemporary Art Belgrade', 'Белград заманауи өнер музейі', 44.81840000, 20.44270000, 'Museum of Contemporary Art Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Museum_of_Contemporary_Art_Belgrade.jpg', ARRAY['art', 'indoor']::text[]),
    ('princess-ljubica-residence', 'belgrade', 'MUSEUM', 1, 'HOURS', 4.5, 'Конак княгини Любицы', 'Princess Ljubica Residence', 'Княгиня Любица резиденциясы', 44.81830000, 20.45210000, 'Princess Ljubica Residence Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Princess_Ljubica_Residence_Belgrade.jpg', ARRAY['heritage']::text[]),
    ('belgrade-zoo', 'belgrade', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Белградский зоопарк', 'Belgrade Zoo', 'Белград зообағы', 44.82410000, 20.45300000, 'Belgrade Zoo Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Belgrade_Zoo.jpg', ARRAY['family', 'zoo']::text[]),
    ('museum-of-illusions-belgrade', 'belgrade', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Музей иллюзий в Белграде', 'Museum of Illusions Belgrade', 'Белград иллюзиялар музейі', 44.81430000, 20.46240000, 'Museum of Illusions Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Museum_of_Illusions_Belgrade.jpg', ARRAY['family', 'indoor']::text[]),
    ('ada-ciganlija', 'belgrade', 'BEACH', 3, 'HOURS', 4.7, 'Ада Циганлия', 'Ada Ciganlija', 'Ада Циганлия', 44.78880000, 20.40020000, 'Ada Ciganlija Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Ada_Ciganlija_Belgrade.jpg', ARRAY['lake-beach', 'summer']::text[]),
    ('jevremovac-botanical-garden', 'belgrade', 'NATURE', 1, 'HOURS', 4.6, 'Ботанический сад Евремовац', 'Jevremovac Botanical Garden', 'Евремовац ботаникалық бағы', 44.81660000, 20.47440000, 'Jevremovac Botanical Garden Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Jevremovac_Botanical_Garden.jpg', ARRAY['garden']::text[]),
    ('tasmajdan-park', 'belgrade', 'PARK', 1, 'HOURS', 4.5, 'Парк Ташмайдан', 'Tasmajdan Park', 'Ташмайдан саябағы', 44.81090000, 20.47160000, 'Tasmajdan Park Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Tasmajdan_Park_Belgrade.jpg', ARRAY['green-space']::text[]),
    ('topcider-park', 'belgrade', 'PARK', 1, 'HOURS', 4.5, 'Парк Топчидер', 'Topcider Park', 'Топчидер саябағы', 44.78310000, 20.44500000, 'Topcider Park Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Topcider_Park_Belgrade.jpg', ARRAY['green-space']::text[]),
    ('kosutnjak', 'belgrade', 'NATURE', 2, 'HOURS', 4.6, 'Кошутняк', 'Kosutnjak', 'Кошутняк', 44.76250000, 20.43550000, 'Kosutnjak Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Kosutnjak_Belgrade.jpg', ARRAY['forest', 'outdoor']::text[]),
    ('avala-tower', 'avala', 'NATURE', 2, 'HOURS', 4.7, 'Гора Авала и Авальская башня', 'Avala Mountain and Tower', 'Авала тауы және мұнарасы', 44.69530000, 20.51440000, 'Avala Tower Belgrade Serbia', ARRAY['avala', 'belgrade']::text[], ARRAY['belgrade', 'avala']::text[], 'Avala_Tower_Serbia.jpg', ARRAY['viewpoint', 'day-trip']::text[]),
    ('zemun-gardos-tower', 'zemun', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Земун и башня Гардош', 'Zemun Gardos Tower', 'Земун және Гардош мұнарасы', 44.84920000, 20.41070000, 'Gardos Tower Zemun Serbia', ARRAY['zemun', 'belgrade']::text[], ARRAY['belgrade', 'zemun']::text[], 'Gardos_Tower_Zemun.jpg', ARRAY['old-town', 'viewpoint']::text[]),
    ('zeleni-venac-market', 'belgrade', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Зелени Венац', 'Zeleni Venac Market', 'Зелени Венац базары', 44.81390000, 20.45540000, 'Zeleni Venac Market Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Zeleni_Venac_Market_Belgrade.jpg', ARRAY['local-market', 'food']::text[]),
    ('kalenic-market', 'belgrade', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Каленич', 'Kalenic Market', 'Каленич базары', 44.80060000, 20.47780000, 'Kalenic Market Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Kalenic_Market_Belgrade.jpg', ARRAY['local-market', 'food']::text[]),
    ('bajloni-market', 'belgrade', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Байлони', 'Bajloni Market', 'Байлони базары', 44.81940000, 20.46620000, 'Bajloni Market Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Bajloni_Market_Belgrade.jpg', ARRAY['local-market']::text[]),
    ('belgrade-night-market-block-44', 'belgrade', 'FOOD', 2, 'HOURS', 4.4, 'Белградский ночной маркет Блок 44', 'Belgrade Night Market Block 44', 'Белград түнгі маркері Блок 44', 44.80570000, 20.38440000, 'Belgrade Night Market Block 44', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Belgrade_Night_Market.jpg', ARRAY['night-market', 'evening']::text[]),
    ('usce-shopping-center', 'belgrade', 'SHOPPING', 2, 'HOURS', 4.5, 'ТЦ Ушче', 'Usce Shopping Center', 'Ушче сауда орталығы', 44.81530000, 20.43710000, 'Usce Shopping Center Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Usce_Shopping_Center_Belgrade.jpg', ARRAY['mall', 'indoor']::text[]),
    ('galerija-belgrade', 'belgrade', 'SHOPPING', 2, 'HOURS', 4.5, 'ТЦ Галерия Белград', 'Galerija Belgrade', 'Галерия Белград сауда орталығы', 44.80570000, 20.45150000, 'Galerija Belgrade Serbia', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Galerija_Belgrade.jpg', ARRAY['mall', 'indoor']::text[]),
    ('rajiceva-shopping-center', 'belgrade', 'SHOPPING', 1, 'HOURS', 4.4, 'ТЦ Райичева', 'Rajiceva Shopping Center', 'Райичева сауда орталығы', 44.81920000, 20.45400000, 'Rajiceva Shopping Center Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Rajiceva_Shopping_Center.jpg', ARRAY['mall', 'old-town']::text[]),
    ('ada-mall', 'belgrade', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Ada Mall', 'Ada Mall', 'Ada Mall сауда орталығы', 44.78140000, 20.41480000, 'Ada Mall Belgrade', ARRAY['belgrade']::text[], ARRAY['belgrade']::text[], 'Ada_Mall_Belgrade.jpg', ARRAY['mall', 'indoor']::text[]),

    ('petrovaradin-fortress', 'petrovaradin', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Петроварадинская крепость', 'Petrovaradin Fortress', 'Петроварадин қамалы', 45.25200000, 19.86250000, 'Petrovaradin Fortress Novi Sad', ARRAY['petrovaradin', 'novi-sad']::text[], ARRAY['novi-sad', 'petrovaradin']::text[], 'Petrovaradin_Fortress.jpg', ARRAY['fortress', 'viewpoint']::text[]),
    ('novi-sad-name-of-mary-church', 'novi-sad', 'TEMPLE', 1, 'HOURS', 4.6, 'Церковь имени Марии в Нови-Саде', 'Name of Mary Church Novi Sad', 'Нови-Сад Мария шіркеуі', 45.25550000, 19.84540000, 'Name of Mary Church Novi Sad', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Name_of_Mary_Church_Novi_Sad.jpg', ARRAY['church', 'city-center']::text[]),
    ('dunavski-park-novi-sad', 'novi-sad', 'PARK', 1, 'HOURS', 4.6, 'Дунайский парк', 'Dunavski Park', 'Дунай саябағы', 45.25560000, 19.85010000, 'Dunavski Park Novi Sad', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Dunavski_Park_Novi_Sad.jpg', ARRAY['green-space']::text[]),
    ('gallery-matica-srpska', 'novi-sad', 'MUSEUM', 2, 'HOURS', 4.6, 'Галерея Матицы сербской', 'Gallery of Matica Srpska', 'Матица серб галереясы', 45.25270000, 19.84010000, 'Gallery of Matica Srpska Novi Sad', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Gallery_of_Matica_Srpska.jpg', ARRAY['art', 'indoor']::text[]),
    ('museum-of-vojvodina', 'novi-sad', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Воеводины', 'Museum of Vojvodina', 'Воеводина музейі', 45.25690000, 19.85270000, 'Museum of Vojvodina Novi Sad', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Museum_of_Vojvodina.jpg', ARRAY['history', 'indoor']::text[]),
    ('novi-sad-synagogue', 'novi-sad', 'TEMPLE', 1, 'HOURS', 4.6, 'Нови-Садская синагога', 'Novi Sad Synagogue', 'Нови-Сад синагогасы', 45.25290000, 19.83720000, 'Novi Sad Synagogue Serbia', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Novi_Sad_Synagogue.jpg', ARRAY['synagogue', 'heritage']::text[]),
    ('strand-beach-novi-sad', 'novi-sad', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Штранд в Нови-Саде', 'Strand Beach Novi Sad', 'Нови-Сад Штранд жағажайы', 45.23940000, 19.84260000, 'Strand Beach Novi Sad Serbia', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Strand_Beach_Novi_Sad.jpg', ARRAY['danube', 'summer']::text[]),
    ('promenada-novi-sad', 'novi-sad', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Promenada Novi Sad', 'Promenada Novi Sad', 'Promenada Novi Sad сауда орталығы', 45.24790000, 19.83700000, 'Promenada Novi Sad Shopping Mall', ARRAY['novi-sad']::text[], ARRAY['novi-sad']::text[], 'Promenada_Novi_Sad.jpg', ARRAY['mall', 'indoor']::text[]),
    ('sremski-karlovci-town-center', 'sremski-karlovci', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Исторический центр Сремски-Карловци', 'Sremski Karlovci Town Center', 'Сремски-Карловци тарихи орталығы', 45.20270000, 19.93360000, 'Sremski Karlovci Town Center Serbia', ARRAY['sremski-karlovci']::text[], ARRAY['novi-sad', 'sremski-karlovci']::text[], 'Sremski_Karlovci.jpg', ARRAY['old-town', 'wine']::text[]),
    ('chapel-of-peace-sremski-karlovci', 'sremski-karlovci', 'TEMPLE', 1, 'HOURS', 4.5, 'Часовня мира', 'Chapel of Peace Sremski Karlovci', 'Бейбітшілік капелласы', 45.20190000, 19.93620000, 'Chapel of Peace Sremski Karlovci', ARRAY['sremski-karlovci']::text[], ARRAY['sremski-karlovci']::text[], 'Chapel_of_Peace_Sremski_Karlovci.jpg', ARRAY['chapel', 'heritage']::text[]),
    ('subotica-city-hall', 'subotica', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Ратуша Суботицы', 'Subotica City Hall', 'Суботица ратушасы', 46.10040000, 19.66510000, 'Subotica City Hall Serbia', ARRAY['subotica']::text[], ARRAY['subotica']::text[], 'Subotica_City_Hall.jpg', ARRAY['art-nouveau', 'city-symbol']::text[]),
    ('subotica-synagogue', 'subotica', 'TEMPLE', 1, 'HOURS', 4.7, 'Суботицкая синагога', 'Subotica Synagogue', 'Суботица синагогасы', 46.10090000, 19.66760000, 'Subotica Synagogue Serbia', ARRAY['subotica']::text[], ARRAY['subotica']::text[], 'Subotica_Synagogue.jpg', ARRAY['art-nouveau', 'synagogue']::text[]),
    ('raichle-palace', 'subotica', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Дворец Ференца Райхля', 'Raichle Palace', 'Райхль сарайы', 46.09660000, 19.66770000, 'Raichle Palace Subotica Serbia', ARRAY['subotica']::text[], ARRAY['subotica']::text[], 'Raichle_Palace_Subotica.jpg', ARRAY['art-nouveau']::text[]),
    ('lake-palic', 'palic', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Палич', 'Lake Palic', 'Палич көлі', 46.10190000, 19.75920000, 'Lake Palic Serbia', ARRAY['palic']::text[], ARRAY['subotica', 'palic']::text[], 'Lake_Palic_Serbia.jpg', ARRAY['lake', 'resort']::text[]),
    ('palic-zoo', 'palic', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Зоопарк Палич', 'Palic Zoo', 'Палич зообағы', 46.10380000, 19.76080000, 'Palic Zoo Serbia', ARRAY['palic']::text[], ARRAY['palic']::text[], 'Palic_Zoo.jpg', ARRAY['family', 'zoo']::text[]),
    ('fruska-gora-national-park', 'fruska-gora', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Фрушка-Гора', 'Fruska Gora National Park', 'Фрушка-Гора ұлттық паркі', 45.16000000, 19.70000000, 'Fruska Gora National Park Serbia', ARRAY['fruska-gora']::text[], ARRAY['novi-sad', 'fruska-gora']::text[], 'Fruska_Gora_National_Park.jpg', ARRAY['national-park', 'monasteries']::text[]),
    ('novo-hopovo-monastery', 'fruska-gora', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Ново-Хопово', 'Novo Hopovo Monastery', 'Ново-Хопово монастырі', 45.13700000, 19.84400000, 'Novo Hopovo Monastery Serbia', ARRAY['fruska-gora']::text[], ARRAY['novi-sad', 'fruska-gora']::text[], 'Novo_Hopovo_Monastery.jpg', ARRAY['monastery']::text[]),
    ('zrenjanin-old-town', 'zrenjanin', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Старый центр Зренянина', 'Zrenjanin Old Town', 'Зренянин ескі орталығы', 45.38160000, 20.38940000, 'Zrenjanin Old Town Serbia', ARRAY['zrenjanin']::text[], ARRAY['zrenjanin']::text[], 'Zrenjanin_City_Hall.jpg', ARRAY['old-town']::text[]),

    ('nis-fortress', 'nis', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Нишская крепость', 'Nis Fortress', 'Ниш қамалы', 43.32470000, 21.89580000, 'Nis Fortress Serbia', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Nis_Fortress.jpg', ARRAY['fortress']::text[]),
    ('skull-tower', 'nis', 'MUSEUM', 1, 'HOURS', 4.6, 'Башня черепов', 'Skull Tower', 'Бас сүйек мұнарасы', 43.31250000, 21.92360000, 'Skull Tower Nis Serbia', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Skull_Tower_Nis.jpg', ARRAY['history', 'memorial']::text[]),
    ('mediana-archaeological-park', 'nis', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Археологический парк Медиана', 'Mediana Archaeological Park', 'Медиана археологиялық паркі', 43.31060000, 21.94810000, 'Mediana Archaeological Park Nis', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Mediana_Nis.jpg', ARRAY['roman', 'archaeology']::text[]),
    ('nis-tinkers-alley', 'nis', 'FOOD', 1, 'HOURS', 4.5, 'Переулок ремесленников Казанджийско сокаче', 'Tinkers Alley Nis', 'Ниш қолөнершілер көшесі', 43.31880000, 21.89590000, 'Tinkers Alley Nis Serbia', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Tinkers_Alley_Nis.jpg', ARRAY['food', 'evening']::text[]),
    ('nis-central-market', 'nis', 'MARKET', 1, 'HOURS', 4.3, 'Центральный рынок Ниша', 'Nis Central Market', 'Ниш орталық базары', 43.31960000, 21.89490000, 'Nis Central Market Serbia', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Nis_Central_Market.jpg', ARRAY['local-market']::text[]),
    ('delta-planet-nis', 'nis', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Delta Planet Nis', 'Delta Planet Nis', 'Delta Planet Nis сауда орталығы', 43.31440000, 21.92050000, 'Delta Planet Nis Serbia', ARRAY['nis']::text[], ARRAY['nis']::text[], 'Delta_Planet_Nis.jpg', ARRAY['mall', 'indoor']::text[]),
    ('sokograd', 'sokobanja', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Средневековый город Сокоград', 'Sokograd Medieval Town', 'Сокоград ортағасырлық қаласы', 43.63140000, 21.87810000, 'Sokograd Sokobanja Serbia', ARRAY['sokobanja']::text[], ARRAY['nis', 'sokobanja']::text[], 'Sokograd_Sokobanja.jpg', ARRAY['fortress', 'day-trip']::text[]),
    ('ripaljka-waterfall', 'sokobanja', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Рипалька', 'Ripaljka Waterfall', 'Рипалька сарқырамасы', 43.63800000, 21.91400000, 'Ripaljka Waterfall Sokobanja', ARRAY['sokobanja']::text[], ARRAY['sokobanja']::text[], 'Ripaljka_Waterfall.jpg', ARRAY['waterfall']::text[]),
    ('felix-romuliana', 'felix-romuliana', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Феликс Ромулиана', 'Felix Romuliana', 'Феликс Ромулиана', 43.89900000, 22.18600000, 'Felix Romuliana Serbia', ARRAY['felix-romuliana', 'zajecar']::text[], ARRAY['zajecar', 'felix-romuliana']::text[], 'Gamzigrad-Romuliana.jpg', ARRAY['unesco', 'roman']::text[]),
    ('national-museum-zajecar', 'zajecar', 'MUSEUM', 1, 'HOURS', 4.4, 'Национальный музей Заечара', 'National Museum Zajecar', 'Заечар ұлттық музейі', 43.90370000, 22.27640000, 'National Museum Zajecar Serbia', ARRAY['zajecar']::text[], ARRAY['zajecar']::text[], 'National_Museum_Zajecar.jpg', ARRAY['regional-history']::text[]),
    ('golubac-fortress', 'golubac', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Голубацкая крепость', 'Golubac Fortress', 'Голубац қамалы', 44.65900000, 21.67660000, 'Golubac Fortress Serbia', ARRAY['golubac', 'djerdap']::text[], ARRAY['belgrade', 'golubac']::text[], 'Golubac_Fortress.jpg', ARRAY['fortress', 'danube']::text[]),
    ('djerdap-national-park', 'djerdap', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Джердап', 'Djerdap National Park', 'Джердап ұлттық паркі', 44.60000000, 22.25000000, 'Djerdap National Park Serbia', ARRAY['djerdap', 'golubac']::text[], ARRAY['belgrade', 'golubac', 'djerdap']::text[], 'Djerdap_National_Park.jpg', ARRAY['national-park', 'danube']::text[]),
    ('lepenski-vir', 'lepenski-vir', 'MUSEUM', 1, 'HOURS', 4.7, 'Археологический комплекс Лепенски-Вир', 'Lepenski Vir', 'Лепенски-Вир археологиялық кешені', 44.55260000, 22.02610000, 'Lepenski Vir Serbia', ARRAY['lepenski-vir', 'djerdap']::text[], ARRAY['golubac', 'djerdap', 'lepenski-vir']::text[], 'Lepenski_Vir.jpg', ARRAY['archaeology']::text[]),
    ('devils-town', 'devils-town', 'NATURE', 2, 'HOURS', 4.7, 'Дьяволий город', 'Devils Town', 'Дьяволий қала', 42.99800000, 21.41000000, 'Devils Town Serbia', ARRAY['devils-town']::text[], ARRAY['nis', 'devils-town']::text[], 'Devils_Town_Serbia.jpg', ARRAY['natural-monument', 'day-trip']::text[]),
    ('leskovac-grill-festival', 'leskovac', 'FOOD', 2, 'HOURS', 4.5, 'Лесковацкая Роштилияда', 'Leskovac Grill Festival', 'Лесковац гриль фестивалі', 42.99900000, 21.94600000, 'Leskovac Grill Festival Serbia', ARRAY['leskovac']::text[], ARRAY['nis', 'leskovac']::text[], 'Leskovac_Rostiljijada.jpg', ARRAY['food-festival']::text[]),

    ('zlatibor-mountain', 'zlatibor', 'NATURE', 4, 'HOURS', 4.8, 'Гора Златибор', 'Zlatibor Mountain', 'Златибор тауы', 43.72700000, 19.69500000, 'Zlatibor Mountain Serbia', ARRAY['zlatibor']::text[], ARRAY['belgrade', 'zlatibor']::text[], 'Zlatibor_Mountain.jpg', ARRAY['mountain', 'resort']::text[]),
    ('zlatibor-gold-gondola', 'zlatibor', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Златиборская Gold Gondola', 'Zlatibor Gold Gondola', 'Златибор Gold Gondola', 43.72700000, 19.69500000, 'Zlatibor Gold Gondola Serbia', ARRAY['zlatibor']::text[], ARRAY['zlatibor']::text[], 'Zlatibor_Gold_Gondola.jpg', ARRAY['gondola', 'viewpoint']::text[]),
    ('stopica-cave', 'zlatibor', 'NATURE', 2, 'HOURS', 4.7, 'Пещера Стопича', 'Stopica Cave', 'Стопича үңгірі', 43.70600000, 19.85400000, 'Stopica Cave Serbia', ARRAY['zlatibor']::text[], ARRAY['zlatibor']::text[], 'Stopica_Cave.jpg', ARRAY['cave']::text[]),
    ('gostilje-waterfall', 'zlatibor', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Гостилье', 'Gostilje Waterfall', 'Гостилье сарқырамасы', 43.64500000, 19.72800000, 'Gostilje Waterfall Serbia', ARRAY['zlatibor']::text[], ARRAY['zlatibor']::text[], 'Gostilje_Waterfall.jpg', ARRAY['waterfall']::text[]),
    ('sirogojno-open-air-museum', 'zlatibor', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей под открытым небом Старое село Сирогойно', 'Sirogojno Open-Air Museum', 'Сирогойно ашық аспан музейі', 43.68800000, 19.88700000, 'Sirogojno Open Air Museum Serbia', ARRAY['zlatibor']::text[], ARRAY['zlatibor']::text[], 'Sirogojno_Open_Air_Museum.jpg', ARRAY['ethno-village', 'family']::text[]),
    ('tara-national-park', 'tara', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Тара', 'Tara National Park', 'Тара ұлттық паркі', 43.92000000, 19.43000000, 'Tara National Park Serbia', ARRAY['tara']::text[], ARRAY['belgrade', 'tara']::text[], 'Tara_National_Park_Serbia.jpg', ARRAY['national-park', 'forest']::text[]),
    ('banjska-stena-viewpoint', 'tara', 'NATURE', 2, 'HOURS', 4.8, 'Смотровая площадка Баньска Стена', 'Banjska Stena Viewpoint', 'Баньска Стена көрініс алаңы', 43.94900000, 19.39800000, 'Banjska Stena Viewpoint Serbia', ARRAY['tara']::text[], ARRAY['tara']::text[], 'Banjska_Stena_Tara.jpg', ARRAY['viewpoint']::text[]),
    ('sargan-eight-railway', 'mokra-gora', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Железная дорога Шарганская восьмерка', 'Sargan Eight Railway', 'Шарган сегіздігі теміржолы', 43.79200000, 19.50700000, 'Sargan Eight Railway Serbia', ARRAY['mokra-gora']::text[], ARRAY['zlatibor', 'mokra-gora']::text[], 'Sargan_Eight_Railway.jpg', ARRAY['heritage-railway', 'family']::text[]),
    ('drvengrad', 'mokra-gora', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дрвенград', 'Drvengrad', 'Дрвенград', 43.79800000, 19.50600000, 'Drvengrad Mokra Gora Serbia', ARRAY['mokra-gora']::text[], ARRAY['zlatibor', 'mokra-gora']::text[], 'Drvengrad_Mokra_Gora.jpg', ARRAY['ethno-village', 'film']::text[]),
    ('uvac-special-nature-reserve', 'uvac', 'NATURE', 4, 'HOURS', 4.9, 'Специальный природный резерват Увац', 'Uvac Special Nature Reserve', 'Увац арнайы табиғи қорығы', 43.35200000, 19.96500000, 'Uvac Special Nature Reserve Serbia', ARRAY['uvac']::text[], ARRAY['zlatibor', 'uvac']::text[], 'Uvac_Special_Nature_Reserve.jpg', ARRAY['canyon', 'wildlife']::text[]),
    ('kopaonik-national-park', 'kopaonik', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Копаоник', 'Kopaonik National Park', 'Копаоник ұлттық паркі', 43.28600000, 20.80900000, 'Kopaonik National Park Serbia', ARRAY['kopaonik']::text[], ARRAY['belgrade', 'nis', 'kopaonik']::text[], 'Kopaonik_National_Park.jpg', ARRAY['ski', 'national-park']::text[]),
    ('studenica-monastery', 'studenica', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Студеница', 'Studenica Monastery', 'Студеница монастырі', 43.48600000, 20.53300000, 'Studenica Monastery Serbia', ARRAY['studenica']::text[], ARRAY['kopaonik', 'studenica']::text[], 'Studenica_Monastery.jpg', ARRAY['unesco', 'monastery']::text[]),
    ('zica-monastery', 'zica', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Жича', 'Zica Monastery', 'Жича монастырі', 43.69600000, 20.64900000, 'Zica Monastery Serbia', ARRAY['zica']::text[], ARRAY['studenica', 'zica']::text[], 'Zica_Monastery.jpg', ARRAY['monastery']::text[]),
    ('novi-pazar-fortress', 'novi-pazar', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Крепость Нови-Пазар', 'Novi Pazar Fortress', 'Нови-Пазар қамалы', 43.13600000, 20.51600000, 'Novi Pazar Fortress Serbia', ARRAY['novi-pazar']::text[], ARRAY['novi-pazar']::text[], 'Novi_Pazar_Fortress.jpg', ARRAY['fortress']::text[]),
    ('altun-alem-mosque', 'novi-pazar', 'TEMPLE', 1, 'HOURS', 4.6, 'Мечеть Алтун-Алем', 'Altun Alem Mosque', 'Алтун-Алем мешіті', 43.13700000, 20.51600000, 'Altun Alem Mosque Novi Pazar', ARRAY['novi-pazar']::text[], ARRAY['novi-pazar']::text[], 'Altun_Alem_Mosque.jpg', ARRAY['mosque', 'heritage']::text[]),
    ('stari-ras', 'novi-pazar', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Археологический комплекс Стари-Рас', 'Stari Ras Archaeological Site', 'Стари-Рас археологиялық кешені', 43.13600000, 20.41500000, 'Stari Ras Serbia', ARRAY['novi-pazar']::text[], ARRAY['novi-pazar']::text[], 'Stari_Ras.jpg', ARRAY['unesco', 'archaeology']::text[]),
    ('sopocani-monastery', 'novi-pazar', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Сопочаны', 'Sopocani Monastery', 'Сопочаны монастырі', 43.11800000, 20.37400000, 'Sopocani Monastery Serbia', ARRAY['novi-pazar']::text[], ARRAY['novi-pazar']::text[], 'Sopocani_Monastery.jpg', ARRAY['unesco', 'monastery']::text[]),
    ('sumarice-memorial-park', 'kragujevac', 'PARK', 2, 'HOURS', 4.7, 'Мемориальный парк Шумарице', 'Sumarice Memorial Park', 'Шумарице мемориалдық паркі', 44.01200000, 20.88500000, 'Sumarice Memorial Park Kragujevac', ARRAY['kragujevac']::text[], ARRAY['belgrade', 'kragujevac']::text[], 'Sumarice_Memorial_Park.jpg', ARRAY['memorial', 'park']::text[]),
    ('memorial-museum-21-october', 'kragujevac', 'MUSEUM', 1, 'HOURS', 4.6, 'Мемориальный музей 21 октября', 'Memorial Museum 21 October', '21 қазан мемориалдық музейі', 44.01300000, 20.88400000, 'Memorial Museum 21 October Kragujevac', ARRAY['kragujevac']::text[], ARRAY['kragujevac']::text[], 'Memorial_Museum_21_October.jpg', ARRAY['history', 'memorial']::text[]),
    ('oplenac-royal-mausoleum', 'topola', 'TEMPLE', 2, 'HOURS', 4.8, 'Опленац и королевский мавзолей', 'Oplenac Royal Mausoleum', 'Опленац патшалық кесенесі', 44.25000000, 20.66700000, 'Oplenac Royal Mausoleum Serbia', ARRAY['topola']::text[], ARRAY['belgrade', 'topola']::text[], 'Oplenac_Royal_Mausoleum.jpg', ARRAY['royal-history', 'church']::text[]),
    ('ovcar-kablar-gorge', 'ovcar-kablar', 'NATURE', 3, 'HOURS', 4.7, 'Овчарско-Кабларское ущелье', 'Ovcar-Kablar Gorge', 'Овчар-Каблар шатқалы', 43.91000000, 20.20000000, 'Ovcar Kablar Gorge Serbia', ARRAY['ovcar-kablar', 'cacak']::text[], ARRAY['cacak', 'ovcar-kablar']::text[], 'Ovcar_Kablar_Gorge.jpg', ARRAY['gorge', 'monasteries']::text[]),
    ('cacak-national-museum', 'cacak', 'MUSEUM', 1, 'HOURS', 4.4, 'Национальный музей Чачака', 'Cacak National Museum', 'Чачак ұлттық музейі', 43.89140000, 20.34970000, 'Cacak National Museum Serbia', ARRAY['cacak']::text[], ARRAY['cacak']::text[], 'Cacak_National_Museum.jpg', ARRAY['regional-history']::text[]);

CREATE TEMP TABLE seed_serbia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-serbia-place:' || seed.slug) AS place_hash,
        md5('id-serbia-media:' || seed.slug) AS media_hash
    FROM seed_serbia_priority_places seed
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
    ARRAY['serbia', city_id, slug, lower(category), 'serbia-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Сербии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Serbia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Сербия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'RS',
    city_id,
    category,
    NULL::numeric,
    'RSD',
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
FROM seed_serbia_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
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
FROM seed_serbia_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_serbia_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_serbia_resolved_places
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
FROM seed_serbia_resolved_places seed
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
FROM seed_serbia_resolved_places
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
    'RS',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_serbia_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'RS',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_serbia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_serbia_resolved_places;
DROP TABLE IF EXISTS seed_serbia_priority_places;
