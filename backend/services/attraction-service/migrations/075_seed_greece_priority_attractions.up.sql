-- Priority Greece destination attractions seed.
-- The seed covers Athens/Attica, northern and central Greece, islands, and Peloponnese routes.

DROP TABLE IF EXISTS seed_greece_resolved_attractions;
DROP TABLE IF EXISTS seed_greece_priority_attractions;

CREATE TEMP TABLE seed_greece_priority_attractions (
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

INSERT INTO seed_greece_priority_attractions (
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
    ('acropolis-of-athens', 'athens', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Афинский Акрополь', 'Acropolis of Athens', 'Афины Акрополі', 37.97150000, 23.72570000, 'Acropolis of Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Acropolis_of_Athens_2013.jpg', ARRAY['unesco', 'ancient-greece']::text[]),
    ('acropolis-museum', 'athens', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Акрополя', 'Acropolis Museum', 'Акрополь музейі', 37.96840000, 23.72850000, 'Acropolis Museum Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Acropolis_Museum_Athens.jpg', ARRAY['indoor', 'ancient-greece']::text[]),
    ('national-archaeological-museum-athens', 'athens', 'MUSEUM', 3, 'HOURS', 4.8, 'Национальный археологический музей Афин', 'National Archaeological Museum Athens', 'Афины ұлттық археология музейі', 37.98900000, 23.73280000, 'National Archaeological Museum Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'National_Archaeological_Museum_Athens.jpg', ARRAY['indoor', 'history']::text[]),
    ('ancient-agora-athens', 'athens', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Древняя Агора Афин', 'Ancient Agora of Athens', 'Афины ежелгі агорасы', 37.97560000, 23.72220000, 'Ancient Agora of Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Ancient_Agora_Athens.jpg', ARRAY['archaeology', 'walk']::text[]),
    ('parthenon', 'athens', 'TEMPLE', 2, 'HOURS', 4.9, 'Парфенон', 'Parthenon', 'Парфенон', 37.97150000, 23.72670000, 'Parthenon Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Parthenon_Athens.jpg', ARRAY['unesco', 'ancient-greece']::text[]),
    ('panathenaic-stadium', 'athens', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Стадион Панатинаикос', 'Panathenaic Stadium', 'Панатинаикос стадионы', 37.96830000, 23.74110000, 'Panathenaic Stadium Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Panathenaic_Stadium_Athens.jpg', ARRAY['olympic-history']::text[]),
    ('temple-olympian-zeus', 'athens', 'TEMPLE', 1, 'HOURS', 4.6, 'Храм Зевса Олимпийского', 'Temple of Olympian Zeus', 'Олимпиялық Зевс храмы', 37.96930000, 23.73310000, 'Temple of Olympian Zeus Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Temple_of_Olympian_Zeus_Athens.jpg', ARRAY['ancient-greece']::text[]),
    ('lycabettus-hill', 'athens', 'NATURE', 2, 'HOURS', 4.7, 'Холм Ликавит', 'Lycabettus Hill', 'Ликавит төбесі', 37.98180000, 23.74370000, 'Lycabettus Hill Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Lycabettus_Hill_Athens.jpg', ARRAY['viewpoint', 'sunset']::text[]),
    ('national-garden-athens', 'athens', 'PARK', 1, 'HOURS', 4.6, 'Национальный сад Афин', 'National Garden Athens', 'Афины ұлттық бағы', 37.97380000, 23.73670000, 'National Garden Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'National_Garden_Athens.jpg', ARRAY['green-space', 'family']::text[]),
    ('stavros-niarchos-cultural-center', 'athens', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Культурный центр Фонда Ставроса Ниархоса', 'Stavros Niarchos Foundation Cultural Center', 'Ставрос Ниархос қоры мәдени орталығы', 37.93970000, 23.69150000, 'Stavros Niarchos Foundation Cultural Center Athens Greece', ARRAY['athens', 'piraeus']::text[], ARRAY['athens', 'piraeus']::text[], 'Stavros_Niarchos_Foundation_Cultural_Center.jpg', ARRAY['family', 'modern-architecture']::text[]),
    ('monastiraki-flea-market', 'athens', 'MARKET', 1, 'HOURS', 4.6, 'Блошиный рынок Монастираки', 'Monastiraki Flea Market', 'Монастираки барахолкасы', 37.97660000, 23.72490000, 'Monastiraki Flea Market Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Monastiraki_Flea_Market_Athens.jpg', ARRAY['local-market', 'souvenirs']::text[]),
    ('athens-central-market', 'athens', 'MARKET', 1, 'HOURS', 4.5, 'Центральный рынок Афин', 'Athens Central Market', 'Афины орталық базары', 37.98170000, 23.72620000, 'Varvakios Central Market Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Athens_Central_Market.jpg', ARRAY['food-market', 'local-market']::text[]),
    ('ermou-street', 'athens', 'SHOPPING', 1, 'HOURS', 4.5, 'Улица Эрму', 'Ermou Street', 'Эрму көшесі', 37.97600000, 23.72800000, 'Ermou Street Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Ermou_Street_Athens.jpg', ARRAY['shopping-street']::text[]),
    ('plaka-and-anafiotika', 'athens', 'FOOD', 2, 'HOURS', 4.7, 'Плака и Анафиотика', 'Plaka and Anafiotika', 'Плака және Анафиотика', 37.97270000, 23.72940000, 'Plaka Anafiotika Athens Greece', ARRAY['athens']::text[], ARRAY['athens']::text[], 'Plaka_Athens.jpg', ARRAY['old-town', 'evening']::text[]),
    ('piraeus-marina-zea', 'piraeus', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Зеа в Пирее', 'Piraeus Marina Zea', 'Пирей Зеа маринасы', 37.93870000, 23.64890000, 'Marina Zea Piraeus Greece', ARRAY['piraeus', 'athens']::text[], ARRAY['athens', 'piraeus']::text[], 'Marina_Zea_Piraeus.jpg', ARRAY['waterfront', 'evening']::text[]),
    ('piraeus-archaeological-museum', 'piraeus', 'MUSEUM', 1, 'HOURS', 4.4, 'Археологический музей Пирея', 'Piraeus Archaeological Museum', 'Пирей археология музейі', 37.93840000, 23.64540000, 'Piraeus Archaeological Museum Greece', ARRAY['piraeus', 'athens']::text[], ARRAY['athens', 'piraeus']::text[], 'Piraeus_Archaeological_Museum.jpg', ARRAY['indoor', 'harbor']::text[]),
    ('glyfada-beach-riviera', 'glyfada', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Глифада и Афинская Ривьера', 'Glyfada Beach and Athens Riviera', 'Глифада жағажайы және Афины Ривьерасы', 37.86360000, 23.75320000, 'Glyfada Beach Athens Riviera Greece', ARRAY['glyfada', 'athens']::text[], ARRAY['athens', 'glyfada']::text[], 'Glyfada_Beach_Athens.jpg', ARRAY['riviera', 'summer']::text[]),
    ('temple-of-poseidon-sounion', 'cape-sounion', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Посейдона на мысе Сунион', 'Temple of Poseidon Sounion', 'Сунион Посейдон храмы', 37.65060000, 24.02450000, 'Temple of Poseidon Sounion Greece', ARRAY['cape-sounion', 'athens']::text[], ARRAY['athens', 'cape-sounion']::text[], 'Temple_of_Poseidon_Sounion.jpg', ARRAY['sunset', 'day-trip']::text[]),

    ('white-tower-thessaloniki', 'thessaloniki', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Белая башня Салоник', 'White Tower of Thessaloniki', 'Салоники Ақ мұнарасы', 40.62630000, 22.94840000, 'White Tower Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'White_Tower_of_Thessaloniki.jpg', ARRAY['city-symbol', 'waterfront']::text[]),
    ('archaeological-museum-thessaloniki', 'thessaloniki', 'MUSEUM', 2, 'HOURS', 4.7, 'Археологический музей Салоник', 'Archaeological Museum of Thessaloniki', 'Салоники археология музейі', 40.62550000, 22.95370000, 'Archaeological Museum of Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Archaeological_Museum_of_Thessaloniki.jpg', ARRAY['indoor', 'history']::text[]),
    ('rotunda-of-galerius', 'thessaloniki', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Ротонда Галерия', 'Rotunda of Galerius', 'Галерий ротондасы', 40.63340000, 22.95290000, 'Rotunda of Galerius Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Rotunda_of_Galerius_Thessaloniki.jpg', ARRAY['roman', 'unesco']::text[]),
    ('aristotelous-square', 'thessaloniki', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Аристотеля', 'Aristotelous Square', 'Аристотель алаңы', 40.63200000, 22.94080000, 'Aristotelous Square Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Aristotelous_Square_Thessaloniki.jpg', ARRAY['city-center', 'walk']::text[]),
    ('modiano-market', 'thessaloniki', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Модиано', 'Modiano Market', 'Модиано базары', 40.63500000, 22.94190000, 'Modiano Market Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Modiano_Market_Thessaloniki.jpg', ARRAY['covered-market', 'food']::text[]),
    ('kapani-market', 'thessaloniki', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Капани', 'Kapani Market', 'Капани базары', 40.63580000, 22.94400000, 'Kapani Market Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Kapani_Market_Thessaloniki.jpg', ARRAY['local-market']::text[]),
    ('ladadika-district', 'thessaloniki', 'FOOD', 2, 'HOURS', 4.6, 'Район Лададика', 'Ladadika District', 'Лададика ауданы', 40.63530000, 22.93650000, 'Ladadika Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Ladadika_Thessaloniki.jpg', ARRAY['nightlife', 'evening']::text[]),
    ('mediterranean-cosmos', 'thessaloniki', 'SHOPPING', 2, 'HOURS', 4.5, 'ТЦ Mediterranean Cosmos', 'Mediterranean Cosmos', 'Mediterranean Cosmos сауда орталығы', 40.56700000, 22.99600000, 'Mediterranean Cosmos Thessaloniki Greece', ARRAY['thessaloniki']::text[], ARRAY['thessaloniki']::text[], 'Mediterranean_Cosmos_Thessaloniki.jpg', ARRAY['mall', 'indoor']::text[]),
    ('meteora-monasteries', 'meteora', 'TEMPLE', 4, 'HOURS', 4.9, 'Монастыри Метеоры', 'Meteora Monasteries', 'Метеора монастырлары', 39.71420000, 21.63110000, 'Meteora Monasteries Greece', ARRAY['meteora', 'kalambaka']::text[], ARRAY['kalambaka', 'meteora', 'thessaloniki', 'athens']::text[], 'Meteora_Monasteries_Greece.jpg', ARRAY['unesco', 'monasteries']::text[]),
    ('kalambaka-town', 'kalambaka', 'FOOD', 1, 'HOURS', 4.4, 'Каламбака у подножия Метеор', 'Kalambaka Old Town', 'Каламбака ескі қаласы', 39.70450000, 21.62760000, 'Kalambaka Greece', ARRAY['kalambaka', 'meteora']::text[], ARRAY['kalambaka', 'meteora']::text[], 'Kalambaka_Meteora_Greece.jpg', ARRAY['gateway-town']::text[]),
    ('archaeological-site-of-delphi', 'delphi', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Археологический комплекс Дельф', 'Archaeological Site of Delphi', 'Дельфы археологиялық кешені', 38.48230000, 22.50100000, 'Archaeological Site of Delphi Greece', ARRAY['delphi']::text[], ARRAY['athens', 'delphi']::text[], 'Delphi_Greece.jpg', ARRAY['unesco', 'ancient-greece']::text[]),
    ('delphi-archaeological-museum', 'delphi', 'MUSEUM', 2, 'HOURS', 4.7, 'Археологический музей Дельф', 'Delphi Archaeological Museum', 'Дельфы археология музейі', 38.48080000, 22.49900000, 'Delphi Archaeological Museum Greece', ARRAY['delphi']::text[], ARRAY['athens', 'delphi']::text[], 'Delphi_Archaeological_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('arachova-village', 'arachova', 'FOOD', 2, 'HOURS', 4.5, 'Горная деревня Арахова', 'Arachova Village', 'Арахова ауылы', 38.47950000, 22.58350000, 'Arachova Greece', ARRAY['arachova', 'delphi']::text[], ARRAY['athens', 'delphi', 'arachova']::text[], 'Arachova_Greece.jpg', ARRAY['mountain-town', 'winter']::text[]),
    ('mount-olympus-national-park', 'olympus', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Олимп', 'Mount Olympus National Park', 'Олимп ұлттық паркі', 40.08560000, 22.35860000, 'Mount Olympus National Park Greece', ARRAY['olympus', 'litochoro']::text[], ARRAY['thessaloniki', 'litochoro', 'olympus']::text[], 'Mount_Olympus_Greece.jpg', ARRAY['national-park', 'hiking']::text[]),
    ('enipeas-gorge', 'litochoro', 'NATURE', 3, 'HOURS', 4.7, 'Ущелье Энипей', 'Enipeas Gorge', 'Энипей шатқалы', 40.10580000, 22.49760000, 'Enipeas Gorge Litochoro Greece', ARRAY['litochoro', 'olympus']::text[], ARRAY['litochoro', 'olympus']::text[], 'Enipeas_Gorge_Greece.jpg', ARRAY['hiking', 'waterfalls']::text[]),
    ('volos-waterfront', 'volos', 'FOOD', 2, 'HOURS', 4.5, 'Набережная Волоса', 'Volos Waterfront', 'Волос жағалауы', 39.36170000, 22.94380000, 'Volos Waterfront Greece', ARRAY['volos']::text[], ARRAY['volos']::text[], 'Volos_Waterfront_Greece.jpg', ARRAY['waterfront', 'tsipouro']::text[]),
    ('pelion-mountain-villages', 'pelion', 'NATURE', 4, 'HOURS', 4.8, 'Горные деревни Пелиона', 'Pelion Mountain Villages', 'Пелион тау ауылдары', 39.38680000, 22.99850000, 'Pelion Mountain Villages Greece', ARRAY['pelion', 'volos']::text[], ARRAY['volos', 'pelion']::text[], 'Pelion_Greece.jpg', ARRAY['villages', 'hiking']::text[]),
    ('halkidiki-sithonia-beaches', 'halkidiki', 'BEACH', 4, 'HOURS', 4.8, 'Пляжи Ситонии в Халкидики', 'Halkidiki Sithonia Beaches', 'Халкидики Ситония жағажайлары', 40.19490000, 23.80080000, 'Halkidiki Sithonia Beaches Greece', ARRAY['halkidiki']::text[], ARRAY['thessaloniki', 'halkidiki']::text[], 'Halkidiki_Beach_Greece.jpg', ARRAY['summer', 'coast']::text[]),

    ('santorini-caldera', 'santorini', 'NATURE', 3, 'HOURS', 4.9, 'Кальдера Санторини', 'Santorini Caldera', 'Санторини кальдерасы', 36.40960000, 25.44400000, 'Santorini Caldera Greece', ARRAY['santorini', 'fira', 'oia']::text[], ARRAY['santorini', 'fira']::text[], 'Santorini_Caldera_Greece.jpg', ARRAY['viewpoint', 'volcanic']::text[]),
    ('oia-sunset', 'oia', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Закат в Ие', 'Oia Sunset', 'Иядағы күн батуы', 36.46180000, 25.37530000, 'Oia Santorini Greece sunset', ARRAY['oia', 'santorini']::text[], ARRAY['santorini', 'oia']::text[], 'Oia_Santorini_Greece.jpg', ARRAY['sunset', 'cyclades']::text[]),
    ('fira-old-port', 'fira', 'FOOD', 2, 'HOURS', 4.5, 'Старый порт Фиры', 'Fira Old Port', 'Фира ескі порты', 36.41650000, 25.43240000, 'Fira Old Port Santorini Greece', ARRAY['fira', 'santorini']::text[], ARRAY['santorini', 'fira']::text[], 'Fira_Santorini_Greece.jpg', ARRAY['waterfront', 'evening']::text[]),
    ('akrotiri-archaeological-site', 'santorini', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Археологический комплекс Акротири', 'Akrotiri Archaeological Site', 'Акротири археологиялық кешені', 36.35170000, 25.40370000, 'Akrotiri Archaeological Site Santorini Greece', ARRAY['santorini']::text[], ARRAY['santorini', 'fira']::text[], 'Akrotiri_Santorini_Greece.jpg', ARRAY['bronze-age', 'indoor']::text[]),
    ('red-beach-santorini', 'santorini', 'BEACH', 2, 'HOURS', 4.5, 'Красный пляж Санторини', 'Red Beach Santorini', 'Санторини Қызыл жағажайы', 36.34840000, 25.39440000, 'Red Beach Santorini Greece', ARRAY['santorini']::text[], ARRAY['santorini', 'fira']::text[], 'Red_Beach_Santorini.jpg', ARRAY['volcanic', 'summer']::text[]),
    ('mykonos-windmills', 'mykonos', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Ветряные мельницы Миконоса', 'Mykonos Windmills', 'Миконос жел диірмендері', 37.44530000, 25.32570000, 'Mykonos Windmills Greece', ARRAY['mykonos']::text[], ARRAY['mykonos']::text[], 'Mykonos_Windmills.jpg', ARRAY['photo-stop', 'cyclades']::text[]),
    ('little-venice-mykonos', 'mykonos', 'FOOD', 2, 'HOURS', 4.6, 'Маленькая Венеция Миконоса', 'Little Venice Mykonos', 'Миконос Кіші Венециясы', 37.44610000, 25.32720000, 'Little Venice Mykonos Greece', ARRAY['mykonos']::text[], ARRAY['mykonos']::text[], 'Little_Venice_Mykonos.jpg', ARRAY['evening', 'waterfront']::text[]),
    ('delos-archaeological-site', 'delos', 'TEMPLE', 3, 'HOURS', 4.8, 'Археологический комплекс Делоса', 'Delos Archaeological Site', 'Делос археологиялық кешені', 37.39630000, 25.27110000, 'Delos Archaeological Site Greece', ARRAY['delos', 'mykonos']::text[], ARRAY['mykonos', 'delos']::text[], 'Delos_Greece.jpg', ARRAY['unesco', 'day-trip']::text[]),
    ('palace-of-knossos', 'heraklion', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Кносский дворец', 'Palace of Knossos', 'Кносс сарайы', 35.29810000, 25.16310000, 'Palace of Knossos Crete Greece', ARRAY['heraklion']::text[], ARRAY['heraklion']::text[], 'Knossos_Crete_Greece.jpg', ARRAY['minoans', 'archaeology']::text[]),
    ('heraklion-archaeological-museum', 'heraklion', 'MUSEUM', 2, 'HOURS', 4.8, 'Археологический музей Ираклиона', 'Heraklion Archaeological Museum', 'Ираклион археология музейі', 35.33970000, 25.13770000, 'Heraklion Archaeological Museum Crete Greece', ARRAY['heraklion']::text[], ARRAY['heraklion']::text[], 'Heraklion_Archaeological_Museum.jpg', ARRAY['indoor', 'minoans']::text[]),
    ('heraklion-central-market', 'heraklion', 'MARKET', 1, 'HOURS', 4.4, 'Центральный рынок Ираклиона', 'Heraklion Central Market', 'Ираклион орталық базары', 35.33890000, 25.13200000, 'Heraklion Central Market Crete Greece', ARRAY['heraklion']::text[], ARRAY['heraklion']::text[], 'Heraklion_Central_Market.jpg', ARRAY['local-market', 'food']::text[]),
    ('old-venetian-harbor-chania', 'chania', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый венецианский порт Ханьи', 'Old Venetian Harbor Chania', 'Ханья ескі венециялық порты', 35.51960000, 24.01720000, 'Old Venetian Harbor Chania Crete Greece', ARRAY['chania']::text[], ARRAY['chania']::text[], 'Chania_Old_Venetian_Harbour.jpg', ARRAY['waterfront', 'old-town']::text[]),
    ('chania-old-market', 'chania', 'MARKET', 1, 'HOURS', 4.4, 'Старый рынок Ханьи', 'Chania Old Market', 'Ханья ескі базары', 35.51270000, 24.01890000, 'Chania Old Market Crete Greece', ARRAY['chania']::text[], ARRAY['chania']::text[], 'Chania_Market_Crete.jpg', ARRAY['covered-market', 'food']::text[]),
    ('balos-lagoon', 'chania', 'BEACH', 4, 'HOURS', 4.9, 'Лагуна Балос', 'Balos Lagoon', 'Балос лагунасы', 35.58300000, 23.58700000, 'Balos Lagoon Crete Greece', ARRAY['chania']::text[], ARRAY['chania']::text[], 'Balos_Lagoon_Crete.jpg', ARRAY['lagoon', 'summer']::text[]),
    ('rethymno-old-town', 'rethymno', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый город Ретимно', 'Rethymno Old Town', 'Ретимно ескі қаласы', 35.37390000, 24.47240000, 'Rethymno Old Town Crete Greece', ARRAY['rethymno']::text[], ARRAY['rethymno']::text[], 'Rethymno_Old_Town.jpg', ARRAY['venetian', 'walk']::text[]),
    ('lake-voulismeni', 'agios-nikolaos', 'NATURE', 1, 'HOURS', 4.5, 'Озеро Вулисмени', 'Lake Voulismeni', 'Вулисмени көлі', 35.19010000, 25.71620000, 'Lake Voulismeni Agios Nikolaos Crete Greece', ARRAY['agios-nikolaos']::text[], ARRAY['agios-nikolaos']::text[], 'Lake_Voulismeni_Crete.jpg', ARRAY['waterfront']::text[]),
    ('elafonisi-beach', 'elafonisi', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Элафониси', 'Elafonisi Beach', 'Элафониси жағажайы', 35.27060000, 23.54060000, 'Elafonisi Beach Crete Greece', ARRAY['elafonisi', 'chania']::text[], ARRAY['chania', 'elafonisi']::text[], 'Elafonisi_Beach_Crete.jpg', ARRAY['pink-sand', 'summer']::text[]),
    ('old-town-of-rhodes', 'rhodes', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Старый город Родоса', 'Old Town of Rhodes', 'Родос ескі қаласы', 36.44360000, 28.22880000, 'Old Town of Rhodes Greece', ARRAY['rhodes']::text[], ARRAY['rhodes']::text[], 'Rhodes_Old_Town.jpg', ARRAY['unesco', 'medieval']::text[]),
    ('palace-grand-master-rhodes', 'rhodes', 'MUSEUM', 2, 'HOURS', 4.7, 'Дворец Великих магистров Родоса', 'Palace of the Grand Master Rhodes', 'Родос Ұлы магистрлер сарайы', 36.44550000, 28.22490000, 'Palace of the Grand Master Rhodes Greece', ARRAY['rhodes']::text[], ARRAY['rhodes']::text[], 'Palace_of_the_Grand_Master_Rhodes.jpg', ARRAY['medieval', 'indoor']::text[]),
    ('lindos-acropolis', 'lindos', 'TEMPLE', 2, 'HOURS', 4.8, 'Акрополь Линдоса', 'Lindos Acropolis', 'Линдос Акрополі', 36.09190000, 28.08510000, 'Lindos Acropolis Rhodes Greece', ARRAY['lindos', 'rhodes']::text[], ARRAY['rhodes', 'lindos']::text[], 'Lindos_Acropolis_Rhodes.jpg', ARRAY['viewpoint', 'ancient-greece']::text[]),
    ('corfu-old-town', 'corfu', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Корфу', 'Corfu Old Town', 'Корфу ескі қаласы', 39.62400000, 19.92800000, 'Corfu Old Town Greece', ARRAY['corfu']::text[], ARRAY['corfu']::text[], 'Corfu_Old_Town.jpg', ARRAY['unesco', 'venetian']::text[]),
    ('achilleion-palace', 'corfu', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Ахиллион', 'Achilleion Palace', 'Ахиллион сарайы', 39.56280000, 19.90420000, 'Achilleion Palace Corfu Greece', ARRAY['corfu']::text[], ARRAY['corfu']::text[], 'Achilleion_Palace_Corfu.jpg', ARRAY['palace', 'garden']::text[]),
    ('paleokastritsa-beach', 'paleokastritsa', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Палеокастрица', 'Paleokastritsa Beach', 'Палеокастрица жағажайы', 39.67250000, 19.71040000, 'Paleokastritsa Beach Corfu Greece', ARRAY['paleokastritsa', 'corfu']::text[], ARRAY['corfu', 'paleokastritsa']::text[], 'Paleokastritsa_Beach_Corfu.jpg', ARRAY['ionian', 'summer']::text[]),
    ('navagio-beach', 'zakynthos', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Навагио', 'Navagio Beach', 'Навагио жағажайы', 37.85910000, 20.62420000, 'Navagio Beach Zakynthos Greece', ARRAY['zakynthos']::text[], ARRAY['zakynthos']::text[], 'Navagio_Beach_Zakynthos.jpg', ARRAY['viewpoint', 'shipwreck']::text[]),
    ('blue-caves-zakynthos', 'zakynthos', 'NATURE', 3, 'HOURS', 4.7, 'Голубые пещеры Закинфа', 'Blue Caves Zakynthos', 'Закинф көк үңгірлері', 37.93220000, 20.70410000, 'Blue Caves Zakynthos Greece', ARRAY['zakynthos']::text[], ARRAY['zakynthos']::text[], 'Blue_Caves_Zakynthos.jpg', ARRAY['boat-trip', 'caves']::text[]),
    ('naxos-portara', 'naxos', 'TEMPLE', 1, 'HOURS', 4.7, 'Портара на Наксосе', 'Naxos Portara', 'Наксос Портарасы', 37.10850000, 25.37280000, 'Naxos Portara Temple of Apollo Greece', ARRAY['naxos']::text[], ARRAY['naxos']::text[], 'Portara_Naxos.jpg', ARRAY['sunset', 'cyclades']::text[]),
    ('paros-naoussa', 'paros', 'FOOD', 2, 'HOURS', 4.6, 'Старый порт Наусы на Паросе', 'Paros Naoussa Old Port', 'Парос Науса ескі порты', 37.12330000, 25.23740000, 'Naoussa Old Port Paros Greece', ARRAY['paros']::text[], ARRAY['paros']::text[], 'Naoussa_Paros_Greece.jpg', ARRAY['waterfront', 'evening']::text[]),

    ('palamidi-fortress', 'nafplio', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Крепость Паламиди', 'Palamidi Fortress', 'Паламиди қамалы', 37.56560000, 22.80320000, 'Palamidi Fortress Nafplio Greece', ARRAY['nafplio']::text[], ARRAY['athens', 'nafplio']::text[], 'Palamidi_Fortress_Nafplio.jpg', ARRAY['fortress', 'viewpoint']::text[]),
    ('nafplio-old-town', 'nafplio', 'FOOD', 2, 'HOURS', 4.7, 'Старый город Нафплиона', 'Nafplio Old Town', 'Нафплион ескі қаласы', 37.56570000, 22.79790000, 'Nafplio Old Town Greece', ARRAY['nafplio']::text[], ARRAY['athens', 'nafplio']::text[], 'Nafplio_Old_Town.jpg', ARRAY['old-town', 'evening']::text[]),
    ('ancient-mycenae', 'mycenae', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Древние Микены', 'Ancient Mycenae', 'Ежелгі Микены', 37.73080000, 22.75490000, 'Ancient Mycenae Greece', ARRAY['mycenae']::text[], ARRAY['athens', 'nafplio', 'mycenae']::text[], 'Mycenae_Greece.jpg', ARRAY['unesco', 'ancient-greece']::text[]),
    ('ancient-theatre-of-epidaurus', 'epidaurus', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Античный театр Эпидавра', 'Ancient Theatre of Epidaurus', 'Эпидавр антикалық театры', 37.59640000, 23.07900000, 'Ancient Theatre of Epidaurus Greece', ARRAY['epidaurus']::text[], ARRAY['athens', 'nafplio', 'epidaurus']::text[], 'Epidaurus_Theatre_Greece.jpg', ARRAY['unesco', 'acoustics']::text[]),
    ('ancient-olympia', 'olympia', 'TEMPLE', 3, 'HOURS', 4.9, 'Древняя Олимпия', 'Ancient Olympia', 'Ежелгі Олимпия', 37.63790000, 21.63000000, 'Ancient Olympia Greece', ARRAY['olympia']::text[], ARRAY['athens', 'patras', 'olympia']::text[], 'Ancient_Olympia_Greece.jpg', ARRAY['unesco', 'olympic-history']::text[]),
    ('olympia-archaeological-museum', 'olympia', 'MUSEUM', 2, 'HOURS', 4.7, 'Археологический музей Олимпии', 'Olympia Archaeological Museum', 'Олимпия археология музейі', 37.64040000, 21.63090000, 'Olympia Archaeological Museum Greece', ARRAY['olympia']::text[], ARRAY['olympia']::text[], 'Olympia_Archaeological_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('patras-castle', 'patras', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Крепость Патр', 'Patras Castle', 'Патры қамалы', 38.24900000, 21.74260000, 'Patras Castle Greece', ARRAY['patras']::text[], ARRAY['patras']::text[], 'Patras_Castle_Greece.jpg', ARRAY['fortress']::text[]),
    ('patras-market-streets', 'patras', 'MARKET', 1, 'HOURS', 4.4, 'Маркато и улицы Рига Фереу в Патрах', 'Patras Markato and Riga Fereou Food Streets', 'Патры Маркато және Рига Фереу көшелері', 38.24600000, 21.73300000, 'Patras Markato Riga Fereou Greece', ARRAY['patras']::text[], ARRAY['patras']::text[], 'Patras_Greece.jpg', ARRAY['food-market', 'local-walk']::text[]),
    ('kalamata-old-town', 'kalamata', 'FOOD', 2, 'HOURS', 4.5, 'Исторический центр и старый рынок Каламаты', 'Kalamata Historic Centre and Old Market', 'Каламата тарихи орталығы және ескі базары', 37.03900000, 22.11200000, 'Kalamata Old Town Market Greece', ARRAY['kalamata']::text[], ARRAY['kalamata']::text[], 'Kalamata_Old_Town_Greece.jpg', ARRAY['old-town', 'market']::text[]),
    ('voidokilia-beach', 'kalamata', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Войдокилия', 'Voidokilia Beach', 'Войдокилия жағажайы', 36.96670000, 21.66330000, 'Voidokilia Beach Greece', ARRAY['kalamata']::text[], ARRAY['kalamata']::text[], 'Voidokilia_Beach_Greece.jpg', ARRAY['lagoon', 'summer']::text[]),
    ('monemvasia-castle-town', 'monemvasia', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Средневековый город-крепость Монемвасия', 'Monemvasia Castle Town', 'Монемвасия қамал қаласы', 36.68780000, 23.05680000, 'Monemvasia Castle Town Greece', ARRAY['monemvasia']::text[], ARRAY['kalamata', 'monemvasia']::text[], 'Monemvasia_Greece.jpg', ARRAY['castle-town', 'medieval']::text[]),
    ('mystras', 'mystras', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Мистра', 'Mystras', 'Мистра', 37.07450000, 22.37010000, 'Mystras Greece', ARRAY['mystras']::text[], ARRAY['kalamata', 'mystras']::text[], 'Mystras_Greece.jpg', ARRAY['unesco', 'byzantine']::text[]),
    ('mani-vathia-village', 'mani', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Башни деревни Ватия в Мани', 'Mani Vathia Village', 'Мани Ватия ауылы', 36.46250000, 22.46560000, 'Vathia Mani Greece', ARRAY['mani']::text[], ARRAY['kalamata', 'mani']::text[], 'Vathia_Mani_Greece.jpg', ARRAY['stone-towers', 'road-trip']::text[]),
    ('diros-caves', 'mani', 'NATURE', 2, 'HOURS', 4.7, 'Пещеры Дироса', 'Diros Caves', 'Дирос үңгірлері', 36.64150000, 22.38100000, 'Diros Caves Mani Greece', ARRAY['mani']::text[], ARRAY['kalamata', 'mani']::text[], 'Diros_Caves_Greece.jpg', ARRAY['caves', 'boat-trip']::text[]);

CREATE TEMP TABLE seed_greece_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-greece-attraction:' || seed.slug) AS attraction_hash,
        md5('id-greece-media:' || seed.slug) AS media_hash
    FROM seed_greece_priority_attractions seed
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
    ARRAY['greece', city_id, slug, lower(category), 'greece-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Греции: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Greece tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Грекия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'GR',
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
FROM seed_greece_resolved_attractions
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
FROM seed_greece_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_greece_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_greece_resolved_attractions
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
FROM seed_greece_resolved_attractions seed
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
FROM seed_greece_resolved_attractions
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
    'GR',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_greece_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'GR',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_greece_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_greece_resolved_attractions;
DROP TABLE IF EXISTS seed_greece_priority_attractions;
