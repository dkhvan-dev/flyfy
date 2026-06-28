-- Global route-level outdoor seed from parallel regional audits.
-- Adds distinct hiking and walking places for reference city hubs without reusing existing route cards.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_global_subagent_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_subagent_outdoor_routes_places;

CREATE TEMP TABLE seed_global_subagent_outdoor_routes_places (
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

INSERT INTO seed_global_subagent_outdoor_routes_places (
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
    ('US', 'USD', 'runyon-canyon-loop', 'los-angeles', 'NATURE', 0, 2, 'HOURS', 4.7, 'Петля каньона Раньон', 'Runyon Canyon Loop', 'Раньон каньоны ілмегі', 'Городской маршрут Голливудских холмов с быстрым набором высоты, открытыми видами на Лос-Анджелес и форматом короткой активной прогулки.', 'An urban Hollywood Hills loop with quick elevation gain, open Los Angeles views and a short active-walk format.', 'Голливуд төбелеріндегі қала бағыты: тез биіктік жинау, Лос-Анджелеске ашық көріністер және қысқа белсенді серуен форматы.', 34.11000000, -118.35100000, 'Griffith_Observatory_2015.jpg', ARRAY['los-angeles']::text[], ARRAY['los-angeles']::text[], ARRAY['united-states','los-angeles','urban-canyon','free-entry','walking']::text[]),
    ('US', 'USD', 'discovery-park-loop-trail', 'seattle', 'NATURE', 0, 3, 'HOURS', 4.7, 'Петля парка Discovery', 'Discovery Park Loop Trail', 'Discovery Park ілмек соқпағы', 'Маршрут Сиэтла через лес, луга и береговые виды Пьюджет-Саунда, добавляющий к городу полноценный природный сценарий.', 'A Seattle route through forest, meadows and Puget Sound shore views, adding a full nature scenario to the city.', 'Сиэтлдегі орман, шалғын және Пьюджет-Саунд жағалау көріністері арқылы өтетін, қалаға толық табиғи сценарий қосатын бағыт.', 47.66000000, -122.41500000, 'Space_Needle002.jpg', ARRAY['seattle']::text[], ARRAY['seattle']::text[], ARRAY['united-states','seattle','urban-nature','coastal','free-entry','walking']::text[]),
    ('CA', 'CAD', 'grouse-grind-trail', 'vancouver', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Grouse Grind', 'Grouse Grind Trail', 'Grouse Grind соқпағы', 'Крутой лесной подъем северного берега Ванкувера к горной зоне, рассчитанный на подготовленный спортивный выход.', 'A steep North Shore forest climb from Vancouver toward the mountain area, suited to a prepared fitness hike.', 'Ванкувердің солтүстік жағалауындағы тау аймағына апаратын тік орман көтерілуі, дайын спорттық хайкке арналған.', 49.37100000, -123.08300000, 'Capilano_Suspension_Bridge.jpg', ARRAY['vancouver']::text[], ARRAY['vancouver']::text[], ARRAY['canada','vancouver','north-shore','steep-forest','hiking']::text[]),
    ('CA', 'CAD', 'scarborough-bluffs-trail', 'toronto', 'NATURE', 0, 2, 'HOURS', 4.6, 'Тропа утесов Скарборо', 'Scarborough Bluffs Trail', 'Скарборо жартастары соқпағы', 'Озерная прогулка Торонто вдоль светлых обрывов, пляжных участков и панорам Онтарио без долгого выезда из города.', 'A Toronto lakefront walk along pale bluffs, beach sections and Lake Ontario views without a long transfer from the city.', 'Торонто маңындағы ашық жартастар, жағажай бөліктері және Онтарио көлі көріністері арқылы өтетін қысқа қалалық серуен.', 43.70600000, -79.23500000, 'Toronto_Islands.jpg', ARRAY['toronto']::text[], ARRAY['toronto']::text[], ARRAY['canada','toronto','bluffs','lakefront','free-entry','walking']::text[]),
    ('BR', 'BRL', 'pedra-da-gavea-trail', 'rio-de-janeiro', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа Pedra da Gavea', 'Pedra da Gavea Trail', 'Pedra da Gavea соқпағы', 'Сильный маршрут Рио по атлантическому лесу к скальной вершине, видам океана и городскому ландшафту с высоты.', 'A strong Rio route through Atlantic forest toward a rocky summit, ocean views and a high city landscape.', 'Риодағы Атлант орманы арқылы жартасты шыңға, мұхит көріністеріне және биіктен қала панорамасына апаратын бағыт.', -22.99900000, -43.28400000, 'Christ the Redeemer - Cristo Redentor.jpg', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], ARRAY['brazil','rio-de-janeiro','atlantic-forest','summit','hiking']::text[]),
    ('AR', 'ARS', 'martial-glacier-trail', 'ushuaia', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа ледника Martial', 'Martial Glacier Trail', 'Martial мұздығы соқпағы', 'Маршрут над Ушуайей к ледниковым видам, субантарктическому лесу и панораме пролива Бигл.', 'A route above Ushuaia toward glacier views, subantarctic forest and a Beagle Channel panorama.', 'Ушуайя үстіндегі мұздық көріністеріне, субантарктикалық орманға және Бигл бұғазы панорамасына апаратын бағыт.', -54.78500000, -68.36300000, 'PeritoMoreno005.jpg', ARRAY['ushuaia']::text[], ARRAY['ushuaia']::text[], ARRAY['argentina','ushuaia','glacier-view','free-entry','hiking']::text[]),
    ('KE', 'KES', 'oloolua-nature-trail', 'nairobi', 'NATURE', 200, 2, 'HOURS', 4.6, 'Природная тропа Oloolua', 'Oloolua Nature Trail', 'Oloolua табиғи соқпағы', 'Лесная прогулка рядом с Найроби с ручьем, пещерным участком и водопадной точкой как спокойная альтернатива более известным городским лесам.', 'A forest walk near Nairobi with a stream, cave section and waterfall point as a calmer alternative to better-known urban forests.', 'Найроби маңындағы орман серуені: бұлақ, үңгір бөлігі және сарқырама нүктесі бар, танымал қалалық ормандарға тынышырақ балама.', -1.35900000, 36.71700000, 'Karura_Forest.jpg', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], ARRAY['kenya','nairobi','urban-forest','waterfall','walking']::text[]),
    ('TZ', 'TZS', 'lake-duluti-forest-walk', 'arusha', 'NATURE', 10000, 3, 'HOURS', 4.6, 'Лесная прогулка озера Дулути', 'Lake Duluti Forest Walk', 'Дулути көлі орман серуені', 'Мягкий маршрут у Аруши вокруг кратерного озера с лесными берегами, птицами и спокойным форматом между сафари-днями.', 'A gentle Arusha route around a crater lake with forested shores, birds and an easy format between safari days.', 'Аруша маңындағы кратерлі көлді айналатын жеңіл бағыт: орманды жағалау, құстар және сафари күндері арасындағы тыныш формат.', -3.38100000, 36.80300000, 'Arusha_National_Park.jpg', ARRAY['arusha']::text[], ARRAY['arusha']::text[], ARRAY['tanzania','arusha','lake','forest','walking']::text[]),
    ('AU', 'AUD', 'bold-park-zamia-trail', 'perth', 'NATURE', 0, 2, 'HOURS', 4.6, 'Тропа Zamia в Bold Park', 'Bold Park Zamia Trail', 'Bold Park Zamia соқпағы', 'Природная прогулка Перта через бушленд, песчаные гряды и точки с видом на город и Индийский океан.', 'A Perth nature walk through bushland, sandy ridges and points with views toward the city and Indian Ocean.', 'Перттегі бұталы табиғат, құмды жоталар және қала мен Үнді мұхитына көріністер арқылы өтетін серуен.', -31.94300000, 115.77200000, 'Perth_(AU),_View_from_Kings_Park_--_2019_--_0435-42.jpg', ARRAY['perth']::text[], ARRAY['perth']::text[], ARRAY['australia','perth','bushland','free-entry','walking']::text[]),
    ('AU', 'AUD', 'morialta-falls-plateau-hike', 'adelaide', 'NATURE', 0, 3, 'HOURS', 4.7, 'Плато и водопады Morialta', 'Morialta Falls Plateau Hike', 'Morialta сарқырамалары плато хайкі', 'Маршрут у Аделаиды через ущелье, эвкалиптовые склоны и водопадные виды, удобный для активного полудня.', 'An Adelaide-area route through gorge terrain, eucalyptus slopes and waterfall views, convenient for an active half day.', 'Аделаида маңындағы шатқал, эвкалипт беткейлері және сарқырама көріністері арқылы өтетін белсенді жарты күндік бағыт.', -34.90400000, 138.70600000, '2025_Christmas_at_the_Adelaide_Central_Market_-_01.jpg', ARRAY['adelaide']::text[], ARRAY['adelaide']::text[], ARRAY['australia','adelaide','gorge','waterfall','hiking']::text[]),
    ('NZ', 'NZD', 'rapaki-track', 'christchurch', 'NATURE', 0, 2, 'HOURS', 4.6, 'Тропа Rapaki', 'Rapaki Track', 'Rapaki соқпағы', 'Городской подъем Крайстчерча на Port Hills с видом на гавань, равнину и горный горизонт Южного острова.', 'A Christchurch city climb on the Port Hills with views to the harbour, plains and South Island mountain horizon.', 'Крайстчерчтегі Port Hills жотасына қалалық көтерілу: айлаққа, жазыққа және Оңтүстік арал тауларына көрініс береді.', -43.58900000, 172.68100000, 'Christchurch_Botanic_Gardens.jpg', ARRAY['christchurch']::text[], ARRAY['christchurch']::text[], ARRAY['new-zealand','christchurch','port-hills','free-entry','walking']::text[]),
    ('NZ', 'NZD', 'red-rocks-coastal-walk', 'wellington', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прибрежная прогулка Red Rocks', 'Red Rocks Coastal Walk', 'Red Rocks жағалау серуені', 'Веллингтонский маршрут вдоль южного берега к красным скалам, ветру пролива и открытым морским видам.', 'A Wellington south-coast route to red rocks, Cook Strait wind and open sea views.', 'Веллингтонның оңтүстік жағалауындағы қызыл жартастарға, бұғаз желіне және ашық теңіз көріністеріне апаратын бағыт.', -41.35000000, 174.72000000, 'Wellington_Cable_Car.jpg', ARRAY['wellington']::text[], ARRAY['wellington']::text[], ARRAY['new-zealand','wellington','coastal','free-entry','walking']::text[]),
    ('NZ', 'NZD', 'queenstown-hill-time-walk', 'queenstown', 'NATURE', 0, 3, 'HOURS', 4.8, 'Time Walk на Queenstown Hill', 'Queenstown Hill Time Walk', 'Queenstown Hill Time Walk соқпағы', 'Классическая прогулка Квинстауна к Basket of Dreams, видам Вакатипу и хребтам вокруг озерной чаши.', 'A classic Queenstown walk to the Basket of Dreams, Lake Wakatipu views and ranges around the lake basin.', 'Квинстаундағы Basket of Dreams нүктесіне, Вакатипу көліне және көл аңғары айналасындағы жоталарға апаратын классикалық серуен.', -45.03400000, 168.67100000, 'Lake_Wakatipu.jpg', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], ARRAY['new-zealand','queenstown','summit','free-entry','walking']::text[]),
    ('MA', 'MAD', 'jebel-musa-ridge-trail', 'tetouan', 'NATURE', 0, 4, 'HOURS', 4.7, 'Гребневая тропа Джебель-Муса', 'Jebel Musa Ridge Trail', 'Джебель-Муса жота соқпағы', 'Маршрут Рифа недалеко от Тетуана к известной вершине, видам пролива и скалистым средиземноморским склонам.', 'A Rif route near Tetouan toward a known summit, strait views and rocky Mediterranean slopes.', 'Тетуан маңындағы Риф бағыты: белгілі шыңға, бұғаз көріністеріне және Жерорта теңізі жартасты беткейлеріне апарады.', 35.90000000, -5.41600000, 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg', ARRAY['tetouan','tangier']::text[], ARRAY['tetouan']::text[], ARRAY['morocco','rif','ridge','free-entry','hiking']::text[]),
    ('MA', 'MAD', 'dades-monkey-fingers-walk', 'ouarzazate', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прогулка у скал Monkey Fingers в Дадесе', 'Dades Monkey Fingers Walk', 'Дадестегі Monkey Fingers серуені', 'Короткий маршрут долины Дадес среди необычных скальных форм, сухих троп и мягкого атласского света.', 'A short Dades Valley route among unusual rock forms, dry paths and soft Atlas light.', 'Дадес аңғарындағы ерекше тас пішіндері, құрғақ жолдар және Атлас тауының жұмсақ жарығы арқылы өтетін қысқа бағыт.', 31.49200000, -5.93200000, 'Ait_Ben_Haddou_03.JPG', ARRAY['ouarzazate']::text[], ARRAY['ouarzazate']::text[], ARRAY['morocco','dades','rock-formations','free-entry','walking']::text[]),
    ('EG', 'EGP', 'abu-galum-blue-hole-coastal-trail', 'dahab', 'NATURE', 200, 4, 'HOURS', 4.7, 'Прибрежная тропа Абу-Галум - Blue Hole', 'Abu Galum to Blue Hole Coastal Trail', 'Абу-Галумнан Blue Hole-ға жағалау соқпағы', 'Синайский маршрут у Дахаба вдоль сухого берега, лагун и гор Красного моря с простым форматом дневного выхода.', 'A Sinai route near Dahab along dry coast, lagoons and Red Sea mountains in an accessible day-hike format.', 'Дахаб маңындағы Синай бағыты: құрғақ жағалау, лагуналар және Қызыл теңіз таулары бойымен өтетін күндік хайк.', 28.61500000, 34.55500000, 'Blue_Hole_Dahab.jpg', ARRAY['dahab','sharm-el-sheikh']::text[], ARRAY['dahab']::text[], ARRAY['egypt','sinai','coastal','protected-area','hiking']::text[]),
    ('TR', 'TRY', 'kayakoy-oludeniz-lycian-way-trail', 'fethiye', 'NATURE', 0, 4, 'HOURS', 4.8, 'Ликийская тропа Каякей - Олюдениз', 'Kayakoy to Oludeniz Lycian Way Trail', 'Каякейден Олюденизге Ликия соқпағы', 'Участок Ликийского пути от каменной деревни к морским видам и спуску в сторону бирюзовой лагуны.', 'A Lycian Way section from the stone village toward sea views and a descent toward the turquoise lagoon area.', 'Тас ауылдан теңіз көріністеріне және көгілдір лагуна жағына түсетін Ликия жолының бөлігі.', 36.57400000, 29.09200000, 'Oludeniz_Blue_Lagoon.jpg', ARRAY['fethiye','oludeniz']::text[], ARRAY['fethiye','oludeniz']::text[], ARRAY['turkey','lycian-way','village-to-beach','free-entry','hiking']::text[]),
    ('GE', 'GEL', 'machakhela-arched-bridges-trail', 'keda', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа арочных мостов Мачахела', 'Machakhela Arched Bridges Trail', 'Мачахела аркалы көпірлер соқпағы', 'Аджарский маршрут вдоль горной реки к арочным мостам, водопадным остановкам и зеленым склонам недалеко от Батуми.', 'An Adjara route along a mountain river toward arched bridges, waterfall stops and green slopes not far from Batumi.', 'Батумиге жақын Аджария бағыты: тау өзені, аркалы көпірлер, сарқырама аялдамалары және жасыл беткейлер арқылы өтеді.', 41.57400000, 41.85800000, 'Batumi,_Georgia.jpg', ARRAY['keda','batumi']::text[], ARRAY['keda','batumi']::text[], ARRAY['georgia','adjara','arched-bridges','free-entry','hiking']::text[]),
    ('GR', 'EUR', 'hymettus-kaisariani-forest-trail', 'athens', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная тропа Имиттос - Кесариани', 'Hymettus Kaisariani Forest Trail', 'Имиттос-Кесариани орман соқпағы', 'Афинский городской хайк по склонам Имиттоса с соснами, монастырским контекстом и видом на чашу города.', 'An Athens urban hike on Hymettus slopes with pines, monastery context and views across the city bowl.', 'Афинадағы Имиттос беткейлерімен өтетін қалалық хайк: қарағайлар, монастырь контексті және қала аңғарына көрініс.', 37.96300000, 23.79800000, 'Lycabettus_Hill_Athens.jpg', ARRAY['athens']::text[], ARRAY['athens']::text[], ARRAY['greece','athens','urban-hike','free-entry','walking']::text[]),
    ('GB', 'GBP', 'cwm-idwal-llyn-idwal-walk', 'snowdonia', 'NATURE', 0, 3, 'HOURS', 4.8, 'Прогулка Cwm Idwal и Llyn Idwal', 'Cwm Idwal and Llyn Idwal Walk', 'Cwm Idwal және Llyn Idwal серуені', 'Классическая валлийская прогулка вокруг горного озера с ледниковым каром, каменными стенами и сильным ландшафтом Эрири.', 'A classic Welsh walk around a mountain lake with a glacial cwm, stone walls and a strong Eryri landscape.', 'Уэльстегі тау көлін айналатын классикалық серуен: мұздық кар, тас қабырғалар және Эриридің әсерлі ландшафты.', 53.12300000, -4.02200000, 'Snowdonia National Park.jpg', ARRAY['snowdonia']::text[], ARRAY['snowdonia']::text[], ARRAY['united-kingdom','snowdonia','lake-walk','free-entry','walking']::text[]),
    ('IS', 'ISK', 'svartifoss-skaftafell-loop', 'skaftafell', 'NATURE', 0, 3, 'HOURS', 4.8, 'Петля Свартифосс в Скафтафетле', 'Svartifoss Skaftafell Loop', 'Скафтафетльдегі Свартифосс ілмегі', 'Маршрут Скафтафетля к базальтовому водопаду, низким березовым участкам и видам ледниковой окраины.', 'A Skaftafell route to the basalt waterfall, low birch sections and glacier-edge views.', 'Скафтафетльдегі базальт сарқырамасына, аласа қайың бөліктеріне және мұздық жиегі көріністеріне апаратын бағыт.', 64.02700000, -16.97500000, 'Skaftafell Iceland.jpg', ARRAY['skaftafell']::text[], ARRAY['skaftafell','reykjavik']::text[], ARRAY['iceland','skaftafell','waterfall','basalt','hiking']::text[]),
    ('FR', 'EUR', 'calanques-port-miou-en-vau-trail', 'marseille', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа каланков Порт-Миу - Эн-Во', 'Calanques Port-Miou to En-Vau Trail', 'Порт-Миудан Эн-Воға каланк соқпағы', 'Прибрежный маршрут Каланков к известной бухте, белым скалам, соснам и сильному средиземноморскому виду.', 'A Calanques coastal route toward a known cove, white cliffs, pines and a strong Mediterranean view.', 'Каланктардағы белгілі қойнауға, ақ жартастарға, қарағайларға және Жерорта теңізі көрінісіне апаратын жағалау бағыты.', 43.20500000, 5.50400000, 'Calanques National Park.jpg', ARRAY['marseille','cassis']::text[], ARRAY['marseille']::text[], ARRAY['france','marseille','calanques','coastal','hiking']::text[]),
    ('KR', 'KRW', 'inwangsan-fortress-wall-trail', 'seoul', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа крепостной стены Инвансан', 'Inwangsan Fortress Wall Trail', 'Инвансан қамал қабырғасы соқпағы', 'Городской маршрут Сеула к гранитным склонам, участку старой крепостной стены и открытому виду на дворцы и центр.', 'A Seoul urban route to granite slopes, an old fortress-wall section and open views toward palaces and the center.', 'Сеулдегі гранит беткейлерге, ескі қамал қабырғасының бөлігіне және сарайлар мен орталыққа ашық көрініске апаратын қалалық бағыт.', 37.58400000, 126.95900000, 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg', ARRAY['seoul']::text[], ARRAY['seoul']::text[], ARRAY['south-korea','seoul','inwangsan','fortress-wall','urban-hike']::text[]),
    ('KR', 'KRW', 'jeju-olle-route-7-coastal-walk', 'seogwipo', 'NATURE', 0, 5, 'HOURS', 4.8, 'Прибрежная прогулка Jeju Olle Route 7', 'Jeju Olle Route 7 Coastal Walk', 'Jeju Olle 7 жағалау серуені', 'Маршрут Согвипхо вдоль южного берега Чеджу с морскими скалами, лесными участками и островным пешим ритмом.', 'A Seogwipo route along Jeju south coast with sea cliffs, forest sections and an island walking rhythm.', 'Согвипхо маңындағы Чеджудың оңтүстік жағалауымен өтетін бағыт: теңіз жартастары, орман бөліктері және аралдық жаяу ырғақ.', 33.24000000, 126.54500000, 'Seongsan,_Jeju_Island.jpg', ARRAY['seogwipo','jeju']::text[], ARRAY['seogwipo','jeju']::text[], ARRAY['south-korea','jeju','seogwipo','olle','coastal']::text[]),
    ('CN', 'CNY', 'purple-mountain-greenway-trail', 'nanjing', 'NATURE', 0, 4, 'HOURS', 4.7, 'Зеленая тропа Пурпурной горы', 'Purple Mountain Greenway Trail', 'Күлгін тау жасыл соқпағы', 'Нанкинский лесной маршрут вокруг Пурпурной горы, соединяющий природные склоны, культурные остановки и спокойный городской хайк.', 'A Nanjing forest route around Purple Mountain, connecting natural slopes, cultural stops and a calm urban hike.', 'Нанкиндегі Күлгін тау маңындағы орман бағыты: табиғи беткейлерді, мәдени аялдамаларды және тыныш қалалық хайкті байланыстырады.', 32.06100000, 118.84900000, 'Nanjing_Ming_Xiaoling_Mausoleum.jpg', ARRAY['nanjing']::text[], ARRAY['nanjing']::text[], ARRAY['china','nanjing','purple-mountain','forest','heritage']::text[]),
    ('IN', 'INR', 'nongriat-double-decker-root-bridge-trail', 'shillong', 'NATURE', 100, 6, 'HOURS', 4.8, 'Тропа к двухъярусному корневому мосту Нонгриат', 'Nongriat Double-Decker Root Bridge Trail', 'Нонгриат екі қабатты тамыр көпірі соқпағы', 'Длинный лесной маршрут Мегхалаи по ступеням, влажным склонам и живым корневым мостам для подготовленного дневного выхода.', 'A long Meghalaya forest route over steps, humid slopes and living root bridges for a prepared day outing.', 'Мегхалаядағы ұзақ орман бағыты: сатылар, ылғалды беткейлер және тірі тамыр көпірлері арқылы дайын күндік сапарға арналған.', 25.24300000, 91.68500000, 'Darjeeling_Himalayan_Railway.jpg', ARRAY['shillong','cherrapunji']::text[], ARRAY['shillong']::text[], ARRAY['india','meghalaya','root-bridge','stairs','forest','trekking']::text[]),
    ('IN', 'INR', 'kanheri-caves-forest-trail', 'mumbai', 'NATURE', 100, 4, 'HOURS', 4.6, 'Лесная тропа пещер Канхери', 'Kanheri Caves Forest Trail', 'Канхери үңгірлері орман соқпағы', 'Маршрут Мумбаи через лес национального парка к древним пещерам, каменным ступеням и более прохладному зеленому сценарию.', 'A Mumbai route through national-park forest toward ancient caves, stone steps and a cooler green scenario.', 'Мумбайдағы ұлттық парк орманы арқылы көне үңгірлерге, тас сатыларға және салқынырақ жасыл сценарийге апаратын бағыт.', 19.20800000, 72.90600000, 'Gateway_of_India,_Mumbai.jpg', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], ARRAY['india','mumbai','kanheri','sanjay-gandhi','forest','heritage']::text[]),
    ('MY', 'MYR', 'bako-telok-pandan-kecil-trail', 'kuching', 'NATURE', 20, 4, 'HOURS', 4.8, 'Тропа Telok Pandan Kecil в Бако', 'Bako Telok Pandan Kecil Trail', 'Бакодағы Telok Pandan Kecil соқпағы', 'Маршрут Саравака через лес Бако к скальным берегам, пляжному виду и влажной тропической природе рядом с Кучингом.', 'A Sarawak route through Bako forest to rocky shores, a beach view and humid tropical nature near Kuching.', 'Кучинг маңындағы Саравак бағыты: Бако орманы, жартасты жағалау, жағажай көрінісі және ылғалды тропикалық табиғат.', 1.71700000, 110.46700000, 'Bako_National_Park_Sarawak.jpg', ARRAY['kuching']::text[], ARRAY['kuching']::text[], ARRAY['malaysia','sarawak','bako','beach-trail','forest']::text[]),
    ('LK', 'LKR', 'bambarakanda-to-lanka-ella-falls-trail', 'haputale', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа от Бамбараканды к Lanka Ella', 'Bambarakanda to Lanka Ella Falls Trail', 'Бамбаракандадан Lanka Ella-ға соқпақ', 'Горный маршрут Хапутале через лесные склоны, водопадные точки и чайный высокогорный ландшафт.', 'A Haputale highland route through forested slopes, waterfall points and tea-country mountain scenery.', 'Хапутале биігіндегі орманды беткейлер, сарқырама нүктелері және шайлы тау ландшафты арқылы өтетін бағыт.', 6.77300000, 80.83100000, 'Bambarakanda_Falls.jpg', ARRAY['haputale','ella']::text[], ARRAY['haputale']::text[], ARRAY['sri-lanka','haputale','waterfall','forest','day-hike']::text[]);

CREATE TEMP TABLE seed_global_subagent_outdoor_routes_resolved_places AS
SELECT
    ('122d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['global-subagent-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_global_subagent_outdoor_routes_places;

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
FROM seed_global_subagent_outdoor_routes_resolved_places
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
FROM seed_global_subagent_outdoor_routes_resolved_places
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
FROM seed_global_subagent_outdoor_routes_resolved_places
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
FROM seed_global_subagent_outdoor_routes_resolved_places
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
FROM seed_global_subagent_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_global_subagent_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_global_subagent_outdoor_routes_places;
