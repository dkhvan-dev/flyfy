-- Priority Azerbaijan destination places seed.
-- The seed covers Baku and Absheron, Gobustan, northern mountains, Sheki-Ganja-Gabala, southern Caspian nature and Nakhchivan.

DROP TABLE IF EXISTS seed_azerbaijan_resolved_places;
DROP TABLE IF EXISTS seed_azerbaijan_priority_places;

CREATE TEMP TABLE seed_azerbaijan_priority_places (
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

INSERT INTO seed_azerbaijan_priority_places (
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
    ('icherisheher-old-city', 'baku', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Ичери-шехер', 'Icherisheher Old City', 'Ішері-шехер ескі қаласы', 40.36670000, 49.83330000, 'Icherisheher Old City Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Old City Baku Azerbaijan.jpg'),
    ('maiden-tower-baku', 'baku', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Девичья башня в Баку', 'Maiden Tower Baku', 'Баку Қыз мұнарасы', 40.36640000, 49.83700000, 'Maiden Tower Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Maiden Tower in Baku.jpg'),
    ('palace-shirvanshahs', 'baku', 'MUSEUM', 2, 'HOURS', 4.8, 'Дворец ширваншахов', 'Palace of the Shirvanshahs', 'Ширваншахтар сарайы', 40.36610000, 49.83390000, 'Palace of the Shirvanshahs Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Palace of the Shirvanshahs.jpg'),
    ('heydar-aliyev-center', 'baku', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Центр Гейдара Алиева', 'Heydar Aliyev Center', 'Гейдар Әлиев орталығы', 40.39530000, 49.86710000, 'Heydar Aliyev Center Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Heydar Aliyev Center in Baku in 2015.jpg'),
    ('azerbaijan-carpet-museum', 'baku', 'MUSEUM', 2, 'HOURS', 4.7, 'Азербайджанский музей ковра', 'Azerbaijan Carpet Museum', 'Әзірбайжан кілем музейі', 40.35940000, 49.83530000, 'Azerbaijan Carpet Museum Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Azerbaijan Carpet Museum 2014.jpg'),
    ('baku-boulevard', 'baku', 'PARK', 2, 'HOURS', 4.7, 'Бакинский бульвар', 'Baku Boulevard', 'Баку бульвары', 40.36300000, 49.84000000, 'Baku Boulevard Seaside National Park', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Baku Boulevard.jpg'),
    ('upland-park-baku', 'baku', 'PARK', 1, 'HOURS', 4.7, 'Нагорный парк Баку', 'Upland Park Baku', 'Баку тау үсті паркі', 40.35780000, 49.82720000, 'Upland Park Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'View of Baku from Highland Park.jpg'),
    ('fountains-square-nizami-street', 'baku', 'FOOD', 2, 'HOURS', 4.6, 'Площадь фонтанов и улица Низами', 'Fountains Square and Nizami Street', 'Фонтан алаңы және Низами көшесі', 40.37170000, 49.83700000, 'Fountains Square Nizami Street Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Fountains Square in Baku.jpg'),
    ('taza-bazaar-baku', 'baku', 'MARKET', 2, 'HOURS', 4.5, 'Таза базар в Баку', 'Taza Bazaar Baku', 'Баку Таза базары', 40.38110000, 49.83210000, 'Taza Bazaar Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Baku bazaar.jpg'),
    ('port-baku-mall', 'baku', 'SHOPPING', 2, 'HOURS', 4.5, 'Port Baku Mall', 'Port Baku Mall', 'Port Baku Mall', 40.37870000, 49.86100000, 'Port Baku Mall', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Baku Azerbaijan.jpg'),
    ('deniz-mall', 'baku', 'SHOPPING', 2, 'HOURS', 4.5, 'Deniz Mall', 'Deniz Mall', 'Deniz Mall', 40.35890000, 49.83940000, 'Deniz Mall Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Baku Boulevard.jpg'),
    ('baku-zoological-park', 'baku', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Бакинский зоопарк', 'Baku Zoological Park', 'Баку хайуанаттар бағы', 40.39750000, 49.84220000, 'Baku Zoological Park', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Baku Azerbaijan.jpg'),
    ('bibi-heybat-mosque', 'baku', 'TEMPLE', 1, 'HOURS', 4.7, 'Мечеть Биби-Эйбат', 'Bibi-Heybat Mosque', 'Биби-Эйбат мешіті', 40.30860000, 49.82030000, 'Bibi-Heybat Mosque Baku', ARRAY['baku']::text[], ARRAY['baku']::text[], 'Bibi-Heybat Mosque Baku.jpg'),
    ('ateshgah-fire-temple', 'absheron', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм огня Атешгях', 'Ateshgah Fire Temple', 'Атешгях от ғибадатханасы', 40.41590000, 50.00890000, 'Ateshgah Fire Temple Azerbaijan', ARRAY['absheron']::text[], ARRAY['baku', 'absheron']::text[], 'Ateshgah Fire Temple near Baku.jpg'),
    ('yanar-dag-burning-mountain', 'absheron', 'NATURE', 1, 'HOURS', 4.6, 'Горящая гора Янардаг', 'Yanar Dag Burning Mountain', 'Янардаг жанып тұрған тауы', 40.50220000, 49.89200000, 'Yanar Dag Azerbaijan', ARRAY['absheron']::text[], ARRAY['baku', 'absheron']::text[], 'Yanar Dag Azerbaijan.jpg'),
    ('gala-reserve', 'absheron', 'MUSEUM', 2, 'HOURS', 4.5, 'Гала - историко-этнографический заповедник', 'Gala State Historical-Ethnographic Reserve', 'Гала тарихи-этнографиялық қорығы', 40.45720000, 50.16760000, 'Gala State Historical Ethnographic Reserve Azerbaijan', ARRAY['absheron']::text[], ARRAY['baku', 'absheron']::text[], 'Gala State Historical Ethnographic Reserve.jpg'),
    ('absheron-national-park', 'absheron', 'PARK', 3, 'HOURS', 4.5, 'Апшеронский национальный парк', 'Absheron National Park', 'Апшерон ұлттық паркі', 40.31000000, 50.30000000, 'Absheron National Park Azerbaijan', ARRAY['absheron']::text[], ARRAY['baku', 'absheron']::text[], 'Absheron National Park Azerbaijan.jpg'),
    ('bilgah-beach', 'absheron', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Бильгя', 'Bilgah Beach', 'Білгә жағажайы', 40.57730000, 50.03310000, 'Bilgah Beach Azerbaijan', ARRAY['absheron']::text[], ARRAY['baku', 'absheron']::text[], 'Caspian Sea beach Azerbaijan.jpg'),

    ('gobustan-rock-art', 'gobustan', 'MUSEUM', 3, 'HOURS', 4.9, 'Гобустанский заповедник наскальных рисунков', 'Gobustan Rock Art Cultural Landscape', 'Гобустан жартас суреттері мәдени ландшафты', 40.10420000, 49.41580000, 'Gobustan Rock Art Cultural Landscape Azerbaijan', ARRAY['gobustan']::text[], ARRAY['baku', 'gobustan']::text[], 'Gobustan rock art Azerbaijan.jpg'),
    ('gobustan-mud-volcanoes', 'mud-volcanoes', 'NATURE', 2, 'HOURS', 4.7, 'Грязевые вулканы Гобустана', 'Gobustan Mud Volcanoes', 'Гобустан балшық жанартаулары', 40.10000000, 49.39000000, 'Gobustan Mud Volcanoes Azerbaijan', ARRAY['mud-volcanoes']::text[], ARRAY['baku', 'gobustan', 'mud-volcanoes']::text[], 'Mud volcanoes in Gobustan Azerbaijan.jpg'),
    ('diri-baba-mausoleum', 'gobustan', 'TEMPLE', 1, 'HOURS', 4.6, 'Мавзолей Дири-Баба', 'Diri Baba Mausoleum', 'Дири-Баба кесенесі', 40.53390000, 48.92820000, 'Diri Baba Mausoleum Azerbaijan', ARRAY['gobustan', 'shamakhi']::text[], ARRAY['baku', 'gobustan', 'shamakhi']::text[], 'Diri Baba Mausoleum.jpg'),
    ('juma-mosque-shamakhi', 'shamakhi', 'TEMPLE', 1, 'HOURS', 4.7, 'Джума-мечеть Шемахы', 'Juma Mosque Shamakhi', 'Шемаха Жұма мешіті', 40.63190000, 48.64170000, 'Juma Mosque Shamakhi Azerbaijan', ARRAY['shamakhi']::text[], ARRAY['baku', 'shamakhi']::text[], 'Juma Mosque Shamakhi Azerbaijan.jpg'),
    ('shamakhi-observatory', 'shamakhi', 'MUSEUM', 2, 'HOURS', 4.5, 'Шемахинская астрофизическая обсерватория', 'Shamakhi Astrophysical Observatory', 'Шемаха астрофизикалық обсерваториясы', 40.78190000, 48.59860000, 'Shamakhi Astrophysical Observatory Azerbaijan', ARRAY['shamakhi']::text[], ARRAY['baku', 'shamakhi']::text[], 'Shamakhi Astrophysical Observatory.jpg'),
    ('meysari-winery', 'shamakhi', 'FOOD', 2, 'HOURS', 4.5, 'Винодельня Meysari', 'Meysari Winery', 'Meysari шарап зауыты', 40.60700000, 48.68700000, 'Meysari Winery Azerbaijan', ARRAY['shamakhi']::text[], ARRAY['baku', 'shamakhi']::text[], 'Vineyards Azerbaijan.jpg'),
    ('lahij-copper-craft-quarter', 'lahij', 'SHOPPING', 2, 'HOURS', 4.7, 'Медные мастерские Лагича', 'Lahij Copper Craft Quarter', 'Лагич мыс шеберханалары', 40.84940000, 48.38570000, 'Lahij Copper Craft Quarter Azerbaijan', ARRAY['lahij']::text[], ARRAY['baku', 'shamakhi', 'lahij']::text[], 'Lahij Azerbaijan.jpg'),
    ('red-settlement-quba', 'quba', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Красная Слобода', 'Red Settlement Quba', 'Губа Қызыл қонысы', 41.37630000, 48.51470000, 'Red Settlement Quba Azerbaijan', ARRAY['quba']::text[], ARRAY['baku', 'quba']::text[], 'Quba Azerbaijan.jpg'),
    ('mountain-jews-museum', 'quba', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей горских евреев', 'Museum of Mountain Jews', 'Тау еврейлері музейі', 41.37390000, 48.51390000, 'Museum of Mountain Jews Quba', ARRAY['quba']::text[], ARRAY['quba']::text[], 'Quba Azerbaijan.jpg'),
    ('khinalig-village', 'khinalig', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Село Хыналыг', 'Khinalig Village', 'Хыналыг ауылы', 41.17870000, 48.12890000, 'Khinalig Village Azerbaijan', ARRAY['khinalig']::text[], ARRAY['quba', 'khinalig']::text[], 'Khinalig Azerbaijan.jpg'),
    ('shahdag-mountain-resort', 'shahdag', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Горный курорт Шахдаг', 'Shahdag Mountain Resort', 'Шахдаг тау курорты', 41.31660000, 48.14470000, 'Shahdag Mountain Resort Azerbaijan', ARRAY['shahdag', 'qusar']::text[], ARRAY['baku', 'qusar', 'shahdag']::text[], 'Shahdag Mountain Resort Azerbaijan.jpg'),
    ('shahdag-national-park', 'qusar', 'PARK', 5, 'HOURS', 4.7, 'Национальный парк Шахдаг', 'Shahdag National Park', 'Шахдаг ұлттық паркі', 41.26000000, 48.24000000, 'Shahdag National Park Azerbaijan', ARRAY['qusar', 'shahdag']::text[], ARRAY['qusar', 'shahdag']::text[], 'Shahdag National Park Azerbaijan.jpg'),
    ('laza-village-waterfalls', 'qusar', 'NATURE', 3, 'HOURS', 4.7, 'Село Лаза и водопады', 'Laza Village and Waterfalls', 'Лаза ауылы және сарқырамалары', 41.30500000, 48.13800000, 'Laza Village Waterfalls Azerbaijan', ARRAY['qusar']::text[], ARRAY['qusar', 'shahdag']::text[], 'Laza Azerbaijan.jpg'),

    ('sheki-khan-palace', 'sheki', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Дворец шекинских ханов', 'Sheki Khan Palace', 'Шеки хандары сарайы', 41.20470000, 47.19710000, 'Sheki Khan Palace Azerbaijan', ARRAY['sheki']::text[], ARRAY['baku', 'sheki']::text[], 'Palace of Shaki Khans.jpg'),
    ('sheki-caravanserai', 'sheki', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Шекинский караван-сарай', 'Sheki Caravanserai', 'Шеки керуен сарайы', 41.19990000, 47.18900000, 'Sheki Caravanserai Azerbaijan', ARRAY['sheki']::text[], ARRAY['sheki']::text[], 'Sheki Caravanserai Azerbaijan.jpg'),
    ('kish-albanian-temple', 'sheki', 'TEMPLE', 1, 'HOURS', 4.7, 'Албанский храм в Кише', 'Kish Albanian Temple', 'Киш албан ғибадатханасы', 41.25280000, 47.18860000, 'Kish Albanian Temple Azerbaijan', ARRAY['sheki']::text[], ARRAY['sheki']::text[], 'Kish Church Azerbaijan.jpg'),
    ('sheki-halva-workshop', 'sheki', 'FOOD', 1, 'HOURS', 4.6, 'Мастерская шекинской халвы', 'Sheki Halva Workshop', 'Шеки халва шеберханасы', 41.20000000, 47.19000000, 'Sheki Halva Workshop Azerbaijan', ARRAY['sheki']::text[], ARRAY['sheki']::text[], 'Sheki Azerbaijan.jpg'),
    ('sheki-bazaar', 'sheki', 'MARKET', 1, 'HOURS', 4.5, 'Шекинский базар', 'Sheki Bazaar', 'Шеки базары', 41.19900000, 47.19000000, 'Sheki Bazaar Azerbaijan', ARRAY['sheki']::text[], ARRAY['sheki']::text[], 'Sheki Azerbaijan.jpg'),
    ('tufandag-mountain-resort', 'gabala', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Горный курорт Туфандаг', 'Gabala Tufandag Mountain Resort', 'Габала Туфандаг тау курорты', 40.99280000, 47.84580000, 'Tufandag Mountain Resort Gabala', ARRAY['gabala']::text[], ARRAY['baku', 'gabala']::text[], 'Tufandag Azerbaijan.jpg'),
    ('gabaland-amusement-park', 'gabala', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Парк развлечений Gabaland', 'Gabaland Amusement Park', 'Gabaland ойын-сауық паркі', 40.98420000, 47.85200000, 'Gabaland Amusement Park Azerbaijan', ARRAY['gabala']::text[], ARRAY['gabala']::text[], 'Gabala Azerbaijan.jpg'),
    ('nohur-lake', 'gabala', 'NATURE', 3, 'HOURS', 4.7, 'Озеро Нохур', 'Nohur Lake', 'Нохур көлі', 40.99080000, 47.87970000, 'Nohur Lake Gabala Azerbaijan', ARRAY['gabala']::text[], ARRAY['gabala']::text[], 'Nohur Lake Azerbaijan.jpg'),
    ('old-gabala-archaeological-center', 'gabala', 'MUSEUM', 2, 'HOURS', 4.5, 'Археологический центр древней Габалы', 'Old Gabala Archaeological Center', 'Ескі Габала археологиялық орталығы', 40.99000000, 47.87000000, 'Old Gabala Archaeological Center Azerbaijan', ARRAY['gabala']::text[], ARRAY['gabala']::text[], 'Gabala Azerbaijan.jpg'),
    ('nizami-mausoleum', 'ganja', 'MUSEUM', 2, 'HOURS', 4.8, 'Мавзолей Низами Гянджеви', 'Nizami Mausoleum', 'Низами кесенесі', 40.68280000, 46.36090000, 'Nizami Mausoleum Ganja', ARRAY['ganja']::text[], ARRAY['baku', 'ganja']::text[], 'Nizami Mausoleum Ganja.jpg'),
    ('imamzadeh-ganja', 'ganja', 'TEMPLE', 2, 'HOURS', 4.7, 'Имамзаде в Гяндже', 'Imamzadeh Mausoleum Ganja', 'Гянджа Имамзаде кесенесі', 40.72420000, 46.32340000, 'Imamzadeh Mausoleum Ganja', ARRAY['ganja']::text[], ARRAY['ganja']::text[], 'Imamzadeh Ganja.jpg'),
    ('khan-baghi-park', 'ganja', 'PARK', 2, 'HOURS', 4.5, 'Парк Хан Багы', 'Khan Baghi Park', 'Хан бағы паркі', 40.68220000, 46.36000000, 'Khan Baghi Park Ganja', ARRAY['ganja']::text[], ARRAY['ganja']::text[], 'Ganja Azerbaijan.jpg'),
    ('ganja-mall', 'ganja', 'SHOPPING', 2, 'HOURS', 4.4, 'Ganja Mall', 'Ganja Mall', 'Ganja Mall', 40.68260000, 46.36060000, 'Ganja Mall Azerbaijan', ARRAY['ganja']::text[], ARRAY['ganja']::text[], 'Ganja Azerbaijan.jpg'),
    ('goygol-national-park', 'goygol', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Гёйгёль', 'Goygol National Park', 'Гёйгёль ұлттық паркі', 40.39250000, 46.33330000, 'Goygol National Park Azerbaijan', ARRAY['goygol']::text[], ARRAY['ganja', 'goygol']::text[], 'Goygol Lake Azerbaijan.jpg'),
    ('goygol-winery', 'goygol', 'FOOD', 2, 'HOURS', 4.5, 'Винодельня Гёйгёль', 'Goygol Winery', 'Гёйгёль шарап зауыты', 40.58500000, 46.31800000, 'Goygol Winery Azerbaijan', ARRAY['goygol']::text[], ARRAY['ganja', 'goygol']::text[], 'Vineyards Azerbaijan.jpg'),
    ('naftalan-oil-spa', 'naftalan', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Нефтяные ванны Нафталана', 'Naftalan Oil Spa', 'Нафталан мұнай шипажайы', 40.50670000, 46.82000000, 'Naftalan Oil Spa Azerbaijan', ARRAY['naftalan']::text[], ARRAY['ganja', 'naftalan']::text[], 'Naftalan Azerbaijan.jpg'),
    ('mingachevir-reservoir', 'mingachevir', 'BEACH', 3, 'HOURS', 4.5, 'Мингечевирское водохранилище', 'Mingachevir Reservoir', 'Мингечевир су қоймасы', 40.77000000, 47.03000000, 'Mingachevir Reservoir Azerbaijan', ARRAY['mingachevir']::text[], ARRAY['ganja', 'mingachevir']::text[], 'Mingachevir Reservoir Azerbaijan.jpg'),

    ('hirkan-national-park', 'hirkan', 'PARK', 5, 'HOURS', 4.8, 'Гирканский национальный парк', 'Hirkan National Park', 'Гиркан ұлттық паркі', 38.62730000, 48.70640000, 'Hirkan National Park Azerbaijan', ARRAY['hirkan', 'lankaran', 'astara']::text[], ARRAY['lankaran', 'hirkan']::text[], 'Hirkan National Park Azerbaijan.jpg'),
    ('gizil-agaj-national-park', 'gizil-agaj', 'PARK', 5, 'HOURS', 4.7, 'Национальный парк Гызыл-Агадж', 'Gizil-Agaj National Park', 'Гызыл-Агадж ұлттық паркі', 39.05000000, 48.90000000, 'Gizil-Agaj National Park Azerbaijan', ARRAY['gizil-agaj', 'lankaran']::text[], ARRAY['lankaran', 'gizil-agaj']::text[], 'Gizil-Agaj Azerbaijan.jpg'),
    ('lankaran-black-sand-beaches', 'lankaran', 'BEACH', 3, 'HOURS', 4.5, 'Черные песчаные пляжи Ленкорани', 'Lankaran Black-Sand Beaches', 'Ленкорань қара құм жағажайлары', 38.75400000, 48.85100000, 'Lankaran black sand beaches Azerbaijan', ARRAY['lankaran']::text[], ARRAY['lankaran']::text[], 'Lankaran Azerbaijan.jpg'),
    ('mir-ahmad-khan-house', 'lankaran', 'MUSEUM', 1, 'HOURS', 4.5, 'Дом Мир Ахмед-хана', 'Mir Ahmad Khan House', 'Мир Ахмед хан үйі', 38.75390000, 48.85140000, 'Mir Ahmad Khan House Lankaran', ARRAY['lankaran']::text[], ARRAY['lankaran']::text[], 'Lankaran Azerbaijan.jpg'),
    ('lankaran-bazaar', 'lankaran', 'MARKET', 1, 'HOURS', 4.5, 'Ленкоранский базар', 'Lankaran Bazaar', 'Ленкорань базары', 38.75460000, 48.85050000, 'Lankaran Bazaar Azerbaijan', ARRAY['lankaran']::text[], ARRAY['lankaran']::text[], 'Lankaran Azerbaijan.jpg'),
    ('tea-citrus-plantations', 'lankaran', 'FOOD', 2, 'HOURS', 4.6, 'Чайные и цитрусовые плантации', 'Tea and Citrus Plantations', 'Шай және цитрус плантациялары', 38.76000000, 48.75000000, 'Tea Citrus Plantations Lankaran Azerbaijan', ARRAY['lankaran']::text[], ARRAY['lankaran']::text[], 'Lankaran Azerbaijan.jpg'),
    ('astara-boulevard', 'astara', 'PARK', 2, 'HOURS', 4.5, 'Астаринский бульвар', 'Astara Boulevard', 'Астара бульвары', 38.45600000, 48.87500000, 'Astara Boulevard Azerbaijan', ARRAY['astara']::text[], ARRAY['lankaran', 'astara']::text[], 'Astara Azerbaijan.jpg'),
    ('yanar-bulag', 'astara', 'NATURE', 1, 'HOURS', 4.5, 'Огненный источник Янар Булаг', 'Yanar Bulag', 'Янар Булаг отты бұлағы', 38.48000000, 48.83000000, 'Yanar Bulag Astara Azerbaijan', ARRAY['astara']::text[], ARRAY['astara']::text[], 'Astara Azerbaijan.jpg'),
    ('masalli-istisu', 'masalli', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Горячие источники Масаллы Истису', 'Masalli Istisu Hot Springs', 'Масаллы Истису ыстық бұлақтары', 39.03300000, 48.66500000, 'Masalli Istisu Hot Springs Azerbaijan', ARRAY['masalli']::text[], ARRAY['lankaran', 'masalli']::text[], 'Masalli Azerbaijan.jpg'),
    ('museum-of-longevity', 'lerik', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей долголетия', 'Museum of Longevity', 'Ұзақ өмір музейі', 38.77360000, 48.41440000, 'Museum of Longevity Lerik', ARRAY['lerik']::text[], ARRAY['lankaran', 'lerik']::text[], 'Lerik Azerbaijan.jpg'),

    ('momine-khatun-mausoleum', 'nakhchivan', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Мавзолей Момине-хатун', 'Momine Khatun Mausoleum', 'Момине хатун кесенесі', 39.20890000, 45.41220000, 'Momine Khatun Mausoleum Nakhchivan', ARRAY['nakhchivan']::text[], ARRAY['nakhchivan']::text[], 'Momine Khatun Mausoleum.jpg'),
    ('nakhchivan-khans-palace', 'nakhchivan', 'MUSEUM', 1, 'HOURS', 4.6, 'Дворец нахичеванских ханов', 'Nakhchivan Khans Palace', 'Нахчыван хандары сарайы', 39.20860000, 45.41280000, 'Nakhchivan Khans Palace Azerbaijan', ARRAY['nakhchivan']::text[], ARRAY['nakhchivan']::text[], 'Nakhchivan Azerbaijan.jpg'),
    ('duzdag-salt-caves', 'nakhchivan', 'NATURE', 2, 'HOURS', 4.6, 'Соляные пещеры Дуздаг', 'Duzdag Salt Caves', 'Дуздаг тұз үңгірлері', 39.22100000, 45.48000000, 'Duzdag Salt Caves Nakhchivan', ARRAY['nakhchivan']::text[], ARRAY['nakhchivan']::text[], 'Nakhchivan Azerbaijan.jpg'),
    ('ordubad-reserve', 'ordubad', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Историко-архитектурный заповедник Ордубад', 'Ordubad Historical-Architectural Reserve', 'Ордубад тарихи-сәулет қорығы', 38.90770000, 46.02390000, 'Ordubad Historical Architectural Reserve Azerbaijan', ARRAY['ordubad']::text[], ARRAY['nakhchivan', 'ordubad']::text[], 'Ordubad Azerbaijan.jpg'),
    ('alinja-castle', 'julfa', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Крепость Алинджа', 'Alinja Castle', 'Алинджа қамалы', 39.20000000, 45.77000000, 'Alinja Castle Azerbaijan', ARRAY['julfa']::text[], ARRAY['nakhchivan', 'julfa']::text[], 'Alinja Castle Azerbaijan.jpg'),
    ('ashabi-kahf-cave', 'julfa', 'TEMPLE', 2, 'HOURS', 4.7, 'Пещера Асхаби-Кахф', 'Ashabi-Kahf Cave Complex', 'Асхаби-Кахф үңгір кешені', 39.22500000, 45.77500000, 'Ashabi Kahf Cave Complex Nakhchivan', ARRAY['julfa']::text[], ARRAY['nakhchivan', 'julfa']::text[], 'Ashabi-Kahf Nakhchivan.jpg'),
    ('batabat-lake', 'batabat', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Батабат', 'Batabat Lake', 'Батабат көлі', 39.51700000, 45.70000000, 'Batabat Lake Nakhchivan', ARRAY['batabat']::text[], ARRAY['nakhchivan', 'batabat']::text[], 'Batabat Lake Azerbaijan.jpg');

CREATE TEMP TABLE seed_azerbaijan_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-azerbaijan-place:' || seed.slug) AS place_hash,
        md5('id-azerbaijan-media:' || seed.slug) AS media_hash
    FROM seed_azerbaijan_priority_places seed
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
    ARRAY['azerbaijan', city_id, slug, lower(category), 'azerbaijan-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Азербайджана: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Azerbaijan tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Әзірбайжан туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    price_amount,
    price_currency,
    rating,
    tags,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'AZ',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20::numeric
        ELSE 10::numeric
    END,
    'AZN',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_azerbaijan_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    default_locale = EXCLUDED.default_locale,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    price_amount = EXCLUDED.price_amount,
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
FROM seed_azerbaijan_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_azerbaijan_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_azerbaijan_resolved_places
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
FROM seed_azerbaijan_resolved_places seed
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
FROM seed_azerbaijan_resolved_places
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
    'AZ',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_azerbaijan_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
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
    'DEPARTURE',
    'AZ',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_azerbaijan_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
