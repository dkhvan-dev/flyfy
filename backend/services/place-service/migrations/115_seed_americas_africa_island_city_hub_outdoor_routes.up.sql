-- Americas, Africa and island city-hub outdoor route seed.
-- Adds route-level walks and hikes for reference hubs still missing concrete outdoor coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_americas_africa_island_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_americas_africa_island_city_hub_outdoor_routes_places;

CREATE TEMP TABLE seed_americas_africa_island_city_hub_outdoor_routes_places (
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

INSERT INTO seed_americas_africa_island_city_hub_outdoor_routes_places (
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
    ('US', 'USD', 'lands-end-trail', 'san-francisco', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Лэндс-Энд', 'Lands End Trail', 'Лэндс-Энд соқпағы', 'Прибрежный маршрут Сан-Франциско по утесам, кипарисам, океанскому ветру и видам на мост и залив.', 'A San Francisco coastal route across cliffs, cypress trees, ocean wind and views toward the bridge and bay.', 'Сан-Францискодағы жартастар, кипаристер, мұхит желі және көпір мен шығанаққа көріністер арқылы өтетін жағалау бағыты.', 37.78600000, -122.50600000, 'Golden_Gate_Park_Aerial.jpg', ARRAY['san-francisco']::text[], ARRAY['san-francisco']::text[], ARRAY['united-states','california','coastal-trail','free-entry','walking']::text[]),
    ('US', 'USD', 'calico-tanks-trail', 'las-vegas', 'NATURE', 20, 3, 'HOURS', 4.8, 'Тропа Калико-Тэнкс', 'Calico Tanks Trail', 'Калико-Тэнкс соқпағы', 'Пустынный маршрут у Лас-Вегаса через красные песчаниковые формы, сухие чаши и вид на городскую долину.', 'A Las Vegas desert route through red sandstone forms, dry basins and a view toward the urban valley.', 'Лас-Вегас маңындағы қызыл құмтас пішіндер, құрғақ ойыстар және қала аңғарына көрініс арқылы өтетін шөл бағыты.', 36.16200000, -115.45000000, 'Red_Rock_Canyon_Nevada_2013.jpg', ARRAY['las-vegas']::text[], ARRAY['las-vegas']::text[], ARRAY['united-states','nevada','red-rock','hiking']::text[]),
    ('CA', 'CAD', 'nose-hill-prairie-loop', 'calgary', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прерийная петля Ноз-Хилл', 'Nose Hill Prairie Loop', 'Ноз-Хилл прерия ілмегі', 'Городской outdoor-маршрут Калгари по холмам прерии, сухой траве и широким видам на центр и Скалистые горы.', 'A Calgary urban outdoor route over prairie hills, dry grass and wide views toward downtown and the Rockies.', 'Калгаридегі прерия төбелері, құрғақ шөп және орталық пен Жартасты тауларға кең көріністер арқылы өтетін қалалық outdoor бағыты.', 51.11300000, -114.10900000, 'Princes_Island_Park_Calgary.jpg', ARRAY['calgary']::text[], ARRAY['calgary']::text[], ARRAY['canada','calgary','prairie','free-entry','walking']::text[]),
    ('BR', 'BRL', 'musa-forest-tower-trail', 'manaus', 'NATURE', 30, 2, 'HOURS', 4.7, 'Лесная тропа башни MUSA', 'MUSA Forest Tower Trail', 'MUSA орман мұнарасы соқпағы', 'Амазонский городской маршрут Манауса по настилам, влажному лесу и смотровой башне над кронами деревьев.', 'A Manaus urban Amazon route along boardwalks, humid forest and a canopy tower above the trees.', 'Манаустағы Амазон қалалық бағыты: тақтайжолдар, ылғалды орман және ағаштар үстіндегі бақылау мұнарасы.', -3.00200000, -59.94000000, 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg', ARRAY['manaus']::text[], ARRAY['manaus']::text[], ARRAY['brazil','amazon','forest-boardwalk','walking']::text[]),
    ('BR', 'BRL', 'cantareira-pedra-grande-trail', 'sao-paulo', 'NATURE', 50, 3, 'HOURS', 4.7, 'Тропа Педра-Гранде в Кантарейре', 'Cantareira Pedra Grande Trail', 'Кантарейра Педра-Гранде соқпағы', 'Маршрут Сан-Паулу через атлантический лес к каменной площадке с видом на огромный городской горизонт.', 'A Sao Paulo route through Atlantic forest toward a rocky viewpoint over the vast city skyline.', 'Сан-Паулудағы Атлантикалық орман арқылы қаланың үлкен көкжиегіне қарайтын тасты көрініс алаңына апаратын бағыт.', -23.45600000, -46.63200000, 'Ibirapuera_Park_in_Sao_Paulo.jpg', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], ARRAY['brazil','sao-paulo','atlantic-forest','hiking']::text[]),
    ('AR', 'ARS', 'cerro-arco-summit-trail', 'mendoza', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа на вершину Серро-Арко', 'Cerro Arco Summit Trail', 'Серро-Арко шыңы соқпағы', 'Сухой предгорный маршрут Мендосы к обзорной вершине, андским линиям горизонта и активному полудню рядом с городом.', 'A dry Mendoza foothill route to a viewpoint summit, Andean horizon lines and an active half day near the city.', 'Мендоса маңындағы құрғақ тау етегі бағыты: көріністі шыңға, Анд көкжиегіне және қала жанындағы белсенді жарты күнге апарады.', -32.84600000, -68.93100000, 'Aconcagua Provincial Park 01.jpg', ARRAY['mendoza']::text[], ARRAY['mendoza']::text[], ARRAY['argentina','mendoza','foothills','free-entry','hiking']::text[]),
    ('AR', 'ARS', 'salta-hill-stairs-trail', 'salta', 'NATURE', 0, 2, 'HOURS', 4.5, 'Лестничная тропа холма Сальты', 'Salta Hill Stairs Trail', 'Сальта төбесі баспалдақ соқпағы', 'Короткий городской подъем Сальты по лестницам и зеленым склонам к панораме долины и исторического центра.', 'A short Salta city climb by stairs and green slopes toward a panorama of the valley and historic center.', 'Сальтадағы баспалдақтар мен жасыл беткейлер арқылы аңғар мен тарихи орталық панорамасына шығатын қысқа қалалық көтерілу.', -24.78600000, -65.39300000, 'Cathedral of Salta 02.jpg', ARRAY['salta']::text[], ARRAY['salta']::text[], ARRAY['argentina','salta','city-view','free-entry','walking']::text[]),
    ('CU', 'CUP', 'cayo-guillermo-dune-coastal-walk', 'cayo-guillermo', 'NATURE', 0, 2, 'HOURS', 4.6, 'Дюнная прогулка Кайо-Гильермо', 'Cayo Guillermo Dune Coastal Walk', 'Кайо-Гильермо құмды жағалау серуені', 'Короткий островной маршрут по песчаным грядам, бирюзовой воде и открытым береговым видам северной Кубы.', 'A short island route across sandy ridges, turquoise water and open northern Cuba coastal views.', 'Кубаның солтүстігіндегі құмды жоталар, көгілдір су және ашық жағалау көріністері арқылы өтетін қысқа арал бағыты.', 22.61200000, -78.68700000, 'Cuba_-_Cayo_Coco.jpg', ARRAY['cayo-guillermo']::text[], ARRAY['cayo-guillermo','cayo-coco']::text[], ARRAY['cuba','cayo-guillermo','dunes','free-entry','walking']::text[]),
    ('EG', 'EGP', 'ras-mohammed-mangrove-boardwalk', 'sharm-el-sheikh', 'NATURE', 5, 2, 'HOURS', 4.7, 'Мангровый настил Рас-Мохаммеда', 'Ras Mohammed Mangrove Boardwalk', 'Рас-Мохаммед мангр тақтайжолы', 'Маршрут Шарм-эль-Шейха у мангров, мелководий и пустынно-морского края для спокойного природного выхода.', 'A Sharm El Sheikh route by mangroves, shallows and the desert-sea edge for a calm nature outing.', 'Шарм-эль-Шейхтегі мангрлар, тайыз сулар және шөл мен теңіз шеті арқылы өтетін тыныш табиғи бағыт.', 27.74200000, 34.24700000, 'Ras_Mohammed_National_Park.jpg', ARRAY['sharm-el-sheikh']::text[], ARRAY['sharm-el-sheikh']::text[], ARRAY['egypt','sinai','mangrove','boardwalk','walking']::text[]),
    ('KE', 'KES', 'karura-waterfall-loop', 'nairobi', 'NATURE', 100, 3, 'HOURS', 4.7, 'Петля к водопаду Карура', 'Karura Waterfall Loop', 'Карура сарқырамасы ілмегі', 'Лесной маршрут Найроби по тенистым дорожкам, ручьям и водопадной точке для быстрого выхода на природу.', 'A Nairobi forest route along shaded paths, streams and a waterfall point for quick access to nature.', 'Найробидегі көлеңкелі жолдар, бұлақтар және табиғатқа жылдам шығуға арналған сарқырама нүктесі арқылы өтетін орман бағыты.', -1.23600000, 36.83300000, 'Karura_Forest.jpg', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], ARRAY['kenya','nairobi','urban-forest','waterfall','walking']::text[]),
    ('TZ', 'TZS', 'ngurdoto-crater-view-trail', 'arusha', 'NATURE', 15000, 3, 'HOURS', 4.7, 'Тропа к виду на кратер Нгурдото', 'Ngurdoto Crater View Trail', 'Нгурдото кратері көрініс соқпағы', 'Маршрут у Аруши к лесным участкам, обзорным точкам кратера и мягкому вулканическому ландшафту.', 'An Arusha-area route to forest sections, crater viewpoints and a gentle volcanic landscape.', 'Аруша маңындағы орман бөліктеріне, кратер көрініс нүктелеріне және жұмсақ жанартаулық ландшафтқа апаратын бағыт.', -3.22700000, 36.85300000, 'Arusha_National_Park.jpg', ARRAY['arusha']::text[], ARRAY['arusha']::text[], ARRAY['tanzania','arusha','crater-view','walking']::text[]),
    ('TZ', 'TZS', 'pugu-hills-forest-trail', 'dar-es-salaam', 'NATURE', 5000, 4, 'HOURS', 4.5, 'Лесная тропа холмов Пугу', 'Pugu Hills Forest Trail', 'Пугу төбелері орман соқпағы', 'Маршрут Дар-эс-Салама к сухому прибрежному лесу, холмам и тенистым участкам недалеко от города.', 'A Dar es Salaam route to dry coastal forest, hills and shaded sections not far from the city.', 'Дар-эс-Салам маңындағы құрғақ жағалау орманына, төбелерге және көлеңкелі бөліктерге апаратын бағыт.', -6.90900000, 39.09000000, 'Dar_es_Salaam_skyline.jpg', ARRAY['dar-es-salaam']::text[], ARRAY['dar-es-salaam']::text[], ARRAY['tanzania','dar-es-salaam','coastal-forest','hiking']::text[]),
    ('TZ', 'TZS', 'uluguru-bondwa-peak-trail', 'morogoro', 'NATURE', 0, 6, 'HOURS', 4.7, 'Тропа на пик Бондва в Улугуру', 'Uluguru Bondwa Peak Trail', 'Улугуру Бондва шыңы соқпағы', 'Горный маршрут Морогорo через влажные склоны, деревни и видовые гребни Восточной дуги.', 'A Morogoro mountain route through humid slopes, villages and scenic ridges of the Eastern Arc.', 'Морогоро маңындағы ылғалды беткейлер, ауылдар және Шығыс доғаның көріністі жоталары арқылы өтетін тау бағыты.', -6.84900000, 37.66700000, 'Morogoro_Tanzania.jpg', ARRAY['morogoro']::text[], ARRAY['morogoro','dar-es-salaam']::text[], ARRAY['tanzania','morogoro','eastern-arc','free-entry','trekking']::text[]),
    ('MA', 'MAD', 'tangier-atlantic-woodland-coastal-walk', 'tangier', 'NATURE', 0, 3, 'HOURS', 4.6, 'Атлантическая лесная прогулка Танжера', 'Tangier Atlantic Woodland Coastal Walk', 'Танжер Атлант орманды жағалау серуені', 'Маршрут Танжера через лесные участки, океанский ветер и скальные виды на месте встречи Атлантики и Средиземноморья.', 'A Tangier route through woodland sections, ocean wind and rocky views where the Atlantic meets the Mediterranean.', 'Танжердегі орманды бөліктер, мұхит желі және Атлант пен Жерорта теңізі түйісетін тасты көріністер арқылы өтетін бағыт.', 35.79000000, -5.93500000, 'Chefchaouen,_Rif_Mountains,_Morocco,_Blue_City.jpg', ARRAY['tangier']::text[], ARRAY['tangier']::text[], ARRAY['morocco','tangier','coastal-walk','free-entry','walking']::text[]),
    ('MA', 'MAD', 'marrakech-stone-desert-ridge-walk', 'marrakech', 'NATURE', 0, 4, 'HOURS', 4.6, 'Каменистая пустынная гребневая прогулка Марракеша', 'Marrakech Stone Desert Ridge Walk', 'Марракеш тасты шөл жотасы серуені', 'Маршрут у Марракеша по сухим каменистым грядам, открытым видам Атласа и спокойной пустынной тишине.', 'A Marrakech-area route across dry stony ridges, open Atlas views and quiet desert stillness.', 'Марракеш маңындағы құрғақ тасты жоталар, Атласқа ашық көріністер және тыныш шөл үнсіздігі арқылы өтетін бағыт.', 31.49800000, -8.06200000, 'Jemaa_el-Fnaa_at_night.jpg', ARRAY['marrakech']::text[], ARRAY['marrakech']::text[], ARRAY['morocco','marrakech','desert-ridge','free-entry','hiking']::text[]),
    ('AU', 'AUD', 'east-point-mangrove-boardwalk', 'darwin', 'NATURE', 0, 2, 'HOURS', 4.5, 'Мангровый настил Ист-Пойнта', 'East Point Mangrove Boardwalk', 'Ист-Пойнт мангр тақтайжолы', 'Тропический маршрут Дарвина по мангровым настилам, прибрежным зарослям и тихим точкам у залива.', 'A Darwin tropical route along mangrove decks, coastal vegetation and quiet points by the bay.', 'Дарвиндегі мангр тақтайжолдары, жағалау өсімдіктері және шығанақ жанындағы тыныш нүктелер арқылы өтетін тропикалық бағыт.', -12.41000000, 130.83600000, 'Darwin_(AU),_Darwin_Waterfront_--_2019_--_4423-5.jpg', ARRAY['darwin']::text[], ARRAY['darwin']::text[], ARRAY['australia','darwin','mangrove','free-entry','walking']::text[]),
    ('AU', 'AUD', 'one-thousand-steps-kokoda-track-memorial-walk', 'melbourne', 'NATURE', 0, 3, 'HOURS', 4.7, 'Мемориальная тропа 1000 Steps Kokoda', '1000 Steps Kokoda Track Memorial Walk', '1000 Steps Kokoda мемориалдық серуені', 'Лесной подъем недалеко от Мельбурна по ступеням, папоротникам и эвкалиптовым склонам для активного полудня.', 'A forest climb near Melbourne over steps, ferns and eucalyptus slopes for an active half day.', 'Мельбурн маңындағы баспалдақтар, қырыққұлақтар және эвкалипт беткейлері арқылы өтетін белсенді жарты күндік орман көтерілуі.', -37.88300000, 145.35000000, 'Melbourne_(AU),_View_from_Eureka_Tower,_Flinders_Street_Railway_Station_--_2019_--_1462.jpg', ARRAY['melbourne']::text[], ARRAY['melbourne']::text[], ARRAY['australia','victoria','forest-steps','free-entry','hiking']::text[]),
    ('AU', 'AUD', 'mount-coolum-summit-track', 'sunshine-coast', 'NATURE', 0, 2, 'HOURS', 4.7, 'Тропа на вершину Маунт-Кулум', 'Mount Coolum Summit Track', 'Маунт-Кулум шыңы соқпағы', 'Короткий маршрут Саншайн-Коста к вулканической вершине, океанским видам и береговой линии Квинсленда.', 'A short Sunshine Coast route to a volcanic summit, ocean views and the Queensland shoreline.', 'Саншайн-Косттағы жанартаулық шыңға, мұхит көріністеріне және Квинсленд жағалауына апаратын қысқа бағыт.', -26.56500000, 153.09100000, 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg', ARRAY['sunshine-coast']::text[], ARRAY['sunshine-coast','brisbane']::text[], ARRAY['australia','queensland','summit','free-entry','hiking']::text[]),
    ('NZ', 'NZD', 'mount-john-summit-track', 'tekapo', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа на вершину Маунт-Джон', 'Mount John Summit Track', 'Маунт-Джон шыңы соқпағы', 'Маршрут у Текапо к обзорной вершине с видом на ледниковое озеро, обсерваторию и сухие склоны Маккензи.', 'A Tekapo route to a viewpoint summit over the glacial lake, observatory and dry Mackenzie slopes.', 'Текапо маңындағы мұздық көлге, обсерваторияға және Маккензидің құрғақ беткейлеріне қарайтын көріністі шыңға апаратын бағыт.', -43.98600000, 170.46500000, 'Lake_Tekapo.jpg', ARRAY['tekapo']::text[], ARRAY['tekapo','christchurch']::text[], ARRAY['new-zealand','tekapo','summit','free-entry','walking']::text[]),
    ('NZ', 'NZD', 'papamoa-hills-track', 'tauranga', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа холмов Папамоа', 'Papamoa Hills Track', 'Папамоа төбелері соқпағы', 'Маршрут у Тауранги через зеленые холмы, фермерские склоны и виды на залив Пленти.', 'A Tauranga-area route through green hills, farm slopes and views over the Bay of Plenty.', 'Тауранга маңындағы жасыл төбелер, ферма беткейлері және Пленти шығанағына көріністер арқылы өтетін бағыт.', -37.74400000, 176.33300000, 'Tauranga_Waterfront.jpg', ARRAY['tauranga']::text[], ARRAY['tauranga','rotorua']::text[], ARRAY['new-zealand','tauranga','hills','free-entry','walking']::text[]),
    ('IE', 'EUR', 'ticknock-fairy-castle-loop', 'dublin', 'NATURE', 0, 3, 'HOURS', 4.7, 'Петля Тикнок - Фэйри-Касл', 'Ticknock Fairy Castle Loop', 'Тикнок - Фэйри-Касл ілмегі', 'Дублинский горный маршрут по лесным дорожкам, каменистым участкам и видам на город, залив и холмы Уиклоу.', 'A Dublin mountain route along forest paths, rocky sections and views of the city, bay and Wicklow hills.', 'Дублиндегі орман жолдары, тасты бөліктер және қалаға, шығанаққа, Уиклоу төбелеріне көріністер арқылы өтетін тау бағыты.', 53.25400000, -6.25000000, 'Phoenix_Park_Dublin.jpg', ARRAY['dublin']::text[], ARRAY['dublin']::text[], ARRAY['ireland','dublin','mountain-loop','free-entry','hiking']::text[]),
    ('IS', 'ISK', 'mount-esja-trail', 'reykjavik', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа горы Эсья', 'Mount Esja Trail', 'Эсья тауы соқпағы', 'Маршрут у Рейкьявика к склонам Эсьи, каменистым участкам и виду на городскую бухту.', 'A Reykjavik-area route to Esja slopes, rocky sections and views across the city bay.', 'Рейкьявик маңындағы Эсья беткейлеріне, тасты бөліктерге және қала шығанағына көріністерге апаратын бағыт.', 64.21000000, -21.71000000, 'Hallgrimskirkja Reykjavik Iceland.jpg', ARRAY['reykjavik']::text[], ARRAY['reykjavik']::text[], ARRAY['iceland','reykjavik','mountain','free-entry','hiking']::text[]),
    ('MT', 'EUR', 'victoria-lines-trail', 'valletta', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа Линий Виктории', 'Victoria Lines Trail', 'Виктория сызықтары соқпағы', 'Мальтийский маршрут по историческому оборонительному гребню, сельским видам и каменным тропам между городами острова.', 'A Malta route along a historic defensive ridge, rural views and stone paths between island towns.', 'Мальтадағы тарихи қорғаныс жотасы, ауылдық көріністер және арал қалалары арасындағы тас жолдар арқылы өтетін бағыт.', 35.91200000, 14.38200000, 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg', ARRAY['valletta','dingli']::text[], ARRAY['valletta']::text[], ARRAY['malta','ridge-walk','heritage','free-entry','hiking']::text[]),
    ('CY', 'EUR', 'cape-aspro-coastal-trail', 'limassol', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прибрежная тропа мыса Аспро', 'Cape Aspro Coastal Trail', 'Аспро мүйісі жағалау соқпағы', 'Кипрский маршрут у Лимасола по белым скалам, морскому ветру и открытым видам на южное побережье.', 'A Limassol-area Cyprus route over white cliffs, sea wind and open views of the southern coast.', 'Лимасол маңындағы ақ жартастар, теңіз желі және оңтүстік жағалауға ашық көріністер арқылы өтетін Кипр бағыты.', 34.66000000, 32.75600000, 'Limassol_01-2017_img20_Marina.jpg', ARRAY['limassol']::text[], ARRAY['limassol']::text[], ARRAY['cyprus','limassol','coastal-cliffs','free-entry','walking']::text[]),
    ('SC', 'SCR', 'trois-freres-trail', 'victoria', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа Труа-Фрер', 'Trois Freres Trail', 'Труа-Фрер соқпағы', 'Маршрут у Виктории на Маэ через гранитные склоны, влажную зелень и виды на порт и островные бухты.', 'A Victoria Mahe route over granite slopes, humid greenery and views of the port and island coves.', 'Маэ аралындағы Виктория маңында гранит беткейлер, ылғалды жасылдық және порт пен арал қойнауларына көріністер арқылы өтетін бағыт.', -4.63500000, 55.45400000, 'Victoria clock tower Seychelles.jpg', ARRAY['victoria','mahe']::text[], ARRAY['victoria','mahe']::text[], ARRAY['seychelles','mahe','granite','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_americas_africa_island_city_hub_outdoor_routes_resolved_places AS
SELECT
    ('115d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['americas-africa-island-city-hub-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_americas_africa_island_city_hub_outdoor_routes_places;

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
FROM seed_americas_africa_island_city_hub_outdoor_routes_resolved_places
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
FROM seed_americas_africa_island_city_hub_outdoor_routes_resolved_places
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
FROM seed_americas_africa_island_city_hub_outdoor_routes_resolved_places
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
FROM seed_americas_africa_island_city_hub_outdoor_routes_resolved_places
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
FROM seed_americas_africa_island_city_hub_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_americas_africa_island_city_hub_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_americas_africa_island_city_hub_outdoor_routes_places;
