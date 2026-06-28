-- Hiking/outdoor coverage for reference-service city hubs that previously had no place seed at all.
-- This is intentionally route-level content so the new rows are not duplicates of broad city or heritage seeds.

DROP TABLE IF EXISTS seed_reference_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_reference_gap_hiking_places;

CREATE TEMP TABLE seed_reference_gap_hiking_places (
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

INSERT INTO seed_reference_gap_hiking_places (
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
    ('KZ', 'KZT', 'imantau-shalkar-lakes-trail', 'petropavlovsk', 'NATURE', 1000, 7, 'HOURS', 4.7, 'Тропа озер Имантау-Шалкар', 'Imantau-Shalkar Lakes Trail', 'Имантау-Шалқар көлдері соқпағы', 'Лесоозерный маршрут Северного Казахстана для выезда из Петропавловска: сосны, гранитные сопки, пляжи и обзорные точки над водой.', 'A northern Kazakhstan lake-and-forest route from Petropavlovsk with pines, granite hills, beaches and viewpoints over the water.', 'Петропавлдан шығатын Солтүстік Қазақстанның көлді-орманды бағыты: қарағайлар, гранитті шоқылар, жағажайлар және суға қарайтын көрініс нүктелері.', 53.07000000, 68.35000000, 'Borovoe1.jpg', ARRAY['petropavlovsk']::text[], ARRAY['petropavlovsk']::text[], ARRAY['kazakhstan','north-kazakhstan','lakes','forest','hiking']::text[]),
    ('RU', 'RUB', 'duderhof-heights', 'spb', 'NATURE', 0, 4, 'HOURS', 4.6, 'Дудергофские высоты', 'Duderhof Heights', 'Дудергоф биіктері', 'Холмистый природный маршрут рядом с Санкт-Петербургом с лесом, озерами и короткими подъемами, который хорошо работает как легкий day-hike.', 'A hilly nature route near Saint Petersburg with forest, lakes and short climbs, working well as an easy day hike.', 'Санкт-Петербург маңындағы орманы, көлдері және қысқа көтерілулері бар қыратты табиғи бағыт, жеңіл күндік жорыққа қолайлы.', 59.69400000, 30.12800000, 'Agura_Waterfalls_Sochi.jpg', ARRAY['spb']::text[], ARRAY['spb']::text[], ARRAY['russia','saint-petersburg','forest','day-hike','free-entry']::text[]),
    ('RU', 'RUB', 'berd-rocks-trail', 'novosibirsk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа Бердских скал', 'Berd Rocks Trail', 'Берд жартастары соқпағы', 'Сибирский маршрут из Новосибирска к скальным выходам над Бердью, сосновым участкам и видовым точкам на долину.', 'A Siberian route from Novosibirsk to rock outcrops above the Berd River, pine sections and valley viewpoints.', 'Новосибирскіден Берд өзені үстіндегі жартастарға, қарағайлы бөліктерге және аңғар көріністеріне апаратын сібірлік бағыт.', 54.63000000, 83.82000000, 'Agura_Waterfalls_Sochi.jpg', ARRAY['novosibirsk']::text[], ARRAY['novosibirsk']::text[], ARRAY['russia','siberia','rocks','forest','free-entry']::text[]),
    ('RU', 'RUB', 'bird-harbor-nature-trail', 'omsk', 'PARK', 0, 2, 'HOURS', 4.4, 'Природная тропа Птичьей гавани', 'Bird Harbor Nature Trail', 'Құс айлағы табиғи соқпағы', 'Короткий городской eco-walk в Омске среди водоемов, тростников и птиц, подходящий для мягкого outdoor-сценария без долгого трансфера.', 'A short urban eco-walk in Omsk among ponds, reeds and birds, suited for a gentle outdoor plan without a long transfer.', 'Омбыдағы тоғандар, қамыстар және құстар арасындағы қысқа қалалық экосеруен, ұзақ жолсыз жеңіл outdoor-сценарийге лайық.', 54.97900000, 73.30900000, 'Agura_Waterfalls_Sochi.jpg', ARRAY['omsk']::text[], ARRAY['omsk']::text[], ARRAY['russia','omsk','wetland','city-walk','free-entry']::text[]),
    ('TJ', 'TJS', 'namadgut-fortress-viewpoint-trail', 'namadgut', 'NATURE', 0, 3, 'HOURS', 4.6, 'Смотровая тропа крепости Намадгут', 'Namadgut Fortress Viewpoint Trail', 'Намадгут қамалы көрініс соқпағы', 'Короткая ваханская прогулка к старым укреплениям и обзорным точкам над долиной, которая дает Намадгуту отдельный outdoor-сценарий.', 'A short Wakhan walk to old fortifications and viewpoints above the valley, giving Namadgut its own outdoor plan.', 'Намадгутқа жеке outdoor-сценарий беретін Вахан аңғарындағы ескі бекіністер мен көрініс нүктелеріне қысқа серуен.', 36.98400000, 72.40700000, 'Wakhan Valley Tajikistan.jpg', ARRAY['namadgut','wakhan-valley']::text[], ARRAY['ishkashim','wakhan-valley','namadgut']::text[], ARRAY['tajikistan','wakhan','viewpoint','gbao-permit','free-entry']::text[]),
    ('TJ', 'TJS', 'khargush-pass-lakes-trail', 'khargush', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа озер перевала Харгуш', 'Khargush Pass Lakes Trail', 'Харгуш асуы көлдері соқпағы', 'Высокогорная остановка Памира с суровыми озерами, открытым плато и короткими прогулками на высоте для подготовленных путешественников.', 'A high Pamir stop with stark lakes, open plateau and short high-altitude walks for prepared travelers.', 'Памирдегі биік аялдама: қатал көлдер, ашық үстірт және дайын саяхатшыларға арналған биіктегі қысқа серуендер.', 37.52600000, 73.33200000, 'Pamir Highway Tajikistan.jpg', ARRAY['khargush']::text[], ARRAY['khorog','murghab','khargush']::text[], ARRAY['tajikistan','pamir','high-altitude','lake','gbao-permit']::text[]),
    ('TJ', 'TJS', 'zorkul-lake-shore-trail', 'zorkul', 'NATURE', 0, 5, 'HOURS', 4.8, 'Береговая тропа озера Зоркуль', 'Zorkul Lake Shore Trail', 'Зоркөл жағалауы соқпағы', 'Удаленный памирский маршрут по берегу Зоркуля с широкими видами, тишиной и ощущением высокогорной границы.', 'A remote Pamir route along Zorkul Lake with wide views, silence and a high-borderland atmosphere.', 'Зоркөл жағалауымен өтетін шалғай Памир бағыты: кең көріністер, тыныштық және биік шекаралық өлкенің әсері.', 37.45600000, 73.65000000, 'Pamir Highway Tajikistan.jpg', ARRAY['zorkul']::text[], ARRAY['murghab','zorkul']::text[], ARRAY['tajikistan','pamir','lake','remote','gbao-permit']::text[]),
    ('TJ', 'TJS', 'ak-baital-pass-viewpoint', 'ak-baital', 'NATURE', 0, 2, 'HOURS', 4.6, 'Смотровая перевала Ак-Байтал', 'Ak-Baital Pass Viewpoint', 'Ақ-Байтал асуының көрініс нүктесі', 'Короткая высотная прогулка у одного из самых известных перевалов Памирского тракта с открытыми видами на каменные хребты.', 'A short high-altitude walk near one of the Pamir Highway best-known passes, with open views of rocky ridges.', 'Памир тас жолының ең белгілі асуларының бірі жанындағы қысқа биік серуен, тасты жоталарға ашық көріністермен.', 38.59000000, 73.58800000, 'Pamir Highway Tajikistan.jpg', ARRAY['ak-baital']::text[], ARRAY['murghab','ak-baital']::text[], ARRAY['tajikistan','pamir-highway','pass','viewpoint','free-entry']::text[]),
    ('TJ', 'TJS', 'rangkul-lakes-viewpoint-trail', 'rangkul', 'NATURE', 0, 4, 'HOURS', 4.6, 'Смотровая тропа озер Рангкуль', 'Rangkul Lakes Viewpoint Trail', 'Рангкөл көлдері көрініс соқпағы', 'Памирская тропа к обзорным точкам над озерной котловиной Рангкуля, степными берегами и суровым высокогорным пейзажем.', 'A Pamir trail to viewpoints above the Rangkul lake basin, steppe shores and stark high-mountain scenery.', 'Рангкөл көл қазаншұңқыры, дала жағалаулары және қатал биік таулы ландшафт үстіндегі көрініс нүктелеріне апаратын Памир соқпағы.', 38.48800000, 74.09000000, 'Pamir Highway Tajikistan.jpg', ARRAY['rangkul']::text[], ARRAY['murghab','rangkul']::text[], ARRAY['tajikistan','pamir','lake','viewpoint','gbao-permit']::text[]),
    ('TJ', 'TJS', 'danghara-foothill-trail', 'danghara', 'NATURE', 0, 3, 'HOURS', 4.4, 'Предгорная тропа Дангары', 'Danghara Foothill Trail', 'Данғара тау етегі соқпағы', 'Легкий маршрут по сухим предгорьям и сельским дорогам вокруг Дангары для короткой активной остановки на юге Таджикистана.', 'An easy route through dry foothills and rural roads around Danghara for a short active stop in southern Tajikistan.', 'Тәжікстанның оңтүстігіндегі қысқа белсенді аялдамаға арналған Данғара маңындағы құрғақ тау етектері мен ауылдық жолдар бағыты.', 38.09500000, 69.34000000, 'Dushanbe Tajikistan.jpg', ARRAY['danghara']::text[], ARRAY['danghara']::text[], ARRAY['tajikistan','foothills','south-tajikistan','free-entry']::text[]),
    ('TJ', 'TJS', 'khovaling-ridge-trail', 'khovaling', 'NATURE', 0, 4, 'HOURS', 4.5, 'Тропа хребтов Ховалинга', 'Khovaling Ridge Trail', 'Ховалинг жоталары соқпағы', 'Горная прогулка по зеленым хребтам Ховалинга с сельскими видами, прохладным воздухом и мягким набором высоты.', 'A mountain walk across Khovaling green ridges with rural views, cooler air and gentle elevation gain.', 'Ховалингтің жасыл жоталарымен өтетін тау серуені: ауылдық көріністер, салқын ауа және бірқалыпты биіктікке көтерілу.', 38.35000000, 69.97000000, 'Childukhtaron Tajikistan.jpg', ARRAY['khovaling']::text[], ARRAY['kulob','khovaling']::text[], ARRAY['tajikistan','khatlon','ridge','hiking','free-entry']::text[]),
    ('TJ', 'TJS', 'panj-river-floodplain-trail', 'farkhor', 'NATURE', 0, 3, 'HOURS', 4.4, 'Пойменная тропа реки Пяндж', 'Panj River Floodplain Trail', 'Пяндж өзені жайылмасы соқпағы', 'Спокойный природный маршрут у Фархора вдоль пойменных участков Пянджа, полей и открытых южных ландшафтов.', 'A calm nature route near Farkhor along Panj floodplain sections, fields and open southern landscapes.', 'Фархор маңындағы Пяндж жайылмасы, егістіктер және оңтүстіктің ашық ландшафттары бойымен өтетін тыныш табиғи бағыт.', 37.49000000, 69.40000000, 'Tigrovaya Balka Tajikistan.jpg', ARRAY['farkhor']::text[], ARRAY['farkhor','kulob']::text[], ARRAY['tajikistan','panj-river','floodplain','south-tajikistan','free-entry']::text[]),
    ('TM', 'TMT', 'kopet-dag-foothills-trail', 'ashgabat', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа предгорий Копетдага', 'Kopet Dag Foothills Trail', 'Копетдаг тау етегі соқпағы', 'Маршрут у южной кромки Ашхабада по сухим предгорьям Копетдага с видами на город и пустынный рельеф.', 'A route along Ashgabat southern edge through the dry Kopet Dag foothills with views of the city and desert terrain.', 'Ашхабадтың оңтүстік шетіндегі құрғақ Копетдаг тау етектерімен өтетін, қала мен шөл бедеріне көрініс беретін бағыт.', 37.90000000, 58.33000000, 'Kopet_Dag_Turkmenistan.jpg', ARRAY['ashgabat']::text[], ARRAY['ashgabat']::text[], ARRAY['turkmenistan','kopet-dag','foothills','desert','free-entry']::text[]),
    ('AM', 'AMD', 'ijevan-dendropark-forest-trail', 'ijevan', 'PARK', 0, 3, 'HOURS', 4.6, 'Лесная тропа Иджеванского дендропарка', 'Ijevan Dendropark Forest Trail', 'Иджеван дендропаркі орман соқпағы', 'Спокойный лесной маршрут в Иджеване среди дендрологических посадок, ущелья и мягких североармянских склонов.', 'A calm forest route in Ijevan among dendropark plantings, gorge scenery and gentle northern Armenian slopes.', 'Иджевандағы дендропарк ағаштары, шатқал көріністері және Солтүстік Арменияның жұмсақ беткейлері арасындағы тыныш орман бағыты.', 40.87500000, 45.14900000, 'Yerevan,_Armenia.jpg', ARRAY['ijevan']::text[], ARRAY['ijevan','dilijan']::text[], ARRAY['armenia','tavush','forest','day-hike','free-entry']::text[]),
    ('MD', 'MDL', 'codru-forest-reserve-trail', 'chisinau', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа заповедника Кодры', 'Codru Forest Reserve Trail', 'Кодры қорығы соқпағы', 'Лесной day-trip из Кишинева к холмам и буковым участкам Кодр, где Молдова выглядит наиболее зеленой и тихой.', 'A forest day trip from Chisinau to the Codru hills and beech sections, where Moldova feels especially green and quiet.', 'Кишиневтен Кодры қыраттары мен бук ормандарына баратын орманды day-trip, Молдованың ең жасыл және тыныш қырын көрсетеді.', 47.10000000, 28.30000000, 'Codru_Reserve_Moldova.jpg', ARRAY['chisinau']::text[], ARRAY['chisinau']::text[], ARRAY['moldova','codru','forest','day-hike','free-entry']::text[]),
    ('VN', 'VND', 'vung-tau-big-mountain-trail', 'vung-tau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа Большой горы Вунгтау', 'Vung Tau Big Mountain Trail', 'Вунгтау Үлкен тау соқпағы', 'Короткий прибрежный подъем во Вунгтау с видом на море, город, маяки и зеленые склоны полуострова.', 'A short coastal climb in Vung Tau with views of the sea, city, lighthouses and green peninsula slopes.', 'Вунгтаудағы теңізге, қалаға, маяктарға және түбектің жасыл беткейлеріне көрінісі бар қысқа жағалаулық көтерілу.', 10.36200000, 107.07300000, 'Ha_Long_Bay_Vietnam.jpg', ARRAY['vung-tau']::text[], ARRAY['vung-tau']::text[], ARRAY['vietnam','coastal-hike','viewpoint','free-entry']::text[]),
    ('VN', 'VND', 'ngu-lam-peak-trail', 'cat-ba', 'NATURE', 80000, 4, 'HOURS', 4.8, 'Тропа к пику Нгу-Лам', 'Ngu Lam Peak Trail', 'Нгу-Лам шыңы соқпағы', 'Классический лесной маршрут национального парка Катба к карстовой смотровой над джунглями и островными хребтами.', 'A classic Cat Ba National Park forest route to a karst viewpoint above jungle and island ridges.', 'Катба ұлттық паркінің джунгли мен арал жоталары үстіндегі карст көрініс нүктесіне апаратын классикалық орман бағыты.', 20.80200000, 106.99900000, 'Ha_Long_Bay_Vietnam.jpg', ARRAY['cat-ba']::text[], ARRAY['cat-ba']::text[], ARRAY['vietnam','cat-ba','national-park','peak','trekking']::text[]),
    ('VN', 'VND', 'ma-pi-leng-pass-trail', 'ha-giang', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа перевала Ма Пи Ленг', 'Ma Pi Leng Pass Trail', 'Ма Пи Ленг асуы соқпағы', 'Панорамный маршрут Хазянга над каньоном Нхо Куе, известняковыми стенами и серпантинами северного Вьетнама.', 'A Ha Giang panoramic route above the Nho Que canyon, limestone walls and northern Vietnam switchbacks.', 'Хазянгтағы Нхо Куе каньоны, әктас қабырғалар және Солтүстік Вьетнам серпантиндері үстіндегі панорамалық бағыт.', 23.25000000, 105.39000000, 'Sa_Pa_terraced_fields_Vietnam.jpg', ARRAY['ha-giang']::text[], ARRAY['ha-giang']::text[], ARRAY['vietnam','ha-giang','pass','canyon','free-entry']::text[]),
    ('VN', 'VND', 'phong-nha-botanical-garden-trail', 'phong-nha', 'NATURE', 40000, 3, 'HOURS', 4.6, 'Тропа ботанического сада Фонгня', 'Phong Nha Botanical Garden Trail', 'Фонгня ботаникалық бағы соқпағы', 'Лесной маршрут Фонгня-Кебанг с водопадом, влажным тропическим лесом и мягким форматом nature walk между пещерными поездками.', 'A Phong Nha-Ke Bang forest route with a waterfall, humid tropical forest and a gentle nature-walk format between cave trips.', 'Фонгня-Кебангтағы сарқырама, ылғалды тропикалық орман және үңгір сапарлары арасындағы жеңіл nature walk форматы бар орман бағыты.', 17.54800000, 106.30500000, 'Phong_Nha_Cave_Vietnam.jpg', ARRAY['phong-nha']::text[], ARRAY['phong-nha']::text[], ARRAY['vietnam','phong-nha','forest','waterfall','hiking']::text[]),
    ('CN', 'CNY', 'heavenly-lake-tianshan-trail', 'urumqi', 'NATURE', 95, 5, 'HOURS', 4.8, 'Тропа озера Тяньчи в Тянь-Шане', 'Heavenly Lake Tianshan Trail', 'Тянь-Шань Тяньчи көлі соқпағы', 'Горный day-trip из Урумчи к озеру Тяньчи с хвойными склонами, альпийским воздухом и видами Восточного Тянь-Шаня.', 'A mountain day trip from Urumqi to Heavenly Lake, with spruce slopes, alpine air and Eastern Tian Shan views.', 'Үрімшіден Тяньчи көліне баратын тау day-trip: шыршалы беткейлер, альпілік ауа және Шығыс Тянь-Шань көріністері.', 43.88000000, 88.12000000, 'Tianchi_Xinjiang.jpg', ARRAY['urumqi']::text[], ARRAY['urumqi']::text[], ARRAY['china','xinjiang','tianshan','lake','hiking']::text[]),
    ('IN', 'INR', 'aravalli-biodiversity-park-trail', 'new-delhi', 'PARK', 0, 2, 'HOURS', 4.5, 'Тропа парка биоразнообразия Аравалли', 'Aravalli Biodiversity Park Trail', 'Аравалли биоалуантүрлілік паркі соқпағы', 'Зеленый urban nature маршрут в Дели среди восстановленных ландшафтов Аравалли, птиц и сухого леса.', 'A green urban-nature route in Delhi through restored Aravalli landscapes, birds and dry forest.', 'Делидегі қалпына келтірілген Аравалли ландшафттары, құстар және құрғақ орман арасындағы жасыл urban nature бағыты.', 28.53200000, 77.15100000, 'Aravalli_Biodiversity_Park.jpg', ARRAY['new-delhi']::text[], ARRAY['new-delhi']::text[], ARRAY['india','delhi','aravalli','urban-nature','free-entry']::text[]),
    ('IT', 'EUR', 'circeo-national-park-trail', 'lazio-coast', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа национального парка Чирчео', 'Circeo National Park Trail', 'Чирчео ұлттық паркі соқпағы', 'Прибрежный маршрут Лацио с лесом, дюнами, известняковыми склонами и видом на Тирренское море.', 'A Lazio coastal route with forest, dunes, limestone slopes and views of the Tyrrhenian Sea.', 'Лацио жағалауындағы орман, дюналар, әктас беткейлер және Тиррен теңізіне көрінісі бар бағыт.', 41.23500000, 13.08700000, 'Circeo_National_Park.jpg', ARRAY['lazio-coast']::text[], ARRAY['rome','lazio-coast']::text[], ARRAY['italy','lazio','coastal-hike','national-park','free-entry']::text[]),
    ('ES', 'EUR', 'clot-de-galvany-trail', 'elche', 'NATURE', 0, 2, 'HOURS', 4.5, 'Тропа Клот-де-Гальвани', 'Clot de Galvany Trail', 'Клот-де-Гальвани соқпағы', 'Легкий маршрут по водно-болотным участкам и дюнам рядом с Эльче, хороший для птиц, моря и спокойной прогулки.', 'An easy route through wetlands and dunes near Elche, good for birds, sea air and a calm walk.', 'Эльче маңындағы сулы-батпақты аумақтар мен дюналар арқылы өтетін жеңіл бағыт, құстарға, теңіз ауасына және тыныш серуенге қолайлы.', 38.24700000, -0.52000000, 'Costa_Blanca_Spain.jpg', ARRAY['elche']::text[], ARRAY['alicante','elche']::text[], ARRAY['spain','costa-blanca','wetland','dunes','free-entry']::text[]),
    ('ES', 'EUR', 'penon-de-ifach-trail', 'calpe', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Пеньон-де-Ифач', 'Penon de Ifach Trail', 'Пеньон-де-Ифач соқпағы', 'Короткий, но выразительный подъем на известняковую скалу Кальпе с морскими панорамами и видом на побережье Коста-Бланки.', 'A short but striking climb on Calpe limestone rock with sea panoramas and views along the Costa Blanca.', 'Кальпенің әктас жартасына қысқа, бірақ әсерлі көтерілу: теңіз панорамалары және Коста-Бланка жағалауына көріністер.', 38.63600000, 0.07200000, 'Costa_Blanca_Spain.jpg', ARRAY['calpe']::text[], ARRAY['calpe','alicante']::text[], ARRAY['spain','costa-blanca','rock','coastal-hike','free-entry']::text[]),
    ('ID', 'IDR', 'angke-kapuk-mangrove-trail', 'jakarta', 'PARK', 30000, 2, 'HOURS', 4.4, 'Мангровая тропа Ангке-Капук', 'Angke Kapuk Mangrove Trail', 'Ангке-Капук мангр соқпағы', 'Короткий природный маршрут в Джакарте по деревянным настилам среди мангров, воды и городских птиц.', 'A short nature route in Jakarta along boardwalks through mangroves, water and urban birdlife.', 'Джакартадағы мангрлар, су және қалалық құстар арасындағы ағаш жолдармен өтетін қысқа табиғи бағыт.', -6.10500000, 106.73500000, 'Mangrove_Angke_Kapuk_Jakarta.jpg', ARRAY['jakarta']::text[], ARRAY['jakarta']::text[], ARRAY['indonesia','jakarta','mangrove','urban-nature','hiking']::text[]);

CREATE TEMP TABLE seed_reference_gap_hiking_resolved_places AS
SELECT
    ('87ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['reference-gap-hiking-v1', lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_reference_gap_hiking_places;

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
FROM seed_reference_gap_hiking_resolved_places
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
FROM seed_reference_gap_hiking_resolved_places
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
FROM seed_reference_gap_hiking_resolved_places
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
FROM seed_reference_gap_hiking_resolved_places
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
FROM seed_reference_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
