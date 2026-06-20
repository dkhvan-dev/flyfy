-- Priority Luxembourg destination places seed.
-- The seed keeps compact country coverage explicit for admin filters and localized mobile discovery.

DROP TABLE IF EXISTS seed_luxembourg_resolved_places;
DROP TABLE IF EXISTS seed_luxembourg_priority_places;

CREATE TEMP TABLE seed_luxembourg_priority_places (
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

INSERT INTO seed_luxembourg_priority_places (
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
    ('bock-casemates', 'luxembourg-city', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Казематы Бок', 'Bock Casemates', 'Бок казематтары', 49.61130000, 6.13670000, 'Bock Casemates Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_Pfaffenthal_Alzette_Béinchen_01.jpg'),
    ('petrusse-casemates', 'luxembourg-city', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Казематы Петрусс', 'Petrusse Casemates', 'Петрусс казематтары', 49.60820000, 6.12680000, 'Petrusse Casemates Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_City_-_Schéieschlach_depuis_Rempart.jpg'),
    ('chemin-de-la-corniche', 'luxembourg-city', 'ARCHITECTURE', 1, 'HOURS', 4.9, 'Шмен-де-ла-Корниш', 'Chemin de la Corniche', 'Шмен-де-ла-Корниш', 49.61070000, 6.13600000, 'Chemin de la Corniche Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_Pfaffenthal_Alzette_Béinchen_01.jpg'),
    ('grand-ducal-palace', 'luxembourg-city', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Дворец великих герцогов', 'Grand Ducal Palace', 'Ұлы герцог сарайы', 49.61110000, 6.13290000, 'Grand Ducal Palace Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_City_-_Schéieschlach_depuis_Rempart.jpg'),
    ('notre-dame-cathedral-luxembourg', 'luxembourg-city', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Нотр-Дам', 'Notre-Dame Cathedral', 'Нотр-Дам соборы', 49.61010000, 6.13120000, 'Notre-Dame Cathedral Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_City_-_Schéieschlach_depuis_Rempart.jpg'),
    ('luxembourg-city-markets', 'luxembourg-city', 'MARKET', 1, 'HOURS', 4.5, 'Рынки центра Люксембурга', 'Luxembourg City Markets', 'Люксембург орталық базарлары', 49.61060000, 6.13210000, 'Place Guillaume II market Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('grund-district', 'luxembourg-city', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Нижний город Грунд', 'Grund District', 'Грунд ауданы', 49.60910000, 6.13890000, 'Grund District Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_Pfaffenthal_Alzette_Béinchen_01.jpg'),
    ('pfaffenthal-panoramic-elevator', 'luxembourg-city', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Панорамный лифт Пфаффенталь', 'Pfaffenthal Panoramic Elevator', 'Пфаффенталь панорамалық лифті', 49.61720000, 6.13220000, 'Pfaffenthal Panoramic Elevator Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_Pfaffenthal_Alzette_Béinchen_01.jpg'),
    ('adolphe-bridge', 'luxembourg-city', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мост Адольфа', 'Adolphe Bridge', 'Адольф көпірі', 49.60800000, 6.12790000, 'Adolphe Bridge Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_City_-_Schéieschlach_depuis_Rempart.jpg'),
    ('constitution-square', 'luxembourg-city', 'PARK', 1, 'HOURS', 4.6, 'Площадь Конституции', 'Constitution Square', 'Конституция алаңы', 49.60940000, 6.12960000, 'Constitution Square Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('mnha-luxembourg', 'luxembourg-city', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей истории и искусства', 'National Museum of History and Art', 'Ұлттық тарих және өнер музейі', 49.61190000, 6.13450000, 'National Museum of History and Art Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('luxembourg-city-museum', 'luxembourg-city', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей истории города Люксембурга', 'Luxembourg City Museum', 'Люксембург қаласы музейі', 49.61110000, 6.13400000, 'Luxembourg City Museum Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('natural-history-museum-luxembourg', 'luxembourg-city', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей естественной истории', 'National Museum of Natural History', 'Ұлттық жаратылыстану музейі', 49.60940000, 6.13670000, 'National Museum of Natural History Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Luxembourg_Pfaffenthal_Alzette_Béinchen_01.jpg'),
    ('merl-park', 'luxembourg-city', 'PARK', 1, 'HOURS', 4.5, 'Парк Мерль', 'Merl Park', 'Мерль саябағы', 49.60200000, 6.11010000, 'Merl Park Luxembourg City Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('cloche-dor-shopping-center', 'luxembourg-city', 'SHOPPING', 2, 'HOURS', 4.5, 'ТЦ Cloche d Or', 'Cloche d Or Shopping Center', 'Cloche d Or сауда орталығы', 49.58660000, 6.12120000, 'Cloche d Or Shopping Center Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),
    ('city-concorde', 'luxembourg-city', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ City Concorde', 'City Concorde', 'City Concorde', 49.61150000, 6.07430000, 'City Concorde Luxembourg', ARRAY['luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'City_Hall_of_Luxembourg_City_01.jpg'),

    ('mudam-luxembourg', 'kirchberg', 'MUSEUM', 2, 'HOURS', 4.7, 'MUDAM Luxembourg', 'MUDAM Luxembourg', 'MUDAM Luxembourg', 49.61700000, 6.13920000, 'MUDAM Luxembourg Kirchberg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),
    ('philharmonie-luxembourg', 'kirchberg', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Филармония Люксембурга', 'Philharmonie Luxembourg', 'Люксембург филармониясы', 49.61750000, 6.14230000, 'Philharmonie Luxembourg Kirchberg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),
    ('fort-thungen-drai-eechelen', 'kirchberg', 'MUSEUM', 2, 'HOURS', 4.6, 'Форт Тюнген и музей Драй Эхелен', 'Fort Thungen and Drai Eechelen Museum', 'Тюнген форты және Драй Эхелен музейі', 49.61720000, 6.13820000, 'Fort Thungen Drai Eechelen Museum Luxembourg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),
    ('kinepolis-kirchberg', 'kirchberg', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Kinepolis Kirchberg', 'Kinepolis Kirchberg', 'Kinepolis Kirchberg', 49.63210000, 6.16960000, 'Kinepolis Kirchberg Luxembourg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),
    ('auchan-kirchberg', 'kirchberg', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Auchan Kirchberg', 'Auchan Kirchberg Shopping Center', 'Auchan Kirchberg сауда орталығы', 49.63030000, 6.17110000, 'Auchan Kirchberg Luxembourg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),
    ('luxexpo-the-box', 'kirchberg', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Luxexpo The Box', 'Luxexpo The Box', 'Luxexpo The Box', 49.63490000, 6.17070000, 'Luxexpo The Box Luxembourg', ARRAY['kirchberg', 'luxembourg-city']::text[], ARRAY['luxembourg-city']::text[], 'Mudam_04_jnl.jpg'),

    ('vianden-castle', 'vianden', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Замок Вианден', 'Vianden Castle', 'Вианден қамалы', 49.93540000, 6.20280000, 'Vianden Castle Luxembourg', ARRAY['vianden']::text[], ARRAY['vianden', 'luxembourg-city']::text[], 'Vianden_chateau1.jpg'),
    ('vianden-chairlift', 'vianden', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канатная дорога Виандена', 'Vianden Chairlift', 'Вианден аспалы жолы', 49.93800000, 6.20150000, 'Vianden Chairlift Luxembourg', ARRAY['vianden']::text[], ARRAY['vianden', 'luxembourg-city']::text[], 'Vianden_chateau1.jpg'),
    ('victor-hugo-house-vianden', 'vianden', 'MUSEUM', 1, 'HOURS', 4.5, 'Дом Виктора Гюго', 'Victor Hugo House', 'Виктор Гюго үйі', 49.93660000, 6.20480000, 'Victor Hugo House Vianden Luxembourg', ARRAY['vianden']::text[], ARRAY['vianden']::text[], 'Vianden_victor_hugo.jpg'),
    ('clervaux-castle', 'clervaux', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Клерво', 'Clervaux Castle', 'Клерво қамалы', 50.05450000, 6.03020000, 'Clervaux Castle Luxembourg', ARRAY['clervaux']::text[], ARRAY['clervaux', 'luxembourg-city']::text[], 'Clervaux_Castle_6.JPG'),
    ('family-of-man', 'clervaux', 'MUSEUM', 2, 'HOURS', 4.8, 'Фотовыставка The Family of Man', 'The Family of Man', 'The Family of Man фотокөрмесі', 50.05460000, 6.03000000, 'The Family of Man Clervaux Luxembourg', ARRAY['clervaux']::text[], ARRAY['clervaux']::text[], 'Clervaux_Castle_6.JPG'),
    ('clervaux-abbey', 'clervaux', 'TEMPLE', 1, 'HOURS', 4.6, 'Аббатство Святого Маврикия и Святого Мавра', 'Abbey of St Maurice and St Maurus', 'Әулие Маврикий және Мавр аббаттығы', 50.05690000, 6.02560000, 'Abbey of St Maurice and St Maurus Clervaux Luxembourg', ARRAY['clervaux']::text[], ARRAY['clervaux']::text[], '0_Clervaux_101021_V1.JPG'),
    ('toy-museum-clervaux', 'clervaux', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей игрушек Клерво', 'Toy Museum Clervaux', 'Клерво ойыншық музейі', 50.05470000, 6.03110000, 'Toy Museum Clervaux Luxembourg', ARRAY['clervaux']::text[], ARRAY['clervaux']::text[], 'Clervaux_Castle_6.JPG'),
    ('bourscheid-castle', 'bourscheid', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Буршайд', 'Bourscheid Castle', 'Буршайд қамалы', 49.90860000, 6.08030000, 'Bourscheid Castle Luxembourg', ARRAY['bourscheid']::text[], ARRAY['bourscheid', 'luxembourg-city']::text[], 'Buerschent.jpg'),
    ('wiltz-castle', 'wiltz', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Замок Вильц', 'Wiltz Castle', 'Вильц қамалы', 49.96690000, 5.93480000, 'Wiltz Castle Luxembourg', ARRAY['wiltz']::text[], ARRAY['wiltz', 'luxembourg-city']::text[], 'Buerschent.jpg'),
    ('garden-of-wiltz', 'wiltz', 'PARK', 1, 'HOURS', 4.5, 'Сад Вильца', 'Garden of Wiltz', 'Вильц бағы', 49.96720000, 5.93400000, 'Garden of Wiltz Luxembourg', ARRAY['wiltz']::text[], ARRAY['wiltz']::text[], 'Buerschent.jpg'),
    ('national-museum-brewing', 'wiltz', 'MUSEUM', 1, 'HOURS', 4.4, 'Национальный музей пивоварения', 'National Museum of Brewing', 'Ұлттық сыра қайнату музейі', 49.96670000, 5.93450000, 'National Museum of Brewing Wiltz Luxembourg', ARRAY['wiltz']::text[], ARRAY['wiltz']::text[], 'Buerschent.jpg'),
    ('esch-sur-sure-castle', 'esch-sur-sure', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Эш-сюр-Сюр', 'Esch-sur-Sure Castle', 'Эш-сюр-Сюр қамалы', 49.91180000, 5.93690000, 'Esch-sur-Sure Castle Luxembourg', ARRAY['esch-sur-sure']::text[], ARRAY['esch-sur-sure', 'luxembourg-city']::text[], 'Buerschent.jpg'),
    ('upper-sure-lake', 'esch-sur-sure', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Верхняя Сюр', 'Upper Sure Lake', 'Жоғарғы Сюр көлі', 49.90200000, 5.87000000, 'Upper Sure Lake Luxembourg', ARRAY['esch-sur-sure']::text[], ARRAY['esch-sur-sure', 'wiltz']::text[], 'Buerschent.jpg'),
    ('military-history-museum-diekirch', 'diekirch', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей военной истории', 'National Museum of Military History', 'Ұлттық әскери тарих музейі', 49.86940000, 6.15780000, 'National Museum of Military History Diekirch Luxembourg', ARRAY['diekirch']::text[], ARRAY['diekirch', 'luxembourg-city']::text[], 'Buerschent.jpg'),
    ('diekirch-weekly-market', 'diekirch', 'MARKET', 1, 'HOURS', 4.4, 'Еженедельный рынок Дикирха', 'Diekirch Weekly Market', 'Дикирх апталық базары', 49.86750000, 6.15890000, 'Diekirch weekly market Luxembourg', ARRAY['diekirch']::text[], ARRAY['diekirch']::text[], 'Buerschent.jpg'),
    ('general-patton-museum', 'ettelbruck', 'MUSEUM', 1, 'HOURS', 4.5, 'Мемориальный музей генерала Паттона', 'General Patton Memorial Museum', 'Генерал Паттон мемориалдық музейі', 49.84790000, 6.10470000, 'General Patton Memorial Museum Ettelbruck Luxembourg', ARRAY['ettelbruck']::text[], ARRAY['ettelbruck', 'luxembourg-city']::text[], 'Buerschent.jpg'),
    ('cape-ettelbruck', 'ettelbruck', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Культурный центр CAPE Ettelbruck', 'CAPE Ettelbruck', 'CAPE Ettelbruck мәдени орталығы', 49.85000000, 6.10090000, 'CAPE Ettelbruck Luxembourg', ARRAY['ettelbruck']::text[], ARRAY['ettelbruck']::text[], 'Buerschent.jpg'),

    ('echternach-abbey', 'echternach', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Аббатство Эхтернах', 'Echternach Abbey', 'Эхтернах аббаттығы', 49.81240000, 6.42190000, 'Echternach Abbey Luxembourg', ARRAY['echternach']::text[], ARRAY['echternach', 'luxembourg-city']::text[], 'Echternach_place_du_Marché_vers_abbaye.jpg'),
    ('st-willibrord-basilica', 'echternach', 'TEMPLE', 1, 'HOURS', 4.7, 'Базилика Святого Виллиброрда', 'St Willibrord Basilica', 'Әулие Виллиброрд базиликасы', 49.81230000, 6.42150000, 'St Willibrord Basilica Echternach Luxembourg', ARRAY['echternach']::text[], ARRAY['echternach']::text[], 'Echternach_place_du_Marché_vers_abbaye.jpg'),
    ('echternach-lake', 'echternach', 'PARK', 2, 'HOURS', 4.6, 'Озеро Эхтернах', 'Echternach Lake', 'Эхтернах көлі', 49.80380000, 6.42850000, 'Echternach Lake Luxembourg', ARRAY['echternach']::text[], ARRAY['echternach']::text[], 'Echternach_place_du_Marché_vers_abbaye.jpg'),
    ('roman-villa-echternach', 'echternach', 'MUSEUM', 1, 'HOURS', 4.5, 'Римская вилла Эхтернаха', 'Roman Villa Echternach', 'Эхтернах рим вилласы', 49.80510000, 6.42880000, 'Roman Villa Echternach Luxembourg', ARRAY['echternach']::text[], ARRAY['echternach']::text[], 'Echternach_place_du_Marché_vers_abbaye.jpg'),
    ('echternach-market-square', 'echternach', 'MARKET', 1, 'HOURS', 4.4, 'Рыночная площадь Эхтернаха', 'Echternach Market Square', 'Эхтернах базар алаңы', 49.81380000, 6.42020000, 'Echternach Market Square Luxembourg', ARRAY['echternach']::text[], ARRAY['echternach']::text[], 'Echternach_place_du_Marché_vers_abbaye.jpg'),
    ('mullerthal-trail', 'mullerthal', 'NATURE', 5, 'HOURS', 4.9, 'Тропа Мюллерталь', 'Mullerthal Trail', 'Мюллерталь соқпағы', 49.79300000, 6.30600000, 'Mullerthal Trail Luxembourg', ARRAY['mullerthal', 'echternach']::text[], ARRAY['mullerthal', 'echternach', 'luxembourg-city']::text[], 'Mullerthal.jpg'),
    ('schiessentumpel-waterfall', 'mullerthal', 'NATURE', 2, 'HOURS', 4.8, 'Водопад Шиссентюмпель', 'Schiessentumpel Waterfall', 'Шиссентюмпель сарқырамасы', 49.77950000, 6.30630000, 'Schiessentumpel Waterfall Mullerthal Luxembourg', ARRAY['mullerthal']::text[], ARRAY['mullerthal', 'echternach']::text[], 'Mullerthal_Cascade_Bridge_01.jpg'),
    ('heringer-millen', 'mullerthal', 'FOOD', 1, 'HOURS', 4.5, 'Heringer Millen', 'Heringer Millen', 'Heringer Millen', 49.78500000, 6.30450000, 'Heringer Millen Mullerthal Luxembourg', ARRAY['mullerthal']::text[], ARRAY['mullerthal', 'echternach']::text[], 'Mullerthal.jpg'),
    ('berdorf-rock-formations', 'berdorf', 'NATURE', 3, 'HOURS', 4.8, 'Скалы Бердорфа', 'Berdorf Rock Formations', 'Бердорф жартастары', 49.82170000, 6.34950000, 'Berdorf rock formations Luxembourg', ARRAY['berdorf']::text[], ARRAY['berdorf', 'echternach']::text[], 'Mullerthal.jpg'),
    ('aquatower-berdorf', 'berdorf', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Аквабашня Бердорф', 'Aquatower Berdorf', 'Бердорф су мұнарасы', 49.82050000, 6.34990000, 'Aquatower Berdorf Luxembourg', ARRAY['berdorf']::text[], ARRAY['berdorf']::text[], 'Mullerthal.jpg'),
    ('werschrummschluff-gorge', 'berdorf', 'NATURE', 2, 'HOURS', 4.7, 'Ущелье Вершруммшлюфф', 'Werschrummschluff Gorge', 'Вершруммшлюфф шатқалы', 49.82260000, 6.34180000, 'Werschrummschluff Berdorf Luxembourg', ARRAY['berdorf']::text[], ARRAY['berdorf', 'echternach']::text[], 'Mullerthal.jpg'),
    ('beaufort-castle', 'beaufort', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Бофор', 'Beaufort Castle', 'Бофор қамалы', 49.83300000, 6.28790000, 'Beaufort Castle Luxembourg', ARRAY['beaufort']::text[], ARRAY['beaufort', 'echternach']::text[], 'Mullerthal.jpg'),
    ('renaissance-castle-beaufort', 'beaufort', 'MUSEUM', 1, 'HOURS', 4.5, 'Ренессансный замок Бофор', 'Renaissance Castle Beaufort', 'Бофор ренессанс қамалы', 49.83310000, 6.28750000, 'Renaissance Castle Beaufort Luxembourg', ARRAY['beaufort']::text[], ARRAY['beaufort']::text[], 'Mullerthal.jpg'),
    ('beaufort-ice-rink', 'beaufort', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Каток Бофора', 'Beaufort Ice Rink', 'Бофор мұз айдыны', 49.83550000, 6.29190000, 'Beaufort Ice Rink Luxembourg', ARRAY['beaufort']::text[], ARRAY['beaufort']::text[], 'Mullerthal.jpg'),
    ('larochette-castle', 'larochette', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Ларошетт', 'Larochette Castle', 'Ларошетт қамалы', 49.78740000, 6.22080000, 'Larochette Castle Luxembourg', ARRAY['larochette']::text[], ARRAY['larochette', 'luxembourg-city']::text[], 'Mullerthal.jpg'),
    ('larochette-market-square', 'larochette', 'MARKET', 1, 'HOURS', 4.3, 'Рыночная площадь Ларошетта', 'Larochette Market Square', 'Ларошетт базар алаңы', 49.78570000, 6.21930000, 'Larochette Market Square Luxembourg', ARRAY['larochette']::text[], ARRAY['larochette']::text[], 'Mullerthal.jpg'),

    ('esch-animal-park-gaalgebierg', 'esch-sur-alzette', 'PARK', 2, 'HOURS', 4.6, 'Зоопарк Гаальгебьерг', 'Esch Animal Park Gaalgebierg', 'Гаальгебьерг жануарлар саябағы', 49.48990000, 5.97870000, 'Esch Animal Park Gaalgebierg Luxembourg', ARRAY['esch-sur-alzette']::text[], ARRAY['esch-sur-alzette', 'luxembourg-city']::text[], 'Belval_88.jpg'),
    ('national-resistance-museum', 'esch-sur-alzette', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный музей сопротивления', 'National Resistance Museum', 'Ұлттық қарсыласу музейі', 49.49620000, 5.98060000, 'National Resistance Museum Esch-sur-Alzette Luxembourg', ARRAY['esch-sur-alzette']::text[], ARRAY['esch-sur-alzette']::text[], 'Belval_88.jpg'),
    ('kulturfabrik-esch', 'esch-sur-alzette', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Kulturfabrik Esch', 'Kulturfabrik Esch', 'Kulturfabrik Esch', 49.50030000, 5.98280000, 'Kulturfabrik Esch-sur-Alzette Luxembourg', ARRAY['esch-sur-alzette']::text[], ARRAY['esch-sur-alzette']::text[], 'Belval_88.jpg'),
    ('esch-city-market', 'esch-sur-alzette', 'MARKET', 1, 'HOURS', 4.3, 'Городской рынок Эш-сюр-Альзетт', 'Esch City Market', 'Эш қалалық базары', 49.49580000, 5.98060000, 'Esch-sur-Alzette city market Luxembourg', ARRAY['esch-sur-alzette']::text[], ARRAY['esch-sur-alzette']::text[], 'Belval_88.jpg'),
    ('belval-blast-furnaces', 'belval', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Доменные печи Бельваля', 'Belval Blast Furnaces', 'Бельваль домна пештері', 49.49960000, 5.94800000, 'Belval Blast Furnaces Luxembourg', ARRAY['belval', 'esch-sur-alzette']::text[], ARRAY['belval', 'esch-sur-alzette', 'luxembourg-city']::text[], 'Belval_88.jpg'),
    ('rockhal', 'belval', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Rockhal', 'Rockhal', 'Rockhal', 49.50040000, 5.94670000, 'Rockhal Belval Luxembourg', ARRAY['belval', 'esch-sur-alzette']::text[], ARRAY['belval', 'esch-sur-alzette']::text[], 'Belval_88.jpg'),
    ('belval-plaza', 'belval', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Belval Plaza', 'Belval Plaza', 'Belval Plaza', 49.50240000, 5.94470000, 'Belval Plaza Luxembourg', ARRAY['belval', 'esch-sur-alzette']::text[], ARRAY['belval', 'esch-sur-alzette']::text[], 'Belval_88.jpg'),
    ('minett-park-fond-de-gras', 'differdange', 'MUSEUM', 3, 'HOURS', 4.7, 'Minett Park Fond-de-Gras', 'Minett Park Fond-de-Gras', 'Minett Park Fond-de-Gras', 49.52740000, 5.91070000, 'Minett Park Fond-de-Gras Luxembourg', ARRAY['differdange']::text[], ARRAY['differdange', 'luxembourg-city']::text[], 'Belval_88.jpg'),
    ('luxembourg-science-center', 'differdange', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Luxembourg Science Center', 'Luxembourg Science Center', 'Luxembourg Science Center', 49.52250000, 5.89120000, 'Luxembourg Science Center Differdange', ARRAY['differdange']::text[], ARRAY['differdange']::text[], 'Belval_88.jpg'),
    ('differdange-castle', 'differdange', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Замок Дифферданж', 'Differdange Castle', 'Дифферданж қамалы', 49.52430000, 5.89150000, 'Differdange Castle Luxembourg', ARRAY['differdange']::text[], ARRAY['differdange']::text[], 'Belval_88.jpg'),
    ('parc-leh-dudelange', 'dudelange', 'PARK', 2, 'HOURS', 4.5, 'Парк Le h', 'Parc Le h', 'Le h саябағы', 49.47900000, 6.08730000, 'Parc Le h Dudelange Luxembourg', ARRAY['dudelange']::text[], ARRAY['dudelange']::text[], 'Belval_88.jpg'),
    ('cna-dudelange', 'dudelange', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный аудиовизуальный центр', 'National Audiovisual Center', 'Ұлттық аудиовизуалдық орталық', 49.48170000, 6.08330000, 'National Audiovisual Center Dudelange Luxembourg', ARRAY['dudelange']::text[], ARRAY['dudelange']::text[], 'Belval_88.jpg'),
    ('dudelange-water-tower', 'dudelange', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Водонапорная башня Дюделанжа', 'Dudelange Water Tower', 'Дюделанж су мұнарасы', 49.47930000, 6.08190000, 'Dudelange Water Tower Luxembourg', ARRAY['dudelange']::text[], ARRAY['dudelange']::text[], 'Belval_88.jpg'),
    ('remich-esplanade', 'remich', 'PARK', 2, 'HOURS', 4.6, 'Эспланада Ремиха', 'Remich Esplanade', 'Ремих эспланадасы', 49.54480000, 6.36710000, 'Remich Esplanade Luxembourg', ARRAY['remich']::text[], ARRAY['remich', 'luxembourg-city']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('moselle-wine-route', 'remich', 'FOOD', 4, 'HOURS', 4.7, 'Мозельская винная дорога', 'Moselle Wine Route', 'Мозель шарап жолы', 49.54600000, 6.36760000, 'Moselle Wine Route Remich Luxembourg', ARRAY['remich', 'grevenmacher', 'schengen']::text[], ARRAY['remich', 'grevenmacher', 'schengen', 'luxembourg-city']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('caves-saint-martin', 'remich', 'FOOD', 2, 'HOURS', 4.5, 'Винные погреба Saint Martin', 'Caves Saint Martin', 'Saint Martin шарап жертөлелері', 49.54360000, 6.37060000, 'Caves Saint Martin Remich Luxembourg', ARRAY['remich']::text[], ARRAY['remich']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('butterfly-garden-grevenmacher', 'grevenmacher', 'PARK', 2, 'HOURS', 4.6, 'Сад бабочек Гревенмахера', 'Butterfly Garden Grevenmacher', 'Гревенмахер көбелек бағы', 49.67480000, 6.43900000, 'Butterfly Garden Grevenmacher Luxembourg', ARRAY['grevenmacher']::text[], ARRAY['grevenmacher', 'luxembourg-city']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('kulturhuef-museum', 'grevenmacher', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Kulturhuef', 'Kulturhuef Museum', 'Kulturhuef музейі', 49.68000000, 6.44100000, 'Kulturhuef Grevenmacher Luxembourg', ARRAY['grevenmacher']::text[], ARRAY['grevenmacher']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('caves-bernard-massard', 'grevenmacher', 'FOOD', 2, 'HOURS', 4.5, 'Винные погреба Bernard-Massard', 'Caves Bernard-Massard', 'Bernard-Massard шарап жертөлелері', 49.68130000, 6.43970000, 'Caves Bernard-Massard Grevenmacher Luxembourg', ARRAY['grevenmacher']::text[], ARRAY['grevenmacher']::text[], 'Tussen_Remich_en_Bous,_panorama_foto7_2017-05-26_14.44.jpg'),
    ('schengen-european-museum', 'schengen', 'MUSEUM', 2, 'HOURS', 4.6, 'Европейский музей Шенгена', 'Schengen European Museum', 'Шенген Еуропалық музейі', 49.47030000, 6.36660000, 'Schengen European Museum Luxembourg', ARRAY['schengen']::text[], ARRAY['schengen', 'luxembourg-city']::text[], 'Luxembourg_Schengen_from_Markusberg_a.jpg'),
    ('schengen-agreement-monument', 'schengen', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Памятник Шенгенскому соглашению', 'Schengen Agreement Monument', 'Шенген келісімі ескерткіші', 49.47010000, 6.36600000, 'Schengen Agreement Monument Luxembourg', ARRAY['schengen']::text[], ARRAY['schengen']::text[], 'Luxembourg_Schengen_from_Markusberg_a.jpg'),
    ('mondorf-domaine-thermal', 'mondorf-les-bains', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Термальный комплекс Мондорф', 'Mondorf Domaine Thermal', 'Мондорф термалды кешені', 49.50760000, 6.28190000, 'Mondorf Domaine Thermal Luxembourg', ARRAY['mondorf-les-bains']::text[], ARRAY['mondorf-les-bains', 'luxembourg-city']::text[], 'Luxembourg_Schengen_from_Markusberg_a.jpg'),
    ('casino-2000', 'mondorf-les-bains', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Casino 2000', 'Casino 2000', 'Casino 2000', 49.50410000, 6.28190000, 'Casino 2000 Mondorf-les-Bains Luxembourg', ARRAY['mondorf-les-bains']::text[], ARRAY['mondorf-les-bains']::text[], 'Luxembourg_Schengen_from_Markusberg_a.jpg'),
    ('parc-thermal-mondorf', 'mondorf-les-bains', 'PARK', 2, 'HOURS', 4.6, 'Термальный парк Мондорфа', 'Parc Thermal de Mondorf', 'Мондорф термалды саябағы', 49.50780000, 6.28100000, 'Parc Thermal de Mondorf Luxembourg', ARRAY['mondorf-les-bains']::text[], ARRAY['mondorf-les-bains']::text[], 'Luxembourg_Schengen_from_Markusberg_a.jpg');

CREATE TEMP TABLE seed_luxembourg_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-luxembourg-place:' || seed.slug) AS place_hash,
        md5('id-luxembourg-media:' || seed.slug) AS media_hash
    FROM seed_luxembourg_priority_places seed
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
    ARRAY['luxembourg', city_id, slug, lower(category), 'luxembourg-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Люксембурга: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Luxembourg tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Люксембург туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'LU',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'EUR',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_luxembourg_resolved_places
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
FROM seed_luxembourg_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_luxembourg_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_luxembourg_resolved_places
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
FROM seed_luxembourg_resolved_places seed
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
FROM seed_luxembourg_resolved_places
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
    'LU',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_luxembourg_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'LU',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_luxembourg_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_luxembourg_resolved_places;
DROP TABLE IF EXISTS seed_luxembourg_priority_places;
