-- Extended Bali destination attractions seed.
-- This migration treats Bali as a tourist destination inside Indonesia while
-- keeping every attraction attached to a concrete practical city/area.

DROP TABLE IF EXISTS seed_indonesia_bali_extended_resolved;
DROP TABLE IF EXISTS seed_indonesia_bali_extended_attractions;

CREATE TEMP TABLE seed_indonesia_bali_extended_attractions (
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

INSERT INTO seed_indonesia_bali_extended_attractions (
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
    ('puputan-badung-square', 'denpasar', 'PARK', 1, 'HOURS', 4.3, 'Площадь Пупутан Бадунг', 'Puputan Badung Square', 'Пупутан Бадунг алаңы', 'Центральная городская площадь Денпасара рядом с музеем и храмами. Хорошая короткая остановка для исторического контекста столицы Бали.', 'A central Denpasar civic square near museums and temples. It works as a quick historical stop in Bali capital.', -8.65700000, 115.21760000, 'Puputan Badung Square Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('kreneng-night-market', 'denpasar', 'MARKET', 2, 'HOURS', 4.2, 'Ночной рынок Крененг', 'Kreneng Night Market', 'Крененг түнгі базары', 'Локальный ночной рынок Денпасара с уличной едой и повседневными товарами. Подходит для вечернего маршрута без пляжной туристической витрины.', 'A local Denpasar night market with street food and everyday goods. It suits an evening route beyond the beach resort layer.', -8.65130000, 115.22270000, 'Kreneng Night Market Denpasar', 'Aerial_view_of_Bajra_Sandhi_Monument_Denpasar_Bali_Indonesia.jpg'),
    ('big-garden-corner', 'denpasar', 'PARK', 2, 'HOURS', 4.2, 'Big Garden Corner', 'Big Garden Corner', 'Big Garden Corner', 'Семейный парк с садами, скульптурами и легкими фото-зонами на востоке Денпасара. Удобен для спокойной остановки с детьми.', 'A family garden park with sculptures and simple photo areas in east Denpasar. It is useful for a calm stop with children.', -8.65450000, 115.25680000, 'Big Garden Corner Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('discovery-shopping-mall', 'kuta', 'SHOPPING', 2, 'HOURS', 4.3, 'Discovery Shopping Mall', 'Discovery Shopping Mall', 'Discovery Shopping Mall', 'Большой молл у пляжа Кута с магазинами, едой и удобной паузой после Waterbom или прогулки по побережью.', 'A large beachfront Kuta mall with shops, dining and a convenient pause after Waterbom or a coastal walk.', -8.72800000, 115.16900000, 'Discovery Shopping Mall Kuta', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('lippo-mall-kuta', 'kuta', 'SHOPPING', 2, 'HOURS', 4.2, 'Lippo Mall Kuta', 'Lippo Mall Kuta', 'Lippo Mall Kuta', 'Практичный торговый центр в южной Куте рядом с отелями и аэропортовым коридором. Полезен для покупок, еды и короткой indoor-паузы.', 'A practical South Kuta mall near hotels and the airport corridor. It is useful for shopping, food and a short indoor pause.', -8.73510000, 115.16600000, 'Lippo Mall Kuta Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('bali-bombing-memorial', 'kuta', 'OTHER', 1, 'HOURS', 4.4, 'Мемориал взрывов на Бали', 'Bali Bombing Memorial', 'Бали жарылыстары мемориалы', 'Мемориал в центре Куты, напоминающий о трагедии 2002 года. Важная спокойная остановка для уважительного городского маршрута.', 'A central Kuta memorial commemorating the 2002 tragedy. It is an important quiet stop for a respectful city route.', -8.71630000, 115.17440000, 'Bali Bombing Memorial Kuta', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('dharmayana-temple-kuta', 'kuta', 'TEMPLE', 1, 'HOURS', 4.3, 'Храм Дхармаяна Кута', 'Dharmayana Temple Kuta', 'Дхармаяна Кута храмы', 'Исторический китайско-буддийский храм в Куте, который добавляет культурный слой к пляжному и shopping-маршруту.', 'A historic Chinese-Buddhist temple in Kuta that adds a cultural layer to beach and shopping routes.', -8.72480000, 115.17610000, 'Dharmayana Temple Kuta', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('garlic-lane-legian', 'legian', 'MARKET', 1, 'HOURS', 4.1, 'Garlic Lane', 'Garlic Lane', 'Garlic Lane', 'Улица магазинов, сувениров и небольших кафе в Легиане. Хороша как легкая прогулка между Кутой и Семиньяком.', 'A Legian street for small shops, souvenirs and casual cafes. It works as an easy walk between Kuta and Seminyak.', -8.70060000, 115.17000000, 'Garlic Lane Legian Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('double-six-beach', 'seminyak', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Double Six', 'Double Six Beach', 'Double Six жағажайы', 'Популярный участок побережья Семиньяка и Легиана с закатами, цветными пуфами и пляжными кафе.', 'A popular Seminyak and Legian beachfront stretch with sunsets, beanbags and beach cafes.', -8.69680000, 115.16320000, 'Double Six Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('petitenget-beach', 'seminyak', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Петитенгет', 'Petitenget Beach', 'Петитенгет жағажайы', 'Пляж рядом с храмом Петитенгет и ресторанами Семиньяка. Подходит для заката и спокойной coastal-прогулки.', 'A beach beside Petitenget Temple and Seminyak dining spots. It suits sunset and a calm coastal walk.', -8.67810000, 115.15160000, 'Petitenget Beach Seminyak', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('berawa-beach', 'canggu', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Берава', 'Berawa Beach', 'Берава жағажайы', 'Серф-пляж Чангу между Batu Bolong и Семиньяком, рядом с beach clubs и кафе. Хорош для активного вечера.', 'A Canggu surf beach between Batu Bolong and Seminyak, close to beach clubs and cafes. It fits an active evening.', -8.66070000, 115.13810000, 'Berawa Beach Canggu', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('pererenan-beach', 'canggu', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Переренан', 'Pererenan Beach', 'Переренан жағажайы', 'Более спокойный пляж рядом с Чангу с серфингом, черным песком и вечерними прогулками.', 'A calmer beach near Canggu with surf, black sand and evening walks.', -8.65130000, 115.12060000, 'Pererenan Beach Bali', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('samadi-sunday-market', 'canggu', 'MARKET', 1, 'HOURS', 4.2, 'Воскресный рынок Samadi', 'Samadi Sunday Market', 'Samadi жексенбілік базары', 'Небольшой рынок Чангу с органическими продуктами, ремеслами и локальной wellness-аудиторией.', 'A small Canggu market with organic produce, crafts and a local wellness crowd.', -8.65020000, 115.13460000, 'Samadi Sunday Market Canggu', 'Kuta_Beach,_Bali,_20220825_1706_0864.jpg'),
    ('mertasari-beach', 'sanur', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Мертасари', 'Mertasari Beach', 'Мертасари жағажайы', 'Южная часть Санура со спокойной водой, прогулками, кайтами и семейной атмосферой.', 'The southern part of Sanur with calm water, walks, kites and a family-friendly mood.', -8.71420000, 115.25690000, 'Mertasari Beach Sanur', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('puja-mandala', 'nusa-dua', 'TEMPLE', 1, 'HOURS', 4.5, 'Комплекс Пуджа Мандала', 'Puja Mandala', 'Пуджа Мандала кешені', 'Межрелигиозный комплекс Нуса-Дуа с храмом, мечетью, церковью и буддийским зданием рядом друг с другом.', 'A Nusa Dua interfaith complex with Hindu, Muslim, Christian and Buddhist houses of worship side by side.', -8.80190000, 115.21920000, 'Puja Mandala Nusa Dua', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('geger-beach', 'nusa-dua', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Гегер', 'Geger Beach', 'Гегер жағажайы', 'Спокойный пляж Нуса-Дуа с мягким песком, отелями рядом и более размеренным ритмом, чем в Куте.', 'A calm Nusa Dua beach with soft sand, nearby resorts and a more relaxed rhythm than Kuta.', -8.81310000, 115.22620000, 'Geger Beach Bali', 'Dvarpala_statue_near_Sanur_Beach,_Bali_02.jpg'),
    ('kedonganan-fish-market', 'jimbaran', 'MARKET', 1, 'HOURS', 4.2, 'Рыбный рынок Кедонганан', 'Kedonganan Fish Market', 'Кедонганан балық базары', 'Утренний рыбный рынок рядом с Джимбараном, полезный для гастро-маршрутов и понимания местной seafood-культуры.', 'A morning fish market near Jimbaran, useful for food routes and local seafood culture.', -8.75670000, 115.17100000, 'Kedonganan Fish Market Bali', 'Sunset_at_Garuda_Wisnu_Kencana_Bali.jpg'),
    ('nyang-nyang-beach', 'uluwatu', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Ньянг-Ньянг', 'Nyang Nyang Beach', 'Ньянг-Ньянг жағажайы', 'Длинный пляж под скалами Букита, более дикий и просторный, чем многие южные пляжи.', 'A long beach below Bukit cliffs, wilder and more spacious than many south Bali beaches.', -8.83790000, 115.09380000, 'Nyang Nyang Beach Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('karang-boma-cliff', 'uluwatu', 'NATURE', 1, 'HOURS', 4.6, 'Скала Каранг Бома', 'Karang Boma Cliff', 'Каранг Бома жартасы', 'Смотровая точка на утесах Улувату с панорамой океана и сильным sunset-сценарием.', 'A Uluwatu cliff viewpoint with ocean panorama and a strong sunset scenario.', -8.84200000, 115.08300000, 'Karang Boma Cliff Bali', 'Luhur_Uluwatu_Temple,_Bali,_20220826_0953_1016.jpg'),
    ('ubud-palace', 'ubud', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Дворец Убуда', 'Ubud Palace', 'Убуд сарайы', 'Королевский дворец в центре Убуда рядом с рынком и храмом Сарасвати. Удобная культурная точка для пешего маршрута.', 'The royal palace in central Ubud near the market and Saraswati temple. It is an easy culture stop for a walking route.', -8.50690000, 115.26250000, 'Ubud Palace Bali', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('pura-dalem-ubud', 'ubud', 'TEMPLE', 1, 'HOURS', 4.4, 'Храм Пура Далем Убуд', 'Pura Dalem Ubud', 'Пура Далем Убуд храмы', 'Храм в центре Убуда, известный резьбой и вечерними танцевальными представлениями по расписанию.', 'A central Ubud temple known for carvings and scheduled evening dance performances.', -8.50540000, 115.25990000, 'Pura Dalem Ubud', 'Macaca_fascicularis,_Ubud_Monkey_Forest,_Bali,_20220822_1012_9935.jpg'),
    ('tibumana-waterfall', 'gianyar', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Тибумана', 'Tibumana Waterfall', 'Тибумана сарқырамасы', 'Аккуратный водопад в зеленой долине Гианьяра, популярный для короткой поездки из Убуда.', 'A neat waterfall in a green Gianyar valley, popular for a short trip from Ubud.', -8.50120000, 115.33010000, 'Tibumana Waterfall Bali', 'Rice_terraces,_Bali.jpg'),
    ('batuan-temple', 'sukawati', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Батуан', 'Batuan Temple', 'Батуан храмы', 'Традиционный храм рядом с Убудом и Сукавати, известный резьбой, дворами и классической архитектурой.', 'A traditional temple near Ubud and Sukawati, known for carvings, courtyards and classic architecture.', -8.56290000, 115.28220000, 'Batuan Temple Bali', 'Rice_terraces,_Bali.jpg'),
    ('celuk-village', 'sukawati', 'OTHER', 1, 'HOURS', 4.2, 'Деревня Челук', 'Celuk Village', 'Челук ауылы', 'Ремесленная деревня, известная серебряными и золотыми изделиями. Подходит для shopping-маршрутов с локальным контекстом.', 'A craft village known for silver and gold work. It suits shopping routes with local context.', -8.59560000, 115.26250000, 'Celuk Village Bali', 'Rice_terraces,_Bali.jpg'),
    ('aloha-ubud-swing', 'tegallalang', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Aloha Ubud Swing', 'Aloha Ubud Swing', 'Aloha Ubud Swing', 'Фото-парк с качелями, видами на зелень и кофейными дегустациями рядом с Тегаллалангом.', 'A photo park with swings, green views and coffee tastings near Tegallalang.', -8.44950000, 115.27970000, 'Aloha Ubud Swing Bali', 'Rice_terraces,_Bali.jpg'),
    ('bali-pulina', 'tegallalang', 'FOOD', 1, 'HOURS', 4.3, 'Bali Pulina', 'Bali Pulina', 'Bali Pulina', 'Агро-кофейная остановка рядом с рисовыми террасами, где удобно совместить дегустацию и виды.', 'An agro-coffee stop near rice terraces, combining tastings and valley views.', -8.43100000, 115.28130000, 'Bali Pulina Tegallalang', 'Rice_terraces,_Bali.jpg'),
    ('the-blooms-garden-bali', 'bedugul', 'PARK', 2, 'HOURS', 4.4, 'The Blooms Garden Bali', 'The Blooms Garden Bali', 'The Blooms Garden Bali', 'Горный цветочный парк в районе Бедугул с прохладным климатом, садами и семейными фото-зонами.', 'A highland flower park near Bedugul with cool air, gardens and family photo spots.', -8.28430000, 115.15030000, 'The Blooms Garden Bali', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('handara-gate', 'bedugul', 'ARCHITECTURE', 1, 'HOURS', 4.2, 'Ворота Handara', 'Handara Gate', 'Handara қақпасы', 'Известные балийские ворота в горной зоне Бедугула, обычно используются как короткая фото-остановка.', 'A well-known Balinese gate in the Bedugul highlands, usually used as a short photo stop.', -8.25030000, 115.16770000, 'Handara Gate Bali', 'Pura_Ulun_Danu_Beratan_in_bali.jpg'),
    ('pura-luhur-batukaru', 'tabanan', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Батукару', 'Pura Luhur Batukaru', 'Батукару храмы', 'Священный горный храм у склонов Батукару в более спокойной части Табанана.', 'A sacred mountain temple on the slopes of Batukaru in a quieter part of Tabanan.', -8.36720000, 115.10280000, 'Pura Luhur Batukaru Bali', 'Jatiluwih_rice_terraces_SF0002.jpg'),
    ('lovina-dolphin-statue', 'lovina', 'ARCHITECTURE', 1, 'HOURS', 4.1, 'Статуя дельфина в Ловине', 'Lovina Dolphin Statue', 'Ловина дельфин мүсіні', 'Небольшой ориентир у пляжа Ловина, удобный как точка встречи и начало прогулки по северному побережью.', 'A small landmark by Lovina Beach, useful as a meeting point and start of a north-coast walk.', -8.16190000, 115.02460000, 'Lovina Dolphin Statue Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('buleleng-museum', 'singaraja', 'MUSEUM', 1, 'HOURS', 4.2, 'Музей Булеленг', 'Buleleng Museum', 'Булеленг музейі', 'Музей в Сингарадже о северобалийской истории, культуре и колониальном прошлом региона.', 'A Singaraja museum about North Bali history, culture and colonial-era context.', -8.11200000, 115.08830000, 'Buleleng Museum Singaraja', 'Rice_terraces,_Bali.jpg'),
    ('gedong-kirtya-library', 'singaraja', 'MUSEUM', 1, 'HOURS', 4.2, 'Библиотека Гедонг Киртья', 'Gedong Kirtya Library', 'Гедонг Киртья кітапханасы', 'Историческая библиотека с коллекциями лонтар-манускриптов и культурным архивом Бали.', 'A historic library with lontar manuscript collections and Bali cultural archive.', -8.11220000, 115.08950000, 'Gedong Kirtya Singaraja', 'Rice_terraces,_Bali.jpg'),
    ('melanting-waterfall', 'munduk', 'NATURE', 2, 'HOURS', 4.5, 'Водопад Мелантинг', 'Melanting Waterfall', 'Мелантинг сарқырамасы', 'Лесной водопад в районе Мундук, который хорошо дополняет прохладные highland-маршруты.', 'A forest waterfall in Munduk that complements cool highland routes.', -8.26370000, 115.06170000, 'Melanting Waterfall Munduk', 'Rice_terraces,_Bali.jpg'),
    ('lipah-beach-amed', 'amed', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Липах', 'Lipah Beach', 'Липах жағажайы', 'Спокойный пляж Амеда с доступным снорклингом и расслабленным восточным побережьем.', 'A calm Amed beach with easy snorkeling and relaxed east-coast rhythm.', -8.34450000, 115.67970000, 'Lipah Beach Amed', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('goa-lawah-temple', 'karangasem', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Гоа Лавах', 'Goa Lawah Temple', 'Гоа Лавах храмы', 'Храм у пещеры летучих мышей на восточном побережье, важный для маршрутов между Сануром и Карангасемом.', 'A temple by a bat cave on the east coast, useful for routes between Sanur and Karangasem.', -8.55280000, 115.46890000, 'Goa Lawah Temple Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('lahangan-sweet', 'karangasem', 'NATURE', 2, 'HOURS', 4.6, 'Смотровая Lahangan Sweet', 'Lahangan Sweet', 'Lahangan Sweet', 'Видовая площадка Восточного Бали с панорамой Агунга, леса и побережья.', 'An East Bali viewpoint with panoramas of Mount Agung, forest and coastline.', -8.37100000, 115.62600000, 'Lahangan Sweet Bali', 'Landscape,_Tirta_Gangga,_Bali.jpg'),
    ('penglipuran-village', 'kintamani', 'OTHER', 2, 'HOURS', 4.7, 'Деревня Пенглипуран', 'Penglipuran Village', 'Пенглипуран ауылы', 'Традиционная деревня Бангли с аккуратной планировкой, архитектурой и bamboo forest рядом.', 'A traditional Bangli village with orderly layout, architecture and nearby bamboo forest.', -8.42470000, 115.35770000, 'Penglipuran Village Bali', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('tukad-cepung-waterfall', 'kintamani', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Тукад Чепунг', 'Tukad Cepung Waterfall', 'Тукад Чепунг сарқырамасы', 'Водопад в каньоне-пещере, известный световыми лучами и фотогеничным заходом через каменные стены.', 'A cave-like canyon waterfall known for light rays and a photogenic walk between stone walls.', -8.43980000, 115.38700000, 'Tukad Cepung Waterfall Bali', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('ulun-danu-batur-temple', 'kintamani', 'TEMPLE', 1, 'HOURS', 4.5, 'Храм Улун Дану Батур', 'Ulun Danu Batur Temple', 'Улун Дану Батур храмы', 'Крупный храмовый комплекс Кинтамани, связанный с озером Батур и горной духовной традицией.', 'A major Kintamani temple complex connected with Lake Batur and highland spiritual traditions.', -8.25450000, 115.33250000, 'Ulun Danu Batur Temple Bali', 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg'),
    ('atuh-beach', 'nusa-penida', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Атух', 'Atuh Beach', 'Атух жағажайы', 'Пляж на востоке Нуса-Пениды среди скал и небольших островков. Хорош как часть восточного маршрута острова.', 'An east Nusa Penida beach framed by cliffs and small offshore rocks. It works well in an east-island route.', -8.77910000, 115.61690000, 'Atuh Beach Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('thousand-islands-viewpoint', 'nusa-penida', 'NATURE', 1, 'HOURS', 4.7, 'Смотровая Thousand Islands', 'Thousand Islands Viewpoint', 'Thousand Islands көрініс алаңы', 'Видовая точка на востоке Нуса-Пениды с панорамой скал, океана и небольших островов.', 'An east Nusa Penida viewpoint overlooking cliffs, ocean and small islands.', -8.77830000, 115.61920000, 'Thousand Islands Viewpoint Nusa Penida', 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg'),
    ('dream-beach-lembongan', 'nusa-lembongan', 'BEACH', 2, 'HOURS', 4.5, 'Dream Beach Лембонган', 'Dream Beach Lembongan', 'Dream Beach Лембонган', 'Небольшой песчаный пляж на Нуса-Лембонгане рядом с Devil''s Tears, удобный для island-day маршрута.', 'A small sandy Nusa Lembongan beach near Devil''s Tears, useful for an island-day route.', -8.68830000, 115.43190000, 'Dream Beach Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg'),
    ('sandy-bay-beach-club', 'nusa-lembongan', 'FOOD', 2, 'HOURS', 4.4, 'Sandy Bay Beach Club', 'Sandy Bay Beach Club', 'Sandy Bay Beach Club', 'Пляжный ресторан и клуб у скал Лембонгана, удобный для заката и паузы после прогулки.', 'A beachfront restaurant and club by Lembongan cliffs, useful for sunset and a rest after exploring.', -8.69150000, 115.42990000, 'Sandy Bay Beach Club Nusa Lembongan', 'Devil%27s_Tear,_Nusa_Lembongan.jpg');

CREATE TEMP TABLE seed_indonesia_bali_extended_resolved AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-indonesia-bali-extended-attraction:' || seed.slug) AS attraction_hash,
        md5('id-indonesia-bali-extended-media:' || seed.slug) AS media_hash
    FROM seed_indonesia_bali_extended_attractions seed
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
    ARRAY['indonesia', 'bali', city_id, slug, lower(category), 'indonesia-bali-extended-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    'Бали бағыты бойынша туристік орын: ' || title_kk || '. Қала, аудан және бағыт бойынша іздеуге арналған.' AS description_kk,
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
FROM seed_indonesia_bali_extended_resolved
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
WHERE attractions.source = 'IMPORT';

INSERT INTO attraction_translations (
    attraction_id,
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
FROM seed_indonesia_bali_extended_resolved seed
CROSS JOIN (VALUES ('ru'), ('en'), ('kk')) AS locale_rows(locale)
ON CONFLICT (attraction_id, locale) DO UPDATE
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
    FROM seed_indonesia_bali_extended_resolved
)
UPDATE attractions
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE attractions.id = seed_locations.id
    AND attractions.source = 'IMPORT';

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
FROM seed_indonesia_bali_extended_resolved
WHERE EXISTS (
    SELECT 1
    FROM attractions a
    WHERE a.id = seed_indonesia_bali_extended_resolved.id
)
ON CONFLICT (id) DO UPDATE
SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO attraction_city_links (id, attraction_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, 'ID', city_id, 0, NOW()
FROM seed_indonesia_bali_extended_resolved
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_indonesia_bali_extended_resolved;
DROP TABLE IF EXISTS seed_indonesia_bali_extended_attractions;
