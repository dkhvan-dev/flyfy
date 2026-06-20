-- Curated Da Nang places seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN and city_id is da-nang;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets, shows and opening conditions change by season/operator.

WITH seed_base (
    id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 'ENTERTAINMENT', 1, 'HOURS', 4.3, ARRAY['vietnam', 'da-nang', 'wonder-park', 'miniatures', 'family', 'photo', 'city']::text[]),
        ('3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 'ENTERTAINMENT', 4, 'HOURS', 4.5, ARRAY['vietnam', 'da-nang', 'mikazuki', 'water-park', 'onsen', 'family', 'japanese-style']::text[]),
        ('03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 'TEMPLE', 2, 'HOURS', 4.7, ARRAY['vietnam', 'da-nang', 'chua-linh-ung', 'son-tra', 'pagoda', 'buddhist', 'viewpoint']::text[]),
        ('9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 'MUSEUM', 2, 'HOURS', 4.4, ARRAY['vietnam', 'da-nang', '3d-museum', 'art-in-paradise', 'family', 'photo', 'indoor']::text[]),
        ('c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 'ENTERTAINMENT', 2, 'HOURS', 4.5, ARRAY['vietnam', 'da-nang', 'sun-wheel', 'asia-park', 'city-view', 'evening', 'family']::text[]),
        ('5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 'ARCHITECTURE', 1, 'HOURS', 4.7, ARRAY['vietnam', 'da-nang', 'dragon-bridge', 'han-river', 'bridge', 'night', 'architecture']::text[]),
        ('df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['vietnam', 'da-nang', 'vincom-plaza', 'shopping-mall', 'cinema', 'food', 'rainy-day']::text[]),
        ('c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 'SHOPPING', 1, 'HOURS', 4.3, ARRAY['vietnam', 'da-nang', 'go-hypermarket', 'shopping', 'supermarket', 'essentials', 'family']::text[]),
        ('c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['vietnam', 'da-nang', 'lotte-mart', 'shopping', 'supermarket', 'food-court', 'souvenirs']::text[]),
        ('072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 'MARKET', 2, 'HOURS', 4.5, ARRAY['vietnam', 'da-nang', 'han-market', 'market', 'local-food', 'souvenirs', 'central']::text[]),
        ('58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 'MARKET', 2, 'HOURS', 4.5, ARRAY['vietnam', 'da-nang', 'con-market', 'market', 'street-food', 'local-life', 'shopping']::text[]),
        ('aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 'MARKET', 2, 'HOURS', 4.5, ARRAY['vietnam', 'da-nang', 'helio-night-market', 'night-market', 'street-food', 'evening', 'family']::text[]),
        ('262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 'MARKET', 1, 'HOURS', 4.4, ARRAY['vietnam', 'da-nang', 'bac-my-an-market', 'market', 'local-food', 'breakfast', 'street-food']::text[])
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
    'da-nang',
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
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'ru', 'Ba Na Hills: Золотой мост', 'Пешеходный мост в комплексе Ba Na Hills рядом с Данангом, известный гигантскими каменными руками и видами на горы. Это фотогеничная точка внутри высокогорного парка, особенно при ясной погоде.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'en', 'Ba Na Hills Golden Bridge', 'A pedestrian bridge inside Ba Na Hills near Da Nang, known for giant stone hands and mountain views. It is a photogenic stop inside the highland park, especially in clear weather.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'kk', 'Ba Na Hills: Алтын көпір', 'Дананг маңындағы Ba Na Hills кешеніндегі алып тас қолдарымен және тау көріністерімен белгілі жаяу жүргінші көпірі. Ашық ауа райында биіктегі парк ішіндегі өте фотогенді аялдама.'),

        ('c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 'ru', 'Wonder Park Da Nang', 'Небольшая семейная зона у Danang Golden Bay с миниатюрными достопримечательностями, прогулочными точками и видами на северную часть города. Подходит для короткой фотопаузы или легкой остановки рядом с набережной.'),
        ('c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 'en', 'Wonder Park Da Nang', 'A small family-friendly zone near Danang Golden Bay with miniature landmarks, walking spots and views toward the northern part of the city. It works as a short photo stop or an easy pause near the waterfront.'),
        ('c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 'kk', 'Wonder Park Da Nang', 'Danang Golden Bay жанындағы миниатюралық көрікті жерлері, серуен аймақтары және қаланың солтүстік бөлігіне көрінісі бар шағын отбасылық аймақ. Қысқа фото аялдамаға немесе жағалау маңындағы жеңіл үзіліске қолайлы.'),

        ('3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 'ru', 'Mikazuki Water Park 365', 'Японский аквапарк и onsen-комплекс на побережье Дананга с бассейнами, горками, теплой водой и семейной инфраструктурой. Хорош для дождливого дня, отдыха с детьми или мягкой паузы между пляжами.'),
        ('3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 'en', 'Mikazuki Water Park 365', 'A Japanese-style water park and onsen complex on the Da Nang coast with pools, slides, warm water and family infrastructure. It is useful for a rainy day, time with children or a relaxed break between beaches.'),
        ('3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 'kk', 'Mikazuki Water Park 365', 'Дананг жағалауындағы бассейндері, сырғанақтары, жылы суы және отбасылық инфрақұрылымы бар жапон стиліндегі аквапарк пен onsen кешені. Жаңбырлы күнге, балалармен демалуға немесе жағажайлар арасындағы тыныш үзіліске ыңғайлы.'),

        ('03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 'ru', 'Chùa Linh Ứng', 'Буддийская пагода на полуострове Сон Тра с большой статуей Quan Âm, видом на Дананг и спокойной территорией у моря. Маршрут лучше проходить уважительно, без спешки и с учетом храмового дресс-кода.'),
        ('03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 'en', 'Chùa Linh Ứng', 'A Buddhist pagoda on the Son Tra Peninsula with a large Quan Am statue, views over Da Nang and a calm seaside setting. The route is best done respectfully, without rushing and with temple dress etiquette in mind.'),
        ('03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 'kk', 'Chùa Linh Ứng', 'Сон Тра түбегіндегі үлкен Quan Âm мүсіні, Дананг көрінісі және теңіз жанындағы тыныш аумағы бар будда пагодасы. Маршрутты құрметпен, асықпай және храмға сай киім ережесін ескеріп өткен дұрыс.'),

        ('9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 'ru', 'Art in Paradise Danang 3D Museum', 'Интерактивный 3D-музей с иллюзионными залами, где фотографии становятся частью экспозиции. Удобен для семей, компаний и дождливой погоды, когда хочется легкой indoor-активности.'),
        ('9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 'en', 'Art in Paradise Danang 3D Museum', 'An interactive 3D museum with illusion rooms where photos become part of the exhibition. It is convenient for families, groups and rainy weather when travelers want an easy indoor activity.'),
        ('9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 'kk', 'Art in Paradise Danang 3D Museum', 'Фотолар экспозицияның бір бөлігіне айналатын иллюзиялық залдары бар интерактивті 3D музей. Отбасыларға, достар тобына және жаңбырлы күндегі жеңіл indoor-белсенділікке ыңғайлы.'),

        ('c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 'ru', 'Sun Wheel', 'Большое колесо обозрения в Asia Park, откуда открываются виды на реку Хан, мосты и вечерний Дананг. Его удобно совмещать с прогулкой по парку, Helio Night Market или ужином рядом.'),
        ('c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 'en', 'Sun Wheel', 'A large observation wheel in Asia Park with views over the Han River, bridges and evening Da Nang. It pairs well with a park walk, Helio Night Market or dinner nearby.'),
        ('c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 'kk', 'Sun Wheel', 'Asia Park ішіндегі Хан өзені, көпірлер және кешкі Дананг көрінетін үлкен шолу дөңгелегі. Оны парк серуенімен, Helio Night Market немесе жақындағы кешкі аспен біріктіруге болады.'),

        ('5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 'ru', 'Dragon Bridge', 'Современный мост через реку Хан и один из главных символов Дананга. Днем он хорош для городских фото, а вечером особенно интересен благодаря подсветке и шоу огня и воды по расписанию.'),
        ('5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 'en', 'Dragon Bridge', 'A modern bridge across the Han River and one of Da Nangs main symbols. By day it is good for city photos, while in the evening it is known for lighting and scheduled fire-and-water shows.'),
        ('5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 'kk', 'Dragon Bridge', 'Хан өзені арқылы өтетін заманауи көпір және Данангтың негізгі символдарының бірі. Күндіз қала фотоларына жақсы, ал кешке жарығы және кесте бойынша өтетін от пен су шоуымен танымал.'),

        ('df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 'ru', 'Vincom Plaza Da Nang', 'Городской торговый центр рядом с рекой Хан с магазинами, кафе, развлечениями и удобной паузой от жары. Подходит как практичная остановка для покупок, кино или семейного досуга.'),
        ('df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 'en', 'Vincom Plaza Da Nang', 'A city shopping mall near the Han River with stores, cafes, entertainment and an easy break from the heat. It works as a practical stop for shopping, cinema or family time.'),
        ('df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 'kk', 'Vincom Plaza Da Nang', 'Хан өзені жанындағы дүкендері, кафелері, ойын-сауығы және ыстықтан демалуға ыңғайлы қалалық сауда орталығы. Саудаға, киноға немесе отбасылық уақытқа практикалық аялдама.'),

        ('c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 'ru', 'GO! Da Nang', 'Крупный гипермаркет в центральной части Дананга для продуктов, воды, бытовых мелочей, одежды и базовых покупок перед поездками. Удобен для семей и путешественников, живущих в апартаментах.'),
        ('c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 'en', 'GO! Da Nang', 'A large hypermarket in central Da Nang for groceries, water, everyday essentials, clothes and basic trip supplies. It is convenient for families and travelers staying in apartments.'),
        ('c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 'kk', 'GO! Da Nang', 'Данангтың орталық бөлігіндегі азық-түлік, су, күнделікті керек-жарақ, киім және сапарға қажет негізгі заттар алуға арналған үлкен гипермаркет. Отбасыларға және апартаментте тұратын саяхатшыларға ыңғайлы.'),

        ('c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 'ru', 'Lotte Mart Da Nang', 'Популярный торговый центр и супермаркет в южной части Дананга с продуктами, сувенирами, бытовыми товарами и фудкортом. Удобная остановка перед пляжным днем или поездкой к югу города.'),
        ('c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 'en', 'Lotte Mart Da Nang', 'A popular shopping center and supermarket in southern Da Nang with groceries, souvenirs, household goods and a food court. It is a useful stop before a beach day or a route south of the city.'),
        ('c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 'kk', 'Lotte Mart Da Nang', 'Данангтың оңтүстігіндегі азық-түлік, кәдесый, тұрмыстық тауарлар және фудкорты бар танымал сауда орталығы мен супермаркет. Жағажай күніне немесе қаланың оңтүстігіне сапар алдында ыңғайлы аялдама.'),

        ('072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 'ru', 'Han Market', 'Центральный рынок Дананга у реки Хан с фруктами, кофе, специями, одеждой, сувенирами и местной атмосферой. Хорош для коротких покупок, знакомства с городским бытом и поиска подарков.'),
        ('072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 'en', 'Han Market', 'A central Da Nang market by the Han River with fruit, coffee, spices, clothes, souvenirs and local atmosphere. It is good for quick shopping, everyday city life and gift hunting.'),
        ('072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 'kk', 'Han Market', 'Хан өзені жанындағы жеміс, кофе, дәмдеуіш, киім, кәдесый және жергілікті атмосферасы бар Данангтың орталық базары. Жылдам саудаға, қала тұрмысымен танысуға және сыйлық іздеуге қолайлы.'),

        ('58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 'ru', 'Con Market', 'Один из самых живых рынков Дананга с локальной едой, товарами, небольшими лавками и плотным городским ритмом. Подходит тем, кто хочет попробовать повседневный Дананг без туристического глянца.'),
        ('58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 'en', 'Con Market', 'One of Da Nangs liveliest markets with local food, goods, small stalls and a dense urban rhythm. It suits travelers who want everyday Da Nang without a polished tourist layer.'),
        ('58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 'kk', 'Con Market', 'Жергілікті тағамы, тауарлары, шағын дүңгіршектері және тығыз қала ырғағы бар Данангтың ең қарбалас базарларының бірі. Туристік жылтырсыз күнделікті Данангты көргісі келетіндерге жақсы.'),

        ('aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 'ru', 'Helio Night Market', 'Вечерний рынок рядом с Asia Park с уличной едой, напитками, музыкой и неформальной атмосферой. Удобен для легкого ужина после Sun Wheel или прогулки по южной части города.'),
        ('aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 'en', 'Helio Night Market', 'An evening market near Asia Park with street food, drinks, music and a relaxed atmosphere. It is convenient for an easy dinner after the Sun Wheel or a walk in southern Da Nang.'),
        ('aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 'kk', 'Helio Night Market', 'Asia Park жанындағы street food, сусындар, музыка және еркін атмосферасы бар кешкі базар. Sun Wheel немесе Данангтың оңтүстік бөлігіндегі серуеннен кейін жеңіл кешкі асқа ыңғайлы.'),

        ('262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 'ru', 'Bac My An Market', 'Локальный рынок рядом с пляжными районами Дананга, известный недорогой едой, десертами, фруктами и повседневными покупками. Хорош для завтрака, перекуса или короткой остановки рядом с My Khe.'),
        ('262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 'en', 'Bac My An Market', 'A local market near Da Nangs beach districts, known for affordable food, desserts, fruit and everyday shopping. It is good for breakfast, a snack or a short stop near My Khe.'),
        ('262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 'kk', 'Bac My An Market', 'Данангтың жағажай аудандары жанындағы қолжетімді тағамы, десерттері, жемістері және күнделікті саудасы бар жергілікті базар. Таңғы асқа, жеңіл тіске басарға немесе My Khe маңындағы қысқа аялдамаға жақсы.')
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
        ('c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 16.09420000, 108.21190000, 'https://www.openstreetmap.org/search?query=Wonder%20Park%20Da%20Nang'),
        ('3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 16.09890000, 108.14570000, 'https://www.openstreetmap.org/search?query=Mikazuki%20Water%20Park%20365%20Da%20Nang'),
        ('03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 16.10060000, 108.27780000, 'https://www.openstreetmap.org/search?query=Chua%20Linh%20Ung%20Son%20Tra%20Da%20Nang'),
        ('9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 16.09330000, 108.24470000, 'https://www.openstreetmap.org/search?query=Art%20in%20Paradise%20Danang%203D%20Museum'),
        ('c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 16.03940000, 108.22750000, 'https://www.openstreetmap.org/search?query=Sun%20Wheel%20Da%20Nang'),
        ('5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 16.06110000, 108.22700000, 'https://www.openstreetmap.org/search?query=Dragon%20Bridge%20Da%20Nang'),
        ('df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 16.07380000, 108.22500000, 'https://www.openstreetmap.org/search?query=Vincom%20Plaza%20Da%20Nang'),
        ('c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 16.06670000, 108.21490000, 'https://www.openstreetmap.org/search?query=GO%20Da%20Nang%20hypermarket'),
        ('c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 16.03650000, 108.22730000, 'https://www.openstreetmap.org/search?query=Lotte%20Mart%20Da%20Nang'),
        ('072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 16.06820000, 108.22400000, 'https://www.openstreetmap.org/search?query=Han%20Market%20Da%20Nang'),
        ('58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 16.06820000, 108.21460000, 'https://www.openstreetmap.org/search?query=Con%20Market%20Da%20Nang'),
        ('aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 16.03900000, 108.22640000, 'https://www.openstreetmap.org/search?query=Helio%20Night%20Market%20Da%20Nang'),
        ('262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 16.04830000, 108.24410000, 'https://www.openstreetmap.org/search?query=Bac%20My%20An%20Market%20Da%20Nang')
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
        ('46000000-0000-4000-8000-000000000001'::uuid, 'c6e51c2f-97dc-4990-8795-a083ee0b265c'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20City%20Square.JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:Da_Nang_City_Square.JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000002'::uuid, '3cb82c60-2819-422b-997e-93fb23bfe6ce'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/My%20Khe%20Beach%20Da%20Nang.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:My_Khe_Beach_Da_Nang.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000003'::uuid, '03db0318-9e27-4262-bdb3-1f7204998d3a'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Son-Tra-Peninsula%20Da-Nang%20Vietnam%20Linh-Ung-Pagoda-01.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Son-Tra-Peninsula_Da-Nang_Vietnam_Linh-Ung-Pagoda-01.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000004'::uuid, '9346a24c-4be7-4e7c-95bc-b232b19c8b8c'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20City%20Square.JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:Da_Nang_City_Square.JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000005'::uuid, 'c4d8a4a5-6a97-4aa6-8855-fc538c75c870'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Sun%20World%20Asia%20Park%2C%20Da%20Nang%20%2849374305713%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Sun_World_Asia_Park,_Da_Nang_(49374305713).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000006'::uuid, '5841aaeb-c597-4b89-992d-26a844dd2054'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20Dragon%20Bridge.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Da_Nang_Dragon_Bridge.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000007'::uuid, 'df554637-6f18-49c8-b4b2-8fcedd82962b'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Jollibee%20Da%20Nang%20in%202015.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Jollibee_Da_Nang_in_2015.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000008'::uuid, 'c64903fe-b7ab-4812-9124-8ca7d67a2bfb'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Interior%20of%20Blue%20Ocean%20Market%2C%20Da%20Nang%2C%20Vietnam.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Interior_of_Blue_Ocean_Market,_Da_Nang,_Vietnam.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000009'::uuid, 'c9860c73-dfb2-41b2-87f4-01f92f8f3fb0'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Streetmarket%20Da%20Nang%20Vietnam.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Streetmarket_Da_Nang_Vietnam.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000010'::uuid, '072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Han%20Market%201.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Han_Market_1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000011'::uuid, '58b1ccbc-6671-4112-a6b4-551767360a11'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Con%20Market%201.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Con_Market_1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000012'::uuid, 'aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Market%20in%20Da%20Nang%20-%20panoramio.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Market_in_Da_Nang_-_panoramio.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('46000000-0000-4000-8000-000000000013'::uuid, '262204b6-09c5-4914-85cf-06a878cd8668'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Street%20market%20-%20Da%20Nang%2C%20Vietnam%20-%20DSC02400.JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:Street_market_-_Da_Nang,_Vietnam_-_DSC02400.JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
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
    'c6e51c2f-97dc-4990-8795-a083ee0b265c',
    '3cb82c60-2819-422b-997e-93fb23bfe6ce',
    '03db0318-9e27-4262-bdb3-1f7204998d3a',
    '9346a24c-4be7-4e7c-95bc-b232b19c8b8c',
    'c4d8a4a5-6a97-4aa6-8855-fc538c75c870',
    '5841aaeb-c597-4b89-992d-26a844dd2054',
    'df554637-6f18-49c8-b4b2-8fcedd82962b',
    'c64903fe-b7ab-4812-9124-8ca7d67a2bfb',
    'c9860c73-dfb2-41b2-87f4-01f92f8f3fb0',
    '072f60d2-ef0d-4eae-aa77-51ff1eee274f',
    '58b1ccbc-6671-4112-a6b4-551767360a11',
    'aa81bb79-cabb-477a-ac05-45b863d6df8e',
    '262204b6-09c5-4914-85cf-06a878cd8668'
)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
