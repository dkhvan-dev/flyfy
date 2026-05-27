-- Priority Finland destination attractions seed.
-- Finland is seeded by durable tourist anchors across Helsinki region, coast, Lakeland, Lapland, and Oulu.

DROP TABLE IF EXISTS seed_finland_resolved_attractions;
DROP TABLE IF EXISTS seed_finland_priority_attractions;

CREATE TEMP TABLE seed_finland_priority_attractions (
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

INSERT INTO seed_finland_priority_attractions (
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
    ('suomenlinna-sea-fortress', 'helsinki', 'ARCHITECTURE', 4, 4.8, 'Морская крепость Суоменлинна', 'Suomenlinna Sea Fortress', 'Суоменлинна теңіз қамалы', 60.14590000, 24.98730000, 'Suomenlinna_Sea_Fortress.jpg', ARRAY['helsinki', 'unesco', 'sea-fortress']::text[]),
    ('helsinki-cathedral', 'helsinki', 'TEMPLE', 1, 4.7, 'Кафедральный собор Хельсинки', 'Helsinki Cathedral', 'Хельсинки кафедралды соборы', 60.17040000, 24.95220000, 'Helsinki_Cathedral_in_July_2004.jpg', ARRAY['helsinki', 'church', 'senate-square']::text[]),
    ('senate-square-helsinki', 'helsinki', 'ARCHITECTURE', 1, 4.6, 'Сенатская площадь', 'Senate Square Helsinki', 'Сенат алаңы', 60.16950000, 24.95230000, 'Senate_Square_Helsinki.jpg', ARRAY['helsinki', 'square', 'neoclassical']::text[]),
    ('temppeliaukio-church', 'helsinki', 'TEMPLE', 1, 4.7, 'Церковь Темппелиаукио', 'Temppeliaukio Church', 'Темппелиаукио шіркеуі', 60.17300000, 24.92520000, 'Temppeliaukio_Church.jpg', ARRAY['helsinki', 'rock-church', 'architecture']::text[]),
    ('uspenski-cathedral', 'helsinki', 'TEMPLE', 1, 4.6, 'Успенский собор', 'Uspenski Cathedral', 'Успен соборы', 60.16850000, 24.95990000, 'Uspenski_Cathedral_Helsinki.jpg', ARRAY['helsinki', 'orthodox', 'cathedral']::text[]),
    ('oodi-central-library', 'helsinki', 'ARCHITECTURE', 2, 4.8, 'Центральная библиотека Oodi', 'Oodi Central Library', 'Oodi орталық кітапханасы', 60.17410000, 24.93820000, 'Helsinki_Central_Library_Oodi.jpg', ARRAY['helsinki', 'library', 'modern-architecture']::text[]),
    ('ateneum-art-museum', 'helsinki', 'MUSEUM', 3, 4.7, 'Художественный музей Атенеум', 'Ateneum Art Museum', 'Атенеум өнер музейі', 60.17010000, 24.94410000, 'Ateneum_Art_Museum_Helsinki.jpg', ARRAY['helsinki', 'art', 'national-gallery']::text[]),
    ('kiasma', 'helsinki', 'MUSEUM', 2, 4.6, 'Музей современного искусства Kiasma', 'Kiasma Museum of Contemporary Art', 'Kiasma заманауи өнер музейі', 60.17130000, 24.93690000, 'Kiasma_Helsinki.jpg', ARRAY['helsinki', 'contemporary-art', 'museum']::text[]),
    ('amos-rex', 'helsinki', 'MUSEUM', 2, 4.6, 'Музей Amos Rex', 'Amos Rex', 'Amos Rex', 60.16990000, 24.93640000, 'Amos_Rex_Helsinki.jpg', ARRAY['helsinki', 'art', 'museum']::text[]),
    ('national-museum-finland', 'helsinki', 'MUSEUM', 2, 4.6, 'Национальный музей Финляндии', 'National Museum of Finland', 'Финляндия ұлттық музейі', 60.17500000, 24.93120000, 'National_Museum_of_Finland.jpg', ARRAY['helsinki', 'history', 'museum']::text[]),
    ('design-museum-helsinki', 'helsinki', 'MUSEUM', 2, 4.5, 'Музей дизайна Хельсинки', 'Design Museum Helsinki', 'Хельсинки дизайн музейі', 60.16300000, 24.94550000, 'Design_Museum_Helsinki.jpg', ARRAY['helsinki', 'design', 'museum']::text[]),
    ('market-square-helsinki', 'helsinki', 'MARKET', 1, 4.6, 'Рыночная площадь Хельсинки', 'Market Square Helsinki', 'Хельсинки базар алаңы', 60.16790000, 24.95520000, 'Helsinki_Market_Square.jpg', ARRAY['helsinki', 'harbour', 'market']::text[]),
    ('old-market-hall-helsinki', 'helsinki', 'MARKET', 1, 4.6, 'Старый крытый рынок Хельсинки', 'Old Market Hall Helsinki', 'Хельсинки ескі жабық базары', 60.16690000, 24.95390000, 'Old_Market_Hall_Helsinki.jpg', ARRAY['helsinki', 'food-hall', 'market']::text[]),
    ('hakaniemi-market-hall', 'helsinki', 'FOOD', 1, 4.5, 'Крытый рынок Хаканиеми', 'Hakaniemi Market Hall', 'Хаканиеми жабық базары', 60.17940000, 24.95080000, 'Hakaniemi_Market_Hall.jpg', ARRAY['helsinki', 'food-hall', 'local-food']::text[]),
    ('esplanadi-park', 'helsinki', 'PARK', 1, 4.6, 'Парк Эспланади', 'Esplanadi Park', 'Эспланади саябағы', 60.16770000, 24.94730000, 'Esplanadi_Park_Helsinki.jpg', ARRAY['helsinki', 'park', 'city-centre']::text[]),
    ('seurasaari-open-air-museum', 'helsinki', 'MUSEUM', 3, 4.6, 'Сеурасаари', 'Seurasaari Open-Air Museum', 'Сеурасаари ашық аспан музейі', 60.18330000, 24.88460000, 'Seurasaari_Open-Air_Museum.jpg', ARRAY['helsinki', 'island', 'open-air-museum']::text[]),
    ('linnanmaki', 'helsinki', 'ENTERTAINMENT', 4, 4.7, 'Линнанмяки', 'Linnanmaki', 'Линнанмяки', 60.18870000, 24.94000000, 'Linnanmaki_amusement_park.jpg', ARRAY['helsinki', 'amusement-park', 'family']::text[]),
    ('korkeasaari-zoo', 'helsinki', 'ENTERTAINMENT', 3, 4.6, 'Зоопарк Коркеасаари', 'Korkeasaari Zoo', 'Коркеасаари зообағы', 60.17560000, 24.98670000, 'Korkeasaari_Zoo.jpg', ARRAY['helsinki', 'zoo', 'island']::text[]),
    ('allas-sea-pool', 'helsinki', 'BEACH', 2, 4.5, 'Allas Sea Pool', 'Allas Sea Pool', 'Allas Sea Pool', 60.16810000, 24.95850000, 'Allas_Sea_Pool_Helsinki.jpg', ARRAY['helsinki', 'sea-pool', 'sauna']::text[]),
    ('loyly-helsinki', 'helsinki', 'FOOD', 2, 4.5, 'Loyly Helsinki', 'Loyly Helsinki', 'Loyly Helsinki', 60.15370000, 24.92170000, 'Loyly_Helsinki.jpg', ARRAY['helsinki', 'sauna', 'restaurant']::text[]),
    ('stockmann-helsinki', 'helsinki', 'SHOPPING', 2, 4.4, 'Stockmann Helsinki', 'Stockmann Helsinki', 'Stockmann Helsinki', 60.16880000, 24.94310000, 'Stockmann_Helsinki.jpg', ARRAY['helsinki', 'department-store', 'shopping']::text[]),
    ('kamppi-centre', 'helsinki', 'SHOPPING', 2, 4.4, 'Торговый центр Kamppi', 'Kamppi Center', 'Kamppi сауда орталығы', 60.16900000, 24.93300000, 'Kamppi_Center_Helsinki.jpg', ARRAY['helsinki', 'mall', 'shopping']::text[]),
    ('mall-of-tripla', 'helsinki', 'SHOPPING', 2, 4.4, 'Mall of Tripla', 'Mall of Tripla', 'Mall of Tripla', 60.19870000, 24.93060000, 'Mall_of_Tripla_Helsinki.jpg', ARRAY['helsinki', 'mall', 'shopping']::text[]),

    ('nuuksio-national-park', 'espoo', 'NATURE', 4, 4.8, 'Национальный парк Нууксио', 'Nuuksio National Park', 'Нууксио ұлттық паркі', 60.30700000, 24.49900000, 'Nuuksio_National_Park.jpg', ARRAY['espoo', 'national-park', 'hiking']::text[]),
    ('emma-espoo', 'espoo', 'MUSEUM', 2, 4.6, 'EMMA - музей современного искусства Эспоо', 'EMMA - Espoo Museum of Modern Art', 'EMMA Эспоо заманауи өнер музейі', 60.17790000, 24.79440000, 'EMMA_Espoo_Museum_of_Modern_Art.jpg', ARRAY['espoo', 'art', 'museum']::text[]),
    ('haltia-nature-centre', 'espoo', 'NATURE', 2, 4.6, 'Финский природный центр Haltia', 'Haltia Finnish Nature Centre', 'Haltia Финляндия табиғат орталығы', 60.29240000, 24.54800000, 'Haltia_Finnish_Nature_Centre.jpg', ARRAY['espoo', 'nature-centre', 'nuuksio']::text[]),
    ('iso-omena', 'espoo', 'SHOPPING', 2, 4.4, 'Торговый центр Iso Omena', 'Iso Omena Shopping Centre', 'Iso Omena сауда орталығы', 60.16170000, 24.73810000, 'Iso_Omena_Shopping_Centre.jpg', ARRAY['espoo', 'mall', 'shopping']::text[]),
    ('heureka', 'vantaa', 'ENTERTAINMENT', 3, 4.7, 'Научный центр Heureka', 'Heureka Finnish Science Centre', 'Heureka ғылым орталығы', 60.28970000, 25.04010000, 'Heureka_Finnish_Science_Centre.jpg', ARRAY['vantaa', 'science-centre', 'family']::text[]),
    ('finnish-aviation-museum', 'vantaa', 'MUSEUM', 2, 4.5, 'Финский авиационный музей', 'Finnish Aviation Museum', 'Финляндия авиация музейі', 60.30450000, 24.96000000, 'Finnish_Aviation_Museum.jpg', ARRAY['vantaa', 'aviation', 'museum']::text[]),
    ('fazer-experience', 'vantaa', 'FOOD', 2, 4.6, 'Центр Fazer Experience', 'Fazer Experience Visitor Centre', 'Fazer Experience келушілер орталығы', 60.26280000, 25.07850000, 'Fazer_Experience_Visitor_Centre.jpg', ARRAY['vantaa', 'chocolate', 'visitor-centre']::text[]),
    ('jumbo-flamingo', 'vantaa', 'SHOPPING', 2, 4.4, 'Jumbo-Flamingo', 'Jumbo-Flamingo Shopping and Entertainment Centre', 'Jumbo-Flamingo сауда және ойын-сауық орталығы', 60.29260000, 24.96500000, 'Jumbo_Shopping_Centre_Vantaa.jpg', ARRAY['vantaa', 'mall', 'entertainment']::text[]),
    ('kuusijarvi', 'vantaa', 'BEACH', 3, 4.6, 'Зона отдыха Куусиярви', 'Kuusijarvi Recreational Area', 'Куусиярви демалыс аймағы', 60.31970000, 25.11980000, 'Kuusijarvi_Vantaa.jpg', ARRAY['vantaa', 'lake', 'sauna']::text[]),

    ('turku-castle', 'turku', 'ARCHITECTURE', 3, 4.8, 'Замок Турку', 'Turku Castle', 'Турку қамалы', 60.43580000, 22.22830000, 'Turku_Castle.jpg', ARRAY['turku', 'castle', 'history']::text[]),
    ('turku-cathedral', 'turku', 'TEMPLE', 1, 4.7, 'Кафедральный собор Турку', 'Turku Cathedral', 'Турку кафедралды соборы', 60.45270000, 22.27860000, 'Turku_Cathedral.jpg', ARRAY['turku', 'cathedral', 'history']::text[]),
    ('aboa-vetus-ars-nova', 'turku', 'MUSEUM', 2, 4.6, 'Aboa Vetus Ars Nova', 'Aboa Vetus Ars Nova', 'Aboa Vetus Ars Nova', 60.45060000, 22.27210000, 'Aboa_Vetus_Ars_Nova.jpg', ARRAY['turku', 'archaeology', 'art']::text[]),
    ('forum-marinum', 'turku', 'MUSEUM', 2, 4.6, 'Forum Marinum', 'Forum Marinum', 'Forum Marinum', 60.43680000, 22.23320000, 'Forum_Marinum_Turku.jpg', ARRAY['turku', 'maritime', 'museum']::text[]),
    ('turku-market-hall', 'turku', 'MARKET', 1, 4.5, 'Крытый рынок Турку', 'Turku Market Hall', 'Турку жабық базары', 60.44900000, 22.26420000, 'Turku_Market_Hall.jpg', ARRAY['turku', 'food-hall', 'market']::text[]),
    ('aura-riverfront', 'turku', 'PARK', 2, 4.6, 'Набережная реки Аура', 'River Aura Riverside', 'Аура өзені жағалауы', 60.44800000, 22.26350000, 'River_Aura_Turku.jpg', ARRAY['turku', 'riverfront', 'walk']::text[]),
    ('ruissalo-island', 'turku', 'NATURE', 4, 4.7, 'Остров Руиссало', 'Ruissalo Island', 'Руиссало аралы', 60.42700000, 22.10800000, 'Ruissalo_Turku.jpg', ARRAY['turku', 'island', 'nature']::text[]),
    ('naantali-old-town', 'naantali', 'ARCHITECTURE', 2, 4.7, 'Старый город Наантали', 'Naantali Old Town', 'Наантали ескі қаласы', 60.46790000, 22.02530000, 'Naantali_Old_Town.jpg', ARRAY['naantali', 'old-town', 'wooden-town']::text[]),
    ('moominworld', 'naantali', 'ENTERTAINMENT', 5, 4.7, 'Муми-мир', 'Moominworld', 'Муми әлемі', 60.46750000, 22.00480000, 'Moominworld_Naantali.jpg', ARRAY['naantali', 'theme-park', 'family']::text[]),
    ('kultaranta-garden', 'naantali', 'PARK', 2, 4.5, 'Сад Култаранта', 'Kultaranta Garden', 'Култаранта бағы', 60.46860000, 21.99270000, 'Kultaranta_Naantali.jpg', ARRAY['naantali', 'garden', 'presidential-residence']::text[]),
    ('vapriikki', 'tampere', 'MUSEUM', 3, 4.8, 'Музейный центр Vapriikki', 'Vapriikki Museum Centre', 'Vapriikki музей орталығы', 61.50380000, 23.76060000, 'Vapriikki_Museum_Centre.jpg', ARRAY['tampere', 'museum-centre', 'history']::text[]),
    ('sarkanniemi', 'tampere', 'ENTERTAINMENT', 5, 4.7, 'Сяркянниеми', 'Sarkanniemi', 'Сяркянниеми', 61.50530000, 23.74460000, 'Sarkanniemi_Tampere.jpg', ARRAY['tampere', 'amusement-park', 'family']::text[]),
    ('pyynikki-observation-tower', 'tampere', 'ARCHITECTURE', 1, 4.7, 'Смотровая башня Пююникки', 'Pyynikki Observation Tower', 'Пююникки бақылау мұнарасы', 61.49880000, 23.73010000, 'Pyynikki_Observation_Tower.jpg', ARRAY['tampere', 'viewpoint', 'cafe']::text[]),
    ('moomin-museum', 'tampere', 'MUSEUM', 2, 4.6, 'Музей Муми-троллей', 'Moomin Museum', 'Муми музейі', 61.49350000, 23.77910000, 'Moomin_Museum_Tampere.jpg', ARRAY['tampere', 'museum', 'family']::text[]),
    ('tampere-market-hall', 'tampere', 'MARKET', 1, 4.6, 'Крытый рынок Тампере', 'Tampere Market Hall', 'Тампере жабық базары', 61.49710000, 23.75860000, 'Tampere_Market_Hall.jpg', ARRAY['tampere', 'food-hall', 'market']::text[]),
    ('ratina-shopping-centre', 'tampere', 'SHOPPING', 2, 4.4, 'Торговый центр Ratina', 'Ratina Shopping Centre', 'Ratina сауда орталығы', 61.49320000, 23.76800000, 'Ratina_Shopping_Centre.jpg', ARRAY['tampere', 'mall', 'shopping']::text[]),
    ('porvoo-old-town', 'porvoo', 'ARCHITECTURE', 3, 4.8, 'Старый Порвоо', 'Porvoo Old Town', 'Порвоо ескі қаласы', 60.39770000, 25.65700000, 'Old_Porvoo.jpg', ARRAY['porvoo', 'old-town', 'wooden-town']::text[]),
    ('porvoo-cathedral', 'porvoo', 'TEMPLE', 1, 4.6, 'Кафедральный собор Порвоо', 'Porvoo Cathedral', 'Порвоо кафедралды соборы', 60.39670000, 25.65750000, 'Porvoo_Cathedral.jpg', ARRAY['porvoo', 'cathedral', 'old-town']::text[]),
    ('runeberg-home', 'porvoo', 'MUSEUM', 1, 4.5, 'Дом-музей Рунеберга', 'J. L. Runeberg Home Museum', 'Рунеберг үй-музейі', 60.39250000, 25.66530000, 'Runeberg_Home_Porvoo.jpg', ARRAY['porvoo', 'writer', 'museum']::text[]),
    ('brunberg-shop', 'porvoo', 'FOOD', 1, 4.5, 'Магазин Brunberg', 'Brunberg Chocolate Shop', 'Brunberg шоколад дүкені', 60.39450000, 25.66230000, 'Brunberg_Porvoo.jpg', ARRAY['porvoo', 'chocolate', 'shop']::text[]),

    ('olavinlinna-castle', 'savonlinna', 'ARCHITECTURE', 3, 4.8, 'Замок Олавинлинна', 'Olavinlinna Castle', 'Олавинлинна қамалы', 61.86470000, 28.90190000, 'Olavinlinna_Castle.jpg', ARRAY['savonlinna', 'castle', 'saimaa']::text[]),
    ('riihisaari-museum', 'savonlinna', 'MUSEUM', 2, 4.6, 'Riihisaari', 'Riihisaari Museum', 'Riihisaari музейі', 61.86440000, 28.89930000, 'Riihisaari_Savonlinna.jpg', ARRAY['savonlinna', 'museum', 'lake-saimaa']::text[]),
    ('savonlinna-market-square', 'savonlinna', 'MARKET', 1, 4.5, 'Рыночная площадь Савонлинны', 'Savonlinna Market Square', 'Савонлинна базар алаңы', 61.86790000, 28.88490000, 'Savonlinna_Market_Square.jpg', ARRAY['savonlinna', 'market', 'lake']::text[]),
    ('punkaharju-ridge', 'savonlinna', 'NATURE', 3, 4.8, 'Гряда Пункахарью', 'Punkaharju Ridge', 'Пункахарью жотасы', 61.80540000, 29.32200000, 'Punkaharju_Ridge.jpg', ARRAY['savonlinna', 'national-landscape', 'nature']::text[]),
    ('lusto-forest-museum', 'savonlinna', 'MUSEUM', 2, 4.5, 'Лесной музей Lusto', 'Lusto Finnish Forest Museum', 'Lusto орман музейі', 61.80040000, 29.31660000, 'Lusto_Finnish_Forest_Museum.jpg', ARRAY['savonlinna', 'forest', 'museum']::text[]),
    ('puijo-tower', 'kuopio', 'ARCHITECTURE', 2, 4.7, 'Башня Пуйо', 'Puijo Tower', 'Пуйо мұнарасы', 62.90970000, 27.65680000, 'Puijo_Tower.jpg', ARRAY['kuopio', 'viewpoint', 'lakeland']::text[]),
    ('kuopio-market-hall', 'kuopio', 'MARKET', 1, 4.6, 'Крытый рынок Куопио', 'Kuopio Market Hall', 'Куопио жабық базары', 62.89230000, 27.67810000, 'Kuopio_Market_Hall.jpg', ARRAY['kuopio', 'market', 'local-food']::text[]),
    ('riisa-orthodox-museum', 'kuopio', 'MUSEUM', 2, 4.5, 'RIISA - православный музей Финляндии', 'RIISA Orthodox Church Museum of Finland', 'RIISA православие музейі', 62.89430000, 27.68110000, 'RIISA_Museum_Kuopio.jpg', ARRAY['kuopio', 'orthodox', 'museum']::text[]),
    ('vainolanniemi', 'kuopio', 'BEACH', 2, 4.5, 'Парк и пляж Вяйнёлянниеми', 'Vainolanniemi Park and Beach', 'Вяйнёлянниеми саябағы мен жағажайы', 62.88380000, 27.68470000, 'Vainolanniemi_Kuopio.jpg', ARRAY['kuopio', 'beach', 'lake']::text[]),
    ('aalto2-museum-centre', 'jyvaskyla', 'MUSEUM', 2, 4.6, 'Музейный центр Aalto2', 'Aalto2 Museum Centre', 'Aalto2 музей орталығы', 62.23700000, 25.73380000, 'Alvar_Aalto_Museum_Jyvaskyla.jpg', ARRAY['jyvaskyla', 'architecture', 'design']::text[]),
    ('toivola-old-courtyard', 'jyvaskyla', 'SHOPPING', 2, 4.5, 'Старый двор Toivola', 'Toivola Old Courtyard', 'Toivola ескі ауласы', 62.23860000, 25.74460000, 'Toivola_Old_Courtyard.jpg', ARRAY['jyvaskyla', 'crafts', 'shopping']::text[]),
    ('harju-observation-tower', 'jyvaskyla', 'PARK', 1, 4.5, 'Башня Харью', 'Harju Observation Tower', 'Харью бақылау мұнарасы', 62.24330000, 25.74570000, 'Harju_Jyvaskyla.jpg', ARRAY['jyvaskyla', 'viewpoint', 'park']::text[]),
    ('lappeenranta-fortress', 'lappeenranta', 'ARCHITECTURE', 2, 4.7, 'Крепость Лаппеэнранта', 'Lappeenranta Fortress', 'Лаппеэнранта қамалы', 61.05820000, 28.18180000, 'Lappeenranta_Fortress.jpg', ARRAY['lappeenranta', 'fortress', 'old-town']::text[]),
    ('south-karelia-museum', 'lappeenranta', 'MUSEUM', 2, 4.5, 'Музей Южной Карелии', 'South Karelia Museum', 'Оңтүстік Карелия музейі', 61.05770000, 28.18090000, 'South_Karelia_Museum.jpg', ARRAY['lappeenranta', 'museum', 'karelia']::text[]),
    ('lappeenranta-harbour', 'lappeenranta', 'MARKET', 2, 4.5, 'Гавань Лаппеэнранты', 'Lappeenranta Harbour and Market Square', 'Лаппеэнранта айлағы мен базар алаңы', 61.05890000, 28.18790000, 'Lappeenranta_Harbour.jpg', ARRAY['lappeenranta', 'harbour', 'saimaa']::text[]),
    ('lappeenranta-sandcastle', 'lappeenranta', 'ENTERTAINMENT', 2, 4.5, 'Песочный замок Лаппеэнранты', 'Lappeenranta Sandcastle', 'Лаппеэнранта құм қамалы', 61.05900000, 28.18860000, 'Lappeenranta_Sandcastle.jpg', ARRAY['lappeenranta', 'family', 'summer']::text[]),
    ('sibelius-hall', 'lahti', 'ARCHITECTURE', 2, 4.6, 'Sibelius Hall', 'Sibelius Hall', 'Sibelius Hall', 60.99470000, 25.65530000, 'Sibelius_Hall_Lahti.jpg', ARRAY['lahti', 'concert-hall', 'wood-architecture']::text[]),
    ('lahti-ski-museum', 'lahti', 'MUSEUM', 2, 4.5, 'Лыжный музей Лахти', 'Lahti Ski Museum', 'Лахти шаңғы музейі', 60.98250000, 25.62690000, 'Lahti_Ski_Museum.jpg', ARRAY['lahti', 'ski', 'museum']::text[]),
    ('lahti-market-hall', 'lahti', 'MARKET', 1, 4.4, 'Крытый рынок Лахти', 'Lahti Market Hall', 'Лахти жабық базары', 60.98220000, 25.66100000, 'Lahti_Market_Hall.jpg', ARRAY['lahti', 'food-hall', 'market']::text[]),
    ('lahti-harbour', 'lahti', 'PARK', 2, 4.5, 'Гавань Лахти', 'Lahti Harbour', 'Лахти айлағы', 60.99600000, 25.65380000, 'Lahti_Harbour.jpg', ARRAY['lahti', 'lake', 'walk']::text[]),

    ('santa-claus-village', 'rovaniemi', 'ENTERTAINMENT', 4, 4.8, 'Деревня Санта-Клауса', 'Santa Claus Village', 'Санта-Клаус ауылы', 66.54310000, 25.84720000, 'Santa_Claus_Village_Rovaniemi.jpg', ARRAY['rovaniemi', 'arctic-circle', 'family']::text[]),
    ('santapark', 'rovaniemi', 'ENTERTAINMENT', 3, 4.5, 'SantaPark', 'SantaPark', 'SantaPark', 66.54270000, 25.79880000, 'SantaPark_Rovaniemi.jpg', ARRAY['rovaniemi', 'christmas', 'theme-park']::text[]),
    ('arktikum', 'rovaniemi', 'MUSEUM', 3, 4.7, 'Арктикум', 'Arktikum', 'Arktikum', 66.50710000, 25.72940000, 'Arktikum_Rovaniemi.jpg', ARRAY['rovaniemi', 'arctic', 'museum']::text[]),
    ('korundi-house-of-culture', 'rovaniemi', 'MUSEUM', 2, 4.5, 'Дом культуры Korundi', 'Korundi House of Culture', 'Korundi мәдениет үйі', 66.50050000, 25.71640000, 'Korundi_House_of_Culture.jpg', ARRAY['rovaniemi', 'art', 'culture']::text[]),
    ('science-centre-pilke', 'rovaniemi', 'MUSEUM', 2, 4.5, 'Научный центр Pilke', 'Science Centre Pilke', 'Pilke ғылым орталығы', 66.50700000, 25.72740000, 'Science_Centre_Pilke.jpg', ARRAY['rovaniemi', 'forest', 'science']::text[]),
    ('ounasvaara', 'rovaniemi', 'NATURE', 3, 4.6, 'Оунасваара', 'Ounasvaara', 'Оунасваара', 66.50010000, 25.77880000, 'Ounasvaara_Rovaniemi.jpg', ARRAY['rovaniemi', 'ski', 'nature']::text[]),
    ('levi-ski-resort', 'levi', 'ENTERTAINMENT', 5, 4.7, 'Горнолыжный курорт Леви', 'Levi Ski Resort', 'Леви тау шаңғы курорты', 67.80550000, 24.80260000, 'Levi_Ski_Resort.jpg', ARRAY['levi', 'ski-resort', 'winter']::text[]),
    ('snowvillage-levi', 'levi', 'ENTERTAINMENT', 2, 4.6, 'SnowVillage Levi', 'Lapland Hotels SnowVillage', 'Lapland Hotels SnowVillage', 67.75060000, 24.67990000, 'SnowVillage_Finland.jpg', ARRAY['levi', 'snow-hotel', 'winter']::text[]),
    ('samiland', 'levi', 'MUSEUM', 2, 4.5, 'Samiland', 'Samiland', 'Samiland', 67.80560000, 24.80830000, 'Samiland_Levi.jpg', ARRAY['levi', 'sami-culture', 'museum']::text[]),
    ('kaunispaa-fell', 'saariselka', 'NATURE', 2, 4.7, 'Сопка Каунуиспяа', 'Kaunispaa Fell', 'Каунуиспяа шоқысы', 68.42170000, 27.43090000, 'Kaunispaa_Fell.jpg', ARRAY['saariselka', 'fell', 'viewpoint']::text[]),
    ('urho-kekkonen-national-park', 'saariselka', 'PARK', 5, 4.8, 'Национальный парк Урхо Кекконена', 'Urho Kekkonen National Park', 'Урхо Кекконен ұлттық паркі', 68.25000000, 28.00000000, 'Urho_Kekkonen_National_Park.jpg', ARRAY['saariselka', 'national-park', 'hiking']::text[]),
    ('siida-sami-museum', 'inari', 'MUSEUM', 3, 4.8, 'Музей саамов Siida', 'Siida Sami Museum', 'Siida саами музейі', 68.90780000, 27.02160000, 'Siida_Sami_Museum.jpg', ARRAY['inari', 'sami-culture', 'museum']::text[]),
    ('lake-inari', 'inari', 'NATURE', 4, 4.8, 'Озеро Инари', 'Lake Inari', 'Инари көлі', 68.95000000, 27.70000000, 'Lake_Inari.jpg', ARRAY['inari', 'lake', 'arctic']::text[]),
    ('saana-fell', 'kilpisjarvi', 'NATURE', 4, 4.8, 'Сопка Саана', 'Saana Fell', 'Саана шоқысы', 69.04260000, 20.84960000, 'Saana_Fell.jpg', ARRAY['kilpisjarvi', 'fell', 'hiking']::text[]),
    ('three-country-cairn', 'kilpisjarvi', 'NATURE', 3, 4.6, 'Пограничный знак трех стран', 'Three-Country Cairn', 'Үш ел шекара белгісі', 69.05990000, 20.54860000, 'Three-Country_Cairn.jpg', ARRAY['kilpisjarvi', 'border-point', 'nature']::text[]),
    ('oulu-market-hall', 'oulu', 'MARKET', 1, 4.6, 'Крытый рынок Оулу', 'Oulu Market Hall', 'Оулу жабық базары', 65.01420000, 25.46460000, 'Oulu_Market_Hall.jpg', ARRAY['oulu', 'market', 'local-food']::text[]),
    ('oulu-market-square', 'oulu', 'MARKET', 1, 4.5, 'Рыночная площадь Оулу', 'Oulu Market Square and Toripolliisi', 'Оулу базар алаңы', 65.01410000, 25.46550000, 'Oulu_Market_Square.jpg', ARRAY['oulu', 'market-square', 'landmark']::text[]),
    ('nallikari-beach', 'oulu', 'BEACH', 3, 4.7, 'Пляж Налликари', 'Nallikari Beach', 'Налликари жағажайы', 65.02560000, 25.41170000, 'Nallikari_Beach.jpg', ARRAY['oulu', 'beach', 'gulf-of-bothnia']::text[]),
    ('hupisaaret-park', 'oulu', 'PARK', 2, 4.6, 'Парк островов Hupisaaret', 'Hupisaaret Islands Park', 'Hupisaaret аралдары саябағы', 65.01980000, 25.48350000, 'Hupisaaret_Islands_Park.jpg', ARRAY['oulu', 'park', 'city-nature']::text[]),
    ('tietomaa', 'oulu', 'MUSEUM', 2, 4.5, 'Научный центр Tietomaa', 'Tietomaa Science Centre', 'Tietomaa ғылым орталығы', 65.01490000, 25.48010000, 'Tietomaa_Science_Centre.jpg', ARRAY['oulu', 'science-centre', 'family']::text[]);

CREATE TEMP TABLE seed_finland_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-finland-attraction:' || seed.slug) AS attraction_hash,
        md5('id-finland-media:' || seed.slug) AS media_hash
    FROM seed_finland_priority_attractions seed
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
    ARRAY['finland', city_id, slug, lower(category), 'finland-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Финляндии: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'Finland tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'Финляндия туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' Finland', ' ', '%20') AS location_source_url,
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
    'FI',
    city_id,
    category,
    NULL::numeric,
    'EUR',
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
FROM seed_finland_resolved_attractions
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
FROM seed_finland_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_finland_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_finland_resolved_attractions
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
FROM seed_finland_resolved_attractions seed
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
FROM seed_finland_resolved_attractions
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
    'FI',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_finland_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'FI',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_finland_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
