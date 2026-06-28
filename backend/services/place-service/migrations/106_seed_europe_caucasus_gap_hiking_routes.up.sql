-- Europe and Caucasus route-level hiking gap seed.
-- Adds concrete trails for weakly covered hubs without replacing broad parks, villages or existing route anchors.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_europe_caucasus_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_europe_caucasus_gap_hiking_places;

CREATE TEMP TABLE seed_europe_caucasus_gap_hiking_places (
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

INSERT INTO seed_europe_caucasus_gap_hiking_places (
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
    ('AB', 'RUB', 'yupshara-canyon-forest-trail', 'lake-ritsa', 'NATURE', 0, 3, 'HOURS', 4.7, 'Лесная тропа Юпшарского каньона', 'Yupshara Canyon Forest Trail', 'Юпшара каньоны орман соқпағы', 'Короткая лесная прогулка по дороге к Рице с влажными стенами каньона, тенистыми участками и мягким форматом для остановки.', 'A short forest walk on the way to Ritsa with humid canyon walls, shade and an easy stopover format.', 'Рицаға барар жолдағы қысқа орман серуені: ылғалды каньон қабырғалары, көлеңкелі бөліктер және жеңіл аялдама форматы.', 43.43100000, 40.50400000, 'Abkhazia. Lake Ritsa P9100146 2600.jpg', ARRAY['lake-ritsa','gagra']::text[], ARRAY['lake-ritsa','gagra']::text[], ARRAY['abkhazia','canyon','forest','free-entry','hiking']::text[]),
    ('GE', 'GEL', 'mestia-glacier-valley-trail', 'mestia', 'NATURE', 0, 5, 'HOURS', 4.8, 'Ледниковая тропа долины Местии', 'Mestia Glacier Valley Trail', 'Местия мұздық аңғары соқпағы', 'Сванетский маршрут к ледниковой долине, каменным моренам и видам на башни и снежные стены вокруг Местии.', 'A Svaneti route toward a glacier valley, stony moraines and views of towers and snowy walls around Mestia.', 'Местия маңындағы мұздық аңғарға, тасты мореналарға және мұнаралар мен қарлы қабырғалар көрінісіне апаратын Сванетия бағыты.', 43.11700000, 42.68900000, 'Kutaisi,_Georgia.jpg', ARRAY['mestia']::text[], ARRAY['mestia']::text[], ARRAY['georgia','svaneti','glacier-view','free-entry','trekking']::text[]),
    ('GE', 'GEL', 'shkhara-valley-view-trail', 'ushguli', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа к виду на долину Шхары', 'Shkhara Valley View Trail', 'Шхара аңғары көрініс соқпағы', 'Высокогорная сванская прогулка к открытым видам на долину, ледниковые склоны и каменные тропы у самой высокой части Кавказа.', 'A high Svaneti walk to open valley views, glacier slopes and stone paths near the highest Caucasus area.', 'Кавказдың ең биік бөлігі маңындағы ашық аңғар көріністеріне, мұздық беткейлерге және тасты жолдарға апаратын биік Сванетия серуені.', 42.91670000, 43.01670000, 'Kutaisi,_Georgia.jpg', ARRAY['ushguli','mestia']::text[], ARRAY['ushguli','mestia']::text[], ARRAY['georgia','svaneti','valley-view','free-entry','trekking']::text[]),
    ('AM', 'AMD', 'artanish-peninsula-ridge-walk', 'artanish', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка по гребню Артанишского полуострова', 'Artanish Peninsula Ridge Walk', 'Артаниш түбегі жотасы серуені', 'Маршрут над Севаном с сухими гребнями, степной травой и широкими видами на озерную чашу.', 'A route above Sevan with dry ridges, steppe grass and wide views over the lake basin.', 'Севан үстіндегі құрғақ жоталар, дала шөбі және көл алабына кең көріністер арқылы өтетін бағыт.', 40.44400000, 45.31500000, 'Lake_Sevan,_Armenia.jpg', ARRAY['artanish','sevan']::text[], ARRAY['artanish','sevan','yerevan']::text[], ARRAY['armenia','sevan','ridge','free-entry','hiking']::text[]),
    ('AM', 'AMD', 'arpa-canyon-resort-trail', 'jermuk', 'NATURE', 0, 3, 'HOURS', 4.6, 'Тропа каньона Арпы у Джермука', 'Arpa Canyon Resort Trail', 'Джермуктағы Арпа каньоны соқпағы', 'Курортная прогулка вдоль горной долины, минерального контекста и прохладных склонов для легкого outdoor-дня.', 'A resort-area walk along a mountain valley, mineral-spring context and cool slopes for an easy outdoor day.', 'Тау аңғары, минералды бұлақ контексті және салқын беткейлер бойымен өтетін жеңіл outdoor күніне арналған курорттық серуен.', 39.76000000, 45.61000000, 'Tatev_Monastery,_Armenia.jpg', ARRAY['jermuk']::text[], ARRAY['jermuk','yerevan']::text[], ARRAY['armenia','vayots-dzor','canyon','free-entry','walking']::text[]),
    ('AZ', 'AZN', 'tengealti-canyon-trail', 'quba', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа каньона Тенгеалти', 'Tengealti Canyon Trail', 'Тенгеалты каньоны соқпағы', 'Маршрут района Губы к узкому каньону, речным участкам и предгорному рельефу северного Азербайджана.', 'A Quba area route to a narrow canyon, river sections and northern Azerbaijan foothill terrain.', 'Губа маңындағы тар каньонға, өзен бөліктеріне және солтүстік Әзербайжанның тау етегі бедеріне апаратын бағыт.', 41.30000000, 48.58000000, 'Quba Azerbaijan.jpg', ARRAY['quba']::text[], ARRAY['quba','baku']::text[], ARRAY['azerbaijan','quba','canyon','free-entry','hiking']::text[]),
    ('AT', 'EUR', 'pasterze-glacier-view-trail', 'grossglockner', 'NATURE', 0, 4, 'HOURS', 4.9, 'Тропа к виду на ледник Пастерце', 'Pasterze Glacier View Trail', 'Пастерце мұздығы көрінісіне соқпақ', 'Альпийский маршрут у высочайшей горной зоны Австрии с ледниковыми видами, каменной тропой и быстрым ощущением масштаба.', 'An alpine route in Austria high mountain area with glacier views, stone paths and an immediate sense of scale.', 'Австрияның биік тау аймағындағы мұздық көріністері, тасты жолдары және ауқымды бірден сездіретін альпілік бағыт.', 47.07430000, 12.75390000, 'Grossglockner_High_Alpine_Road,_National_Park_Hohe_Tauern_Austria.jpg', ARRAY['grossglockner']::text[], ARRAY['grossglockner','zell-am-see']::text[], ARRAY['austria','alps','glacier-view','free-entry','hiking']::text[]),
    ('CH', 'CHF', 'trupchun-valley-wildlife-trail', 'swiss-national-park', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа дикой долины Трупчун', 'Trupchun Valley Wildlife Trail', 'Трупчун жабайы аңғар соқпағы', 'Маршрут по альпийской долине с лесом, лугами и шансом увидеть горных животных при спокойном темпе.', 'An alpine valley route with forest, meadows and a chance to observe mountain wildlife at a calm pace.', 'Орманы, шалғындары және тыныш қарқында тау жануарларын көру мүмкіндігі бар альпілік аңғар бағыты.', 46.61750000, 10.02930000, 'Matterhorn Riffelsee 2005-06-11.jpg', ARRAY['swiss-national-park']::text[], ARRAY['st-moritz','chur','swiss-national-park']::text[], ARRAY['switzerland','graubunden','wildlife','free-entry','trekking']::text[]),
    ('CY', 'EUR', 'troodos-cedar-ridge-trail', 'troodos', 'NATURE', 0, 4, 'HOURS', 4.7, 'Кедровая тропа хребта Троодоса', 'Troodos Cedar Ridge Trail', 'Троодос самырсын жотасы соқпағы', 'Горная прогулка по кипрскому лесному поясу с прохладой, хвойными участками и видами над островом.', 'A Cyprus mountain walk through a cool forest belt, conifer sections and island views.', 'Кипрдің салқын орман белдеуі, қылқанды бөліктері және арал көріністері арқылы өтетін тау серуені.', 34.93320000, 32.87200000, 'Troodos_mountains.jpg', ARRAY['troodos']::text[], ARRAY['troodos','limassol']::text[], ARRAY['cyprus','troodos','forest','free-entry','hiking']::text[]),
    ('CZ', 'CZK', 'elbe-sandstone-forest-trail', 'bohemian-switzerland', 'NATURE', 0, 4, 'HOURS', 4.7, 'Лесная тропа Эльбских песчаников', 'Elbe Sandstone Forest Trail', 'Эльба құмтастары орман соқпағы', 'Маршрут среди песчаников, лесных лестниц и влажных ущелий северной Чехии без повтора главной арки.', 'A northern Czech route among sandstone forms, forest stairs and humid ravines without repeating the main arch stop.', 'Солтүстік Чехиядағы құмтас пішіндері, орман баспалдақтары және ылғалды шатқалдар арасындағы бағыт.', 50.88400000, 14.28100000, 'Bohemian Switzerland National Park.jpg', ARRAY['bohemian-switzerland']::text[], ARRAY['prague','bohemian-switzerland']::text[], ARRAY['czechia','sandstone','forest','free-entry','hiking']::text[]),
    ('DE', 'EUR', 'reintal-gorge-approach-trail', 'garmisch-partenkirchen', 'NATURE', 0, 5, 'HOURS', 4.7, 'Подходная тропа ущелья Райнталь', 'Reintal Gorge Approach Trail', 'Райнталь шатқалына жақындау соқпағы', 'Баварская альпийская тропа с речной долиной, лесом и видом на высокие склоны вокруг Гармиша.', 'A Bavarian alpine route with a river valley, forest and views of high slopes around Garmisch.', 'Гармиш маңындағы өзен аңғары, орман және биік беткейлер көрінісі бар Бавария альпілік бағыты.', 47.46920000, 11.11860000, 'Schloss_Neuschwanstein_2013.jpg', ARRAY['garmisch-partenkirchen']::text[], ARRAY['garmisch-partenkirchen','munich']::text[], ARRAY['germany','bavaria','alps','free-entry','hiking']::text[]),
    ('DK', 'DKK', 'klinteskoven-cliff-forest-trail', 'mons-klint', 'NATURE', 0, 3, 'HOURS', 4.7, 'Лесная тропа утесов Клинтесковен', 'Klinteskoven Cliff Forest Trail', 'Клинтесковен жартасты орман соқпағы', 'Датская прибрежная прогулка по буковому лесу, меловым обрывам и лестницам к морю.', 'A Danish coastal walk through beech forest, chalk cliffs and stairways toward the sea.', 'Даниядағы бук орманы, борлы жартастар және теңізге түсетін баспалдақтар арқылы өтетін жағалау серуені.', 54.96650000, 12.55060000, 'Denmark,_Møns_Klint_(denmark-mons-klint).jpg', ARRAY['mons-klint']::text[], ARRAY['copenhagen','mons-klint']::text[], ARRAY['denmark','coast','cliffs','free-entry','walking']::text[]),
    ('FI', 'EUR', 'kilpisjarvi-fell-ridge-trail', 'kilpisjarvi', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа сопочного гребня Килписъярви', 'Kilpisjarvi Fell Ridge Trail', 'Килписъярви қырқасы соқпағы', 'Лапландский маршрут по открытым сопкам, северному ветру и широким видам у границы трех стран.', 'A Lapland route across open fells, northern wind and wide views near the three-country border.', 'Үш ел шекарасы маңындағы ашық қырқалар, солтүстік жел және кең көріністер арқылы өтетін Лапландия бағыты.', 69.04500000, 20.80000000, 'Saana_Fell.jpg', ARRAY['kilpisjarvi']::text[], ARRAY['kilpisjarvi']::text[], ARRAY['finland','lapland','fell','free-entry','trekking']::text[]),
    ('FR', 'EUR', 'lac-blanc-trail', 'chamonix', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа к озеру Лак-Блан', 'Lac Blanc Trail', 'Лак-Блан көлі соқпағы', 'Классический маршрут Шамони к высокому озеру, скальным участкам и панорамам Монбланского массива.', 'A classic Chamonix route to a high lake, rocky sections and Mont Blanc massif panoramas.', 'Шамонидегі биік көлге, тасты бөліктерге және Монблан массиві панорамаларына апаратын классикалық бағыт.', 45.99600000, 6.88500000, 'Aiguille du Midi.jpg', ARRAY['chamonix']::text[], ARRAY['chamonix','lyon']::text[], ARRAY['france','chamonix','alps','free-entry','trekking']::text[]),
    ('GB', 'GBP', 'catbells-ridge-walk', 'lake-district', 'NATURE', 0, 4, 'HOURS', 4.8, 'Прогулка по гребню Кэтбеллс', 'Catbells Ridge Walk', 'Кэтбеллс жотасы серуені', 'Озерный маршрут по открытой гряде с мягким подъемом, видами на воду и классическим английским hill-walk форматом.', 'A Lake District route along an open ridge with gentle climbing, water views and a classic English hill-walk format.', 'Көлдер аймағындағы ашық жота, жұмсақ көтерілу және су көріністері бар классикалық ағылшын hill-walk форматы.', 54.56800000, -3.17000000, 'Lake District National Park.jpg', ARRAY['lake-district']::text[], ARRAY['manchester','lake-district']::text[], ARRAY['united-kingdom','lake-district','ridge','free-entry','hiking']::text[]),
    ('GR', 'EUR', 'prionia-forest-ascent-trail', 'litochoro', 'NATURE', 0, 5, 'HOURS', 4.8, 'Лесная тропа подъема к Прионии', 'Prionia Forest Ascent Trail', 'Прионияға орманды көтерілу соқпағы', 'Маршрут у подножия Олимпа через лес, прохладные ручьи и постепенный набор высоты для подготовленного дня.', 'A Mount Olympus foothill route through forest, cool streams and steady elevation gain for a prepared day.', 'Олимп етегіндегі орман, салқын бұлақтар және дайын күнге арналған біртіндеп биіктік жинауы бар бағыт.', 40.08600000, 22.40700000, 'Meteora_Monasteries_Greece.jpg', ARRAY['litochoro']::text[], ARRAY['litochoro','thessaloniki']::text[], ARRAY['greece','olympus','forest','free-entry','trekking']::text[]),
    ('IE', 'EUR', 'spinc-and-glenealo-valley-trail', 'glendalough', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа Спинк и долины Гленеало', 'Spinc and Glenealo Valley Trail', 'Спинк және Гленеало аңғары соқпағы', 'Маршрут Уиклоу к верхним смотровым, озерным видам и горной долине над монастырским ландшафтом.', 'A Wicklow route to upper viewpoints, lake views and a mountain valley above the monastic landscape.', 'Уиклоудағы жоғарғы көрініс нүктелеріне, көл көріністеріне және монастырлық ландшафт үстіндегі тау аңғарына апаратын бағыт.', 53.01000000, -6.32750000, 'Glendalough_Ireland.jpg', ARRAY['glendalough']::text[], ARRAY['dublin','glendalough']::text[], ARRAY['ireland','wicklow','lake-view','free-entry','hiking']::text[]),
    ('IS', 'ISK', 'snaefellsnes-coastal-lava-walk', 'snaefellsnes', 'NATURE', 0, 3, 'HOURS', 4.7, 'Лавовая прогулка побережья Снайфедльснеса', 'Snaefellsnes Coastal Lava Walk', 'Снайфедльснес жағалауы лава серуені', 'Исландский маршрут по лавовым полям, черному берегу и ветреным видам полуострова для короткого outdoor-плана.', 'An Icelandic route across lava fields, black coastline and windy peninsula views for a short outdoor plan.', 'Исландиядағы лава алқаптары, қара жағалау және түбектің желді көріністері арқылы өтетін қысқа outdoor бағыты.', 64.80500000, -23.77000000, 'Snaefellsjokull National Park Iceland.jpg', ARRAY['snaefellsnes']::text[], ARRAY['reykjavik','snaefellsnes']::text[], ARRAY['iceland','west-iceland','lava','free-entry','walking']::text[]),
    ('IT', 'EUR', 'path-of-the-gods-trail', 'amalfi-coast', 'NATURE', 0, 4, 'HOURS', 4.9, 'Тропа Богов на Амальфитанском побережье', 'Path of the Gods Trail', 'Амальфи жағалауындағы Құдайлар соқпағы', 'Панорамный прибрежный маршрут над деревнями, террасами и морем с сильным южноитальянским outdoor-сценарием.', 'A panoramic coastal route above villages, terraces and the sea with a strong southern Italy outdoor scenario.', 'Ауылдар, террасалар және теңіз үстіндегі панорамалық жағалау бағыты, Оңтүстік Италиядағы әсерлі outdoor сценарий.', 40.61300000, 14.53900000, 'Vernazza_Cinque_Terre.jpg', ARRAY['amalfi-coast']::text[], ARRAY['naples','amalfi-coast']::text[], ARRAY['italy','amalfi','coast','free-entry','hiking']::text[]),
    ('ME', 'EUR', 'durmitor-lake-forest-loop', 'durmitor', 'NATURE', 0, 3, 'HOURS', 4.8, 'Лесная петля озер Дурмитора', 'Durmitor Lake Forest Loop', 'Дурмитор көлдері орман ілмегі', 'Короткий горный маршрут по хвойному лесу, озерным видам и каменным склонам вокруг Жабляка.', 'A short mountain route through conifer forest, lake views and rocky slopes around Zabljak.', 'Жабляк маңындағы қылқанды орман, көл көріністері және тасты беткейлер арқылы өтетін қысқа тау бағыты.', 43.14620000, 19.09370000, 'Durmitor_-_Crno_jezero.jpg', ARRAY['durmitor','zabljak']::text[], ARRAY['zabljak','durmitor']::text[], ARRAY['montenegro','durmitor','forest','free-entry','walking']::text[]),
    ('MT', 'EUR', 'malta-western-clifftop-walk', 'dingli', 'NATURE', 0, 2, 'HOURS', 4.6, 'Прогулка западных обрывов Мальты', 'Malta Western Clifftop Walk', 'Мальтаның батыс жартастары серуені', 'Короткий островной маршрут по открытым обрывам, морскому ветру и закатным видам западной Мальты.', 'A short island route along open cliffs, sea wind and sunset views of western Malta.', 'Батыс Мальтаның ашық жартастары, теңіз желі және күн бату көріністері бойымен өтетін қысқа арал бағыты.', 35.86160000, 14.38360000, 'Dingli_Cliffs_Malta.jpg', ARRAY['dingli']::text[], ARRAY['valletta','dingli']::text[], ARRAY['malta','coast','cliffs','free-entry','walking']::text[]),
    ('NL', 'EUR', 'veluwe-sand-drift-trail', 'hoge-veluwe', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа песчаных дюн Велюве', 'Veluwe Sand Drift Trail', 'Велюве құмды алқап соқпағы', 'Нидерландская природная прогулка по соснам, открытым песчаным участкам и мягкому лесному рельефу.', 'A Netherlands nature walk through pines, open sand drifts and gentle forest terrain.', 'Нидерландтағы қарағайлар, ашық құмды алқаптар және жұмсақ орман бедері арқылы өтетін табиғи серуен.', 52.08330000, 5.80000000, 'Hoge_Veluwe_National_Park.jpg', ARRAY['hoge-veluwe','arnhem']::text[], ARRAY['arnhem','hoge-veluwe']::text[], ARRAY['netherlands','veluwe','sand-drift','free-entry','walking']::text[]),
    ('PL', 'PLN', 'tatra-lake-approach-trail', 'zakopane', 'NATURE', 0, 5, 'HOURS', 4.8, 'Подходная тропа к татранскому озеру', 'Tatra Lake Approach Trail', 'Татра көліне жақындау соқпағы', 'Маршрут из Закопане к горной долине, хвойному лесу и высокогорным видам польских Татр.', 'A Zakopane route toward a mountain valley, conifer forest and high views of the Polish Tatras.', 'Закопанеден тау аңғарына, қылқанды орманға және Польша Татрасының биік көріністеріне апаратын бағыт.', 49.25000000, 19.93330000, 'MORSKIE OKO.jpg', ARRAY['zakopane']::text[], ARRAY['krakow','zakopane']::text[], ARRAY['poland','tatras','lake-approach','free-entry','hiking']::text[]),
    ('PT', 'EUR', 'pico-ruivo-trail', 'madeira', 'NATURE', 0, 5, 'HOURS', 4.9, 'Тропа Пику-Руйву', 'Pico Ruivo Trail', 'Пику-Руйву соқпағы', 'Горный маршрут Мадейры к высокому гребню, облачным видам и сильному островному рельефу.', 'A Madeira mountain route to a high ridge, cloud views and dramatic island terrain.', 'Мадейрадағы биік жотаға, бұлтты көріністерге және әсерлі арал бедеріне апаратын тау бағыты.', 32.75800000, -16.94200000, 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg', ARRAY['madeira','funchal']::text[], ARRAY['madeira','funchal']::text[], ARRAY['portugal','madeira','ridge','free-entry','trekking']::text[]),
    ('RS', 'RSD', 'banjska-stena-viewpoint-trail', 'tara', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа к обзорной Баньска Стена', 'Banjska Stena Viewpoint Trail', 'Баньска Стена көрініс соқпағы', 'Сербский лесной маршрут к открытому виду на каньон, соснам и спокойному горному воздуху.', 'A Serbian forest route to an open canyon view, pines and calm mountain air.', 'Сербиядағы каньон көрінісіне, қарағайларға және тыныш тау ауасына апаратын орман бағыты.', 43.94900000, 19.39800000, 'Tara_National_Park_Serbia.jpg', ARRAY['tara']::text[], ARRAY['belgrade','tara']::text[], ARRAY['serbia','tara','viewpoint','free-entry','hiking']::text[]),
    ('SE', 'SEK', 'areskutan-summit-trail', 'are', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа на вершину Орескутан', 'Areskutan Summit Trail', 'Орескутан шыңы соқпағы', 'Скандинавский маршрут к открытой вершине, ветру, каменным участкам и видам на горный курорт Оре.', 'A Scandinavian route to an open summit, wind, stone sections and views over the Are mountain resort.', 'Оре тау курортына көрінісі бар ашық шыңға, желге және тасты бөліктерге апаратын Скандинавия бағыты.', 63.43140000, 13.09060000, 'Åreskutan from Fröåvägen.jpg', ARRAY['are']::text[], ARRAY['are']::text[], ARRAY['sweden','are','summit','free-entry','hiking']::text[]),
    ('TR', 'TRY', 'red-valley-loop-trail', 'cappadocia', 'NATURE', 0, 3, 'HOURS', 4.8, 'Петля Красной долины', 'Red Valley Loop Trail', 'Қызыл аңғар ілмегі', 'Каппадокийский маршрут среди туфовых склонов, пещерных троп и вечернего света для понятного полудня.', 'A Cappadocia route among tuff slopes, cave paths and evening light for an easy half day.', 'Каппадокиядағы туф беткейлері, үңгір жолдары және кешкі жарық арасындағы түсінікті жарты күндік бағыт.', 38.65300000, 34.84900000, 'Goreme_Open_Air_Museum.jpg', ARRAY['cappadocia','goreme']::text[], ARRAY['cappadocia','goreme']::text[], ARRAY['turkey','cappadocia','valley','free-entry','hiking']::text[]),
    ('UA', 'UAH', 'tsetsyno-ridge-forest-trail', 'chernivtsi', 'NATURE', 0, 3, 'HOURS', 4.5, 'Лесная тропа хребта Цецино', 'Tsetsyno Ridge Forest Trail', 'Цецино жотасы орман соқпағы', 'Короткая буковинская прогулка по лесной гряде, городским видам и мягкому рельефу рядом с Черновцами.', 'A short Bukovyna walk along a forest ridge, city views and gentle terrain near Chernivtsi.', 'Черновцы маңындағы орман жотасы, қала көріністері және жұмсақ бедер арқылы өтетін қысқа Буковина серуені.', 48.28600000, 25.84600000, 'Shevchenko_Park_Chernivtsi.jpg', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], ARRAY['ukraine','bukovyna','forest','free-entry','walking']::text[]),
    ('PT', 'EUR', 'sintra-cabo-da-roca-cliff-walk', 'sintra', 'NATURE', 0, 3, 'HOURS', 4.8, 'Скальная прогулка Синтра - Кабу-да-Рока', 'Sintra Cabo da Roca Cliff Walk', 'Синтра - Кабу-да-Рока жартасты серуені', 'Прибрежный маршрут среди океанских обрывов, ветра и диких пляжных видов западнее Лиссабона.', 'A coastal route among ocean cliffs, wind and wild beach views west of Lisbon.', 'Лиссабонның батысындағы мұхит жартастары, жел және жабайы жағажай көріністері арқылы өтетін жағалау бағыты.', 38.78040000, -9.49890000, 'Praia_da_adraga_portugal.jpg', ARRAY['sintra']::text[], ARRAY['sintra','lisbon']::text[], ARRAY['portugal','sintra','coast','free-entry','walking']::text[]),
    ('IE', 'EUR', 'howth-cliff-loop-walk', 'howth', 'NATURE', 0, 3, 'HOURS', 4.7, 'Кольцевая прогулка по утесам Хоута', 'Howth Cliff Loop Walk', 'Хоут жартастары айналма серуені', 'Дублинская прибрежная прогулка с морским ветром, маяками и быстрым outdoor-сценарием рядом с городом.', 'A Dublin coastal walk with sea wind, lighthouse views and a quick outdoor scenario close to the city.', 'Дублин маңындағы теңіз желі, маяк көріністері және қалаға жақын жылдам outdoor сценарийі бар жағалау серуені.', 53.37140000, -6.05650000, 'Howth_Cliff_Path_Ireland.jpg', ARRAY['howth','dublin']::text[], ARRAY['dublin','howth']::text[], ARRAY['ireland','dublin','coast','free-entry','walking']::text[]),
    ('LU', 'EUR', 'mullerthal-schiessentumpel-trail', 'mullerthal', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Шиссентюмпель в Мюллертале', 'Mullerthal Schiessentumpel Trail', 'Мюллерталь Шиссентюмпель соқпағы', 'Лесной маршрут Люксембурга среди песчаников, мостиков, ручьев и мягкого рельефа малого каньона.', 'A Luxembourg forest route among sandstone, small bridges, streams and gentle mini-canyon terrain.', 'Люксембургтегі құмтас, шағын көпірлер, бұлақтар және жұмсақ кіші каньон бедері арасындағы орман бағыты.', 49.77950000, 6.30630000, 'Mullerthal_Cascade_Bridge_01.jpg', ARRAY['mullerthal','echternach']::text[], ARRAY['mullerthal','echternach','luxembourg-city']::text[], ARRAY['luxembourg','mullerthal','sandstone','free-entry','hiking']::text[]),
    ('EE', 'EUR', 'lahemaa-viru-bog-boardwalk', 'lahemaa', 'NATURE', 0, 2, 'HOURS', 4.8, 'Настил болота Виру в Лахемаа', 'Lahemaa Viru Bog Boardwalk', 'Лахемаа Виру батпағы тақтайжолы', 'Эстонская природная прогулка по деревянному настилу среди болотных озер, сосен и открытого северного ландшафта.', 'An Estonian nature walk on a wooden boardwalk among bog pools, pines and open northern landscape.', 'Эстониядағы батпақ көлшіктері, қарағайлар және ашық солтүстік ландшафт арасындағы ағаш тақтайжол серуені.', 59.47160000, 25.63680000, 'Viru_Bog.jpg', ARRAY['lahemaa']::text[], ARRAY['tallinn','lahemaa']::text[], ARRAY['estonia','lahemaa','bog','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_europe_caucasus_gap_hiking_resolved_places AS
SELECT
    ('106d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['europe-caucasus-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_europe_caucasus_gap_hiking_places;

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
FROM seed_europe_caucasus_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_gap_hiking_resolved_places
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
FROM seed_europe_caucasus_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_europe_caucasus_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_europe_caucasus_gap_hiking_places;
