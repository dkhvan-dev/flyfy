-- Hidden Kazakhstan route-level outdoor/hiking seed.
-- Adds additional concrete local routes without replacing broad parks, gorges and previously seeded anchors.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_hidden_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_hidden_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_hidden_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_hidden_outdoor_routes_places (
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
    ('KZ', 'KZT', 'cosmostation-ridge-walk', 'almaty', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Прогулка по гребню Космостанции', 'Cosmostation Ridge Walk', 'Космостанция жотасы серуені', 'Высотная прогулка над зоной Большого Алматинского озера с сухими гребнями, видом на обсерватории и быстрым ощущением альпийского масштаба.', 'A high-altitude walk above the Big Almaty Lake area with dry ridges, observatory views and a quick feel for alpine scale.', 'Үлкен Алматы көлі аймағы үстіндегі биіктау серуені: құрғақ жоталар, обсерватория көріністері және альпілік ауқымды тез сезіну.', 43.05500000, 76.96200000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','ridge','observatory-view','hiking']::text[]),
    ('KZ', 'KZT', 'molodezhny-peak-approach-trail', 'almaty', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Подходная тропа к пику Молодежный', 'Molodezhny Peak Approach Trail', 'Молодежный шыңына жақындау соқпағы', 'Спортивный маршрут из высокогорной зоны к каменным осыпям, снежным видам и гребням для подготовленного дневного треккинга.', 'A sporty route from the high mountain zone toward scree slopes, snowline views and ridges for prepared day trekking.', 'Биіктау аймағынан тас үйінділерге, қар сызығы көріністеріне және дайын күндік треккингке арналған жоталарға апаратын спорттық бағыт.', 43.06400000, 77.10200000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','summit-approach','trekking']::text[]),
    ('KZ', 'KZT', 'karlytau-glacier-view-trail', 'almaty', 'NATURE', 1000, 8, 'HOURS', 4.8, 'Тропа к виду на ледник Карлытау', 'Karlytau Glacier View Trail', 'Қарлытау мұздығы көрінісіне соқпақ', 'Высотный выход в альпийском узле Алматы к моренам, холодным ручьям и панорамам ледниковой зоны для опытных гостей.', 'A high mountain outing in Almaty alpine node toward moraines, cold streams and glacier-area panoramas for experienced visitors.', 'Алматының альпілік торабындағы биіктау бағыты: мореналар, салқын бұлақтар және тәжірибелі қонақтарға арналған мұздық аймағы панорамалары.', 43.07000000, 77.11600000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','glacier-view','trekking']::text[]),
    ('KZ', 'KZT', 'shymbulak-talgar-pass-view-walk', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Прогулка к виду на Талгарский перевал от Шымбулака', 'Shymbulak Talgar Pass View Walk', 'Шымбұлақтан Талғар асуы көрінісіне серуен', 'Доступная горная прогулка от верхней курортной зоны к открытым видам на седловину, снежные склоны и Малую Алматинку.', 'An accessible mountain walk from the upper resort area toward open views of the pass saddle, snow slopes and Little Almatinka.', 'Курорттың жоғарғы аймағынан асу еріне, қарлы беткейлерге және Кіші Алматыға ашық көріністерге апаратын қолжетімді тау серуені.', 43.11600000, 77.10600000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','shymbulak','pass-view','walking']::text[]),
    ('KZ', 'KZT', 'turgen-wild-apple-ridge-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Тропа яблоневых склонов Тургеня', 'Turgen Wild Apple Ridge Trail', 'Түрген жабайы алма жотасы соқпағы', 'Маршрут восточнее Алматы по яблоневому поясу, сухим склонам и видовым ребрам, где горный день получается тише популярных направлений.', 'A route east of Almaty through wild apple slopes, dry hillsides and scenic ribs, giving a quieter mountain day than the busiest directions.', 'Алматының шығысындағы жабайы алма беткейлері, құрғақ қапталдар және көріністі қырлар арқылы өтетін, танымал бағыттарға қарағанда тынышырақ тау күні.', 43.29000000, 77.76000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','wild-apple','ridge','hiking']::text[]),
    ('KZ', 'KZT', 'kaskelen-upper-meadows-trail', 'almaty', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа верхних лугов Каскелена', 'Kaskelen Upper Meadows Trail', 'Қаскелең жоғарғы шалғындары соқпағы', 'Предгорный маршрут к зеленым лугам, ручьям и спокойным обзорным точкам западнее Алматы без сложной технической части.', 'A foothill route to green meadows, streams and calm viewpoints west of Almaty without difficult technical sections.', 'Алматының батысындағы жасыл шалғындарға, бұлақтарға және тыныш көрініс нүктелеріне апаратын техникалық күрделі емес тау етегі бағыты.', 43.09500000, 76.61000000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','meadows','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'upper-kora-cascades-trail', 'taldykorgan', 'NATURE', 0, 7, 'HOURS', 4.8, 'Тропа верхних каскадов Коры', 'Upper Kora Cascades Trail', 'Қора жоғарғы каскадтары соқпағы', 'Дальняя жетысуская тропа вдоль бурной реки к каскадам, хвойным склонам и более дикому сценарию горного дня.', 'A remote Zhetysu trail along a fast river toward cascades, conifer slopes and a wilder mountain-day scenario.', 'Жетісудағы алыстау бағыт: ағынды өзен бойымен каскадтарға, қылқанды беткейлерге және жабайырақ тау күніне апарады.', 44.90000000, 79.43000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','river','cascades','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'zhetysu-dzungarian-fir-belt-trail', 'taldykorgan', 'NATURE', 0, 6, 'HOURS', 4.7, 'Тропа елового пояса Жетысу', 'Zhetysu Dzungarian Fir Belt Trail', 'Жетісу Жоңғар шырша белдеуі соқпағы', 'Горный маршрут Жетысу к прохладному лесному поясу, родникам и открытым полянам, который хорошо расширяет выбор из Талдыкоргана.', 'A Zhetysu mountain route toward a cool forest belt, springs and open glades, widening the outdoor choice from Taldykorgan.', 'Жетісудың салқын орман белдеуіне, бұлақтарға және ашық алаңқайларға апаратын тау бағыты, Талдықорғаннан outdoor таңдауын кеңейтеді.', 45.06000000, 78.72000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','fir-forest','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'ridder-stone-bowl-forest-trail', 'ust-kamenogorsk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Лесная тропа Каменной чаши Риддера', 'Ridder Stone Bowl Forest Trail', 'Риддер Тас тостаған орман соқпағы', 'Алтайская прогулка из района Риддера через темную тайгу, скальные чаши и снежные поляны, хорошо подходящая для активного полудня.', 'An Altai walk from the Ridder area through dark taiga, stone bowls and snowy glades, well suited for an active half day.', 'Риддер маңынан қара тайга, тас тостағандар және қарлы алаңқайлар арқылы өтетін, белсенді жарты күнге лайық Алтай серуені.', 50.37500000, 83.57500000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','ridder','forest','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'west-altai-cedar-loop', 'ust-kamenogorsk', 'NATURE', 0, 6, 'HOURS', 4.8, 'Кедровая петля Западного Алтая', 'West Altai Cedar Loop', 'Батыс Алтай самырсын ілмегі', 'Лесной маршрут Восточного Казахстана по кедровым участкам, ручьям и влажным долинам для спокойного таежного треккинга.', 'An East Kazakhstan forest route through cedar sections, streams and humid valleys for calm taiga trekking.', 'Шығыс Қазақстандағы самырсынды бөліктер, бұлақтар және ылғалды аңғарлар арқылы өтетін тыныш тайга треккингі.', 50.33000000, 84.15000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','cedar','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'sibins-hidden-lake-loop', 'semey', 'NATURE', 0, 4, 'HOURS', 4.6, 'Петля скрытого озера Сибин', 'Sibins Hidden Lake Loop', 'Сібе жасырын көлі ілмегі', 'Короткий восточноказахстанский маршрут между гранитными берегами, соснами и прозрачной водой для тихого летнего outdoor-дня.', 'A short East Kazakhstan route between granite shores, pines and clear water for a quiet summer outdoor day.', 'Шығыс Қазақстандағы гранит жағалар, қарағайлар және мөлдір су арасындағы тыныш жазғы outdoor күнге арналған қысқа бағыт.', 49.43000000, 82.62000000, 'Katon-Karagay_National_Park.jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','lake-loop','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kiin-kerish-mars-valley-walk', 'semey', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка марсианской долины Киин-Кериш', 'Kiin-Kerish Mars Valley Walk', 'Қиын-Керіш марс аңғары серуені', 'Пеший маршрут по цветным глинам и сухим гребням восточной пустынной зоны, где особенно важны ранний старт и запас воды.', 'A walking route across colored clays and dry ridges in the eastern desert zone, where an early start and enough water matter most.', 'Шығыс шөл аймағындағы түрлі түсті саздар мен құрғақ жоталар арқылы өтетін жаяу бағыт, ерте шығу мен жеткілікті су маңызды.', 48.30200000, 84.12000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','clay-hills','desert','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'shaitankol-ridge-walk', 'karaganda', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Жотная прогулка Шайтанколь', 'Shaitankol Ridge Walk', 'Шайтанкөл жотасы серуені', 'Лесная тропа Сарыарки к каменным гребням и тихому озерному виду, дополняющая маршруты вокруг Каркаралы.', 'A Saryarka forest trail toward rocky ridges and a quiet lake view, complementing routes around the Karkaraly area.', 'Сарыарқаның тасты жоталарға және тыныш көл көрінісіне апаратын орманды соқпағы, Қарқаралы маңындағы бағыттарды толықтырады.', 49.40600000, 75.46200000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','saryarka','forest','ridge','hiking']::text[]),
    ('KZ', 'KZT', 'kyzylarai-cedar-valley-walk', 'karaganda', 'NATURE', 0, 5, 'HOURS', 4.6, 'Прогулка кедровой долины Кызыларай', 'Kyzylarai Cedar Valley Walk', 'Қызыларай самырсын аңғары серуені', 'Спокойный маршрут по горно-степной долине Центрального Казахстана с гранитными склонами, хвойными островками и широким горизонтом.', 'A calm route through a central Kazakhstan mountain-steppe valley with granite slopes, conifer islands and a wide horizon.', 'Орталық Қазақстандағы гранит беткейлері, қылқанды аралдары және кең көкжиегі бар тау-дала аңғарымен өтетін тыныш бағыт.', 48.80500000, 75.66000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda','balkhash']::text[], ARRAY['karaganda','balkhash']::text[], ARRAY['kazakhstan','central-kazakhstan','kyzylarai','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'buiratau-stone-ridge-walk', 'astana', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Прогулка каменной гряды Буйратау', 'Buiratau Stone Ridge Walk', 'Бұйратау тас жотасы серуені', 'Степной выезд из Астаны к невысоким скалам, сухим склонам и панораме северной Сарыарки без тяжелой логистики.', 'A steppe escape from Astana toward low rocks, dry slopes and a northern Saryarka panorama without heavy logistics.', 'Астанадан аласа жартастарға, құрғақ беткейлерге және солтүстік Сарыарқа панорамасына апаратын жеңіл дала бағыты.', 51.58000000, 73.40500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['astana']::text[], ARRAY['astana']::text[], ARRAY['kazakhstan','akmola-region','stone-ridge','hiking']::text[]),
    ('KZ', 'KZT', 'ulytau-edige-peak-trail', 'zhezkazgan', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа на пик Едиге в Улытау', 'Ulytau Edige Peak Trail', 'Ұлытау Едіге шыңы соқпағы', 'Горная тропа исторического ядра страны к каменному подъему, степным видам и маршруту, который хорошо сочетается с культурными остановками.', 'A mountain trail in the country historical core toward a rocky ascent, steppe views and a route that pairs well with cultural stops.', 'Елдің тарихи өзегіндегі тасты көтерілуге, дала көріністеріне және мәдени аялдамалармен жақсы үйлесетін бағытқа апаратын тау соқпағы.', 48.65700000, 67.03200000, 'Dzhuchi khan mausoleum.jpg', ARRAY['zhezkazgan']::text[], ARRAY['zhezkazgan']::text[], ARRAY['kazakhstan','ulytau','summit','history','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'naurzum-pine-lake-birding-trail', 'kostanay', 'NATURE', 0, 4, 'HOURS', 4.7, 'Орнитологическая тропа сосновых озер Наурзума', 'Naurzum Pine Lake Birding Trail', 'Наурызым қарағайлы көлдер құсбақылау соқпағы', 'Северный маршрут Костанайской области по сосновым участкам, озерным берегам и точкам наблюдения за птицами.', 'A northern Kostanay Region route through pine sections, lake shores and birdwatching points.', 'Қостанай облысының солтүстігіндегі қарағайлы бөліктер, көл жағалары және құс бақылау нүктелері арқылы өтетін бағыт.', 51.44000000, 64.64000000, 'Borovoe1.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','birdwatching','lakes','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'zhygylgan-rim-walk', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.7, 'Прогулка по краю Жыгылгана', 'Zhygylgan Rim Walk', 'Жығылған жиегімен серуен', 'Мангистауский маршрут по краю провальной формы рельефа с сухими балками, каменными стенами и видом на Каспийский простор.', 'A Mangystau route along the rim of a collapsed landform with dry gullies, stone walls and views toward the Caspian expanse.', 'Маңғыстаудағы опырылған бедер жиегімен өтетін бағыт: құрғақ сайлар, тас қабырғалар және Каспий кеңістігіне көрініс.', 44.51500000, 51.94500000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','rim-walk','caspian','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'tuzbair-sunrise-cliffs-trail', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа рассветных обрывов Тузбаира', 'Tuzbair Sunrise Cliffs Trail', 'Тұзбайыр таңғы жартастары соқпағы', 'Ранний маршрут по белым обрывам плато, сухим ложбинам и мягкому свету Мангистау для фото и легкого хайкинга.', 'An early route across pale plateau cliffs, dry hollows and soft Mangystau light for photos and light hiking.', 'Маңғыстаудың ақшыл үстірт жартастары, құрғақ ойпаңдары және жұмсақ жарығы арқылы өтетін фотоға және жеңіл хайкингке арналған ерте бағыт.', 44.01800000, 53.02500000, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','cliffs','sunrise','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'torysh-stone-field-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.7, 'Прогулка каменного поля Торыш', 'Torysh Stone Field Walk', 'Торыш тас алаңы серуені', 'Короткий маршрут среди шаровых каменных форм, сухой степи и открытого неба Мангистау для спокойной остановки в дороге.', 'A short route among spherical stone forms, dry steppe and open Mangystau sky for a calm road-trip stop.', 'Маңғыстаудың шар тәрізді тас пішіндері, құрғақ даласы және ашық аспаны арасындағы жол үстіндегі тыныш аялдамаға арналған қысқа бағыт.', 44.23600000, 51.61000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','stone-field','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'inder-salt-dome-view-walk', 'atyrau', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка к соляному куполу Индер', 'Inder Salt Dome View Walk', 'Индер тұз күмбезі көрінісіне серуен', 'Западноказахстанская прогулка к соляным формам, открытой степи и необычному минеральному ландшафту в формате короткого выезда.', 'A western Kazakhstan walk toward salt forms, open steppe and an unusual mineral landscape in a short-trip format.', 'Батыс Қазақстандағы тұзды пішіндерге, ашық далаға және ерекше минералды ландшафтқа апаратын қысқа сапар форматы.', 48.54000000, 51.73000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['atyrau']::text[], ARRAY['atyrau']::text[], ARRAY['kazakhstan','atyrau-region','salt-dome','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kargaly-reservoir-ridge-walk', 'aktobe', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка по гряде Каргалинского водохранилища', 'Kargaly Reservoir Ridge Walk', 'Қарғалы су қоймасы жотасы серуені', 'Легкий выезд из Актобе к водному зеркалу, низким грядам и ветреным степным видам для короткого outdoor-плана.', 'An easy trip from Aktobe to reservoir views, low ridges and windy steppe scenery for a short outdoor plan.', 'Ақтөбеден су айдынына, аласа жоталарға және желді дала көріністеріне апаратын қысқа outdoor жоспарға арналған жеңіл бағыт.', 50.08300000, 57.51200000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','reservoir','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'chagan-riverbank-forest-walk', 'oral', 'NATURE', 0, 2, 'HOURS', 4.4, 'Лесная прогулка берега Чагана', 'Chagan Riverbank Forest Walk', 'Шаған жағалауы орман серуені', 'Короткая природная прогулка у Орала по пойменным деревьям, воде и спокойному ритму западноказахстанского города.', 'A short nature walk near Oral through floodplain trees, water views and a calm western Kazakhstan city rhythm.', 'Орал маңындағы жайылма ағаштар, су көріністері және Батыс Қазақстан қаласының тыныш ырғағы арқылы өтетін қысқа табиғи серуен.', 51.21800000, 51.35000000, 'Atyrau footbridge across Ural River.jpg', ARRAY['oral']::text[], ARRAY['oral']::text[], ARRAY['kazakhstan','west-kazakhstan','riverbank','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'tulkibas-juniper-foothill-trail', 'shymkent', 'NATURE', 0, 5, 'HOURS', 4.6, 'Арчовая предгорная тропа Тюлькубаса', 'Tulkibas Juniper Foothill Trail', 'Түлкібас аршалы тау етегі соқпағы', 'Южный маршрут к арчовым склонам, сухим балкам и весенним цветущим участкам недалеко от Шымкента.', 'A southern route toward juniper slopes, dry gullies and spring flowering sections not far from Shymkent.', 'Шымкенттен алыс емес аршалы беткейлерге, құрғақ сайларға және көктемгі гүлдейтін бөліктерге апаратын оңтүстік бағыт.', 42.48900000, 70.27000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent']::text[], ARRAY['shymkent']::text[], ARRAY['kazakhstan','turkestan-region','juniper','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'kazygurt-mountain-pilgrim-trail', 'shymkent', 'NATURE', 0, 4, 'HOURS', 4.6, 'Паломническая тропа горы Казыгурт', 'Kazygurt Mountain Pilgrim Trail', 'Қазығұрт тауы зиярат соқпағы', 'Маршрут к южной горе с культурными легендами, открытыми склонами и мягким набором высоты для полудневной поездки.', 'A route to a southern mountain with cultural legends, open slopes and gentle elevation gain for a half-day trip.', 'Мәдени аңыздары, ашық беткейлері және жұмсақ биіктік жинауы бар оңтүстік тауға апаратын жарты күндік бағыт.', 41.76600000, 69.95000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','turkestan']::text[], ARRAY['shymkent','turkestan']::text[], ARRAY['kazakhstan','south-kazakhstan','mountain','pilgrim','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'karatau-arystanbab-steppe-ridge-walk', 'turkestan', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная гряда Каратау у Арыстанбаба', 'Karatau Arystanbab Steppe Ridge Walk', 'Арыстанбаб маңындағы Қаратау дала жотасы серуені', 'Сухой маршрут Туркестанской области по низким грядам, каменистым тропам и ландшафту, который соединяет природу и паломнический контекст.', 'A dry Turkestan Region route across low ridges, stony paths and a landscape that connects nature with pilgrim context.', 'Түркістан облысындағы аласа жоталар, тасты жолдар және табиғатты зиярат контекстімен байланыстыратын ландшафт арқылы өтетін құрғақ бағыт.', 42.85500000, 68.26000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['turkestan','shymkent']::text[], ARRAY['turkestan','shymkent']::text[], ARRAY['kazakhstan','karatau','steppe-ridge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'merke-upper-pasture-trail', 'taraz', 'NATURE', 0, 5, 'HOURS', 4.6, 'Тропа верхних пастбищ Мерке', 'Merke Upper Pasture Trail', 'Меркі жоғарғы жайлауы соқпағы', 'Маршрут из Тараза к горным пастбищам, ручьям и прохладному западнотяньшанскому рельефу без перегруженных туристических точек.', 'A route from Taraz toward mountain pastures, streams and cool Western Tian Shan terrain without overloaded tourist stops.', 'Тараздан тау жайылымдарына, бұлақтарға және турист көп жиналмайтын салқын Батыс Тянь-Шань бедеріне апаратын бағыт.', 42.84400000, 73.16500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz']::text[], ARRAY['taraz']::text[], ARRAY['kazakhstan','zhambyl-region','pasture','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_hidden_outdoor_routes_resolved_places AS
SELECT
    ('104d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-hidden-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_hidden_outdoor_routes_places;

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
FROM seed_kazakhstan_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_hidden_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_hidden_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_hidden_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_hidden_outdoor_routes_places;
