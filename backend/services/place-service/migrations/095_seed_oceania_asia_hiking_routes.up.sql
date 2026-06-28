-- Oceania and remaining Asia route-level hiking/day-hike seed.
-- This layer adds concrete trails without duplicating broad parks, temples and previously seeded place anchors.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_oceania_asia_hiking_resolved_places;
DROP TABLE IF EXISTS seed_oceania_asia_hiking_places;

CREATE TEMP TABLE seed_oceania_asia_hiking_places (
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

INSERT INTO seed_oceania_asia_hiking_places (
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
    ('grand-canyon-track-blue-mountains', 'AU', 'blue-mountains', 'NATURE', 0, 'AUD', 4, 'HOURS', 4.9, 'Тропа Grand Canyon в Голубых горах', 'Grand Canyon Track', 'Көк таулар Grand Canyon соқпағы', 'Классический лесной маршрут Голубых гор с каменными стенами, ручьями и прохладными ущельями для насыщенного дневного плана.', 'A classic Blue Mountains forest route with stone walls, creeks and cool gullies for a rich day plan.', 'Көк таулардағы классикалық орман бағыты: тас қабырғалар, бұлақтар және салқын шатқалдар арқылы өтеді.', -33.63800000, 150.32100000, 'Blue_Mountains_National_Park_(AU),_Three_Sisters_--_2019_--_1987-9.jpg', ARRAY['blue-mountains']::text[], ARRAY['blue-mountains','sydney']::text[], ARRAY['australia','new-south-wales','gorge','day-hike']::text[]),
    ('bondi-coogee-coastal-walk', 'AU', 'sydney', 'NATURE', 0, 'AUD', 3, 'HOURS', 4.8, 'Прибрежная прогулка Бондай - Куджи', 'Bondi to Coogee Coastal Walk', 'Бондайдан Куджиге жағалау серуені', 'Городской coastal-маршрут Сиднея с океаном, скалами, бухтами и удобным форматом без дальнего трансфера.', 'A Sydney coastal route with ocean views, cliffs, coves and an easy no-transfer format.', 'Сиднейдегі мұхит, жартастар, шағын шығанақтар және алыс жолсыз ыңғайлы формат бар жағалау бағыты.', -33.89700000, 151.27400000, 'Exterior_of_Sydney_Opera_House.jpg', ARRAY['sydney']::text[], ARRAY['sydney']::text[], ARRAY['australia','sydney','coastal','walking']::text[]),
    ('mount-ainslie-summit-trail', 'AU', 'canberra', 'NATURE', 0, 'AUD', 2, 'HOURS', 4.7, 'Тропа на гору Ainslie', 'Mount Ainslie Summit Trail', 'Ainslie тауына соқпақ', 'Короткий подъем в Канберре к панораме парламентской оси, зеленых кварталов и окружающих холмов.', 'A short Canberra climb to views over the parliamentary axis, green districts and surrounding hills.', 'Канберрадағы парламент осіне, жасыл аудандарға және төңіректегі төбелерге көрініс беретін қысқа көтерілу.', -35.27500000, 149.16000000, 'Parliament_House_at_dusk,_Canberra_ACT.jpg', ARRAY['canberra']::text[], ARRAY['canberra']::text[], ARRAY['australia','canberra','summit','free-entry']::text[]),
    ('kunanyi-organ-pipes-track', 'AU', 'hobart', 'NATURE', 0, 'AUD', 4, 'HOURS', 4.8, 'Тропа Organ Pipes на kunanyi', 'kunanyi Organ Pipes Track', 'kunanyi Organ Pipes соқпағы', 'Горный маршрут над Хобартом к долеритовым стенам, лесным участкам и открытому виду на залив.', 'A mountain route above Hobart toward dolerite columns, forest sections and open bay views.', 'Хобарт үстіндегі долерит қабырғаларына, орманды бөліктерге және шығанақ көрінісіне апаратын тау бағыты.', -42.89500000, 147.23700000, 'Hobart_Tasmania_Salamanca_Place.jpg', ARRAY['hobart']::text[], ARRAY['hobart']::text[], ARRAY['australia','tasmania','mountain','hiking']::text[]),
    ('noosa-headland-coastal-walk', 'AU', 'noosa', 'NATURE', 0, 'AUD', 3, 'HOURS', 4.8, 'Прибрежная тропа мыса Нуса', 'Noosa Headland Coastal Walk', 'Нуса мүйісі жағалау соқпағы', 'Легкий маршрут по мысу с океанскими видами, эвкалиптами, бухтами и хорошим форматом для половины дня.', 'An easy headland route with ocean views, eucalyptus sections, coves and a good half-day format.', 'Мұхит көрінісі, эвкалипт бөліктері, шағын шығанақтар және жарты күнге қолайлы жеңіл бағыт.', -26.38600000, 153.09300000, 'South_Bank_ferry_wharf_seen_from_the_river,_June_2019.jpg', ARRAY['noosa']::text[], ARRAY['noosa','sunshine-coast']::text[], ARRAY['australia','queensland','coastal','walking']::text[]),
    ('rangitoto-summit-track', 'NZ', 'auckland', 'NATURE', 0, 'NZD', 5, 'HOURS', 4.8, 'Тропа на вершину Rangitoto', 'Rangitoto Summit Track', 'Rangitoto шыңына соқпақ', 'Островной маршрут Окленда по лавовым полям и кустарнику к кратеру с видом на гавань и город.', 'An Auckland island route across lava fields and bush toward a crater viewpoint over the harbour and city.', 'Окленд маңындағы арал бағыты: лава алаңдары мен бұталар арқылы айлақ пен қала көрінісіне апарады.', -36.78600000, 174.86100000, 'Mount_Eden_Auckland.jpg', ARRAY['auckland']::text[], ARRAY['auckland']::text[], ARRAY['new-zealand','auckland','volcanic','day-hike']::text[]),
    ('mauao-summit-track', 'NZ', 'mount-maunganui', 'NATURE', 0, 'NZD', 2, 'HOURS', 4.8, 'Тропа на вершину Mauao', 'Mauao Summit Track', 'Mauao шыңына соқпақ', 'Короткий, но выразительный подъем над заливом с океаном, пляжами и круговой панорамой побережья.', 'A short but expressive climb above the bay with ocean, beaches and a wide coastal panorama.', 'Шығанақ үстіндегі қысқа әрі әсерлі көтерілу: мұхит, жағажайлар және жағалаудың кең панорамасы.', -37.63200000, 176.17200000, 'Mount_Maunganui_Beach.jpg', ARRAY['mount-maunganui']::text[], ARRAY['mount-maunganui','tauranga']::text[], ARRAY['new-zealand','bay-of-plenty','summit','walking']::text[]),
    ('ben-lomond-track-queenstown', 'NZ', 'queenstown', 'NATURE', 0, 'NZD', 7, 'HOURS', 4.9, 'Тропа Ben Lomond', 'Ben Lomond Track', 'Ben Lomond соқпағы', 'Сильный горный маршрут Квинстауна к гребню с видами на озеро, хребты и альпийский ландшафт.', 'A strong Queenstown mountain route to a ridge with lake, range and alpine views.', 'Квинстаундағы көлге, жоталарға және альпілік ландшафтқа көрініс беретін қарқынды тау бағыты.', -45.02200000, 168.64200000, 'Lake_Wakatipu.jpg', ARRAY['queenstown']::text[], ARRAY['queenstown']::text[], ARRAY['new-zealand','queenstown','summit','trekking']::text[]),
    ('key-summit-track', 'NZ', 'fiordland', 'NATURE', 0, 'NZD', 3, 'HOURS', 4.8, 'Тропа Key Summit', 'Key Summit Track', 'Key Summit соқпағы', 'Альпийский маршрут района Фьордленда к болотным плато, озерным чашам и видам на долину Divide.', 'An alpine Fiordland area route to wetland plateaus, tarns and views over the Divide valley.', 'Фьордленд аймағындағы альпілік бағыт: батпақты үстірттер, шағын көлдер және Divide аңғарына көріністер.', -44.78400000, 168.00600000, 'Fiordland_National_Park.jpg', ARRAY['fiordland']::text[], ARRAY['fiordland','queenstown']::text[], ARRAY['new-zealand','fiordland','alpine','day-hike']::text[]),
    ('mount-victoria-lookout-walk', 'NZ', 'wellington', 'NATURE', 0, 'NZD', 2, 'HOURS', 4.7, 'Прогулка к смотровой Mount Victoria', 'Mount Victoria Lookout Walk', 'Mount Victoria көрінісіне серуен', 'Городской холм Веллингтона с лесными дорожками и быстрым выходом к панораме гавани.', 'A Wellington city hill route with forest paths and quick access to a harbour panorama.', 'Веллингтондағы орман жолдары мен айлақ панорамасына жылдам шығатын қала төбесі бағыты.', -41.29600000, 174.79400000, 'Wellington_Cable_Car.jpg', ARRAY['wellington']::text[], ARRAY['wellington']::text[], ARRAY['new-zealand','wellington','viewpoint','walking']::text[]),
    ('ba-vi-summit-trail', 'VN', 'hanoi', 'NATURE', 60000, 'VND', 5, 'HOURS', 4.7, 'Тропа на вершины Ba Vi', 'Ba Vi Summit Trail', 'Ba Vi шыңдарына соқпақ', 'Дневной маршрут из Ханоя к зеленым вершинам, влажному лесу и прохладному горному воздуху рядом со столицей.', 'A day route from Hanoi toward green summits, humid forest and cooler mountain air near the capital.', 'Ханойдан жасыл шыңдарға, ылғалды орманға және астанаға жақын салқын тау ауасына апаратын күндік бағыт.', 21.07000000, 105.37000000, 'Hanoi_panoramic_view_from_Lotte_3.jpg', ARRAY['hanoi']::text[], ARRAY['hanoi']::text[], ARRAY['vietnam','hanoi','forest','day-hike']::text[]),
    ('lang-biang-peak-trail', 'VN', 'da-lat', 'NATURE', 50000, 'VND', 5, 'HOURS', 4.7, 'Тропа на пик Lang Biang', 'Lang Biang Peak Trail', 'Lang Biang шыңына соқпақ', 'Горный маршрут Далата с сосновыми участками, прохладным климатом и видом на плато Ламдонг.', 'A Da Lat mountain route with pine sections, cool climate and views over the Lam Dong plateau.', 'Далаттағы қарағайлы бөліктер, салқын климат және Ламдонг үстіртіне көрініс беретін тау бағыты.', 12.04500000, 108.44200000, 'Datanla_Waterfall_1.jpg', ARRAY['da-lat']::text[], ARRAY['da-lat']::text[], ARRAY['vietnam','da-lat','mountain','hiking']::text[]),
    ('bach-ma-hai-vong-dai-trail', 'VN', 'hue', 'NATURE', 60000, 'VND', 5, 'HOURS', 4.8, 'Тропа Bach Ma к Hai Vong Dai', 'Bach Ma Hai Vong Dai Trail', 'Bach Ma Hai Vong Dai соқпағы', 'Маршрут из Хюэ в горный лес с обзорной башней, влажными тропами и видами к лагунам и побережью.', 'A Hue area route into mountain forest with a lookout tower, humid paths and views toward lagoons and the coast.', 'Хюэ аймағындағы тау орманына, қарауыл мұнарасына, ылғалды соқпақтарға және лагуналар мен жағалауға көріністерге апаратын бағыт.', 16.20000000, 107.85300000, 'Perfume River, Hue, Vietnam (6927400994).jpg', ARRAY['hue']::text[], ARRAY['hue','da-nang']::text[], ARRAY['vietnam','bach-ma','forest','trekking']::text[]),
    ('monks-trail-wat-pha-lat', 'TH', 'chiang-mai', 'NATURE', 0, 'THB', 3, 'HOURS', 4.8, 'Тропа монахов к Wat Pha Lat', $$Monk's Trail to Wat Pha Lat$$, 'Wat Pha Lat-қа монахтар соқпағы', 'Лесной подъем из Чиангмая к тихому храму на склоне, с камнями, ручьями и видом на город.', 'A forest climb from Chiang Mai to a quiet hillside temple, with rocks, streams and city views.', 'Чиангмайдан беткейдегі тыныш ғибадатханаға апаратын орманды көтерілу: тастар, бұлақтар және қала көрінісі.', 18.79800000, 98.93700000, 'Doi_Inthanon_National_Park.jpg', ARRAY['chiang-mai']::text[], ARRAY['chiang-mai']::text[], ARRAY['thailand','chiang-mai','forest','temple-walk']::text[]),
    ('railay-viewpoint-lagoon-trail', 'TH', 'krabi', 'NATURE', 0, 'THB', 2, 'HOURS', 4.7, 'Тропа к смотровой Railay и лагуне', 'Railay Viewpoint and Lagoon Trail', 'Railay көрінісі мен лагунасына соқпақ', 'Короткий, крутой маршрут Краби по известняковому рельефу к смотровой площадке и скрытой лагуне.', 'A short steep Krabi route across limestone terrain toward a viewpoint and hidden lagoon.', 'Крабидегі әктас бедерімен көрініс алаңы мен жасырын лагунаға апаратын қысқа тік бағыт.', 8.01000000, 98.83800000, 'Railay Beach 2.jpg', ARRAY['krabi']::text[], ARRAY['krabi']::text[], ARRAY['thailand','krabi','limestone','hiking']::text[]),
    ('osmena-peak-trail', 'PH', 'cebu-city', 'NATURE', 50, 'PHP', 3, 'HOURS', 4.7, 'Тропа на пик Osmena', 'Osmena Peak Trail', 'Osmena шыңына соқпақ', 'Горный маршрут Себу к зубчатым холмам и открытому виду на острова, удобный для утреннего выезда.', 'A Cebu mountain route to jagged hills and open island views, convenient for a morning departure.', 'Себудегі тісті төбелер мен аралдарға ашық көрініс беретін таңғы сапарға қолайлы тау бағыты.', 9.82900000, 123.45400000, 'Sirao_Flower_Garden_Cebu.jpg', ARRAY['cebu-city']::text[], ARRAY['cebu-city']::text[], ARRAY['philippines','cebu','summit','day-hike']::text[]),
    ('marlboro-hills-blue-soil-trail', 'PH', 'sagada', 'NATURE', 100, 'PHP', 4, 'HOURS', 4.8, 'Тропа Marlboro Hills и Blue Soil', 'Marlboro Hills Blue Soil Trail', 'Marlboro Hills және Blue Soil соқпағы', 'Высокогорная прогулка Сагады с рассветными холмами, сосновыми склонами и необычным голубоватым грунтом.', 'A Sagada highland walk with sunrise hills, pine slopes and unusual bluish soil.', 'Сагададағы таңғы төбелер, қарағайлы беткейлер және ерекше көгілдір топырақ арқылы өтетін биік таулы серуен.', 17.10500000, 120.89900000, 'Sagada_Hanging_Coffins.jpg', ARRAY['sagada']::text[], ARRAY['sagada','baguio']::text[], ARRAY['philippines','sagada','highlands','hiking']::text[]),
    ('mount-abang-trail', 'ID', 'kintamani', 'NATURE', 100000, 'IDR', 6, 'HOURS', 4.8, 'Тропа на гору Abang', 'Mount Abang Trail', 'Abang тауына соқпақ', 'Балийский горный маршрут над Кинтамани с лесом, рассветными видами и панорамой вулканического ландшафта.', 'A Bali mountain route above Kintamani with forest, sunrise views and volcanic landscape panoramas.', 'Кинтамани үстіндегі орман, таңғы көріністер және жанартаулық ландшафт панорамалары бар Бали тау бағыты.', -8.28000000, 115.42100000, 'Bangly-Regency_Bali_Indonesia_Lake-Batur-01.jpg', ARRAY['kintamani']::text[], ARRAY['kintamani','ubud']::text[], ARRAY['indonesia','bali','volcanic','trekking']::text[]),
    ('tamblingan-forest-loop-trail', 'ID', 'munduk', 'NATURE', 50000, 'IDR', 4, 'HOURS', 4.7, 'Лесная петля Tamblingan', 'Tamblingan Forest Loop Trail', 'Tamblingan орман ілмегі', 'Маршрут Мундука через влажный лес, храмы у воды и тихие участки северной горной Бали.', 'A Munduk route through humid forest, waterside temples and quiet sections of north mountain Bali.', 'Мундуктағы ылғалды орман, су жағасындағы ғибадатханалар және Бали солтүстігінің тыныш тау бөліктері арқылы өтетін бағыт.', -8.25700000, 115.09000000, 'Pura_Ulun_Danu_Beratan_in_bali.jpg', ARRAY['munduk']::text[], ARRAY['munduk','ubud']::text[], ARRAY['indonesia','bali','forest','walking']::text[]),
    ('penang-hill-heritage-trail', 'MY', 'penang', 'NATURE', 0, 'MYR', 4, 'HOURS', 4.7, 'Историческая тропа Penang Hill', 'Penang Hill Heritage Trail', 'Penang Hill тарихи соқпағы', 'Подъем по старым дорожкам Пенанга через влажный лес, колониальные следы и виды на Джорджтаун.', 'A climb on old Penang paths through humid forest, colonial traces and views toward George Town.', 'Пенангтың ескі жолдарымен ылғалды орман, отарлық іздер және Джорджтаун көріністері арқылы өтетін көтерілу.', 5.42400000, 100.26900000, 'Penang_Hill.jpg', ARRAY['penang']::text[], ARRAY['penang']::text[], ARRAY['malaysia','penang','heritage','hiking']::text[]),
    ('sosodikon-hill-trail', 'MY', 'kota-kinabalu', 'NATURE', 5, 'MYR', 2, 'HOURS', 4.6, 'Тропа холма Sosodikon', 'Sosodikon Hill Trail', 'Sosodikon төбесі соқпағы', 'Короткая прогулка Сабаха к открытой точке с видами на долину Кундасанг и горный силуэт.', 'A short Sabah walk to an open viewpoint over Kundasang valley and the mountain silhouette.', 'Сабахтағы Кундасанг аңғары мен тау сұлбасына ашық көрініс беретін қысқа серуен.', 6.01500000, 116.57400000, 'Mount_Kinabalu.jpg', ARRAY['kota-kinabalu']::text[], ARRAY['kota-kinabalu']::text[], ARRAY['malaysia','sabah','viewpoint','walking']::text[]),
    ('southern-ridges-walk', 'SG', 'singapore', 'NATURE', 0, 'SGD', 3, 'HOURS', 4.8, 'Прогулка Southern Ridges', 'Southern Ridges Walk', 'Southern Ridges серуені', 'Городской зеленый маршрут Сингапура через мосты, парковые гребни и виды на гавань.', 'A Singapore urban green route through bridges, park ridges and harbour views.', 'Сингапурдағы көпірлер, саябақ жоталары және айлақ көріністері арқылы өтетін қалалық жасыл бағыт.', 1.27900000, 103.81900000, 'Henderson_Waves_Singapore.jpg', ARRAY['singapore']::text[], ARRAY['singapore']::text[], ARRAY['singapore','urban-nature','walking','free-entry']::text[]),
    ('macritchie-treetop-loop', 'SG', 'singapore', 'NATURE', 0, 'SGD', 4, 'HOURS', 4.8, 'Петля TreeTop Walk в MacRitchie', 'MacRitchie TreeTop Walk Loop', 'MacRitchie TreeTop Walk ілмегі', 'Лесная петля Сингапура с подвесным мостом, тропическим лесом и более активным форматом городской природы.', 'A Singapore forest loop with a suspension bridge, tropical forest and a more active urban nature format.', 'Сингапурдағы аспалы көпірі, тропикалық орманы және белсендірек қалалық табиғат форматы бар орман ілмегі.', 1.35600000, 103.82700000, 'MacRitchie_Reservoir_Park.jpg', ARRAY['singapore']::text[], ARRAY['singapore']::text[], ARRAY['singapore','forest','loop','free-entry']::text[]),
    ('riverston-pitawala-pathana-trail', 'LK', 'kandy', 'NATURE', 0, 'LKR', 5, 'HOURS', 4.7, 'Тропа Riverston и Pitawala Pathana', 'Riverston Pitawala Pathana Trail', 'Riverston Pitawala Pathana соқпағы', 'Горный маршрут из Канди к ветреным лугам, обрывам и видам центральной Шри-Ланки.', 'A Kandy departure route toward windy grasslands, cliffs and views of central Sri Lanka.', 'Кандиден шығатын орталық Шри-Ланканың желді шалғындарына, жартастарына және көріністеріне апаратын бағыт.', 7.53500000, 80.74100000, 'Kandy_Lake.jpg', ARRAY['kandy']::text[], ARRAY['kandy']::text[], ARRAY['sri-lanka','central-highlands','grassland','hiking']::text[]),
    ('fushimi-inari-summit-trail', 'JP', 'kyoto', 'NATURE', 0, 'JPY', 3, 'HOURS', 4.8, 'Тропа на вершину Fushimi Inari', 'Fushimi Inari Summit Trail', 'Fushimi Inari шыңына соқпақ', 'Киотская прогулка через красные ворота, лесной склон и маленькие святилища к верхней части горы.', 'A Kyoto walk through red gates, forest slope and small shrines toward the upper mountain section.', 'Киотодағы қызыл қақпалар, орманды беткей және шағын қасиетті орындар арқылы таудың жоғарғы бөлігіне апаратын серуен.', 34.96700000, 135.77200000, 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg', ARRAY['kyoto']::text[], ARRAY['kyoto']::text[], ARRAY['japan','kyoto','forest','walking']::text[]),
    ('seoraksan-ulsanbawi-rock-trail', 'KR', 'sokcho', 'NATURE', 0, 'KRW', 5, 'HOURS', 4.9, 'Тропа к скале Ulsanbawi', 'Seoraksan Ulsanbawi Rock Trail', 'Seoraksan Ulsanbawi жартасына соқпақ', 'Сильный маршрут Сокчо к гранитным куполам, лестницам и одной из лучших панорам восточной Кореи.', 'A strong Sokcho route to granite domes, stair sections and one of eastern Korea strongest panoramas.', 'Сокчодан гранит күмбездерге, баспалдақты бөліктерге және шығыс Кореяның ең әсерлі панорамаларының біріне апаратын қарқынды бағыт.', 38.17000000, 128.48500000, 'Seoraksan_National_Park_panorama_3.jpg', ARRAY['sokcho']::text[], ARRAY['sokcho','seoul']::text[], ARRAY['south-korea','sokcho','granite','trekking']::text[]),
    ('yulong-river-karst-walk', 'CN', 'yangshuo', 'NATURE', 0, 'CNY', 4, 'HOURS', 4.8, 'Карстовая прогулка вдоль реки Yulong', 'Yulong River Karst Walking Trail', 'Yulong өзені карст серуені', 'Пеший маршрут Яншо между карстовыми холмами, рисовыми полями и тихими сельскими дорогами.', 'A Yangshuo walking route among karst hills, rice fields and quiet rural lanes.', 'Яншодағы карст төбелері, күріш алқаптары және тыныш ауыл жолдары арасындағы жаяу бағыт.', 24.78000000, 110.46000000, 'Li_River,_Guilin.jpg', ARRAY['yangshuo']::text[], ARRAY['yangshuo','guilin']::text[], ARRAY['china','guangxi','karst','walking']::text[]),
    ('bhrigu-lake-trek', 'IN', 'manali', 'NATURE', 0, 'INR', 8, 'HOURS', 4.8, 'Трек к озеру Bhrigu', 'Bhrigu Lake Trek', 'Bhrigu көліне трек', 'Гималайский маршрут из Манали к альпийским лугам, открытому гребню и высокогорному озеру для подготовленного дня.', 'A Himalayan route from Manali to alpine meadows, an open ridge and a high mountain lake for a prepared day.', 'Маналиден альпілік шалғындарға, ашық жотаға және биік тау көліне апаратын дайын саяхатшыларға арналған гималай бағыты.', 32.32400000, 77.21500000, 'Manali,_Himachal_Pradesh.jpg', ARRAY['manali']::text[], ARRAY['manali']::text[], ARRAY['india','himachal-pradesh','lake','trekking']::text[]);

CREATE TEMP TABLE seed_oceania_asia_hiking_resolved_places AS
SELECT
    ('95ad0000-0000-4000-8000-' || substr(md5(slug), 1, 12))::uuid AS id,
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
    ARRAY['oceania-asia-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_oceania_asia_hiking_places;

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
FROM seed_oceania_asia_hiking_resolved_places
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
FROM seed_oceania_asia_hiking_resolved_places
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
FROM seed_oceania_asia_hiking_resolved_places
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
FROM seed_oceania_asia_hiking_resolved_places
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
FROM seed_oceania_asia_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
