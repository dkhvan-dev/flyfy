-- Remaining Kazakhstan route-level outdoor/hiking seed.
-- Adds concrete non-duplicate routes that complement previous Kazakhstan hiking layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_remaining_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remaining_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_remaining_outdoor_routes_places (
    country_code varchar(2) NOT NULL,
    price_currency varchar(3) NOT NULL,
    slug varchar(96) NOT NULL,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    price_amount numeric(12,2) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL DEFAULT 'HOURS',
    rating numeric(2,1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    description_kk text NOT NULL,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    media_file text NOT NULL,
    access_city_ids text[] NOT NULL,
    departure_city_ids text[] NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[],
    PRIMARY KEY (country_code, slug)
);

INSERT INTO seed_kazakhstan_remaining_outdoor_routes_places (
    country_code,
    price_currency,
    slug,
    city_id,
    category,
    price_amount,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    media_file,
    access_city_ids,
    departure_city_ids,
    extra_tags
) VALUES
    ('KZ', 'KZT', 'temirlik-canyon-trail', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа каньона Темирлик', 'Temirlik Canyon Trail', 'Темірлік каньоны соқпағы', 'Менее перегруженный маршрут Чарынского района с красными стенами, сухим руслом и короткой пешей логистикой для активной остановки.', 'A quieter Charyn-area route with red walls, a dry streambed and short walking logistics for an active stop.', 'Шарын маңындағы тынышырақ бағыт: қызыл қабырғалар, құрғақ арна және белсенді аялдамаға арналған қысқа жаяу логистика.', 43.44900000, 79.25500000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','canyon','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'bestamak-canyon-rim-trail', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа по краю каньона Бестамак', 'Bestamak Canyon Rim Trail', 'Бестамақ каньоны жиегі соқпағы', 'Маршрут по сухому каньонному рельефу с открытыми видами, каменными ребрами и более спокойным сценарием по сравнению с главными смотровыми.', 'A dry canyon-land route with open views, stone ribs and a calmer scenario than the main viewpoints.', 'Ашық көріністері, тасты қырлары және негізгі көрініс нүктелерінен тынышырақ сценарийі бар құрғақ каньон бағыты.', 43.39900000, 79.11200000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn-area','rim','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'first-kolsai-shore-loop', 'almaty', 'NATURE', 1000, 3, 'HOURS', 4.8, 'Береговая петля Первого Кольсая', 'First Kolsai Shore Loop', 'Бірінші Көлсай жағалау ілмегі', 'Доступная прогулка вокруг нижнего горного озера с еловым лесом, прозрачной водой и мягким форматом для семейного дня.', 'An accessible walk around the lower mountain lake with spruce forest, clear water and a gentle family-day format.', 'Төменгі тау көлі маңындағы қолжетімді серуен: шыршалы орман, мөлдір су және отбасылық күнге жұмсақ формат.', 42.93800000, 78.32500000, 'Kolsai lake.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kolsai','lake-shore','walking']::text[]),
    ('KZ', 'KZT', 'turgusun-waterfall-forest-trail', 'ust-kamenogorsk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Лесная тропа к Тургусунскому водопаду', 'Turgusun Waterfall Forest Trail', 'Тұрғысын сарқырамасы орман соқпағы', 'Алтайский маршрут к лесной долине, влажным склонам и водопадной точке для спокойного выезда из Восточного Казахстана.', 'An Altai route toward a forest valley, humid slopes and a waterfall point for a calm East Kazakhstan outing.', 'Шығыс Қазақстандағы тыныш сапарға арналған Алтай бағыты: орман аңғары, ылғалды беткейлер және сарқырама нүктесі.', 50.26800000, 84.24500000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','waterfall','forest','free-entry','hiking','trekking']::text[]),
    ('KZ', 'KZT', 'bukhtarma-shore-pine-trail', 'ust-kamenogorsk', 'NATURE', 0, 3, 'HOURS', 4.6, 'Сосновая тропа берега Бухтармы', 'Bukhtarma Shore Pine Trail', 'Бұқтырма жағалауы қарағай соқпағы', 'Легкая природная прогулка у водохранилища с сосновыми участками, открытой водой и мягким летним форматом.', 'An easy nature walk by the reservoir with pine sections, open water and a gentle summer format.', 'Су қоймасы маңындағы қарағайлы бөліктері, ашық суы және жеңіл жазғы форматы бар табиғи серуен.', 49.63500000, 83.51600000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['kazakhstan','bukhtarma','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'chernovaya-uba-forest-trail', 'ust-kamenogorsk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Лесная тропа Черновой Убы', 'Chernovaya Uba Forest Trail', 'Қара Үбі орман соқпағы', 'Таежный маршрут района Риддера вдоль прохладной реки, хвойных склонов и тихих полян для насыщенного лесного дня.', 'A Ridder-area taiga route along a cool river, conifer slopes and quiet glades for a rich forest day.', 'Риддер маңындағы салқын өзен, қылқанды беткейлер және тыныш алаңқайлар бойымен өтетін тайга бағыты.', 50.37400000, 83.77100000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','ridder','taiga','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'sabyndykol-pine-shore-loop', 'pavlodar', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Сосновая петля берега Сабындыколя', 'Sabyndykol Pine Shore Loop', 'Сабындыкөл қарағайлы жағалау ілмегі', 'Короткая баянаульская прогулка у воды, сосен и гранитных склонов, подходящая для спокойного летнего дня.', 'A short Bayanaul walk by water, pines and granite slopes, suited to a calm summer day.', 'Су, қарағай және гранит беткейлері жанындағы қысқа Баянауыл серуені, тыныш жазғы күнге лайық.', 50.79000000, 75.67700000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','lake-shore','walking']::text[]),
    ('KZ', 'KZT', 'birzhankol-granite-trail', 'pavlodar', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Гранитная тропа Биржанколя', 'Birzhankol Granite Trail', 'Біржанкөл гранит соқпағы', 'Баянаульский маршрут среди низких скал, соснового воздуха и тихих обзорных точек вдали от самых популярных берегов.', 'A Bayanaul route among low rocks, pine air and quiet viewpoints away from the busiest shores.', 'Ең танымал жағалардан алыстау аласа жартастар, қарағай ауасы және тыныш көрініс нүктелері арасындағы Баянауыл бағыты.', 50.74100000, 75.83000000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','granite','hiking']::text[]),
    ('KZ', 'KZT', 'sandyktau-forest-ridge-walk', 'kokshetau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Лесная прогулка гряды Сандыктау', 'Sandyktau Forest Ridge Walk', 'Сандықтау орман жотасы серуені', 'Северная лесостепная прогулка к низким грядам, сосновым участкам и открытым видам Акмолинской области.', 'A northern forest-steppe walk to low ridges, pine pockets and open Akmola Region views.', 'Ақмола облысының аласа жоталарына, қарағайлы бөліктеріне және ашық көріністеріне апаратын солтүстік орманды дала серуені.', 52.76500000, 68.16800000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','akmola-region','forest-steppe','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shortandy-lake-shore-walk', 'kokshetau', 'NATURE', 0, 2, 'HOURS', 4.5, 'Береговая прогулка озера Шортанды', 'Shortandy Lake Shore Walk', 'Шортанды көлі жағалау серуені', 'Легкая северная прогулка у озера с камышами, соснами и спокойной природной паузой между городскими маршрутами.', 'An easy northern lake walk with reeds, pines and a calm nature pause between city routes.', 'Қамысы, қарағайы және қалалық бағыттар арасында тыныш табиғи үзілісі бар жеңіл солтүстік көл серуені.', 52.98900000, 70.24200000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','akmola-region','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karatal-delta-reed-walk', 'balkhash', 'NATURE', 0, 4, 'HOURS', 4.6, 'Камышовая прогулка дельты Каратала', 'Karatal Delta Reed Walk', 'Қаратал атырауы қамыс серуені', 'Маршрут у восточной части Балхаша с камышовыми протоками, птицами и мягким водно-степным ландшафтом.', 'A route on the eastern side of Balkhash with reed channels, birds and a gentle water-steppe landscape.', 'Балқаштың шығыс жағындағы қамысты тармақтар, құстар және жұмсақ су-дала ландшафты арқылы өтетін бағыт.', 45.99500000, 78.09000000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash','taldykorgan']::text[], ARRAY['balkhash','taldykorgan']::text[], ARRAY['kazakhstan','balkhash','delta','free-entry','birdwatching']::text[]),
    ('KZ', 'KZT', 'aksu-ayuly-steppe-ridge-walk', 'karaganda', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная прогулка гряды Аксу-Аюлы', 'Aksu-Ayuly Steppe Ridge Walk', 'Ақсу-Аюлы дала жотасы серуені', 'Центральноказахстанский маршрут по низким сопкам, сухой траве и открытым горизонтам для короткого выезда из Караганды.', 'A central Kazakhstan route across low hills, dry grass and open horizons for a short outing from Karaganda.', 'Қарағандыдан қысқа шығуға арналған Орталық Қазақстан бағыты: аласа шоқылар, құрғақ шөп және ашық көкжиектер.', 48.77300000, 73.67200000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda','balkhash']::text[], ARRAY['karaganda','balkhash']::text[], ARRAY['kazakhstan','central-kazakhstan','steppe-ridge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kambash-lake-dune-walk', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.5, 'Дюнная прогулка озера Камбаш', 'Kambash Lake Dune Walk', 'Қамбаш көлі құмды серуені', 'Приаральская прогулка у песчаных берегов, открытой воды и сухого степного ветра для спокойной природной остановки.', 'An Aral-side walk by sandy shores, open water and dry steppe wind for a calm nature stop.', 'Арал маңындағы құмды жағалар, ашық су және құрғақ дала желі жанындағы тыныш табиғи аялдама.', 46.04000000, 61.73000000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','aral-region','lake','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'syrdarya-tugai-walk', 'kyzylorda', 'NATURE', 0, 3, 'HOURS', 4.4, 'Тугайная прогулка Сырдарьи', 'Syrdarya Tugai Walk', 'Сырдария тоғай серуені', 'Легкий маршрут у пойменной зелени Сырдарьи с тенистыми участками, водой и редким для региона контрастом к пустынному пейзажу.', 'An easy route through Syrdarya floodplain greenery with shade, water and a contrast to the regional desert landscape.', 'Сырдария жайылмасының жасылдығы, көлеңкелі бөліктері, суы және өңірдің шөл пейзажына қарама-қарсы әсері бар жеңіл бағыт.', 44.84200000, 65.50200000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','kyzylorda-region','river','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karagaily-mugodzhary-ridge-trail', 'aktobe', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа Карагайлинской гряды Мугоджар', 'Karagaily Mugodzhary Ridge Trail', 'Қарағайлы Мұғалжар жотасы соқпағы', 'Западноказахстанский маршрут по вытянутой гряде, степным склонам и редким лесным участкам для полноценного outdoor-дня.', 'A western Kazakhstan route along an elongated ridge, steppe slopes and rare forest pockets for a full outdoor day.', 'Батыс Қазақстандағы созылған жота, дала беткейлері және сирек орман бөліктері арқылы өтетін толық outdoor күн бағыты.', 49.48500000, 58.23500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','ridge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'bokei-orda-pine-belt-walk', 'oral', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка соснового пояса Бокей Орды', 'Bokei Orda Pine Belt Walk', 'Бөкей Орда қарағай белдеуі серуені', 'Западноказахстанский маршрут среди песчаных почв, сосен и степного воздуха, который дает региону более мягкий природный сценарий.', 'A West Kazakhstan route among sandy soils, pines and steppe air, giving the region a softer nature scenario.', 'Батыс Қазақстандағы құмды топырақ, қарағай және дала ауасы арасындағы бағыт, өңірге жұмсағырақ табиғи сценарий береді.', 49.19000000, 47.33500000, 'Atyrau footbridge across Ural River.jpg', ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','pine-belt','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'akkespe-chalk-cliffs-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прогулка меловых обрывов Акеспе', 'Akkespe Chalk Cliffs Walk', 'Ақеспе бор жартастары серуені', 'Мангистауский маршрут по светлым меловым стенам, сухим ложбинам и мягкому пустынному свету для короткого выезда.', 'A Mangystau route along pale chalk walls, dry hollows and soft desert light for a short outing.', 'Маңғыстаудағы ақшыл бор қабырғалары, құрғақ ойпаңдар және жұмсақ шөл жарығы бойымен өтетін қысқа сапар.', 44.43200000, 52.44600000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','chalk-cliffs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karaman-ata-ravine-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка балки Караман-Ата', 'Karaman-Ata Ravine Walk', 'Қараман-Ата сайы серуені', 'Короткий маршрут по сухой балке и плато Мангистау, где природный рельеф соединяется с историко-паломническим контекстом.', 'A short route through a dry ravine and Mangystau plateau where landform meets heritage and pilgrim context.', 'Құрғақ сай және Маңғыстау үстірті арқылы өтетін қысқа бағыт, табиғи бедерді мұра және зиярат контекстімен байланыстырады.', 44.19000000, 52.15000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','ravine','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kelte-mashat-canyon-walk', 'shymkent', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка каньона Кельте-Машат', 'Kelte-Mashat Canyon Walk', 'Келте-Машат каньоны серуені', 'Южный маршрут к сухим стенкам каньона, ручьям и арчовым склонам, который расширяет выбор коротких выездов из Шымкента.', 'A southern route to dry canyon walls, streams and juniper slopes, widening short-trip choices from Shymkent.', 'Шымкенттен қысқа шығу таңдауын кеңейтетін оңтүстік бағыт: құрғақ каньон қабырғалары, бұлақтар және аршалы беткейлер.', 42.39000000, 70.07000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','south-kazakhstan','canyon','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'akmechet-cave-steppe-walk', 'turkestan', 'NATURE', 0, 3, 'HOURS', 4.5, 'Степная прогулка к пещере Акмешит', 'Akmechet Cave Steppe Walk', 'Ақмешіт үңгірі дала серуені', 'Короткий маршрут Туркестанской области к природной пещере, сухим склонам и открытому степному пейзажу.', 'A short Turkestan Region route toward a natural cave, dry slopes and an open steppe landscape.', 'Түркістан облысындағы табиғи үңгірге, құрғақ беткейлерге және ашық дала пейзажына апаратын қысқа бағыт.', 43.11500000, 68.90500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','turkestan-region','cave','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'zhanatas-karatau-ridge-walk', 'taraz', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка хребта Каратау у Жанатаса', 'Zhanatas Karatau Ridge Walk', 'Жаңатас Қаратау жотасы серуені', 'Жамбылский маршрут по сухим грядам, каменистым тропам и широким видам северного Каратау для спокойного полудня.', 'A Zhambyl route across dry ridges, stony paths and wide northern Karatau views for a calm half day.', 'Жамбыл өңіріндегі құрғақ жоталар, тасты жолдар және солтүстік Қаратаудың кең көріністері арқылы өтетін тыныш жарты күндік бағыт.', 43.57500000, 69.75500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz','turkestan']::text[], ARRAY['taraz','turkestan']::text[], ARRAY['kazakhstan','zhambyl-region','ridge','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_remaining_outdoor_routes_resolved_places AS
SELECT
    ('105d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
    country_code,
    price_currency,
    slug,
    city_id,
    category,
    price_amount,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    media_file,
    access_city_ids,
    departure_city_ids,
    (
        substr(md5(country_code || ':' || slug || ':media'), 1, 8) || '-' ||
        substr(md5(country_code || ':' || slug || ':media'), 9, 4) || '-4' ||
        substr(md5(country_code || ':' || slug || ':media'), 14, 3) || '-8' ||
        substr(md5(country_code || ':' || slug || ':media'), 18, 3) || '-' ||
        substr(md5(country_code || ':' || slug || ':media'), 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(media_file, ' ', '%20') || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || replace(media_file, ' ', '_') AS media_source_url,
    ARRAY['kazakhstan-remaining-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_remaining_outdoor_routes_places;

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
    latitude,
    longitude,
    location_source_url,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
    duration_value,
    duration_unit,
    rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    tags,
    latitude,
    longitude,
    'https://inflap.app/map?lat=' || trim(to_char(latitude, 'FM999999990.000000')) || '&lon=' || trim(to_char(longitude, 'FM999999990.000000')),
    NOW(),
    NOW()
FROM seed_kazakhstan_remaining_outdoor_routes_resolved_places
ON CONFLICT (id) DO UPDATE SET
    author_user_id = EXCLUDED.author_user_id,
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
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location_source_url = EXCLUDED.location_source_url,
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
    locale,
    title,
    description,
    NOW(),
    NOW()
FROM seed_kazakhstan_remaining_outdoor_routes_resolved_places
CROSS JOIN LATERAL (
    VALUES
        ('ru', title_ru, description_ru),
        ('en', title_en, description_en),
        ('kk', title_kk, description_kk)
) AS localized(locale, title, description)
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

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
    media_source_url,
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM seed_kazakhstan_remaining_outdoor_routes_resolved_places
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
    place_id,
    city_id,
    kind,
    sort_order
)
SELECT
    id,
    access_city.city_id,
    'ACCESS',
    access_city.ord::int - 1
FROM seed_kazakhstan_remaining_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

INSERT INTO place_city_links (
    place_id,
    city_id,
    kind,
    sort_order
)
SELECT
    id,
    departure_city.city_id,
    'DEPARTURE',
    departure_city.ord::int - 1
FROM seed_kazakhstan_remaining_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_remaining_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_remaining_outdoor_routes_places;
