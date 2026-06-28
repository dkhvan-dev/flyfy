-- Extra Kazakhstan route-level outdoor/hiking seed.
-- This layer adds concrete trails and nature walks that complement broad parks, gorges and already seeded anchors.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_extra_outdoor_routes_places (
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
    ('KZ', 'KZT', 'abai-peak-classic-trail', 'almaty', 'NATURE', 1000, 8, 'HOURS', 4.8, 'Классическая тропа на пик Абая', 'Abai Peak Classic Trail', 'Абай шыңына классикалық соқпақ', 'Классический высотный маршрут из зоны Шымбулака к узнаваемой вершине, открытым гребням и панораме Заилийского Алатау.', 'A classic high mountain route from the Shymbulak area toward a recognizable summit, open ridges and an Ile Alatau panorama.', 'Шымбұлақ аймағынан танымал шыңға, ашық жоталарға және Іле Алатауы панорамасына апаратын классикалық биік таулы бағыт.', 43.08900000, 77.09800000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','summit','trekking']::text[]),
    ('KZ', 'KZT', 'three-brothers-rocks-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Тропа к скалам Три брата', 'Three Brothers Rocks Trail', 'Үш ағайынды жартастарына соқпақ', 'Маршрут над городом к скальным выходам и видовым точкам, хорошо подходящий для активного дня без дальнего трансфера.', 'A route above the city toward rock outcrops and viewpoints, well suited for an active day without a long transfer.', 'Қала үстіндегі жартасты нүктелер мен көрініс алаңдарына апаратын бағыт, алыс трансферсіз белсенді күнге ыңғайлы.', 43.12600000, 76.99100000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','rocks','day-hike']::text[]),
    ('KZ', 'KZT', 'charyn-moon-canyon-trail', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.8, 'Тропа Лунного каньона Чарына', 'Charyn Moon Canyon Trail', 'Шарын Ай каньоны соқпағы', 'Сухой маршрут в системе Чарына по светлым стенкам, глинистым склонам и тихим видовым точкам вдали от основной тропы.', 'A dry route in the Charyn system across pale walls, clay slopes and quieter viewpoints away from the main trail.', 'Шарын жүйесіндегі ашық қабырғалар, сазды беткейлер және негізгі соқпақтан тыс тынышырақ көрініс нүктелері арқылы өтетін құрғақ бағыт.', 43.35000000, 79.13000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','canyon','day-hike']::text[]),
    ('KZ', 'KZT', 'aigaikum-singing-dune-walk', 'taldykorgan', 'NATURE', 1000, 3, 'HOURS', 4.8, 'Прогулка по Поющему бархану Айгайкум', 'Aigaikum Singing Dune Walk', 'Айғайқұм әнші құмы серуені', 'Короткая прогулка по песчаному гребню Алтын-Эмеля с ветром, пустынным горизонтом и сильным ощущением открытого пространства.', 'A short walk along an Altyn-Emel sand ridge with wind, desert horizon and a strong sense of open space.', 'Алтын-Емелдегі құм жотасымен өтетін қысқа серуен: жел, шөл көкжиегі және кең ашық кеңістік сезімі.', 44.05000000, 78.69000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan','almaty']::text[], ARRAY['taldykorgan','almaty']::text[], ARRAY['kazakhstan','altyn-emel','dune','walking']::text[]),
    ('KZ', 'KZT', 'basshi-steppe-eco-trail', 'taldykorgan', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Степная экотропа Басши', 'Basshi Steppe Eco Trail', 'Басши дала экосоқпағы', 'Маршрут у поселка Басши по сухой степи, низким холмам и спокойным наблюдательным точкам перед дальними локациями парка.', 'A route near Basshi across dry steppe, low hills and calm observation points before the park deeper locations.', 'Басши маңындағы құрғақ дала, аласа қыраттар және парктің алыс нүктелеріне дейінгі тыныш бақылау орындары арқылы өтетін бағыт.', 44.17000000, 78.75000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan','almaty']::text[], ARRAY['kazakhstan','zhetysu','steppe','hiking']::text[]),
    ('KZ', 'KZT', 'lepsy-river-valley-trail', 'taldykorgan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа долины реки Лепсы', 'Lepsy River Valley Trail', 'Лепсі өзені аңғары соқпағы', 'Зеленый маршрут Жетісу к речной долине, предгорным видам и более спокойной альтернативе популярным алматинским тропам.', 'A green Zhetysu route toward a river valley, foothill views and a calmer alternative to the busiest Almaty trails.', 'Жетісудың өзен аңғарына, тау етегі көріністеріне және Алматыдағы ең танымал соқпақтарға қарағанда тынышырақ баламаға апаратын жасыл бағыты.', 45.49000000, 80.61000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','river-valley','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'austrian-road-katon-karagay-trail', 'ust-kamenogorsk', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Тропа Австрийской дороги Катон-Карагая', 'Austrian Road Katon-Karagay Trail', 'Қатонқарағай Австрия жолы соқпағы', 'Горный маршрут по исторической дороге Алтая с лесом, серпантинами, речными долинами и широкими видами Катон-Карагая.', 'A mountain route along a historic Altai road with forest, switchbacks, river valleys and wide Katon-Karagay views.', 'Алтайдың тарихи жолымен өтетін тау бағыты: орман, бұралаңдар, өзен аңғарлары және Қатонқарағайдың кең көріністері.', 49.19000000, 86.20000000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','katon-karagay','trekking']::text[]),
    ('KZ', 'KZT', 'belukha-base-view-trail', 'ust-kamenogorsk', 'NATURE', 1000, 8, 'HOURS', 4.9, 'Тропа к виду на базу Белухи', 'Belukha Base View Trail', 'Белуха базасы көрініс соқпағы', 'Сильный алтайский маршрут для подготовленных гостей к видам на ледниковую зону, долины и высокогорный северо-восток Казахстана.', 'A strong Altai route for prepared visitors toward glacier-area views, valleys and the high mountain northeast of Kazakhstan.', 'Дайын саяхатшыларға арналған Алтай бағыты: мұздық аймағының көріністері, аңғарлар және Қазақстанның биік таулы солтүстік-шығысы.', 49.81000000, 86.59000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','belukha','trekking']::text[]),
    ('KZ', 'KZT', 'berel-valley-heritage-walk', 'ust-kamenogorsk', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка по долине Берели', 'Berel Valley Heritage Walk', 'Берел аңғары серуені', 'Пеший маршрут по алтайской долине рядом с археологическим контекстом, речными видами и мягким форматом outdoor-прогулки.', 'A walking route through an Altai valley near archaeological context, river views and a gentle outdoor format.', 'Археологиялық контексті, өзен көріністері және жеңіл outdoor форматы бар Алтай аңғарымен өтетін жаяу бағыт.', 49.33000000, 86.36000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','heritage','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kempirtas-rock-trail', 'pavlodar', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа скал Кемпиртас', 'Kempirtas Rock Trail', 'Кемпіртас жартастары соқпағы', 'Баянаульский маршрут среди гранитных форм, сосен и обзорных точек, дополняющий прогулки у Жасыбая и Торайгыра.', 'A Bayanaul route among granite forms, pines and viewpoints, complementing walks near Zhasybai and Toraigyr.', 'Баянауылдағы гранит пішіндері, қарағайлар және көрініс нүктелері арқылы өтетін бағыт, Жасыбай мен Торайғыр маңындағы серуендерді толықтырады.', 50.77000000, 75.65000000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','granite','hiking']::text[]),
    ('KZ', 'KZT', 'auliebulak-spring-trail', 'pavlodar', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Тропа источника Аулиебулак', 'Auliebulak Spring Trail', 'Әулиебұлақ бұлағы соқпағы', 'Короткая лесная прогулка в Баянауле к роднику, каменным склонам и спокойному формату семейного outdoor-дня.', 'A short forest walk in Bayanaul toward a spring, rocky slopes and a calm family outdoor format.', 'Баянауылдағы бұлаққа, тасты беткейлерге және отбасылық тыныш outdoor күнге арналған қысқа орман серуені.', 50.80600000, 75.61000000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','bayanaul','spring','walking']::text[]),
    ('KZ', 'KZT', 'bugyly-mountains-trail', 'karaganda', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа гор Бугылы', 'Bugyly Mountains Trail', 'Бұғылы таулары соқпағы', 'Степной горный маршрут Центрального Казахстана с низкими скалами, открытым горизонтом и форматом спокойного треккинга.', 'A central Kazakhstan steppe mountain route with low rocks, open horizon and a calm trekking format.', 'Орталық Қазақстандағы аласа жартастары, ашық көкжиегі және тыныш треккинг форматы бар дала-таулы бағыт.', 49.26000000, 75.45000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda','balkhash']::text[], ARRAY['karaganda','balkhash']::text[], ARRAY['kazakhstan','central-kazakhstan','steppe-mountains','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'karkaraly-three-caves-trail', 'karaganda', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа Трех пещер Каркаралы', 'Karkaraly Three Caves Trail', 'Қарқаралы Үш үңгір соқпағы', 'Лесной маршрут Каркаралы к каменным нишам, сосновым участкам и обзорным точкам без длинного набора высоты.', 'A Karkaraly forest route toward stone niches, pine sections and viewpoints without a long elevation gain.', 'Қарқаралыдағы тас қуыстарға, қарағайлы бөліктерге және ұзақ биіктік жинамайтын көрініс нүктелеріне апаратын орман бағыты.', 49.42000000, 75.47000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','caves','hiking']::text[]),
    ('KZ', 'KZT', 'pashennoye-lake-forest-trail', 'karaganda', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Лесная тропа озера Пашенное', 'Pashennoye Lake Forest Trail', 'Пашенное көлі орман соқпағы', 'Спокойный маршрут в Каркаралинской зоне по соснам, береговым участкам и каменным склонам для мягкого outdoor-дня.', 'A calm route in the Karkaraly area through pines, shore sections and rocky slopes for a gentle outdoor day.', 'Қарқаралы аймағындағы қарағайлар, жағалау бөліктері және тасты беткейлер арқылы өтетін тыныш outdoor бағыты.', 49.40500000, 75.43800000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','lake','hiking']::text[]),
    ('KZ', 'KZT', 'burabay-green-cape-trail', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Тропа Зеленого мыса Бурабая', 'Burabay Green Cape Trail', 'Бурабай Жасыл мүйіс соқпағы', 'Короткая прогулка по северному лесоозерному ландшафту с соснами, водой и мягкими видами Бурабайской зоны.', 'A short walk through a northern forest-and-lake landscape with pines, water and soft views of the Burabay area.', 'Қарағайы, суы және Бурабай аймағының жұмсақ көріністері бар солтүстік орман-көл ландшафтымен өтетін қысқа серуен.', 53.09000000, 70.30000000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','lake-shore','walking']::text[]),
    ('KZ', 'KZT', 'ereymentau-granite-ridge-trail', 'astana', 'NATURE', 0, 5, 'HOURS', 4.6, 'Гранитная тропа Ерейментау', 'Ereymentau Granite Ridge Trail', 'Ерейментау гранит жотасы соқпағы', 'Степной выезд из Астаны к гранитным грядам, сухим склонам и широким видам северного Сарыарка.', 'A steppe escape from Astana toward granite ridges, dry slopes and wide northern Saryarka views.', 'Астанадан гранит жоталарға, құрғақ беткейлерге және солтүстік Сарыарқаның кең көріністеріне апаратын дала бағыты.', 51.62000000, 73.10000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana']::text[], ARRAY['astana']::text[], ARRAY['kazakhstan','akmola-region','granite','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'shakpak-ata-canyon-walk', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка каньона Шакпак-Ата', 'Shakpak-Ata Canyon Walk', 'Шақпақ-Ата каньоны серуені', 'Пеший маршрут Мангистау через известняковые стенки, сухие русла и культурный ландшафт севернее Актау.', 'A Mangystau walking route through limestone walls, dry washes and a cultural landscape north of Aktau.', 'Ақтаудың солтүстігіндегі әктас қабырғалар, құрғақ сайлар және мәдени ландшафт арқылы өтетін Маңғыстау серуені.', 44.43000000, 51.12000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','canyon','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kokala-clay-hills-trail', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа глинистых холмов Кокала', 'Kokala Clay Hills Trail', 'Көкала сазды қыраттары соқпағы', 'Пустынный маршрут среди цветных глин, мягких холмов и открытого пространства Мангистау для фото и легкого хайкинга.', 'A desert route among colored clays, soft hills and open Mangystau space for photos and light hiking.', 'Түрлі түсті саздар, жұмсақ қыраттар және Маңғыстаудың ашық кеңістігі арасындағы фотоға және жеңіл хайкингке арналған шөл бағыты.', 43.94000000, 53.29000000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','clay-hills','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'beket-ata-plateau-walk', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.8, 'Прогулка плато Бекет-Ата', 'Beket-Ata Plateau Walk', 'Бекет-Ата үстірті серуені', 'Маршрут по плато и сухим спускам Мангистау, где природная прогулка соединяется с важным культурным контекстом региона.', 'A route across Mangystau plateau and dry descents where a nature walk connects with important regional cultural context.', 'Маңғыстау үстірті мен құрғақ түсу жолдары арқылы өтетін бағыт, табиғи серуен өңірдің маңызды мәдени контекстімен байланысады.', 43.59600000, 54.07000000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','plateau','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'akzhaiyk-reserve-boardwalk-trail', 'atyrau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Экотропа Акжайыкского резервата', 'Akzhaiyk Reserve Boardwalk Trail', 'Ақжайық резерваты экосоқпағы', 'Легкая природная прогулка у дельты Урала с камышами, птицами и водным ландшафтом рядом с Атырау.', 'An easy nature walk near the Ural delta with reedbeds, birds and a waterside landscape close to Atyrau.', 'Атырау маңындағы Жайық атырауының қамысы, құстары және су ландшафты бар жеңіл табиғи серуені.', 46.93000000, 51.85000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['atyrau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','atyrau-region','wetlands','free-entry','birdwatching']::text[]),
    ('KZ', 'KZT', 'barsa-kelmes-desert-edge-trail', 'kyzylorda', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа к краю пустыни Барсакельмес', 'Barsa-Kelmes Desert Edge Trail', 'Барсакелмес шөл жиегі соқпағы', 'Пустынный маршрут Приаралья с солончаками, сухим горизонтом и сильным ощущением большого ландшафта.', 'An Aral-side desert route with salt flats, dry horizon and a strong feeling of a vast landscape.', 'Арал маңындағы тұзды жазықтары, құрғақ көкжиегі және үлкен ландшафт сезімі бар шөл бағыты.', 45.64000000, 59.91000000, 'Balkhash lake, september 2020.jpg', ARRAY['kyzylorda']::text[], ARRAY['kyzylorda']::text[], ARRAY['kazakhstan','aral-region','desert','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'mugodzhary-hills-trail', 'aktobe', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа Мугоджарских холмов', 'Mugodzhary Hills Trail', 'Мұғалжар қыраттары соқпағы', 'Маршрут западных холмов Казахстана с сухой степью, мягким набором высоты и редким для Актобе outdoor-сценарием.', 'A western Kazakhstan hill route with dry steppe, gentle elevation gain and an outdoor scenario that is rare for Aktobe.', 'Батыс Қазақстан қыраттарындағы құрғақ дала, жұмсақ биіктік жинау және Ақтөбе үшін сирек outdoor сценарийі бар бағыт.', 49.21000000, 58.61000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','hills','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'koksay-gorge-trail', 'taraz', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья Коксай', 'Koksay Gorge Trail', 'Көксай шатқалы соқпағы', 'Маршрут Жамбылской области к зеленому ущелью, ручьям и западно-тяньшанскому рельефу для выезда из Тараза.', 'A Zhambyl region route toward a green gorge, streams and Western Tian Shan terrain for a departure from Taraz.', 'Жамбыл облысындағы Тараздан шығатын бағыт: жасыл шатқал, бұлақтар және Батыс Тянь-Шань бедері.', 42.56000000, 72.83000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','gorge','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'baldybrek-canyon-trail', 'shymkent', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа каньона Балдыбрек', 'Baldybrek Canyon Trail', 'Балдыбрек каньоны соқпағы', 'Южный маршрут к сухому каньону и предгорным видам, добавляющий к Шымкенту еще один природный сценарий выходного дня.', 'A southern route toward a dry canyon and foothill views, adding another weekend nature scenario for Shymkent.', 'Құрғақ каньон мен тау етегі көріністеріне апаратын оңтүстік бағыт, Шымкент үшін тағы бір демалыс күнгі табиғи сценарий қосады.', 42.42400000, 69.90600000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','south-kazakhstan','canyon','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'ulytau-aulietau-summit-trail', 'zhezkazgan', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа на вершину Аулиетау Улытау', 'Ulytau Aulietau Summit Trail', 'Ұлытау Әулиетау шыңы соқпағы', 'Маршрут по священной горной зоне Улытау с каменными склонами, открытой степью и сильным историческим фоном.', 'A route through the sacred Ulytau mountain area with rocky slopes, open steppe and strong historical context.', 'Ұлытаудың қасиетті тау аймағы арқылы өтетін бағыт: тасты беткейлер, ашық дала және күшті тарихи контекст.', 48.65300000, 67.00500000, 'Dzhuchi khan mausoleum.jpg', ARRAY['zhezkazgan']::text[], ARRAY['zhezkazgan']::text[], ARRAY['kazakhstan','ulytau','summit','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'balkhash-reed-islands-walk', 'balkhash', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка по камышовым островам Балхаша', 'Balkhash Reed Islands Walk', 'Балқаш қамысты аралдары серуені', 'Легкая прогулка у Балхаша с водной гладью, камышами и тихими береговыми участками для спокойной природной остановки.', 'An easy Balkhash walk with open water, reeds and quiet shore sections for a calm nature stop.', 'Балқаштағы ашық су, қамыс және тыныш жағалау бөліктері бар жеңіл табиғи аялдама.', 46.75000000, 74.98000000, 'Balkhash lake, september 2020.jpg', ARRAY['balkhash']::text[], ARRAY['balkhash']::text[], ARRAY['kazakhstan','balkhash','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shalkar-lake-shore-walk', 'oral', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая прогулка озера Шалкар', 'Shalkar Lake Shore Walk', 'Шалқар көлі жағалау серуені', 'Западноказахстанский маршрут к открытому озерному берегу, степному ветру и короткой природной паузе из Орала.', 'A West Kazakhstan route to an open lake shore, steppe wind and a short nature pause from Oral.', 'Оралдан ашық көл жағасына, дала желіне және қысқа табиғи үзіліске апаратын Батыс Қазақстан бағыты.', 50.73000000, 50.95000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','lake-shore','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_routes_resolved_places AS
SELECT
    ('a0ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-extra-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_extra_outdoor_routes_places;

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
FROM seed_kazakhstan_extra_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_routes_places;
