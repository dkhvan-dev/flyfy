-- Priority Mexico destination places seed.
-- Mexico is seeded as a broad country destination with city-like tourist hubs
-- for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_mexico_resolved_places;
DROP TABLE IF EXISTS seed_mexico_priority_places;

CREATE TEMP TABLE seed_mexico_priority_places (
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

INSERT INTO seed_mexico_priority_places (
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
    ('mexico-city-historic-center', 'mexico-city', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Исторический центр Мехико', 'Mexico City Historic Center', 'Мехико тарихи орталығы', 19.43260000, -99.13320000, 'Mexico City Historic Center Mexico', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('zocalo-mexico-city', 'mexico-city', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Площадь Сокало', 'Zocalo Mexico City', 'Сокало алаңы', 19.43260000, -99.13320000, 'Zocalo Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('palacio-bellas-artes', 'mexico-city', 'MUSEUM', 2, 'HOURS', 4.9, 'Дворец изящных искусств', 'Palacio de Bellas Artes', 'Паласио-де-Бельяс-Артес', 19.43520000, -99.14120000, 'Palacio de Bellas Artes Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('chapultepec-park', 'mexico-city', 'PARK', 4, 'HOURS', 4.9, 'Парк Чапультепек', 'Chapultepec Park', 'Чапультепек саябағы', 19.42040000, -99.18190000, 'Chapultepec Park Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('national-museum-anthropology', 'mexico-city', 'MUSEUM', 4, 'HOURS', 4.9, 'Национальный музей антропологии', 'National Museum of Anthropology', 'Ұлттық антропология музейі', 19.42600000, -99.18620000, 'National Museum of Anthropology Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('chapultepec-castle', 'mexico-city', 'MUSEUM', 2, 'HOURS', 4.8, 'Замок Чапультепек', 'Chapultepec Castle', 'Чапультепек қамалы', 19.42040000, -99.18100000, 'Chapultepec Castle Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('frida-kahlo-museum', 'mexico-city', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Фриды Кало', 'Frida Kahlo Museum', 'Фрида Кало музейі', 19.35520000, -99.16280000, 'Frida Kahlo Museum Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('templo-mayor', 'mexico-city', 'MUSEUM', 2, 'HOURS', 4.8, 'Темпло Майор', 'Templo Mayor Museum', 'Темпло Майор музейі', 19.43440000, -99.13120000, 'Templo Mayor Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('coyoacan-center', 'mexico-city', 'MARKET', 3, 'HOURS', 4.7, 'Центр Койоакана', 'Coyoacan Center', 'Койоакан орталығы', 19.34900000, -99.16250000, 'Coyoacan Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('xochimilco', 'mexico-city', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Каналы Сочимилько', 'Xochimilco', 'Сочимилько каналдары', 19.25700000, -99.10360000, 'Xochimilco Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('basilica-guadalupe', 'mexico-city', 'TEMPLE', 2, 'HOURS', 4.8, 'Базилика Девы Гваделупской', 'Basilica of Our Lady of Guadalupe', 'Гваделупа ана базиликасы', 19.48470000, -99.11790000, 'Basilica of Our Lady of Guadalupe Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('mercado-ciudadela', 'mexico-city', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Ла-Сьюдадела', 'Mercado La Ciudadela', 'Ла-Сьюдадела базары', 19.43120000, -99.15080000, 'Mercado La Ciudadela Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('museo-soumaya', 'mexico-city', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Сумайя', 'Museo Soumaya', 'Сумайя музейі', 19.44070000, -99.20470000, 'Museo Soumaya Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('angel-independence', 'mexico-city', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Ангел независимости', 'Angel of Independence', 'Тәуелсіздік періштесі', 19.42690000, -99.16770000, 'Angel of Independence Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('arena-mexico', 'mexico-city', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Arena Mexico', 'Arena Mexico', 'Arena Mexico', 19.42400000, -99.15220000, 'Arena Mexico Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('parque-bicentenario', 'mexico-city', 'PARK', 2, 'HOURS', 4.5, 'Парк Бисентенарио', 'Parque Bicentenario', 'Бисентенарио саябағы', 19.46910000, -99.19830000, 'Parque Bicentenario Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('centro-santa-fe', 'mexico-city', 'SHOPPING', 3, 'HOURS', 4.5, 'Centro Santa Fe', 'Centro Santa Fe', 'Centro Santa Fe', 19.36090000, -99.27500000, 'Centro Santa Fe Mexico City', ARRAY['mexico-city']::text[], ARRAY['mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('teotihuacan', 'teotihuacan', 'ARCHITECTURE', 5, 'HOURS', 4.9, 'Теотиуакан', 'Teotihuacan', 'Теотиуакан', 19.69250000, -98.84380000, 'Teotihuacan Mexico', ARRAY['teotihuacan', 'mexico-city']::text[], ARRAY['teotihuacan', 'mexico-city']::text[], 'Teotihuacan, Pyramid of the Sun (20064112414).jpg'),
    ('pyramid-sun-teotihuacan', 'teotihuacan', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Пирамида Солнца', 'Pyramid of the Sun Teotihuacan', 'Күн пирамидасы', 19.69230000, -98.84390000, 'Pyramid of the Sun Teotihuacan Mexico', ARRAY['teotihuacan', 'mexico-city']::text[], ARRAY['teotihuacan', 'mexico-city']::text[], 'Teotihuacan, Pyramid of the Sun (20064112414).jpg'),
    ('puebla-historic-center', 'puebla', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Пуэблы', 'Puebla Historic Center', 'Пуэбла тарихи орталығы', 19.04330000, -98.20190000, 'Puebla Historic Center Mexico', ARRAY['puebla']::text[], ARRAY['puebla', 'mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),
    ('puebla-cathedral', 'puebla', 'TEMPLE', 1, 'HOURS', 4.8, 'Кафедральный собор Пуэблы', 'Puebla Cathedral', 'Пуэбла кафедралды соборы', 19.04380000, -98.19890000, 'Puebla Cathedral Mexico', ARRAY['puebla']::text[], ARRAY['puebla']::text[], 'Palacio de Bellas Artes.jpg'),
    ('biblioteca-palafoxiana', 'puebla', 'MUSEUM', 1, 'HOURS', 4.7, 'Библиотека Палафоксиана', 'Biblioteca Palafoxiana', 'Палафоксиана кітапханасы', 19.04260000, -98.19820000, 'Biblioteca Palafoxiana Puebla Mexico', ARRAY['puebla']::text[], ARRAY['puebla']::text[], 'Palacio de Bellas Artes.jpg'),
    ('cholula-great-pyramid', 'cholula', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Великая пирамида Чолулы', 'Great Pyramid of Cholula', 'Чолула үлкен пирамидасы', 19.05730000, -98.30190000, 'Great Pyramid of Cholula Mexico', ARRAY['cholula', 'puebla']::text[], ARRAY['cholula', 'puebla']::text[], 'Teotihuacan, Pyramid of the Sun (20064112414).jpg'),
    ('cuernavaca-cortes-palace', 'cuernavaca', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Кортеса', 'Palace of Cortes Cuernavaca', 'Кортес сарайы', 18.92190000, -99.23420000, 'Palace of Cortes Cuernavaca Mexico', ARRAY['cuernavaca', 'mexico-city']::text[], ARRAY['cuernavaca', 'mexico-city']::text[], 'Palacio de Bellas Artes.jpg'),

    ('cancun-hotel-zone-beaches', 'cancun', 'BEACH', 5, 'HOURS', 4.8, 'Пляжи гостиничной зоны Канкуна', 'Cancun Hotel Zone Beaches', 'Канкун қонақүй аймағы жағажайлары', 21.08390000, -86.77040000, 'Cancun Hotel Zone Beaches Mexico', ARRAY['cancun']::text[], ARRAY['cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('playa-delfines', 'cancun', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Дельфинес', 'Playa Delfines', 'Дельфинес жағажайы', 21.06130000, -86.78070000, 'Playa Delfines Cancun Mexico', ARRAY['cancun']::text[], ARRAY['cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('isla-mujeres-playa-norte', 'isla-mujeres', 'BEACH', 4, 'HOURS', 4.9, 'Плайя Норте на Исла-Мухерес', 'Isla Mujeres Playa Norte', 'Исла-Мухерес Плайя Норте', 21.25980000, -86.75000000, 'Playa Norte Isla Mujeres Mexico', ARRAY['isla-mujeres', 'cancun']::text[], ARRAY['isla-mujeres', 'cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('cancun-underwater-museum', 'cancun', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Подводный музей Канкуна', 'Cancun Underwater Museum', 'Канкун суасты музейі', 21.08200000, -86.75900000, 'Cancun Underwater Museum Mexico', ARRAY['cancun', 'isla-mujeres']::text[], ARRAY['cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('mercado-28-cancun', 'cancun', 'MARKET', 2, 'HOURS', 4.4, 'Рынок 28', 'Mercado 28 Cancun', 'Канкун 28 базары', 21.16190000, -86.83950000, 'Mercado 28 Cancun Mexico', ARRAY['cancun']::text[], ARRAY['cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('la-isla-shopping-cancun', 'cancun', 'SHOPPING', 3, 'HOURS', 4.6, 'La Isla Shopping Village', 'La Isla Shopping Village Cancun', 'La Isla Shopping Village Cancun', 21.11070000, -86.76200000, 'La Isla Shopping Village Cancun', ARRAY['cancun']::text[], ARRAY['cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('quinta-avenida-playa', 'playa-del-carmen', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Пятая авеню Плая-дель-Кармен', 'Fifth Avenue Playa del Carmen', 'Плая-дель-Кармен бесінші авенюі', 20.62740000, -87.07390000, 'Fifth Avenue Playa del Carmen Mexico', ARRAY['playa-del-carmen']::text[], ARRAY['playa-del-carmen', 'cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('mamitas-beach', 'playa-del-carmen', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Мамитас', 'Mamitas Beach', 'Мамитас жағажайы', 20.63340000, -87.06670000, 'Mamitas Beach Playa del Carmen Mexico', ARRAY['playa-del-carmen']::text[], ARRAY['playa-del-carmen']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('xcaret-park', 'playa-del-carmen', 'ENTERTAINMENT', 6, 'HOURS', 4.8, 'Парк Xcaret', 'Xcaret Park', 'Xcaret паркі', 20.58070000, -87.11900000, 'Xcaret Park Mexico', ARRAY['playa-del-carmen', 'cancun']::text[], ARRAY['playa-del-carmen', 'cancun']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('xplor-park', 'playa-del-carmen', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Парк Xplor', 'Xplor Park', 'Xplor паркі', 20.58030000, -87.12420000, 'Xplor Park Mexico', ARRAY['playa-del-carmen']::text[], ARRAY['playa-del-carmen']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('tulum-archaeological-zone', 'tulum', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Археологическая зона Тулума', 'Tulum Archaeological Zone', 'Тулум археологиялық аймағы', 20.21400000, -87.42910000, 'Tulum Archaeological Zone Mexico', ARRAY['tulum', 'playa-del-carmen']::text[], ARRAY['tulum', 'playa-del-carmen']::text[], 'Chichen Itza El Castillo.JPG'),
    ('playa-paraiso-tulum', 'tulum', 'BEACH', 4, 'HOURS', 4.7, 'Плайя Параисо', 'Playa Paraiso Tulum', 'Тулум Плайя Параисо', 20.20970000, -87.43330000, 'Playa Paraiso Tulum Mexico', ARRAY['tulum']::text[], ARRAY['tulum']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('gran-cenote', 'tulum', 'NATURE', 3, 'HOURS', 4.6, 'Гран Сеноте', 'Gran Cenote', 'Гран Сеноте', 20.24770000, -87.46420000, 'Gran Cenote Tulum Mexico', ARRAY['tulum']::text[], ARRAY['tulum']::text[], 'Chichen Itza El Castillo.JPG'),
    ('sian-kaan-biosphere', 'tulum', 'NATURE', 6, 'HOURS', 4.8, 'Биосферный заповедник Сиан-Каан', 'Sian Kaan Biosphere Reserve', 'Сиан-Каан биосфералық қорығы', 19.46670000, -87.65000000, 'Sian Kaan Biosphere Reserve Mexico', ARRAY['tulum']::text[], ARRAY['tulum']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('cozumel-reefs', 'cozumel', 'NATURE', 5, 'HOURS', 4.9, 'Рифы Косумеля', 'Cozumel Reefs', 'Косумель рифтері', 20.42200000, -86.92230000, 'Cozumel Reefs Mexico', ARRAY['cozumel', 'playa-del-carmen']::text[], ARRAY['cozumel', 'playa-del-carmen']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('chankanaab-park', 'cozumel', 'PARK', 4, 'HOURS', 4.6, 'Парк Чанканааб', 'Chankanaab Park', 'Чанканааб паркі', 20.45490000, -86.98850000, 'Chankanaab Park Cozumel Mexico', ARRAY['cozumel']::text[], ARRAY['cozumel']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),
    ('san-gervasio-cozumel', 'cozumel', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Сан-Гервасио', 'San Gervasio Cozumel', 'Косумель Сан-Гервасио', 20.50080000, -86.84680000, 'San Gervasio Cozumel Mexico', ARRAY['cozumel']::text[], ARRAY['cozumel']::text[], 'Chichen Itza El Castillo.JPG'),
    ('merida-historic-center', 'merida', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Мериды', 'Merida Historic Center', 'Мерида тарихи орталығы', 20.96740000, -89.59260000, 'Merida Historic Center Mexico', ARRAY['merida']::text[], ARRAY['merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('paseo-montejo', 'merida', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Пасео-де-Монтехо', 'Paseo de Montejo', 'Пасео-де-Монтехо', 20.98630000, -89.62000000, 'Paseo de Montejo Merida Mexico', ARRAY['merida']::text[], ARRAY['merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('gran-museo-mundo-maya', 'merida', 'MUSEUM', 2, 'HOURS', 4.6, 'Большой музей мира майя', 'Gran Museo del Mundo Maya', 'Майя әлемінің үлкен музейі', 21.03240000, -89.63030000, 'Gran Museo del Mundo Maya Merida', ARRAY['merida']::text[], ARRAY['merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('mercado-lucas-galvez', 'merida', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Лукас-де-Гальвес', 'Mercado Lucas de Galvez', 'Лукас-де-Гальвес базары', 20.96650000, -89.62130000, 'Mercado Lucas de Galvez Merida', ARRAY['merida']::text[], ARRAY['merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('valladolid-historic-center', 'valladolid', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Исторический центр Вальядолида', 'Valladolid Historic Center', 'Вальядолид тарихи орталығы', 20.68960000, -88.20220000, 'Valladolid Historic Center Yucatan Mexico', ARRAY['valladolid']::text[], ARRAY['valladolid']::text[], 'Chichen Itza El Castillo.JPG'),
    ('cenote-zaci', 'valladolid', 'NATURE', 2, 'HOURS', 4.6, 'Сеноте Саси', 'Cenote Zaci', 'Саси сенотесі', 20.68900000, -88.19970000, 'Cenote Zaci Valladolid Mexico', ARRAY['valladolid']::text[], ARRAY['valladolid']::text[], 'Chichen Itza El Castillo.JPG'),
    ('chichen-itza', 'chichen-itza', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Чичен-Ица', 'Chichen Itza', 'Чичен-Ица', 20.68430000, -88.56780000, 'Chichen Itza Mexico', ARRAY['chichen-itza', 'valladolid', 'merida']::text[], ARRAY['chichen-itza', 'valladolid', 'merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('ik-kil-cenote', 'chichen-itza', 'NATURE', 2, 'HOURS', 4.6, 'Сеноте Ик-Киль', 'Ik Kil Cenote', 'Ик-Киль сенотесі', 20.66290000, -88.55030000, 'Ik Kil Cenote Mexico', ARRAY['chichen-itza', 'valladolid']::text[], ARRAY['chichen-itza', 'valladolid']::text[], 'Chichen Itza El Castillo.JPG'),
    ('uxmal', 'uxmal', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Ушмаль', 'Uxmal', 'Ушмаль', 20.35990000, -89.76840000, 'Uxmal Mexico', ARRAY['uxmal', 'merida']::text[], ARRAY['uxmal', 'merida']::text[], 'Chichen Itza El Castillo.JPG'),
    ('celestun-biosphere', 'merida', 'NATURE', 5, 'HOURS', 4.7, 'Биосферный заповедник Селестун', 'Celestun Biosphere Reserve', 'Селестун биосфералық қорығы', 20.85960000, -90.39950000, 'Celestun Biosphere Reserve Mexico', ARRAY['merida']::text[], ARRAY['merida']::text[], 'Hotel Zone in Cancun, Mexico.jpg'),

    ('los-cabos-arch', 'cabo-san-lucas', 'NATURE', 2, 'HOURS', 4.9, 'Арка Лос-Кабос', 'Los Cabos Arch', 'Лос-Кабос аркасы', 22.87510000, -109.89440000, 'The Arch of Cabo San Lucas Mexico', ARRAY['cabo-san-lucas', 'los-cabos']::text[], ARRAY['cabo-san-lucas', 'los-cabos']::text[], 'The Arch of Cabo San Lucas.jpg'),
    ('medano-beach', 'cabo-san-lucas', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Медано', 'Medano Beach', 'Медано жағажайы', 22.89060000, -109.90260000, 'Medano Beach Cabo San Lucas Mexico', ARRAY['cabo-san-lucas', 'los-cabos']::text[], ARRAY['cabo-san-lucas']::text[], 'The Arch of Cabo San Lucas.jpg'),
    ('marina-cabo-san-lucas', 'cabo-san-lucas', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Марина Кабо-Сан-Лукас', 'Marina Cabo San Lucas', 'Кабо-Сан-Лукас маринасы', 22.88160000, -109.91220000, 'Marina Cabo San Lucas Mexico', ARRAY['cabo-san-lucas', 'los-cabos']::text[], ARRAY['cabo-san-lucas']::text[], 'The Arch of Cabo San Lucas.jpg'),
    ('san-jose-art-district', 'san-jose-del-cabo', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Арт-дистрикт Сан-Хосе-дель-Кабо', 'San Jose del Cabo Art District', 'Сан-Хосе-дель-Кабо арт ауданы', 23.06140000, -109.69720000, 'San Jose del Cabo Art District Mexico', ARRAY['san-jose-del-cabo', 'los-cabos']::text[], ARRAY['san-jose-del-cabo']::text[], 'The Arch of Cabo San Lucas.jpg'),
    ('balandra-beach', 'la-paz-mexico', 'BEACH', 4, 'HOURS', 4.9, 'Пляж Баландра', 'Balandra Beach', 'Баландра жағажайы', 24.31900000, -110.33100000, 'Balandra Beach La Paz Mexico', ARRAY['la-paz-mexico']::text[], ARRAY['la-paz-mexico']::text[], 'Balandra Beach, La Paz (43838674241).jpg'),
    ('espiritu-santo-island', 'la-paz-mexico', 'NATURE', 6, 'HOURS', 4.9, 'Остров Эспириту-Санто', 'Espiritu Santo Island', 'Эспириту-Санто аралы', 24.46670000, -110.33330000, 'Espiritu Santo Island Baja California Sur Mexico', ARRAY['la-paz-mexico']::text[], ARRAY['la-paz-mexico']::text[], 'Balandra Beach, La Paz (43838674241).jpg'),
    ('la-paz-malecon', 'la-paz-mexico', 'PARK', 2, 'HOURS', 4.7, 'Малекон Ла-Паса', 'La Paz Malecon', 'Ла-Пас малеконы', 24.15690000, -110.31580000, 'La Paz Malecon Baja California Sur Mexico', ARRAY['la-paz-mexico']::text[], ARRAY['la-paz-mexico']::text[], 'Balandra Beach, La Paz (43838674241).jpg'),
    ('puerto-vallarta-malecon', 'puerto-vallarta', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Малекон Пуэрто-Вальярты', 'Puerto Vallarta Malecon', 'Пуэрто-Вальярта малеконы', 20.60890000, -105.23530000, 'Puerto Vallarta Malecon Mexico', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('our-lady-guadalupe-puerto-vallarta', 'puerto-vallarta', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Богоматери Гваделупской', 'Church of Our Lady of Guadalupe Puerto Vallarta', 'Пуэрто-Вальярта Гваделупа ана шіркеуі', 20.60670000, -105.23500000, 'Church of Our Lady of Guadalupe Puerto Vallarta', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('zona-romantica', 'puerto-vallarta', 'FOOD', 3, 'HOURS', 4.6, 'Романтическая зона', 'Zona Romantica Puerto Vallarta', 'Пуэрто-Вальярта романтикалық аймағы', 20.60280000, -105.23790000, 'Zona Romantica Puerto Vallarta Mexico', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('playa-los-muertos', 'puerto-vallarta', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Лос-Муэртос', 'Playa Los Muertos', 'Лос-Муэртос жағажайы', 20.60060000, -105.23890000, 'Playa Los Muertos Puerto Vallarta', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('marina-vallarta', 'puerto-vallarta', 'SHOPPING', 2, 'HOURS', 4.5, 'Марина Вальярта', 'Marina Vallarta', 'Марина Вальярта', 20.66250000, -105.24990000, 'Marina Vallarta Mexico', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('sayulita-beach', 'sayulita', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Саюлита', 'Sayulita Beach', 'Саюлита жағажайы', 20.86890000, -105.44080000, 'Sayulita Beach Mexico', ARRAY['sayulita', 'puerto-vallarta']::text[], ARRAY['sayulita', 'puerto-vallarta']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('mazatlan-malecon', 'mazatlan', 'PARK', 3, 'HOURS', 4.7, 'Малекон Масатлана', 'Mazatlan Malecon', 'Масатлан малеконы', 23.22150000, -106.42190000, 'Mazatlan Malecon Mexico', ARRAY['mazatlan']::text[], ARRAY['mazatlan']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('mazatlan-historic-center', 'mazatlan', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Исторический центр Масатлана', 'Mazatlan Historic Center', 'Масатлан тарихи орталығы', 23.20130000, -106.42130000, 'Mazatlan Historic Center Mexico', ARRAY['mazatlan']::text[], ARRAY['mazatlan']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('gran-acuario-mazatlan', 'mazatlan', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Gran Acuario Mazatlan', 'Gran Acuario Mazatlan', 'Gran Acuario Mazatlan', 23.23970000, -106.43990000, 'Gran Acuario Mazatlan Mexico', ARRAY['mazatlan']::text[], ARRAY['mazatlan']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('la-quebrada-acapulco', 'acapulco', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Скалы Ла-Кебрада', 'La Quebrada Acapulco', 'Акапулько Ла-Кебрада', 16.84470000, -99.91770000, 'La Quebrada Acapulco Mexico', ARRAY['acapulco']::text[], ARRAY['acapulco']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('playa-condesa-acapulco', 'acapulco', 'BEACH', 4, 'HOURS', 4.5, 'Пляж Кондеса', 'Playa Condesa Acapulco', 'Кондеса жағажайы', 16.85620000, -99.86130000, 'Playa Condesa Acapulco Mexico', ARRAY['acapulco']::text[], ARRAY['acapulco']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('fort-san-diego-acapulco', 'acapulco', 'MUSEUM', 2, 'HOURS', 4.6, 'Форт Сан-Диего', 'Fort San Diego Acapulco', 'Сан-Диего форты', 16.84850000, -99.90880000, 'Fort San Diego Acapulco Mexico', ARRAY['acapulco']::text[], ARRAY['acapulco']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('playa-la-ropa-zihuatanejo', 'zihuatanejo', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Ла-Ропа', 'Playa La Ropa Zihuatanejo', 'Ла-Ропа жағажайы', 17.62970000, -101.54680000, 'Playa La Ropa Zihuatanejo Mexico', ARRAY['zihuatanejo']::text[], ARRAY['zihuatanejo']::text[], 'Malecon, Puerto Vallarta (27212709499).jpg'),
    ('fundidora-park', 'monterrey', 'PARK', 4, 'HOURS', 4.8, 'Парк Фундидора', 'Fundidora Park', 'Фундидора саябағы', 25.67800000, -100.28440000, 'Fundidora Park Monterrey Mexico', ARRAY['monterrey']::text[], ARRAY['monterrey']::text[], 'Catedral de Guadalajara.jpg'),
    ('macroplaza-monterrey', 'monterrey', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Макроплаза Монтеррея', 'Macroplaza Monterrey', 'Монтеррей Макроплазасы', 25.66990000, -100.30980000, 'Macroplaza Monterrey Mexico', ARRAY['monterrey']::text[], ARRAY['monterrey']::text[], 'Catedral de Guadalajara.jpg'),
    ('chipinque-park', 'monterrey', 'NATURE', 4, 'HOURS', 4.8, 'Парк Чипинке', 'Chipinque Park', 'Чипинке саябағы', 25.61400000, -100.35300000, 'Chipinque Park Monterrey Mexico', ARRAY['monterrey']::text[], ARRAY['monterrey']::text[], 'Catedral de Guadalajara.jpg'),

    ('guadalajara-cathedral', 'guadalajara', 'TEMPLE', 1, 'HOURS', 4.8, 'Кафедральный собор Гвадалахары', 'Guadalajara Cathedral', 'Гвадалахара кафедралды соборы', 20.67670000, -103.34750000, 'Guadalajara Cathedral Mexico', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('hospicio-cabanas', 'guadalajara', 'MUSEUM', 2, 'HOURS', 4.8, 'Hospicio Cabanas', 'Hospicio Cabanas', 'Hospicio Cabanas', 20.67720000, -103.33750000, 'Hospicio Cabanas Guadalajara Mexico', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('mercado-san-juan-dios', 'guadalajara', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Сан-Хуан-де-Диос', 'Mercado San Juan de Dios', 'Сан-Хуан-де-Диос базары', 20.67680000, -103.34000000, 'Mercado San Juan de Dios Guadalajara', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('tlaquepaque-arts', 'guadalajara', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Тлакепаке', 'Tlaquepaque Arts District', 'Тлакепаке өнер ауданы', 20.64080000, -103.31250000, 'Tlaquepaque Guadalajara Mexico', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('andares-shopping', 'guadalajara', 'SHOPPING', 3, 'HOURS', 4.6, 'Andares', 'Andares Shopping Center', 'Andares сауда орталығы', 20.71070000, -103.41260000, 'Andares Guadalajara Mexico', ARRAY['guadalajara']::text[], ARRAY['guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('tequila-town', 'tequila', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Город Текила', 'Tequila Town', 'Текила қаласы', 20.88200000, -103.83500000, 'Tequila Jalisco Mexico', ARRAY['tequila', 'guadalajara']::text[], ARRAY['tequila', 'guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('jose-cuervo-distillery', 'tequila', 'FOOD', 2, 'HOURS', 4.7, 'Дистиллерия Jose Cuervo', 'Jose Cuervo Distillery', 'Jose Cuervo дистиллериясы', 20.88100000, -103.83570000, 'Jose Cuervo Distillery Tequila Mexico', ARRAY['tequila', 'guadalajara']::text[], ARRAY['tequila', 'guadalajara']::text[], 'Catedral de Guadalajara.jpg'),
    ('guanajuato-historic-center', 'guanajuato', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Исторический центр Гуанахуато', 'Guanajuato Historic Center', 'Гуанахуато тарихи орталығы', 21.01900000, -101.25740000, 'Guanajuato Historic Center Mexico', ARRAY['guanajuato']::text[], ARRAY['guanajuato']::text[], 'San Miguel de Allende.JPG'),
    ('alley-kiss-guanajuato', 'guanajuato', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Аллея поцелуя', 'Alley of the Kiss Guanajuato', 'Гуанахуато сүйісу аллеясы', 21.01790000, -101.25650000, 'Alley of the Kiss Guanajuato Mexico', ARRAY['guanajuato']::text[], ARRAY['guanajuato']::text[], 'San Miguel de Allende.JPG'),
    ('alhondiga-granaditas', 'guanajuato', 'MUSEUM', 2, 'HOURS', 4.7, 'Альхондига-де-Гранадитас', 'Alhondiga de Granaditas', 'Альхондига-де-Гранадитас', 21.01860000, -101.25930000, 'Alhondiga de Granaditas Guanajuato', ARRAY['guanajuato']::text[], ARRAY['guanajuato']::text[], 'San Miguel de Allende.JPG'),
    ('san-miguel-de-allende', 'san-miguel-de-allende', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Сан-Мигель-де-Альенде', 'San Miguel de Allende', 'Сан-Мигель-де-Альенде', 20.91440000, -100.74520000, 'San Miguel de Allende Mexico', ARRAY['san-miguel-de-allende']::text[], ARRAY['san-miguel-de-allende']::text[], 'San Miguel de Allende.JPG'),
    ('parroquia-san-miguel', 'san-miguel-de-allende', 'TEMPLE', 1, 'HOURS', 4.9, 'Приход Сан-Мигель-Арканхель', 'Parroquia de San Miguel Arcangel', 'Сан-Мигель-Арканхель шіркеуі', 20.91390000, -100.74420000, 'Parroquia San Miguel de Allende Mexico', ARRAY['san-miguel-de-allende']::text[], ARRAY['san-miguel-de-allende']::text[], 'San Miguel de Allende.JPG'),
    ('queretaro-historic-center', 'queretaro', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Керетаро', 'Queretaro Historic Center', 'Керетаро тарихи орталығы', 20.58880000, -100.38990000, 'Queretaro Historic Center Mexico', ARRAY['queretaro']::text[], ARRAY['queretaro']::text[], 'San Miguel de Allende.JPG'),
    ('oaxaca-historic-center', 'oaxaca', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Исторический центр Оахаки', 'Oaxaca Historic Center', 'Оахака тарихи орталығы', 17.06080000, -96.72530000, 'Oaxaca Historic Center Mexico', ARRAY['oaxaca']::text[], ARRAY['oaxaca']::text[], 'Oaxaca San Domingo.jpg'),
    ('santo-domingo-oaxaca', 'oaxaca', 'TEMPLE', 2, 'HOURS', 4.9, 'Храм Санто-Доминго-де-Гусман', 'Santo Domingo de Guzman Oaxaca', 'Оахака Санто-Доминго храмы', 17.06540000, -96.72370000, 'Santo Domingo de Guzman Oaxaca Mexico', ARRAY['oaxaca']::text[], ARRAY['oaxaca']::text[], 'Oaxaca San Domingo.jpg'),
    ('mercado-20-noviembre', 'oaxaca', 'MARKET', 2, 'HOURS', 4.7, 'Рынок 20 ноября', 'Mercado 20 de Noviembre', '20 қараша базары', 17.05920000, -96.72470000, 'Mercado 20 de Noviembre Oaxaca', ARRAY['oaxaca']::text[], ARRAY['oaxaca']::text[], 'Oaxaca San Domingo.jpg'),
    ('monte-alban', 'monte-alban', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Монте-Альбан', 'Monte Alban', 'Монте-Альбан', 17.04390000, -96.76720000, 'Monte Alban Oaxaca Mexico', ARRAY['monte-alban', 'oaxaca']::text[], ARRAY['monte-alban', 'oaxaca']::text[], 'Oaxaca San Domingo.jpg'),
    ('hierve-el-agua', 'oaxaca', 'NATURE', 5, 'HOURS', 4.7, 'Иерве-эль-Агуа', 'Hierve el Agua', 'Иерве-эль-Агуа', 16.86530000, -96.27670000, 'Hierve el Agua Oaxaca Mexico', ARRAY['oaxaca']::text[], ARRAY['oaxaca']::text[], 'Oaxaca San Domingo.jpg'),
    ('san-cristobal-historic-center', 'san-cristobal-de-las-casas', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Исторический центр Сан-Кристобаля', 'San Cristobal de las Casas Historic Center', 'Сан-Кристобаль тарихи орталығы', 16.73700000, -92.63760000, 'San Cristobal de las Casas Mexico', ARRAY['san-cristobal-de-las-casas']::text[], ARRAY['san-cristobal-de-las-casas']::text[], 'Chichen Itza El Castillo.JPG'),
    ('sumidero-canyon', 'san-cristobal-de-las-casas', 'NATURE', 5, 'HOURS', 4.8, 'Каньон Сумидеро', 'Sumidero Canyon', 'Сумидеро каньоны', 16.83000000, -93.08000000, 'Sumidero Canyon Chiapas Mexico', ARRAY['san-cristobal-de-las-casas']::text[], ARRAY['san-cristobal-de-las-casas']::text[], 'Chichen Itza El Castillo.JPG'),
    ('palenque-archaeological-zone', 'palenque', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Археологическая зона Паленке', 'Palenque Archaeological Zone', 'Паленке археологиялық аймағы', 17.48490000, -92.04650000, 'Palenque Archaeological Zone Mexico', ARRAY['palenque']::text[], ARRAY['palenque']::text[], 'Chichen Itza El Castillo.JPG'),
    ('agua-azul-waterfalls', 'palenque', 'NATURE', 5, 'HOURS', 4.6, 'Водопады Агуа-Асуль', 'Agua Azul Waterfalls', 'Агуа-Асуль сарқырамалары', 17.25760000, -92.11440000, 'Agua Azul Waterfalls Chiapas Mexico', ARRAY['palenque']::text[], ARRAY['palenque']::text[], 'Chichen Itza El Castillo.JPG');

CREATE TEMP TABLE seed_mexico_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-mexico-place:' || seed.slug) AS place_hash,
        md5('id-mexico-media:' || seed.slug) AS media_hash
    FROM seed_mexico_priority_places seed
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
    ARRAY['mexico', city_id, slug, lower(category), 'mexico-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Мексики: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Mexico tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Мексика туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'MX',
    city_id,
    category,
    NULL::numeric,
    'MXN',
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
FROM seed_mexico_resolved_places
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
FROM seed_mexico_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_mexico_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_mexico_resolved_places
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
FROM seed_mexico_resolved_places seed
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
FROM seed_mexico_resolved_places
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
    'MX',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_mexico_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'MX',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_mexico_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_mexico_resolved_places;
DROP TABLE IF EXISTS seed_mexico_priority_places;
