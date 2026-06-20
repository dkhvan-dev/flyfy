-- Initial curated Kazakhstan places/destinations seed.
-- Texts are original Inflap editorial summaries localized for en, ru, kk.
-- Sources audited in April 2026:
-- - Visit Almaty: Charyn, Kolsai, Kaindy, Big Almaty Lake, Medeu, Shymbulak.
-- - Official Altyn-Emel National Park site.
-- - UNESCO World Heritage Centre / UNESCO MAB / gov.kz UNESCO pages.
-- - Kazakhstan.travel / QazTravel and regional gov.kz tourism pages for national parks, lakes and cultural sites.
-- Rating policy:
-- - rating is an editorial seed baseline from 4.5 to 4.8 for sorting curated import content.
-- - review_count starts at 0; after users leave reviews, the service recalculates rating from place_reviews.
-- - price is left NULL because official fees, guide costs and transport costs vary by season/operator.
-- Location policy:
-- - country_code stores the ISO-2 code from reference-service/data/countries.json (KZ).
-- - city_id stores a reference-service/data/cities.json id; for regional/nature sites it points to the nearest practical hub city.

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
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'almaty', 'NATURE', 8, 'HOURS', 4.8, ARRAY['kazakhstan', 'almaty-region', 'canyon', 'nature', 'hiking', 'photography', 'charyn']::text[]),
        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'almaty', 'NATURE', 2, 'DAYS', 4.8, ARRAY['kazakhstan', 'almaty-region', 'kolsai', 'lake', 'mountains', 'hiking', 'horse-riding']::text[]),
        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'almaty', 'NATURE', 8, 'HOURS', 4.7, ARRAY['kazakhstan', 'almaty-region', 'kaindy', 'lake', 'sunken-forest', 'saty', 'nature']::text[]),
        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'almaty', 'NATURE', 4, 'HOURS', 4.6, ARRAY['kazakhstan', 'almaty', 'big-almaty-lake', 'bao', 'ile-alatau', 'mountains', 'viewpoint']::text[]),
        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'almaty', 'ENTERTAINMENT', 3, 'HOURS', 4.6, ARRAY['kazakhstan', 'almaty', 'medeu', 'skating', 'winter', 'mountains', 'sports']::text[]),
        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'almaty', 'ENTERTAINMENT', 6, 'HOURS', 4.7, ARRAY['kazakhstan', 'almaty', 'shymbulak', 'ski', 'snowboard', 'mountains', 'cable-car']::text[]),
        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'taldykorgan', 'NATURE', 2, 'DAYS', 4.8, ARRAY['kazakhstan', 'zhetysu', 'altyn-emel', 'national-park', 'singing-dune', 'aktau-mountains', 'desert']::text[]),
        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'almaty', 'MUSEUM', 5, 'HOURS', 4.7, ARRAY['kazakhstan', 'almaty-region', 'tamgaly', 'tanbaly', 'unesco', 'petroglyphs', 'history']::text[]),
        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'turkestan', 'TEMPLE', 3, 'HOURS', 4.8, ARRAY['kazakhstan', 'turkestan', 'yasawi', 'unesco', 'mausoleum', 'silk-road', 'pilgrimage']::text[]),
        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'kokshetau', 'NATURE', 2, 'DAYS', 4.7, ARRAY['kazakhstan', 'akmola', 'burabay', 'borovoe', 'national-park', 'lakes', 'forest']::text[]),
        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'pavlodar', 'NATURE', 2, 'DAYS', 4.7, ARRAY['kazakhstan', 'pavlodar', 'bayanaul', 'national-park', 'jasybay', 'lakes', 'hiking']::text[]),
        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'ust-kamenogorsk', 'NATURE', 3, 'DAYS', 4.8, ARRAY['kazakhstan', 'east-kazakhstan', 'katon-karagay', 'altai', 'national-park', 'ecotourism', 'berel']::text[]),
        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'shymkent', 'NATURE', 2, 'DAYS', 4.8, ARRAY['kazakhstan', 'turkestan-region', 'aksu-jabagly', 'western-tien-shan', 'reserve', 'tulips', 'wildlife']::text[]),
        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'astana', 'NATURE', 2, 'DAYS', 4.7, ARRAY['kazakhstan', 'akmola', 'kostanay', 'saryarka', 'unesco', 'korgalzhyn', 'naurzum', 'birdwatching']::text[]),
        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'taldykorgan', 'BEACH', 2, 'DAYS', 4.5, ARRAY['kazakhstan', 'zhetysu', 'abai', 'alakol', 'lake', 'beach', 'wellness', 'birdwatching']::text[]),
        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'balkhash', 'BEACH', 2, 'DAYS', 4.5, ARRAY['kazakhstan', 'balkhash', 'lake', 'beach', 'fishing', 'central-kazakhstan', 'nature']::text[]),
        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'aktau', 'NATURE', 1, 'DAYS', 4.8, ARRAY['kazakhstan', 'mangystau', 'bozjyra', 'ustyurt', 'desert', 'limestone', 'photography']::text[]),
        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'astana', 'ARCHITECTURE', 2, 'HOURS', 4.5, ARRAY['kazakhstan', 'astana', 'bayterek', 'tower', 'architecture', 'viewpoint', 'city']::text[]),
        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'taraz', 'MUSEUM', 3, 'HOURS', 4.6, ARRAY['kazakhstan', 'taraz', 'zhambyl', 'ancient-taraz', 'silk-road', 'museum', 'archaeology']::text[]),
        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'zhezkazgan', 'MUSEUM', 2, 'DAYS', 4.7, ARRAY['kazakhstan', 'ulytau', 'reserve-museum', 'great-steppe', 'jochi-khan', 'petroglyphs', 'history']::text[])
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
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'en', 'Charyn Canyon', 'A signature canyon route in Almaty Region, known for the Valley of Castles, red sedimentary cliffs and the Charyn River. It works well as a full day trip from Almaty with walking, viewpoints and photography.'),
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'ru', 'Чарынский каньон', 'Один из главных природных маршрутов Алматинской области: Долина замков, красные осадочные скалы и река Чарын. Формат хорошо подходит для однодневной поездки из Алматы с прогулкой, смотровыми точками и фотографиями.'),
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'kk', 'Шарын шатқалы', 'Алматы облысындағы ең танымал табиғи бағыттардың бірі: Қамалдар аңғары, қызыл түсті жартастар және Шарын өзені. Алматыдан бір күндік сапарға, серуенге, көрініс алаңдарына және фотосуретке қолайлы.'),

        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'en', 'Kolsai Lakes', 'A cascade of alpine lakes in the Northern Tien Shan, surrounded by spruce forest, meadows and steep mountain slopes. The lower lake is the easiest to reach; the upper routes are better for hiking or horse riding over two days.'),
        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'ru', 'Кольсайские озера', 'Каскад высокогорных озер Северного Тянь-Шаня среди елового леса, лугов и крутых склонов. Нижнее озеро самое доступное, а маршруты выше лучше планировать на два дня с пешим походом или конной прогулкой.'),
        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'kk', 'Көлсай көлдері', 'Солтүстік Тянь-Шаньдағы шыршалы орман, шалғын және тік тау беткейлері қоршаған биік таулы көлдер каскады. Төменгі көлге жету жеңіл, ал жоғарғы бағыттарды жаяу не атпен екі күнге жоспарлаған дұрыс.'),

        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'en', 'Lake Kaindy', 'A mountain lake near Saty famous for its sunken spruce trunks rising from cold blue-green water. The lake formed after an earthquake-triggered landslide, and it pairs naturally with Kolsai while staying a separate stop.'),
        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'ru', 'Озеро Каинды', 'Горное озеро рядом с Саты, знаменитое затопленными елями, которые поднимаются из холодной сине-зеленой воды. Озеро образовалось после оползня, вызванного землетрясением, и удобно совмещается с Кольсаем.'),
        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'kk', 'Қайыңды көлі', 'Саты ауылы маңындағы көгілдір-жасыл суынан шығып тұрған су астындағы шыршаларымен белгілі тау көлі. Ол жер сілкінісінен кейінгі көшкін нәтижесінде пайда болған және Көлсаймен бірге бөлек аялдама ретінде ыңғайлы.'),

        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'en', 'Big Almaty Lake', 'A high-mountain reservoir in Ile-Alatau National Park about 20 km from Almaty. Its turquoise-to-emerald water, alpine air and surrounding peaks make it a short scenic escape from the city.'),
        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'ru', 'Большое Алматинское озеро', 'Высокогорное водохранилище в Иле-Алатауском национальном парке примерно в 20 км от Алматы. Бирюзово-изумрудная вода, горный воздух и окружающие вершины делают его коротким живописным выездом из города.'),
        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'kk', 'Үлкен Алматы көлі', 'Алматыдан шамамен 20 км жердегі Іле-Алатауы ұлттық паркінің биік таулы су айдыны. Көгілдірден изумруд түске ауысатын суы, тау ауасы және шыңдары оны қала маңындағы әдемі бағыт етеді.'),

        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'en', 'Medeu Alpine Skating Rink', 'A high-altitude open-air sports complex above Almaty, known for its large artificial ice field, mountain views and record-setting skating history. Outside winter it is a gateway to the dam, stairs and nearby mountain walks.'),
        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'ru', 'Высокогорный каток Медеу', 'Высокогорный спортивный комплекс над Алматы с большим искусственным ледовым полем, видами на горы и историей мировых рекордов. Вне зимнего сезона это старт к плотине, лестнице здоровья и горным прогулкам.'),
        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'kk', 'Медеу жоғары таулы мұз айдыны', 'Алматы үстіндегі үлкен жасанды мұз айдынымен, тау көріністерімен және рекордтар тарихымен белгілі биік таулы спорт кешені. Қыстан тыс уақытта бөгетке, денсаулық баспалдағына және тау серуендеріне жол ашады.'),

        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'en', 'Shymbulak Ski Resort', 'A year-round mountain resort above Almaty with skiing, snowboarding, cable-car viewpoints, cafes and summer alpine activities. The highest areas can be reached from the city within about an hour in normal conditions.'),
        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'ru', 'Горный курорт Шымбулак', 'Круглогодичный горный курорт над Алматы: лыжи, сноуборд, канатная дорога, смотровые площадки, кафе и летние активности в горах. До верхних зон обычно можно добраться из города примерно за час.'),
        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'kk', 'Шымбұлақ тау курорты', 'Алматы үстіндегі жыл бойы жұмыс істейтін тау курорты: шаңғы, сноуборд, аспалы жол, көрініс алаңдары, кафе және жазғы тау белсенділіктері. Қаладан жоғарғы аймақтарға қалыпты жағдайда шамамен бір сағатта жетуге болады.'),

        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'en', 'Altyn-Emel National Park', 'A large protected landscape in Zhetysu where desert, steppe, mountains and wildlife habitats meet. Key routes include the Singing Dune, Aktau and Katutau formations, Besshatyr mounds and the Ili River valley.'),
        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'ru', 'Национальный парк Алтын-Эмель', 'Большая охраняемая территория Жетісу, где встречаются пустыня, степь, горы и места обитания редких животных. Основные маршруты ведут к Поющему бархану, горам Актау и Катутау, курганам Бесшатыр и долине Или.'),
        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'kk', 'Алтынемел ұлттық паркі', 'Жетісудағы шөл, дала, таулар және сирек жануарлар мекені тоғысқан үлкен қорғалатын аумақ. Негізгі бағыттар Әншіқұмға, Ақтау мен Қатутау тауларына, Бесшатыр қорғандарына және Іле аңғарына апарады.'),

        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'en', 'Tamgaly Petroglyphs', 'A UNESCO-listed archaeological landscape in the Chu-Ili mountains with thousands of rock carvings, settlements, burial sites and ritual spaces. The central gorge is especially valuable for Bronze Age and later pastoral cultures.'),
        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'ru', 'Петроглифы Тамгалы', 'Археологический ландшафт ЮНЕСКО в горах Чу-Или с тысячами наскальных рисунков, поселениями, захоронениями и ритуальными местами. Центральное ущелье особенно ценно для изучения культур бронзового века и поздних эпох.'),
        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'kk', 'Таңбалы петроглифтері', 'Шу-Іле тауларындағы ЮНЕСКО тізіміндегі археологиялық ландшафт: мыңдаған жартас суреттері, қоныстар, қорымдар және ғұрыптық орындар. Орталық шатқал қола дәуірі мен кейінгі малшы мәдениеттер үшін ерекше құнды.'),

        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'en', 'Mausoleum of Khoja Ahmed Yasawi', 'A UNESCO World Heritage monument in Turkestan and one of the best preserved major Timurid buildings. It is central to Silk Road heritage, pilgrimage routes and the architectural identity of southern Kazakhstan.'),
        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'ru', 'Мавзолей Ходжи Ахмеда Ясави', 'Памятник Всемирного наследия ЮНЕСКО в Туркестане и один из наиболее сохранных крупных объектов тимуридской архитектуры. Он важен для наследия Шелкового пути, паломничества и архитектурной идентичности юга Казахстана.'),
        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'kk', 'Қожа Ахмет Ясауи кесенесі', 'Түркістандағы ЮНЕСКО дүниежүзілік мұрасы және темірлік сәулет өнерінің ең жақсы сақталған ірі ескерткіштерінің бірі. Ол Жібек жолы мұрасы, зиярат дәстүрі және оңтүстік Қазақстан сәулеті үшін маңызды.'),

        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'en', 'Burabay National Park', 'A year-round resort area in Akmola Region with pine forests, lakes, granite rocks and accessible hiking near Astana. Popular stops include Okzhetpes, Zhumbaktas, Bolektau viewpoints and lakeside recreation zones.'),
        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'ru', 'Национальный парк Бурабай', 'Круглогодичная курортная зона Акмолинской области с сосновыми лесами, озерами, гранитными скалами и доступными маршрутами недалеко от Астаны. Популярны Окжетпес, Жумбактас, Бурабайские смотровые точки и зоны отдыха у воды.'),
        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'kk', 'Бурабай ұлттық паркі', 'Ақмола облысындағы жыл бойы демалуға болатын аймақ: қарағайлы орман, көлдер, гранит жартастар және Астанаға жақын жеңіл маршруттар. Оқжетпес, Жұмбақтас, Бөлектау көріністері және көл жағалауы танымал.'),

        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'en', 'Bayanaul National Park', 'Kazakhstan''s first national park, combining granite cliffs, pine forests, clear lakes and sacred historical sites. Jasybay, Sabyndykol and Toraigyr lakes make it strong for summer recreation, hiking and family trips.'),
        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'ru', 'Национальный парк Баянаул', 'Первый национальный парк Казахстана: гранитные скалы, сосновые леса, чистые озера и сакральные исторические места. Озера Жасыбай, Сабындыколь и Торайгыр делают его сильным направлением для лета, походов и семейных поездок.'),
        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'kk', 'Баянауыл ұлттық паркі', 'Қазақстанның алғашқы ұлттық паркі: гранит жартастар, қарағайлы орман, мөлдір көлдер және киелі тарихи орындар. Жасыбай, Сабындыкөл және Торайғыр көлдері жазғы демалысқа, жаяу серуенге және отбасылық сапарға қолайлы.'),

        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'en', 'Katon-Karagay National Park', 'A vast Altai national park with mountain rivers, forests, alpine meadows, wildlife habitats and cultural sites such as the Berel mounds. Its scale and remote location make it better for slow eco-adventure.'),
        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'ru', 'Национальный парк Катон-Карагай', 'Большой национальный парк Алтая с горными реками, лесами, альпийскими лугами, местами обитания животных и культурными объектами вроде Берельских курганов. Масштаб и удаленность делают его направлением для неспешного экопутешествия.'),
        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'kk', 'Қатонқарағай ұлттық паркі', 'Алтайдағы тау өзендері, ормандар, альпілік шалғындар, жануарлар мекені және Берел қорғандары сияқты мәдени нысандары бар үлкен ұлттық парк. Аумағы мен қашықтығы оны баяу экосаяхатқа лайық етеді.'),

        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'en', 'Aksu-Zhabagly Nature Reserve', 'A protected Western Tien Shan area known for mountain biodiversity, wild tulips, deep canyons, alpine meadows and rare wildlife including snow leopard habitat. It is one of southern Kazakhstan''s strongest nature destinations.'),
        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'ru', 'Заповедник Аксу-Жабаглы', 'Охраняемая территория Западного Тянь-Шаня, известная горным биоразнообразием, дикими тюльпанами, глубокими каньонами, альпийскими лугами и редкими животными, включая ареал снежного барса. Один из главных природных маршрутов юга Казахстана.'),
        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'kk', 'Ақсу-Жабағылы қорығы', 'Батыс Тянь-Шаньдағы тау биоалуандығымен, жабайы қызғалдақтарымен, терең шатқалдарымен, альпілік шалғындарымен және қар барысы мекендейтін сирек жануарларымен белгілі қорғалатын аумақ. Оңтүстік Қазақстандағы басты табиғи бағыттардың бірі.'),

        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'en', 'Saryarka Steppe and Lakes', 'A UNESCO World Heritage natural site formed by Korgalzhyn and Naurzum reserves. Its wetlands and steppe landscapes are important for migratory birds and for protecting the wider Central Asian steppe ecosystem.'),
        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'ru', 'Сарыарка: степи и озера', 'Природный объект Всемирного наследия ЮНЕСКО, включающий Коргалжынский и Наурзумский заповедники. Водно-болотные угодья и степи важны для мигрирующих птиц и сохранения экосистем Центральной Азии.'),
        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'kk', 'Сарыарқа даласы мен көлдері', 'Қорғалжын және Наурызым қорықтарын қамтитын ЮНЕСКО дүниежүзілік табиғи мұрасы. Сулы-батпақты жерлер мен дала ландшафттары қоныс аударатын құстар және Орталық Азия экожүйелерін сақтау үшін маңызды.'),

        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'en', 'Lake Alakol', 'A large mineral lake on the border of Zhetysu and Abai regions, known for changing water colors, dark pebble beaches, summer recreation and wellness tourism. The coast is also a practical family resort area.'),
        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'ru', 'Озеро Алаколь', 'Крупное минеральное озеро на границе областей Жетісу и Абай, известное меняющимися оттенками воды, темной галькой, летним отдыхом и оздоровительным туризмом. Побережье удобно для семейного курортного формата.'),
        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'kk', 'Алакөл', 'Жетісу мен Абай облыстары шекарасындағы су түсі құбылып тұратын, қара малтатасты жағалауымен, жазғы демалысымен және сауықтыру туризмімен белгілі ірі минералды көл. Жағалауы отбасылық курортқа қолайлы.'),

        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'en', 'Lake Balkhash', 'One of Kazakhstan''s largest lakes, known for its unusual split character: the western part is almost fresh while the eastern part is brackish. It supports beach recreation, fishing, birdlife and central Kazakhstan road trips.'),
        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'ru', 'Озеро Балхаш', 'Одно из крупнейших озер Казахстана с необычным разделением: западная часть почти пресная, восточная солоноватая. Балхаш подходит для пляжного отдыха, рыбалки, наблюдения за птицами и автопутешествий по центру страны.'),
        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'kk', 'Балқаш көлі', 'Қазақстандағы ең үлкен көлдердің бірі, батыс бөлігі тұщыға жақын, шығыс бөлігі тұздылау болып бөлінетін ерекшелігімен белгілі. Балқаш жағажай демалысына, балық аулауға, құстарды бақылауға және орталық өңірлерге сапарға қолайлы.'),

        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'en', 'Bozjyra Tract', 'A dramatic Mangystau landscape on the Ustyurt Plateau with pale limestone cliffs, clay desert and isolated buttes. Its remote access and exposed terrain make it best as a guided full-day route with careful logistics.'),
        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'ru', 'Урочище Бозжыра', 'Выразительный ландшафт Мангистау на плато Устюрт: светлые известняковые обрывы, глинистая пустыня и останцы. Из-за удаленности и открытой местности маршрут лучше планировать на полный день с гидом и подготовленной логистикой.'),
        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'kk', 'Бозжыра шатқалы', 'Үстірт платосындағы Маңғыстаудың әсерлі ландшафты: ақшыл әктас жартастар, сазды шөл және оқшау мұнара пішінді қалдықтар. Қашық орналасуы мен ашық жер бедері үшін толық күндік гидпен жоспарланғаны дұрыс.'),

        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'en', 'Bayterek Tower', 'Astana''s landmark observation tower, inspired by the tree-of-life myth and the Samruk bird. The viewing level symbolically aligns with 1997, the year Astana became the capital, making it a concise city orientation stop.'),
        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'ru', 'Монумент Байтерек', 'Знаковая смотровая башня Астаны, вдохновленная образом дерева жизни и птицы Самрук. Высота смотрового уровня символически связана с 1997 годом, когда Астана стала столицей, поэтому это удобная первая точка знакомства с городом.'),
        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'kk', 'Бәйтерек монументі', 'Өмір ағашы мен Самұрық құсы туралы аңыздан шабыт алған Астананың басты көрініс мұнарасы. Көрініс деңгейі Астананың астана болған 1997 жылымен символикалық байланыста, сондықтан қалаға бағдар алуға ыңғайлы алғашқы нүкте.'),

        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'en', 'Ancient Taraz Historical and Cultural Center', 'A 10-hectare open-air museum in Taraz where archaeological work reveals Silk Road urban life and steppe civilization layers. Visitors can see traces of mosques, madrasas, baths, coins and household artifacts.'),
        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'ru', 'Историко-культурный центр Древний Тараз', 'Открытый музей площадью около 10 гектаров в Таразе, где археология раскрывает городскую жизнь Шелкового пути и слои степной цивилизации. Здесь можно увидеть следы мечетей, медресе, бань, монеты и бытовые находки.'),
        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'kk', 'Ежелгі Тараз тарихи-мәдени орталығы', 'Тараздағы шамамен 10 гектарлық ашық аспан астындағы музей, онда археология Жібек жолы қалалық өмірін және дала өркениетінің қабаттарын ашады. Келушілер мешіт, медресе, монша іздерін, монеталар мен тұрмыстық бұйымдарды көре алады.'),

        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'en', 'Ulytau Reserve-Museum', 'A historical, cultural and natural reserve-museum in the symbolic center of Kazakhstan. The protected landscape connects Jochi Khan, Alasha Khan, Terekty Aulie petroglyphs and long layers of Great Steppe history.'),
        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'ru', 'Заповедник-музей Улытау', 'Историко-культурный и природный заповедник-музей в символическом центре Казахстана. Охраняемый ландшафт связан с Жошы ханом, Алаша ханом, петроглифами Теректы Аулие и многослойной историей Великой степи.'),
        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'kk', 'Ұлытау қорық-музейі', 'Қазақстанның символдық орталығындағы тарихи-мәдени және табиғи қорық-музей. Қорғалатын ландшафт Жошы хан, Алаша хан, Теректі Әулие петроглифтері және Ұлы даланың көпқабатты тарихымен байланысты.')
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
