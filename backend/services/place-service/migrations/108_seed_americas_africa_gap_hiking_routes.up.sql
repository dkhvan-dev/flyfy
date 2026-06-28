-- Americas and Africa gap route-level hiking/day-hike seed.
-- Adds concrete non-duplicate routes for hubs that already had broad landmarks or weak outdoor coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_americas_africa_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_americas_africa_gap_hiking_places;

CREATE TEMP TABLE seed_americas_africa_gap_hiking_places (
    slug varchar(96) PRIMARY KEY,
    country_code varchar(2) NOT NULL,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    price_amount numeric(12,2) NOT NULL,
    price_currency varchar(3) NOT NULL,
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
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_americas_africa_gap_hiking_places (
    slug,
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
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
    ('fairy-falls-grand-prismatic-overlook-trail', 'US', 'yellowstone', 'NATURE', 35, 'USD', 4, 'HOURS', 4.8, 'Тропа Fairy Falls и обзор Grand Prismatic', 'Fairy Falls and Grand Prismatic Overlook Trail', 'Fairy Falls және Grand Prismatic көрініс соқпағы', 'Маршрут по гейзерному району к водопаду, лесному участку и высокой обзорной точке над цветным термальным бассейном.', 'A geyser-basin route to a waterfall, forest section and elevated overlook above the colorful thermal basin.', 'Гейзерлі аймақ арқылы сарқырамаға, орман бөлігіне және түрлі түсті термалды бассейн үстіндегі көрініске апаратын бағыт.', 44.52000000, -110.83800000, 'Grand_Prismatic_Spring_2013.jpg', ARRAY['yellowstone']::text[], ARRAY['yellowstone']::text[], ARRAY['united-states','wyoming','thermal','waterfall','day-hike']::text[]),
    ('horseshoe-lake-trail-denali', 'US', 'denali', 'NATURE', 15, 'USD', 2, 'HOURS', 4.7, 'Тропа Horseshoe Lake', 'Horseshoe Lake Trail', 'Horseshoe Lake соқпағы', 'Короткая лесная петля у входной зоны Денали с озером, речной долиной и хорошим форматом разминки перед дальними выездами.', 'A short forest loop in the Denali entrance area with a lake, river valley and an easy warm-up format before longer trips.', 'Денали кіреберіс аймағындағы көл, өзен аңғары және ұзақ сапарлар алдындағы жеңіл дайындық форматы бар қысқа орман ілмегі.', 63.73600000, -148.89900000, 'Denali_National_Park.jpg', ARRAY['denali']::text[], ARRAY['denali']::text[], ARRAY['united-states','alaska','lake','forest','hiking']::text[]),
    ('powerline-pass-trail', 'US', 'anchorage', 'NATURE', 0, 'USD', 5, 'HOURS', 4.7, 'Тропа Powerline Pass', 'Powerline Pass Trail', 'Powerline Pass соқпағы', 'Долинный маршрут Чугача над Анкориджем с открытыми склонами, ручьями и видом на альпийские стены без технического рельефа.', 'A Chugach valley route above Anchorage with open slopes, creeks and alpine wall views without technical terrain.', 'Анкоридж үстіндегі Чугач аңғары бағыты: ашық беткейлер, бұлақтар және техникалық бедерсіз альпілік қабырғалар көрінісі.', 61.09100000, -149.62000000, 'Chugach_State_Park_Alaska.jpg', ARRAY['anchorage']::text[], ARRAY['anchorage']::text[], ARRAY['united-states','alaska','chugach','valley','free-entry','hiking']::text[]),
    ('sliding-sands-trail', 'US', 'maui', 'NATURE', 30, 'USD', 6, 'HOURS', 4.9, 'Тропа Sliding Sands', 'Sliding Sands Trail', 'Sliding Sands соқпағы', 'Высотный вулканический маршрут Мауи по красным конусам, сухим склонам и лунному рельефу кратерной зоны.', 'A high volcanic Maui route across red cones, dry slopes and moonlike crater terrain.', 'Мауидегі қызыл конустар, құрғақ беткейлер және кратер аймағының айға ұқсас бедері арқылы өтетін биік жанартаулық бағыт.', 20.71400000, -156.25000000, 'Haleakala_crater_Maui.jpg', ARRAY['maui']::text[], ARRAY['maui']::text[], ARRAY['united-states','hawaii','volcano','trekking']::text[]),
    ('makapuu-point-lighthouse-trail', 'US', 'honolulu', 'NATURE', 0, 'USD', 2, 'HOURS', 4.7, 'Тропа к маяку Makapuu Point', 'Makapuu Point Lighthouse Trail', 'Makapuu Point шамшырағына соқпақ', 'Короткий прибрежный маршрут Оаху к маяку, океанским обрывам и открытым видам на восточную сторону острова.', 'A short Oahu coastal route to a lighthouse, ocean cliffs and open views over the island east side.', 'Оахудың шығыс жағына ашық көрініс беретін маякқа, мұхит жартастарына апаратын қысқа жағалау бағыты.', 21.31000000, -157.65000000, 'Diamond_Head_Hawaii.jpg', ARRAY['honolulu']::text[], ARRAY['honolulu']::text[], ARRAY['united-states','hawaii','coastal','lighthouse','free-entry','walking']::text[]),
    ('quarry-rock-trail-vancouver', 'CA', 'vancouver', 'NATURE', 0, 'CAD', 2, 'HOURS', 4.7, 'Тропа Quarry Rock', 'Quarry Rock Trail', 'Quarry Rock соқпағы', 'Лесной маршрут северного берега Ванкувера к скальному виду на залив, острова и хвойные склоны.', 'A North Shore forest route from Vancouver area to a rocky view over the inlet, islands and conifer slopes.', 'Ванкувердің солтүстік жағалауындағы орман бағыты: шығанаққа, аралдарға және қылқанды беткейлерге қарайтын жартасты көрініске апарады.', 49.32700000, -122.94900000, 'Capilano_Suspension_Bridge.jpg', ARRAY['vancouver']::text[], ARRAY['vancouver']::text[], ARRAY['canada','british-columbia','north-shore','forest','free-entry','hiking']::text[]),
    ('mount-finlayson-trail', 'CA', 'victoria', 'NATURE', 0, 'CAD', 3, 'HOURS', 4.7, 'Тропа Mount Finlayson', 'Mount Finlayson Trail', 'Mount Finlayson соқпағы', 'Короткий, но крутой маршрут рядом с Викторией к скальным участкам и панорамам южного острова Ванкувер.', 'A short but steep route near Victoria to rocky sections and panoramas over southern Vancouver Island.', 'Виктория маңындағы қысқа, бірақ тік бағыт: тасты бөліктер мен оңтүстік Ванкувер аралы панорамаларына апарады.', 48.48400000, -123.53600000, 'Beacon_Hill_Park_Victoria.jpg', ARRAY['victoria']::text[], ARRAY['victoria']::text[], ARRAY['canada','british-columbia','summit','free-entry','hiking']::text[]),
    ('north-head-trail-st-johns', 'CA', 'st-johns', 'NATURE', 0, 'CAD', 3, 'HOURS', 4.8, 'Тропа North Head', 'North Head Trail', 'North Head соқпағы', 'Прибрежная тропа Сент-Джонса по склонам над гаванью, с видом на Атлантику, скалы и исторический берег.', 'A St. Johns coastal trail on slopes above the harbour, with Atlantic, cliff and historic shoreline views.', 'Сент-Джонс айлағы үстіндегі беткейлермен өтетін жағалау соқпағы: Атлантика, жартастар және тарихи жағалау көріністері.', 47.57100000, -52.68200000, 'Signal_Hill_Newfoundland.jpg', ARRAY['st-johns']::text[], ARRAY['st-johns']::text[], ARRAY['canada','newfoundland','coastal','free-entry','walking']::text[]),
    ('grey-mountain-ridge-trail', 'CA', 'whitehorse', 'NATURE', 0, 'CAD', 6, 'HOURS', 4.7, 'Гребневая тропа Grey Mountain', 'Grey Mountain Ridge Trail', 'Grey Mountain жотасы соқпағы', 'Маршрут над Уайтхорсом к северному гребню, открытым видам на долину Юкона и спокойному горному формату.', 'A route above Whitehorse toward a northern ridge, open Yukon valley views and a calm mountain format.', 'Уайтхорс үстіндегі солтүстік жотаға, Юкон аңғары көріністеріне және тыныш тау форматына апаратын бағыт.', 60.68400000, -134.89200000, 'Miles_Canyon_Yukon.jpg', ARRAY['whitehorse']::text[], ARRAY['whitehorse']::text[], ARRAY['canada','yukon','ridge','free-entry','hiking']::text[]),
    ('cerro-de-la-silla-trail', 'MX', 'monterrey', 'NATURE', 0, 'MXN', 6, 'HOURS', 4.8, 'Тропа Cerro de la Silla', 'Cerro de la Silla Trail', 'Cerro de la Silla соқпағы', 'Сильный маршрут Монтеррея к узнаваемому силуэту горы, сухим склонам и широкому виду на городскую долину.', 'A strong Monterrey route to the city signature mountain silhouette, dry slopes and wide views over the valley.', 'Монтеррейдің танымал тау сұлбасына, құрғақ беткейлерге және қала аңғарына кең көрініске апаратын қарқынды бағыт.', 25.62600000, -100.23100000, 'Catedral de Guadalajara.jpg', ARRAY['monterrey']::text[], ARRAY['monterrey']::text[], ARRAY['mexico','nuevo-leon','summit','free-entry','trekking']::text[]),
    ('boca-tomatlan-las-animas-trail', 'MX', 'puerto-vallarta', 'NATURE', 0, 'MXN', 4, 'HOURS', 4.8, 'Тропа Boca de Tomatlan - Las Animas', 'Boca de Tomatlan to Las Animas Trail', 'Boca de Tomatlan-нан Las Animas-қа соқпақ', 'Береговой маршрут южнее Пуэрто-Вальярты через маленькие бухты, джунгли и пляжные участки с гибкой логистикой на лодке.', 'A coastal route south of Puerto Vallarta through small coves, jungle and beach sections with flexible boat logistics.', 'Пуэрто-Вальяртаның оңтүстігіндегі шағын бухталар, джунгли және жағажай бөліктері арқылы өтетін, қайықпен икемді логистикасы бар бағыт.', 20.50800000, -105.31900000, 'Malecon, Puerto Vallarta (27212709499).jpg', ARRAY['puerto-vallarta']::text[], ARRAY['puerto-vallarta']::text[], ARRAY['mexico','jalisco','coastal','free-entry','hiking']::text[]),
    ('muyil-sian-kaan-boardwalk-trail', 'MX', 'tulum', 'NATURE', 100, 'MXN', 3, 'HOURS', 4.7, 'Настильная тропа Muyil и Sian Ka''an', $$Muyil Sian Ka'an Boardwalk Trail$$, 'Muyil және Sian Ka''an настил соқпағы', 'Маршрут Тулума по деревянным настилам, лагунам и тропическому лесу, который дает спокойный природный сценарий без пляжной толпы.', 'A Tulum route on wooden boardwalks, lagoons and tropical forest, giving a calm nature scenario away from beach crowds.', 'Тулумдағы ағаш төсемдер, лагуналар және тропикалық орман арқылы өтетін, жағажайдағы көпшіліктен алыстау тыныш табиғи бағыт.', 20.07800000, -87.61700000, 'Hotel Zone in Cancun, Mexico.jpg', ARRAY['tulum']::text[], ARRAY['tulum']::text[], ARRAY['mexico','quintana-roo','boardwalk','lagoon','walking']::text[]),
    ('macuco-trail-iguazu', 'BR', 'foz-do-iguacu', 'NATURE', 97, 'BRL', 3, 'HOURS', 4.8, 'Тропа Macuco в Игуасу', 'Macuco Trail Iguazu', 'Игуасудағы Macuco соқпағы', 'Лесной маршрут Фос-ду-Игуасу через влажную атлантическую зелень к тихим участкам и водопадной атмосфере.', 'A Foz do Iguacu forest route through humid Atlantic greenery toward quiet sections and waterfall atmosphere.', 'Фос-ду-Игуасудағы ылғалды атлантикалық жасыл орман арқылы тыныш бөліктер мен сарқырама атмосферасына апаратын бағыт.', -25.62200000, -54.45000000, 'Iguazu-Falls-January-2013.jpg', ARRAY['foz-do-iguacu']::text[], ARRAY['foz-do-iguacu']::text[], ARRAY['brazil','parana','atlantic-forest','hiking']::text[]),
    ('lagoa-bonita-dune-trail', 'BR', 'lencois-maranhenses', 'NATURE', 0, 'BRL', 4, 'HOURS', 4.9, 'Дюнная тропа Lagoa Bonita', 'Lagoa Bonita Dune Trail', 'Lagoa Bonita құмды соқпағы', 'Маршрут по белым дюнам к сезонным лагунам и высокому виду на песчаный ландшафт северо-восточной Бразилии.', 'A route over white dunes toward seasonal lagoons and a high view over the sandy landscape of northeast Brazil.', 'Бразилияның солтүстік-шығысындағы ақ құмдар, маусымдық лагуналар және құмды ландшафтқа биік көрініс беретін бағыт.', -2.61000000, -43.11300000, 'Lençóis Maranhenses 2018.jpg', ARRAY['lencois-maranhenses']::text[], ARRAY['lencois-maranhenses','sao-luis']::text[], ARRAY['brazil','maranhao','dunes','lagoon','free-entry','walking']::text[]),
    ('boca-da-onca-waterfall-trail', 'BR', 'bonito', 'NATURE', 300, 'BRL', 5, 'HOURS', 4.8, 'Тропа водопада Boca da Onca', 'Boca da Onca Waterfall Trail', 'Boca da Onca сарқырамасы соқпағы', 'Маршрут региона Бонито по лесным ступеням, прозрачным ручьям и нескольким водопадным точкам для активного дня.', 'A Bonito area route on forest steps, clear streams and multiple waterfall stops for an active day.', 'Бонито аймағындағы орман баспалдақтары, мөлдір бұлақтар және бірнеше сарқырама нүктелері арқылы өтетін белсенді күн бағыты.', -21.13100000, -56.73000000, 'Lençóis Maranhenses 2018.jpg', ARRAY['bonito']::text[], ARRAY['bonito']::text[], ARRAY['brazil','mato-grosso-do-sul','waterfalls','hiking']::text[]),
    ('veu-de-noiva-waterfall-trail-cuiaba', 'BR', 'cuiaba', 'NATURE', 0, 'BRL', 3, 'HOURS', 4.7, 'Тропа водопада Veu de Noiva', 'Veu de Noiva Waterfall Trail', 'Veu de Noiva сарқырамасы соқпағы', 'Маршрут из Куябы к красным стенам, серрадо и обзорным точкам над водопадом в горной части региона.', 'A Cuiaba area route to red walls, cerrado vegetation and viewpoints above a waterfall in the upland section.', 'Куяба маңындағы қызыл қабырғаларға, серрадо өсімдіктеріне және таулы бөліктегі сарқырама үстіндегі көріністерге апаратын бағыт.', -15.41000000, -55.82900000, 'Lençóis Maranhenses 2018.jpg', ARRAY['cuiaba']::text[], ARRAY['cuiaba']::text[], ARRAY['brazil','mato-grosso','waterfall','free-entry','hiking']::text[]),
    ('glacier-balcony-boardwalk-trail', 'AR', 'el-calafate', 'NATURE', 0, 'ARS', 3, 'HOURS', 4.9, 'Настильная тропа ледниковых балконов', 'Glacier Balcony Boardwalk Trail', 'Мұздық балкондары настил соқпағы', 'Серия настильных дорожек Эль-Калафате к ледовой стене, смотровым балконам и безопасным углам для медленной прогулки.', 'A set of El Calafate boardwalks toward the ice wall, viewing balconies and safe angles for a slow walk.', 'Эль-Калафатедегі мұз қабырғасына, көрініс балкондарына және баяу серуенге қауіпсіз нүктелерге апаратын настил жолдар жүйесі.', -50.48600000, -73.03500000, 'PeritoMoreno005.jpg', ARRAY['el-calafate']::text[], ARRAY['el-calafate']::text[], ARRAY['argentina','patagonia','glacier-view','boardwalk','walking']::text[]),
    ('laguna-de-horcones-trail', 'AR', 'aconcagua', 'NATURE', 0, 'ARS', 3, 'HOURS', 4.8, 'Тропа Laguna de Horcones', 'Laguna de Horcones Trail', 'Laguna de Horcones соқпағы', 'Высокогорная тропа у Аконкагуа к лагуне, моренным видам и первым панорамам большой Андской стены.', 'A high Andean trail near Aconcagua toward a lagoon, moraine views and first panoramas of the great mountain wall.', 'Аконкагуа маңындағы лагунаға, мореналық көріністерге және үлкен Анд қабырғасының алғашқы панорамаларына апаратын биіктау соқпағы.', -32.80600000, -69.95500000, 'Aconcagua Provincial Park 01.jpg', ARRAY['aconcagua','uspallata']::text[], ARRAY['mendoza','uspallata','aconcagua']::text[], ARRAY['argentina','mendoza','andes','lagoon','trekking']::text[]),
    ('purmamarca-colorados-loop', 'AR', 'purmamarca', 'NATURE', 0, 'ARS', 2, 'HOURS', 4.7, 'Цветная петля Пурмамарки', 'Purmamarca Colorados Loop', 'Пурмамарка түсті ілмегі', 'Короткая прогулка вокруг красных холмов Пурмамарки с мягким рельефом, сухими оврагами и светом северо-запада Аргентины.', 'A short walk around Purmamarca red hills with gentle terrain, dry gullies and northwest Argentina light.', 'Пурмамарканың қызыл төбелері маңындағы қысқа серуен: жұмсақ бедер, құрғақ жыралар және Аргентинаның солтүстік-батыс жарығы.', -23.74600000, -65.49900000, 'Cerro de los Siete Colores 03.jpg', ARRAY['purmamarca']::text[], ARRAY['purmamarca','jujuy']::text[], ARRAY['argentina','jujuy','red-hills','free-entry','walking']::text[]),
    ('los-aquaticos-trail', 'CU', 'vinales', 'NATURE', 10, 'CUP', 4, 'HOURS', 4.7, 'Тропа Los Aquaticos', 'Los Aquaticos Trail', 'Los Aquaticos соқпағы', 'Маршрут Виньялеса к сельским склонам, табачным полям и виду на моготы без повторения основных смотровых точек.', 'A Vinales route to rural slopes, tobacco fields and mogote views without repeating the main viewpoints.', 'Виньялестегі ауылдық беткейлерге, темекі алқаптарына және негізгі көрініс нүктелерін қайталамайтын моготе көріністеріне апаратын бағыт.', 22.62700000, -83.73500000, 'CUBA._VINALES_(8).jpg', ARRAY['vinales']::text[], ARRAY['vinales']::text[], ARRAY['cuba','pinar-del-rio','mogotes','hiking']::text[]),
    ('el-yunque-summit-trail-baracoa', 'CU', 'baracoa', 'NATURE', 10, 'CUP', 5, 'HOURS', 4.8, 'Тропа на вершину Эль-Юнке', 'El Yunque Summit Trail', 'Эль-Юнке шыңы соқпағы', 'Влажный маршрут Баракоа по тропическому лесу к плоской вершине, реке и видам на побережье восточной Кубы.', 'A humid Baracoa route through tropical forest to a flat summit, river and views over Cuba east coast.', 'Баракоадағы тропикалық орман арқылы жалпақ шыңға, өзенге және Кубаның шығыс жағалауына көрініске апаратын ылғалды бағыт.', 20.34500000, -74.57100000, 'Baracoa_-_El_Yunque.jpg', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], ARRAY['cuba','baracoa','rainforest','summit','hiking']::text[]),
    ('sinai-sunrise-steps-trail', 'EG', 'saint-catherine', 'NATURE', 200, 'EGP', 5, 'HOURS', 4.8, 'Рассветная тропа ступеней Синая', 'Sinai Sunrise Steps Trail', 'Синай таңғы сатылар соқпағы', 'Ночной и раннеутренний маршрут района Святой Екатерины по каменным ступеням к высокому рассветному виду.', 'A night-to-early-morning Saint Catherine area route on stone steps toward a high sunrise viewpoint.', 'Әулие Екатерина аймағындағы тас сатылармен жоғары таңғы көрініске апаратын түнгі және ерте таңғы бағыт.', 28.53900000, 33.97500000, 'Mount_Sinai_Egypt.jpg', ARRAY['saint-catherine','dahab','sharm-el-sheikh']::text[], ARRAY['saint-catherine','dahab']::text[], ARRAY['egypt','sinai','sunrise','trekking']::text[]),
    ('magic-lake-dune-walk', 'EG', 'fayoum', 'NATURE', 50, 'EGP', 3, 'HOURS', 4.6, 'Дюнная прогулка Magic Lake', 'Magic Lake Dune Walk', 'Magic Lake құмды серуені', 'Пустынная прогулка Фаюма к тихому озеру, песчаным грядам и мягкому вечернему свету для короткого outdoor-сценария.', 'A Fayoum desert walk to a quiet lake, sandy ridges and soft evening light for a short outdoor scenario.', 'Фаюмдағы тыныш көлге, құмды жоталарға және жұмсақ кешкі жарыққа апаратын қысқа outdoor серуені.', 29.19100000, 30.40000000, 'Wadi_El_Rayan_Egypt.jpg', ARRAY['fayoum','cairo']::text[], ARRAY['fayoum','cairo']::text[], ARRAY['egypt','fayoum','desert-lake','walking']::text[]),
    ('setti-fatma-waterfalls-trail', 'MA', 'ourika', 'NATURE', 0, 'MAD', 4, 'HOURS', 4.7, 'Тропа водопадов Setti Fatma', 'Setti Fatma Waterfalls Trail', 'Setti Fatma сарқырамалары соқпағы', 'Горный маршрут долины Урики к каскадам, каменным ступеням и берберским селам на склонах Высокого Атласа.', 'A mountain route in the Ourika area toward cascades, stone steps and Berber villages on High Atlas slopes.', 'Урика аймағындағы каскадтарға, тасты сатыларға және Биік Атлас беткейіндегі бербер ауылдарына апаратын тау бағыты.', 31.22500000, -7.67400000, 'Jemaa_el-Fnaa_at_night.jpg', ARRAY['ourika','marrakech']::text[], ARRAY['ourika','marrakech']::text[], ARRAY['morocco','high-atlas','waterfalls','free-entry','hiking']::text[]),
    ('naro-moru-river-trail', 'KE', 'mount-kenya', 'NATURE', 3000, 'KES', 6, 'HOURS', 4.8, 'Тропа реки Наро-Мору', 'Naro Moru River Trail', 'Наро-Мору өзені соқпағы', 'Высотный маршрут района горы Кения вдоль леса, реки и открывающихся вересковых склонов для подготовленного дневного плана.', 'A Mount Kenya area highland route along forest, river and opening moorland slopes for a prepared day plan.', 'Кения тауы аймағындағы орман, өзен және ашық вереск беткейлері бойымен өтетін дайын күндік бағыт.', -0.17000000, 37.22000000, 'Mount_Kenya.jpg', ARRAY['mount-kenya','nanyuki','nyeri']::text[], ARRAY['nanyuki','nyeri','nairobi']::text[], ARRAY['kenya','mount-kenya-area','river','trekking']::text[]),
    ('hells-gate-gorge-walk', 'KE', 'hells-gate', 'NATURE', 3000, 'KES', 4, 'HOURS', 4.7, 'Прогулка по ущелью Хеллс-Гейт', $$Hell's Gate Gorge Walk$$, 'Хеллс-Гейт шатқалы серуені', 'Пеший маршрут среди узких стен, вулканического рельефа и открытой саванны рядом с Найвашей.', 'A walking route among narrow walls, volcanic terrain and open savanna near Naivasha.', 'Найваша маңындағы тар қабырғалар, жанартаулық бедер және ашық саванна арасындағы жаяу бағыт.', -0.90800000, 36.31900000, 'Hells_Gate_National_Park.jpg', ARRAY['hells-gate','naivasha']::text[], ARRAY['naivasha','nairobi']::text[], ARRAY['kenya','rift-valley','gorge','walking']::text[]),
    ('marangu-mandara-hut-trail', 'TZ', 'kilimanjaro', 'NATURE', 70000, 'TZS', 7, 'HOURS', 4.8, 'Тропа Marangu к хижине Mandara', 'Marangu Mandara Hut Trail', 'Marangu Mandara Hut соқпағы', 'Лесной маршрут Килиманджаро от ворот Марангу к первой горной хижине, влажному лесу и постепенному набору высоты.', 'A Kilimanjaro forest route from Marangu Gate toward the first mountain hut, humid forest and gradual elevation gain.', 'Килиманджародағы Марангу қақпасынан алғашқы тау хижинасына, ылғалды орманға және біртіндеп биіктік жинауға апаратын орман бағыты.', -3.18500000, 37.52000000, 'Kilimanjaro_from_Amboseli_National_Park.jpg', ARRAY['kilimanjaro','moshi']::text[], ARRAY['moshi','kilimanjaro']::text[], ARRAY['tanzania','kilimanjaro','forest','trekking']::text[]);

CREATE TEMP TABLE seed_americas_africa_gap_hiking_resolved_places AS
SELECT
    ('108d0000-0000-4000-8000-' || substr(md5(slug), 1, 12))::uuid AS id,
    slug,
    country_code,
    city_id,
    category,
    price_amount,
    price_currency,
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
        substr(md5(slug || ':media'), 1, 8) || '-' ||
        substr(md5(slug || ':media'), 9, 4) || '-4' ||
        substr(md5(slug || ':media'), 14, 3) || '-8' ||
        substr(md5(slug || ':media'), 18, 3) || '-' ||
        substr(md5(slug || ':media'), 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(media_file, ' ', '%20') || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || replace(media_file, ' ', '_') AS media_source_url,
    ARRAY['americas-africa-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_americas_africa_gap_hiking_places;

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
FROM seed_americas_africa_gap_hiking_resolved_places
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
FROM seed_americas_africa_gap_hiking_resolved_places
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
FROM seed_americas_africa_gap_hiking_resolved_places
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
FROM seed_americas_africa_gap_hiking_resolved_places
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
FROM seed_americas_africa_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_americas_africa_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_americas_africa_gap_hiking_places;
