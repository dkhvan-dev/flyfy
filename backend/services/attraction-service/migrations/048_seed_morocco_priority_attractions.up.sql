-- Priority Morocco destination attractions seed.
-- The seed keeps tourist hubs explicit for admin filters and localized mobile discovery.

DROP TABLE IF EXISTS seed_morocco_resolved_attractions;
DROP TABLE IF EXISTS seed_morocco_priority_attractions;

CREATE TEMP TABLE seed_morocco_priority_attractions (
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

INSERT INTO seed_morocco_priority_attractions (
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
    ('hassan-ii-mosque', 'casablanca', 'TEMPLE', 2, 'HOURS', 4.9, 'Мечеть Хасана II', 'Hassan II Mosque', 'Хасан II мешіті', 33.60840000, -7.63260000, 'Hassan II Mosque Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('la-corniche-ain-diab', 'casablanca', 'BEACH', 2, 'HOURS', 4.6, 'Корниш и Айн-Диаб', 'La Corniche and Ain Diab', 'Корниш және Айн-Диаб', 33.58980000, -7.67490000, 'La Corniche Ain Diab Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('quartier-habous', 'casablanca', 'MARKET', 2, 'HOURS', 4.6, 'Квартал Хабус', 'Quartier Habous', 'Хабус кварталы', 33.57320000, -7.60110000, 'Quartier Habous Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('marche-central-casablanca', 'casablanca', 'MARKET', 2, 'HOURS', 4.5, 'Центральный рынок Касабланки', 'Marche Central', 'Касабланка орталық базары', 33.59550000, -7.61370000, 'Marche Central Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('arab-league-park', 'casablanca', 'PARK', 1, 'HOURS', 4.5, 'Парк Лиги арабских государств', 'Arab League Park', 'Араб мемлекеттері лигасы саябағы', 33.58970000, -7.62370000, 'Arab League Park Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('morocco-mall', 'casablanca', 'SHOPPING', 3, 'HOURS', 4.5, 'Morocco Mall', 'Morocco Mall', 'Morocco Mall', 33.57500000, -7.70600000, 'Morocco Mall Casablanca', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('parc-sindibad', 'casablanca', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Парк Синдибад', 'Parc Sindibad', 'Синдибад саябағы', 33.57100000, -7.68600000, 'Parc Sindibad Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),
    ('villa-des-arts-casablanca', 'casablanca', 'MUSEUM', 2, 'HOURS', 4.5, 'Вилла искусств Касабланки', 'Villa des Arts Casablanca', 'Касабланка өнер вилласы', 33.59080000, -7.63060000, 'Villa des Arts Casablanca Morocco', ARRAY['casablanca']::text[], ARRAY['casablanca']::text[], 'Hassan_II_Mosque_Plaza.jpg'),

    ('hassan-tower-mausoleum', 'rabat', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Башня Хасана и мавзолей Мухаммеда V', 'Hassan Tower and Mohammed V Mausoleum', 'Хасан мұнарасы және Мұхаммед V кесенесі', 34.02410000, -6.82240000, 'Hassan Tower Mohammed V Mausoleum Rabat Morocco', ARRAY['rabat']::text[], ARRAY['rabat', 'casablanca']::text[], 'Hassan_Tower_01.jpg'),
    ('kasbah-oudayas', 'rabat', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Касба Удайя', 'Kasbah of the Oudayas', 'Удайя қамалы', 34.03190000, -6.83620000, 'Kasbah of the Oudayas Rabat Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('chellah', 'rabat', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Археологический комплекс Шелла', 'Chellah Archaeological Site', 'Шелла археологиялық кешені', 34.00670000, -6.82000000, 'Chellah Rabat Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('rabat-medina', 'rabat', 'MARKET', 2, 'HOURS', 4.6, 'Медина Рабата', 'Rabat Medina', 'Рабат мединасы', 34.02540000, -6.83600000, 'Rabat Medina Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('mohammed-vi-museum', 'rabat', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей современного искусства Мухаммеда VI', 'Mohammed VI Museum of Modern and Contemporary Art', 'Мұхаммед VI заманауи өнер музейі', 34.01430000, -6.83240000, 'Mohammed VI Museum Rabat Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('mega-mall-rabat', 'rabat', 'SHOPPING', 2, 'HOURS', 4.2, 'Mega Mall Рабат', 'Mega Mall Rabat', 'Mega Mall Рабат', 33.97600000, -6.85000000, 'Mega Mall Rabat Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('rabat-zoo', 'rabat', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Зоопарк Рабата', 'Rabat Zoo', 'Рабат хайуанаттар бағы', 33.95400000, -6.89700000, 'Rabat Zoo Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),
    ('rabat-beach', 'rabat', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Рабата', 'Rabat Beach', 'Рабат жағажайы', 34.03050000, -6.84090000, 'Rabat Beach Morocco', ARRAY['rabat']::text[], ARRAY['rabat']::text[], 'Hassan_Tower_01.jpg'),

    ('tangier-medina-grand-socco', 'tangier', 'MARKET', 3, 'HOURS', 4.7, 'Медина Танжера и Гранд-Сокко', 'Tangier Medina and Grand Socco', 'Танжер мединасы және Гранд-Сокко', 35.78470000, -5.81260000, 'Grand Socco Tangier Medina Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('kasbah-museum-tangier', 'tangier', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Касбы Танжера', 'Kasbah Museum', 'Танжер касба музейі', 35.78950000, -5.81200000, 'Kasbah Museum Tangier Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('tangier-american-legation', 'tangier', 'MUSEUM', 2, 'HOURS', 4.6, 'Американская легация в Танжере', 'Tangier American Legation', 'Танжер американдық легациясы', 35.78590000, -5.81000000, 'Tangier American Legation Museum Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('cap-spartel', 'tangier', 'NATURE', 2, 'HOURS', 4.7, 'Мыс Спартель', 'Cap Spartel', 'Спартель мүйісі', 35.79260000, -5.92230000, 'Cap Spartel Tangier Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('hercules-caves', 'tangier', 'NATURE', 2, 'HOURS', 4.5, 'Пещеры Геркулеса', 'Hercules Caves', 'Геркулес үңгірлері', 35.75910000, -5.93970000, 'Caves of Hercules Tangier Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('tangier-beach', 'tangier', 'BEACH', 2, 'HOURS', 4.4, 'Городской пляж Танжера', 'Tangier Beach', 'Танжер қалалық жағажайы', 35.77590000, -5.79040000, 'Tangier Municipal Beach Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('perdicaris-park', 'tangier', 'PARK', 2, 'HOURS', 4.6, 'Парк Пердикарис', 'Perdicaris Park', 'Пердикарис саябағы', 35.77980000, -5.88950000, 'Perdicaris Park Tangier Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('socco-alto-mall', 'tangier', 'SHOPPING', 2, 'HOURS', 4.3, 'Socco Alto Mall', 'Socco Alto Mall', 'Socco Alto Mall', 35.75960000, -5.82280000, 'Socco Alto Mall Tangier Morocco', ARRAY['tangier']::text[], ARRAY['tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),

    ('chefchaouen-medina', 'chefchaouen', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Медина Шефшауэна', 'Chefchaouen Medina', 'Шефшауэн мединасы', 35.16880000, -5.26360000, 'Chefchaouen Medina Morocco', ARRAY['chefchaouen']::text[], ARRAY['chefchaouen', 'tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('chefchaouen-kasbah-museum', 'chefchaouen', 'MUSEUM', 1, 'HOURS', 4.5, 'Касба и этнографический музей Шефшауэна', 'Kasbah and Ethnographic Museum', 'Шефшауэн касба және этнография музейі', 35.16870000, -5.26330000, 'Chefchaouen Kasbah Ethnographic Museum Morocco', ARRAY['chefchaouen']::text[], ARRAY['chefchaouen']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('plaza-uta-el-hammam', 'chefchaouen', 'FOOD', 1, 'HOURS', 4.6, 'Площадь Ута-эль-Хаммам', 'Plaza Uta el-Hammam', 'Ута-эль-Хаммам алаңы', 35.16880000, -5.26340000, 'Plaza Uta el Hammam Chefchaouen Morocco', ARRAY['chefchaouen']::text[], ARRAY['chefchaouen']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('ras-el-maa-waterfall', 'chefchaouen', 'NATURE', 1, 'HOURS', 4.6, 'Водопад Рас-эль-Маа', 'Ras El Maa Waterfall', 'Рас-эль-Маа сарқырамасы', 35.17150000, -5.26020000, 'Ras El Maa Chefchaouen Morocco', ARRAY['chefchaouen']::text[], ARRAY['chefchaouen']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('akchour-waterfalls', 'chefchaouen', 'NATURE', 5, 'HOURS', 4.8, 'Водопады Акшур', 'Akchour Waterfalls', 'Акшур сарқырамалары', 35.25000000, -5.18000000, 'Akchour Waterfalls Chefchaouen Morocco', ARRAY['chefchaouen']::text[], ARRAY['chefchaouen']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),

    ('tetouan-medina', 'tetouan', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Медина Тетуана', 'Medina of Tetouan', 'Тетуан мединасы', 35.57070000, -5.37230000, 'Medina of Tetouan Morocco', ARRAY['tetouan']::text[], ARRAY['tetouan', 'tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('tetouan-archaeological-museum', 'tetouan', 'MUSEUM', 1, 'HOURS', 4.4, 'Археологический музей Тетуана', 'Archaeological Museum of Tetouan', 'Тетуан археологиялық музейі', 35.57280000, -5.37510000, 'Archaeological Museum Tetouan Morocco', ARRAY['tetouan']::text[], ARRAY['tetouan']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('feddan-park-tetouan', 'tetouan', 'PARK', 1, 'HOURS', 4.5, 'Парк Феддан и площадь Хасана II', 'Feddan Park and Hassan II Square', 'Феддан саябағы және Хасан II алаңы', 35.57000000, -5.37400000, 'Feddan Park Tetouan Morocco', ARRAY['tetouan']::text[], ARRAY['tetouan']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('martil-beach', 'tetouan', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Мартиль', 'Martil Beach', 'Мартиль жағажайы', 35.61670000, -5.27500000, 'Martil Beach Tetouan Morocco', ARRAY['tetouan']::text[], ARRAY['tetouan']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),

    ('asilah-medina-murals', 'asilah', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Медина Асилы и настенные росписи', 'Asilah Medina and Murals', 'Асила мединасы және қабырға суреттері', 35.46500000, -6.03400000, 'Asilah Medina Murals Morocco', ARRAY['asilah']::text[], ARRAY['asilah', 'tangier']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('asilah-souk', 'asilah', 'MARKET', 1, 'HOURS', 4.4, 'Сук Асилы', 'Asilah Souk', 'Асила базары', 35.46520000, -6.03350000, 'Asilah souk medina shops Morocco', ARRAY['asilah']::text[], ARRAY['asilah']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('paradise-beach-asilah', 'asilah', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Парадайз', 'Paradise Beach', 'Парадайз жағажайы', 35.49800000, -6.12600000, 'Paradise Beach Rmilat Asilah Morocco', ARRAY['asilah']::text[], ARRAY['asilah']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),
    ('asilah-evening-medina', 'asilah', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Вечерняя медина Асилы', 'Asilah Evening Medina', 'Асила кешкі мединасы', 35.46510000, -6.03420000, 'Asilah medina evening cafes Morocco', ARRAY['asilah']::text[], ARRAY['asilah']::text[], 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg'),

    ('jemaa-el-fna', 'marrakech', 'MARKET', 3, 'HOURS', 4.9, 'Площадь Джемаа-эль-Фна', 'Jemaa el-Fna Square', 'Джемаа-эль-Фна алаңы', 31.62580000, -7.98910000, 'Jemaa el-Fna Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('jemaa-night-food-stalls', 'marrakech', 'FOOD', 2, 'HOURS', 4.7, 'Ночные фуд-лавки Джемаа-эль-Фна', 'Jemaa el-Fna Night Food Stalls', 'Джемаа-эль-Фна түнгі тағам орындары', 31.62580000, -7.98910000, 'Jemaa el-Fna food stalls Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('marrakech-souks', 'marrakech', 'MARKET', 3, 'HOURS', 4.8, 'Суки Марракеша', 'Marrakech Souks', 'Марракеш базарлары', 31.62950000, -7.98720000, 'Souk Semmarine Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('marrakech-medina', 'marrakech', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Медина Марракеша', 'Medina of Marrakech', 'Марракеш мединасы', 31.62950000, -7.98110000, 'Marrakech Medina Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('bahia-palace', 'marrakech', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Дворец Бахия', 'Bahia Palace', 'Бахия сарайы', 31.62170000, -7.98300000, 'Bahia Palace Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('el-badi-palace', 'marrakech', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Дворец Эль-Бади', 'El Badi Palace', 'Эль-Бади сарайы', 31.61820000, -7.98500000, 'El Badi Palace Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('koutoubia-mosque', 'marrakech', 'TEMPLE', 1, 'HOURS', 4.8, 'Мечеть Кутубия', 'Koutoubia Mosque', 'Кутубия мешіті', 31.62410000, -7.99360000, 'Koutoubia Mosque Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('saadian-tombs', 'marrakech', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Саадские гробницы', 'Saadian Tombs', 'Саадиттер кесенелері', 31.61720000, -7.98800000, 'Saadian Tombs Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('ben-youssef-madrasa', 'marrakech', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Медресе Бен Юсефа', 'Ben Youssef Madrasa', 'Бен Юсеф медресесі', 31.63200000, -7.98670000, 'Ben Youssef Madrasa Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('jardin-majorelle', 'marrakech', 'PARK', 2, 'HOURS', 4.8, 'Сад Мажорель', 'Jardin Majorelle', 'Мажорель бағы', 31.64170000, -8.00390000, 'Jardin Majorelle Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('le-jardin-secret', 'marrakech', 'PARK', 1, 'HOURS', 4.7, 'Секретный сад', 'Le Jardin Secret', 'Құпия бақ', 31.63090000, -7.98830000, 'Le Jardin Secret Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('menara-gardens', 'marrakech', 'PARK', 2, 'HOURS', 4.5, 'Сады Менара', 'Menara Gardens', 'Менара бақтары', 31.61300000, -8.02190000, 'Menara Gardens Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('cyber-park-marrakech', 'marrakech', 'PARK', 1, 'HOURS', 4.5, 'Кибер-парк Арсат Мулай Абдеслам', 'Cyber Park Arsat Moulay Abdeslam', 'Арсат Мулай Абдеслам кибер-саябағы', 31.62670000, -7.99900000, 'Cyber Park Arsat Moulay Abdeslam Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('dar-si-said-museum', 'marrakech', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Дар Си Саид', 'Dar Si Said Museum', 'Дар Си Саид музейі', 31.62290000, -7.98400000, 'Dar Si Said Museum Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('ysl-museum-marrakech', 'marrakech', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Ива Сен-Лорана', 'Yves Saint Laurent Museum', 'Ив Сен-Лоран музейі', 31.64220000, -8.00470000, 'Yves Saint Laurent Museum Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('oasiria-marrakech', 'marrakech', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Аквапарк Oasiria Marrakech', 'Oasiria Marrakech', 'Oasiria Marrakech аквапаркі', 31.58990000, -8.02850000, 'Oasiria Marrakech water park Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('menara-mall', 'marrakech', 'SHOPPING', 2, 'HOURS', 4.4, 'Menara Mall', 'Menara Mall', 'Menara Mall', 31.61590000, -8.00450000, 'Menara Mall Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('carre-eden', 'marrakech', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Carre Eden', 'Carre Eden Shopping Center', 'Carre Eden сауда орталығы', 31.63400000, -8.01000000, 'Carre Eden Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('marrakech-palmeraie', 'marrakech', 'NATURE', 3, 'HOURS', 4.4, 'Пальмовая роща Марракеша', 'Marrakech Palmeraie', 'Марракеш пальма тоғайы', 31.69000000, -7.97000000, 'La Palmeraie Marrakech Morocco', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),

    ('anima-garden', 'ourika', 'PARK', 2, 'HOURS', 4.7, 'Сад ANIMA', 'ANIMA Garden', 'ANIMA бағы', 31.41500000, -7.85500000, 'ANIMA Garden Ourika Marrakech Morocco', ARRAY['ourika', 'marrakech']::text[], ARRAY['ourika', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('ourika-valley', 'ourika', 'NATURE', 5, 'HOURS', 4.8, 'Долина Урика', 'Ourika Valley', 'Урика аңғары', 31.30000000, -7.78000000, 'Ourika Valley Morocco', ARRAY['ourika']::text[], ARRAY['ourika', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('agafay-desert', 'agafay', 'NATURE', 4, 'HOURS', 4.7, 'Пустыня Агафай', 'Agafay Desert', 'Агафай шөлі', 31.52000000, -8.19000000, 'Agafay Desert Marrakech Morocco', ARRAY['agafay']::text[], ARRAY['agafay', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('agafay-camel-quad-dinner', 'agafay', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Верблюды, квадроциклы и ужин в Агафае', 'Agafay Camel, Quad and Dinner Experience', 'Агафай түйе, квадроцикл және кешкі ас тәжірибесі', 31.52000000, -8.19000000, 'Agafay desert camel quad dinner Marrakech Morocco', ARRAY['agafay']::text[], ARRAY['agafay', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('lalla-takerkoust-lake', 'lalla-takerkoust', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Лалла-Такеркуст', 'Lalla Takerkoust Lake', 'Лалла-Такеркуст көлі', 31.35400000, -8.13200000, 'Lalla Takerkoust Lake Marrakech Morocco', ARRAY['lalla-takerkoust']::text[], ARRAY['lalla-takerkoust', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('imlil-high-atlas', 'imlil', 'NATURE', 5, 'HOURS', 4.8, 'Имлиль и Высокий Атлас', 'Imlil High Atlas Trekking Base', 'Имлиль және Биік Атлас треккинг базасы', 31.13500000, -7.91800000, 'Imlil High Atlas Morocco', ARRAY['imlil']::text[], ARRAY['imlil', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('ouzoud-waterfalls', 'ouzoud', 'NATURE', 5, 'HOURS', 4.8, 'Водопады Узуд', 'Ouzoud Waterfalls', 'Узуд сарқырамалары', 32.01500000, -6.71900000, 'Ouzoud Waterfalls Morocco', ARRAY['ouzoud', 'azilal']::text[], ARRAY['ouzoud', 'azilal', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('bin-el-ouidane-lake', 'azilal', 'NATURE', 4, 'HOURS', 4.7, 'Озеро Бин-эль-Уидан', 'Bin El Ouidane Lake', 'Бин-эль-Уидан көлі', 32.10300000, -6.45900000, 'Bin El Ouidane Lake Morocco', ARRAY['azilal']::text[], ARRAY['azilal', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),
    ('ait-bouguemez-valley', 'azilal', 'NATURE', 5, 'HOURS', 4.7, 'Долина Аит Бугуемез', 'Ait Bouguemez Valley', 'Аит Бугуемез аңғары', 31.63000000, -6.45000000, 'Ait Bouguemez Valley Morocco', ARRAY['azilal']::text[], ARRAY['azilal', 'marrakech']::text[], 'Jemaa_el-Fnaa_at_night.jpg'),

    ('fes-el-bali-medina', 'fes', 'MARKET', 4, 'HOURS', 4.9, 'Медина Фес-эль-Бали', 'Fes el-Bali Medina', 'Фес-эль-Бали мединасы', 34.06110000, -4.97690000, 'Fes el Bali Medina Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('bab-bou-jeloud', 'fes', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Ворота Баб-Бу-Джелуд', 'Bab Bou Jeloud', 'Баб-Бу-Джелуд қақпасы', 34.06260000, -4.98380000, 'Bab Bou Jeloud Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('bou-inania-madrasa', 'fes', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Медресе Бу Инания', 'Bou Inania Madrasa', 'Бу Инания медресесі', 34.06220000, -4.98260000, 'Bou Inania Madrasa Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('chouara-tanneries', 'fes', 'MARKET', 1, 'HOURS', 4.6, 'Кожевни Шуара', 'Chouara Tanneries', 'Шуара былғары шеберханалары', 34.06460000, -4.97300000, 'Chouara Tannery Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('nejjarine-museum', 'fes', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей деревянного искусства Неджарин', 'Nejjarine Museum of Wooden Arts and Crafts', 'Неджарин ағаш өнері музейі', 34.06420000, -4.97750000, 'Nejjarine Museum Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('jnan-sbil-gardens', 'fes', 'PARK', 1, 'HOURS', 4.6, 'Сады Жнан-Сбиль', 'Jnan Sbil Gardens', 'Жнан-Сбиль бақтары', 34.05880000, -4.98760000, 'Jnan Sbil Gardens Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('dar-batha-museum', 'fes', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Дар-Батха', 'Dar Batha Museum', 'Дар-Батха музейі', 34.06110000, -4.98400000, 'Dar Batha Museum Fes Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),
    ('borj-fez-mall', 'fes', 'SHOPPING', 2, 'HOURS', 4.2, 'ТЦ Borj Fez', 'Borj Fez Mall', 'Borj Fez сауда орталығы', 34.03930000, -5.00300000, 'Borj Fez Mall Morocco', ARRAY['fes']::text[], ARRAY['fes']::text[], 'Fes-el-Bali_(Old_Medina),_Fes_(6217953305).jpg'),

    ('meknes-medina', 'meknes', 'MARKET', 3, 'HOURS', 4.8, 'Медина Мекнеса', 'Meknes Medina', 'Мекнес мединасы', 33.89350000, -5.56560000, 'Meknes Medina Morocco', ARRAY['meknes']::text[], ARRAY['meknes', 'fes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('bab-mansour', 'meknes', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Ворота Баб-Мансур', 'Bab Mansour', 'Баб-Мансур қақпасы', 33.89320000, -5.56450000, 'Bab Mansour Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('place-el-hedim', 'meknes', 'FOOD', 1, 'HOURS', 4.5, 'Площадь Эль-Хедим', 'Place el-Hedim', 'Эль-Хедим алаңы', 33.89300000, -5.56390000, 'Place el Hedim Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('heri-es-souani', 'meknes', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Хери-эс-Суани и Дар-аль-Ма', 'Heri es-Souani and Dar al-Ma', 'Хери-эс-Суани және Дар-аль-Ма', 33.87890000, -5.57000000, 'Heri es-Souani Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('moulay-ismail-mausoleum', 'meknes', 'TEMPLE', 1, 'HOURS', 4.6, 'Мавзолей Мулай Исмаила', 'Mausoleum of Moulay Ismail', 'Мулай Исмаил кесенесі', 33.89370000, -5.56310000, 'Mausoleum of Moulay Ismail Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('dar-jamai-museum', 'meknes', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Дар-Жамаи', 'Dar Jamai Museum', 'Дар-Жамаи музейі', 33.89420000, -5.56270000, 'Dar Jamai Museum Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('lahboul-gardens', 'meknes', 'PARK', 1, 'HOURS', 4.4, 'Сады Лахбул', 'Lahboul Gardens', 'Лахбул бақтары', 33.89850000, -5.55380000, 'Lahboul Gardens Meknes Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('meknes-plaza', 'meknes', 'SHOPPING', 2, 'HOURS', 4.1, 'Meknes Plaza', 'Meknes Plaza', 'Meknes Plaza', 33.89000000, -5.55000000, 'Meknes Plaza shopping center Morocco', ARRAY['meknes']::text[], ARRAY['meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('volubilis-archaeological-site', 'volubilis', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Археологический комплекс Волюбилис', 'Archaeological Site of Volubilis', 'Волюбилис археологиялық кешені', 34.07120000, -5.55300000, 'Volubilis archaeological site Morocco', ARRAY['volubilis', 'meknes']::text[], ARRAY['volubilis', 'meknes', 'fes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('volubilis-mosaics', 'volubilis', 'MUSEUM', 2, 'HOURS', 4.7, 'Мозаики Волюбилиса', 'Volubilis Mosaics', 'Волюбилис мозаикалары', 34.07120000, -5.55300000, 'Volubilis mosaics Morocco', ARRAY['volubilis']::text[], ARRAY['volubilis', 'meknes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('ifrane-national-park', 'ifrane', 'NATURE', 4, 'HOURS', 4.7, 'Национальный парк Ифрана', 'Ifrane National Park', 'Ифран ұлттық паркі', 33.53330000, -5.10000000, 'Ifrane National Park Morocco', ARRAY['ifrane']::text[], ARRAY['ifrane', 'fes']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('lake-dayet-aoua', 'ifrane', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Дайет-Ауа', 'Lake Dayet Aoua', 'Дайет-Ауа көлі', 33.65000000, -5.05000000, 'Lake Dayet Aoua Ifrane Morocco', ARRAY['ifrane']::text[], ARRAY['ifrane']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('cedar-forest-ifrane', 'ifrane', 'NATURE', 3, 'HOURS', 4.6, 'Кедровый лес и берберские макаки', 'Cedar Forest and Barbary Apes', 'Кедр орманы және бербер макакалары', 33.43600000, -5.22100000, 'Cedar Forest Barbary Apes Ifrane Azrou Morocco', ARRAY['ifrane']::text[], ARRAY['ifrane']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('ain-vittel', 'ifrane', 'PARK', 1, 'HOURS', 4.4, 'Источник Айн-Витель', 'Ain Vittel', 'Айн-Витель бұлағы', 33.52000000, -5.13000000, 'Ain Vittel Ifrane Morocco', ARRAY['ifrane']::text[], ARRAY['ifrane']::text[], 'Maroc_-_Volubilis_-01.JPG'),
    ('michlifen-ski-resort', 'ifrane', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Горнолыжный курорт Мишлифен', 'Michlifen Ski Resort', 'Мишлифен шаңғы курорты', 33.41200000, -5.08600000, 'Michlifen Ski Resort Ifrane Morocco', ARRAY['ifrane']::text[], ARRAY['ifrane']::text[], 'Maroc_-_Volubilis_-01.JPG'),

    ('agadir-beach-corniche', 'agadir', 'BEACH', 4, 'HOURS', 4.8, 'Пляж и набережная Агадира', 'Agadir Beach and Corniche', 'Агадир жағажайы және жағалауы', 30.41000000, -9.60000000, 'Agadir Beach Corniche Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('kasbah-agadir-oufella', 'agadir', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Касба Агадир Уфелла', 'Kasbah Agadir Oufella', 'Агадир Уфелла қамалы', 30.42890000, -9.62200000, 'Kasbah Agadir Oufella Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('souk-el-had', 'agadir', 'MARKET', 3, 'HOURS', 4.7, 'Сук Эль-Хад', 'Souk El Had', 'Эль-Хад базары', 30.41820000, -9.58100000, 'Souk El Had Agadir Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('crocoparc-agadir', 'agadir', 'PARK', 3, 'HOURS', 4.6, 'Крокопарк Агадира', 'Crocoparc Agadir', 'Агадир Крокопаркі', 30.39880000, -9.48560000, 'Crocoparc Agadir Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('medina-polizzi', 'agadir', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Медина Полицци', 'Medina Polizzi', 'Полицци мединасы', 30.39000000, -9.56000000, 'Medina Polizzi Agadir Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('amazigh-heritage-museum', 'agadir', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей амазигского наследия', 'Amazigh Heritage Museum', 'Амазиг мұрасы музейі', 30.41420000, -9.59500000, 'Amazigh Heritage Museum Agadir Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('marina-agadir', 'agadir', 'SHOPPING', 2, 'HOURS', 4.4, 'Марина Агадира', 'Marina Agadir', 'Агадир маринасы', 30.42500000, -9.61700000, 'Marina Agadir Morocco', ARRAY['agadir']::text[], ARRAY['agadir']::text[], 'Agadir_beach,_Morocco.JPG'),

    ('essaouira-medina', 'essaouira', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Медина Эс-Сувейры', 'Medina of Essaouira', 'Эс-Сувейра мединасы', 31.51250000, -9.77000000, 'Medina of Essaouira Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira', 'marrakech']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('skala-de-la-ville', 'essaouira', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Скала де ла Виль и крепостные стены', 'Skala de la Ville and Ramparts', 'Скала-де-ла-Виль және қамал қабырғалары', 31.51340000, -9.77320000, 'Skala de la Ville Essaouira Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('essaouira-fishing-port', 'essaouira', 'FOOD', 1, 'HOURS', 4.6, 'Рыбный порт Эс-Сувейры', 'Essaouira Fishing Port', 'Эс-Сувейра балық порты', 31.51100000, -9.77400000, 'Essaouira fishing port Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('essaouira-beach', 'essaouira', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Эс-Сувейры', 'Essaouira Beach', 'Эс-Сувейра жағажайы', 31.50100000, -9.76500000, 'Essaouira Beach Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('sidi-kaouki-beach', 'essaouira', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Сиди-Кауки', 'Sidi Kaouki Beach', 'Сиди-Кауки жағажайы', 31.35000000, -9.80000000, 'Sidi Kaouki Beach Essaouira Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('sidi-mohammed-ben-abdallah-museum', 'essaouira', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей Сиди Мохаммеда бен Абдаллаха', 'Sidi Mohammed Ben Abdallah Museum', 'Сиди Мұхаммед бен Абдаллах музейі', 31.51300000, -9.77090000, 'Sidi Mohammed Ben Abdallah Museum Essaouira Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),
    ('place-moulay-hassan', 'essaouira', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Площадь Мулай Хассан', 'Place Moulay Hassan', 'Мулай Хассан алаңы', 31.51200000, -9.77040000, 'Place Moulay Hassan Essaouira Morocco', ARRAY['essaouira']::text[], ARRAY['essaouira']::text[], 'Ramparts_of_Essaouira.JPG'),

    ('taghazout-beach', 'taghazout', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Тагазута', 'Taghazout Beach', 'Тагазут жағажайы', 30.54500000, -9.70800000, 'Taghazout Beach Morocco', ARRAY['taghazout']::text[], ARRAY['taghazout', 'agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('anchor-point', 'taghazout', 'NATURE', 2, 'HOURS', 4.7, 'Энкор-Пойнт', 'Anchor Point', 'Энкор-Пойнт', 30.54800000, -9.72700000, 'Anchor Point Taghazout Morocco', ARRAY['taghazout']::text[], ARRAY['taghazout']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('taghazout-bay', 'taghazout', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Тагазут-Бей', 'Taghazout Bay', 'Тагазут-Бей', 30.52000000, -9.68000000, 'Taghazout Bay Morocco', ARRAY['taghazout']::text[], ARRAY['taghazout', 'agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('paradise-valley-taghazout', 'taghazout', 'NATURE', 4, 'HOURS', 4.7, 'Райская долина', 'Paradise Valley', 'Жұмақ аңғары', 30.58500000, -9.53000000, 'Paradise Valley Taghazout Morocco', ARRAY['taghazout', 'agadir']::text[], ARRAY['taghazout', 'agadir']::text[], 'Agadir_beach,_Morocco.JPG'),
    ('taghazout-village-beachfront', 'taghazout', 'FOOD', 2, 'HOURS', 4.4, 'Вечерняя набережная Тагазута', 'Taghazout Village Beachfront', 'Тагазут кешкі жағалауы', 30.54200000, -9.70900000, 'Taghazout village beachfront cafes Morocco', ARRAY['taghazout']::text[], ARRAY['taghazout']::text[], 'Agadir_beach,_Morocco.JPG'),

    ('ksar-ait-ben-haddou', 'ouarzazate', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Ксар Айт-Бен-Хадду', 'Ksar Ait Ben Haddou', 'Айт-Бен-Хадду ксары', 31.04700000, -7.12900000, 'Ksar Ait Ben Haddou Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate', 'marrakech']::text[], 'Ait_Ben_Haddou_03.JPG'),
    ('kasbah-taourirt', 'ouarzazate', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Касба Таурирт', 'Kasbah Taourirt', 'Таурирт қамалы', 30.92060000, -6.89360000, 'Kasbah Taourirt Ouarzazate Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], 'Ait_Ben_Haddou_03.JPG'),
    ('atlas-studios', 'ouarzazate', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Атлас Студиос', 'Atlas Studios', 'Атлас студиялары', 30.93900000, -6.96600000, 'Atlas Studios Ouarzazate Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], 'Ait_Ben_Haddou_03.JPG'),
    ('cinema-museum-ouarzazate', 'ouarzazate', 'MUSEUM', 2, 'HOURS', 4.3, 'Музей кино Уарзазата', 'Cinema Museum of Ouarzazate', 'Уарзазат кино музейі', 30.92000000, -6.89320000, 'Cinema Museum Ouarzazate Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], 'Ait_Ben_Haddou_03.JPG'),
    ('fint-oasis', 'ouarzazate', 'NATURE', 4, 'HOURS', 4.6, 'Оазис Финт', 'Fint Oasis', 'Финт оазисі', 30.85700000, -6.98600000, 'Fint Oasis Ouarzazate Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], 'Ait_Ben_Haddou_03.JPG'),
    ('ouarzazate-artisanal-complex', 'ouarzazate', 'MARKET', 2, 'HOURS', 4.3, 'Ремесленный комплекс Уарзазата', 'Ouarzazate Artisanal Complex', 'Уарзазат қолөнер кешені', 30.92000000, -6.91000000, 'Ouarzazate Artisanal Complex Morocco', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], 'Ait_Ben_Haddou_03.JPG'),

    ('erg-chebbi-dunes', 'merzouga', 'NATURE', 5, 'HOURS', 4.9, 'Дюны Эрг-Шебби', 'Erg Chebbi Dunes', 'Эрг-Шебби құм төбелері', 31.10000000, -4.01000000, 'Erg Chebbi dunes Merzouga Morocco', ARRAY['merzouga']::text[], ARRAY['merzouga']::text[], 'Merzouga_desert_Erg_Chebbi.jpg'),
    ('sahara-camel-trek', 'merzouga', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Верблюжий трек и лагерь в Сахаре', 'Sahara Camel Trek and Desert Camp', 'Сахара түйе жорығы және лагерь', 31.10000000, -4.01000000, 'Merzouga camel trekking desert camp Morocco', ARRAY['merzouga']::text[], ARRAY['merzouga']::text[], 'Merzouga_desert_Erg_Chebbi.jpg'),
    ('lake-dayet-srij', 'merzouga', 'NATURE', 2, 'HOURS', 4.5, 'Озеро Дайет-Сридж', 'Lake Dayet Srij', 'Дайет-Сридж көлі', 31.08100000, -4.01700000, 'Lake Dayet Srij Merzouga Morocco', ARRAY['merzouga']::text[], ARRAY['merzouga']::text[], 'Merzouga_desert_Erg_Chebbi.jpg'),
    ('khamlia-gnawa-village', 'merzouga', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Гнауа-деревня Хамлия', 'Khamlia Gnawa Village', 'Хамлия гнауа ауылы', 31.08400000, -4.02000000, 'Khamlia Gnawa village Merzouga Morocco', ARRAY['merzouga']::text[], ARRAY['merzouga']::text[], 'Merzouga_desert_Erg_Chebbi.jpg'),
    ('merzouga-4x4-sandboarding', 'merzouga', 'ENTERTAINMENT', 3, 'HOURS', 4.6, '4x4 и сэндбординг в Мерзуге', 'Merzouga 4x4 and Sandboarding Area', 'Мерзуга 4x4 және сэндбординг аймағы', 31.10000000, -4.01000000, 'Merzouga sandboarding 4x4 Erg Chebbi Morocco', ARRAY['merzouga']::text[], ARRAY['merzouga']::text[], 'Merzouga_desert_Erg_Chebbi.jpg');

CREATE TEMP TABLE seed_morocco_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-morocco-attraction:' || seed.slug) AS attraction_hash,
        md5('id-morocco-media:' || seed.slug) AS media_hash
    FROM seed_morocco_priority_attractions seed
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
    ARRAY['morocco', city_id, slug, lower(category), 'morocco-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Марокко: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Morocco tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Марокко туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'MA',
    city_id,
    category,
    NULL::numeric,
    'MAD',
    duration_value,
    duration_unit,
    rating,
    0,
    NULL,
    'IMPORT',
    'PUBLISHED',
    tags,
    NOW(),
    NOW()
FROM seed_morocco_resolved_attractions
ON CONFLICT (id) DO UPDATE SET
    default_locale = EXCLUDED.default_locale,
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    spots = EXCLUDED.spots,
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
SELECT
    id,
    'ru',
    title_ru,
    description_ru,
    NOW(),
    NOW()
FROM seed_morocco_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_morocco_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_morocco_resolved_attractions
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
FROM seed_morocco_resolved_attractions seed
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
FROM seed_morocco_resolved_attractions
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
    'MA',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_morocco_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'MA',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_morocco_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_morocco_resolved_attractions;
DROP TABLE IF EXISTS seed_morocco_priority_attractions;
