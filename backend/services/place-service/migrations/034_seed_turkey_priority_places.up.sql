-- Priority Turkey destination places seed.
-- Turkey is seeded as a country destination with concrete city hubs for
-- admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_turkey_resolved_places;
DROP TABLE IF EXISTS seed_turkey_priority_places;

CREATE TEMP TABLE seed_turkey_priority_places (
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

INSERT INTO seed_turkey_priority_places (
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
    ('hagia-sophia', 'istanbul', 'TEMPLE', 2, 'HOURS', 4.9, 'Айя-София', 'Hagia Sophia', 'Айя-София', 41.00860000, 28.98020000, 'Hagia Sophia Istanbul Turkey', ARRAY['istanbul', 'princes-islands']::text[], ARRAY['istanbul']::text[], 'Hagia_Sophia_Mars_2013.jpg'),
    ('topkapi-palace', 'istanbul', 'MUSEUM', 3, 'HOURS', 4.8, 'Дворец Топкапы', 'Topkapi Palace', 'Топкапы сарайы', 41.01150000, 28.98330000, 'Topkapi Palace Istanbul Turkey', ARRAY['istanbul', 'princes-islands']::text[], ARRAY['istanbul']::text[], 'Topkapi_Palace_Bosphorus.jpg'),
    ('blue-mosque', 'istanbul', 'TEMPLE', 1, 'HOURS', 4.8, 'Голубая мечеть', 'Blue Mosque', 'Көк мешіт', 41.00550000, 28.97680000, 'Blue Mosque Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Blue_Mosque_Istanbul_2007.jpg'),
    ('basilica-cistern', 'istanbul', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Цистерна Базилика', 'Basilica Cistern', 'Базилика цистернасы', 41.00840000, 28.97790000, 'Basilica Cistern Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Basilica_Cistern_2014.jpg'),
    ('grand-bazaar', 'istanbul', 'MARKET', 2, 'HOURS', 4.7, 'Гранд-базар', 'Grand Bazaar', 'Гранд базар', 41.01070000, 28.96800000, 'Grand Bazaar Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Grand_Bazaar_Istanbul_2007.jpg'),
    ('spice-bazaar', 'istanbul', 'MARKET', 1, 'HOURS', 4.6, 'Египетский рынок специй', 'Spice Bazaar', 'Дәмдеуіштер базары', 41.01660000, 28.97060000, 'Spice Bazaar Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Spice_Bazaar_Istanbul.jpg'),
    ('galata-tower', 'istanbul', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Галатская башня', 'Galata Tower', 'Галата мұнарасы', 41.02560000, 28.97410000, 'Galata Tower Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Galata_Tower_2020.jpg'),
    ('dolmabahce-palace', 'istanbul', 'MUSEUM', 2, 'HOURS', 4.8, 'Дворец Долмабахче', 'Dolmabahce Palace', 'Долмабахче сарайы', 41.03920000, 29.00050000, 'Dolmabahce Palace Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Dolmabahce_Palace_Bosphorus.jpg'),
    ('istanbul-modern', 'istanbul', 'MUSEUM', 2, 'HOURS', 4.6, 'Стамбульский музей современного искусства', 'Istanbul Modern', 'Стамбул заманауи өнер музейі', 41.02590000, 28.98040000, 'Istanbul Modern Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Istanbul_Modern.jpg'),
    ('gulhane-park', 'istanbul', 'PARK', 1, 'HOURS', 4.6, 'Парк Гюльхане', 'Gulhane Park', 'Гүлхане саябағы', 41.01380000, 28.98140000, 'Gulhane Park Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Gulhane_Park.jpg'),
    ('mall-of-istanbul', 'istanbul', 'SHOPPING', 3, 'HOURS', 4.5, 'Mall of Istanbul', 'Mall of Istanbul', 'Mall of Istanbul', 41.06340000, 28.80790000, 'Mall of Istanbul Turkey', ARRAY['istanbul']::text[], ARRAY['istanbul']::text[], 'Mall_of_Istanbul.jpg'),
    ('princes-islands', 'princes-islands', 'NATURE', 4, 'HOURS', 4.7, 'Принцевы острова', $$Princes' Islands$$, 'Ханзада аралдары', 40.87460000, 29.12900000, 'Princes Islands Istanbul Turkey', ARRAY['princes-islands', 'istanbul']::text[], ARRAY['istanbul', 'princes-islands']::text[], 'Princes_Islands_Buyukada.jpg'),
    ('aya-yorgi-church', 'princes-islands', 'TEMPLE', 2, 'HOURS', 4.6, 'Церковь Айя-Йорги', 'Aya Yorgi Church', 'Айя-Йорги шіркеуі', 40.84980000, 29.12490000, 'Aya Yorgi Church Buyukada Turkey', ARRAY['princes-islands', 'istanbul']::text[], ARRAY['istanbul']::text[], 'Aya_Yorgi_Church_Buyukada.jpg'),

    ('kaleici-old-town', 'antalya', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый город Калеичи', 'Kaleici Old Town', 'Калеичи ескі қаласы', 36.88410000, 30.70560000, 'Kaleici Old Town Antalya Turkey', ARRAY['antalya', 'kemer', 'belek', 'side']::text[], ARRAY['antalya']::text[], 'Kaleici_Antalya.jpg'),
    ('konyaalti-beach', 'antalya', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Коньяалты', 'Konyaalti Beach', 'Коньяалты жағажайы', 36.87910000, 30.63310000, 'Konyaalti Beach Antalya Turkey', ARRAY['antalya', 'kemer']::text[], ARRAY['antalya']::text[], 'Konyaalti_Beach_Antalya.jpg'),
    ('duden-waterfalls', 'antalya', 'NATURE', 2, 'HOURS', 4.7, 'Водопады Дюден', 'Duden Waterfalls', 'Дүден сарқырамалары', 36.85060000, 30.78360000, 'Duden Waterfalls Antalya Turkey', ARRAY['antalya', 'belek']::text[], ARRAY['antalya']::text[], 'Duden_Waterfalls_Antalya.jpg'),
    ('antalya-museum', 'antalya', 'MUSEUM', 2, 'HOURS', 4.7, 'Археологический музей Антальи', 'Antalya Museum', 'Анталья музейі', 36.88460000, 30.67920000, 'Antalya Museum Turkey', ARRAY['antalya', 'kemer', 'belek']::text[], ARRAY['antalya']::text[], 'Antalya_Museum.jpg'),
    ('mall-of-antalya', 'antalya', 'SHOPPING', 2, 'HOURS', 4.5, 'Mall of Antalya', 'Mall of Antalya', 'Mall of Antalya', 36.91810000, 30.78360000, 'Mall of Antalya Turkey', ARRAY['antalya', 'belek']::text[], ARRAY['antalya']::text[], 'Mall_of_Antalya.jpg'),
    ('alanya-castle', 'alanya', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Крепость Аланьи', 'Alanya Castle', 'Аланья қамалы', 36.53640000, 31.99440000, 'Alanya Castle Turkey', ARRAY['alanya', 'side']::text[], ARRAY['alanya']::text[], 'Alanya_Castle.jpg'),
    ('cleopatra-beach', 'alanya', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Клеопатры', 'Cleopatra Beach', 'Клеопатра жағажайы', 36.54400000, 31.98600000, 'Cleopatra Beach Alanya Turkey', ARRAY['alanya']::text[], ARRAY['alanya']::text[], 'Cleopatra_Beach_Alanya.jpg'),
    ('alanya-friday-bazaar', 'alanya', 'MARKET', 1, 'HOURS', 4.4, 'Пятничный базар Аланьи', 'Alanya Friday Bazaar', 'Аланья жұма базары', 36.55060000, 31.99680000, 'Alanya Friday Bazaar Turkey', ARRAY['alanya']::text[], ARRAY['alanya']::text[], 'Alanya_Bazaar.jpg'),
    ('side-ancient-city', 'side', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Античный город Сиде', 'Side Ancient City', 'Сиде көне қаласы', 36.76660000, 31.39060000, 'Side Ancient City Turkey', ARRAY['side', 'belek', 'alanya', 'antalya']::text[], ARRAY['side', 'antalya']::text[], 'Side_Ancient_City.jpg'),
    ('temple-of-apollo-side', 'side', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Аполлона в Сиде', 'Temple of Apollo', 'Аполлон ғибадатханасы', 36.76600000, 31.38640000, 'Temple of Apollo Side Turkey', ARRAY['side', 'belek']::text[], ARRAY['side']::text[], 'Temple_of_Apollo_Side.jpg'),
    ('manavgat-waterfall', 'side', 'NATURE', 1, 'HOURS', 4.5, 'Водопад Манавгат', 'Manavgat Waterfall', 'Манавгат сарқырамасы', 36.81210000, 31.45490000, 'Manavgat Waterfall Turkey', ARRAY['side', 'belek', 'alanya']::text[], ARRAY['side']::text[], 'Manavgat_Waterfall.jpg'),
    ('the-land-of-legends', 'belek', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'The Land of Legends', 'The Land of Legends', 'The Land of Legends', 36.86000000, 31.05500000, 'The Land of Legends Belek Turkey', ARRAY['belek', 'antalya', 'side']::text[], ARRAY['belek', 'antalya']::text[], 'The_Land_of_Legends.jpg'),
    ('aspendos-theatre', 'belek', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Театр Аспендос', 'Aspendos Theatre', 'Аспендос театры', 36.93920000, 31.17220000, 'Aspendos Theatre Turkey', ARRAY['belek', 'side', 'antalya']::text[], ARRAY['belek', 'antalya']::text[], 'Aspendos_Theatre.jpg'),
    ('phaselis-ancient-city', 'kemer', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Античный город Фаселис', 'Phaselis Ancient City', 'Фаселис көне қаласы', 36.52470000, 30.55240000, 'Phaselis Ancient City Kemer Turkey', ARRAY['kemer', 'antalya', 'kas']::text[], ARRAY['kemer', 'antalya']::text[], 'Phaselis_Turkey.jpg'),
    ('tahtali-mountain-cable-car', 'kemer', 'NATURE', 3, 'HOURS', 4.7, 'Гора Тахталы и канатная дорога', 'Tahtali Mountain Cable Car', 'Тахталы тауы аспалы жолы', 36.54300000, 30.48640000, 'Tahtali Mountain Olympos Cable Car Turkey', ARRAY['kemer', 'antalya']::text[], ARRAY['kemer']::text[], 'Tahtali_Mountain.jpg'),
    ('kaputas-beach', 'kas', 'BEACH', 2, 'HOURS', 4.8, 'Пляж Капуташ', 'Kaputas Beach', 'Капуташ жағажайы', 36.22980000, 29.45070000, 'Kaputas Beach Turkey', ARRAY['kas', 'fethiye']::text[], ARRAY['kas', 'fethiye']::text[], 'Kaputas_Beach.jpg'),
    ('kekova-simena', 'kas', 'NATURE', 4, 'HOURS', 4.7, 'Кекова и Симена', 'Kekova and Simena', 'Кекова және Симена', 36.19160000, 29.86970000, 'Kekova Simena Turkey', ARRAY['kas', 'kemer']::text[], ARRAY['kas']::text[], 'Kekova_Turkey.jpg'),

    ('ephesus-ancient-city', 'selcuk', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Древний Эфес', 'Ephesus Ancient City', 'Ефес көне қаласы', 37.94110000, 27.34190000, 'Ephesus Ancient City Selcuk Turkey', ARRAY['selcuk', 'izmir', 'pamukkale']::text[], ARRAY['selcuk', 'izmir']::text[], 'Ephesus_Celsus_Library.jpg'),
    ('house-of-virgin-mary', 'selcuk', 'TEMPLE', 1, 'HOURS', 4.6, 'Дом Девы Марии', 'House of Virgin Mary', 'Бикеш Мария үйі', 37.91270000, 27.33390000, 'House of Virgin Mary Selcuk Turkey', ARRAY['selcuk', 'izmir']::text[], ARRAY['selcuk', 'izmir']::text[], 'House_of_the_Virgin_Mary.jpg'),
    ('sirince-village', 'selcuk', 'FOOD', 2, 'HOURS', 4.6, 'Деревня Шириндже', 'Sirince Village', 'Ширинже ауылы', 37.94390000, 27.43140000, 'Sirince Village Turkey', ARRAY['selcuk', 'izmir']::text[], ARRAY['selcuk', 'izmir']::text[], 'Sirince_Village_Turkey.jpg'),
    ('kemeralti-bazaar', 'izmir', 'MARKET', 2, 'HOURS', 4.7, 'Базар Кемералты', 'Kemeralti Bazaar', 'Кемералты базары', 38.41830000, 27.13480000, 'Kemeralti Bazaar Izmir Turkey', ARRAY['izmir', 'selcuk', 'cesme']::text[], ARRAY['izmir']::text[], 'Kemeralti_Bazaar_Izmir.jpg'),
    ('izmir-clock-tower', 'izmir', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Часовая башня Измира', 'Izmir Clock Tower', 'Измир сағат мұнарасы', 38.41890000, 27.12850000, 'Izmir Clock Tower Turkey', ARRAY['izmir']::text[], ARRAY['izmir']::text[], 'Izmir_Clock_Tower.jpg'),
    ('forum-bornova', 'izmir', 'SHOPPING', 2, 'HOURS', 4.5, 'Forum Bornova', 'Forum Bornova', 'Forum Bornova', 38.45330000, 27.21010000, 'Forum Bornova Izmir Turkey', ARRAY['izmir']::text[], ARRAY['izmir']::text[], 'Forum_Bornova.jpg'),
    ('cesme-castle', 'cesme', 'MUSEUM', 2, 'HOURS', 4.6, 'Замок Чешме', 'Cesme Castle', 'Чешме қамалы', 38.32690000, 26.30690000, 'Cesme Castle Turkey', ARRAY['cesme', 'izmir']::text[], ARRAY['cesme', 'izmir']::text[], 'Cesme_Castle.jpg'),
    ('ilica-beach', 'cesme', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Илиджа', 'Ilica Beach', 'Илыджа жағажайы', 38.31570000, 26.36540000, 'Ilica Beach Cesme Turkey', ARRAY['cesme', 'izmir']::text[], ARRAY['cesme']::text[], 'Ilica_Beach_Cesme.jpg'),
    ('bodrum-castle', 'bodrum', 'MUSEUM', 2, 'HOURS', 4.8, 'Замок Бодрума', 'Bodrum Castle', 'Бодрум қамалы', 37.03220000, 27.42930000, 'Bodrum Castle Turkey', ARRAY['bodrum', 'marmaris']::text[], ARRAY['bodrum']::text[], 'Bodrum_Castle.jpg'),
    ('mausoleum-at-halicarnassus', 'bodrum', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Мавзолей в Галикарнасе', 'Mausoleum at Halicarnassus', 'Галикарнас кесенесі', 37.03790000, 27.42410000, 'Mausoleum at Halicarnassus Bodrum Turkey', ARRAY['bodrum']::text[], ARRAY['bodrum']::text[], 'Mausoleum_at_Halicarnassus.jpg'),
    ('marmaris-grand-bazaar', 'marmaris', 'MARKET', 2, 'HOURS', 4.4, 'Гранд-базар Мармариса', 'Marmaris Grand Bazaar', 'Мармарис Гранд базары', 36.85210000, 28.27460000, 'Marmaris Grand Bazaar Turkey', ARRAY['marmaris', 'bodrum', 'fethiye']::text[], ARRAY['marmaris']::text[], 'Marmaris_Bazaar.jpg'),
    ('icmeler-beach', 'marmaris', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Ичмелер', 'Icmeler Beach', 'Ичмелер жағажайы', 36.80150000, 28.23240000, 'Icmeler Beach Marmaris Turkey', ARRAY['marmaris']::text[], ARRAY['marmaris']::text[], 'Icmeler_Beach.jpg'),
    ('fethiye-paspatur', 'fethiye', 'MARKET', 2, 'HOURS', 4.5, 'Паспатур и старый город Фетхие', 'Fethiye Paspatur Old Town', 'Фетхие Паспатур ескі қаласы', 36.62200000, 29.11270000, 'Fethiye Paspatur Old Town Turkey', ARRAY['fethiye', 'oludeniz']::text[], ARRAY['fethiye']::text[], 'Fethiye_Old_Town.jpg'),
    ('saklikent-canyon', 'fethiye', 'NATURE', 4, 'HOURS', 4.7, 'Каньон Саклыкент', 'Saklikent Canyon', 'Саклыкент шатқалы', 36.47440000, 29.40340000, 'Saklikent Canyon Turkey', ARRAY['fethiye', 'oludeniz']::text[], ARRAY['fethiye']::text[], 'Saklikent_Canyon.jpg'),
    ('oludeniz-blue-lagoon', 'oludeniz', 'BEACH', 3, 'HOURS', 4.9, 'Голубая лагуна Олюдениз', 'Oludeniz Blue Lagoon', 'Олюдениз көк лагунасы', 36.54830000, 29.12450000, 'Oludeniz Blue Lagoon Turkey', ARRAY['oludeniz', 'fethiye']::text[], ARRAY['oludeniz', 'fethiye']::text[], 'Oludeniz_Blue_Lagoon.jpg'),
    ('babadag-paragliding', 'oludeniz', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Парапланы на Бабадаге', 'Babadag Paragliding', 'Бабадаг парапланы', 36.53420000, 29.17440000, 'Babadag Paragliding Oludeniz Turkey', ARRAY['oludeniz', 'fethiye']::text[], ARRAY['oludeniz']::text[], 'Babadag_Paragliding.jpg'),
    ('pamukkale-travertines', 'pamukkale', 'NATURE', 3, 'HOURS', 4.9, 'Травертины Памуккале', 'Pamukkale Travertines', 'Памуккале травертиндері', 37.91370000, 29.11870000, 'Pamukkale Travertines Turkey', ARRAY['pamukkale', 'denizli', 'selcuk']::text[], ARRAY['pamukkale', 'denizli']::text[], 'Pamukkale_Travertines.jpg'),
    ('hierapolis-ancient-city', 'pamukkale', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Античный город Иераполис', 'Hierapolis Ancient City', 'Иераполис көне қаласы', 37.92650000, 29.12500000, 'Hierapolis Ancient City Turkey', ARRAY['pamukkale', 'denizli']::text[], ARRAY['pamukkale']::text[], 'Hierapolis_Pamukkale.jpg'),
    ('laodicea-ancient-city', 'denizli', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Античная Лаодикея', 'Laodicea Ancient City', 'Лаодикея көне қаласы', 37.83570000, 29.10760000, 'Laodicea Ancient City Denizli Turkey', ARRAY['denizli', 'pamukkale']::text[], ARRAY['denizli', 'pamukkale']::text[], 'Laodicea_Turkey.jpg'),

    ('goreme-open-air-museum', 'goreme', 'MUSEUM', 3, 'HOURS', 4.9, 'Музей под открытым небом Гёреме', 'Goreme Open Air Museum', 'Гёреме ашық аспан музейі', 38.64000000, 34.84510000, 'Goreme Open Air Museum Turkey', ARRAY['goreme', 'cappadocia', 'uchisar', 'urgup', 'avanos']::text[], ARRAY['goreme', 'cappadocia']::text[], 'Goreme_Open_Air_Museum.jpg'),
    ('uchisar-castle', 'uchisar', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Крепость Учхисар', 'Uchisar Castle', 'Учхисар қамалы', 38.63110000, 34.80560000, 'Uchisar Castle Cappadocia Turkey', ARRAY['uchisar', 'goreme', 'cappadocia']::text[], ARRAY['uchisar', 'goreme']::text[], 'Uchisar_Castle.jpg'),
    ('derinkuyu-underground-city', 'nevsehir', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Подземный город Деринкую', 'Derinkuyu Underground City', 'Деринкую жер асты қаласы', 38.37530000, 34.73520000, 'Derinkuyu Underground City Turkey', ARRAY['nevsehir', 'cappadocia', 'goreme', 'urgup']::text[], ARRAY['nevsehir', 'goreme']::text[], 'Derinkuyu_Underground_City.jpg'),
    ('pasabag-monks-valley', 'avanos', 'NATURE', 1, 'HOURS', 4.7, 'Пашабаг и Долина монахов', 'Pasabag Monks Valley', 'Пашабаг монахтар аңғары', 38.67910000, 34.85380000, 'Pasabag Monks Valley Cappadocia Turkey', ARRAY['avanos', 'goreme', 'urgup', 'cappadocia']::text[], ARRAY['avanos', 'goreme']::text[], 'Pasabag_Cappadocia.jpg'),
    ('avanos-pottery-workshops', 'avanos', 'SHOPPING', 2, 'HOURS', 4.6, 'Гончарные мастерские Аваноса', 'Avanos Pottery Workshops', 'Аванос қыш шеберханалары', 38.71500000, 34.84670000, 'Avanos Pottery Workshops Turkey', ARRAY['avanos', 'goreme', 'urgup']::text[], ARRAY['avanos']::text[], 'Avanos_Pottery.jpg'),
    ('urgup-viewpoint', 'urgup', 'NATURE', 1, 'HOURS', 4.6, 'Смотровые точки Ургюпа', 'Urgup Viewpoints', 'Үргүп көрініс алаңдары', 38.63190000, 34.91190000, 'Urgup Viewpoints Cappadocia Turkey', ARRAY['urgup', 'goreme', 'uchisar', 'cappadocia']::text[], ARRAY['urgup']::text[], 'Urgup_Cappadocia.jpg'),
    ('cappadocia-clay-pot-kebab', 'cappadocia', 'FOOD', 2, 'HOURS', 4.6, 'Каппадокийский тесты-кебаб', 'Cappadocia Clay Pot Kebab', 'Каппадокия құмыра кебабы', 38.64310000, 34.82890000, 'Cappadocia clay pot kebab Turkey', ARRAY['cappadocia', 'goreme', 'urgup', 'avanos']::text[], ARRAY['cappadocia', 'goreme']::text[], 'Cappadocia_Pottery.jpg'),
    ('anitkabir', 'ankara', 'MUSEUM', 2, 'HOURS', 4.9, 'Аныткабир', 'Anitkabir', 'Анытқабір', 39.92510000, 32.83690000, 'Anitkabir Ankara Turkey', ARRAY['ankara']::text[], ARRAY['ankara']::text[], 'Anitkabir_Ankara.jpg'),
    ('museum-of-anatolian-civilizations', 'ankara', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей анатолийских цивилизаций', 'Museum of Anatolian Civilizations', 'Анадолы өркениеттері музейі', 39.93860000, 32.86190000, 'Museum of Anatolian Civilizations Ankara Turkey', ARRAY['ankara', 'konya', 'cappadocia']::text[], ARRAY['ankara']::text[], 'Museum_of_Anatolian_Civilizations.jpg'),
    ('ankara-castle', 'ankara', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Анкарская крепость', 'Ankara Castle', 'Анкара қамалы', 39.94140000, 32.86480000, 'Ankara Castle Turkey', ARRAY['ankara']::text[], ARRAY['ankara']::text[], 'Ankara_Castle.jpg'),
    ('mevlana-museum', 'konya', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Мевляны', 'Mevlana Museum', 'Мевлана музейі', 37.87060000, 32.50410000, 'Mevlana Museum Konya Turkey', ARRAY['konya', 'cappadocia', 'ankara']::text[], ARRAY['konya']::text[], 'Mevlana_Museum_Konya.jpg'),
    ('aziziye-mosque-konya-bazaar', 'konya', 'MARKET', 2, 'HOURS', 4.5, 'Мечеть Азизие и базар Коньи', 'Aziziye Mosque and Konya Bazaar', 'Азизие мешіті және Конья базары', 37.87170000, 32.50490000, 'Aziziye Mosque Konya Bazaar Turkey', ARRAY['konya']::text[], ARRAY['konya']::text[], 'Konya_Bazaar.jpg'),

    ('sumela-monastery', 'trabzon', 'TEMPLE', 3, 'HOURS', 4.8, 'Монастырь Сумела', 'Sumela Monastery', 'Сумела монастырі', 40.69000000, 39.65900000, 'Sumela Monastery Trabzon Turkey', ARRAY['trabzon', 'uzungol', 'rize']::text[], ARRAY['trabzon']::text[], 'Sumela_Monastery.jpg'),
    ('trabzon-hagia-sophia', 'trabzon', 'TEMPLE', 1, 'HOURS', 4.6, 'Айя-София Трабзона', 'Hagia Sophia Trabzon', 'Трабзон Айя-Софиясы', 41.00320000, 39.69680000, 'Hagia Sophia Trabzon Turkey', ARRAY['trabzon']::text[], ARRAY['trabzon']::text[], 'Hagia_Sophia_Trabzon.jpg'),
    ('uzungol', 'uzungol', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Узунгёль', 'Uzungol', 'Ұзынкөл', 40.61920000, 40.29500000, 'Uzungol Trabzon Turkey', ARRAY['uzungol', 'trabzon', 'rize']::text[], ARRAY['trabzon', 'uzungol']::text[], 'Uzungol_Trabzon.jpg'),
    ('ayder-plateau', 'rize', 'NATURE', 4, 'HOURS', 4.7, 'Плато Айдер', 'Ayder Plateau', 'Айдер жайлауы', 40.95260000, 41.09390000, 'Ayder Plateau Rize Turkey', ARRAY['rize', 'uzungol', 'trabzon']::text[], ARRAY['rize', 'trabzon']::text[], 'Ayder_Plateau.jpg'),
    ('zil-kale', 'rize', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Зиль', 'Zil Castle', 'Зил қамалы', 40.95040000, 40.96080000, 'Zil Castle Rize Turkey', ARRAY['rize', 'uzungol']::text[], ARRAY['rize']::text[], 'Zil_Kale_Rize.jpg'),
    ('borcka-karagol', 'artvin', 'NATURE', 3, 'HOURS', 4.7, 'Озеро Карагёль в Борчке', 'Borcka Karagol Lake', 'Борчка Қаракөл көлі', 41.35470000, 41.84850000, 'Borcka Karagol Artvin Turkey', ARRAY['artvin', 'rize']::text[], ARRAY['artvin', 'rize']::text[], 'Borcka_Karagol.jpg'),
    ('mardin-old-town', 'mardin', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый Мардин', 'Mardin Old Town', 'Ескі Мардин', 37.31310000, 40.73510000, 'Mardin Old Town Turkey', ARRAY['mardin', 'sanliurfa']::text[], ARRAY['mardin']::text[], 'Mardin_Old_Town.jpg'),
    ('deyrulzafaran-monastery', 'mardin', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Дейрулзафаран', 'Deyrulzafaran Monastery', 'Дейрулзафаран монастырі', 37.31630000, 40.77040000, 'Deyrulzafaran Monastery Mardin Turkey', ARRAY['mardin']::text[], ARRAY['mardin']::text[], 'Deyrulzafaran_Monastery.jpg'),
    ('gobeklitepe', 'sanliurfa', 'TEMPLE', 2, 'HOURS', 4.9, 'Гёбекли-Тепе', 'Gobeklitepe', 'Гөбеклі-Тепе', 37.22400000, 38.92200000, 'Gobeklitepe Sanliurfa Turkey', ARRAY['sanliurfa', 'mardin', 'gaziantep']::text[], ARRAY['sanliurfa']::text[], 'Gobekli_Tepe.jpg'),
    ('sanliurfa-bazaar', 'sanliurfa', 'MARKET', 2, 'HOURS', 4.6, 'Базары Шанлыурфы', 'Sanliurfa Bazaar', 'Шанлыурфа базары', 37.15070000, 38.78690000, 'Sanliurfa Bazaar Turkey', ARRAY['sanliurfa']::text[], ARRAY['sanliurfa']::text[], 'Sanliurfa_Bazaar.jpg'),
    ('zeugma-mosaic-museum', 'gaziantep', 'MUSEUM', 2, 'HOURS', 4.9, 'Музей мозаик Зевгмы', 'Zeugma Mosaic Museum', 'Зевгма мозаика музейі', 37.06620000, 37.38330000, 'Zeugma Mosaic Museum Gaziantep Turkey', ARRAY['gaziantep', 'sanliurfa']::text[], ARRAY['gaziantep']::text[], 'Zeugma_Mosaic_Museum.jpg'),
    ('gaziantep-bakircilar-bazaar', 'gaziantep', 'MARKET', 2, 'HOURS', 4.7, 'Базар медников Газиантепа', 'Gaziantep Bakircilar Bazaar', 'Газиантеп мысшылар базары', 37.06490000, 37.37940000, 'Gaziantep Bakircilar Bazaar Turkey', ARRAY['gaziantep']::text[], ARRAY['gaziantep']::text[], 'Gaziantep_Bakircilar_Bazaar.jpg'),
    ('gaziantep-baklava-route', 'gaziantep', 'FOOD', 2, 'HOURS', 4.8, 'Гастрономический маршрут баклавы', 'Gaziantep Baklava Route', 'Газиантеп баклава бағыты', 37.06690000, 37.37810000, 'Gaziantep baklava route Turkey', ARRAY['gaziantep']::text[], ARRAY['gaziantep']::text[], 'Gaziantep_Baklava.jpg');

CREATE TEMP TABLE seed_turkey_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-turkey-place:' || seed.slug) AS place_hash,
        md5('id-turkey-media:' || seed.slug) AS media_hash
    FROM seed_turkey_priority_places seed
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
    ARRAY['turkey', city_id, slug, lower(category), 'turkey-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Турции: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Turkey tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Түркия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'TR',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 400::numeric
        ELSE 200::numeric
    END,
    'TRY',
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
FROM seed_turkey_resolved_places
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
FROM seed_turkey_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_turkey_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_turkey_resolved_places
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
FROM seed_turkey_resolved_places seed
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
FROM seed_turkey_resolved_places
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
    'TR',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_turkey_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'TR',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_turkey_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_turkey_resolved_places;
DROP TABLE IF EXISTS seed_turkey_priority_places;
