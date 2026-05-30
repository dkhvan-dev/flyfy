-- Priority Philippines attractions seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Love Philippines / official local tourism pages where available.
-- - Klook and Tripadvisor for tourist-demand signals.
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always PH;
-- - city_id stores the practical tourist hub for filtering and guide departures;
-- - markets and night markets use the MARKET category;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets, tours and opening conditions change by season/operator.

DROP TABLE IF EXISTS seed_philippines_resolved_attractions;
DROP TABLE IF EXISTS seed_philippines_priority_attractions;

CREATE TEMP TABLE seed_philippines_priority_attractions (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    tags text[] NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    description_kk text NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_source_url text NOT NULL,
    media_file text NOT NULL
);

INSERT INTO seed_philippines_priority_attractions (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    location_source_url,
    media_file
) VALUES
    ('intramuros', 'manila', 'ARCHITECTURE', 3, 'HOURS', 4.7, ARRAY['philippines', 'manila', 'intramuros', 'old-city', 'history', 'architecture']::text[], 'Интрамурос', 'Intramuros', 'Интрамурос', 'Исторический укрепленный район Манилы с испанскими стенами, церквями, музеями и пешеходными маршрутами. Это главный старт для знакомства с колониальной историей города.', 'Manila historic walled district with Spanish-era walls, churches, museums and walkable routes. It is the main starting point for the city colonial history.', 'Испан дәуірінің қабырғалары, шіркеулері, музейлері және жаяу маршруттары бар Маниланың тарихи қамалды ауданы. Қаланың отарлық тарихымен танысуға негізгі бастау.', 14.58960000, 120.97470000, 'https://www.openstreetmap.org/search?query=Intramuros%20Manila', 'Intramuros,_Manila.jpg'),
    ('fort-santiago', 'manila', 'ARCHITECTURE', 2, 'HOURS', 4.7, ARRAY['philippines', 'manila', 'fort-santiago', 'intramuros', 'history', 'fort']::text[], 'Форт Сантьяго', 'Fort Santiago', 'Сантьяго форты', 'Крепость внутри Интрамуроса с воротами, бастионами и мемориальным маршрутом о Хосе Рисале. Хорошо работает как центральная остановка исторической экскурсии.', 'A fortress inside Intramuros with gates, bastions and a Jose Rizal memorial route. It works as a central stop on a historic city tour.', 'Қақпалары, бастиондары және Хосе Рисал туралы мемориалдық маршруты бар Интрамурос ішіндегі қамал. Тарихи қалалық экскурсияның негізгі аялдамасы.', 14.59400000, 120.97030000, 'https://www.openstreetmap.org/search?query=Fort%20Santiago%20Manila', 'Fort_Santiago_Manila.jpg'),
    ('rizal-park', 'manila', 'PARK', 2, 'HOURS', 4.5, ARRAY['philippines', 'manila', 'rizal-park', 'luneta', 'park', 'history']::text[], 'Парк Рисаля', 'Rizal Park', 'Рисал паркі', 'Большой городской парк Лунета с монументом Хосе Рисаля, садами и открытыми прогулочными зонами. Удобен как спокойная связка между Интрамуросом и музейным кварталом.', 'A large Luneta city park with the Jose Rizal monument, gardens and open walking areas. It connects naturally with Intramuros and the museum district.', 'Хосе Рисал ескерткіші, бақтары және ашық серуен аймақтары бар үлкен Лунета қалалық паркі. Интрамурос пен музей ауданын табиғи байланыстырады.', 14.58260000, 120.97830000, 'https://www.openstreetmap.org/search?query=Rizal%20Park%20Manila', 'Rizal_Park_Manila.jpg'),
    ('national-museum-fine-arts', 'manila', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['philippines', 'manila', 'national-museum', 'fine-arts', 'museum', 'culture']::text[], 'Национальный музей изящных искусств', 'National Museum of Fine Arts', 'Ұлттық бейнелеу өнері музейі', 'Ключевой художественный музей Манилы с филиппинской живописью, скульптурой и национальными коллекциями. Хорошая indoor-точка для культурного маршрута.', 'A key Manila art museum with Filipino painting, sculpture and national collections. It is a useful indoor stop for culture-focused routes.', 'Филиппин кескіндемесі, мүсіні және ұлттық коллекциялары бар Маниланың негізгі өнер музейі. Мәдени маршруттарға пайдалы indoor аялдама.', 14.58690000, 120.98100000, 'https://www.openstreetmap.org/search?query=National%20Museum%20of%20Fine%20Arts%20Manila', 'National_Museum_of_Fine_Arts_(Manila).jpg'),
    ('national-museum-natural-history', 'manila', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['philippines', 'manila', 'natural-history', 'museum', 'family', 'indoor']::text[], 'Национальный музей естественной истории', 'National Museum of Natural History', 'Ұлттық табиғи тарих музейі', 'Музей о природе Филиппин, биоразнообразии и геологии в выразительном историческом здании. Подходит для семей и маршрутов в жару или дождь.', 'A museum about Philippine nature, biodiversity and geology in a striking historic building. It suits families and hot or rainy day routes.', 'Филиппин табиғаты, биоалуандығы және геологиясы туралы әсерлі тарихи ғимараттағы музей. Отбасыларға және ыстық не жаңбырлы күн маршруттарына сай.', 14.58310000, 120.98170000, 'https://www.openstreetmap.org/search?query=National%20Museum%20of%20Natural%20History%20Manila', 'National_Museum_of_Natural_History_Manila.jpg'),
    ('binondo-chinatown', 'manila', 'FOOD', 3, 'HOURS', 4.6, ARRAY['philippines', 'manila', 'binondo', 'chinatown', 'food', 'walk']::text[], 'Китайский квартал Бинондо', 'Binondo Chinatown', 'Бинондо Қытай кварталы', 'Старый китайский квартал Манилы с едой, храмами, рынками и насыщенными улицами. Это сильная точка для гастро-прогулок и повседневного городского ритма.', 'Manila old Chinatown with food, temples, markets and dense streets. It is a strong stop for food walks and everyday city rhythm.', 'Тағамы, храмдары, базарлары және тығыз көшелері бар Маниланың ескі Қытай кварталы. Гастро-серуен мен күнделікті қала ырғағына жақсы.', 14.60060000, 120.97460000, 'https://www.openstreetmap.org/search?query=Binondo%20Chinatown%20Manila', 'Binondo_Manila.jpg'),
    ('divisoria-market', 'manila', 'MARKET', 3, 'HOURS', 4.3, ARRAY['philippines', 'manila', 'divisoria', 'market', 'shopping', 'local']::text[], 'Рынок Дивисория', 'Divisoria Market', 'Дивисория базары', 'Крупная торговая зона Манилы с тканями, одеждой, сувенирами и плотным локальным потоком. Нужна как отдельный практичный shopping-сценарий, а не короткая остановка.', 'A large Manila trading area with fabrics, clothes, souvenirs and dense local flow. It works as a dedicated practical shopping scenario rather than a quick stop.', 'Маталары, киімі, сувенирлері және тығыз жергілікті ағыны бар Маниланың ірі сауда аймағы. Қысқа аялдама емес, жеке практикалық сауда сценарийі.', 14.60460000, 120.97370000, 'https://www.openstreetmap.org/search?query=Divisoria%20Market%20Manila', 'Divisoria_Market_Manila.jpg'),
    ('manila-ocean-park', 'manila', 'ENTERTAINMENT', 3, 'HOURS', 4.4, ARRAY['philippines', 'manila', 'ocean-park', 'aquarium', 'family', 'entertainment']::text[], 'Manila Ocean Park', 'Manila Ocean Park', 'Manila Ocean Park', 'Семейный океанариум и развлекательный комплекс у Манильского залива. Хорош для маршрутов с детьми и как indoor-альтернатива в плохую погоду.', 'A family aquarium and entertainment complex by Manila Bay. It is useful for routes with children and as an indoor alternative in bad weather.', 'Манила шығанағы жанындағы отбасылық океанариум және ойын-сауық кешені. Балалы маршруттарға және нашар ауа райында indoor баламаға ыңғайлы.', 14.57920000, 120.97260000, 'https://www.openstreetmap.org/search?query=Manila%20Ocean%20Park', 'Manila_Ocean_Park.jpg'),
    ('sm-mall-of-asia', 'manila', 'SHOPPING', 3, 'HOURS', 4.6, ARRAY['philippines', 'manila', 'sm-mall-of-asia', 'mall', 'shopping', 'bay']::text[], 'SM Mall of Asia', 'SM Mall of Asia', 'SM Mall of Asia', 'Один из крупнейших моллов Метро Манилы у залива с магазинами, ресторанами, развлечениями и набережной. Подходит для шопинга, еды и комфортной паузы.', 'One of Metro Manila largest bayside malls with shops, restaurants, entertainment and a promenade. It suits shopping, food and a comfortable pause.', 'Дүкендері, мейрамханалары, ойын-сауығы және набережнаясы бар Метро Маниланың ең ірі моллдарының бірі. Сауда, тамақ және жайлы үзіліске сай.', 14.53530000, 120.98200000, 'https://www.openstreetmap.org/search?query=SM%20Mall%20of%20Asia', 'SM_Mall_of_Asia.jpg'),
    ('ayala-museum', 'makati', 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['philippines', 'makati', 'ayala-museum', 'museum', 'history', 'culture']::text[], 'Музей Аяла', 'Ayala Museum', 'Аяла музейі', 'Современный музей в Макати о филиппинской истории, искусстве и культурной идентичности. Удобен как качественная indoor-точка рядом с деловым районом.', 'A modern Makati museum about Philippine history, art and cultural identity. It is a quality indoor stop near the business district.', 'Филиппин тарихы, өнері және мәдени бірегейлігі туралы Макатидегі заманауи музей. Іскерлік аудан жанындағы сапалы indoor аялдама.', 14.55360000, 121.02330000, 'https://www.openstreetmap.org/search?query=Ayala%20Museum%20Makati', 'Ayala_Museum.jpg'),
    ('greenbelt-makati', 'makati', 'SHOPPING', 2, 'HOURS', 4.5, ARRAY['philippines', 'makati', 'greenbelt', 'mall', 'shopping', 'food']::text[], 'Greenbelt Makati', 'Greenbelt Makati', 'Greenbelt Makati', 'Комплекс моллов и садов в Макати с ресторанами, магазинами и спокойными пешеходными связками. Хорош как премиальная городская точка без длинного трансфера.', 'A Makati mall-and-garden complex with restaurants, shops and calm walking links. It is a premium city stop without a long transfer.', 'Мейрамханалары, дүкендері және тыныш жаяу байланыстары бар Макатидегі молл-бақ кешені. Ұзақ трансферсіз премиум қалалық аялдама.', 14.55110000, 121.02060000, 'https://www.openstreetmap.org/search?query=Greenbelt%20Makati', 'Greenbelt_Makati.jpg'),
    ('bonifacio-high-street', 'taguig', 'SHOPPING', 2, 'HOURS', 4.5, ARRAY['philippines', 'taguig', 'bgc', 'bonifacio-high-street', 'shopping', 'walk']::text[], 'Bonifacio High Street', 'Bonifacio High Street', 'Bonifacio High Street', 'Пешеходная торгово-ресторанная зона BGC с магазинами, кафе, открытыми площадями и современным городским ритмом. Удобна для вечерних прогулок.', 'A walkable BGC shopping and dining district with stores, cafes, open plazas and a modern city rhythm. It is convenient for evening strolls.', 'Дүкендері, кафелері, ашық алаңдары және заманауи қала ырғағы бар BGC жаяу сауда-ресторан ауданы. Кешкі серуенге ыңғайлы.', 14.55090000, 121.05070000, 'https://www.openstreetmap.org/search?query=Bonifacio%20High%20Street%20Taguig', 'Bonifacio_Global_City.jpg'),
    ('venice-grand-canal-mall', 'taguig', 'SHOPPING', 2, 'HOURS', 4.3, ARRAY['philippines', 'taguig', 'venice-grand-canal', 'mall', 'shopping', 'photo']::text[], 'Venice Grand Canal Mall', 'Venice Grand Canal Mall', 'Venice Grand Canal Mall', 'Тематический молл в Тагиге с каналом, мостами, ресторанами и сильной фото-точкой. Подходит для легкого leisure-сценария в Метро Маниле.', 'A themed Taguig mall with a canal, bridges, restaurants and strong photo value. It works for an easy leisure scenario in Metro Manila.', 'Каналы, көпірлері, мейрамханалары және фото құндылығы бар Тагигтегі тақырыптық молл. Метро Маниладағы жеңіл leisure сценарийіне сай.', 14.53380000, 121.05170000, 'https://www.openstreetmap.org/search?query=Venice%20Grand%20Canal%20Mall%20Taguig', 'Venice_Grand_Canal_Mall.jpg'),
    ('taal-volcano-viewpoint', 'tagaytay', 'NATURE', 2, 'HOURS', 4.7, ARRAY['philippines', 'tagaytay', 'taal', 'volcano', 'lake', 'viewpoint']::text[], 'Смотровые площадки на вулкан Тааль', 'Taal Volcano Viewpoints', 'Тааль жанартауы көрініс алаңдары', 'Видовые точки Тагайтая на озеро и вулкан Тааль, популярные для коротких поездок из Манилы. Хорошо работают как мягкий day trip без сложной логистики.', 'Tagaytay viewpoints over Taal Lake and Volcano, popular for short trips from Manila. They work as an easy day trip without complex logistics.', 'Тааль көлі мен жанартауына қарайтын Тагайтай смотроваялары, Маниладан қысқа сапарларға танымал. Күрделі логистикасыз жеңіл day trip.', 14.09530000, 120.93900000, 'https://www.openstreetmap.org/search?query=Taal%20Volcano%20Viewpoint%20Tagaytay', 'Taal_Volcano_and_Lake.jpg'),
    ('sky-ranch-tagaytay', 'tagaytay', 'ENTERTAINMENT', 2, 'HOURS', 4.3, ARRAY['philippines', 'tagaytay', 'sky-ranch', 'theme-park', 'family', 'view']::text[], 'Sky Ranch Tagaytay', 'Sky Ranch Tagaytay', 'Sky Ranch Tagaytay', 'Семейный парк аттракционов в Тагайтае с колесом обозрения и видом на озеро Тааль. Удобен как легкая остановка после обзорных площадок.', 'A family amusement park in Tagaytay with a Ferris wheel and views toward Taal Lake. It is an easy stop after viewpoints.', 'Тааль көліне қарайтын дөңгелегі бар Тагайтайдағы отбасылық аттракциондар паркі. Смотроваялардан кейін жеңіл аялдама.', 14.09360000, 120.93370000, 'https://www.openstreetmap.org/search?query=Sky%20Ranch%20Tagaytay', 'Sky_Ranch_Tagaytay.jpg'),

    ('magellans-cross', 'cebu-city', 'ARCHITECTURE', 1, 'HOURS', 4.5, ARRAY['philippines', 'cebu', 'magellans-cross', 'history', 'landmark']::text[], 'Крест Магеллана', 'Magellan''s Cross', 'Магеллан кресі', 'Историческая часовня в центре Себу с крестом, связанным с ранней испанской эпохой. Это короткая, но обязательная остановка городского маршрута.', 'A historic chapel in central Cebu with a cross tied to the early Spanish period. It is a short but essential city-route stop.', 'Ерте испан дәуірімен байланысты кресті бар Себу орталығындағы тарихи капелла. Қысқа, бірақ қалалық маршруттағы міндетті аялдама.', 10.29370000, 123.90210000, 'https://www.openstreetmap.org/search?query=Magellan%27s%20Cross%20Cebu', 'Magellan%27s_Cross_Cebu.jpg'),
    ('basilica-santo-nino', 'cebu-city', 'TEMPLE', 1, 'HOURS', 4.6, ARRAY['philippines', 'cebu', 'santo-nino', 'basilica', 'church', 'history']::text[], 'Базилика Миноре дель Санто-Ниньо', 'Basilica Minore del Santo Nino', 'Санто-Ниньо базиликасы', 'Одна из важнейших церквей Филиппин и духовный центр старого Себу. Хорошо объединяется с Крестом Магеллана и Фортом Сан-Педро.', 'One of the Philippines most important churches and the spiritual center of old Cebu. It pairs naturally with Magellan''s Cross and Fort San Pedro.', 'Филиппиндегі маңызды шіркеулердің бірі және ескі Себудың рухани орталығы. Магеллан кресі және Сан-Педро фортымен жақсы үйлеседі.', 10.29440000, 123.90220000, 'https://www.openstreetmap.org/search?query=Basilica%20Minore%20del%20Santo%20Nino%20Cebu', 'Basilica_Minore_del_Santo_Ni%C3%B1o_Cebu.jpg'),
    ('fort-san-pedro-cebu', 'cebu-city', 'ARCHITECTURE', 1, 'HOURS', 4.4, ARRAY['philippines', 'cebu', 'fort-san-pedro', 'fort', 'history', 'architecture']::text[], 'Форт Сан-Педро', 'Fort San Pedro', 'Сан-Педро форты', 'Испанский каменный форт у порта Себу с небольшим музеем и прогулкой по стенам. Это компактная историческая точка рядом с центром.', 'A Spanish stone fort near Cebu port with a small museum and wall walk. It is a compact historic stop near the center.', 'Шағын музейі және қабырға бойымен серуені бар Себу порты жанындағы испан тас форты. Орталыққа жақын ықшам тарихи аялдама.', 10.29260000, 123.90580000, 'https://www.openstreetmap.org/search?query=Fort%20San%20Pedro%20Cebu', 'Fort_San_Pedro_Cebu.jpg'),
    ('sirao-garden', 'cebu-city', 'PARK', 2, 'HOURS', 4.4, ARRAY['philippines', 'cebu', 'sirao-garden', 'flowers', 'view', 'family']::text[], 'Сад Сирао', 'Sirao Garden', 'Сирао бағы', 'Горный цветочный сад над Себу с яркими фотозонами и видами. Хорош для легкого маршрута по холмам вместе с Temple of Leah и Tops.', 'A hill flower garden above Cebu with bright photo zones and views. It fits an easy upland route with Temple of Leah and Tops.', 'Себу үстіндегі жарқын фото-аймақтары және көріністері бар тау гүл бағы. Temple of Leah және Tops-пен бірге жеңіл тау маршрутына сай.', 10.39890000, 123.86880000, 'https://www.openstreetmap.org/search?query=Sirao%20Garden%20Cebu', 'Sirao_Flower_Garden_Cebu.jpg'),
    ('temple-of-leah', 'cebu-city', 'ARCHITECTURE', 1, 'HOURS', 4.3, ARRAY['philippines', 'cebu', 'temple-of-leah', 'architecture', 'view', 'photo']::text[], 'Temple of Leah', 'Temple of Leah', 'Temple of Leah', 'Монументальный комплекс на холмах Себу с колоннами, статуями и панорамными видами. Популярен как фото-точка и короткая остановка на upland-маршруте.', 'A monumental hill complex in Cebu with columns, statues and panoramic views. It is popular as a photo stop on upland routes.', 'Себу төбелеріндегі бағандары, мүсіндері және панорамалық көріністері бар монументалды кешен. Upland маршрутындағы фото аялдамаға танымал.', 10.36590000, 123.87380000, 'https://www.openstreetmap.org/search?query=Temple%20of%20Leah%20Cebu', 'Temple_of_Leah_Cebu.jpg'),
    ('cebu-taoist-temple', 'cebu-city', 'TEMPLE', 1, 'HOURS', 4.4, ARRAY['philippines', 'cebu', 'taoist-temple', 'temple', 'view', 'culture']::text[], 'Даосский храм Себу', 'Cebu Taoist Temple', 'Себу даос храмы', 'Храмовый комплекс в районе Beverly Hills с лестницами, пагодами и видом на город. Хорош как культурная и визуальная остановка в Себу.', 'A temple complex in Beverly Hills with stairways, pagodas and city views. It works as a cultural and visual stop in Cebu.', 'Beverly Hills ауданындағы баспалдақтары, пагодалары және қала көрінісі бар храм кешені. Себудағы мәдени әрі визуалды аялдама.', 10.34350000, 123.88640000, 'https://www.openstreetmap.org/search?query=Cebu%20Taoist%20Temple', 'Cebu_Taoist_Temple.jpg'),
    ('carbon-market', 'cebu-city', 'MARKET', 2, 'HOURS', 4.3, ARRAY['philippines', 'cebu', 'carbon-market', 'market', 'food', 'local']::text[], 'Рынок Карбон', 'Carbon Market', 'Карбон базары', 'Один из старейших и самых оживленных рынков Себу с продуктами, едой и локальной торговлей. Подходит для гастро-маршрутов и живого городского опыта.', 'One of Cebu oldest and busiest markets, with produce, food and local trade. It suits food routes and lived city experience.', 'Өнімдері, тағамы және жергілікті саудасы бар Себудың ең ескі әрі қызу базарларының бірі. Гастро маршруттар мен шынайы қала тәжірибесіне сай.', 10.29340000, 123.89750000, 'https://www.openstreetmap.org/search?query=Carbon%20Market%20Cebu', 'Carbon_Market_Cebu.jpg'),
    ('ayala-center-cebu', 'cebu-city', 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['philippines', 'cebu', 'ayala-center', 'mall', 'shopping', 'food']::text[], 'Ayala Center Cebu', 'Ayala Center Cebu', 'Ayala Center Cebu', 'Крупный молл Себу с магазинами, ресторанами и зеленой центральной зоной. Удобен как сервисная и вечерняя точка после экскурсий.', 'A major Cebu mall with shops, restaurants and a green central area. It is a practical service and evening stop after tours.', 'Дүкендері, мейрамханалары және жасыл орталық аймағы бар Себудың ірі моллы. Экскурсиялардан кейінгі практикалық әрі кешкі аялдама.', 10.31720000, 123.90540000, 'https://www.openstreetmap.org/search?query=Ayala%20Center%20Cebu', 'Ayala_Center_Cebu.jpg'),
    ('sm-seaside-city-cebu', 'cebu-city', 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['philippines', 'cebu', 'sm-seaside', 'mall', 'shopping', 'family']::text[], 'SM Seaside City Cebu', 'SM Seaside City Cebu', 'SM Seaside City Cebu', 'Большой молл у побережья Себу с магазинами, ресторанами и семейными развлечениями. Хорош для indoor-сценария в жару или дождь.', 'A large seaside Cebu mall with shops, restaurants and family entertainment. It is useful as an indoor scenario for hot or rainy days.', 'Дүкендері, мейрамханалары және отбасылық ойын-сауығы бар Себудың жағалаудағы үлкен моллы. Ыстық не жаңбырлы күндегі indoor сценарийге пайдалы.', 10.28100000, 123.88170000, 'https://www.openstreetmap.org/search?query=SM%20Seaside%20City%20Cebu', 'SM_Seaside_City_Cebu.jpg'),
    ('mactan-shrine', 'mactan', 'ARCHITECTURE', 1, 'HOURS', 4.3, ARRAY['philippines', 'mactan', 'mactan-shrine', 'lapu-lapu', 'history']::text[], 'Святилище Мактан', 'Mactan Shrine', 'Мактан мемориалы', 'Мемориальный парк на Мактане, связанный с Лапу-Лапу и битвой при Мактане. Удобен для короткой исторической остановки рядом с курортами и аэропортом.', 'A Mactan memorial park tied to Lapu-Lapu and the Battle of Mactan. It is an easy historic stop near resorts and the airport.', 'Лапу-Лапу және Мактан шайқасымен байланысты Мактан мемориалдық паркі. Курорттар мен әуежай маңындағы жеңіл тарихи аялдама.', 10.31190000, 124.01540000, 'https://www.openstreetmap.org/search?query=Mactan%20Shrine', 'Mactan_Shrine.jpg'),
    ('ten-thousand-roses', 'mactan', 'ENTERTAINMENT', 1, 'HOURS', 4.2, ARRAY['philippines', 'mactan', '10000-roses', 'photo', 'family', 'cafe']::text[], '10,000 Roses Cafe', '10,000 Roses Cafe', '10,000 Roses Cafe', 'Фотолокация и кафе в Кордове с LED-розами и видом на воду. Подходит для легкой вечерней остановки в районе Мактан.', 'A Cordova photo spot and cafe with LED roses and water views. It suits an easy evening stop in the Mactan area.', 'LED раушандары және су көрінісі бар Кордовадағы фото орын және кафе. Мактан ауданындағы жеңіл кешкі аялдамаға сай.', 10.25560000, 123.94950000, 'https://www.openstreetmap.org/search?query=10000%20Roses%20Cafe%20Cebu', '10000_Roses_Cafe_Cebu.jpg'),
    ('chocolate-hills', 'bohol', 'NATURE', 3, 'HOURS', 4.8, ARRAY['philippines', 'bohol', 'chocolate-hills', 'nature', 'viewpoint', 'unesco']::text[], 'Шоколадные холмы', 'Chocolate Hills', 'Шоколад төбелері', 'Самый узнаваемый природный ландшафт Бохола с сотнями округлых холмов и обзорными площадками. Это основной якорь сухопутного маршрута по острову.', 'Bohol most recognizable natural landscape, with hundreds of rounded hills and viewpoints. It is the core inland route anchor on the island.', 'Жүздеген домалақ төбелері және смотроваялары бар Бохолдың ең танымал табиғи ландшафты. Аралдағы ішкі маршруттың негізгі нысаны.', 9.82970000, 124.13970000, 'https://www.openstreetmap.org/search?query=Chocolate%20Hills%20Bohol', 'Chocolate_Hills_Bohol.jpg'),
    ('philippine-tarsier-sanctuary', 'bohol', 'PARK', 1, 'HOURS', 4.5, ARRAY['philippines', 'bohol', 'tarsier', 'wildlife', 'sanctuary', 'family']::text[], 'Заповедник филиппинских долгопятов', 'Philippine Tarsier Sanctuary', 'Филиппин долгопяттары қорығы', 'Небольшой природоохранный центр, где можно увидеть долгопятов в спокойной лесной среде. Важно посещать его тихо и без вспышек.', 'A small conservation center where visitors can see tarsiers in a calm forest setting. It should be visited quietly and without flash.', 'Тыныш орман ортасында долгопяттарды көруге болатын шағын табиғатты қорғау орталығы. Оны тыныш және жарқылсыз көру маңызды.', 9.78190000, 123.89270000, 'https://www.openstreetmap.org/search?query=Philippine%20Tarsier%20Sanctuary%20Bohol', 'Philippine_Tarsier_Sanctuary.jpg'),
    ('loboc-river', 'bohol', 'NATURE', 2, 'HOURS', 4.5, ARRAY['philippines', 'bohol', 'loboc-river', 'river', 'cruise', 'food']::text[], 'Река Лобок', 'Loboc River', 'Лобок өзені', 'Зеленая река Бохола, популярная для спокойных круизов, обедов на лодках и коротких природных маршрутов. Хорошо дополняет поездку к Шоколадным холмам.', 'A green Bohol river popular for relaxed cruises, boat lunches and short nature routes. It pairs well with the Chocolate Hills trip.', 'Тыныш круиздерге, қайықтағы түскі асқа және қысқа табиғи маршруттарға танымал Бохолдың жасыл өзені. Шоколад төбелері сапарын жақсы толықтырады.', 9.63760000, 124.03050000, 'https://www.openstreetmap.org/search?query=Loboc%20River%20Bohol', 'Loboc_River_Bohol.jpg'),
    ('alona-beach', 'bohol', 'BEACH', 3, 'HOURS', 4.4, ARRAY['philippines', 'bohol', 'panglao', 'alona-beach', 'beach', 'resort']::text[], 'Пляж Алона', 'Alona Beach', 'Алона жағажайы', 'Главный туристический пляж Панглао с отелями, ресторанами, дайв-центрами и вечерней инфраструктурой. Подходит как база для морских экскурсий.', 'Panglao main tourist beach, with hotels, restaurants, dive centers and evening infrastructure. It works as a base for sea trips.', 'Қонақүйлері, мейрамханалары, дайв-орталықтары және кешкі инфрақұрылымы бар Панглаоның негізгі туристік жағажайы. Теңіз экскурсияларының базасына сай.', 9.54880000, 123.77100000, 'https://www.openstreetmap.org/search?query=Alona%20Beach%20Bohol', 'Alona_Beach_Bohol.jpg'),
    ('balicasag-island', 'bohol', 'BEACH', 5, 'HOURS', 4.7, ARRAY['philippines', 'bohol', 'balicasag', 'island', 'snorkeling', 'beach']::text[], 'Остров Баликасаг', 'Balicasag Island', 'Баликасаг аралы', 'Морской day trip рядом с Панглао, известный снорклингом, черепахами и коралловыми участками. Требует аккуратного отношения к морской среде.', 'A sea day trip near Panglao, known for snorkeling, turtles and coral areas. It requires careful treatment of the marine environment.', 'Снорклинг, тасбақалар және маржан аймақтарымен белгілі Панглао маңындағы теңіз day trip. Теңіз ортасына ұқыпты қарауды қажет етеді.', 9.51730000, 123.68050000, 'https://www.openstreetmap.org/search?query=Balicasag%20Island%20Bohol', 'Balicasag_Island_Bohol.jpg'),

    ('puerto-princesa-underground-river', 'puerto-princesa', 'NATURE', 5, 'HOURS', 4.8, ARRAY['philippines', 'palawan', 'puerto-princesa', 'underground-river', 'unesco', 'nature']::text[], 'Подземная река Пуэрто-Принсеса', 'Puerto Princesa Subterranean River National Park', 'Пуэрто-Принсеса жер асты өзені', 'Национальный парк с известной подземной рекой, пещерными залами и лодочным маршрутом. Это главный природный якорь Пуэрто-Принсесы.', 'A national park with a famous underground river, cave chambers and boat route. It is Puerto Princesa main nature anchor.', 'Әйгілі жер асты өзені, үңгір залдары және қайық маршруты бар ұлттық парк. Пуэрто-Принсесаның басты табиғи нысаны.', 10.19530000, 118.92670000, 'https://www.openstreetmap.org/search?query=Puerto%20Princesa%20Underground%20River', 'Puerto_Princesa_Underground_River.jpg'),
    ('honda-bay', 'puerto-princesa', 'BEACH', 5, 'HOURS', 4.5, ARRAY['philippines', 'palawan', 'puerto-princesa', 'honda-bay', 'island-hopping', 'beach']::text[], 'Залив Хонда', 'Honda Bay', 'Хонда шығанағы', 'Близкая к Пуэрто-Принсесе зона island hopping с пляжами, снорклингом и короткими морскими переездами. Хороша для первого пляжного дня на Палаване.', 'An island-hopping area close to Puerto Princesa, with beaches, snorkeling and short boat transfers. It is useful for a first Palawan beach day.', 'Пуэрто-Принсесаға жақын жағажайлары, снорклингі және қысқа теңіз өтулері бар island hopping аймағы. Палавандағы алғашқы жағажай күніне жақсы.', 9.98330000, 118.81670000, 'https://www.openstreetmap.org/search?query=Honda%20Bay%20Puerto%20Princesa', 'Honda_Bay_Palawan.jpg'),
    ('nagtabon-beach', 'puerto-princesa', 'BEACH', 3, 'HOURS', 4.5, ARRAY['philippines', 'palawan', 'puerto-princesa', 'nagtabon', 'beach', 'sunset']::text[], 'Пляж Нагтабон', 'Nagtabon Beach', 'Нагтабон жағажайы', 'Западный пляж Пуэрто-Принсесы с более спокойной атмосферой, широким берегом и горными видами. Подходит для неспешной поездки за город.', 'A west-coast Puerto Princesa beach with a calmer atmosphere, broad shore and mountain views. It suits an unhurried trip outside the city.', 'Тыныш атмосферасы, кең жағалауы және тау көріністері бар Пуэрто-Принсесаның батыс жағажайы. Қала сыртындағы асықпай сапарға сай.', 9.87680000, 118.65060000, 'https://www.openstreetmap.org/search?query=Nagtabon%20Beach%20Palawan', 'Nagtabon_Beach_Palawan.jpg'),
    ('palawan-wildlife-rescue-center', 'puerto-princesa', 'PARK', 1, 'HOURS', 4.2, ARRAY['philippines', 'palawan', 'wildlife', 'conservation', 'family', 'park']::text[], 'Центр спасения дикой природы Палавана', 'Palawan Wildlife Rescue and Conservation Center', 'Палаван жабайы табиғатты құтқару орталығы', 'Природоохранный центр с филиппинскими крокодилами и другими местными видами. Хорош как короткая семейная остановка в городском туре.', 'A conservation center with Philippine crocodiles and other local species. It is a short family-friendly stop on a city tour.', 'Филиппин қолтырауындары және басқа жергілікті түрлері бар табиғатты қорғау орталығы. Қалалық турдағы қысқа отбасылық аялдама.', 9.78360000, 118.73500000, 'https://www.openstreetmap.org/search?query=Palawan%20Wildlife%20Rescue%20and%20Conservation%20Center', 'Palawan_Wildlife_Rescue_and_Conservation_Center.jpg'),
    ('big-lagoon-el-nido', 'el-nido', 'NATURE', 3, 'HOURS', 4.8, ARRAY['philippines', 'palawan', 'el-nido', 'big-lagoon', 'lagoon', 'kayak']::text[], 'Большая лагуна Эль-Нидо', 'Big Lagoon', 'Эль-Нидо Үлкен лагунасы', 'Бирюзовая лагуна Бакит-Бэй среди известняковых скал, обычно исследуемая на лодке или каяке. Это один из главных символов Эль-Нидо.', 'A turquoise Bacuit Bay lagoon among limestone cliffs, usually explored by boat or kayak. It is one of El Nido main symbols.', 'Әктас жартастар арасындағы Бакит-Бэйдің көгілдір лагунасы, әдетте қайықпен немесе каякпен зерттеледі. Эль-Нидоның басты символдарының бірі.', 11.15200000, 119.32200000, 'https://www.openstreetmap.org/search?query=Big%20Lagoon%20El%20Nido', 'Big_Lagoon_El_Nido.jpg'),
    ('nacpan-beach', 'el-nido', 'BEACH', 4, 'HOURS', 4.7, ARRAY['philippines', 'palawan', 'el-nido', 'nacpan-beach', 'beach', 'sunset']::text[], 'Пляж Накпан', 'Nacpan Beach', 'Накпан жағажайы', 'Длинный песчаный пляж к северу от Эль-Нидо с плавным берегом и расслабленным дневным форматом. Хорош для отдыха вне плотного island hopping.', 'A long sandy beach north of El Nido with a gentle shore and relaxed daytime format. It works for downtime outside dense island hopping.', 'Эль-Нидодан солтүстікке қарай ұзын құмды жағажай, жайлы жағалауы және тыныш күндізгі форматы бар. Тығыз island hopping-тен тыс демалысқа жақсы.', 11.32090000, 119.42570000, 'https://www.openstreetmap.org/search?query=Nacpan%20Beach%20El%20Nido', 'Nacpan_Beach_El_Nido.jpg'),
    ('seven-commandos-beach', 'el-nido', 'BEACH', 2, 'HOURS', 4.6, ARRAY['philippines', 'palawan', 'el-nido', 'seven-commandos', 'beach', 'island-hopping']::text[], 'Пляж Seven Commandos', 'Seven Commandos Beach', 'Seven Commandos жағажайы', 'Белый пляж рядом с Эль-Нидо, часто используемый как расслабленная остановка в island hopping маршрутах. Подходит для плавания и мягкого завершения тура.', 'A white beach near El Nido, often used as a relaxed stop on island-hopping routes. It suits swimming and a gentle tour ending.', 'Эль-Нидо маңындағы ақ жағажай, island hopping маршруттарындағы тыныш аялдама ретінде жиі қолданылады. Жүзуге және турды жұмсақ аяқтауға сай.', 11.17000000, 119.38500000, 'https://www.openstreetmap.org/search?query=Seven%20Commandos%20Beach%20El%20Nido', 'Seven_Commandos_Beach_El_Nido.jpg'),
    ('hidden-beach-el-nido', 'el-nido', 'BEACH', 2, 'HOURS', 4.7, ARRAY['philippines', 'palawan', 'el-nido', 'hidden-beach', 'beach', 'limestone']::text[], 'Скрытый пляж Эль-Нидо', 'Hidden Beach', 'Эль-Нидо Жасырын жағажайы', 'Укрытый известняковыми стенами пляж, куда заходят через узкий проход на морских турах. Ценится за закрытую природную атмосферу.', 'A beach enclosed by limestone walls and entered through a narrow opening on sea tours. It is valued for its sheltered natural atmosphere.', 'Әктас қабырғаларымен қоршалған және теңіз турларында тар өткел арқылы кіретін жағажай. Жабық табиғи атмосферасымен бағаланады.', 11.17800000, 119.30300000, 'https://www.openstreetmap.org/search?query=Hidden%20Beach%20El%20Nido', 'Hidden_Beach_El_Nido.jpg'),
    ('kayangan-lake', 'coron', 'NATURE', 3, 'HOURS', 4.8, ARRAY['philippines', 'palawan', 'coron', 'kayangan-lake', 'lake', 'viewpoint']::text[], 'Озеро Каянган', 'Kayangan Lake', 'Каянган көлі', 'Прозрачное озеро Корона с известной смотровой площадкой и известняковым окружением. Это главная природная точка классического тура по Корону.', 'A clear Coron lake with a famous viewpoint and limestone setting. It is the main natural stop on classic Coron tours.', 'Әйгілі смотроваясы және әктас ортасы бар Коронның мөлдір көлі. Корон бойынша классикалық турдың басты табиғи аялдамасы.', 11.95540000, 120.22450000, 'https://www.openstreetmap.org/search?query=Kayangan%20Lake%20Coron', 'Kayangan_Lake_Coron.jpg'),
    ('twin-lagoon', 'coron', 'NATURE', 3, 'HOURS', 4.8, ARRAY['philippines', 'palawan', 'coron', 'twin-lagoon', 'lagoon', 'swim']::text[], 'Двойная лагуна', 'Twin Lagoon', 'Қос лагуна', 'Две лагуны Корона, соединенные узким проходом между известняковыми скалами. Хороши для плавания, каяка и яркого морского маршрута.', 'Two Coron lagoons connected by a narrow opening between limestone cliffs. They are strong for swimming, kayaking and scenic sea routes.', 'Әктас жартастар арасындағы тар өткелмен қосылған Коронның екі лагунасы. Жүзу, каяк және әсерлі теңіз маршрутына жақсы.', 11.95100000, 120.21690000, 'https://www.openstreetmap.org/search?query=Twin%20Lagoon%20Coron', 'Twin_Lagoon_Coron.jpg'),
    ('barracuda-lake', 'coron', 'NATURE', 2, 'HOURS', 4.7, ARRAY['philippines', 'palawan', 'coron', 'barracuda-lake', 'lake', 'diving']::text[], 'Озеро Барракуда', 'Barracuda Lake', 'Барракуда көлі', 'Известняковое озеро Корона с очень прозрачной водой, скалами и необычными температурными слоями. Подходит для снорклинга, дайвинга и природного маршрута.', 'A Coron limestone lake with very clear water, rock walls and unusual temperature layers. It suits snorkeling, diving and nature routes.', 'Өте мөлдір суы, жартастары және ерекше температура қабаттары бар Корон әктас көлі. Снорклинг, дайвинг және табиғи маршруттарға сай.', 11.95060000, 120.22940000, 'https://www.openstreetmap.org/search?query=Barracuda%20Lake%20Coron', 'Barracuda_Lake_Coron.jpg'),
    ('mount-tapyas', 'coron', 'NATURE', 1, 'HOURS', 4.6, ARRAY['philippines', 'palawan', 'coron', 'mount-tapyas', 'viewpoint', 'sunset']::text[], 'Гора Тапьяс', 'Mount Tapyas', 'Тапьяс тауы', 'Смотровая гора над городом Корон, куда поднимаются по лестнице ради панорамы и заката. Хорошая короткая активность без лодки.', 'A viewpoint hill above Coron town, reached by stairs for panorama and sunset. It is a good short non-boat activity.', 'Панорама және күн батуы үшін баспалдақпен көтерілетін Корон қаласы үстіндегі смотровая тау. Қайықсыз қысқа белсенділікке жақсы.', 11.99970000, 120.19670000, 'https://www.openstreetmap.org/search?query=Mount%20Tapyas%20Coron', 'Mount_Tapyas_Coron.jpg'),
    ('maquinit-hot-spring', 'coron', 'NATURE', 2, 'HOURS', 4.4, ARRAY['philippines', 'palawan', 'coron', 'maquinit-hot-spring', 'hot-spring', 'evening']::text[], 'Горячие источники Макинит', 'Maquinit Hot Spring', 'Макинит ыстық бұлақтары', 'Соленые горячие источники у мангров и моря рядом с Короном. Обычно подходят для расслабленного вечера после island hopping.', 'Saltwater hot springs by mangroves and the sea near Coron. They usually fit a relaxed evening after island hopping.', 'Корон маңындағы мангрлар мен теңіз жанындағы тұзды ыстық бұлақтар. Island hopping-тен кейінгі тыныш кешке сай.', 12.00220000, 120.23690000, 'https://www.openstreetmap.org/search?query=Maquinit%20Hot%20Spring%20Coron', 'Maquinit_Hot_Spring_Coron.jpg'),
    ('malcapuya-island', 'coron', 'BEACH', 5, 'HOURS', 4.7, ARRAY['philippines', 'palawan', 'coron', 'malcapuya', 'island', 'beach']::text[], 'Остров Малкапуя', 'Malcapuya Island', 'Малкапуя аралы', 'Белопесчаный островной day trip из Корона с пляжем, плаванием и спокойным морским форматом. Хорош для туристов, которым нужен именно пляжный день.', 'A white-sand island day trip from Coron, with beach, swimming and a relaxed sea format. It suits travelers who want a dedicated beach day.', 'Короннан ақ құмды арал day trip, жағажайы, жүзуі және тыныш теңіз форматы бар. Нақты жағажай күнін қалайтын туристерге сай.', 11.81250000, 120.11750000, 'https://www.openstreetmap.org/search?query=Malcapuya%20Island%20Coron', 'Malcapuya_Island_Coron.jpg'),

    ('white-beach-boracay', 'boracay', 'BEACH', 4, 'HOURS', 4.8, ARRAY['philippines', 'boracay', 'white-beach', 'beach', 'sunset', 'resort']::text[], 'Белый пляж Боракая', 'White Beach', 'Боракай Ақ жағажайы', 'Главный пляж Боракая с длинной белой береговой линией, закатами, отелями и ресторанами. Это основной островной якорь для большинства туристов.', 'Boracay main beach, with a long white shoreline, sunsets, hotels and restaurants. It is the island core anchor for most travelers.', 'Ұзын ақ жағалауы, күн батуы, қонақүйлері және мейрамханалары бар Боракайдың басты жағажайы. Көп турист үшін аралдың негізгі нысаны.', 11.96240000, 121.92450000, 'https://www.openstreetmap.org/search?query=White%20Beach%20Boracay', 'White_Beach_Boracay.jpg'),
    ('puka-shell-beach', 'boracay', 'BEACH', 3, 'HOURS', 4.5, ARRAY['philippines', 'boracay', 'puka-beach', 'beach', 'quiet', 'north']::text[], 'Пляж Пука Шелл', 'Puka Shell Beach', 'Пука Шелл жағажайы', 'Северный пляж Боракая с более спокойной атмосферой и крупным песком с ракушками. Хорош как альтернатива оживленному White Beach.', 'A northern Boracay beach with a calmer atmosphere and coarser shell-mixed sand. It is a useful alternative to busy White Beach.', 'Тыныш атмосферасы және ракушка аралас ірі құмы бар Боракайдың солтүстік жағажайы. Қызу White Beach-ке жақсы балама.', 11.99860000, 121.91680000, 'https://www.openstreetmap.org/search?query=Puka%20Shell%20Beach%20Boracay', 'Puka_Shell_Beach_Boracay.jpg'),
    ('bulabog-beach', 'boracay', 'BEACH', 3, 'HOURS', 4.4, ARRAY['philippines', 'boracay', 'bulabog-beach', 'kitesurfing', 'beach', 'sports']::text[], 'Пляж Булабог', 'Bulabog Beach', 'Булабог жағажайы', 'Восточный пляж Боракая, известный ветром, кайтсерфингом и более спортивной атмосферой. Нужен для активного островного сценария.', 'Boracay east-side beach, known for wind, kitesurfing and a sportier atmosphere. It supports an active island scenario.', 'Желі, кайтсерфингі және спорттық атмосферасымен белгілі Боракайдың шығыс жағажайы. Белсенді арал сценарийіне керек.', 11.96310000, 121.92940000, 'https://www.openstreetmap.org/search?query=Bulabog%20Beach%20Boracay', 'Bulabog_Beach_Boracay.jpg'),
    ('willys-rock', 'boracay', 'NATURE', 1, 'HOURS', 4.5, ARRAY['philippines', 'boracay', 'willys-rock', 'landmark', 'photo', 'beach']::text[], 'Скала Вилли', 'Willy''s Rock', 'Willy''s Rock', 'Небольшая скала с религиозной статуей прямо у White Beach. Это одна из самых узнаваемых фото-точек Боракая.', 'A small rock with a religious statue directly by White Beach. It is one of Boracay most recognizable photo spots.', 'White Beach жанындағы діни мүсіні бар шағын тас. Боракайдың ең танымал фото нүктелерінің бірі.', 11.97010000, 121.91860000, 'https://www.openstreetmap.org/search?query=Willy%27s%20Rock%20Boracay', 'Willy%27s_Rock_Boracay.jpg'),
    ('dmall-boracay', 'boracay', 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['philippines', 'boracay', 'dmall', 'shopping', 'food', 'station-2']::text[], 'D''Mall Boracay', 'D''Mall Boracay', 'D''Mall Boracay', 'Центральная открытая торгово-ресторанная зона Боракая у Station 2. Удобна для встреч, еды, сувениров и сервисных задач туриста.', 'Boracay central open-air shopping and dining area near Station 2. It is useful for meeting, food, souvenirs and practical traveler needs.', 'Station 2 маңындағы Боракайдың орталық ашық сауда-ресторан аймағы. Кездесу, тамақ, сувенир және туристің практикалық істеріне ыңғайлы.', 11.96190000, 121.92520000, 'https://www.openstreetmap.org/search?query=D%27Mall%20Boracay', 'D%27Mall_Boracay.jpg'),
    ('dtalipapa-market', 'boracay', 'MARKET', 2, 'HOURS', 4.3, ARRAY['philippines', 'boracay', 'dtalipapa', 'market', 'seafood', 'food']::text[], 'Рынок D''Talipapa', 'D''Talipapa Market', 'D''Talipapa базары', 'Рынок морепродуктов и paluto-зона, где туристы покупают продукты и отдают их приготовить рядом. Хорош для гастро-сценария на острове.', 'A seafood market and paluto area where travelers buy seafood and have it cooked nearby. It works for an island food scenario.', 'Туристер теңіз өнімдерін сатып алып, жанында пісіртетін seafood market және paluto аймағы. Аралдағы гастро сценарийге жақсы.', 11.95900000, 121.92900000, 'https://www.openstreetmap.org/search?query=D%27Talipapa%20Market%20Boracay', 'D%27Talipapa_Market_Boracay.jpg'),
    ('iloilo-river-esplanade', 'iloilo', 'PARK', 2, 'HOURS', 4.5, ARRAY['philippines', 'iloilo', 'river-esplanade', 'park', 'walk', 'sunset']::text[], 'Набережная реки Илоило', 'Iloilo River Esplanade', 'Илоило өзені набережнаясы', 'Длинная городская набережная для прогулок, бега, велосипедов и закатных видов. Это понятный urban-парк для знакомства с современным Илоило.', 'A long urban riverside promenade for walking, jogging, cycling and sunset views. It is an easy urban-park introduction to modern Iloilo.', 'Серуен, жүгіру, велосипед және күн батуы үшін ұзын қалалық өзен набережнаясы. Заманауи Илоиломен танысуға жеңіл urban-парк.', 10.70730000, 122.54680000, 'https://www.openstreetmap.org/search?query=Iloilo%20River%20Esplanade', 'Iloilo_River_Esplanade.jpg'),
    ('molo-church', 'iloilo', 'ARCHITECTURE', 1, 'HOURS', 4.5, ARRAY['philippines', 'iloilo', 'molo-church', 'church', 'heritage', 'architecture']::text[], 'Церковь Моло', 'Molo Church', 'Моло шіркеуі', 'Историческая церковь Илоило с готико-ренессансными мотивами и узнаваемым фасадом. Хорошо подходит для короткой heritage-остановки.', 'A historic Iloilo church with Gothic-Renaissance motifs and a recognizable facade. It works for a short heritage stop.', 'Готика-ренессанс мотивтері және танымал фасады бар Илоилоның тарихи шіркеуі. Қысқа heritage аялдамаға жақсы.', 10.69530000, 122.54620000, 'https://www.openstreetmap.org/search?query=Molo%20Church%20Iloilo', 'Molo_Church_Iloilo.jpg'),
    ('calle-real-iloilo', 'iloilo', 'ARCHITECTURE', 2, 'HOURS', 4.4, ARRAY['philippines', 'iloilo', 'calle-real', 'heritage', 'walk', 'architecture']::text[], 'Калье Реаль в Илоило', 'Calle Real Iloilo', 'Илоило Калье Реаль', 'Историческая улица центра Илоило с коммерческими зданиями испанской и американской эпох. Подходит для неспешной городской прогулки.', 'A historic downtown Iloilo street with Spanish and American-era commercial buildings. It suits an unhurried city walk.', 'Испан және америкалық дәуірдегі сауда ғимараттары бар Илоило орталығының тарихи көшесі. Асықпай қалалық серуенге сай.', 10.69640000, 122.56950000, 'https://www.openstreetmap.org/search?query=Calle%20Real%20Iloilo', 'Calle_Real_Iloilo.jpg'),
    ('la-paz-public-market', 'iloilo', 'MARKET', 1, 'HOURS', 4.4, ARRAY['philippines', 'iloilo', 'la-paz-public-market', 'market', 'food', 'batchoy']::text[], 'Общественный рынок Ла-Пас', 'La Paz Public Market', 'Ла-Пас қоғамдық базары', 'Классический рынок Илоило, связанный с La Paz batchoy и локальной кухней. Хорош для короткого гастро-маршрута без туристической полировки.', 'A classic Iloilo market tied to La Paz batchoy and local food culture. It works for a short food route without a polished tourist layer.', 'La Paz batchoy және жергілікті ас мәдениетімен байланысты Илоилоның классикалық базары. Туристік жылтырсыз қысқа гастро маршрутқа жақсы.', 10.70640000, 122.56610000, 'https://www.openstreetmap.org/search?query=La%20Paz%20Public%20Market%20Iloilo', 'La_Paz_Public_Market.jpg'),
    ('the-ruins-bacolod', 'bacolod', 'ARCHITECTURE', 1, 'HOURS', 4.6, ARRAY['philippines', 'bacolod', 'the-ruins', 'heritage', 'architecture', 'photo']::text[], 'Руины особняка Лаксон', 'The Ruins', 'Лаксон сарайының қирандылары', 'Фотогеничные руины сахарной эпохи рядом с Баколодом, часто используемые как главный heritage-символ Негроса. Хороши на закате.', 'Photogenic sugar-era mansion ruins near Bacolod, often used as Negros main heritage symbol. They are strong around sunset.', 'Баколод маңындағы қант дәуірінің фотогенді сарай қирандылары, Негростың басты heritage символы ретінде жиі қолданылады. Күн батарда әсерлі.', 10.71460000, 122.98070000, 'https://www.openstreetmap.org/search?query=The%20Ruins%20Bacolod', 'The_Ruins_Talisay_Negros.jpg'),
    ('negros-museum', 'bacolod', 'MUSEUM', 1, 'HOURS', 4.4, ARRAY['philippines', 'bacolod', 'negros-museum', 'museum', 'culture', 'history']::text[], 'Музей Негроса', 'The Negros Museum', 'Негрос музейі', 'Музей о культуре, истории и сахарном наследии Негроса. Полезен как indoor-точка перед прогулкой по Баколоду.', 'A museum about Negros culture, history and sugar heritage. It is useful as an indoor stop before a Bacolod walk.', 'Негрос мәдениеті, тарихы және қант мұрасы туралы музей. Баколод серуенінің алдындағы indoor аялдамаға пайдалы.', 10.67750000, 122.95320000, 'https://www.openstreetmap.org/search?query=The%20Negros%20Museum%20Bacolod', 'The_Negros_Museum.jpg'),
    ('manokan-country', 'bacolod', 'FOOD', 1, 'HOURS', 4.5, ARRAY['philippines', 'bacolod', 'manokan-country', 'food', 'chicken-inasal', 'local']::text[], 'Manokan Country', 'Manokan Country', 'Manokan Country', 'Известная зона куриного inasal в Баколоде и важная точка локального food-туризма. Подходит для простого ужина после прогулки.', 'A famous Bacolod chicken inasal dining area and an important local food-tourism stop. It suits a simple dinner after a walk.', 'Баколодтағы әйгілі chicken inasal тамақтану аймағы және жергілікті food-туризмнің маңызды нүктесі. Серуеннен кейінгі қарапайым кешкі асқа сай.', 10.67170000, 122.94570000, 'https://www.openstreetmap.org/search?query=Manokan%20Country%20Bacolod', 'Chicken_inasal_Bacolod.jpg'),

    ('peoples-park-davao', 'davao', 'PARK', 2, 'HOURS', 4.4, ARRAY['philippines', 'davao', 'peoples-park', 'park', 'city', 'family']::text[], 'People''s Park Davao', 'People''s Park Davao', 'People''s Park Davao', 'Центральный городской парк Давао с садами, скульптурами и семейными прогулками. Удобен как легкая точка в центре города.', 'A central Davao city park with gardens, sculptures and family walks. It is an easy stop in the city center.', 'Бақтары, мүсіндері және отбасылық серуендері бар Даваоның орталық қалалық паркі. Қала орталығындағы жеңіл аялдама.', 7.07090000, 125.60890000, 'https://www.openstreetmap.org/search?query=People%27s%20Park%20Davao', 'People%27s_Park_Davao.jpg'),
    ('philippine-eagle-center', 'davao', 'PARK', 2, 'HOURS', 4.7, ARRAY['philippines', 'davao', 'philippine-eagle-center', 'wildlife', 'conservation', 'family']::text[], 'Центр филиппинского орла', 'Philippine Eagle Center', 'Филиппин бүркіті орталығы', 'Природоохранный центр рядом с Давао, посвященный филиппинскому орлу и другим видам. Хорош для семей и осознанного wildlife-маршрута.', 'A conservation center near Davao dedicated to the Philippine eagle and other species. It suits families and responsible wildlife routes.', 'Филиппин бүркіті және басқа түрлерге арналған Давао маңындағы табиғатты қорғау орталығы. Отбасыларға және саналы wildlife маршрутына сай.', 7.18340000, 125.41730000, 'https://www.openstreetmap.org/search?query=Philippine%20Eagle%20Center%20Davao', 'Philippine_Eagle_Center.jpg'),
    ('eden-nature-park', 'davao', 'PARK', 3, 'HOURS', 4.5, ARRAY['philippines', 'davao', 'eden-nature-park', 'park', 'mountain', 'family']::text[], 'Eden Nature Park', 'Eden Nature Park', 'Eden Nature Park', 'Горный природный парк у Давао с садами, прохладным климатом, активностями и семейными маршрутами. Хорош как зеленая пауза от города.', 'A mountain nature park near Davao with gardens, cooler air, activities and family routes. It is a green pause from the city.', 'Бақтары, салқын ауасы, белсенділіктері және отбасылық маршруттары бар Давао маңындағы тау табиғи паркі. Қаладан жасыл үзіліс.', 7.00860000, 125.39440000, 'https://www.openstreetmap.org/search?query=Eden%20Nature%20Park%20Davao', 'Eden_Nature_Park_Davao.jpg'),
    ('roxas-night-market', 'davao', 'MARKET', 2, 'HOURS', 4.5, ARRAY['philippines', 'davao', 'roxas-night-market', 'night-market', 'street-food', 'market']::text[], 'Ночной рынок Рохас', 'Roxas Night Market', 'Рохас түнгі базары', 'Популярный вечерний рынок Давао с уличной едой, грилем и плотным локальным ритмом. Подходит для простого гастро-вечера.', 'A popular Davao evening market with street food, grills and dense local rhythm. It suits a simple food evening.', 'Стрит-фуд, гриль және тығыз жергілікті ырғағы бар Даваоның танымал кешкі базары. Қарапайым гастро кешке сай.', 7.07030000, 125.60990000, 'https://www.openstreetmap.org/search?query=Roxas%20Night%20Market%20Davao', 'Roxas_Night_Market_Davao.jpg'),
    ('abreeza-mall', 'davao', 'SHOPPING', 2, 'HOURS', 4.4, ARRAY['philippines', 'davao', 'abreeza-mall', 'mall', 'shopping', 'food']::text[], 'Abreeza Mall', 'Abreeza Mall', 'Abreeza Mall', 'Крупный молл Давао с магазинами, ресторанами и сервисами для туристов. Удобен как indoor-точка и место встречи.', 'A major Davao mall with shops, restaurants and traveler services. It is useful as an indoor stop and meeting point.', 'Дүкендері, мейрамханалары және туристік сервистері бар Даваоның ірі моллы. Indoor аялдама және кездесу орны ретінде ыңғайлы.', 7.09130000, 125.61130000, 'https://www.openstreetmap.org/search?query=Abreeza%20Mall%20Davao', 'Abreeza_Mall_Davao.jpg'),
    ('cloud-9-siargao', 'siargao', 'BEACH', 3, 'HOURS', 4.8, ARRAY['philippines', 'siargao', 'cloud-9', 'surfing', 'beach', 'boardwalk']::text[], 'Cloud 9 Siargao', 'Cloud 9 Siargao', 'Cloud 9 Siargao', 'Главная серф-точка Сиаргао с променадом, волнами и узнаваемой островной атмосферой. Это базовый якорь General Luna.', 'Siargao main surf spot, with a boardwalk, waves and a recognizable island atmosphere. It is the core General Luna anchor.', 'Променады, толқындары және танымал арал атмосферасы бар Сиаргаоның басты серф нүктесі. General Luna-ның негізгі нысаны.', 9.81190000, 126.16470000, 'https://www.openstreetmap.org/search?query=Cloud%209%20Siargao', 'Cloud_9_Siargao.jpg'),
    ('sugba-lagoon', 'siargao', 'NATURE', 5, 'HOURS', 4.7, ARRAY['philippines', 'siargao', 'sugba-lagoon', 'lagoon', 'kayak', 'island-hopping']::text[], 'Лагуна Сугба', 'Sugba Lagoon', 'Сугба лагунасы', 'Бирюзовая лагуна среди мангров и островов, популярная для каяков, SUP и прыжков с платформы. Хороша как полный day trip из Сиаргао.', 'A turquoise lagoon among mangroves and islands, popular for kayaking, SUP and platform jumps. It works as a full Siargao day trip.', 'Мангрлар мен аралдар арасындағы көгілдір лагуна, каяк, SUP және платформадан секіруге танымал. Сиаргаодан толық day trip.', 9.85390000, 125.96580000, 'https://www.openstreetmap.org/search?query=Sugba%20Lagoon%20Siargao', 'Sugba_Lagoon_Siargao.jpg'),
    ('magpupungko-rock-pools', 'siargao', 'NATURE', 3, 'HOURS', 4.6, ARRAY['philippines', 'siargao', 'magpupungko', 'rock-pools', 'tide', 'nature']::text[], 'Скальные бассейны Магпупунгко', 'Magpupungko Rock Pools', 'Магпупунгко тас бассейндері', 'Приливные скальные бассейны на востоке Сиаргао, которые лучше посещать во время отлива. Нужны как природная остановка вне серфинга.', 'Tidal rock pools on eastern Siargao, best visited at low tide. They add a nature stop beyond surfing.', 'Сиаргаоның шығысындағы қайтқанда жақсы көрінетін толқын тас бассейндері. Серфингтен тыс табиғи аялдама қосады.', 9.90550000, 126.14430000, 'https://www.openstreetmap.org/search?query=Magpupungko%20Rock%20Pools%20Siargao', 'Magpupungko_Rock_Pools.jpg'),
    ('maasin-river', 'siargao', 'NATURE', 1, 'HOURS', 4.3, ARRAY['philippines', 'siargao', 'maasin-river', 'river', 'photo', 'palm']::text[], 'Река Маасин', 'Maasin River', 'Маасин өзені', 'Живописная речная остановка с пальмами, лодками и спокойной тропической атмосферой. Хороша как короткая часть островного road trip.', 'A scenic river stop with palms, boats and a calm tropical atmosphere. It works as a short part of an island road trip.', 'Пальмалары, қайықтары және тыныш тропикалық атмосферасы бар көркем өзен аялдамасы. Арал road trip-інің қысқа бөлігіне сай.', 9.83390000, 126.03760000, 'https://www.openstreetmap.org/search?query=Maasin%20River%20Siargao', 'Maasin_River_Siargao.jpg'),
    ('dahilayan-adventure-park', 'cagayan-de-oro', 'ENTERTAINMENT', 4, 'HOURS', 4.6, ARRAY['philippines', 'cagayan-de-oro', 'dahilayan', 'adventure', 'zipline', 'family']::text[], 'Dahilayan Adventure Park', 'Dahilayan Adventure Park', 'Dahilayan Adventure Park', 'Горный парк приключений в Букидноне с зиплайнами, аттракционами и прохладным климатом. Часто используется как day trip из Кагаян-де-Оро.', 'A Bukidnon mountain adventure park with ziplines, rides and cooler air. It is often used as a day trip from Cagayan de Oro.', 'Зиплайндары, аттракциондары және салқын ауасы бар Букиднон тау adventure паркі. Кагаян-де-Ородан day trip ретінде жиі қолданылады.', 8.21150000, 124.88830000, 'https://www.openstreetmap.org/search?query=Dahilayan%20Adventure%20Park', 'Dahilayan_Adventure_Park.jpg'),
    ('camiguin-white-island', 'camiguin', 'BEACH', 3, 'HOURS', 4.7, ARRAY['philippines', 'camiguin', 'white-island', 'sandbar', 'beach', 'volcano-view']::text[], 'Белый остров Камигина', 'Camiguin White Island', 'Камигин Ақ аралы', 'Песчаная коса у Камигина с видом на вулканы и прозрачной водой. Это один из самых понятных пляжных символов острова.', 'A Camiguin sandbar with volcano views and clear water. It is one of the island clearest beach symbols.', 'Жанартаулар көрінісі және мөлдір суы бар Камигин құм аралы. Аралдың ең түсінікті жағажай символдарының бірі.', 9.25960000, 124.65700000, 'https://www.openstreetmap.org/search?query=White%20Island%20Camiguin', 'White_Island_Camiguin.jpg'),
    ('sunken-cemetery-camiguin', 'camiguin', 'OTHER', 1, 'HOURS', 4.5, ARRAY['philippines', 'camiguin', 'sunken-cemetery', 'history', 'sea', 'viewpoint']::text[], 'Затонувшее кладбище Камигина', 'Sunken Cemetery', 'Камигин су астындағы зираты', 'Мемориальное место у побережья Камигина с большим крестом в море и историей вулканического извержения. Хорошо работает как короткая культурная остановка.', 'A Camiguin coastal memorial with a large sea cross and volcanic eruption history. It works as a short cultural stop.', 'Теңіздегі үлкен кресті және жанартау атқылауы тарихы бар Камигин жағалауындағы мемориал. Қысқа мәдени аялдамаға жақсы.', 9.20330000, 124.63170000, 'https://www.openstreetmap.org/search?query=Sunken%20Cemetery%20Camiguin', 'Sunken_Cemetery_Camiguin.jpg'),

    ('burnham-park', 'baguio', 'PARK', 2, 'HOURS', 4.5, ARRAY['philippines', 'baguio', 'burnham-park', 'park', 'lake', 'family']::text[], 'Парк Бернхэм', 'Burnham Park', 'Бернхэм паркі', 'Центральный парк Багио с озером, лодками, прогулками и семейными активностями. Это базовая точка для первого знакомства с городом.', 'Baguio central park with a lake, boats, walks and family activities. It is the base first stop for the city.', 'Көлі, қайықтары, серуендері және отбасылық белсенділіктері бар Багионың орталық паркі. Қаламен алғашқы танысуға базалық аялдама.', 16.41100000, 120.59360000, 'https://www.openstreetmap.org/search?query=Burnham%20Park%20Baguio', 'Burnham_Park_Baguio.jpg'),
    ('mines-view-park', 'baguio', 'NATURE', 1, 'HOURS', 4.3, ARRAY['philippines', 'baguio', 'mines-view-park', 'viewpoint', 'mountains', 'souvenirs']::text[], 'Парк Mines View', 'Mines View Park', 'Mines View паркі', 'Популярная смотровая площадка Багио с горными видами, сувенирами и короткой прогулкой. Хороша как классическая stop-and-view точка.', 'A popular Baguio viewpoint with mountain views, souvenirs and a short walk. It works as a classic stop-and-view point.', 'Тау көріністері, сувенирлері және қысқа серуені бар Багионың танымал смотроваясы. Классикалық stop-and-view нүктесіне сай.', 16.42150000, 120.62750000, 'https://www.openstreetmap.org/search?query=Mines%20View%20Park%20Baguio', 'Mines_View_Park_Baguio.jpg'),
    ('bencab-museum', 'baguio', 'MUSEUM', 2, 'HOURS', 4.7, ARRAY['philippines', 'baguio', 'bencab-museum', 'museum', 'art', 'culture']::text[], 'Музей BenCab', 'BenCab Museum', 'BenCab музейі', 'Художественный музей рядом с Багио с современным филиппинским искусством, коллекциями и видом на горы. Один из лучших indoor-культурных якорей региона.', 'An art museum near Baguio with contemporary Philippine art, collections and mountain views. It is one of the region best indoor culture anchors.', 'Заманауи филиппин өнері, коллекциялары және тау көріністері бар Багио маңындағы өнер музейі. Аймақтың ең жақсы indoor мәдени нысандарының бірі.', 16.40970000, 120.55090000, 'https://www.openstreetmap.org/search?query=BenCab%20Museum%20Baguio', 'BenCab_Museum.jpg'),
    ('baguio-night-market', 'baguio', 'MARKET', 2, 'HOURS', 4.4, ARRAY['philippines', 'baguio', 'night-market', 'market', 'shopping', 'street-food']::text[], 'Ночной рынок Багио', 'Baguio Night Market', 'Багио түнгі базары', 'Вечерний рынок на Harrison Road с одеждой, товарами, едой и плотной городской атмосферой. Хорош для экономного шопинга и вечерней прогулки.', 'An evening Harrison Road market with clothes, goods, food and dense city atmosphere. It suits budget shopping and an evening walk.', 'Киім, тауарлар, тағам және тығыз қала атмосферасы бар Harrison Road кешкі базары. Үнемді сауда және кешкі серуенге сай.', 16.41210000, 120.59490000, 'https://www.openstreetmap.org/search?query=Baguio%20Night%20Market', 'Baguio_Night_Market.jpg'),
    ('calle-crisologo', 'vigan', 'ARCHITECTURE', 2, 'HOURS', 4.8, ARRAY['philippines', 'vigan', 'calle-crisologo', 'unesco', 'heritage', 'architecture']::text[], 'Калье Крисолого', 'Calle Crisologo', 'Калье Крисолого', 'Главная историческая улица Вигана с мощеными дорогами, домами колониальной эпохи и прогулками на калесе. Это основной символ heritage-маршрута.', 'Vigan main historic street, with cobblestones, colonial-era houses and kalesa rides. It is the core symbol of the heritage route.', 'Тас төселген жолдары, отарлық дәуір үйлері және kalesa серуендері бар Виганның басты тарихи көшесі. Heritage маршрутының негізгі символы.', 17.57470000, 120.38890000, 'https://www.openstreetmap.org/search?query=Calle%20Crisologo%20Vigan', 'Calle_Crisologo_Vigan.jpg'),
    ('vigan-cathedral', 'vigan', 'TEMPLE', 1, 'HOURS', 4.5, ARRAY['philippines', 'vigan', 'cathedral', 'church', 'heritage', 'architecture']::text[], 'Кафедральный собор Вигана', 'Vigan Cathedral', 'Виган кафедралды соборы', 'Исторический собор у Plaza Salcedo в центре Вигана. Хорошо дополняет маршрут по Калье Крисолого и старому городу.', 'A historic cathedral by Plaza Salcedo in central Vigan. It pairs well with Calle Crisologo and the old town route.', 'Виган орталығындағы Plaza Salcedo жанындағы тарихи собор. Калье Крисолого және ескі қала маршрутын жақсы толықтырады.', 17.57580000, 120.38730000, 'https://www.openstreetmap.org/search?query=Vigan%20Cathedral', 'Vigan_Cathedral.jpg'),
    ('banaue-rice-terraces', 'banaue', 'NATURE', 4, 'HOURS', 4.8, ARRAY['philippines', 'banaue', 'rice-terraces', 'ifugao', 'unesco', 'nature']::text[], 'Рисовые террасы Банауэ', 'Banaue Rice Terraces', 'Банауэ күріш террасалары', 'Знаменитые горные рисовые террасы Ифугао с обзорными точками и культурным контекстом. Это главный природно-культурный якорь Северного Лусона.', 'Famous Ifugao mountain rice terraces with viewpoints and cultural context. They are the main nature-culture anchor of Northern Luzon.', 'Смотроваялары және мәдени контексті бар Ифугаоның әйгілі тау күріш террасалары. Солтүстік Лусонның басты табиғи-мәдени нысаны.', 16.91920000, 121.05960000, 'https://www.openstreetmap.org/search?query=Banaue%20Rice%20Terraces', 'Banaue_Rice_Terraces.jpg'),
    ('sagada-hanging-coffins', 'sagada', 'OTHER', 2, 'HOURS', 4.6, ARRAY['philippines', 'sagada', 'hanging-coffins', 'culture', 'valley', 'history']::text[], 'Висячие гробы Сагады', 'Sagada Hanging Coffins', 'Сагада аспалы табыттары', 'Культурный маршрут в долине Сагады с традиционными висячими гробами и местными правилами посещения. Требует уважительного поведения и локального гида.', 'A cultural Sagada valley route with traditional hanging coffins and local visitor rules. It requires respectful behavior and a local guide.', 'Дәстүрлі аспалы табыттары және жергілікті келу ережелері бар Сагада аңғарындағы мәдени маршрут. Құрметті мінез-құлық пен жергілікті гид қажет.', 17.08380000, 120.89920000, 'https://www.openstreetmap.org/search?query=Sagada%20Hanging%20Coffins', 'Sagada_Hanging_Coffins.jpg'),
    ('sumaguing-cave', 'sagada', 'NATURE', 3, 'HOURS', 4.6, ARRAY['philippines', 'sagada', 'sumaguing-cave', 'cave', 'adventure', 'nature']::text[], 'Пещера Сумагуинг', 'Sumaguing Cave', 'Сумагуинг үңгірі', 'Большая пещера Сагады с известняковыми формациями и приключенческим прохождением. Нужна как активный маршрут только с подготовкой и местным сопровождением.', 'A large Sagada cave with limestone formations and adventure-style traversal. It is an active route that needs preparation and local guidance.', 'Әктас формациялары және adventure өтуі бар Сагаданың үлкен үңгірі. Дайындық пен жергілікті сүйемелдеу қажет белсенді маршрут.', 17.08100000, 120.90860000, 'https://www.openstreetmap.org/search?query=Sumaguing%20Cave%20Sagada', 'Sumaguing_Cave_Sagada.jpg'),
    ('san-juan-surf-beach-la-union', 'la-union', 'BEACH', 3, 'HOURS', 4.5, ARRAY['philippines', 'la-union', 'san-juan', 'surfing', 'beach', 'sunset']::text[], 'Серф-пляж Сан-Хуан', 'San Juan Surf Beach', 'Сан-Хуан серф жағажайы', 'Популярная серф-зона Ла-Унион с школами серфинга, кафе и закатной атмосферой. Хороша для активного пляжного сценария из Северного Лусона.', 'A popular La Union surf area with surf schools, cafes and sunset atmosphere. It is useful for an active beach scenario in Northern Luzon.', 'Серф мектептері, кафелері және күн батуы атмосферасы бар Ла-Унионның танымал серф аймағы. Солтүстік Лусондағы белсенді жағажай сценарийіне пайдалы.', 16.66760000, 120.31650000, 'https://www.openstreetmap.org/search?query=San%20Juan%20Surf%20Beach%20La%20Union', 'San_Juan_La_Union_Surf_Beach.jpg'),
    ('saud-beach', 'pagudpud', 'BEACH', 3, 'HOURS', 4.6, ARRAY['philippines', 'pagudpud', 'saud-beach', 'beach', 'ilocos', 'north']::text[], 'Пляж Сауд', 'Saud Beach', 'Сауд жағажайы', 'Северный пляж Пагудпуда с белым песком, пальмами и спокойным курортным ритмом. Подходит для пляжной остановки в маршруте по Илокосу.', 'A northern Pagudpud beach with white sand, palms and a calm resort rhythm. It suits a beach stop on an Ilocos route.', 'Ақ құмы, пальмалары және тыныш курорттық ырғағы бар Пагудпудтың солтүстік жағажайы. Илокос маршруты бойынша жағажай аялдамасына сай.', 18.61990000, 120.78670000, 'https://www.openstreetmap.org/search?query=Saud%20Beach%20Pagudpud', 'Saud_Beach_Pagudpud.jpg'),
    ('bangui-windmills', 'pagudpud', 'OTHER', 1, 'HOURS', 4.5, ARRAY['philippines', 'pagudpud', 'bangui-windmills', 'wind-farm', 'photo', 'coast']::text[], 'Ветряки Банги', 'Bangui Windmills', 'Банги жел диірмендері', 'Ряд ветрогенераторов на северном побережье Илокоса, ставший узнаваемой фото-точкой региона. Хорошо совмещается с пляжами Пагудпуда.', 'A row of wind turbines on the northern Ilocos coast that became a recognizable regional photo stop. It pairs well with Pagudpud beaches.', 'Солтүстік Илокос жағалауындағы жел генераторлары қатары, аймақтың танымал фото нүктесіне айналған. Пагудпуд жағажайларымен жақсы үйлеседі.', 18.53360000, 120.71830000, 'https://www.openstreetmap.org/search?query=Bangui%20Windmills', 'Bangui_Windmills.jpg');

CREATE TEMP TABLE seed_philippines_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('ph-attraction:' || seed.slug) AS attraction_hash,
        md5('ph-media:' || seed.slug) AS media_hash
    FROM seed_philippines_priority_attractions seed
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
    tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    description_kk,
    latitude,
    longitude,
    location_source_url,
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
    'PH',
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
FROM seed_philippines_resolved_attractions
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
FROM seed_philippines_resolved_attractions seed
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
    FROM seed_philippines_resolved_attractions
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
FROM seed_philippines_resolved_attractions
WHERE EXISTS (
    SELECT 1
    FROM attractions a
    WHERE a.id = seed_philippines_resolved_attractions.id
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
SELECT gen_random_uuid(), id, kind, 'PH', city_id, 0, NOW()
FROM seed_philippines_resolved_attractions
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_philippines_resolved_attractions;
DROP TABLE IF EXISTS seed_philippines_priority_attractions;
