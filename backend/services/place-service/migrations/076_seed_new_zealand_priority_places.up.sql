-- Priority New Zealand destination places seed.
-- The seed covers North Island city/day-trip routes and South Island nature, adventure, markets, malls, museums, beaches, and parks.

DROP TABLE IF EXISTS seed_new_zealand_resolved_places;
DROP TABLE IF EXISTS seed_new_zealand_priority_places;

CREATE TEMP TABLE seed_new_zealand_priority_places (
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

INSERT INTO seed_new_zealand_priority_places (
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
    ('sky-tower-auckland', 'auckland', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Скай Тауэр в Окленде', 'Sky Tower Auckland', 'Окленд Скай Тауэрі', -36.84850000, 174.76220000, 'Sky Tower Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Sky_Tower_Auckland.jpg', ARRAY['viewpoint', 'city-symbol']::text[]),
    ('auckland-war-memorial-museum', 'auckland', 'MUSEUM', 2, 'HOURS', 4.8, 'Оклендский военный мемориальный музей', 'Auckland War Memorial Museum', 'Окленд әскери мемориал музейі', -36.86090000, 174.77720000, 'Auckland War Memorial Museum New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_War_Memorial_Museum.jpg', ARRAY['history', 'indoor']::text[]),
    ('auckland-art-gallery', 'auckland', 'MUSEUM', 2, 'HOURS', 4.7, 'Оклендская художественная галерея Toi o Tamaki', 'Auckland Art Gallery Toi o Tamaki', 'Окленд Toi o Tamaki өнер галереясы', -36.85160000, 174.76760000, 'Auckland Art Gallery Toi o Tamaki New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_Art_Gallery.jpg', ARRAY['art', 'indoor']::text[]),
    ('new-zealand-maritime-museum', 'auckland', 'MUSEUM', 2, 'HOURS', 4.6, 'Морской музей Новой Зеландии', 'New Zealand Maritime Museum', 'Жаңа Зеландия теңіз музейі', -36.84090000, 174.76520000, 'New Zealand Maritime Museum Auckland', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'New_Zealand_Maritime_Museum.jpg', ARRAY['harbor', 'family']::text[]),
    ('weta-workshop-unleashed-auckland', 'auckland', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Weta Workshop Unleashed в Окленде', 'Weta Workshop Unleashed Auckland', 'Окленд Weta Workshop Unleashed', -36.84940000, 174.76200000, 'Weta Workshop Unleashed Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Weta_Workshop_Unleashed_Auckland.jpg', ARRAY['cinema', 'family']::text[]),
    ('sea-life-kelly-tarltons-aquarium', 'auckland', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Аквариум SEA LIFE Kelly Tarltons', 'SEA LIFE Kelly Tarltons Aquarium', 'SEA LIFE Kelly Tarltons аквариумы', -36.84660000, 174.81720000, 'SEA LIFE Kelly Tarltons Aquarium Auckland', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Kelly_Tarltons_Aquarium_Auckland.jpg', ARRAY['aquarium', 'family']::text[]),
    ('auckland-zoo', 'auckland', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Зоопарк Окленда', 'Auckland Zoo', 'Окленд зообағы', -36.86310000, 174.71980000, 'Auckland Zoo New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),
    ('auckland-domain', 'auckland', 'PARK', 2, 'HOURS', 4.6, 'Парк Auckland Domain', 'Auckland Domain', 'Auckland Domain саябағы', -36.86000000, 174.77500000, 'Auckland Domain New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_Domain.jpg', ARRAY['green-space', 'walk']::text[]),
    ('mount-eden', 'auckland', 'NATURE', 2, 'HOURS', 4.7, 'Маунгафау / гора Иден', 'Maungawhau Mount Eden', 'Маунгафау Маунт Иден', -36.87700000, 174.76430000, 'Mount Eden Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Mount_Eden_Auckland.jpg', ARRAY['viewpoint', 'volcano']::text[]),
    ('cornwall-park-auckland', 'auckland', 'PARK', 2, 'HOURS', 4.6, 'Корнуолл-парк', 'Cornwall Park Auckland', 'Окленд Корнуолл паркі', -36.90060000, 174.78310000, 'Cornwall Park Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Cornwall_Park_Auckland.jpg', ARRAY['green-space', 'family']::text[]),
    ('mission-bay-beach', 'auckland', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Мишен-Бэй', 'Mission Bay Beach', 'Мишен-Бэй жағажайы', -36.84750000, 174.83050000, 'Mission Bay Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Mission_Bay_Auckland.jpg', ARRAY['waterfront', 'summer']::text[]),
    ('westfield-newmarket', 'auckland', 'SHOPPING', 2, 'HOURS', 4.5, 'ТЦ Westfield Newmarket', 'Westfield Newmarket', 'Westfield Newmarket сауда орталығы', -36.87030000, 174.77570000, 'Westfield Newmarket Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Westfield_Newmarket_Auckland.jpg', ARRAY['mall', 'indoor']::text[]),
    ('commercial-bay-auckland', 'auckland', 'SHOPPING', 2, 'HOURS', 4.5, 'Коммершл-Бэй', 'Commercial Bay Auckland', 'Окленд Commercial Bay', -36.84400000, 174.76750000, 'Commercial Bay Auckland New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Commercial_Bay_Auckland.jpg', ARRAY['mall', 'food-hall']::text[]),
    ('auckland-night-markets', 'auckland', 'MARKET', 1, 'HOURS', 4.5, 'Ночные рынки Окленда', 'Auckland Night Markets', 'Окленд түнгі базарлары', -36.91450000, 174.83700000, 'Auckland Night Markets New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_Night_Markets.jpg', ARRAY['night-market', 'street-food']::text[]),
    ('auckland-fish-market', 'auckland', 'MARKET', 1, 'HOURS', 4.4, 'Рыбный рынок Окленда', 'Auckland Fish Market', 'Окленд балық базары', -36.84130000, 174.75560000, 'Auckland Fish Market New Zealand', ARRAY['auckland']::text[], ARRAY['auckland']::text[], 'Auckland_Fish_Market.jpg', ARRAY['food-market', 'local-market']::text[]),
    ('waiheke-island', 'waiheke-island', 'NATURE', 5, 'HOURS', 4.8, 'Остров Уаихеке', 'Waiheke Island', 'Уаихеке аралы', -36.78100000, 175.00900000, 'Waiheke Island New Zealand', ARRAY['waiheke-island', 'auckland']::text[], ARRAY['auckland', 'waiheke-island']::text[], 'Waiheke_Island_New_Zealand.jpg', ARRAY['island', 'wine']::text[]),
    ('piha-beach', 'waitakere-ranges', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Пиха', 'Piha Beach', 'Пиха жағажайы', -36.95450000, 174.46990000, 'Piha Beach New Zealand', ARRAY['waitakere-ranges', 'auckland']::text[], ARRAY['auckland', 'waitakere-ranges']::text[], 'Piha_Beach.jpg', ARRAY['surf', 'black-sand']::text[]),
    ('waitakere-ranges-regional-park', 'waitakere-ranges', 'NATURE', 4, 'HOURS', 4.8, 'Региональный парк Уаитакере', 'Waitakere Ranges Regional Park', 'Уаитакере аймақтық паркі', -36.94000000, 174.52000000, 'Waitakere Ranges Regional Park New Zealand', ARRAY['waitakere-ranges', 'auckland']::text[], ARRAY['auckland', 'waitakere-ranges']::text[], 'Waitakere_Ranges_New_Zealand.jpg', ARRAY['hiking', 'rainforest']::text[]),

    ('te-puia', 'rotorua', 'NATURE', 3, 'HOURS', 4.8, 'Те Пуиа', 'Te Puia', 'Те Пуиа', -38.16390000, 176.25370000, 'Te Puia Rotorua New Zealand', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Te_Puia_Rotorua.jpg', ARRAY['geothermal', 'maori-culture']::text[]),
    ('wai-o-tapu-thermal-wonderland', 'rotorua', 'NATURE', 3, 'HOURS', 4.8, 'Геотермальный парк Wai-O-Tapu', 'Wai-O-Tapu Thermal Wonderland', 'Wai-O-Tapu геотермалдық паркі', -38.35100000, 176.36900000, 'Wai-O-Tapu Thermal Wonderland Rotorua', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Wai-O-Tapu_Thermal_Wonderland.jpg', ARRAY['geothermal', 'volcanic']::text[]),
    ('redwoods-whakarewarewa-forest', 'rotorua', 'PARK', 3, 'HOURS', 4.8, 'Редвудс / лес Факареварева', 'Redwoods Whakarewarewa Forest', 'Редвудс Факареварева орманы', -38.15780000, 176.28770000, 'Redwoods Whakarewarewa Forest Rotorua', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Whakarewarewa_Forest_Rotorua.jpg', ARRAY['forest', 'walk']::text[]),
    ('skyline-rotorua', 'rotorua', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Skyline Rotorua', 'Skyline Rotorua', 'Skyline Rotorua', -38.10920000, 176.22820000, 'Skyline Rotorua New Zealand', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Skyline_Rotorua.jpg', ARRAY['luge', 'family']::text[]),
    ('polynesian-spa', 'rotorua', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Полинезийский спа', 'Polynesian Spa', 'Полинезиялық спа', -38.13600000, 176.25440000, 'Polynesian Spa Rotorua New Zealand', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Polynesian_Spa_Rotorua.jpg', ARRAY['hot-springs', 'wellness']::text[]),
    ('rotorua-night-market', 'rotorua', 'MARKET', 1, 'HOURS', 4.4, 'Ночной рынок Роторуа', 'Rotorua Night Market', 'Роторуа түнгі базары', -38.13680000, 176.24970000, 'Rotorua Night Market New Zealand', ARRAY['rotorua']::text[], ARRAY['rotorua']::text[], 'Rotorua_Night_Market.jpg', ARRAY['night-market', 'street-food']::text[]),
    ('huka-falls', 'taupo', 'NATURE', 2, 'HOURS', 4.8, 'Водопад Хука', 'Huka Falls', 'Хука сарқырамасы', -38.64880000, 176.08900000, 'Huka Falls Taupo New Zealand', ARRAY['taupo']::text[], ARRAY['taupo', 'rotorua']::text[], 'Huka_Falls_New_Zealand.jpg', ARRAY['waterfall', 'day-trip']::text[]),
    ('lake-taupo', 'taupo', 'NATURE', 3, 'HOURS', 4.7, 'Озеро Таупо', 'Lake Taupo', 'Таупо көлі', -38.80500000, 175.90000000, 'Lake Taupo New Zealand', ARRAY['taupo']::text[], ARRAY['taupo']::text[], 'Lake_Taupo_New_Zealand.jpg', ARRAY['lake', 'scenic']::text[]),
    ('waitomo-glowworm-caves', 'waitomo', 'NATURE', 2, 'HOURS', 4.8, 'Пещеры светлячков Уаитомо', 'Waitomo Glowworm Caves', 'Уаитомо жарқырауық үңгірлері', -38.26080000, 175.10360000, 'Waitomo Glowworm Caves New Zealand', ARRAY['waitomo']::text[], ARRAY['auckland', 'rotorua', 'waitomo']::text[], 'Waitomo_Glowworm_Caves.jpg', ARRAY['caves', 'glowworms']::text[]),
    ('hobbiton-movie-set', 'matamata', 'ENTERTAINMENT', 3, 'HOURS', 4.9, 'Кинодеревня Хоббитон', 'Hobbiton Movie Set', 'Хоббитон кино алаңы', -37.87210000, 175.68290000, 'Hobbiton Movie Set Matamata New Zealand', ARRAY['matamata']::text[], ARRAY['auckland', 'rotorua', 'matamata']::text[], 'Hobbiton_Movie_Set.jpg', ARRAY['cinema', 'family']::text[]),
    ('tauranga-waterfront', 'tauranga', 'FOOD', 2, 'HOURS', 4.4, 'Набережная Тауранги', 'Tauranga Waterfront', 'Тауранга жағалауы', -37.68690000, 176.16890000, 'Tauranga Waterfront New Zealand', ARRAY['tauranga', 'mount-maunganui']::text[], ARRAY['tauranga', 'mount-maunganui']::text[], 'Tauranga_Waterfront.jpg', ARRAY['waterfront', 'evening']::text[]),
    ('mount-maunganui-main-beach', 'mount-maunganui', 'BEACH', 3, 'HOURS', 4.8, 'Главный пляж Маунт-Маунгануи', 'Mount Maunganui Main Beach', 'Маунт-Маунгануи басты жағажайы', -37.63290000, 176.18150000, 'Mount Maunganui Main Beach New Zealand', ARRAY['mount-maunganui', 'tauranga']::text[], ARRAY['tauranga', 'mount-maunganui']::text[], 'Mount_Maunganui_Beach.jpg', ARRAY['surf', 'summer']::text[]),
    ('tongariro-alpine-crossing', 'tongariro', 'NATURE', 7, 'HOURS', 4.9, 'Альпийский переход Тонгариро', 'Tongariro Alpine Crossing', 'Тонгариро альпі өткелі', -39.13000000, 175.65000000, 'Tongariro Alpine Crossing New Zealand', ARRAY['tongariro']::text[], ARRAY['taupo', 'tongariro']::text[], 'Tongariro_Alpine_Crossing.jpg', ARRAY['hiking', 'national-park']::text[]),
    ('napier-art-deco-quarter', 'napier', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Квартал ар-деко в Нейпире', 'Napier Art Deco Quarter', 'Нейпир ар-деко кварталы', -39.49280000, 176.91200000, 'Napier Art Deco Quarter New Zealand', ARRAY['napier']::text[], ARRAY['napier']::text[], 'Napier_Art_Deco.jpg', ARRAY['art-deco', 'walk']::text[]),

    ('te-papa-tongarewa', 'wellington', 'MUSEUM', 3, 'HOURS', 4.9, 'Музей Новой Зеландии Те Папа Тонгарева', 'Te Papa Tongarewa', 'Те Папа Тонгарева музейі', -41.29050000, 174.78200000, 'Museum of New Zealand Te Papa Tongarewa Wellington', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Te_Papa_Tongarewa_Museum.jpg', ARRAY['national-museum', 'indoor']::text[]),
    ('zealandia', 'wellington', 'NATURE', 3, 'HOURS', 4.8, 'Заповедник Zealandia', 'Zealandia Te Mara a Tane', 'Zealandia қорығы', -41.30660000, 174.75050000, 'Zealandia Wellington New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Zealandia_Wellington.jpg', ARRAY['wildlife', 'eco-sanctuary']::text[]),
    ('wellington-cable-car', 'wellington', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Веллингтонский фуникулер', 'Wellington Cable Car', 'Веллингтон фуникулері', -41.28370000, 174.77420000, 'Wellington Cable Car New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Wellington_Cable_Car.jpg', ARRAY['city-symbol', 'viewpoint']::text[]),
    ('wellington-botanic-garden', 'wellington', 'PARK', 2, 'HOURS', 4.7, 'Веллингтонский ботанический сад', 'Wellington Botanic Garden', 'Веллингтон ботаникалық бағы', -41.28280000, 174.76600000, 'Wellington Botanic Garden New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Wellington_Botanic_Garden.jpg', ARRAY['garden', 'walk']::text[]),
    ('wellington-night-market', 'wellington', 'MARKET', 1, 'HOURS', 4.4, 'Ночной рынок Веллингтона', 'Wellington Night Market', 'Веллингтон түнгі базары', -41.29210000, 174.77720000, 'Wellington Night Market New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Wellington_Night_Market.jpg', ARRAY['night-market', 'street-food']::text[]),
    ('harbourside-market-wellington', 'wellington', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Harbourside', 'Harbourside Market Wellington', 'Веллингтон Harbourside базары', -41.29030000, 174.78240000, 'Harbourside Market Wellington New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Harbourside_Market_Wellington.jpg', ARRAY['food-market', 'waterfront']::text[]),
    ('oriental-bay-beach', 'wellington', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Ориентал-Бэй', 'Oriental Bay Beach', 'Ориентал-Бэй жағажайы', -41.29170000, 174.79420000, 'Oriental Bay Beach Wellington New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Oriental_Bay_Wellington.jpg', ARRAY['city-beach', 'waterfront']::text[]),
    ('old-bank-arcade', 'wellington', 'SHOPPING', 1, 'HOURS', 4.4, 'Торговая галерея Old Bank Arcade', 'Old Bank Arcade', 'Old Bank Arcade сауда галереясы', -41.28430000, 174.77680000, 'Old Bank Arcade Wellington New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Old_Bank_Arcade_Wellington.jpg', ARRAY['shopping-arcade', 'heritage']::text[]),
    ('weta-workshop-wellington', 'wellington', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Экскурсии Weta Workshop в Веллингтоне', 'Weta Workshop Wellington', 'Веллингтон Weta Workshop', -41.31680000, 174.81660000, 'Weta Workshop Wellington New Zealand', ARRAY['wellington']::text[], ARRAY['wellington']::text[], 'Weta_Workshop_Wellington.jpg', ARRAY['cinema', 'family']::text[]),

    ('christchurch-botanic-gardens', 'christchurch', 'PARK', 2, 'HOURS', 4.8, 'Ботанический сад Крайстчерча', 'Christchurch Botanic Gardens', 'Крайстчерч ботаникалық бағы', -43.53100000, 172.62050000, 'Christchurch Botanic Gardens New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Christchurch_Botanic_Gardens.jpg', ARRAY['garden', 'walk']::text[]),
    ('canterbury-museum', 'christchurch', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Кентербери', 'Canterbury Museum', 'Кентербери музейі', -43.53080000, 172.62720000, 'Canterbury Museum Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Canterbury_Museum_Christchurch.jpg', ARRAY['history', 'indoor']::text[]),
    ('christchurch-art-gallery', 'christchurch', 'MUSEUM', 2, 'HOURS', 4.6, 'Художественная галерея Крайстчерча', 'Christchurch Art Gallery', 'Крайстчерч өнер галереясы', -43.52990000, 172.62690000, 'Christchurch Art Gallery New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Christchurch_Art_Gallery.jpg', ARRAY['art', 'indoor']::text[]),
    ('riverside-market-christchurch', 'christchurch', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Riverside в Крайстчерче', 'Riverside Market Christchurch', 'Крайстчерч Riverside базары', -43.53450000, 172.63300000, 'Riverside Market Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Riverside_Market_Christchurch.jpg', ARRAY['food-market', 'covered-market']::text[]),
    ('westfield-riccarton', 'christchurch', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Westfield Riccarton', 'Westfield Riccarton', 'Westfield Riccarton сауда орталығы', -43.53090000, 172.59810000, 'Westfield Riccarton Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Westfield_Riccarton.jpg', ARRAY['mall', 'indoor']::text[]),
    ('new-regent-street', 'christchurch', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Улица New Regent Street', 'New Regent Street', 'New Regent Street көшесі', -43.52960000, 172.63970000, 'New Regent Street Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'New_Regent_Street_Christchurch.jpg', ARRAY['heritage', 'walk']::text[]),
    ('cardboard-cathedral', 'christchurch', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Временный картонный собор', 'Cardboard Cathedral Christchurch', 'Крайстчерч картон соборы', -43.53270000, 172.64280000, 'Cardboard Cathedral Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'Cardboard_Cathedral_Christchurch.jpg', ARRAY['modern-architecture', 'post-earthquake']::text[]),
    ('new-brighton-pier', 'christchurch', 'BEACH', 2, 'HOURS', 4.5, 'Пирс Нью-Брайтон', 'New Brighton Pier', 'Нью-Брайтон пирсі', -43.50650000, 172.73380000, 'New Brighton Pier Christchurch New Zealand', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'New_Brighton_Pier.jpg', ARRAY['beach', 'pier']::text[]),
    ('international-antarctic-centre', 'christchurch', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Международный антарктический центр', 'International Antarctic Centre', 'Халықаралық Антарктика орталығы', -43.48800000, 172.54070000, 'International Antarctic Centre Christchurch', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], 'International_Antarctic_Centre.jpg', ARRAY['family', 'indoor']::text[]),
    ('kaikoura-whale-watching', 'kaikoura', 'NATURE', 3, 'HOURS', 4.8, 'Наблюдение за китами в Кайкоуре', 'Kaikoura Whale Watching', 'Кайкоурада киттерді бақылау', -42.40070000, 173.68000000, 'Whale Watch Kaikoura New Zealand', ARRAY['kaikoura']::text[], ARRAY['christchurch', 'kaikoura']::text[], 'Kaikoura_Whale_Watching.jpg', ARRAY['wildlife', 'boat-trip']::text[]),
    ('kaikoura-peninsula-walkway', 'kaikoura', 'NATURE', 3, 'HOURS', 4.7, 'Тропа полуострова Кайкоура', 'Kaikoura Peninsula Walkway', 'Кайкоура түбегі соқпағы', -42.42200000, 173.70400000, 'Kaikoura Peninsula Walkway New Zealand', ARRAY['kaikoura']::text[], ARRAY['kaikoura']::text[], 'Kaikoura_Peninsula_Walkway.jpg', ARRAY['walk', 'coast']::text[]),
    ('kaikoura-museum', 'kaikoura', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей Кайкоуры', 'Kaikoura Museum', 'Кайкоура музейі', -42.40000000, 173.68170000, 'Kaikoura Museum New Zealand', ARRAY['kaikoura']::text[], ARRAY['kaikoura']::text[], 'Kaikoura_Museum.jpg', ARRAY['local-history', 'indoor']::text[]),
    ('abel-tasman-national-park', 'abel-tasman', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Абел-Тасман', 'Abel Tasman National Park', 'Абел-Тасман ұлттық паркі', -40.88650000, 173.04400000, 'Abel Tasman National Park New Zealand', ARRAY['abel-tasman', 'nelson']::text[], ARRAY['nelson', 'abel-tasman']::text[], 'Abel_Tasman_National_Park.jpg', ARRAY['national-park', 'coast']::text[]),
    ('abel-tasman-coast-track', 'abel-tasman', 'NATURE', 5, 'HOURS', 4.9, 'Прибрежная тропа Абел-Тасман', 'Abel Tasman Coast Track', 'Абел-Тасман жағалау соқпағы', -41.00070000, 173.01510000, 'Abel Tasman Coast Track New Zealand', ARRAY['abel-tasman', 'nelson']::text[], ARRAY['nelson', 'abel-tasman']::text[], 'Abel_Tasman_Coast_Track.jpg', ARRAY['great-walk', 'hiking']::text[]),
    ('nelson-market', 'nelson', 'MARKET', 1, 'HOURS', 4.5, 'Нельсонский рынок', 'Nelson Market', 'Нельсон базары', -41.27640000, 173.28320000, 'Nelson Market New Zealand', ARRAY['nelson']::text[], ARRAY['nelson']::text[], 'Nelson_Market_New_Zealand.jpg', ARRAY['local-market', 'crafts']::text[]),
    ('tahunanui-beach', 'nelson', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Тахунануи', 'Tahunanui Beach', 'Тахунануи жағажайы', -41.28200000, 173.24600000, 'Tahunanui Beach Nelson New Zealand', ARRAY['nelson']::text[], ARRAY['nelson']::text[], 'Tahunanui_Beach.jpg', ARRAY['city-beach', 'family']::text[]),
    ('founders-heritage-park', 'nelson', 'PARK', 2, 'HOURS', 4.5, 'Исторический парк Founders', 'Founders Heritage Park', 'Founders тарихи паркі', -41.26540000, 173.29050000, 'Founders Heritage Park Nelson New Zealand', ARRAY['nelson']::text[], ARRAY['nelson']::text[], 'Founders_Heritage_Park.jpg', ARRAY['heritage', 'family']::text[]),
    ('suter-art-gallery', 'nelson', 'MUSEUM', 1, 'HOURS', 4.5, 'Художественная галерея The Suter', 'The Suter Art Gallery', 'The Suter өнер галереясы', -41.27550000, 173.28950000, 'The Suter Art Gallery Nelson New Zealand', ARRAY['nelson']::text[], ARRAY['nelson']::text[], 'Suter_Art_Gallery_Nelson.jpg', ARRAY['art', 'indoor']::text[]),
    ('dunedin-railway-station', 'dunedin', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Железнодорожный вокзал Данидина', 'Dunedin Railway Station', 'Данидин теміржол вокзалы', -45.87430000, 170.50840000, 'Dunedin Railway Station New Zealand', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Dunedin_Railway_Station.jpg', ARRAY['heritage', 'city-symbol']::text[]),
    ('otago-museum', 'dunedin', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Otago', 'Otago Museum', 'Otago музейі', -45.86640000, 170.51010000, 'Otago Museum Dunedin New Zealand', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Otago_Museum_Dunedin.jpg', ARRAY['indoor', 'science']::text[]),
    ('toitu-otago-settlers-museum', 'dunedin', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей поселенцев Отаго Toitu', 'Toitu Otago Settlers Museum', 'Toitu Otago қоныстанушылар музейі', -45.87520000, 170.50800000, 'Toitu Otago Settlers Museum Dunedin', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Toitu_Otago_Settlers_Museum.jpg', ARRAY['local-history', 'indoor']::text[]),
    ('otago-farmers-market', 'dunedin', 'MARKET', 1, 'HOURS', 4.6, 'Фермерский рынок Отаго', 'Otago Farmers Market', 'Отаго фермерлер базары', -45.87380000, 170.50900000, 'Otago Farmers Market Dunedin', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Otago_Farmers_Market.jpg', ARRAY['farmers-market', 'food']::text[]),
    ('dunedin-botanic-garden', 'dunedin', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Данидина', 'Dunedin Botanic Garden', 'Данидин ботаникалық бағы', -45.85630000, 170.52030000, 'Dunedin Botanic Garden New Zealand', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Dunedin_Botanic_Garden.jpg', ARRAY['garden', 'walk']::text[]),
    ('larnach-castle', 'otago-peninsula', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Ларнак', 'Larnach Castle', 'Ларнак қамалы', -45.86170000, 170.62720000, 'Larnach Castle Dunedin New Zealand', ARRAY['otago-peninsula', 'dunedin']::text[], ARRAY['dunedin', 'otago-peninsula']::text[], 'Larnach_Castle.jpg', ARRAY['castle', 'garden']::text[]),
    ('royal-albatross-centre', 'otago-peninsula', 'NATURE', 2, 'HOURS', 4.7, 'Центр королевских альбатросов', 'Royal Albatross Centre', 'Корольдік альбатрос орталығы', -45.77480000, 170.72770000, 'Royal Albatross Centre Otago Peninsula', ARRAY['otago-peninsula', 'dunedin']::text[], ARRAY['dunedin', 'otago-peninsula']::text[], 'Royal_Albatross_Centre.jpg', ARRAY['wildlife', 'coast']::text[]),
    ('tunnel-beach', 'dunedin', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Tunnel Beach', 'Tunnel Beach', 'Tunnel Beach жағажайы', -45.91970000, 170.45530000, 'Tunnel Beach Dunedin New Zealand', ARRAY['dunedin']::text[], ARRAY['dunedin']::text[], 'Tunnel_Beach_Dunedin.jpg', ARRAY['coast', 'walk']::text[]),

    ('skyline-queenstown', 'queenstown', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Skyline Queenstown', 'Skyline Queenstown', 'Skyline Queenstown', -45.03110000, 168.65830000, 'Skyline Queenstown New Zealand', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], 'Skyline_Queenstown.jpg', ARRAY['gondola', 'luge']::text[]),
    ('shotover-jet', 'queenstown', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Shotover Jet', 'Shotover Jet', 'Shotover Jet', -44.98700000, 168.66700000, 'Shotover Jet Queenstown New Zealand', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], 'Shotover_Jet.jpg', ARRAY['adventure', 'jet-boat']::text[]),
    ('queenstown-gardens', 'queenstown', 'PARK', 1, 'HOURS', 4.6, 'Сады Квинстауна', 'Queenstown Gardens', 'Квинстаун бақтары', -45.03570000, 168.66470000, 'Queenstown Gardens New Zealand', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], 'Queenstown_Gardens.jpg', ARRAY['waterfront', 'walk']::text[]),
    ('queenstown-mall', 'queenstown', 'SHOPPING', 1, 'HOURS', 4.4, 'Queenstown Mall', 'Queenstown Mall', 'Queenstown Mall', -45.03120000, 168.66260000, 'Queenstown Mall New Zealand', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], 'Queenstown_Mall.jpg', ARRAY['shopping-street', 'central']::text[]),
    ('lake-wakatipu', 'queenstown', 'NATURE', 2, 'HOURS', 4.9, 'Озеро Вакатипу', 'Lake Wakatipu', 'Вакатипу көлі', -45.05200000, 168.61000000, 'Lake Wakatipu Queenstown New Zealand', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], 'Lake_Wakatipu.jpg', ARRAY['lake', 'scenic']::text[]),
    ('arrowtown-historic-village', 'arrowtown', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Исторический Эрроутаун', 'Arrowtown Historic Village', 'Тарихи Эрроутаун ауылы', -44.93880000, 168.83510000, 'Arrowtown Historic Village New Zealand', ARRAY['arrowtown', 'queenstown']::text[], ARRAY['queenstown', 'arrowtown']::text[], 'Arrowtown_New_Zealand.jpg', ARRAY['gold-rush', 'heritage']::text[]),
    ('wanaka-lakefront', 'wanaka', 'NATURE', 2, 'HOURS', 4.8, 'Набережная озера Ванака', 'Wanaka Lakefront', 'Ванака көл жағалауы', -44.69600000, 169.13500000, 'Wanaka Lakefront New Zealand', ARRAY['wanaka']::text[], ARRAY['wanaka', 'queenstown']::text[], 'Wanaka_Lakefront.jpg', ARRAY['lake', 'walk']::text[]),
    ('roys-peak-track', 'wanaka', 'NATURE', 6, 'HOURS', 4.9, 'Тропа Roys Peak', 'Roys Peak Track', 'Roys Peak соқпағы', -44.69730000, 169.06680000, 'Roys Peak Track Wanaka New Zealand', ARRAY['wanaka']::text[], ARRAY['wanaka']::text[], 'Roys_Peak_New_Zealand.jpg', ARRAY['hiking', 'viewpoint']::text[]),
    ('puzzling-world', 'wanaka', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Puzzling World', 'Puzzling World', 'Puzzling World', -44.68110000, 169.16060000, 'Puzzling World Wanaka New Zealand', ARRAY['wanaka']::text[], ARRAY['wanaka']::text[], 'Puzzling_World_Wanaka.jpg', ARRAY['family', 'indoor']::text[]),
    ('lake-tekapo', 'tekapo', 'NATURE', 2, 'HOURS', 4.8, 'Озеро Текапо', 'Lake Tekapo', 'Текапо көлі', -44.00470000, 170.47710000, 'Lake Tekapo New Zealand', ARRAY['tekapo']::text[], ARRAY['christchurch', 'tekapo']::text[], 'Lake_Tekapo.jpg', ARRAY['lake', 'stargazing']::text[]),
    ('church-of-good-shepherd', 'tekapo', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Церковь Доброго Пастыря', 'Church of the Good Shepherd', 'Қайырымды Бағушы шіркеуі', -44.00430000, 170.48240000, 'Church of the Good Shepherd Lake Tekapo', ARRAY['tekapo']::text[], ARRAY['tekapo']::text[], 'Church_of_the_Good_Shepherd_Tekapo.jpg', ARRAY['landmark', 'photo-stop']::text[]),
    ('aoraki-mount-cook-national-park', 'aoraki-mount-cook', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Аораки / Маунт-Кук', 'Aoraki Mount Cook National Park', 'Аораки Маунт-Кук ұлттық паркі', -43.73510000, 170.09670000, 'Aoraki Mount Cook National Park New Zealand', ARRAY['aoraki-mount-cook', 'tekapo']::text[], ARRAY['tekapo', 'aoraki-mount-cook']::text[], 'Aoraki_Mount_Cook_National_Park.jpg', ARRAY['national-park', 'alpine']::text[]),
    ('hooker-valley-track', 'aoraki-mount-cook', 'NATURE', 4, 'HOURS', 4.9, 'Тропа Hooker Valley', 'Hooker Valley Track', 'Hooker Valley соқпағы', -43.71800000, 170.09300000, 'Hooker Valley Track New Zealand', ARRAY['aoraki-mount-cook']::text[], ARRAY['aoraki-mount-cook']::text[], 'Hooker_Valley_Track.jpg', ARRAY['hiking', 'glacier-view']::text[]),
    ('milford-sound', 'milford-sound', 'NATURE', 4, 'HOURS', 4.9, 'Милфорд-Саунд', 'Milford Sound', 'Милфорд-Саунд', -44.67160000, 167.92550000, 'Milford Sound New Zealand', ARRAY['milford-sound', 'fiordland']::text[], ARRAY['queenstown', 'fiordland', 'milford-sound']::text[], 'Milford_Sound_New_Zealand.jpg', ARRAY['fjord', 'boat-trip']::text[]),
    ('fiordland-national-park', 'fiordland', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Фьордленд', 'Fiordland National Park', 'Фьордленд ұлттық паркі', -45.41600000, 167.71800000, 'Fiordland National Park New Zealand', ARRAY['fiordland', 'milford-sound']::text[], ARRAY['queenstown', 'fiordland']::text[], 'Fiordland_National_Park.jpg', ARRAY['national-park', 'unesco']::text[]),
    ('te-anau-glowworm-caves', 'fiordland', 'NATURE', 2, 'HOURS', 4.7, 'Пещеры светлячков Те-Анау', 'Te Anau Glowworm Caves', 'Те-Анау жарқырауық үңгірлері', -45.41900000, 167.71600000, 'Te Anau Glowworm Caves New Zealand', ARRAY['fiordland']::text[], ARRAY['queenstown', 'fiordland']::text[], 'Te_Anau_Glowworm_Caves.jpg', ARRAY['caves', 'glowworms']::text[]),
    ('franz-josef-glacier', 'franz-josef', 'NATURE', 4, 'HOURS', 4.8, 'Ледник Франц-Иосиф', 'Franz Josef Glacier', 'Франц-Иосиф мұздығы', -43.46400000, 170.18100000, 'Franz Josef Glacier New Zealand', ARRAY['franz-josef']::text[], ARRAY['franz-josef']::text[], 'Franz_Josef_Glacier.jpg', ARRAY['glacier', 'west-coast']::text[]),
    ('fox-glacier', 'fox-glacier', 'NATURE', 4, 'HOURS', 4.7, 'Ледник Фокса', 'Fox Glacier', 'Фокс мұздығы', -43.46310000, 170.01710000, 'Fox Glacier New Zealand', ARRAY['fox-glacier']::text[], ARRAY['fox-glacier', 'franz-josef']::text[], 'Fox_Glacier_New_Zealand.jpg', ARRAY['glacier', 'west-coast']::text[]);

CREATE TEMP TABLE seed_new_zealand_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-new-zealand-place:' || seed.slug) AS place_hash,
        md5('id-new-zealand-media:' || seed.slug) AS media_hash
    FROM seed_new_zealand_priority_places seed
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
    ARRAY['new-zealand', city_id, slug, lower(category), 'new-zealand-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Новой Зеландии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'New Zealand tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Жаңа Зеландия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'NZ',
    city_id,
    category,
    NULL::numeric,
    'NZD',
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
FROM seed_new_zealand_resolved_places
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
FROM seed_new_zealand_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_new_zealand_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_new_zealand_resolved_places
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
FROM seed_new_zealand_resolved_places seed
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
FROM seed_new_zealand_resolved_places
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
    'NZ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_new_zealand_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'NZ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_new_zealand_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_new_zealand_resolved_places;
DROP TABLE IF EXISTS seed_new_zealand_priority_places;
