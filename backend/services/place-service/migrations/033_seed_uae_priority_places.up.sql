-- Priority United Arab Emirates destination places seed.
-- The UAE is seeded as one country destination, while each place is tied
-- to a concrete city or tourist hub for reference/admin filters and route search.

DROP TABLE IF EXISTS seed_uae_resolved_places;
DROP TABLE IF EXISTS seed_uae_priority_places;

CREATE TEMP TABLE seed_uae_priority_places (
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

INSERT INTO seed_uae_priority_places (
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
    ('burj-khalifa', 'dubai', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Бурдж-Халифа', 'Burj Khalifa', 'Бурдж-Халифа', 25.19720000, 55.27440000, 'Burj Khalifa Dubai United Arab Emirates', ARRAY['dubai', 'abu-dhabi', 'sharjah']::text[], ARRAY['dubai', 'abu-dhabi', 'sharjah']::text[], 'Burj_Khalifa_-_Dubai.jpg'),
    ('the-dubai-mall', 'dubai', 'SHOPPING', 3, 'HOURS', 4.8, 'Дубай Молл', 'The Dubai Mall', 'Дубай Молл', 25.19750000, 55.27960000, 'The Dubai Mall United Arab Emirates', ARRAY['dubai', 'abu-dhabi', 'sharjah']::text[], ARRAY['dubai', 'abu-dhabi', 'sharjah']::text[], 'The_Dubai_Mall.jpg'),
    ('the-dubai-fountain', 'dubai', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Фонтан Dubai Fountain', 'The Dubai Fountain', 'Dubai Fountain субұрқағы', 25.19590000, 55.27590000, 'The Dubai Fountain Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Burj_Khalifa.jpg'),
    ('dubai-frame', 'dubai', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Дубайская рамка', 'Dubai Frame', 'Дубай рамкасы', 25.23550000, 55.30030000, 'Dubai Frame United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Dubai_Frame.jpg'),
    ('museum-of-the-future', 'dubai', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей будущего', 'Museum of the Future', 'Болашақ музейі', 25.21920000, 55.28100000, 'Museum of the Future Dubai United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Museum_of_the_Future_Dubai.jpg'),
    ('al-fahidi-historical-neighbourhood', 'dubai', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Исторический район Аль-Фахиди', 'Al Fahidi Historical Neighbourhood', 'Әл-Фахиди тарихи ауданы', 25.26350000, 55.30030000, 'Al Fahidi Historical Neighbourhood Dubai United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Al_Fahidi_Fort.jpg'),
    ('al-shindagha-museum', 'dubai', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Аль-Шиндага', 'Al Shindagha Museum', 'Әл-Шиндага музейі', 25.26740000, 55.29290000, 'Al Shindagha Museum Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Al_Fahidi_Fort.jpg'),
    ('etihad-museum', 'dubai', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Этихад', 'Etihad Museum', 'Этихад музейі', 25.24100000, 55.26910000, 'Etihad Museum Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Etihad_Museum_Dubai.jpg'),
    ('jumeirah-mosque', 'dubai', 'TEMPLE', 1, 'HOURS', 4.7, 'Мечеть Джумейра', 'Jumeirah Mosque', 'Джумейра мешіті', 25.23410000, 55.26510000, 'Jumeirah Mosque Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Jumeirah_Mosque_Dubai.jpg'),
    ('gold-souk', 'dubai', 'MARKET', 2, 'HOURS', 4.6, 'Золотой рынок', 'Gold Souk', 'Алтын базары', 25.26970000, 55.29630000, 'Gold Souk Dubai United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Dubai_Gold_Souk.jpg'),
    ('spice-souk', 'dubai', 'MARKET', 1, 'HOURS', 4.5, 'Рынок специй', 'Spice Souk', 'Дәмдеуіштер базары', 25.26730000, 55.29660000, 'Spice Souk Dubai United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Dubai_Spice_Souk.jpg'),
    ('souk-madinat-jumeirah', 'dubai', 'MARKET', 2, 'HOURS', 4.6, 'Сук Мадинат Джумейра', 'Souk Madinat Jumeirah', 'Сук Мадинат Джумейра', 25.13350000, 55.18400000, 'Souk Madinat Jumeirah Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Souk_Madinat_Jumeirah.jpg'),
    ('time-out-market-dubai', 'dubai', 'FOOD', 2, 'HOURS', 4.5, 'Фуд-холл Time Out Market Dubai', 'Time Out Market Dubai', 'Time Out Market Dubai фуд-холлы', 25.19470000, 55.27770000, 'Time Out Market Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Downtown_Dubai.jpg'),
    ('mall-of-the-emirates', 'dubai', 'SHOPPING', 3, 'HOURS', 4.6, 'Молл Эмиратов', 'Mall of the Emirates', 'Эмираттар моллы', 25.11810000, 55.20060000, 'Mall of the Emirates Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Mall_of_the_Emirates.jpg'),
    ('jumeirah-beach', 'dubai', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Джумейра', 'Jumeirah Beach', 'Джумейра жағажайы', 25.20480000, 55.25300000, 'Jumeirah Beach Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Jumeirah_Beach_Dubai.jpg'),
    ('kite-beach', 'dubai', 'BEACH', 2, 'HOURS', 4.6, 'Kite Beach', 'Kite Beach', 'Kite Beach', 25.16120000, 55.20770000, 'Kite Beach Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Kite_Beach_Dubai.jpg'),
    ('jbr-beach', 'dubai', 'BEACH', 2, 'HOURS', 4.6, 'Пляж JBR', 'The Beach JBR', 'JBR жағажайы', 25.08090000, 55.13400000, 'The Beach JBR Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Jumeirah_Beach_Residence.jpg'),
    ('dubai-miracle-garden', 'dubai', 'PARK', 2, 'HOURS', 4.6, 'Сад чудес Дубая', 'Dubai Miracle Garden', 'Дубай ғажайып бағы', 25.06000000, 55.24470000, 'Dubai Miracle Garden United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Dubai_Miracle_Garden.jpg'),
    ('ras-al-khor-wildlife-sanctuary', 'dubai', 'NATURE', 2, 'HOURS', 4.5, 'Заповедник Рас-аль-Хор', 'Ras Al Khor Wildlife Sanctuary', 'Рас-әл-Хор қорығы', 25.19270000, 55.31690000, 'Ras Al Khor Wildlife Sanctuary Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Ras_Al_Khor_Wildlife_Sanctuary.jpg'),
    ('dubai-safari-park', 'dubai', 'ENTERTAINMENT', 4, 'HOURS', 4.4, 'Dubai Safari Park', 'Dubai Safari Park', 'Dubai Safari Park', 25.17410000, 55.44930000, 'Dubai Safari Park United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'Dubai_Safari_Park.jpg'),
    ('dubai-aquarium-underwater-zoo', 'dubai', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Дубайский аквариум и подводный зоопарк', 'Dubai Aquarium and Underwater Zoo', 'Дубай аквариумы және суасты зообағы', 25.19740000, 55.27920000, 'Dubai Aquarium and Underwater Zoo United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Dubai_Aquarium.jpg'),
    ('ski-dubai', 'dubai', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Ski Dubai', 'Ski Dubai', 'Ski Dubai', 25.11800000, 55.20070000, 'Ski Dubai Mall of the Emirates United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Ski_Dubai.jpg'),
    ('img-worlds-of-adventure', 'dubai', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'IMG Worlds of Adventure', 'IMG Worlds of Adventure', 'IMG Worlds of Adventure', 25.08200000, 55.32080000, 'IMG Worlds of Adventure Dubai United Arab Emirates', ARRAY['dubai', 'sharjah']::text[], ARRAY['dubai', 'sharjah']::text[], 'IMG_Worlds_of_Adventure.jpg'),
    ('aquaventure-world', 'dubai', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Aquaventure World', 'Aquaventure World', 'Aquaventure World', 25.13040000, 55.11710000, 'Aquaventure World Dubai United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Atlantis_The_Palm_Dubai.jpg'),
    ('global-village-dubai', 'dubai', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Global Village', 'Global Village', 'Global Village', 25.06700000, 55.30620000, 'Global Village Dubai United Arab Emirates', ARRAY['dubai', 'sharjah', 'ajman']::text[], ARRAY['dubai', 'sharjah', 'ajman']::text[], 'Global_Village_Dubai.jpg'),
    ('dubai-opera', 'dubai', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Дубай Опера', 'Dubai Opera', 'Дубай Опера', 25.19500000, 55.27120000, 'Dubai Opera United Arab Emirates', ARRAY['dubai']::text[], ARRAY['dubai']::text[], 'Dubai_Opera.jpg'),
    ('hatta-dam', 'hatta', 'NATURE', 2, 'HOURS', 4.7, 'Дамба Хатта', 'Hatta Dam', 'Хатта бөгеті', 24.79390000, 56.11230000, 'Hatta Dam United Arab Emirates', ARRAY['hatta', 'dubai']::text[], ARRAY['hatta', 'dubai']::text[], 'Hatta_Dam_-_UAE.jpg'),
    ('hatta-wadi-hub', 'hatta', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Hatta Wadi Hub', 'Hatta Wadi Hub', 'Hatta Wadi Hub', 24.80770000, 56.12400000, 'Hatta Wadi Hub United Arab Emirates', ARRAY['hatta', 'dubai']::text[], ARRAY['hatta', 'dubai']::text[], 'Hatta_Dam_-_UAE.jpg'),
    ('hatta-heritage-village', 'hatta', 'MUSEUM', 2, 'HOURS', 4.5, 'Этнографическая деревня Хатта', 'Hatta Heritage Village', 'Хатта мұра ауылы', 24.80400000, 56.11700000, 'Hatta Heritage Village United Arab Emirates', ARRAY['hatta', 'dubai']::text[], ARRAY['hatta', 'dubai']::text[], 'Hatta_Heritage_Village.jpg'),
    ('hatta-hill-park', 'hatta', 'PARK', 2, 'HOURS', 4.4, 'Парк Hatta Hill Park', 'Hatta Hill Park', 'Hatta Hill Park', 24.80010000, 56.12380000, 'Hatta Hill Park United Arab Emirates', ARRAY['hatta', 'dubai']::text[], ARRAY['hatta', 'dubai']::text[], 'Hatta_Dam_-_UAE.jpg'),
    ('sheikh-zayed-grand-mosque', 'abu-dhabi', 'TEMPLE', 2, 'HOURS', 4.9, 'Мечеть шейха Зайда', 'Sheikh Zayed Grand Mosque', 'Шейх Зайд мешіті', 24.41280000, 54.47490000, 'Sheikh Zayed Grand Mosque Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Sheikh_Zayed_Grand_Mosque_@_Abu_Dhabi_(15856602738).jpg'),
    ('qasr-al-watan', 'abu-dhabi', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Каср Аль Ватан', 'Qasr Al Watan', 'Қаср әл-Ватан', 24.46370000, 54.30700000, 'Qasr Al Watan Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Qasr_Al_Watan.jpg'),
    ('qasr-al-hosn', 'abu-dhabi', 'MUSEUM', 2, 'HOURS', 4.7, 'Каср Аль Хосн', 'Qasr Al Hosn', 'Қаср әл-Хосн', 24.48260000, 54.35420000, 'Qasr Al Hosn Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Qasr_Al_Hosn.jpg'),
    ('louvre-abu-dhabi', 'abu-dhabi', 'MUSEUM', 3, 'HOURS', 4.8, 'Лувр Абу-Даби', 'Louvre Abu Dhabi', 'Лувр Әбу-Даби', 24.53370000, 54.39870000, 'Louvre Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Louvre_Abu_Dhabi_01.jpg'),
    ('ferrari-world-yas-island', 'abu-dhabi', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Ferrari World на острове Яс', 'Ferrari World Yas Island', 'Ferrari World Yas Island', 24.48460000, 54.60760000, 'Ferrari World Yas Island Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Ferrari_World_Abu_Dhabi.jpg'),
    ('warner-bros-world-abu-dhabi', 'abu-dhabi', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Warner Bros. World Абу-Даби', 'Warner Bros. World Abu Dhabi', 'Warner Bros. World Abu Dhabi', 24.49100000, 54.59900000, 'Warner Bros World Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Yas_Island_Abu_Dhabi.jpg'),
    ('yas-waterworld', 'abu-dhabi', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Аквапарк Yas Waterworld', 'Yas Waterworld', 'Yas Waterworld', 24.48770000, 54.60420000, 'Yas Waterworld Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Yas_Island_Abu_Dhabi.jpg'),
    ('seaworld-yas-island', 'abu-dhabi', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'SeaWorld на острове Яс', 'SeaWorld Yas Island', 'SeaWorld Yas Island', 24.49390000, 54.60650000, 'SeaWorld Yas Island Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Yas_Island_Abu_Dhabi.jpg'),
    ('yas-marina-circuit', 'abu-dhabi', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Трасса Yas Marina Circuit', 'Yas Marina Circuit', 'Yas Marina Circuit', 24.46720000, 54.60310000, 'Yas Marina Circuit Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'Yas_Marina_Circuit.jpg'),
    ('yas-mall', 'abu-dhabi', 'SHOPPING', 3, 'HOURS', 4.5, 'Yas Mall', 'Yas Mall', 'Yas Mall', 24.48890000, 54.60800000, 'Yas Mall Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Yas_Mall.jpg'),
    ('yas-bay-waterfront', 'abu-dhabi', 'FOOD', 2, 'HOURS', 4.5, 'Набережная Yas Bay', 'Yas Bay Waterfront', 'Yas Bay Waterfront', 24.46030000, 54.60800000, 'Yas Bay Waterfront Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Yas_Island_Abu_Dhabi.jpg'),
    ('corniche-beach-abu-dhabi', 'abu-dhabi', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Корниш', 'Corniche Beach', 'Корниш жағажайы', 24.47480000, 54.33720000, 'Corniche Beach Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Abu_Dhabi_Corniche.jpg'),
    ('umm-al-emarat-park', 'abu-dhabi', 'PARK', 2, 'HOURS', 4.6, 'Парк Умм Аль Эмарат', 'Umm Al Emarat Park', 'Умм әл-Эмарат саябағы', 24.45180000, 54.38390000, 'Umm Al Emarat Park Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Umm_Al_Emarat_Park.jpg'),
    ('jubail-mangrove-park', 'abu-dhabi', 'NATURE', 2, 'HOURS', 4.7, 'Мангровый парк Джубейл', 'Jubail Mangrove Park', 'Джубейл мангр саябағы', 24.52700000, 54.45320000, 'Jubail Mangrove Park Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Abu_Dhabi_Mangroves.jpg'),
    ('mina-market-abu-dhabi', 'abu-dhabi', 'MARKET', 2, 'HOURS', 4.4, 'Рынок Мина', 'Mina Market', 'Мина базары', 24.52360000, 54.37100000, 'Mina Market Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Abu_Dhabi_Market.jpg'),
    ('world-trade-center-souk-mall', 'abu-dhabi', 'SHOPPING', 2, 'HOURS', 4.5, 'Сук и молл World Trade Center', 'World Trade Center Souk and Mall', 'World Trade Center Souk and Mall', 24.48830000, 54.35890000, 'World Trade Center Souk and Mall Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi']::text[], ARRAY['abu-dhabi']::text[], 'Abu_Dhabi_World_Trade_Center.jpg'),
    ('baps-hindu-mandir-abu-dhabi', 'abu-dhabi', 'TEMPLE', 2, 'HOURS', 4.7, 'Индуистский храм BAPS', 'BAPS Hindu Mandir Abu Dhabi', 'BAPS индуистік ғибадатханасы', 24.44920000, 54.73560000, 'BAPS Hindu Mandir Abu Dhabi United Arab Emirates', ARRAY['abu-dhabi', 'dubai']::text[], ARRAY['abu-dhabi', 'dubai']::text[], 'BAPS_Hindu_Mandir_Abu_Dhabi.jpg'),
    ('al-ain-oasis', 'al-ain', 'NATURE', 2, 'HOURS', 4.8, 'Оазис Аль-Айн', 'Al Ain Oasis', 'Әл-Айн оазисі', 24.21740000, 55.76500000, 'Al Ain Oasis United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Al_Ain_Oasis.jpg'),
    ('al-jahili-fort', 'al-ain', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Форт Аль-Джахили', 'Al Jahili Fort', 'Әл-Джахили форты', 24.22200000, 55.77390000, 'Al Jahili Fort Al Ain United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Al_Jahili_Fort.jpg'),
    ('qasr-al-muwaiji', 'al-ain', 'MUSEUM', 2, 'HOURS', 4.6, 'Каср Аль Мувайджи', 'Qasr Al Muwaiji', 'Қаср әл-Муайджи', 24.24520000, 55.73770000, 'Qasr Al Muwaiji Al Ain United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Qasr_Al_Muwaiji.jpg'),
    ('jebel-hafit-desert-park', 'al-ain', 'NATURE', 3, 'HOURS', 4.7, 'Пустынный парк Джебель-Хафит', 'Jebel Hafit Desert Park', 'Джебель-Хафит шөл саябағы', 24.05700000, 55.77800000, 'Jebel Hafit Desert Park Al Ain United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Jebel_Hafeet.jpg'),
    ('hili-archaeological-park', 'al-ain', 'PARK', 2, 'HOURS', 4.5, 'Археологический парк Хили', 'Hili Archaeological Park', 'Хили археологиялық саябағы', 24.29100000, 55.79470000, 'Hili Archaeological Park Al Ain United Arab Emirates', ARRAY['al-ain']::text[], ARRAY['al-ain']::text[], 'Hili_Archaeological_Park.jpg'),
    ('al-ain-zoo', 'al-ain', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Зоопарк Аль-Айн', 'Al Ain Zoo', 'Әл-Айн зообағы', 24.17950000, 55.73950000, 'Al Ain Zoo United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Al_Ain_Zoo.jpg'),
    ('al-ain-camel-market', 'al-ain', 'MARKET', 1, 'HOURS', 4.4, 'Верблюжий рынок Аль-Айн', 'Al Ain Camel Market', 'Әл-Айн түйе базары', 24.20070000, 55.73080000, 'Al Ain Camel Market United Arab Emirates', ARRAY['al-ain']::text[], ARRAY['al-ain']::text[], 'Al_Ain_Camel_Market.jpg'),
    ('hili-fun-city', 'al-ain', 'ENTERTAINMENT', 4, 'HOURS', 4.3, 'Hili Fun City', 'Hili Fun City', 'Hili Fun City', 24.29870000, 55.78870000, 'Hili Fun City Al Ain United Arab Emirates', ARRAY['al-ain', 'abu-dhabi']::text[], ARRAY['al-ain', 'abu-dhabi']::text[], 'Hili_Fun_City.jpg'),
    ('sharjah-museum-of-islamic-civilization', 'sharjah', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей исламской цивилизации Шарджи', 'Sharjah Museum of Islamic Civilization', 'Шарджа ислам өркениеті музейі', 25.36650000, 55.38850000, 'Sharjah Museum of Islamic Civilization United Arab Emirates', ARRAY['sharjah', 'dubai', 'ajman']::text[], ARRAY['sharjah', 'dubai', 'ajman']::text[], 'Sharjah_Museum_of_Islamic_Civilization.jpg'),
    ('heart-of-sharjah', 'sharjah', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Район Сердце Шарджи', 'Heart of Sharjah', 'Шарджа жүрегі ауданы', 25.35770000, 55.38220000, 'Heart of Sharjah United Arab Emirates', ARRAY['sharjah', 'dubai', 'ajman']::text[], ARRAY['sharjah', 'dubai', 'ajman']::text[], 'Sharjah_Heritage_Area,_UAE_(4324549568).jpg'),
    ('al-noor-island', 'sharjah', 'PARK', 2, 'HOURS', 4.6, 'Остров Аль-Нур', 'Al Noor Island', 'Әл-Нур аралы', 25.33410000, 55.38220000, 'Al Noor Island Sharjah United Arab Emirates', ARRAY['sharjah', 'dubai', 'ajman']::text[], ARRAY['sharjah', 'dubai', 'ajman']::text[], 'Al_Noor_Island.jpg'),
    ('blue-souk', 'sharjah', 'MARKET', 2, 'HOURS', 4.6, 'Центральный базар Голубой рынок', 'Blue Souk', 'Көк базар', 25.34110000, 55.38960000, 'Blue Souk Sharjah United Arab Emirates', ARRAY['sharjah', 'dubai', 'ajman']::text[], ARRAY['sharjah', 'dubai', 'ajman']::text[], 'Blue_Souk_Sharjah.jpg'),
    ('souq-al-arsah', 'sharjah', 'MARKET', 1, 'HOURS', 4.5, 'Сук Аль-Арса', 'Souq Al Arsah', 'Сук Әл-Арса', 25.35930000, 55.38270000, 'Souq Al Arsah Sharjah United Arab Emirates', ARRAY['sharjah', 'ajman']::text[], ARRAY['sharjah', 'ajman']::text[], 'Heart_of_Sharjah.jpg'),
    ('sharjah-aquarium', 'sharjah', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Аквариум Шарджи', 'Sharjah Aquarium', 'Шарджа аквариумы', 25.35280000, 55.37090000, 'Sharjah Aquarium United Arab Emirates', ARRAY['sharjah', 'ajman']::text[], ARRAY['sharjah', 'ajman']::text[], 'Sharjah_Aquarium.jpg'),
    ('al-montazah-parks', 'sharjah', 'ENTERTAINMENT', 4, 'HOURS', 4.4, 'Парк Аль-Монтаза', 'Al Montazah Parks', 'Әл-Монтаза паркі', 25.33700000, 55.37890000, 'Al Montazah Parks Sharjah United Arab Emirates', ARRAY['sharjah', 'ajman', 'dubai']::text[], ARRAY['sharjah', 'ajman', 'dubai']::text[], 'Al_Montazah_Parks.jpg'),
    ('sahara-centre', 'sharjah', 'SHOPPING', 2, 'HOURS', 4.4, 'Торговый центр Sahara Centre', 'Sahara Centre', 'Sahara Centre сауда орталығы', 25.29720000, 55.37240000, 'Sahara Centre Sharjah United Arab Emirates', ARRAY['sharjah', 'dubai', 'ajman']::text[], ARRAY['sharjah', 'dubai', 'ajman']::text[], 'Sahara_Centre_Sharjah.jpg'),
    ('khor-fakkan-beach', 'khor-fakkan', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Хор-Факкан', 'Khor Fakkan Beach', 'Хор-Факкан жағажайы', 25.33940000, 56.35950000, 'Khor Fakkan Beach United Arab Emirates', ARRAY['khor-fakkan', 'sharjah', 'fujairah']::text[], ARRAY['khor-fakkan', 'sharjah', 'fujairah']::text[], 'Khor_Fakkan_Beach.jpg'),
    ('shees-park', 'khor-fakkan', 'PARK', 2, 'HOURS', 4.6, 'Парк Шис', 'Shees Park', 'Шис саябағы', 25.29130000, 56.17750000, 'Shees Park Khor Fakkan United Arab Emirates', ARRAY['khor-fakkan', 'fujairah', 'sharjah']::text[], ARRAY['khor-fakkan', 'fujairah', 'sharjah']::text[], 'Shees_Park.jpg'),
    ('al-rafisah-dam', 'khor-fakkan', 'NATURE', 2, 'HOURS', 4.6, 'Дамба Аль-Рафиса', 'Al Rafisah Dam', 'Әл-Рафиса бөгеті', 25.31380000, 56.20260000, 'Al Rafisah Dam Khor Fakkan United Arab Emirates', ARRAY['khor-fakkan', 'fujairah', 'sharjah']::text[], ARRAY['khor-fakkan', 'fujairah', 'sharjah']::text[], 'Al_Rafisah_Dam.jpg'),
    ('khor-fakkan-amphitheatre', 'khor-fakkan', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Амфитеатр Хор-Факкана', 'Khor Fakkan Amphitheatre', 'Хор-Факкан амфитеатры', 25.33680000, 56.36390000, 'Khor Fakkan Amphitheatre United Arab Emirates', ARRAY['khor-fakkan', 'fujairah']::text[], ARRAY['khor-fakkan', 'fujairah']::text[], 'Khor_Fakkan_Amphitheatre.jpg'),
    ('ajman-museum', 'ajman', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Аджмана', 'Ajman Museum', 'Аджман музейі', 25.41220000, 55.44500000, 'Ajman Museum United Arab Emirates', ARRAY['ajman', 'sharjah', 'dubai']::text[], ARRAY['ajman', 'sharjah', 'dubai']::text[], 'Ajman_Museum.jpg'),
    ('al-zorah-nature-reserve', 'ajman', 'NATURE', 2, 'HOURS', 4.6, 'Заповедник Аль-Зора', 'Al Zorah Nature Reserve', 'Әл-Зора қорығы', 25.42610000, 55.47490000, 'Al Zorah Nature Reserve Ajman United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Al_Zorah_Nature_Reserve.jpg'),
    ('ajman-corniche', 'ajman', 'BEACH', 2, 'HOURS', 4.5, 'Набережная Аджмана', 'Ajman Corniche', 'Аджман жағалауы', 25.41750000, 55.43680000, 'Ajman Corniche United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Ajman_Corniche.jpg'),
    ('saleh-souq', 'ajman', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Салех', 'Saleh Souq', 'Салех базары', 25.41090000, 55.44450000, 'Saleh Souq Ajman United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Ajman_Museum.jpg'),
    ('ajman-fish-market', 'ajman', 'MARKET', 1, 'HOURS', 4.4, 'Рыбный рынок Аджмана', 'Ajman Fish Market', 'Аджман балық базары', 25.40860000, 55.45630000, 'Ajman Fish Market United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Ajman_Fish_Market.jpg'),
    ('ajman-city-centre-mall', 'ajman', 'SHOPPING', 2, 'HOURS', 4.4, 'Торговый центр Ajman City Centre', 'Ajman City Centre Mall', 'Ajman City Centre Mall', 25.39940000, 55.47760000, 'Ajman City Centre Mall United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Ajman_City_Centre.jpg'),
    ('marsa-ajman', 'ajman', 'FOOD', 2, 'HOURS', 4.4, 'Марса Аджман', 'Marsa Ajman', 'Марса Аджман', 25.41290000, 55.44460000, 'Marsa Ajman United Arab Emirates', ARRAY['ajman', 'sharjah']::text[], ARRAY['ajman', 'sharjah']::text[], 'Ajman_Corniche.jpg'),
    ('jebel-jais', 'ras-al-khaimah', 'NATURE', 4, 'HOURS', 4.8, 'Джебель-Джайс', 'Jebel Jais', 'Джебель-Джайс', 25.94140000, 56.12960000, 'Jebel Jais Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah', 'dubai']::text[], ARRAY['ras-al-khaimah', 'dubai']::text[], 'Jebel_Jais_Ras_Al_Khaimah.jpg'),
    ('jais-flight-jais-sledder', 'ras-al-khaimah', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Jais Flight и Jais Sledder', 'Jais Flight and Jais Sledder', 'Jais Flight және Jais Sledder', 25.93360000, 56.13290000, 'Jais Flight Jais Sledder Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah', 'dubai']::text[], ARRAY['ras-al-khaimah', 'dubai']::text[], 'Jebel_Jais_Ras_Al_Khaimah.jpg'),
    ('dhayah-fort', 'ras-al-khaimah', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Форт Дайя', 'Dhayah Fort', 'Дайя форты', 25.89790000, 56.06140000, 'Dhayah Fort Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'Dhayah_Fort.jpg'),
    ('national-museum-ras-al-khaimah', 'ras-al-khaimah', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный музей Рас-эль-Хаймы', 'National Museum of Ras Al Khaimah', 'Рас-эль-Хайма ұлттық музейі', 25.78830000, 55.94560000, 'National Museum of Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'National_Museum_Ras_Al_Khaimah.jpg'),
    ('flamingo-beach-rak', 'ras-al-khaimah', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Фламинго', 'Flamingo Beach', 'Фламинго жағажайы', 25.72680000, 55.84530000, 'Flamingo Beach Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'Ras_Al_Khaimah_Beach.jpg'),
    ('kuwaiti-souq-rak', 'ras-al-khaimah', 'MARKET', 1, 'HOURS', 4.3, 'Кувейтский сук', 'Kuwaiti Souq', 'Кувейт сугі', 25.78990000, 55.94340000, 'Kuwaiti Souq Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'Ras_Al_Khaimah_Souq.jpg'),
    ('al-hamra-mall', 'ras-al-khaimah', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Al Hamra Mall', 'Al Hamra Mall', 'Al Hamra Mall', 25.68140000, 55.78090000, 'Al Hamra Mall Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'Al_Hamra_Mall.jpg'),
    ('saqr-park', 'ras-al-khaimah', 'PARK', 2, 'HOURS', 4.4, 'Парк Сакр', 'Saqr Park', 'Сакр саябағы', 25.75270000, 55.93660000, 'Saqr Park Ras Al Khaimah United Arab Emirates', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah']::text[], 'Saqr_Park.jpg'),
    ('fujairah-fort', 'fujairah', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Форт Фуджейры', 'Fujairah Fort', 'Фуджейра форты', 25.13560000, 56.33780000, 'Fujairah Fort United Arab Emirates', ARRAY['fujairah', 'khor-fakkan']::text[], ARRAY['fujairah', 'khor-fakkan']::text[], 'Fujairah_Fort_(1).jpg'),
    ('al-bidya-mosque', 'fujairah', 'TEMPLE', 1, 'HOURS', 4.6, 'Мечеть Аль-Бидья', 'Al Bidya Mosque', 'Әл-Бидья мешіті', 25.43890000, 56.35340000, 'Al Bidya Mosque Fujairah United Arab Emirates', ARRAY['fujairah', 'khor-fakkan']::text[], ARRAY['fujairah', 'khor-fakkan']::text[], 'Al_Bidya_Mosque.jpg'),
    ('fujairah-museum', 'fujairah', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Фуджейры', 'Fujairah Museum', 'Фуджейра музейі', 25.13440000, 56.33840000, 'Fujairah Museum United Arab Emirates', ARRAY['fujairah']::text[], ARRAY['fujairah']::text[], 'Fujairah_Museum.jpg'),
    ('al-aqah-beach-snoopy-island', 'fujairah', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Аль-Ака и остров Снупи', 'Al Aqah Beach and Snoopy Island', 'Әл-Ақа жағажайы және Снупи аралы', 25.49260000, 56.36320000, 'Al Aqah Beach Snoopy Island Fujairah United Arab Emirates', ARRAY['fujairah', 'khor-fakkan']::text[], ARRAY['fujairah', 'khor-fakkan']::text[], 'Snoopy_Island_Fujairah.jpg'),
    ('souq-al-juma-friday-market', 'fujairah', 'MARKET', 1, 'HOURS', 4.4, 'Сук аль-Джума', 'Souq Al Juma Friday Market', 'Сук әл-Джума базары', 25.30920000, 56.16270000, 'Souq Al Juma Friday Market Fujairah United Arab Emirates', ARRAY['fujairah', 'khor-fakkan']::text[], ARRAY['fujairah', 'khor-fakkan']::text[], 'Masafi_Friday_Market.jpg'),
    ('city-centre-fujairah', 'fujairah', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ City Centre Fujairah', 'City Centre Fujairah', 'City Centre Fujairah', 25.12200000, 56.30370000, 'City Centre Fujairah United Arab Emirates', ARRAY['fujairah']::text[], ARRAY['fujairah']::text[], 'City_Centre_Fujairah.jpg'),
    ('fujairah-adventure-park', 'fujairah', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Парк приключений Фуджейры', 'Fujairah Adventure Park', 'Фуджейра шытырман саябағы', 25.16870000, 56.30690000, 'Fujairah Adventure Park United Arab Emirates', ARRAY['fujairah', 'khor-fakkan']::text[], ARRAY['fujairah', 'khor-fakkan']::text[], 'Fujairah_Mountains.jpg'),
    ('umm-al-quwain-fort-museum', 'umm-al-quwain', 'MUSEUM', 2, 'HOURS', 4.4, 'Форт и музей Умм-эль-Кувейна', 'Umm Al Quwain Fort and Museum', 'Умм-эль-Кувейн форты және музейі', 25.56570000, 55.55310000, 'Umm Al Quwain Fort and Museum United Arab Emirates', ARRAY['umm-al-quwain', 'ajman', 'ras-al-khaimah']::text[], ARRAY['umm-al-quwain', 'ajman', 'ras-al-khaimah']::text[], 'Umm_Al_Quwain_Fort.jpg'),
    ('dreamland-aqua-park', 'umm-al-quwain', 'ENTERTAINMENT', 4, 'HOURS', 4.4, 'Dreamland Aqua Park', 'Dreamland Aqua Park', 'Dreamland Aqua Park', 25.59920000, 55.64110000, 'Dreamland Aqua Park Umm Al Quwain United Arab Emirates', ARRAY['umm-al-quwain', 'ajman', 'ras-al-khaimah']::text[], ARRAY['umm-al-quwain', 'ajman', 'ras-al-khaimah']::text[], 'Dreamland_Aqua_Park.jpg'),
    ('mangrove-beach-umm-al-quwain', 'umm-al-quwain', 'NATURE', 2, 'HOURS', 4.5, 'Мангровый пляж Умм-эль-Кувейна', 'Mangrove Beach Umm Al Quwain', 'Умм-эль-Кувейн мангр жағажайы', 25.54440000, 55.57710000, 'Mangrove Beach Umm Al Quwain United Arab Emirates', ARRAY['umm-al-quwain', 'ajman']::text[], ARRAY['umm-al-quwain', 'ajman']::text[], 'Umm_Al_Quwain_mangroves_(7267363924).jpg'),
    ('falaj-al-mualla-fort', 'umm-al-quwain', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Форт Фаладж Аль-Муалла', 'Falaj Al Mualla Fort', 'Фаладж әл-Муалла форты', 25.35580000, 55.85360000, 'Falaj Al Mualla Fort Umm Al Quwain United Arab Emirates', ARRAY['umm-al-quwain']::text[], ARRAY['umm-al-quwain']::text[], 'Falaj_Al_Mualla_Fort.jpg');

CREATE TEMP TABLE seed_uae_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-uae-place:' || seed.slug) AS place_hash,
        md5('id-uae-media:' || seed.slug) AS media_hash
    FROM seed_uae_priority_places seed
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
    ARRAY['uae', city_id, slug, lower(category), 'uae-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка ОАЭ: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'UAE tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'БАЭ туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'AE',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 50::numeric
        ELSE 25::numeric
    END,
    'AED',
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
FROM seed_uae_resolved_places
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
FROM seed_uae_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_uae_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_uae_resolved_places
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
FROM seed_uae_resolved_places seed
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
FROM seed_uae_resolved_places
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
    'AE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_uae_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'AE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_uae_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_uae_resolved_places;
DROP TABLE IF EXISTS seed_uae_priority_places;
