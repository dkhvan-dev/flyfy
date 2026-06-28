-- Asia and Oceania gap route-level hiking/day-walk seed.
-- Adds concrete routes for hubs that already had broad place anchors but weak route-level outdoor coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_asia_oceania_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_asia_oceania_gap_hiking_places;

CREATE TEMP TABLE seed_asia_oceania_gap_hiking_places (
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

INSERT INTO seed_asia_oceania_gap_hiking_places (
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
    ('VN', 'VND', 'y-linh-ho-lao-chai-valley-trail', 'sa-pa', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа Y Linh Ho - Lao Chai', 'Y Linh Ho to Lao Chai Valley Trail', 'Y Linh Ho - Lao Chai аңғар соқпағы', 'Маршрут Сапы через террасные поля и деревни долины, с мягким набором высоты и сильным северным пейзажем.', 'A Sa Pa route through terraced fields and valley villages, with gentle elevation and a strong northern mountain landscape.', 'Сападағы террасалы алқаптар мен аңғар ауылдары арқылы өтетін бағыт, жеңіл биіктік жинау және солтүстік тау көрінісі бар.', 22.31400000, 103.87400000, 'M%C6%B0%E1%BB%9Dng_Hoa_Valley_06.jpg', ARRAY['sa-pa']::text[], ARRAY['sa-pa']::text[], ARRAY['vietnam','sa-pa','rice-terraces','trekking']::text[]),
    ('VN', 'VND', 'cuc-phuong-ancient-tree-trail', 'ninh-binh', 'NATURE', 60000, 4, 'HOURS', 4.7, 'Тропа древнего дерева Кукфыонга', 'Cuc Phuong Ancient Tree Trail', 'Кукфыонг көне ағаш соқпағы', 'Лесной маршрут Ниньбиня к старым деревьям, влажному тропическому лесу и тихому природному сценарию без лодочной программы.', 'A Ninh Binh forest route toward old trees, humid tropical woodland and a calm nature plan away from boat itineraries.', 'Ниньбиньдегі көне ағаштарға, ылғалды тропикалық орманға және қайықсыз тыныш табиғи жоспарға апаратын орман бағыты.', 20.31600000, 105.60900000, 'Cuc.Phuong.National.Park.jpg', ARRAY['ninh-binh']::text[], ARRAY['ninh-binh','hanoi']::text[], ARRAY['vietnam','ninh-binh','forest','day-hike']::text[]),
    ('TH', 'THB', 'black-rock-viewpoint-trail', 'phuket', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа к Black Rock Viewpoint', 'Black Rock Viewpoint Trail', 'Black Rock көрінісіне соқпақ', 'Короткий холмистый маршрут Пхукета к открытой точке над южным побережьем, пляжами и островной линией горизонта.', 'A short Phuket hill route to an open viewpoint over the south coast, beaches and island horizon.', 'Пхукеттегі оңтүстік жағалау, жағажайлар және арал көкжиегі көрінетін қысқа төбе бағыты.', 7.77500000, 98.30600000, 'The_Big_Buddha.jpg', ARRAY['phuket']::text[], ARRAY['phuket']::text[], ARRAY['thailand','phuket','viewpoint','walking']::text[]),
    ('TH', 'THB', 'john-suwan-viewpoint-trail', 'koh-tao', 'NATURE', 50, 2, 'HOURS', 4.7, 'Тропа к John-Suwan Viewpoint', 'John-Suwan Viewpoint Trail', 'John-Suwan көрінісіне соқпақ', 'Островной маршрут Ко Тао к скальной смотровой площадке между бухтами, с коротким подъемом и сильным видом на море.', 'A Koh Tao island route to a rocky lookout between bays, with a short climb and strong sea views.', 'Ко Таодағы шығанақтар арасындағы жартасты көрініс алаңына апаратын қысқа көтерілуі және теңіз көрінісі бар бағыт.', 10.06600000, 99.82600000, 'Ko_Nang_Yuan_from_Viewpoint.jpg', ARRAY['koh-tao']::text[], ARRAY['koh-tao']::text[], ARRAY['thailand','koh-tao','viewpoint','walking']::text[]),
    ('PH', 'PHP', 'batad-rice-terraces-trail', 'banaue', 'NATURE', 50, 5, 'HOURS', 4.8, 'Тропа рисовых террас Батад', 'Batad Rice Terraces Trail', 'Батад күріш террасалары соқпағы', 'Горный маршрут Кордильер по амфитеатру террас, деревенским тропам и видовым переходам вокруг Батад.', 'A Cordillera mountain route across amphitheatre terraces, village paths and viewpoint sections around Batad.', 'Кордильерадағы Батад айналасындағы амфитеатр террасалары, ауыл соқпақтары және көріністі өткелдер арқылы өтетін тау бағыты.', 16.93000000, 121.13500000, 'Banaue_Rice_Terraces.jpg', ARRAY['banaue']::text[], ARRAY['banaue','baguio']::text[], ARRAY['philippines','cordillera','rice-terraces','trekking']::text[]),
    ('PH', 'PHP', 'tapyas-sunset-stair-trail', 'coron', 'NATURE', 0, 2, 'HOURS', 4.6, 'Лестничная тропа Тапьяс на закате', 'Tapyas Sunset Stair Trail', 'Тапьяс күнбатар баспалдақ соқпағы', 'Короткий подъем над Короном по лестнице к панораме залива, островов и закатного света без лодочной логистики.', 'A short stair climb above Coron to a panorama of the bay, islands and sunset light without boat logistics.', 'Корон үстіндегі шығанаққа, аралдарға және күнбатар жарығына көрініс беретін қайықсыз қысқа баспалдақ бағыты.', 11.99970000, 120.19670000, 'Mount_Tapyas_Coron.jpg', ARRAY['coron']::text[], ARRAY['coron']::text[], ARRAY['philippines','coron','viewpoint','walking']::text[]),
    ('PH', 'PHP', 'bohol-karst-hills-view-trail', 'bohol', 'NATURE', 100, 2, 'HOURS', 4.7, 'Видовая тропа карстовых холмов Бохола', 'Bohol Karst Hills View Trail', 'Бохол карст төбелері көрініс соқпағы', 'Короткий сухопутный маршрут Бохола к смотровым площадкам над округлыми карстовыми холмами и сельским ландшафтом.', 'A short Bohol inland route to viewpoints over rounded karst hills and rural scenery.', 'Бохолдағы домалақ карст төбелері мен ауылдық ландшафт көрінетін смотроваяларға апаратын қысқа ішкі бағыт.', 9.82970000, 124.13970000, 'Chocolate_Hills_Bohol.jpg', ARRAY['bohol']::text[], ARRAY['bohol']::text[], ARRAY['philippines','bohol','karst','viewpoint']::text[]),
    ('ID', 'IDR', 'kelingking-cliff-view-trail', 'nusa-penida', 'NATURE', 25000, 2, 'HOURS', 4.8, 'Тропа к скалам Келингкинг', 'Kelingking Cliff View Trail', 'Келингкинг жартастары көрініс соқпағы', 'Крутой маршрут Нуса-Пениды к известной скальной форме, океанскому виду и короткой активной прогулке над западным берегом.', 'A steep Nusa Penida route toward the famous cliff shape, ocean view and a short active walk above the west coast.', 'Нуса-Пенидадағы әйгілі жартас пішініне, мұхит көрінісіне және батыс жағалау үстіндегі қысқа белсенді серуенге апаратын бағыт.', -8.75100000, 115.47400000, 'Kelingking_Beach_%28T-Rex_Bay%29_of_Nusa_Penida,_Bali_%282025%29_-_img_06.jpg', ARRAY['nusa-penida']::text[], ARRAY['nusa-penida','sanur']::text[], ARRAY['indonesia','nusa-penida','cliff','walking']::text[]),
    ('ID', 'IDR', 'sidemen-rice-terrace-walk', 'sidemen', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прогулка по террасе Сидемена', 'Sidemen Rice Terrace Walk', 'Сидемен күріш террасасы серуені', 'Мягкий маршрут восточного Бали через поля, деревенские дорожки и виды на Агунг для спокойного rural-дня.', 'A gentle east Bali route through fields, village lanes and Agung views for a calm rural day.', 'Шығыс Балидегі алқаптар, ауыл жолдары және Агунг көріністері арқылы өтетін тыныш rural күнге арналған жеңіл бағыт.', -8.46600000, 115.44000000, 'Rice_terraces,_Bali.jpg', ARRAY['sidemen']::text[], ARRAY['sidemen','ubud']::text[], ARRAY['indonesia','bali','rice-fields','walking']::text[]),
    ('ID', 'IDR', 'jatiluwih-subak-terrace-loop', 'jatiluwih', 'NATURE', 50000, 3, 'HOURS', 4.8, 'Петля субак-террас Джатилувиха', 'Jatiluwih Subak Terrace Loop', 'Джатилувих субак террасалары ілмегі', 'Кольцевой маршрут по водным каналам субак, зеленым ступеням полей и спокойным тропам у Батукару.', 'A loop along subak water channels, green field steps and calm paths near Batukaru.', 'Батукару маңындағы субак су арналары, жасыл егіс сатылары және тыныш жолдар арқылы өтетін айналма бағыт.', -8.36980000, 115.13120000, 'Jatiluwih_rice_terraces_SF0002.jpg', ARRAY['jatiluwih']::text[], ARRAY['jatiluwih','ubud']::text[], ARRAY['indonesia','bali','subak','walking']::text[]),
    ('MV', 'MVR', 'fuvahmulah-lake-beach-nature-walk', 'fuvahmulah', 'NATURE', 0, 3, 'HOURS', 4.5, 'Природная прогулка от озера к берегу Фувахмулаха', 'Fuvahmulah Lake-to-Beach Nature Walk', 'Фувахмулах көлден жағалауға табиғи серуені', 'Островной маршрут Фувахмулаха между пресной водой, зелеными участками и необычной береговой линией южного атолла.', 'A Fuvahmulah island route between freshwater, green pockets and the unusual shoreline of the southern atoll.', 'Фувахмулахтағы тұщы су, жасыл бөліктер және оңтүстік атоллдың ерекше жағалау сызығы арасындағы арал бағыты.', -0.29900000, 73.42500000, 'Thoondu_-_Aerial_view_of_the_the_pebble_beach_of_Fuvahmulah.jpg', ARRAY['fuvahmulah']::text[], ARRAY['fuvahmulah']::text[], ARRAY['maldives','fuvahmulah','island-walk','free-entry']::text[]),
    ('MV', 'MVR', 'hulhumale-eastern-beach-coastal-walk', 'hulhumale', 'NATURE', 0, 2, 'HOURS', 4.4, 'Восточная прибрежная прогулка Хулхумале', 'Hulhumale Eastern Beach Coastal Walk', 'Хулхумале шығыс жағалауы серуені', 'Городской островной маршрут рядом с аэропортом, где удобно пройтись вдоль воды, парков и жилых кварталов перед трансфером.', 'An urban island route near the airport, convenient for a walk along water, parks and residential blocks before transfer.', 'Әуежай маңындағы қалалық арал бағыты, трансфер алдында су, саябақтар және тұрғын аудандар бойымен серуендеуге ыңғайлы.', 4.21220000, 73.54550000, 'Flora_of_Male_islands,_Maldives_04.jpg', ARRAY['hulhumale']::text[], ARRAY['hulhumale','male']::text[], ARRAY['maldives','hulhumale','coastal','walking']::text[]),
    ('CN', 'CNY', 'nine-creeks-longjing-trail', 'hangzhou', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа Nine Creeks и Longjing', 'Nine Creeks and Longjing Trail', 'Nine Creeks және Longjing соқпағы', 'Зеленый маршрут Ханчжоу через ручьи, чайные склоны и тенистые дорожки в сторону деревень Лунцзина.', 'A green Hangzhou route through creeks, tea slopes and shaded paths toward Longjing villages.', 'Ханчжоудағы бұлақтар, шайлы беткейлер және Лунцзин ауылдарына апаратын көлеңкелі жолдар арқылы өтетін жасыл бағыт.', 30.21000000, 120.11500000, 'West_Lake_in_Hangzhou.jpg', ARRAY['hangzhou']::text[], ARRAY['hangzhou']::text[], ARRAY['china','hangzhou','tea-fields','walking']::text[]),
    ('CN', 'CNY', 'golden-whip-stream-trail', 'zhangjiajie', 'NATURE', 225, 4, 'HOURS', 4.9, 'Тропа Golden Whip Stream', 'Golden Whip Stream Trail', 'Golden Whip Stream соқпағы', 'Маршрут Чжанцзяцзе по дну каньона между кварцитовыми башнями, ручьем и лесными участками.', 'A Zhangjiajie canyon-floor route between quartzite towers, a stream and forest sections.', 'Чжанцзяцзедегі кварцит мұнаралар, бұлақ және орманды бөліктер арасындағы каньон түбі бағыты.', 29.33900000, 110.46600000, 'Zhangjiajie_National_Forest_Park.jpg', ARRAY['zhangjiajie']::text[], ARRAY['zhangjiajie']::text[], ARRAY['china','zhangjiajie','canyon','hiking']::text[]),
    ('JP', 'JPY', 'daibutsu-hiking-trail', 'kamakura', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа Daibutsu в Камакуре', 'Daibutsu Hiking Trail', 'Daibutsu жаяу соқпағы', 'Лесная тропа Камакуры между храмовыми кварталами, холмами и тихими участками старой прибрежной столицы.', 'A Kamakura forest trail between temple districts, hills and quiet sections of the old coastal capital.', 'Камакурадағы ғибадатхана аудандары, төбелер және ескі жағалау астанасының тыныш бөліктері арқылы өтетін орман соқпағы.', 35.32100000, 139.53500000, '070203_MM21%26FUJI.jpg', ARRAY['kamakura']::text[], ARRAY['kamakura','tokyo']::text[], ARRAY['japan','kamakura','forest','walking']::text[]),
    ('JP', 'JPY', 'senjogahara-marshland-trail', 'nikko', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа болот Сэндзёгахара', 'Senjogahara Marshland Trail', 'Сэндзёгахара батпағы соқпағы', 'Высокогорная прогулка Никко по деревянным настилам, открытым лугам и видам к вулканическим склонам.', 'A Nikko highland walk across boardwalks, open grassland and views toward volcanic slopes.', 'Никкодағы тақтайжолдар, ашық шалғындар және жанартаулық беткейлер көрінісі арқылы өтетін биіктаулы серуен.', 36.78000000, 139.44000000, 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg', ARRAY['nikko']::text[], ARRAY['nikko','tokyo']::text[], ARRAY['japan','nikko','marshland','walking']::text[]),
    ('KR', 'KRW', 'igidae-coastal-walk', 'busan', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прибрежная прогулка Igidae', 'Igidae Coastal Walk', 'Igidae жағалау серуені', 'Маршрут Пусана по скальным участкам берега, мостам, морскому виду и зеленым склонам у города.', 'A Busan route along rocky coast sections, bridges, sea views and green city slopes.', 'Пусандағы жартасты жағалау бөліктері, көпірлер, теңіз көрінісі және қала маңындағы жасыл беткейлер арқылы өтетін бағыт.', 35.12700000, 129.11600000, 'Haeundae_Beach_in_Busan.jpg', ARRAY['busan']::text[], ARRAY['busan']::text[], ARRAY['south-korea','busan','coastal','walking']::text[]),
    ('MY', 'MYR', 'bukit-gasing-forest-trail', 'kuala-lumpur', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная тропа Bukit Gasing', 'Bukit Gasing Forest Trail', 'Bukit Gasing орман соқпағы', 'Городской лесной маршрут Куала-Лумпура с короткими подъемами, тенистыми участками и быстрым outdoor-форматом.', 'A Kuala Lumpur urban forest route with short climbs, shaded sections and a quick outdoor format.', 'Куала-Лумпурдағы қысқа көтерілістері, көлеңкелі бөліктері және жылдам outdoor форматы бар қалалық орман бағыты.', 3.09500000, 101.65600000, 'FRIM_01.jpg', ARRAY['kuala-lumpur']::text[], ARRAY['kuala-lumpur']::text[], ARRAY['malaysia','kuala-lumpur','urban-forest','hiking']::text[]),
    ('LK', 'LKR', 'ella-mini-adams-ridge-walk', 'ella', 'NATURE', 0, 2, 'HOURS', 4.8, 'Гребневая прогулка Mini Adams в Элле', 'Ella Mini Adams Ridge Walk', 'Элла Mini Adams жота серуені', 'Короткий маршрут Эллы к мягкому гребню, чайным склонам и открытым видам на долину центрального нагорья.', 'A short Ella route to a gentle ridge, tea slopes and open views over the central highlands valley.', 'Элладағы жұмсақ жотаға, шайлы беткейлерге және орталық таулы аңғарға ашық көріністерге апаратын қысқа бағыт.', 6.87580000, 81.06660000, 'Little_Adams_Peak_Ella.jpg', ARRAY['ella']::text[], ARRAY['ella']::text[], ARRAY['sri-lanka','ella','ridge','walking']::text[]),
    ('IN', 'INR', 'neer-garh-waterfall-trail', 'rishikesh', 'NATURE', 50, 3, 'HOURS', 4.6, 'Тропа к водопаду Neer Garh', 'Neer Garh Waterfall Trail', 'Neer Garh сарқырамасына соқпақ', 'Легкий предгорный маршрут Ришикеша к каскадам, каменным бассейнам и прохладной паузе после города.', 'An easy Rishikesh foothill route to cascades, rocky pools and a cool pause after the city.', 'Ришикештегі каскадтарға, тасты бассейндерге және қаладан кейінгі салқын үзіліске апаратын жеңіл тау етегі бағыты.', 30.14700000, 78.33500000, 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg', ARRAY['rishikesh']::text[], ARRAY['rishikesh']::text[], ARRAY['india','rishikesh','waterfall','day-hike']::text[]),
    ('IN', 'INR', 'sham-valley-day-trek', 'leh', 'NATURE', 0, 6, 'HOURS', 4.7, 'Дневной трек по долине Sham', 'Sham Valley Day Trek', 'Sham аңғары күндік трегі', 'Ладакхский маршрут из Леха по сухим долинам, монастырским деревням и высокогорному ландшафту без тяжелой экспедиции.', 'A Ladakh route from Leh across dry valleys, monastery villages and high-altitude scenery without a heavy expedition.', 'Лехтен құрғақ аңғарлар, монастырь ауылдары және күрделі экспедициясыз биіктау ландшафты арқылы өтетін Ладакх бағыты.', 34.23000000, 77.58000000, 'Leh,_Ladakh,_India.jpg', ARRAY['leh']::text[], ARRAY['leh']::text[], ARRAY['india','ladakh','high-altitude','trekking']::text[]),
    ('AU', 'AUD', 'ubirr-rock-art-walk', 'kakadu', 'NATURE', 25, 2, 'HOURS', 4.8, 'Прогулка Ubirr Rock Art', 'Ubirr Rock Art Walk', 'Ubirr жартас өнері серуені', 'Короткая прогулка Какаду среди скальных галерей, саванны и вечерних видов на пойменный ландшафт.', 'A short Kakadu walk among rock galleries, savanna and evening views over floodplain country.', 'Какадудағы жартас галереялары, саванна және жайылма ландшафтына кешкі көріністер арқылы өтетін қысқа серуен.', -12.40870000, 132.95410000, 'Kakadu_(AU),_Kakadu_National_Park,_Nadap_Lookout_--_2019_--_4200.jpg', ARRAY['kakadu']::text[], ARRAY['kakadu','darwin']::text[], ARRAY['australia','kakadu','rock-art','walking']::text[]),
    ('NZ', 'NZD', 'sealy-tarns-track', 'aoraki-mount-cook', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа Sealy Tarns', 'Sealy Tarns Track', 'Sealy Tarns соқпағы', 'Крутой альпийский подъем Аораки к ступенчатым участкам, ледниковым видам и площадке над долиной.', 'A steep Aoraki alpine climb with stair sections, glacier views and a platform above the valley.', 'Аоракидегі сатылы бөліктері, мұздық көріністері және аңғар үстіндегі алаңы бар тік альпілік көтерілу.', -43.73000000, 170.08500000, 'Aoraki_Mount_Cook_National_Park.jpg', ARRAY['aoraki-mount-cook']::text[], ARRAY['aoraki-mount-cook','tekapo']::text[], ARRAY['new-zealand','aoraki','alpine','trekking']::text[]),
    ('MY', 'MYR', 'cameron-highlands-boardwalk-trail', 'cameron-highlands', 'NATURE', 30, 2, 'HOURS', 4.6, 'Тропа настилов Cameron Highlands', 'Cameron Highlands Boardwalk Trail', 'Cameron Highlands тақтайжол соқпағы', 'Высокогорная лесная прогулка по настилам, влажным мхам и прохладному воздуху малайзийских нагорий.', 'A highland forest walk on boardwalks, humid moss and cool air in the Malaysian hills.', 'Малайзия таулы аймағындағы тақтайжолдар, ылғалды мүк және салқын ауа арқылы өтетін биіктаулы орман серуені.', 4.52270000, 101.38160000, 'Mossy_Forest_Cameron_Highlands.jpg', ARRAY['cameron-highlands']::text[], ARRAY['cameron-highlands','ipoh']::text[], ARRAY['malaysia','cameron-highlands','forest','walking']::text[]),
    ('MY', 'MYR', 'gunung-raya-summit-trail', 'langkawi', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа на Gunung Raya', 'Gunung Raya Summit Trail', 'Gunung Raya шыңы соқпағы', 'Островной горный маршрут Лангкави к лесистым склонам, панорамам архипелага и прохладной вершине.', 'A Langkawi island mountain route to forested slopes, archipelago panoramas and a cooler summit.', 'Лангкавидегі орманды беткейлерге, архипелаг панорамаларына және салқындау шыңға апаратын арал тауы бағыты.', 6.37800000, 99.81400000, 'Langkawi_Sky_Bridge.jpg', ARRAY['langkawi']::text[], ARRAY['langkawi']::text[], ARRAY['malaysia','langkawi','summit','hiking']::text[]),
    ('AU', 'AUD', 'wreck-beach-steps-walk', 'great-ocean-road', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка по ступеням Wreck Beach', 'Wreck Beach Steps Walk', 'Wreck Beach Steps серуені', 'Прибрежный маршрут Great Ocean Road по лестницам, скалам и океанским видам с коротким, но выразительным рельефом.', 'A Great Ocean Road coastal route with stairs, cliffs and ocean views in a short but expressive terrain profile.', 'Great Ocean Road бойындағы баспалдақтар, жартастар және мұхит көріністері бар қысқа әрі әсерлі жағалау бағыты.', -38.65400000, 143.06100000, 'Princetown_(AU),_Port_Campbell_National_Park,_Twelve_Apostles_--_2019_--_0969.jpg', ARRAY['great-ocean-road']::text[], ARRAY['great-ocean-road','melbourne']::text[], ARRAY['australia','victoria','coastal','walking']::text[]),
    ('AU', 'AUD', 'red-arrow-circuit', 'cairns', 'NATURE', 0, 1, 'HOURS', 4.6, 'Кольцо Red Arrow', 'Red Arrow Circuit', 'Red Arrow айналма соқпағы', 'Короткий городской тропический маршрут Кэрнса с подъемом, лесом и быстрым видом на прибрежную равнину.', 'A short Cairns tropical urban route with a climb, forest and quick views over the coastal plain.', 'Кэрнстегі көтерілуі, орманы және жағалау жазығына жылдам көрінісі бар қысқа тропикалық қалалық бағыт.', -16.90000000, 145.74200000, 'The_Great_Barrier_Reef,_Cairns,_Queensland_(Ank_Kumar)_01.jpg', ARRAY['cairns']::text[], ARRAY['cairns']::text[], ARRAY['australia','cairns','urban-nature','walking']::text[]),
    ('AE', 'AED', 'jebel-hafit-foothill-trail', 'al-ain', 'NATURE', 0, 3, 'HOURS', 4.6, 'Предгорная тропа Джебель-Хафит', 'Jebel Hafit Foothill Trail', 'Джебель-Хафит тау етегі соқпағы', 'Пустынный маршрут Аль-Айна у подножия горы, с каменистыми участками, сухими видами и коротким outdoor-сценарием.', 'An Al Ain desert route at the mountain foot, with rocky sections, dry views and a short outdoor plan.', 'Әл-Айндағы тау етегіндегі шөл бағыты: тасты бөліктер, құрғақ көріністер және қысқа outdoor жоспары.', 24.05700000, 55.77800000, 'Jebel_Hafeet.jpg', ARRAY['al-ain','abu-dhabi']::text[], ARRAY['al-ain','abu-dhabi']::text[], ARRAY['united-arab-emirates','al-ain','desert','hiking']::text[]);

CREATE TEMP TABLE seed_asia_oceania_gap_hiking_resolved_places AS
SELECT
    ('110d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['asia-oceania-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_asia_oceania_gap_hiking_places;

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
FROM seed_asia_oceania_gap_hiking_resolved_places
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
FROM seed_asia_oceania_gap_hiking_resolved_places
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
FROM seed_asia_oceania_gap_hiking_resolved_places
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
FROM seed_asia_oceania_gap_hiking_resolved_places
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
FROM seed_asia_oceania_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_asia_oceania_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_asia_oceania_gap_hiking_places;
