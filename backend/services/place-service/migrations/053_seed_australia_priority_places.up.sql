-- Priority Australia destination places seed.
-- The seed covers major city, coast, reef, outback, museum, shopping, market, wildlife, and entertainment hubs for localized discovery.

DROP TABLE IF EXISTS seed_australia_resolved_places;
DROP TABLE IF EXISTS seed_australia_priority_places;

CREATE TEMP TABLE seed_australia_priority_places (
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

INSERT INTO seed_australia_priority_places (
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
    ('sydney-opera-house', 'sydney', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Сиднейская опера', 'Sydney Opera House', 'Сидней опера театры', -33.85678000, 151.21530000, 'Sydney Opera House Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('sydney-harbour-bridge', 'sydney', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Сиднейский Харбор-Бридж', 'Sydney Harbour Bridge', 'Сидней Харбор көпірі', -33.85230000, 151.21080000, 'Sydney Harbour Bridge Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('royal-botanic-garden-sydney', 'sydney', 'PARK', 2, 'HOURS', 4.8, 'Королевский ботанический сад Сиднея', 'Royal Botanic Garden Sydney', 'Сидней корольдік ботаникалық бағы', -33.86420000, 151.21660000, 'Royal Botanic Garden Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('bondi-beach', 'sydney', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Бондай', 'Bondi Beach', 'Бондай жағажайы', -33.89150000, 151.27670000, 'Bondi Beach Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('manly-beach', 'sydney', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Мэнли', 'Manly Beach', 'Мэнли жағажайы', -33.79690000, 151.28730000, 'Manly Beach Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('taronga-zoo-sydney', 'sydney', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Зоопарк Таронга', 'Taronga Zoo Sydney', 'Таронга хайуанаттар бағы', -33.84380000, 151.24120000, 'Taronga Zoo Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('darling-harbour', 'sydney', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Дарлинг-Харбор', 'Darling Harbour', 'Дарлинг-Харбор', -33.87270000, 151.19990000, 'Darling Harbour Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('australian-museum-sydney', 'sydney', 'MUSEUM', 2, 'HOURS', 4.7, 'Австралийский музей', 'Australian Museum', 'Австралия музейі', -33.87450000, 151.21330000, 'Australian Museum Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('museum-contemporary-art-australia', 'sydney', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей современного искусства Австралии', 'Museum of Contemporary Art Australia', 'Австралия заманауи өнер музейі', -33.85990000, 151.20900000, 'Museum of Contemporary Art Australia Sydney', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('queen-victoria-building-sydney', 'sydney', 'SHOPPING', 2, 'HOURS', 4.7, 'Здание Королевы Виктории', 'Queen Victoria Building Sydney', 'Сидней Queen Victoria Building', -33.87180000, 151.20660000, 'Queen Victoria Building Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('chinatown-night-market-sydney', 'sydney', 'MARKET', 2, 'HOURS', 4.5, 'Ночной рынок Чайнатауна', 'Chinatown Night Market Sydney', 'Сидней Чайнатаун түнгі базары', -33.87910000, 151.20460000, 'Chinatown Night Market Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('paddys-markets-haymarket', 'sydney', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Пэддис Haymarket', 'Paddys Markets Haymarket', 'Haymarket Пэддис базары', -33.87990000, 151.20390000, 'Paddys Markets Haymarket Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('sydney-fish-market', 'sydney', 'FOOD', 2, 'HOURS', 4.6, 'Сиднейский рыбный рынок', 'Sydney Fish Market', 'Сидней балық базары', -33.87140000, 151.19150000, 'Sydney Fish Market Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('st-marys-cathedral-sydney', 'sydney', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святой Марии в Сиднее', 'St Marys Cathedral Sydney', 'Сидней Әулие Мария соборы', -33.87110000, 151.21340000, 'St Marys Cathedral Sydney Australia', ARRAY['sydney']::text[], ARRAY['sydney']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('blue-mountains-three-sisters', 'blue-mountains', 'NATURE', 3, 'HOURS', 4.9, 'Три Сестры в Голубых горах', 'Blue Mountains Three Sisters', 'Көк таулар Үш апалы-сіңлі', -33.73280000, 150.31250000, 'Three Sisters Blue Mountains Australia', ARRAY['blue-mountains']::text[], ARRAY['blue-mountains', 'sydney']::text[], 'Blue_Mountains_National_Park_(AU),_Three_Sisters_--_2019_--_1987-9.jpg'),
    ('scenic-world-blue-mountains', 'blue-mountains', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Scenic World в Голубых горах', 'Scenic World Blue Mountains', 'Көк таулар Scenic World', -33.72860000, 150.30190000, 'Scenic World Blue Mountains Australia', ARRAY['blue-mountains']::text[], ARRAY['blue-mountains', 'sydney']::text[], 'Blue_Mountains_National_Park_(AU),_Three_Sisters_--_2019_--_1987-9.jpg'),
    ('jenolan-caves', 'blue-mountains', 'NATURE', 4, 'HOURS', 4.7, 'Пещеры Дженолан', 'Jenolan Caves', 'Дженолан үңгірлері', -33.82060000, 150.02100000, 'Jenolan Caves Australia', ARRAY['blue-mountains']::text[], ARRAY['blue-mountains', 'sydney']::text[], 'Blue_Mountains_National_Park_(AU),_Three_Sisters_--_2019_--_1987-9.jpg'),
    ('parliament-house-canberra', 'canberra', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Парламент Австралии', 'Parliament House Canberra', 'Канберра парламент үйі', -35.30820000, 149.12450000, 'Parliament House Canberra Australia', ARRAY['canberra']::text[], ARRAY['canberra']::text[], 'Parliament_House_at_dusk,_Canberra_ACT.jpg'),
    ('australian-war-memorial', 'canberra', 'MUSEUM', 3, 'HOURS', 4.9, 'Австралийский военный мемориал', 'Australian War Memorial', 'Австралия соғыс мемориалы', -35.28090000, 149.14990000, 'Australian War Memorial Canberra', ARRAY['canberra']::text[], ARRAY['canberra']::text[], 'Parliament_House_at_dusk,_Canberra_ACT.jpg'),
    ('national-gallery-australia', 'canberra', 'MUSEUM', 3, 'HOURS', 4.7, 'Национальная галерея Австралии', 'National Gallery of Australia', 'Австралия ұлттық галереясы', -35.30060000, 149.13620000, 'National Gallery of Australia Canberra', ARRAY['canberra']::text[], ARRAY['canberra']::text[], 'Parliament_House_at_dusk,_Canberra_ACT.jpg'),
    ('national-museum-australia', 'canberra', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Австралии', 'National Museum of Australia', 'Австралия ұлттық музейі', -35.29310000, 149.12030000, 'National Museum of Australia Canberra', ARRAY['canberra']::text[], ARRAY['canberra']::text[], 'Parliament_House_at_dusk,_Canberra_ACT.jpg'),
    ('questacon-canberra', 'canberra', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Questacon', 'Questacon', 'Questacon', -35.29860000, 149.13240000, 'Questacon Canberra Australia', ARRAY['canberra']::text[], ARRAY['canberra']::text[], 'Parliament_House_at_dusk,_Canberra_ACT.jpg'),
    ('cape-byron-lighthouse', 'byron-bay', 'NATURE', 2, 'HOURS', 4.8, 'Маяк Кейп-Байрон', 'Cape Byron Lighthouse', 'Кейп-Байрон маяғы', -28.63880000, 153.63590000, 'Cape Byron Lighthouse Australia', ARRAY['byron-bay']::text[], ARRAY['byron-bay']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),
    ('byron-main-beach', 'byron-bay', 'BEACH', 3, 'HOURS', 4.7, 'Главный пляж Байрон-Бей', 'Byron Bay Main Beach', 'Байрон-Бей негізгі жағажайы', -28.64180000, 153.61450000, 'Byron Bay Main Beach Australia', ARRAY['byron-bay']::text[], ARRAY['byron-bay']::text[], 'Exterior_of_Sydney_Opera_House.jpg'),

    ('federation-square', 'melbourne', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Площадь Федерации', 'Federation Square', 'Федерация алаңы', -37.81790000, 144.96910000, 'Federation Square Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('hosier-lane', 'melbourne', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Переулок Хозьер', 'Hosier Lane', 'Хозьер жолағы', -37.81650000, 144.96900000, 'Hosier Lane Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('national-gallery-victoria', 'melbourne', 'MUSEUM', 3, 'HOURS', 4.8, 'Национальная галерея Виктории', 'National Gallery of Victoria', 'Виктория ұлттық галереясы', -37.82260000, 144.96890000, 'National Gallery of Victoria Melbourne', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('melbourne-museum', 'melbourne', 'MUSEUM', 3, 'HOURS', 4.7, 'Мельбурнский музей', 'Melbourne Museum', 'Мельбурн музейі', -37.80330000, 144.97170000, 'Melbourne Museum Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('royal-botanic-gardens-melbourne', 'melbourne', 'PARK', 3, 'HOURS', 4.8, 'Королевские ботанические сады Мельбурна', 'Royal Botanic Gardens Melbourne', 'Мельбурн корольдік ботаникалық бақтары', -37.83040000, 144.97960000, 'Royal Botanic Gardens Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('queen-victoria-market', 'melbourne', 'MARKET', 2, 'HOURS', 4.8, 'Рынок Королевы Виктории', 'Queen Victoria Market', 'Queen Victoria базары', -37.80760000, 144.95680000, 'Queen Victoria Market Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('south-melbourne-market', 'melbourne', 'MARKET', 2, 'HOURS', 4.6, 'Рынок South Melbourne', 'South Melbourne Market', 'South Melbourne базары', -37.83290000, 144.95770000, 'South Melbourne Market Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('bourke-street-mall', 'melbourne', 'SHOPPING', 2, 'HOURS', 4.6, 'Bourke Street Mall', 'Bourke Street Mall', 'Bourke Street Mall', -37.81360000, 144.96310000, 'Bourke Street Mall Melbourne', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('emporium-melbourne', 'melbourne', 'SHOPPING', 2, 'HOURS', 4.6, 'Emporium Melbourne', 'Emporium Melbourne', 'Emporium Melbourne', -37.81250000, 144.96340000, 'Emporium Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('st-kilda-beach', 'melbourne', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Сент-Килда', 'St Kilda Beach', 'Сент-Килда жағажайы', -37.86770000, 144.97690000, 'St Kilda Beach Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('luna-park-melbourne', 'melbourne', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Luna Park Melbourne', 'Luna Park Melbourne', 'Luna Park Melbourne', -37.86780000, 144.97670000, 'Luna Park Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('st-pauls-cathedral-melbourne', 'melbourne', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Святого Павла в Мельбурне', 'St Pauls Cathedral Melbourne', 'Мельбурн Әулие Павел соборы', -37.81690000, 144.96740000, 'St Pauls Cathedral Melbourne Australia', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg'),
    ('great-ocean-road-memorial-arch', 'great-ocean-road', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мемориальная арка Great Ocean Road', 'Great Ocean Road Memorial Arch', 'Ұлы мұхит жолы мемориал аркасы', -38.47140000, 144.04120000, 'Great Ocean Road Memorial Arch Australia', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('bells-beach', 'great-ocean-road', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Bells Beach', 'Bells Beach', 'Bells Beach', -38.36830000, 144.28400000, 'Bells Beach Australia', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('twelve-apostles', 'great-ocean-road', 'NATURE', 3, 'HOURS', 4.9, 'Двенадцать апостолов', 'Twelve Apostles', 'Он екі апостол', -38.66550000, 143.10400000, 'Twelve Apostles Great Ocean Road Australia', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('loch-ard-gorge', 'great-ocean-road', 'NATURE', 2, 'HOURS', 4.8, 'Ущелье Loch Ard Gorge', 'Loch Ard Gorge', 'Loch Ard шатқалы', -38.64930000, 143.07090000, 'Loch Ard Gorge Australia', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('erskine-falls', 'great-ocean-road', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Эрскин', 'Erskine Falls', 'Эрскин сарқырамасы', -38.53860000, 143.91250000, 'Erskine Falls Australia', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('penguin-parade', 'phillip-island', 'NATURE', 3, 'HOURS', 4.9, 'Парад пингвинов', 'Penguin Parade', 'Пингвиндер шеруі', -38.50650000, 145.15040000, 'Penguin Parade Phillip Island Australia', ARRAY['phillip-island']::text[], ARRAY['phillip-island', 'melbourne']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('the-nobbies-reserve', 'phillip-island', 'NATURE', 2, 'HOURS', 4.7, 'Заповедник The Nobbies', 'The Nobbies Reserve', 'The Nobbies қорығы', -38.52060000, 145.11270000, 'The Nobbies Phillip Island Australia', ARRAY['phillip-island']::text[], ARRAY['phillip-island']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('koala-conservation-reserve', 'phillip-island', 'NATURE', 2, 'HOURS', 4.6, 'Заповедник коал', 'Koala Conservation Reserve', 'Коала қорығы', -38.47640000, 145.23170000, 'Koala Conservation Reserve Phillip Island', ARRAY['phillip-island']::text[], ARRAY['phillip-island']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('a-mazen-things', 'phillip-island', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'A Maze N Things', 'A Maze N Things', 'A Maze N Things', -38.48070000, 145.23550000, 'A Maze N Things Phillip Island Australia', ARRAY['phillip-island']::text[], ARRAY['phillip-island']::text[], 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg'),
    ('salamanca-market', 'hobart', 'MARKET', 2, 'HOURS', 4.8, 'Рынок Salamanca', 'Salamanca Market', 'Salamanca базары', -42.88640000, 147.33020000, 'Salamanca Market Hobart Australia', ARRAY['hobart']::text[], ARRAY['hobart']::text[], 'Salamanca_Markets.jpg'),
    ('mona-hobart', 'hobart', 'MUSEUM', 3, 'HOURS', 4.8, 'MONA', 'MONA Museum of Old and New Art', 'MONA Museum of Old and New Art', -42.81260000, 147.25920000, 'MONA Hobart Tasmania Australia', ARRAY['hobart']::text[], ARRAY['hobart']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),
    ('mount-wellington-kunanyi', 'hobart', 'NATURE', 3, 'HOURS', 4.8, 'kunanyi / Mount Wellington', 'kunanyi Mount Wellington', 'kunanyi Mount Wellington', -42.89530000, 147.23530000, 'Mount Wellington Hobart Tasmania', ARRAY['hobart']::text[], ARRAY['hobart']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),
    ('tasmanian-museum-art-gallery', 'hobart', 'MUSEUM', 2, 'HOURS', 4.6, 'Тасманийский музей и художественная галерея', 'Tasmanian Museum and Art Gallery', 'Тасмания музейі және өнер галереясы', -42.88270000, 147.32950000, 'Tasmanian Museum and Art Gallery Hobart', ARRAY['hobart']::text[], ARRAY['hobart']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),
    ('royal-tasmanian-botanical-gardens', 'hobart', 'PARK', 2, 'HOURS', 4.6, 'Королевские тасманийские ботанические сады', 'Royal Tasmanian Botanical Gardens', 'Тасмания корольдік ботаникалық бағы', -42.86660000, 147.33030000, 'Royal Tasmanian Botanical Gardens Hobart', ARRAY['hobart']::text[], ARRAY['hobart']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),
    ('cataract-gorge', 'launceston', 'NATURE', 3, 'HOURS', 4.8, 'Ущелье Cataract Gorge', 'Cataract Gorge', 'Cataract шатқалы', -41.44590000, 147.12030000, 'Cataract Gorge Launceston Tasmania', ARRAY['launceston']::text[], ARRAY['launceston', 'hobart']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),
    ('james-boags-brewery', 'launceston', 'FOOD', 2, 'HOURS', 4.5, 'Пивоварня James Boag', 'James Boags Brewery', 'James Boag сыра зауыты', -41.43140000, 147.14210000, 'James Boags Brewery Launceston', ARRAY['launceston']::text[], ARRAY['launceston']::text[], 'Hobart_Tasmania_Salamanca_Place.jpg'),

    ('south-bank-parklands-brisbane', 'brisbane', 'PARK', 3, 'HOURS', 4.8, 'South Bank Parklands', 'South Bank Parklands', 'South Bank Parklands', -27.47670000, 153.02260000, 'South Bank Parklands Brisbane Australia', ARRAY['brisbane']::text[], ARRAY['brisbane']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('queensland-museum-kurilpa', 'brisbane', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Квинсленда Kurilpa', 'Queensland Museum Kurilpa', 'Queensland Museum Kurilpa', -27.47280000, 153.01830000, 'Queensland Museum Kurilpa Brisbane', ARRAY['brisbane']::text[], ARRAY['brisbane']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('eat-street-northshore', 'brisbane', 'MARKET', 2, 'HOURS', 4.7, 'Eat Street Northshore', 'Eat Street Northshore', 'Eat Street Northshore', -27.43960000, 153.08190000, 'Eat Street Northshore Brisbane Australia', ARRAY['brisbane']::text[], ARRAY['brisbane']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('mt-coot-tha-lookout', 'brisbane', 'NATURE', 2, 'HOURS', 4.7, 'Смотровая Mt Coot-tha', 'Mt Coot-tha Lookout', 'Mt Coot-tha көрініс алаңы', -27.46900000, 152.94850000, 'Mt Coot-tha Lookout Brisbane Australia', ARRAY['brisbane']::text[], ARRAY['brisbane']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('lone-pine-koala-sanctuary', 'brisbane', 'NATURE', 3, 'HOURS', 4.7, 'Заповедник коал Lone Pine', 'Lone Pine Koala Sanctuary', 'Lone Pine коала қорығы', -27.53310000, 152.96880000, 'Lone Pine Koala Sanctuary Brisbane', ARRAY['brisbane']::text[], ARRAY['brisbane']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('surfers-paradise-beach', 'gold-coast', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Surfers Paradise', 'Surfers Paradise Beach', 'Surfers Paradise жағажайы', -28.00270000, 153.43180000, 'Surfers Paradise Beach Gold Coast Australia', ARRAY['gold-coast']::text[], ARRAY['gold-coast', 'brisbane']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('burleigh-head-national-park', 'gold-coast', 'NATURE', 2, 'HOURS', 4.7, 'Национальный парк Burleigh Head', 'Burleigh Head National Park', 'Burleigh Head ұлттық паркі', -28.09610000, 153.45970000, 'Burleigh Head National Park Gold Coast', ARRAY['gold-coast']::text[], ARRAY['gold-coast']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('currumbin-wildlife-sanctuary', 'gold-coast', 'NATURE', 4, 'HOURS', 4.8, 'Заповедник Currumbin Wildlife Sanctuary', 'Currumbin Wildlife Sanctuary', 'Currumbin Wildlife Sanctuary', -28.13500000, 153.48880000, 'Currumbin Wildlife Sanctuary Gold Coast', ARRAY['gold-coast']::text[], ARRAY['gold-coast']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('pacific-fair', 'gold-coast', 'SHOPPING', 3, 'HOURS', 4.6, 'Pacific Fair Shopping Centre', 'Pacific Fair Shopping Centre', 'Pacific Fair Shopping Centre', -28.03690000, 153.42520000, 'Pacific Fair Shopping Centre Gold Coast', ARRAY['gold-coast']::text[], ARRAY['gold-coast']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('dreamworld-gold-coast', 'gold-coast', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Dreamworld', 'Dreamworld Gold Coast', 'Dreamworld Gold Coast', -27.86160000, 153.31690000, 'Dreamworld Gold Coast Australia', ARRAY['gold-coast']::text[], ARRAY['gold-coast']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('skypoint-observation-deck', 'gold-coast', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Смотровая SkyPoint', 'SkyPoint Observation Deck', 'SkyPoint көрініс алаңы', -28.00610000, 153.42960000, 'SkyPoint Observation Deck Gold Coast', ARRAY['gold-coast']::text[], ARRAY['gold-coast']::text[], 'Surfers_Paradise_Beach,_Gold_Coast,_Queensland,_Australia.jpg'),
    ('eumundi-markets', 'sunshine-coast', 'MARKET', 2, 'HOURS', 4.7, 'Eumundi Markets', 'Eumundi Markets', 'Eumundi Markets', -26.47740000, 152.95150000, 'Eumundi Markets Sunshine Coast Australia', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('mooloolaba-beach', 'sunshine-coast', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Mooloolaba', 'Mooloolaba Beach', 'Mooloolaba жағажайы', -26.68110000, 153.12070000, 'Mooloolaba Beach Sunshine Coast', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('sea-life-sunshine-coast', 'sunshine-coast', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'SEA LIFE Sunshine Coast', 'SEA LIFE Sunshine Coast', 'SEA LIFE Sunshine Coast', -26.68280000, 153.11840000, 'SEA LIFE Sunshine Coast Australia', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('australia-zoo', 'sunshine-coast', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Australia Zoo', 'Australia Zoo', 'Australia Zoo', -26.83540000, 152.96050000, 'Australia Zoo Sunshine Coast', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('sunshine-plaza', 'sunshine-coast', 'SHOPPING', 2, 'HOURS', 4.5, 'Sunshine Plaza', 'Sunshine Plaza', 'Sunshine Plaza', -26.65430000, 153.09040000, 'Sunshine Plaza Maroochydore Australia', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('noosa-national-park', 'noosa', 'NATURE', 3, 'HOURS', 4.8, 'Национальный парк Нуса', 'Noosa National Park', 'Нуса ұлттық паркі', -26.38860000, 153.09290000, 'Noosa National Park Australia', ARRAY['noosa']::text[], ARRAY['noosa', 'sunshine-coast']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('hastings-street-noosa', 'noosa', 'SHOPPING', 2, 'HOURS', 4.6, 'Hastings Street', 'Hastings Street Noosa', 'Hastings Street Noosa', -26.38610000, 153.09040000, 'Hastings Street Noosa Australia', ARRAY['noosa']::text[], ARRAY['noosa']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('noosa-main-beach', 'noosa', 'BEACH', 3, 'HOURS', 4.8, 'Главный пляж Нусы', 'Noosa Main Beach', 'Нуса негізгі жағажайы', -26.38640000, 153.09010000, 'Noosa Main Beach Australia', ARRAY['noosa']::text[], ARRAY['noosa']::text[], 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg'),
    ('cairns-esplanade-lagoon', 'cairns', 'PARK', 2, 'HOURS', 4.7, 'Лагуна Cairns Esplanade', 'Cairns Esplanade Lagoon', 'Cairns Esplanade Lagoon', -16.91860000, 145.77820000, 'Cairns Esplanade Lagoon Australia', ARRAY['cairns']::text[], ARRAY['cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('cairns-museum', 'cairns', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Кэрнса', 'Cairns Museum', 'Кэрнс музейі', -16.92210000, 145.77620000, 'Cairns Museum Australia', ARRAY['cairns']::text[], ARRAY['cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('rustys-markets-cairns', 'cairns', 'MARKET', 2, 'HOURS', 4.7, 'Rustys Markets', 'Rustys Markets Cairns', 'Rustys Markets Cairns', -16.92410000, 145.77580000, 'Rustys Markets Cairns Australia', ARRAY['cairns']::text[], ARRAY['cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('cairns-night-markets', 'cairns', 'MARKET', 2, 'HOURS', 4.5, 'Ночной рынок Кэрнса', 'Cairns Night Markets', 'Кэрнс түнгі базары', -16.92090000, 145.77830000, 'Cairns Night Markets Australia', ARRAY['cairns']::text[], ARRAY['cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('great-barrier-reef', 'cairns', 'NATURE', 6, 'HOURS', 4.9, 'Большой Барьерный риф', 'Great Barrier Reef', 'Үлкен тосқауыл рифі', -16.50000000, 146.00000000, 'Great Barrier Reef Cairns Australia', ARRAY['cairns']::text[], ARRAY['cairns', 'port-douglas']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('daintree-cape-tribulation', 'port-douglas', 'NATURE', 5, 'HOURS', 4.8, 'Дейнтри и Кейп-Трибьюлейшн', 'Daintree and Cape Tribulation', 'Дейнтри және Кейп-Трибьюлейшн', -16.25000000, 145.43000000, 'Daintree Cape Tribulation Australia', ARRAY['port-douglas']::text[], ARRAY['port-douglas', 'cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('four-mile-beach-port-douglas', 'port-douglas', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Four Mile Beach', 'Four Mile Beach Port Douglas', 'Four Mile Beach Port Douglas', -16.50080000, 145.46720000, 'Four Mile Beach Port Douglas Australia', ARRAY['port-douglas']::text[], ARRAY['port-douglas']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('kuranda-scenic-railway', 'kuranda', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Железная дорога Kuranda Scenic Railway', 'Kuranda Scenic Railway', 'Kuranda Scenic Railway', -16.81860000, 145.63890000, 'Kuranda Scenic Railway Australia', ARRAY['kuranda']::text[], ARRAY['kuranda', 'cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('kuranda-markets', 'kuranda', 'MARKET', 2, 'HOURS', 4.6, 'Рынки Куранды', 'Kuranda Markets', 'Куранда базарлары', -16.81870000, 145.63580000, 'Kuranda Markets Australia', ARRAY['kuranda']::text[], ARRAY['kuranda', 'cairns']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('whitehaven-beach-hill-inlet', 'whitsundays', 'BEACH', 5, 'HOURS', 4.9, 'Whitehaven Beach и Hill Inlet', 'Whitehaven Beach and Hill Inlet', 'Whitehaven Beach және Hill Inlet', -20.28750000, 149.03890000, 'Whitehaven Beach Hill Inlet Whitsundays Australia', ARRAY['whitsundays']::text[], ARRAY['whitsundays', 'airlie-beach']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('hamilton-island', 'whitsundays', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Остров Hamilton Island', 'Hamilton Island', 'Hamilton Island', -20.35170000, 148.95180000, 'Hamilton Island Whitsundays Australia', ARRAY['whitsundays']::text[], ARRAY['whitsundays', 'airlie-beach']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('airlie-beach-lagoon', 'airlie-beach', 'PARK', 2, 'HOURS', 4.6, 'Лагуна Airlie Beach', 'Airlie Beach Lagoon', 'Airlie Beach Lagoon', -20.26770000, 148.71640000, 'Airlie Beach Lagoon Australia', ARRAY['airlie-beach']::text[], ARRAY['airlie-beach']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),
    ('coral-sea-marina', 'airlie-beach', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Coral Sea', 'Coral Sea Marina', 'Coral Sea Marina', -20.26420000, 148.71100000, 'Coral Sea Marina Airlie Beach Australia', ARRAY['airlie-beach']::text[], ARRAY['airlie-beach']::text[], 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg'),

    ('rundle-mall', 'adelaide', 'SHOPPING', 2, 'HOURS', 4.6, 'Rundle Mall', 'Rundle Mall', 'Rundle Mall', -34.92290000, 138.60260000, 'Rundle Mall Adelaide Australia', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('adelaide-central-market', 'adelaide', 'MARKET', 2, 'HOURS', 4.8, 'Центральный рынок Аделаиды', 'Adelaide Central Market', 'Аделаида орталық базары', -34.92930000, 138.59800000, 'Adelaide Central Market Australia', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('art-gallery-south-australia', 'adelaide', 'MUSEUM', 2, 'HOURS', 4.7, 'Художественная галерея Южной Австралии', 'Art Gallery of South Australia', 'Оңтүстік Австралия өнер галереясы', -34.92100000, 138.60400000, 'Art Gallery of South Australia Adelaide', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('adelaide-botanic-garden', 'adelaide', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Аделаиды', 'Adelaide Botanic Garden', 'Аделаида ботаникалық бағы', -34.91720000, 138.61150000, 'Adelaide Botanic Garden Australia', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('glenelg-beach', 'adelaide', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Гленелг', 'Glenelg Beach', 'Гленелг жағажайы', -34.98080000, 138.51110000, 'Glenelg Beach Adelaide Australia', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('adelaide-oval', 'adelaide', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Adelaide Oval', 'Adelaide Oval', 'Adelaide Oval', -34.91550000, 138.59620000, 'Adelaide Oval Australia', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('seppeltsfield-estate', 'barossa-valley', 'FOOD', 3, 'HOURS', 4.7, 'Seppeltsfield Estate', 'Seppeltsfield Estate', 'Seppeltsfield Estate', -34.48880000, 138.92570000, 'Seppeltsfield Estate Barossa Valley Australia', ARRAY['barossa-valley']::text[], ARRAY['barossa-valley', 'adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('jacobs-creek-visitor-centre', 'barossa-valley', 'FOOD', 2, 'HOURS', 4.6, 'Визитор-центр Jacobs Creek', 'Jacobs Creek Visitor Centre', 'Jacobs Creek Visitor Centre', -34.53820000, 138.95770000, 'Jacobs Creek Visitor Centre Barossa Valley Australia', ARRAY['barossa-valley']::text[], ARRAY['barossa-valley', 'adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('mengler-hill-lookout', 'barossa-valley', 'NATURE', 1, 'HOURS', 4.6, 'Смотровая Mengler Hill', 'Mengler Hill Lookout', 'Mengler Hill көрініс алаңы', -34.51990000, 138.97990000, 'Mengler Hill Lookout Barossa Valley', ARRAY['barossa-valley']::text[], ARRAY['barossa-valley']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('flinders-chase-national-park', 'kangaroo-island', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Flinders Chase', 'Flinders Chase National Park', 'Flinders Chase ұлттық паркі', -35.95360000, 136.73420000, 'Flinders Chase National Park Kangaroo Island', ARRAY['kangaroo-island']::text[], ARRAY['kangaroo-island', 'adelaide']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('remarkable-rocks', 'kangaroo-island', 'NATURE', 2, 'HOURS', 4.8, 'Remarkable Rocks', 'Remarkable Rocks', 'Remarkable Rocks', -36.05940000, 136.75690000, 'Remarkable Rocks Kangaroo Island Australia', ARRAY['kangaroo-island']::text[], ARRAY['kangaroo-island']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('admirals-arch', 'kangaroo-island', 'NATURE', 2, 'HOURS', 4.8, 'Арка Адмирала', 'Admirals Arch', 'Admirals Arch', -36.06560000, 136.70510000, 'Admirals Arch Kangaroo Island Australia', ARRAY['kangaroo-island']::text[], ARRAY['kangaroo-island']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),
    ('seal-bay', 'kangaroo-island', 'NATURE', 2, 'HOURS', 4.8, 'Seal Bay', 'Seal Bay', 'Seal Bay', -35.99500000, 137.31670000, 'Seal Bay Kangaroo Island Australia', ARRAY['kangaroo-island']::text[], ARRAY['kangaroo-island']::text[], '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg'),

    ('mindil-beach-sunset-market', 'darwin', 'MARKET', 2, 'HOURS', 4.8, 'Ночной рынок Mindil Beach', 'Mindil Beach Sunset Market', 'Mindil Beach Sunset Market', -12.44870000, 130.83240000, 'Mindil Beach Sunset Market Darwin Australia', ARRAY['darwin']::text[], ARRAY['darwin']::text[], 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg'),
    ('magnt-darwin', 'darwin', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей и художественная галерея Северной территории', 'Museum and Art Gallery of the Northern Territory', 'Солтүстік аумақ музейі және өнер галереясы', -12.43890000, 130.83450000, 'Museum and Art Gallery of the Northern Territory Darwin', ARRAY['darwin']::text[], ARRAY['darwin']::text[], 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg'),
    ('crocosaurus-cove', 'darwin', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Crocosaurus Cove', 'Crocosaurus Cove', 'Crocosaurus Cove', -12.46140000, 130.84160000, 'Crocosaurus Cove Darwin Australia', ARRAY['darwin']::text[], ARRAY['darwin']::text[], 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg'),
    ('darwin-waterfront-wave-lagoon', 'darwin', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Лагуна с волнами на набережной Дарвина', 'Darwin Waterfront Wave Lagoon', 'Darwin Waterfront Wave Lagoon', -12.46730000, 130.84640000, 'Darwin Waterfront Wave Lagoon Australia', ARRAY['darwin']::text[], ARRAY['darwin']::text[], 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg'),
    ('parap-village-markets', 'darwin', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Parap Village', 'Parap Village Markets', 'Parap Village Markets', -12.43030000, 130.84350000, 'Parap Village Markets Darwin Australia', ARRAY['darwin']::text[], ARRAY['darwin']::text[], 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg'),
    ('ubirr-kakadu', 'kakadu', 'NATURE', 3, 'HOURS', 4.9, 'Убирр в Какаду', 'Kakadu Ubirr', 'Какаду Убирр', -12.40870000, 132.95410000, 'Ubirr Kakadu National Park Australia', ARRAY['kakadu']::text[], ARRAY['kakadu', 'darwin']::text[], 'Kakadu_(AU),_Kakadu_National_Park,_Nadap_Lookout_--_2019_--_4200.jpg'),
    ('burrungkuy-nourlangie', 'kakadu', 'NATURE', 3, 'HOURS', 4.8, 'Буррунгуй / Нурланги', 'Burrungkuy Nourlangie Kakadu', 'Буррунгуй Нурланги Какаду', -12.85860000, 132.80720000, 'Burrungkuy Nourlangie Kakadu Australia', ARRAY['kakadu']::text[], ARRAY['kakadu', 'darwin']::text[], 'Kakadu_(AU),_Kakadu_National_Park,_Nadap_Lookout_--_2019_--_4200.jpg'),
    ('yellow-water-billabong', 'kakadu', 'NATURE', 3, 'HOURS', 4.8, 'Биллабонг Yellow Water', 'Yellow Water Billabong', 'Yellow Water Billabong', -12.89500000, 132.52360000, 'Yellow Water Billabong Kakadu Australia', ARRAY['kakadu']::text[], ARRAY['kakadu']::text[], 'Kakadu_(AU),_Kakadu_National_Park,_Nadap_Lookout_--_2019_--_4200.jpg'),
    ('alice-springs-desert-park', 'alice-springs', 'NATURE', 3, 'HOURS', 4.7, 'Пустынный парк Алис-Спрингс', 'Alice Springs Desert Park', 'Alice Springs Desert Park', -23.70160000, 133.83350000, 'Alice Springs Desert Park Australia', ARRAY['alice-springs']::text[], ARRAY['alice-springs']::text[], 'Petermann_Ranges_(AU),_Uluru-Kata_Tjuta_National_Park,_Uluru,_Kuniya_Walk_--_2019_--_3674.jpg'),
    ('alice-springs-telegraph-station', 'alice-springs', 'MUSEUM', 2, 'HOURS', 4.6, 'Телеграфная станция Алис-Спрингс', 'Alice Springs Telegraph Station', 'Alice Springs Telegraph Station', -23.70030000, 133.88180000, 'Alice Springs Telegraph Station Australia', ARRAY['alice-springs']::text[], ARRAY['alice-springs']::text[], 'Petermann_Ranges_(AU),_Uluru-Kata_Tjuta_National_Park,_Uluru,_Kuniya_Walk_--_2019_--_3674.jpg'),
    ('uluru', 'uluru', 'NATURE', 4, 'HOURS', 4.9, 'Улуру', 'Uluru', 'Улуру', -25.34440000, 131.03690000, 'Uluru Australia', ARRAY['uluru']::text[], ARRAY['uluru', 'alice-springs']::text[], 'Petermann_Ranges_(AU),_Uluru-Kata_Tjuta_National_Park,_Uluru,_Kuniya_Walk_--_2019_--_3674.jpg'),
    ('kata-tjuta-valley-winds', 'uluru', 'NATURE', 4, 'HOURS', 4.8, 'Ката-Тьюта и Долина ветров', 'Kata Tjuta Valley of the Winds', 'Ката-Тьюта Желдер аңғары', -25.30070000, 130.73100000, 'Kata Tjuta Valley of the Winds Australia', ARRAY['uluru']::text[], ARRAY['uluru', 'alice-springs']::text[], 'Petermann_Ranges_(AU),_Uluru-Kata_Tjuta_National_Park,_Uluru,_Kuniya_Walk_--_2019_--_3674.jpg'),
    ('uluru-cultural-centre', 'uluru', 'MUSEUM', 2, 'HOURS', 4.7, 'Культурный центр Улуру-Ката-Тьюта', 'Uluru-Kata Tjuta Cultural Centre', 'Улуру-Ката Тьюта мәдени орталығы', -25.24060000, 130.98950000, 'Uluru-Kata Tjuta Cultural Centre Australia', ARRAY['uluru']::text[], ARRAY['uluru']::text[], 'Petermann_Ranges_(AU),_Uluru-Kata_Tjuta_National_Park,_Uluru,_Kuniya_Walk_--_2019_--_3674.jpg'),

    ('kings-park-botanic-garden', 'perth', 'PARK', 3, 'HOURS', 4.8, 'Кингс-парк и ботанический сад', 'Kings Park and Botanic Garden', 'Kings Park және ботаникалық бақ', -31.96160000, 115.83200000, 'Kings Park and Botanic Garden Perth Australia', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('elizabeth-quay', 'perth', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Elizabeth Quay', 'Elizabeth Quay', 'Elizabeth Quay', -31.95870000, 115.85760000, 'Elizabeth Quay Perth Australia', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('bell-tower-perth', 'perth', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Колокольня Перта', 'The Bell Tower Perth', 'Перт қоңырау мұнарасы', -31.95940000, 115.85870000, 'The Bell Tower Perth Australia', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('wa-museum-boola-bardip', 'perth', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей WA Boola Bardip', 'WA Museum Boola Bardip', 'WA Museum Boola Bardip', -31.94930000, 115.86100000, 'WA Museum Boola Bardip Perth', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('art-gallery-western-australia', 'perth', 'MUSEUM', 2, 'HOURS', 4.6, 'Художественная галерея Западной Австралии', 'Art Gallery of Western Australia', 'Батыс Австралия өнер галереясы', -31.94970000, 115.86010000, 'Art Gallery of Western Australia Perth', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('cottesloe-beach', 'perth', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Cottesloe', 'Cottesloe Beach', 'Cottesloe жағажайы', -31.99410000, 115.75190000, 'Cottesloe Beach Perth Australia', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('watertown-brand-outlet', 'perth', 'SHOPPING', 2, 'HOURS', 4.4, 'Watertown Brand Outlet Centre', 'Watertown Brand Outlet Centre', 'Watertown Brand Outlet Centre', -31.94910000, 115.84630000, 'Watertown Brand Outlet Centre Perth', ARRAY['perth']::text[], ARRAY['perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('fremantle-prison', 'fremantle', 'MUSEUM', 3, 'HOURS', 4.8, 'Тюрьма Фримантла', 'Fremantle Prison', 'Фримантл түрмесі', -32.05590000, 115.75390000, 'Fremantle Prison Australia', ARRAY['fremantle']::text[], ARRAY['fremantle', 'perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('fremantle-markets', 'fremantle', 'MARKET', 2, 'HOURS', 4.7, 'Рынки Фримантла', 'Fremantle Markets', 'Фримантл базарлары', -32.05670000, 115.74790000, 'Fremantle Markets Australia', ARRAY['fremantle']::text[], ARRAY['fremantle', 'perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('wa-maritime-museum', 'fremantle', 'MUSEUM', 2, 'HOURS', 4.6, 'Морской музей Западной Австралии', 'WA Maritime Museum', 'Батыс Австралия теңіз музейі', -32.05510000, 115.73970000, 'WA Maritime Museum Fremantle', ARRAY['fremantle']::text[], ARRAY['fremantle']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('bathers-beach', 'fremantle', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Bathers Beach', 'Bathers Beach', 'Bathers Beach', -32.05680000, 115.74250000, 'Bathers Beach Fremantle Australia', ARRAY['fremantle']::text[], ARRAY['fremantle']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('thomson-bay', 'rottnest-island', 'BEACH', 3, 'HOURS', 4.7, 'Thomson Bay', 'Thomson Bay Rottnest Island', 'Thomson Bay Rottnest Island', -31.99550000, 115.54050000, 'Thomson Bay Rottnest Island Australia', ARRAY['rottnest-island']::text[], ARRAY['rottnest-island', 'perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('pinky-beach', 'rottnest-island', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Pinky Beach', 'Pinky Beach', 'Pinky Beach', -31.99590000, 115.53750000, 'Pinky Beach Rottnest Island Australia', ARRAY['rottnest-island']::text[], ARRAY['rottnest-island', 'perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('little-salmon-bay', 'rottnest-island', 'NATURE', 3, 'HOURS', 4.7, 'Little Salmon Bay', 'Little Salmon Bay', 'Little Salmon Bay', -32.01860000, 115.51280000, 'Little Salmon Bay Rottnest Island Australia', ARRAY['rottnest-island']::text[], ARRAY['rottnest-island']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('lake-cave-margaret-river', 'margaret-river', 'NATURE', 2, 'HOURS', 4.7, 'Пещера Lake Cave', 'Lake Cave Margaret River', 'Lake Cave Margaret River', -34.04190000, 115.03180000, 'Lake Cave Margaret River Australia', ARRAY['margaret-river']::text[], ARRAY['margaret-river', 'perth']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('cape-leeuwin-lighthouse', 'margaret-river', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Маяк Cape Leeuwin', 'Cape Leeuwin Lighthouse', 'Cape Leeuwin маяғы', -34.37430000, 115.13500000, 'Cape Leeuwin Lighthouse Australia', ARRAY['margaret-river']::text[], ARRAY['margaret-river']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('surfers-point-margaret-river', 'margaret-river', 'NATURE', 2, 'HOURS', 4.6, 'Surfers Point', 'Surfers Point Margaret River', 'Surfers Point Margaret River', -33.97950000, 114.99480000, 'Surfers Point Margaret River Australia', ARRAY['margaret-river']::text[], ARRAY['margaret-river']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('margaret-river-farmers-market', 'margaret-river', 'MARKET', 2, 'HOURS', 4.6, 'Фермерский рынок Margaret River', 'Margaret River Farmers Market', 'Margaret River Farmers Market', -33.95190000, 115.07340000, 'Margaret River Farmers Market Australia', ARRAY['margaret-river']::text[], ARRAY['margaret-river']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('cable-beach', 'broome', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Cable Beach', 'Cable Beach', 'Cable Beach', -17.93440000, 122.20790000, 'Cable Beach Broome Australia', ARRAY['broome']::text[], ARRAY['broome']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('gantheaume-point', 'broome', 'NATURE', 2, 'HOURS', 4.7, 'Gantheaume Point', 'Gantheaume Point', 'Gantheaume Point', -17.97410000, 122.17690000, 'Gantheaume Point Broome Australia', ARRAY['broome']::text[], ARRAY['broome']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('broome-chinatown', 'broome', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Чайнатаун Брума', 'Chinatown Broome', 'Брум Чайнатаун', -17.95590000, 122.24240000, 'Chinatown Broome Australia', ARRAY['broome']::text[], ARRAY['broome']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg'),
    ('town-beach-staircase-markets', 'broome', 'MARKET', 2, 'HOURS', 4.6, 'Town Beach и рынки Staircase to the Moon', 'Town Beach and Staircase to the Moon Markets', 'Town Beach және Staircase to the Moon Markets', -17.96140000, 122.23650000, 'Town Beach Staircase to the Moon Markets Broome', ARRAY['broome']::text[], ARRAY['broome']::text[], 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg');

CREATE TEMP TABLE seed_australia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-australia-place:' || seed.slug) AS place_hash,
        md5('id-australia-media:' || seed.slug) AS media_hash
    FROM seed_australia_priority_places seed
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
    ARRAY['australia', city_id, slug, lower(category), 'australia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Австралии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Australia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Австралия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'AU',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'AUD',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_australia_resolved_places
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
FROM seed_australia_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_australia_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_australia_resolved_places
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
FROM seed_australia_resolved_places seed
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
FROM seed_australia_resolved_places
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
    'AU',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_australia_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'AU',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_australia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_australia_resolved_places;
DROP TABLE IF EXISTS seed_australia_priority_places;
