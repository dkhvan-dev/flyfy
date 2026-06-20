-- Priority Uzbekistan destination places seed.
-- The seed covers classic Silk Road cities, Fergana Valley crafts, Karakalpakstan, mountain day trips, markets and modern city leisure.

DROP TABLE IF EXISTS seed_uzbekistan_resolved_places;
DROP TABLE IF EXISTS seed_uzbekistan_priority_places;

CREATE TEMP TABLE seed_uzbekistan_priority_places (
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

INSERT INTO seed_uzbekistan_priority_places (
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
    ('amir-timur-square', 'tashkent', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Сквер Амира Тимура', 'Amir Timur Square', 'Әмір Темір алаңы', 41.31120000, 69.27970000, 'Amir Timur Square Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Amir Timur Square Tashkent.jpg'),
    ('hazrati-imam-complex', 'tashkent', 'TEMPLE', 2, 'HOURS', 4.8, 'Комплекс Хазрати Имам', 'Hazrati Imam Complex', 'Хазірет Имам кешені', 41.33710000, 69.24090000, 'Hazrati Imam Complex Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Hazrati Imam Complex Tashkent.jpg'),
    ('kukeldash-madrasah', 'tashkent', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Медресе Кукельдаш', 'Kukeldash Madrasah', 'Көкелдаш медресесі', 41.32540000, 69.23540000, 'Kukeldash Madrasah Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Kukeldash Madrasah Tashkent.jpg'),
    ('minor-mosque', 'tashkent', 'TEMPLE', 1, 'HOURS', 4.8, 'Мечеть Минор', 'Minor Mosque', 'Минор мешіті', 41.34290000, 69.28200000, 'Minor Mosque Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Minor Mosque Tashkent.jpg'),
    ('tashkent-metro', 'tashkent', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Ташкентское метро', 'Tashkent Metro', 'Ташкент метросы', 41.31110000, 69.27970000, 'Tashkent Metro stations', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Tashkent Metro Kosmonavtlar.jpg'),
    ('state-museum-history-uzbekistan', 'tashkent', 'MUSEUM', 2, 'HOURS', 4.6, 'Государственный музей истории Узбекистана', 'State Museum of History of Uzbekistan', 'Өзбекстан тарихы мемлекеттік музейі', 41.31060000, 69.27240000, 'State Museum of History of Uzbekistan Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'State Museum of History of Uzbekistan.jpg'),
    ('state-museum-applied-arts', 'tashkent', 'MUSEUM', 2, 'HOURS', 4.7, 'Государственный музей прикладного искусства', 'State Museum of Applied Arts', 'Қолданбалы өнер мемлекеттік музейі', 41.29970000, 69.26630000, 'State Museum of Applied Arts Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Museum of Applied Arts Tashkent.jpg'),
    ('chorsu-bazaar', 'tashkent', 'MARKET', 2, 'HOURS', 4.7, 'Базар Чорсу', 'Chorsu Bazaar', 'Чорсу базары', 41.32640000, 69.23540000, 'Chorsu Bazaar Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Chorsu Bazaar Tashkent.jpg'),
    ('oloy-bazaar', 'tashkent', 'MARKET', 1, 'HOURS', 4.5, 'Алайский базар', 'Oloy Bazaar', 'Алай базары', 41.32120000, 69.28180000, 'Oloy Bazaar Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Oloy Bazaar Tashkent.jpg'),
    ('central-asian-plov-center', 'tashkent', 'FOOD', 1, 'HOURS', 4.6, 'Центр плова Беш Козон', 'Central Asian Plov Center', 'Орталық Азия палау орталығы', 41.34470000, 69.28440000, 'Central Asian Plov Center Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Central Asian Plov Center Tashkent.jpg'),
    ('tashkent-botanical-garden', 'tashkent', 'PARK', 2, 'HOURS', 4.6, 'Ташкентский ботанический сад', 'Tashkent Botanical Garden', 'Ташкент ботаникалық бағы', 41.36470000, 69.31380000, 'Tashkent Botanical Garden', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Tashkent Botanical Garden.jpg'),
    ('magic-city-tashkent', 'tashkent', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Magic City Tashkent', 'Magic City Tashkent', 'Magic City Tashkent', 41.30530000, 69.24320000, 'Magic City Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Magic City Tashkent.jpg'),
    ('tashkent-city-mall', 'tashkent', 'SHOPPING', 3, 'HOURS', 4.5, 'Tashkent City Mall', 'Tashkent City Mall', 'Tashkent City Mall', 41.31410000, 69.24470000, 'Tashkent City Mall', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Tashkent City Mall.jpg'),
    ('samarqand-darvoza', 'tashkent', 'SHOPPING', 2, 'HOURS', 4.4, 'Samarqand Darvoza', 'Samarqand Darvoza', 'Samarqand Darvoza', 41.31570000, 69.22990000, 'Samarqand Darvoza Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Samarqand Darvoza Tashkent.jpg'),
    ('alisher-navoi-theatre', 'tashkent', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Большой театр имени Алишера Навои', 'Alisher Navoi State Academic Grand Theatre', 'Әлішер Науаи атындағы мемлекеттік академиялық үлкен театр', 41.30680000, 69.28020000, 'Alisher Navoi Theatre Tashkent', ARRAY['tashkent']::text[], ARRAY['tashkent']::text[], 'Alisher Navoi Theatre Tashkent.jpg'),
    ('chimgan-mountains', 'chimgan', 'NATURE', 5, 'HOURS', 4.8, 'Горы Чимган', 'Chimgan Mountains', 'Шымған таулары', 41.54930000, 70.02040000, 'Chimgan Mountains Uzbekistan', ARRAY['chimgan']::text[], ARRAY['tashkent', 'chimgan']::text[], 'Chimgan mountains Uzbekistan.jpg'),
    ('charvak-reservoir-beaches', 'charvak', 'BEACH', 4, 'HOURS', 4.6, 'Пляжи Чарвакского водохранилища', 'Charvak Reservoir Beaches', 'Шарбақ су қоймасы жағажайлары', 41.63490000, 69.94010000, 'Charvak Reservoir Uzbekistan beach', ARRAY['charvak']::text[], ARRAY['tashkent', 'charvak']::text[], 'Charvak Reservoir Uzbekistan.jpg'),

    ('registan-square', 'samarkand', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Площадь Регистан', 'Registan Square', 'Регистан алаңы', 39.65470000, 66.97500000, 'Registan Square Samarkand', ARRAY['samarkand']::text[], ARRAY['tashkent', 'samarkand']::text[], 'Registan Samarkand.jpg'),
    ('shah-i-zinda', 'samarkand', 'TEMPLE', 2, 'HOURS', 4.9, 'Шахи-Зинда', 'Shah-i-Zinda', 'Шахи-Зинда', 39.66200000, 66.98760000, 'Shah-i-Zinda Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Shah-i-Zinda Samarkand.jpg'),
    ('bibi-khanym-mosque', 'samarkand', 'TEMPLE', 2, 'HOURS', 4.8, 'Мечеть Биби-Ханым', 'Bibi-Khanym Mosque', 'Бибі-Ханым мешіті', 39.66070000, 66.98020000, 'Bibi-Khanym Mosque Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Bibi-Khanym Mosque Samarkand.jpg'),
    ('gur-e-amir-mausoleum', 'samarkand', 'TEMPLE', 2, 'HOURS', 4.8, 'Мавзолей Гур-Эмир', 'Gur-e-Amir Mausoleum', 'Гүр-Әмір кесенесі', 39.64860000, 66.96990000, 'Gur-e-Amir Mausoleum Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Gur-e Amir Samarkand.jpg'),
    ('ulugh-beg-observatory', 'samarkand', 'MUSEUM', 1, 'HOURS', 4.6, 'Обсерватория Улугбека', 'Ulugh Beg Observatory', 'Ұлықбек обсерваториясы', 39.67450000, 67.00570000, 'Ulugh Beg Observatory Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Ulugh Beg Observatory Samarkand.jpg'),
    ('afrasiab-museum', 'samarkand', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Афрасиаб', 'Afrasiab Museum', 'Афрасиаб музейі', 39.67660000, 66.98770000, 'Afrasiab Museum Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Afrasiab Museum Samarkand.jpg'),
    ('siab-bazaar', 'samarkand', 'MARKET', 2, 'HOURS', 4.6, 'Сиабский базар', 'Siab Bazaar', 'Сиаб базары', 39.66260000, 66.98040000, 'Siab Bazaar Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Siab Bazaar Samarkand.jpg'),
    ('konigil-meros-paper-mill', 'samarkand', 'SHOPPING', 2, 'HOURS', 4.5, 'Конигил и бумажная фабрика Мерос', 'Konigil Village and Meros Paper Mill', 'Қонигил және Мерос қағаз шеберханасы', 39.70450000, 67.04640000, 'Konigil Meros Paper Mill Samarkand', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], 'Konigil Paper Mill Samarkand.jpg'),

    ('ark-of-bukhara', 'bukhara', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Арк Бухары', 'Ark of Bukhara', 'Бұхара Аркі', 39.77740000, 64.40920000, 'Ark of Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Ark of Bukhara.jpg'),
    ('poi-kalyan-complex', 'bukhara', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Комплекс Пои-Калян', 'Poi Kalyan Complex', 'Пои-Калян кешені', 39.77570000, 64.41520000, 'Poi Kalyan Complex Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Poi Kalyan Bukhara.jpg'),
    ('lyabi-hauz', 'bukhara', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Ляби-Хауз', 'Lyabi-Hauz', 'Ляби-Хауз', 39.77270000, 64.42270000, 'Lyabi-Hauz Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Lyabi Hauz Bukhara.jpg'),
    ('samanid-mausoleum', 'bukhara', 'TEMPLE', 1, 'HOURS', 4.8, 'Мавзолей Саманидов', 'Samanid Mausoleum', 'Саманидтер кесенесі', 39.77760000, 64.40050000, 'Samanid Mausoleum Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Samanid Mausoleum Bukhara.jpg'),
    ('chor-minor', 'bukhara', 'TEMPLE', 1, 'HOURS', 4.6, 'Чор-Минор', 'Chor Minor', 'Чор-Минор', 39.77440000, 64.42760000, 'Chor Minor Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Chor Minor Bukhara.jpg'),
    ('bukhara-trading-domes', 'bukhara', 'MARKET', 2, 'HOURS', 4.6, 'Торговые купола Бухары', 'Bukhara Trading Domes', 'Бұхара сауда күмбездері', 39.77480000, 64.41790000, 'Bukhara Trading Domes', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Bukhara Trading Domes.jpg'),
    ('sitorai-mokhi-khosa-palace', 'bukhara', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Ситораи Мохи-Хоса', 'Sitorai-Mokhi-Khosa Palace', 'Ситораи Мохи-Хоса сарайы', 39.82350000, 64.42170000, 'Sitorai-Mokhi-Khosa Palace Bukhara', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], 'Sitorai Mokhi Khosa Palace.jpg'),

    ('itchan-kala', 'khiva', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Ичан-Кала', 'Itchan Kala', 'Ичан-қала', 41.37830000, 60.35960000, 'Itchan Kala Khiva', ARRAY['khiva']::text[], ARRAY['urgench', 'khiva']::text[], 'Itchan Kala Khiva.jpg'),
    ('kalta-minor-minaret', 'khiva', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Минарет Кальта-Минор', 'Kalta Minor Minaret', 'Кальта-Минор мұнарасы', 41.37810000, 60.35750000, 'Kalta Minor Minaret Khiva', ARRAY['khiva']::text[], ARRAY['khiva']::text[], 'Kalta Minor Khiva.jpg'),
    ('kunya-ark-citadel', 'khiva', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Куня-Арк', 'Kunya-Ark Citadel', 'Көне Арк қамалы', 41.37960000, 60.35700000, 'Kunya-Ark Citadel Khiva', ARRAY['khiva']::text[], ARRAY['khiva']::text[], 'Kunya Ark Khiva.jpg'),
    ('juma-mosque-khiva', 'khiva', 'TEMPLE', 1, 'HOURS', 4.8, 'Джума-мечеть Хивы', 'Juma Mosque Khiva', 'Хива Жұма мешіті', 41.37800000, 60.36100000, 'Juma Mosque Khiva', ARRAY['khiva']::text[], ARRAY['khiva']::text[], 'Juma Mosque Khiva.jpg'),
    ('pahlavan-mahmud-mausoleum', 'khiva', 'TEMPLE', 1, 'HOURS', 4.8, 'Мавзолей Пахлавана Махмуда', 'Pahlavan Mahmud Mausoleum', 'Палуан Махмұд кесенесі', 41.37730000, 60.35890000, 'Pahlavan Mahmud Mausoleum Khiva', ARRAY['khiva']::text[], ARRAY['khiva']::text[], 'Pahlavan Mahmud Mausoleum Khiva.jpg'),
    ('allakuli-khan-bazaar', 'khiva', 'MARKET', 1, 'HOURS', 4.5, 'Базар и караван-сарай Аллакули-хана', 'Allakuli Khan Bazaar and Caravanserai', 'Аллақұли хан базары және керуен сарайы', 41.37770000, 60.36350000, 'Allakuli Khan Bazaar Khiva', ARRAY['khiva']::text[], ARRAY['khiva']::text[], 'Allakuli Khan Bazaar Khiva.jpg'),
    ('ayaz-kala-fortress', 'urgench', 'ARCHITECTURE', 4, 'HOURS', 4.7, 'Крепость Аяз-Кала', 'Ayaz-Kala Fortress', 'Аяз-қала қамалы', 42.01060000, 61.02750000, 'Ayaz-Kala Fortress Uzbekistan', ARRAY['urgench']::text[], ARRAY['urgench', 'khiva']::text[], 'Ayaz Kala Uzbekistan.jpg'),
    ('savitsky-museum', 'nukus', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Савицкого', 'Savitsky Museum', 'Савицкий музейі', 42.46190000, 59.61530000, 'Savitsky Museum Nukus', ARRAY['nukus']::text[], ARRAY['nukus']::text[], 'Savitsky Museum Nukus.jpg'),
    ('mizdakhan-necropolis', 'nukus', 'TEMPLE', 2, 'HOURS', 4.6, 'Некрополь Миздахкан', 'Mizdakhan Necropolis', 'Миздахқан қорымы', 42.48330000, 59.48330000, 'Mizdakhan Necropolis Nukus', ARRAY['nukus']::text[], ARRAY['nukus']::text[], 'Mizdakhan Necropolis.jpg'),
    ('moynaq-ship-cemetery', 'muynak', 'MUSEUM', 2, 'HOURS', 4.7, 'Кладбище кораблей в Муйнаке', 'Moynaq Ship Cemetery', 'Мойнақ кеме зираты', 43.77230000, 59.03020000, 'Moynaq Ship Cemetery Uzbekistan', ARRAY['muynak']::text[], ARRAY['nukus', 'muynak']::text[], 'Moynaq Ship Cemetery.jpg'),
    ('aral-sea', 'aral-sea', 'NATURE', 6, 'HOURS', 4.6, 'Аральское море', 'Aral Sea', 'Арал теңізі', 45.00000000, 59.00000000, 'Aral Sea Uzbekistan', ARRAY['aral-sea']::text[], ARRAY['nukus', 'muynak', 'aral-sea']::text[], 'Aral Sea Uzbekistan.jpg'),

    ('margilan-yodgorlik-silk-factory', 'margilan', 'SHOPPING', 2, 'HOURS', 4.7, 'Шелковая фабрика Ёдгорлик в Маргилане', 'Margilan Yodgorlik Silk Factory', 'Марғилан Ёдгорлик жібек фабрикасы', 40.47180000, 71.72400000, 'Yodgorlik Silk Factory Margilan', ARRAY['margilan']::text[], ARRAY['fergana', 'margilan']::text[], 'Yodgorlik Silk Factory Margilan.jpg'),
    ('kumtepa-bazaar', 'margilan', 'MARKET', 2, 'HOURS', 4.5, 'Базар Кумтепа', 'Kumtepa Bazaar', 'Кумтепа базары', 40.49500000, 71.73000000, 'Kumtepa Bazaar Margilan', ARRAY['margilan']::text[], ARRAY['fergana', 'margilan']::text[], 'Kumtepa Bazaar Margilan.jpg'),
    ('palace-of-khudayar-khan', 'kokand', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Худояр-хана', 'Palace of Khudayar Khan', 'Хұдайяр хан сарайы', 40.52870000, 70.94280000, 'Khudayar Khan Palace Kokand', ARRAY['kokand']::text[], ARRAY['fergana', 'kokand']::text[], 'Khudayar Khan Palace Kokand.jpg'),
    ('jameh-mosque-kokand', 'kokand', 'TEMPLE', 1, 'HOURS', 4.6, 'Джума-мечеть Коканда', 'Jameh Mosque in Kokand', 'Қоқан Жұма мешіті', 40.52800000, 70.94010000, 'Jameh Mosque Kokand', ARRAY['kokand']::text[], ARRAY['kokand']::text[], 'Jameh Mosque Kokand.jpg'),
    ('rishtan-ceramic-workshops', 'rishtan', 'SHOPPING', 2, 'HOURS', 4.7, 'Керамические мастерские Риштана', 'Rishtan Ceramic Workshops', 'Риштан керамика шеберханалары', 40.35670000, 71.28470000, 'Rishtan Ceramic Workshops', ARRAY['rishtan']::text[], ARRAY['fergana', 'rishtan']::text[], 'Rishtan Ceramics Uzbekistan.jpg'),
    ('babur-literary-museum', 'andijan', 'MUSEUM', 2, 'HOURS', 4.6, 'Литературный музей Бабура', 'Babur Literary Museum', 'Бабыр әдеби музейі', 40.78330000, 72.35000000, 'Babur Museum Andijan', ARRAY['andijan']::text[], ARRAY['fergana', 'andijan']::text[], 'Babur Museum Andijan.jpg'),
    ('namangan-flowers-garden', 'namangan', 'PARK', 2, 'HOURS', 4.5, 'Сад цветов в Намангане', 'Namangan Flowers Garden', 'Наманган гүлдер бағы', 41.00000000, 71.67260000, 'Namangan Flowers Garden', ARRAY['namangan']::text[], ARRAY['fergana', 'namangan']::text[], 'Namangan Flowers Garden.jpg'),

    ('ak-saray-palace', 'shahrisabz', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Дворец Ак-Сарай', 'Ak-Saray Palace', 'Ақ-Сарай сарайы', 39.05770000, 66.83440000, 'Ak-Saray Palace Shahrisabz', ARRAY['shahrisabz']::text[], ARRAY['samarkand', 'shahrisabz']::text[], 'Ak Saray Palace Shahrisabz.jpg'),
    ('dorut-tilovat-ensemble', 'shahrisabz', 'TEMPLE', 1, 'HOURS', 4.6, 'Ансамбль Дорут Тиловат', 'Dorut Tilovat Ensemble', 'Дорут Тиловат ансамблі', 39.05550000, 66.83130000, 'Dorut Tilovat Shahrisabz', ARRAY['shahrisabz']::text[], ARRAY['shahrisabz']::text[], 'Dorut Tilovat Shahrisabz.jpg'),
    ('termez-archaeological-museum', 'termez', 'MUSEUM', 2, 'HOURS', 4.6, 'Археологический музей Термеза', 'Termez Archaeological Museum', 'Термез археологиялық музейі', 37.22420000, 67.27830000, 'Termez Archaeological Museum', ARRAY['termez']::text[], ARRAY['termez']::text[], 'Termez Archaeological Museum.jpg'),
    ('fayaztepa-buddhist-monastery', 'termez', 'TEMPLE', 2, 'HOURS', 4.6, 'Буддийский монастырь Фаязтепа', 'Fayaztepa Buddhist Monastery', 'Фаязтепа будда монастыры', 37.28760000, 67.18790000, 'Fayaztepa Buddhist Monastery Termez', ARRAY['termez']::text[], ARRAY['termez']::text[], 'Fayaztepa Buddhist Monastery.jpg'),
    ('sarmishsay-petroglyphs', 'navoi', 'NATURE', 3, 'HOURS', 4.7, 'Петроглифы Сармышсая', 'Sarmishsay Petroglyphs', 'Сармышсай петроглифтері', 40.07900000, 65.59800000, 'Sarmishsay Petroglyphs Uzbekistan', ARRAY['navoi']::text[], ARRAY['navoi']::text[], 'Sarmishsay Petroglyphs.jpg'),
    ('rabat-i-malik-caravanserai', 'navoi', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Караван-сарай Рабат-и-Малик', 'Rabat-i Malik Caravanserai', 'Рабат-и-Малик керуен сарайы', 40.11940000, 65.19020000, 'Rabat-i Malik Caravanserai', ARRAY['navoi']::text[], ARRAY['navoi']::text[], 'Rabat-i Malik Caravanserai.jpg'),
    ('chashma-complex-nurata', 'nurata', 'TEMPLE', 2, 'HOURS', 4.6, 'Комплекс Чашма в Нурате', 'Chashma Complex Nurata', 'Нұрата Чашма кешені', 40.56100000, 65.68890000, 'Chashma Complex Nurata', ARRAY['nurata']::text[], ARRAY['navoi', 'nurata']::text[], 'Chashma Complex Nurata.jpg'),
    ('nuratau-mountains', 'nurata', 'NATURE', 5, 'HOURS', 4.7, 'Горы Нуратау', 'Nuratau Mountains', 'Нұрата таулары', 40.50000000, 66.50000000, 'Nuratau Mountains Uzbekistan', ARRAY['nurata']::text[], ARRAY['navoi', 'nurata']::text[], 'Nuratau Mountains Uzbekistan.jpg'),
    ('zaamin-national-park', 'zaamin', 'NATURE', 5, 'HOURS', 4.7, 'Зааминский национальный парк', 'Zaamin National Park', 'Заамин ұлттық паркі', 39.62000000, 68.43000000, 'Zaamin National Park Uzbekistan', ARRAY['zaamin']::text[], ARRAY['samarkand', 'zaamin']::text[], 'Zaamin National Park.jpg');

CREATE TEMP TABLE seed_uzbekistan_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-uzbekistan-place:' || seed.slug) AS place_hash,
        md5('id-uzbekistan-media:' || seed.slug) AS media_hash
    FROM seed_uzbekistan_priority_places seed
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
    ARRAY['uzbekistan', city_id, slug, lower(category), 'uzbekistan-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Узбекистана: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Uzbekistan tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Өзбекстан туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    price_currency,
    rating,
    tags,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'UZ',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'UZS',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_uzbekistan_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    default_locale = EXCLUDED.default_locale,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
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
FROM seed_uzbekistan_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_uzbekistan_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_uzbekistan_resolved_places
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
FROM seed_uzbekistan_resolved_places seed
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
FROM seed_uzbekistan_resolved_places
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
    'UZ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_uzbekistan_resolved_places
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
    'UZ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_uzbekistan_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
