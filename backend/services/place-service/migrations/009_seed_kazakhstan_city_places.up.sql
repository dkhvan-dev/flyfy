-- Curated in-city Kazakhstan places seed.
-- Texts are original Inflap editorial summaries localized for en, ru, kk.
-- Sources audited in May 2026:
-- - Visit Almaty for Almaty urban parks, Kok Tobe, Central Park, Botanical Garden and Panfilov Park references.
-- - Visit Astana and QazTravel for Astana landmarks, Nur Alem, National Museum, Hazrat Sultan and city routes.
-- - Visit Shymkent / Info Shymkent for Shymkent Citadel, Zoo, Dendropark and Abay Park.
-- - QazTravel, regional tourism portals and Museums of Kazakhstan for Turkestan, Karaganda, Atyrau, Aktau,
--   Pavlodar, East Kazakhstan, Semey, Kostanay, Kyzylorda, Oral, Aktobe and Kokshetau.
-- Selection policy:
-- - this migration complements nature-heavy national seeds with practical city anchors;
-- - every place belongs to a reference-service/data/cities.json city_id;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price_amount stores a conservative entry-price floor; 0 means free entry.

WITH seed_base (
    id,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 'almaty', 'ENTERTAINMENT', 3, 'HOURS', 4.7, ARRAY['kazakhstan', 'almaty', 'kok-tobe', 'cable-car', 'viewpoint', 'family', 'city']::text[]),
        ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 'almaty', 'PARK', 2, 'HOURS', 4.7, ARRAY['kazakhstan', 'almaty', 'panfilov-park', 'ascension-cathedral', 'history', 'architecture', 'walk']::text[]),
        ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 'almaty', 'PARK', 3, 'HOURS', 4.6, ARRAY['kazakhstan', 'almaty', 'central-park', 'gorky-park', 'amusement-park', 'lake', 'family']::text[]),
        ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 'almaty', 'ENTERTAINMENT', 3, 'HOURS', 4.4, ARRAY['kazakhstan', 'almaty', 'fantasy-world', 'amusement-park', 'rides', 'family', 'kids']::text[]),
        ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 'almaty', 'ENTERTAINMENT', 3, 'HOURS', 4.5, ARRAY['kazakhstan', 'almaty', 'zoo', 'family', 'animals', 'education', 'kids']::text[]),
        ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 'almaty', 'MARKET', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'almaty', 'green-bazaar', 'market', 'food', 'local-life', 'shopping']::text[]),
        ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 'almaty', 'MARKET', 3, 'HOURS', 4.3, ARRAY['kazakhstan', 'almaty', 'barakholka', 'market', 'shopping', 'local-life', 'bargain']::text[]),
        ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, 'almaty', 'PARK', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'almaty', 'first-president-park', 'park', 'fountains', 'walk', 'family']::text[]),
        ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 'astana', 'ARCHITECTURE', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'astana', 'khan-shatyr', 'architecture', 'shopping', 'entertainment', 'landmark']::text[]),
        ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 'astana', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['kazakhstan', 'astana', 'nur-alem', 'expo', 'museum', 'future-energy', 'architecture']::text[]),
        ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 'astana', 'PARK', 2, 'HOURS', 4.5, ARRAY['kazakhstan', 'astana', 'botanical-garden', 'park', 'walk', 'green-space', 'family']::text[]),
        ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 'astana', 'TEMPLE', 1, 'HOURS', 4.7, ARRAY['kazakhstan', 'astana', 'hazrat-sultan', 'mosque', 'architecture', 'spiritual', 'landmark']::text[]),
        ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 'astana', 'MUSEUM', 3, 'HOURS', 4.7, ARRAY['kazakhstan', 'astana', 'national-museum', 'history', 'culture', 'golden-man', 'family']::text[]),
        ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 'astana', 'ARCHITECTURE', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'astana', 'opera', 'theatre', 'architecture', 'culture', 'evening']::text[]),
        ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 'shymkent', 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'shymkent', 'citadel', 'old-city', 'history', 'silk-road', 'museum']::text[]),
        ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 'shymkent', 'ENTERTAINMENT', 3, 'HOURS', 4.5, ARRAY['kazakhstan', 'shymkent', 'zoo', 'family', 'animals', 'safari-park', 'kids']::text[]),
        ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 'shymkent', 'PARK', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'shymkent', 'dendropark', 'arboretum', 'park', 'lake', 'walk']::text[]),
        ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 'shymkent', 'PARK', 2, 'HOURS', 4.4, ARRAY['kazakhstan', 'shymkent', 'abay-park', 'memorials', 'museum', 'walk', 'city']::text[]),
        ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 'shymkent', 'PARK', 2, 'HOURS', 4.3, ARRAY['kazakhstan', 'shymkent', 'ken-baba', 'ethno-park', 'family', 'walk', 'city']::text[]),
        ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 'turkestan', 'ENTERTAINMENT', 3, 'HOURS', 4.6, ARRAY['kazakhstan', 'turkestan', 'karavansaray', 'silk-road', 'shopping', 'flying-theatre', 'family']::text[]),
        ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 'turkestan', 'MUSEUM', 3, 'HOURS', 4.7, ARRAY['kazakhstan', 'turkestan', 'azret-sultan', 'museum-reserve', 'yasawi', 'history', 'pilgrimage']::text[]),
        ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 'turkestan', 'MUSEUM', 4, 'HOURS', 4.6, ARRAY['kazakhstan', 'turkestan-region', 'otrar', 'ancient-settlement', 'silk-road', 'archaeology', 'history']::text[]),
        ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 'karaganda', 'MUSEUM', 3, 'HOURS', 4.7, ARRAY['kazakhstan', 'karaganda', 'karlag', 'dolinka', 'museum', 'history', 'memory']::text[]),
        ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 'karaganda', 'PARK', 2, 'HOURS', 4.4, ARRAY['kazakhstan', 'karaganda', 'central-park', 'lake', 'walk', 'family', 'city']::text[]),
        ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 'atyrau', 'ARCHITECTURE', 2, 'HOURS', 4.5, ARRAY['kazakhstan', 'atyrau', 'bridges', 'embankment', 'ural-river', 'europe-asia', 'walk']::text[]),
        ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, 'aktau', 'NATURE', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'aktau', 'rocky-trail', 'caspian-sea', 'walk', 'cliffs', 'sunset']::text[]),
        ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 'aktau', 'PARK', 2, 'HOURS', 4.4, ARRAY['kazakhstan', 'aktau', 'seafront', 'caspian-sea', 'promenade', 'sunset', 'city']::text[]),
        ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 'pavlodar', 'TEMPLE', 1, 'HOURS', 4.6, ARRAY['kazakhstan', 'pavlodar', 'mashkhur-jusup', 'mosque', 'architecture', 'spiritual', 'landmark']::text[]),
        ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 'ust-kamenogorsk', 'MUSEUM', 3, 'HOURS', 4.6, ARRAY['kazakhstan', 'ust-kamenogorsk', 'ethnographic-museum', 'ethno-park', 'open-air', 'culture', 'family']::text[]),
        ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 'semey', 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'semey', 'abai', 'museum-reserve', 'literature', 'culture', 'history']::text[]),
        ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 'kyzylorda', 'ARCHITECTURE', 2, 'HOURS', 4.6, ARRAY['kazakhstan', 'kyzylorda', 'korkyt-ata', 'memorial', 'music', 'syrdarya', 'culture']::text[]),
        ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 'aktobe', 'TEMPLE', 1, 'HOURS', 4.6, ARRAY['kazakhstan', 'aktobe', 'nur-gasyr', 'mosque', 'architecture', 'spiritual', 'landmark']::text[]),
        ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 'kostanay', 'MUSEUM', 2, 'HOURS', 4.4, ARRAY['kazakhstan', 'kostanay', 'regional-museum', 'local-history', 'culture', 'history', 'city']::text[]),
        ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 'oral', 'MUSEUM', 2, 'HOURS', 4.5, ARRAY['kazakhstan', 'oral', 'uralsk', 'west-kazakhstan-museum', 'local-history', 'culture', 'history']::text[]),
        ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 'kokshetau', 'MUSEUM', 2, 'HOURS', 4.5, ARRAY['kazakhstan', 'kokshetau', 'akmola-museum', 'local-history', 'culture', 'history', 'city']::text[])
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
    'en',
    'KZ',
    seed_base.city_id,
    seed_base.category,
    CASE seed_base.id
        -- Almaty
        WHEN '2eeacb52-12ef-4499-b229-05e52a199d22'::uuid THEN 10000::numeric -- Kok Tobe cable car, round-trip adult 2026
        WHEN '396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid THEN 7000::numeric  -- Fantasy World, weekday adult, all rides
        WHEN '8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid THEN 1450::numeric  -- Almaty Zoo adult (2026)
        -- Astana
        WHEN 'abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid THEN 0::numeric     -- Nur Alem: closed Dec 2024, no admission in 2026
        WHEN '12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid THEN 2000::numeric  -- National Museum of Kazakhstan, adult
        WHEN 'adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid THEN 1000::numeric  -- Astana Opera, show ticket from
        -- Shymkent
        WHEN '92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid THEN 800::numeric   -- Shymkent Zoo adult
        WHEN 'd3951503-5e02-41ec-b886-dfc7cce1f925'::uuid THEN 0::numeric     -- Dendropark, free entry
        -- Turkestan
        WHEN 'b8847588-a922-42cf-94a2-ffcbf043922a'::uuid THEN 0::numeric     -- Karavansaray: public area free (flying theatre 6500 separate)
        WHEN '788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid THEN 1000::numeric  -- Azret Sultan reserve, local base
        WHEN '877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid THEN 200::numeric   -- Otrar settlement, adult
        -- Karaganda
        WHEN '1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid THEN 1000::numeric  -- KarLag Museum adult
        -- Kyzylorda
        WHEN '1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid THEN 500::numeric   -- Korkyt Ata memorial complex
        -- Regional museums (approximate floors, ~500 KZT typical)
        WHEN 'b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid THEN 500::numeric   -- East KZ ethnographic museum-reserve
        WHEN '90742f2d-6b54-4676-930c-97bc59b60a64'::uuid THEN 500::numeric   -- Abai museum-reserve, Semey
        WHEN '0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid THEN 500::numeric   -- Kostanay regional museum
        WHEN 'eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid THEN 500::numeric   -- West Kazakhstan museum, Oral
        WHEN '3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid THEN 500::numeric   -- Akmola regional museum, Kokshetau
        -- Free entry: parks, embankments, markets, mosques, memorials, open areas
        ELSE 0::numeric
    END,
    'KZT',
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
        ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 'en', 'Kok Tobe Hill and Cable Car', 'A classic Almaty viewpoint reached by cable car or road, with city panoramas, cafes, small family places and evening lights above the foothills. It is a strong first-day stop because it explains the scale of the city at a glance.'),
        ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 'ru', 'Кок-Тобе и канатная дорога', 'Классическая смотровая точка Алматы, куда можно подняться по канатной дороге или на машине: панорамы города, кафе, семейные развлечения и вечерние огни над предгорьями. Хорошая первая точка, чтобы быстро почувствовать масштаб города.'),
        ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 'kk', 'Көк-Төбе және аспалы жол', 'Алматының классикалық көрініс нүктесі: аспалы жолмен не көлікпен көтерілуге болады, қала панорамасы, кафе, отбасылық ойын-сауық және тау бөктеріндегі кешкі шамдар бар. Қаланы алғаш тануға ыңғайлы аялдама.'),

        ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 'en', 'Park of 28 Panfilov Guardsmen and Ascension Cathedral', 'A compact historic walk in central Almaty combining shaded alleys, memorial architecture, the wooden Ascension Cathedral and nearby museums. It is one of the easiest places to connect city history, photography and a relaxed stroll.'),
        ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 'ru', 'Парк 28 панфиловцев и Вознесенский собор', 'Компактный исторический маршрут в центре Алматы: тенистые аллеи, мемориальная архитектура, деревянный Вознесенский собор и музеи рядом. Это одно из самых удобных мест, чтобы совместить историю города, фото и спокойную прогулку.'),
        ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 'kk', '28 панфиловшылар паркі және Вознесенск соборы', 'Алматы орталығындағы ықшам тарихи серуен: көлеңкелі аллеялар, мемориалдық сәулет, ағаш Вознесенск соборы және жақын маңдағы музейлер. Қала тарихын, фотосуретті және жайлы жүрісті біріктіретін орын.'),

        ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 'en', 'Central Park Almaty', 'Almaty urban leisure in one place: rides, boating, lake paths, food points and family activities. It works well for users looking for an easy afternoon plan without leaving the city center.'),
        ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 'ru', 'Центральный парк Алматы', 'Городской отдых Алматы в одном месте: аттракционы, лодки, дорожки у озера, точки с едой и семейные активности. Хорошо подходит для простого дневного плана без выезда из центра города.'),
        ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 'kk', 'Алматы орталық паркі', 'Алматыдағы қалалық демалыс орны: аттракциондар, қайық, көл жағасындағы жолдар, тамақтану орындары және отбасылық белсенділіктер. Қала ортасынан шықпай түстен кейінгі жоспарға ыңғайлы.'),

        ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 'en', 'Fantasy World Almaty', 'A city amusement park near the circus district, useful for families, teenagers and short playful breaks between cultural stops. It adds a lighter entertainment option to Almaty itineraries.'),
        ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 'ru', 'Fantasy World Алматы', 'Городской парк аттракционов рядом с районом цирка, удобный для семей, подростков и короткой развлекательной паузы между культурными точками. Добавляет в маршрут по Алматы легкий формат отдыха.'),
        ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 'kk', 'Fantasy World Алматы', 'Цирк маңындағы қалалық аттракциондар паркі, отбасыларға, жасөспірімдерге және мәдени аялдамалар арасындағы қысқа көңілді үзіліске қолайлы. Алматы маршрутына жеңіл ойын-сауық қосады.'),

        ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 'en', 'Almaty Zoo', 'A long-running city zoo close to Central Park, good for families and slow educational walks. It is useful as a practical must-visit option when users travel with children or need a half-day urban plan.'),
        ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 'ru', 'Алматинский зоопарк', 'Городской зоопарк рядом с Центральным парком, подходящий для семей и спокойной познавательной прогулки. Практичная must-visit точка для поездки с детьми или половины дня в городе.'),
        ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 'kk', 'Алматы хайуанаттар бағы', 'Орталық паркке жақын орналасқан қалалық зообақ, отбасылық және танымдық серуенге ыңғайлы. Балалармен саяхатта немесе қала ішіндегі жарты күндік жоспарға жақсы must-visit нүкте.'),

        ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 'en', 'Green Bazaar', 'A historic Almaty market for spices, dried fruit, local sweets, produce and everyday city rhythm. It is one of the best low-friction ways to taste the city and buy edible souvenirs.'),
        ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 'ru', 'Зеленый базар', 'Исторический рынок Алматы со специями, сухофруктами, местными сладостями, продуктами и живым городским ритмом. Один из самых простых способов попробовать город и купить съедобные сувениры.'),
        ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 'kk', 'Көк базар', 'Дәмдеуіштер, кепкен жемістер, жергілікті тәттілер, өнімдер және қаланың күнделікті ырғағы сезілетін Алматының тарихи базары. Қаланы дәм арқылы тануға және жеуге болатын сыйлық алуға ыңғайлы.'),

        ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 'en', 'Barakholka Market', 'A large open-air and warehouse-style shopping district known for bargain hunting, practical goods and local trade culture. It is not polished tourism, but it gives a real Almaty market layer for curious travelers.'),
        ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 'ru', 'Барахолка Алматы', 'Большой торговый район с открытыми и складскими рядами, известный поиском выгодных покупок, практичными товарами и местной торговой культурой. Это не глянцевый туризм, но очень живой слой Алматы для любопытных путешественников.'),
        ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 'kk', 'Алматы барахолкасы', 'Ашық және қойма қатарлары бар үлкен сауда ауданы, тиімді саудамен, күнделікті тауарлармен және жергілікті нарық мәдениетімен белгілі. Жылтыр туризм емес, бірақ Алматының шынайы қабатын көрсетеді.'),

        ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, 'en', 'First President Park', 'One of Almaty largest landscaped parks, with fountains, alleys, gardens and mountain views from the upper side. It is a good calm stop for families, walks and seasonal city events.'),
        ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, 'ru', 'Парк Первого Президента', 'Один из крупнейших благоустроенных парков Алматы с фонтанами, аллеями, садами и видами на горы с верхней части. Хорошая спокойная точка для семьи, прогулки и сезонных городских событий.'),
        ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, 'kk', 'Тұңғыш Президент паркі', 'Фонтандары, аллеялары, бақтары және жоғарғы бөлігінен тау көрінісі бар Алматыдағы ең үлкен көгалдандырылған парктердің бірі. Отбасылық серуенге және маусымдық қалалық шараларға қолайлы тыныш орын.'),

        ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 'en', 'Khan Shatyr', 'A landmark tent-shaped entertainment and shopping center on Astana main axis. It is useful for architecture, weather-proof leisure, restaurants and an easy stop after walking Nurzhol Boulevard.'),
        ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 'ru', 'Хан Шатыр', 'Знаковый торгово-развлекательный центр в форме шатра на главной оси Астаны. Удобен для архитектуры, отдыха в любую погоду, ресторанов и простой остановки после прогулки по бульвару Нуржол.'),
        ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 'kk', 'Хан Шатыр', 'Астананың басты осіндегі шатыр пішінді танымал сауда және ойын-сауық орталығы. Сәулет, ауа райына тәуелсіз демалыс, мейрамханалар және Нұржол бойымен серуеннен кейінгі аялдама үшін ыңғайлы.'),

        ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 'en', 'Nur Alem Future Energy Museum', 'The spherical EXPO-2017 pavilion turned into a multi-floor museum about future energy, science and the capital. It is a strong indoor place for families, tech-curious travelers and cold or windy days.'),
        ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 'ru', 'Музей энергии будущего Nur Alem', 'Сферический павильон EXPO-2017, превращенный в многоэтажный музей об энергии будущего, науке и столице. Сильная indoor-точка для семей, любителей технологий и холодной или ветреной погоды.'),
        ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 'kk', 'Nur Alem болашақ энергиясы музейі', 'EXPO-2017 сфералық павильоны болашақ энергиясы, ғылым және астана туралы көпқабатты музейге айналған. Отбасыларға, технологияға қызығатындарға және суық не желді күндерге жақсы жабық нысан.'),

        ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 'en', 'Astana Botanical Garden', 'A broad green pause on the left bank with walking paths, water features and seasonal plantings. It balances Astana monument-heavy routes with a calm outdoor stop.'),
        ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 'ru', 'Ботанический сад Астаны', 'Большая зеленая пауза на левом берегу с прогулочными дорожками, водой и сезонными посадками. Хорошо балансирует насыщенные монументами маршруты по Астане спокойной outdoor-точкой.'),
        ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 'kk', 'Астана ботаникалық бағы', 'Сол жағалаудағы серуен жолдары, су нысандары және маусымдық өсімдіктері бар үлкен жасыл кеңістік. Астананың монументті маршрутын тыныш ашық аспан астындағы аялдамамен теңестіреді.'),

        ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 'en', 'Hazrat Sultan Mosque', 'A major Astana spiritual and architectural landmark near Independence Square and the National Museum. Its scale, white exterior and interior halls make it a respectful cultural stop for visitors.'),
        ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 'ru', 'Мечеть Хазрет Султан', 'Крупная духовная и архитектурная достопримечательность Астаны рядом с площадью Независимости и Национальным музеем. Масштаб, белый фасад и внутренние залы делают ее важной культурной точкой.'),
        ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 'kk', 'Хазірет Сұлтан мешіті', 'Тәуелсіздік алаңы мен Ұлттық музейге жақын орналасқан Астананың ірі рухани және сәулеттік нысаны. Ауқымы, ақ қасбеті және ішкі залдары оны маңызды мәдени аялдама етеді.'),

        ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 'en', 'National Museum of Kazakhstan', 'A large museum by Independence Square covering archaeology, ethnography, state history, art and modern Kazakhstan. It is the best single indoor stop to understand the national context before touring the regions.'),
        ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 'ru', 'Национальный музей Казахстана', 'Крупный музей у площади Независимости: археология, этнография, история государства, искусство и современный Казахстан. Лучший единый indoor-старт, чтобы понять контекст страны перед поездками по регионам.'),
        ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 'kk', 'Қазақстан Ұлттық музейі', 'Тәуелсіздік алаңы жанындағы үлкен музей: археология, этнография, мемлекет тарихы, өнер және қазіргі Қазақстан. Өңірлерге сапар алдында ел контексін түсінуге ең қолайлы жабық аялдама.'),

        ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 'en', 'Astana Opera', 'A monumental opera and ballet theater that works both as an architectural stop and an evening culture plan. It is especially useful for premium city itineraries and date-night recommendations.'),
        ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 'ru', 'Astana Opera', 'Монументальный театр оперы и балета, который работает и как архитектурная точка, и как вечерний культурный план. Особенно полезен для премиальных городских маршрутов и вечерних рекомендаций.'),
        ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 'kk', 'Astana Opera', 'Сәулеттік нысан әрі кешкі мәдени жоспар ретінде жарайтын опера және балет театры. Премиум қала маршруттары мен кешкі ұсыныстар үшін әсіресе қолайлы.'),

        ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 'en', 'Shymkent Citadel', 'The reconstructed old city core of Shymkent and a clear anchor for Silk Road urban history. It pairs well with museums and nearby central walks for a compact city route.'),
        ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 'ru', 'Шымкентская цитадель', 'Реконструированное ядро старого Шымкента и понятная точка для истории городов Шелкового пути. Хорошо сочетается с музеями и прогулками по центру в компактном маршруте.'),
        ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 'kk', 'Шымкент цитаделі', 'Ескі Шымкенттің қайта жаңғыртылған өзегі және Жібек жолы қалалық тарихын түсіндіретін негізгі орын. Музейлермен және орталықтағы серуенмен жақсы үйлеседі.'),

        ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 'en', 'Shymkent Zoo', 'One of the city family anchors, with regional and exotic animals and an accessible format for children. It is a useful in-city alternative when users want recreation rather than a museum-heavy route.'),
        ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 'ru', 'Шымкентский зоопарк', 'Одна из семейных городских точек с региональными и экзотическими животными, удобная для детей. Хорошая альтернатива в городе, когда пользователю нужен отдых, а не только музеи.'),
        ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 'kk', 'Шымкент хайуанаттар бағы', 'Аймақтық және экзотикалық жануарлары бар, балаларға ыңғайлы қалалық отбасылық орындардың бірі. Музейден бөлек демалыс керек болғанда жақсы балама.'),

        ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 'en', 'Shymkent Dendropark', 'A large arboretum with rare trees, lake scenery and soft walking routes. It is the strongest green-space recommendation for Shymkent when users need a calm outdoor plan.'),
        ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 'ru', 'Дендропарк Шымкента', 'Большой дендропарк с редкими деревьями, озером и спокойными прогулочными маршрутами. Самая сильная зеленая рекомендация Шымкента для тихого outdoor-плана.'),
        ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 'kk', 'Шымкент дендропаркі', 'Сирек ағаштары, көлі және жайлы серуен бағыттары бар үлкен дендропарк. Шымкентте тыныш ашық ауадағы жоспар үшін ең мықты жасыл ұсыныс.'),

        ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 'en', 'Abay Park Shymkent', 'A central Shymkent park with memorials, museums nearby and a calm walking rhythm. It works as a simple connector between culture, history and everyday city life.'),
        ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 'ru', 'Парк Абая в Шымкенте', 'Центральный парк Шымкента с мемориалами, музеями рядом и спокойным прогулочным ритмом. Работает как простой мост между культурой, историей и повседневной городской жизнью.'),
        ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 'kk', 'Шымкенттегі Абай паркі', 'Мемориалдары, жақын музейлері және тыныш серуен ырғағы бар Шымкенттің орталық паркі. Мәдениет, тарих және күнделікті қала өмірін байланыстыратын жеңіл маршрут.'),

        ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 'en', 'Ken Baba Ethno Park', 'A compact family-friendly urban park with oriental-style details, cafes and child-friendly leisure. It gives Shymkent routes a lighter local recreation stop.'),
        ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 'ru', 'Этнопарк Кен Баба', 'Компактный семейный городской парк с восточными деталями, кафе и детским досугом. Добавляет маршрутам по Шымкенту легкую локальную точку отдыха.'),
        ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 'kk', 'Кен Баба этнопаркі', 'Шығыс стиліндегі бөлшектері, кафелері және балаларға ыңғайлы демалысы бар шағын отбасылық қалалық парк. Шымкент маршрутына жеңіл жергілікті демалыс қосады.'),

        ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 'en', 'Karavansaray Turkistan', 'A multifunctional tourist complex near the Yasawi mausoleum, styled as a Silk Road settlement with waterways, shopping, restaurants, shows and a flying theater. It is the strongest modern family place in Turkistan.'),
        ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 'ru', 'Каравансарай Туркестан', 'Многофункциональный туристический комплекс рядом с мавзолеем Ясави, оформленный как город Шелкового пути: каналы, шопинг, рестораны, шоу и летающий театр. Самая сильная современная семейная точка Туркестана.'),
        ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 'kk', 'Түркістандағы Керуен-сарай', 'Ясауи кесенесі жанындағы Жібек жолы қаласы стиліндегі туристік кешен: су арналары, сауда, мейрамханалар, шоу және ұшатын театр. Түркістандағы ең мықты заманауи отбасылық нысан.'),

        ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 'en', 'Azret Sultan Museum-Reserve', 'The core museum-reserve around Turkistan sacred heritage, connecting the Yasawi complex with surrounding historical objects. It helps users see Turkistan as more than one monument.'),
        ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 'ru', 'Музей-заповедник Азрет Султан', 'Ключевой музей-заповедник сакрального наследия Туркестана, связывающий комплекс Ясави с окружающими историческими объектами. Помогает увидеть Туркестан не как один памятник, а как целую среду.'),
        ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 'kk', 'Әзірет Сұлтан музей-қорығы', 'Түркістанның киелі мұрасын қамтитын негізгі музей-қорық, Ясауи кешенін айналасындағы тарихи нысандармен байланыстырады. Түркістанды бір ғана ескерткіш емес, тұтас орта ретінде көруге көмектеседі.'),

        ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 'en', 'Otrar Ancient Settlement', 'A major Silk Road archaeological site near Turkistan, associated with medieval trade, scholarship and city life. It is a strong half-day extension for travelers who want more depth after the Yasawi complex.'),
        ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 'ru', 'Городище Отрар', 'Крупный археологический объект Шелкового пути рядом с Туркестаном, связанный со средневековой торговлей, наукой и городской жизнью. Сильное продолжение на полдня после комплекса Ясави.'),
        ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 'kk', 'Отырар қалашығы', 'Түркістан маңындағы ортағасырлық сауда, ғылым және қала өмірімен байланысты ірі Жібек жолы археологиялық нысаны. Ясауи кешенінен кейін жарты күндік терең маршрутқа жақсы.'),

        ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 'en', 'KarLag Museum', 'A memorial museum in Dolinka near Karaganda, set in the former administrative center of one of the largest Soviet labor camps. It is essential for serious historical tourism and remembrance.'),
        ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 'ru', 'Музей КарЛаг', 'Мемориальный музей в Долинке рядом с Карагандой, расположенный в бывшем административном центре одного из крупнейших советских лагерей. Важная точка для серьезного исторического туризма и памяти.'),
        ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 'kk', 'КарЛаг музейі', 'Қарағанды маңындағы Долинкада орналасқан, ірі кеңестік еңбек лагерлерінің бұрынғы әкімшілік орталығындағы мемориалдық музей. Терең тарихи туризм мен еске алу үшін маңызды орын.'),

        ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 'en', 'Central Park Karaganda', 'A practical green stop in Karaganda with lake walks, seasonal leisure and family recreation. It balances the heavier historical route to KarLag with an easy city pause.'),
        ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 'ru', 'Центральный парк Караганды', 'Практичная зеленая точка Караганды с прогулками у воды, сезонным досугом и семейным отдыхом. Балансирует более тяжелый исторический маршрут в КарЛаг простой городской паузой.'),
        ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 'kk', 'Қарағанды орталық паркі', 'Су жағасындағы серуен, маусымдық демалыс және отбасылық уақытқа арналған Қарағандыдағы жасыл орын. КарЛагқа ауыр тарихи бағытты жеңіл қала үзілісімен теңестіреді.'),

        ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 'en', 'Atyrau Bridges and Embankment', 'A signature Atyrau walk along the Ural River, where bridges visually connect the two banks and the city identity of Europe and Asia. Evening lighting makes it especially strong for short city recommendations.'),
        ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 'ru', 'Мосты и набережная Атырау', 'Фирменная прогулка Атырау вдоль Урала, где мосты визуально соединяют два берега и городскую идею Европы и Азии. Вечерняя подсветка делает маршрут особенно удачным для короткой рекомендации.'),
        ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 'kk', 'Атырау көпірлері мен жағалауы', 'Жайық бойындағы Атыраудың негізгі серуені, мұнда көпірлер екі жағалауды және Еуропа мен Азия идеясын байланыстырады. Кешкі жарық қысқа қала ұсынысы үшін өте әсерлі.'),

        ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, 'en', 'Aktau Rocky Trail', 'A scenic walking route between Caspian shoreline and rock formations, strong for sunset, photos and a quick sense of Aktau coastal character. It is one of the most memorable in-city outdoor stops.'),
        ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, 'ru', 'Скальная тропа Актау', 'Живописный пешеходный маршрут между каспийским берегом и скальными формами, сильный для заката, фото и быстрого ощущения прибрежного характера Актау. Одна из самых запоминающихся outdoor-точек города.'),
        ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, 'kk', 'Ақтаудың жартас соқпағы', 'Каспий жағалауы мен жартас бедері арасындағы көркем жаяу маршрут, күн батуы, фотосурет және Ақтаудың теңіздік мінезін сезіну үшін қолайлы. Қаладағы ең есте қаларлық ашық нүктелердің бірі.'),

        ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 'en', 'Aktau Seafront Promenade', 'An easy Caspian city walk with sea air, open horizons, cafes nearby and sunset views. It is the simplest recommendation for users who are already in Aktau and want a low-effort plan.'),
        ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 'ru', 'Приморская набережная Актау', 'Простая каспийская прогулка с морским воздухом, открытым горизонтом, кафе поблизости и видами на закат. Самая легкая рекомендация для пользователя, который уже находится в Актау.'),
        ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 'kk', 'Ақтаудың теңіз жағалауы', 'Теңіз ауасы, ашық көкжиек, жақын кафелер және күн батуы бар қарапайым Каспий серуені. Ақтауда жүрген пайдаланушыға ең жеңіл ұсыныс.'),

        ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 'en', 'Mashkhur Jusup Kopeyev Mosque', 'A central Pavlodar landmark and one of the region most recognizable religious buildings, with a distinctive blue dome and national architectural motifs. It works as a short respectful cultural stop.'),
        ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 'ru', 'Мечеть Машхур Жусупа Копеева', 'Центральная достопримечательность Павлодара и одно из самых узнаваемых религиозных зданий региона с ярким голубым куполом и национальными мотивами. Подходит для короткой уважительной культурной остановки.'),
        ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 'kk', 'Мәшһүр Жүсіп Көпеев мешіті', 'Павлодардың орталық нысаны және көк күмбезі мен ұлттық сәулет сарындары бар өңірдегі ең танымал діни ғимараттардың бірі. Қысқа әрі құрметті мәдени аялдамаға қолайлы.'),

        ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 'en', 'East Kazakhstan Ethnographic Museum-Reserve', 'A museum-reserve in Ust-Kamenogorsk with indoor exhibitions and open-air cultural spaces, including ethnographic displays and family-friendly areas. It is a strong all-weather city anchor.'),
        ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 'ru', 'Восточно-Казахстанский этнографический музей-заповедник', 'Музей-заповедник в Усть-Каменогорске с экспозициями в зданиях и открытыми культурными пространствами, этнографическими площадками и семейными зонами. Сильная городская точка на любую погоду.'),
        ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 'kk', 'Шығыс Қазақстан этнографиялық музей-қорығы', 'Өскемендегі ғимарат ішіндегі экспозициялары мен ашық мәдени кеңістіктері, этнографиялық алаңдары және отбасылық аймақтары бар музей-қорық. Кез келген ауа райына лайық қала нүктесі.'),

        ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 'en', 'Abai Museum-Reserve', 'A key Semey literary and cultural museum connected with Abai, his legacy and the intellectual history of the region. It is the natural first stop for travelers exploring Abay region.'),
        ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 'ru', 'Музей-заповедник Абая', 'Ключевой литературно-культурный музей Семея, связанный с Абаем, его наследием и интеллектуальной историей региона. Естественная первая точка для знакомства с областью Абай.'),
        ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 'kk', 'Абай музей-қорығы', 'Семейдегі Абаймен, оның мұрасымен және өңірдің рухани тарихымен байланысты негізгі әдеби-мәдени музей. Абай облысын тануды бастауға табиғи бірінші аялдама.'),

        ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 'en', 'Korkyt Ata Memorial', 'A cultural memorial near Kyzylorda dedicated to the poet and composer Korkyt Ata, with a wind organ that evokes the sound of kobyz. It is a distinctive stop for music, steppe mythology and Syr Darya routes.'),
        ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 'ru', 'Мемориальный комплекс Коркыт Ата', 'Культурный мемориал рядом с Кызылордой, посвященный поэту и композитору Коркыт Ата, с ветровым органом, напоминающим звук кобыза. Самобытная точка для музыки, степной мифологии и маршрутов по Сырдарье.'),
        ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 'kk', 'Қорқыт Ата мемориалы', 'Қызылорда маңындағы ақын және күйші Қорқыт Атаға арналған, қобыз үнін еске салатын жел органы бар мәдени мемориал. Музыка, дала мифологиясы және Сырдария бағыттары үшін ерекше орын.'),

        ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 'en', 'Nur Gasyr Mosque', 'The central mosque of Aktobe and a major architectural landmark with four tall minarets and a large gilded dome. It is a clear short must-visit for users exploring the city core.'),
        ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 'ru', 'Мечеть Нур Гасыр', 'Центральная мечеть Актобе и крупная архитектурная доминанта с четырьмя высокими минаретами и большим позолоченным куполом. Понятная короткая must-visit точка в центре города.'),
        ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 'kk', 'Нұр Ғасыр мешіті', 'Ақтөбенің орталық мешіті, төрт биік мұнарасы және үлкен алтын күмбезі бар ірі сәулеттік белгі. Қала ортасын аралаған пайдаланушыға қысқа must-visit нүкте.'),

        ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 'en', 'Kostanay Regional Museum of Local History', 'A compact cultural start for Kostanay, with regional history, ethnography, archive photos and local heritage exhibits. It is useful for travelers who want context before walking the city.'),
        ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 'ru', 'Костанайский областной краеведческий музей', 'Компактный культурный старт по Костанаю: история региона, этнография, архивные фотографии и местное наследие. Полезен путешественникам, которым нужен контекст перед прогулкой по городу.'),
        ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 'kk', 'Қостанай облыстық тарихи-өлкетану музейі', 'Қостанаймен танысудың шағын мәдени басы: өңір тарихы, этнография, архив фотосуреттері және жергілікті мұра. Қаланы араламас бұрын контекст іздеген саяхатшыларға пайдалы.'),

        ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 'en', 'West Kazakhstan Museum of Local History', 'A historic museum in Oral with archaeology, art objects and exhibits across different periods of Kazakhstan history. Its long institutional history makes it a strong cultural anchor for West Kazakhstan routes.'),
        ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 'ru', 'Западно-Казахстанский краеведческий музей', 'Исторический музей в Уральске с археологией, предметами искусства и экспозициями разных эпох истории Казахстана. Долгая история учреждения делает его сильной культурной точкой Западного Казахстана.'),
        ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 'kk', 'Батыс Қазақстан тарихи-өлкетану музейі', 'Оралдағы археология, өнер нысандары және Қазақстан тарихының әр кезеңіне арналған экспозициялары бар тарихи музей. Ұзақ тарихы оны Батыс Қазақстан бағытының маңызды мәдени нүктесі етеді.'),

        ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 'en', 'Akmola Regional Museum of History and Local Lore', 'One of the oldest cultural institutions in Kazakhstan, located in Kokshetau and focused on Akmola regional history, archaeology, ethnography and nature. It gives Kokshetau a strong indoor cultural anchor.'),
        ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 'ru', 'Акмолинский областной историко-краеведческий музей', 'Один из старейших культурных институтов Казахстана в Кокшетау, посвященный истории, археологии, этнографии и природе Акмолинского региона. Дает Кокшетау сильную indoor-точку культуры.'),
        ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 'kk', 'Ақмола облыстық тарихи-өлкетану музейі', 'Көкшетауда орналасқан, Ақмола өңірінің тарихына, археологиясына, этнографиясына және табиғатына арналған Қазақстандағы көне мәдени мекемелердің бірі. Көкшетауға мықты жабық мәдени нүкте қосады.')
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
        ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 43.2327, 76.9762, 'https://www.openstreetmap.org/search?query=Kok%20Tobe%20Almaty'),
        ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 43.2583, 76.9542, 'https://www.openstreetmap.org/search?query=Park%20of%2028%20Panfilov%20Guardsmen%20Almaty'),
        ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 43.2566, 76.9731, 'https://www.openstreetmap.org/search?query=Central%20Park%20Almaty'),
        ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 43.2396, 76.9196, 'https://www.openstreetmap.org/search?query=Fantasy%20World%20Almaty'),
        ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 43.2593, 76.9735, 'https://www.openstreetmap.org/search?query=Almaty%20Zoo'),
        ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 43.2630, 76.9455, 'https://www.openstreetmap.org/search?query=Green%20Bazaar%20Almaty'),
        ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 43.3290, 76.9020, 'https://www.openstreetmap.org/search?query=Barakholka%20Market%20Almaty'),
        ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, 43.187184, 76.886580, 'https://visitalmaty.kz/en/first-presidents-park-3/'),
        ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 51.1320, 71.4036, 'https://www.openstreetmap.org/search?query=Khan%20Shatyr%20Astana'),
        ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 51.0900, 71.4144, 'https://qaztravel.kz/en/tourist-spots/nur-alem-museum-of-future-energy'),
        ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 51.1000, 71.4000, 'https://www.openstreetmap.org/search?query=Astana%20Botanical%20Garden'),
        ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 51.1244, 71.4705, 'https://qaztravel.kz/en/tourist-spots/hazrat-sultan-mosque'),
        ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 51.1183, 71.4693, 'https://www.openstreetmap.org/search?query=National%20Museum%20of%20Kazakhstan%20Astana'),
        ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 51.1280, 71.4280, 'https://www.openstreetmap.org/search?query=Astana%20Opera'),
        ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 42.3169, 69.5901, 'https://www.openstreetmap.org/search?query=Shymkent%20Citadel'),
        ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 42.3689, 69.6018, 'https://shymkent-zoo.kz/'),
        ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 42.3205, 69.5876, 'https://www.ontustik.com/destination/dendropark'),
        ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 42.3203, 69.5746, 'https://www.openstreetmap.org/search?query=Abay%20Park%20Shymkent'),
        ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 42.3152, 69.5958, 'https://www.openstreetmap.org/search?query=Ken%20Baba%20Park%20Shymkent'),
        ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 43.2991, 68.2732, 'https://qaztravel.kz/en/tourist-spots/karavansaray-tourist-complex'),
        ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 43.2977, 68.2710, 'https://www.openstreetmap.org/search?query=Azret%20Sultan%20Museum%20Reserve%20Turkistan'),
        ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 42.8516, 68.3021, 'https://www.openstreetmap.org/search?query=Otrar%20Ancient%20Settlement%20Kazakhstan'),
        ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 49.6743, 72.6804, 'https://visitqaraganda.kz/en/map/dostoprimechatelnosti/muzey-karlag/'),
        ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 49.8078, 73.0853, 'https://www.openstreetmap.org/search?query=Central%20Park%20Karaganda'),
        ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 47.1058, 51.9240, 'https://visitatyrau.kz/en/bridges-of-atyrau/'),
        ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, 43.6415, 51.1989, 'https://www.openstreetmap.org/search?query=Aktau%20Rocky%20Trail'),
        ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 43.6522, 51.1575, 'https://www.openstreetmap.org/search?query=Aktau%20Seafront%20Promenade'),
        ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 52.2872, 76.9674, 'https://qaztravel.kz/en/tourist-spots/mashkhur-jusup-kopeyev-mosque'),
        ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 49.9500, 82.6200, 'https://qaztravel.kz/kk/tourist-spots/ethnographic-museum-reserve-of-east-kazakhstan-province'),
        ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 50.4114, 80.2275, 'https://abai-museum.kz/'),
        ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 45.6945, 63.3212, 'https://qaztravel.kz/en/tourist-spots/korkyt-ata-memorial'),
        ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 50.2838, 57.1677, 'https://qaztravel.kz/en/tourist-spots/nur-gasyr-regional-mosque'),
        ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 53.2144, 63.6245, 'https://culturemap.kz/en/object/kostanaiyskiiy-oblastnoiy-istoriko-kraevedcheskiiy-muzeiy'),
        ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 51.2240, 51.3671, 'https://qaztravel.kz/en/tourist-spots/west-kazakhstan-museum-of-local-history'),
        ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 53.2869, 69.3828, 'https://e-museum.kz/en/museum/68da379a95773a384-en/')
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

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    '2eeacb52-12ef-4499-b229-05e52a199d22',
    '6acdc04c-67b9-4e86-a43f-160738c3dda3',
    '3c070f18-a92c-4d5c-868c-dd4bda71ce95',
    '396f6629-a240-4845-8a5d-2fa33fc42b1b',
    '8a7b975e-9a4e-434e-a7e2-d721c41bda93',
    'ce5ca032-073b-4e4a-93d9-825a4e495574',
    'bc934181-e9d9-4daa-9909-5f87a3169159',
    '33192bba-1776-48e6-918b-198e81b17eae',
    '39759c2a-e2f1-4f2f-b354-d5c29f40fcc9',
    'abede8f2-87db-4f12-bc3e-64e815a1f97e',
    'a752e044-c458-4926-bdd1-76638b74b1c1',
    '1ede5116-b919-493e-9c58-b0027eb5f93b',
    '12e77265-9e9d-4d11-9c6d-acb8aac48f4b',
    'adece1ed-0d63-48e5-b54e-d49cad52a391',
    '9ed105cc-3f78-437a-ad1b-137422f3c8e6',
    '92f6c2cc-1b44-4900-a764-c1daab90024d',
    'd3951503-5e02-41ec-b886-dfc7cce1f925',
    'f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e',
    '0e06eed4-e871-4f78-919c-a11322eda453',
    'b8847588-a922-42cf-94a2-ffcbf043922a',
    '788b2836-0bbb-40bc-8a14-9548f47979ab',
    '877a0a46-da12-4f4c-be9c-a12a2032f93a',
    '1d3163c5-fa93-484f-b917-f721a8f1ae27',
    '09cdcef4-cb4d-4206-8a7a-2200270401ec',
    '1f32c9d1-d41d-4428-a853-fabe168aadef',
    '25f2452e-9943-463f-a135-27a72df7015d',
    '7344289b-c411-4ad5-ab27-268c06ef3cbb',
    'c7d8a58e-ee75-44cb-93f8-6f93f9a8a929',
    'b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60',
    '90742f2d-6b54-4676-930c-97bc59b60a64',
    '1ab18d1c-be18-4cfc-a5df-4494a4c12aed',
    'e895297e-6ecd-454e-89a5-88e341ccad4f',
    '0ce9cd13-dfc9-481b-821f-78ccaafb48bc',
    'eb123ce9-2da4-4b75-a0cd-d419699c166f',
    '3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'
)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
