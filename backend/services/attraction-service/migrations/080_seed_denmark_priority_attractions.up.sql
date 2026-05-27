-- Priority Denmark destination attractions seed.
-- Denmark is seeded by major tourist anchors so admin/mobile filters remain city-based and readable.

DROP TABLE IF EXISTS seed_denmark_resolved_attractions;
DROP TABLE IF EXISTS seed_denmark_priority_attractions;

CREATE TEMP TABLE seed_denmark_priority_attractions (
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

INSERT INTO seed_denmark_priority_attractions (
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
    ('tivoli-gardens', 'copenhagen', 'ENTERTAINMENT', 4, 4.8, 'Сады Тиволи', 'Tivoli Gardens', 'Тиволи бақтары', 55.67360000, 12.56830000, 'Tivoli_Gardens,_Copenhagen,_Denmark.jpg', ARRAY['copenhagen', 'amusement-park', 'family']::text[]),
    ('nyhavn', 'copenhagen', 'ARCHITECTURE', 2, 4.8, 'Нюхавн', 'Nyhavn', 'Нюхавн', 55.67970000, 12.59110000, 'Nyhavn_Copenhagen.jpg', ARRAY['copenhagen', 'waterfront', 'canal']::text[]),
    ('little-mermaid', 'copenhagen', 'ARCHITECTURE', 1, 4.5, 'Русалочка', 'The Little Mermaid', 'Кішкентай су перісі', 55.69290000, 12.59930000, 'Visiting_the_Little_Mermaid.JPG', ARRAY['copenhagen', 'statue', 'harbour']::text[]),
    ('amalienborg-palace', 'copenhagen', 'ARCHITECTURE', 2, 4.7, 'Дворец Амалиенборг', 'Amalienborg Palace', 'Амалиенборг сарайы', 55.68400000, 12.59300000, 'Amalienborg_Palace_-_Copenhagen_-_Denmark.jpg', ARRAY['copenhagen', 'royal', 'palace']::text[]),
    ('christiansborg-palace', 'copenhagen', 'ARCHITECTURE', 2, 4.7, 'Дворец Кристиансборг', 'Christiansborg Palace', 'Кристиансборг сарайы', 55.67630000, 12.58080000, 'Christiansborg,_Copenhagen.jpg', ARRAY['copenhagen', 'palace', 'parliament']::text[]),
    ('rosenborg-castle', 'copenhagen', 'MUSEUM', 2, 4.7, 'Замок Розенборг', 'Rosenborg Castle', 'Розенборг қамалы', 55.68580000, 12.57760000, 'Rosenborg_Castle_01.jpg', ARRAY['copenhagen', 'castle', 'crown-jewels']::text[]),
    ('round-tower-copenhagen', 'copenhagen', 'ARCHITECTURE', 1, 4.6, 'Круглая башня', 'The Round Tower', 'Дөңгелек мұнара', 55.68140000, 12.57580000, 'Rundetaarn_Copenhagen.jpg', ARRAY['copenhagen', 'viewpoint', 'observatory']::text[]),
    ('church-of-our-saviour', 'copenhagen', 'TEMPLE', 1, 4.7, 'Церковь Спасителя', 'Church of Our Saviour', 'Құтқарушы шіркеуі', 55.67220000, 12.59370000, 'Church_of_Our_Saviour_Copenhagen.jpg', ARRAY['copenhagen', 'church', 'viewpoint']::text[]),
    ('national-museum-denmark', 'copenhagen', 'MUSEUM', 3, 4.7, 'Национальный музей Дании', 'The National Museum of Denmark', 'Дания ұлттық музейі', 55.67450000, 12.57480000, 'National_Museum_of_Denmark_Copenhagen.jpg', ARRAY['copenhagen', 'history', 'vikings']::text[]),
    ('smk-national-gallery-denmark', 'copenhagen', 'MUSEUM', 3, 4.7, 'Государственный музей искусств Дании', 'SMK - National Gallery of Denmark', 'Дания ұлттық галереясы', 55.68880000, 12.57730000, 'Statens_Museum_for_Kunst_Copenhagen.jpg', ARRAY['copenhagen', 'art', 'gallery']::text[]),
    ('glyptoteket', 'copenhagen', 'MUSEUM', 2, 4.7, 'Новая глиптотека Карлсберга', 'Glyptoteket', 'Глиптотека', 55.67240000, 12.57250000, 'Ny_Carlsberg_Glyptotek_Copenhagen.jpg', ARRAY['copenhagen', 'art', 'sculpture']::text[]),
    ('designmuseum-danmark', 'copenhagen', 'MUSEUM', 2, 4.6, 'Датский музей дизайна', 'Designmuseum Danmark', 'Дания дизайн музейі', 55.68550000, 12.59090000, 'Designmuseum_Danmark_Copenhagen.jpg', ARRAY['copenhagen', 'design', 'museum']::text[]),
    ('danish-architecture-center', 'copenhagen', 'MUSEUM', 2, 4.5, 'Датский архитектурный центр', 'Danish Architecture Center', 'Дания сәулет орталығы', 55.67270000, 12.57990000, 'Danish_Architecture_Center_BLOX.jpg', ARRAY['copenhagen', 'architecture', 'exhibitions']::text[]),
    ('copenhagen-contemporary', 'copenhagen', 'MUSEUM', 2, 4.5, 'Copenhagen Contemporary', 'Copenhagen Contemporary', 'Copenhagen Contemporary', 55.68610000, 12.60990000, 'Copenhagen_Contemporary.jpg', ARRAY['copenhagen', 'contemporary-art', 'refshaleoen']::text[]),
    ('botanical-garden-copenhagen', 'copenhagen', 'PARK', 2, 4.7, 'Ботанический сад Копенгагена', 'The Botanical Garden', 'Копенгаген ботаникалық бағы', 55.68620000, 12.57330000, 'Botanical_Garden_Copenhagen.jpg', ARRAY['copenhagen', 'garden', 'palm-house']::text[]),
    ('kings-garden-copenhagen', 'copenhagen', 'PARK', 1, 4.6, 'Королевский сад', 'The King''s Garden', 'Патша бағы', 55.68520000, 12.58020000, 'Kings_Garden_Copenhagen.jpg', ARRAY['copenhagen', 'park', 'rosenborg']::text[]),
    ('frederiksberg-gardens', 'copenhagen', 'PARK', 2, 4.7, 'Сады Фредериксберг', 'Frederiksberg Gardens', 'Фредериксберг бақтары', 55.67270000, 12.52360000, 'Frederiksberg_Gardens_Copenhagen.jpg', ARRAY['copenhagen', 'park', 'royal-garden']::text[]),
    ('superkilen-park', 'copenhagen', 'PARK', 1, 4.4, 'Парк Суперкилен', 'Superkilen Park', 'Суперкилен саябағы', 55.69920000, 12.54250000, 'Superkilen_Copenhagen.jpg', ARRAY['copenhagen', 'urban-design', 'norrebro']::text[]),
    ('amager-beach-park', 'copenhagen', 'BEACH', 3, 4.6, 'Пляжный парк Амагер', 'Amager Beach Park', 'Амагер жағажай саябағы', 55.65400000, 12.63800000, 'Amager_Beach_Park_Copenhagen.jpg', ARRAY['copenhagen', 'beach', 'swimming']::text[]),
    ('islands-brygge-harbour-bath', 'copenhagen', 'BEACH', 2, 4.5, 'Купальня Islands Brygge', 'Islands Brygge Harbour Bath', 'Islands Brygge айлақ купальнясы', 55.66620000, 12.57770000, 'Islands_Brygge_Harbour_Bath.jpg', ARRAY['copenhagen', 'harbour-bath', 'summer']::text[]),
    ('royal-danish-opera-house', 'copenhagen', 'ARCHITECTURE', 1, 4.6, 'Королевская опера Дании', 'The Royal Danish Opera House', 'Дания корольдік операсы', 55.68200000, 12.60060000, 'Copenhagen_Opera_House.jpg', ARRAY['copenhagen', 'opera', 'harbour']::text[]),
    ('copenhagen-zoo', 'copenhagen', 'ENTERTAINMENT', 3, 4.6, 'Копенгагенский зоопарк', 'Copenhagen Zoo', 'Копенгаген зообағы', 55.67220000, 12.52100000, 'Copenhagen_Zoo.jpg', ARRAY['copenhagen', 'zoo', 'family']::text[]),
    ('den-bla-planet', 'copenhagen', 'ENTERTAINMENT', 3, 4.6, 'Национальный аквариум Den Bla Planet', 'Den Bla Planet', 'Den Bla Planet', 55.63860000, 12.65780000, 'Den_Bla_Planet_Copenhagen.jpg', ARRAY['copenhagen', 'aquarium', 'family']::text[]),
    ('copenhill', 'copenhagen', 'ENTERTAINMENT', 2, 4.5, 'CopenHill', 'CopenHill', 'CopenHill', 55.68420000, 12.62040000, 'CopenHill_Copenhagen.jpg', ARRAY['copenhagen', 'ski-slope', 'viewpoint']::text[]),
    ('bakken', 'copenhagen', 'ENTERTAINMENT', 4, 4.6, 'Bakken', 'Bakken', 'Bakken', 55.77550000, 12.57400000, 'Dyrehavsbakken_Bakken.jpg', ARRAY['copenhagen', 'amusement-park', 'dyrehaven']::text[]),
    ('torvehallerne-kbh', 'copenhagen', 'MARKET', 1, 4.7, 'TorvehallerneKBH', 'TorvehallerneKBH', 'TorvehallerneKBH', 55.68320000, 12.57160000, 'Torvehallerne_Copenhagen.jpg', ARRAY['copenhagen', 'food-hall', 'market']::text[]),
    ('reffen-copenhagen-street-food', 'copenhagen', 'FOOD', 2, 4.6, 'Reffen - Copenhagen Street Food', 'Reffen - Copenhagen Street Food', 'Reffen - Copenhagen Street Food', 55.69290000, 12.61330000, 'Reffen_Copenhagen_Street_Food.jpg', ARRAY['copenhagen', 'street-food', 'waterfront']::text[]),
    ('broens-street-food', 'copenhagen', 'FOOD', 1, 4.5, 'Broens Street Food', 'Broens Street Food', 'Broens Street Food', 55.67790000, 12.59350000, 'Broens_Street_Food_Copenhagen.jpg', ARRAY['copenhagen', 'street-food', 'harbour']::text[]),
    ('kodbyen-meatpacking-district', 'copenhagen', 'FOOD', 2, 4.5, 'Мясной квартал Кёдбюэн', 'The Meatpacking District', 'Кёдбюэн ет кварталы', 55.66850000, 12.56030000, 'Kodbyen_Copenhagen.jpg', ARRAY['copenhagen', 'restaurants', 'nightlife']::text[]),
    ('stroget', 'copenhagen', 'SHOPPING', 2, 4.6, 'Стрёгет', 'Stroget', 'Стрёгет', 55.67850000, 12.57490000, 'Stroget_Copenhagen.jpg', ARRAY['copenhagen', 'shopping-street', 'pedestrian']::text[]),
    ('fisketorvet-copenhagen-mall', 'copenhagen', 'SHOPPING', 2, 4.4, 'Торговый центр Fisketorvet', 'Fisketorvet - Copenhagen Mall', 'Fisketorvet сауда орталығы', 55.66170000, 12.56160000, 'Fisketorvet_Copenhagen_Mall.jpg', ARRAY['copenhagen', 'mall', 'cinema']::text[]),

    ('aros-aarhus-art-museum', 'aarhus', 'MUSEUM', 3, 4.8, 'Художественный музей ARoS Aarhus', 'ARoS Aarhus Art Museum', 'ARoS Aarhus өнер музейі', 56.15390000, 10.19940000, 'ARoS_2108-0955.jpg', ARRAY['aarhus', 'art', 'rainbow-panorama']::text[]),
    ('den-gamle-by', 'aarhus', 'MUSEUM', 3, 4.8, 'Старый город Den Gamle By', 'Den Gamle By', 'Den Gamle By', 56.15940000, 10.19100000, 'Den_Gamle_By_Aarhus.jpg', ARRAY['aarhus', 'open-air-museum', 'history']::text[]),
    ('moesgaard-museum', 'aarhus', 'MUSEUM', 3, 4.8, 'Музей Moesgaard', 'Moesgaard Museum', 'Moesgaard музейі', 56.08680000, 10.22360000, 'Moesgaard_Museum_Aarhus.jpg', ARRAY['aarhus', 'vikings', 'archaeology']::text[]),
    ('aarhus-cathedral', 'aarhus', 'TEMPLE', 1, 4.6, 'Орхусский собор', 'Aarhus Cathedral', 'Орхус соборы', 56.15780000, 10.21070000, 'Aarhus_Cathedral.jpg', ARRAY['aarhus', 'church', 'old-town']::text[]),
    ('dokk1', 'aarhus', 'ARCHITECTURE', 1, 4.6, 'Dokk1', 'Dokk1', 'Dokk1', 56.15350000, 10.21370000, 'Dokk1_Aarhus.jpg', ARRAY['aarhus', 'waterfront', 'library']::text[]),
    ('tivoli-friheden', 'aarhus', 'ENTERTAINMENT', 4, 4.5, 'Tivoli Friheden', 'Tivoli Friheden', 'Tivoli Friheden', 56.13790000, 10.19640000, 'Tivoli_Friheden_Aarhus.jpg', ARRAY['aarhus', 'amusement-park', 'family']::text[]),
    ('marselisborg-deer-park', 'aarhus', 'PARK', 2, 4.6, 'Олений парк Марселисборг', 'Marselisborg Deer Park', 'Марселисборг бұғы саябағы', 56.11930000, 10.21440000, 'Marselisborg_Deer_Park_Aarhus.jpg', ARRAY['aarhus', 'park', 'family']::text[]),
    ('aarhus-botanical-garden', 'aarhus', 'PARK', 2, 4.6, 'Ботанический сад Орхуса', 'Aarhus Botanical Garden', 'Орхус ботаникалық бағы', 56.16060000, 10.19070000, 'Aarhus_Botanical_Garden.jpg', ARRAY['aarhus', 'garden', 'greenhouses']::text[]),
    ('aarhus-street-food', 'aarhus', 'FOOD', 1, 4.6, 'Aarhus Street Food', 'Aarhus Street Food', 'Aarhus Street Food', 56.15170000, 10.20360000, 'Aarhus_Street_Food.jpg', ARRAY['aarhus', 'street-food', 'food-hall']::text[]),
    ('bruns-galleri', 'aarhus', 'SHOPPING', 2, 4.4, 'Bruuns Galleri', 'Bruuns Galleri', 'Bruuns Galleri', 56.14940000, 10.20340000, 'Bruuns_Galleri_Aarhus.jpg', ARRAY['aarhus', 'mall', 'shopping']::text[]),
    ('salling-rooftop-aarhus', 'aarhus', 'ENTERTAINMENT', 1, 4.5, 'Salling Rooftop Aarhus', 'Salling Rooftop Aarhus', 'Salling Rooftop Aarhus', 56.15660000, 10.20750000, 'Salling_Rooftop_Aarhus.jpg', ARRAY['aarhus', 'viewpoint', 'shopping']::text[]),

    ('hc-andersen-house', 'odense', 'MUSEUM', 2, 4.7, 'Дом Ханса Кристиана Андерсена', 'H. C. Andersen House', 'Ханс Кристиан Андерсен үйі', 55.39770000, 10.38990000, 'H_C_Andersen_House_Odense.jpg', ARRAY['odense', 'andersen', 'museum']::text[]),
    ('funen-village', 'odense', 'MUSEUM', 3, 4.6, 'Фюнская деревня', 'The Funen Village', 'Фюн ауылы', 55.36370000, 10.38570000, 'The_Funen_Village_Odense.jpg', ARRAY['odense', 'open-air-museum', 'history']::text[]),
    ('odense-zoo', 'odense', 'ENTERTAINMENT', 3, 4.6, 'Зоопарк Оденсе', 'Odense Zoo', 'Оденсе зообағы', 55.37790000, 10.36000000, 'Odense_Zoo.jpg', ARRAY['odense', 'zoo', 'family']::text[]),
    ('brandts-odense', 'odense', 'MUSEUM', 2, 4.5, 'Музей Brandts', 'Brandts', 'Brandts', 55.39730000, 10.38190000, 'Brandts_Museum_Odense.jpg', ARRAY['odense', 'art', 'photography']::text[]),
    ('danmarks-jernbanemuseum', 'odense', 'MUSEUM', 2, 4.6, 'Датский железнодорожный музей', 'Danish Railway Museum', 'Дания теміржол музейі', 55.40350000, 10.38570000, 'Danish_Railway_Museum_Odense.jpg', ARRAY['odense', 'railway', 'family']::text[]),
    ('munke-mose', 'odense', 'PARK', 1, 4.5, 'Парк Munke Mose', 'Munke Mose', 'Munke Mose', 55.39150000, 10.37760000, 'Munke_Mose_Odense.jpg', ARRAY['odense', 'park', 'river']::text[]),
    ('storms-pakhus', 'odense', 'FOOD', 1, 4.6, 'Storms Pakhus', 'Storms Pakhus', 'Storms Pakhus', 55.39950000, 10.37770000, 'Storms_Pakhus_Odense.jpg', ARRAY['odense', 'street-food', 'food-hall']::text[]),
    ('rosengardcentret', 'odense', 'SHOPPING', 2, 4.3, 'Rosengardcentret', 'Rosengardcentret', 'Rosengardcentret', 55.38420000, 10.42530000, 'Rosengardcentret_Odense.jpg', ARRAY['odense', 'mall', 'shopping']::text[]),
    ('egeskov-castle', 'odense', 'ARCHITECTURE', 4, 4.8, 'Замок Эгесков', 'Egeskov Castle', 'Эгесков қамалы', 55.17630000, 10.49090000, 'Egeskov_Castle_Denmark.jpg', ARRAY['funen', 'castle', 'garden']::text[]),

    ('aalborg-zoo', 'aalborg', 'ENTERTAINMENT', 3, 4.5, 'Зоопарк Ольборга', 'Aalborg Zoo', 'Ольборг зообағы', 57.03640000, 9.89850000, 'Aalborg_Zoo.jpg', ARRAY['aalborg', 'zoo', 'family']::text[]),
    ('utzon-center', 'aalborg', 'MUSEUM', 2, 4.5, 'Центр Утзона', 'Utzon Center', 'Утзон орталығы', 57.04950000, 9.92610000, 'Utzon_Center_Aalborg.jpg', ARRAY['aalborg', 'architecture', 'design']::text[]),
    ('kunsten-museum-modern-art-aalborg', 'aalborg', 'MUSEUM', 2, 4.6, 'Музей современного искусства Kunsten', 'Kunsten Museum of Modern Art Aalborg', 'Kunsten заманауи өнер музейі', 57.04410000, 9.89910000, 'Kunsten_Aalborg.jpg', ARRAY['aalborg', 'modern-art', 'museum']::text[]),
    ('lindholm-hoje', 'aalborg', 'MUSEUM', 2, 4.6, 'Линдхольм Хёйе', 'Lindholm Hoje', 'Линдхольм Хёйе', 57.07830000, 9.91290000, 'Lindholm_Hoje.jpg', ARRAY['aalborg', 'vikings', 'archaeology']::text[]),
    ('aalborg-waterfront', 'aalborg', 'PARK', 1, 4.5, 'Набережная Ольборга', 'Aalborg Waterfront', 'Ольборг жағалауы', 57.04990000, 9.92040000, 'Aalborg_Waterfront.jpg', ARRAY['aalborg', 'waterfront', 'walk']::text[]),
    ('jomfru-ane-gade', 'aalborg', 'ENTERTAINMENT', 2, 4.4, 'Jomfru Ane Gade', 'Jomfru Ane Gade', 'Jomfru Ane Gade', 57.04820000, 9.91930000, 'Jomfru_Ane_Gade_Aalborg.jpg', ARRAY['aalborg', 'nightlife', 'street']::text[]),
    ('aalborg-street-food', 'aalborg', 'FOOD', 1, 4.5, 'Aalborg Street Food', 'Aalborg Street Food', 'Aalborg Street Food', 57.04950000, 9.91460000, 'Aalborg_Street_Food.jpg', ARRAY['aalborg', 'street-food', 'food-hall']::text[]),

    ('legoland-billund-resort', 'billund', 'ENTERTAINMENT', 6, 4.8, 'LEGOLAND Billund Resort', 'LEGOLAND Billund Resort', 'LEGOLAND Billund Resort', 55.73590000, 9.12750000, 'Legoland_Billund_entrance_2024-08-02.jpg', ARRAY['billund', 'theme-park', 'family']::text[]),
    ('lego-house', 'billund', 'ENTERTAINMENT', 3, 4.8, 'LEGO House', 'LEGO House', 'LEGO House', 55.72980000, 9.11220000, 'LEGO_House_Billund.jpg', ARRAY['billund', 'lego', 'family']::text[]),
    ('lalandia-billund', 'billund', 'ENTERTAINMENT', 4, 4.5, 'Lalandia Billund', 'Lalandia Billund', 'Lalandia Billund', 55.73320000, 9.12340000, 'Lalandia_Billund.jpg', ARRAY['billund', 'waterpark', 'family']::text[]),
    ('wow-park-billund', 'billund', 'ENTERTAINMENT', 3, 4.5, 'WOW PARK Billund', 'WOW PARK Billund', 'WOW PARK Billund', 55.74770000, 9.08460000, 'WOW_Park_Billund.jpg', ARRAY['billund', 'adventure', 'forest']::text[]),
    ('givskud-zoo', 'billund', 'ENTERTAINMENT', 4, 4.6, 'Givskud Zoo', 'Givskud Zoo', 'Givskud Zoo', 55.81120000, 9.35420000, 'Givskud_Zoo.jpg', ARRAY['billund', 'safari', 'family']::text[]),

    ('skagen-grenen', 'skagen', 'NATURE', 2, 4.8, 'Гренен в Скагене', 'Skagen Grenen', 'Скаген Гренен', 57.74490000, 10.65330000, 'Grenen_Skagen.jpg', ARRAY['skagen', 'nature', 'seas']::text[]),
    ('rabjerg-mile', 'skagen', 'NATURE', 2, 4.7, 'Дюна Рабьерг Миле', 'Rabjerg Mile', 'Рабьерг Миле', 57.65370000, 10.40730000, 'Rabjerg_Mile.jpg', ARRAY['skagen', 'dune', 'nature']::text[]),
    ('skagens-museum', 'skagen', 'MUSEUM', 2, 4.6, 'Музей Скагена', 'Skagens Museum', 'Скаген музейі', 57.72400000, 10.59150000, 'Skagens_Museum.jpg', ARRAY['skagen', 'art', 'museum']::text[]),
    ('sand-covered-church', 'skagen', 'ARCHITECTURE', 1, 4.5, 'Занесённая песком церковь', 'The Sand-Covered Church', 'Құм басқан шіркеу', 57.72070000, 10.54440000, 'Den_Tilsandede_Kirke.jpg', ARRAY['skagen', 'church', 'sand']::text[]),
    ('skagen-sonderstrand', 'skagen', 'BEACH', 2, 4.5, 'Пляж Сённерстранд', 'Skagen Sonderstrand', 'Скаген Сённерстранд жағажайы', 57.72450000, 10.60930000, 'Skagen_Sonderstrand.jpg', ARRAY['skagen', 'beach', 'north-sea']::text[]),

    ('ribe-viking-center', 'ribe', 'MUSEUM', 3, 4.7, 'Викинг-центр Рибе', 'Ribe Viking Center', 'Рибе викинг орталығы', 55.30890000, 8.74370000, 'Ribe_Viking_Center.jpg', ARRAY['ribe', 'vikings', 'open-air-museum']::text[]),
    ('ribe-cathedral', 'ribe', 'TEMPLE', 1, 4.6, 'Собор Рибе', 'Ribe Cathedral', 'Рибе соборы', 55.32870000, 8.76190000, 'Ribe_Cathedral.jpg', ARRAY['ribe', 'church', 'old-town']::text[]),
    ('wadden-sea-centre', 'ribe', 'MUSEUM', 2, 4.6, 'Центр Ваттового моря', 'Wadden Sea Centre', 'Ватт теңізі орталығы', 55.27950000, 8.56590000, 'Wadden_Sea_Centre_Denmark.jpg', ARRAY['ribe', 'unesco', 'nature']::text[]),
    ('ribe-old-town', 'ribe', 'ARCHITECTURE', 2, 4.7, 'Старый город Рибе', 'Ribe Old Town', 'Рибе ескі қаласы', 55.32810000, 8.76300000, 'Ribe_Old_Town.jpg', ARRAY['ribe', 'old-town', 'architecture']::text[]),

    ('men-at-sea', 'esbjerg', 'ARCHITECTURE', 1, 4.6, 'Люди у моря', 'Men at Sea', 'Теңіздегі адамдар', 55.48910000, 8.41160000, 'Men_at_Sea_Esbjerg.jpg', ARRAY['esbjerg', 'sculpture', 'coast']::text[]),
    ('fisheries-maritime-museum', 'esbjerg', 'MUSEUM', 2, 4.6, 'Музей рыболовства и мореходства', 'Fisheries and Maritime Museum', 'Балық шаруашылығы және теңіз музейі', 55.48830000, 8.41270000, 'Fisheries_and_Maritime_Museum_Esbjerg.jpg', ARRAY['esbjerg', 'maritime', 'museum']::text[]),
    ('fano-beach', 'esbjerg', 'BEACH', 3, 4.6, 'Пляж Фанё', 'Fano Beach', 'Фанё жағажайы', 55.42120000, 8.36630000, 'Fano_Beach_Denmark.jpg', ARRAY['esbjerg', 'beach', 'wadden-sea']::text[]),
    ('esbjerg-street-food', 'esbjerg', 'FOOD', 1, 4.4, 'Esbjerg Street Food', 'Esbjerg Street Food', 'Esbjerg Street Food', 55.46590000, 8.45190000, 'Esbjerg_Street_Food.jpg', ARRAY['esbjerg', 'street-food', 'food-hall']::text[]),
    ('broen-shopping', 'esbjerg', 'SHOPPING', 2, 4.3, 'BROEN Shopping', 'BROEN Shopping', 'BROEN Shopping', 55.47020000, 8.45250000, 'BROEN_Shopping_Esbjerg.jpg', ARRAY['esbjerg', 'mall', 'shopping']::text[]),

    ('roskilde-cathedral', 'roskilde', 'TEMPLE', 2, 4.8, 'Роскилльский собор', 'Roskilde Cathedral', 'Роскилле соборы', 55.64290000, 12.08040000, 'Roskilde_Cathedral.jpg', ARRAY['roskilde', 'unesco', 'royal']::text[]),
    ('viking-ship-museum-roskilde', 'roskilde', 'MUSEUM', 2, 4.7, 'Музей кораблей викингов', 'Viking Ship Museum Roskilde', 'Роскилле викинг кемелері музейі', 55.65040000, 12.07830000, 'Viking_Ship_Museum_Roskilde.jpg', ARRAY['roskilde', 'vikings', 'museum']::text[]),
    ('land-of-legends', 'roskilde', 'MUSEUM', 3, 4.6, 'Земля легенд Лейре', 'Land of Legends', 'Аңыздар елі', 55.60470000, 11.95160000, 'Land_of_Legends_Lejre.jpg', ARRAY['roskilde', 'open-air-museum', 'history']::text[]),
    ('roskilde-harbour', 'roskilde', 'PARK', 1, 4.4, 'Гавань Роскилле', 'Roskilde Harbour', 'Роскилле айлағы', 55.65080000, 12.07970000, 'Roskilde_Harbour.jpg', ARRAY['roskilde', 'harbour', 'walk']::text[]),

    ('kronborg-castle', 'helsingor', 'ARCHITECTURE', 3, 4.8, 'Замок Кронборг', 'Kronborg Castle', 'Кронборг қамалы', 56.03900000, 12.62120000, 'Helsingoer_Kronborg_Castle.jpg', ARRAY['helsingor', 'unesco', 'hamlet']::text[]),
    ('ms-maritime-museum-denmark', 'helsingor', 'MUSEUM', 2, 4.7, 'Морской музей Дании', 'M/S Maritime Museum of Denmark', 'Дания теңіз музейі', 56.03960000, 12.62030000, 'Maritime_Museum_of_Denmark.jpg', ARRAY['helsingor', 'maritime', 'museum']::text[]),
    ('helsingor-old-town', 'helsingor', 'ARCHITECTURE', 2, 4.5, 'Старый город Хельсингёра', 'Helsingor Old Town', 'Хельсингёр ескі қаласы', 56.03610000, 12.61360000, 'Helsingor_Old_Town.jpg', ARRAY['helsingor', 'old-town', 'walk']::text[]),
    ('culture-yard-helsingor', 'helsingor', 'ENTERTAINMENT', 1, 4.4, 'Культурная верфь Хельсингёра', 'The Culture Yard', 'Хельсингёр мәдени верфі', 56.03920000, 12.61720000, 'Culture_Yard_Helsingor.jpg', ARRAY['helsingor', 'culture', 'harbour']::text[]),

    ('frederiksborg-castle', 'hillerod', 'ARCHITECTURE', 3, 4.8, 'Замок Фредериксборг', 'Frederiksborg Castle', 'Фредериксборг қамалы', 55.93480000, 12.30040000, 'Frederiksborg_Hillerød.jpg', ARRAY['hillerod', 'castle', 'museum']::text[]),
    ('frederiksborg-castle-gardens', 'hillerod', 'PARK', 2, 4.7, 'Сады Фредериксборга', 'Frederiksborg Castle Gardens', 'Фредериксборг бақтары', 55.93560000, 12.30380000, 'Frederiksborg_Castle_Gardens.jpg', ARRAY['hillerod', 'park', 'baroque-garden']::text[]),
    ('hillerod-town-centre', 'hillerod', 'SHOPPING', 1, 4.3, 'Центр Хиллерёда', 'Hillerod Town Centre', 'Хиллерёд орталығы', 55.92770000, 12.30060000, 'Hillerod_Town_Centre.jpg', ARRAY['hillerod', 'shopping', 'old-town']::text[]),

    ('mons-klint', 'mons-klint', 'NATURE', 3, 4.8, 'Мёнс-Клинт', 'Mons Klint', 'Мёнс-Клинт', 54.96650000, 12.55060000, 'Denmark,_Møns_Klint_(denmark-mons-klint).jpg', ARRAY['mons-klint', 'cliffs', 'unesco']::text[]),
    ('geocenter-mons-klint', 'mons-klint', 'MUSEUM', 2, 4.6, 'GeoCenter Møns Klint', 'GeoCenter Mons Klint', 'GeoCenter Møns Klint', 54.96680000, 12.54890000, 'GeoCenter_Mons_Klint.jpg', ARRAY['mons-klint', 'geology', 'family']::text[]),
    ('liselund-park', 'mons-klint', 'PARK', 2, 4.5, 'Парк Лиселунд', 'Liselund Park', 'Лиселунд саябағы', 55.00420000, 12.52920000, 'Liselund_Park_Mon.jpg', ARRAY['mons-klint', 'park', 'romantic-garden']::text[]),
    ('klintholm-havn', 'mons-klint', 'BEACH', 1, 4.4, 'Гавань Клинтхольм', 'Klintholm Havn', 'Клинтхольм айлағы', 54.95620000, 12.47350000, 'Klintholm_Havn_Mon.jpg', ARRAY['mons-klint', 'harbour', 'coast']::text[]);

CREATE TEMP TABLE seed_denmark_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-denmark-attraction:' || seed.slug) AS attraction_hash,
        md5('id-denmark-media:' || seed.slug) AS media_hash
    FROM seed_denmark_priority_attractions seed
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
    ARRAY['denmark', city_id, slug, lower(category), 'denmark-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Дании: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'Denmark tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'Дания туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' Denmark', ' ', '%20') AS location_source_url,
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
    'DK',
    city_id,
    category,
    NULL::numeric,
    'DKK',
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
FROM seed_denmark_resolved_attractions
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
FROM seed_denmark_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_denmark_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_denmark_resolved_attractions
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
FROM seed_denmark_resolved_attractions seed
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
FROM seed_denmark_resolved_attractions
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
    'DK',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_denmark_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'DK',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_denmark_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
