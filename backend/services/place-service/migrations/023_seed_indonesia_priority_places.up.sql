-- Priority Indonesia places seed.
-- Texts are original Inflap editorial summaries localized for ru/en.
-- Sources audited in May 2026:
-- - Denpasar Tourism, Visit Bali, Indonesia Travel and official place pages where available.
-- - Tripadvisor and Klook for tourist-demand signals.
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location anchors.
-- Selection policy:
-- - country_code is always ID;
-- - city_id stores the practical Indonesia tourist hub used for filtering and guide departures;
-- - markets and night markets use the MARKET category;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets, tours and opening conditions change by season/operator.

DROP TABLE IF EXISTS seed_indonesia_resolved_places;
DROP TABLE IF EXISTS seed_indonesia_priority_places;

CREATE TEMP TABLE seed_indonesia_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_query text NOT NULL,
    media_file text NOT NULL
);

INSERT INTO seed_indonesia_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    latitude,
    longitude,
    location_query,
    media_file
) VALUES
    ('bajra-sandhi-monument', 'denpasar', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Монумент Баджра Сандхи', 'Bajra Sandhi Monument', 'Баджра Сандхи монументі', 'Знаковый монумент в Денпасаре с диорамами о балийской истории и борьбе народа. Хорошая культурная точка для начала маршрута по столице острова.', 'An iconic Denpasar monument with dioramas about Balinese history and the island people''s struggle. It is a strong cultural opener for the capital route.', -8.67170000, 115.23390000, 'Bajra Sandhi Monument Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('bali-museum-denpasar', 'denpasar', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Бали', 'Bali Museum', 'Бали музейі', 'Главный музей Денпасара о культуре, ремеслах, археологии и традиционной архитектуре Бали. Удобен как indoor-точка в жару или дождь.', 'Denpasar main museum covering Balinese culture, crafts, archaeology and traditional architecture. It is a useful indoor stop on hot or rainy days.', -8.65780000, 115.21890000, 'Bali Museum Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('badung-kumbasari-night-market', 'denpasar', 'MARKET', 2, 'HOURS', 4.3, 'Ночной рынок Бадунг и Кумбасари', 'Badung and Kumbasari Night Market', 'Бадунг және Кумбасари түнгі базары', 'Большая рыночная зона Денпасара с едой, товарами и плотной локальной атмосферой. Подходит для вечернего знакомства с настоящим городским ритмом.', 'A large Denpasar market zone with food, goods and dense local atmosphere. It suits an evening look at the real city rhythm.', -8.65690000, 115.21280000, 'Badung Kumbasari Night Market Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('taman-werdhi-budaya-art-centre', 'denpasar', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Арт-центр Таман Вердхи Будая', 'Taman Werdhi Budaya Art Centre', 'Таман Вердхи Будая өнер орталығы', 'Культурный комплекс Денпасара для выставок, фестивалей и традиционных представлений. Хорошая точка для событийных маршрутов и знакомства с искусством.', 'A Denpasar cultural complex for exhibitions, festivals and traditional performances. It works well for event-led routes and arts context.', -8.64600000, 115.23300000, 'Taman Werdhi Budaya Art Centre Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('kuta-beach', 'kuta', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Кута', 'Kuta Beach', 'Кута жағажайы', 'Классический пляж Бали для серфинга, закатов и первого знакомства с курортной западной береговой линией. Хорош для простого пляжного маршрута.', 'Bali classic beach for surfing, sunsets and the first feel of the west-coast resort strip. It fits an easy beach route.', -8.71850000, 115.16860000, 'Kuta Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('waterbom-bali', 'kuta', 'PARK', 4, 'HOURS', 4.7, 'Аквапарк Waterbom Bali', 'Waterbom Bali', 'Waterbom Bali аквапаркі', 'Крупный тропический аквапарк в Куте с горками, бассейнами и семейной инфраструктурой. Нужен как сильная точка для отдыха с детьми.', 'A major tropical water park in Kuta with slides, pools and family facilities. It is a strong stop for trips with children.', -8.72850000, 115.16930000, 'Waterbom Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('beachwalk-shopping-center', 'kuta', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговый центр Beachwalk', 'Beachwalk Shopping Center', 'Beachwalk сауда орталығы', 'Открытый курортный молл напротив пляжа Кута с магазинами, едой и комфортной паузой между пляжными прогулками.', 'An open-air resort-style mall opposite Kuta Beach with shops, dining and a comfortable pause between beach walks.', -8.71670000, 115.16890000, 'Beachwalk Shopping Center Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('mal-bali-galeria', 'kuta', 'SHOPPING', 2, 'HOURS', 4.3, 'Молл Bali Galeria', 'Mal Bali Galeria', 'Bali Galeria моллы', 'Один из крупных моллов Куты у Simpang Dewa Ruci с магазинами, кафе и повседневными сервисами. Полезен для практичного шопинга.', 'One of Kuta large malls by Simpang Dewa Ruci, with shops, cafes and everyday services. It is useful for practical shopping.', -8.72320000, 115.18420000, 'Mal Bali Galeria', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('kuta-art-market', 'kuta', 'MARKET', 1, 'HOURS', 4.1, 'Арт-рынок Куты', 'Kuta Art Market', 'Кута арт-базары', 'Туристический рынок у побережья Куты с сувенирами, одеждой и небольшими подарками. Хорош как короткая остановка рядом с пляжем.', 'A tourist market near Kuta coast with souvenirs, clothes and small gifts. It is a quick stop near the beach.', -8.72410000, 115.17040000, 'Kuta Art Market Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('legian-beach', 'legian', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Легиан', 'Legian Beach', 'Легиан жағажайы', 'Широкий песчаный пляж между Кутой и Семиньяком с серфингом, закатами и более спокойным ритмом, чем в центре Куты.', 'A wide sandy beach between Kuta and Seminyak with surfing, sunsets and a calmer rhythm than central Kuta.', -8.70490000, 115.16660000, 'Legian Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('seminyak-beach', 'seminyak', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Семиньяк', 'Seminyak Beach', 'Семиньяк жағажайы', 'Стильный пляж с закатами, ресторанами и beach clubs. Подходит для вечернего маршрута с едой и океанской атмосферой.', 'A stylish sunset beach backed by restaurants and beach clubs. It fits an evening route with food and ocean atmosphere.', -8.69080000, 115.15920000, 'Seminyak Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('petitenget-temple', 'seminyak', 'TEMPLE', 1, 'HOURS', 4.3, 'Храм Петитенгет', 'Petitenget Temple', 'Петитенгет храмы', 'Прибрежный индуистский храм рядом с пляжем Семиньяк и ресторанной зоной. Добавляет культурный контекст к leisure-маршруту.', 'A coastal Hindu temple near Seminyak Beach and the dining district. It adds cultural context to a leisure route.', -8.67870000, 115.15380000, 'Petitenget Temple Seminyak', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('potato-head-beach-club', 'seminyak', 'FOOD', 3, 'HOURS', 4.5, 'Beach Club Potato Head', 'Potato Head Beach Club', 'Potato Head Beach Club', 'Известное место у океана для еды, коктейлей, дизайна и заката. Хорошо работает как премиальная вечерняя точка Семиньяка.', 'A well-known oceanfront venue for dining, drinks, design and sunset. It works as a premium Seminyak evening stop.', -8.67630000, 115.15190000, 'Potato Head Beach Club Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('seminyak-flea-market', 'seminyak', 'MARKET', 1, 'HOURS', 4.1, 'Рынок Семиньяка', 'Seminyak Flea Market', 'Семиньяк базары', 'Компактный рынок с одеждой, аксессуарами и сувенирами в пешей доступности от пляжа и ресторанной зоны.', 'A compact market with clothes, accessories and souvenirs within walking distance of the beach and dining area.', -8.68070000, 115.15530000, 'Seminyak Flea Market Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('batu-bolong-beach', 'canggu', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Бату Болонг', 'Batu Bolong Beach', 'Бату Болонг жағажайы', 'Главный пляж Чангу для серфинга, закатов и неформальной атмосферы кафе. Удобен как базовая точка района.', 'Central Canggu surf beach with sunset hangouts and informal cafe energy. It is the area baseline stop.', -8.65870000, 115.13070000, 'Batu Bolong Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('echo-beach-canggu', 'canggu', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Echo Beach', 'Echo Beach', 'Echo Beach жағажайы', 'Чернопесчаный серф-пляж Чангу с кафе и закатным настроением. Хорош для активной прогулки по побережью.', 'A black-sand Canggu surf beach with cafes and sunset mood. It suits an active coast walk.', -8.65500000, 115.12690000, 'Echo Beach Canggu Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('finns-beach-club', 'canggu', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Beach Club FINNS', 'FINNS Beach Club', 'FINNS Beach Club', 'Крупный пляжный клуб в Чангу с бассейнами, барами, музыкой и видом на океан. Подходит для вечернего leisure-сценария.', 'A large Canggu beach club with pools, bars, music and ocean views. It fits an evening leisure scenario.', -8.66080000, 115.13760000, 'FINNS Beach Club Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('love-anchor-market', 'canggu', 'MARKET', 1, 'HOURS', 4.2, 'Рынок Love Anchor', 'Love Anchor Market', 'Love Anchor базары', 'Открытый рынок Чангу с одеждой, ремеслами и сувенирами. Хорош как легкая shopping-остановка между кафе и пляжем.', 'An open-air Canggu market with fashion, crafts and souvenirs. It is an easy shopping stop between cafes and beach time.', -8.65580000, 115.13550000, 'Love Anchor Market Canggu', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('sanur-beach', 'sanur', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Санур', 'Sanur Beach', 'Санур жағажайы', 'Спокойный пляж для рассветов, прогулочной набережной и семейного отдыха у защищенной рифом воды.', 'A calm sunrise beach with a long promenade and reef-protected water, useful for family-friendly routes.', -8.69330000, 115.26270000, 'Sanur Beach Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('sindhu-night-market', 'sanur', 'MARKET', 2, 'HOURS', 4.3, 'Ночной рынок Синдху', 'Sindhu Night Market', 'Синдху түнгі базары', 'Вечерний рынок Санура с недорогой индонезийской уличной едой. Хорош для простого гастро-маршрута без формальности.', 'An affordable Sanur evening market for Indonesian street food. It suits a simple food route without formality.', -8.68950000, 115.26200000, 'Sindhu Night Market Sanur', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('le-mayeur-museum', 'sanur', 'MUSEUM', 1, 'HOURS', 4.2, 'Музей Ле Майера', 'Le Mayeur Museum', 'Ле Майер музейі', 'Дом-музей художника Адриена-Жана Ле Майера рядом с пляжем Санур. Добавляет культурный слой к спокойному coastal-маршруту.', 'The house museum of painter Adrien-Jean Le Mayeur near Sanur Beach. It adds a cultural layer to a calm coastal route.', -8.67400000, 115.26470000, 'Le Mayeur Museum Sanur', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('icon-bali-mall', 'sanur', 'SHOPPING', 2, 'HOURS', 4.2, 'Молл ICON Bali', 'ICON Bali Mall', 'ICON Bali моллы', 'Новый прибрежный молл Санура с магазинами, едой и развлечениями. Полезен как комфортная пауза у пляжной зоны.', 'A newer beachfront Sanur mall with shopping, dining and entertainment. It is useful as a comfortable pause near the beach zone.', -8.68890000, 115.26380000, 'ICON Bali Mall Sanur', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('nusa-dua-beach', 'nusa-dua', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Нуса-Дуа', 'Nusa Dua Beach', 'Нуса-Дуа жағажайы', 'Ухоженный курортный пляж со спокойной водой, отелями и удобной инфраструктурой. Подходит для семейного и размеренного отдыха.', 'A manicured resort beach with calm water, hotels and easy infrastructure. It suits family-friendly and relaxed beach time.', -8.80000000, 115.22900000, 'Nusa Dua Beach Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('water-blow-nusa-dua', 'nusa-dua', 'NATURE', 1, 'HOURS', 4.4, 'Water Blow Нуса-Дуа', 'Water Blow', 'Water Blow Нуса-Дуа', 'Скальная точка в Нуса-Дуа, где волны эффектно разбиваются о берег. Хороша как короткая фото-остановка рядом с курортами.', 'A Nusa Dua cliff point where waves break into dramatic spray. It is a short photo stop near the resorts.', -8.79390000, 115.24050000, 'Water Blow Nusa Dua', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('museum-pasifika', 'nusa-dua', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Пасифика', 'Museum Pasifika', 'Пасифика музейі', 'Художественный музей Азии и Тихоокеанского региона в Нуса-Дуа. Хорошая indoor-точка для культурного маршрута в курортной зоне.', 'An Asia-Pacific art museum in Nusa Dua. It is a strong indoor culture stop in the resort enclave.', -8.79810000, 115.22840000, 'Museum Pasifika Nusa Dua', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('bali-collection', 'nusa-dua', 'SHOPPING', 2, 'HOURS', 4.3, 'Bali Collection', 'Bali Collection', 'Bali Collection', 'Открытая торгово-ресторанная зона Нуса-Дуа с магазинами, кафе и туристической инфраструктурой внутри курортного анклава.', 'An open-air Nusa Dua shopping and dining village with stores, cafes and tourist services inside the resort enclave.', -8.80050000, 115.22990000, 'Bali Collection Nusa Dua', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('devdan-show', 'nusa-dua', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Шоу Devdan', 'Devdan Show', 'Devdan шоуы', 'Сценическое шоу в театре Нуса-Дуа с танцами, акробатикой и мотивами разных регионов Индонезии. Хорошо для вечерней программы.', 'A Nusa Dua theatre show mixing dance, acrobatics and themes from Indonesian regions. It works for an evening program.', -8.79950000, 115.22550000, 'Devdan Show Nusa Dua', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('jimbaran-bay-seafood', 'jimbaran', 'FOOD', 2, 'HOURS', 4.4, 'Морепродукты на закате в Джимбаране', 'Jimbaran Bay Seafood Sunset', 'Джимбаран шығанағындағы теңіз өнімдері', 'Пляжные рестораны с морепродуктами на песке Джимбарана. Сильная вечерняя точка для ужина и заката.', 'Beachfront seafood dining on Jimbaran sand. It is a strong evening stop for dinner and sunset.', -8.78400000, 115.16100000, 'Jimbaran Bay Seafood Bali', 'Sunset_at_Garuda_Wisnu_Kencana_Bali.jpg'),
    ('kedonganan-fish-market', 'jimbaran', 'MARKET', 1, 'HOURS', 4.3, 'Рыбный рынок Кедонганан', 'Kedonganan Fish Market', 'Кедонганан балық базары', 'Рабочий рыбный рынок у Джимбарана, где видно локальную торговлю морепродуктами. Подходит для гастро- и lifestyle-маршрутов.', 'A working seafood market near Jimbaran where local fish trade is visible. It suits food and lifestyle routes.', -8.76070000, 115.17130000, 'Kedonganan Fish Market Bali', 'Sunset_at_Garuda_Wisnu_Kencana_Bali.jpg'),
    ('samasta-lifestyle-village', 'jimbaran', 'SHOPPING', 2, 'HOURS', 4.2, 'Samasta Lifestyle Village', 'Samasta Lifestyle Village', 'Samasta Lifestyle Village', 'Лайфстайл-комплекс Джимбарана с ресторанами, магазинами и событиями. Удобен как мягкая evening-точка рядом с отелями.', 'A Jimbaran lifestyle village with dining, shops and events. It is an easy evening stop near hotels.', -8.79080000, 115.16470000, 'Samasta Lifestyle Village Bali', 'Sunset_at_Garuda_Wisnu_Kencana_Bali.jpg'),
    ('uluwatu-temple', 'uluwatu', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Улувату', 'Uluwatu Temple', 'Улувату храмы', 'Драматичный морской храм на высоком известняковом утесе, знаменитый закатом и танцем кечак. Один из главных символов юга Бали.', 'A dramatic sea temple on a high limestone cliff, known for sunset and kecak dance. It is one of South Bali key symbols.', -8.82910000, 115.08490000, 'Uluwatu Temple Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('garuda-wisnu-kencana', 'uluwatu', 'PARK', 3, 'HOURS', 4.5, 'Культурный парк Гаруда Вишну Кенчана', 'Garuda Wisnu Kencana Cultural Park', 'Гаруда Вишну Кенчана мәдени паркі', 'Культурный парк с гигантской статуей, площадями, видами и представлениями. Хорошо работает как крупная дневная точка Букита.', 'A cultural park with a giant statue, plazas, viewpoints and performances. It works as a major daytime Bukit stop.', -8.81010000, 115.16700000, 'Garuda Wisnu Kencana Bali', 'Sunset_at_Garuda_Wisnu_Kencana_Bali.jpg'),
    ('melasti-beach', 'uluwatu', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Меласти', 'Melasti Beach', 'Меласти жағажайы', 'Живописный пляж у известняковых скал в Унгасане с бирюзовой водой и сильной фото-ценностью.', 'A scenic limestone-cliff beach in Ungasan with turquoise water and strong photo value.', -8.84570000, 115.16130000, 'Melasti Beach Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('pandawa-beach', 'uluwatu', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Пандава', 'Pandawa Beach', 'Пандава жағажайы', 'Белопесчаный пляж, к которому ведет дорога через известняковые скалы. Хорош для дневного купания и семейных маршрутов.', 'A white-sand beach reached through carved limestone cliffs. It suits daytime swimming and family routes.', -8.84590000, 115.18510000, 'Pandawa Beach Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('padang-padang-beach', 'uluwatu', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Паданг-Паданг', 'Padang Padang Beach', 'Паданг-Паданг жағажайы', 'Небольшая бухта полуострова Букит, известная серфингом, прозрачной водой и скальным проходом к песку.', 'A small Bukit cove known for surf, clear water and a rocky passage down to the sand.', -8.81070000, 115.10180000, 'Padang Padang Beach Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('suluban-blue-point-beach', 'uluwatu', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Сулубан / Blue Point', 'Suluban / Blue Point Beach', 'Сулубан / Blue Point жағажайы', 'Серф-пляж под утесами Улувату, куда ведут скальные проходы. Подходит для видов, фото и наблюдения за волнами.', 'A surf beach below Uluwatu cliffs, reached through rock passages. It suits views, photos and wave-watching.', -8.81570000, 115.08770000, 'Suluban Beach Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),

    ('sacred-monkey-forest-ubud', 'ubud', 'PARK', 2, 'HOURS', 4.7, 'Священный лес обезьян Убуда', 'Sacred Monkey Forest Sanctuary', 'Убуд қасиетті маймылдар орманы', 'Лесной заповедник с макаками, древними храмами и тенистыми тропами в центре Убуда. Это один из самых узнаваемых культурно-природных объектов Бали.', 'A forest sanctuary with macaques, ancient temples and shaded paths in central Ubud. It is one of Bali most recognizable culture-nature stops.', -8.51930000, 115.26060000, 'Sacred Monkey Forest Sanctuary Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('ubud-palace', 'ubud', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Дворец Убуда', 'Ubud Palace', 'Убуд сарайы', 'Исторический королевский дворец в центре Убуда с резьбой, дворами и вечерними танцевальными программами.', 'A historic royal palace in central Ubud with carvings, courtyards and evening dance programs.', -8.50690000, 115.26250000, 'Ubud Palace Bali', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('pura-taman-saraswati', 'ubud', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Сарасвати в Убуде', 'Pura Taman Saraswati', 'Убуд Сарасвати храмы', 'Водный храм с лотосовыми прудами и классической балийской архитектурой. Удобен как красивая короткая остановка в центре Убуда.', 'A water temple with lotus ponds and classic Balinese architecture. It is a beautiful short stop in central Ubud.', -8.50660000, 115.26180000, 'Pura Taman Saraswati Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('ubud-art-market', 'ubud', 'MARKET', 2, 'HOURS', 4.3, 'Арт-рынок Убуда', 'Ubud Art Market', 'Убуд арт-базары', 'Центральный рынок ремесел с тканями, резьбой, сумками и сувенирами. Хорош для маршрутов с локальным shopping-опытом.', 'A central craft market for textiles, carvings, bags and souvenirs. It suits routes with local shopping experience.', -8.50670000, 115.26310000, 'Ubud Art Market Bali', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('campuhan-ridge-walk', 'ubud', 'NATURE', 2, 'HOURS', 4.5, 'Тропа Кампухан', 'Campuhan Ridge Walk', 'Кампухан жотасы жолы', 'Легкая прогулочная тропа с зелеными видами недалеко от центра Убуда. Хороша для рассвета, заката и спокойной паузы.', 'An easy ridge walk with green valley views close to Ubud center. It works for sunrise, sunset and a calm pause.', -8.50440000, 115.25530000, 'Campuhan Ridge Walk Ubud', 'Rice_terraces,_Bali.jpg'),
    ('museum-puri-lukisan', 'ubud', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Пури Лукисан', 'Museum Puri Lukisan', 'Пури Лукисан музейі', 'Классический музей балийской живописи и резьбы по дереву в Убуде. Хорошая точка для культурного маршрута без дальнего трансфера.', 'A classic Ubud museum of Balinese painting and wood carving. It is a good culture stop without a long transfer.', -8.50650000, 115.26010000, 'Museum Puri Lukisan Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('neka-art-museum', 'ubud', 'MUSEUM', 2, 'HOURS', 4.5, 'Художественный музей Нека', 'Neka Art Museum', 'Нека өнер музейі', 'Крупный музей Убуда о балийском и вдохновленном Бали искусстве. Полезен для глубокого культурного сценария.', 'A major Ubud museum covering Balinese and Bali-inspired art. It is useful for deeper culture-focused routes.', -8.49230000, 115.25300000, 'Neka Art Museum Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('arma-museum', 'ubud', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей искусства Агунг Раи', 'Agung Rai Museum of Art', 'Агунг Раи өнер музейі', 'Художественный музей и культурный комплекс в районе Пенгосекан. Подходит для маршрутов об искусстве и традициях Убуда.', 'An art museum and cultural complex in Pengosekan. It suits routes about Ubud art and tradition.', -8.52670000, 115.26420000, 'Agung Rai Museum of Art Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('blanco-renaissance-museum', 'ubud', 'MUSEUM', 1, 'HOURS', 4.3, 'Музей Бланко', 'Blanco Renaissance Museum', 'Бланко музейі', 'Музей художника Антонио Бланко в бывшей усадьбе над рекой. Добавляет необычный художественный акцент к прогулке по Убуду.', 'The museum of painter Antonio Blanco in his former river-view estate. It adds an unusual art accent to an Ubud walk.', -8.50690000, 115.25570000, 'Blanco Renaissance Museum Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('goa-gajah', 'gianyar', 'TEMPLE', 1, 'HOURS', 4.5, 'Гоа Гаджа / Слоновья пещера', 'Goa Gajah', 'Гоа Гаджа', 'Древнее пещерное святилище рядом с Убудом с купелями, резьбой и археологическим контекстом.', 'An ancient cave sanctuary near Ubud with bathing pools, carvings and archaeological context.', -8.52380000, 115.28670000, 'Goa Gajah Bali', 'Rice_terraces,_Bali.jpg'),
    ('kanto-lampo-waterfall', 'gianyar', 'NATURE', 2, 'HOURS', 4.5, 'Водопад Канто Лампо', 'Kanto Lampo Waterfall', 'Канто Лампо сарқырамасы', 'Фотогеничный каскадный водопад в Гианьяре, удобный для короткой поездки из Убуда.', 'A photogenic stepped waterfall in Gianyar, convenient for a short trip from Ubud.', -8.53250000, 115.33140000, 'Kanto Lampo Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('tegenungan-waterfall', 'sukawati', 'NATURE', 2, 'HOURS', 4.5, 'Водопад Тегенунган', 'Tegenungan Waterfall', 'Тегенунган сарқырамасы', 'Популярный водопад на реке Петану рядом с Кеменухом и Убудом. Хорош для первого waterfall-маршрута на Бали.', 'A popular waterfall on the Petanu River near Kemenuh and Ubud. It is a strong first waterfall route in Bali.', -8.57500000, 115.28900000, 'Tegenungan Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('bali-bird-park', 'sukawati', 'PARK', 2, 'HOURS', 4.5, 'Парк птиц Бали', 'Bali Bird Park', 'Бали құстар паркі', 'Парк птиц в Сингападу с тропическими вольерами и образовательными программами. Хорош для семейного маршрута.', 'A Singapadu bird park with tropical aviaries and educational programs. It works well for family routes.', -8.59840000, 115.24940000, 'Bali Bird Park', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('bali-zoo', 'sukawati', 'PARK', 3, 'HOURS', 4.5, 'Зоопарк Бали', 'Bali Zoo', 'Бали хайуанаттар бағы', 'Семейный зоопарк в Сингападу с программами знакомства с животными и удобной инфраструктурой для детей.', 'A family wildlife park in Singapadu with animal encounters and child-friendly infrastructure.', -8.59120000, 115.25410000, 'Bali Zoo', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('sukawati-art-market', 'sukawati', 'MARKET', 2, 'HOURS', 4.2, 'Арт-рынок Сукавати', 'Sukawati Art Market', 'Сукавати арт-базары', 'Традиционный рынок картин, тканей, ремесел и сувениров. Хорош для более локального shopping-сценария, чем пляжные лавки.', 'A traditional market for paintings, textiles, crafts and souvenirs. It is a more local shopping scenario than beach stalls.', -8.60080000, 115.27900000, 'Sukawati Art Market Bali', 'Rice_terraces,_Bali.jpg'),
    ('bali-safari-marine-park', 'gianyar', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Бали Сафари и Морской парк', 'Bali Safari and Marine Park', 'Бали сафари және теңіз паркі', 'Крупный сафари-парк в Гианьяре с животными, шоу и семейными аттракционами. Удобен как полный day-plan.', 'A large safari park in Gianyar with animals, shows and family places. It works as a full day-plan.', -8.58460000, 115.35400000, 'Bali Safari and Marine Park', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('tegalalang-rice-terrace', 'tegallalang', 'NATURE', 2, 'HOURS', 4.6, 'Рисовые террасы Тегаллаланг', 'Tegalalang Rice Terrace', 'Тегаллаланг күріш террасалары', 'Знаковые рисовые террасы к северу от Убуда с видами, прогулками и классической картинкой Бали.', 'Iconic rice terraces north of Ubud with views, walks and the classic Bali landscape.', -8.43170000, 115.27930000, 'Tegalalang Rice Terrace Bali', 'Rice_terraces,_Bali.jpg'),
    ('alas-harum-bali', 'tegallalang', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Алас Харум Бали', 'Alas Harum Bali', 'Алас Харум Бали', 'Агро-туристический парк с видами на рисовые террасы, качелями и дегустацией кофе. Хорош для фото- и family-маршрутов.', 'An agro-tourism park with rice-terrace views, swings and coffee tasting. It suits photo-led and family routes.', -8.42640000, 115.27960000, 'Alas Harum Bali', 'Rice_terraces,_Bali.jpg'),
    ('aloha-ubud-swing', 'tegallalang', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Aloha Ubud Swing', 'Aloha Ubud Swing', 'Aloha Ubud Swing', 'Качели и фотолокации с видом на поля Тегаллаланга. Подходит для туристов, которым нужен быстрый визуальный опыт Убуда.', 'Swing and photo spots overlooking Tegallalang paddies. It suits travelers looking for a quick visual Ubud experience.', -8.43110000, 115.28130000, 'Aloha Ubud Swing', 'Rice_terraces,_Bali.jpg'),
    ('tirta-empul-temple', 'tampaksiring', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Тирта Эмпул', 'Tirta Empul Temple', 'Тирта Эмпул храмы', 'Священный храм-источник в Тампаксиринге, известный ритуалами очищения. Важная spiritual-точка центрального Бали.', 'A sacred holy spring temple in Tampaksiring, known for purification rituals. It is a key spiritual stop in Central Bali.', -8.41580000, 115.31520000, 'Tirta Empul Temple Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('gunung-kawi-temple', 'tampaksiring', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Гунунг Кави', 'Gunung Kawi Temple', 'Гунунг Кави храмы', 'Храмово-погребальный комплекс XI века, высеченный в скалах. Хорош для маршрутов о древней истории Бали.', 'An 11th-century cliff-carved temple and funerary complex. It suits routes about ancient Balinese history.', -8.42220000, 115.31200000, 'Gunung Kawi Temple Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('ulun-danu-beratan', 'bedugul', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Улун Дану Бератан', 'Ulun Danu Beratan Temple', 'Улун Дану Бератан храмы', 'Знаковый храм на озере Бератан в прохладном высокогорье Бедугул. Один из самых узнаваемых пейзажей Бали.', 'An iconic lake temple on Lake Beratan in the cool Bedugul highlands. It is one of Bali most recognizable landscapes.', -8.27500000, 115.16680000, 'Ulun Danu Beratan Temple Bali', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('bali-botanic-garden', 'bedugul', 'PARK', 2, 'HOURS', 4.5, 'Ботанический сад Бали', 'Bali Botanic Garden', 'Бали ботаникалық бағы', 'Большой горный ботанический сад с орхидеями, тропическими растениями и прохладными прогулками.', 'A large highland botanical garden with orchids, tropical plant collections and cool walking paths.', -8.27880000, 115.15400000, 'Bali Botanic Garden Bedugul', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('candi-kuning-market', 'bedugul', 'MARKET', 1, 'HOURS', 4.2, 'Рынок Чанди Кунинг', 'Candi Kuning Market', 'Чанди Кунинг базары', 'Горный рынок фруктов, овощей, цветов, специй и сувениров рядом с Бедугулом. Хорош как локальная пауза в северном маршруте.', 'A highland market for fruit, vegetables, flowers, spices and souvenirs near Bedugul. It is a local pause on a northbound route.', -8.27990000, 115.16230000, 'Candi Kuning Market Bedugul', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('tanah-lot', 'tabanan', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Танах Лот', 'Tanah Lot', 'Танах Лот храмы', 'Один из самых известных морских храмов Бали на скале у океана, особенно популярный на закате.', 'One of Bali most famous sea temples on an offshore rock, especially popular at sunset.', -8.62120000, 115.08680000, 'Tanah Lot Bali', 'Tanah_Lot,_Bali,_Indonesia,_20220827_1008_1159.jpg'),
    ('jatiluwih-rice-terraces', 'jatiluwih', 'NATURE', 3, 'HOURS', 4.8, 'Рисовые террасы Джатилувих', 'Jatiluwih Rice Terraces', 'Джатилувих күріш террасалары', 'Просторные рисовые террасы с системой субак у склонов Батукару. Сильная точка для природы, прогулок и спокойного rural-Бали.', 'Expansive subak rice terraces near Mount Batukaru. They are a strong nature, walking and rural-Bali stop.', -8.36980000, 115.13120000, 'Jatiluwih Rice Terraces Bali', 'Jatiluwih_rice_terraces_SF0002.jpg'),
    ('batukaru-temple', 'tabanan', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Батукару', 'Batukaru Temple', 'Батукару храмы', 'Священный горный храм на склонах Батукару, окруженный влажным лесом. Хорош для спокойного spiritual-маршрута.', 'A sacred mountain temple on Mount Batukaru slopes, surrounded by wet forest. It suits a calm spiritual route.', -8.39010000, 115.10260000, 'Batukaru Temple Bali', 'Jatiluwih_rice_terraces_SF0002.jpg'),

    ('lovina-beach', 'lovina', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Ловина', 'Lovina Beach', 'Ловина жағажайы', 'Спокойный северный пляж с черным песком, рассветными лодочными прогулками и неспешным ритмом.', 'A calm black-sand north-coast beach known for sunrise boat trips and relaxed seaside stays.', -8.16190000, 115.02570000, 'Lovina Beach Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('banjar-hot-springs', 'lovina', 'NATURE', 2, 'HOURS', 4.4, 'Горячие источники Банджар', 'Banjar Hot Springs', 'Банджар ыстық бұлақтары', 'Горячие источники в тропическом саду с несколькими теплыми бассейнами рядом с Ловиной.', 'Tropical garden hot springs with tiered warm pools near Lovina.', -8.21040000, 114.96750000, 'Banjar Hot Springs Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('brahmavihara-arama', 'lovina', 'TEMPLE', 1, 'HOURS', 4.5, 'Монастырь Брахмавихара-Арама', 'Brahmavihara-Arama Monastery', 'Брахмавихара-Арама монастыры', 'Крупнейший буддийский монастырь Бали с садами, ступами и спокойными видами с холмов.', 'Bali largest Buddhist monastery, with gardens, stupas and peaceful hill views.', -8.21080000, 114.95890000, 'Brahmavihara Arama Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('gitgit-waterfall', 'singaraja', 'NATURE', 2, 'HOURS', 4.5, 'Водопад Гитгит', 'Gitgit Waterfall', 'Гитгит сарқырамасы', 'Классический водопад Северного Бали, к которому ведет короткая лесная тропа.', 'A classic North Bali waterfall reached by a short forest walk.', -8.20270000, 115.13970000, 'Gitgit Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('sekumpul-waterfall', 'singaraja', 'NATURE', 3, 'HOURS', 4.8, 'Водопад Секумпул', 'Sekumpul Waterfall', 'Секумпул сарқырамасы', 'Впечатляющая система водопадов в зеленой речной долине, часто считающаяся одной из лучших природных точек Бали.', 'A dramatic waterfall system in a green river valley, often treated as one of Bali best nature stops.', -8.17210000, 115.18190000, 'Sekumpul Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('aling-aling-waterfall', 'singaraja', 'NATURE', 3, 'HOURS', 4.6, 'Водопад Алинг-Алинг', 'Aling-Aling Waterfall', 'Алинг-Алинг сарқырамасы', 'Активная водопадная зона с джунглями, природными бассейнами, слайдами и прыжками со скал.', 'An adventure waterfall area with jungle pools, slides and cliff-jump routes.', -8.14430000, 115.10770000, 'Aling-Aling Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('pura-beji-sangsit', 'singaraja', 'TEMPLE', 1, 'HOURS', 4.4, 'Храм Беджи Сангсит', 'Pura Beji Sangsit', 'Беджи Сангсит храмы', 'Украшенный храм субака рядом с Сингараджей, известный северобалийской каменной резьбой.', 'An ornate subak temple near Singaraja, known for rich North Balinese stone carving.', -8.08890000, 115.12200000, 'Pura Beji Sangsit Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('munduk-waterfall', 'munduk', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Мундук', 'Munduk Waterfall', 'Мундук сарқырамасы', 'Горный водопад среди гвоздичных, кофейных плантаций и леса. Хорош для прохладного highland-маршрута.', 'A highland waterfall surrounded by clove, coffee and forest scenery. It suits a cool highland route.', -8.26260000, 115.06160000, 'Munduk Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('banyumala-twin-waterfalls', 'munduk', 'NATURE', 3, 'HOURS', 4.7, 'Двойной водопад Баньюмала', 'Banyumala Twin Waterfalls', 'Баньюмала қос сарқырамасы', 'Два каскада с природным бассейном ниже высокогорья Буян-Тамблинган. Хороши для природного маршрута северного Бали.', 'Twin cascades with a natural pool below the Buyan-Tamblingan highlands. They work well for a North Bali nature route.', -8.21730000, 115.10350000, 'Banyumala Twin Waterfalls Bali', 'Rice_terraces,_Bali.jpg'),
    ('lake-tamblingan', 'munduk', 'NATURE', 2, 'HOURS', 4.5, 'Озеро Тамблинган', 'Lake Tamblingan', 'Тамблинган көлі', 'Тихое кратерное озеро с лесными тропами и традиционными прогулками на каноэ.', 'A quiet crater lake with forest trails and traditional canoe trips.', -8.25700000, 115.10000000, 'Lake Tamblingan Bali', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('west-bali-national-park', 'gilimanuk', 'PARK', 4, 'HOURS', 4.6, 'Национальный парк Западный Бали', 'West Bali National Park', 'Батыс Бали ұлттық паркі', 'Охраняемый лесной и морской парк с прибрежными экосистемами и ареалом балийского скворца.', 'A protected forest and marine park with coastal ecosystems and Bali starling habitat.', -8.14400000, 114.49300000, 'West Bali National Park', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('menjangan-island', 'gilimanuk', 'NATURE', 4, 'HOURS', 4.7, 'Остров Менджанган', 'Menjangan Island', 'Менджанган аралы', 'Небольшой остров в Национальном парке Западный Бали, известный рифами, дайвингом и снорклингом.', 'A small island in West Bali National Park, famous for reefs, diving and snorkeling.', -8.09500000, 114.51900000, 'Menjangan Island Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('amed-beach', 'amed', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Амед', 'Amed Beach', 'Амед жағажайы', 'Тихое восточное побережье с вулканическим песком, рассветами, рыбацкими лодками и видом на Агунг.', 'A quiet east-coast beach with volcanic sand, sunrise views, fishing boats and Mount Agung backdrop.', -8.33700000, 115.65500000, 'Amed Beach Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('jemeluk-bay', 'amed', 'NATURE', 3, 'HOURS', 4.6, 'Бухта Джемелук', 'Jemeluk Bay', 'Джемелук шығанағы', 'Удобная бухта для снорклинга с берега, коралловыми садами и видом на горы.', 'An easy shore-snorkeling bay with coral gardens and mountain views.', -8.33400000, 115.65400000, 'Jemeluk Bay Amed', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('japanese-shipwreck-amed', 'amed', 'NATURE', 2, 'HOURS', 4.5, 'Японский рэк Баньюнинг', 'Japanese Shipwreck, Banyuning', 'Баньюнинг жапон кемесі', 'Неглубокий рэк у берега с кораллами, подходящий для снорклинга и простых погружений.', 'A shallow shore wreck with coral growth, suitable for snorkeling and easy dives.', -8.34900000, 115.69500000, 'Japanese Shipwreck Amed Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('tirta-gangga-water-palace', 'karangasem', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Водный дворец Тирта Гангга', 'Tirta Gangga Water Palace', 'Тирта Гангга су сарайы', 'Королевский водный сад с прудами, фонтанами, каменными дорожками и карпами. Один из лучших объектов Восточного Бали.', 'A royal water garden with ponds, fountains, stepping stones and carp pools. It is one of East Bali best stops.', -8.41100000, 115.58700000, 'Tirta Gangga Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('taman-ujung-water-palace', 'karangasem', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Водный дворец Таман Уджунг', 'Taman Ujung Water Palace', 'Таман Уджунг су сарайы', 'Бывший дворец Карангасема с прудами, мостами, павильонами и видами на море.', 'A former Karangasem royal palace with ponds, bridges, pavilions and sea views.', -8.46400000, 115.63100000, 'Taman Ujung Water Palace Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('lempuyang-temple', 'karangasem', 'TEMPLE', 3, 'HOURS', 4.6, 'Храм Лемпуянг', 'Lempuyang Temple', 'Лемпуянг храмы', 'Священный храмовый комплекс Восточного Бали, известный воротами с видом на гору Агунг.', 'A sacred East Bali temple complex known for split gates framing Mount Agung.', -8.39000000, 115.63100000, 'Lempuyang Temple Bali', 'Mother_Temple_of_Besakih.jpg'),
    ('besakih-temple', 'karangasem', 'TEMPLE', 3, 'HOURS', 4.8, 'Храм Бесаких', 'Besakih Temple', 'Бесаких храмы', 'Крупнейший и самый священный индуистский храмовый комплекс Бали на склонах Агунга.', 'Bali largest and holiest Hindu temple complex on Mount Agung slopes.', -8.37400000, 115.45100000, 'Besakih Temple Bali', 'Mother_Temple_of_Besakih.jpg'),
    ('candidasa-lotus-lagoon', 'candidasa', 'PARK', 1, 'HOURS', 4.2, 'Лотосовая лагуна Чандидаса', 'Candidasa Lotus Lagoon', 'Чандидаса лотос лагунасы', 'Живописный лотосовый пруд у главной дороги и побережья Чандидасы. Хорош как короткая спокойная остановка.', 'A scenic lotus pond beside the main Candidasa road and coast. It is a short calm stop.', -8.50700000, 115.56600000, 'Candidasa Lotus Lagoon Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('virgin-beach-pasir-putih', 'candidasa', 'BEACH', 3, 'HOURS', 4.6, 'Вирджин-Бич / Пасир Путих', 'Virgin Beach / Pasir Putih', 'Вирджин-Бич / Пасир Путих', 'Белопесчаная бухта рядом с Бугбугом и Чандидасой с бирюзовой водой и более тихим восточным ритмом.', 'A white-sand cove near Bugbug and Candidasa with turquoise water and a quieter east-coast rhythm.', -8.50500000, 115.61100000, 'Virgin Beach Bali Pasir Putih', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('tenganan-village', 'candidasa', 'OTHER', 2, 'HOURS', 4.5, 'Деревня Тенганан Пегрингсинган', 'Tenganan Pegringsingan Village', 'Тенганан Пегрингсинган ауылы', 'Деревня наследия Бали-Ага, известная сохраненными обычаями и традиционным ткачеством грингсинг.', 'A Bali Aga heritage village known for preserved customs and traditional gringsing weaving.', -8.47500000, 115.56600000, 'Tenganan Pegringsingan Village Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('sidemen-rice-terraces', 'sidemen', 'NATURE', 2, 'HOURS', 4.7, 'Рисовые террасы Сидемен', 'Sidemen Rice Terraces', 'Сидемен күріш террасалары', 'Спокойная долина рисовых полей с видами на Агунг и сельскими прогулочными маршрутами.', 'A peaceful rice-field valley with Mount Agung views and rural walking routes.', -8.46600000, 115.44000000, 'Sidemen Rice Terraces Bali', 'Rice_terraces,_Bali.jpg'),
    ('gembleng-waterfall', 'sidemen', 'NATURE', 2, 'HOURS', 4.5, 'Водопад Гембленг', 'Gembleng Waterfall', 'Гембленг сарқырамасы', 'Многоуровневый водопад с природными каменными бассейнами над долиной Сидемен.', 'A multi-tier waterfall with natural rock pools above Sidemen Valley.', -8.45500000, 115.44400000, 'Gembleng Waterfall Sidemen', 'Rice_terraces,_Bali.jpg'),
    ('mount-batur', 'kintamani', 'NATURE', 4, 'HOURS', 4.8, 'Вулкан Батур', 'Mount Batur', 'Батур жанартауы', 'Активный вулкан в геопарке Батур, популярный для рассветных треков и панорамных маршрутов.', 'An active volcano in the Batur geopark, popular for sunrise hikes and panoramic routes.', -8.24200000, 115.37500000, 'Mount Batur Bali', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('lake-batur', 'kintamani', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Батур', 'Lake Batur', 'Батур көлі', 'Вулканическое озеро внутри кальдеры Батура, окруженное лавовыми полями, деревнями и видами на горы.', 'A volcanic lake inside the Mount Batur caldera, surrounded by lava fields, villages and mountain views.', -8.25500000, 115.40800000, 'Lake Batur Bali', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('batur-geopark-museum', 'kintamani', 'MUSEUM', 1, 'HOURS', 4.3, 'Музей геопарка Батур', 'Batur Geopark Museum', 'Батур геопарк музейі', 'Геологический музей о вулкане Батур, кальдере, извержениях и наследии геопарка.', 'A geology museum explaining Mount Batur, its caldera, eruptions and geopark heritage.', -8.27400000, 115.34400000, 'Batur Geopark Museum', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('kelingking-beach', 'nusa-penida', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Келингкинг', 'Kelingking Beach', 'Келингкинг жағажайы', 'Знаковая смотровая площадка на скалах и крутая тропа к пляжу на западе Нуса-Пениды.', 'An iconic cliff viewpoint and steep beach trail on west Nusa Penida.', -8.75100000, 115.47400000, 'Kelingking Beach Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('broken-beach', 'nusa-penida', 'NATURE', 1, 'HOURS', 4.7, 'Брокен-Бич / Пасих Ууг', 'Broken Beach / Pasih Uug', 'Брокен-Бич / Пасих Ууг', 'Природная морская арка и круглая скальная бухта на западном побережье Нуса-Пениды.', 'A natural sea arch and circular cliff pool on Nusa Penida west coast.', -8.73300000, 115.44900000, 'Broken Beach Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('angels-billabong', 'nusa-penida', 'NATURE', 1, 'HOURS', 4.6, 'Энджелс Биллабонг', 'Angel''s Billabong', 'Энджелс Биллабонг', 'Природный приливный бассейн рядом с Broken Beach, который безопаснее всего смотреть при спокойной воде и низком приливе.', 'A natural tidal pool beside Broken Beach, best viewed when the sea is calm and the tide is low.', -8.73400000, 115.44900000, 'Angels Billabong Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('crystal-bay', 'nusa-penida', 'BEACH', 3, 'HOURS', 4.6, 'Кристал-Бэй', 'Crystal Bay', 'Кристал-Бэй', 'Защищенная бухта для пляжного отдыха, снорклинга и дайв-поездок у Нуса-Пениды.', 'A sheltered bay used for beach time, snorkeling and dive trips on Nusa Penida.', -8.71500000, 115.45700000, 'Crystal Bay Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('diamond-beach', 'nusa-penida', 'BEACH', 3, 'HOURS', 4.7, 'Даймонд-Бич', 'Diamond Beach', 'Даймонд-Бич', 'Белый пляж под драматичными известняковыми скалами на востоке Нуса-Пениды.', 'A white beach below dramatic limestone cliffs on east Nusa Penida.', -8.77300000, 115.62000000, 'Diamond Beach Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('goa-giri-putri', 'nusa-penida', 'TEMPLE', 1, 'HOURS', 4.5, 'Пещерный храм Гоа Гири Путри', 'Goa Giri Putri Temple', 'Гоа Гири Путри үңгір храмы', 'Священный пещерный храм на востоке Нуса-Пениды с узким входом и большим внутренним залом.', 'A sacred cave temple on east Nusa Penida with a narrow entrance and a large inner chamber.', -8.70400000, 115.57500000, 'Goa Giri Putri Temple Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('devils-tears', 'nusa-lembongan', 'NATURE', 1, 'HOURS', 4.6, 'Слезы Дьявола', 'Devil''s Tears', 'Devil''s Tears', 'Драматичный скальный прибой на Нуса-Лембонгане, где волны взлетают брызгами, особенно на закате.', 'A dramatic cliff blowhole on Nusa Lembongan where waves explode into spray, especially at sunset.', -8.69000000, 115.43100000, 'Devils Tears Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg'),
    ('mangrove-forest-lembongan', 'nusa-lembongan', 'PARK', 2, 'HOURS', 4.4, 'Мангровый лес Лембонгана', 'Mangrove Forest Lembongan', 'Лембонган мангр орманы', 'Мангровые каналы для прогулок на лодке, каяке или сапборде на спокойной стороне острова.', 'Mangrove channels explored by small boat, kayak or paddleboard on the calm side of the island.', -8.66600000, 115.46000000, 'Mangrove Forest Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg'),
    ('yellow-bridge-lembongan', 'nusa-lembongan', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Желтый мост', 'Yellow Bridge', 'Сары көпір', 'Знаковый мост для пешеходов и скутеров между Нуса-Лембонганом и Нуса-Ченинганом.', 'An iconic pedestrian and scooter bridge linking Nusa Lembongan and Nusa Ceningan.', -8.69500000, 115.45100000, 'Yellow Bridge Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg'),
    ('mushroom-bay', 'nusa-lembongan', 'BEACH', 2, 'HOURS', 4.4, 'Машрум-Бэй', 'Mushroom Bay', 'Машрум-Бэй', 'Защищенная песчаная бухта с лодками, купанием и простыми кафе у воды.', 'A sheltered sandy bay with boats, swimming and casual beachfront dining.', -8.68500000, 115.43200000, 'Mushroom Bay Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg');

CREATE TEMP TABLE seed_indonesia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-bali-place:' || seed.slug) AS place_hash,
        md5('id-bali-media:' || seed.slug) AS media_hash
    FROM seed_indonesia_priority_places seed
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
    ARRAY['indonesia', 'bali', city_id, slug, lower(category), 'indonesia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    'Балидағы туристік орын: ' || title_kk || '. Туристік маршруттарға, гид ұсыныстарына және қала бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
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
    'ID',
    city_id,
    category,
    NULL::numeric,
    NULL::varchar(3),
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
FROM seed_indonesia_resolved_places
ON CONFLICT (id) DO UPDATE
SET
    default_locale = EXCLUDED.default_locale,
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    spots = EXCLUDED.spots,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    updated_at = NOW(),
    deleted_at = NULL
WHERE places.source = 'IMPORT';

INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed.id,
    locale_rows.locale,
    CASE locale_rows.locale
        WHEN 'ru' THEN seed.title_ru
        WHEN 'kk' THEN seed.title_kk
        ELSE seed.title_en
    END,
    CASE locale_rows.locale
        WHEN 'ru' THEN seed.description_ru
        WHEN 'kk' THEN seed.description_kk
        ELSE seed.description_en
    END,
    NOW(),
    NOW()
FROM seed_indonesia_resolved_places seed
CROSS JOIN (VALUES ('ru'), ('en'), ('kk')) AS locale_rows(locale)
ON CONFLICT (place_id, locale) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

WITH seed_locations (
    id,
    latitude,
    longitude,
    location_source_url
) AS (
    SELECT
        id,
        latitude,
        longitude,
        location_source_url
    FROM seed_indonesia_resolved_places
)
UPDATE places
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE places.id = seed_locations.id
    AND places.source = 'IMPORT';

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
FROM seed_indonesia_resolved_places
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = seed_indonesia_resolved_places.id
)
ON CONFLICT (id) DO UPDATE
SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, 'ID', city_id, 0, NOW()
FROM seed_indonesia_resolved_places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_indonesia_resolved_places;
DROP TABLE IF EXISTS seed_indonesia_priority_places;
