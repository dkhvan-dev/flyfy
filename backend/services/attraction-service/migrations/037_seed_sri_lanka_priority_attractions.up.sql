-- Priority Sri Lanka destination attractions seed.
-- Sri Lanka is seeded as a country destination with concrete city hubs for
-- admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_sri_lanka_resolved_attractions;
DROP TABLE IF EXISTS seed_sri_lanka_priority_attractions;

CREATE TEMP TABLE seed_sri_lanka_priority_attractions (
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

INSERT INTO seed_sri_lanka_priority_attractions (
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
    ('pettah-market', 'colombo', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Петтах', 'Pettah Market', 'Петтах базары', 6.93670000, 79.85000000, 'Pettah Market Colombo Sri Lanka', ARRAY['colombo', 'mount-lavinia', 'negombo']::text[], ARRAY['colombo']::text[], 'Pettah_Market_Colombo.jpg'),
    ('galle-face-green', 'colombo', 'PARK', 2, 'HOURS', 4.6, 'Галле-Фейс-Грин', 'Galle Face Green', 'Галле-Фейс-Грин', 6.92360000, 79.84430000, 'Galle Face Green Colombo Sri Lanka', ARRAY['colombo', 'mount-lavinia']::text[], ARRAY['colombo']::text[], 'Galle_Face_Green.jpg'),
    ('colombo-national-museum', 'colombo', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Коломбо', 'Colombo National Museum', 'Коломбо ұлттық музейі', 6.91060000, 79.86130000, 'Colombo National Museum Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Colombo_National_Museum.jpg'),
    ('gangaramaya-temple', 'colombo', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Гангарамая', 'Gangaramaya Temple', 'Гангарамая ғибадатханасы', 6.91670000, 79.85630000, 'Gangaramaya Temple Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Gangaramaya_Temple_Colombo.jpg'),
    ('seema-malakaya', 'colombo', 'TEMPLE', 1, 'HOURS', 4.5, 'Сима Малакая', 'Seema Malakaya', 'Сима Малакая', 6.91750000, 79.85380000, 'Seema Malakaya Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Seema_Malakaya_Colombo.jpg'),
    ('viharamahadevi-park', 'colombo', 'PARK', 1, 'HOURS', 4.5, 'Парк Вихарамахадеви', 'Viharamahadevi Park', 'Вихарамахадеви паркі', 6.91480000, 79.86190000, 'Viharamahadevi Park Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Viharamahadevi_Park.jpg'),
    ('independence-memorial-hall-colombo', 'colombo', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мемориальный зал Независимости', 'Independence Memorial Hall', 'Тәуелсіздік мемориал залы', 6.90360000, 79.86890000, 'Independence Memorial Hall Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Independence_Memorial_Hall_Colombo.jpg'),
    ('colombo-lotus-tower', 'colombo', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Башня Лотоса', 'Colombo Lotus Tower', 'Коломбо лотос мұнарасы', 6.92710000, 79.85870000, 'Colombo Lotus Tower Sri Lanka', ARRAY['colombo', 'mount-lavinia']::text[], ARRAY['colombo']::text[], 'Colombo_Lotus_Tower.jpg'),
    ('one-galle-face-mall', 'colombo', 'SHOPPING', 3, 'HOURS', 4.5, 'One Galle Face Mall', 'One Galle Face Mall', 'One Galle Face Mall', 6.92780000, 79.84490000, 'One Galle Face Mall Colombo Sri Lanka', ARRAY['colombo', 'mount-lavinia']::text[], ARRAY['colombo']::text[], 'One_Galle_Face_Mall.jpg'),
    ('dutch-hospital-colombo', 'colombo', 'FOOD', 2, 'HOURS', 4.5, 'Голландский госпиталь Коломбо', 'Dutch Hospital Shopping Precinct', 'Коломбо Dutch Hospital', 6.93330000, 79.84490000, 'Dutch Hospital Shopping Precinct Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Dutch_Hospital_Colombo.jpg'),
    ('diyatha-uyana', 'colombo', 'PARK', 2, 'HOURS', 4.5, 'Дията Уяна', 'Diyatha Uyana', 'Дията Уяна', 6.90560000, 79.90810000, 'Diyatha Uyana Colombo Sri Lanka', ARRAY['colombo']::text[], ARRAY['colombo']::text[], 'Diyatha_Uyana.jpg'),
    ('negombo-beach', 'negombo', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Негомбо', 'Negombo Beach', 'Негомбо жағажайы', 7.23500000, 79.84180000, 'Negombo Beach Sri Lanka', ARRAY['negombo', 'colombo']::text[], ARRAY['negombo', 'colombo']::text[], 'Negombo_Beach.jpg'),
    ('negombo-fish-market', 'negombo', 'MARKET', 1, 'HOURS', 4.4, 'Рыбный рынок Негомбо', 'Negombo Fish Market', 'Негомбо балық базары', 7.20930000, 79.83320000, 'Negombo Fish Market Sri Lanka', ARRAY['negombo', 'colombo']::text[], ARRAY['negombo']::text[], 'Negombo_Fish_Market.jpg'),
    ('muthurajawela-marsh', 'negombo', 'NATURE', 3, 'HOURS', 4.6, 'Болота Мутураджавела', 'Muthurajawela Marsh', 'Мутураджавела батпақты аймағы', 7.10470000, 79.85830000, 'Muthurajawela Marsh Sri Lanka', ARRAY['negombo', 'colombo']::text[], ARRAY['negombo', 'colombo']::text[], 'Muthurajawela_Marsh.jpg'),
    ('dutch-canal-negombo', 'negombo', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Голландский канал Негомбо', 'Dutch Canal Negombo', 'Негомбо Dutch Canal', 7.20890000, 79.83670000, 'Dutch Canal Negombo Sri Lanka', ARRAY['negombo']::text[], ARRAY['negombo']::text[], 'Dutch_Canal_Negombo.jpg'),
    ('mount-lavinia-beach', 'mount-lavinia', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Маунт-Лавиния', 'Mount Lavinia Beach', 'Маунт-Лавиния жағажайы', 6.83940000, 79.86320000, 'Mount Lavinia Beach Sri Lanka', ARRAY['mount-lavinia', 'colombo']::text[], ARRAY['mount-lavinia', 'colombo']::text[], 'Mount_Lavinia_Beach.jpg'),
    ('dehiwala-zoological-garden', 'mount-lavinia', 'ENTERTAINMENT', 3, 'HOURS', 4.3, 'Зоопарк Дехивала', 'Dehiwala Zoological Garden', 'Дехивала зоопаркі', 6.85690000, 79.87390000, 'Dehiwala Zoological Garden Sri Lanka', ARRAY['mount-lavinia', 'colombo']::text[], ARRAY['mount-lavinia', 'colombo']::text[], 'Dehiwala_Zoo.jpg'),

    ('sigiriya-rock-fortress', 'sigiriya', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Сигирия', 'Sigiriya Rock Fortress', 'Сигирия жартас қамалы', 7.95700000, 80.76030000, 'Sigiriya Rock Fortress Sri Lanka', ARRAY['sigiriya', 'dambulla', 'kandy', 'anuradhapura', 'polonnaruwa']::text[], ARRAY['sigiriya', 'dambulla', 'kandy', 'colombo']::text[], 'Sigiriya_rock_fortress_Sri_Lanka.jpg'),
    ('sigiriya-museum', 'sigiriya', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей Сигирии', 'Sigiriya Museum', 'Сигирия музейі', 7.95220000, 80.74890000, 'Sigiriya Museum Sri Lanka', ARRAY['sigiriya', 'dambulla']::text[], ARRAY['sigiriya', 'dambulla']::text[], 'Sigiriya_Museum.jpg'),
    ('pidurangala-rock', 'sigiriya', 'NATURE', 3, 'HOURS', 4.8, 'Пидурангала', 'Pidurangala Rock', 'Пидурангала жартасы', 7.96540000, 80.76030000, 'Pidurangala Rock Sri Lanka', ARRAY['sigiriya', 'dambulla']::text[], ARRAY['sigiriya', 'dambulla']::text[], 'Pidurangala_Rock.jpg'),
    ('minneriya-national-park', 'sigiriya', 'NATURE', 4, 'HOURS', 4.8, 'Национальный парк Миннерия', 'Minneriya National Park', 'Миннерия ұлттық паркі', 8.03610000, 80.90170000, 'Minneriya National Park Sri Lanka', ARRAY['sigiriya', 'dambulla', 'polonnaruwa']::text[], ARRAY['sigiriya', 'dambulla']::text[], 'Minneriya_National_Park.jpg'),
    ('kaudulla-national-park', 'sigiriya', 'NATURE', 4, 'HOURS', 4.7, 'Национальный парк Каудулла', 'Kaudulla National Park', 'Каудулла ұлттық паркі', 8.16000000, 80.91830000, 'Kaudulla National Park Sri Lanka', ARRAY['sigiriya', 'dambulla', 'polonnaruwa']::text[], ARRAY['sigiriya', 'dambulla']::text[], 'Kaudulla_National_Park.jpg'),
    ('dambulla-cave-temple', 'dambulla', 'TEMPLE', 3, 'HOURS', 4.9, 'Пещерный храм Дамбуллы', 'Dambulla Cave Temple', 'Дамбулла үңгір ғибадатханасы', 7.85690000, 80.64920000, 'Dambulla Cave Temple Sri Lanka', ARRAY['dambulla', 'sigiriya', 'kandy']::text[], ARRAY['dambulla', 'sigiriya', 'kandy']::text[], 'Dambulla_Cave_Temple.jpg'),
    ('golden-buddha-temple-dambulla', 'dambulla', 'TEMPLE', 1, 'HOURS', 4.5, 'Золотой храм Дамбуллы', 'Golden Buddha Temple Dambulla', 'Дамбулла алтын Будда ғибадатханасы', 7.85640000, 80.64970000, 'Golden Buddha Temple Dambulla Sri Lanka', ARRAY['dambulla', 'sigiriya']::text[], ARRAY['dambulla']::text[], 'Golden_Buddha_Dambulla.jpg'),
    ('dambulla-economic-centre', 'dambulla', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Дамбуллы', 'Dambulla Dedicated Economic Centre', 'Дамбулла орталық базары', 7.87310000, 80.65190000, 'Dambulla Dedicated Economic Centre Sri Lanka', ARRAY['dambulla', 'sigiriya']::text[], ARRAY['dambulla']::text[], 'Dambulla_Economic_Centre.jpg'),
    ('ibbankatuwa-megalithic-tombs', 'dambulla', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Мегалитические гробницы Иббанкатува', 'Ibbankatuwa Megalithic Tombs', 'Иббанкатува мегалит қабірлері', 7.87490000, 80.63180000, 'Ibbankatuwa Megalithic Tombs Sri Lanka', ARRAY['dambulla', 'sigiriya']::text[], ARRAY['dambulla']::text[], 'Ibbankatuwa_Megalithic_Tombs.jpg'),
    ('temple-of-sacred-tooth-relic', 'kandy', 'TEMPLE', 2, 'HOURS', 4.9, 'Храм Зуба Будды', 'Temple of the Sacred Tooth Relic', 'Қасиетті тіс реликвиясы ғибадатханасы', 7.29360000, 80.64130000, 'Temple of the Sacred Tooth Relic Kandy Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy', 'colombo']::text[], 'Temple_of_the_Tooth_Kandy.jpg'),
    ('royal-botanic-gardens-peradeniya', 'kandy', 'PARK', 3, 'HOURS', 4.8, 'Королевский ботанический сад Перадения', 'Royal Botanic Gardens Peradeniya', 'Перадения корольдік ботаникалық бағы', 7.27330000, 80.59670000, 'Royal Botanic Gardens Peradeniya Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Royal_Botanic_Gardens_Peradeniya.jpg'),
    ('kandy-lake', 'kandy', 'PARK', 1, 'HOURS', 4.6, 'Озеро Канди', 'Kandy Lake', 'Канди көлі', 7.29060000, 80.64150000, 'Kandy Lake Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Kandy_Lake.jpg'),
    ('national-museum-of-kandy', 'kandy', 'MUSEUM', 1, 'HOURS', 4.4, 'Национальный музей Канди', 'National Museum of Kandy', 'Канди ұлттық музейі', 7.29310000, 80.64280000, 'National Museum of Kandy Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'National_Museum_of_Kandy.jpg'),
    ('bahirawakanda-buddha-statue', 'kandy', 'TEMPLE', 1, 'HOURS', 4.6, 'Бахираваканда', 'Bahirawakanda Vihara Buddha Statue', 'Бахираваканда Будда мүсіні', 7.29640000, 80.63500000, 'Bahirawakanda Vihara Buddha Statue Kandy', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Bahirawakanda_Buddha_Statue.jpg'),
    ('kandy-market-hall', 'kandy', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Канди', 'Kandy Market Hall', 'Канди базары', 7.29180000, 80.63440000, 'Kandy Market Hall Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Kandy_Market_Hall.jpg'),
    ('kandy-city-centre', 'kandy', 'SHOPPING', 2, 'HOURS', 4.4, 'Kandy City Centre', 'Kandy City Centre', 'Kandy City Centre', 7.29200000, 80.63690000, 'Kandy City Centre Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Kandy_City_Centre.jpg'),
    ('kandyan-cultural-show', 'kandy', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Кандийское культурное шоу', 'Kandyan Cultural Show', 'Канди мәдени шоуы', 7.29270000, 80.64200000, 'Kandyan Cultural Show Kandy Sri Lanka', ARRAY['kandy']::text[], ARRAY['kandy']::text[], 'Kandyan_Cultural_Dance.jpg'),
    ('ancient-city-of-anuradhapura', 'anuradhapura', 'ARCHITECTURE', 5, 'HOURS', 4.9, 'Священный город Анурадхапура', 'Ancient City of Anuradhapura', 'Анурадхапура көне қаласы', 8.34050000, 80.39640000, 'Ancient City of Anuradhapura Sri Lanka', ARRAY['anuradhapura', 'sigiriya', 'dambulla']::text[], ARRAY['anuradhapura', 'sigiriya']::text[], 'Anuradhapura_Ruwanwelisaya.jpg'),
    ('jaya-sri-maha-bodhi', 'anuradhapura', 'TEMPLE', 1, 'HOURS', 4.8, 'Джая Шри Маха Бодхи', 'Jaya Sri Maha Bodhi', 'Джая Шри Маха Бодхи', 8.34460000, 80.39740000, 'Jaya Sri Maha Bodhi Anuradhapura Sri Lanka', ARRAY['anuradhapura']::text[], ARRAY['anuradhapura']::text[], 'Jaya_Sri_Maha_Bodhi.jpg'),
    ('ruwanwelisaya', 'anuradhapura', 'TEMPLE', 1, 'HOURS', 4.9, 'Руванвелисая', 'Ruwanwelisaya', 'Руванвелисая', 8.35000000, 80.39640000, 'Ruwanwelisaya Anuradhapura Sri Lanka', ARRAY['anuradhapura']::text[], ARRAY['anuradhapura']::text[], 'Ruwanwelisaya_Stupa.jpg'),
    ('polonnaruwa-ancient-city', 'polonnaruwa', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Древний город Полоннарува', 'Polonnaruwa Ancient City', 'Полоннарува көне қаласы', 7.94030000, 81.01880000, 'Polonnaruwa Ancient City Sri Lanka', ARRAY['polonnaruwa', 'sigiriya', 'dambulla']::text[], ARRAY['polonnaruwa', 'sigiriya']::text[], 'Polonnaruwa_Ancient_City.jpg'),
    ('gal-vihara', 'polonnaruwa', 'TEMPLE', 1, 'HOURS', 4.8, 'Гал Вихара', 'Gal Vihara', 'Гал Вихара', 7.96570000, 81.00420000, 'Gal Vihara Polonnaruwa Sri Lanka', ARRAY['polonnaruwa']::text[], ARRAY['polonnaruwa']::text[], 'Gal_Vihara_Polonnaruwa.jpg'),

    ('galle-fort', 'galle', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Форт Галле', 'Galle Fort', 'Галле қамалы', 6.02500000, 80.21670000, 'Galle Fort Sri Lanka', ARRAY['galle', 'unawatuna', 'hikkaduwa']::text[], ARRAY['galle', 'colombo']::text[], 'Galle_Fort_Sri_Lanka.jpg'),
    ('galle-lighthouse', 'galle', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Маяк Галле', 'Galle Lighthouse', 'Галле маягы', 6.02420000, 80.21920000, 'Galle Lighthouse Sri Lanka', ARRAY['galle', 'unawatuna']::text[], ARRAY['galle']::text[], 'Galle_Lighthouse.jpg'),
    ('national-maritime-museum-galle', 'galle', 'MUSEUM', 1, 'HOURS', 4.5, 'Национальный морской музей Галле', 'National Maritime Museum Galle', 'Галле ұлттық теңіз музейі', 6.02670000, 80.21650000, 'National Maritime Museum Galle Sri Lanka', ARRAY['galle']::text[], ARRAY['galle']::text[], 'National_Maritime_Museum_Galle.jpg'),
    ('dutch-reformed-church-galle', 'galle', 'TEMPLE', 1, 'HOURS', 4.5, 'Голландская реформатская церковь', 'Dutch Reformed Church Galle', 'Галле Dutch Reformed Church', 6.02630000, 80.21600000, 'Dutch Reformed Church Galle Sri Lanka', ARRAY['galle']::text[], ARRAY['galle']::text[], 'Dutch_Reformed_Church_Galle.jpg'),
    ('dutch-hospital-galle', 'galle', 'SHOPPING', 2, 'HOURS', 4.5, 'Dutch Hospital Galle', 'Dutch Hospital Galle', 'Dutch Hospital Galle', 6.02420000, 80.21970000, 'Dutch Hospital Galle Sri Lanka', ARRAY['galle']::text[], ARRAY['galle']::text[], 'Dutch_Hospital_Galle.jpg'),
    ('old-dutch-market-galle', 'galle', 'MARKET', 1, 'HOURS', 4.4, 'Старый голландский рынок Галле', 'Old Dutch Market Galle', 'Галле ескі Dutch базары', 6.03390000, 80.21720000, 'Old Dutch Market Galle Sri Lanka', ARRAY['galle']::text[], ARRAY['galle']::text[], 'Old_Dutch_Market_Galle.jpg'),
    ('unawatuna-beach', 'unawatuna', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Унаватуна', 'Unawatuna Beach', 'Унаватуна жағажайы', 6.01080000, 80.24850000, 'Unawatuna Beach Sri Lanka', ARRAY['unawatuna', 'galle']::text[], ARRAY['unawatuna', 'galle']::text[], 'Unawatuna_Beach.jpg'),
    ('japanese-peace-pagoda-unawatuna', 'unawatuna', 'TEMPLE', 1, 'HOURS', 4.6, 'Японская пагода мира', 'Japanese Peace Pagoda Unawatuna', 'Унаватуна бейбітшілік пагодасы', 6.02150000, 80.23860000, 'Japanese Peace Pagoda Unawatuna Sri Lanka', ARRAY['unawatuna', 'galle']::text[], ARRAY['unawatuna', 'galle']::text[], 'Japanese_Peace_Pagoda_Unawatuna.jpg'),
    ('rumassala-sanctuary', 'unawatuna', 'NATURE', 2, 'HOURS', 4.6, 'Румассала', 'Rumassala Sanctuary', 'Румассала табиғи аймағы', 6.02110000, 80.24270000, 'Rumassala Sanctuary Unawatuna Sri Lanka', ARRAY['unawatuna', 'galle']::text[], ARRAY['unawatuna']::text[], 'Rumassala_Unawatuna.jpg'),
    ('dalawella-beach', 'unawatuna', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Далавелла', 'Dalawella Beach', 'Далавелла жағажайы', 5.99990000, 80.26520000, 'Dalawella Beach Sri Lanka', ARRAY['unawatuna', 'galle']::text[], ARRAY['unawatuna']::text[], 'Dalawella_Beach.jpg'),
    ('mirissa-beach', 'mirissa', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Мирисса', 'Mirissa Beach', 'Мирисса жағажайы', 5.94470000, 80.45830000, 'Mirissa Beach Sri Lanka', ARRAY['mirissa', 'galle']::text[], ARRAY['mirissa', 'galle']::text[], 'Mirissa_Beach.jpg'),
    ('coconut-tree-hill', 'mirissa', 'NATURE', 1, 'HOURS', 4.6, 'Coconut Tree Hill', 'Coconut Tree Hill', 'Coconut Tree Hill', 5.94670000, 80.47170000, 'Coconut Tree Hill Mirissa Sri Lanka', ARRAY['mirissa']::text[], ARRAY['mirissa']::text[], 'Coconut_Tree_Hill_Mirissa.jpg'),
    ('mirissa-whale-watching', 'mirissa', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Наблюдение за китами в Мириссе', 'Whale Watching in Mirissa', 'Мирисса кит бақылауы', 5.94830000, 80.45660000, 'Whale Watching Mirissa Sri Lanka', ARRAY['mirissa', 'galle']::text[], ARRAY['mirissa']::text[], 'Whale_Watching_Mirissa.jpg'),
    ('secret-beach-mirissa', 'mirissa', 'BEACH', 2, 'HOURS', 4.6, 'Secret Beach Mirissa', 'Secret Beach Mirissa', 'Secret Beach Mirissa', 5.94130000, 80.45200000, 'Secret Beach Mirissa Sri Lanka', ARRAY['mirissa']::text[], ARRAY['mirissa']::text[], 'Secret_Beach_Mirissa.jpg'),
    ('bentota-beach', 'bentota', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Бентота', 'Bentota Beach', 'Бентота жағажайы', 6.42150000, 79.99680000, 'Bentota Beach Sri Lanka', ARRAY['bentota', 'hikkaduwa', 'galle']::text[], ARRAY['bentota', 'colombo']::text[], 'Bentota_Beach.jpg'),
    ('bentota-river', 'bentota', 'NATURE', 2, 'HOURS', 4.5, 'Река Бентота', 'Bentota River', 'Бентота өзені', 6.42480000, 80.00070000, 'Bentota River Sri Lanka', ARRAY['bentota']::text[], ARRAY['bentota']::text[], 'Bentota_River.jpg'),
    ('lunuganga-estate', 'bentota', 'PARK', 2, 'HOURS', 4.7, 'Lunuganga Estate', 'Lunuganga Estate', 'Lunuganga Estate', 6.44040000, 80.00980000, 'Lunuganga Estate Bentota Sri Lanka', ARRAY['bentota']::text[], ARRAY['bentota']::text[], 'Lunuganga_Estate.jpg'),
    ('brief-garden', 'bentota', 'PARK', 2, 'HOURS', 4.6, 'Brief Garden', 'Brief Garden', 'Brief Garden', 6.37170000, 80.03030000, 'Brief Garden Bentota Sri Lanka', ARRAY['bentota']::text[], ARRAY['bentota']::text[], 'Brief_Garden_Bentota.jpg'),
    ('madu-ganga-river-safari', 'bentota', 'NATURE', 3, 'HOURS', 4.6, 'Сафари по реке Маду Ганга', 'Madu Ganga River Safari', 'Маду Ганга өзені сафариі', 6.28710000, 80.04460000, 'Madu Ganga River Safari Sri Lanka', ARRAY['bentota', 'hikkaduwa']::text[], ARRAY['bentota']::text[], 'Madu_Ganga_River.jpg'),
    ('kosgoda-turtle-conservation', 'bentota', 'NATURE', 1, 'HOURS', 4.4, 'Центр морских черепах Косгода', 'Kosgoda Sea Turtle Conservation', 'Косгода теңіз тасбақалары орталығы', 6.33830000, 80.03060000, 'Kosgoda Sea Turtle Conservation Sri Lanka', ARRAY['bentota', 'hikkaduwa']::text[], ARRAY['bentota']::text[], 'Kosgoda_Turtle_Hatchery.jpg'),
    ('hikkaduwa-beach', 'hikkaduwa', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Хиккадува', 'Hikkaduwa Beach', 'Хиккадува жағажайы', 6.13950000, 80.09930000, 'Hikkaduwa Beach Sri Lanka', ARRAY['hikkaduwa', 'galle']::text[], ARRAY['hikkaduwa', 'galle']::text[], 'Hikkaduwa_Beach.jpg'),
    ('hikkaduwa-coral-sanctuary', 'hikkaduwa', 'NATURE', 2, 'HOURS', 4.6, 'Коралловый заповедник Хиккадува', 'Hikkaduwa Coral Sanctuary', 'Хиккадува маржан қорығы', 6.13810000, 80.09970000, 'Hikkaduwa Coral Sanctuary Sri Lanka', ARRAY['hikkaduwa']::text[], ARRAY['hikkaduwa']::text[], 'Hikkaduwa_Coral_Sanctuary.jpg'),
    ('hikkaduwa-diving-wrecks', 'hikkaduwa', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Дайвинг и рэки Хиккадувы', 'Hikkaduwa Diving and Wrecks', 'Хиккадува дайвингі', 6.13430000, 80.10140000, 'Hikkaduwa Diving Wrecks Sri Lanka', ARRAY['hikkaduwa']::text[], ARRAY['hikkaduwa']::text[], 'Hikkaduwa_Diving.jpg'),

    ('nine-arches-bridge', 'ella', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Мост Девяти Ар', 'Nine Arches Bridge', 'Тоғыз арка көпірі', 6.87680000, 81.06080000, 'Nine Arches Bridge Ella Sri Lanka', ARRAY['ella', 'haputale', 'nuwara-eliya']::text[], ARRAY['ella', 'kandy']::text[], 'Nine_Arches_Bridge_Ella.jpg'),
    ('little-adams-peak', 'ella', 'NATURE', 2, 'HOURS', 4.8, 'Малый пик Адама', $$Little Adam's Peak$$, 'Кіші Адам шыңы', 6.87580000, 81.06660000, 'Little Adams Peak Ella Sri Lanka', ARRAY['ella']::text[], ARRAY['ella']::text[], 'Little_Adams_Peak_Ella.jpg'),
    ('ella-rock', 'ella', 'NATURE', 4, 'HOURS', 4.8, 'Элла-Рок', 'Ella Rock', 'Элла жартасы', 6.85760000, 81.04750000, 'Ella Rock Sri Lanka', ARRAY['ella', 'haputale']::text[], ARRAY['ella']::text[], 'Ella_Rock.jpg'),
    ('ravana-falls', 'ella', 'NATURE', 1, 'HOURS', 4.6, 'Водопад Равана', 'Ravana Falls', 'Равана сарқырамасы', 6.83990000, 81.05550000, 'Ravana Falls Sri Lanka', ARRAY['ella']::text[], ARRAY['ella']::text[], 'Ravana_Falls.jpg'),
    ('uva-halpewatte-tea-factory', 'ella', 'FOOD', 2, 'HOURS', 4.6, 'Чайная фабрика Uva Halpewatte', 'Uva Halpewatte Tea Factory', 'Uva Halpewatte шай фабрикасы', 6.89150000, 81.04460000, 'Uva Halpewatte Tea Factory Ella Sri Lanka', ARRAY['ella']::text[], ARRAY['ella']::text[], 'Uva_Halpewatte_Tea_Factory.jpg'),
    ('flying-ravana-zipline', 'ella', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Flying Ravana Zipline', 'Flying Ravana Zipline', 'Flying Ravana Zipline', 6.87440000, 81.06630000, 'Flying Ravana Zipline Ella Sri Lanka', ARRAY['ella']::text[], ARRAY['ella']::text[], 'Flying_Ravana_Zipline.jpg'),
    ('dowa-rock-temple', 'ella', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Дова', 'Dowa Rock Temple', 'Дова жартас ғибадатханасы', 6.83570000, 81.00870000, 'Dowa Rock Temple Sri Lanka', ARRAY['ella', 'haputale']::text[], ARRAY['ella']::text[], 'Dowa_Rock_Temple.jpg'),
    ('horton-plains-worlds-end', 'nuwara-eliya', 'PARK', 5, 'HOURS', 4.8, 'Horton Plains и Worlds End', $$Horton Plains and World's End$$, 'Horton Plains және Worlds End', 6.80210000, 80.80730000, 'Horton Plains National Park Sri Lanka', ARRAY['nuwara-eliya', 'haputale']::text[], ARRAY['nuwara-eliya', 'ella']::text[], 'Horton_Plains_National_Park.jpg'),
    ('gregory-lake', 'nuwara-eliya', 'PARK', 2, 'HOURS', 4.5, 'Озеро Грегори', 'Gregory Lake', 'Грегори көлі', 6.95850000, 80.78290000, 'Gregory Lake Nuwara Eliya Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Gregory_Lake_Nuwara_Eliya.jpg'),
    ('nuwara-eliya-tea-country', 'nuwara-eliya', 'NATURE', 3, 'HOURS', 4.7, 'Чайная страна Нувара-Элии', 'Nuwara Eliya Tea Country', 'Нувара-Элия шай өлкесі', 6.97000000, 80.78500000, 'Nuwara Eliya Tea Country Sri Lanka', ARRAY['nuwara-eliya', 'ella', 'haputale']::text[], ARRAY['nuwara-eliya', 'kandy']::text[], 'Nuwara_Eliya_Tea_Country.jpg'),
    ('pedro-tea-estate', 'nuwara-eliya', 'FOOD', 2, 'HOURS', 4.6, 'Чайная плантация Pedro', 'Pedro Tea Estate', 'Pedro шай плантациясы', 6.96670000, 80.81390000, 'Pedro Tea Estate Nuwara Eliya Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Pedro_Tea_Estate.jpg'),
    ('hakgala-botanical-garden', 'nuwara-eliya', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Хакгала', 'Hakgala Botanical Garden', 'Хакгала ботаникалық бағы', 6.92670000, 80.81940000, 'Hakgala Botanical Garden Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Hakgala_Botanical_Garden.jpg'),
    ('victoria-park-nuwara-eliya', 'nuwara-eliya', 'PARK', 1, 'HOURS', 4.4, 'Парк Виктория', 'Victoria Park Nuwara Eliya', 'Виктория паркі', 6.97080000, 80.76670000, 'Victoria Park Nuwara Eliya Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Victoria_Park_Nuwara_Eliya.jpg'),
    ('seetha-amman-temple', 'nuwara-eliya', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Сита Амман', 'Seetha Amman Temple', 'Сита Амман ғибадатханасы', 6.92960000, 80.81090000, 'Seetha Amman Temple Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Seetha_Amman_Temple.jpg'),
    ('nuwara-eliya-central-market', 'nuwara-eliya', 'MARKET', 1, 'HOURS', 4.3, 'Центральный рынок Нувара-Элии', 'Nuwara Eliya Central Market', 'Нувара-Элия орталық базары', 6.97190000, 80.76720000, 'Nuwara Eliya Central Market Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Nuwara_Eliya_Market.jpg'),
    ('bale-bazaar-nuwara-eliya', 'nuwara-eliya', 'SHOPPING', 1, 'HOURS', 4.3, 'Bale Bazaar', 'Bale Bazaar Nuwara Eliya', 'Bale Bazaar', 6.97100000, 80.76620000, 'Bale Bazaar Nuwara Eliya Sri Lanka', ARRAY['nuwara-eliya']::text[], ARRAY['nuwara-eliya']::text[], 'Nuwara_Eliya_Bale_Bazaar.jpg'),
    ('liptons-seat', 'haputale', 'NATURE', 3, 'HOURS', 4.8, 'Liptons Seat', $$Lipton's Seat$$, 'Липтон көрініс алаңы', 6.78190000, 81.04370000, 'Liptons Seat Haputale Sri Lanka', ARRAY['haputale', 'ella', 'nuwara-eliya']::text[], ARRAY['haputale', 'ella']::text[], 'Liptons_Seat_Sri_Lanka.jpg'),
    ('dambatenne-tea-factory', 'haputale', 'FOOD', 2, 'HOURS', 4.5, 'Чайная фабрика Dambatenne', 'Dambatenne Tea Factory', 'Dambatenne шай фабрикасы', 6.78130000, 81.01250000, 'Dambatenne Tea Factory Sri Lanka', ARRAY['haputale']::text[], ARRAY['haputale']::text[], 'Dambatenne_Tea_Factory.jpg'),
    ('diyaluma-falls', 'haputale', 'NATURE', 3, 'HOURS', 4.7, 'Водопад Диялума', 'Diyaluma Falls', 'Диялума сарқырамасы', 6.73400000, 81.03190000, 'Diyaluma Falls Sri Lanka', ARRAY['haputale', 'ella']::text[], ARRAY['haputale', 'ella']::text[], 'Diyaluma_Falls.jpg'),
    ('bambarakanda-falls', 'haputale', 'NATURE', 3, 'HOURS', 4.7, 'Водопад Бамбараканда', 'Bambarakanda Falls', 'Бамбараканда сарқырамасы', 6.77340000, 80.83130000, 'Bambarakanda Falls Sri Lanka', ARRAY['haputale', 'nuwara-eliya']::text[], ARRAY['haputale']::text[], 'Bambarakanda_Falls.jpg'),
    ('sri-pada-adams-peak', 'adams-peak', 'TEMPLE', 5, 'HOURS', 4.9, 'Шри-Пада / Пик Адама', $$Adam's Peak / Sri Pada$$, 'Шри-Пада / Адам шыңы', 6.80960000, 80.49940000, 'Sri Pada Adams Peak Sri Lanka', ARRAY['adams-peak', 'nuwara-eliya', 'kandy']::text[], ARRAY['adams-peak', 'kandy']::text[], 'Sri_Pada_Adams_Peak.jpg'),

    ('fort-frederick-trincomalee', 'trincomalee', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Форт Фредерик', 'Fort Frederick', 'Фредерик қамалы', 8.57770000, 81.24460000, 'Fort Frederick Trincomalee Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Fort_Frederick_Trincomalee.jpg'),
    ('koneswaram-kovil', 'trincomalee', 'TEMPLE', 1, 'HOURS', 4.8, 'Храм Конешварам', 'Koneswaram Kovil', 'Конешварам ғибадатханасы', 8.58180000, 81.24520000, 'Koneswaram Kovil Trincomalee Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Koneswaram_Temple_Trincomalee.jpg'),
    ('nilaveli-beach', 'trincomalee', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Нилавели', 'Nilaveli Beach', 'Нилавели жағажайы', 8.68420000, 81.19100000, 'Nilaveli Beach Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Nilaveli_Beach.jpg'),
    ('uppuveli-beach', 'trincomalee', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Уппувели', 'Uppuveli Beach', 'Уппувели жағажайы', 8.60660000, 81.21930000, 'Uppuveli Beach Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Uppuveli_Beach.jpg'),
    ('pigeon-island-national-park', 'trincomalee', 'NATURE', 4, 'HOURS', 4.8, 'Национальный парк Pigeon Island', 'Pigeon Island National Park', 'Pigeon Island ұлттық паркі', 8.72000000, 81.20360000, 'Pigeon Island National Park Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Pigeon_Island_National_Park.jpg'),
    ('kanniya-hot-springs', 'trincomalee', 'NATURE', 1, 'HOURS', 4.3, 'Горячие источники Канния', 'Kanniya Hot Springs', 'Канния ыстық бұлақтары', 8.60490000, 81.16560000, 'Kanniya Hot Springs Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Kanniya_Hot_Springs.jpg'),
    ('trincomalee-maritime-naval-museum', 'trincomalee', 'MUSEUM', 1, 'HOURS', 4.4, 'Морской и военно-морской музей Тринкомали', 'Maritime and Naval History Museum Trincomalee', 'Тринкомали теңіз музейі', 8.57260000, 81.23690000, 'Maritime and Naval History Museum Trincomalee Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Trincomalee_Maritime_Museum.jpg'),
    ('trincomalee-whale-watching', 'trincomalee', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Наблюдение за китами в Тринкомали', 'Trincomalee Whale Watching', 'Тринкомали кит бақылауы', 8.58580000, 81.23310000, 'Trincomalee Whale Watching Sri Lanka', ARRAY['trincomalee']::text[], ARRAY['trincomalee']::text[], 'Trincomalee_Whale_Watching.jpg'),
    ('arugam-bay', 'arugam-bay', 'BEACH', 3, 'HOURS', 4.8, 'Аругам-Бей', 'Arugam Bay', 'Аругам-Бей', 6.84040000, 81.83680000, 'Arugam Bay Sri Lanka', ARRAY['arugam-bay']::text[], ARRAY['arugam-bay']::text[], 'Arugam_Bay.jpg'),
    ('whiskey-point-arugam-bay', 'arugam-bay', 'BEACH', 2, 'HOURS', 4.6, 'Whiskey Point', 'Whiskey Point', 'Whiskey Point', 6.91710000, 81.84920000, 'Whiskey Point Arugam Bay Sri Lanka', ARRAY['arugam-bay']::text[], ARRAY['arugam-bay']::text[], 'Whiskey_Point_Arugam_Bay.jpg'),
    ('pottuvil-lagoon', 'arugam-bay', 'NATURE', 2, 'HOURS', 4.6, 'Лагуна Поттувил', 'Pottuvil Lagoon', 'Поттувил лагунасы', 6.87730000, 81.83640000, 'Pottuvil Lagoon Sri Lanka', ARRAY['arugam-bay']::text[], ARRAY['arugam-bay']::text[], 'Pottuvil_Lagoon.jpg'),
    ('muhudu-maha-viharaya', 'arugam-bay', 'TEMPLE', 1, 'HOURS', 4.4, 'Мухуду Маха Вихарая', 'Muhudu Maha Viharaya', 'Мухуду Маха Вихарая', 6.87860000, 81.82910000, 'Muhudu Maha Viharaya Sri Lanka', ARRAY['arugam-bay']::text[], ARRAY['arugam-bay']::text[], 'Muhudu_Maha_Viharaya.jpg'),
    ('kumana-national-park', 'arugam-bay', 'PARK', 5, 'HOURS', 4.7, 'Национальный парк Кумана', 'Kumana National Park', 'Кумана ұлттық паркі', 6.53000000, 81.67000000, 'Kumana National Park Sri Lanka', ARRAY['arugam-bay', 'yala']::text[], ARRAY['arugam-bay']::text[], 'Kumana_National_Park.jpg'),
    ('jaffna-fort', 'jaffna', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Форт Джафны', 'Jaffna Fort', 'Джафна қамалы', 9.66260000, 80.00910000, 'Jaffna Fort Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Jaffna_Fort.jpg'),
    ('nallur-kandaswamy-kovil', 'jaffna', 'TEMPLE', 1, 'HOURS', 4.8, 'Храм Наллур Кандасвами', 'Nallur Kandaswamy Kovil', 'Наллур Кандасвами ғибадатханасы', 9.67490000, 80.02930000, 'Nallur Kandaswamy Kovil Jaffna Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Nallur_Kandaswamy_Kovil.jpg'),
    ('jaffna-public-library', 'jaffna', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Публичная библиотека Джафны', 'Jaffna Public Library', 'Джафна қоғамдық кітапханасы', 9.66280000, 80.01130000, 'Jaffna Public Library Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Jaffna_Public_Library.jpg'),
    ('jaffna-market', 'jaffna', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Джафны', 'Jaffna Market', 'Джафна базары', 9.66470000, 80.02010000, 'Jaffna Market Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Jaffna_Market.jpg'),
    ('cargills-square-jaffna', 'jaffna', 'SHOPPING', 2, 'HOURS', 4.4, 'Cargills Square Jaffna', 'Cargills Square Jaffna', 'Cargills Square Jaffna', 9.66390000, 80.01580000, 'Cargills Square Jaffna Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Cargills_Square_Jaffna.jpg'),
    ('casuarina-beach', 'jaffna', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Казуарина', 'Casuarina Beach', 'Казуарина жағажайы', 9.75130000, 79.92530000, 'Casuarina Beach Jaffna Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Casuarina_Beach_Jaffna.jpg'),
    ('delft-island', 'jaffna', 'NATURE', 5, 'HOURS', 4.6, 'Остров Делфт', 'Delft Island', 'Делфт аралы', 9.51520000, 79.70250000, 'Delft Island Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Delft_Island_Sri_Lanka.jpg'),
    ('jaffna-archaeological-museum', 'jaffna', 'MUSEUM', 1, 'HOURS', 4.3, 'Археологический музей Джафны', 'Jaffna Archaeological Museum', 'Джафна археологиялық музейі', 9.67400000, 80.02590000, 'Jaffna Archaeological Museum Sri Lanka', ARRAY['jaffna']::text[], ARRAY['jaffna']::text[], 'Jaffna_Archaeological_Museum.jpg'),
    ('yala-national-park', 'yala', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Яла', 'Yala National Park', 'Яла ұлттық паркі', 6.37250000, 81.51850000, 'Yala National Park Sri Lanka', ARRAY['yala', 'arugam-bay']::text[], ARRAY['yala', 'colombo']::text[], 'Yala_National_Park_Sri_Lanka.jpg'),
    ('udawalawe-national-park', 'udawalawe', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Удавалаве', 'Udawalawe National Park', 'Удавалаве ұлттық паркі', 6.47590000, 80.88870000, 'Udawalawe National Park Sri Lanka', ARRAY['udawalawe', 'ella', 'mirissa']::text[], ARRAY['udawalawe', 'ella']::text[], 'Udawalawe_National_Park.jpg'),
    ('wilpattu-national-park', 'wilpattu', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Вилпатту', 'Wilpattu National Park', 'Вилпатту ұлттық паркі', 8.44500000, 80.05000000, 'Wilpattu National Park Sri Lanka', ARRAY['wilpattu', 'anuradhapura']::text[], ARRAY['wilpattu', 'anuradhapura']::text[], 'Wilpattu_National_Park.jpg');

CREATE TEMP TABLE seed_sri_lanka_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-sri-lanka-attraction:' || seed.slug) AS attraction_hash,
        md5('id-sri-lanka-media:' || seed.slug) AS media_hash
    FROM seed_sri_lanka_priority_attractions seed
)
SELECT
    (
        substr(attraction_hash, 1, 8) || '-' ||
        substr(attraction_hash, 9, 4) || '-4' ||
        substr(attraction_hash, 14, 3) || '-8' ||
        substr(attraction_hash, 18, 3) || '-' ||
        substr(attraction_hash, 21, 12)
    )::uuid AS id,
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    ARRAY['sri-lanka', city_id, slug, lower(category), 'sri-lanka-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Шри-Ланки: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Sri Lanka tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Шри-Ланка туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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

INSERT INTO attractions (
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
    'LK',
    city_id,
    category,
    NULL::numeric,
    'LKR',
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
FROM seed_sri_lanka_resolved_attractions
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

INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT id, 'ru', title_ru, description_ru, NOW(), NOW()
FROM seed_sri_lanka_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_sri_lanka_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_sri_lanka_resolved_attractions
ON CONFLICT (attraction_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE attractions a
SET
    latitude = seed.latitude,
    longitude = seed.longitude,
    location_source_url = seed.location_source_url,
    updated_at = NOW()
FROM seed_sri_lanka_resolved_attractions seed
WHERE a.id = seed.id;

INSERT INTO attraction_media (
    id,
    attraction_id,
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
FROM seed_sri_lanka_resolved_attractions
ON CONFLICT (id) DO UPDATE SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO attraction_city_links (
    id,
    attraction_id,
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
    'LK',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_sri_lanka_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'LK',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_sri_lanka_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_sri_lanka_resolved_attractions;
DROP TABLE IF EXISTS seed_sri_lanka_priority_attractions;
