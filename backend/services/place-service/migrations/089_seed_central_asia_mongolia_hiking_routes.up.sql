-- Route-level hiking/day-hike enrichment for Central Asia and Mongolia hubs.
-- These rows intentionally avoid duplicating broad park/lake/city seeds and add concrete trail scenarios instead.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_central_asia_mongolia_hiking_resolved_places;
DROP TABLE IF EXISTS seed_central_asia_mongolia_hiking_places;

CREATE TEMP TABLE seed_central_asia_mongolia_hiking_places (
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

INSERT INTO seed_central_asia_mongolia_hiking_places (
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
    ('KG', 'KGS', 'kol-ukok-lake-trek', 'kochkor', 'NATURE', 0, 8, 'HOURS', 4.8, 'Трек к озеру Коль-Укок', 'Kol-Ukok Lake Trek', 'Көл-Үкөк көліне трек', 'Маршрут из Кочкора к высокогорному озеру в Тескей Ала-Тоо: пастбища, моренные склоны и сильный формат трека на один длинный день или с ночевкой.', 'A route from Kochkor to a high mountain lake in the Terskey Ala-Too, with pastures, moraine slopes and a strong long-day or overnight trekking format.', 'Кочкордан Тескей Ала-Тоодағы биік таулы көлге апаратын бағыт: жайылымдар, мореналық беткейлер және бір ұзақ күнге не түнеуге лайық трек.', 42.09000000, 75.88000000, 'Song-Kul, Kyrgyzstan (43670021735).jpg', ARRAY['kochkor']::text[], ARRAY['kochkor']::text[], ARRAY['kyrgyzstan','naryn-region','lake','trekking','free-entry']::text[]),
    ('KG', 'KGS', 'eki-naryn-valley-trail', 'naryn', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа долины Эки-Нарын', 'Eki-Naryn Valley Trail', 'Эки-Нарын аңғары соқпағы', 'Живописная долина недалеко от Нарына с рекой, хвойными участками и спокойным горным маршрутом без экстремального набора высоты.', 'A scenic valley near Naryn with a river, conifer sections and a calm mountain route without extreme elevation gain.', 'Нарын маңындағы өзені, қылқан жапырақты бөліктері және қатты биіктіксіз тыныш тау бағыты бар көркем аңғар.', 41.65000000, 76.08000000, 'At-Bashy Valley.jpg', ARRAY['naryn']::text[], ARRAY['naryn']::text[], ARRAY['kyrgyzstan','naryn','valley','river','free-entry','hiking']::text[]),
    ('KG', 'KGS', 'besh-tash-lake-trail', 'talas', 'NATURE', 200, 7, 'HOURS', 4.8, 'Тропа к озеру Беш-Таш', 'Besh-Tash Lake Trail', 'Беш-Таш көлі соқпағы', 'Маршрут из Таласа в одноименный природный парк: ущелье, горная река и подъем к бирюзовому озеру на северных склонах Таласского Ала-Тоо.', 'A route from Talas into the nature park of the same name, with a gorge, mountain river and climb toward a turquoise lake on the northern Talas Alatoo slopes.', 'Таластан аттас табиғи паркке баратын бағыт: шатқал, тау өзені және Талас Ала-Тоосының солтүстік беткейлеріндегі көгілдір көлге көтерілу.', 42.41000000, 72.52000000, 'Manas Ordo Kyrgyzstan.jpg', ARRAY['talas']::text[], ARRAY['talas']::text[], ARRAY['kyrgyzstan','talas','nature-park','lake','trekking']::text[]),
    ('KG', 'KGS', 'konorchek-canyon-trail', 'tokmok', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа каньонов Конорчек', 'Konorchek Canyon Trail', 'Көңөрчөк каньондары соқпағы', 'Сухой каньонный маршрут из Чуйской долины с красными стенами, узкими проходами и хорошим форматом day-hike из Токмока или Бишкека.', 'A dry canyon route from the Chuy Valley with red walls, narrow passages and a solid day-hike format from Tokmok or Bishkek.', 'Шу аңғарынан шығатын қызыл қабырғалары, тар өтпелері және Тоқмақ не Бішкектен day-hike форматына ыңғайлы құрғақ каньон бағыты.', 42.62000000, 75.03000000, 'Burana Tower, Kyrgyzstan.jpg', ARRAY['tokmok']::text[], ARRAY['bishkek','tokmok']::text[], ARRAY['kyrgyzstan','chuy-region','canyon','day-hike','free-entry']::text[]),
    ('KG', 'KGS', 'grigorievka-gorge-trail', 'cholpon-ata', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа Григорьевского ущелья', 'Grigorievka Gorge Trail', 'Григорьевка шатқалы соқпағы', 'Горная прогулка с северного берега Иссык-Куля к хвойным склонам, реке и прохладным пастбищам, хорошо дополняющая пляжный сценарий Чолпон-Аты.', 'A mountain walk from the north shore of Issyk-Kul toward conifer slopes, a river and cool pastures, pairing well with Cholpon-Ata beach time.', 'Ыстықкөлдің солтүстік жағалауынан қылқан жапырақты беткейлерге, өзенге және салқын жайылымдарға баратын тау серуені, Шолпан-Атадағы жағажай демалысын жақсы толықтырады.', 42.78000000, 77.47000000, 'Lake Issyk-Kul, Kyrgyzstan.jpg', ARRAY['cholpon-ata']::text[], ARRAY['cholpon-ata','balykchy']::text[], ARRAY['kyrgyzstan','issyk-kul','gorge','day-hike','free-entry']::text[]),
    ('KG', 'KGS', 'kara-shoro-nature-park-trail', 'uzgen', 'NATURE', 200, 7, 'HOURS', 4.7, 'Тропа природного парка Кара-Шоро', 'Kara-Shoro Nature Park Trail', 'Қара-Шоро табиғи паркі соқпағы', 'Южный горный маршрут из Узгена к еловым ущельям Ферганского хребта, минеральным источникам и более дикому пейзажу Ошской области.', 'A southern mountain route from Uzgen toward spruce gorges of the Fergana Range, mineral springs and a wilder Osh Region landscape.', 'Өзгеннен Ферғана жотасының шыршалы шатқалдарына, минералды бұлақтарға және Ош облысының жабайырақ пейзажына апаратын оңтүстік тау бағыты.', 40.43000000, 73.52000000, 'Walnut forest Arslanbob.jpg', ARRAY['uzgen']::text[], ARRAY['osh','uzgen']::text[], ARRAY['kyrgyzstan','osh-region','fergana-range','nature-park','trekking']::text[]),
    ('UZ', 'UZS', 'aman-kutan-gorge-trail', 'samarkand', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа ущелья Аман-Кутан', 'Aman-Kutan Gorge Trail', 'Аман-Құтан шатқалы соқпағы', 'Горный day-trip из Самарканда к прохладному ущелью Зеравшанских отрогов, где городская программа получает живой outdoor-контраст.', 'A mountain day trip from Samarkand to a cool gorge in the Zeravshan foothills, adding a real outdoor contrast to the city itinerary.', 'Самарқаннан Зарафшан тау етегіндегі салқын шатқалға баратын тау day-trip, қалалық маршрутқа нақты outdoor-контраст қосады.', 39.30000000, 66.90000000, 'Samarkand Registan square 2012.jpg', ARRAY['samarkand']::text[], ARRAY['samarkand']::text[], ARRAY['uzbekistan','samarkand','gorge','day-hike','free-entry']::text[]),
    ('UZ', 'UZS', 'sarmishsay-gorge-petroglyph-trail', 'navoi', 'NATURE', 30000, 4, 'HOURS', 4.8, 'Тропа петроглифов ущелья Сармышсай', 'Sarmishsay Gorge Petroglyph Trail', 'Сармышсай петроглифтері соқпағы', 'Маршрут из Навои по песчаниковому ущелью с древними петроглифами, кустарниками и переходом от пустыни к западному Тянь-Шаню.', 'A route from Navoi through a sandstone gorge with ancient petroglyphs, shrubs and the transition from desert to the western Tian Shan.', 'Науайыдан ежелгі петроглифтері, бұталары және шөлден Батыс Тянь-Шаньға өтетін ландшафты бар құмтас шатқал арқылы өтетін бағыт.', 40.00000000, 65.54000000, 'Nuratau Mountains Uzbekistan.jpg', ARRAY['navoi']::text[], ARRAY['navoi','nurata']::text[], ARRAY['uzbekistan','navoi-region','petroglyphs','gorge','hiking']::text[]),
    ('UZ', 'UZS', 'aydarkul-desert-shore-trail', 'nurata', 'NATURE', 0, 4, 'HOURS', 4.6, 'Береговая тропа Айдаркуля', 'Aydarkul Desert Shore Trail', 'Айдаркөл шөл жағалауы соқпағы', 'Мягкий маршрут у озера на краю Кызылкума: песок, открытая вода, птицы и спокойный природный сценарий после гор Нуратa.', 'A gentle route by the lake on the edge of the Kyzylkum, with sand, open water, birds and a calm nature plan after the Nuratau mountains.', 'Қызылқұм шетіндегі көл бойындағы жеңіл бағыт: құм, ашық су, құстар және Нұрата тауларынан кейінгі тыныш табиғи сценарий.', 40.90000000, 66.80000000, 'Nuratau Mountains Uzbekistan.jpg', ARRAY['nurata']::text[], ARRAY['navoi','nurata']::text[], ARRAY['uzbekistan','aydarkul','kyzylkum','lake','free-entry','hiking']::text[]),
    ('UZ', 'UZS', 'fergana-valley-foothill-trail', 'fergana', 'NATURE', 0, 4, 'HOURS', 4.4, 'Предгорная тропа Ферганской долины', 'Fergana Valley Foothill Trail', 'Ферғана аңғары тау етегі соқпағы', 'Легкий маршрут из Ферганы к зеленым предгорьям, арыкам и сельским дорогам, чтобы в регионе была не только ремесленная и городская карточка.', 'An easy route from Fergana toward green foothills, irrigation channels and village roads, adding an outdoor card beyond craft and city stops.', 'Ферғанадан жасыл тау етектеріне, арықтарға және ауыл жолдарына апаратын жеңіл бағыт, өңірге қолөнер мен қала аялдамаларынан тыс outdoor карточка қосады.', 40.43000000, 71.78000000, 'Chimgan_mountains_Uzbekistan.jpg', ARRAY['fergana']::text[], ARRAY['fergana']::text[], ARRAY['uzbekistan','fergana-valley','foothills','walking','free-entry']::text[]),
    ('UZ', 'UZS', 'gissar-range-foothill-trail', 'shahrisabz', 'NATURE', 0, 5, 'HOURS', 4.6, 'Предгорная тропа Гиссарского хребта', 'Gissar Range Foothill Trail', 'Гиссар жотасы тау етегі соқпағы', 'Маршрут из Шахрисабза к южным предгорьям с широкими видами, садами и ощущением перехода от исторического города к горам.', 'A route from Shahrisabz toward southern foothills with wide views, gardens and the shift from a historic city into the mountains.', 'Шахрисабздан оңтүстік тау етектеріне баратын бағыт: кең көріністер, бақтар және тарихи қаладан тауға ауысу сезімі.', 39.02000000, 66.82000000, 'Zaamin National Park.jpg', ARRAY['shahrisabz']::text[], ARRAY['samarkand','shahrisabz']::text[], ARRAY['uzbekistan','gissar-range','foothills','day-hike','free-entry']::text[]),
    ('TJ', 'TJS', 'varzob-waterfall-trail', 'dushanbe', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа к водопадам Варзоба', 'Varzob Waterfall Trail', 'Варзоб сарқырамалары соқпағы', 'Короткий горный выезд из Душанбе по Варзобскому направлению: прохладная вода, каменные склоны и понятный day-hike вместо только городского парка.', 'A short mountain escape from Dushanbe along the Varzob corridor, with cool water, rocky slopes and a clear day-hike beyond city parks.', 'Душанбеден Варзоб бағытымен қысқа тау сапары: салқын су, тасты беткейлер және тек қалалық саябақ емес, түсінікті day-hike.', 38.79000000, 68.83000000, 'Varzob Gorge Tajikistan.jpg', ARRAY['dushanbe','varzob']::text[], ARRAY['dushanbe','varzob']::text[], ARRAY['tajikistan','varzob','waterfall','day-hike','free-entry']::text[]),
    ('TJ', 'TJS', 'pshart-valley-trail', 'murghab', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа долины Пшарт', 'Pshart Valley Trail', 'Пшарт аңғары соқпағы', 'Высокогорный памирский маршрут из Мургаба с открытой долиной, суровыми хребтами и ощущением настоящего удаленного trekking-дня.', 'A high Pamir route from Murghab with an open valley, stark ridges and the feel of a true remote trekking day.', 'Мурғабтан шығатын биік Памир бағыты: ашық аңғар, қатал жоталар және нағыз шалғай trekking күні.', 38.02000000, 73.92000000, 'Pamir Highway Tajikistan.jpg', ARRAY['murghab']::text[], ARRAY['murghab']::text[], ARRAY['tajikistan','pamir','gbao-permit','remote','trekking']::text[]),
    ('TJ', 'TJS', 'jizeu-valley-trail', 'khorog', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа долины Джизеу', 'Jizeu Valley Trail', 'Жизеу аңғары соқпағы', 'Пешеходный маршрут из района Хорога к памирской деревне и озерам, где тропа дает более живой сценарий, чем просто переезд по тракту.', 'A walking route from the Khorog area toward a Pamir village and lakes, adding a richer trail plan than simply driving the highway.', 'Хорог маңынан Памир ауылы мен көлдеріне баратын жаяу бағыт, трактпен жай жүруден гөрі мазмұнды trail-сценарий береді.', 37.65000000, 71.73000000, 'Wakhan Valley Tajikistan.jpg', ARRAY['khorog']::text[], ARRAY['khorog']::text[], ARRAY['tajikistan','pamir','village-trail','gbao-permit','trekking']::text[]),
    ('TJ', 'TJS', 'baljuvon-valley-trail', 'baljuvon', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа долин Бальджувона', 'Baljuvon Valley Trail', 'Балжувон аңғарлары соқпағы', 'Зеленый маршрут южного Таджикистана с холмами, водой и сельскими видами, который дополняет соседние водопадные и культурные точки.', 'A green southern Tajikistan route with hills, water and rural views, complementing nearby waterfall and cultural stops.', 'Оңтүстік Тәжікстандағы төбелері, суы және ауыл көріністері бар жасыл бағыт, жақын маңдағы сарқырама және мәдени нүктелерді толықтырады.', 38.31000000, 69.68000000, 'Childukhtaron Tajikistan.jpg', ARRAY['baljuvon']::text[], ARRAY['kulob','baljuvon']::text[], ARRAY['tajikistan','khatlon','valley','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'bogd-khan-tsetsee-gun-trail', 'ulaanbaatar', 'NATURE', 10000, 7, 'HOURS', 4.8, 'Тропа Богд-хан к Цэцээ-Гун', 'Bogd Khan Tsetsee Gun Trail', 'Богд хан Цэцээ гүн соқпағы', 'Классический горный маршрут над Улан-Батором через лес Богдхан-Уула к обзорной вершине, дающий столице полноценный hiking-сценарий.', 'A classic mountain route above Ulaanbaatar through Bogd Khan Uul forest toward a viewpoint summit, giving the capital a full hiking scenario.', 'Ұлан-Батор үстіндегі Богдхан-Уул орманы арқылы көріністі шыңға апаратын классикалық тау бағыты, астанаға толық hiking-сценарий береді.', 47.80000000, 106.98000000, 'Ulaanbaatar Bogd Khan Mountain.jpg', ARRAY['ulaanbaatar']::text[], ARRAY['ulaanbaatar']::text[], ARRAY['mongolia','bogd-khan','summit','trekking']::text[]),
    ('MN', 'MNT', 'mongol-olle-terelj-route', 'gorkhi-terelj', 'NATURE', 10000, 5, 'HOURS', 4.7, 'Маршрут Mongol Olle в Тэрэлже', 'Mongol Olle Terelj Route', 'Тэрэлждегі Mongol Olle бағыты', 'Размеченный пеший маршрут в национальном парке Горхи-Тэрэлж с долинами, скалами и мягкой сложностью для дневной прогулки.', 'A marked walking route in the Gorkhi-Terelj area with valleys, rocks and friendly difficulty for a day walk.', 'Горхи-Тэрэлж аумағындағы белгіленген жаяу бағыт: аңғарлар, жартастар және күндік серуенге ыңғайлы жеңіл күрделілік.', 47.92000000, 107.43000000, 'Gorkhi-Terelj National Park Mongolia.jpg', ARRAY['gorkhi-terelj']::text[], ARRAY['ulaanbaatar','gorkhi-terelj']::text[], ARRAY['mongolia','terelj','marked-trail','day-hike','hiking']::text[]),
    ('MN', 'MNT', 'khorgo-volcano-crater-trail', 'khorgo-terkhiin-tsagaan-nuur', 'NATURE', 10000, 3, 'HOURS', 4.8, 'Тропа кратера вулкана Хорго', 'Khorgo Volcano Crater Trail', 'Хорго жанартауы кратері соқпағы', 'Короткий, но выразительный подъем к кратеру потухшего вулкана у озера Тэрхийн-Цагаан, с лавовыми полями и широкими видами.', 'A short but memorable climb to an extinct volcano crater near Terkhiin Tsagaan Lake, with lava fields and wide views.', 'Тэрхийн-Цагаан көлі маңындағы сөнген жанартау кратеріне қысқа, бірақ әсерлі көтерілу: лава алқаптары және кең көріністер.', 48.18000000, 99.86000000, 'Terkhiin Tsagaan Lake Mongolia.jpg', ARRAY['khorgo-terkhiin-tsagaan-nuur']::text[], ARRAY['tsetserleg','khorgo-terkhiin-tsagaan-nuur']::text[], ARRAY['mongolia','khorgo','volcano','crater','hiking']::text[]),
    ('MN', 'MNT', 'khuvsgul-east-shore-trail', 'khatgal', 'NATURE', 0, 5, 'HOURS', 4.7, 'Восточная береговая тропа Хубсугула', 'Khuvsgul East Shore Trail', 'Хөвсгөл шығыс жағалауы соқпағы', 'Пеший маршрут от Хатгала вдоль прозрачной воды Хубсугула, лесистых склонов и бухт, хороший как спокойная альтернатива автопереезду.', 'A walking route from Khatgal along clear Khuvsgul water, forested slopes and bays, working as a calm alternative to driving.', 'Хатгалдан Хөвсгөлдің мөлдір суы, орманды беткейлері және қойнаулары бойымен өтетін жаяу бағыт, көлікпен жүруге тыныш балама.', 50.46000000, 100.18000000, 'Lake Khuvsgul Mongolia.jpg', ARRAY['khatgal','khuvsgul']::text[], ARRAY['murun','khatgal']::text[], ARRAY['mongolia','khuvsgul','lake-shore','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'potanin-glacier-base-trail', 'ulgii', 'NATURE', 10000, 8, 'HOURS', 4.9, 'Тропа к базе ледника Потанина', 'Potanin Glacier Base Trail', 'Потанин мұздығы базасына соқпақ', 'Высокогорный маршрут из Улгия к Монгольскому Алтаю: морены, ледниковые виды и серьезный remote trekking-сценарий для подготовленных путешественников.', 'A high mountain route from Ulgii toward the Mongolian Altai, with moraines, glacier views and a serious remote trekking plan for prepared travelers.', 'Өлгийден Моңғол Алтайына апаратын биік тау бағыты: мореналар, мұздық көріністері және дайын саяхатшыларға арналған күрделі remote trekking.', 49.05000000, 87.86000000, 'Altai Tavan Bogd National Park.jpg', ARRAY['ulgii','altai-tavan-bogd']::text[], ARRAY['ulgii','altai-tavan-bogd']::text[], ARRAY['mongolia','altai','glacier','remote','trekking']::text[]),
    ('MN', 'MNT', 'onon-balj-valley-trail', 'binder', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа долины Онон-Балж', 'Onon-Balj Valley Trail', 'Онон-Балж аңғары соқпағы', 'Северо-восточный природный маршрут от Биндэра через речные долины и лесостепь, который дает отдельный outdoor-сценарий вне классического Гоби и Алтая.', 'A north-eastern nature route from Binder through river valleys and forest-steppe, adding an outdoor plan beyond the classic Gobi and Altai circuits.', 'Биндэрден өзен аңғарлары мен орманды дала арқылы өтетін солтүстік-шығыс табиғи бағыт, классикалық Гоби мен Алтайдан бөлек outdoor-сценарий қосады.', 49.06000000, 109.62000000, 'Baldan Bereeven Monastery.jpg', ARRAY['binder']::text[], ARRAY['ulaanbaatar','binder']::text[], ARRAY['mongolia','khentii','river-valley','forest-steppe','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_central_asia_mongolia_hiking_resolved_places AS
SELECT
    ('89ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['central-asia-mongolia-hiking-v1', lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_central_asia_mongolia_hiking_places;

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
FROM seed_central_asia_mongolia_hiking_resolved_places
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
FROM seed_central_asia_mongolia_hiking_resolved_places
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
FROM seed_central_asia_mongolia_hiking_resolved_places
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
FROM seed_central_asia_mongolia_hiking_resolved_places
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
FROM seed_central_asia_mongolia_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;
