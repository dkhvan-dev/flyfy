-- Priority Singapore destination places seed.
-- Singapore is modeled as one city-state destination, with districts and travel themes stored as tags.

DROP TABLE IF EXISTS seed_singapore_resolved_places;
DROP TABLE IF EXISTS seed_singapore_priority_places;

CREATE TEMP TABLE seed_singapore_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    media_file text NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_singapore_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    rating,
    title_ru,
    title_en,
    title_kk,
    latitude,
    longitude,
    media_file,
    extra_tags
) VALUES
    ('gardens-by-the-bay', 'singapore', 'PARK', 3, 4.9, 'Сады у залива', 'Gardens by the Bay', 'Шығанақ жанындағы бақтар', 1.28160000, 103.86360000, 'Gardens_by_the_Bay_Singapore.jpg', ARRAY['marina-bay', 'garden']::text[]),
    ('cloud-forest', 'singapore', 'NATURE', 2, 4.8, 'Облачный лес', 'Cloud Forest', 'Бұлтты орман', 1.28440000, 103.86570000, 'Cloud_Forest_Gardens_by_the_Bay.jpg', ARRAY['conservatory', 'waterfall']::text[]),
    ('supertree-grove', 'singapore', 'PARK', 2, 4.8, 'Роща Супердеревьев', 'Supertree Grove', 'Суперағаштар тоғайы', 1.28190000, 103.86360000, 'Supertree_Grove_Gardens_by_the_Bay.jpg', ARRAY['light-show', 'garden']::text[]),
    ('marina-barrage', 'singapore', 'PARK', 2, 4.6, 'Марина Барраж', 'Marina Barrage', 'Марина Барраж', 1.28090000, 103.87120000, 'Marina_Barrage_Singapore.jpg', ARRAY['waterfront', 'picnic']::text[]),
    ('merlion-park', 'singapore', 'ARCHITECTURE', 1, 4.8, 'Парк Мерлион', 'Merlion Park', 'Мерлион саябағы', 1.28690000, 103.85460000, 'Merlion_Park_Singapore.jpg', ARRAY['landmark', 'waterfront']::text[]),
    ('marina-bay-sands', 'singapore', 'ARCHITECTURE', 2, 4.8, 'Marina Bay Sands', 'Marina Bay Sands', 'Marina Bay Sands', 1.28340000, 103.86070000, 'Marina_Bay_Sands_Singapore.jpg', ARRAY['skyline', 'landmark']::text[]),
    ('sands-skypark-observation-deck', 'singapore', 'ENTERTAINMENT', 2, 4.7, 'Смотровая площадка Sands SkyPark', 'Sands SkyPark Observation Deck', 'Sands SkyPark қарау алаңы', 1.28380000, 103.86050000, 'Sands_SkyPark_Observation_Deck.jpg', ARRAY['viewpoint', 'skyline']::text[]),
    ('helix-bridge', 'singapore', 'ARCHITECTURE', 1, 4.6, 'Мост Хеликс', 'Helix Bridge', 'Хеликс көпірі', 1.28680000, 103.86060000, 'Helix_Bridge_Singapore.jpg', ARRAY['bridge', 'night-view']::text[]),
    ('artscience-museum', 'singapore', 'MUSEUM', 2, 4.7, 'Музей искусства и науки', 'ArtScience Museum', 'Өнер және ғылым музейі', 1.28630000, 103.85930000, 'ArtScience_Museum_Singapore.jpg', ARRAY['exhibitions', 'technology']::text[]),
    ('national-gallery-singapore', 'singapore', 'MUSEUM', 3, 4.8, 'Национальная галерея Сингапура', 'National Gallery Singapore', 'Сингапур ұлттық галереясы', 1.29060000, 103.85190000, 'National_Gallery_Singapore.jpg', ARRAY['art', 'civic-district']::text[]),
    ('asian-civilisations-museum', 'singapore', 'MUSEUM', 2, 4.7, 'Музей азиатских цивилизаций', 'Asian Civilisations Museum', 'Азия өркениеттері музейі', 1.28750000, 103.85150000, 'Asian_Civilisations_Museum_Singapore.jpg', ARRAY['culture', 'history']::text[]),
    ('national-museum-singapore', 'singapore', 'MUSEUM', 2, 4.7, 'Национальный музей Сингапура', 'National Museum of Singapore', 'Сингапур ұлттық музейі', 1.29660000, 103.84850000, 'National_Museum_of_Singapore.jpg', ARRAY['history', 'heritage']::text[]),
    ('esplanade-theatres', 'singapore', 'ENTERTAINMENT', 2, 4.6, 'Эспланада - Театры у залива', 'Esplanade - Theatres on the Bay', 'Эспланада шығанақ театрлары', 1.28960000, 103.85570000, 'Esplanade_Theatres_on_the_Bay_Singapore.jpg', ARRAY['performing-arts', 'concerts']::text[]),
    ('singapore-flyer', 'singapore', 'ENTERTAINMENT', 1, 4.6, 'Сингапурское колесо обозрения', 'Singapore Flyer', 'Сингапур шолу дөңгелегі', 1.28930000, 103.86310000, 'Singapore_Flyer_2010.jpg', ARRAY['observation', 'skyline']::text[]),
    ('old-hill-street-police-station', 'singapore', 'ARCHITECTURE', 1, 4.5, 'Старое здание полиции на Хилл-стрит', 'Old Hill Street Police Station', 'Хилл-стрит ескі полиция ғимараты', 1.29040000, 103.84860000, 'Old_Hill_Street_Police_Station_Singapore.jpg', ARRAY['colonial', 'facade']::text[]),
    ('raffles-hotel-singapore', 'singapore', 'ARCHITECTURE', 1, 4.7, 'Отель Raffles Singapore', 'Raffles Hotel Singapore', 'Raffles Singapore қонақ үйі', 1.29490000, 103.85450000, 'Raffles_Hotel_Singapore.jpg', ARRAY['heritage', 'colonial']::text[]),
    ('victoria-theatre-concert-hall', 'singapore', 'ARCHITECTURE', 1, 4.5, 'Театр и концертный зал Виктория', 'Victoria Theatre and Concert Hall', 'Виктория театры және концерт залы', 1.28830000, 103.85150000, 'Victoria_Theatre_and_Concert_Hall_Singapore.jpg', ARRAY['civic-district', 'colonial']::text[]),
    ('lau-pa-sat', 'singapore', 'MARKET', 1, 4.7, 'Lau Pa Sat', 'Lau Pa Sat', 'Lau Pa Sat', 1.28050000, 103.85040000, 'Lau_Pa_Sat_Singapore.jpg', ARRAY['hawker', 'satay']::text[]),
    ('makansutra-gluttons-bay', 'singapore', 'FOOD', 1, 4.5, 'Makansutra Gluttons Bay', 'Makansutra Gluttons Bay', 'Makansutra Gluttons Bay', 1.28990000, 103.85680000, 'Makansutra_Gluttons_Bay_Singapore.jpg', ARRAY['hawker', 'open-air']::text[]),
    ('shoppes-marina-bay-sands', 'singapore', 'SHOPPING', 2, 4.6, 'The Shoppes at Marina Bay Sands', 'The Shoppes at Marina Bay Sands', 'The Shoppes at Marina Bay Sands', 1.28370000, 103.85910000, 'The_Shoppes_at_Marina_Bay_Sands.jpg', ARRAY['luxury', 'mall']::text[]),
    ('raffles-city-singapore', 'singapore', 'SHOPPING', 2, 4.5, 'Raffles City Singapore', 'Raffles City Singapore', 'Raffles City Singapore', 1.29310000, 103.85220000, 'Raffles_City_Singapore.jpg', ARRAY['mall', 'civic-district']::text[]),
    ('suntec-city', 'singapore', 'SHOPPING', 2, 4.5, 'Suntec City', 'Suntec City', 'Suntec City', 1.29400000, 103.85810000, 'Suntec_City_Singapore.jpg', ARRAY['mall', 'dining']::text[]),
    ('orchard-road', 'singapore', 'SHOPPING', 3, 4.7, 'Orchard Road', 'Orchard Road', 'Orchard Road', 1.30480000, 103.83180000, 'Orchard_Road_Singapore.jpg', ARRAY['shopping-street', 'central']::text[]),
    ('ion-orchard', 'singapore', 'SHOPPING', 2, 4.6, 'ION Orchard', 'ION Orchard', 'ION Orchard', 1.30400000, 103.83180000, 'ION_Orchard_Singapore.jpg', ARRAY['mall', 'orchard']::text[]),
    ('clarke-quay', 'singapore', 'ENTERTAINMENT', 2, 4.5, 'Clarke Quay', 'Clarke Quay', 'Clarke Quay', 1.29060000, 103.84650000, 'Clarke_Quay_Singapore.jpg', ARRAY['nightlife', 'riverfront']::text[]),

    ('universal-studios-singapore', 'singapore', 'ENTERTAINMENT', 6, 4.8, 'Universal Studios Singapore', 'Universal Studios Singapore', 'Universal Studios Singapore', 1.25400000, 103.82380000, 'Universal_Studios_Singapore_entrance.jpg', ARRAY['sentosa', 'theme-park']::text[]),
    ('singapore-oceanarium', 'singapore', 'MUSEUM', 3, 4.7, 'Сингапурский океанариум', 'Singapore Oceanarium', 'Сингапур океанариумы', 1.25860000, 103.82070000, 'Singapore_Oceanarium.jpg', ARRAY['sentosa', 'marine-life']::text[]),
    ('adventure-cove-waterpark', 'singapore', 'ENTERTAINMENT', 4, 4.6, 'Аквапарк Adventure Cove', 'Adventure Cove Waterpark', 'Adventure Cove аквапаркі', 1.25880000, 103.81790000, 'Adventure_Cove_Waterpark_Singapore.jpg', ARRAY['sentosa', 'waterpark']::text[]),
    ('fort-siloso', 'singapore', 'MUSEUM', 2, 4.6, 'Форт Силосо', 'Fort Siloso', 'Форт Силосо', 1.25690000, 103.81010000, 'Fort_Siloso_Singapore.jpg', ARRAY['sentosa', 'history']::text[]),
    ('madame-tussauds-singapore', 'singapore', 'MUSEUM', 2, 4.4, 'Музей мадам Тюссо в Сингапуре', 'Madame Tussauds Singapore', 'Сингапур мадам Тюссо музейі', 1.25640000, 103.81930000, 'Madame_Tussauds_Singapore.jpg', ARRAY['sentosa', 'interactive']::text[]),
    ('sentosa-sensoryscape', 'singapore', 'ARCHITECTURE', 1, 4.5, 'Sentosa Sensoryscape', 'Sentosa Sensoryscape', 'Sentosa Sensoryscape', 1.25400000, 103.81980000, 'Sentosa_Sensoryscape.jpg', ARRAY['sentosa', 'light-art']::text[]),
    ('siloso-beach', 'singapore', 'BEACH', 3, 4.6, 'Пляж Силосо', 'Siloso Beach', 'Силосо жағажайы', 1.25420000, 103.81380000, 'Siloso_Beach_Singapore.jpg', ARRAY['sentosa', 'beach-bars']::text[]),
    ('palawan-beach', 'singapore', 'BEACH', 3, 4.5, 'Пляж Палаван', 'Palawan Beach', 'Палаван жағажайы', 1.24890000, 103.82380000, 'Palawan_Beach_Singapore.jpg', ARRAY['sentosa', 'family']::text[]),
    ('tanjong-beach', 'singapore', 'BEACH', 3, 4.5, 'Пляж Танжонг', 'Tanjong Beach', 'Танжонг жағажайы', 1.24370000, 103.82770000, 'Tanjong_Beach_Singapore.jpg', ARRAY['sentosa', 'sunset']::text[]),
    ('central-beach-bazaar', 'singapore', 'MARKET', 1, 4.4, 'Центральный пляжный базар', 'Central Beach Bazaar', 'Орталық жағажай базары', 1.25130000, 103.81910000, 'Central_Beach_Bazaar_Sentosa.jpg', ARRAY['sentosa', 'food-kiosks']::text[]),
    ('wings-of-time-fireworks-symphony', 'singapore', 'ENTERTAINMENT', 1, 4.6, 'Шоу Wings of Time Fireworks Symphony', 'Wings of Time Fireworks Symphony', 'Wings of Time отшашу симфониясы', 1.25100000, 103.81870000, 'Wings_of_Time_Sentosa.jpg', ARRAY['sentosa', 'night-show']::text[]),
    ('skyline-luge-singapore', 'singapore', 'ENTERTAINMENT', 2, 4.6, 'Skyline Luge Singapore', 'Skyline Luge Singapore', 'Skyline Luge Singapore', 1.25470000, 103.81760000, 'Skyline_Luge_Singapore.jpg', ARRAY['sentosa', 'family']::text[]),
    ('mega-adventure-park', 'singapore', 'ENTERTAINMENT', 2, 4.5, 'Парк приключений Mega Adventure', 'Mega Adventure Park', 'Mega Adventure Park', 1.25440000, 103.81200000, 'Mega_Adventure_Park_Sentosa.jpg', ARRAY['sentosa', 'zipline']::text[]),
    ('vivocity', 'singapore', 'SHOPPING', 2, 4.5, 'Торговый центр VivoCity', 'VivoCity', 'VivoCity', 1.26440000, 103.82230000, 'VivoCity_Singapore.jpg', ARRAY['mall', 'waterfront']::text[]),
    ('singapore-cable-car', 'singapore', 'ENTERTAINMENT', 2, 4.6, 'Канатная дорога Сингапура', 'Singapore Cable Car', 'Сингапур аспалы жолы', 1.27140000, 103.81930000, 'Singapore_Cable_Car.jpg', ARRAY['views', 'sentosa']::text[]),
    ('mount-faber-park', 'singapore', 'PARK', 2, 4.6, 'Парк Маунт-Фейбер', 'Mount Faber Park', 'Маунт-Фейбер саябағы', 1.27100000, 103.81980000, 'Mount_Faber_Park_Singapore.jpg', ARRAY['viewpoint', 'southern-ridges']::text[]),
    ('henderson-waves', 'singapore', 'ARCHITECTURE', 1, 4.6, 'Мост Волны Хендерсона', 'Henderson Waves', 'Хендерсон толқындары көпірі', 1.27860000, 103.81900000, 'Henderson_Waves_Singapore.jpg', ARRAY['bridge', 'viewpoint']::text[]),
    ('labrador-nature-reserve', 'singapore', 'NATURE', 2, 4.5, 'Природный заповедник Лабрадор', 'Labrador Nature Reserve', 'Лабрадор табиғи қорығы', 1.26620000, 103.80290000, 'Labrador_Nature_Reserve_Singapore.jpg', ARRAY['coastal', 'history']::text[]),

    ('buddha-tooth-relic-temple', 'singapore', 'TEMPLE', 2, 4.7, 'Храм и музей Зуба Будды', 'Buddha Tooth Relic Temple and Museum', 'Будда тісі реликті храмы және музейі', 1.28150000, 103.84430000, 'Buddha_Tooth_Relic_Temple_and_Museum.jpg', ARRAY['chinatown', 'buddhist']::text[]),
    ('sri-mariamman-temple', 'singapore', 'TEMPLE', 1, 4.6, 'Храм Шри Мариамман', 'Sri Mariamman Temple', 'Шри Мариамман храмы', 1.28210000, 103.84550000, 'Sri_Mariamman_Temple_Singapore.jpg', ARRAY['chinatown', 'hindu']::text[]),
    ('thian-hock-keng-temple', 'singapore', 'TEMPLE', 1, 4.6, 'Храм Тхиан Хок Кенг', 'Thian Hock Keng Temple', 'Тхиан Хок Кенг храмы', 1.28090000, 103.84760000, 'Thian_Hock_Keng_Temple_Singapore.jpg', ARRAY['telok-ayer', 'chinese-temple']::text[]),
    ('chinatown-street-market', 'singapore', 'MARKET', 1, 4.5, 'Уличный рынок Чайнатауна', 'Chinatown Street Market', 'Чайнатаун көше базары', 1.28320000, 103.84370000, 'Chinatown_Street_Market_Singapore.jpg', ARRAY['chinatown', 'souvenirs']::text[]),
    ('maxwell-food-centre', 'singapore', 'FOOD', 1, 4.7, 'Центр уличной еды Maxwell', 'Maxwell Food Centre', 'Maxwell фуд-орталығы', 1.28030000, 103.84420000, 'Maxwell_Food_Centre_Singapore.jpg', ARRAY['hawker', 'chinatown']::text[]),
    ('chinatown-complex-market', 'singapore', 'MARKET', 1, 4.6, 'Chinatown Complex Market and Food Centre', 'Chinatown Complex Market and Food Centre', 'Chinatown Complex базары және фуд-орталығы', 1.28240000, 103.84350000, 'Chinatown_Complex_Market_and_Food_Centre.jpg', ARRAY['hawker', 'market']::text[]),
    ('sri-veeramakaliamman-temple', 'singapore', 'TEMPLE', 1, 4.6, 'Храм Шри Вирамакалиамман', 'Sri Veeramakaliamman Temple', 'Шри Вирамакалиамман храмы', 1.30670000, 103.84960000, 'Sri_Veeramakaliamman_Temple_Singapore.jpg', ARRAY['little-india', 'hindu']::text[]),
    ('indian-heritage-centre', 'singapore', 'MUSEUM', 2, 4.5, 'Центр индийского наследия', 'Indian Heritage Centre', 'Үнді мұрасы орталығы', 1.30690000, 103.85230000, 'Indian_Heritage_Centre_Singapore.jpg', ARRAY['little-india', 'culture']::text[]),
    ('tekka-centre', 'singapore', 'MARKET', 1, 4.6, 'Tekka Centre', 'Tekka Centre', 'Tekka Centre', 1.30640000, 103.85050000, 'Tekka_Centre_Singapore.jpg', ARRAY['wet-market', 'hawker']::text[]),
    ('mustafa-centre', 'singapore', 'SHOPPING', 2, 4.4, 'Mustafa Centre', 'Mustafa Centre', 'Mustafa Centre', 1.30970000, 103.85540000, 'Mustafa_Centre_Singapore.jpg', ARRAY['little-india', 'department-store']::text[]),
    ('sultan-mosque', 'singapore', 'ARCHITECTURE', 1, 4.7, 'Мечеть Султана', 'Sultan Mosque', 'Сұлтан мешіті', 1.30200000, 103.85940000, 'Sultan_Mosque_Singapore.jpg', ARRAY['kampong-gelam', 'mosque']::text[]),
    ('haji-lane', 'singapore', 'SHOPPING', 1, 4.5, 'Haji Lane', 'Haji Lane', 'Haji Lane', 1.30080000, 103.85950000, 'Haji_Lane_Singapore.jpg', ARRAY['street-art', 'boutiques']::text[]),
    ('arab-street', 'singapore', 'SHOPPING', 1, 4.5, 'Arab Street', 'Arab Street', 'Arab Street', 1.30220000, 103.85880000, 'Arab_Street_Singapore.jpg', ARRAY['textiles', 'kampong-gelam']::text[]),

    ('singapore-botanic-gardens', 'singapore', 'PARK', 3, 4.9, 'Сингапурский ботанический сад', 'Singapore Botanic Gardens', 'Сингапур ботаникалық бағы', 1.31380000, 103.81590000, 'Singapore_Botanic_Gardens.jpg', ARRAY['unesco', 'garden']::text[]),
    ('national-orchid-garden', 'singapore', 'NATURE', 2, 4.8, 'Национальный сад орхидей', 'National Orchid Garden', 'Ұлттық орхидея бағы', 1.31190000, 103.81420000, 'National_Orchid_Garden_Singapore.jpg', ARRAY['orchids', 'botanic-gardens']::text[]),
    ('singapore-zoo', 'singapore', 'ENTERTAINMENT', 4, 4.8, 'Сингапурский зоопарк', 'Singapore Zoo', 'Сингапур зообағы', 1.40430000, 103.79300000, 'Singapore_Zoo_entrance.jpg', ARRAY['wildlife', 'family']::text[]),
    ('night-safari', 'singapore', 'ENTERTAINMENT', 3, 4.7, 'Ночное сафари', 'Night Safari', 'Түнгі сафари', 1.40210000, 103.78850000, 'Night_Safari_Singapore.jpg', ARRAY['wildlife', 'night']::text[]),
    ('river-wonders', 'singapore', 'ENTERTAINMENT', 3, 4.6, 'River Wonders', 'River Wonders', 'River Wonders', 1.40420000, 103.79060000, 'River_Wonders_Singapore.jpg', ARRAY['wildlife', 'aquarium']::text[]),
    ('bird-paradise', 'singapore', 'ENTERTAINMENT', 3, 4.7, 'Bird Paradise', 'Bird Paradise', 'Bird Paradise', 1.41040000, 103.78890000, 'Bird_Paradise_Singapore.jpg', ARRAY['birds', 'wildlife']::text[]),
    ('jewel-changi-airport', 'singapore', 'SHOPPING', 3, 4.8, 'Jewel Changi Airport', 'Jewel Changi Airport', 'Jewel Changi Airport', 1.36020000, 103.98900000, 'Jewel_Changi_Airport.jpg', ARRAY['mall', 'architecture']::text[]),
    ('changi-experience-studio', 'singapore', 'MUSEUM', 2, 4.5, 'Changi Experience Studio', 'Changi Experience Studio', 'Changi Experience Studio', 1.36020000, 103.98900000, 'Changi_Experience_Studio.jpg', ARRAY['airport', 'interactive']::text[]),
    ('east-coast-park', 'singapore', 'PARK', 3, 4.7, 'Парк Ист-Кост', 'East Coast Park', 'Ист-Кост саябағы', 1.30080000, 103.91220000, 'East_Coast_Park_Singapore.jpg', ARRAY['coast', 'cycling']::text[]),
    ('changi-beach-park', 'singapore', 'BEACH', 2, 4.5, 'Пляжный парк Чанги', 'Changi Beach Park', 'Чанги жағажай саябағы', 1.39010000, 103.99150000, 'Changi_Beach_Park_Singapore.jpg', ARRAY['beach', 'sunset']::text[]),
    ('pulau-ubin', 'singapore', 'NATURE', 4, 4.7, 'Пулау-Убин', 'Pulau Ubin', 'Пулау-Убин', 1.40430000, 103.96000000, 'Pulau_Ubin_Singapore.jpg', ARRAY['island', 'cycling']::text[]),
    ('chek-jawa-wetlands', 'singapore', 'NATURE', 3, 4.7, 'Водно-болотные угодья Чек-Джава', 'Chek Jawa Wetlands', 'Чек-Джава сулы-батпақты алқаптары', 1.40890000, 103.99340000, 'Chek_Jawa_Wetlands.jpg', ARRAY['wetlands', 'biodiversity']::text[]),
    ('macritchie-reservoir-park', 'singapore', 'NATURE', 3, 4.7, 'Парк водохранилища Мак-Ритчи', 'MacRitchie Reservoir Park', 'Мак-Ритчи су қоймасы саябағы', 1.34480000, 103.82240000, 'MacRitchie_Reservoir_Park.jpg', ARRAY['reservoir', 'hiking']::text[]),
    ('sungei-buloh-wetland-reserve', 'singapore', 'NATURE', 3, 4.7, 'Заповедник Сунгей-Булох', 'Sungei Buloh Wetland Reserve', 'Сунгей-Булох сулы-батпақты қорығы', 1.44790000, 103.73040000, 'Sungei_Buloh_Wetland_Reserve.jpg', ARRAY['wetlands', 'birdwatching']::text[]),
    ('bukit-timah-nature-reserve', 'singapore', 'NATURE', 3, 4.7, 'Заповедник Букит-Тимах', 'Bukit Timah Nature Reserve', 'Букит-Тимах табиғи қорығы', 1.35210000, 103.77670000, 'Bukit_Timah_Nature_Reserve.jpg', ARRAY['rainforest', 'hiking']::text[]),
    ('jurong-lake-gardens', 'singapore', 'PARK', 2, 4.6, 'Сады озера Джуронг', 'Jurong Lake Gardens', 'Джуронг көлі бақтары', 1.34130000, 103.72740000, 'Jurong_Lake_Gardens_Singapore.jpg', ARRAY['lakeside', 'family']::text[]),
    ('newton-food-centre', 'singapore', 'FOOD', 1, 4.6, 'Newton Food Centre', 'Newton Food Centre', 'Newton Food Centre', 1.31200000, 103.83990000, 'Newton_Food_Centre_Singapore.jpg', ARRAY['hawker', 'night-food']::text[]),
    ('geylang-serai-market', 'singapore', 'MARKET', 1, 4.6, 'Рынок и фуд-центр Geylang Serai', 'Geylang Serai Market and Food Centre', 'Geylang Serai базары және фуд-орталығы', 1.31690000, 103.89710000, 'Geylang_Serai_Market_Singapore.jpg', ARRAY['market', 'malay-food']::text[]),
    ('old-airport-road-food-centre', 'singapore', 'FOOD', 1, 4.6, 'Old Airport Road Food Centre', 'Old Airport Road Food Centre', 'Old Airport Road Food Centre', 1.30830000, 103.88590000, 'Old_Airport_Road_Food_Centre.jpg', ARRAY['hawker', 'classics']::text[]),
    ('chomp-chomp-food-centre', 'singapore', 'FOOD', 1, 4.5, 'Chomp Chomp Food Centre', 'Chomp Chomp Food Centre', 'Chomp Chomp Food Centre', 1.36450000, 103.86660000, 'Chomp_Chomp_Food_Centre.jpg', ARRAY['hawker', 'night-food']::text[]),
    ('bugis-street', 'singapore', 'MARKET', 2, 4.5, 'Bugis Street', 'Bugis Street', 'Bugis Street', 1.30080000, 103.85520000, 'Bugis_Street_Singapore.jpg', ARRAY['street-market', 'shopping']::text[]);

CREATE TEMP TABLE seed_singapore_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-singapore-place:' || seed.slug) AS place_hash,
        md5('id-singapore-media:' || seed.slug) AS media_hash
    FROM seed_singapore_priority_places seed
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
    'HOURS'::varchar(16) AS duration_unit,
    rating,
    ARRAY['singapore', city_id, slug, lower(category), 'singapore-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Сингапура: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'Singapore tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'Сингапур туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' Singapore', ' ', '%20') AS location_source_url,
    ARRAY[city_id]::text[] AS access_city_ids,
    ARRAY[city_id]::text[] AS departure_city_ids,
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
    'SG',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 30::numeric
        ELSE 15::numeric
    END,
    'SGD',
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
FROM seed_singapore_resolved_places
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
FROM seed_singapore_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_singapore_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_singapore_resolved_places
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
FROM seed_singapore_resolved_places seed
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
FROM seed_singapore_resolved_places
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
    'SG',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_singapore_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'SG',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_singapore_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
