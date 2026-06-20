-- Priority Netherlands destination places seed.
-- The seed covers Amsterdam, North Holland, Rotterdam, The Hague, Delft, Leiden, Utrecht, North Brabant, Limburg, Gelderland, Overijssel, Groningen, Friesland and Zeeland.

DROP TABLE IF EXISTS seed_netherlands_resolved_places;
DROP TABLE IF EXISTS seed_netherlands_priority_places;

CREATE TEMP TABLE seed_netherlands_priority_places (
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

INSERT INTO seed_netherlands_priority_places (
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
    ('rijksmuseum', 'amsterdam', 'MUSEUM', 3, 'HOURS', 4.9, 'Рейксмюсеум', 'Rijksmuseum', 'Рейксмюсеум', 52.35999700, 4.88521900, 'Rijksmuseum Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Rijksmuseum_Amsterdam.jpg', ARRAY['art', 'indoor']::text[]),
    ('van-gogh-museum', 'amsterdam', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Ван Гога', 'Van Gogh Museum', 'Ван Гог музейі', 52.35840000, 4.88110000, 'Van Gogh Museum Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Van_Gogh_Museum_Amsterdam.jpg', ARRAY['art', 'indoor']::text[]),
    ('anne-frank-house', 'amsterdam', 'MUSEUM', 2, 'HOURS', 4.8, 'Дом Анны Франк', 'Anne Frank House', 'Анна Франк үйі', 52.37520000, 4.88400000, 'Anne Frank House Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Anne_Frank_House_Amsterdam.jpg', ARRAY['history', 'indoor']::text[]),
    ('canal-ring-amsterdam', 'amsterdam', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Канальное кольцо Амстердама', 'Canal Ring Amsterdam', 'Амстердам канал сақинасы', 52.37020000, 4.89520000, 'Amsterdam Canal Ring Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Amsterdam_Canal_Ring.jpg', ARRAY['unesco', 'walk']::text[]),
    ('vondelpark', 'amsterdam', 'PARK', 2, 'HOURS', 4.8, 'Вондельпарк', 'Vondelpark', 'Вонделпарк', 52.35790000, 4.86860000, 'Vondelpark Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Vondelpark_Amsterdam.jpg', ARRAY['green-space', 'family']::text[]),
    ('albert-cuyp-market', 'amsterdam', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Альберта Кейпа', 'Albert Cuyp Market', 'Альберт Кейп базары', 52.35500000, 4.89100000, 'Albert Cuyp Market Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Albert_Cuyp_Market_Amsterdam.jpg', ARRAY['local-market', 'food']::text[]),
    ('artis-amsterdam-royal-zoo', 'amsterdam', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Королевский зоопарк ARTIS', 'ARTIS Amsterdam Royal Zoo', 'ARTIS Амстердам корольдік хайуанаттар бағы', 52.36630000, 4.91690000, 'ARTIS Amsterdam Royal Zoo Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Artis_Amsterdam.jpg', ARRAY['family', 'zoo']::text[]),
    ('nemo-science-museum', 'amsterdam', 'MUSEUM', 2, 'HOURS', 4.7, 'Научный музей NEMO', 'NEMO Science Museum', 'NEMO ғылым музейі', 52.37420000, 4.91230000, 'NEMO Science Museum Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'NEMO_Science_Museum_Amsterdam.jpg', ARRAY['family', 'interactive']::text[]),
    ('royal-palace-amsterdam', 'amsterdam', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Королевский дворец Амстердама', 'Royal Palace Amsterdam', 'Амстердам корольдік сарайы', 52.37310000, 4.89130000, 'Royal Palace Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Royal_Palace_Amsterdam.jpg', ARRAY['palace', 'history']::text[]),
    ('de-hallen-amsterdam', 'amsterdam', 'FOOD', 2, 'HOURS', 4.6, 'Фуд-холл De Hallen', 'De Hallen Amsterdam', 'De Hallen Амстердам', 52.36770000, 4.86860000, 'De Hallen Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'De_Hallen_Amsterdam.jpg', ARRAY['food-hall', 'indoor']::text[]),
    ('magna-plaza-amsterdam', 'amsterdam', 'SHOPPING', 1, 'HOURS', 4.5, 'Торговый центр Magna Plaza', 'Magna Plaza Amsterdam', 'Magna Plaza Амстердам сауда орталығы', 52.37440000, 4.89020000, 'Magna Plaza Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'Magna_Plaza_Amsterdam.jpg', ARRAY['mall', 'indoor']::text[]),
    ('adam-lookout', 'amsterdam', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Смотровая площадка A DAM Lookout', 'A DAM Lookout', 'A DAM Lookout қарау алаңы', 52.38470000, 4.90210000, 'A DAM Lookout Amsterdam Netherlands', ARRAY['amsterdam']::text[], ARRAY['amsterdam']::text[], 'A_DAM_Lookout_Amsterdam.jpg', ARRAY['viewpoint']::text[]),

    ('grote-kerk-haarlem', 'haarlem', 'TEMPLE', 1, 'HOURS', 4.7, 'Большая церковь Харлема', 'Grote Kerk Haarlem', 'Харлем үлкен шіркеуі', 52.38100000, 4.63740000, 'Grote Kerk Haarlem Netherlands', ARRAY['haarlem']::text[], ARRAY['amsterdam', 'haarlem']::text[], 'Grote_Kerk_Haarlem.jpg', ARRAY['church', 'history']::text[]),
    ('frans-hals-museum', 'haarlem', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Франса Халса', 'Frans Hals Museum', 'Франс Халс музейі', 52.37660000, 4.63390000, 'Frans Hals Museum Haarlem Netherlands', ARRAY['haarlem']::text[], ARRAY['amsterdam', 'haarlem']::text[], 'Frans_Hals_Museum_Haarlem.jpg', ARRAY['art', 'indoor']::text[]),
    ('grote-markt-haarlem', 'haarlem', 'MARKET', 1, 'HOURS', 4.6, 'Гроте-Маркт Харлема', 'Grote Markt Haarlem', 'Харлем Гроте-Маркт алаңы', 52.38120000, 4.63720000, 'Grote Markt Haarlem Netherlands', ARRAY['haarlem']::text[], ARRAY['amsterdam', 'haarlem']::text[], 'Grote_Markt_Haarlem.jpg', ARRAY['market-square']::text[]),
    ('czar-peter-house', 'zaandam', 'MUSEUM', 1, 'HOURS', 4.5, 'Домик Петра I в Зандаме', 'Czar Peter House Zaandam', 'Зандамдағы Петр патша үйі', 52.43830000, 4.82690000, 'Czar Peter House Zaandam Netherlands', ARRAY['zaandam']::text[], ARRAY['amsterdam', 'zaandam']::text[], 'Czar_Peter_House_Zaandam.jpg', ARRAY['history', 'indoor']::text[]),
    ('zaanse-schans', 'zaanse-schans', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Зансе-Сханс', 'Zaanse Schans', 'Зансе-Сханс', 52.47380000, 4.81760000, 'Zaanse Schans Netherlands', ARRAY['zaanse-schans', 'zaandam']::text[], ARRAY['amsterdam', 'zaandam', 'zaanse-schans']::text[], 'Zaanse_Schans_windmills.jpg', ARRAY['windmills', 'heritage']::text[]),
    ('zaans-museum', 'zaanse-schans', 'MUSEUM', 2, 'HOURS', 4.6, 'Заанский музей', 'Zaans Museum', 'Заан музейі', 52.47430000, 4.82100000, 'Zaans Museum Zaanse Schans Netherlands', ARRAY['zaanse-schans', 'zaandam']::text[], ARRAY['amsterdam', 'zaanse-schans']::text[], 'Zaans_Museum.jpg', ARRAY['indoor', 'heritage']::text[]),
    ('volendam-harbor', 'volendam', 'OTHER', 1, 'HOURS', 4.6, 'Гавань Волендама', 'Volendam Harbor and De Dijk', 'Волендам айлағы және Дейк жағалауы', 52.49500000, 5.07400000, 'Volendam Harbor Netherlands', ARRAY['volendam']::text[], ARRAY['amsterdam', 'volendam']::text[], 'Volendam_Harbor.jpg', ARRAY['harbor', 'walk']::text[]),
    ('marken-harbor', 'marken', 'OTHER', 1, 'HOURS', 4.5, 'Гавань Маркена', 'Marken Harbor', 'Маркен айлағы', 52.45800000, 5.10200000, 'Marken Harbor Netherlands', ARRAY['marken']::text[], ARRAY['amsterdam', 'marken']::text[], 'Marken_Harbor.jpg', ARRAY['harbor', 'village']::text[]),
    ('alkmaar-cheese-market', 'alkmaar', 'MARKET', 1, 'HOURS', 4.7, 'Сырный рынок Алкмара', 'Alkmaar Cheese Market', 'Алкмар ірімшік базары', 52.63180000, 4.74860000, 'Alkmaar Cheese Market Netherlands', ARRAY['alkmaar']::text[], ARRAY['amsterdam', 'alkmaar']::text[], 'Alkmaar_Cheese_Market.jpg', ARRAY['cheese', 'local-market']::text[]),
    ('zandvoort-beach', 'zandvoort', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Зандворта', 'Zandvoort Beach', 'Зандворт жағажайы', 52.37300000, 4.52600000, 'Zandvoort Beach Netherlands', ARRAY['zandvoort', 'haarlem']::text[], ARRAY['amsterdam', 'haarlem', 'zandvoort']::text[], 'Zandvoort_Beach_Netherlands.jpg', ARRAY['coast', 'summer']::text[]),
    ('texel-lighthouse', 'texel', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Маяк Тексела', 'Texel Lighthouse', 'Тексел маягы', 53.18250000, 4.85530000, 'Texel Lighthouse Netherlands', ARRAY['texel']::text[], ARRAY['amsterdam', 'texel']::text[], 'Texel_Lighthouse.jpg', ARRAY['island', 'viewpoint']::text[]),
    ('de-slufter-texel', 'texel', 'NATURE', 2, 'HOURS', 4.8, 'Де Слуфтер на Текселе', 'De Slufter Texel', 'Тексел Де Слуфтер қорығы', 53.11670000, 4.81950000, 'De Slufter Texel Netherlands', ARRAY['texel']::text[], ARRAY['texel']::text[], 'De_Slufter_Texel.jpg', ARRAY['nature-reserve', 'island']::text[]),
    ('ecomare-texel', 'texel', 'MUSEUM', 2, 'HOURS', 4.6, 'Экомаре на Текселе', 'Ecomare Texel', 'Тексел Экомаре музейі', 53.07890000, 4.76120000, 'Ecomare Texel Netherlands', ARRAY['texel']::text[], ARRAY['texel']::text[], 'Ecomare_Texel.jpg', ARRAY['family', 'sea']::text[]),

    ('markthal-rotterdam', 'rotterdam', 'FOOD', 1, 'HOURS', 4.7, 'Марктхал Роттердам', 'Markthal Rotterdam', 'Роттердам Markthal', 51.92000000, 4.48660000, 'Markthal Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Markthal_Rotterdam.jpg', ARRAY['food-hall', 'architecture']::text[]),
    ('cube-houses-rotterdam', 'rotterdam', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Кубические дома Роттердама', 'Cube Houses Rotterdam', 'Роттердам куб үйлері', 51.92020000, 4.49000000, 'Cube Houses Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Cube_Houses_Rotterdam.jpg', ARRAY['architecture', 'photo-stop']::text[]),
    ('erasmus-bridge', 'rotterdam', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мост Эразма', 'Erasmus Bridge', 'Эразм көпірі', 51.90900000, 4.48600000, 'Erasmus Bridge Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Erasmus_Bridge_Rotterdam.jpg', ARRAY['city-symbol']::text[]),
    ('euromast', 'rotterdam', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Евромачта', 'Euromast', 'Еуромачта', 51.90540000, 4.46650000, 'Euromast Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Euromast_Rotterdam.jpg', ARRAY['viewpoint']::text[]),
    ('depot-boijmans-van-beuningen', 'rotterdam', 'MUSEUM', 2, 'HOURS', 4.6, 'Депо Бойманса ван Бёнингена', 'Depot Boijmans Van Beuningen', 'Бойманс ван Бёнинген депосы', 51.91410000, 4.47360000, 'Depot Boijmans Van Beuningen Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Depot_Boijmans_Van_Beuningen.jpg', ARRAY['art', 'indoor']::text[]),
    ('kunsthal-rotterdam', 'rotterdam', 'MUSEUM', 2, 'HOURS', 4.5, 'Кюнстхал Роттердам', 'Kunsthal Rotterdam', 'Кюнстхал Роттердам', 51.91420000, 4.47300000, 'Kunsthal Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Kunsthal_Rotterdam.jpg', ARRAY['art', 'indoor']::text[]),
    ('maritime-museum-rotterdam', 'rotterdam', 'MUSEUM', 2, 'HOURS', 4.6, 'Морской музей Роттердама', 'Maritime Museum Rotterdam', 'Роттердам теңіз музейі', 51.91780000, 4.48240000, 'Maritime Museum Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Maritime_Museum_Rotterdam.jpg', ARRAY['family', 'maritime']::text[]),
    ('diergaarde-blijdorp', 'rotterdam', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Зоопарк Бляйдорп', 'Diergaarde Blijdorp', 'Бляйдорп хайуанаттар бағы', 51.92790000, 4.44520000, 'Diergaarde Blijdorp Rotterdam Netherlands', ARRAY['rotterdam']::text[], ARRAY['rotterdam']::text[], 'Diergaarde_Blijdorp_Rotterdam.jpg', ARRAY['family', 'zoo']::text[]),

    ('mauritshuis', 'the-hague', 'MUSEUM', 2, 'HOURS', 4.8, 'Маурицхёйс', 'Mauritshuis', 'Маурицхёйс', 52.08070000, 4.31420000, 'Mauritshuis The Hague Netherlands', ARRAY['the-hague']::text[], ARRAY['rotterdam', 'the-hague']::text[], 'Mauritshuis_The_Hague.jpg', ARRAY['art', 'indoor']::text[]),
    ('peace-palace', 'the-hague', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Дворец мира', 'Peace Palace', 'Бейбітшілік сарайы', 52.08660000, 4.29550000, 'Peace Palace The Hague Netherlands', ARRAY['the-hague']::text[], ARRAY['rotterdam', 'the-hague']::text[], 'Peace_Palace_The_Hague.jpg', ARRAY['international-law', 'architecture']::text[]),
    ('madurodam', 'the-hague', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Мадюродам', 'Madurodam', 'Мадюродам', 52.09900000, 4.29700000, 'Madurodam The Hague Netherlands', ARRAY['the-hague']::text[], ARRAY['rotterdam', 'the-hague']::text[], 'Madurodam_The_Hague.jpg', ARRAY['family', 'miniatures']::text[]),
    ('the-hague-market', 'the-hague', 'MARKET', 1, 'HOURS', 4.5, 'Гаагский рынок', 'The Hague Market', 'Гаага базары', 52.06480000, 4.29870000, 'The Hague Market Netherlands', ARRAY['the-hague']::text[], ARRAY['the-hague']::text[], 'The_Hague_Market.jpg', ARRAY['local-market']::text[]),
    ('de-passage-the-hague', 'the-hague', 'SHOPPING', 1, 'HOURS', 4.5, 'Пассаж в Гааге', 'De Passage The Hague', 'Гаага Пассажы', 52.07860000, 4.31170000, 'De Passage The Hague Netherlands', ARRAY['the-hague']::text[], ARRAY['the-hague']::text[], 'De_Passage_The_Hague.jpg', ARRAY['shopping-arcade']::text[]),
    ('westfield-mall-netherlands', 'the-hague', 'SHOPPING', 2, 'HOURS', 4.5, 'Westfield Mall of the Netherlands', 'Westfield Mall of the Netherlands', 'Westfield Mall of the Netherlands', 52.08950000, 4.38350000, 'Westfield Mall of the Netherlands Leidschendam', ARRAY['the-hague']::text[], ARRAY['the-hague']::text[], 'Westfield_Mall_of_the_Netherlands.jpg', ARRAY['mall', 'indoor']::text[]),
    ('scheveningen-beach', 'scheveningen', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Схевенингена', 'Scheveningen Beach', 'Схевенинген жағажайы', 52.11230000, 4.28030000, 'Scheveningen Beach Netherlands', ARRAY['scheveningen', 'the-hague']::text[], ARRAY['the-hague', 'scheveningen']::text[], 'Scheveningen_Beach.jpg', ARRAY['coast', 'summer']::text[]),
    ('scheveningen-pier', 'scheveningen', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Пирс Схевенингена', 'Scheveningen Pier', 'Схевенинген пирсі', 52.11750000, 4.28130000, 'Scheveningen Pier Netherlands', ARRAY['scheveningen', 'the-hague']::text[], ARRAY['the-hague', 'scheveningen']::text[], 'Scheveningen_Pier.jpg', ARRAY['coast', 'family']::text[]),
    ('sea-life-scheveningen', 'scheveningen', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'SEA LIFE Схевенинген', 'SEA LIFE Scheveningen', 'SEA LIFE Схевенинген', 52.11290000, 4.28150000, 'SEA LIFE Scheveningen Netherlands', ARRAY['scheveningen', 'the-hague']::text[], ARRAY['the-hague', 'scheveningen']::text[], 'SEA_LIFE_Scheveningen.jpg', ARRAY['family', 'indoor']::text[]),

    ('royal-delft', 'delft', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Royal Delft', 'Royal Delft', 'Royal Delft музейі', 51.99870000, 4.36960000, 'Royal Delft Museum Netherlands', ARRAY['delft']::text[], ARRAY['rotterdam', 'delft']::text[], 'Royal_Delft_Museum.jpg', ARRAY['ceramics', 'indoor']::text[]),
    ('nieuwe-kerk-delft', 'delft', 'TEMPLE', 1, 'HOURS', 4.6, 'Новая церковь Делфта', 'Nieuwe Kerk Delft', 'Делфт жаңа шіркеуі', 52.01250000, 4.36000000, 'Nieuwe Kerk Delft Netherlands', ARRAY['delft']::text[], ARRAY['rotterdam', 'delft']::text[], 'Nieuwe_Kerk_Delft.jpg', ARRAY['church', 'viewpoint']::text[]),
    ('vermeer-centrum-delft', 'delft', 'MUSEUM', 1, 'HOURS', 4.5, 'Центр Вермеера в Делфте', 'Vermeer Centrum Delft', 'Делфт Вермеер орталығы', 52.01260000, 4.35790000, 'Vermeer Centrum Delft Netherlands', ARRAY['delft']::text[], ARRAY['delft']::text[], 'Vermeer_Centrum_Delft.jpg', ARRAY['art', 'indoor']::text[]),
    ('delft-market-square', 'delft', 'MARKET', 1, 'HOURS', 4.6, 'Рыночная площадь Делфта', 'Delft Market Square', 'Делфт базар алаңы', 52.01170000, 4.35910000, 'Delft Market Square Netherlands', ARRAY['delft']::text[], ARRAY['delft']::text[], 'Delft_Market_Square.jpg', ARRAY['market-square']::text[]),
    ('naturalis-biodiversity-center', 'leiden', 'MUSEUM', 2, 'HOURS', 4.7, 'Центр биоразнообразия Naturalis', 'Naturalis Biodiversity Center', 'Naturalis биоалуантүрлілік орталығы', 52.16410000, 4.47380000, 'Naturalis Biodiversity Center Leiden Netherlands', ARRAY['leiden']::text[], ARRAY['amsterdam', 'leiden']::text[], 'Naturalis_Biodiversity_Center.jpg', ARRAY['family', 'science']::text[]),
    ('hortus-botanicus-leiden', 'leiden', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Лейдена', 'Hortus Botanicus Leiden', 'Лейден ботаникалық бағы', 52.15710000, 4.48400000, 'Hortus Botanicus Leiden Netherlands', ARRAY['leiden']::text[], ARRAY['leiden']::text[], 'Hortus_Botanicus_Leiden.jpg', ARRAY['garden']::text[]),
    ('burcht-van-leiden', 'leiden', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Лейденская крепость', 'Burcht van Leiden', 'Лейден қамалы', 52.15880000, 4.49340000, 'Burcht van Leiden Netherlands', ARRAY['leiden']::text[], ARRAY['leiden']::text[], 'Burcht_van_Leiden.jpg', ARRAY['viewpoint', 'history']::text[]),
    ('leiden-market', 'leiden', 'MARKET', 1, 'HOURS', 4.5, 'Лейденский рынок', 'Leiden Market', 'Лейден базары', 52.15820000, 4.49240000, 'Leiden Market Netherlands', ARRAY['leiden']::text[], ARRAY['leiden']::text[], 'Leiden_Market.jpg', ARRAY['local-market']::text[]),
    ('dom-tower-utrecht', 'utrecht', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Домская башня', 'Dom Tower Utrecht', 'Утрехт Дом мұнарасы', 52.09070000, 5.12140000, 'Dom Tower Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['amsterdam', 'utrecht']::text[], 'Dom_Tower_Utrecht.jpg', ARRAY['viewpoint', 'city-symbol']::text[]),
    ('oudegracht-utrecht', 'utrecht', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый канал Утрехта', 'Oudegracht Utrecht', 'Утрехт ескі каналы', 52.09100000, 5.11950000, 'Oudegracht Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['utrecht']::text[], 'Oudegracht_Utrecht.jpg', ARRAY['canal', 'walk']::text[]),
    ('centraal-museum-utrecht', 'utrecht', 'MUSEUM', 2, 'HOURS', 4.6, 'Центральный музей Утрехта', 'Centraal Museum Utrecht', 'Утрехт орталық музейі', 52.08370000, 5.12540000, 'Centraal Museum Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['utrecht']::text[], 'Centraal_Museum_Utrecht.jpg', ARRAY['art', 'indoor']::text[]),
    ('rietveld-schroder-house', 'utrecht', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Дом Ритвельда Шрёдер', 'Rietveld Schroder House', 'Ритвельд Шрёдер үйі', 52.08530000, 5.14700000, 'Rietveld Schroder House Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['utrecht']::text[], 'Rietveld_Schroder_House.jpg', ARRAY['unesco', 'design']::text[]),
    ('hoog-catharijne', 'utrecht', 'SHOPPING', 2, 'HOURS', 4.5, 'Хоог-Катарейне', 'Hoog Catharijne', 'Hoog Catharijne', 52.08900000, 5.11260000, 'Hoog Catharijne Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['utrecht']::text[], 'Hoog_Catharijne_Utrecht.jpg', ARRAY['mall', 'indoor']::text[]),
    ('vredenburg-market', 'utrecht', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Вреденбург', 'Vredenburg Market', 'Вреденбург базары', 52.09200000, 5.11380000, 'Vredenburg Market Utrecht Netherlands', ARRAY['utrecht']::text[], ARRAY['utrecht']::text[], 'Vredenburg_Market_Utrecht.jpg', ARRAY['local-market']::text[]),
    ('gouda-cheese-market', 'gouda', 'MARKET', 1, 'HOURS', 4.6, 'Сырный рынок Гауды', 'Gouda Cheese Market', 'Гауда ірімшік базары', 52.01150000, 4.71050000, 'Gouda Cheese Market Netherlands', ARRAY['gouda']::text[], ARRAY['rotterdam', 'gouda']::text[], 'Gouda_Cheese_Market.jpg', ARRAY['cheese', 'local-market']::text[]),
    ('kinderdijk-windmills', 'kinderdijk', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Ветряные мельницы Киндердейка', 'Kinderdijk Windmills', 'Киндердейк жел диірмендері', 51.88260000, 4.63350000, 'Kinderdijk Windmills Netherlands', ARRAY['kinderdijk', 'rotterdam']::text[], ARRAY['rotterdam', 'kinderdijk']::text[], 'Kinderdijk_Windmills.jpg', ARRAY['unesco', 'windmills']::text[]),
    ('giethoorn', 'giethoorn', 'NATURE', 3, 'HOURS', 4.8, 'Гитхорн', 'Giethoorn', 'Гитхорн', 52.74070000, 6.07990000, 'Giethoorn Netherlands', ARRAY['giethoorn']::text[], ARRAY['amsterdam', 'giethoorn']::text[], 'Giethoorn_Netherlands.jpg', ARRAY['canals', 'village']::text[]),

    ('van-abbemuseum', 'eindhoven', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Ван Аббе', 'Van Abbemuseum', 'Ван Аббе музейі', 51.43500000, 5.48230000, 'Van Abbemuseum Eindhoven Netherlands', ARRAY['eindhoven']::text[], ARRAY['eindhoven']::text[], 'Van_Abbemuseum_Eindhoven.jpg', ARRAY['art', 'indoor']::text[]),
    ('strijp-s-eindhoven', 'eindhoven', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Креативный район Strijp-S', 'Strijp-S Eindhoven', 'Эйндховен Strijp-S ауданы', 51.44800000, 5.45600000, 'Strijp-S Eindhoven Netherlands', ARRAY['eindhoven']::text[], ARRAY['eindhoven']::text[], 'Strijp-S_Eindhoven.jpg', ARRAY['design', 'evening']::text[]),
    ('psv-stadium', 'eindhoven', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Стадион PSV', 'PSV Stadium', 'PSV стадионы', 51.44170000, 5.46750000, 'PSV Stadium Eindhoven Netherlands', ARRAY['eindhoven']::text[], ARRAY['eindhoven']::text[], 'PSV_Stadium_Eindhoven.jpg', ARRAY['sport']::text[]),
    ('st-johns-cathedral-den-bosch', 'den-bosch', 'TEMPLE', 1, 'HOURS', 4.8, 'Собор Святого Иоанна в Ден-Босе', 'St Johns Cathedral Den Bosch', 'Ден-Бос Әулие Иоанн соборы', 51.68890000, 5.30760000, 'St Johns Cathedral Den Bosch Netherlands', ARRAY['den-bosch']::text[], ARRAY['eindhoven', 'den-bosch']::text[], 'St_Johns_Cathedral_Den_Bosch.jpg', ARRAY['cathedral']::text[]),
    ('noordbrabants-museum', 'den-bosch', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Северного Брабанта', 'Noordbrabants Museum', 'Солтүстік Брабант музейі', 51.68750000, 5.30580000, 'Noordbrabants Museum Den Bosch Netherlands', ARRAY['den-bosch']::text[], ARRAY['den-bosch']::text[], 'Noordbrabants_Museum.jpg', ARRAY['art', 'history']::text[]),
    ('efteling', 'kaatsheuvel', 'ENTERTAINMENT', 8, 'HOURS', 4.9, 'Парк развлечений Эфтелинг', 'Efteling', 'Эфтелинг ойын-сауық паркі', 51.65000000, 5.04860000, 'Efteling Kaatsheuvel Netherlands', ARRAY['kaatsheuvel', 'den-bosch']::text[], ARRAY['eindhoven', 'den-bosch', 'kaatsheuvel']::text[], 'Efteling_Kaatsheuvel.jpg', ARRAY['theme-park', 'family']::text[]),
    ('vrijthof-maastricht', 'maastricht', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Площадь Врейтхоф в Маастрихте', 'Vrijthof Maastricht', 'Маастрихт Врейтхоф алаңы', 50.84880000, 5.68800000, 'Vrijthof Maastricht Netherlands', ARRAY['maastricht']::text[], ARRAY['maastricht']::text[], 'Vrijthof_Maastricht.jpg', ARRAY['square', 'walk']::text[]),
    ('boekhandel-dominicanen', 'maastricht', 'SHOPPING', 1, 'HOURS', 4.8, 'Книжный магазин Dominicanen', 'Boekhandel Dominicanen', 'Dominicanen кітап дүкені', 50.85040000, 5.69000000, 'Boekhandel Dominicanen Maastricht Netherlands', ARRAY['maastricht']::text[], ARRAY['maastricht']::text[], 'Boekhandel_Dominicanen_Maastricht.jpg', ARRAY['bookstore', 'architecture']::text[]),
    ('basilica-of-saint-servatius', 'maastricht', 'TEMPLE', 1, 'HOURS', 4.6, 'Базилика Святого Серватия', 'Basilica of Saint Servatius', 'Әулие Серватий базиликасы', 50.84890000, 5.68730000, 'Basilica of Saint Servatius Maastricht Netherlands', ARRAY['maastricht']::text[], ARRAY['maastricht']::text[], 'Basilica_of_Saint_Servatius_Maastricht.jpg', ARRAY['basilica', 'history']::text[]),
    ('valkenburg-caves', 'valkenburg', 'NATURE', 2, 'HOURS', 4.6, 'Пещеры Валкенбурга', 'Valkenburg Caves', 'Валкенбург үңгірлері', 50.86250000, 5.83210000, 'Valkenburg Caves Netherlands', ARRAY['valkenburg', 'maastricht']::text[], ARRAY['maastricht', 'valkenburg']::text[], 'Valkenburg_Caves.jpg', ARRAY['cave', 'family']::text[]),
    ('hoge-veluwe-national-park', 'hoge-veluwe', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Хоге-Велюве', 'Hoge Veluwe National Park', 'Хоге-Велюве ұлттық паркі', 52.08330000, 5.80000000, 'Hoge Veluwe National Park Netherlands', ARRAY['hoge-veluwe', 'arnhem']::text[], ARRAY['arnhem', 'hoge-veluwe']::text[], 'Hoge_Veluwe_National_Park.jpg', ARRAY['nature', 'cycling']::text[]),
    ('kroller-muller-museum', 'hoge-veluwe', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Крёллер-Мюллер', 'Kroller-Muller Museum', 'Крёллер-Мюллер музейі', 52.09500000, 5.81670000, 'Kroller-Muller Museum Netherlands', ARRAY['hoge-veluwe', 'arnhem']::text[], ARRAY['arnhem', 'hoge-veluwe']::text[], 'Kroller_Muller_Museum.jpg', ARRAY['art', 'sculpture-garden']::text[]),
    ('netherlands-open-air-museum', 'arnhem', 'MUSEUM', 3, 'HOURS', 4.7, 'Нидерландский музей под открытым небом', 'Netherlands Open Air Museum', 'Нидерланд ашық аспан музейі', 52.00710000, 5.90780000, 'Netherlands Open Air Museum Arnhem', ARRAY['arnhem']::text[], ARRAY['arnhem']::text[], 'Netherlands_Open_Air_Museum_Arnhem.jpg', ARRAY['family', 'heritage']::text[]),
    ('burgers-zoo', 'arnhem', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Зоопарк Бюргерс', 'Burgers Zoo', 'Бюргерс хайуанаттар бағы', 52.00900000, 5.90000000, 'Burgers Zoo Arnhem Netherlands', ARRAY['arnhem']::text[], ARRAY['arnhem']::text[], 'Burgers_Zoo_Arnhem.jpg', ARRAY['family', 'zoo']::text[]),
    ('muzeumpark-orientalis', 'nijmegen', 'MUSEUM', 2, 'HOURS', 4.5, 'Музейный парк Ориенталис', 'Museumpark Orientalis', 'Ориенталис музей паркі', 51.81500000, 5.86200000, 'Museumpark Orientalis Nijmegen Netherlands', ARRAY['nijmegen']::text[], ARRAY['arnhem', 'nijmegen']::text[], 'Museumpark_Orientalis.jpg', ARRAY['family', 'heritage']::text[]),
    ('waalkade-nijmegen', 'nijmegen', 'PARK', 1, 'HOURS', 4.5, 'Набережная Ваалкаде в Неймегене', 'Waalkade Nijmegen', 'Неймеген Ваалкаде жағалауы', 51.84900000, 5.86900000, 'Waalkade Nijmegen Netherlands', ARRAY['nijmegen']::text[], ARRAY['nijmegen']::text[], 'Waalkade_Nijmegen.jpg', ARRAY['riverfront', 'walk']::text[]),

    ('martinitoren-groningen', 'groningen', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Башня Мартини в Гронингене', 'Martinitoren Groningen', 'Гронинген Мартини мұнарасы', 53.21930000, 6.56800000, 'Martinitoren Groningen Netherlands', ARRAY['groningen']::text[], ARRAY['groningen']::text[], 'Martinitoren_Groningen.jpg', ARRAY['viewpoint', 'city-symbol']::text[]),
    ('groninger-museum', 'groningen', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Гронингена', 'Groninger Museum', 'Гронинген музейі', 53.21240000, 6.56650000, 'Groninger Museum Netherlands', ARRAY['groningen']::text[], ARRAY['groningen']::text[], 'Groninger_Museum.jpg', ARRAY['art', 'indoor']::text[]),
    ('forum-groningen-rooftop', 'groningen', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Смотровая крыша Forum Groningen', 'Forum Groningen Rooftop', 'Forum Groningen шатыры', 53.21820000, 6.56880000, 'Forum Groningen Rooftop Netherlands', ARRAY['groningen']::text[], ARRAY['groningen']::text[], 'Forum_Groningen.jpg', ARRAY['viewpoint']::text[]),
    ('vismarkt-groningen', 'groningen', 'MARKET', 1, 'HOURS', 4.5, 'Висмаркт в Гронингене', 'Vismarkt Groningen', 'Гронинген Висмаркт базары', 53.21660000, 6.56390000, 'Vismarkt Groningen Netherlands', ARRAY['groningen']::text[], ARRAY['groningen']::text[], 'Vismarkt_Groningen.jpg', ARRAY['local-market']::text[]),
    ('fries-museum', 'leeuwarden', 'MUSEUM', 2, 'HOURS', 4.6, 'Фризский музей', 'Fries Museum', 'Фриз музейі', 53.20120000, 5.79910000, 'Fries Museum Leeuwarden Netherlands', ARRAY['leeuwarden']::text[], ARRAY['leeuwarden']::text[], 'Fries_Museum_Leeuwarden.jpg', ARRAY['indoor', 'history']::text[]),
    ('oldehove-leeuwarden', 'leeuwarden', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Олдехове в Леувардене', 'Oldehove Leeuwarden', 'Леуварден Олдехове', 53.20270000, 5.79260000, 'Oldehove Leeuwarden Netherlands', ARRAY['leeuwarden']::text[], ARRAY['leeuwarden']::text[], 'Oldehove_Leeuwarden.jpg', ARRAY['viewpoint', 'tower']::text[]),
    ('friday-market-leeuwarden', 'leeuwarden', 'MARKET', 1, 'HOURS', 4.4, 'Пятничный рынок Леувардена', 'Friday Market Leeuwarden', 'Леуварден жұма базары', 53.20150000, 5.79820000, 'Friday Market Leeuwarden Netherlands', ARRAY['leeuwarden']::text[], ARRAY['leeuwarden']::text[], 'Leeuwarden_Market.jpg', ARRAY['local-market']::text[]),
    ('lange-jan-middelburg', 'middelburg', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Башня Ланге Ян в Мидделбурге', 'Lange Jan Middelburg', 'Мидделбург Ланге Ян мұнарасы', 51.50060000, 3.61390000, 'Lange Jan Middelburg Netherlands', ARRAY['middelburg']::text[], ARRAY['middelburg']::text[], 'Lange_Jan_Middelburg.jpg', ARRAY['viewpoint', 'tower']::text[]),
    ('zeeuws-museum', 'middelburg', 'MUSEUM', 2, 'HOURS', 4.5, 'Зеландский музей', 'Zeeuws Museum', 'Зеланд музейі', 51.50040000, 3.61400000, 'Zeeuws Museum Middelburg Netherlands', ARRAY['middelburg']::text[], ARRAY['middelburg']::text[], 'Zeeuws_Museum.jpg', ARRAY['indoor', 'history']::text[]),
    ('middelburg-market', 'middelburg', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Мидделбурга', 'Middelburg Market', 'Мидделбург базары', 51.49950000, 3.61090000, 'Middelburg Market Netherlands', ARRAY['middelburg']::text[], ARRAY['middelburg']::text[], 'Middelburg_Market.jpg', ARRAY['local-market']::text[]),
    ('domburg-beach', 'domburg', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Домбурга', 'Domburg Beach', 'Домбург жағажайы', 51.56300000, 3.49600000, 'Domburg Beach Netherlands', ARRAY['domburg', 'middelburg']::text[], ARRAY['middelburg', 'domburg']::text[], 'Domburg_Beach.jpg', ARRAY['coast', 'summer']::text[]),
    ('manteling-walcheren', 'domburg', 'NATURE', 2, 'HOURS', 4.6, 'Де Мантелинг на Валхерене', 'De Manteling of Walcheren', 'Валхерен Де Мантелинг қорығы', 51.57900000, 3.52600000, 'De Manteling Walcheren Netherlands', ARRAY['domburg', 'middelburg']::text[], ARRAY['middelburg', 'domburg']::text[], 'De_Manteling_Walcheren.jpg', ARRAY['nature-reserve', 'coast']::text[]);

CREATE TEMP TABLE seed_netherlands_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-netherlands-place:' || seed.slug) AS place_hash,
        md5('id-netherlands-media:' || seed.slug) AS media_hash
    FROM seed_netherlands_priority_places seed
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
    ARRAY['netherlands', city_id, slug, lower(category), 'netherlands-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Нидерландов: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Netherlands tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Нидерланд туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'NL',
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
FROM seed_netherlands_resolved_places
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
FROM seed_netherlands_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_netherlands_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_netherlands_resolved_places
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
FROM seed_netherlands_resolved_places seed
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
FROM seed_netherlands_resolved_places
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
    'NL',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_netherlands_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'NL',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_netherlands_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_netherlands_resolved_places;
DROP TABLE IF EXISTS seed_netherlands_priority_places;
