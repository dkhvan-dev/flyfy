-- Curated Nha Trang places seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN and city_id is nha-trang;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets, shows and opening conditions change by season/operator;
-- - GO! Nha Trang keeps Big C Nha Trang in descriptions as a familiar legacy/search alias.

WITH seed_base (
    id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 'MARKET', 2, 'HOURS', 4.4, ARRAY['vietnam', 'nha-trang', 'night-market', 'shopping', 'souvenirs', 'street-food', 'evening']::text[]),
        ('4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['vietnam', 'nha-trang', 'vincom-plaza', 'shopping-mall', 'cinema', 'food', 'rainy-day']::text[]),
        ('24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 'SHOPPING', 1, 'HOURS', 4.3, ARRAY['vietnam', 'nha-trang', 'go-hypermarket', 'big-c', 'shopping', 'supermarket', 'essentials']::text[]),
        ('0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 'MARKET', 2, 'HOURS', 4.5, ARRAY['vietnam', 'nha-trang', 'cho-dam', 'dam-market', 'market', 'local-food', 'souvenirs']::text[]),
        ('07040179-73c0-400c-867a-9c97d70bc818'::uuid, 'SHOPPING', 2, 'HOURS', 4.3, ARRAY['vietnam', 'nha-trang', 'ab-central-square', 'shopping-mall', 'food', 'central', 'rainy-day']::text[]),
        ('cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 'SHOPPING', 1, 'HOURS', 4.4, ARRAY['vietnam', 'nha-trang', 'lotte-mart', 'shopping', 'supermarket', 'food-court', 'family']::text[]),
        ('2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['vietnam', 'nha-trang', 'gold-coast', 'shopping-mall', 'lotte-mart', 'food', 'central']::text[]),
        ('a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['vietnam', 'nha-trang', 'oceanographic-museum', 'museum', 'science', 'marine-life', 'indoor']::text[]),
        ('aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 'TEMPLE', 1, 'HOURS', 4.7, ARRAY['vietnam', 'nha-trang', 'long-son-pagoda', 'buddhist', 'temple', 'viewpoint', 'culture']::text[]),
        ('b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 'NATURE', 4, 'HOURS', 4.7, ARRAY['vietnam', 'nha-trang', 'ba-ho-waterfall', 'waterfall', 'trekking', 'nature', 'outdoor']::text[]),
        ('d2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 'BEACH', 3, 'HOURS', 4.6, ARRAY['vietnam', 'nha-trang', 'nha-trang-beach', 'beach', 'sea', 'promenade', 'family']::text[]),
        ('c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 'BEACH', 4, 'HOURS', 4.6, ARRAY['vietnam', 'nha-trang', 'doc-let-beach', 'beach', 'white-sand', 'relax', 'day-trip']::text[]),
        ('0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 'BEACH', 4, 'HOURS', 4.5, ARRAY['vietnam', 'nha-trang', 'bai-dai-beach', 'cam-ranh', 'beach', 'sea', 'day-trip']::text[])
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
    'nha-trang',
    seed_base.category,
    NULL::numeric,
    NULL::varchar(3),
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
        ('b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 'ru', 'Ночной рынок Нячанга', 'Вечерний рынок в туристическом центре Нячанга с сувенирами, одеждой, простыми подарками и уличной едой. Удобная точка для неспешной прогулки после пляжа и знакомства с вечерним ритмом города.'),
        ('b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 'en', 'Nha Trang Night Market', 'An evening market in the tourist center of Nha Trang with souvenirs, clothes, simple gifts and street food. It is a convenient relaxed walk after the beach and a quick way to feel the city at night.'),
        ('b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 'kk', 'Нячанг түнгі базары', 'Нячангтың туристік орталығындағы кәдесыйлар, киім, шағын сыйлықтар және көше тағамдары бар кешкі базар. Жағажайдан кейін жай серуендеуге және қаланың кешкі ырғағын сезуге ыңғайлы.'),

        ('4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 'ru', 'Vincom Plaza Нячанг', 'Городской торговый центр для покупок, кафе, кино и короткой паузы в жару или дождь. Хорошо подходит как практичная остановка рядом с центральными маршрутами Нячанга.'),
        ('4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 'en', 'Vincom Plaza Nha Trang', 'A city shopping mall for retail, cafes, cinema and a short break from heat or rain. It works well as a practical stop near central Nha Trang routes.'),
        ('4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 'kk', 'Vincom Plaza Нячанг', 'Сауда, кафе, кино және ыстықтан немесе жаңбырдан қысқа үзіліс жасауға арналған қалалық сауда орталығы. Нячанг орталығындағы маршруттарға жақын практикалық аялдама.'),

        ('24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 'ru', 'GO! Нячанг', 'Крупный гипермаркет Нячанга, который многие путешественники по привычке ищут как Big C Nha Trang. Подходит для покупки продуктов, пляжных мелочей, товаров на несколько дней и понятного indoor-маршрута.'),
        ('24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 'en', 'GO! Nha Trang', 'A large Nha Trang hypermarket that many travelers still search for as Big C Nha Trang. It is useful for groceries, beach essentials, supplies for several days and an easy indoor stop.'),
        ('24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 'kk', 'GO! Нячанг', 'Көп саяхатшы әлі де Big C Nha Trang деп іздейтін Нячангтағы үлкен гипермаркет. Азық-түлік, жағажайға қажет заттар және бірнеше күндік керек-жарақ алуға ыңғайлы indoor-аялдама.'),

        ('0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 'ru', 'Рынок Чо Дам', 'Главный центральный рынок Нячанга с морепродуктами, фруктами, специями, одеждой и сувенирами. Подходит для живого локального опыта, но лучше закладывать время на торг и плотный поток людей.'),
        ('0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 'en', 'Chợ Đầm Market', 'The main central market of Nha Trang with seafood, fruit, spices, clothes and souvenirs. It is a vivid local stop, best visited with time for bargaining and a busy crowd.'),
        ('0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 'kk', 'Чо Дам базары', 'Нячангтың теңіз өнімдері, жеміс, дәмдеуіштер, киім және кәдесыйлар сатылатын басты орталық базары. Жергілікті өмірді көруге жақсы, бірақ саудаласуға және адам көп болуына уақыт қалдырған дұрыс.'),

        ('07040179-73c0-400c-867a-9c97d70bc818'::uuid, 'ru', 'AB Central Square', 'Современный городской комплекс в центре Нячанга с магазинами, кафе и удобной локацией рядом с пляжной зоной. Хорош для короткой остановки, встречи или укрытия от жары между прогулками.'),
        ('07040179-73c0-400c-867a-9c97d70bc818'::uuid, 'en', 'AB Central Square', 'A modern city complex in central Nha Trang with shops, cafes and a convenient location near the beach area. It is useful for a short stop, meeting point or break from the heat between walks.'),
        ('07040179-73c0-400c-867a-9c97d70bc818'::uuid, 'kk', 'AB Central Square', 'Нячанг орталығындағы дүкендері, кафелері және жағажай аймағына жақын ыңғайлы орны бар заманауи қалалық кешен. Қысқа аялдамаға, кездесуге немесе серуен арасында ыстықтан демалуға қолайлы.'),

        ('cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 'ru', 'Lotte Mart Нячанг', 'Большой супермаркет и торговая точка для продуктов, готовой еды, бытовых товаров и покупок на дорогу. Хороший практичный вариант для семей, долгого проживания и дождливого дня.'),
        ('cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 'en', 'Lotte Mart Nha Trang', 'A large supermarket and shopping stop for groceries, prepared food, household goods and travel supplies. It is a practical choice for families, longer stays and rainy days.'),
        ('cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 'kk', 'Lotte Mart Нячанг', 'Азық-түлік, дайын тағам, тұрмыстық тауарлар және жолға керек заттар алуға арналған үлкен супермаркет әрі сауда нүктесі. Отбасыларға, ұзақ тұруға және жаңбырлы күнге практикалық таңдау.'),

        ('2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 'ru', 'Gold Coast Shopping Mall', 'Торговый комплекс в центральной части Нячанга с магазинами, кафе и супермаркетом. Удобен для покупок без долгого переезда и как нейтральная точка встречи перед прогулкой по центру.'),
        ('2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 'en', 'Gold Coast Shopping Mall', 'A shopping complex in central Nha Trang with stores, cafes and a supermarket. It is convenient for shopping without a long transfer and as a neutral meeting point before a city walk.'),
        ('2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 'kk', 'Gold Coast Shopping Mall', 'Нячанг орталығындағы дүкендері, кафелері және супермаркеті бар сауда кешені. Ұзақ жолсыз сауда жасауға және қала серуені алдындағы бейтарап кездесу нүктесіне ыңғайлы.'),

        ('a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 'ru', 'Национальный океанографический музей', 'Музей при океанографическом институте Нячанга с морскими коллекциями, аквариумами, скелетами крупных животных и научным контекстом побережья. Хороший indoor-маршрут для семей и любителей природы.'),
        ('a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 'en', 'National Oceanographic Museum', 'A museum at the Nha Trang oceanographic institute with marine collections, aquariums, large animal skeletons and scientific context for the coast. It is a strong indoor route for families and nature-minded travelers.'),
        ('a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 'kk', 'Ұлттық океанография музейі', 'Нячанг океанография институтындағы теңіз коллекциялары, аквариумдар, ірі жануарлар қаңқалары және жағалау туралы ғылыми контексті бар музей. Отбасыларға және табиғатты ұнататындарға жақсы indoor-маршрут.'),

        ('aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 'ru', 'Пагода Лонг Сон', 'Буддийская пагода Нячанга, известная белой статуей Будды на холме и панорамой города. Это спокойная культурная остановка, которую удобно совместить с историческими и городскими маршрутами.'),
        ('aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 'en', 'Long Sơn Pagoda', 'A Buddhist pagoda in Nha Trang known for its white Buddha statue on the hill and city panorama. It is a calm cultural stop that fits well with historic and central city routes.'),
        ('aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 'kk', 'Лонг Сон пагодасы', 'Төбедегі ақ Будда мүсінімен және қала панорамасымен белгілі Нячангтағы буддистік пагода. Тарихи және орталық қала маршруттарына жақсы қосылатын тыныш мәдени аялдама.'),

        ('b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 'ru', 'Водопад Ба Хо', 'Природный маршрут к каскадам и природным чашам к северу от Нячанга. Подходит для активной поездки с треккингом, купанием и скалистыми участками, поэтому лучше учитывать погоду и обувь.'),
        ('b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 'en', 'Ba Ho Waterfall', 'A nature route to cascades and natural pools north of Nha Trang. It suits an active trip with trekking, swimming and rocky sections, so weather and footwear matter.'),
        ('b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 'kk', 'Ба Хо сарқырамасы', 'Нячангтың солтүстігіндегі каскадтар мен табиғи су қоймаларына апаратын табиғи маршрут. Треккинг, шомылу және тасты учаскелері бар белсенді сапарға сай, сондықтан ауа райы мен аяқ киімді ескерген дұрыс.'),

        ('d2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 'ru', 'Пляж Нячанг', 'Главный городской пляж Нячанга вдоль набережной с видом на залив, кафе, отелями и удобной инфраструктурой. Подходит для первого пляжного дня, вечерней прогулки и маршрута без долгого трансфера.'),
        ('d2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 'en', 'Nha Trang Beach', 'The main city beach of Nha Trang along the promenade, with bay views, cafes, hotels and easy infrastructure. It fits a first beach day, evening walk and route without a long transfer.'),
        ('d2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 'kk', 'Нячанг жағажайы', 'Шығанақ көрінісі, кафелері, қонақүйлері және ыңғайлы инфрақұрылымы бар Нячангтың набережная бойындағы басты қалалық жағажайы. Алғашқы жағажай күніне, кешкі серуенге және ұзақ трансферсіз маршрутқа сай.'),

        ('c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 'ru', 'Пляж Док Лет', 'Пляж к северу от Нячанга, известный светлым песком, более спокойной атмосферой и форматом дневной поездки. Хорош для отдыха у моря, фото и смены обстановки после центрального пляжа.'),
        ('c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 'en', 'Dốc Lết Beach', 'A beach north of Nha Trang known for light sand, a calmer mood and a day-trip format. It works well for seaside rest, photos and a change of scenery after the central beach.'),
        ('c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 'kk', 'Док Лет жағажайы', 'Нячангтың солтүстігіндегі ашық құмы, тынышырақ атмосферасы және бір күндік сапар форматы бар жағажай. Теңіз жағасында демалуға, фотоға және орталық жағажайдан кейін көріністі өзгертуге жақсы.'),

        ('0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 'ru', 'Пляж Бай Дай', 'Протяженный пляж в районе Камрани южнее Нячанга с широким берегом, морским воздухом и курортной инфраструктурой. Подходит для спокойной дневной поездки, если хочется меньше городской плотности.'),
        ('0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 'en', 'Bãi Dài Beach', 'A long beach in the Cam Ranh area south of Nha Trang, with a wide shoreline, sea air and resort infrastructure. It is a calm day-trip option when travelers want less city density.'),
        ('0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 'kk', 'Бай Дай жағажайы', 'Нячангтың оңтүстігіндегі Камрань ауданындағы ұзын жағажай: кең жағалау, теңіз ауасы және курорттық инфрақұрылым бар. Қала тығыздығынан алысырақ тыныш бір күндік сапарға сай.')
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

WITH po_nagar_translations (
    place_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'ru', 'Тямские башни Понагар', 'Тямский храмовый комплекс рядом с Нячангом, посвященный богине Ян По Нагар. Компактная культурная остановка с краснокирпичными башнями, видом на реку и контекстом древней Чампы.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'en', 'Po Nagar Cham Towers', 'A Cham temple complex near Nha Trang dedicated to the goddess Yan Po Nagar. It is a compact cultural stop with red-brick towers, river views and context around ancient Champa.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'kk', 'Понагар Чам мұнаралары', 'Нячанг маңындағы Ян По Нагар құдайына арналған Чам храм кешені. Қызыл кірпіш мұнаралары, өзен көрінісі және ежелгі Чампа туралы контексті бар ықшам мәдени аялдама.')
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
    po_nagar_translations.place_id,
    po_nagar_translations.locale,
    po_nagar_translations.title,
    po_nagar_translations.description,
    NOW(),
    NOW()
FROM po_nagar_translations
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = po_nagar_translations.place_id
        AND a.source = 'IMPORT'
)
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
        ('b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 12.23760000, 109.19670000, 'https://www.openstreetmap.org/search?query=Nha%20Trang%20Night%20Market'),
        ('4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 12.24600000, 109.19420000, 'https://www.openstreetmap.org/search?query=Vincom%20Plaza%20Nha%20Trang'),
        ('24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 12.24540000, 109.19060000, 'https://www.openstreetmap.org/search?query=GO%20Nha%20Trang%20Big%20C'),
        ('0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 12.25460000, 109.19130000, 'https://www.openstreetmap.org/search?query=Cho%20Dam%20Market%20Nha%20Trang'),
        ('07040179-73c0-400c-867a-9c97d70bc818'::uuid, 12.23820000, 109.19620000, 'https://www.openstreetmap.org/search?query=AB%20Central%20Square%20Nha%20Trang'),
        ('cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 12.23570000, 109.18490000, 'https://www.openstreetmap.org/search?query=Lotte%20Mart%20Nha%20Trang'),
        ('2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 12.24950000, 109.19420000, 'https://www.openstreetmap.org/search?query=Gold%20Coast%20Shopping%20Mall%20Nha%20Trang'),
        ('a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 12.20770000, 109.21410000, 'https://www.openstreetmap.org/search?query=National%20Oceanographic%20Museum%20Nha%20Trang'),
        ('aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 12.25160000, 109.18080000, 'https://www.openstreetmap.org/search?query=Long%20Son%20Pagoda%20Nha%20Trang'),
        ('b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 12.38996000, 109.13803000, 'https://www.openstreetmap.org/search?query=Ba%20Ho%20Waterfall%20Nha%20Trang'),
        ('d2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 12.23880000, 109.19690000, 'https://www.openstreetmap.org/search?query=Nha%20Trang%20Beach'),
        ('c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 12.52960000, 109.23070000, 'https://www.openstreetmap.org/search?query=Doc%20Let%20Beach%20Nha%20Trang'),
        ('0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 12.08600000, 109.19600000, 'https://www.openstreetmap.org/search?query=Bai%20Dai%20Beach%20Cam%20Ranh%20Nha%20Trang')
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
        ('48000000-0000-4000-8000-000000000001'::uuid, 'b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Nha%20Trang%20night.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Nha_Trang_night.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000002'::uuid, '4257b4a9-5a58-4c6b-b0a6-70e5d5307618'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Nha%20Trang%20center.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Nha_Trang_center.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000003'::uuid, '24dced8d-8032-477f-abf6-9816d08701bc'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Nha%20Trang%20n%C4%83m%202013%20%28c%E1%BB%ADa%20h%C3%A0ng%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Nha_Trang_n%C4%83m_2013_(c%E1%BB%ADa_h%C3%A0ng).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000004'::uuid, '0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Dam%20Market%20Nha%20Trang%201.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Dam_Market_Nha_Trang_1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000005'::uuid, '07040179-73c0-400c-867a-9c97d70bc818'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/AB%20Central%20Square%2C%20l%E1%BB%99c%20th%E1%BB%8D%2C%20nha%20trang%2C%20kh%C3%A1nh%20h%C3%B2a.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:AB_Central_Square,_l%E1%BB%99c_th%E1%BB%8D,_nha_trang,_kh%C3%A1nh_h%C3%B2a.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000006'::uuid, 'cc3df3f7-e3c4-43c9-855e-9c98957d6f8d'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Baguettes%20in%20Lotte%20Mart.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Baguettes_in_Lotte_Mart.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000007'::uuid, '2065e87e-6cd2-4146-9d5b-64b67d8d39fb'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Gold%20Coast%20Nha%20Trang.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Gold_Coast_Nha_Trang.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000008'::uuid, 'a708528c-04c0-452f-ba7f-0729f576aa52'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BA%A3i%20d%C6%B0%C6%A1ng%20h%E1%BB%8Dc%20Nha%20Trang.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:H%E1%BA%A3i_d%C6%B0%C6%A1ng_h%E1%BB%8Dc_Nha_Trang.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000009'::uuid, 'aca1444b-ef1c-4795-8c6f-a454b285567c'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Nha%20Trang%2C%20Long%20Son%20pagoda.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Nha_Trang,_Long_Son_pagoda.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000010'::uuid, 'b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Su%E1%BB%91i%20Ba%20H%E1%BB%93%2025.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Su%E1%BB%91i_Ba_H%E1%BB%93_25.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000011'::uuid, 'd2a9f71a-f62c-4b94-b862-8f61955100e3'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Beach%20at%20Nha%20Trang%2C%20Vietnam.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Beach_at_Nha_Trang,_Vietnam.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000012'::uuid, 'c78fd68a-17e6-486a-9ac4-c2923a76127b'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Doc%20Let%20Beach.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Doc_Let_Beach.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('48000000-0000-4000-8000-000000000013'::uuid, '0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/DAI%20LO%20NGUYEN%20TAT%20THANH%2C%20BAI%20DAI%2C%20CAM%20LAM%20-%20panoramio.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:DAI_LO_NGUYEN_TAT_THANH,_BAI_DAI,_CAM_LAM_-_panoramio.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
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
    'b789d8ae-3f3f-41e3-88b2-e553cd978947',
    '4257b4a9-5a58-4c6b-b0a6-70e5d5307618',
    '24dced8d-8032-477f-abf6-9816d08701bc',
    '0425d348-b915-4c47-9dfe-a3edb8186be5',
    '07040179-73c0-400c-867a-9c97d70bc818',
    'cc3df3f7-e3c4-43c9-855e-9c98957d6f8d',
    '2065e87e-6cd2-4146-9d5b-64b67d8d39fb',
    'a708528c-04c0-452f-ba7f-0729f576aa52',
    'aca1444b-ef1c-4795-8c6f-a454b285567c',
    'b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08',
    'd2a9f71a-f62c-4b94-b862-8f61955100e3',
    'c78fd68a-17e6-486a-9ac4-c2923a76127b',
    '0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'
)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
