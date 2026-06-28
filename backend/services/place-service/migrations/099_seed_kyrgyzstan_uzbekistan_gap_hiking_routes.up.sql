-- Gap-filling route-level hiking/day-hike seed for Kyrgyzstan and Uzbekistan.
-- These rows cover reference hubs that had broad landmarks but no concrete outdoor route card.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_kyrgyzstan_uzbekistan_gap_hiking_places;

CREATE TEMP TABLE seed_kyrgyzstan_uzbekistan_gap_hiking_places (
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

INSERT INTO seed_kyrgyzstan_uzbekistan_gap_hiking_places (
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
    ('KG', 'KGS', 'ak-sai-waterfall-trail', 'ala-archa', 'NATURE', 200, 5, 'HOURS', 4.8, 'Тропа к водопаду Ак-Сай', 'Ak-Sai Waterfall Trail', 'Ақ-Сай сарқырамасына соқпақ', 'Маршрут в долине Ак-Сай с горной рекой, хвойными склонами и удобным форматом дневного выхода из Бишкека.', 'A route in the Ak-Sai valley with a mountain river, conifer slopes and a convenient day-hike format from Bishkek.', 'Ақ-Сай аңғарындағы тау өзені, қылқан беткейлер және Бішкектен күндік жорыққа ыңғайлы бағыт.', 42.54500000, 74.48600000, 'Ala-Archa National Park in Kyrgyzstan.jpg', ARRAY['ala-archa']::text[], ARRAY['bishkek','ala-archa']::text[], ARRAY['kyrgyzstan','chuy-region','waterfall','day-hike','trekking']::text[]),
    ('KG', 'KGS', 'chunkurchak-ridge-viewpoint-trail', 'chunkurchak', 'NATURE', 0, 4, 'HOURS', 4.7, 'Смотровая тропа хребта Чункурчак', 'Chunkurchak Ridge Viewpoint Trail', 'Чункурчак жотасы көрініс соқпағы', 'Короткий маршрут по открытым склонам Чуйских гор с панорамой долины, пастбищами и быстрым выездом из столицы.', 'A short route across open Chuy mountain slopes with valley panoramas, pastures and quick access from the capital.', 'Шу тауларының ашық беткейлерімен өтетін қысқа бағыт: аңғар панорамасы, жайылымдар және астанадан тез жету.', 42.64400000, 74.67500000, 'Chunkurchak, Chuy region, Kyrgyzstan.jpg', ARRAY['chunkurchak']::text[], ARRAY['bishkek','chunkurchak']::text[], ARRAY['kyrgyzstan','chuy-region','ridge','viewpoint','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'issyk-ata-waterfall-gorge-trail', 'issyk-ata', 'NATURE', 0, 4, 'HOURS', 4.7, 'Водопадная тропа Иссык-Аты', 'Issyk-Ata Waterfall Gorge Trail', 'Ыстық-Ата сарқырама шатқалы соқпағы', 'Доступный маршрут к воде, скалам и прохладному ущелью, который хорошо работает как мягкий outdoor-день из Бишкека.', 'An accessible route to water, rocks and a cool gorge, working well as a gentle outdoor day from Bishkek.', 'Суға, жартастарға және салқын шатқалға апаратын қолжетімді бағыт, Бішкектен жеңіл outdoor күнге лайық.', 42.60300000, 74.95500000, 'Ysyk Ata waterfall view from the river, Ysyk Ata Gorge, Kyrgyzstan.jpg', ARRAY['issyk-ata']::text[], ARRAY['bishkek','issyk-ata']::text[], ARRAY['kyrgyzstan','chuy-region','waterfall','free-entry','day-hike']::text[]),
    ('KG', 'KGS', 'telety-valley-day-hike', 'jeti-oguz', 'NATURE', 0, 6, 'HOURS', 4.8, 'Дневной маршрут долины Телеты', 'Telety Valley Day Hike', 'Телеты аңғары күндік жорығы', 'Тянь-шаньская тропа из района Джети-Огуза к пастбищам, красным скалам и более тихим горным видам южного Иссык-Куля.', 'A Tian Shan trail from the Jeti-Oguz area toward pastures, red rocks and quieter mountain views of southern Issyk-Kul.', 'Жеті-Өгүз маңынан жайылымдарға, қызыл жартастарға және оңтүстік Ыстықкөлдің тынышырақ тау көріністеріне апаратын Тянь-Шань соқпағы.', 42.30300000, 78.35900000, 'Jeti-Oguz rocks, Issyk Kul region, Kyrgyzstan 02.jpg', ARRAY['jeti-oguz']::text[], ARRAY['karakol','jeti-oguz']::text[], ARRAY['kyrgyzstan','issyk-kul','valley','day-hike','trekking']::text[]),
    ('KG', 'KGS', 'barskoon-upper-cascade-trail', 'barskoon', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа верхних каскадов Барскоона', 'Barskoon Upper Cascade Trail', 'Барскоон жоғарғы каскадтары соқпағы', 'Маршрут выше основной остановки к каскадам, хвойным участкам и видам ущелья для гостей южного берега Иссык-Куля.', 'A route above the main stop toward cascades, conifer sections and gorge views for southern Issyk-Kul visitors.', 'Ыстықкөлдің оңтүстік жағалауындағы қонақтарға негізгі аялдамадан жоғары каскадтарға, қылқан бөліктерге және шатқал көріністеріне баратын бағыт.', 42.13300000, 77.62700000, 'Barskoön Waterfall.jpg', ARRAY['barskoon']::text[], ARRAY['karakol','barskoon']::text[], ARRAY['kyrgyzstan','issyk-kul','cascade','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'skazka-canyon-ridge-loop', 'skazka-canyon', 'NATURE', 0, 3, 'HOURS', 4.8, 'Кольцо по гребням каньона Сказка', 'Skazka Canyon Ridge Loop', 'Сказка каньоны жота айналма соқпағы', 'Короткий маршрут по цветным глиняным гребням с видами на южный берег, сухие формы и озерный горизонт.', 'A short route over colored clay ridges with views of the south shore, dry formations and the lake horizon.', 'Түрлі түсті сазды жоталармен өтетін қысқа бағыт: оңтүстік жағалау, құрғақ бедер және көл көкжиегі көрінеді.', 42.17400000, 77.35400000, 'Skazka Canyon, Kyrgyzstan (43904244194).jpg', ARRAY['skazka-canyon']::text[], ARRAY['karakol','bokonbaevo','skazka-canyon']::text[], ARRAY['kyrgyzstan','issyk-kul','canyon','free-entry','walking']::text[]),
    ('KG', 'KGS', 'shatyly-panorama-trail', 'bokonbaevo', 'NATURE', 0, 4, 'HOURS', 4.7, 'Панорамная тропа Шатылы', 'Shatyly Panorama Trail', 'Шатылы панорама соқпағы', 'Маршрут над Боконбаево к открытым видам на южный Иссык-Куль, сухие холмы и горный горизонт Терскей Ала-Тоо.', 'A route above Bokonbaevo toward open views of southern Issyk-Kul, dry hills and the Terskey Ala-Too skyline.', 'Боконбаево үстінен оңтүстік Ыстықкөлге, құрғақ қыраттарға және Теріскей Ала-Тоо көкжиегіне ашық көріністер беретін бағыт.', 42.10700000, 77.00400000, 'Bokonbaevo Eagle Hunter.jpg', ARRAY['bokonbaevo']::text[], ARRAY['bokonbaevo','cholpon-ata']::text[], ARRAY['kyrgyzstan','issyk-kul','panorama','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'tamga-gorge-petroglyph-trail', 'tamga', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа петроглифов Тамгинского ущелья', 'Tamga Gorge Petroglyph Trail', 'Тамға шатқалы петроглифтері соқпағы', 'Небольшой маршрут у Тамги с каменными выходами, культурным контекстом и мягким горным рельефом южного Иссык-Куля.', 'A compact route near Tamga with rocky outcrops, cultural context and gentle mountain terrain of southern Issyk-Kul.', 'Тамға маңындағы шағын бағыт: тасты жерлер, мәдени контекст және оңтүстік Ыстықкөлдің жұмсақ тау бедері.', 42.13600000, 77.52600000, 'Tamga Tash.jpg', ARRAY['tamga']::text[], ARRAY['karakol','tamga']::text[], ARRAY['kyrgyzstan','issyk-kul','petroglyphs','free-entry','walking']::text[]),
    ('KG', 'KGS', 'kaji-say-shoreline-ridge-walk', 'kaji-say', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая гряда Каджи-Сая', 'Kaji-Say Shoreline Ridge Walk', 'Қажы-Сай жағалау жотасы серуені', 'Легкая прогулка над южным берегом с сухими холмами, пляжными видами и коротким форматом между переездами по Иссык-Кулю.', 'An easy walk above the south shore with dry hills, beach views and a short format between Issyk-Kul transfers.', 'Оңтүстік жағалау үстіндегі жеңіл серуен: құрғақ қыраттар, жағажай көріністері және Ыстықкөл бойындағы жол арасында қысқа формат.', 42.16200000, 77.17000000, 'Lake Issyk-Kul, Kyrgyzstan.jpg', ARRAY['kaji-say']::text[], ARRAY['bokonbaevo','kaji-say']::text[], ARRAY['kyrgyzstan','issyk-kul','shoreline','free-entry','walking']::text[]),
    ('KG', 'KGS', 'song-kul-shore-pasture-loop', 'song-kul', 'NATURE', 0, 4, 'HOURS', 4.8, 'Пастбищное кольцо Сон-Куля', 'Song-Kul Shore Pasture Loop', 'Соңкөл жайылым жағалауы айналма бағыты', 'Высокогорная прогулка по береговым пастбищам с юртами, открытым небом и мягким рельефом для неспешного знакомства с плато.', 'A highland walk across shore pastures with yurts, open sky and gentle terrain for an unhurried plateau experience.', 'Киіз үйлері, ашық аспаны және үстіртпен асықпай танысуға лайық жұмсақ бедері бар биік таулы жайылым серуені.', 41.85000000, 75.15000000, 'Song-Kul, Kyrgyzstan (43670021735).jpg', ARRAY['song-kul']::text[], ARRAY['kochkor','naryn','song-kul']::text[], ARRAY['kyrgyzstan','naryn-region','pasture','free-entry','walking']::text[]),
    ('KG', 'KGS', 'chatyr-kul-pass-view-trail', 'tash-rabat', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа к виду на перевал Чатыр-Куль', 'Chatyr-Kul Pass View Trail', 'Шатыркөл асуы көрініс соқпағы', 'Высокогорный маршрут от района Таш-Рабата к открытым видам Ат-Башинского хребта и пограничных плато.', 'A highland route from the Tash Rabat area toward open views of the At-Bashy range and borderland plateaus.', 'Таш-Рабат маңынан Ат-Башы жотасы мен шекаралық үстірттердің ашық көріністеріне апаратын биік таулы бағыт.', 40.79000000, 75.35000000, 'Tash Rabat.JPG', ARRAY['tash-rabat','at-bashy']::text[], ARRAY['naryn','at-bashy','tash-rabat']::text[], ARRAY['kyrgyzstan','naryn-region','pass','free-entry','trekking']::text[]),
    ('KG', 'KGS', 'kel-suu-canyon-shore-trail', 'kel-suu', 'NATURE', 0, 5, 'HOURS', 4.9, 'Береговая тропа каньона Кель-Суу', 'Kel-Suu Canyon Shore Trail', 'Көл-Суу каньоны жағалау соқпағы', 'Маршрут по высокогорному каньону и береговым участкам с бирюзовой водой, скалами и удаленной логистикой Нарына.', 'A route through a high mountain canyon and shore sections with turquoise water, cliffs and remote Naryn logistics.', 'Көгілдір суы, жартастары және Нарынның шалғай логистикасы бар биік таулы каньон мен жағалау бөліктері арқылы өтетін бағыт.', 40.63900000, 76.40700000, 'Kel-Suu.jpg', ARRAY['kel-suu']::text[], ARRAY['naryn','at-bashy','kel-suu']::text[], ARRAY['kyrgyzstan','naryn-region','canyon','remote','trekking']::text[]),
    ('KG', 'KGS', 'at-bashy-ridge-view-trail', 'at-bashy', 'NATURE', 0, 5, 'HOURS', 4.6, 'Смотровая тропа хребта Ат-Башы', 'At-Bashy Ridge View Trail', 'Ат-Башы жотасы көрініс соқпағы', 'Маршрут над долиной Ат-Башы с широкими видами на пастбища, сухие хребты и дорогу к высокогорным южным маршрутам.', 'A route above the At-Bashy valley with wide views of pastures, dry ranges and the road toward southern highland routes.', 'Ат-Башы аңғары үстіндегі бағыт: жайылымдарға, құрғақ жоталарға және оңтүстік биік таулы жолдарға кең көрініс береді.', 41.17000000, 75.82000000, 'At-Bashy Valley.jpg', ARRAY['at-bashy']::text[], ARRAY['naryn','at-bashy']::text[], ARRAY['kyrgyzstan','naryn-region','ridge','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'kara-alma-walnut-forest-trail', 'jalal-abad', 'NATURE', 0, 5, 'HOURS', 4.6, 'Ореховая тропа Кара-Алмы', 'Kara-Alma Walnut Forest Trail', 'Қара-Алма жаңғақ орманы соқпағы', 'Зеленый маршрут из Джалал-Абада к плодовым лесам, тенистым склонам и мягкому южному горному пейзажу.', 'A green route from Jalal-Abad toward fruit forests, shaded slopes and a gentle southern mountain landscape.', 'Жалал-Абадтан жеміс ормандарына, көлеңкелі беткейлерге және оңтүстіктің жұмсақ тау көрінісіне апаратын жасыл бағыт.', 41.21000000, 73.30000000, 'Jalal-Abad Kyrgyzstan.jpg', ARRAY['jalal-abad']::text[], ARRAY['jalal-abad']::text[], ARRAY['kyrgyzstan','jalal-abad-region','walnut-forest','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'small-arslanbob-waterfall-loop', 'arslanbob', 'NATURE', 0, 4, 'HOURS', 4.8, 'Малое водопадное кольцо Арсланбоба', 'Small Arslanbob Waterfall Loop', 'Арсланбоб шағын сарқырама айналма бағыты', 'Пешее кольцо через ореховый лес, ручьи и обзорные точки у нижних каскадов для гостей, которым нужен понятный короткий маршрут.', 'A walking loop through walnut forest, streams and viewpoints near lower cascades for visitors who need a clear short route.', 'Жаңғақ орманы, бұлақтар және төменгі каскадтар маңындағы көрініс нүктелері арқылы өтетін түсінікті қысқа айналма бағыт.', 41.33400000, 72.92800000, 'Walnut forest Arslanbob.jpg', ARRAY['arslanbob']::text[], ARRAY['jalal-abad','arslanbob']::text[], ARRAY['kyrgyzstan','jalal-abad-region','forest','waterfall','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'arkyt-to-sary-chelek-lake-trail', 'sary-chelek', 'NATURE', 200, 6, 'HOURS', 4.9, 'Тропа Аркыт - Сары-Челек', 'Arkyt to Sary-Chelek Lake Trail', 'Арқыттан Сары-Челекке соқпақ', 'Маршрут от Аркыта к горному берегу через лес, холмы и видовые участки западного Кыргызстана.', 'A route from Arkyt toward the mountain shore through forest, hills and scenic sections of western Kyrgyzstan.', 'Арқыттан таулы жағалауға орман, қыраттар және Батыс Қырғызстанның көріністі бөліктері арқылы апаратын бағыт.', 41.87300000, 71.95700000, 'Sary Chelek Lake.jpg', ARRAY['sary-chelek']::text[], ARRAY['jalal-abad','sary-chelek']::text[], ARRAY['kyrgyzstan','jalal-abad-region','lake-shore','trekking']::text[]),
    ('KG', 'KGS', 'toktogul-shore-ridge-trail', 'toktogul', 'NATURE', 0, 4, 'HOURS', 4.6, 'Береговая гряда Токтогула', 'Toktogul Shore Ridge Trail', 'Тоқтоғұл жағалау жотасы соқпағы', 'Короткий маршрут по сухим грядам над водой с видами на долину Нарына и удобной остановкой на трассе Бишкек - Ош.', 'A short route across dry ridges above the water with Naryn valley views and a convenient stop on the Bishkek-Osh road.', 'Су үстіндегі құрғақ жоталармен өтетін қысқа бағыт: Нарын аңғары көріністері және Бішкек - Ош жолында ыңғайлы аялдама.', 41.84500000, 72.98500000, 'Manas Ordo Kyrgyzstan.jpg', ARRAY['toktogul']::text[], ARRAY['bishkek','toktogul']::text[], ARRAY['kyrgyzstan','jalal-abad-region','shoreline','free-entry','walking']::text[]),
    ('KG', 'KGS', 'too-ashuu-ridge-walk', 'suusamyr', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка по гребню Тоо-Ашуу', 'Too-Ashuu Ridge Walk', 'Тоо-Ашуу жотасы серуені', 'Высокогорная прогулка у Суусамырской долины с ветреным перевалом, открытыми склонами и широкими пастбищными видами.', 'A highland walk near the Suusamyr valley with a windy pass, open slopes and wide pasture views.', 'Суусамыр аңғары маңындағы биік таулы серуен: желді асу, ашық беткейлер және кең жайылым көріністері.', 42.32500000, 73.82500000, 'Manas Ordo Kyrgyzstan.jpg', ARRAY['suusamyr']::text[], ARRAY['bishkek','suusamyr']::text[], ARRAY['kyrgyzstan','chuy-region','pass','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'tudakul-lake-shore-birding-trail', 'bukhara', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая тропа озера Тудакуль', 'Tudakul Lake Shore Birding Trail', 'Тудакөл жағалау құсбақылау соқпағы', 'Природная остановка из Бухары к воде, камышам и наблюдению за птицами после насыщенной городской программы.', 'A nature stop from Bukhara toward water, reeds and birdwatching after a dense city itinerary.', 'Бұхарадан суға, қамысқа және құс бақылауға апаратын табиғи аялдама, қала бағдарламасынан кейін жақсы толықтырады.', 39.89000000, 64.85000000, 'Nuratau Mountains Uzbekistan.jpg', ARRAY['bukhara']::text[], ARRAY['bukhara']::text[], ARRAY['uzbekistan','bukhara-region','birdwatching','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'toprak-kala-desert-loop-trail', 'khiva', 'NATURE', 0, 4, 'HOURS', 4.7, 'Пустынное кольцо Топрак-Кала', 'Toprak-Kala Desert Loop Trail', 'Топрақ-қала шөл айналма соқпағы', 'Маршрут из Хивы и Ургенча к древним крепостным холмам, сухим равнинам и открытому хорезмскому горизонту.', 'A route from Khiva and Urgench toward ancient fortress hills, dry plains and the open Khorezm horizon.', 'Хиуа мен Үргеніштен көне бекініс төбелеріне, құрғақ жазықтарға және ашық Хорезм көкжиегіне апаратын бағыт.', 41.92000000, 60.83000000, 'Ayaz Kala Uzbekistan.jpg', ARRAY['khiva','urgench']::text[], ARRAY['urgench','khiva']::text[], ARRAY['uzbekistan','khorezm','desert','fortress-landscape','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'sudochye-lake-ustyurt-birding-trail', 'nukus', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа озера Судочье и Устюрта', 'Sudochye Lake Ustyurt Birding Trail', 'Судочье көлі мен Үстірт құсбақылау соқпағы', 'Маршрут из Нукуса к водно-пустынному ландшафту с птицами, тростником и ощущением края Устюрта.', 'A route from Nukus to a water-and-desert landscape with birds, reeds and the feel of the Ustyurt edge.', 'Нүкістен құстары, қамысы және Үстірт шеті сезімі бар су-шөл ландшафтына апаратын бағыт.', 43.46000000, 58.56000000, 'Aral Sea Uzbekistan.jpg', ARRAY['nukus']::text[], ARRAY['nukus']::text[], ARRAY['uzbekistan','karakalpakstan','ustyurt','birdwatching','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'moynaq-aral-seabed-dune-walk', 'muynak', 'NATURE', 0, 3, 'HOURS', 4.6, 'Дюнная прогулка по бывшему дну Арала', 'Moynaq Aral Seabed Dune Walk', 'Мойнақ Арал табаны құмды серуені', 'Короткий маршрут у Муйнака по песчаным участкам бывшего морского дна с суровым ландшафтом и сильным экологическим контекстом.', 'A short route near Moynaq across sandy sections of the former seabed with stark scenery and strong ecological context.', 'Мойнақ маңындағы бұрынғы теңіз табанының құмды бөліктерімен өтетін қысқа бағыт, қатал пейзаж және маңызды экологиялық контекст береді.', 43.78000000, 59.01000000, 'Aral Sea Uzbekistan.jpg', ARRAY['muynak']::text[], ARRAY['nukus','muynak']::text[], ARRAY['uzbekistan','karakalpakstan','aral','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'yazyavan-sands-eco-trail', 'margilan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Экотропа Язъяванских песков', 'Yazyavan Sands Eco Trail', 'Язъяван құмдары экосоқпағы', 'Ферганский природный маршрут к песчаным участкам, редкой пустынной флоре и мягкому контрасту после ремесленных остановок.', 'A Fergana nature route toward sandy areas, rare desert flora and a gentle contrast after craft stops.', 'Ферғана табиғи бағыты: құмды аумақтарға, сирек шөл флорасына және қолөнер аялдамаларынан кейінгі жұмсақ контрастқа апарады.', 40.62000000, 71.86000000, 'Yodgorlik Silk Factory Margilan.jpg', ARRAY['margilan','fergana']::text[], ARRAY['fergana','margilan']::text[], ARRAY['uzbekistan','fergana-valley','sands','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'kokand-foothill-steppe-trail', 'kokand', 'NATURE', 0, 4, 'HOURS', 4.4, 'Предгорная степная тропа Коканда', 'Kokand Foothill Steppe Trail', 'Қоқан тау етегі дала соқпағы', 'Легкий выезд из Коканда к открытым предгорьям, сельским дорогам и видам Ферганской долины.', 'An easy escape from Kokand to open foothills, village roads and Fergana Valley views.', 'Қоқаннан ашық тау етектеріне, ауыл жолдарына және Ферғана аңғары көріністеріне апаратын жеңіл бағыт.', 40.56000000, 70.76000000, 'Khudayar Khan Palace Kokand.jpg', ARRAY['kokand']::text[], ARRAY['fergana','kokand']::text[], ARRAY['uzbekistan','fergana-valley','foothills','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'sokh-river-foothill-trail', 'rishtan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Предгорная тропа реки Сох', 'Sokh River Foothill Trail', 'Сох өзені тау етегі соқпағы', 'Маршрут из Риштана к речным участкам и предгорьям, который добавляет к керамическому маршруту природную паузу.', 'A route from Rishtan toward river sections and foothills, adding a nature pause to the ceramics itinerary.', 'Риштаннан өзен бөліктері мен тау етектеріне апаратын бағыт, керамика маршрутына табиғи үзіліс қосады.', 40.28000000, 71.04000000, 'Rishtan Ceramics Uzbekistan.jpg', ARRAY['rishtan']::text[], ARRAY['fergana','rishtan']::text[], ARRAY['uzbekistan','fergana-valley','river','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'andijan-reservoir-shore-trail', 'andijan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Береговая тропа Андижанского водохранилища', 'Andijan Reservoir Shore Trail', 'Әндіжан су қоймасы жағалау соқпағы', 'Природный маршрут из Андижана к воде, холмам и открытым видам восточной Ферганской долины.', 'A nature route from Andijan toward water, hills and open views of the eastern Fergana Valley.', 'Әндіжаннан суға, қыраттарға және шығыс Ферғана аңғарының ашық көріністеріне апаратын табиғи бағыт.', 40.82000000, 73.17000000, 'Babur Museum Andijan.jpg', ARRAY['andijan']::text[], ARRAY['fergana','andijan']::text[], ARRAY['uzbekistan','andijan-region','reservoir','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'papsay-gorge-foothill-trail', 'namangan', 'NATURE', 0, 5, 'HOURS', 4.6, 'Предгорная тропа ущелья Папсай', 'Papsay Gorge Foothill Trail', 'Папсай шатқалы тау етегі соқпағы', 'Маршрут из Намангана к предгорьям Чаткала с водой, зелеными склонами и более горным сценарием для региона.', 'A route from Namangan toward Chatkal foothills with water, green slopes and a more mountain-like plan for the region.', 'Наманганнан Шатқал тау етектеріне баратын бағыт: су, жасыл беткейлер және өңір үшін таулырақ сценарий.', 41.08000000, 71.60000000, 'Namangan Flowers Garden.jpg', ARRAY['namangan']::text[], ARRAY['fergana','namangan']::text[], ARRAY['uzbekistan','namangan-region','gorge','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'charvak-ridge-view-trail', 'charvak', 'NATURE', 0, 4, 'HOURS', 4.7, 'Смотровая тропа хребта Чарвака', 'Charvak Ridge View Trail', 'Шарбақ жотасы көрініс соқпағы', 'Маршрут над водой и курортными зонами с видом на западный Тянь-Шань, подходящий для короткого mountain-day из Ташкента.', 'A route above water and resort areas with Western Tian Shan views, suited for a short mountain day from Tashkent.', 'Су мен курорттық аймақтардың үстіндегі Батыс Тянь-Шань көріністері бар бағыт, Ташкенттен қысқа mountain-day үшін қолайлы.', 41.63500000, 69.94000000, 'Charvak Reservoir Uzbekistan.jpg', ARRAY['charvak']::text[], ARRAY['tashkent','charvak']::text[], ARRAY['uzbekistan','tashkent-region','ridge','free-entry','day-hike']::text[]),
    ('UZ', 'UZS', 'surkhan-river-tugai-trail', 'termez', 'NATURE', 0, 3, 'HOURS', 4.4, 'Тугайная тропа реки Сурхандарья', 'Surkhan River Tugai Trail', 'Сұрхандария тоғай соқпағы', 'Короткая природная прогулка из Термеза к пойменной зелени, птицам и жаркому южному ландшафту Сурхандарьи.', 'A short nature walk from Termez toward floodplain greenery, birds and the hot southern Surkhandarya landscape.', 'Термезден жайылма жасылдығына, құстарға және Сұрхандарияның ыстық оңтүстік ландшафтына апаратын қысқа табиғи серуен.', 37.25000000, 67.30000000, 'Fayaztepa Buddhist Monastery.jpg', ARRAY['termez']::text[], ARRAY['termez']::text[], ARRAY['uzbekistan','surkhandarya','river','free-entry','walking']::text[]),
    ('UZ', 'UZS', 'supa-plateau-juniper-trail', 'zaamin', 'NATURE', 30000, 6, 'HOURS', 4.8, 'Арчовая тропа плато Супа', 'Supa Plateau Juniper Trail', 'Супа үстірті арша соқпағы', 'Горный маршрут Заамина к арчовым склонам, прохладному плато и открытым видам Туркестанского хребта.', 'A Zaamin mountain route toward juniper slopes, a cool plateau and open views of the Turkestan Range.', 'Зааминнің аршалы беткейлеріне, салқын үстіртіне және Түркістан жотасының ашық көріністеріне апаратын тау бағыты.', 39.65000000, 68.43000000, 'Chimgan mountains Uzbekistan.jpg', ARRAY['zaamin']::text[], ARRAY['samarkand','zaamin']::text[], ARRAY['uzbekistan','zaamin','juniper','trekking']::text[]);

CREATE TEMP TABLE seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places AS
SELECT
    ('99ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kyrgyzstan-uzbekistan-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_places;

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
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places
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
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places
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
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places
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
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places
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
FROM seed_kyrgyzstan_uzbekistan_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
