-- Curated Vietnam attractions seed.
-- Texts are original FlyFy editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons and Wikipedia for representative cover media and source pages.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN;
-- - city_id stores a practical departure/search hub inside Vietnam;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets and opening conditions change by season/operator.

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
        ('e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 'hanoi', 'PARK', 1, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'hoan-kiem-lake', 'lake', 'old-quarter', 'walk', 'city']::text[]),
        ('19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 'hanoi', 'TEMPLE', 2, 'HOURS', 4.8, ARRAY['vietnam', 'hanoi', 'temple-of-literature', 'confucius', 'history', 'culture', 'architecture']::text[]),
        ('e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 'hanoi', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['vietnam', 'hanoi', 'ethnology', 'museum', 'culture', 'indoor', 'families']::text[]),
        ('95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 'ha-long', 'NATURE', 6, 'HOURS', 4.9, ARRAY['vietnam', 'ha-long', 'bay', 'unesco', 'limestone', 'cruise', 'nature']::text[]),
        ('60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 'ninh-binh', 'NATURE', 4, 'HOURS', 4.8, ARRAY['vietnam', 'ninh-binh', 'trang-an', 'unesco', 'boat', 'caves', 'nature']::text[]),
        ('79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 'hue', 'ARCHITECTURE', 3, 'HOURS', 4.8, ARRAY['vietnam', 'hue', 'imperial-city', 'citadel', 'nguyen-dynasty', 'history', 'architecture']::text[]),
        ('ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 'da-nang', 'NATURE', 3, 'HOURS', 4.7, ARRAY['vietnam', 'da-nang', 'marble-mountains', 'caves', 'pagodas', 'viewpoint', 'nature']::text[]),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'da-nang', 'ARCHITECTURE', 2, 'HOURS', 4.7, ARRAY['vietnam', 'da-nang', 'golden-bridge', 'ba-na-hills', 'viewpoint', 'architecture', 'photo']::text[]),
        ('98791410-4cf9-444d-818d-463fc10728fa'::uuid, 'hoi-an', 'ARCHITECTURE', 3, 'HOURS', 4.9, ARRAY['vietnam', 'hoi-an', 'old-town', 'unesco', 'lanterns', 'heritage', 'architecture']::text[]),
        ('b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 'ho-chi-minh-city', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['vietnam', 'ho-chi-minh-city', 'war-remnants-museum', 'museum', 'history', 'indoor', 'culture']::text[]),
        ('8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 'ho-chi-minh-city', 'MARKET', 2, 'HOURS', 4.6, ARRAY['vietnam', 'ho-chi-minh-city', 'ben-thanh-market', 'market', 'food', 'shopping', 'city']::text[]),
        ('583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 'ho-chi-minh-city', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['vietnam', 'ho-chi-minh-city', 'independence-palace', 'history', 'architecture', 'museum', 'saigon']::text[]),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'nha-trang', 'TEMPLE', 1, 'HOURS', 4.6, ARRAY['vietnam', 'nha-trang', 'po-nagar', 'cham', 'temple', 'history', 'culture']::text[]),
        ('89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 'nha-trang', 'ENTERTAINMENT', 5, 'HOURS', 4.6, ARRAY['vietnam', 'nha-trang', 'vinwonders', 'theme-park', 'family', 'island', 'entertainment']::text[]),
        ('f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 'phu-quoc', 'NATURE', 5, 'HOURS', 4.7, ARRAY['vietnam', 'phu-quoc', 'national-park', 'island', 'forest', 'beach', 'nature']::text[]),
        ('54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 'sa-pa', 'NATURE', 5, 'HOURS', 4.8, ARRAY['vietnam', 'sa-pa', 'fansipan', 'mountain', 'cable-car', 'viewpoint', 'outdoor']::text[]),
        ('b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 'can-tho', 'MARKET', 3, 'HOURS', 4.6, ARRAY['vietnam', 'can-tho', 'cai-rang', 'floating-market', 'mekong', 'food', 'morning']::text[]),
        ('4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 'da-lat', 'ARCHITECTURE', 1, 'HOURS', 4.5, ARRAY['vietnam', 'da-lat', 'crazy-house', 'architecture', 'photo', 'creative', 'city']::text[])
)
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
    seed_base.id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'VN',
    seed_base.city_id,
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
WHERE attractions.source = 'IMPORT';

WITH seed_translations (
    attraction_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 'ru', 'Озеро Хоанкьем', 'Озеро в историческом центре Ханоя рядом со Старым кварталом, мостом Хук и башней Черепахи. Подходит для первой спокойной прогулки по городу, утренних фото и знакомства с повседневным ритмом столицы.'),
        ('e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 'en', 'Hoan Kiem Lake', 'A lake in the historic center of Hanoi beside the Old Quarter, The Huc Bridge and Turtle Tower. It is a natural first walk through the city, good for morning photos and feeling the daily rhythm of the capital.'),
        ('e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 'kk', 'Хоан Кием көлі', 'Ханойдың тарихи орталығындағы Ескі квартал, Хук көпірі және Тасбақа мұнарасы жанындағы көл. Қаланы алғашқы рет жай қарқынмен аралауға, таңғы фотоға және астананың күнделікті ырғағын сезуге қолайлы.'),

        ('19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 'ru', 'Храм литературы', 'Конфуцианский храмовый комплекс Ханоя и один из главных символов образования во Вьетнаме. Дворы, стелы докторов и спокойная архитектура дают понятный культурный маршрут без суеты Старого квартала.'),
        ('19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 'en', 'Temple of Literature', 'A Confucian temple complex in Hanoi and one of the main symbols of education in Vietnam. Its courtyards, doctor steles and calm architecture make a clear cultural route away from the Old Quarter rush.'),
        ('19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 'kk', 'Әдебиет ғибадатханасы', 'Ханойдағы конфуцийлік ғибадатхана кешені және Вьетнамдағы білімнің басты нышандарының бірі. Аулалары, докторлар стелалары және тыныш сәулеті Ескі квартал қарбаласынан тыс мәдени маршрут береді.'),

        ('e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 'ru', 'Музей этнологии Вьетнама', 'Музей в Ханое о 54 официально признанных этнических группах страны, с экспозициями, ремеслами и открытой зоной традиционных домов. Хороший indoor-маршрут для семей и путешественников, которым нужен культурный контекст.'),
        ('e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 'en', 'Vietnam Museum of Ethnology', 'A Hanoi museum about the 54 officially recognized ethnic groups of Vietnam, with exhibits, crafts and an outdoor area of traditional houses. It is a strong indoor route for families and travelers who want cultural context.'),
        ('e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 'kk', 'Вьетнам этнология музейі', 'Елдегі ресми танылған 54 этникалық топ туралы Ханой музейі: экспозициялар, қолөнер және дәстүрлі үйлердің ашық аймағы бар. Отбасыларға және мәдени контекст іздеген саяхатшыларға жақсы жабық маршрут.'),

        ('95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 'ru', 'Бухта Халонг', 'Знаменитая бухта северного Вьетнама с тысячами известняковых островков, круизами, гротами и панорамами воды. Это сильная природная точка для поездки из Ханоя или ночного маршрута у побережья.'),
        ('95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 'en', 'Ha Long Bay', 'A famous bay in northern Vietnam with thousands of limestone islets, cruises, grottoes and wide water views. It is a major nature stop for a trip from Hanoi or an overnight coastal route.'),
        ('95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 'kk', 'Халонг шығанағы', 'Солтүстік Вьетнамдағы мыңдаған әктас аралшалары, круиздері, үңгірлері және кең су көріністері бар әйгілі шығанақ. Ханойдан сапарға немесе жағалауда түнеуге арналған мықты табиғи бағыт.'),

        ('60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 'ru', 'Ландшафтный комплекс Чанган', 'Живописная зона Ниньбиня с лодочными маршрутами между карстовыми скалами, пещерами и храмами. Подходит для спокойного полудневного маршрута, где природа и культурные остановки идут вместе.'),
        ('60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 'en', 'Trang An Scenic Landscape Complex', 'A scenic area in Ninh Binh with boat routes between karst cliffs, caves and temples. It works well as a calm half-day route where nature and cultural stops sit together.'),
        ('60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 'kk', 'Чанган ландшафт кешені', 'Ниньбиньдегі карст жартастары, үңгірлер және храмдар арасындағы қайық маршруттары бар көрікті аймақ. Табиғат пен мәдени аялдамалар қатар жүретін тыныш жарты күндік бағытқа қолайлы.'),

        ('79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 'ru', 'Императорский город Хюэ', 'Крепостной дворцовый комплекс бывшей императорской столицы Вьетнама с воротами, павильонами, дворцами и садами. Это главная точка Хюэ для понимания династии Нгуен и истории центрального Вьетнама.'),
        ('79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 'en', 'Imperial City of Hue', 'A walled palace complex of the former imperial capital of Vietnam, with gates, pavilions, palaces and gardens. It is the main Hue stop for understanding the Nguyen dynasty and central Vietnamese history.'),
        ('79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 'kk', 'Хюэ императорлық қаласы', 'Вьетнамның бұрынғы императорлық астанасындағы қақпалары, павильондары, сарайлары және бақтары бар бекіністі сарай кешені. Нгуен әулеті мен орталық Вьетнам тарихын түсінуге арналған басты нүкте.'),

        ('ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 'ru', 'Мраморные горы', 'Группа мраморных и известняковых холмов к югу от Дананга с пещерами, пагодами, лестницами и смотровыми площадками. Хорошо подходит для активной короткой поездки, где есть и природа, и религиозные детали.'),
        ('ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 'en', 'Marble Mountains', 'A cluster of marble and limestone hills south of Da Nang with caves, pagodas, stairs and viewpoints. It is a good compact active route that combines nature with religious details.'),
        ('ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 'kk', 'Мрамор таулары', 'Данангтың оңтүстігіндегі үңгірлері, пагодалары, баспалдақтары және қарау алаңдары бар мәрмәр мен әктас төбелер тобы. Табиғат пен діни бөлшектерді біріктіретін қысқа белсенді маршрутқа ыңғайлы.'),

        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'ru', 'Золотой мост', 'Пешеходный мост в Ba Na Hills рядом с Данангом, известный гигантскими каменными руками и видами на горы. Это фотогеничная точка для поездки в парк на высоте, особенно при ясной погоде.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'en', 'Golden Bridge', 'A pedestrian bridge in Ba Na Hills near Da Nang, known for giant stone hands and mountain views. It is a photogenic stop inside the highland park, especially in clear weather.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'kk', 'Алтын көпір', 'Дананг маңындағы Ba Na Hills аймағындағы алып тас қолдарымен және тау көріністерімен белгілі жаяу жүргінші көпірі. Ашық ауа райында биіктегі парк ішіндегі өте фотогенді аялдама.'),

        ('98791410-4cf9-444d-818d-463fc10728fa'::uuid, 'ru', 'Старый город Хойан', 'Исторический торговый город с желтыми фасадами, фонарями, мостами, ремесленными лавками и вечерней атмосферой. Хорош для неспешной прогулки, еды, фото и маршрута без длинных переездов.'),
        ('98791410-4cf9-444d-818d-463fc10728fa'::uuid, 'en', 'Hoi An Ancient Town', 'A historic trading town with yellow facades, lanterns, bridges, craft shops and an evening atmosphere. It is ideal for a slow walk, food, photos and a route without long transfers.'),
        ('98791410-4cf9-444d-818d-463fc10728fa'::uuid, 'kk', 'Хойан ескі қаласы', 'Сары қасбеттері, шамдары, көпірлері, қолөнер дүкендері және кешкі атмосферасы бар тарихи сауда қаласы. Асықпай серуендеуге, тамаққа, фотоға және ұзақ жолсыз маршрутқа қолайлы.'),

        ('b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 'ru', 'Музей жертв войны', 'Музей в Хошимине с экспозициями о войнах в Индокитае и Вьетнамской войне. Маршрут эмоционально тяжелый, но важный для понимания истории страны и современного отношения к памяти.'),
        ('b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 'en', 'War Remnants Museum', 'A museum in Ho Chi Minh City with exhibits about the Indochina wars and the Vietnam War. The route can be emotionally heavy, but it is important for understanding national history and memory.'),
        ('b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 'kk', 'Соғыс құрбандары музейі', 'Хошиминдегі Үндіқытай соғыстары мен Вьетнам соғысы туралы экспозициялары бар музей. Маршрут эмоциялық тұрғыдан ауыр болуы мүмкін, бірақ ел тарихы мен жады мәдениетін түсінуге маңызды.'),

        ('8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 'ru', 'Рынок Бен Тхань', 'Один из самых известных рынков Хошимина в центре города: еда, сувениры, специи, ткани и вечерняя торговля. Удобная точка для короткого городского маршрута и знакомства с локальным ритмом.'),
        ('8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 'en', 'Ben Thanh Market', 'One of the best-known markets in central Ho Chi Minh City, with food, souvenirs, spices, fabrics and evening trade. It is a convenient short city stop for feeling the local rhythm.'),
        ('8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 'kk', 'Бен Тхань базары', 'Хошимин орталығындағы ең белгілі базарлардың бірі: тамақ, кәдесыйлар, дәмдеуіштер, маталар және кешкі сауда бар. Қаланың жергілікті ырғағын сезуге арналған қысқа әрі ыңғайлы аялдама.'),

        ('583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 'ru', 'Дворец независимости', 'Знаковое здание Хошимина, связанное с политической историей Южного Вьетнама и завершением войны в 1975 году. Внутри сохранились залы, кабинеты и подземные помещения, полезные для исторического маршрута.'),
        ('583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 'en', 'Independence Palace', 'A landmark building in Ho Chi Minh City connected with South Vietnamese political history and the end of the war in 1975. Its halls, offices and underground rooms make a useful historical route.'),
        ('583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 'kk', 'Тәуелсіздік сарайы', 'Оңтүстік Вьетнамның саяси тарихымен және 1975 жылғы соғыстың аяқталуымен байланысты Хошиминдегі маңызды ғимарат. Залдары, кабинеттері және жерасты бөлмелері тарихи маршрутқа пайдалы.'),

        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'ru', 'Башни По Нагар', 'Чамский храмовый комплекс рядом с Нячангом, посвященный богине Ян По Нагар. Компактная культурная остановка с краснокирпичными башнями, видом на реку и контекстом древней Чампы.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'en', 'Po Nagar Cham Towers', 'A Cham temple complex near Nha Trang dedicated to the goddess Yan Po Nagar. It is a compact cultural stop with red-brick towers, river views and context around ancient Champa.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'kk', 'По Нагар Чам мұнаралары', 'Нячанг маңындағы Ян По Нагар құдайына арналған Чам храм кешені. Қызыл кірпіш мұнаралары, өзен көрінісі және ежелгі Чампа туралы контексті бар ықшам мәдени аялдама.'),

        ('89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 'ru', 'VinWonders Нячанг', 'Крупный островной парк развлечений у Нячанга с аттракционами, водными зонами, шоу и семейной инфраструктурой. Подходит для полного дня, когда нужен легкий отдых без музейного темпа.'),
        ('89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 'en', 'VinWonders Nha Trang', 'A large island entertainment park near Nha Trang with rides, water areas, shows and family infrastructure. It fits a full-day plan when travelers want easier leisure rather than a museum pace.'),
        ('89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 'kk', 'VinWonders Нячанг', 'Нячанг маңындағы аттракциондары, су аймақтары, шоулары және отбасылық инфрақұрылымы бар үлкен аралдық ойын-сауық паркі. Музей қарқынынсыз жеңіл толық күндік демалысқа сай.'),

        ('f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 'ru', 'Национальный парк Фукуок', 'Природная территория на острове Фукуок с лесами, холмами, побережьем и маршрутами для спокойного outdoor-отдыха. Хорошо дополняет пляжный отдых и помогает увидеть остров не только как курорт.'),
        ('f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 'en', 'Phu Quoc National Park', 'A nature area on Phu Quoc Island with forests, hills, coastline and calm outdoor routes. It complements beach travel and helps visitors see the island beyond the resort format.'),
        ('f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 'kk', 'Фукуок ұлттық паркі', 'Фукуок аралындағы ормандары, төбелері, жағалауы және тыныш outdoor бағыттары бар табиғи аймақ. Жағажай демалысын толықтырып, аралды тек курорт ретінде емес көруге көмектеседі.'),

        ('54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 'ru', 'Фансипан', 'Самая высокая гора Вьетнама рядом с Сапой, известная как крыша Индокитая. Маршрут может быть активным походом или более мягкой поездкой с канатной дорогой и видами на горные хребты.'),
        ('54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 'en', 'Fansipan', 'The highest mountain in Vietnam near Sa Pa, known as the Roof of Indochina. The route can be an active hike or an easier cable-car trip with views across the mountain ranges.'),
        ('54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 'kk', 'Фансипан', 'Сапа маңындағы Вьетнамның ең биік тауы, Үндіқытайдың төбесі ретінде белгілі. Маршрут белсенді жорық немесе тау жоталарына көрінісі бар жеңілірек аспалы жол сапары болуы мүмкін.'),

        ('b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 'ru', 'Плавучий рынок Кай Ранг', 'Утренний рынок на воде рядом с Кантхо, где лодки продают фрукты, еду и товары прямо на реке. Это хороший маршрут по Меконгу для раннего старта, фото и живого локального опыта.'),
        ('b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 'en', 'Cai Rang Floating Market', 'A morning river market near Can Tho where boats sell fruit, food and goods directly on the water. It is a strong Mekong route for an early start, photos and a lived local experience.'),
        ('b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 'kk', 'Кай Ранг жүзбелі базары', 'Кантхо маңындағы таңғы өзен базары, мұнда қайықтар жеміс, тамақ және тауарларды тікелей суда сатады. Ерте бастауға, фотоға және тірі жергілікті тәжірибеге арналған жақсы Меконг бағыты.'),

        ('4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 'ru', 'Crazy House Далат', 'Необычный гостевой дом и арт-объект в Далате с органичными формами, мостиками, лестницами и сказочной архитектурой. Хорошая короткая остановка для фото и легкого городского маршрута.'),
        ('4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 'en', 'Crazy House Da Lat', 'An unusual guesthouse and art object in Da Lat with organic forms, bridges, stairways and fairy-tale architecture. It is a good short stop for photos and a light city route.'),
        ('4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 'kk', 'Далаттағы Crazy House', 'Далаттағы органикалық пішіндері, көпірлері, баспалдақтары және ертегідей сәулеті бар ерекше қонақ үй әрі арт-нысан. Фотоға және жеңіл қалалық маршрутқа арналған қысқа жақсы аялдама.')
)
INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed_translations.attraction_id,
    seed_translations.locale,
    seed_translations.title,
    seed_translations.description,
    NOW(),
    NOW()
FROM seed_translations
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
    VALUES
        ('e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 21.02888889, 105.85250000, 'https://www.openstreetmap.org/search?query=Hoan%20Kiem%20Lake%20Hanoi'),
        ('19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 21.02861111, 105.83555556, 'https://www.openstreetmap.org/search?query=Temple%20of%20Literature%20Hanoi'),
        ('e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 21.04060000, 105.79870000, 'https://www.openstreetmap.org/search?query=Vietnam%20Museum%20of%20Ethnology%20Hanoi'),
        ('95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 20.90000000, 107.20000000, 'https://www.openstreetmap.org/search?query=Ha%20Long%20Bay%20Vietnam'),
        ('60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 20.25666667, 105.89638889, 'https://www.openstreetmap.org/search?query=Trang%20An%20Scenic%20Landscape%20Complex'),
        ('79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 16.46972222, 107.57777778, 'https://www.openstreetmap.org/search?query=Imperial%20City%20of%20Hue'),
        ('ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 16.00000000, 108.26000000, 'https://www.openstreetmap.org/search?query=Marble%20Mountains%20Da%20Nang'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 15.99486000, 107.99625000, 'https://www.openstreetmap.org/search?query=Golden%20Bridge%20Ba%20Na%20Hills'),
        ('98791410-4cf9-444d-818d-463fc10728fa'::uuid, 15.87725000, 108.32640000, 'https://www.openstreetmap.org/search?query=Hoi%20An%20Ancient%20Town'),
        ('b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 10.77947500, 106.69213200, 'https://www.openstreetmap.org/search?query=War%20Remnants%20Museum%20Ho%20Chi%20Minh%20City'),
        ('8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 10.77252069, 106.69801918, 'https://www.openstreetmap.org/search?query=Ben%20Thanh%20Market%20Ho%20Chi%20Minh%20City'),
        ('583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 10.77694444, 106.69527778, 'https://www.openstreetmap.org/search?query=Independence%20Palace%20Ho%20Chi%20Minh%20City'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 12.26527778, 109.19555556, 'https://www.openstreetmap.org/search?query=Po%20Nagar%20Cham%20Towers%20Nha%20Trang'),
        ('89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 12.21670000, 109.24240000, 'https://www.openstreetmap.org/search?query=VinWonders%20Nha%20Trang'),
        ('f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 10.32500000, 103.95000000, 'https://www.openstreetmap.org/search?query=Phu%20Quoc%20National%20Park'),
        ('54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 22.30333333, 103.77500000, 'https://www.openstreetmap.org/search?query=Fansipan%20Sa%20Pa'),
        ('b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 10.00194400, 105.74425600, 'https://www.openstreetmap.org/search?query=Cai%20Rang%20Floating%20Market%20Can%20Tho'),
        ('4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 11.93472000, 108.43064000, 'https://www.openstreetmap.org/search?query=Crazy%20House%20Da%20Lat')
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

WITH curated_media (
    id,
    attraction_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('44000000-0000-4000-8000-000000000001'::uuid, 'e4f055be-5d5f-4f63-845f-e3220caff0fb'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/7/79/Thap_Rua.jpg', 'https://en.wikipedia.org/wiki/Ho%C3%A0n_Ki%E1%BA%BFm_Lake', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000002'::uuid, '19bdd927-5df2-4593-b1d8-c7fe71968675'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/3/39/Hanoi_Temple_of_Literature_%28cropped%29.jpg', 'https://en.wikipedia.org/wiki/Temple_of_Literature%2C_Hanoi', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000003'::uuid, 'e142d319-5e4c-45b6-b5b2-ac79792b854d'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/f/f3/Dan_toc_hoc_1.jpg', 'https://en.wikipedia.org/wiki/Vietnam_Museum_of_Ethnology', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000004'::uuid, '95481324-fb23-4a34-bb2c-1def1a1d8777'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/7/79/Ha_Long_Bay_in_2019.jpg', 'https://en.wikipedia.org/wiki/H%E1%BA%A1_Long_Bay', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000005'::uuid, '60ce09ec-1579-4951-91fa-9918a49a7773'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/0/08/Muaxuantamcoc.jpg', 'https://en.wikipedia.org/wiki/Tr%C3%A0ng_An_Scenic_Landscape_Complex', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000006'::uuid, '79d877e2-c392-4d27-b500-c8abc645e2c3'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/5/52/Hu%E1%BA%BF_%282024%29_-_Meridian_Gate_-_Ng%E1%BB%8D_M%C3%B4n_%28Ho%C3%A0ng_th%C3%A0nh_Hu%E1%BA%BF%29_-_img_02.jpg', 'https://en.wikipedia.org/wiki/Imperial_City_of_Hu%E1%BA%BF', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000007'::uuid, 'ab83611c-6360-4ede-9aa2-6dad96f6cdc4'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Ngu_hanh_son_toan_canh.jpg/1400px-Ngu_hanh_son_toan_canh.jpg', 'https://commons.wikimedia.org/wiki/File:Ngu_hanh_son_toan_canh.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('44000000-0000-4000-8000-000000000008'::uuid, '0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg/3840px-Golden_Bridge_at_Ba_Na_Hills_20250718.jpg', 'https://en.wikipedia.org/wiki/Golden_Bridge_(Vietnam)', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000009'::uuid, '98791410-4cf9-444d-818d-463fc10728fa'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/2/27/10549-Hoi-An_%2837621348460%29.jpg', 'https://en.wikipedia.org/wiki/H%E1%BB%99i_An_Old_Town', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000010'::uuid, 'b95d8c30-4a45-475b-b51f-8346e6795017'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/War_Remnants_Museum%2C_HCMC%2C_front.JPG/3840px-War_Remnants_Museum%2C_HCMC%2C_front.JPG', 'https://en.wikipedia.org/wiki/War_Remnants_Museum', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000011'::uuid, '8b507042-be77-4e72-a530-78a6ccbf8979'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Ben_Thanh%2C_Ciudad_Ho_Chi_Minh%2C_Vietnam%2C_2013-08-14%2C_DD_01.JPG', 'https://en.wikipedia.org/wiki/B%E1%BA%BFn_Th%C3%A0nh_Market', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000012'::uuid, '583e0a5e-08b8-47fc-9627-33423c11ae8c'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/7/7d/20190923_Independence_Palace-10.jpg', 'https://en.wikipedia.org/wiki/Independence_Palace', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000013'::uuid, 'fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/b/b0/Ganesh_Tempel_Po_Nagar_Nha_Trang.jpg', 'https://en.wikipedia.org/wiki/Po_Nagar', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000014'::uuid, '89a209fe-1216-46e5-b8e2-bf18bd9e687a'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Vinpearl%20Land%20seen%20from%20Nha%20Trang.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Vinpearl_Land_seen_from_Nha_Trang.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('44000000-0000-4000-8000-000000000015'::uuid, 'f2b54b44-acbc-40a7-b3e3-4f963d306f42'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Beautiful%20beach%20on%20Phu%20Quoc%20island%20Vietnam%20%2839543775721%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Beautiful_beach_on_Phu_Quoc_island_Vietnam_(39543775721).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('44000000-0000-4000-8000-000000000016'::uuid, '54117429-8b9c-400d-83ed-b344b3ed8a52'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/0/04/Fansipan_Summit.jpg', 'https://en.wikipedia.org/wiki/Fansipan', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('44000000-0000-4000-8000-000000000017'::uuid, 'b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Cai%20Rang%20Floating%20Market%203.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Cai_Rang_Floating_Market_3.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('44000000-0000-4000-8000-000000000018'::uuid, '4a6b839b-1252-46bf-b4bc-f93b13d29dc0'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hang%20Nga%20guesthouse%2001.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hang_Nga_guesthouse_01.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
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
    curated_media.id,
    curated_media.attraction_id,
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
    FROM attractions a
    WHERE a.id = curated_media.attraction_id
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
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM attractions
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    'e4f055be-5d5f-4f63-845f-e3220caff0fb',
    '19bdd927-5df2-4593-b1d8-c7fe71968675',
    'e142d319-5e4c-45b6-b5b2-ac79792b854d',
    '95481324-fb23-4a34-bb2c-1def1a1d8777',
    '60ce09ec-1579-4951-91fa-9918a49a7773',
    '79d877e2-c392-4d27-b500-c8abc645e2c3',
    'ab83611c-6360-4ede-9aa2-6dad96f6cdc4',
    '0d3d4f26-f5e0-4f82-a7a8-850046edae00',
    '98791410-4cf9-444d-818d-463fc10728fa',
    'b95d8c30-4a45-475b-b51f-8346e6795017',
    '8b507042-be77-4e72-a530-78a6ccbf8979',
    '583e0a5e-08b8-47fc-9627-33423c11ae8c',
    'fdedb547-0ae0-4fe8-a413-dec8f9d9f154',
    '89a209fe-1216-46e5-b8e2-bf18bd9e687a',
    'f2b54b44-acbc-40a7-b3e3-4f963d306f42',
    '54117429-8b9c-400d-83ed-b344b3ed8a52',
    'b0f6561c-68a2-4dad-ae5a-80ae3edfc53c',
    '4a6b839b-1252-46bf-b4bc-f93b13d29dc0'
)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;
