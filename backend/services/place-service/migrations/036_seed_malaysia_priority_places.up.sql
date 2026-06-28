-- Priority Malaysia destination places seed.
-- Malaysia is seeded as a country destination with concrete city hubs for
-- admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_malaysia_resolved_places;
DROP TABLE IF EXISTS seed_malaysia_priority_places;

CREATE TEMP TABLE seed_malaysia_priority_places (
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

INSERT INTO seed_malaysia_priority_places (
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
    ('petronas-twin-towers', 'kuala-lumpur', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Башни Петронас', 'Petronas Twin Towers', 'Петронас мұнаралары', 3.15790000, 101.71230000, 'Petronas Twin Towers Kuala Lumpur Malaysia', ARRAY['kuala-lumpur', 'selangor', 'putrajaya']::text[], ARRAY['kuala-lumpur']::text[], 'Petronas_Towers_Kuala_Lumpur_Malaysia.jpg'),
    ('kl-tower', 'kuala-lumpur', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Башня KL Tower', 'KL Tower', 'KL Tower мұнарасы', 3.15280000, 101.70370000, 'KL Tower Kuala Lumpur Malaysia', ARRAY['kuala-lumpur', 'selangor']::text[], ARRAY['kuala-lumpur']::text[], 'KL_Tower_Kuala_Lumpur.jpg'),
    ('merdeka-square', 'kuala-lumpur', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Мердека', 'Merdeka Square', 'Мердека алаңы', 3.14770000, 101.69340000, 'Merdeka Square Kuala Lumpur Malaysia', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Merdeka_Square_Kuala_Lumpur.jpg'),
    ('islamic-arts-museum-malaysia', 'kuala-lumpur', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей исламского искусства Малайзии', 'Islamic Arts Museum Malaysia', 'Малайзия ислам өнері музейі', 3.14170000, 101.68910000, 'Islamic Arts Museum Malaysia Kuala Lumpur', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Islamic_Arts_Museum_Malaysia.jpg'),
    ('central-market-kuala-lumpur', 'kuala-lumpur', 'MARKET', 2, 'HOURS', 4.6, 'Центральный рынок Куала-Лумпура', 'Central Market Kuala Lumpur', 'Куала-Лумпур орталық базары', 3.14580000, 101.69530000, 'Central Market Kuala Lumpur Malaysia', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Central_Market_Kuala_Lumpur.jpg'),
    ('petaling-street-chinatown', 'kuala-lumpur', 'MARKET', 2, 'HOURS', 4.5, 'Чайнатаун на Petaling Street', 'Petaling Street Chinatown', 'Petaling Street Қытай қаласы', 3.14420000, 101.69790000, 'Petaling Street Chinatown Kuala Lumpur', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Petaling_Street_Kuala_Lumpur.jpg'),
    ('jalan-alor-food-street', 'kuala-lumpur', 'FOOD', 2, 'HOURS', 4.6, 'Фуд-стрит Jalan Alor', 'Jalan Alor Food Street', 'Jalan Alor тағам көшесі', 3.14500000, 101.70890000, 'Jalan Alor Kuala Lumpur Malaysia', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Jalan_Alor_Kuala_Lumpur.jpg'),
    ('perdana-botanical-garden', 'kuala-lumpur', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Пердана', 'Perdana Botanical Garden', 'Пердана ботаникалық бағы', 3.14310000, 101.68430000, 'Perdana Botanical Garden Kuala Lumpur', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Perdana_Botanical_Garden.jpg'),
    ('aquaria-klcc', 'kuala-lumpur', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Океанариум Aquaria KLCC', 'Aquaria KLCC', 'Aquaria KLCC океанариумы', 3.15310000, 101.71310000, 'Aquaria KLCC Kuala Lumpur', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Aquaria_KLCC.jpg'),
    ('thean-hou-temple', 'kuala-lumpur', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Thean Hou', 'Thean Hou Temple', 'Thean Hou ғибадатханасы', 3.12190000, 101.68750000, 'Thean Hou Temple Kuala Lumpur', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], 'Thean_Hou_Temple_Kuala_Lumpur.jpg'),
    ('batu-caves', 'selangor', 'TEMPLE', 2, 'HOURS', 4.8, 'Пещеры Бату', 'Batu Caves', 'Бату үңгірлері', 3.23790000, 101.68400000, 'Batu Caves Selangor Malaysia', ARRAY['selangor', 'kuala-lumpur']::text[], ARRAY['kuala-lumpur', 'selangor']::text[], 'Batu_Caves_Murugan_Statue.jpg'),
    ('sunway-lagoon', 'selangor', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Sunway Lagoon', 'Sunway Lagoon', 'Sunway Lagoon', 3.07140000, 101.60520000, 'Sunway Lagoon Selangor Malaysia', ARRAY['selangor', 'kuala-lumpur', 'putrajaya']::text[], ARRAY['selangor', 'kuala-lumpur']::text[], 'Sunway_Lagoon.jpg'),
    ('i-city-shah-alam', 'selangor', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'i-City Shah Alam', 'i-City Shah Alam', 'i-City Shah Alam', 3.06530000, 101.48430000, 'i-City Shah Alam Selangor', ARRAY['selangor', 'kuala-lumpur']::text[], ARRAY['selangor']::text[], 'I-City_Shah_Alam.jpg'),
    ('forest-research-institute-malaysia', 'selangor', 'NATURE', 3, 'HOURS', 4.7, 'Лесной парк FRIM Selangor', 'Forest Research Institute Malaysia Forest Park Selangor', 'FRIM Selangor орман паркі', 3.23670000, 101.63470000, 'FRIM Forest Park Selangor Malaysia', ARRAY['selangor', 'kuala-lumpur']::text[], ARRAY['selangor', 'kuala-lumpur']::text[], 'FRIM_01.jpg'),
    ('kuala-selangor-fireflies', 'selangor', 'NATURE', 2, 'HOURS', 4.6, 'Светлячки Куала-Селангор', 'Kuala Selangor Fireflies', 'Куала-Селангор жарқырауықтары', 3.34860000, 101.24690000, 'Kuala Selangor Fireflies Malaysia', ARRAY['selangor', 'kuala-lumpur']::text[], ARRAY['selangor', 'kuala-lumpur']::text[], 'Kuala_Selangor_Fireflies.jpg'),
    ('putrajaya-mosque', 'putrajaya', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мечеть Путра', 'Putrajaya Mosque', 'Путра мешіті', 2.93500000, 101.68900000, 'Putra Mosque Putrajaya Malaysia', ARRAY['putrajaya', 'kuala-lumpur', 'selangor']::text[], ARRAY['putrajaya', 'kuala-lumpur']::text[], 'Putra_Mosque_Putrajaya.jpg'),
    ('putrajaya-botanical-garden', 'putrajaya', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Путраджаи', 'Putrajaya Botanical Garden', 'Путраджая ботаникалық бағы', 2.94440000, 101.69540000, 'Putrajaya Botanical Garden Malaysia', ARRAY['putrajaya', 'kuala-lumpur']::text[], ARRAY['putrajaya']::text[], 'Putrajaya_Botanical_Garden.jpg'),
    ('ioi-city-mall', 'putrajaya', 'SHOPPING', 3, 'HOURS', 4.5, 'IOI City Mall', 'IOI City Mall', 'IOI City Mall', 2.97090000, 101.71380000, 'IOI City Mall Putrajaya Malaysia', ARRAY['putrajaya', 'kuala-lumpur', 'selangor']::text[], ARRAY['putrajaya']::text[], 'IOI_City_Mall.jpg'),

    ('george-town-unesco-heritage-core', 'george-town', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Исторический центр Джорджтауна UNESCO', 'George Town UNESCO Heritage Core', 'Джорджтаун UNESCO тарихи орталығы', 5.41410000, 100.32880000, 'George Town UNESCO Heritage Core Penang Malaysia', ARRAY['george-town', 'penang']::text[], ARRAY['george-town', 'penang']::text[], 'George_Town_Penang.jpg'),
    ('penang-hill', 'penang', 'NATURE', 3, 'HOURS', 4.7, 'Холм Пенанг', 'Penang Hill', 'Пенанг төбесі', 5.42440000, 100.26970000, 'Penang Hill Malaysia', ARRAY['penang', 'george-town']::text[], ARRAY['penang', 'george-town']::text[], 'Penang_Hill.jpg'),
    ('kek-lok-si-temple', 'penang', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Кек Лок Си', 'Kek Lok Si Temple', 'Кек Лок Си ғибадатханасы', 5.39990000, 100.27320000, 'Kek Lok Si Temple Penang Malaysia', ARRAY['penang', 'george-town']::text[], ARRAY['penang']::text[], 'Kek_Lok_Si_Temple_Penang.jpg'),
    ('pinang-peranakan-mansion', 'george-town', 'MUSEUM', 2, 'HOURS', 4.7, 'Pinang Peranakan Mansion', 'Pinang Peranakan Mansion', 'Pinang Peranakan Mansion', 5.41730000, 100.34030000, 'Pinang Peranakan Mansion George Town', ARRAY['george-town', 'penang']::text[], ARRAY['george-town']::text[], 'Pinang_Peranakan_Mansion.JPG'),
    ('fort-cornwallis', 'george-town', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Форт Корнуоллис', 'Fort Cornwallis', 'Корнуоллис қамалы', 5.42020000, 100.34450000, 'Fort Cornwallis Penang Malaysia', ARRAY['george-town', 'penang']::text[], ARRAY['george-town']::text[], 'Fort_Cornwallis_Penang.jpg'),
    ('clan-jetties-chew-jetty', 'george-town', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Клановые причалы Chew Jetty', 'Clan Jetties Chew Jetty', 'Chew Jetty кландық айлақтары', 5.41030000, 100.34060000, 'Chew Jetty George Town Penang', ARRAY['george-town', 'penang']::text[], ARRAY['george-town']::text[], 'Chew_Jetty_Penang.jpg'),
    ('entopia-penang', 'penang', 'PARK', 2, 'HOURS', 4.6, 'Entopia by Penang Butterfly Farm', 'Entopia by Penang Butterfly Farm', 'Entopia көбелек паркі', 5.44820000, 100.21480000, 'Entopia Penang Butterfly Farm Malaysia', ARRAY['penang']::text[], ARRAY['penang']::text[], 'Entopia_Penang.jpg'),
    ('batu-ferringhi-beach', 'penang', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Бату Ферринги', 'Batu Ferringhi Beach', 'Бату Ферринги жағажайы', 5.47520000, 100.24910000, 'Batu Ferringhi Beach Penang Malaysia', ARRAY['penang', 'george-town']::text[], ARRAY['penang']::text[], 'Batu_Ferringhi_Beach.jpg'),
    ('batu-ferringhi-night-market', 'penang', 'MARKET', 2, 'HOURS', 4.4, 'Ночной рынок Бату Ферринги', 'Batu Ferringhi Night Market', 'Бату Ферринги түнгі базары', 5.47500000, 100.24760000, 'Batu Ferringhi Night Market Penang', ARRAY['penang']::text[], ARRAY['penang']::text[], 'Batu_Ferringhi_Night_Market.jpg'),
    ('gurney-plaza', 'penang', 'SHOPPING', 2, 'HOURS', 4.5, 'Gurney Plaza', 'Gurney Plaza', 'Gurney Plaza', 5.43780000, 100.30900000, 'Gurney Plaza Penang Malaysia', ARRAY['penang', 'george-town']::text[], ARRAY['penang']::text[], 'Gurney_Plaza.jpg'),
    ('langkawi-sky-bridge', 'langkawi', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'SkyCab и SkyBridge Лангкави', 'Langkawi Sky Bridge', 'Лангкави аспан көпірі', 6.37110000, 99.67160000, 'Langkawi Sky Bridge Malaysia', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Langkawi_Sky_Bridge.jpg'),
    ('kilim-geoforest-park', 'langkawi', 'NATURE', 4, 'HOURS', 4.8, 'Геопарк Килим', 'Kilim Geoforest Park', 'Килим геоорман паркі', 6.40880000, 99.85830000, 'Kilim Geoforest Park Langkawi', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Kilim_Geoforest_Park_Langkawi.jpg'),
    ('pantai-cenang', 'langkawi', 'BEACH', 3, 'HOURS', 4.6, 'Пантай Ченанг', 'Pantai Cenang', 'Пантай Ченанг', 6.29390000, 99.72780000, 'Pantai Cenang Langkawi Malaysia', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Pantai_Cenang_Langkawi.jpg'),
    ('tanjung-rhu-beach', 'langkawi', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Танджунг Ру', 'Tanjung Rhu Beach', 'Танджунг Ру жағажайы', 6.45750000, 99.82370000, 'Tanjung Rhu Beach Langkawi', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Tanjung_Rhu_Beach.jpg'),
    ('underwater-world-langkawi', 'langkawi', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Underwater World Langkawi', 'Underwater World Langkawi', 'Underwater World Langkawi', 6.29180000, 99.72870000, 'Underwater World Langkawi Malaysia', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Underwater_World_Langkawi.jpg'),
    ('eagle-square-langkawi', 'langkawi', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Площадь Орла Dataran Lang', 'Eagle Square Dataran Lang', 'Dataran Lang бүркіт алаңы', 6.30510000, 99.85030000, 'Eagle Square Langkawi Malaysia', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Eagle_Square_Langkawi.jpg'),
    ('langkawi-night-market', 'langkawi', 'MARKET', 2, 'HOURS', 4.4, 'Ночной рынок Лангкави', 'Langkawi Night Market', 'Лангкави түнгі базары', 6.32610000, 99.84690000, 'Langkawi Night Market Malaysia', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], 'Langkawi_Night_Market.jpg'),

    ('melaka-unesco-dutch-square', 'melaka', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Мелаки и Dutch Square', 'Melaka UNESCO Historic Core', 'Малакка UNESCO тарихи орталығы', 2.19440000, 102.24930000, 'Melaka UNESCO Historic Core Dutch Square Malaysia', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Dutch_Square_Melaka.jpg'),
    ('a-famosa', 'melaka', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'A Famosa', 'A Famosa', 'A Famosa', 2.19190000, 102.25030000, 'A Famosa Melaka Malaysia', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'A_Famosa_Melaka.jpg'),
    ('jonker-street-night-market', 'melaka', 'MARKET', 2, 'HOURS', 4.7, 'Ночной рынок Jonker Street', 'Jonker Street Night Market', 'Jonker Street түнгі базары', 2.19630000, 102.24640000, 'Jonker Street Night Market Melaka', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Jonker_Street_Night_Market_Melaka.jpg'),
    ('baba-nyonya-heritage-museum', 'melaka', 'MUSEUM', 2, 'HOURS', 4.7, 'Baba & Nyonya Heritage Museum', 'Baba & Nyonya Heritage Museum', 'Baba & Nyonya Heritage Museum', 2.19680000, 102.24730000, 'Baba Nyonya Heritage Museum Melaka', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Baba_Nyonya_Heritage_Museum.JPG'),
    ('cheng-hoon-teng-temple', 'melaka', 'TEMPLE', 1, 'HOURS', 4.6, 'Храм Cheng Hoon Teng', 'Cheng Hoon Teng Temple', 'Cheng Hoon Teng ғибадатханасы', 2.19670000, 102.24610000, 'Cheng Hoon Teng Temple Melaka', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Cheng_Hoon_Teng_Temple_Melaka.jpg'),
    ('melaka-river-cruise', 'melaka', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Круиз по реке Мелака', 'Melaka River Cruise', 'Малакка өзені круизі', 2.20060000, 102.24680000, 'Melaka River Cruise Malaysia', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Melaka_River.jpg'),
    ('dataran-pahlawan-melaka-megamall', 'melaka', 'SHOPPING', 2, 'HOURS', 4.4, 'Dataran Pahlawan Melaka Megamall', 'Dataran Pahlawan Melaka Megamall', 'Dataran Pahlawan Melaka Megamall', 2.19130000, 102.24950000, 'Dataran Pahlawan Melaka Megamall', ARRAY['melaka']::text[], ARRAY['melaka']::text[], 'Dataran_Pahlawan_Melaka_Megamall.jpg'),
    ('ipoh-old-town-concubine-lane', 'ipoh', 'FOOD', 2, 'HOURS', 4.6, 'Старый Ипох и Concubine Lane', 'Ipoh Old Town & Concubine Lane', 'Ескі Ипох және Concubine Lane', 4.59740000, 101.07770000, 'Ipoh Old Town Concubine Lane Malaysia', ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Concubine_Lane_Ipoh.jpg'),
    ('han-chin-pet-soo', 'ipoh', 'MUSEUM', 2, 'HOURS', 4.7, 'Han Chin Pet Soo', 'Han Chin Pet Soo', 'Han Chin Pet Soo', 4.59780000, 101.07840000, 'Han Chin Pet Soo Ipoh Malaysia', ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Han_Chin_Pet_Soo.jpg'),
    ('kek-lok-tong-cave-temple', 'ipoh', 'TEMPLE', 2, 'HOURS', 4.7, 'Пещерный храм Kek Lok Tong', 'Kek Lok Tong Cave Temple', 'Kek Lok Tong үңгір ғибадатханасы', 4.55940000, 101.12950000, 'Kek Lok Tong Cave Temple Ipoh', ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Kek_Lok_Tong_Cave_Temple.jpg'),
    ('kellies-castle', 'ipoh', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Замок Келли', $$Kellie's Castle$$, 'Келли қамалы', 4.47450000, 101.09120000, $$Kellie's Castle Perak Malaysia$$, ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Kellies_Castle.jpg'),
    ('gerbang-malam-ipoh', 'ipoh', 'MARKET', 2, 'HOURS', 4.4, 'Ночной рынок Gerbang Malam Ipoh', 'Gerbang Malam Ipoh', 'Gerbang Malam Ipoh түнгі базары', 4.59650000, 101.08490000, 'Gerbang Malam Ipoh Night Market', ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Gerbang_Malam_Ipoh.jpg'),
    ('lost-world-of-tambun', 'ipoh', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Lost World of Tambun', 'Lost World of Tambun', 'Lost World of Tambun', 4.62680000, 101.15420000, 'Lost World of Tambun Ipoh Malaysia', ARRAY['ipoh']::text[], ARRAY['ipoh']::text[], 'Lost_World_of_Tambun.jpg'),
    ('mossy-forest-cameron-highlands', 'cameron-highlands', 'NATURE', 3, 'HOURS', 4.7, 'Mossy Forest Eco Park', 'Mossy Forest Eco Park', 'Mossy Forest Eco Park', 4.52270000, 101.38160000, 'Mossy Forest Cameron Highlands Malaysia', ARRAY['cameron-highlands', 'ipoh']::text[], ARRAY['cameron-highlands', 'ipoh']::text[], 'Mossy_Forest_Cameron_Highlands.jpg'),
    ('cameron-boh-tea-centre', 'cameron-highlands', 'NATURE', 2, 'HOURS', 4.7, 'Чайный центр BOH Cameron Highlands', 'Cameron BOH Tea Centre', 'Cameron BOH шай орталығы', 4.51460000, 101.40820000, 'BOH Tea Centre Cameron Highlands Malaysia', ARRAY['cameron-highlands']::text[], ARRAY['cameron-highlands']::text[], 'BOH_Tea_Plantation_Cameron_Highlands.jpg'),
    ('kea-farm-market', 'cameron-highlands', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Kea Farm', 'Kea Farm Market', 'Kea Farm базары', 4.50230000, 101.40820000, 'Kea Farm Market Cameron Highlands', ARRAY['cameron-highlands']::text[], ARRAY['cameron-highlands']::text[], 'Kea_Farm_Cameron_Highlands.jpg'),

    ('tunku-abdul-rahman-park', 'kota-kinabalu', 'PARK', 4, 'HOURS', 4.8, 'Морской парк Тунку Абдул Рахман', 'Tunku Abdul Rahman Park', 'Тунку Абдул Рахман паркі', 5.97330000, 116.02190000, 'Tunku Abdul Rahman Park Kota Kinabalu', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Tunku_Abdul_Rahman_National_Park.jpg'),
    ('tanjung-aru-beach', 'kota-kinabalu', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Танджунг-Ару', 'Tanjung Aru Beach', 'Танджунг-Ару жағажайы', 5.94750000, 116.04690000, 'Tanjung Aru Beach Kota Kinabalu', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Tanjung_Aru_Beach_and_the_Islands.jpg'),
    ('sabah-museum-complex', 'kota-kinabalu', 'MUSEUM', 2, 'HOURS', 4.5, 'Музейный комплекс Сабаха', 'Sabah Museum Complex', 'Сабах музей кешені', 5.96270000, 116.07150000, 'Sabah Museum Complex Kota Kinabalu', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Sabah_Museum.jpg'),
    ('gaya-street-sunday-market', 'kota-kinabalu', 'MARKET', 2, 'HOURS', 4.5, 'Воскресный рынок Gaya Street', 'Gaya Street Sunday Market', 'Gaya Street жексенбі базары', 5.98400000, 116.07620000, 'Gaya Street Sunday Market Kota Kinabalu', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Gaya_Street_Kota_Kinabalu.jpg'),
    ('kota-kinabalu-city-mosque', 'kota-kinabalu', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Городская мечеть Кота-Кинабалу', 'Kota Kinabalu City Mosque', 'Кота-Кинабалу қалалық мешіті', 5.99570000, 116.10790000, 'Kota Kinabalu City Mosque Malaysia', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'KotaKinabalu_Sabah_CityMosque-00.jpg'),
    ('imago-shopping-mall', 'kota-kinabalu', 'SHOPPING', 2, 'HOURS', 4.4, 'Imago Shopping Mall', 'Imago Shopping Mall', 'Imago Shopping Mall', 5.97090000, 116.06650000, 'Imago Shopping Mall Kota Kinabalu', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Imago_Shopping_Mall.jpg'),
    ('kinabalu-park', 'kota-kinabalu', 'NATURE', 5, 'HOURS', 4.9, 'Парк Кинабалу', 'Kinabalu Park', 'Кинабалу паркі', 6.07530000, 116.55860000, 'Kinabalu Park Sabah Malaysia', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], 'Mount_Kinabalu.jpg'),
    ('sepilok-orangutan-rehabilitation-centre', 'sandakan', 'NATURE', 3, 'HOURS', 4.8, 'Центр реабилитации орангутанов Sepilok', 'Sepilok Orangutan Rehabilitation Centre', 'Sepilok орангутан орталығы', 5.86440000, 117.94720000, 'Sepilok Orangutan Rehabilitation Centre Sabah', ARRAY['sandakan']::text[], ARRAY['sandakan']::text[], 'Sepilok_Orangutan_Rehabilitation_Centre.jpg'),
    ('bornean-sun-bear-conservation-centre', 'sandakan', 'NATURE', 2, 'HOURS', 4.7, 'Центр сохранения малайских медведей', 'Bornean Sun Bear Conservation Centre', 'Борнео күн аюы орталығы', 5.86450000, 117.94790000, 'Bornean Sun Bear Conservation Centre Sabah', ARRAY['sandakan']::text[], ARRAY['sandakan']::text[], 'Bornean_Sun_Bear_Conservation_Centre.jpg'),
    ('rainforest-discovery-centre', 'sandakan', 'NATURE', 3, 'HOURS', 4.7, 'Rainforest Discovery Centre', 'Rainforest Discovery Centre', 'Rainforest Discovery Centre', 5.87250000, 117.94490000, 'Rainforest Discovery Centre Sandakan Sabah', ARRAY['sandakan']::text[], ARRAY['sandakan']::text[], 'Rainforest_Discovery_Centre_Sepilok.jpg'),
    ('turtle-islands-park', 'sandakan', 'PARK', 4, 'HOURS', 4.7, 'Парк Turtle Islands', 'Turtle Islands Park', 'Turtle Islands паркі', 6.17350000, 118.06490000, 'Turtle Islands Park Sabah Malaysia', ARRAY['sandakan']::text[], ARRAY['sandakan']::text[], 'Turtle_Islands_Park_Sabah.jpg'),
    ('sipadan-island', 'semporna', 'NATURE', 5, 'HOURS', 4.9, 'Остров Сипадан', 'Sipadan Island', 'Сипадан аралы', 4.11470000, 118.62870000, 'Sipadan Island Sabah Malaysia', ARRAY['semporna']::text[], ARRAY['semporna']::text[], 'Sipadan_Island.jpg'),
    ('mabul-island', 'semporna', 'BEACH', 4, 'HOURS', 4.8, 'Остров Мабул', 'Mabul Island', 'Мабул аралы', 4.24600000, 118.63180000, 'Mabul Island Semporna Sabah', ARRAY['semporna']::text[], ARRAY['semporna']::text[], 'Mabul_Island_Borneo.jpg'),
    ('bohey-dulang', 'semporna', 'NATURE', 4, 'HOURS', 4.8, 'Bohey Dulang', 'Bohey Dulang', 'Bohey Dulang', 4.60000000, 118.76670000, 'Bohey Dulang Semporna Sabah', ARRAY['semporna']::text[], ARRAY['semporna']::text[], 'Bohey_Dulang.jpg'),
    ('sarawak-cultural-village', 'kuching', 'MUSEUM', 3, 'HOURS', 4.7, 'Культурная деревня Саравака', 'Sarawak Cultural Village', 'Саравак мәдени ауылы', 1.74960000, 110.31580000, 'Sarawak Cultural Village Kuching Malaysia', ARRAY['kuching']::text[], ARRAY['kuching']::text[], 'Sarawak_Cultural_Village.jpg'),
    ('borneo-cultures-museum', 'kuching', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей культур Борнео', 'Borneo Cultures Museum', 'Борнео мәдениеттері музейі', 1.55780000, 110.34460000, 'Borneo Cultures Museum Kuching', ARRAY['kuching']::text[], ARRAY['kuching']::text[], 'Borneo_Cultures_Museum.jpg'),
    ('bako-national-park', 'kuching', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Бако', 'Bako National Park', 'Бако ұлттық паркі', 1.71670000, 110.46670000, 'Bako National Park Sarawak Malaysia', ARRAY['kuching']::text[], ARRAY['kuching']::text[], 'Bako_National_Park_Sarawak.jpg'),
    ('semenggoh-wildlife-centre', 'kuching', 'NATURE', 3, 'HOURS', 4.7, 'Центр дикой природы Семенггох', 'Semenggoh Wildlife Centre', 'Семенггох табиғат орталығы', 1.39740000, 110.31880000, 'Semenggoh Wildlife Centre Kuching', ARRAY['kuching']::text[], ARRAY['kuching']::text[], 'Semenggoh_Wildlife_Centre.jpg'),
    ('kuching-waterfront-main-bazaar', 'kuching', 'MARKET', 2, 'HOURS', 4.6, 'Набережная Кучинга и Main Bazaar', 'Kuching Waterfront & Main Bazaar', 'Кучинг жағалауы және Main Bazaar', 1.56070000, 110.34490000, 'Kuching Waterfront Main Bazaar', ARRAY['kuching']::text[], ARRAY['kuching']::text[], 'Kuching_Waterfront.jpg'),
    ('gunung-mulu-national-park', 'miri', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Гунунг-Мулу', 'Gunung Mulu National Park', 'Гунунг-Мулу ұлттық паркі', 4.12980000, 114.91950000, 'Gunung Mulu National Park Sarawak', ARRAY['miri', 'kuching']::text[], ARRAY['miri']::text[], 'Gunung_Mulu_National_Park.jpg'),
    ('niah-national-park', 'miri', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Ниах', 'Niah National Park', 'Ниах ұлттық паркі', 3.81670000, 113.76670000, 'Niah National Park Sarawak Malaysia', ARRAY['miri']::text[], ARRAY['miri']::text[], 'Niah_Caves.jpg'),
    ('lambir-hills-national-park', 'miri', 'PARK', 4, 'HOURS', 4.7, 'Национальный парк Ламбир-Хиллс', 'Lambir Hills National Park', 'Ламбир-Хиллс ұлттық паркі', 4.20000000, 114.04000000, 'Lambir Hills National Park Miri', ARRAY['miri']::text[], ARRAY['miri']::text[], 'Lambir_Hills_National_Park.jpg'),
    ('canada-hill-petroleum-museum', 'miri', 'MUSEUM', 2, 'HOURS', 4.5, 'Canada Hill и Petroleum Museum', 'Canada Hill & Petroleum Museum', 'Canada Hill және Petroleum Museum', 4.40090000, 113.99100000, 'Canada Hill Petroleum Museum Miri', ARRAY['miri']::text[], ARRAY['miri']::text[], 'Grand_Old_Lady_Miri.jpg'),
    ('miri-handicraft-centre', 'miri', 'MARKET', 1, 'HOURS', 4.4, 'Miri Handicraft Centre', 'Miri Handicraft Centre', 'Miri Handicraft Centre', 4.39960000, 113.99160000, 'Miri Handicraft Centre Sarawak', ARRAY['miri']::text[], ARRAY['miri']::text[], 'Miri_Handicraft_Centre.jpg'),

    ('legoland-malaysia', 'johor-bahru', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'LEGOLAND Malaysia', 'LEGOLAND Malaysia', 'LEGOLAND Malaysia', 1.42650000, 103.63180000, 'LEGOLAND Malaysia Johor Bahru', ARRAY['johor-bahru', 'desaru']::text[], ARRAY['johor-bahru']::text[], 'Legoland_Malaysia.jpg'),
    ('johor-bahru-city-square', 'johor-bahru', 'SHOPPING', 2, 'HOURS', 4.4, 'Johor Bahru City Square', 'Johor Bahru City Square', 'Johor Bahru City Square', 1.46210000, 103.76360000, 'Johor Bahru City Square Malaysia', ARRAY['johor-bahru']::text[], ARRAY['johor-bahru']::text[], 'Johor_Bahru_City_Square.jpg'),
    ('bazaar-karat-johor-bahru', 'johor-bahru', 'MARKET', 2, 'HOURS', 4.4, 'Bazaar Karat Johor Bahru', 'Bazaar Karat Johor Bahru', 'Bazaar Karat Johor Bahru', 1.45790000, 103.76480000, 'Bazaar Karat Johor Bahru Malaysia', ARRAY['johor-bahru']::text[], ARRAY['johor-bahru']::text[], 'Johor_Bahru_Bazaar_Karat.jpg'),
    ('sultan-abu-bakar-mosque', 'johor-bahru', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мечеть султана Абу Бакара', 'Sultan Abu Bakar State Mosque', 'Сұлтан Әбу Бакар мешіті', 1.45710000, 103.75190000, 'Sultan Abu Bakar State Mosque Johor Bahru', ARRAY['johor-bahru']::text[], ARRAY['johor-bahru']::text[], 'Sultan_Abu_Bakar_State_Mosque.jpg'),
    ('desaru-beach', 'desaru', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Десару', 'Desaru Beach', 'Десару жағажайы', 1.54090000, 104.26600000, 'Desaru Beach Johor Malaysia', ARRAY['desaru', 'johor-bahru']::text[], ARRAY['desaru', 'johor-bahru']::text[], 'Desaru_Beach.jpg'),
    ('desaru-coast-adventure-waterpark', 'desaru', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Аквапарк Desaru Coast Adventure', 'Desaru Coast Adventure Waterpark', 'Desaru Coast Adventure аквапаркі', 1.54250000, 104.26350000, 'Adventure Waterpark Desaru Coast Malaysia', ARRAY['desaru', 'johor-bahru']::text[], ARRAY['desaru']::text[], 'Desaru_Coast_Adventure_Waterpark.jpg'),
    ('desaru-fruit-farm', 'desaru', 'NATURE', 2, 'HOURS', 4.5, 'Фруктовая ферма Десару', 'Desaru Fruit Farm', 'Десару жеміс фермасы', 1.57370000, 104.16600000, 'Desaru Fruit Farm Malaysia', ARRAY['desaru', 'johor-bahru']::text[], ARRAY['desaru']::text[], 'Desaru_Fruit_Farm.jpg'),
    ('tioman-island', 'tioman', 'BEACH', 4, 'HOURS', 4.8, 'Остров Тиоман', 'Tioman Island', 'Тиоман аралы', 2.79020000, 104.16980000, 'Tioman Island Malaysia', ARRAY['tioman', 'kuantan']::text[], ARRAY['tioman', 'kuantan']::text[], 'Beach_of_Pulau_Tioman.JPG'),
    ('juara-beach-tioman', 'tioman', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Juara', 'Juara Beach', 'Juara жағажайы', 2.81650000, 104.20300000, 'Juara Beach Tioman Malaysia', ARRAY['tioman']::text[], ARRAY['tioman']::text[], 'Juara_Beach_Tioman.jpg'),
    ('perhentian-islands', 'perhentian-islands', 'BEACH', 4, 'HOURS', 4.8, 'Перхентианские острова', 'Perhentian Islands', 'Перхентиан аралдары', 5.91670000, 102.73330000, 'Perhentian Islands Malaysia', ARRAY['perhentian-islands', 'kuala-terengganu']::text[], ARRAY['perhentian-islands', 'kuala-terengganu']::text[], 'Perhentian_Islands_Malaysia.jpg'),
    ('long-beach-coral-bay-perhentian', 'perhentian-islands', 'BEACH', 3, 'HOURS', 4.7, 'Long Beach и Coral Bay', 'Long Beach & Coral Bay', 'Long Beach және Coral Bay', 5.91240000, 102.72190000, 'Long Beach Coral Bay Perhentian Islands', ARRAY['perhentian-islands']::text[], ARRAY['perhentian-islands']::text[], 'Perhentian_Long_Beach.jpg'),
    ('redang-island', 'redang', 'BEACH', 4, 'HOURS', 4.8, 'Остров Реданг', 'Redang Island', 'Реданг аралы', 5.78430000, 103.00640000, 'Redang Island Malaysia', ARRAY['redang', 'kuala-terengganu']::text[], ARRAY['redang', 'kuala-terengganu']::text[], 'Redang_Island_Beach.jpg'),
    ('redang-marine-park', 'redang', 'NATURE', 3, 'HOURS', 4.7, 'Морской парк Реданг', 'Redang Marine Park', 'Реданг теңіз паркі', 5.76670000, 103.00000000, 'Redang Marine Park Malaysia', ARRAY['redang']::text[], ARRAY['redang']::text[], 'Redang_Marine_Park.jpg'),
    ('pasar-payang', 'kuala-terengganu', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Pasar Payang', 'Pasar Payang', 'Pasar Payang базары', 5.33360000, 103.13660000, 'Pasar Payang Kuala Terengganu', ARRAY['kuala-terengganu', 'redang', 'perhentian-islands']::text[], ARRAY['kuala-terengganu']::text[], 'Pasar_Payang_Kuala_Terengganu.jpg'),
    ('terengganu-state-museum', 'kuala-terengganu', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей штата Теренггану', 'Terengganu State Museum', 'Теренггану музейі', 5.31110000, 103.11850000, 'Terengganu State Museum Kuala Terengganu', ARRAY['kuala-terengganu']::text[], ARRAY['kuala-terengganu']::text[], 'Terengganu_State_Museum.jpg'),
    ('crystal-mosque', 'kuala-terengganu', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Кристальная мечеть', 'Crystal Mosque', 'Кристалл мешіті', 5.31080000, 103.12850000, 'Crystal Mosque Kuala Terengganu Malaysia', ARRAY['kuala-terengganu']::text[], ARRAY['kuala-terengganu']::text[], 'Crystal_Mosque_Aerial_Shot_1.jpg'),
    ('teluk-cempedak-beach', 'kuantan', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Teluk Cempedak', 'Teluk Cempedak Beach', 'Teluk Cempedak жағажайы', 3.81220000, 103.37290000, 'Teluk Cempedak Beach Kuantan', ARRAY['kuantan', 'tioman']::text[], ARRAY['kuantan']::text[], 'Teluk_Cempedak.jpg'),
    ('kuantan-188', 'kuantan', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Kuantan 188', 'Kuantan 188', 'Kuantan 188', 3.80540000, 103.33010000, 'Kuantan 188 Malaysia', ARRAY['kuantan']::text[], ARRAY['kuantan']::text[], 'Kuantan_188.jpg'),
    ('sungai-lembing', 'kuantan', 'MUSEUM', 3, 'HOURS', 4.5, 'Sungai Lembing', 'Sungai Lembing', 'Sungai Lembing', 3.91670000, 103.03330000, 'Sungai Lembing Kuantan Malaysia', ARRAY['kuantan']::text[], ARRAY['kuantan']::text[], 'Sungai_Lembing.jpg'),
    ('tanjung-lumpur-seafood', 'kuantan', 'FOOD', 2, 'HOURS', 4.5, 'Морепродукты Tanjung Lumpur', 'Tanjung Lumpur Seafood', 'Tanjung Lumpur теңіз тағамдары', 3.79400000, 103.34120000, 'Tanjung Lumpur Seafood Kuantan', ARRAY['kuantan']::text[], ARRAY['kuantan']::text[], 'Kuantan_Tanjung_Lumpur.jpg');

CREATE TEMP TABLE seed_malaysia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-malaysia-place:' || seed.slug) AS place_hash,
        md5('id-malaysia-media:' || seed.slug) AS media_hash
    FROM seed_malaysia_priority_places seed
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
    ARRAY['malaysia', city_id, slug, lower(category), 'malaysia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Малайзии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Malaysia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Малайзия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'MY',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 40::numeric
        ELSE 20::numeric
    END,
    'MYR',
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
FROM seed_malaysia_resolved_places
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
FROM seed_malaysia_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_malaysia_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_malaysia_resolved_places
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
FROM seed_malaysia_resolved_places seed
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
FROM seed_malaysia_resolved_places
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
    'MY',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_malaysia_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'MY',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_malaysia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_malaysia_resolved_places;
DROP TABLE IF EXISTS seed_malaysia_priority_places;
