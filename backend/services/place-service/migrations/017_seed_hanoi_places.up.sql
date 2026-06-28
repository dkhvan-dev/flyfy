-- Curated Hanoi places seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN and city_id is hanoi;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price_amount stores a conservative entry-price floor; 0 means free entry.
-- - existing Hanoi seed entries from earlier migrations are not duplicated here.

WITH seed_base (
    id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'hoa-lo-prison', 'museum', 'history', 'french-colonial', 'indoor']::text[]),
        ('a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 'ARCHITECTURE', 2, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'ho-chi-minh-mausoleum', 'history', 'architecture', 'ba-dinh', 'landmark']::text[]),
        ('9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 'ARCHITECTURE', 1, 'HOURS', 4.6, ARRAY['vietnam', 'hanoi', 'st-joseph-cathedral', 'architecture', 'old-quarter', 'photo', 'culture']::text[]),
        ('0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 'ARCHITECTURE', 1, 'HOURS', 4.4, ARRAY['vietnam', 'hanoi', 'train-street', 'railway', 'old-quarter', 'photo', 'urban']::text[]),
        ('71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 'ENTERTAINMENT', 1, 'HOURS', 4.5, ARRAY['vietnam', 'hanoi', 'lotte-observation-deck', 'viewpoint', 'skyline', 'indoor', 'rainy-day']::text[]),
        ('fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 'ARCHITECTURE', 2, 'HOURS', 4.8, ARRAY['vietnam', 'hanoi', 'imperial-citadel-thang-long', 'unesco', 'history', 'architecture', 'culture']::text[]),
        ('6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['vietnam', 'hanoi', 'ho-chi-minh-museum', 'museum', 'history', 'ba-dinh', 'indoor']::text[]),
        ('74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 'TEMPLE', 1, 'HOURS', 4.6, ARRAY['vietnam', 'hanoi', 'one-pillar-pagoda', 'buddhist', 'temple', 'history', 'ba-dinh']::text[]),
        ('0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 'ARCHITECTURE', 3, 'HOURS', 4.8, ARRAY['vietnam', 'hanoi', 'old-quarter', 'walking', 'street-food', 'architecture', 'shopping']::text[]),
        ('4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 'ARCHITECTURE', 1, 'HOURS', 4.5, ARRAY['vietnam', 'hanoi', 'long-bien-bridge', 'bridge', 'red-river', 'history', 'photo']::text[]),
        ('587038b0-d882-4220-b65e-005b54d99344'::uuid, 'MARKET', 2, 'HOURS', 4.5, ARRAY['vietnam', 'hanoi', 'dong-xuan-market', 'market', 'shopping', 'street-food', 'old-quarter']::text[]),
        ('1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 'TEMPLE', 1, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'tran-quoc-pagoda', 'buddhist', 'temple', 'west-lake', 'culture']::text[]),
        ('2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 'ENTERTAINMENT', 2, 'HOURS', 4.6, ARRAY['vietnam', 'hanoi', 'water-puppet-theatre', 'show', 'culture', 'family', 'evening']::text[]),
        ('0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'vietnamese-womens-museum', 'museum', 'culture', 'history', 'indoor']::text[])
)
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
    seed_base.id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'VN',
    'hanoi',
    seed_base.category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 100000::numeric
        ELSE 50000::numeric
    END,
    'VND',
    seed_base.duration_value,
    seed_base.duration_unit,
    seed_base.rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    seed_base.tags,
    NOW(),
    NOW()
FROM seed_base
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

WITH seed_translations (
    place_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 'ru', 'Тюрьма Хоало', 'Исторический комплекс бывшей тюрьмы в центре Ханоя, связанный с французским колониальным периодом и войной во Вьетнаме. Подходит для вдумчивого indoor-маршрута, где важны контекст, документы и мемориальные экспозиции.'),
        ('0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 'en', 'Hỏa Lò Prison', 'A historic former prison complex in central Hanoi connected with the French colonial period and the Vietnam War. It works best as a thoughtful indoor route focused on context, documents and memorial exhibits.'),
        ('0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 'kk', 'Хоало түрмесі', 'Ханой орталығындағы Франция отаршылдығы кезеңімен және Вьетнам соғысымен байланысты бұрынғы түрме кешені. Контекст, құжаттар және мемориалдық экспозициялар маңызды indoor-маршрутқа сай.'),

        ('a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 'ru', 'Мавзолей Хо Ши Мина', 'Главный мемориальный объект на площади Бадинь, где можно увидеть торжественную архитектуру, церемониальный ритм и важный слой современной истории Вьетнама. Посещение лучше планировать с учетом расписания и правил поведения.'),
        ('a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 'en', 'Ho Chi Minh Mausoleum', 'The main memorial landmark on Ba Dinh Square, with solemn architecture, ceremonial rhythm and an important layer of modern Vietnamese history. It is best planned around opening schedules and visitor rules.'),
        ('a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 'kk', 'Хо Ши Мин кесенесі', 'Бадинь алаңындағы басты мемориалдық нысан: салтанатты сәулет, рәсімдік атмосфера және қазіргі Вьетнам тарихының маңызды қабаты. Баруды кесте мен тәртіп ережелерін ескеріп жоспарлаған дұрыс.'),

        ('9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 'ru', 'Собор Святого Иосифа', 'Неоготический собор рядом со Старым кварталом Ханоя, заметный по высоким башням, площади перед фасадом и оживленным кафе вокруг. Хорошая остановка для архитектуры, фото и вечерней прогулки по центру.'),
        ('9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 'en', 'St. Joseph''s Cathedral', 'A neo-Gothic cathedral near Hanoi Old Quarter, known for its tall towers, front square and lively cafes around it. It is a strong stop for architecture, photos and an evening walk through the center.'),
        ('9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 'kk', 'Әулие Иосиф соборы', 'Ханойдың Ескі кварталы жанындағы биік мұнаралары, алдындағы алаңы және айналасындағы жанданған кафелерімен белгілі неоготикалық собор. Сәулет, фото және орталықтағы кешкі серуен үшін жақсы аялдама.'),

        ('0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 'ru', 'Ханойская железнодорожная улица', 'Узкая городская улица, где железная дорога проходит вплотную к домам и кафе. Маршрут требует аккуратности и уважения к ограничениям безопасности, но хорошо показывает плотную городскую ткань старого Ханоя.'),
        ('0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 'en', 'Hanoi Train Street', 'A narrow urban street where the railway runs close to homes and cafes. The route needs care and respect for safety restrictions, but it gives a vivid view of old Hanoi urban density.'),
        ('0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 'kk', 'Ханой теміржол көшесі', 'Теміржол үйлер мен кафелерге өте жақын өтетін тар қалалық көше. Маршрут қауіпсіздік шектеулерін құрметтеуді талап етеді, бірақ ескі Ханойдың тығыз қалалық құрылымын анық көрсетеді.'),

        ('71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 'ru', 'Lotte Observation Deck Hanoi', 'Высотная смотровая площадка в Lotte Center Hanoi с панорамой города, Западного озера и плотной застройки столицы. Хороший indoor-вариант для дождливого дня, заката или первого знакомства с масштабом Ханоя.'),
        ('71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 'en', 'Lotte Observation Deck Hanoi', 'A high-rise observation deck in Lotte Center Hanoi with views over the city, West Lake and the dense capital skyline. It is a good indoor option for rain, sunset or a first sense of Hanoi scale.'),
        ('71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 'kk', 'Lotte Observation Deck Hanoi', 'Lotte Center Hanoi ішіндегі қаланы, Батыс көлді және астананың тығыз көкжиегін көрсететін биік шолу алаңы. Жаңбырлы күнге, күн батар шаққа немесе Ханой ауқымын алғаш көруге жақсы indoor-нұсқа.'),

        ('fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 'ru', 'Императорская цитадель Тханглонг', 'Исторический комплекс и объект ЮНЕСКО в центре Ханоя с воротами, археологическими слоями и следами разных династий. Подходит для маршрута о государственности, древнем городе и культурной памяти Вьетнама.'),
        ('fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 'en', 'Imperial Citadel of Thang Long', 'A historic complex and UNESCO site in central Hanoi with gates, archaeological layers and traces of multiple dynasties. It fits a route about statehood, the ancient city and Vietnamese cultural memory.'),
        ('fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 'kk', 'Тханглонг императорлық цитаделі', 'Ханой орталығындағы қақпалары, археологиялық қабаттары және бірнеше әулеттің іздері бар тарихи кешен әрі ЮНЕСКО нысаны. Мемлекеттілік, ежелгі қала және Вьетнам мәдени жады туралы маршрутқа сай.'),

        ('6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 'ru', 'Музей Хо Ши Мина', 'Музей рядом с мавзолеем, посвященный жизни Хо Ши Мина и политической истории страны. Лучше всего работает в связке с площадью Бадинь, пагодой на одном столбе и мемориальным кварталом.'),
        ('6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 'en', 'Ho Chi Minh Museum', 'A museum near the mausoleum dedicated to the life of Ho Chi Minh and the political history of the country. It works best together with Ba Dinh Square, One Pillar Pagoda and the memorial district.'),
        ('6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 'kk', 'Хо Ши Мин музейі', 'Кесене жанындағы Хо Ши Миннің өміріне және елдің саяси тарихына арналған музей. Бадинь алаңымен, Бір бағаналы пагодамен және мемориалдық ауданмен бірге қарағанда жақсы ашылады.'),

        ('74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 'ru', 'Пагода на одном столбе', 'Один из самых узнаваемых буддийских символов Ханоя, построенный как компактная пагода на одной опоре. Удобно совмещается с мавзолеем, музеем Хо Ши Мина и прогулкой по району Бадинь.'),
        ('74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 'en', 'One Pillar Pagoda', 'One of the most recognizable Buddhist symbols of Hanoi, built as a compact pagoda on a single pillar. It pairs easily with the mausoleum, Ho Chi Minh Museum and a Ba Dinh district walk.'),
        ('74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 'kk', 'Бір бағаналы пагода', 'Ханойдың ең танымал буддистік нышандарының бірі, бір бағананың үстіндегі ықшам пагода ретінде салынған. Кесенемен, Хо Ши Мин музейімен және Бадинь ауданындағы серуенмен оңай үйлеседі.'),

        ('0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 'ru', 'Старый квартал Ханоя', 'Плотный исторический район с узкими улицами, уличной едой, торговыми рядами, кафе и ремесленными кварталами. Это лучший маршрут для первого живого знакомства с городом без долгих переездов.'),
        ('0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 'en', 'Hanoi Old Quarter', 'A dense historic district with narrow streets, street food, market rows, cafes and craft streets. It is one of the best routes for a first vivid encounter with the city without long transfers.'),
        ('0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 'kk', 'Ханой ескі кварталы', 'Тар көшелері, көше тағамдары, сауда қатарлары, кафелері және қолөнер көшелері бар тығыз тарихи аудан. Қаланы ұзақ жолсыз алғаш тірі сезінуге арналған ең жақсы маршруттардың бірі.'),

        ('4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 'ru', 'Мост Лонгбьен', 'Исторический мост через Красную реку, связанный с городской инфраструктурой и колониальной инженерией. Хорош для короткой фотоостановки, прогулки на рассвете или маршрута о старом транспортном Ханое.'),
        ('4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 'en', 'Long Bien Bridge', 'A historic bridge across the Red River connected with city infrastructure and colonial engineering. It is good for a short photo stop, sunrise walk or a route about old transport Hanoi.'),
        ('4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 'kk', 'Лонгбьен көпірі', 'Қызыл өзен үстіндегі қала инфрақұрылымымен және отарлық инженериямен байланысты тарихи көпір. Қысқа фото аялдамаға, таңғы серуенге немесе ескі көлік Ханойы туралы маршрутқа жақсы.'),

        ('587038b0-d882-4220-b65e-005b54d99344'::uuid, 'ru', 'Рынок Донг Суан', 'Крупный крытый рынок в северной части Старого квартала с одеждой, товарами для дома, сувенирами и локальными закусками вокруг. Подходит для маршрута о торговом Ханое и практичных покупок.'),
        ('587038b0-d882-4220-b65e-005b54d99344'::uuid, 'en', 'Dong Xuan Market', 'A large covered market in the northern Old Quarter with clothes, household goods, souvenirs and local snacks around it. It suits a route about commercial Hanoi and practical shopping.'),
        ('587038b0-d882-4220-b65e-005b54d99344'::uuid, 'kk', 'Донг Суан базары', 'Ескі кварталдың солтүстігіндегі киім, тұрмыстық тауарлар, кәдесыйлар және маңындағы жергілікті тағамдары бар үлкен жабық базар. Сауда Ханойы және практикалық сатып алулар маршрутына сай.'),

        ('1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 'ru', 'Пагода Чанкуок', 'Одна из старейших пагод Ханоя на берегу Западного озера, известная многоярусной башней и спокойной атмосферой. Хорошая культурная остановка для маршрута вокруг озера и северной части центра.'),
        ('1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 'en', 'Tran Quoc Pagoda', 'One of the oldest pagodas in Hanoi on the shore of West Lake, known for its multi-tiered tower and calm atmosphere. It is a strong cultural stop for a route around the lake and northern center.'),
        ('1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 'kk', 'Чанкуок пагодасы', 'Батыс көл жағасындағы көпқабатты мұнарасымен және тыныш атмосферасымен белгілі Ханойдың ең көне пагодаларының бірі. Көл маңы және орталықтың солтүстігі бойынша мәдени аялдамаға жақсы.'),

        ('2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 'ru', 'Театр водных кукол Тханглонг', 'Классическое ханойское шоу водных кукол с музыкой, сценами народной жизни и коротким вечерним форматом. Хороший вариант для семей, первого вечера в городе и культурной программы без долгой подготовки.'),
        ('2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 'en', 'Thang Long Water Puppet Theatre', 'A classic Hanoi water puppet show with music, folk-life scenes and a compact evening format. It is a good choice for families, a first night in the city and an accessible cultural program.'),
        ('2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 'kk', 'Тханглонг су қуыршақ театры', 'Музыкасы, халық өмірінен көріністері және қысқа кешкі форматы бар классикалық Ханой су қуыршақ шоуы. Отбасыларға, қаладағы алғашқы кешке және жеңіл мәдени бағдарламаға жақсы таңдау.'),

        ('0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 'ru', 'Музей вьетнамских женщин', 'Современный музей о роли женщин во вьетнамской семье, обществе, ремеслах и истории. Подходит для содержательного indoor-маршрута, особенно если хочется выйти за пределы стандартных памятников.'),
        ('0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 'en', 'Vietnamese Women''s Museum', 'A modern museum about the role of women in Vietnamese family life, society, crafts and history. It is a meaningful indoor route, especially when travelers want more than the standard monuments.'),
        ('0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 'kk', 'Вьетнам әйелдері музейі', 'Вьетнам әйелдерінің отбасы, қоғам, қолөнер және тарихтағы рөлі туралы заманауи музей. Әсіресе стандартты ескерткіштерден бөлек мазмұнды indoor-маршрут іздегендерге қолайлы.')
)
INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed_translations.place_id,
    seed_translations.locale,
    seed_translations.title,
    seed_translations.description,
    NOW(),
    NOW()
FROM seed_translations
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
    VALUES
        ('0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 21.02530000, 105.84640000, 'https://www.openstreetmap.org/search?query=Hoa%20Lo%20Prison%20Hanoi'),
        ('a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 21.03680000, 105.83470000, 'https://www.openstreetmap.org/search?query=Ho%20Chi%20Minh%20Mausoleum%20Hanoi'),
        ('9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 21.02870000, 105.84890000, 'https://www.openstreetmap.org/search?query=St%20Joseph%20Cathedral%20Hanoi'),
        ('0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 21.03000000, 105.84260000, 'https://www.openstreetmap.org/search?query=Hanoi%20Train%20Street'),
        ('71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 21.03240000, 105.81260000, 'https://www.openstreetmap.org/search?query=Lotte%20Observation%20Deck%20Hanoi'),
        ('fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 21.03500000, 105.84030000, 'https://www.openstreetmap.org/search?query=Imperial%20Citadel%20of%20Thang%20Long'),
        ('6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 21.03540000, 105.83360000, 'https://www.openstreetmap.org/search?query=Ho%20Chi%20Minh%20Museum%20Hanoi'),
        ('74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 21.03590000, 105.83360000, 'https://www.openstreetmap.org/search?query=One%20Pillar%20Pagoda%20Hanoi'),
        ('0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 21.03550000, 105.85000000, 'https://www.openstreetmap.org/search?query=Hanoi%20Old%20Quarter'),
        ('4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 21.04400000, 105.85700000, 'https://www.openstreetmap.org/search?query=Long%20Bien%20Bridge%20Hanoi'),
        ('587038b0-d882-4220-b65e-005b54d99344'::uuid, 21.03820000, 105.85010000, 'https://www.openstreetmap.org/search?query=Dong%20Xuan%20Market%20Hanoi'),
        ('1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 21.04790000, 105.83650000, 'https://www.openstreetmap.org/search?query=Tran%20Quoc%20Pagoda%20Hanoi'),
        ('2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 21.03160000, 105.85300000, 'https://www.openstreetmap.org/search?query=Thang%20Long%20Water%20Puppet%20Theatre'),
        ('0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 21.02570000, 105.84940000, 'https://www.openstreetmap.org/search?query=Vietnamese%20Women%20Museum%20Hanoi')
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

WITH curated_media (
    id,
    place_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('49000000-0000-4000-8000-000000000001'::uuid, '0429c1dd-586e-4eef-a18f-3b00b55472d0'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hoa%20Lo%20Prison%20%28Maison%20Centrale%29%2C%20Hanoi%20%286923115824%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hoa_Lo_Prison_(Maison_Centrale),_Hanoi_(6923115824).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000002'::uuid, 'a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Ho%20Chi%20Minh%20Mausoleum%20in%20Hanoi.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Ho_Chi_Minh_Mausoleum_in_Hanoi.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000003'::uuid, '9487d156-5a4c-4a93-a359-629a34bf0bd1'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hanoi%20St%20Joseph%27s%20cathedral.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hanoi_St_Joseph%27s_cathedral.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000004'::uuid, '0f06fb99-6e0a-4f47-a62a-e6ac62c932a3'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Train%20street%20in%20Hanoi.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Train_street_in_Hanoi.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000005'::uuid, '71849380-f17f-49f8-bc6a-2bb051011fb8'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hanoi%20panoramic%20view%20from%20Lotte%203.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hanoi_panoramic_view_from_Lotte_3.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000006'::uuid, 'fa6e73e1-48aa-48cf-9b26-3bc6f953db84'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Central%20Sector%20of%20the%20Imperial%20Citadel%20of%20Thang%20Long%20-%20Hanoi.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Central_Sector_of_the_Imperial_Citadel_of_Thang_Long_-_Hanoi.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000007'::uuid, '6790557c-eeea-4a09-9f2c-58b3cc7cc7af'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hanoi%20Vietnam%20Ho-Chi-Minh-Museum-01.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hanoi_Vietnam_Ho-Chi-Minh-Museum-01.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000008'::uuid, '74174fa1-4e3c-49bf-ad92-da03c5f3a840'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/One%20Pillar%20Pagoda%2C%20Hanoi%2C%20Vietnam%2C%2020240123%201122%203222.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:One_Pillar_Pagoda,_Hanoi,_Vietnam,_20240123_1122_3222.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000009'::uuid, '0298b36d-ebb3-4c20-9371-38575e36bac5'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Old%20Quarter%20street%20scene%2C%20Hanoi%20%281%29%20%2838464672752%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Old_Quarter_street_scene,_Hanoi_(1)_(38464672752).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000010'::uuid, '4613a547-498e-4781-bdbc-ae3d75dd27b8'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Long-bien-bridge-3371617.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Long-bien-bridge-3371617.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000011'::uuid, '587038b0-d882-4220-b65e-005b54d99344'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Dong%20Xuan%20market.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Dong_Xuan_market.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000012'::uuid, '1000f102-63ac-4d09-9d4e-81bde627a01c'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Tran%20Quoc%20Pagoda%2C%20Hanoi%2C%20Vietnam%2C%2020240123%201623%203392.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Tran_Quoc_Pagoda,_Hanoi,_Vietnam,_20240123_1623_3392.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000013'::uuid, '2c1910d7-1a31-4768-a4da-fb3e937b3d16'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Thang%20Long%20Water%20Puppet%20Theatre.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Thang_Long_Water_Puppet_Theatre.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('49000000-0000-4000-8000-000000000014'::uuid, '0a73723a-d901-4b73-aaba-655eb0c8b9d9'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Vietnamese%20Women%27s%20Museum%20in%202014%20A%2022.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Vietnamese_Women%27s_Museum_in_2014_A_22.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
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
    curated_media.id,
    curated_media.place_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    curated_media.external_url,
    curated_media.source_url,
    curated_media.credit,
    curated_media.license,
    'PHOTO',
    0,
    NOW()
FROM curated_media
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = curated_media.place_id
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
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    '0429c1dd-586e-4eef-a18f-3b00b55472d0',
    'a1a5bd3d-7ede-4986-9eda-ba9b190a4e6e',
    '9487d156-5a4c-4a93-a359-629a34bf0bd1',
    '0f06fb99-6e0a-4f47-a62a-e6ac62c932a3',
    '71849380-f17f-49f8-bc6a-2bb051011fb8',
    'fa6e73e1-48aa-48cf-9b26-3bc6f953db84',
    '6790557c-eeea-4a09-9f2c-58b3cc7cc7af',
    '74174fa1-4e3c-49bf-ad92-da03c5f3a840',
    '0298b36d-ebb3-4c20-9371-38575e36bac5',
    '4613a547-498e-4781-bdbc-ae3d75dd27b8',
    '587038b0-d882-4220-b65e-005b54d99344',
    '1000f102-63ac-4d09-9d4e-81bde627a01c',
    '2c1910d7-1a31-4768-a4da-fb3e937b3d16',
    '0a73723a-d901-4b73-aaba-655eb0c8b9d9'
)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
