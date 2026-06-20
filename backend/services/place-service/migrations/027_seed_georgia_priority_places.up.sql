-- Priority Georgia destination places seed.
-- Georgia is a country destination, while every place stays attached to
-- a concrete city, town, resort, or practical regional reference used by admin filters.

DROP TABLE IF EXISTS seed_georgia_resolved_places;
DROP TABLE IF EXISTS seed_georgia_priority_places;

CREATE TEMP TABLE seed_georgia_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_query text NOT NULL,
    media_file text NOT NULL
);

INSERT INTO seed_georgia_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    latitude,
    longitude,
    location_query,
    media_file
) VALUES
    ('narikala-fortress', 'tbilisi', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Нарикала', 'Narikala Fortress', 'Нарикала қамалы', 'Древняя крепость над Старым Тбилиси с панорамой на серные бани, Куру и исторический центр.', 'An ancient fortress above Old Tbilisi with panoramas over the sulfur baths, the Kura River and the historic centre.', 41.68790000, 44.80860000, 'Narikala Fortress Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('abanotubani-sulfur-baths', 'tbilisi', 'OTHER', 2, 'HOURS', 4.5, 'Серные бани Абанотубани', 'Abanotubani Sulfur Baths', 'Абанотубани күкірт моншалары', 'Исторический банный район с кирпичными куполами, серными источниками и плотной атмосферой Старого Тбилиси.', 'A historic bath district with brick domes, sulfur springs and dense Old Tbilisi atmosphere.', 41.68800000, 44.81120000, 'Abanotubani Sulfur Baths Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('bridge-of-peace-tbilisi', 'tbilisi', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Мост Мира', 'Bridge of Peace', 'Бейбітшілік көпірі', 'Современный пешеходный мост между Старым городом и парком Рике, удобный для вечерней прогулки.', 'A modern pedestrian bridge between Old Tbilisi and Rike Park, useful for an evening walk.', 41.69300000, 44.80840000, 'Bridge of Peace Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('rike-park', 'tbilisi', 'PARK', 1, 'HOURS', 4.4, 'Парк Рике', 'Rike Park', 'Рике саябағы', 'Речной парк рядом с Мостом Мира и канатной дорогой, хороший старт для маршрута по Старому Тбилиси.', 'A riverside park near the Bridge of Peace and cable car, a good start for an Old Tbilisi route.', 41.69410000, 44.81060000, 'Rike Park Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('holy-trinity-cathedral-tbilisi', 'tbilisi', 'TEMPLE', 2, 'HOURS', 4.8, 'Собор Святой Троицы Самеба', 'Holy Trinity Cathedral of Tbilisi', 'Тбилиси Қасиетті Үштік соборы', 'Крупнейший современный православный собор города на холме Элия и сильная видовая точка.', 'The city largest modern Orthodox cathedral on Elia Hill and a strong viewpoint.', 41.69730000, 44.81660000, 'Holy Trinity Cathedral Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('metekhi-church', 'tbilisi', 'TEMPLE', 1, 'HOURS', 4.6, 'Церковь Метехи', 'Metekhi Church', 'Метехи шіркеуі', 'Историческая церковь на скале над Курой с видом на Старый город и район Абанотубани.', 'A historic cliffside church above the Kura River with views of Old Tbilisi and Abanotubani.', 41.69000000, 44.81110000, 'Metekhi Church Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('mtatsminda-park', 'tbilisi', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Парк Мтацминда', 'Mtatsminda Park', 'Мтацминда саябағы', 'Парк развлечений и смотровая зона над Тбилиси с колесом обозрения, кафе и семейными активностями.', 'An amusement park and viewpoint above Tbilisi with a ferris wheel, cafes and family activities.', 41.69580000, 44.78510000, 'Mtatsminda Park Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('national-botanical-garden-georgia', 'tbilisi', 'PARK', 2, 'HOURS', 4.6, 'Национальный ботанический сад Грузии', 'National Botanical Garden of Georgia', 'Грузия ұлттық ботаникалық бағы', 'Большой зеленый сад в ущелье рядом с Нарикалой, водопадом и прогулочными тропами.', 'A large green garden in the gorge beside Narikala, with a waterfall and walking paths.', 41.68470000, 44.80690000, 'National Botanical Garden of Georgia Tbilisi', 'Tbilisi,_Georgia.jpg'),
    ('turtle-lake-tbilisi', 'tbilisi', 'NATURE', 2, 'HOURS', 4.5, 'Черепашье озеро', 'Turtle Lake', 'Тасбақа көлі', 'Рекреационное озеро над Ваке для прогулок, спорта, кафе и спокойного отдыха от центра.', 'A recreational lake above Vake for walks, sport, cafes and a calm break from the centre.', 41.70135000, 44.75425000, 'Turtle Lake Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('chronicle-of-georgia', 'tbilisi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мемориал История Грузии', 'Chronicle of Georgia', 'Грузия тарихы мемориалы', 'Монументальные колонны у Тбилисского моря с рельефами и широкой панорамой города.', 'Monumental columns near the Tbilisi Sea with reliefs and broad city panoramas.', 41.77040000, 44.81050000, 'Chronicle of Georgia Tbilisi', 'Tbilisi,_Georgia.jpg'),
    ('simon-janashia-museum-georgia', 'tbilisi', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Грузии имени Симона Джанашиа', 'Simon Janashia Museum of Georgia', 'Симон Джанашиа атындағы Грузия музейі', 'Главный историко-археологический музей страны на проспекте Руставели.', 'The country main historical and archaeological museum on Rustaveli Avenue.', 41.69620000, 44.79870000, 'Simon Janashia Museum of Georgia Tbilisi', 'Tbilisi,_Georgia.jpg'),
    ('open-air-museum-ethnography-tbilisi', 'tbilisi', 'MUSEUM', 2, 'HOURS', 4.5, 'Этнографический музей под открытым небом', 'G. Chitaia Open Air Museum of Ethnography', 'Ашық аспан астындағы этнография музейі', 'Архитектура и быт регионов Грузии на зеленом склоне рядом с Черепашьим озером.', 'Architecture and everyday life of Georgian regions on a green slope near Turtle Lake.', 41.70430000, 44.74650000, 'Open Air Museum of Ethnography Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('dry-bridge-market', 'tbilisi', 'MARKET', 2, 'HOURS', 4.5, 'Блошиный рынок Сухой мост', 'Dry Bridge Market', 'Құрғақ көпір базары', 'Открытый рынок антиквариата, винтажа, картин, сувениров и городских находок.', 'An open market for antiques, vintage objects, paintings, souvenirs and city finds.', 41.70120000, 44.80290000, 'Dry Bridge Market Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('dezerter-bazaar', 'tbilisi', 'MARKET', 2, 'HOURS', 4.4, 'Дезертирский базар', 'Dezerter Bazaar', 'Дезертир базары', 'Главный продуктовый рынок Тбилиси со специями, сырами, фруктами, чурчхелой и шумным локальным ритмом.', 'Tbilisi main food market with spices, cheese, fruit, churchkhela and a lively local rhythm.', 41.72430000, 44.79350000, 'Dezerter Bazaar Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('orbeliani-bazaar', 'tbilisi', 'FOOD', 1, 'HOURS', 4.4, 'Базар Орбелиани', 'Orbeliani Bazaar', 'Орбелиани базары', 'Обновленный исторический рынок с фермерскими продуктами, кафе и фуд-холлом в центре.', 'A renewed historic market with farm produce, cafes and a central food hall.', 41.69940000, 44.80200000, 'Orbeliani Bazaar Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('meidan-bazaar', 'tbilisi', 'MARKET', 1, 'HOURS', 4.2, 'Мейдан Базар', 'Meidan Bazaar', 'Мейдан базары', 'Подземный сувенирный рынок в туристическом сердце Старого Тбилиси.', 'An underground souvenir market in the tourist heart of Old Tbilisi.', 41.68970000, 44.80940000, 'Meidan Bazaar Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('galleria-tbilisi', 'tbilisi', 'SHOPPING', 2, 'HOURS', 4.4, 'Галерея Тбилиси', 'Galleria Tbilisi', 'Galleria Tbilisi', 'Центральный торговый центр у площади Свободы с магазинами, кинотеатром и фудкортом.', 'A central mall near Freedom Square with shops, cinema and a food court.', 41.69400000, 44.80130000, 'Galleria Tbilisi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('tbilisi-mall', 'tbilisi', 'SHOPPING', 3, 'HOURS', 4.4, 'Тбилиси Молл', 'Tbilisi Mall', 'Тбилиси моллы', 'Большой молл на трассе Тбилиси-Мцхета с магазинами, развлечениями и семейным форматом.', 'A large mall on the Tbilisi-Mtskheta road with shops, entertainment and family use cases.', 41.78620000, 44.77440000, 'Tbilisi Mall Georgia', 'Tbilisi,_Georgia.jpg'),
    ('svetitskhoveli-cathedral', 'mtskheta', 'TEMPLE', 2, 'HOURS', 4.8, 'Собор Светицховели', 'Svetitskhoveli Cathedral', 'Светицховели соборы', 'Главный храм Мцхеты и один из важнейших духовных символов Грузии.', 'The main cathedral of Mtskheta and one of Georgia most important spiritual symbols.', 41.84200000, 44.72080000, 'Svetitskhoveli Cathedral Mtskheta Georgia', 'Tbilisi,_Georgia.jpg'),
    ('jvari-monastery', 'mtskheta', 'TEMPLE', 1, 'HOURS', 4.8, 'Монастырь Джвари', 'Jvari Monastery', 'Джвари монастыры', 'Монастырь на скале над слиянием Мтквари и Арагви, одна из лучших видовых точек Мцхеты.', 'A monastery on a cliff above the confluence of the Mtkvari and Aragvi rivers, one of Mtskheta best viewpoints.', 41.83850000, 44.73410000, 'Jvari Monastery Mtskheta Georgia', 'Tbilisi,_Georgia.jpg'),
    ('samtavro-monastery', 'mtskheta', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Самтавро', 'Samtavro Monastery', 'Самтавро монастыры', 'Исторический монастырский комплекс в центре Мцхеты, дополняющий маршрут Светицховели и Джвари.', 'A historic monastery complex in central Mtskheta, pairing naturally with Svetitskhoveli and Jvari.', 41.84540000, 44.71880000, 'Samtavro Monastery Mtskheta Georgia', 'Tbilisi,_Georgia.jpg'),
    ('batumi-boulevard', 'batumi', 'PARK', 3, 'HOURS', 4.7, 'Батумский бульвар', 'Batumi Boulevard', 'Батуми бульвары', 'Главная прогулочная ось у моря с пальмами, велодорожками, кафе, пляжем и вечерней жизнью.', 'The main seaside promenade with palms, bike paths, cafes, beach access and evening life.', 41.65290000, 41.63240000, 'Batumi Boulevard Georgia', 'Batumi,_Georgia.jpg'),
    ('ali-and-nino-statue', 'batumi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Скульптура Али и Нино', 'Ali and Nino Statue', 'Әли мен Нино мүсіні', 'Кинетическая скульптура у моря и один из самых узнаваемых символов Батуми.', 'A kinetic seaside sculpture and one of Batumi most recognizable symbols.', 41.65590000, 41.64100000, 'Ali and Nino Statue Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('alphabetic-tower', 'batumi', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Алфавитная башня', 'Alphabetic Tower', 'Әліпби мұнарасы', 'Высотная башня в Miracle Park, посвященная грузинскому алфавиту и городскому skyline.', 'A high-rise tower in Miracle Park dedicated to the Georgian alphabet and Batumi skyline.', 41.65530000, 41.63920000, 'Alphabetic Tower Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-miracle-park', 'batumi', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Парк чудес Батуми', 'Batumi Miracle Park', 'Батуми ғажайыптар саябағы', 'Прибрежная зона с колесом обозрения, башней, скульптурами и вечерними прогулками.', 'A seaside zone with ferris wheel, towers, sculptures and evening walks.', 41.65560000, 41.63980000, 'Miracle Park Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('argo-cable-car', 'batumi', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Канатная дорога Арго', 'Argo Cable Car', 'Арго аспалы жолы', 'Канатная дорога из центра Батуми на гору Анурия с панорамой порта, моря и города.', 'A cable car from central Batumi to Anuria Mountain with views over the port, sea and city.', 41.64660000, 41.64400000, 'Argo Cable Car Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-dolphinarium', 'batumi', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Батумский дельфинарий', 'Batumi Dolphinarium', 'Батуми дельфинарийі', 'Семейное шоу с дельфинами рядом с парком 6 Мая и понятный indoor-outdoor сценарий для детей.', 'A family dolphin show near 6 May Park and a clear indoor-outdoor scenario for children.', 41.64840000, 41.62560000, 'Batumi Dolphinarium Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-dancing-fountains', 'batumi', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Танцующие фонтаны Батуми', 'Batumi Dancing Fountains', 'Батуми билейтін субұрқақтары', 'Вечернее светомузыкальное шоу у бульвара и озера Ардагани.', 'An evening light and music show near the boulevard and Ardagani Lake.', 41.64270000, 41.61680000, 'Batumi Dancing Fountains Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-piazza', 'batumi', 'FOOD', 2, 'HOURS', 4.4, 'Пьяцца Батуми', 'Batumi Piazza', 'Батуми Пьяццасы', 'Атмосферная площадь с кафе, ресторанами, барами и вечерней городской активностью.', 'An atmospheric square with cafes, restaurants, bars and evening city activity.', 41.65070000, 41.64070000, 'Batumi Piazza Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-beach', 'batumi', 'BEACH', 3, 'HOURS', 4.3, 'Пляж Батуми', 'Batumi Beach', 'Батуми жағажайы', 'Городской галечный пляж у бульвара, отелей, кафе и летней инфраструктуры.', 'An urban pebble beach near the boulevard, hotels, cafes and summer infrastructure.', 41.63750000, 41.61080000, 'Batumi Beach Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-central-agri-market', 'batumi', 'MARKET', 2, 'HOURS', 4.4, 'Центральный агрорынок Батуми', 'Batumi Central Agri-Market', 'Батуми орталық агробазары', 'Главный рынок специй, сыров, фруктов, орехов, чурчхелы и локального гастро-опыта.', 'The main market for spices, cheese, fruit, nuts, churchkhela and local food experience.', 41.65530000, 41.64360000, 'Batumi Central Agri Market Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-fish-market', 'batumi', 'MARKET', 2, 'HOURS', 4.4, 'Рыбный рынок Батуми', 'Batumi Fish Market', 'Батуми балық базары', 'Рынок черноморской рыбы и морепродуктов с соседними кафе, где можно приготовить покупку.', 'A Black Sea fish and seafood market with nearby cafes that can cook what visitors buy.', 41.65990000, 41.67800000, 'Batumi Fish Market Georgia', 'Batumi,_Georgia.jpg'),
    ('grand-mall-batumi', 'batumi', 'SHOPPING', 3, 'HOURS', 4.4, 'Grand Mall Batumi', 'Grand Mall Batumi', 'Grand Mall Batumi', 'Крупный современный торговый центр Батуми с магазинами, едой, кино и семейными развлечениями.', 'A large modern Batumi mall with shops, food, cinema and family entertainment.', 41.63300000, 41.60990000, 'Grand Mall Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('metro-city-forum', 'batumi', 'SHOPPING', 2, 'HOURS', 4.2, 'Metro City Forum', 'Metro City Forum', 'Metro City Forum', 'Торговый центр в районе Нового бульвара с супермаркетом, фудкортом и повседневным шопингом.', 'A shopping centre near New Boulevard with supermarket, food court and everyday shopping.', 41.61560000, 41.59640000, 'Metro City Forum Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-archaeological-museum', 'batumi', 'MUSEUM', 2, 'HOURS', 4.4, 'Батумский археологический музей', 'Batumi Archaeological Museum', 'Батуми археологиялық музейі', 'Музей древней истории Аджарии с артефактами от каменного века до средневековья.', 'A museum of ancient Adjara history with artefacts from the Stone Age to the Middle Ages.', 41.64410000, 41.63120000, 'Batumi Archaeological Museum Georgia', 'Batumi,_Georgia.jpg'),
    ('batumi-botanical-garden', 'mtsvane-kontskhi', 'NATURE', 3, 'HOURS', 4.8, 'Батумский ботанический сад', 'Batumi Botanical Garden', 'Батуми ботаникалық бағы', 'Большой субтропический сад у Зеленого мыса с видами на Черное море.', 'A large subtropical garden at Green Cape with Black Sea views.', 41.69460000, 41.70760000, 'Batumi Botanical Garden Georgia', 'Batumi,_Georgia.jpg'),
    ('green-cape-beach', 'mtsvane-kontskhi', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Зеленый мыс', 'Green Cape Beach', 'Жасыл мүйіс жағажайы', 'Более спокойный пляж под склонами ботанического сада с галькой, зеленью и прозрачной водой.', 'A calmer beach below the botanical garden slopes with pebbles, greenery and clear water.', 41.69280000, 41.70490000, 'Green Cape Beach Batumi Georgia', 'Batumi,_Georgia.jpg'),
    ('gonio-kvariati-beach', 'kvariati', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Гонио-Квариати', 'Gonio-Kvariati Beach', 'Гонио-Квариати жағажайы', 'Южный пляжный кластер по дороге к Сарпи, более спокойная альтернатива центру Батуми.', 'A southern beach cluster on the road to Sarpi, a calmer alternative to central Batumi.', 41.55250000, 41.56550000, 'Gonio Kvariati Beach Georgia', 'Batumi,_Georgia.jpg'),
    ('sarpi-beach', 'sarpi', 'BEACH', 2, 'HOURS', 4.3, 'Пляж Сарпи', 'Sarpi Beach', 'Сарпи жағажайы', 'Популярный пляж у грузино-турецкой границы с прозрачной водой и летней атмосферой.', 'A popular beach near the Georgia-Turkey border with clear water and summer atmosphere.', 41.52180000, 41.54760000, 'Sarpi Beach Georgia', 'Batumi,_Georgia.jpg'),
    ('gonio-apsaros-fortress', 'gonio', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Крепость Гонио-Апсарос', 'Gonio-Apsaros Fortress', 'Гонио-Апсарос қамалы', 'Римская крепость южнее Батуми и исторический якорь маршрута к Сарпи.', 'A Roman fortress south of Batumi and a historical anchor on the Sarpi route.', 41.57350000, 41.57290000, 'Gonio Apsaros Fortress Georgia', 'Batumi,_Georgia.jpg'),
    ('petra-fortress-georgia', 'tsikhisdziri', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Крепость Петра', 'Petra Fortress', 'Петра қамалы', 'Византийская крепость на скале с видом на Черное море и побережье Аджарии.', 'A Byzantine fortress on a cliff with views of the Black Sea and Adjara coast.', 41.76880000, 41.75380000, 'Petra Fortress Tsikhisdziri Georgia', 'Batumi,_Georgia.jpg'),
    ('mtirala-national-park', 'chakvistavi', 'NATURE', 4, 'HOURS', 4.7, 'Национальный парк Мтирала', 'Mtirala National Park', 'Мтирала ұлттық паркі', 'Влажный колхидский лес, водопады, озеро и хайкинг примерно в часе от Батуми.', 'Humid Colchic forest, waterfalls, a lake and hiking about an hour from Batumi.', 41.68190000, 41.87210000, 'Mtirala National Park Georgia', 'Batumi,_Georgia.jpg'),
    ('makhuntseti-waterfall-queen-tamar-bridge', 'keda', 'NATURE', 3, 'HOURS', 4.6, 'Водопад Махунцети и мост Тамары', 'Makhuntseti Waterfall and Queen Tamar Bridge', 'Махунцети сарқырамасы және Тамара көпірі', 'Горный day-trip из Батуми с водопадом, арочным мостом и аджарским маршрутом вдоль реки.', 'A mountain day trip from Batumi with a waterfall, arched bridge and Adjara river route.', 41.57490000, 41.85810000, 'Makhuntseti Waterfall Queen Tamar Bridge Georgia', 'Batumi,_Georgia.jpg'),
    ('mirveti-waterfall', 'mirveti', 'NATURE', 2, 'HOURS', 4.4, 'Водопад Мирвети', 'Mirveti Waterfall', 'Мирвети сарқырамасы', 'Лесной водопад рядом с Батуми, хорошо дополняющий маршрут по горной Аджарии.', 'A forest waterfall near Batumi that complements mountain Adjara routes.', 41.58900000, 41.78200000, 'Mirveti Waterfall Georgia', 'Batumi,_Georgia.jpg'),
    ('kobuleti-beach', 'kobuleti', 'BEACH', 3, 'HOURS', 4.2, 'Пляж Кобулети', 'Kobuleti Beach', 'Кобулети жағажайы', 'Длинный курортный пляж севернее Батуми для спокойного морского отдыха.', 'A long resort beach north of Batumi for calmer seaside stays.', 41.82100000, 41.77600000, 'Kobuleti Beach Georgia', 'Batumi,_Georgia.jpg'),
    ('tsitsinatela-amusement-park', 'shekvetili', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Парк аттракционов Цицинатела', 'Tsitsinatela Amusement Park', 'Цицинатела ойын-сауық саябағы', 'Крупный сезонный парк аттракционов на побережье, удобный для семей из Батуми и Кобулети.', 'A large seasonal amusement park on the coast, useful for families from Batumi and Kobuleti.', 41.94070000, 41.76760000, 'Tsitsinatela Amusement Park Georgia', 'Batumi,_Georgia.jpg'),
    ('bagrati-cathedral', 'kutaisi', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Баграти', 'Bagrati Cathedral', 'Баграти соборы', 'Главный визуальный символ Кутаиси на холме Укимериони и городская смотровая точка.', 'Kutaisi main visual symbol on Ukimerioni Hill and a city viewpoint.', 42.27760000, 42.70450000, 'Bagrati Cathedral Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('gelati-monastery', 'kutaisi', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Гелати', 'Gelati Monastery', 'Гелати монастыры', 'UNESCO-монастырский комплекс и один из главных культурных объектов Западной Грузии.', 'A UNESCO monastery complex and one of western Georgia main cultural sites.', 42.29470000, 42.76840000, 'Gelati Monastery Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('motsameta-monastery', 'kutaisi', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Моцамета', 'Motsameta Monastery', 'Моцамета монастыры', 'Атмосферный монастырь в лесном ущелье между Кутаиси и Гелати.', 'An atmospheric monastery in a forested gorge between Kutaisi and Gelati.', 42.28250000, 42.75900000, 'Motsameta Monastery Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('kutaisi-state-historical-museum', 'kutaisi', 'MUSEUM', 2, 'HOURS', 4.4, 'Кутаисский исторический музей', 'Kutaisi State Historical Museum', 'Кутаиси тарихи музейі', 'Музей истории Имеретии и Колхиды, удобный indoor-старт перед поездками по региону.', 'A museum of Imereti and Colchis history, a useful indoor start before regional trips.', 42.27080000, 42.70580000, 'Kutaisi State Historical Museum Georgia', 'Kutaisi,_Georgia.jpg'),
    ('kutaisi-green-bazaar', 'kutaisi', 'MARKET', 2, 'HOURS', 4.5, 'Зеленый базар Кутаиси', 'Kutaisi Green Bazaar', 'Кутаиси жасыл базары', 'Центральный рынок с сырами, специями, фруктами, чурчхелой и локальным бытом.', 'A central market with cheese, spices, fruit, churchkhela and local everyday life.', 42.26980000, 42.70190000, 'Kutaisi Green Bazaar Georgia', 'Kutaisi,_Georgia.jpg'),
    ('colchis-fountain', 'kutaisi', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Колхидский фонтан', 'Colchis Fountain', 'Колхида субұрқағы', 'Центральная городская точка с золотыми мотивами Колхиды и удобной навигацией по центру.', 'A central city landmark with golden Colchis motifs and easy navigation around the centre.', 42.27050000, 42.70490000, 'Colchis Fountain Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('white-bridge-kutaisi', 'kutaisi', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Белый мост', 'White Bridge', 'Ақ көпір', 'Пешеходный мост и городской фото-ориентир над Риони рядом с канатной дорогой.', 'A pedestrian bridge and city photo landmark over the Rioni near the cable car.', 42.26740000, 42.70020000, 'White Bridge Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('kutaisi-botanical-garden', 'kutaisi', 'PARK', 2, 'HOURS', 4.3, 'Ботанический сад Кутаиси', 'Kutaisi Botanical Garden', 'Кутаиси ботаникалық бағы', 'Тихий зеленый сад недалеко от центра, подходящий для slow travel и семейной прогулки.', 'A quiet green garden close to the centre, suitable for slow travel and family walks.', 42.28000000, 42.70480000, 'Kutaisi Botanical Garden Georgia', 'Kutaisi,_Georgia.jpg'),
    ('besik-gabashvili-park', 'kutaisi', 'ENTERTAINMENT', 2, 'HOURS', 4.2, 'Парк Бесика Габашвили', 'Besik Gabashvili Park', 'Бесик Габашвили саябағы', 'Городской парк развлечений на холме с семейными активностями и видом на Кутаиси.', 'A hilltop city amusement park with family activities and views over Kutaisi.', 42.26600000, 42.69600000, 'Besik Gabashvili Park Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('kutaisi-aerial-tramway', 'kutaisi', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Канатная дорога Кутаиси', 'Kutaisi Aerial Tramway', 'Кутаиси аспалы жолы', 'Ретро-канатка от района Белого моста к парку Габашвили с коротким scenic ride.', 'A retro cable car from the White Bridge area to Gabashvili Park with a short scenic ride.', 42.26690000, 42.69950000, 'Kutaisi Aerial Tramway Georgia', 'Kutaisi,_Georgia.jpg'),
    ('grand-mall-kutaisi', 'kutaisi', 'SHOPPING', 2, 'HOURS', 4.1, 'Grand Mall Кутаиси', 'Grand Mall Kutaisi', 'Grand Mall Кутаиси', 'Современный торговый центр Кутаиси с магазинами, кафе и повседневными сервисами.', 'A modern Kutaisi shopping centre with stores, cafes and everyday services.', 42.25580000, 42.67310000, 'Grand Mall Kutaisi Georgia', 'Kutaisi,_Georgia.jpg'),
    ('prometheus-cave', 'tskaltubo', 'NATURE', 2, 'HOURS', 4.8, 'Пещера Прометея', 'Prometheus Cave', 'Прометей үңгірі', 'Большая туристическая карстовая пещера рядом с Цхалтубо, главный nature day-trip из Кутаиси.', 'A large tourist karst cave near Tskaltubo and a key nature day trip from Kutaisi.', 42.37660000, 42.60050000, 'Prometheus Cave Georgia', 'Kutaisi,_Georgia.jpg'),
    ('sataplia-nature-reserve', 'tskaltubo', 'NATURE', 3, 'HOURS', 4.6, 'Заповедник Сатаплия', 'Sataplia Nature Reserve', 'Сатаплия қорығы', 'Пещера, колхидский лес, следы динозавров и обзорная площадка рядом с Кутаиси.', 'A cave, Colchic forest, dinosaur footprints and viewpoint near Kutaisi.', 42.31230000, 42.67370000, 'Sataplia Nature Reserve Georgia', 'Kutaisi,_Georgia.jpg'),
    ('okatse-canyon', 'khoni', 'NATURE', 3, 'HOURS', 4.6, 'Каньон Окаце', 'Okatse Canyon', 'Окаце каньоны', 'Каньон с подвесной тропой, лесной дорогой и сильной adventure-фототочкой.', 'A canyon with a hanging walkway, forest road and strong adventure photo value.', 42.45550000, 42.52700000, 'Okatse Canyon Georgia', 'Kutaisi,_Georgia.jpg'),
    ('kinchkha-waterfall', 'khoni', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Кинчха', 'Kinchkha Waterfall', 'Кинчха сарқырамасы', 'Высокий каскадный водопад, который удобно объединять с маршрутом по каньону Окаце.', 'A tall cascading waterfall that pairs naturally with the Okatse Canyon route.', 42.49400000, 42.54800000, 'Kinchkha Waterfall Georgia', 'Kutaisi,_Georgia.jpg'),
    ('martvili-canyon', 'martvili', 'NATURE', 3, 'HOURS', 4.7, 'Каньон Мартвили', 'Martvili Canyon', 'Мартвили каньоны', 'Бирюзовый каньон с короткой лодочной прогулкой и популярный day-trip из Кутаиси.', 'A turquoise canyon with a short boat ride and a popular day trip from Kutaisi.', 42.45700000, 42.37700000, 'Martvili Canyon Georgia', 'Kutaisi,_Georgia.jpg'),
    ('navenakhevi-cave', 'terjola', 'NATURE', 1, 'HOURS', 4.2, 'Пещера Навенахеви', 'Navenakhevi Cave', 'Навенахеви үңгірі', 'Компактная благоустроенная пещера, менее перегруженная альтернатива популярным маршрутам.', 'A compact visitor-ready cave and a quieter alternative to the busiest cave routes.', 42.19200000, 42.96500000, 'Navenakhevi Cave Georgia', 'Kutaisi,_Georgia.jpg'),
    ('vani-archaeological-museum', 'vani', 'MUSEUM', 2, 'HOURS', 4.5, 'Археологический музей Вани', 'Vani Archaeological Museum', 'Вани археологиялық музейі', 'Музей Колхиды и золотого наследия, важный культурный слой для маршрутов Западной Грузии.', 'A museum of Colchis and golden heritage, an important cultural layer for western Georgia routes.', 42.08380000, 42.51180000, 'Vani Archaeological Museum Georgia', 'Kutaisi,_Georgia.jpg'),
    ('katskhi-pillar', 'chiatura', 'TEMPLE', 2, 'HOURS', 4.6, 'Столп Кацхи', 'Katskhi Pillar', 'Кацхи бағанасы', 'Драматичный известняковый монолит с церковью наверху и сильным visual wow-эффектом.', 'A dramatic limestone monolith with a church on top and strong visual wow effect.', 42.28730000, 43.21530000, 'Katskhi Pillar Georgia', 'Kutaisi,_Georgia.jpg'),
    ('mghvimevi-monastery', 'chiatura', 'TEMPLE', 1, 'HOURS', 4.4, 'Монастырь Мгвимеви', 'Mghvimevi Monastery', 'Мгвимеви монастыры', 'Скальный монастырь в долине Квирила, хорошо дополняющий маршрут Кацхи и Чиатура.', 'A rock monastery in the Kvirila valley, pairing well with Katskhi and Chiatura.', 42.29280000, 43.28400000, 'Mghvimevi Monastery Georgia', 'Kutaisi,_Georgia.jpg'),
    ('sairme-zipline', 'baghdati', 'ENTERTAINMENT', 2, 'HOURS', 4.2, 'Зиплайн Саирме', 'Sairme Zipline', 'Саирме zipline', 'Активность в курортной зоне Саирме с лесными видами и outdoor-сценарием.', 'An activity in the Sairme resort area with forest views and an outdoor scenario.', 41.86170000, 42.81220000, 'Sairme Zipline Georgia', 'Kutaisi,_Georgia.jpg'),
    ('gergeti-trinity-church', 'stepantsminda', 'TEMPLE', 3, 'HOURS', 4.9, 'Троицкая церковь Гергети', 'Gergeti Trinity Church', 'Гергети Үштік шіркеуі', 'Иконический храм над Степанцминдой с видом на Казбек и долину Терека.', 'An iconic church above Stepantsminda with views of Mount Kazbek and the Terek valley.', 42.66260000, 44.62080000, 'Gergeti Trinity Church Stepantsminda Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('mount-kazbek-viewpoint', 'stepantsminda', 'NATURE', 2, 'HOURS', 4.8, 'Видовая точка на Казбек', 'Mount Kazbek / Gergeti Viewpoint', 'Қазбек көрініс нүктесі', 'Панорама Казбека, Гергети, долины Терека и Кавказского хребта.', 'A panorama over Mount Kazbek, Gergeti, the Terek valley and the Caucasus ridge.', 42.65890000, 44.62200000, 'Mount Kazbek Gergeti Viewpoint Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('gveleti-waterfall', 'stepantsminda', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Гвелети', 'Gveleti Waterfall', 'Гвелети сарқырамасы', 'Короткий природный хайк в Дарьяльском ущелье рядом со Степанцминдой.', 'A short nature hike in the Dariali Gorge near Stepantsminda.', 42.70480000, 44.61560000, 'Gveleti Waterfall Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('truso-valley', 'stepantsminda', 'NATURE', 5, 'HOURS', 4.8, 'Долина Трусо', 'Truso Valley', 'Трусо аңғары', 'Горная долина с минеральными источниками, травертинами и jeep-hiking маршрутом.', 'A mountain valley with mineral springs, travertines and jeep-hiking routes.', 42.58700000, 44.45000000, 'Truso Valley Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('juta-chaukhi-massif', 'stepantsminda', 'NATURE', 5, 'HOURS', 4.8, 'Джута и массив Чаухи', 'Juta and Chaukhi Massif', 'Джута және Чаухи массиві', 'Высокогорная деревня и старт к маршрутам под скальным массивом Чаухи.', 'A highland village and trailhead beneath the rocky Chaukhi massif.', 42.56670000, 44.74400000, 'Juta Chaukhi Massif Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('gudauri-ski-resort', 'gudauri', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Горнолыжный курорт Гудаури', 'Gudauri Ski Resort', 'Гудаури тау шаңғы курорты', 'Главный горнолыжный курорт Военно-Грузинской дороги, актуальный зимой и летом для видов.', 'The main ski resort on the Georgian Military Highway, useful in winter and for summer views.', 42.47750000, 44.47620000, 'Gudauri Ski Resort Georgia', 'Gergeti_Trinity_Church,_Georgia.jpg'),
    ('bodbe-monastery', 'sighnaghi', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Бодбе', 'Bodbe Monastery', 'Бодбе монастыры', 'Монастырь у Сигнахи, связанный со святой Нино и видом на Алазанскую долину.', 'A monastery near Sighnaghi connected with Saint Nino and views over the Alazani Valley.', 41.60680000, 45.92570000, 'Bodbe Monastery Sighnaghi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('sighnaghi-old-town-walls', 'sighnaghi', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый город и стены Сигнахи', 'Sighnaghi Old Town and Walls', 'Сигнахи ескі қаласы және қамал қабырғалары', 'Каменные улицы, крепостные стены и вид на Алазанскую долину в винном регионе.', 'Stone streets, fortress walls and Alazani Valley views in the wine region.', 41.62090000, 45.92160000, 'Sighnaghi Old Town Georgia', 'Tbilisi,_Georgia.jpg'),
    ('tsinandali-estate', 'telavi', 'FOOD', 2, 'HOURS', 4.6, 'Усадьба Цинандали', 'Tsinandali Estate', 'Цинандали үй-жайы', 'Историческая усадьба с садом, винным погребом и культурным контекстом Кахетии.', 'A historic estate with a garden, wine cellar and Kakheti cultural context.', 41.89310000, 45.57080000, 'Tsinandali Estate Georgia', 'Tbilisi,_Georgia.jpg'),
    ('telavi-bazaar', 'telavi', 'MARKET', 2, 'HOURS', 4.3, 'Базар Телави', 'Telavi Bazaar', 'Телави базары', 'Локальный рынок Кахетии с фруктами, специями, сырами и продуктами для гастро-маршрута.', 'A local Kakheti market with fruit, spices, cheese and products for food routes.', 41.91870000, 45.47310000, 'Telavi Bazaar Georgia', 'Tbilisi,_Georgia.jpg'),
    ('batonistsikhe-fortress', 'telavi', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Крепость Батонисцихе', 'Batonistsikhe Fortress', 'Батонисцихе қамалы', 'Царская резиденция кахетинских царей и музейный комплекс в центре Телави.', 'A royal residence of Kakhetian kings and museum complex in central Telavi.', 41.91990000, 45.47340000, 'Batonistsikhe Fortress Telavi Georgia', 'Tbilisi,_Georgia.jpg'),
    ('gremi-monastic-complex', 'kvareli', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Монастырский комплекс Греми', 'Gremi Monastic Complex', 'Греми монастырлық кешені', 'Бывшая столица Кахетии с крепостью, храмом, дворцом и музейным слоем.', 'A former Kakheti capital with a fortress, church, palace and museum layer.', 42.00160000, 45.66080000, 'Gremi Monastic Complex Georgia', 'Tbilisi,_Georgia.jpg'),
    ('nekresi-monastery', 'kvareli', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Некреси', 'Nekresi Monastery', 'Некреси монастыры', 'Горный монастырский комплекс над Алазанской долиной рядом с Кварели.', 'A mountain monastery complex above the Alazani Valley near Kvareli.', 41.97280000, 45.75970000, 'Nekresi Monastery Georgia', 'Tbilisi,_Georgia.jpg'),
    ('alaverdi-monastery', 'telavi', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Алаверди', 'Alaverdi Monastery', 'Алаверди монастыры', 'Один из крупнейших храмов Грузии среди кахетинских виноградников.', 'One of Georgia largest churches among Kakheti vineyards.', 42.03240000, 45.37740000, 'Alaverdi Monastery Georgia', 'Tbilisi,_Georgia.jpg'),
    ('borjomi-central-park', 'borjomi', 'PARK', 3, 'HOURS', 4.6, 'Центральный парк Боржоми', 'Borjomi Central Park', 'Боржоми орталық саябағы', 'Курортный парк с минеральным источником, прогулками и семейной инфраструктурой.', 'A resort park with mineral spring, walks and family infrastructure.', 41.83640000, 43.38960000, 'Borjomi Central Park Georgia', 'Kutaisi,_Georgia.jpg'),
    ('borjomi-kharagauli-national-park', 'borjomi', 'NATURE', 5, 'HOURS', 4.7, 'Национальный парк Боржоми-Харагаули', 'Borjomi-Kharagauli National Park', 'Боржоми-Харагаули ұлттық паркі', 'Один из крупнейших природных парков Кавказа с лесами, горами и треккинговыми маршрутами.', 'One of the Caucasus largest nature parks with forests, mountains and trekking routes.', 41.85000000, 43.30000000, 'Borjomi Kharagauli National Park Georgia', 'Kutaisi,_Georgia.jpg'),
    ('bakuriani-ski-resort', 'bakuriani', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'Горнолыжный курорт Бакуриани', 'Bakuriani Ski Resort', 'Бакуриани тау шаңғы курорты', 'Горный курорт для зимних активностей, семейного отдыха и летних прогулок.', 'A mountain resort for winter activities, family stays and summer walks.', 41.74970000, 43.53250000, 'Bakuriani Ski Resort Georgia', 'Kutaisi,_Georgia.jpg'),
    ('uplistsikhe-cave-town', 'uplistsikhe', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Пещерный город Уплисцихе', 'Uplistsikhe Cave Town', 'Уплисцихе үңгір қаласы', 'Древний скальный город у Мтквари и сильная культурная остановка рядом с Гори.', 'An ancient rock-cut town by the Mtkvari River and a strong cultural stop near Gori.', 41.96750000, 44.20750000, 'Uplistsikhe Cave Town Georgia', 'Tbilisi,_Georgia.jpg'),
    ('stalin-museum-gori', 'gori', 'MUSEUM', 2, 'HOURS', 4.1, 'Музей Сталина в Гори', 'Stalin Museum in Gori', 'Горидегі Сталин музейі', 'Исторически спорный, но посещаемый музей советской эпохи, который важно описывать нейтрально.', 'A historically sensitive but heavily visited Soviet-era museum that should be framed neutrally.', 41.98620000, 44.11340000, 'Stalin Museum Gori Georgia', 'Tbilisi,_Georgia.jpg'),
    ('gori-fortress', 'gori', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Крепость Гори', 'Gori Fortress', 'Гори қамалы', 'Крепость над городом и удобная обзорная точка для маршрута Гори-Уплисцихе.', 'A fortress above the city and a useful viewpoint on the Gori-Uplistsikhe route.', 41.98470000, 44.10860000, 'Gori Fortress Georgia', 'Tbilisi,_Georgia.jpg'),
    ('vardzia-cave-monastery', 'vardzia', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Пещерный монастырь Вардзия', 'Vardzia Cave Monastery', 'Вардзия үңгір монастыры', 'Масштабный средневековый пещерный комплекс на склоне Эрушети.', 'A large medieval cave complex on the slope of the Erusheti mountain.', 41.38110000, 43.28470000, 'Vardzia Cave Monastery Georgia', 'Kutaisi,_Georgia.jpg'),
    ('upper-vardzia-convent', 'vardzia', 'TEMPLE', 2, 'HOURS', 4.5, 'Верхняя Вардзия', 'Upper Vardzia Convent', 'Жоғарғы Вардзия', 'Более тихий пещерный монастырский объект рядом с основным комплексом Вардзии.', 'A quieter cave convent near the main Vardzia complex.', 41.38900000, 43.27500000, 'Upper Vardzia Convent Georgia', 'Kutaisi,_Georgia.jpg'),
    ('khertvisi-fortress', 'aspindza', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Крепость Хертвиси', 'Khertvisi Fortress', 'Хертвиси қамалы', 'Одна из старейших крепостей Грузии и логичная остановка на дороге к Вардзии.', 'One of Georgia oldest fortresses and a natural stop on the road to Vardzia.', 41.47940000, 43.28560000, 'Khertvisi Fortress Georgia', 'Kutaisi,_Georgia.jpg'),
    ('svaneti-museum-history-ethnography', 'mestia', 'MUSEUM', 2, 'HOURS', 4.7, 'Сванетский историко-этнографический музей', 'Svaneti Museum of History and Ethnography', 'Сванети тарихи-этнографиялық музейі', 'Главный музей Сванетии с иконами, рукописями и этнографией региона.', 'The main museum of Svaneti with icons, manuscripts and regional ethnography.', 43.04570000, 42.72780000, 'Svaneti Museum of History and Ethnography Mestia Georgia', 'Kutaisi,_Georgia.jpg'),
    ('mestia-svan-towers', 'mestia', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Сванские башни Местии', 'Svan Towers of Mestia', 'Местияның сван мұнаралары', 'Средневековые оборонительные башни и визуальный символ Сванетии.', 'Medieval defensive towers and the visual symbol of Svaneti.', 43.04300000, 42.72400000, 'Svan Towers Mestia Georgia', 'Kutaisi,_Georgia.jpg'),
    ('koruldi-lakes', 'mestia', 'NATURE', 5, 'HOURS', 4.8, 'Озера Корулди', 'Koruldi Lakes', 'Корулди көлдері', 'Высокогорные озера над Местией с видами на Ушбу и Кавказский хребет.', 'High mountain lakes above Mestia with views of Ushba and the Caucasus ridge.', 43.08820000, 42.69070000, 'Koruldi Lakes Mestia Georgia', 'Kutaisi,_Georgia.jpg'),
    ('chalaadi-glacier', 'mestia', 'NATURE', 5, 'HOURS', 4.7, 'Ледник Чалаади', 'Chalaadi Glacier', 'Чалаади мұздығы', 'Доступный трек к леднику у склонов Ушбы и Чатини.', 'An accessible glacier hike near the slopes of Ushba and Chatini.', 43.11700000, 42.68900000, 'Chalaadi Glacier Mestia Georgia', 'Kutaisi,_Georgia.jpg'),
    ('hatsvali-zuruldi-cable-car', 'mestia', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Хацвали и канатная дорога Зурулди', 'Hatsvali / Zuruldi Cable Car', 'Хацвали және Зурулди аспалы жолы', 'Горнолыжная зона и панорамная канатка над Местией для зимних и летних видов.', 'A ski area and panoramic cable car above Mestia for winter and summer views.', 43.03300000, 42.73300000, 'Hatsvali Zuruldi Cable Car Mestia Georgia', 'Kutaisi,_Georgia.jpg'),
    ('ushguli-village', 'ushguli', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Деревня Ушгули', 'Ushguli Village', 'Ушгули ауылы', 'Высокогорные средневековые деревни со сванскими башнями и видом на Шхару.', 'High mountain medieval villages with Svan towers and views of Shkhara.', 42.91670000, 43.01670000, 'Ushguli Village Georgia', 'Kutaisi,_Georgia.jpg');

CREATE TEMP TABLE seed_georgia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-georgia-place:' || seed.slug) AS place_hash,
        md5('id-georgia-media:' || seed.slug) AS media_hash
    FROM seed_georgia_priority_places seed
)
SELECT
    (
        substr(place_hash, 1, 8) || '-' ||
        substr(place_hash, 9, 4) || '-4' ||
        substr(place_hash, 14, 3) || '-8' ||
        substr(place_hash, 18, 3) || '-' ||
        substr(place_hash, 21, 12)
    )::uuid AS id,
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    ARRAY['georgia', city_id, slug, lower(category), 'georgia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    'Грузия бағыты бойынша туристік орын: ' || title_kk || '. Ел, қала және маршрут бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
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
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'GE',
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
FROM seed_georgia_resolved_places
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

INSERT INTO place_translations (
    place_id,
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
FROM seed_georgia_resolved_places seed
CROSS JOIN (VALUES ('ru'), ('en'), ('kk')) AS locale_rows(locale)
ON CONFLICT (place_id, locale) DO UPDATE
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
    FROM seed_georgia_resolved_places
)
UPDATE places
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE places.id = seed_locations.id
    AND places.source = 'IMPORT';

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
    source_url,
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM seed_georgia_resolved_places
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = seed_georgia_resolved_places.id
)
ON CONFLICT (id) DO UPDATE
SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, 'GE', city_id, 0, NOW()
FROM seed_georgia_resolved_places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_georgia_resolved_places;
DROP TABLE IF EXISTS seed_georgia_priority_places;
