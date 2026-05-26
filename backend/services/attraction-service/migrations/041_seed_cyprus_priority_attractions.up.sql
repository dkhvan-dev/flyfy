-- Priority Cyprus destination attractions seed.
-- Cyprus is seeded as one country destination with city-like tourist hubs
-- for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_cyprus_resolved_attractions;
DROP TABLE IF EXISTS seed_cyprus_priority_attractions;

CREATE TEMP TABLE seed_cyprus_priority_attractions (
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

INSERT INTO seed_cyprus_priority_attractions (
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
    ('cyprus-museum', 'nicosia', 'MUSEUM', 2, 'HOURS', 4.8, 'Кипрский музей', 'Cyprus Museum', 'Кипр музейі', 35.17190000, 33.35530000, 'Cyprus Museum Nicosia', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Nicosia_01-2017_img28_Cyprus_Museum.jpg'),
    ('ledra-street', 'nicosia', 'SHOPPING', 2, 'HOURS', 4.6, 'Улица Ледра', 'Ledra Street', 'Ледра көшесі', 35.17090000, 33.36120000, 'Ledra Street Nicosia Cyprus', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Ledra-street-nikosia.jpg'),
    ('leventis-museum-nicosia', 'nicosia', 'MUSEUM', 2, 'HOURS', 4.6, 'Муниципальный музей Левентиса', 'Leventis Municipal Museum of Nicosia', 'Левентис муниципалдық музейі', 35.17110000, 33.36210000, 'Leventis Municipal Museum Nicosia', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Nicosia_01-2017_img28_Cyprus_Museum.jpg'),
    ('laiki-geitonia', 'nicosia', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Квартал Лаики Гитония', 'Laiki Geitonia', 'Лаики Гитония кварталы', 35.17120000, 33.36250000, 'Laiki Geitonia Nicosia', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Ledra-street-nikosia.jpg'),
    ('shacolas-tower-observatory', 'nicosia', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Обсерватория башни Шаколас', 'Shacolas Tower Observatory', 'Шаколас мұнарасы көрініс алаңы', 35.17150000, 33.36120000, 'Shacolas Tower Observatory Nicosia', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Ledra-street-nikosia.jpg'),
    ('nicosia-municipal-market', 'nicosia', 'MARKET', 2, 'HOURS', 4.4, 'Муниципальный рынок Никосии', 'Nicosia Municipal Market', 'Никосия муниципалдық базары', 35.17210000, 33.36280000, 'Nicosia Municipal Market Cyprus', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Ledra-street-nikosia.jpg'),
    ('buyuk-han', 'nicosia', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Бюйюк-хан', 'Buyuk Han', 'Бүйүк-хан', 35.17630000, 33.36400000, 'Buyuk Han Nicosia Cyprus', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Nicosia_Buyuk_Han_02.jpg'),
    ('selimiye-mosque-nicosia', 'nicosia', 'TEMPLE', 1, 'HOURS', 4.6, 'Мечеть Селимие', 'Selimiye Mosque Nicosia', 'Селимие мешіті', 35.17690000, 33.36310000, 'Selimiye Mosque Nicosia Cyprus', ARRAY['nicosia']::text[], ARRAY['nicosia']::text[], 'Nicosia_Buyuk_Han_02.jpg'),

    ('limassol-marina', 'limassol', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Марина Лимасола', 'Limassol Marina', 'Лимасол маринасы', 34.66670000, 33.04000000, 'Limassol Marina Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('limassol-castle', 'limassol', 'MUSEUM', 2, 'HOURS', 4.7, 'Лимасольский замок', 'Limassol Castle', 'Лимасол қамалы', 34.67220000, 33.04160000, 'Limassol Castle Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'The_Medieval_Castle_of_Limassol.jpg'),
    ('molos-promenade', 'limassol', 'PARK', 2, 'HOURS', 4.6, 'Набережная Молос', 'Molos Promenade', 'Молос жағалауы', 34.67660000, 33.04980000, 'Molos Promenade Limassol Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('limassol-agora', 'limassol', 'MARKET', 2, 'HOURS', 4.5, 'Лимасольская агора', 'Limassol Agora', 'Лимасол агорасы', 34.67630000, 33.04280000, 'Limassol Agora Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('mymall-limassol', 'limassol', 'SHOPPING', 3, 'HOURS', 4.5, 'MYMALL Лимасол', 'MYMALL Limassol', 'MYMALL Лимасол', 34.65250000, 32.99670000, 'MYMALL Limassol Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('dasoudi-beach', 'limassol', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Дасуди', 'Dasoudi Beach', 'Дасуди жағажайы', 34.69260000, 33.08190000, 'Dasoudi Beach Limassol Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('fasouri-watermania', 'limassol', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Аквапарк Fasouri Watermania', 'Fasouri Watermania Waterpark', 'Fasouri Watermania аквапаркі', 34.64040000, 32.97020000, 'Fasouri Watermania Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'Limassol_01-2017_img20_Marina.jpg'),
    ('amathus-archaeological-site', 'limassol', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Археологический парк Аматус', 'Amathus Archaeological Site', 'Аматус археологиялық орны', 34.71390000, 33.14160000, 'Amathus Archaeological Site Limassol Cyprus', ARRAY['limassol']::text[], ARRAY['limassol']::text[], 'The_Medieval_Castle_of_Limassol.jpg'),
    ('kolossi-castle', 'limassol', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Замок Колосси', 'Kolossi Castle', 'Колосси қамалы', 34.66510000, 32.93410000, 'Kolossi Castle Cyprus', ARRAY['limassol', 'kourion']::text[], ARRAY['limassol']::text[], 'Theatre_Kourion_Cyprus.jpg'),

    ('foinikoudes-beach', 'larnaca', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Финикудес', 'Finikoudes Beach', 'Финикудес жағажайы', 34.91390000, 33.63840000, 'Finikoudes Beach Larnaca Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Finikoudes_Beach,_Larnaca.jpg'),
    ('church-saint-lazarus', 'larnaca', 'TEMPLE', 1, 'HOURS', 4.8, 'Церковь Святого Лазаря', 'Church of Saint Lazarus', 'Әулие Лазар шіркеуі', 34.91170000, 33.63540000, 'Church of Saint Lazarus Larnaca Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], '2022_03_Larnaca_Saint_Lazarus_Church.jpg'),
    ('larnaca-salt-lake', 'larnaca', 'NATURE', 2, 'HOURS', 4.7, 'Соленое озеро Ларнаки', 'Larnaca Salt Lake', 'Ларнака тұзды көлі', 34.89420000, 33.61140000, 'Larnaca Salt Lake Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Larnaca_01-2017_img31_Salt_Lake.jpg'),
    ('hala-sultan-tekke', 'larnaca', 'TEMPLE', 1, 'HOURS', 4.7, 'Хала Султан Текке', 'Hala Sultan Tekke', 'Хала Сұлтан Текке', 34.88530000, 33.61010000, 'Hala Sultan Tekke Larnaca Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Larnaca_01-2017_img31_Salt_Lake.jpg'),
    ('larnaca-medieval-castle', 'larnaca', 'MUSEUM', 1, 'HOURS', 4.5, 'Средневековый замок Ларнаки', 'Larnaca Medieval Castle', 'Ларнака ортағасырлық қамалы', 34.91030000, 33.63770000, 'Larnaca Medieval Castle Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Finikoudes_Beach,_Larnaca.jpg'),
    ('mackenzie-beach', 'larnaca', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Маккензи', 'Mackenzie Beach', 'Маккензи жағажайы', 34.89050000, 33.63810000, 'Mackenzie Beach Larnaca Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Mackenzie_by_Georgy_-_panoramio.jpg'),
    ('larnaca-municipal-market', 'larnaca', 'MARKET', 2, 'HOURS', 4.4, 'Муниципальный рынок Ларнаки', 'Larnaca Municipal Market', 'Ларнака муниципалдық базары', 34.91250000, 33.63610000, 'Larnaca Municipal Market Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Finikoudes_Beach,_Larnaca.jpg'),
    ('metropolis-mall-larnaca', 'larnaca', 'SHOPPING', 3, 'HOURS', 4.5, 'Metropolis Mall Ларнака', 'Metropolis Mall Larnaca', 'Metropolis Mall Ларнака', 34.92470000, 33.60480000, 'Metropolis Mall Larnaca Cyprus', ARRAY['larnaca']::text[], ARRAY['larnaca']::text[], 'Finikoudes_Beach,_Larnaca.jpg'),

    ('paphos-archaeological-park', 'paphos', 'MUSEUM', 3, 'HOURS', 4.9, 'Археологический парк Пафоса', 'Paphos Archaeological Park', 'Пафос археологиялық паркі', 34.75850000, 32.40770000, 'Paphos Archaeological Park Cyprus', ARRAY['paphos', 'coral-bay']::text[], ARRAY['paphos']::text[], 'Columns_in_Paphos_Archaeological_Park_2016_Nov_02_(0309).jpg'),
    ('tombs-of-the-kings', 'paphos', 'MUSEUM', 2, 'HOURS', 4.8, 'Царские гробницы', 'Tombs of the Kings', 'Патшалар қабірлері', 34.77590000, 32.40500000, 'Tombs of the Kings Paphos Cyprus', ARRAY['paphos', 'coral-bay']::text[], ARRAY['paphos']::text[], 'Tombs_of_the_Kings,_Paphos,_Cyprus.jpg'),
    ('kato-paphos-harbour', 'paphos', 'FOOD', 2, 'HOURS', 4.7, 'Гавань Като-Пафоса', 'Kato Paphos Harbour', 'Като-Пафос айлағы', 34.75640000, 32.41110000, 'Kato Paphos Harbour Cyprus', ARRAY['paphos']::text[], ARRAY['paphos']::text[], 'Paphos_Castle.jpg'),
    ('paphos-castle', 'paphos', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Пафосский замок', 'Paphos Castle', 'Пафос қамалы', 34.75370000, 32.40690000, 'Paphos Castle Cyprus', ARRAY['paphos']::text[], ARRAY['paphos']::text[], 'Paphos_Castle.jpg'),
    ('kings-avenue-mall', 'paphos', 'SHOPPING', 3, 'HOURS', 4.5, 'Kings Avenue Mall', 'Kings Avenue Mall', 'Kings Avenue Mall', 34.76710000, 32.41340000, 'Kings Avenue Mall Paphos Cyprus', ARRAY['paphos']::text[], ARRAY['paphos']::text[], 'Paphos_Castle.jpg'),
    ('paphos-aphrodite-waterpark', 'paphos', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Аквапарк Paphos Aphrodite', 'Paphos Aphrodite Waterpark', 'Paphos Aphrodite аквапаркі', 34.74450000, 32.43290000, 'Paphos Aphrodite Waterpark Cyprus', ARRAY['paphos']::text[], ARRAY['paphos']::text[], 'Paphos_Castle.jpg'),
    ('aphrodites-rock', 'paphos', 'NATURE', 1, 'HOURS', 4.8, 'Скала Афродиты', $$Aphrodite's Rock$$, 'Афродита жартасы', 34.66450000, 32.62790000, 'Aphrodites Rock Cyprus', ARRAY['paphos', 'limassol']::text[], ARRAY['paphos', 'limassol']::text[], 'Aphrodites-Rock-Cyprus.jpg'),
    ('paphos-old-town-market', 'paphos', 'MARKET', 2, 'HOURS', 4.4, 'Рынок старого города Пафоса', 'Paphos Old Town Market', 'Пафос ескі қала базары', 34.77560000, 32.42130000, 'Paphos Old Town Market Cyprus', ARRAY['paphos']::text[], ARRAY['paphos']::text[], 'Paphos_Castle.jpg'),

    ('nissi-beach', 'ayia-napa', 'BEACH', 4, 'HOURS', 4.9, 'Пляж Нисси', 'Nissi Beach', 'Нисси жағажайы', 34.98830000, 33.97120000, 'Nissi Beach Ayia Napa Cyprus', ARRAY['ayia-napa', 'protaras']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),
    ('makronissos-beach', 'ayia-napa', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Макронисос', 'Makronissos Beach', 'Макронисос жағажайы', 34.98280000, 33.95510000, 'Makronissos Beach Ayia Napa Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),
    ('cape-greco', 'ayia-napa', 'NATURE', 3, 'HOURS', 4.9, 'Кейп Греко', 'Cape Greco', 'Кейп Греко', 34.96500000, 34.07000000, 'Cape Greco Cyprus', ARRAY['ayia-napa', 'protaras']::text[], ARRAY['ayia-napa', 'protaras']::text[], 'Cyprus,_Cape_Greco_National_Forest_Park.jpg'),
    ('sea-caves-ayia-napa', 'ayia-napa', 'NATURE', 2, 'HOURS', 4.8, 'Морские пещеры Айя-Напы', 'Ayia Napa Sea Caves', 'Айя-Напа теңіз үңгірлері', 34.98520000, 34.06690000, 'Ayia Napa Sea Caves Cyprus', ARRAY['ayia-napa', 'protaras']::text[], ARRAY['ayia-napa']::text[], 'Cyprus,_Cape_Greco_National_Forest_Park.jpg'),
    ('love-bridge-ayia-napa', 'ayia-napa', 'NATURE', 1, 'HOURS', 4.7, 'Мост любви', 'Love Bridge Ayia Napa', 'Махаббат көпірі', 34.98250000, 34.01650000, 'Love Bridge Ayia Napa Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Cyprus,_Cape_Greco_National_Forest_Park.jpg'),
    ('ayia-napa-sculpture-park', 'ayia-napa', 'PARK', 2, 'HOURS', 4.6, 'Парк скульптур Айя-Напы', 'Ayia Napa Sculpture Park', 'Айя-Напа мүсіндер паркі', 34.98570000, 34.01700000, 'Ayia Napa Sculpture Park Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Cyprus,_Cape_Greco_National_Forest_Park.jpg'),
    ('ayia-napa-monastery', 'ayia-napa', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Айя-Напы', 'Ayia Napa Monastery', 'Айя-Напа монастыры', 34.98920000, 33.99970000, 'Ayia Napa Monastery Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),
    ('thalassa-museum', 'ayia-napa', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Thalassa', 'Thalassa Museum', 'Thalassa музейі', 34.98760000, 34.00210000, 'Thalassa Museum Ayia Napa Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),
    ('waterworld-ayia-napa', 'ayia-napa', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Аквапарк WaterWorld', 'WaterWorld Themed Waterpark', 'WaterWorld аквапаркі', 34.98530000, 33.94360000, 'WaterWorld Ayia Napa Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),
    ('parko-paliatso', 'ayia-napa', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Луна-парк Parko Paliatso', 'Parko Paliatso Luna Park', 'Parko Paliatso луна-паркі', 34.98560000, 33.99730000, 'Parko Paliatso Ayia Napa Cyprus', ARRAY['ayia-napa']::text[], ARRAY['ayia-napa']::text[], 'Agia_Napa_Nissi_Beach_1.jpg'),

    ('fig-tree-bay', 'protaras', 'BEACH', 4, 'HOURS', 4.9, 'Бухта Фигового дерева', 'Fig Tree Bay', 'Інжір ағашы шығанағы', 35.01260000, 34.05850000, 'Fig Tree Bay Protaras Cyprus', ARRAY['protaras', 'paralimni', 'ayia-napa']::text[], ARRAY['protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),
    ('konnos-bay', 'protaras', 'BEACH', 4, 'HOURS', 4.8, 'Бухта Коннос', 'Konnos Bay', 'Коннос шығанағы', 34.98280000, 34.06960000, 'Konnos Bay Cyprus', ARRAY['protaras', 'ayia-napa']::text[], ARRAY['protaras', 'ayia-napa']::text[], 'Cyprus,_Cape_Greco_National_Forest_Park.jpg'),
    ('kalamies-beach', 'paralimni', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Каламиес', 'Kalamies Beach', 'Каламиес жағажайы', 35.03670000, 34.03770000, 'Kalamies Beach Protaras Cyprus', ARRAY['protaras', 'paralimni']::text[], ARRAY['protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),
    ('profitis-elias-church', 'protaras', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Пророка Илии', 'Church of Profitis Elias', 'Ілияс пайғамбар шіркеуі', 35.01850000, 34.04120000, 'Church of Profitis Elias Protaras Cyprus', ARRAY['protaras', 'paralimni']::text[], ARRAY['protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),
    ('protaras-ocean-aquarium', 'paralimni', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Океанариум Протараса', 'Protaras Ocean Aquarium', 'Протарас океанариумы', 35.04760000, 34.01840000, 'Protaras Ocean Aquarium Cyprus', ARRAY['protaras', 'paralimni']::text[], ARRAY['protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),
    ('paralimni-open-market', 'paralimni', 'MARKET', 2, 'HOURS', 4.3, 'Открытый рынок Паралимни', 'Paralimni Open Market', 'Паралимни ашық базары', 35.03700000, 33.98300000, 'Paralimni Open Market Cyprus', ARRAY['paralimni', 'protaras']::text[], ARRAY['paralimni', 'protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),
    ('protaras-central-strip', 'protaras', 'FOOD', 2, 'HOURS', 4.4, 'Центральная улица Протараса', 'Protaras Central Strip', 'Протарас орталық көшесі', 35.01750000, 34.04820000, 'Protaras Central Strip Cyprus', ARRAY['protaras']::text[], ARRAY['protaras']::text[], 'Fig_Tree_Bay,_Cyprus_(41914176930).jpg'),

    ('famagusta-walled-city', 'famagusta', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Фамагусты', 'Famagusta Walled City', 'Фамагуста қабырғалы қаласы', 35.12490000, 33.94140000, 'Famagusta Walled City Cyprus', ARRAY['famagusta', 'ayia-napa', 'protaras']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),
    ('othello-castle', 'famagusta', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Отелло', 'Othello Castle', 'Отелло қамалы', 35.12770000, 33.94360000, 'Othello Castle Famagusta Cyprus', ARRAY['famagusta']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),
    ('lala-mustafa-pasha-mosque', 'famagusta', 'TEMPLE', 1, 'HOURS', 4.7, 'Мечеть Лала Мустафа-паши', 'Lala Mustafa Pasha Mosque', 'Лала Мұстафа паша мешіті', 35.12490000, 33.94270000, 'Lala Mustafa Pasha Mosque Famagusta Cyprus', ARRAY['famagusta']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),
    ('ancient-salamis', 'famagusta', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Древний Саламин', 'Ancient Salamis', 'Ежелгі Саламин', 35.18710000, 33.90370000, 'Ancient Salamis Cyprus', ARRAY['famagusta']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),
    ('saint-barnabas-monastery', 'famagusta', 'TEMPLE', 2, 'HOURS', 4.6, 'Монастырь Святого Варнавы', 'Monastery of Saint Barnabas', 'Әулие Варнава монастыры', 35.17450000, 33.88090000, 'Monastery of Saint Barnabas Cyprus', ARRAY['famagusta']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),
    ('city-mall-famagusta', 'famagusta', 'SHOPPING', 2, 'HOURS', 4.3, 'City Mall Фамагуста', 'City Mall Famagusta', 'City Mall Фамагуста', 35.12590000, 33.92080000, 'City Mall Famagusta Cyprus', ARRAY['famagusta']::text[], ARRAY['famagusta']::text[], 'Famagusta_01-2017_img04_city_walls.jpg'),

    ('kyrenia-harbour', 'kyrenia', 'FOOD', 2, 'HOURS', 4.8, 'Гавань Кирении', 'Kyrenia Harbour', 'Кирения айлағы', 35.34180000, 33.31970000, 'Kyrenia Harbour Cyprus', ARRAY['kyrenia']::text[], ARRAY['kyrenia']::text[], 'Kyrenia_Harbour_1.JPG'),
    ('kyrenia-castle', 'kyrenia', 'MUSEUM', 2, 'HOURS', 4.7, 'Киренийский замок', 'Kyrenia Castle', 'Кирения қамалы', 35.34190000, 33.32100000, 'Kyrenia Castle Cyprus', ARRAY['kyrenia']::text[], ARRAY['kyrenia']::text[], 'Kyrenia_Harbour_1.JPG'),
    ('bellapais-abbey', 'kyrenia', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Аббатство Беллапаис', 'Bellapais Abbey', 'Беллапаис аббаттығы', 35.30770000, 33.35480000, 'Bellapais Abbey Cyprus', ARRAY['kyrenia']::text[], ARRAY['kyrenia']::text[], 'Bellapais_Abbey_Cyprus.jpg'),
    ('alagadi-turtle-beach', 'kyrenia', 'BEACH', 3, 'HOURS', 4.5, 'Черепаший пляж Алагади', 'Alagadi Turtle Beach', 'Алагади тасбақа жағажайы', 35.33450000, 33.50560000, 'Alagadi Turtle Beach Cyprus', ARRAY['kyrenia']::text[], ARRAY['kyrenia']::text[], 'Kyrenia_Harbour_1.JPG'),

    ('troodos-mountains', 'troodos', 'NATURE', 4, 'HOURS', 4.9, 'Горы Троодос', 'Troodos Mountains', 'Троодос таулары', 34.93320000, 32.87200000, 'Troodos Mountains Cyprus', ARRAY['troodos', 'platres', 'kakopetria', 'agros']::text[], ARRAY['troodos', 'limassol']::text[], 'Troodos_mountains.jpg'),
    ('artemis-trail', 'troodos', 'NATURE', 3, 'HOURS', 4.7, 'Тропа Артемис', 'Artemis Trail', 'Артемис соқпағы', 34.93320000, 32.87200000, 'Artemis Trail Troodos Cyprus', ARRAY['troodos']::text[], ARRAY['troodos']::text[], 'Troodos_mountains.jpg'),
    ('kykkos-monastery', 'troodos', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Киккос', 'Kykkos Monastery', 'Киккос монастыры', 34.98350000, 32.74100000, 'Kykkos Monastery Cyprus', ARRAY['troodos', 'kakopetria', 'platres']::text[], ARRAY['troodos']::text[], 'Kykkos.jpg'),
    ('troodos-geopark-visitor-centre', 'troodos', 'MUSEUM', 2, 'HOURS', 4.5, 'Визит-центр геопарка Троодос', 'Troodos Geopark Visitor Centre', 'Троодос геопаркі визит-орталығы', 34.93070000, 32.92740000, 'Troodos Geopark Visitor Centre Cyprus', ARRAY['troodos', 'platres']::text[], ARRAY['troodos']::text[], 'Troodos_mountains.jpg'),
    ('caledonia-waterfall', 'platres', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Каледония', 'Caledonia Waterfall Trail', 'Каледония сарқырамасы', 34.90270000, 32.87060000, 'Caledonia Waterfall Platres Cyprus', ARRAY['platres', 'troodos']::text[], ARRAY['platres', 'troodos']::text[], 'Troodos_mountains.jpg'),
    ('sparti-platres-rope-park', 'platres', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Веревочный парк Sparti Platres', 'Sparti Platres Rope Adventure Park', 'Sparti Platres арқан паркі', 34.88780000, 32.86450000, 'Sparti Platres Rope Adventure Park Cyprus', ARRAY['platres']::text[], ARRAY['platres']::text[], 'Troodos_mountains.jpg'),
    ('trooditissa-monastery', 'platres', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Троодитисса', 'Trooditissa Monastery', 'Троодитисса монастыры', 34.91290000, 32.83820000, 'Trooditissa Monastery Cyprus', ARRAY['platres', 'troodos']::text[], ARRAY['platres']::text[], 'Kykkos.jpg'),
    ('omodos-village', 'omodos', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Деревня Омодос', 'Omodos Village', 'Омодос ауылы', 34.84930000, 32.80990000, 'Omodos Village Cyprus', ARRAY['omodos', 'platres', 'limassol']::text[], ARRAY['omodos', 'limassol']::text[], 'Troodos_mountains.jpg'),
    ('holy-cross-monastery-omodos', 'omodos', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Святого Креста', 'Monastery of the Holy Cross Omodos', 'Омодостағы Қасиетті Крест монастыры', 34.84940000, 32.81010000, 'Monastery of the Holy Cross Omodos Cyprus', ARRAY['omodos']::text[], ARRAY['omodos']::text[], 'Kykkos.jpg'),
    ('old-kakopetria', 'kakopetria', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старая Какопетрия', 'Old Kakopetria', 'Ескі Какопетрия', 34.98880000, 32.90420000, 'Old Kakopetria Cyprus', ARRAY['kakopetria', 'troodos']::text[], ARRAY['kakopetria']::text[], 'Troodos_mountains.jpg'),
    ('agios-nikolaos-tis-stegis', 'kakopetria', 'TEMPLE', 1, 'HOURS', 4.8, 'Церковь Святого Николая под Крышей', 'Agios Nikolaos tis Stegis Church', 'Агиос Николаос тис Стегис шіркеуі', 34.97730000, 32.88950000, 'Agios Nikolaos tis Stegis Church Cyprus', ARRAY['kakopetria', 'troodos']::text[], ARRAY['kakopetria']::text[], 'Kykkos.jpg'),
    ('tsolakis-rose-factory', 'agros', 'FOOD', 1, 'HOURS', 4.5, 'Розовая фабрика Tsolakis', 'Tsolakis Rose Factory', 'Tsolakis раушан фабрикасы', 34.91800000, 33.01740000, 'Tsolakis Rose Factory Agros Cyprus', ARRAY['agros', 'troodos']::text[], ARRAY['agros']::text[], 'Troodos_mountains.jpg'),

    ('choirokoitia', 'choirokoitia', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Хирокития', 'Choirokoitia', 'Хирокития', 34.79700000, 33.34300000, 'Choirokoitia Cyprus', ARRAY['choirokoitia', 'larnaca', 'limassol']::text[], ARRAY['choirokoitia', 'larnaca']::text[], 'Choirokoitia,_Cyprus_-_panoramio.jpg'),
    ('kourion-archaeological-site', 'kourion', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Археологический парк Курион', 'Kourion Archaeological Site', 'Курион археологиялық орны', 34.66460000, 32.88870000, 'Kourion Archaeological Site Cyprus', ARRAY['kourion', 'limassol']::text[], ARRAY['kourion', 'limassol']::text[], 'Theatre_Kourion_Cyprus.jpg'),
    ('kourion-beach', 'kourion', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Курион', 'Kourion Beach', 'Курион жағажайы', 34.66310000, 32.88260000, 'Kourion Beach Cyprus', ARRAY['kourion', 'limassol']::text[], ARRAY['kourion']::text[], 'Theatre_Kourion_Cyprus.jpg'),
    ('sanctuary-apollon-hylates', 'kourion', 'TEMPLE', 1, 'HOURS', 4.6, 'Святилище Аполлона Хилата', 'Sanctuary of Apollon Hylates', 'Аполлон Хилат ғибадатханасы', 34.67310000, 32.86370000, 'Sanctuary of Apollon Hylates Cyprus', ARRAY['kourion', 'limassol']::text[], ARRAY['kourion']::text[], 'Theatre_Kourion_Cyprus.jpg'),
    ('coral-bay', 'coral-bay', 'BEACH', 4, 'HOURS', 4.7, 'Корал-Бэй', 'Coral Bay', 'Корал-Бэй', 34.85470000, 32.36970000, 'Coral Bay Cyprus', ARRAY['coral-bay', 'paphos', 'peyia']::text[], ARRAY['coral-bay', 'paphos']::text[], 'Coral_Bay,_Cyprus.jpg'),
    ('avakas-gorge', 'peyia', 'NATURE', 3, 'HOURS', 4.8, 'Ущелье Авакас', 'Avakas Gorge', 'Авакас шатқалы', 34.91920000, 32.33380000, 'Avakas Gorge Cyprus', ARRAY['peyia', 'coral-bay', 'paphos']::text[], ARRAY['peyia', 'paphos']::text[], 'Pegeia,_Cyprus,_Avakas_Gorge,_limestone.jpg'),
    ('lara-beach', 'peyia', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Лара', 'Lara Beach', 'Лара жағажайы', 34.95650000, 32.31030000, 'Lara Beach Akamas Cyprus', ARRAY['peyia', 'coral-bay']::text[], ARRAY['peyia']::text[], 'Coral_Bay,_Cyprus.jpg'),
    ('latchi-harbour', 'latchi', 'FOOD', 2, 'HOURS', 4.6, 'Гавань Лачи', 'Latchi Harbour', 'Лачи айлағы', 35.04040000, 32.39160000, 'Latchi Harbour Cyprus', ARRAY['latchi', 'polis']::text[], ARRAY['latchi', 'polis']::text[], 'Coral_Bay,_Cyprus.jpg'),
    ('baths-of-aphrodite', 'polis', 'NATURE', 2, 'HOURS', 4.6, 'Купальня Афродиты', 'Baths of Aphrodite', 'Афродита моншалары', 35.05640000, 32.34600000, 'Baths of Aphrodite Cyprus', ARRAY['polis', 'latchi']::text[], ARRAY['polis', 'latchi']::text[], 'Aphrodites-Rock-Cyprus.jpg'),
    ('polis-camping-beach', 'polis', 'BEACH', 3, 'HOURS', 4.4, 'Муниципальный пляж Полиса', 'Polis Municipal Beach', 'Полис муниципалдық жағажайы', 35.04300000, 32.42300000, 'Polis Municipal Beach Cyprus', ARRAY['polis', 'latchi']::text[], ARRAY['polis']::text[], 'Coral_Bay,_Cyprus.jpg');

CREATE TEMP TABLE seed_cyprus_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-cyprus-attraction:' || seed.slug) AS attraction_hash,
        md5('id-cyprus-media:' || seed.slug) AS media_hash
    FROM seed_cyprus_priority_attractions seed
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
    ARRAY['cyprus', city_id, slug, lower(category), 'cyprus-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Кипра: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Cyprus tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Кипр туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'CY',
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
FROM seed_cyprus_resolved_attractions
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
FROM seed_cyprus_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_cyprus_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_cyprus_resolved_attractions
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
FROM seed_cyprus_resolved_attractions seed
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
FROM seed_cyprus_resolved_attractions
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
    'CY',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_cyprus_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'CY',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_cyprus_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_cyprus_resolved_attractions;
DROP TABLE IF EXISTS seed_cyprus_priority_attractions;
