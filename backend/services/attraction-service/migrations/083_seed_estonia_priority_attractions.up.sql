-- Priority Estonia destination attractions seed.
-- The seed covers Tallinn, South Estonia, West Estonia, islands, North Estonia, East Estonia, parks, beaches, museums, markets, malls, and entertainment points.

DROP TABLE IF EXISTS seed_estonia_resolved_attractions;
DROP TABLE IF EXISTS seed_estonia_priority_attractions;

CREATE TEMP TABLE seed_estonia_priority_attractions (
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

INSERT INTO seed_estonia_priority_attractions (
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
    ('tallinn-old-town', 'tallinn', 'ARCHITECTURE', 4, 4.9, 'Старый город Таллина', 'Tallinn Old Town', 'Таллин ескі қаласы', 59.43720000, 24.74540000, 'Tallinn_old_town.jpg', ARRAY['tallinn', 'unesco', 'old-town']::text[]),
    ('tallinn-town-hall-square', 'tallinn', 'ARCHITECTURE', 1, 4.8, 'Ратушная площадь Таллина', 'Tallinn Town Hall Square', 'Таллин ратуша алаңы', 59.43700000, 24.74530000, 'Tallinn_Town_Hall_Square.jpg', ARRAY['tallinn', 'old-town', 'square']::text[]),
    ('toompea-castle', 'tallinn', 'ARCHITECTURE', 1, 4.7, 'Замок Тоомпеа', 'Toompea Castle', 'Тоомпеа қамалы', 59.43580000, 24.73740000, 'Toompea_Castle.jpg', ARRAY['tallinn', 'castle', 'government']::text[]),
    ('alexander-nevsky-cathedral-tallinn', 'tallinn', 'TEMPLE', 1, 4.8, 'Собор Александра Невского', 'Alexander Nevsky Cathedral Tallinn', 'Александр Невский соборы', 59.43570000, 24.73920000, 'Alexander_Nevsky_Cathedral_Tallinn.jpg', ARRAY['tallinn', 'orthodox', 'cathedral']::text[]),
    ('st-olafs-church', 'tallinn', 'TEMPLE', 1, 4.7, 'Церковь Святого Олафа', 'St. Olafs Church Tallinn', 'Әулие Олаф шіркеуі', 59.44130000, 24.74760000, 'St_Olafs_Church_Tallinn.jpg', ARRAY['tallinn', 'church', 'viewpoint']::text[]),
    ('seaplane-harbour', 'tallinn', 'MUSEUM', 3, 4.8, 'Летная гавань', 'Seaplane Harbour', 'Гидроұшақ айлағы', 59.45150000, 24.73840000, 'Seaplane_Harbour_Tallinn.jpg', ARRAY['tallinn', 'maritime', 'family']::text[]),
    ('kumu-art-museum', 'tallinn', 'MUSEUM', 3, 4.7, 'Художественный музей Kumu', 'Kumu Art Museum', 'Kumu өнер музейі', 59.43620000, 24.79670000, 'Kumu_Art_Museum.jpg', ARRAY['tallinn', 'art', 'museum']::text[]),
    ('kadriorg-park', 'tallinn', 'PARK', 2, 4.8, 'Парк Кадриорг', 'Kadriorg Park', 'Кадриорг саябағы', 59.43830000, 24.79240000, 'Kadriorg_Park.jpg', ARRAY['tallinn', 'park', 'palace']::text[]),
    ('estonian-open-air-museum', 'tallinn', 'MUSEUM', 3, 4.7, 'Эстонский музей под открытым небом', 'Estonian Open Air Museum', 'Эстония ашық аспан музейі', 59.43120000, 24.63860000, 'Estonian_Open_Air_Museum.jpg', ARRAY['tallinn', 'open-air-museum', 'culture']::text[]),
    ('tallinn-tv-tower', 'tallinn', 'ENTERTAINMENT', 2, 4.6, 'Таллинская телебашня', 'Tallinn TV Tower', 'Таллин телемұнарасы', 59.47120000, 24.88760000, 'Tallinn_TV_Tower.jpg', ARRAY['tallinn', 'viewpoint', 'family']::text[]),
    ('pirita-beach', 'tallinn', 'BEACH', 2, 4.6, 'Пляж Пирита', 'Pirita Beach', 'Пирита жағажайы', 59.46960000, 24.83280000, 'Pirita_Beach.jpg', ARRAY['tallinn', 'beach', 'summer']::text[]),
    ('telliskivi-creative-city', 'tallinn', 'ENTERTAINMENT', 2, 4.6, 'Творческий город Telliskivi', 'Telliskivi Creative City', 'Telliskivi шығармашылық қаласы', 59.43940000, 24.72870000, 'Telliskivi_Creative_City.jpg', ARRAY['tallinn', 'creative-quarter', 'evening']::text[]),
    ('fotografiska-tallinn', 'tallinn', 'MUSEUM', 2, 4.6, 'Fotografiska Tallinn', 'Fotografiska Tallinn', 'Fotografiska Tallinn', 59.43920000, 24.72940000, 'Fotografiska_Tallinn.jpg', ARRAY['tallinn', 'photo', 'museum']::text[]),
    ('noblessner', 'tallinn', 'ENTERTAINMENT', 2, 4.6, 'Квартал Noblessner', 'Noblessner', 'Noblessner кварталы', 59.45190000, 24.72850000, 'Noblessner_Tallinn.jpg', ARRAY['tallinn', 'waterfront', 'restaurants']::text[]),
    ('rotermann-quarter', 'tallinn', 'SHOPPING', 2, 4.6, 'Квартал Ротерманни', 'Rotermann Quarter', 'Ротерманн кварталы', 59.43860000, 24.75610000, 'Rotermann_Quarter_Tallinn.jpg', ARRAY['tallinn', 'shopping', 'architecture']::text[]),
    ('balti-jaama-turg', 'tallinn', 'MARKET', 1, 4.7, 'Balti Jaama Turg', 'Balti Jaama Turg', 'Balti Jaama Turg', 59.44090000, 24.73560000, 'Balti_Jaama_Turg.jpg', ARRAY['tallinn', 'food-market', 'local']::text[]),
    ('cafe-maiasmokk', 'tallinn', 'FOOD', 1, 4.5, 'Кафе Maiasmokk', 'Cafe Maiasmokk', 'Maiasmokk кафесі', 59.43810000, 24.74770000, 'Cafe_Maiasmokk_Tallinn.jpg', ARRAY['tallinn', 'cafe', 'historic']::text[]),

    ('tartu-town-hall-square', 'tartu', 'ARCHITECTURE', 1, 4.7, 'Ратушная площадь Тарту', 'Tartu Town Hall Square', 'Тарту ратуша алаңы', 58.38000000, 26.72250000, 'Tartu_Town_Hall_Square.jpg', ARRAY['tartu', 'square', 'old-town']::text[]),
    ('estonian-national-museum', 'tartu', 'MUSEUM', 3, 4.8, 'Эстонский национальный музей', 'Estonian National Museum', 'Эстония ұлттық музейі', 58.39810000, 26.74320000, 'Estonian_National_Museum.jpg', ARRAY['tartu', 'culture', 'museum']::text[]),
    ('ahhaa-science-centre', 'tartu', 'ENTERTAINMENT', 3, 4.8, 'Научный центр AHHAA', 'AHHAA Science Centre', 'AHHAA ғылым орталығы', 58.37770000, 26.73040000, 'AHHAA_Tartu.jpg', ARRAY['tartu', 'science', 'family']::text[]),
    ('tartu-cathedral', 'tartu', 'TEMPLE', 2, 4.6, 'Тартуский кафедральный собор', 'Tartu Cathedral', 'Тарту кафедралды соборы', 58.38100000, 26.71410000, 'Tartu_Cathedral.jpg', ARRAY['tartu', 'cathedral', 'history']::text[]),
    ('university-of-tartu-museum', 'tartu', 'MUSEUM', 2, 4.6, 'Музей Тартуского университета', 'University of Tartu Museum', 'Тарту университеті музейі', 58.38090000, 26.71400000, 'University_of_Tartu_Museum.jpg', ARRAY['tartu', 'university', 'museum']::text[]),
    ('botanical-garden-tartu', 'tartu', 'PARK', 2, 4.6, 'Ботанический сад Тартуского университета', 'University of Tartu Botanical Garden', 'Тарту университетінің ботаникалық бағы', 58.38450000, 26.72210000, 'University_of_Tartu_Botanical_Garden.jpg', ARRAY['tartu', 'garden', 'plants']::text[]),
    ('st-johns-church-tartu', 'tartu', 'TEMPLE', 1, 4.6, 'Церковь Святого Иоанна в Тарту', 'St. Johns Church in Tartu', 'Тартудағы Әулие Иоанн шіркеуі', 58.38270000, 26.72050000, 'St_Johns_Church_Tartu.jpg', ARRAY['tartu', 'church', 'old-town']::text[]),
    ('aparaaditehas', 'tartu', 'ENTERTAINMENT', 2, 4.6, 'Творческий город Aparaaditehas', 'Aparaaditehas Creative City', 'Aparaaditehas шығармашылық қаласы', 58.37170000, 26.70660000, 'Aparaaditehas_Tartu.jpg', ARRAY['tartu', 'creative-quarter', 'food']::text[]),

    ('lake-puhajarv', 'otepaa', 'NATURE', 3, 4.7, 'Озеро Пюхаярв', 'Lake Puhajarv', 'Пюхаярв көлі', 58.04980000, 26.45350000, 'Lake_Puhajarv.jpg', ARRAY['otepaa', 'lake', 'nature']::text[]),
    ('puhajarve-beach', 'otepaa', 'BEACH', 2, 4.6, 'Пляж Пюхаярве', 'Puhajarve Beach', 'Пюхаярве жағажайы', 58.04700000, 26.45000000, 'Puhajarve_Beach.jpg', ARRAY['otepaa', 'beach', 'lake']::text[]),
    ('otepaa-adventure-park', 'otepaa', 'ENTERTAINMENT', 3, 4.6, 'Парк приключений Отепя', 'Otepaa Adventure Park', 'Отепя шытырман паркі', 58.05770000, 26.49690000, 'Otepaa_Adventure_Park.jpg', ARRAY['otepaa', 'family', 'adventure']::text[]),
    ('tehvandi-sports-center', 'otepaa', 'ENTERTAINMENT', 3, 4.6, 'Спортивный центр Tehvandi', 'Tehvandi Sports Center', 'Tehvandi спорт орталығы', 58.05800000, 26.49970000, 'Tehvandi_Sports_Center.jpg', ARRAY['otepaa', 'sports', 'winter']::text[]),
    ('sangaste-castle', 'otepaa', 'ARCHITECTURE', 2, 4.6, 'Замок Сангасте', 'Sangaste Castle', 'Сангасте қамалы', 57.91380000, 26.32790000, 'Sangaste_Castle.jpg', ARRAY['otepaa', 'castle', 'architecture']::text[]),

    ('suur-munamagi', 'vorumaa', 'NATURE', 2, 4.8, 'Смотровая башня Суур-Мунамяги', 'Suur Munamagi observation tower', 'Суур-Мунамяги бақылау мұнарасы', 57.71420000, 27.05940000, 'Suur_Munamagi.jpg', ARRAY['vorumaa', 'viewpoint', 'highest-point']::text[]),
    ('hinni-canyon', 'vorumaa', 'NATURE', 2, 4.6, 'Каньон Хинни', 'Hinni Canyon', 'Хинни каньоны', 57.73040000, 27.09530000, 'Hinni_Canyon.jpg', ARRAY['vorumaa', 'canyon', 'hiking']::text[]),
    ('piusa-caves', 'vorumaa', 'NATURE', 2, 4.6, 'Пещеры Пиуза', 'Piusa Caves Visitor Centre', 'Пиуза үңгірлері', 57.84260000, 27.46660000, 'Piusa_Caves.jpg', ARRAY['vorumaa', 'caves', 'visitor-centre']::text[]),
    ('vastseliina-castle', 'vorumaa', 'ARCHITECTURE', 2, 4.6, 'Руины замка Вастселийна', 'Ruins of Vastseliina Bishops Castle', 'Вастселийна қамалының қирандылары', 57.74290000, 27.27460000, 'Vastseliina_Castle.jpg', ARRAY['vorumaa', 'castle', 'history']::text[]),
    ('tamula-beach', 'vorumaa', 'BEACH', 2, 4.5, 'Пляж озера Тамула', 'Tamula Lake beach and promenade', 'Тамула көлі жағажайы', 57.84250000, 27.01510000, 'Tamula_Lake_Beach.jpg', ARRAY['vorumaa', 'beach', 'promenade']::text[]),

    ('viljandi-castle-ruins', 'viljandi', 'ARCHITECTURE', 2, 4.8, 'Руины замка Вильянди', 'Viljandi Castle Ruins', 'Вильянди қамалының қирандылары', 58.36160000, 25.59790000, 'Viljandi_Castle_Ruins.jpg', ARRAY['viljandi', 'castle', 'viewpoint']::text[]),
    ('viljandi-castle-park', 'viljandi', 'PARK', 2, 4.7, 'Замковый парк Вильянди', 'Viljandi Castle Park', 'Вильянди қамал саябағы', 58.36240000, 25.59760000, 'Viljandi_Castle_Park.jpg', ARRAY['viljandi', 'park', 'castle']::text[]),
    ('viljandi-suspension-bridge', 'viljandi', 'ARCHITECTURE', 1, 4.6, 'Вильяндиский подвесной мост', 'Viljandi Suspension Bridge', 'Вильянди аспалы көпірі', 58.36020000, 25.59720000, 'Viljandi_Suspension_Bridge.jpg', ARRAY['viljandi', 'bridge', 'photo-stop']::text[]),
    ('lake-viljandi-beach', 'viljandi', 'BEACH', 2, 4.6, 'Пляж озера Вильянди', 'Lake Viljandi Beach', 'Вильянди көлі жағажайы', 58.35880000, 25.60230000, 'Lake_Viljandi_Beach.jpg', ARRAY['viljandi', 'beach', 'lake']::text[]),
    ('kondas-centre', 'viljandi', 'MUSEUM', 1, 4.5, 'Центр Kondas', 'Kondas Centre', 'Kondas орталығы', 58.36300000, 25.59830000, 'Kondas_Centre.jpg', ARRAY['viljandi', 'art', 'museum']::text[]),

    ('parnu-beach', 'parnu', 'BEACH', 3, 4.8, 'Пляж Пярну', 'Parnu Beach', 'Пярну жағажайы', 58.37380000, 24.49620000, 'Parnu_Beach.jpg', ARRAY['parnu', 'beach', 'summer-capital']::text[]),
    ('parnu-coastal-meadow-trail', 'parnu', 'NATURE', 2, 4.6, 'Прибрежная тропа Пярну', 'Parnu coastal meadow hiking trail', 'Пярну жағалау шалғыны соқпағы', 58.37230000, 24.48750000, 'Parnu_Coastal_Meadow.jpg', ARRAY['parnu', 'nature-trail', 'birdwatching']::text[]),
    ('parnu-beach-park', 'parnu', 'PARK', 2, 4.6, 'Пляжный парк Пярну', 'Parnu Beach Park', 'Пярну жағажай саябағы', 58.37500000, 24.50150000, 'Parnu_Beach_Park.jpg', ARRAY['parnu', 'park', 'resort']::text[]),
    ('parnu-museum', 'parnu', 'MUSEUM', 2, 4.5, 'Пярнуский музей', 'Parnu Museum', 'Пярну музейі', 58.38430000, 24.50790000, 'Parnu_Museum.jpg', ARRAY['parnu', 'museum', 'history']::text[]),
    ('tallinn-gate-parnu', 'parnu', 'ARCHITECTURE', 1, 4.5, 'Таллинские ворота в Пярну', 'Tallinn Gate', 'Пярну Таллин қақпасы', 58.38350000, 24.49310000, 'Tallinn_Gate_Parnu.jpg', ARRAY['parnu', 'fortification', 'old-town']::text[]),
    ('lottemaa-theme-park', 'parnu', 'ENTERTAINMENT', 5, 4.7, 'Парк Lottemaa', 'Lottemaa Theme Park', 'Lottemaa ойын-сауық паркі', 58.23850000, 24.55280000, 'Lottemaa.jpg', ARRAY['parnu', 'theme-park', 'family']::text[]),

    ('haapsalu-castle', 'haapsalu', 'ARCHITECTURE', 2, 4.8, 'Хаапсалуский замок', 'Haapsalu Castle', 'Хаапсалу қамалы', 58.94750000, 23.53610000, 'Haapsalu_Castle.jpg', ARRAY['haapsalu', 'castle', 'history']::text[]),
    ('africa-beach-haapsalu', 'haapsalu', 'BEACH', 2, 4.5, 'Африканский пляж и променад', 'Africa Beach and Promenade', 'Африка жағажайы және серуенжолы', 58.94980000, 23.52000000, 'Africa_Beach_Haapsalu.jpg', ARRAY['haapsalu', 'beach', 'promenade']::text[]),
    ('haapsalu-railway-museum', 'haapsalu', 'MUSEUM', 2, 4.6, 'Железнодорожный музей Хаапсалу', 'Haapsalu Railway and Communications Museum', 'Хаапсалу теміржол және байланыс музейі', 58.93970000, 23.53240000, 'Haapsalu_Railway_Station.jpg', ARRAY['haapsalu', 'railway', 'museum']::text[]),
    ('ilons-wonderland', 'haapsalu', 'ENTERTAINMENT', 2, 4.5, 'Ilons Wonderland', 'Ilons Wonderland', 'Ilons Wonderland', 58.94740000, 23.53900000, 'Ilons_Wonderland.jpg', ARRAY['haapsalu', 'family', 'children']::text[]),

    ('kuressaare-castle', 'kuressaare', 'ARCHITECTURE', 3, 4.8, 'Епископский замок Курессааре', 'Kuressaare Castle', 'Курессааре қамалы', 58.24790000, 22.48050000, 'Kuressaare_Castle.jpg', ARRAY['kuressaare', 'castle', 'museum']::text[]),
    ('kuressaare-town-park', 'kuressaare', 'PARK', 2, 4.6, 'Городской парк Курессааре', 'Kuressaare Town Park', 'Курессааре қалалық саябағы', 58.24820000, 22.48160000, 'Kuressaare_Town_Park.jpg', ARRAY['kuressaare', 'park', 'castle']::text[]),
    ('kuressaare-town-hall', 'kuressaare', 'ARCHITECTURE', 1, 4.5, 'Ратуша Курессааре', 'Kuressaare Town Hall', 'Курессааре ратушасы', 58.25250000, 22.48690000, 'Kuressaare_Town_Hall.jpg', ARRAY['kuressaare', 'old-town', 'architecture']::text[]),
    ('saare-kek-museum', 'kuressaare', 'MUSEUM', 2, 4.5, 'Музей Saare KEK', 'Saare KEK Museum', 'Saare KEK музейі', 58.25960000, 22.49220000, 'Saare_KEK_Museum.jpg', ARRAY['kuressaare', 'museum', 'modernism']::text[]),

    ('kaali-meteorite-crater', 'saaremaa', 'NATURE', 2, 4.7, 'Метеоритные кратеры Каали', 'Kaali Meteorite Crater', 'Каали метеорит кратері', 58.37010000, 22.66830000, 'Kaali_crater.jpg', ARRAY['saaremaa', 'crater', 'nature']::text[]),
    ('panga-cliff', 'saaremaa', 'NATURE', 2, 4.7, 'Клиф Панга', 'Panga cliff and recreation area', 'Панга жартасы', 58.57270000, 22.29020000, 'Panga_Cliff.jpg', ARRAY['saaremaa', 'cliff', 'coast']::text[]),
    ('angla-windmill-mount', 'saaremaa', 'ARCHITECTURE', 2, 4.6, 'Ветряные мельницы Англа', 'Angla Windmill Mount', 'Англа жел диірмендері', 58.52640000, 22.70080000, 'Angla_Windmills.jpg', ARRAY['saaremaa', 'windmills', 'culture']::text[]),
    ('sorve-lighthouse', 'saaremaa', 'ARCHITECTURE', 2, 4.6, 'Маяк Сырве', 'Sorve Lighthouse and Visitor Center', 'Сырве шамшырағы', 57.90990000, 22.05520000, 'Sorve_Lighthouse.jpg', ARRAY['saaremaa', 'lighthouse', 'viewpoint']::text[]),
    ('vilsandi-national-park', 'saaremaa', 'NATURE', 4, 4.7, 'Национальный парк Вильсанди', 'Vilsandi National Park', 'Вильсанди ұлттық паркі', 58.38000000, 21.86000000, 'Vilsandi_National_Park.jpg', ARRAY['saaremaa', 'national-park', 'islands']::text[]),
    ('mandjala-beach', 'saaremaa', 'BEACH', 2, 4.5, 'Пляж Мяндьяла', 'Mandjala Beach', 'Мяндьяла жағажайы', 58.21150000, 22.32870000, 'Mandjala_Beach.jpg', ARRAY['saaremaa', 'beach', 'family']::text[]),

    ('kopu-lighthouse', 'hiiumaa', 'ARCHITECTURE', 2, 4.8, 'Маяк Кыпу', 'Kopu Lighthouse', 'Кыпу шамшырағы', 58.91670000, 22.19970000, 'Kopu_Lighthouse.jpg', ARRAY['hiiumaa', 'lighthouse', 'viewpoint']::text[]),
    ('tahkuna-lighthouse', 'hiiumaa', 'ARCHITECTURE', 2, 4.6, 'Маяк Тахкуна', 'Tahkuna Lighthouse', 'Тахкуна шамшырағы', 59.09190000, 22.58640000, 'Tahkuna_Lighthouse.jpg', ARRAY['hiiumaa', 'lighthouse', 'coast']::text[]),
    ('saaretirp', 'hiiumaa', 'NATURE', 2, 4.6, 'Сяэретирп', 'Saaretirp', 'Saaretirp', 58.80090000, 22.99450000, 'Saaretirp_Hiiumaa.jpg', ARRAY['hiiumaa', 'spit', 'nature']::text[]),
    ('orjaku-study-trail', 'hiiumaa', 'NATURE', 2, 4.5, 'Учебная тропа Орьяку', 'Orjaku study trail', 'Орьяку оқу соқпағы', 58.78700000, 22.79000000, 'Orjaku_Study_Trail.jpg', ARRAY['hiiumaa', 'trail', 'birdwatching']::text[]),
    ('windtower-experience-centre', 'hiiumaa', 'ENTERTAINMENT', 2, 4.5, 'Windtower Experience Centre', 'Windtower Experience Centre', 'Windtower Experience Centre', 58.81710000, 22.77320000, 'Windtower_Experience_Centre.jpg', ARRAY['hiiumaa', 'family', 'experience']::text[]),
    ('luidja-beach', 'hiiumaa', 'BEACH', 2, 4.5, 'Пляж Луйдья', 'Luidja Beach', 'Луйдья жағажайы', 58.99750000, 22.45110000, 'Luidja_Beach.jpg', ARRAY['hiiumaa', 'beach', 'camping']::text[]),

    ('lahemaa-national-park', 'lahemaa', 'PARK', 5, 4.9, 'Национальный парк Лахемаа', 'Lahemaa National Park', 'Лахемаа ұлттық паркі', 59.56670000, 25.80000000, 'Lahemaa_National_Park.jpg', ARRAY['lahemaa', 'national-park', 'forest']::text[]),
    ('viru-bog-trail', 'lahemaa', 'NATURE', 3, 4.8, 'Учебная тропа болота Виру', 'Viru Bog Nature Trail', 'Виру батпағы соқпағы', 59.47160000, 25.63680000, 'Viru_Bog.jpg', ARRAY['lahemaa', 'bog', 'boardwalk']::text[]),
    ('palmse-manor', 'lahemaa', 'ARCHITECTURE', 2, 4.6, 'Мыза Палмсе', 'Palmse Manor and Open-Air Museum', 'Палмсе мызасы', 59.51100000, 25.95810000, 'Palmse_Manor.jpg', ARRAY['lahemaa', 'manor', 'museum']::text[]),
    ('sagadi-manor', 'lahemaa', 'ARCHITECTURE', 2, 4.6, 'Мыза Сагади', 'Sagadi Manor', 'Сагади мызасы', 59.53540000, 26.09000000, 'Sagadi_Manor.jpg', ARRAY['lahemaa', 'manor', 'forest']::text[]),
    ('altja-fishing-village', 'lahemaa', 'ARCHITECTURE', 2, 4.6, 'Рыбацкая деревня Алтья', 'Altja fishing village', 'Алтья балықшылар ауылы', 59.57790000, 26.10250000, 'Altja_Fishing_Village.jpg', ARRAY['lahemaa', 'village', 'coast']::text[]),
    ('vosu-beach', 'lahemaa', 'BEACH', 2, 4.5, 'Пляж Вызу', 'Vosu Beach', 'Вызу жағажайы', 59.57710000, 25.96760000, 'Vosu_Beach.jpg', ARRAY['lahemaa', 'beach', 'summer']::text[]),
    ('jagala-waterfall', 'lahemaa', 'NATURE', 2, 4.7, 'Водопад Ягала', 'Jagala Waterfall', 'Ягала сарқырамасы', 59.44990000, 25.17840000, 'Jagala_Waterfall.jpg', ARRAY['lahemaa', 'waterfall', 'day-trip']::text[]),
    ('hara-harbour', 'lahemaa', 'MUSEUM', 2, 4.5, 'Подводная база в гавани Хара', 'Submarine base at Hara Harbor', 'Хара айлағындағы сүңгуір қайық базасы', 59.58500000, 25.63990000, 'Hara_Harbour.jpg', ARRAY['lahemaa', 'industrial-heritage', 'coast']::text[]),

    ('narva-castle', 'narva', 'MUSEUM', 3, 4.8, 'Нарвский замок', 'Narva Castle', 'Нарва қамалы', 59.37590000, 28.20170000, 'Narva_Castle.jpg', ARRAY['narva', 'castle', 'museum']::text[]),
    ('narva-river-promenade', 'narva', 'PARK', 2, 4.6, 'Нарвский речной променад', 'Narva River Promenade', 'Нарва өзені серуенжолы', 59.37700000, 28.20500000, 'Narva_River_Promenade.jpg', ARRAY['narva', 'riverfront', 'walk']::text[]),
    ('victoria-bastion-casemates', 'narva', 'MUSEUM', 2, 4.6, 'Казематы бастиона Виктория', 'Casemates of the Bastion Victoria', 'Виктория бастионы казематтары', 59.38000000, 28.19380000, 'Victoria_Bastion_Narva.jpg', ARRAY['narva', 'fortifications', 'museum']::text[]),
    ('kreenholm-district', 'narva', 'ARCHITECTURE', 2, 4.5, 'Кренгольмский квартал', 'Kreenholm District', 'Кренгольм ауданы', 59.35760000, 28.18720000, 'Kreenholm_Manufacturing_Company.jpg', ARRAY['narva', 'industrial-heritage', 'architecture']::text[]),
    ('narva-town-hall', 'narva', 'ARCHITECTURE', 1, 4.5, 'Нарвская ратуша', 'Narva Town Hall', 'Нарва ратушасы', 59.37900000, 28.19890000, 'Narva_Town_Hall.jpg', ARRAY['narva', 'old-town', 'architecture']::text[]),
    ('narva-alexander-cathedral', 'narva', 'TEMPLE', 1, 4.5, 'Нарвский Александровский собор', 'Narva Alexanders Cathedral', 'Нарва Александр соборы', 59.36770000, 28.18720000, 'Narva_Alexander_Cathedral.jpg', ARRAY['narva', 'church', 'cathedral']::text[]),
    ('joaoru-beach', 'narva', 'BEACH', 2, 4.5, 'Пляж Йоаорг', 'Joaoru beach and recreation area', 'Йоаорг жағажайы', 59.37450000, 28.20350000, 'Joaoru_Beach_Narva.jpg', ARRAY['narva', 'beach', 'river']::text[]),

    ('narva-joesuu-beach', 'narva-joesuu', 'BEACH', 3, 4.8, 'Пляж Нарва-Йыэсуу', 'Narva-Joesuu beach', 'Нарва-Йыэсуу жағажайы', 59.45900000, 28.03800000, 'Narva-Joesuu_Beach.jpg', ARRAY['narva-joesuu', 'beach', 'spa']::text[]),
    ('narva-joesuu-lighthouse', 'narva-joesuu', 'ARCHITECTURE', 1, 4.4, 'Маяк Нарва-Йыэсуу', 'Narva-Joesuu Lighthouse', 'Нарва-Йыэсуу шамшырағы', 59.46970000, 28.04390000, 'Narva-Joesuu_Lighthouse.jpg', ARRAY['narva-joesuu', 'lighthouse', 'coast']::text[]),
    ('narva-joesuu-ethnography-museum', 'narva-joesuu', 'MUSEUM', 1, 4.4, 'Этнографический музей Нарва-Йыэсуу', 'Narva-Joesuu Ethnography Museum', 'Нарва-Йыэсуу этнография музейі', 59.45960000, 28.04100000, 'Narva-Joesuu_Ethnography_Museum.jpg', ARRAY['narva-joesuu', 'museum', 'local-history']::text[]),

    ('rakvere-castle', 'rakvere', 'ARCHITECTURE', 3, 4.8, 'Раквереский замок', 'Rakvere Castle', 'Раквере қамалы', 59.34980000, 26.35560000, 'Rakvere_Castle.jpg', ARRAY['rakvere', 'castle', 'family']::text[]),
    ('estonian-police-museum', 'rakvere', 'MUSEUM', 2, 4.6, 'Эстонский полицейский музей', 'Estonian Police Museum', 'Эстония полиция музейі', 59.34600000, 26.36040000, 'Estonian_Police_Museum.jpg', ARRAY['rakvere', 'museum', 'family']::text[]),
    ('tarvas-sculpture', 'rakvere', 'OTHER', 1, 4.5, 'Скульптура Тарвас', 'Tarvas sculpture', 'Тарвас мүсіні', 59.34930000, 26.35670000, 'Tarvas_Sculpture_Rakvere.jpg', ARRAY['rakvere', 'landmark', 'photo-stop']::text[]),
    ('rakvere-central-square', 'rakvere', 'ARCHITECTURE', 1, 4.4, 'Центральная площадь Раквере', 'Rakvere Central Square', 'Раквере орталық алаңы', 59.34670000, 26.36100000, 'Rakvere_Central_Square.jpg', ARRAY['rakvere', 'square', 'architecture']::text[]),

    ('valaste-waterfall', 'ida-viru', 'NATURE', 2, 4.7, 'Водопад Валасте', 'Valaste Waterfall', 'Валасте сарқырамасы', 59.44430000, 27.33540000, 'Valaste_Waterfall.jpg', ARRAY['ida-viru', 'waterfall', 'coast']::text[]),
    ('oru-park-toila', 'ida-viru', 'PARK', 2, 4.6, 'Парк Ору в Тойла', 'Oru Park in Toila', 'Тойладағы Ору саябағы', 59.42300000, 27.51400000, 'Oru_Park_Toila.jpg', ARRAY['ida-viru', 'park', 'coast']::text[]),
    ('estonian-mining-museum', 'ida-viru', 'MUSEUM', 3, 4.6, 'Эстонский шахтерский музей', 'Estonian Mining Museum', 'Эстония тау-кен музейі', 59.33200000, 27.21130000, 'Estonian_Mining_Museum.jpg', ARRAY['ida-viru', 'mining', 'museum']::text[]),
    ('alutaguse-national-park', 'ida-viru', 'PARK', 4, 4.7, 'Национальный парк Алутагузе', 'Alutaguse National Park', 'Алутагузе ұлттық паркі', 59.13800000, 27.53600000, 'Alutaguse_National_Park.jpg', ARRAY['ida-viru', 'national-park', 'forest']::text[]),

    ('soomaa-national-park', 'soomaa', 'PARK', 5, 4.8, 'Национальный парк Соомаа', 'Soomaa National Park', 'Соомаа ұлттық паркі', 58.43000000, 25.00000000, 'Soomaa_National_Park.jpg', ARRAY['soomaa', 'national-park', 'bog']::text[]),
    ('riisa-bog-trail', 'soomaa', 'NATURE', 3, 4.7, 'Учебная тропа Рийса', 'Riisa Bog Trail', 'Рийса батпағы соқпағы', 58.43500000, 25.01800000, 'Riisa_Bog_Trail.jpg', ARRAY['soomaa', 'bog', 'boardwalk']::text[]),
    ('soomaa-canoe-trips', 'soomaa', 'ENTERTAINMENT', 4, 4.7, 'Каноэ в Соомаа', 'Soomaa canoe trips', 'Соомаада каноэ серуені', 58.43000000, 25.02000000, 'Soomaa_Canoe.jpg', ARRAY['soomaa', 'canoe', 'fifth-season']::text[]);

CREATE TEMP TABLE seed_estonia_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-estonia-attraction:' || seed.slug) AS attraction_hash,
        md5('id-estonia-media:' || seed.slug) AS media_hash
    FROM seed_estonia_priority_attractions seed
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
    ARRAY['estonia', city_id, slug, lower(category), 'estonia-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Эстонии: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'Estonia tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'Эстония туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' Estonia', ' ', '%20') AS location_source_url,
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
    'EE',
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
FROM seed_estonia_resolved_attractions
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
FROM seed_estonia_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_estonia_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_estonia_resolved_attractions
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
FROM seed_estonia_resolved_attractions seed
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
FROM seed_estonia_resolved_attractions
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
    'EE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_estonia_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'EE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_estonia_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
