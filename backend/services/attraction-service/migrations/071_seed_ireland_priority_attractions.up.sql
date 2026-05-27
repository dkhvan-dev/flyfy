-- Priority Ireland destination attractions seed.
-- The seed covers Dublin and the east coast, Galway and the Wild Atlantic Way, Cork and Kerry, Waterford, Kilkenny, Limerick, Sligo, Donegal and Wexford.

DROP TABLE IF EXISTS seed_ireland_resolved_attractions;
DROP TABLE IF EXISTS seed_ireland_priority_attractions;

CREATE TEMP TABLE seed_ireland_priority_attractions (
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

INSERT INTO seed_ireland_priority_attractions (
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
    ('guinness-storehouse', 'dublin', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Guinness Storehouse', 'Guinness Storehouse', 'Guinness Storehouse музейі', 53.34190000, -6.28670000, 'Guinness Storehouse Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Guinness_Storehouse_Dublin.jpg', ARRAY['indoor', 'beer']::text[]),
    ('book-of-kells-trinity-college', 'dublin', 'MUSEUM', 2, 'HOURS', 4.8, 'Книга Келлс и Тринити-колледж', 'Book of Kells Experience, Trinity College Dublin', 'Келлс кітабы және Тринити колледжі', 53.34380000, -6.25460000, 'Book of Kells Trinity College Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Trinity_College_Dublin_Long_Room.jpg', ARRAY['indoor', 'library']::text[]),
    ('dublin-castle', 'dublin', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дублинский замок', 'Dublin Castle', 'Дублин қамалы', 53.34290000, -6.26750000, 'Dublin Castle Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Dublin_Castle_Ireland.jpg', ARRAY['history']::text[]),
    ('kilmainham-gaol-museum', 'dublin', 'MUSEUM', 2, 'HOURS', 4.8, 'Тюрьма-музей Килмэнхэм', 'Kilmainham Gaol Museum', 'Килмэнхэм түрме музейі', 53.34190000, -6.30930000, 'Kilmainham Gaol Museum Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Kilmainham_Gaol_Dublin.jpg', ARRAY['indoor', 'history']::text[]),
    ('epic-irish-emigration-museum', 'dublin', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей ирландской эмиграции EPIC', 'EPIC The Irish Emigration Museum', 'EPIC ирланд эмиграция музейі', 53.34830000, -6.24830000, 'EPIC The Irish Emigration Museum Dublin', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'EPIC_The_Irish_Emigration_Museum.jpg', ARRAY['indoor', 'interactive']::text[]),
    ('national-museum-ireland-archaeology', 'dublin', 'MUSEUM', 2, 'HOURS', 4.8, 'Национальный музей Ирландии: археология', 'National Museum of Ireland - Archaeology', 'Ирландия ұлттық музейі: археология', 53.34030000, -6.25540000, 'National Museum of Ireland Archaeology Dublin', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'National_Museum_of_Ireland_Archaeology.jpg', ARRAY['indoor', 'history']::text[]),
    ('christ-church-cathedral-dublin', 'dublin', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Крайст-Черч', 'Christ Church Cathedral Dublin', 'Дублин Крайст-Черч соборы', 53.34350000, -6.27110000, 'Christ Church Cathedral Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Christ_Church_Cathedral_Dublin.jpg', ARRAY['cathedral']::text[]),
    ('st-patricks-cathedral-dublin', 'dublin', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святого Патрика', 'St Patricks Cathedral Dublin', 'Әулие Патрик соборы Дублин', 53.33950000, -6.27150000, 'St Patricks Cathedral Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'St_Patricks_Cathedral_Dublin.jpg', ARRAY['cathedral']::text[]),
    ('phoenix-park', 'dublin', 'PARK', 2, 'HOURS', 4.8, 'Феникс-парк', 'Phoenix Park', 'Феникс паркі', 53.35680000, -6.32920000, 'Phoenix Park Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Phoenix_Park_Dublin.jpg', ARRAY['family', 'green-space']::text[]),
    ('dublin-zoo', 'dublin', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Дублинский зоопарк', 'Dublin Zoo', 'Дублин хайуанаттар бағы', 53.35590000, -6.30530000, 'Dublin Zoo Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Dublin_Zoo.jpg', ARRAY['family']::text[]),
    ('grafton-street', 'dublin', 'SHOPPING', 1, 'HOURS', 4.6, 'Графтон-стрит', 'Grafton Street', 'Графтон көшесі', 53.34200000, -6.26030000, 'Grafton Street Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Grafton_Street_Dublin.jpg', ARRAY['shopping-street']::text[]),
    ('georges-street-arcade', 'dublin', 'MARKET', 1, 'HOURS', 4.6, 'Аркада Джордж-стрит', 'Georges Street Arcade', 'Джордж-стрит аркадасы', 53.34200000, -6.26360000, 'Georges Street Arcade Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Georges_Street_Arcade_Dublin.jpg', ARRAY['indoor', 'local-market']::text[]),
    ('temple-bar-food-market', 'dublin', 'MARKET', 1, 'HOURS', 4.5, 'Продовольственный рынок Темпл-Бар', 'Temple Bar Food Market', 'Темпл-Бар азық-түлік базары', 53.34520000, -6.26430000, 'Temple Bar Food Market Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Temple_Bar_Dublin.jpg', ARRAY['local-market', 'weekend']::text[]),
    ('temple-bar-district', 'dublin', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Район Темпл-Бар', 'Temple Bar District', 'Темпл-Бар ауданы', 53.34540000, -6.26450000, 'Temple Bar District Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Temple_Bar_District_Dublin.jpg', ARRAY['nightlife', 'evening']::text[]),
    ('dundrum-town-centre', 'dublin', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговый центр Dundrum Town Centre', 'Dundrum Town Centre', 'Dundrum Town Centre сауда орталығы', 53.28600000, -6.24250000, 'Dundrum Town Centre Dublin Ireland', ARRAY['dublin']::text[], ARRAY['dublin']::text[], 'Dundrum_Town_Centre_Dublin.jpg', ARRAY['mall', 'indoor']::text[]),
    ('howth-cliff-path-loop', 'howth', 'NATURE', 3, 'HOURS', 4.8, 'Тропа по утесам Хоута', 'Howth Cliff Path Loop', 'Хоут жартастары соқпағы', 53.37140000, -6.05650000, 'Howth Cliff Path Loop Ireland', ARRAY['howth', 'dublin']::text[], ARRAY['dublin', 'howth']::text[], 'Howth_Cliff_Path_Ireland.jpg', ARRAY['coast', 'hiking']::text[]),
    ('howth-market', 'howth', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Хоута', 'Howth Market', 'Хоут базары', 53.38800000, -6.07460000, 'Howth Market Dublin Ireland', ARRAY['howth', 'dublin']::text[], ARRAY['dublin', 'howth']::text[], 'Howth_Market_Dublin.jpg', ARRAY['local-market']::text[]),
    ('dun-laoghaire-east-pier', 'dun-laoghaire', 'NATURE', 1, 'HOURS', 4.7, 'Восточный пирс Дан-Лэаре', 'Dun Laoghaire East Pier', 'Дан-Лэаре шығыс пирсі', 53.29550000, -6.12810000, 'Dun Laoghaire East Pier Ireland', ARRAY['dun-laoghaire', 'dublin']::text[], ARRAY['dublin', 'dun-laoghaire']::text[], 'Dun_Laoghaire_East_Pier.jpg', ARRAY['coast', 'walk']::text[]),
    ('forty-foot', 'dun-laoghaire', 'BEACH', 1, 'HOURS', 4.7, 'Купальня Форти-Фут', 'Forty Foot', 'Форти-Фут шомылу орны', 53.28740000, -6.11300000, 'Forty Foot Dun Laoghaire Ireland', ARRAY['dun-laoghaire', 'dublin']::text[], ARRAY['dublin', 'dun-laoghaire']::text[], 'Forty_Foot_Dublin.jpg', ARRAY['sea-swim']::text[]),
    ('bray-seafront-and-beach', 'bray', 'BEACH', 2, 'HOURS', 4.7, 'Набережная и пляж Брея', 'Bray Seafront and Beach', 'Брей жағалауы және жағажайы', 53.20290000, -6.09810000, 'Bray Seafront and Beach Ireland', ARRAY['bray', 'dublin']::text[], ARRAY['dublin', 'bray']::text[], 'Bray_Seafront_Ireland.jpg', ARRAY['coast', 'family']::text[]),
    ('bray-head', 'bray', 'NATURE', 2, 'HOURS', 4.7, 'Брей-Хед', 'Bray Head', 'Брей-Хед', 53.18930000, -6.08390000, 'Bray Head Ireland', ARRAY['bray', 'dublin']::text[], ARRAY['dublin', 'bray']::text[], 'Bray_Head_Ireland.jpg', ARRAY['hiking', 'viewpoint']::text[]),
    ('glendalough-monastic-site', 'glendalough', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Монастырский комплекс Глендалох', 'Glendalough Monastic Site', 'Глендалох монастырь кешені', 53.01000000, -6.32750000, 'Glendalough Monastic Site Ireland', ARRAY['glendalough']::text[], ARRAY['dublin', 'glendalough']::text[], 'Glendalough_Ireland.jpg', ARRAY['history', 'monastic']::text[]),
    ('wicklow-mountains-national-park', 'glendalough', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Уиклоу-Маунтинс', 'Wicklow Mountains National Park', 'Уиклоу таулары ұлттық паркі', 53.00640000, -6.34690000, 'Wicklow Mountains National Park Ireland', ARRAY['glendalough', 'bray']::text[], ARRAY['dublin', 'glendalough', 'bray']::text[], 'Wicklow_Mountains_National_Park.jpg', ARRAY['hiking', 'nature']::text[]),

    ('galway-city-museum', 'galway', 'MUSEUM', 1, 'HOURS', 4.6, 'Городской музей Голуэя', 'Galway City Museum', 'Голуэй қалалық музейі', 53.26930000, -9.05330000, 'Galway City Museum Ireland', ARRAY['galway']::text[], ARRAY['galway']::text[], 'Galway_City_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('galway-latin-quarter', 'galway', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Латинский квартал Голуэя', 'Galway Latin Quarter', 'Голуэй Латын кварталы', 53.27170000, -9.05400000, 'Galway Latin Quarter Ireland', ARRAY['galway']::text[], ARRAY['galway']::text[], 'Galway_Latin_Quarter.jpg', ARRAY['evening', 'walk']::text[]),
    ('galway-market-at-st-nicholas', 'galway', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Голуэя у Святого Николая', 'Galway Market at St Nicholas', 'Әулие Николай жанындағы Голуэй базары', 53.27210000, -9.05320000, 'Galway Market at St Nicholas Ireland', ARRAY['galway']::text[], ARRAY['galway']::text[], 'Galway_Market_Ireland.jpg', ARRAY['local-market', 'weekend']::text[]),
    ('salthill-promenade', 'galway', 'PARK', 1, 'HOURS', 4.6, 'Набережная Солтхилл', 'Salthill Promenade', 'Солтхилл жағалауы', 53.25950000, -9.07900000, 'Salthill Promenade Galway Ireland', ARRAY['galway']::text[], ARRAY['galway']::text[], 'Salthill_Promenade_Galway.jpg', ARRAY['coast', 'walk']::text[]),
    ('galway-atlantaquaria', 'galway', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Океанариум Голуэя', 'Galway Atlantaquaria', 'Голуэй океанариумы', 53.26030000, -9.07470000, 'Galway Atlantaquaria Ireland', ARRAY['galway']::text[], ARRAY['galway']::text[], 'Galway_Atlantaquaria.jpg', ARRAY['family', 'indoor']::text[]),
    ('connemara-national-park', 'connemara', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Коннемара', 'Connemara National Park', 'Коннемара ұлттық паркі', 53.54890000, -9.94830000, 'Connemara National Park Ireland', ARRAY['connemara', 'galway']::text[], ARRAY['galway', 'connemara']::text[], 'Connemara_National_Park.jpg', ARRAY['hiking', 'wild-atlantic-way']::text[]),
    ('kylemore-abbey', 'connemara', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Аббатство Кайлмор и викторианский сад', 'Kylemore Abbey and Victorian Walled Garden', 'Кайлмор аббаттығы және викториан бағы', 53.56160000, -9.88960000, 'Kylemore Abbey Ireland', ARRAY['connemara', 'galway']::text[], ARRAY['galway', 'connemara']::text[], 'Kylemore_Abbey_Ireland.jpg', ARRAY['garden', 'history']::text[]),
    ('dogs-bay-beach', 'connemara', 'BEACH', 2, 'HOURS', 4.8, 'Пляж Догс-Бэй', 'Dogs Bay Beach', 'Догс-Бэй жағажайы', 53.37880000, -9.96500000, 'Dogs Bay Beach Galway Ireland', ARRAY['connemara']::text[], ARRAY['galway', 'connemara']::text[], 'Dogs_Bay_Beach_Ireland.jpg', ARRAY['coast']::text[]),
    ('killary-fjord', 'connemara', 'NATURE', 2, 'HOURS', 4.7, 'Фьорд Киллари', 'Killary Fjord', 'Киллари фьорды', 53.59600000, -9.68500000, 'Killary Fjord Ireland', ARRAY['connemara']::text[], ARRAY['galway', 'connemara']::text[], 'Killary_Harbour_Ireland.jpg', ARRAY['fjord', 'boat']::text[]),
    ('cliffs-of-moher', 'cliffs-of-moher', 'NATURE', 2, 'HOURS', 4.9, 'Утесы Мохер', 'Cliffs of Moher', 'Мохер жартастары', 52.97150000, -9.43090000, 'Cliffs of Moher Ireland', ARRAY['cliffs-of-moher', 'galway']::text[], ARRAY['galway', 'cliffs-of-moher']::text[], 'Cliffs_of_Moher_Ireland.jpg', ARRAY['wild-atlantic-way', 'viewpoint']::text[]),
    ('burren-national-park', 'burren', 'PARK', 3, 'HOURS', 4.7, 'Национальный парк Буррен', 'Burren National Park', 'Буррен ұлттық паркі', 53.03400000, -9.03700000, 'Burren National Park Ireland', ARRAY['burren', 'galway']::text[], ARRAY['galway', 'burren']::text[], 'Burren_National_Park.jpg', ARRAY['karst', 'hiking']::text[]),
    ('poulnabrone-dolmen', 'burren', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Дольмен Пулнаброн', 'Poulnabrone Dolmen', 'Пулнаброн дольмені', 53.04870000, -9.14090000, 'Poulnabrone Dolmen Ireland', ARRAY['burren']::text[], ARRAY['galway', 'burren']::text[], 'Poulnabrone_Dolmen_Ireland.jpg', ARRAY['megalith', 'history']::text[]),
    ('aillwee-cave', 'burren', 'NATURE', 2, 'HOURS', 4.5, 'Пещера Эйлуи', 'Aillwee Cave', 'Эйлуи үңгірі', 53.09180000, -9.15030000, 'Aillwee Cave Ireland', ARRAY['burren']::text[], ARRAY['galway', 'burren']::text[], 'Aillwee_Cave_Ireland.jpg', ARRAY['cave', 'family']::text[]),
    ('dun-aonghasa', 'aran-islands', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Дун Энгус', 'Dun Aonghasa', 'Дун Энгус', 53.12560000, -9.76740000, 'Dun Aonghasa Aran Islands Ireland', ARRAY['aran-islands']::text[], ARRAY['galway', 'aran-islands']::text[], 'Dun_Aonghasa_Ireland.jpg', ARRAY['fort', 'island']::text[]),
    ('kilmurvey-beach', 'aran-islands', 'BEACH', 1, 'HOURS', 4.6, 'Пляж Килмёрви', 'Kilmurvey Beach', 'Килмёрви жағажайы', 53.12650000, -9.74800000, 'Kilmurvey Beach Aran Islands Ireland', ARRAY['aran-islands']::text[], ARRAY['galway', 'aran-islands']::text[], 'Kilmurvey_Beach_Ireland.jpg', ARRAY['island']::text[]),
    ('aran-sweater-market-inis-mor', 'aran-islands', 'SHOPPING', 1, 'HOURS', 4.5, 'Рынок аранских свитеров, Инишмор', 'Aran Sweater Market Inis Mor', 'Инишмор Аран свитер базары', 53.12260000, -9.66950000, 'Aran Sweater Market Inis Mor Ireland', ARRAY['aran-islands']::text[], ARRAY['galway', 'aran-islands']::text[], 'Aran_Sweater_Market_Inis_Mor.jpg', ARRAY['souvenirs']::text[]),
    ('great-western-greenway', 'westport', 'NATURE', 4, 'HOURS', 4.8, 'Великий западный гринвей', 'Great Western Greenway', 'Ұлы батыс гринвейі', 53.80000000, -9.52000000, 'Great Western Greenway Ireland', ARRAY['westport', 'achill']::text[], ARRAY['galway', 'westport']::text[], 'Great_Western_Greenway_Ireland.jpg', ARRAY['cycling', 'trail']::text[]),
    ('westport-house-and-gardens', 'westport', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Усадьба и сады Уэстпорта', 'Westport House and Gardens', 'Уэстпорт үйі мен бақтары', 53.80090000, -9.53560000, 'Westport House and Gardens Ireland', ARRAY['westport']::text[], ARRAY['galway', 'westport']::text[], 'Westport_House_Ireland.jpg', ARRAY['garden', 'family']::text[]),
    ('croagh-patrick', 'westport', 'NATURE', 4, 'HOURS', 4.8, 'Крох-Патрик', 'Croagh Patrick', 'Крох-Патрик', 53.75990000, -9.65960000, 'Croagh Patrick Ireland', ARRAY['westport']::text[], ARRAY['galway', 'westport']::text[], 'Croagh_Patrick_Ireland.jpg', ARRAY['hiking', 'pilgrimage']::text[]),
    ('keem-bay', 'achill', 'BEACH', 2, 'HOURS', 4.9, 'Бухта Ким', 'Keem Bay', 'Ким шығанағы', 53.96780000, -10.19500000, 'Keem Bay Achill Ireland', ARRAY['achill', 'westport']::text[], ARRAY['westport', 'achill']::text[], 'Keem_Bay_Achill_Ireland.jpg', ARRAY['wild-atlantic-way', 'beach']::text[]),

    ('english-market-cork', 'cork', 'MARKET', 1, 'HOURS', 4.7, 'Английский рынок Корка', 'English Market Cork', 'Корк ағылшын базары', 51.89800000, -8.47600000, 'English Market Cork Ireland', ARRAY['cork']::text[], ARRAY['cork']::text[], 'English_Market_Cork.jpg', ARRAY['local-market', 'food']::text[]),
    ('cork-city-gaol', 'cork', 'MUSEUM', 2, 'HOURS', 4.6, 'Тюрьма-музей Корка', 'Cork City Gaol', 'Корк түрме музейі', 51.89900000, -8.49900000, 'Cork City Gaol Ireland', ARRAY['cork']::text[], ARRAY['cork']::text[], 'Cork_City_Gaol.jpg', ARRAY['indoor', 'history']::text[]),
    ('saint-fin-barres-cathedral', 'cork', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Святого Финбарра', 'Saint Fin Barres Cathedral', 'Әулие Финбарр соборы', 51.89400000, -8.48000000, 'Saint Fin Barres Cathedral Cork Ireland', ARRAY['cork']::text[], ARRAY['cork']::text[], 'Saint_Fin_Barres_Cathedral_Cork.jpg', ARRAY['cathedral']::text[]),
    ('fitzgerald-park-cork', 'cork', 'PARK', 1, 'HOURS', 4.5, 'Парк Фицджеральда', 'Fitzgerald Park Cork', 'Корк Фицджеральд паркі', 51.89600000, -8.49400000, 'Fitzgerald Park Cork Ireland', ARRAY['cork']::text[], ARRAY['cork']::text[], 'Fitzgerald_Park_Cork.jpg', ARRAY['family']::text[]),
    ('titanic-experience-cobh', 'cobh', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Titanic Experience в Кове', 'Titanic Experience Cobh', 'Ков Titanic Experience музейі', 51.85000000, -8.29500000, 'Titanic Experience Cobh Ireland', ARRAY['cobh', 'cork']::text[], ARRAY['cork', 'cobh']::text[], 'Titanic_Experience_Cobh.jpg', ARRAY['indoor', 'history']::text[]),
    ('spike-island', 'cobh', 'MUSEUM', 3, 'HOURS', 4.7, 'Остров Спайк', 'Spike Island', 'Спайк аралы', 51.83500000, -8.28700000, 'Spike Island Cork Ireland', ARRAY['cobh', 'cork']::text[], ARRAY['cork', 'cobh']::text[], 'Spike_Island_Cork.jpg', ARRAY['island', 'history']::text[]),
    ('saint-colmans-cathedral-cobh', 'cobh', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святого Колмана в Кове', 'Saint Colmans Cathedral Cobh', 'Ков Әулие Колман соборы', 51.85200000, -8.29400000, 'Saint Colmans Cathedral Cobh Ireland', ARRAY['cobh', 'cork']::text[], ARRAY['cork', 'cobh']::text[], 'Saint_Colmans_Cathedral_Cobh.jpg', ARRAY['cathedral']::text[]),
    ('blarney-castle-and-gardens', 'blarney', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Замок и сады Бларни', 'Blarney Castle and Gardens', 'Бларни қамалы мен бақтары', 51.92900000, -8.57100000, 'Blarney Castle and Gardens Ireland', ARRAY['blarney', 'cork']::text[], ARRAY['cork', 'blarney']::text[], 'Blarney_Castle_Ireland.jpg', ARRAY['garden', 'history']::text[]),
    ('charles-fort-kinsale', 'kinsale', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Форт Чарльз в Кинсейле', 'Charles Fort Kinsale', 'Кинсейл Чарльз форты', 51.70600000, -8.49800000, 'Charles Fort Kinsale Ireland', ARRAY['kinsale', 'cork']::text[], ARRAY['cork', 'kinsale']::text[], 'Charles_Fort_Kinsale.jpg', ARRAY['fort', 'coast']::text[]),
    ('kinsale-farmers-market', 'kinsale', 'MARKET', 1, 'HOURS', 4.4, 'Фермерский рынок Кинсейла', 'Kinsale Farmers Market', 'Кинсейл фермерлер базары', 51.70500000, -8.52200000, 'Kinsale Farmers Market Ireland', ARRAY['kinsale', 'cork']::text[], ARRAY['cork', 'kinsale']::text[], 'Kinsale_Farmers_Market.jpg', ARRAY['local-market']::text[]),
    ('killarney-national-park', 'killarney', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Килларни', 'Killarney National Park', 'Килларни ұлттық паркі', 52.01700000, -9.50600000, 'Killarney National Park Ireland', ARRAY['killarney']::text[], ARRAY['cork', 'killarney']::text[], 'Killarney_National_Park.jpg', ARRAY['hiking', 'lakes']::text[]),
    ('muckross-house-and-gardens', 'killarney', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом и сады Макросс', 'Muckross House and Gardens', 'Макросс үйі мен бақтары', 52.01800000, -9.50100000, 'Muckross House and Gardens Ireland', ARRAY['killarney']::text[], ARRAY['killarney']::text[], 'Muckross_House_Ireland.jpg', ARRAY['garden', 'indoor']::text[]),
    ('ross-castle', 'killarney', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Замок Росс', 'Ross Castle', 'Росс қамалы', 52.04200000, -9.53200000, 'Ross Castle Killarney Ireland', ARRAY['killarney']::text[], ARRAY['killarney']::text[], 'Ross_Castle_Killarney.jpg', ARRAY['castle', 'lake']::text[]),
    ('torc-waterfall', 'killarney', 'NATURE', 1, 'HOURS', 4.8, 'Водопад Торк', 'Torc Waterfall', 'Торк сарқырамасы', 52.00500000, -9.50600000, 'Torc Waterfall Killarney Ireland', ARRAY['killarney']::text[], ARRAY['killarney']::text[], 'Torc_Waterfall_Killarney.jpg', ARRAY['waterfall']::text[]),
    ('gap-of-dunloe', 'killarney', 'NATURE', 4, 'HOURS', 4.8, 'Ущелье Данлоу', 'Gap of Dunloe', 'Данлоу шатқалы', 52.01100000, -9.63300000, 'Gap of Dunloe Ireland', ARRAY['killarney']::text[], ARRAY['killarney']::text[], 'Gap_of_Dunloe_Ireland.jpg', ARRAY['hiking', 'viewpoint']::text[]),
    ('ring-of-kerry', 'ring-of-kerry', 'NATURE', 8, 'HOURS', 4.9, 'Кольцо Керри', 'Ring of Kerry', 'Керри сақинасы', 51.93000000, -10.20000000, 'Ring of Kerry Ireland', ARRAY['ring-of-kerry', 'killarney']::text[], ARRAY['killarney', 'ring-of-kerry']::text[], 'Ring_of_Kerry_Ireland.jpg', ARRAY['road-trip', 'wild-atlantic-way']::text[]),
    ('derrynane-beach', 'ring-of-kerry', 'BEACH', 2, 'HOURS', 4.8, 'Пляж Дерринейн', 'Derrynane Beach', 'Дерринейн жағажайы', 51.76600000, -10.13100000, 'Derrynane Beach Ireland', ARRAY['ring-of-kerry']::text[], ARRAY['killarney', 'ring-of-kerry']::text[], 'Derrynane_Beach_Ireland.jpg', ARRAY['beach', 'coast']::text[]),
    ('kerry-cliffs', 'ring-of-kerry', 'NATURE', 2, 'HOURS', 4.8, 'Скалы Керри', 'Kerry Cliffs', 'Керри жартастары', 51.88600000, -10.37800000, 'Kerry Cliffs Ireland', ARRAY['ring-of-kerry']::text[], ARRAY['killarney', 'ring-of-kerry']::text[], 'Kerry_Cliffs_Ireland.jpg', ARRAY['viewpoint']::text[]),
    ('skellig-michael', 'ring-of-kerry', 'ARCHITECTURE', 5, 'HOURS', 4.9, 'Скеллиг-Майкл', 'Skellig Michael', 'Скеллиг-Майкл', 51.77200000, -10.54000000, 'Skellig Michael Ireland', ARRAY['ring-of-kerry']::text[], ARRAY['killarney', 'ring-of-kerry']::text[], 'Skellig_Michael_Ireland.jpg', ARRAY['unesco', 'island']::text[]),
    ('dingle-peninsula', 'dingle', 'NATURE', 6, 'HOURS', 4.9, 'Полуостров Дингл', 'Dingle Peninsula', 'Дингл түбегі', 52.14000000, -10.27000000, 'Dingle Peninsula Ireland', ARRAY['dingle']::text[], ARRAY['killarney', 'dingle']::text[], 'Dingle_Peninsula_Ireland.jpg', ARRAY['road-trip', 'coast']::text[]),
    ('slea-head-drive', 'dingle', 'NATURE', 3, 'HOURS', 4.8, 'Маршрут Сли-Хед', 'Slea Head Drive', 'Сли-Хед бағыты', 52.10400000, -10.46300000, 'Slea Head Drive Ireland', ARRAY['dingle']::text[], ARRAY['dingle']::text[], 'Slea_Head_Drive_Ireland.jpg', ARRAY['viewpoint', 'coast']::text[]),
    ('inch-beach', 'dingle', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Инч', 'Inch Beach', 'Инч жағажайы', 52.14200000, -9.98200000, 'Inch Beach Kerry Ireland', ARRAY['dingle']::text[], ARRAY['dingle']::text[], 'Inch_Beach_Ireland.jpg', ARRAY['surf', 'beach']::text[]),
    ('gallarus-oratory', 'dingle', 'TEMPLE', 1, 'HOURS', 4.6, 'Ораторий Галларус', 'Gallarus Oratory', 'Галларус ораториясы', 52.17300000, -10.35300000, 'Gallarus Oratory Ireland', ARRAY['dingle']::text[], ARRAY['dingle']::text[], 'Gallarus_Oratory_Ireland.jpg', ARRAY['monastic', 'history']::text[]),
    ('dingle-oceanworld-aquarium', 'dingle', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Океанариум Dingle Oceanworld', 'Dingle Oceanworld Aquarium', 'Dingle Oceanworld океанариумы', 52.14000000, -10.27700000, 'Dingle Oceanworld Aquarium Ireland', ARRAY['dingle']::text[], ARRAY['dingle']::text[], 'Dingle_Oceanworld_Aquarium.jpg', ARRAY['family', 'indoor']::text[]),

    ('waterford-viking-triangle', 'waterford', 'MUSEUM', 2, 'HOURS', 4.7, 'Викингский треугольник Уотерфорда', 'Waterford Viking Triangle', 'Уотерфорд викинг үшбұрышы', 52.26030000, -7.10620000, 'Waterford Viking Triangle Ireland', ARRAY['waterford']::text[], ARRAY['waterford']::text[], 'Waterford_Viking_Triangle.jpg', ARRAY['history', 'walk']::text[]),
    ('waterford-treasures-medieval-museum', 'waterford', 'MUSEUM', 2, 'HOURS', 4.7, 'Средневековый музей Waterford Treasures', 'Waterford Treasures Medieval Museum', 'Waterford Treasures ортағасырлық музейі', 52.26100000, -7.10600000, 'Waterford Treasures Medieval Museum Ireland', ARRAY['waterford']::text[], ARRAY['waterford']::text[], 'Waterford_Treasures_Medieval_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('reginalds-tower', 'waterford', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Башня Реджинальда', 'Reginalds Tower', 'Реджинальд мұнарасы', 52.26080000, -7.10670000, 'Reginalds Tower Waterford Ireland', ARRAY['waterford']::text[], ARRAY['waterford']::text[], 'Reginalds_Tower_Waterford.jpg', ARRAY['history']::text[]),
    ('house-of-waterford-crystal', 'waterford', 'SHOPPING', 2, 'HOURS', 4.6, 'Дом хрусталя Waterford', 'House of Waterford Crystal', 'Waterford Crystal үйі', 52.26000000, -7.10700000, 'House of Waterford Crystal Ireland', ARRAY['waterford']::text[], ARRAY['waterford']::text[], 'House_of_Waterford_Crystal.jpg', ARRAY['indoor', 'craft']::text[]),
    ('waterford-greenway', 'waterford', 'PARK', 4, 'HOURS', 4.8, 'Уотерфордская зеленая велодорога', 'Waterford Greenway', 'Уотерфорд гринвейі', 52.26000000, -7.11100000, 'Waterford Greenway Ireland', ARRAY['waterford']::text[], ARRAY['waterford']::text[], 'Waterford_Greenway_Ireland.jpg', ARRAY['cycling', 'trail']::text[]),
    ('kilkenny-castle', 'kilkenny', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Килкенни', 'Kilkenny Castle', 'Килкенни қамалы', 52.65050000, -7.24920000, 'Kilkenny Castle Ireland', ARRAY['kilkenny']::text[], ARRAY['dublin', 'kilkenny']::text[], 'Kilkenny_Castle_Ireland.jpg', ARRAY['castle', 'garden']::text[]),
    ('medieval-mile-museum', 'kilkenny', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей Средневековой мили', 'Medieval Mile Museum', 'Ортағасырлық миль музейі', 52.65260000, -7.25270000, 'Medieval Mile Museum Kilkenny Ireland', ARRAY['kilkenny']::text[], ARRAY['kilkenny']::text[], 'Medieval_Mile_Museum_Kilkenny.jpg', ARRAY['indoor', 'history']::text[]),
    ('st-canices-cathedral-round-tower', 'kilkenny', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Святого Каниса и круглая башня', 'St Canices Cathedral and Round Tower', 'Әулие Канис соборы және дөңгелек мұнара', 52.65780000, -7.25650000, 'St Canices Cathedral Kilkenny Ireland', ARRAY['kilkenny']::text[], ARRAY['kilkenny']::text[], 'St_Canices_Cathedral_Kilkenny.jpg', ARRAY['cathedral', 'viewpoint']::text[]),
    ('smithwicks-experience-kilkenny', 'kilkenny', 'FOOD', 2, 'HOURS', 4.6, 'Пивоваренный центр Smithwicks', 'Smithwicks Experience Kilkenny', 'Smithwicks тәжірибе орталығы', 52.65480000, -7.25470000, 'Smithwicks Experience Kilkenny Ireland', ARRAY['kilkenny']::text[], ARRAY['kilkenny']::text[], 'Smithwicks_Experience_Kilkenny.jpg', ARRAY['beer', 'indoor']::text[]),
    ('kilkenny-design-centre', 'kilkenny', 'SHOPPING', 1, 'HOURS', 4.5, 'Центр ирландского дизайна Килкенни', 'Kilkenny Design Centre', 'Килкенни дизайн орталығы', 52.65070000, -7.24840000, 'Kilkenny Design Centre Ireland', ARRAY['kilkenny']::text[], ARRAY['kilkenny']::text[], 'Kilkenny_Design_Centre.jpg', ARRAY['souvenirs']::text[]),
    ('rock-of-cashel', 'cashel', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Скала Кашел', 'Rock of Cashel', 'Кашел жартасы', 52.52010000, -7.89050000, 'Rock of Cashel Ireland', ARRAY['cashel', 'kilkenny']::text[], ARRAY['dublin', 'kilkenny', 'cashel']::text[], 'Rock_of_Cashel_Ireland.jpg', ARRAY['history', 'monastic']::text[]),
    ('bru-boru-cultural-centre', 'cashel', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Культурный центр Бру Бору', 'Bru Boru Cultural Centre', 'Бру Бору мәдени орталығы', 52.51910000, -7.89180000, 'Bru Boru Cultural Centre Cashel Ireland', ARRAY['cashel']::text[], ARRAY['cashel']::text[], 'Bru_Boru_Cultural_Centre_Cashel.jpg', ARRAY['culture', 'music']::text[]),
    ('king-johns-castle', 'limerick', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок короля Иоанна', 'King Johns Castle', 'Король Джон қамалы', 52.66970000, -8.62500000, 'King Johns Castle Limerick Ireland', ARRAY['limerick']::text[], ARRAY['limerick']::text[], 'King_Johns_Castle_Limerick.jpg', ARRAY['castle', 'history']::text[]),
    ('hunt-museum', 'limerick', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Ханта', 'The Hunt Museum', 'Хант музейі', 52.66570000, -8.62360000, 'The Hunt Museum Limerick Ireland', ARRAY['limerick']::text[], ARRAY['limerick']::text[], 'Hunt_Museum_Limerick.jpg', ARRAY['indoor', 'art']::text[]),
    ('milk-market-limerick', 'limerick', 'MARKET', 1, 'HOURS', 4.5, 'Молочный рынок Лимерика', 'Milk Market Limerick', 'Лимерик сүт базары', 52.66190000, -8.62390000, 'Milk Market Limerick Ireland', ARRAY['limerick']::text[], ARRAY['limerick']::text[], 'Milk_Market_Limerick.jpg', ARRAY['local-market', 'food']::text[]),
    ('lough-gur', 'limerick', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Лох-Гур', 'Lough Gur', 'Лох-Гур көлі', 52.52000000, -8.52600000, 'Lough Gur Limerick Ireland', ARRAY['limerick']::text[], ARRAY['limerick']::text[], 'Lough_Gur_Ireland.jpg', ARRAY['lake', 'history']::text[]),
    ('carrowmore-megalithic-cemetery', 'sligo', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мегалитическое кладбище Карроумор', 'Carrowmore Megalithic Cemetery', 'Карроумор мегалит зираты', 54.25070000, -8.51970000, 'Carrowmore Megalithic Cemetery Sligo Ireland', ARRAY['sligo']::text[], ARRAY['sligo']::text[], 'Carrowmore_Megalithic_Cemetery.jpg', ARRAY['megalith', 'history']::text[]),
    ('sligo-abbey', 'sligo', 'TEMPLE', 1, 'HOURS', 4.5, 'Аббатство Слайго', 'Sligo Abbey', 'Слайго аббаттығы', 54.27140000, -8.47050000, 'Sligo Abbey Ireland', ARRAY['sligo']::text[], ARRAY['sligo']::text[], 'Sligo_Abbey_Ireland.jpg', ARRAY['monastic']::text[]),
    ('strandhill-beach', 'sligo', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Страндхилл', 'Strandhill Beach', 'Страндхилл жағажайы', 54.27000000, -8.59400000, 'Strandhill Beach Sligo Ireland', ARRAY['sligo']::text[], ARRAY['sligo']::text[], 'Strandhill_Beach_Ireland.jpg', ARRAY['surf', 'coast']::text[]),
    ('national-surf-centre-strandhill', 'sligo', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Национальный серф-центр Страндхилл', 'National Surf Centre Strandhill', 'Страндхилл ұлттық серф орталығы', 54.27050000, -8.59600000, 'National Surf Centre Strandhill Ireland', ARRAY['sligo']::text[], ARRAY['sligo']::text[], 'National_Surf_Centre_Strandhill.jpg', ARRAY['surf', 'family']::text[]),
    ('slieve-league-cliffs', 'donegal', 'NATURE', 2, 'HOURS', 4.9, 'Скалы Слив-Лиг', 'Slieve League Cliffs', 'Слив-Лиг жартастары', 54.62790000, -8.68420000, 'Slieve League Cliffs Donegal Ireland', ARRAY['donegal']::text[], ARRAY['donegal', 'letterkenny']::text[], 'Slieve_League_Cliffs_Ireland.jpg', ARRAY['wild-atlantic-way', 'viewpoint']::text[]),
    ('donegal-castle', 'donegal', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Донегол', 'Donegal Castle', 'Донегол қамалы', 54.65450000, -8.11070000, 'Donegal Castle Ireland', ARRAY['donegal']::text[], ARRAY['donegal']::text[], 'Donegal_Castle_Ireland.jpg', ARRAY['castle']::text[]),
    ('fanad-lighthouse', 'donegal', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Маяк Фанад', 'Fanad Lighthouse', 'Фанад маягы', 55.27530000, -7.63200000, 'Fanad Lighthouse Donegal Ireland', ARRAY['donegal', 'letterkenny']::text[], ARRAY['letterkenny', 'donegal']::text[], 'Fanad_Lighthouse_Ireland.jpg', ARRAY['coast', 'viewpoint']::text[]),
    ('malin-head', 'donegal', 'NATURE', 2, 'HOURS', 4.8, 'Мэлин-Хед', 'Malin Head', 'Мэлин-Хед', 55.37900000, -7.37300000, 'Malin Head Donegal Ireland', ARRAY['donegal', 'letterkenny']::text[], ARRAY['letterkenny', 'donegal']::text[], 'Malin_Head_Ireland.jpg', ARRAY['northern-point', 'coast']::text[]),
    ('portsalon-beach', 'donegal', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Портсалон', 'Portsalon Beach', 'Портсалон жағажайы', 55.19600000, -7.62800000, 'Portsalon Beach Donegal Ireland', ARRAY['donegal', 'letterkenny']::text[], ARRAY['letterkenny', 'donegal']::text[], 'Portsalon_Beach_Ireland.jpg', ARRAY['beach', 'coast']::text[]),
    ('glenveagh-national-park-and-castle', 'letterkenny', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк и замок Гленви', 'Glenveagh National Park and Castle', 'Гленви ұлттық паркі және қамалы', 55.05600000, -7.93900000, 'Glenveagh National Park and Castle Ireland', ARRAY['letterkenny', 'donegal']::text[], ARRAY['letterkenny', 'donegal']::text[], 'Glenveagh_National_Park_Ireland.jpg', ARRAY['hiking', 'castle']::text[]),
    ('donegal-county-museum', 'letterkenny', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей графства Донегол', 'Donegal County Museum', 'Донегол графтығының музейі', 54.95530000, -7.73840000, 'Donegal County Museum Letterkenny Ireland', ARRAY['letterkenny']::text[], ARRAY['letterkenny']::text[], 'Donegal_County_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('hook-lighthouse', 'wexford', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Маяк Хук', 'Hook Lighthouse', 'Хук маягы', 52.12300000, -6.92900000, 'Hook Lighthouse Wexford Ireland', ARRAY['wexford']::text[], ARRAY['wexford']::text[], 'Hook_Lighthouse_Ireland.jpg', ARRAY['coast', 'history']::text[]),
    ('irish-national-heritage-park', 'wexford', 'MUSEUM', 2, 'HOURS', 4.6, 'Ирландский национальный парк наследия', 'Irish National Heritage Park', 'Ирландия ұлттық мұра паркі', 52.34800000, -6.51600000, 'Irish National Heritage Park Wexford Ireland', ARRAY['wexford']::text[], ARRAY['wexford']::text[], 'Irish_National_Heritage_Park.jpg', ARRAY['family', 'history']::text[]),
    ('curracloe-beach', 'wexford', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Курраклоу', 'Curracloe Beach', 'Курраклоу жағажайы', 52.39700000, -6.35600000, 'Curracloe Beach Wexford Ireland', ARRAY['wexford']::text[], ARRAY['wexford']::text[], 'Curracloe_Beach_Ireland.jpg', ARRAY['beach', 'coast']::text[]),
    ('wells-house-and-gardens', 'wexford', 'PARK', 2, 'HOURS', 4.5, 'Усадьба и сады Уэллс', 'Wells House and Gardens', 'Уэллс үйі мен бақтары', 52.61900000, -6.25700000, 'Wells House and Gardens Wexford Ireland', ARRAY['wexford']::text[], ARRAY['wexford']::text[], 'Wells_House_Wexford.jpg', ARRAY['garden', 'family']::text[]),
    ('national-opera-house-wexford', 'wexford', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Национальный оперный театр Уэксфорда', 'National Opera House Wexford', 'Уэксфорд ұлттық опера театры', 52.33730000, -6.46210000, 'National Opera House Wexford Ireland', ARRAY['wexford']::text[], ARRAY['wexford']::text[], 'National_Opera_House_Wexford.jpg', ARRAY['culture', 'evening']::text[]);

CREATE TEMP TABLE seed_ireland_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-ireland-attraction:' || seed.slug) AS attraction_hash,
        md5('id-ireland-media:' || seed.slug) AS media_hash
    FROM seed_ireland_priority_attractions seed
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
    ARRAY['ireland', city_id, slug, lower(category), 'ireland-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Ирландии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Ireland tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Ирландия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'IE',
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
FROM seed_ireland_resolved_attractions
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
FROM seed_ireland_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_ireland_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_ireland_resolved_attractions
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
FROM seed_ireland_resolved_attractions seed
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
FROM seed_ireland_resolved_attractions
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
    'IE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_ireland_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'IE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_ireland_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_ireland_resolved_attractions;
DROP TABLE IF EXISTS seed_ireland_priority_attractions;
