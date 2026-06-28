-- Priority Czechia destination places seed.
-- The seed covers Prague, Central Bohemia, South Moravia, South Bohemia, West Bohemia, North Moravia, and key nature regions.

DROP TABLE IF EXISTS seed_czechia_resolved_places;
DROP TABLE IF EXISTS seed_czechia_priority_places;

CREATE TEMP TABLE seed_czechia_priority_places (
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

INSERT INTO seed_czechia_priority_places (
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
    ('prague-castle', 'prague', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Пражский Град', 'Prague Castle', 'Прага қамалы', 50.09110000, 14.40160000, 'Prague Castle Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Prague Castle.jpg'),
    ('charles-bridge', 'prague', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Карлов мост', 'Charles Bridge', 'Карлов көпірі', 50.08650000, 14.41140000, 'Charles Bridge Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Charles Bridge, Prague.jpg'),
    ('old-town-square', 'prague', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Староместская площадь', 'Old Town Square', 'Ескі қала алаңы', 50.08700000, 14.42130000, 'Old Town Square Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Old Town Square Prague.jpg'),
    ('prague-astronomical-clock', 'prague', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Пражские куранты', 'Prague Astronomical Clock', 'Прага астрономиялық сағаты', 50.08690000, 14.42080000, 'Prague Astronomical Clock', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Prague Astronomical Clock.jpg'),
    ('st-vitus-cathedral', 'prague', 'TEMPLE', 2, 'HOURS', 4.8, 'Собор Святого Вита', 'St Vitus Cathedral', 'Әулие Вит соборы', 50.09090000, 14.40070000, 'St Vitus Cathedral Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'St Vitus Cathedral Prague.jpg'),
    ('national-museum-prague', 'prague', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Праги', 'National Museum Prague', 'Прага ұлттық музейі', 50.07950000, 14.43000000, 'National Museum Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'National Museum Prague.jpg'),
    ('national-technical-museum-prague', 'prague', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный технический музей', 'National Technical Museum Prague', 'Прага ұлттық техникалық музейі', 50.09760000, 14.42410000, 'National Technical Museum Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'National Technical Museum Prague.jpg'),
    ('petrin-hill-and-tower', 'prague', 'PARK', 2, 'HOURS', 4.7, 'Петршинский холм и башня', 'Petrin Hill and Tower', 'Петршин төбесі мен мұнарасы', 50.08350000, 14.39520000, 'Petrin Tower Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Petrin Tower Prague.jpg'),
    ('prague-zoo', 'prague', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Пражский зоопарк', 'Prague Zoo', 'Прага зообағы', 50.11690000, 14.41170000, 'Prague Zoo', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Prague Zoo.jpg'),
    ('stromovka-park', 'prague', 'PARK', 2, 'HOURS', 4.6, 'Парк Стромовка', 'Stromovka Park', 'Стромовка паркі', 50.10680000, 14.42300000, 'Stromovka Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Stromovka Prague.jpg'),
    ('havelske-market', 'prague', 'MARKET', 1, 'HOURS', 4.4, 'Гавельский рынок', 'Havelske Market', 'Гавел базары', 50.08460000, 14.42150000, 'Havelske Market Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Havelske trziste Prague.jpg'),
    ('palladium-prague', 'prague', 'SHOPPING', 2, 'HOURS', 4.4, 'Palladium Prague', 'Palladium Prague', 'Palladium Prague', 50.08950000, 14.42860000, 'Palladium Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Palladium Praha.jpg'),
    ('manifesto-market-prague', 'prague', 'FOOD', 2, 'HOURS', 4.5, 'Manifesto Market Prague', 'Manifesto Market Prague', 'Manifesto Market Prague', 50.09140000, 14.43730000, 'Manifesto Market Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Manifesto Market Prague.jpg'),
    ('zlute-lazne', 'prague', 'BEACH', 3, 'HOURS', 4.5, 'Жлуте Лазне', 'Zlute Lazne', 'Жлуте Лазне', 50.04430000, 14.41470000, 'Zlute Lazne Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Zlute lazne Prague.jpg'),
    ('vysehrad', 'prague', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Вышеград', 'Vysehrad', 'Вышеград', 50.06440000, 14.41740000, 'Vysehrad Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'Vysehrad Prague.jpg'),
    ('dox-centre-prague', 'prague', 'MUSEUM', 2, 'HOURS', 4.5, 'Центр современного искусства DOX', 'DOX Centre for Contemporary Art', 'DOX заманауи өнер орталығы', 50.10560000, 14.44960000, 'DOX Centre Prague', ARRAY['prague']::text[], ARRAY['prague']::text[], 'DOX Centre Prague.jpg'),

    ('karlstejn-castle', 'karlstejn', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Карлштейн', 'Karlstejn Castle', 'Карлштейн қамалы', 49.93900000, 14.18800000, 'Karlstejn Castle Czechia', ARRAY['karlstejn']::text[], ARRAY['prague', 'karlstejn']::text[], 'Karlstejn Castle.jpg'),
    ('koneprusy-caves', 'karlstejn', 'NATURE', 2, 'HOURS', 4.6, 'Конепрусские пещеры', 'Koneprusy Caves', 'Конепрусы үңгірлері', 49.91510000, 14.07000000, 'Koneprusy Caves', ARRAY['karlstejn']::text[], ARRAY['prague', 'karlstejn']::text[], 'Koneprusy caves.jpg'),

    ('st-barbara-cathedral', 'kutna-hora', 'TEMPLE', 2, 'HOURS', 4.8, 'Собор Святой Варвары', 'St Barbara Cathedral', 'Әулие Варвара соборы', 49.94410000, 15.26320000, 'St Barbara Cathedral Kutna Hora', ARRAY['kutna-hora']::text[], ARRAY['prague', 'kutna-hora']::text[], 'Cathedral St Barbara.jpg'),
    ('sedlec-ossuary', 'kutna-hora', 'TEMPLE', 1, 'HOURS', 4.6, 'Костница в Седлеце', 'Sedlec Ossuary', 'Седлец сүйекханасы', 49.96190000, 15.28800000, 'Sedlec Ossuary Kutna Hora', ARRAY['kutna-hora']::text[], ARRAY['prague', 'kutna-hora']::text[], 'Sedlec Ossuary.jpg'),
    ('italian-court-kutna-hora', 'kutna-hora', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Итальянский двор', 'Italian Court Kutna Hora', 'Италиялық аула', 49.94950000, 15.26890000, 'Italian Court Kutna Hora', ARRAY['kutna-hora']::text[], ARRAY['kutna-hora']::text[], 'Italian Court Kutna Hora.jpg'),
    ('czech-museum-of-silver', 'kutna-hora', 'MUSEUM', 2, 'HOURS', 4.6, 'Чешский музей серебра', 'Czech Museum of Silver', 'Чех күміс музейі', 49.94660000, 15.26560000, 'Czech Museum of Silver Kutna Hora', ARRAY['kutna-hora']::text[], ARRAY['kutna-hora']::text[], 'Czech Museum of Silver Kutna Hora.jpg'),

    ('spilberk-castle', 'brno', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Шпильберк', 'Spilberk Castle', 'Шпильберк қамалы', 49.19490000, 16.59950000, 'Spilberk Castle Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Brno hrad Spilberk.jpg'),
    ('villa-tugendhat', 'brno', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Вилла Тугендхат', 'Villa Tugendhat', 'Тугендхат вилласы', 49.20730000, 16.61620000, 'Villa Tugendhat Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Villa Tugendhat Brno 01.jpg'),
    ('cathedral-st-peter-and-paul-brno', 'brno', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святых Петра и Павла', 'Cathedral of St Peter and Paul Brno', 'Брно Петр және Павел соборы', 49.19110000, 16.60750000, 'Cathedral of St Peter and Paul Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Brno Cathedral St. Peter and Paul-01.jpg'),
    ('vegetable-market-brno', 'brno', 'MARKET', 1, 'HOURS', 4.5, 'Овощной рынок Брно', 'Vegetable Market Brno', 'Брно көкөніс базары', 49.19290000, 16.60970000, 'Zelny trh Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Zelný trh Brno.jpg'),
    ('labyrinth-under-vegetable-market', 'brno', 'MUSEUM', 1, 'HOURS', 4.5, 'Лабиринт под овощным рынком', 'Labyrinth under Vegetable Market', 'Көкөніс базары астындағы лабиринт', 49.19300000, 16.60940000, 'Labyrinth under Vegetable Market Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Zelný trh Brno.jpg'),
    ('vida-science-centre', 'brno', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'VIDA Science Centre', 'VIDA Science Centre', 'VIDA Science Centre', 49.18770000, 16.58330000, 'VIDA Science Centre Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'VIDA Science Centre Brno.jpg'),
    ('brno-zoo', 'brno', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Зоопарк Брно', 'Brno Zoo', 'Брно зообағы', 49.23110000, 16.53360000, 'Brno Zoo', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Brno Zoo.jpg'),
    ('luzanky-park', 'brno', 'PARK', 1, 'HOURS', 4.5, 'Парк Лужанки', 'Luzanky Park', 'Лужанки паркі', 49.20590000, 16.60770000, 'Luzanky Park Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Lužánky Park Brno.jpg'),
    ('brno-dam', 'brno', 'BEACH', 3, 'HOURS', 4.5, 'Брненское водохранилище', 'Brno Dam', 'Брно су қоймасы', 49.23640000, 16.51780000, 'Brno Dam Reservoir', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Brno Dam.jpg'),
    ('olympia-brno', 'brno', 'SHOPPING', 2, 'HOURS', 4.4, 'Olympia Brno', 'Olympia Brno', 'Olympia Brno', 49.13670000, 16.63400000, 'Olympia Brno', ARRAY['brno']::text[], ARRAY['brno']::text[], 'Olympia Brno.jpg'),

    ('lednice-castle', 'lednice-valtice', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Леднице', 'Lednice Castle', 'Леднице қамалы', 48.80190000, 16.80430000, 'Lednice Castle Czechia', ARRAY['lednice-valtice']::text[], ARRAY['brno', 'lednice-valtice']::text[], 'Lednice Castle.jpg'),
    ('valtice-chateau', 'lednice-valtice', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Валтице', 'Valtice Chateau', 'Валтице қамалы', 48.74120000, 16.75550000, 'Valtice Chateau', ARRAY['lednice-valtice']::text[], ARRAY['brno', 'lednice-valtice']::text[], 'Valtice Chateau.jpg'),
    ('lednice-chateau-park', 'lednice-valtice', 'PARK', 2, 'HOURS', 4.7, 'Парк замка Леднице', 'Lednice Chateau Park', 'Леднице қамал паркі', 48.80400000, 16.80580000, 'Lednice Chateau Park', ARRAY['lednice-valtice']::text[], ARRAY['lednice-valtice']::text[], 'Lednice Park.jpg'),
    ('wine-salon-valtice', 'lednice-valtice', 'FOOD', 2, 'HOURS', 4.6, 'Винный салон Чехии', 'Wine Salon of the Czech Republic', 'Чехия шарап салоны', 48.74140000, 16.75580000, 'Wine Salon Valtice', ARRAY['lednice-valtice']::text[], ARRAY['brno', 'lednice-valtice']::text[], 'Valtice Chateau.jpg'),

    ('mikulov-chateau', 'mikulov', 'MUSEUM', 2, 'HOURS', 4.7, 'Замок Микулов', 'Mikulov Chateau', 'Микулов қамалы', 48.80620000, 16.63760000, 'Mikulov Chateau', ARRAY['mikulov']::text[], ARRAY['brno', 'mikulov']::text[], 'Mikulov Castle.jpg'),
    ('holy-hill-mikulov', 'mikulov', 'NATURE', 2, 'HOURS', 4.7, 'Святая гора Микулова', 'Holy Hill Mikulov', 'Микулов қасиетті төбесі', 48.80000000, 16.64970000, 'Holy Hill Mikulov', ARRAY['mikulov']::text[], ARRAY['mikulov']::text[], 'Svaty Kopecek Mikulov.jpg'),
    ('mikulov-wine-region', 'mikulov', 'FOOD', 2, 'HOURS', 4.6, 'Винный регион Микулов', 'Mikulov Wine Region', 'Микулов шарап өңірі', 48.80540000, 16.63800000, 'Mikulov Wine Region', ARRAY['mikulov']::text[], ARRAY['brno', 'mikulov']::text[], 'Mikulov Castle.jpg'),

    ('punkva-caves', 'moravian-karst', 'NATURE', 3, 'HOURS', 4.8, 'Пещеры Пунква', 'Punkva Caves', 'Пунква үңгірлері', 49.37200000, 16.72950000, 'Punkva Caves Moravian Karst', ARRAY['moravian-karst']::text[], ARRAY['brno', 'moravian-karst']::text[], 'The Punkva Caves - panoramio.jpg'),
    ('macocha-abyss', 'moravian-karst', 'NATURE', 2, 'HOURS', 4.7, 'Пропасть Мацоха', 'Macocha Abyss', 'Мацоха шыңырауы', 49.37270000, 16.72900000, 'Macocha Abyss Moravian Karst', ARRAY['moravian-karst']::text[], ARRAY['brno', 'moravian-karst']::text[], 'Macocha Abyss.jpg'),
    ('balcarka-cave', 'moravian-karst', 'NATURE', 2, 'HOURS', 4.5, 'Пещера Балцарка', 'Balcarka Cave', 'Балцарка үңгірі', 49.37340000, 16.75600000, 'Balcarka Cave Moravian Karst', ARRAY['moravian-karst']::text[], ARRAY['moravian-karst']::text[], 'Balcarka Cave.jpg'),

    ('cesky-krumlov-castle', 'cesky-krumlov', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Чески-Крумлов', 'Cesky Krumlov Castle', 'Чески-Крумлов қамалы', 48.81270000, 14.31520000, 'Cesky Krumlov Castle', ARRAY['cesky-krumlov']::text[], ARRAY['prague', 'ceske-budejovice', 'cesky-krumlov']::text[], 'Cesky Krumlov Castle.jpg'),
    ('cesky-krumlov-old-town', 'cesky-krumlov', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Чески-Крумлова', 'Cesky Krumlov Old Town', 'Чески-Крумлов ескі қаласы', 48.81190000, 14.31500000, 'Cesky Krumlov Old Town', ARRAY['cesky-krumlov']::text[], ARRAY['cesky-krumlov']::text[], 'Historic Centre of Cesky Krumlov.jpg'),
    ('egon-schiele-art-centrum', 'cesky-krumlov', 'MUSEUM', 2, 'HOURS', 4.5, 'Egon Schiele Art Centrum', 'Egon Schiele Art Centrum', 'Egon Schiele Art Centrum', 48.81080000, 14.31390000, 'Egon Schiele Art Centrum Cesky Krumlov', ARRAY['cesky-krumlov']::text[], ARRAY['cesky-krumlov']::text[], 'Egon Schiele Art Centrum.jpg'),
    ('graphite-mine-cesky-krumlov', 'cesky-krumlov', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Графитовая шахта Чески-Крумлов', 'Graphite Mine Cesky Krumlov', 'Чески-Крумлов графит шахтасы', 48.81920000, 14.31300000, 'Graphite Mine Cesky Krumlov', ARRAY['cesky-krumlov']::text[], ARRAY['cesky-krumlov']::text[], 'Cesky Krumlov Castle.jpg'),

    ('black-tower-ceske-budejovice', 'ceske-budejovice', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Черная башня Ческе-Будеёвице', 'Black Tower Ceske Budejovice', 'Ческе-Будеёвице қара мұнарасы', 48.97560000, 14.47490000, 'Black Tower Ceske Budejovice', ARRAY['ceske-budejovice']::text[], ARRAY['ceske-budejovice']::text[], 'Black Tower Ceske Budejovice Czech Republic.jpg'),
    ('premysl-otakar-square', 'ceske-budejovice', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Пржемысла Отакара II', 'Premysl Otakar II Square', 'Пржемысл Отакар II алаңы', 48.97480000, 14.47400000, 'Premysl Otakar II Square Ceske Budejovice', ARRAY['ceske-budejovice']::text[], ARRAY['ceske-budejovice']::text[], 'Ceske Budejovice Square.jpg'),
    ('budweiser-budvar-brewery', 'ceske-budejovice', 'FOOD', 2, 'HOURS', 4.6, 'Пивоварня Budweiser Budvar', 'Budweiser Budvar Brewery', 'Budweiser Budvar сыра қайнату зауыты', 48.99200000, 14.48070000, 'Budweiser Budvar Brewery', ARRAY['ceske-budejovice']::text[], ARRAY['ceske-budejovice']::text[], 'Budweiser Budvar Brewery.jpg'),
    ('hluboka-castle', 'ceske-budejovice', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Глубока', 'Hluboka Castle', 'Глубока қамалы', 49.05220000, 14.44100000, 'Hluboka Castle Czechia', ARRAY['ceske-budejovice']::text[], ARRAY['ceske-budejovice']::text[], 'Hluboka Castle.jpg'),

    ('sumava-national-park', 'sumava', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Шумава', 'Sumava National Park', 'Шумава ұлттық паркі', 49.03700000, 13.50000000, 'Sumava National Park', ARRAY['sumava']::text[], ARRAY['ceske-budejovice', 'sumava']::text[], 'Sumava National Park.jpg'),
    ('lipno-treetop-walkway', 'sumava', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Тропа по кронам деревьев Липно', 'Lipno Treetop Walkway', 'Липно ағаш басы жолы', 48.63930000, 14.23080000, 'Lipno Treetop Walkway', ARRAY['sumava']::text[], ARRAY['ceske-budejovice', 'sumava']::text[], 'Lipno Treetop Walkway.jpg'),
    ('lipno-lake-beach', 'sumava', 'BEACH', 3, 'HOURS', 4.5, 'Пляж озера Липно', 'Lipno Lake Beach', 'Липно көлі жағажайы', 48.64000000, 14.22900000, 'Lipno Lake Beach', ARRAY['sumava']::text[], ARRAY['sumava']::text[], 'Lake Lipno.jpg'),

    ('telc-historic-centre', 'telc', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Исторический центр Тельча', 'Telc Historic Centre', 'Тельч тарихи орталығы', 49.18420000, 15.45270000, 'Telc Historic Centre', ARRAY['telc']::text[], ARRAY['prague', 'telc']::text[], 'Telc main square.jpg'),
    ('telc-chateau', 'telc', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Тельч', 'Telc Chateau', 'Тельч қамалы', 49.18440000, 15.45150000, 'Telc Chateau', ARRAY['telc']::text[], ARRAY['telc']::text[], 'Státní zámek Telč.jpg'),

    ('trebic-jewish-quarter-basilica', 'trebic', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Еврейский квартал и базилика Святого Прокопия', 'Jewish Quarter and St Procopius Basilica Trebic', 'Тршебич еврей кварталы және Әулие Прокопий базиликасы', 49.21620000, 15.87970000, 'Jewish Quarter and St Procopius Basilica Trebic', ARRAY['trebic']::text[], ARRAY['brno', 'trebic']::text[], 'Trebic view on procopius basilica.jpg'),
    ('rear-synagogue-trebic', 'trebic', 'MUSEUM', 1, 'HOURS', 4.6, 'Задняя синагога Тршебича', 'Rear Synagogue Trebic', 'Тршебич артқы синагогасы', 49.21670000, 15.88080000, 'Rear Synagogue Trebic', ARRAY['trebic']::text[], ARRAY['trebic']::text[], 'Trebic synagogue.jpg'),

    ('mill-colonnade-karlovy-vary', 'karlovy-vary', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мельничная колоннада Карловых Вар', 'Mill Colonnade Karlovy Vary', 'Карловы Вары диірмен колоннадасы', 50.22360000, 12.88240000, 'Mill Colonnade Karlovy Vary', ARRAY['karlovy-vary']::text[], ARRAY['prague', 'karlovy-vary']::text[], 'Mill Colonnade Karlovy Vary.jpg'),
    ('hot-spring-colonnade', 'karlovy-vary', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Гейзерная колоннада', 'Hot Spring Colonnade', 'Ыстық бұлақ колоннадасы', 50.22240000, 12.88370000, 'Hot Spring Colonnade Karlovy Vary', ARRAY['karlovy-vary']::text[], ARRAY['karlovy-vary']::text[], 'Hot Spring Colonnade Karlovy Vary.jpg'),
    ('diana-observation-tower', 'karlovy-vary', 'NATURE', 2, 'HOURS', 4.6, 'Смотровая башня Диана', 'Diana Observation Tower', 'Диана қарау мұнарасы', 50.21890000, 12.87290000, 'Diana Observation Tower Karlovy Vary', ARRAY['karlovy-vary']::text[], ARRAY['karlovy-vary']::text[], 'Diana Observation Tower Karlovy Vary.jpg'),
    ('moser-glass-museum', 'karlovy-vary', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей стекла Moser', 'Moser Glass Museum', 'Moser шыны музейі', 50.23050000, 12.84100000, 'Moser Glass Museum Karlovy Vary', ARRAY['karlovy-vary']::text[], ARRAY['karlovy-vary']::text[], 'Moser Glass Museum.jpg'),
    ('varyada-shopping-centre', 'karlovy-vary', 'SHOPPING', 2, 'HOURS', 4.3, 'Торговый центр Varyada', 'Varyada Shopping Centre', 'Varyada сауда орталығы', 50.23180000, 12.84390000, 'Varyada Shopping Centre Karlovy Vary', ARRAY['karlovy-vary']::text[], ARRAY['karlovy-vary']::text[], 'Varyada Karlovy Vary.jpg'),

    ('singing-fountain-marianske-lazne', 'marianske-lazne', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Поющий фонтан Марианске-Лазне', 'Singing Fountain Marianske Lazne', 'Марианске-Лазне әнші фонтаны', 49.97690000, 12.70450000, 'Singing Fountain Marianske Lazne', ARRAY['marianske-lazne']::text[], ARRAY['prague', 'marianske-lazne']::text[], 'Singende Fontäne Marianske Lazne.jpg'),
    ('main-colonnade-marianske-lazne', 'marianske-lazne', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Главная колоннада Марианске-Лазне', 'Main Colonnade Marianske Lazne', 'Марианске-Лазне басты колоннадасы', 49.97710000, 12.70430000, 'Main Colonnade Marianske Lazne', ARRAY['marianske-lazne']::text[], ARRAY['marianske-lazne']::text[], 'Marianske Lazne Colonnade.jpg'),
    ('park-boheminium', 'marianske-lazne', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Парк Богеминиум', 'Park Boheminium', 'Богеминиум паркі', 49.97330000, 12.71880000, 'Park Boheminium Marianske Lazne', ARRAY['marianske-lazne']::text[], ARRAY['marianske-lazne']::text[], 'Park Boheminium.jpg'),

    ('pilsner-urquell-brewery', 'plzen', 'FOOD', 3, 'HOURS', 4.8, 'Пивоварня Pilsner Urquell', 'Pilsner Urquell Brewery', 'Pilsner Urquell сыра қайнату зауыты', 49.74770000, 13.38650000, 'Pilsner Urquell Brewery', ARRAY['plzen']::text[], ARRAY['prague', 'plzen']::text[], 'Pilsner Urquell Brewery.jpg'),
    ('great-synagogue-plzen', 'plzen', 'TEMPLE', 1, 'HOURS', 4.6, 'Большая синагога Пльзеня', 'Great Synagogue Plzen', 'Пльзень үлкен синагогасы', 49.74740000, 13.37460000, 'Great Synagogue Plzen', ARRAY['plzen']::text[], ARRAY['plzen']::text[], 'Great Synagogue Plzen.jpg'),
    ('techmania-science-center', 'plzen', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Techmania Science Center', 'Techmania Science Center', 'Techmania Science Center', 49.74390000, 13.35990000, 'Techmania Science Center Plzen', ARRAY['plzen']::text[], ARRAY['plzen']::text[], 'Techmania Science Center.jpg'),
    ('plzen-zoo', 'plzen', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Зоопарк Пльзеня', 'Plzen Zoo', 'Пльзень зообағы', 49.76250000, 13.35640000, 'Plzen Zoo', ARRAY['plzen']::text[], ARRAY['plzen']::text[], 'Plzen Zoo.jpg'),
    ('depo2015-street-food-market', 'plzen', 'MARKET', 2, 'HOURS', 4.4, 'DEPO2015 Street Food Market', 'DEPO2015 Street Food Market', 'DEPO2015 Street Food Market', 49.74300000, 13.38950000, 'DEPO2015 Plzen', ARRAY['plzen']::text[], ARRAY['plzen']::text[], 'DEPO2015 Plzen.jpg'),

    ('litomysl-castle', 'litomysl', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Литомишль', 'Litomysl Castle', 'Литомишль қамалы', 49.87240000, 16.31290000, 'Litomysl Castle', ARRAY['litomysl']::text[], ARRAY['prague', 'brno', 'litomysl']::text[], 'Litomyšl Renaissance Castle.jpg'),
    ('portmoneum-litomysl', 'litomysl', 'MUSEUM', 1, 'HOURS', 4.5, 'Portmoneum Litomysl', 'Portmoneum Litomysl', 'Portmoneum Litomysl', 49.87110000, 16.31160000, 'Portmoneum Litomysl', ARRAY['litomysl']::text[], ARRAY['litomysl']::text[], 'Portmoneum Litomysl.jpg'),
    ('monastery-gardens-litomysl', 'litomysl', 'PARK', 1, 'HOURS', 4.5, 'Монастырские сады Литомишля', 'Monastery Gardens Litomysl', 'Литомишль монастырь бақтары', 49.87150000, 16.31340000, 'Monastery Gardens Litomysl', ARRAY['litomysl']::text[], ARRAY['litomysl']::text[], 'Litomysl Monastery Gardens.jpg'),

    ('holy-trinity-column-olomouc', 'olomouc', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Колонна Святой Троицы в Оломоуце', 'Holy Trinity Column Olomouc', 'Оломоуц Қасиетті Үштік бағаны', 49.59390000, 17.25090000, 'Holy Trinity Column Olomouc', ARRAY['olomouc']::text[], ARRAY['brno', 'olomouc']::text[], 'Olomouc Holy Trinity Column.jpg'),
    ('olomouc-astronomical-clock', 'olomouc', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Астрономические часы Оломоуца', 'Olomouc Astronomical Clock', 'Оломоуц астрономиялық сағаты', 49.59390000, 17.25140000, 'Olomouc Astronomical Clock', ARRAY['olomouc']::text[], ARRAY['olomouc']::text[], 'Olomouc astronomical clock.jpg'),
    ('olomouc-zoo', 'olomouc', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Зоопарк Оломоуца', 'Olomouc Zoo', 'Оломоуц зообағы', 49.63380000, 17.34330000, 'Olomouc Zoo', ARRAY['olomouc']::text[], ARRAY['olomouc']::text[], 'Olomouc Zoo.jpg'),
    ('galerie-santovka', 'olomouc', 'SHOPPING', 2, 'HOURS', 4.4, 'Galerie Santovka', 'Galerie Santovka', 'Galerie Santovka', 49.58770000, 17.25360000, 'Galerie Santovka Olomouc', ARRAY['olomouc']::text[], ARRAY['olomouc']::text[], 'Galerie Santovka Olomouc.jpg'),

    ('lower-vitkovice', 'ostrava', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Нижняя область Витковице', 'Lower Vitkovice', 'Төменгі Витковице', 49.82050000, 18.28060000, 'Lower Vitkovice Ostrava', ARRAY['ostrava']::text[], ARRAY['ostrava']::text[], 'Dolni Vitkovice Ostrava.jpg'),
    ('landek-park-mining-museum', 'ostrava', 'MUSEUM', 3, 'HOURS', 4.6, 'Горный музей Landek Park', 'Landek Park Mining Museum', 'Landek Park тау-кен музейі', 49.86530000, 18.26110000, 'Landek Park Ostrava', ARRAY['ostrava']::text[], ARRAY['ostrava']::text[], 'Landek Park.jpg'),
    ('ostrava-zoo', 'ostrava', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Зоопарк Остравы', 'Ostrava Zoo', 'Острава зообағы', 49.84300000, 18.31940000, 'Ostrava Zoo', ARRAY['ostrava']::text[], ARRAY['ostrava']::text[], 'Ostrava Zoo.jpg'),
    ('forum-nova-karolina', 'ostrava', 'SHOPPING', 2, 'HOURS', 4.4, 'Forum Nova Karolina', 'Forum Nova Karolina', 'Forum Nova Karolina', 49.83130000, 18.28450000, 'Forum Nova Karolina Ostrava', ARRAY['ostrava']::text[], ARRAY['ostrava']::text[], 'Forum Nova Karolina.jpg'),
    ('stodolni-street', 'ostrava', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Улица Стодольни', 'Stodolni Street', 'Стодольни көшесі', 49.83590000, 18.28830000, 'Stodolni Street Ostrava', ARRAY['ostrava']::text[], ARRAY['ostrava']::text[], 'Stodolni Street Ostrava.jpg'),

    ('jested-tower', 'liberec', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Башня Йештед', 'Jested Tower', 'Йештед мұнарасы', 50.73260000, 14.98470000, 'Jested Tower Liberec', ARRAY['liberec']::text[], ARRAY['prague', 'liberec']::text[], 'Jested Tower.jpg'),
    ('liberec-zoo', 'liberec', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Зоопарк Либерца', 'Liberec Zoo', 'Либерец зообағы', 50.77150000, 15.08140000, 'Liberec Zoo', ARRAY['liberec']::text[], ARRAY['liberec']::text[], 'Liberec Zoo.jpg'),
    ('iqlandia-liberec', 'liberec', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'iQLANDIA Liberec', 'iQLANDIA Liberec', 'iQLANDIA Liberec', 50.76210000, 15.04970000, 'iQLANDIA Liberec', ARRAY['liberec']::text[], ARRAY['liberec']::text[], 'iQLANDIA Liberec.jpg'),
    ('forum-liberec', 'liberec', 'SHOPPING', 2, 'HOURS', 4.3, 'Forum Liberec', 'Forum Liberec', 'Forum Liberec', 50.76730000, 15.05570000, 'Forum Liberec', ARRAY['liberec']::text[], ARRAY['liberec']::text[], 'Forum Liberec.jpg'),

    ('white-tower-hradec-kralove', 'hradec-kralove', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Белая башня Градец-Кралове', 'White Tower Hradec Kralove', 'Градец-Кралове ақ мұнарасы', 50.20980000, 15.83180000, 'White Tower Hradec Kralove', ARRAY['hradec-kralove']::text[], ARRAY['hradec-kralove']::text[], 'White Tower Hradec Kralove.jpg'),
    ('east-bohemian-museum', 'hradec-kralove', 'MUSEUM', 2, 'HOURS', 4.5, 'Восточночешский музей', 'East Bohemian Museum', 'Шығыс Чехия музейі', 50.21040000, 15.82690000, 'East Bohemian Museum Hradec Kralove', ARRAY['hradec-kralove']::text[], ARRAY['hradec-kralove']::text[], 'East Bohemian Museum.jpg'),
    ('aupark-hradec-kralove', 'hradec-kralove', 'SHOPPING', 2, 'HOURS', 4.3, 'Aupark Hradec Kralove', 'Aupark Hradec Kralove', 'Aupark Hradec Kralove', 50.21280000, 15.81490000, 'Aupark Hradec Kralove', ARRAY['hradec-kralove']::text[], ARRAY['hradec-kralove']::text[], 'Aupark Hradec Kralove.jpg'),
    ('hradec-city-parks', 'hradec-kralove', 'PARK', 2, 'HOURS', 4.5, 'Городские парки Градец-Кралове', 'Hradec Kralove City Parks', 'Градец-Кралове қалалық парктері', 50.20500000, 15.82900000, 'Hradec Kralove city parks', ARRAY['hradec-kralove']::text[], ARRAY['hradec-kralove']::text[], 'Hradec Kralove park.jpg'),

    ('pardubice-chateau', 'pardubice', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Пардубице', 'Pardubice Chateau', 'Пардубице қамалы', 50.04040000, 15.77970000, 'Pardubice Chateau', ARRAY['pardubice']::text[], ARRAY['pardubice']::text[], 'Pardubice Chateau.jpg'),
    ('green-gate-pardubice', 'pardubice', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Зеленые ворота Пардубице', 'Green Gate Pardubice', 'Пардубице жасыл қақпасы', 50.03860000, 15.77820000, 'Green Gate Pardubice', ARRAY['pardubice']::text[], ARRAY['pardubice']::text[], 'Green Gate Pardubice.jpg'),
    ('aquacentre-pardubice', 'pardubice', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Аквацентр Пардубице', 'Aquacentre Pardubice', 'Пардубице акваорталығы', 50.03900000, 15.76650000, 'Aquacentre Pardubice', ARRAY['pardubice']::text[], ARRAY['pardubice']::text[], 'Aquacentre Pardubice.jpg'),
    ('palac-pardubice', 'pardubice', 'SHOPPING', 2, 'HOURS', 4.3, 'Palac Pardubice', 'Palac Pardubice', 'Palac Pardubice', 50.03330000, 15.77060000, 'Palac Pardubice', ARRAY['pardubice']::text[], ARRAY['pardubice']::text[], 'Palac Pardubice.jpg'),

    ('pravcicka-gate', 'bohemian-switzerland', 'NATURE', 4, 'HOURS', 4.8, 'Правчицкие ворота', 'Pravcicka Gate', 'Правчицка қақпасы', 50.88310000, 14.28170000, 'Pravcicka Gate Bohemian Switzerland', ARRAY['bohemian-switzerland']::text[], ARRAY['prague', 'bohemian-switzerland']::text[], 'Pravcicka brana.jpg'),
    ('kamenice-gorges', 'bohemian-switzerland', 'NATURE', 4, 'HOURS', 4.7, 'Ущелья реки Каменице', 'Kamenice River Gorges', 'Каменице өзені шатқалдары', 50.87400000, 14.27600000, 'Kamenice River Gorges Bohemian Switzerland', ARRAY['bohemian-switzerland']::text[], ARRAY['bohemian-switzerland']::text[], 'Kamenice Gorge.jpg'),
    ('bohemian-switzerland-national-park', 'bohemian-switzerland', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Чешская Швейцария', 'Bohemian Switzerland National Park', 'Чешская Швейцария ұлттық паркі', 50.87300000, 14.35500000, 'Bohemian Switzerland National Park', ARRAY['bohemian-switzerland']::text[], ARRAY['prague', 'bohemian-switzerland']::text[], 'Bohemian Switzerland National Park.jpg'),

    ('prachov-rocks', 'cesky-raj', 'NATURE', 4, 'HOURS', 4.8, 'Праховские скалы', 'Prachov Rocks', 'Прахов жартастары', 50.46790000, 15.29080000, 'Prachov Rocks Cesky Raj', ARRAY['cesky-raj']::text[], ARRAY['prague', 'cesky-raj']::text[], 'Prachov Rocks.jpg'),
    ('hruba-skala-rock-town', 'cesky-raj', 'NATURE', 3, 'HOURS', 4.7, 'Скальный город Груба-Скала', 'Hruba Skala Rock Town', 'Груба-Скала жартас қаласы', 50.54890000, 15.19720000, 'Hruba Skala Rock Town', ARRAY['cesky-raj']::text[], ARRAY['cesky-raj']::text[], 'Hruba Skala.jpg'),
    ('trosky-castle', 'cesky-raj', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Троски', 'Trosky Castle', 'Троски қамалы', 50.51660000, 15.23000000, 'Trosky Castle', ARRAY['cesky-raj']::text[], ARRAY['cesky-raj']::text[], 'Trosky Castle.jpg'),

    ('snezka-mountain', 'krkonose', 'NATURE', 5, 'HOURS', 4.8, 'Гора Снежка', 'Snezka Mountain', 'Снежка тауы', 50.73610000, 15.74000000, 'Snezka Mountain Krkonose', ARRAY['krkonose']::text[], ARRAY['prague', 'krkonose']::text[], 'Snezka mountain.jpg'),
    ('spindleruv-mlyn', 'krkonose', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Шпиндлерув-Млин', 'Spindleruv Mlyn', 'Шпиндлерув-Млин', 50.72600000, 15.60940000, 'Spindleruv Mlyn Krkonose', ARRAY['krkonose']::text[], ARRAY['krkonose']::text[], 'Spindleruv Mlyn.jpg'),
    ('krkonose-national-park', 'krkonose', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Крконоше', 'Krkonose National Park', 'Крконоше ұлттық паркі', 50.73300000, 15.65000000, 'Krkonose National Park', ARRAY['krkonose']::text[], ARRAY['prague', 'krkonose']::text[], 'Krkonose National Park.jpg'),
    ('mumlava-waterfall', 'krkonose', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Мумлава', 'Mumlava Waterfall', 'Мумлава сарқырамасы', 50.77340000, 15.43170000, 'Mumlava Waterfall Harrachov', ARRAY['krkonose']::text[], ARRAY['krkonose']::text[], 'Mumlava Waterfall.jpg');

CREATE TEMP TABLE seed_czechia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-czechia-place:' || seed.slug) AS place_hash,
        md5('id-czechia-media:' || seed.slug) AS media_hash
    FROM seed_czechia_priority_places seed
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
    ARRAY['czechia', city_id, slug, lower(category), 'czechia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Чехии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Czechia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Чехия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'CZ',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 400::numeric
        ELSE 200::numeric
    END,
    'CZK',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_czechia_resolved_places
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
FROM seed_czechia_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_czechia_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_czechia_resolved_places
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
FROM seed_czechia_resolved_places seed
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
FROM seed_czechia_resolved_places
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
    'CZ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_czechia_resolved_places
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
    'CZ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_czechia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
