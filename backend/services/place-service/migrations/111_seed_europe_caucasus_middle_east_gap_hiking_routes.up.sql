-- Europe, Caucasus and Middle East gap hiking seed.
-- Adds route-level hiking choices for reference hubs that still had thin outdoor coverage.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_europe_caucasus_middle_east_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_europe_caucasus_middle_east_gap_hiking_places;

CREATE TEMP TABLE seed_europe_caucasus_middle_east_gap_hiking_places (
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

INSERT INTO seed_europe_caucasus_middle_east_gap_hiking_places (
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
    ('GE', 'GEL', 'truso-valley-trail', 'gudauri', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа долины Трусо', 'Truso Valley Trail', 'Трусо аңғары соқпағы', 'Высокогорный маршрут Казбеги к минеральным источникам, башням и широким ледниковым видам для насыщенного дня из Гудаури.', 'A Kazbegi highland route to mineral springs, towers and broad glacier views for a rich day from Gudauri.', 'Гудауриден шығатын Қазбегі биік таулы бағыты: минералды бұлақтар, мұнаралар және мұздықтарға кең көріністер.', 42.60400000, 44.46600000, 'Gergeti_Trinity_Church,_Georgia.jpg', ARRAY['gudauri','stepantsminda']::text[], ARRAY['gudauri','tbilisi']::text[], ARRAY['georgia','kazbegi','valley','free-entry','trekking']::text[]),
    ('GE', 'GEL', 'mestia-zhabeshi-trail', 'mestia', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа из Местии в Жабеши', 'Mestia to Zhabeshi Trail', 'Местиядан Жабешиге соқпақ', 'Сванетский дневной переход между селами, луговыми склонами и башенными панорамами, хорошо дополняющий базу в Местии.', 'A Svaneti day stage between villages, meadow slopes and tower panoramas, adding a strong walking option from Mestia.', 'Местиядан басталатын Сванетиядағы ауылдар, шалғын беткейлері және мұнаралы панорамалар арасындағы күндік бағыт.', 43.03400000, 42.80300000, 'Kutaisi,_Georgia.jpg', ARRAY['mestia']::text[], ARRAY['mestia','kutaisi']::text[], ARRAY['georgia','svaneti','village-to-village','free-entry','trekking']::text[]),
    ('AM', 'AMD', 'jukhtak-monastery-forest-trail', 'dilijan', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная тропа монастыря Джухтак', 'Jukhtak Monastery Forest Trail', 'Жухтак монастыры орман соқпағы', 'Короткий дилижанский маршрут через тенистый лес, ручьи и старые каменные стены для спокойного природного выезда.', 'A short Dilijan route through shaded forest, streams and old stone walls for a calm nature outing.', 'Дилижандағы көлеңкелі орман, бұлақтар және көне тас қабырғалар арқылы өтетін қысқа табиғи бағыт.', 40.76100000, 44.91300000, 'Yerevan,_Armenia.jpg', ARRAY['dilijan']::text[], ARRAY['dilijan','yerevan']::text[], ARRAY['armenia','dilijan','forest','free-entry','walking']::text[]),
    ('AM', 'AMD', 'jermuk-gndevank-canyon-trail', 'jermuk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Каньонная тропа из Джермука к Гндеванку', 'Jermuk to Gndevank Canyon Trail', 'Джермуктан Гндеванкке каньон соқпағы', 'Маршрут Вайоц Дзора от курортной зоны к каньону, речной долине и старому каменному храмовому месту.', 'A Vayots Dzor route from the resort area toward a canyon, river valley and an old stone church setting.', 'Вайоц Дзордағы курорт аймағынан каньонға, өзен аңғарына және көне тас шіркеу орнына апаратын бағыт.', 39.80700000, 45.67100000, 'Tatev_Monastery,_Armenia.jpg', ARRAY['jermuk']::text[], ARRAY['jermuk','yerevan']::text[], ARRAY['armenia','vayots-dzor','canyon','free-entry','hiking']::text[]),
    ('AZ', 'AZN', 'afurja-waterfall-trail', 'quba', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа к водопаду Афурджа', 'Afurja Waterfall Trail', 'Афурджа сарқырамасы соқпағы', 'Североазербайджанский маршрут из Кубы к лесной долине, прохладной воде и короткому природному сценарию в предгорьях.', 'A northern Azerbaijan route from Quba toward a forest valley, cool water and a short foothill nature plan.', 'Кубадан орманды аңғарға, салқын суға және тау етегіндегі қысқа табиғи сценарийге апаратын Солтүстік Әзербайжан бағыты.', 41.20200000, 48.29800000, 'Quba Azerbaijan.jpg', ARRAY['quba']::text[], ARRAY['quba','baku']::text[], ARRAY['azerbaijan','quba','waterfall','free-entry','walking']::text[]),
    ('AE', 'AED', 'hatta-sign-hill-trail', 'hatta', 'NATURE', 0, 2, 'HOURS', 4.6, 'Тропа холма Hatta Sign', 'Hatta Sign Hill Trail', 'Hatta Sign төбесі соқпағы', 'Короткий подъем над Хаттой к открытым видам на дамбу, склоны Хаджара и горный силуэт эмирата.', 'A short climb above Hatta with open views toward the dam, Hajar slopes and the emirate mountain skyline.', 'Хатта үстіндегі қысқа көтерілу: бөгетке, Хаджар беткейлеріне және әмірліктің тау силуэтіне ашық көріністер.', 24.79400000, 56.11100000, 'Hatta_Dam_-_UAE.jpg', ARRAY['hatta']::text[], ARRAY['dubai','hatta']::text[], ARRAY['uae','hatta','viewpoint','free-entry','walking']::text[]),
    ('AE', 'AED', 'wadi-shah-stairway-heaven-trail', 'ras-al-khaimah', 'NATURE', 0, 7, 'HOURS', 4.8, 'Горная тропа Вади Шах', 'Wadi Shah Stairway to Heaven Trail', 'Уади Шах тау соқпағы', 'Сложный маршрут Рас-эль-Хаймы по каменным уступам, старым поселениям и сухим долинам для подготовленных путешественников.', 'A demanding Ras Al Khaimah route across rocky ledges, old settlements and dry valleys for prepared hikers.', 'Рас-эль-Хаймадағы дайын саяхатшыларға арналған күрделі бағыт: тасты кемерлер, ескі қоныстар және құрғақ аңғарлар.', 25.88100000, 56.09600000, 'Jebel_Jais_Ras_Al_Khaimah.jpg', ARRAY['ras-al-khaimah']::text[], ARRAY['ras-al-khaimah','dubai']::text[], ARRAY['uae','hajar','wadi','free-entry','trekking']::text[]),
    ('AE', 'AED', 'wadi-abadilah-trail', 'fujairah', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа Вади Абадила', 'Wadi Abadilah Trail', 'Уади Абадила соқпағы', 'Маршрут Фуджейры по сухому руслу, финиковым участкам и каменным стенкам с мягким горным рельефом.', 'A Fujairah route through a dry streambed, palm pockets and rocky walls with moderate mountain terrain.', 'Фуджейрадағы құрғақ арна, пальма бөліктері және жұмсақ тау бедері бар тасты қабырғалар арқылы өтетін бағыт.', 25.37300000, 56.21400000, 'Fujairah_Mountains.jpg', ARRAY['fujairah']::text[], ARRAY['fujairah','dubai']::text[], ARRAY['uae','fujairah','wadi','free-entry','hiking']::text[]),
    ('TR', 'TRY', 'avusor-plateau-trail', 'rize', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа плато Авусор', 'Avusor Plateau Trail', 'Авусор үстірті соқпағы', 'Черноморский маршрут Ризе к туманным лугам, деревянным домам и высокогорной пастбищной атмосфере Качкара.', 'A Rize Black Sea route to misty meadows, wooden houses and the high pasture atmosphere of the Kackar area.', 'Ризеден тұманды шалғындарға, ағаш үйлерге және Качкар аймағының биік жайлау атмосферасына апаратын Қара теңіз бағыты.', 40.88900000, 40.99500000, 'Ayder_Plateau.jpg', ARRAY['rize']::text[], ARRAY['rize','trabzon']::text[], ARRAY['turkey','rize','plateau','free-entry','hiking']::text[]),
    ('TR', 'TRY', 'love-valley-uchisar-trail', 'cappadocia', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа из Долины Любви в Учхисар', 'Love Valley to Uchisar Trail', 'Махаббат аңғарынан Учхисарға соқпақ', 'Каппадокийский маршрут между туфовыми колоннами, садами и скальным силуэтом Учхисара для полноценного полудня пешком.', 'A Cappadocia walk between tuff columns, gardens and the rocky Uchisar silhouette for a full half day on foot.', 'Каппадокиядағы туф бағандары, бақтар және Учхисардың жартас силуэті арасындағы жарты күндік жаяу бағыт.', 38.64600000, 34.81400000, 'Goreme_Open_Air_Museum.jpg', ARRAY['cappadocia']::text[], ARRAY['cappadocia','kayseri']::text[], ARRAY['turkey','cappadocia','valley','free-entry','walking']::text[]),
    ('TR', 'TRY', 'olympos-cirali-lycian-way-walk', 'kemer', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка Ликийской тропы Олимпос - Чиралы', 'Olympos to Cirali Lycian Way Walk', 'Олимпостан Чыралыға Ликия жолы серуені', 'Прибрежный маршрут у Кемера между соснами, древними руинами, пляжем и морским воздухом Средиземноморья.', 'A coastal route near Kemer between pines, ancient ruins, beach and Mediterranean sea air.', 'Кемер маңындағы жағалау бағыты: қарағайлар, көне қирандылар, жағажай және Жерорта теңізінің ауасы.', 36.40400000, 30.47300000, 'Goynuk_Canyon_Turkey.jpg', ARRAY['kemer']::text[], ARRAY['kemer','antalya']::text[], ARRAY['turkey','lycia','coastal-walk','free-entry','walking']::text[]),
    ('CY', 'EUR', 'atalanti-trail', 'troodos', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа Аталанти', 'Atalanti Trail', 'Аталанти соқпағы', 'Кипрский горный круг по хвойному поясу Троодоса, тенистым участкам и видам на островные склоны.', 'A Cyprus mountain loop through the Troodos conifer belt, shaded sections and views over island slopes.', 'Кипрдегі Троодос қылқанды белдеуі, көлеңкелі бөліктер және арал беткейлеріне көріністер арқылы өтетін тау ілмегі.', 34.93900000, 32.86300000, 'Troodos_mountains.jpg', ARRAY['troodos']::text[], ARRAY['troodos','limassol','nicosia']::text[], ARRAY['cyprus','troodos','forest','free-entry','hiking']::text[]),
    ('GR', 'EUR', 'gortsia-petrostrouga-trail', 'litochoro', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа Горция - Петроструга', 'Gortsia to Petrostrouga Trail', 'Горциядан Петростругаға соқпақ', 'Олимпийский маршрут над Литохоро через буковый лес, горные поляны и постепенный набор высоты к альпийской зоне.', 'An Olympus route above Litochoro through beech forest, mountain clearings and steady ascent toward the alpine zone.', 'Литохоро үстіндегі Олимп бағыты: шамшат орманы, тау алаңдары және альпілік белдеуге біртіндеп көтерілу.', 40.10300000, 22.40700000, 'Meteora_Monasteries_Greece.jpg', ARRAY['litochoro']::text[], ARRAY['litochoro','thessaloniki']::text[], ARRAY['greece','olympus','forest','free-entry','trekking']::text[]),
    ('CH', 'CHF', 'hardergrat-trail', 'interlaken', 'NATURE', 0, 8, 'HOURS', 4.9, 'Гребневая тропа Хардерграт', 'Hardergrat Trail', 'Хардерграт жотасы соқпағы', 'Длинный альпийский гребень над Интерлакеном с озерными панорамами, крутыми участками и форматом для опытных хайкеров.', 'A long alpine ridge above Interlaken with lake panoramas, steep sections and a format for experienced hikers.', 'Интерлакен үстіндегі ұзын альпілік жота: көл панорамалары, тік бөліктер және тәжірибелі хайкерлерге арналған формат.', 46.75400000, 7.92400000, 'Jungfreijoch.jpg', ARRAY['interlaken']::text[], ARRAY['interlaken','bern']::text[], ARRAY['switzerland','bernese-oberland','ridge','free-entry','trekking']::text[]),
    ('AT', 'EUR', 'gamsgrubenweg-panorama-trail', 'grossglockner', 'NATURE', 0, 3, 'HOURS', 4.7, 'Панорамная тропа Гамсгрубенвег', 'Gamsgrubenweg Panorama Trail', 'Гамсгрубенвег панорама соқпағы', 'Высокогорная прогулка у Гросглокнера с ледниковым видом, тоннельными участками и удобным форматом без длинного подъема.', 'A high mountain walk near Grossglockner with glacier views, tunnel sections and an accessible format without a long climb.', 'Гросглокнер маңындағы биік таулы серуен: мұздық көріністері, тоннель бөліктері және ұзақ көтерілусіз қолайлы формат.', 47.07400000, 12.75000000, 'Grossglockner_High_Alpine_Road,_National_Park_Hohe_Tauern_Austria.jpg', ARRAY['grossglockner']::text[], ARRAY['grossglockner','zell-am-see']::text[], ARRAY['austria','hohe-tauern','glacier-view','free-entry','walking']::text[]),
    ('FR', 'EUR', 'grand-balcon-nord-trail', 'chamonix', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа Гран-Балькон Нор', 'Grand Balcon Nord Trail', 'Гран-Балькон Нор соқпағы', 'Классический маршрут Шамони по высокому балкону долины с видами на ледники, скальные башни и массив Монблана.', 'A classic Chamonix high-balcony route with views of glaciers, rock towers and the Mont Blanc massif.', 'Шамонидегі аңғардың биік балконымен өтетін классикалық бағыт: мұздықтар, жартас мұнаралары және Монблан массиві көрінеді.', 45.92000000, 6.89300000, 'Aiguille_du_Midi.jpg', ARRAY['chamonix']::text[], ARRAY['chamonix','geneva']::text[], ARRAY['france','alps','mont-blanc','free-entry','trekking']::text[]),
    ('GB', 'GBP', 'helvellyn-striding-edge-walk', 'lake-district', 'NATURE', 0, 7, 'HOURS', 4.9, 'Маршрут Хелвеллин через Страйдинг Эдж', 'Helvellyn Striding Edge Walk', 'Хелвеллин Страйдинг Эдж маршруты', 'Озерный край для подготовленных: гребень, каменные участки и сильная панорама феллов вокруг Гленриддинга.', 'A prepared-hiker Lake District day with ridge terrain, rocky sections and a strong panorama of fells around Glenridding.', 'Дайын хайкерлерге арналған Көлдер өлкесі бағыты: жота, тасты бөліктер және Гленриддинг айналасындағы феллдер панорамасы.', 54.52600000, -3.01600000, 'Lake_District_National_Park.jpg', ARRAY['lake-district']::text[], ARRAY['lake-district','manchester']::text[], ARRAY['united-kingdom','cumbria','ridge','free-entry','trekking']::text[]),
    ('IT', 'EUR', 'punta-campanella-trail', 'amalfi-coast', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа Пунта Кампанелла', 'Punta Campanella Trail', 'Пунта Кампанелла соқпағы', 'Прибрежный маршрут Амальфи к мысу, оливковым террасам, морским видам и силуэту Капри.', 'An Amalfi coastal route to the headland, olive terraces, sea views and the Capri silhouette.', 'Амальфи жағалауындағы мүйіске, зәйтүн террасаларына, теңіз көріністеріне және Капри силуэтіне апаратын бағыт.', 40.56200000, 14.33500000, 'Vernazza_Cinque_Terre.jpg', ARRAY['amalfi-coast']::text[], ARRAY['amalfi-coast','naples']::text[], ARRAY['italy','amalfi','coastal-walk','free-entry','walking']::text[]),
    ('ES', 'EUR', 'sierra-bernia-circular-trail', 'calpe', 'NATURE', 0, 5, 'HOURS', 4.8, 'Круговая тропа Сьерра-де-Берния', 'Sierra de Bernia Circular Trail', 'Сьерра-де-Берния айналма соқпағы', 'Коста-Бланка маршрут по известняковому хребту, старому форту, арке-тоннелю и видам на Средиземное море.', 'A Costa Blanca route across a limestone ridge, old fort, tunnel arch and Mediterranean views.', 'Коста-Бланкадағы әктас жота, ескі форт, тоннель аркасы және Жерорта теңізіне көріністер арқылы өтетін бағыт.', 38.65000000, -0.06400000, 'Costa_Blanca_Spain.jpg', ARRAY['calpe']::text[], ARRAY['calpe','alicante']::text[], ARRAY['spain','costa-blanca','ridge','free-entry','hiking']::text[]),
    ('PT', 'EUR', 'levada-caldeirao-verde-trail', 'madeira', 'NATURE', 0, 5, 'HOURS', 4.9, 'Левада к Кальдейран-Верде', 'Levada do Caldeirao Verde Trail', 'Кальдейран-Верде левадасы соқпағы', 'Мадейрский маршрут вдоль левады через лавровый лес, тоннели и влажные стены к зеленому котлу с водопадом.', 'A Madeira levada route through laurel forest, tunnels and wet walls toward a green waterfall amphitheater.', 'Мадейрадағы левада бағыты: лавр орманы, тоннельдер және сарқырамалы жасыл амфитеатрға апаратын ылғалды қабырғалар.', 32.78400000, -16.90400000, 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg', ARRAY['madeira']::text[], ARRAY['madeira','funchal']::text[], ARRAY['portugal','madeira','levada','free-entry','hiking']::text[]),
    ('IE', 'EUR', 'derrybawn-woodland-trail', 'glendalough', 'NATURE', 0, 3, 'HOURS', 4.6, 'Лесная тропа Деррибоун', 'Derrybawn Woodland Trail', 'Деррибоун орман соқпағы', 'Короткий маршрут Глендалоха через лес, склоновые тропы и мягкие виды на ледниковую долину.', 'A short Glendalough route through woodland, hillside paths and gentle views over the glacial valley.', 'Глендалохтағы орман, беткей жолдары және мұздық аңғарға жұмсақ көріністер арқылы өтетін қысқа бағыт.', 53.00600000, -6.32900000, 'Glendalough_Ireland.jpg', ARRAY['glendalough']::text[], ARRAY['glendalough','dublin']::text[], ARRAY['ireland','wicklow','forest','free-entry','walking']::text[]),
    ('IS', 'ISK', 'arnarstapi-hellnar-coastal-walk', 'snaefellsnes', 'NATURE', 0, 2, 'HOURS', 4.8, 'Прибрежная прогулка Арнарстапи - Хелльнар', 'Arnarstapi to Hellnar Coastal Walk', 'Арнарстапиден Хелльнарға жағалау серуені', 'Исландский маршрут по лавовым берегам, базальтовым аркам, птицам и океанскому ветру полуострова Снайфедльснес.', 'An Iceland route along lava shores, basalt arches, bird cliffs and ocean wind on the Snaefellsnes peninsula.', 'Снайфедльснес түбегіндегі лава жағалаулары, базальт аркалары, құс жартастары және мұхит желі арқылы өтетін Исландия бағыты.', 64.76400000, -23.63300000, 'Snaefellsjokull_National_Park_Iceland.jpg', ARRAY['snaefellsnes']::text[], ARRAY['snaefellsnes','reykjavik']::text[], ARRAY['iceland','snaefellsnes','coastal-walk','free-entry','walking']::text[]),
    ('PL', 'PLN', 'dolina-pieciu-stawow-trail', 'zakopane', 'NATURE', 0, 6, 'HOURS', 4.9, 'Тропа в Долину пяти прудов', 'Dolina Pieciu Stawow Trail', 'Бес тоған аңғары соқпағы', 'Татранский маршрут из района Закопане к высокогорным озерам, каменным тропам и сильной альпийской сцене.', 'A Tatra route from the Zakopane area toward high mountain lakes, stone paths and a strong alpine scene.', 'Закопане аймағынан биік тау көлдеріне, тасты соқпақтарға және айқын альпілік көрініске апаратын Татра бағыты.', 49.21900000, 20.05000000, 'MORSKIE OKO.jpg', ARRAY['zakopane']::text[], ARRAY['zakopane','krakow']::text[], ARRAY['poland','tatras','alpine-lakes','free-entry','trekking']::text[]),
    ('ME', 'EUR', 'bobotov-kuk-summit-trail', 'durmitor', 'NATURE', 0, 7, 'HOURS', 4.9, 'Тропа на вершину Боботов-Кук', 'Bobotov Kuk Summit Trail', 'Боботов-Кук шыңы соқпағы', 'Черногорский высокогорный маршрут Дурмитора к каменистым циркам, перевалам и главной вершине массива.', 'A Montenegro high mountain route in Durmitor toward rocky cirques, passes and the main summit of the massif.', 'Черногориядағы Дурмитордың биік таулы бағыты: тасты цирктерге, асуларға және массивтің басты шыңына апарады.', 43.12800000, 19.03300000, 'Durmitor_-_Crno_jezero.jpg', ARRAY['durmitor']::text[], ARRAY['durmitor','podgorica']::text[], ARRAY['montenegro','durmitor','summit','free-entry','trekking']::text[]);

CREATE TEMP TABLE seed_europe_caucasus_middle_east_gap_hiking_resolved_places AS
SELECT
    ('111d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['europe-caucasus-middle-east-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_europe_caucasus_middle_east_gap_hiking_places;

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
FROM seed_europe_caucasus_middle_east_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_middle_east_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_middle_east_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_middle_east_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_middle_east_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_europe_caucasus_middle_east_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_europe_caucasus_middle_east_gap_hiking_places;
