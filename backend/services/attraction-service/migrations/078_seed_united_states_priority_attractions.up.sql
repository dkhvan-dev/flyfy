-- Priority United States destination attractions seed.
-- The seed covers major city anchors, national parks, beaches, museums, malls, markets, food halls, and entertainment points.

DROP TABLE IF EXISTS seed_united_states_resolved_attractions;
DROP TABLE IF EXISTS seed_united_states_priority_attractions;

CREATE TEMP TABLE seed_united_states_priority_attractions (
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

INSERT INTO seed_united_states_priority_attractions (
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
    ('statue-liberty-ellis-island', 'new-york', 'ARCHITECTURE', 3, 4.9, 'Статуя Свободы и остров Эллис', 'Statue of Liberty and Ellis Island', 'Бостандық мүсіні және Эллис аралы', 40.68924700, -74.04450200, 'Statue_of_Liberty.jpg', ARRAY['landmark', 'harbor']::text[]),
    ('central-park', 'new-york', 'PARK', 3, 4.9, 'Центральный парк', 'Central Park', 'Орталық саябақ', 40.78120000, -73.96650000, 'Central_Park_New_York_City_New_York_23.jpg', ARRAY['green-space', 'family']::text[]),
    ('metropolitan-museum-art', 'new-york', 'MUSEUM', 3, 4.9, 'Метрополитен-музей', 'The Metropolitan Museum of Art', 'Метрополитен өнер музейі', 40.77940000, -73.96320000, 'Metropolitan_Museum_of_Art_1000_5th_Avenue.jpg', ARRAY['art', 'indoor']::text[]),
    ('american-museum-natural-history', 'new-york', 'MUSEUM', 3, 4.8, 'Американский музей естественной истории', 'American Museum of Natural History', 'Америкалық табиғи тарих музейі', 40.78130000, -73.97350000, 'American_Museum_of_Natural_History_New_York.jpg', ARRAY['science', 'family']::text[]),
    ('times-square-broadway', 'new-york', 'ENTERTAINMENT', 2, 4.7, 'Таймс-сквер и Бродвей', 'Times Square and Broadway District', 'Таймс-сквер және Бродвей', 40.75800000, -73.98550000, 'Times_Square_New_York_City_HDR.jpg', ARRAY['theater', 'evening']::text[]),
    ('chelsea-market', 'new-york', 'MARKET', 1, 4.6, 'Chelsea Market', 'Chelsea Market', 'Chelsea Market', 40.74230000, -74.00600000, 'Chelsea_Market_New_York.jpg', ARRAY['food-market', 'covered-market']::text[]),

    ('national-mall-memorial-parks', 'washington-dc', 'PARK', 4, 4.9, 'Национальная аллея и мемориальные парки', 'National Mall and Memorial Parks', 'Ұлттық аллея және мемориалдық саябақтар', 38.88950000, -77.03530000, 'National_Mall_Washington_DC.jpg', ARRAY['monuments', 'walk']::text[]),
    ('nmaahc', 'washington-dc', 'MUSEUM', 3, 4.8, 'Национальный музей афроамериканской истории и культуры', 'National Museum of African American History and Culture', 'Афроамерикалық тарих және мәдениет ұлттық музейі', 38.89100000, -77.03200000, 'National_Museum_of_African_American_History_and_Culture.jpg', ARRAY['history', 'smithsonian']::text[]),
    ('national-gallery-art', 'washington-dc', 'MUSEUM', 3, 4.8, 'Национальная галерея искусства', 'National Gallery of Art', 'Ұлттық өнер галереясы', 38.89130000, -77.02000000, 'National_Gallery_of_Art_Washington_DC.jpg', ARRAY['art', 'indoor']::text[]),
    ('capitol-visitor-center', 'washington-dc', 'ARCHITECTURE', 2, 4.7, 'Центр посетителей Капитолия США', 'United States Capitol Visitor Center', 'АҚШ Капитолийінің келушілер орталығы', 38.88990000, -77.00910000, 'United_States_Capitol_west_front_edit2.jpg', ARRAY['government', 'landmark']::text[]),
    ('eastern-market-dc', 'washington-dc', 'MARKET', 1, 4.6, 'Eastern Market в Вашингтоне', 'Eastern Market DC', 'Вашингтон Eastern Market', 38.88420000, -76.99560000, 'Eastern_Market_Washington_DC.jpg', ARRAY['local-market', 'food-market']::text[]),
    ('union-market-dc', 'washington-dc', 'FOOD', 1, 4.6, 'Union Market District', 'Union Market District', 'Union Market District', 38.90860000, -76.99750000, 'Union_Market_Washington_DC.jpg', ARRAY['food-hall', 'evening']::text[]),

    ('freedom-trail-boston', 'boston', 'ARCHITECTURE', 3, 4.8, 'Тропа Свободы в Бостоне', 'Freedom Trail Boston', 'Бостон Бостандық жолы', 42.35770000, -71.06180000, 'Freedom_Trail_Boston.jpg', ARRAY['history', 'walking-route']::text[]),
    ('boston-common-public-garden', 'boston', 'PARK', 2, 4.8, 'Бостон-Коммон и Public Garden', 'Boston Common and Public Garden', 'Бостон-Коммон және қоғамдық бақ', 42.35500000, -71.06560000, 'Boston_Common_2021.jpg', ARRAY['green-space', 'central']::text[]),
    ('fenway-park', 'boston', 'ENTERTAINMENT', 2, 4.8, 'Фенуэй Парк', 'Fenway Park', 'Фенуэй Парк', 42.34670000, -71.09720000, 'Fenway_Park_2013.jpg', ARRAY['sports', 'stadium']::text[]),
    ('museum-fine-arts-boston', 'boston', 'MUSEUM', 3, 4.8, 'Музей изящных искусств Бостона', 'Museum of Fine Arts Boston', 'Бостон бейнелеу өнері музейі', 42.33940000, -71.09420000, 'Museum_of_Fine_Arts_Boston.jpg', ARRAY['art', 'indoor']::text[]),
    ('faneuil-hall-quincy-market', 'boston', 'MARKET', 2, 4.6, 'Faneuil Hall Marketplace и Quincy Market', 'Faneuil Hall Marketplace and Quincy Market', 'Faneuil Hall және Quincy Market', 42.36010000, -71.05630000, 'Faneuil_Hall_Marketplace_Boston.jpg', ARRAY['food-market', 'historic-market']::text[]),
    ('new-england-aquarium', 'boston', 'ENTERTAINMENT', 2, 4.6, 'Аквариум Новой Англии', 'New England Aquarium', 'Жаңа Англия аквариумы', 42.35920000, -71.04900000, 'New_England_Aquarium_Boston.jpg', ARRAY['family', 'aquarium']::text[]),

    ('independence-hall-liberty-bell', 'philadelphia', 'ARCHITECTURE', 2, 4.9, 'Индепенденс-холл и Колокол Свободы', 'Independence Hall and Liberty Bell', 'Индепенденс-холл және Бостандық қоңырауы', 39.94890000, -75.15000000, 'Independence_Hall_Philadelphia.jpg', ARRAY['unesco', 'history']::text[]),
    ('philadelphia-museum-art-rocky-steps', 'philadelphia', 'MUSEUM', 3, 4.8, 'Филадельфийский музей искусств и ступени Рокки', 'Philadelphia Museum of Art and Rocky Steps', 'Филадельфия өнер музейі және Рокки баспалдақтары', 39.96560000, -75.18100000, 'Philadelphia_Museum_of_Art_2017.jpg', ARRAY['art', 'photo-stop']::text[]),
    ('reading-terminal-market', 'philadelphia', 'MARKET', 1, 4.8, 'Reading Terminal Market', 'Reading Terminal Market', 'Reading Terminal Market', 39.95330000, -75.15930000, 'Reading_Terminal_Market_2018.jpg', ARRAY['covered-market', 'food-market']::text[]),
    ('eastern-state-penitentiary', 'philadelphia', 'MUSEUM', 2, 4.7, 'Восточная государственная тюрьма', 'Eastern State Penitentiary', 'Eastern State Penitentiary', 39.96830000, -75.17270000, 'Eastern_State_Penitentiary.jpg', ARRAY['history', 'indoor']::text[]),
    ('fairmount-park', 'philadelphia', 'PARK', 2, 4.6, 'Fairmount Park', 'Fairmount Park', 'Fairmount Park', 39.98330000, -75.20000000, 'Fairmount_Park_Philadelphia.jpg', ARRAY['green-space', 'river']::text[]),

    ('niagara-falls-state-park', 'niagara-falls', 'NATURE', 4, 4.9, 'Государственный парк Ниагара-Фолс', 'Niagara Falls State Park', 'Ниагара сарқырамасы мемлекеттік саябағы', 43.08380000, -79.07400000, 'Niagara_Falls_State_Park.jpg', ARRAY['waterfall', 'state-park']::text[]),
    ('cave-of-the-winds', 'niagara-falls', 'ENTERTAINMENT', 2, 4.8, 'Cave of the Winds', 'Cave of the Winds', 'Cave of the Winds', 43.08160000, -79.07070000, 'Cave_of_the_Winds_Niagara_Falls.jpg', ARRAY['waterfall', 'seasonal']::text[]),
    ('maid-of-the-mist', 'niagara-falls', 'ENTERTAINMENT', 1, 4.8, 'Maid of the Mist', 'Maid of the Mist', 'Maid of the Mist', 43.08600000, -79.07100000, 'Maid_of_the_Mist_Niagara_Falls.jpg', ARRAY['boat-tour', 'waterfall']::text[]),
    ('aquarium-of-niagara', 'niagara-falls', 'ENTERTAINMENT', 2, 4.4, 'Аквариум Ниагары', 'Aquarium of Niagara', 'Ниагара аквариумы', 43.09470000, -79.06050000, 'Aquarium_of_Niagara.jpg', ARRAY['family', 'aquarium']::text[]),
    ('old-falls-street', 'niagara-falls', 'FOOD', 1, 4.3, 'Old Falls Street', 'Old Falls Street', 'Old Falls Street', 43.08550000, -79.06180000, 'Old_Falls_Street_Niagara_Falls.jpg', ARRAY['walk', 'food']::text[]),
    ('fashion-outlets-niagara', 'niagara-falls', 'SHOPPING', 2, 4.3, 'Fashion Outlets of Niagara Falls USA', 'Fashion Outlets of Niagara Falls USA', 'Niagara Falls Fashion Outlets', 43.09700000, -78.98100000, 'Fashion_Outlets_of_Niagara_Falls.jpg', ARRAY['outlet', 'indoor']::text[]),

    ('millennium-park-chicago', 'chicago', 'PARK', 2, 4.8, 'Миллениум-парк Чикаго', 'Millennium Park Chicago', 'Чикаго Миллениум саябағы', 41.88260000, -87.62260000, 'Millennium_Park_Chicago_2011.jpg', ARRAY['public-art', 'central']::text[]),
    ('art-institute-chicago', 'chicago', 'MUSEUM', 3, 4.9, 'Чикагский институт искусств', 'Art Institute of Chicago', 'Чикаго өнер институты', 41.87960000, -87.62370000, 'Art_Institute_of_Chicago_2007.jpg', ARRAY['art', 'indoor']::text[]),
    ('navy-pier', 'chicago', 'ENTERTAINMENT', 3, 4.6, 'Нэви-пир', 'Navy Pier', 'Нэви-пир', 41.89170000, -87.60860000, 'Navy_Pier_Chicago_2014.jpg', ARRAY['family', 'lakefront']::text[]),
    ('magnificent-mile', 'chicago', 'SHOPPING', 2, 4.6, 'Великолепная миля', 'The Magnificent Mile', 'Керемет миля', 41.89500000, -87.62430000, 'Magnificent_Mile_Chicago.jpg', ARRAY['shopping-street', 'central']::text[]),
    ('chicago-riverwalk', 'chicago', 'ARCHITECTURE', 2, 4.7, 'Набережная Chicago Riverwalk', 'Chicago Riverwalk', 'Chicago Riverwalk жағалауы', 41.88710000, -87.62630000, 'Chicago_Riverwalk_2018.jpg', ARRAY['waterfront', 'walk']::text[]),

    ('griffith-observatory', 'los-angeles', 'ARCHITECTURE', 2, 4.8, 'Обсерватория Гриффита', 'Griffith Observatory', 'Гриффит обсерваториясы', 34.11840000, -118.30040000, 'Griffith_Observatory_2015.jpg', ARRAY['viewpoint', 'science']::text[]),
    ('getty-center', 'los-angeles', 'MUSEUM', 3, 4.8, 'Центр Гетти', 'The Getty Center', 'Гетти орталығы', 34.07800000, -118.47410000, 'Getty_Center_2014.jpg', ARRAY['art', 'architecture']::text[]),
    ('santa-monica-pier-beach', 'los-angeles', 'BEACH', 3, 4.7, 'Пирс и пляж Санта-Моники', 'Santa Monica Pier and Beach', 'Санта-Моника пирсі және жағажайы', 34.00940000, -118.49730000, 'Santa_Monica_Pier_2009.jpg', ARRAY['beach', 'family']::text[]),
    ('universal-studios-hollywood', 'los-angeles', 'ENTERTAINMENT', 6, 4.8, 'Universal Studios Hollywood', 'Universal Studios Hollywood', 'Universal Studios Hollywood', 34.13810000, -118.35340000, 'Universal_Studios_Hollywood_Entrance.jpg', ARRAY['theme-park', 'family']::text[]),
    ('grand-central-market-los-angeles', 'los-angeles', 'MARKET', 1, 4.6, 'Grand Central Market в Лос-Анджелесе', 'Grand Central Market Los Angeles', 'Лос-Анджелес Grand Central Market', 34.05070000, -118.24880000, 'Grand_Central_Market_Los_Angeles.jpg', ARRAY['food-market', 'downtown']::text[]),
    ('the-grove-farmers-market', 'los-angeles', 'SHOPPING', 2, 4.6, 'The Grove и Original Farmers Market', 'The Grove and Original Farmers Market', 'The Grove және Original Farmers Market', 34.07190000, -118.35730000, 'The_Grove_Los_Angeles.jpg', ARRAY['shopping', 'food-market']::text[]),

    ('golden-gate-bridge', 'san-francisco', 'ARCHITECTURE', 2, 4.9, 'Мост Золотые Ворота', 'Golden Gate Bridge', 'Алтын қақпа көпірі', 37.81990000, -122.47830000, 'Golden_Gate_Bridge_as_seen_from_Battery_East.jpg', ARRAY['landmark', 'viewpoint']::text[]),
    ('alcatraz-island', 'san-francisco', 'MUSEUM', 3, 4.8, 'Остров Алькатрас', 'Alcatraz Island', 'Алькатрас аралы', 37.82670000, -122.42300000, 'Alcatraz_Island_photo_D_Ramey_Logan.jpg', ARRAY['history', 'island']::text[]),
    ('golden-gate-park', 'san-francisco', 'PARK', 3, 4.8, 'Парк Золотые Ворота', 'Golden Gate Park', 'Алтын қақпа саябағы', 37.76940000, -122.48620000, 'Golden_Gate_Park_Aerial.jpg', ARRAY['green-space', 'family']::text[]),
    ('sfmoma', 'san-francisco', 'MUSEUM', 2, 4.7, 'SFMOMA', 'SFMOMA', 'SFMOMA', 37.78570000, -122.40110000, 'SFMOMA_2016.jpg', ARRAY['modern-art', 'indoor']::text[]),
    ('ferry-building-marketplace', 'san-francisco', 'MARKET', 1, 4.7, 'Ferry Building Marketplace', 'Ferry Building Marketplace', 'Ferry Building Marketplace', 37.79550000, -122.39370000, 'San_Francisco_Ferry_Building_2018.jpg', ARRAY['food-market', 'waterfront']::text[]),
    ('pier-39-fishermans-wharf', 'san-francisco', 'ENTERTAINMENT', 2, 4.5, 'PIER 39 и Fishermans Wharf', 'PIER 39 and Fishermans Wharf', 'PIER 39 және Fishermans Wharf', 37.80870000, -122.40980000, 'Pier_39_San_Francisco.jpg', ARRAY['family', 'waterfront']::text[]),

    ('balboa-park', 'san-diego', 'PARK', 4, 4.8, 'Парк Бальбоа', 'Balboa Park', 'Бальбоа саябағы', 32.73410000, -117.14460000, 'Balboa_Park_San_Diego.jpg', ARRAY['museums', 'green-space']::text[]),
    ('san-diego-zoo', 'san-diego', 'ENTERTAINMENT', 4, 4.9, 'Зоопарк Сан-Диего', 'San Diego Zoo', 'Сан-Диего зообағы', 32.73530000, -117.14900000, 'San_Diego_Zoo_entrance.jpg', ARRAY['family', 'wildlife']::text[]),
    ('uss-midway-museum', 'san-diego', 'MUSEUM', 3, 4.8, 'Музей USS Midway', 'USS Midway Museum', 'USS Midway музейі', 32.71370000, -117.17510000, 'USS_Midway_Museum_2020.jpg', ARRAY['maritime-history', 'indoor']::text[]),
    ('la-jolla-cove', 'san-diego', 'BEACH', 2, 4.8, 'Бухта Ла-Хойя', 'La Jolla Cove', 'Ла-Хойя бухтасы', 32.85070000, -117.27260000, 'La_Jolla_Cove_2018.jpg', ARRAY['beach', 'wildlife']::text[]),
    ('coronado-beach', 'san-diego', 'BEACH', 3, 4.8, 'Пляж Коронадо', 'Coronado Beach', 'Коронадо жағажайы', 32.68000000, -117.18000000, 'Coronado_Beach_San_Diego.jpg', ARRAY['beach', 'family']::text[]),
    ('liberty-public-market', 'san-diego', 'MARKET', 1, 4.6, 'Liberty Public Market', 'Liberty Public Market', 'Liberty Public Market', 32.74010000, -117.21280000, 'Liberty_Public_Market_San_Diego.jpg', ARRAY['food-market', 'indoor']::text[]),

    ('fountains-of-bellagio', 'las-vegas', 'ENTERTAINMENT', 1, 4.8, 'Фонтаны Белладжио', 'Fountains of Bellagio', 'Белладжио фонтандары', 36.11270000, -115.17670000, 'Bellagio_Fountains_Las_Vegas.jpg', ARRAY['evening-show', 'free']::text[]),
    ('fremont-street-experience', 'las-vegas', 'ENTERTAINMENT', 2, 4.6, 'Fremont Street Experience', 'Fremont Street Experience', 'Fremont Street Experience', 36.17070000, -115.14440000, 'Fremont_Street_Experience_Las_Vegas.jpg', ARRAY['evening', 'downtown']::text[]),
    ('mob-museum', 'las-vegas', 'MUSEUM', 2, 4.7, 'Музей мафии', 'The Mob Museum', 'Мафия музейі', 36.17280000, -115.14120000, 'The_Mob_Museum_Las_Vegas.jpg', ARRAY['history', 'indoor']::text[]),
    ('area15', 'las-vegas', 'ENTERTAINMENT', 3, 4.6, 'AREA15', 'AREA15', 'AREA15', 36.13250000, -115.18030000, 'AREA15_Las_Vegas.jpg', ARRAY['immersive', 'indoor']::text[]),
    ('grand-canal-shoppes', 'las-vegas', 'SHOPPING', 2, 4.6, 'Grand Canal Shoppes', 'Grand Canal Shoppes', 'Grand Canal Shoppes', 36.12130000, -115.16960000, 'Grand_Canal_Shoppes_Las_Vegas.jpg', ARRAY['mall', 'indoor']::text[]),
    ('red-rock-canyon', 'las-vegas', 'NATURE', 4, 4.8, 'Национальная заповедная зона Red Rock Canyon', 'Red Rock Canyon National Conservation Area', 'Red Rock Canyon ұлттық қорық аймағы', 36.13500000, -115.42790000, 'Red_Rock_Canyon_Nevada_2013.jpg', ARRAY['desert', 'scenic-drive']::text[]),

    ('space-needle', 'seattle', 'ARCHITECTURE', 2, 4.7, 'Спейс-Нидл', 'Space Needle', 'Space Needle', 47.62050000, -122.34930000, 'Space_Needle002.jpg', ARRAY['viewpoint', 'landmark']::text[]),
    ('pike-place-market', 'seattle', 'MARKET', 2, 4.8, 'Pike Place Market', 'Pike Place Market', 'Pike Place Market', 47.60970000, -122.34250000, 'Pike_Place_Market_Seattle.jpg', ARRAY['covered-market', 'food-market']::text[]),
    ('chihuly-garden-glass', 'seattle', 'MUSEUM', 2, 4.7, 'Chihuly Garden and Glass', 'Chihuly Garden and Glass', 'Chihuly Garden and Glass', 47.62060000, -122.35050000, 'Chihuly_Garden_and_Glass.jpg', ARRAY['glass-art', 'indoor']::text[]),
    ('museum-pop-culture', 'seattle', 'MUSEUM', 2, 4.6, 'Музей поп-культуры', 'Museum of Pop Culture', 'Поп-мәдениет музейі', 47.62150000, -122.34800000, 'Museum_of_Pop_Culture_Seattle.jpg', ARRAY['music', 'indoor']::text[]),
    ('olympic-sculpture-park', 'seattle', 'PARK', 1, 4.6, 'Olympic Sculpture Park', 'Olympic Sculpture Park', 'Olympic Sculpture Park', 47.61660000, -122.35530000, 'Olympic_Sculpture_Park_Seattle.jpg', ARRAY['public-art', 'waterfront']::text[]),
    ('alki-beach', 'seattle', 'BEACH', 2, 4.6, 'Пляж Алки', 'Alki Beach', 'Алки жағажайы', 47.58120000, -122.40570000, 'Alki_Beach_Seattle.jpg', ARRAY['beach', 'viewpoint']::text[]),

    ('powells-city-books', 'portland', 'SHOPPING', 2, 4.8, 'Powells City of Books', 'Powells City of Books', 'Powells City of Books', 45.52310000, -122.68130000, 'Powells_City_of_Books_Portland.jpg', ARRAY['bookstore', 'central']::text[]),
    ('washington-park-portland', 'portland', 'PARK', 3, 4.8, 'Washington Park в Портленде', 'Washington Park Portland', 'Портленд Washington Park', 45.51650000, -122.70430000, 'Washington_Park_Portland_Oregon.jpg', ARRAY['green-space', 'family']::text[]),
    ('portland-japanese-garden', 'portland', 'PARK', 2, 4.8, 'Японский сад Портленда', 'Portland Japanese Garden', 'Портленд жапон бағы', 45.51870000, -122.70820000, 'Portland_Japanese_Garden_2019.jpg', ARRAY['garden', 'culture']::text[]),
    ('portland-saturday-market', 'portland', 'MARKET', 1, 4.6, 'Portland Saturday Market', 'Portland Saturday Market', 'Portland Saturday Market', 45.52270000, -122.67060000, 'Portland_Saturday_Market.jpg', ARRAY['craft-market', 'weekend']::text[]),
    ('pittock-mansion', 'portland', 'ARCHITECTURE', 2, 4.7, 'Особняк Питток', 'Pittock Mansion', 'Питток сарайы', 45.52520000, -122.71620000, 'Pittock_Mansion_Portland.jpg', ARRAY['mansion', 'viewpoint']::text[]),
    ('lan-su-chinese-garden', 'portland', 'PARK', 1, 4.7, 'Китайский сад Лань Су', 'Lan Su Chinese Garden', 'Лань Су қытай бағы', 45.52510000, -122.67270000, 'Lan_Su_Chinese_Garden_Portland.jpg', ARRAY['garden', 'culture']::text[]),

    ('south-beach-miami', 'miami', 'BEACH', 3, 4.7, 'Саут-Бич Майами', 'South Beach Miami', 'Майами Саут-Бич', 25.79070000, -80.13000000, 'South_Beach_Miami.jpg', ARRAY['beach', 'art-deco']::text[]),
    ('vizcaya-museum-gardens', 'miami', 'MUSEUM', 2, 4.7, 'Музей и сады Вискайя', 'Vizcaya Museum and Gardens', 'Вискайя музейі және бақтары', 25.74440000, -80.21020000, 'Vizcaya_Museum_and_Gardens.jpg', ARRAY['villa', 'garden']::text[]),
    ('wynwood-walls', 'miami', 'ARCHITECTURE', 2, 4.6, 'Wynwood Walls', 'Wynwood Walls', 'Wynwood Walls', 25.80110000, -80.19950000, 'Wynwood_Walls_Miami.jpg', ARRAY['street-art', 'photo-stop']::text[]),
    ('perez-art-museum-miami', 'miami', 'MUSEUM', 2, 4.5, 'Perez Art Museum Miami', 'Perez Art Museum Miami', 'Perez Art Museum Miami', 25.78600000, -80.18650000, 'Perez_Art_Museum_Miami.jpg', ARRAY['modern-art', 'waterfront']::text[]),

    ('walt-disney-world-resort', 'orlando', 'ENTERTAINMENT', 8, 4.9, 'Walt Disney World Resort', 'Walt Disney World Resort', 'Walt Disney World Resort', 28.38520000, -81.56390000, 'Cinderella_Castle_Magic_Kingdom_Walt_Disney_World.jpg', ARRAY['theme-park', 'family']::text[]),
    ('universal-orlando-resort', 'orlando', 'ENTERTAINMENT', 8, 4.8, 'Universal Orlando Resort', 'Universal Orlando Resort', 'Universal Orlando Resort', 28.47440000, -81.46850000, 'Universal_Orlando_Resort_2017.jpg', ARRAY['theme-park', 'family']::text[]),
    ('lake-eola-park', 'orlando', 'PARK', 2, 4.7, 'Парк Lake Eola', 'Lake Eola Park', 'Lake Eola саябағы', 28.54390000, -81.37230000, 'Lake_Eola_Park_Orlando.jpg', ARRAY['downtown', 'green-space']::text[]),
    ('icon-park-orlando', 'orlando', 'ENTERTAINMENT', 2, 4.5, 'ICON Park Orlando', 'ICON Park Orlando', 'ICON Park Orlando', 28.44350000, -81.47100000, 'ICON_Park_Orlando.jpg', ARRAY['observation-wheel', 'evening']::text[]),

    ('french-quarter-new-orleans', 'new-orleans', 'ARCHITECTURE', 3, 4.8, 'Французский квартал Нового Орлеана', 'French Quarter New Orleans', 'Жаңа Орлеан Француз кварталы', 29.95840000, -90.06440000, 'French_Quarter_New_Orleans.jpg', ARRAY['historic-district', 'music']::text[]),
    ('national-wwii-museum', 'new-orleans', 'MUSEUM', 3, 4.9, 'Национальный музей Второй мировой войны', 'The National WWII Museum', 'Екінші дүниежүзілік соғыс ұлттық музейі', 29.94300000, -90.07020000, 'National_WWII_Museum_New_Orleans.jpg', ARRAY['history', 'indoor']::text[]),
    ('new-orleans-city-park', 'new-orleans', 'PARK', 3, 4.8, 'Городской парк Нового Орлеана', 'New Orleans City Park', 'Жаңа Орлеан қалалық саябағы', 29.98650000, -90.09880000, 'New_Orleans_City_Park.jpg', ARRAY['green-space', 'family']::text[]),
    ('french-market-new-orleans', 'new-orleans', 'MARKET', 1, 4.5, 'Французский рынок Нового Орлеана', 'French Market New Orleans', 'Жаңа Орлеан Француз базары', 29.95890000, -90.06170000, 'French_Market_New_Orleans.jpg', ARRAY['food-market', 'historic-market']::text[]),

    ('texas-state-capitol', 'austin', 'ARCHITECTURE', 2, 4.8, 'Капитолий штата Техас', 'Texas State Capitol', 'Техас штатының Капитолийі', 30.27470000, -97.74040000, 'Texas_State_Capitol_Austin.jpg', ARRAY['government', 'landmark']::text[]),
    ('zilker-metropolitan-park', 'austin', 'PARK', 3, 4.7, 'Zilker Metropolitan Park', 'Zilker Metropolitan Park', 'Zilker Metropolitan Park', 30.26700000, -97.77290000, 'Zilker_Park_Austin.jpg', ARRAY['green-space', 'family']::text[]),
    ('barton-springs-pool', 'austin', 'NATURE', 2, 4.7, 'Barton Springs Pool', 'Barton Springs Pool', 'Barton Springs Pool', 30.26400000, -97.77130000, 'Barton_Springs_Pool_Austin.jpg', ARRAY['swimming', 'spring']::text[]),
    ('blanton-museum-art', 'austin', 'MUSEUM', 2, 4.6, 'Музей искусств Блантона', 'Blanton Museum of Art', 'Блантон өнер музейі', 30.28090000, -97.73770000, 'Blanton_Museum_of_Art_Austin.jpg', ARRAY['art', 'indoor']::text[]),

    ('sixth-floor-museum', 'dallas', 'MUSEUM', 2, 4.7, 'Музей шестого этажа на Дили-Плаза', 'The Sixth Floor Museum at Dealey Plaza', 'Dealey Plaza алтыншы қабат музейі', 32.77980000, -96.80850000, 'Sixth_Floor_Museum_Dallas.jpg', ARRAY['history', 'indoor']::text[]),
    ('dallas-museum-art', 'dallas', 'MUSEUM', 2, 4.7, 'Далласский музей искусств', 'Dallas Museum of Art', 'Даллас өнер музейі', 32.78760000, -96.80100000, 'Dallas_Museum_of_Art.jpg', ARRAY['art', 'indoor']::text[]),
    ('klyde-warren-park', 'dallas', 'PARK', 2, 4.7, 'Klyde Warren Park', 'Klyde Warren Park', 'Klyde Warren Park', 32.78940000, -96.80170000, 'Klyde_Warren_Park_Dallas.jpg', ARRAY['green-space', 'food-trucks']::text[]),
    ('northpark-center', 'dallas', 'SHOPPING', 2, 4.6, 'NorthPark Center', 'NorthPark Center', 'NorthPark Center', 32.86880000, -96.77350000, 'NorthPark_Center_Dallas.jpg', ARRAY['mall', 'indoor']::text[]),

    ('space-center-houston', 'houston', 'MUSEUM', 4, 4.8, 'Космический центр Хьюстона', 'Space Center Houston', 'Хьюстон ғарыш орталығы', 29.55180000, -95.09820000, 'Space_Center_Houston.jpg', ARRAY['space', 'family']::text[]),
    ('museum-fine-arts-houston', 'houston', 'MUSEUM', 3, 4.8, 'Музей изящных искусств Хьюстона', 'Museum of Fine Arts Houston', 'Хьюстон бейнелеу өнері музейі', 29.72560000, -95.39050000, 'Museum_of_Fine_Arts_Houston.jpg', ARRAY['art', 'indoor']::text[]),
    ('houston-zoo', 'houston', 'ENTERTAINMENT', 3, 4.7, 'Зоопарк Хьюстона', 'Houston Zoo', 'Хьюстон зообағы', 29.71580000, -95.39020000, 'Houston_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),
    ('galleria-houston', 'houston', 'SHOPPING', 2, 4.5, 'The Galleria Houston', 'The Galleria Houston', 'The Galleria Houston', 29.73990000, -95.46360000, 'The_Galleria_Houston.jpg', ARRAY['mall', 'indoor']::text[]),

    ('the-alamo', 'san-antonio', 'ARCHITECTURE', 2, 4.8, 'Аламо', 'The Alamo', 'Аламо', 29.42590000, -98.48610000, 'The_Alamo_2019.jpg', ARRAY['history', 'landmark']::text[]),
    ('san-antonio-river-walk', 'san-antonio', 'ARCHITECTURE', 3, 4.8, 'Набережная Сан-Антонио River Walk', 'San Antonio River Walk', 'Сан-Антонио River Walk', 29.42410000, -98.49360000, 'San_Antonio_River_Walk.jpg', ARRAY['waterfront', 'walk']::text[]),
    ('san-antonio-missions', 'san-antonio', 'ARCHITECTURE', 4, 4.8, 'Национальный исторический парк миссий Сан-Антонио', 'San Antonio Missions National Historical Park', 'Сан-Антонио миссиялары ұлттық тарихи паркі', 29.32850000, -98.46220000, 'Mission_San_Jose_San_Antonio.jpg', ARRAY['unesco', 'history']::text[]),
    ('historic-market-square-san-antonio', 'san-antonio', 'MARKET', 1, 4.5, 'Историческая рыночная площадь Сан-Антонио', 'Historic Market Square San Antonio', 'Сан-Антонио тарихи базар алаңы', 29.42470000, -98.49990000, 'Historic_Market_Square_San_Antonio.jpg', ARRAY['market', 'food']::text[]),

    ('grand-canyon-south-rim', 'grand-canyon', 'NATURE', 5, 4.9, 'Южный край Гранд-Каньона', 'Grand Canyon South Rim', 'Гранд-Каньон оңтүстік жиегі', 36.05720000, -112.14390000, 'Grand_Canyon_South_Rim.jpg', ARRAY['national-park', 'viewpoint']::text[]),
    ('mather-point', 'grand-canyon', 'NATURE', 1, 4.8, 'Mather Point', 'Mather Point', 'Mather Point', 36.06170000, -112.10810000, 'Mather_Point_Grand_Canyon.jpg', ARRAY['viewpoint', 'sunrise']::text[]),
    ('desert-view-watchtower', 'grand-canyon', 'ARCHITECTURE', 1, 4.7, 'Desert View Watchtower', 'Desert View Watchtower', 'Desert View Watchtower', 36.04470000, -111.82650000, 'Desert_View_Watchtower.jpg', ARRAY['viewpoint', 'historic']::text[]),

    ('yellowstone-national-park', 'yellowstone', 'PARK', 6, 4.9, 'Йеллоустонский национальный парк', 'Yellowstone National Park', 'Йеллоустоун ұлттық паркі', 44.42800000, -110.58850000, 'Yellowstone_National_Park_banner.jpg', ARRAY['national-park', 'wildlife']::text[]),
    ('old-faithful-yellowstone', 'yellowstone', 'NATURE', 2, 4.9, 'Old Faithful в Йеллоустоуне', 'Old Faithful Yellowstone', 'Йеллоустоун Old Faithful', 44.46050000, -110.82810000, 'Old_Faithful_geyser_Yellowstone.jpg', ARRAY['geyser', 'family']::text[]),
    ('grand-prismatic-spring', 'yellowstone', 'NATURE', 2, 4.9, 'Большой призматический источник', 'Grand Prismatic Spring', 'Үлкен призмалық бұлақ', 44.52500000, -110.83820000, 'Grand_Prismatic_Spring_2013.jpg', ARRAY['hot-spring', 'viewpoint']::text[]),
    ('grand-canyon-yellowstone', 'yellowstone', 'NATURE', 3, 4.9, 'Большой каньон Йеллоустоуна', 'Grand Canyon of the Yellowstone', 'Йеллоустоун Үлкен каньоны', 44.71970000, -110.49660000, 'Grand_Canyon_of_the_Yellowstone.jpg', ARRAY['waterfall', 'viewpoint']::text[]),

    ('yosemite-national-park', 'yosemite', 'PARK', 6, 4.9, 'Национальный парк Йосемити', 'Yosemite National Park', 'Йосемити ұлттық паркі', 37.86510000, -119.53830000, 'Tunnel_View_Yosemite_Valley.jpg', ARRAY['national-park', 'mountains']::text[]),
    ('yosemite-valley', 'yosemite', 'NATURE', 5, 4.9, 'Долина Йосемити', 'Yosemite Valley', 'Йосемити аңғары', 37.74560000, -119.59360000, 'Yosemite_Valley_from_Tunnel_View.jpg', ARRAY['valley', 'viewpoint']::text[]),
    ('glacier-point', 'yosemite', 'NATURE', 2, 4.9, 'Glacier Point', 'Glacier Point', 'Glacier Point', 37.73040000, -119.57370000, 'Glacier_Point_Yosemite.jpg', ARRAY['viewpoint', 'seasonal']::text[]),
    ('mariposa-grove', 'yosemite', 'NATURE', 3, 4.8, 'Роща гигантских секвой Марипоса', 'Mariposa Grove of Giant Sequoias', 'Марипоса алып секвойя тоғайы', 37.51340000, -119.60020000, 'Mariposa_Grove_Yosemite.jpg', ARRAY['sequoia', 'forest']::text[]),

    ('zion-national-park', 'zion', 'PARK', 5, 4.9, 'Национальный парк Зайон', 'Zion National Park', 'Зайон ұлттық паркі', 37.29820000, -113.02630000, 'Zion_Canyon.jpg', ARRAY['national-park', 'canyon']::text[]),
    ('zion-canyon-scenic-drive', 'zion', 'NATURE', 3, 4.9, 'Живописная дорога по каньону Зайон', 'Zion Canyon Scenic Drive', 'Зайон каньоны көріністі жолы', 37.25080000, -112.95660000, 'Zion_Canyon_Scenic_Drive.jpg', ARRAY['scenic-drive', 'viewpoint']::text[]),
    ('the-narrows-zion', 'zion', 'NATURE', 5, 4.9, 'The Narrows в Зайоне', 'The Narrows Zion', 'Зайон The Narrows', 37.28540000, -112.94770000, 'The_Narrows_Zion.jpg', ARRAY['hiking', 'canyon']::text[]),
    ('angels-landing', 'zion', 'NATURE', 5, 4.9, 'Angels Landing', 'Angels Landing', 'Angels Landing', 37.26910000, -112.94790000, 'Angels_Landing_Zion.jpg', ARRAY['hiking', 'permit']::text[]),

    ('rocky-mountain-national-park', 'rocky-mountain', 'PARK', 5, 4.9, 'Национальный парк Роки-Маунтин', 'Rocky Mountain National Park', 'Роки-Маунтин ұлттық паркі', 40.34280000, -105.68360000, 'Rocky_Mountain_National_Park.jpg', ARRAY['national-park', 'mountains']::text[]),
    ('bear-lake-rocky-mountain', 'rocky-mountain', 'NATURE', 2, 4.9, 'Bear Lake в Роки-Маунтин', 'Bear Lake Rocky Mountain', 'Роки-Маунтин Bear Lake', 40.31330000, -105.64790000, 'Bear_Lake_Rocky_Mountain_National_Park.jpg', ARRAY['lake', 'family']::text[]),
    ('trail-ridge-road', 'rocky-mountain', 'NATURE', 3, 4.8, 'Trail Ridge Road', 'Trail Ridge Road', 'Trail Ridge Road', 40.39650000, -105.76760000, 'Trail_Ridge_Road.jpg', ARRAY['scenic-drive', 'seasonal']::text[]),
    ('emerald-lake-trail', 'rocky-mountain', 'NATURE', 3, 4.8, 'Тропа к озеру Emerald Lake', 'Emerald Lake Trail', 'Emerald Lake Trail', 40.31230000, -105.66650000, 'Emerald_Lake_Rocky_Mountain_National_Park.jpg', ARRAY['hiking', 'lake']::text[]),

    ('waikiki-beach', 'honolulu', 'BEACH', 3, 4.8, 'Пляж Вайкики', 'Waikiki Beach', 'Вайкики жағажайы', 21.27670000, -157.82620000, 'Waikiki_Beach_Honolulu.jpg', ARRAY['beach', 'surfing']::text[]),
    ('diamond-head-state-monument', 'honolulu', 'NATURE', 2, 4.8, 'Государственный памятник Diamond Head', 'Diamond Head State Monument', 'Diamond Head мемлекеттік ескерткіші', 21.26190000, -157.80530000, 'Diamond_Head_Hawaii.jpg', ARRAY['hiking', 'viewpoint']::text[]),
    ('hanauma-bay', 'honolulu', 'NATURE', 3, 4.7, 'Природный заповедник Hanauma Bay', 'Hanauma Bay Nature Preserve', 'Hanauma Bay табиғи қорығы', 21.26900000, -157.69380000, 'Hanauma_Bay_Oahu.jpg', ARRAY['snorkeling', 'marine']::text[]),
    ('pearl-harbor-national-memorial', 'honolulu', 'MUSEUM', 3, 4.8, 'Национальный мемориал Перл-Харбор', 'Pearl Harbor National Memorial', 'Перл-Харбор ұлттық мемориалы', 21.36500000, -157.95000000, 'USS_Arizona_Memorial_Pearl_Harbor.jpg', ARRAY['history', 'memorial']::text[]),

    ('haleakala-national-park', 'maui', 'PARK', 5, 4.9, 'Национальный парк Халеакала', 'Haleakala National Park', 'Халеакала ұлттық паркі', 20.72040000, -156.15520000, 'Haleakala_National_Park.jpg', ARRAY['national-park', 'volcano']::text[]),
    ('haleakala-summit', 'maui', 'NATURE', 3, 4.9, 'Вершина Халеакала', 'Haleakala Summit District', 'Халеакала шыңы', 20.70970000, -156.25330000, 'Haleakala_crater_Maui.jpg', ARRAY['sunrise', 'viewpoint']::text[]),
    ('kipahulu-oheo-gulch', 'maui', 'NATURE', 3, 4.7, 'Район Kipahulu и Oheo Gulch', 'Kipahulu District and Oheo Gulch', 'Kipahulu ауданы және Oheo Gulch', 20.66190000, -156.04530000, 'Oheo_Gulch_Maui.jpg', ARRAY['waterfall', 'road-to-hana']::text[]),
    ('waianapanapa-state-park', 'maui', 'BEACH', 2, 4.8, 'Государственный парк Waianapanapa', 'Waianapanapa State Park', 'Waianapanapa мемлекеттік саябағы', 20.78500000, -156.00330000, 'Waianapanapa_State_Park_Maui.jpg', ARRAY['black-sand-beach', 'coast']::text[]),

    ('chugach-state-park', 'anchorage', 'PARK', 4, 4.8, 'Государственный парк Чугач', 'Chugach State Park', 'Чугач мемлекеттік саябағы', 61.14990000, -149.28700000, 'Chugach_State_Park_Alaska.jpg', ARRAY['mountains', 'hiking']::text[]),
    ('flattop-mountain-glen-alps', 'anchorage', 'NATURE', 3, 4.8, 'Flattop Mountain и Glen Alps', 'Flattop Mountain and Glen Alps', 'Flattop Mountain және Glen Alps', 61.09030000, -149.66870000, 'Flattop_Mountain_Anchorage.jpg', ARRAY['hiking', 'viewpoint']::text[]),
    ('alaska-native-heritage-center', 'anchorage', 'MUSEUM', 2, 4.7, 'Центр наследия коренных народов Аляски', 'Alaska Native Heritage Center', 'Аляска жергілікті халықтары мұра орталығы', 61.23240000, -149.71790000, 'Alaska_Native_Heritage_Center.jpg', ARRAY['culture', 'indoor']::text[]),
    ('denali-national-park', 'denali', 'PARK', 6, 4.9, 'Национальный парк Денали', 'Denali National Park', 'Денали ұлттық паркі', 63.11480000, -151.19260000, 'Denali_National_Park.jpg', ARRAY['national-park', 'wildlife']::text[]),
    ('denali-park-road', 'denali', 'NATURE', 5, 4.8, 'Дорога Denali Park Road', 'Denali Park Road', 'Denali Park Road', 63.72800000, -148.88600000, 'Denali_Park_Road.jpg', ARRAY['scenic-drive', 'wildlife']::text[]),

    ('grand-ole-opry', 'nashville', 'ENTERTAINMENT', 3, 4.8, 'Гранд-Ол-Опри', 'Grand Ole Opry', 'Grand Ole Opry', 36.20680000, -86.69200000, 'Grand_Ole_Opry_House.jpg', ARRAY['music', 'evening']::text[]),
    ('country-music-hall-fame', 'nashville', 'MUSEUM', 2, 4.8, 'Зал славы и музей кантри-музыки', 'Country Music Hall of Fame and Museum', 'Кантри музыка даңқ залы және музейі', 36.15830000, -86.77610000, 'Country_Music_Hall_of_Fame_and_Museum.jpg', ARRAY['music', 'indoor']::text[]),
    ('ryman-auditorium', 'nashville', 'ENTERTAINMENT', 2, 4.8, 'Аудиториум Райман', 'Ryman Auditorium', 'Ryman Auditorium', 36.16130000, -86.77850000, 'Ryman_Auditorium_Nashville.jpg', ARRAY['music', 'history']::text[]),
    ('nmaam-nashville', 'nashville', 'MUSEUM', 2, 4.7, 'Национальный музей афроамериканской музыки', 'National Museum of African American Music', 'Афроамерикалық музыка ұлттық музейі', 36.16120000, -86.77900000, 'National_Museum_of_African_American_Music.jpg', ARRAY['music', 'culture']::text[]),
    ('nashville-farmers-market', 'nashville', 'MARKET', 1, 4.6, 'Фермерский рынок Нэшвилла', 'Nashville Farmers Market', 'Нэшвилл фермерлер базары', 36.17240000, -86.78760000, 'Nashville_Farmers_Market.jpg', ARRAY['food-market', 'local-market']::text[]),

    ('georgia-aquarium', 'atlanta', 'ENTERTAINMENT', 3, 4.8, 'Аквариум Джорджии', 'Georgia Aquarium', 'Джорджия аквариумы', 33.76340000, -84.39510000, 'Georgia_Aquarium_Atlanta.jpg', ARRAY['aquarium', 'family']::text[]),
    ('world-of-coca-cola', 'atlanta', 'MUSEUM', 2, 4.5, 'Мир Coca-Cola', 'World of Coca-Cola', 'Coca-Cola әлемі', 33.76270000, -84.39280000, 'World_of_Coca-Cola_Atlanta.jpg', ARRAY['brand-museum', 'family']::text[]),
    ('martin-luther-king-park', 'atlanta', 'ARCHITECTURE', 2, 4.8, 'Национальный исторический парк Мартина Лютера Кинга-младшего', 'Martin Luther King Jr National Historical Park', 'Мартин Лютер Кинг ұлттық тарихи паркі', 33.75540000, -84.37330000, 'Martin_Luther_King_Jr_National_Historical_Park.jpg', ARRAY['history', 'civil-rights']::text[]),
    ('piedmont-park', 'atlanta', 'PARK', 2, 4.7, 'Парк Пидмонт', 'Piedmont Park', 'Пидмонт саябағы', 33.78500000, -84.37360000, 'Piedmont_Park_Atlanta.jpg', ARRAY['green-space', 'central']::text[]),
    ('ponce-city-market', 'atlanta', 'MARKET', 2, 4.6, 'Ponce City Market', 'Ponce City Market', 'Ponce City Market', 33.77260000, -84.36550000, 'Ponce_City_Market_Atlanta.jpg', ARRAY['food-market', 'shopping']::text[]),

    ('fort-sumter-fort-moultrie', 'charleston', 'ARCHITECTURE', 3, 4.7, 'Форт-Самтер и Форт-Моултри', 'Fort Sumter and Fort Moultrie National Historical Park', 'Форт-Самтер және Форт-Моултри ұлттық тарихи паркі', 32.75230000, -79.87470000, 'Fort_Sumter_Charleston.jpg', ARRAY['history', 'national-park']::text[]),
    ('historic-charleston-city-market', 'charleston', 'MARKET', 1, 4.6, 'Исторический городской рынок Чарлстона', 'Historic Charleston City Market', 'Чарлстон тарихи қалалық базары', 32.78090000, -79.92930000, 'Charleston_City_Market.jpg', ARRAY['historic-market', 'souvenirs']::text[]),
    ('joe-riley-waterfront-park', 'charleston', 'PARK', 1, 4.7, 'Парк Joe Riley Waterfront', 'Joe Riley Waterfront Park', 'Joe Riley Waterfront саябағы', 32.77970000, -79.92560000, 'Waterfront_Park_Charleston.jpg', ARRAY['waterfront', 'walk']::text[]),
    ('rainbow-row', 'charleston', 'ARCHITECTURE', 1, 4.6, 'Rainbow Row', 'Rainbow Row', 'Rainbow Row', 32.77890000, -79.92600000, 'Rainbow_Row_Charleston.jpg', ARRAY['historic-street', 'photo-stop']::text[]),
    ('patriots-point', 'charleston', 'MUSEUM', 3, 4.7, 'Военно-морской музей Patriots Point', 'Patriots Point Naval and Maritime Museum', 'Patriots Point әскери-теңіз музейі', 32.79050000, -79.90690000, 'Patriots_Point_Charleston.jpg', ARRAY['maritime-history', 'indoor']::text[]),

    ('forsyth-park-savannah', 'savannah', 'PARK', 2, 4.8, 'Парк Форсайт в Саванне', 'Forsyth Park Savannah', 'Саванна Форсайт саябағы', 32.06760000, -81.09570000, 'Forsyth_Park_Savannah.jpg', ARRAY['green-space', 'central']::text[]),
    ('bonaventure-cemetery', 'savannah', 'ARCHITECTURE', 2, 4.7, 'Кладбище Бонавентура', 'Bonaventure Cemetery', 'Бонавентура зираты', 32.04500000, -81.05020000, 'Bonaventure_Cemetery_Savannah.jpg', ARRAY['history', 'walk']::text[]),
    ('historic-river-street-savannah', 'savannah', 'ARCHITECTURE', 2, 4.6, 'Историческая Ривер-стрит в Саванне', 'Historic River Street Savannah', 'Саванна тарихи River Street', 32.08100000, -81.09120000, 'River_Street_Savannah.jpg', ARRAY['waterfront', 'historic-district']::text[]),
    ('savannah-city-market', 'savannah', 'MARKET', 1, 4.5, 'Городской рынок Саванны', 'Savannah City Market', 'Саванна қалалық базары', 32.08090000, -81.09470000, 'Savannah_City_Market.jpg', ARRAY['market', 'food']::text[]),
    ('telfair-museums', 'savannah', 'MUSEUM', 2, 4.6, 'Музеи Телфэр', 'Telfair Museums', 'Телфэр музейлері', 32.07880000, -81.09580000, 'Telfair_Museums_Savannah.jpg', ARRAY['art', 'history']::text[]);

CREATE TEMP TABLE seed_united_states_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-united-states-attraction:' || seed.slug) AS attraction_hash,
        md5('id-united-states-media:' || seed.slug) AS media_hash
    FROM seed_united_states_priority_attractions seed
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
    'HOURS'::varchar(16) AS duration_unit,
    rating,
    ARRAY['united-states', city_id, slug, lower(category), 'united-states-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка США: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'United States tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'АҚШ туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' United States', ' ', '%20') AS location_source_url,
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
    'US',
    city_id,
    category,
    NULL::numeric,
    'USD',
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
FROM seed_united_states_resolved_attractions
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
FROM seed_united_states_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_united_states_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_united_states_resolved_attractions
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
FROM seed_united_states_resolved_attractions seed
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
FROM seed_united_states_resolved_attractions
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
    'US',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_united_states_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'US',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_united_states_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
