-- Priority Tanzania destination places seed.
-- The seed covers safari circuits, Zanzibar, Indian Ocean beaches, museums, markets, malls, food spots, and southern/western nature routes.

DROP TABLE IF EXISTS seed_tanzania_resolved_places;
DROP TABLE IF EXISTS seed_tanzania_priority_places;

CREATE TEMP TABLE seed_tanzania_priority_places (
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

INSERT INTO seed_tanzania_priority_places (
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
    ('national-museum-tanzania', 'dar-es-salaam', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей Танзании', 'National Museum of Tanzania', 'Танзания ұлттық музейі', -6.81390000, 39.29210000, 'National Museum of Tanzania Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('village-museum-makumbusho', 'dar-es-salaam', 'MUSEUM', 2, 'HOURS', 4.6, 'Деревенский музей Макумбушо', 'Village Museum', 'Макумбушо ауыл музейі', -6.77510000, 39.24320000, 'Village Museum Makumbusho Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('kariakoo-market', 'dar-es-salaam', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Кариакоо', 'Kariakoo Market', 'Кариакоо базары', -6.82020000, 39.27430000, 'Kariakoo Market Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('kivukoni-fish-market', 'dar-es-salaam', 'MARKET', 2, 'HOURS', 4.5, 'Рыбный рынок Кивукони', 'Kivukoni Fish Market', 'Кивукони балық базары', -6.82190000, 39.29910000, 'Kivukoni Fish Market Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('mwenge-woodcarvers-market', 'dar-es-salaam', 'SHOPPING', 2, 'HOURS', 4.5, 'Рынок резчиков Мвенге', 'Mwenge Woodcarvers Market', 'Мвенге ағаш шеберлері базары', -6.77020000, 39.22860000, 'Mwenge Woodcarvers Market Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('mlimani-city-mall', 'dar-es-salaam', 'SHOPPING', 2, 'HOURS', 4.5, 'Mlimani City Mall', 'Mlimani City Mall', 'Mlimani City Mall', -6.77120000, 39.22260000, 'Mlimani City Mall Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('the-slipway', 'dar-es-salaam', 'SHOPPING', 2, 'HOURS', 4.5, 'The Slipway', 'The Slipway', 'The Slipway', -6.75460000, 39.27540000, 'The Slipway Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('azania-front-lutheran-cathedral', 'dar-es-salaam', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Азания-Фронт', 'Azania Front Lutheran Cathedral', 'Азания-Фронт соборы', -6.81640000, 39.29260000, 'Azania Front Lutheran Cathedral Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('coco-beach-oyster-bay', 'dar-es-salaam', 'BEACH', 3, 'HOURS', 4.5, 'Коко-Бич и Oyster Bay', 'Coco Beach and Oyster Bay', 'Коко жағажайы және Oyster Bay', -6.75850000, 39.27640000, 'Coco Beach Oyster Bay Dar es Salaam', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('mbudya-island', 'dar-es-salaam', 'BEACH', 4, 'HOURS', 4.7, 'Остров Мбудья', 'Mbudya Island', 'Мбудья аралы', -6.66580000, 39.26450000, 'Mbudya Island Dar es Salaam Marine Reserve', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),
    ('bongoyo-island', 'dar-es-salaam', 'BEACH', 4, 'HOURS', 4.7, 'Остров Бонгойо', 'Bongoyo Island Marine Reserve', 'Бонгойо аралы', -6.70160000, 39.27050000, 'Bongoyo Island Marine Reserve Tanzania', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], 'Dar_es_Salaam_skyline.jpg'),

    ('bagamoyo-historic-town', 'bagamoyo', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Исторический город Багамойо', 'Bagamoyo Historic Town', 'Багамойо тарихи қаласы', -6.44260000, 38.90490000, 'Bagamoyo Historic Town Tanzania', ARRAY['bagamoyo']::text[], ARRAY['bagamoyo', 'dar-es-salaam']::text[], 'Bagamoyo_Tanzania.jpg'),
    ('caravan-serai-museum', 'bagamoyo', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Караван-Сарай', 'Caravan Serai Museum', 'Караван-Сарай музейі', -6.44390000, 38.90250000, 'Caravan Serai Museum Bagamoyo', ARRAY['bagamoyo']::text[], ARRAY['bagamoyo', 'dar-es-salaam']::text[], 'Bagamoyo_Tanzania.jpg'),
    ('kaole-ruins', 'bagamoyo', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Руины Каоле', 'Kaole Ruins', 'Каоле қирандылары', -6.41680000, 38.92890000, 'Kaole Ruins Bagamoyo Tanzania', ARRAY['bagamoyo']::text[], ARRAY['bagamoyo', 'dar-es-salaam']::text[], 'Bagamoyo_Tanzania.jpg'),
    ('bagamoyo-catholic-museum', 'bagamoyo', 'MUSEUM', 2, 'HOURS', 4.5, 'Католический музей Багамойо', 'Bagamoyo Catholic Museum', 'Багамойо католик музейі', -6.44330000, 38.90550000, 'Bagamoyo Catholic Museum Tanzania', ARRAY['bagamoyo']::text[], ARRAY['bagamoyo', 'dar-es-salaam']::text[], 'Bagamoyo_Tanzania.jpg'),
    ('saadani-national-park', 'saadani', 'PARK', 6, 'HOURS', 4.7, 'Национальный парк Саадани', 'Saadani National Park', 'Саадани ұлттық паркі', -6.00000000, 38.75000000, 'Saadani National Park Tanzania', ARRAY['saadani']::text[], ARRAY['saadani', 'dar-es-salaam']::text[], 'Saadani_National_Park.jpg'),
    ('pangani-historic-town', 'pangani', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Исторический город Пангани', 'Pangani Historic Town', 'Пангани тарихи қаласы', -5.42530000, 38.97350000, 'Pangani Historic Town Tanzania', ARRAY['pangani']::text[], ARRAY['pangani', 'tanga']::text[], 'Pangani_Tanzania.jpg'),
    ('ushongo-beach', 'pangani', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Ушонго', 'Ushongo Beach', 'Ушонго жағажайы', -5.51660000, 38.99420000, 'Ushongo Beach Pangani Tanzania', ARRAY['pangani']::text[], ARRAY['pangani', 'tanga']::text[], 'Pangani_Tanzania.jpg'),
    ('maziwe-island-marine-reserve', 'pangani', 'NATURE', 4, 'HOURS', 4.7, 'Морской заповедник Мазиве', 'Maziwe Island Marine Reserve', 'Мазиве теңіз қорығы', -5.50000000, 39.08330000, 'Maziwe Island Marine Reserve Tanzania', ARRAY['pangani']::text[], ARRAY['pangani', 'tanga']::text[], 'Pangani_Tanzania.jpg'),
    ('amboni-caves', 'tanga', 'NATURE', 2, 'HOURS', 4.6, 'Пещеры Амбони', 'Amboni Caves', 'Амбони үңгірлері', -5.03750000, 39.07180000, 'Amboni Caves Tanga Tanzania', ARRAY['tanga']::text[], ARRAY['tanga']::text[], 'Amboni_Caves.jpg'),
    ('tongoni-ruins', 'tanga', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Руины Тонгони', 'Tongoni Ruins', 'Тонгони қирандылары', -5.02910000, 39.11680000, 'Tongoni Ruins Tanga Tanzania', ARRAY['tanga']::text[], ARRAY['tanga']::text[], 'Amboni_Caves.jpg'),
    ('toten-island', 'tanga', 'OTHER', 2, 'HOURS', 4.4, 'Остров Тотен', 'Toten Island', 'Тотен аралы', -5.06670000, 39.11670000, 'Toten Island Tanga Tanzania', ARRAY['tanga']::text[], ARRAY['tanga']::text[], 'Amboni_Caves.jpg'),
    ('mafia-island-marine-park', 'mafia-island', 'NATURE', 6, 'HOURS', 4.8, 'Морской парк острова Мафия', 'Mafia Island Marine Park', 'Мафия аралы теңіз паркі', -7.98650000, 39.71880000, 'Mafia Island Marine Park Tanzania', ARRAY['mafia-island']::text[], ARRAY['mafia-island', 'dar-es-salaam']::text[], 'Mafia_Island_Tanzania.jpg'),
    ('chole-island', 'mafia-island', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Остров Чоле', 'Chole Island', 'Чоле аралы', -7.97420000, 39.76840000, 'Chole Island Mafia Tanzania', ARRAY['mafia-island']::text[], ARRAY['mafia-island']::text[], 'Mafia_Island_Tanzania.jpg'),

    ('stone-town', 'stone-town', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Стоун-Таун', 'Stone Town', 'Стоун-Таун', -6.16220000, 39.19210000, 'Stone Town Zanzibar Tanzania', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('old-fort-zanzibar', 'stone-town', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Старый форт Занзибара', 'Old Fort Zanzibar', 'Занзибар ескі қамалы', -6.16160000, 39.18910000, 'Old Fort Zanzibar Stone Town', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('house-of-wonders', 'stone-town', 'MUSEUM', 1, 'HOURS', 4.5, 'Дом чудес', 'House of Wonders', 'Ғажайыптар үйі', -6.16090000, 39.18960000, 'House of Wonders Zanzibar', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('anglican-cathedral-former-slave-market', 'stone-town', 'TEMPLE', 2, 'HOURS', 4.7, 'Англиканский собор и бывший рынок рабов', 'Anglican Cathedral and Former Slave Market', 'Англикан соборы және бұрынғы құл базары', -6.16400000, 39.19180000, 'Anglican Cathedral Former Slave Market Zanzibar', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('freddie-mercury-museum', 'stone-town', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Фредди Меркьюри', 'Freddie Mercury Museum', 'Фредди Меркьюри музейі', -6.16030000, 39.18830000, 'Freddie Mercury Museum Zanzibar', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('old-dispensary-zanzibar', 'stone-town', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Старая диспансерия Занзибара', 'Old Dispensary Zanzibar', 'Занзибар ескі диспансері', -6.15840000, 39.19310000, 'Old Dispensary Zanzibar', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('darajani-bazaar', 'zanzibar-city', 'MARKET', 2, 'HOURS', 4.6, 'Базар Дараджани', 'Darajani Bazaar', 'Дараджани базары', -6.16400000, 39.19310000, 'Darajani Bazaar Zanzibar', ARRAY['zanzibar-city', 'stone-town']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('forodhani-night-market', 'stone-town', 'FOOD', 2, 'HOURS', 4.7, 'Ночной рынок Фородани', 'Forodhani Night Market', 'Фородани түнгі базары', -6.16060000, 39.18920000, 'Forodhani Night Market Zanzibar', ARRAY['stone-town', 'zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('spice-farm-tour', 'zanzibar-city', 'FOOD', 3, 'HOURS', 4.6, 'Тур по ферме специй', 'Spice Farm Tour', 'Дәмдеуіш фермасы туры', -6.08000000, 39.24000000, 'Spice Farm Tour Zanzibar', ARRAY['zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('prison-island-zanzibar', 'zanzibar-city', 'NATURE', 4, 'HOURS', 4.7, 'Остров Призон', 'Prison Island', 'Призон аралы', -6.11900000, 39.16890000, 'Prison Island Zanzibar', ARRAY['zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('nakupenda-sandbank', 'zanzibar-city', 'BEACH', 4, 'HOURS', 4.8, 'Отмель Накупенда', 'Nakupenda Sandbank', 'Накупенда құм қайраңы', -6.15400000, 39.14300000, 'Nakupenda Sandbank Zanzibar', ARRAY['zanzibar-city']::text[], ARRAY['zanzibar-city', 'stone-town']::text[], 'Stone_Town_Zanzibar.jpg'),
    ('nungwi-beach', 'nungwi', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Нунгви', 'Nungwi Beach', 'Нунгви жағажайы', -5.72610000, 39.29840000, 'Nungwi Beach Zanzibar', ARRAY['nungwi']::text[], ARRAY['nungwi', 'zanzibar-city']::text[], 'Nungwi_Beach_Zanzibar.jpg'),
    ('mnarani-aquarium', 'nungwi', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Аквариум Мнарани', 'Nungwi Mnarani Aquarium', 'Нунгви Мнарани аквариумы', -5.72670000, 39.30430000, 'Nungwi Mnarani Aquarium Zanzibar', ARRAY['nungwi']::text[], ARRAY['nungwi', 'zanzibar-city']::text[], 'Nungwi_Beach_Zanzibar.jpg'),
    ('kendwa-beach', 'kendwa', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Кендва', 'Kendwa Beach', 'Кендва жағажайы', -5.75490000, 39.28980000, 'Kendwa Beach Zanzibar', ARRAY['kendwa']::text[], ARRAY['kendwa', 'zanzibar-city']::text[], 'Nungwi_Beach_Zanzibar.jpg'),
    ('paje-beach', 'paje', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Паже', 'Paje Beach', 'Паже жағажайы', -6.26520000, 39.53540000, 'Paje Beach Zanzibar', ARRAY['paje']::text[], ARRAY['paje', 'zanzibar-city']::text[], 'Zanzibar_Paje_beach.jpg'),
    ('mwani-seaweed-centre', 'paje', 'OTHER', 2, 'HOURS', 4.5, 'Центр водорослей Mwani', 'Mwani Seaweed Centre', 'Mwani теңіз балдыры орталығы', -6.26610000, 39.53590000, 'Mwani Seaweed Centre Zanzibar', ARRAY['paje']::text[], ARRAY['paje', 'zanzibar-city']::text[], 'Zanzibar_Paje_beach.jpg'),
    ('jambiani-beach', 'jambiani', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Джамбиани', 'Jambiani Beach', 'Джамбиани жағажайы', -6.32200000, 39.54850000, 'Jambiani Beach Zanzibar', ARRAY['jambiani']::text[], ARRAY['jambiani', 'zanzibar-city']::text[], 'Zanzibar_Paje_beach.jpg'),
    ('kuza-cave', 'jambiani', 'NATURE', 2, 'HOURS', 4.6, 'Пещера Куза', 'Kuza Cave', 'Куза үңгірі', -6.32160000, 39.54670000, 'Kuza Cave Jambiani Zanzibar', ARRAY['jambiani']::text[], ARRAY['jambiani', 'zanzibar-city']::text[], 'Zanzibar_Paje_beach.jpg'),
    ('jozani-forest', 'jozani', 'PARK', 3, 'HOURS', 4.7, 'Лес Джозани', 'Jozani Forest', 'Джозани орманы', -6.25300000, 39.42440000, 'Jozani Forest Zanzibar', ARRAY['jozani']::text[], ARRAY['jozani', 'zanzibar-city']::text[], 'Jozani_Forest_Zanzibar.jpg'),
    ('mnemba-marine-area', 'mnemba', 'NATURE', 4, 'HOURS', 4.8, 'Морская зона Мнемба', 'Mnemba Marine Area', 'Мнемба теңіз аймағы', -5.81880000, 39.38300000, 'Mnemba Marine Area Zanzibar', ARRAY['mnemba']::text[], ARRAY['mnemba', 'nungwi']::text[], 'Nungwi_Beach_Zanzibar.jpg'),

    ('arusha-national-park', 'arusha', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Аруша', 'Arusha National Park', 'Аруша ұлттық паркі', -3.25000000, 36.83330000, 'Arusha National Park Tanzania', ARRAY['arusha']::text[], ARRAY['arusha']::text[], 'Arusha_National_Park.jpg'),
    ('mount-meru', 'mount-meru', 'NATURE', 8, 'HOURS', 4.8, 'Гора Меру', 'Mount Meru', 'Меру тауы', -3.23920000, 36.75080000, 'Mount Meru Tanzania', ARRAY['mount-meru', 'arusha']::text[], ARRAY['arusha', 'mount-meru']::text[], 'Mount_Meru_Tanzania.jpg'),
    ('momella-lakes', 'arusha', 'NATURE', 3, 'HOURS', 4.6, 'Озера Момелла', 'Momella Lakes', 'Момелла көлдері', -3.25080000, 36.88390000, 'Momella Lakes Arusha National Park', ARRAY['arusha']::text[], ARRAY['arusha']::text[], 'Arusha_National_Park.jpg'),
    ('national-natural-history-museum-arusha', 'arusha', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный музей естественной истории', 'National Natural History Museum Arusha', 'Аруша табиғи тарих музейі', -3.36670000, 36.68330000, 'National Natural History Museum Arusha Tanzania', ARRAY['arusha']::text[], ARRAY['arusha']::text[], 'Arusha_Tanzania.jpg'),
    ('arusha-cultural-heritage-centre', 'arusha', 'MUSEUM', 3, 'HOURS', 4.7, 'Центр культурного наследия Аруши', 'Arusha Cultural Heritage Centre', 'Аруша мәдени мұра орталығы', -3.43070000, 36.67090000, 'Arusha Cultural Heritage Centre Tanzania', ARRAY['arusha']::text[], ARRAY['arusha']::text[], 'Arusha_Tanzania.jpg'),
    ('arusha-maasai-market', 'arusha', 'MARKET', 2, 'HOURS', 4.5, 'Рынок масаи в Аруше', 'Arusha Maasai Market', 'Аруша масаи базары', -3.37200000, 36.69480000, 'Arusha Maasai Market Tanzania', ARRAY['arusha']::text[], ARRAY['arusha']::text[], 'Arusha_Tanzania.jpg'),
    ('kilimanjaro-national-park', 'kilimanjaro', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Килиманджаро', 'Kilimanjaro National Park', 'Килиманджаро ұлттық паркі', -3.06740000, 37.35560000, 'Kilimanjaro National Park Tanzania', ARRAY['kilimanjaro', 'moshi']::text[], ARRAY['moshi', 'kilimanjaro']::text[], 'Kilimanjaro_from_Amboseli_National_Park.jpg'),
    ('mount-kilimanjaro', 'kilimanjaro', 'NATURE', 8, 'HOURS', 4.9, 'Гора Килиманджаро', 'Mount Kilimanjaro', 'Килиманджаро тауы', -3.06740000, 37.35560000, 'Mount Kilimanjaro Tanzania', ARRAY['kilimanjaro', 'moshi']::text[], ARRAY['moshi', 'kilimanjaro']::text[], 'Kilimanjaro_from_Amboseli_National_Park.jpg'),
    ('materuni-waterfalls-coffee-tour', 'moshi', 'NATURE', 4, 'HOURS', 4.7, 'Водопады Матеруни и кофейный тур', 'Materuni Waterfalls and Coffee Tour', 'Матеруни сарқырамасы және кофе туры', -3.25330000, 37.52440000, 'Materuni Waterfalls Coffee Tour Moshi Tanzania', ARRAY['moshi']::text[], ARRAY['moshi', 'kilimanjaro']::text[], 'Kilimanjaro_from_Amboseli_National_Park.jpg'),
    ('chemka-kikuletwa-hot-springs', 'moshi', 'NATURE', 4, 'HOURS', 4.7, 'Горячие источники Чемка', 'Chemka Kikuletwa Hot Springs', 'Чемка ыстық бұлақтары', -3.41870000, 37.19840000, 'Chemka Kikuletwa Hot Springs Tanzania', ARRAY['moshi']::text[], ARRAY['moshi', 'arusha']::text[], 'Kilimanjaro_from_Amboseli_National_Park.jpg'),
    ('lake-chala', 'kilimanjaro', 'NATURE', 4, 'HOURS', 4.6, 'Озеро Чала', 'Lake Chala', 'Чала көлі', -3.31670000, 37.70000000, 'Lake Chala Tanzania', ARRAY['kilimanjaro', 'moshi']::text[], ARRAY['moshi', 'kilimanjaro']::text[], 'Kilimanjaro_from_Amboseli_National_Park.jpg'),
    ('serengeti-national-park', 'serengeti', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Серенгети', 'Serengeti National Park', 'Серенгети ұлттық паркі', -2.33330000, 34.83330000, 'Serengeti National Park Tanzania', ARRAY['serengeti']::text[], ARRAY['serengeti', 'arusha']::text[], 'Serengeti_National_Park_Tanzania.jpg'),
    ('central-serengeti-game-drives', 'serengeti', 'PARK', 6, 'HOURS', 4.9, 'Сафари по центральному Серенгети', 'Central Serengeti Game Drives', 'Орталық Серенгети сафариі', -2.44000000, 34.82000000, 'Central Serengeti Seronera Tanzania', ARRAY['serengeti']::text[], ARRAY['serengeti', 'arusha']::text[], 'Serengeti_National_Park_Tanzania.jpg'),
    ('ngorongoro-crater', 'ngorongoro', 'PARK', 6, 'HOURS', 4.9, 'Кратер Нгоронгоро', 'Ngorongoro Crater', 'Нгоронгоро кратері', -3.16180000, 35.58770000, 'Ngorongoro Crater Tanzania', ARRAY['ngorongoro']::text[], ARRAY['ngorongoro', 'arusha', 'karatu']::text[], 'Ngorongoro_Crater_Tanzania.jpg'),
    ('olduvai-gorge-museum', 'ngorongoro', 'MUSEUM', 2, 'HOURS', 4.7, 'Ущелье Олдувай и музей', 'Olduvai Gorge Museum', 'Олдувай шатқалы музейі', -2.99560000, 35.35270000, 'Olduvai Gorge Museum Tanzania', ARRAY['ngorongoro']::text[], ARRAY['ngorongoro', 'karatu']::text[], 'Ngorongoro_Crater_Tanzania.jpg'),
    ('empakaai-crater', 'ngorongoro', 'NATURE', 4, 'HOURS', 4.7, 'Кратер Эмпакаи', 'Empakaai Crater', 'Эмпакаи кратері', -2.91110000, 35.82390000, 'Empakaai Crater Ngorongoro Tanzania', ARRAY['ngorongoro']::text[], ARRAY['ngorongoro', 'karatu']::text[], 'Ngorongoro_Crater_Tanzania.jpg'),
    ('tarangire-national-park', 'tarangire', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Тарангире', 'Tarangire National Park', 'Тарангире ұлттық паркі', -3.83330000, 36.00000000, 'Tarangire National Park Tanzania', ARRAY['tarangire']::text[], ARRAY['tarangire', 'arusha']::text[], 'Tarangire_National_Park.jpg'),
    ('lake-manyara-national-park', 'lake-manyara', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Лейк-Маньяра', 'Lake Manyara National Park', 'Маньяра көлі ұлттық паркі', -3.54100000, 35.81830000, 'Lake Manyara National Park Tanzania', ARRAY['lake-manyara']::text[], ARRAY['lake-manyara', 'karatu', 'arusha']::text[], 'Lake_Manyara_National_Park.jpg'),
    ('lake-manyara-canopy-walkway', 'lake-manyara', 'NATURE', 2, 'HOURS', 4.6, 'Тропа по кронам Лейк-Маньяра', 'Lake Manyara Canopy Walkway', 'Маньяра ағаш үсті жолы', -3.41000000, 35.82000000, 'Lake Manyara Canopy Walkway Tanzania', ARRAY['lake-manyara']::text[], ARRAY['lake-manyara', 'karatu']::text[], 'Lake_Manyara_National_Park.jpg'),
    ('karatu-coffee-village-walk', 'karatu', 'FOOD', 3, 'HOURS', 4.6, 'Кофейный тур и деревни Карату', 'Karatu Coffee Biking Tour and Village Walk', 'Карату кофе және ауыл туры', -3.34170000, 35.67030000, 'Karatu Coffee Biking Tour Tanzania', ARRAY['karatu']::text[], ARRAY['karatu', 'arusha']::text[], 'Ngorongoro_Crater_Tanzania.jpg'),
    ('endoro-waterfalls-elephant-caves', 'karatu', 'NATURE', 3, 'HOURS', 4.6, 'Водопады Эндоро и Пещеры слонов', 'Endoro Waterfalls and Elephant Caves', 'Эндоро сарқырамасы және піл үңгірлері', -3.35000000, 35.65000000, 'Endoro Waterfalls Elephant Caves Karatu', ARRAY['karatu']::text[], ARRAY['karatu']::text[], 'Ngorongoro_Crater_Tanzania.jpg'),

    ('nyerere-square-dodoma', 'dodoma', 'PARK', 1, 'HOURS', 4.4, 'Площадь Ньерере', 'Nyerere Square', 'Ньерере алаңы', -6.17010000, 35.73950000, 'Nyerere Square Dodoma Tanzania', ARRAY['dodoma']::text[], ARRAY['dodoma']::text[], 'Dodoma_Tanzania.jpg'),
    ('gaddafi-mosque-dodoma', 'dodoma', 'TEMPLE', 1, 'HOURS', 4.5, 'Мечеть Каддафи', 'Gaddafi Mosque', 'Каддафи мешіті', -6.17240000, 35.74420000, 'Gaddafi Mosque Dodoma Tanzania', ARRAY['dodoma']::text[], ARRAY['dodoma']::text[], 'Dodoma_Tanzania.jpg'),
    ('bunge-parliament-building', 'dodoma', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Здание парламента Бунге', 'Bunge Parliament Building', 'Бунге парламент ғимараты', -6.18320000, 35.74640000, 'Bunge Parliament Building Dodoma Tanzania', ARRAY['dodoma']::text[], ARRAY['dodoma']::text[], 'Dodoma_Tanzania.jpg'),
    ('dodoma-wine-estate', 'dodoma', 'FOOD', 2, 'HOURS', 4.4, 'Винодельня Додомы', 'Dodoma Wine Estate', 'Додома шарап шаруашылығы', -6.19700000, 35.74400000, 'Dodoma Wine Estate Tanzania', ARRAY['dodoma']::text[], ARRAY['dodoma']::text[], 'Dodoma_Tanzania.jpg'),
    ('uluguru-mountains', 'morogoro', 'NATURE', 5, 'HOURS', 4.7, 'Горы Улугуру', 'Uluguru Mountains', 'Улугуру таулары', -6.98330000, 37.66670000, 'Uluguru Mountains Morogoro Tanzania', ARRAY['morogoro']::text[], ARRAY['morogoro']::text[], 'Morogoro_Tanzania.jpg'),
    ('kinole-waterfalls', 'morogoro', 'NATURE', 4, 'HOURS', 4.6, 'Водопады Киноле', 'Kinole Waterfalls', 'Киноле сарқырамалары', -7.05000000, 37.80000000, 'Kinole Waterfalls Morogoro Tanzania', ARRAY['morogoro']::text[], ARRAY['morogoro']::text[], 'Morogoro_Tanzania.jpg'),
    ('soko-kuu-kingalu', 'morogoro', 'MARKET', 2, 'HOURS', 4.4, 'Центральный рынок Кингалу', 'Soko Kuu la Kingalu', 'Кингалу орталық базары', -6.82260000, 37.66120000, 'Soko Kuu la Kingalu Morogoro', ARRAY['morogoro']::text[], ARRAY['morogoro']::text[], 'Morogoro_Tanzania.jpg'),
    ('mikumi-national-park', 'mikumi', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Микуми', 'Mikumi National Park', 'Микуми ұлттық паркі', -7.25000000, 37.00000000, 'Mikumi National Park Tanzania', ARRAY['mikumi']::text[], ARRAY['mikumi', 'morogoro']::text[], 'Mikumi_National_Park.jpg'),
    ('udzungwa-mountains-national-park', 'udzungwa', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Удзунгва', 'Udzungwa Mountains National Park', 'Удзунгва таулары ұлттық паркі', -7.80000000, 36.85000000, 'Udzungwa Mountains National Park Tanzania', ARRAY['udzungwa']::text[], ARRAY['udzungwa', 'morogoro']::text[], 'Udzungwa_Mountains_National_Park.jpg'),
    ('sanje-waterfall', 'udzungwa', 'NATURE', 4, 'HOURS', 4.7, 'Водопад Сандже', 'Sanje Waterfall', 'Сандже сарқырамасы', -7.76700000, 36.88300000, 'Sanje Waterfall Udzungwa Tanzania', ARRAY['udzungwa']::text[], ARRAY['udzungwa', 'morogoro']::text[], 'Udzungwa_Mountains_National_Park.jpg'),
    ('ruaha-national-park', 'ruaha', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Руаха', 'Ruaha National Park', 'Руаха ұлттық паркі', -7.50000000, 35.00000000, 'Ruaha National Park Tanzania', ARRAY['ruaha']::text[], ARRAY['ruaha', 'iringa']::text[], 'Ruaha_National_Park.jpg'),
    ('great-ruaha-river', 'ruaha', 'NATURE', 4, 'HOURS', 4.7, 'Великая река Руаха', 'Great Ruaha River', 'Ұлы Руаха өзені', -7.65000000, 34.95000000, 'Great Ruaha River Tanzania', ARRAY['ruaha']::text[], ARRAY['ruaha', 'iringa']::text[], 'Ruaha_National_Park.jpg'),
    ('nyerere-national-park', 'nyerere', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Ньерере', 'Nyerere National Park', 'Ньерере ұлттық паркі', -8.90000000, 37.80000000, 'Nyerere National Park Tanzania', ARRAY['nyerere']::text[], ARRAY['nyerere', 'dar-es-salaam']::text[], 'Selous_Game_Reserve_Tanzania.jpg'),
    ('rufiji-river', 'nyerere', 'NATURE', 4, 'HOURS', 4.8, 'Река Руфиджи', 'Rufiji River', 'Руфиджи өзені', -7.85000000, 38.75000000, 'Rufiji River Nyerere National Park', ARRAY['nyerere']::text[], ARRAY['nyerere', 'dar-es-salaam']::text[], 'Selous_Game_Reserve_Tanzania.jpg'),
    ('iringa-boma-regional-museum', 'iringa', 'MUSEUM', 2, 'HOURS', 4.6, 'Региональный музей Иринга Бома', 'Iringa Boma Regional Museum', 'Иринга Бома өңірлік музейі', -7.77180000, 35.69780000, 'Iringa Boma Regional Museum Tanzania', ARRAY['iringa']::text[], ARRAY['iringa']::text[], 'Iringa_Tanzania.jpg'),
    ('isimila-stone-age-site', 'iringa', 'MUSEUM', 2, 'HOURS', 4.7, 'Стоянка каменного века Исимила', 'Isimila Stone Age Site', 'Исимила тас дәуірі орны', -7.85000000, 35.75000000, 'Isimila Stone Age Site Tanzania', ARRAY['iringa']::text[], ARRAY['iringa']::text[], 'Iringa_Tanzania.jpg'),
    ('gangilonga-rock', 'iringa', 'NATURE', 2, 'HOURS', 4.5, 'Скала Гангилонга', 'Gangilonga Rock', 'Гангилонга жартасы', -7.77120000, 35.70010000, 'Gangilonga Rock Iringa Tanzania', ARRAY['iringa']::text[], ARRAY['iringa']::text[], 'Iringa_Tanzania.jpg'),
    ('iringa-market-area', 'iringa', 'MARKET', 2, 'HOURS', 4.4, 'Рыночный район Иринги', 'Iringa Market Area', 'Иринга базар аймағы', -7.77090000, 35.69090000, 'Iringa Market Area Tanzania', ARRAY['iringa']::text[], ARRAY['iringa']::text[], 'Iringa_Tanzania.jpg'),
    ('lake-ngozi-crater', 'mbeya', 'NATURE', 5, 'HOURS', 4.7, 'Кратерное озеро Нгози', 'Lake Ngozi Crater', 'Нгози кратер көлі', -9.03660000, 33.57090000, 'Lake Ngozi Crater Mbeya Tanzania', ARRAY['mbeya']::text[], ARRAY['mbeya']::text[], 'Mbeya_Tanzania.jpg'),
    ('mbozi-meteorite', 'mbeya', 'OTHER', 2, 'HOURS', 4.5, 'Метеорит Мбози', 'Mbozi Meteorite', 'Мбози метеориті', -9.11670000, 33.06670000, 'Mbozi Meteorite Tanzania', ARRAY['mbeya']::text[], ARRAY['mbeya']::text[], 'Mbeya_Tanzania.jpg'),
    ('matema-beach', 'mbeya', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Матема', 'Matema Beach', 'Матема жағажайы', -9.50000000, 34.01670000, 'Matema Beach Lake Nyasa Tanzania', ARRAY['mbeya']::text[], ARRAY['mbeya']::text[], 'Mbeya_Tanzania.jpg'),
    ('kitulo-national-park', 'kitulo', 'PARK', 6, 'HOURS', 4.7, 'Национальный парк Китуло', 'Kitulo National Park', 'Китуло ұлттық паркі', -9.00000000, 33.90000000, 'Kitulo National Park Tanzania', ARRAY['kitulo']::text[], ARRAY['kitulo', 'mbeya']::text[], 'Kitulo_National_Park.jpg'),

    ('bismarck-rock', 'mwanza', 'NATURE', 1, 'HOURS', 4.6, 'Скала Бисмарка', 'Bismarck Rock', 'Бисмарк жартасы', -2.51670000, 32.90000000, 'Bismarck Rock Mwanza Tanzania', ARRAY['mwanza']::text[], ARRAY['mwanza']::text[], 'Bismarck_Rock_Mwanza_Tanzania.jpg'),
    ('lake-victoria-waterfront', 'mwanza', 'BEACH', 2, 'HOURS', 4.5, 'Набережная Lake Victoria', 'Lake Victoria Waterfront', 'Виктория көлі жағалауы', -2.51650000, 32.90090000, 'Lake Victoria Waterfront Mwanza Tanzania', ARRAY['mwanza']::text[], ARRAY['mwanza']::text[], 'Bismarck_Rock_Mwanza_Tanzania.jpg'),
    ('saanane-island-national-park', 'mwanza', 'PARK', 4, 'HOURS', 4.7, 'Национальный парк Саанане', 'Saanane Island National Park', 'Саанане аралы ұлттық паркі', -2.55260000, 32.89220000, 'Saanane Island National Park Tanzania', ARRAY['mwanza']::text[], ARRAY['mwanza']::text[], 'Bismarck_Rock_Mwanza_Tanzania.jpg'),
    ('sukuma-museum', 'mwanza', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей народа Sukuma', 'Sukuma Museum', 'Сукума музейі', -2.68330000, 33.03330000, 'Sukuma Museum Mwanza Tanzania', ARRAY['mwanza']::text[], ARRAY['mwanza']::text[], 'Bismarck_Rock_Mwanza_Tanzania.jpg'),
    ('mwaloni-fish-market', 'mwanza', 'MARKET', 2, 'HOURS', 4.4, 'Рыбный рынок Mwaloni', 'Mwaloni Fish Market', 'Mwaloni балық базары', -2.52360000, 32.89440000, 'Mwaloni Fish Market Mwanza', ARRAY['mwanza']::text[], ARRAY['mwanza']::text[], 'Bismarck_Rock_Mwanza_Tanzania.jpg'),
    ('rubondo-island-national-park', 'rubondo-island', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Рубондо', 'Rubondo Island National Park', 'Рубондо аралы ұлттық паркі', -2.32000000, 31.85000000, 'Rubondo Island National Park Tanzania', ARRAY['rubondo-island']::text[], ARRAY['rubondo-island', 'mwanza']::text[], 'Rubondo_Island_National_Park.jpg'),
    ('kigoma-bay-lake-tanganyika', 'kigoma', 'NATURE', 2, 'HOURS', 4.6, 'Залив Кигома на Lake Tanganyika', 'Lake Tanganyika Kigoma Bay', 'Танганьика көлі Кигома шығанағы', -4.88330000, 29.63330000, 'Lake Tanganyika Kigoma Bay Tanzania', ARRAY['kigoma']::text[], ARRAY['kigoma']::text[], 'Lake_Tanganyika.jpg'),
    ('jakobsens-mwamahunga-beach', 'kigoma', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Jakobsen Mwamahunga', 'Jakobsen Mwamahunga Beach', 'Якобсен Mwamahunga жағажайы', -4.90900000, 29.62300000, 'Jakobsen Mwamahunga Beach Kigoma', ARRAY['kigoma']::text[], ARRAY['kigoma']::text[], 'Lake_Tanganyika.jpg'),
    ('ujiji-livingstone-memorial-museum', 'kigoma', 'MUSEUM', 2, 'HOURS', 4.6, 'Мемориальный музей Ливингстона', 'Dr Livingstone Memorial Museum', 'Ливингстон мемориал музейі', -4.90000000, 29.68330000, 'Dr Livingstone Memorial Museum Ujiji Tanzania', ARRAY['kigoma']::text[], ARRAY['kigoma']::text[], 'Lake_Tanganyika.jpg'),
    ('gombe-stream-national-park', 'gombe', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Гомбе', 'Gombe Stream National Park', 'Гомбе ұлттық паркі', -4.66670000, 29.63330000, 'Gombe Stream National Park Tanzania', ARRAY['gombe']::text[], ARRAY['gombe', 'kigoma']::text[], 'Gombe_Stream_National_Park.jpg'),
    ('gombe-chimpanzee-trekking', 'gombe', 'NATURE', 5, 'HOURS', 4.8, 'Трекинг к шимпанзе в Гомбе', 'Chimpanzee Trekking Gombe', 'Гомбеде шимпанзе трекингі', -4.66670000, 29.63330000, 'Chimpanzee Trekking Gombe Tanzania', ARRAY['gombe']::text[], ARRAY['gombe', 'kigoma']::text[], 'Gombe_Stream_National_Park.jpg'),
    ('mahale-mountains-national-park', 'mahale', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Mahale Mountains', 'Mahale Mountains National Park', 'Махале таулары ұлттық паркі', -6.23330000, 29.91670000, 'Mahale Mountains National Park Tanzania', ARRAY['mahale']::text[], ARRAY['mahale', 'kigoma']::text[], 'Mahale_Mountains_National_Park.jpg'),
    ('mahale-lake-beaches', 'mahale', 'BEACH', 3, 'HOURS', 4.8, 'Пляжи Mahale на Lake Tanganyika', 'Mahale Lake Beaches', 'Махале көл жағажайлары', -6.23330000, 29.91670000, 'Mahale Lake Tanganyika Beaches Tanzania', ARRAY['mahale']::text[], ARRAY['mahale', 'kigoma']::text[], 'Mahale_Mountains_National_Park.jpg'),
    ('livingstones-tembe-kwihara', 'tabora', 'MUSEUM', 2, 'HOURS', 4.5, 'Livingstone Tembe в Kwihara', 'Livingstones Tembe Kwihara Museum', 'Kwihara Livingstone Tembe музейі', -5.01670000, 32.80000000, 'Livingstones Tembe Kwihara Tabora Tanzania', ARRAY['tabora']::text[], ARRAY['tabora']::text[], 'Tabora_Tanzania.jpg'),
    ('tabora-central-market', 'tabora', 'MARKET', 2, 'HOURS', 4.4, 'Центральный рынок Tabora', 'Tabora Central Market', 'Табора орталық базары', -5.01670000, 32.80000000, 'Tabora Central Market Tanzania', ARRAY['tabora']::text[], ARRAY['tabora']::text[], 'Tabora_Tanzania.jpg');

CREATE TEMP TABLE seed_tanzania_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-tanzania-place:' || seed.slug) AS place_hash,
        md5('id-tanzania-media:' || seed.slug) AS media_hash
    FROM seed_tanzania_priority_places seed
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
    ARRAY['tanzania', city_id, slug, lower(category), 'tanzania-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Танзании: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Tanzania tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Танзания туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'TZ',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20000::numeric
        ELSE 10000::numeric
    END,
    'TZS',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_tanzania_resolved_places
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
FROM seed_tanzania_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_tanzania_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_tanzania_resolved_places
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
FROM seed_tanzania_resolved_places seed
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
FROM seed_tanzania_resolved_places
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
    'TZ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_tanzania_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'TZ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_tanzania_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_tanzania_resolved_places;
DROP TABLE IF EXISTS seed_tanzania_priority_places;
