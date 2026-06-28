-- Gap-filling route-level hiking/day-hike seed for Tajikistan.
-- These rows add concrete outdoor route cards for Tajikistan hubs that already had broad landmarks.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_tajikistan_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_tajikistan_gap_hiking_places;

CREATE TEMP TABLE seed_tajikistan_gap_hiking_places (
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

INSERT INTO seed_tajikistan_gap_hiking_places (
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
    ('TJ', 'TJS', 'mogol-tau-foothill-trail', 'khujand', 'NATURE', 0, 4, 'HOURS', 4.6, 'Предгорная тропа Могол-Тау', 'Mogol-Tau Foothill Trail', 'Моғол-Тау тау етегі соқпағы', 'Короткий выезд из Худжанда к сухим предгорьям, каменным склонам и панорамам Согдийской долины.', 'A short escape from Khujand toward dry foothills, rocky slopes and Sughd valley panoramas.', 'Худжандтан құрғақ тау етектеріне, тасты беткейлерге және Соғды аңғарының панорамасына апаратын қысқа бағыт.', 40.31200000, 69.70500000, 'Khujand Museum.jpg', ARRAY['khujand']::text[], ARRAY['khujand']::text[], ARRAY['tajikistan','sughd','foothills','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'hisor-range-foothill-trail', 'hisor', 'NATURE', 0, 4, 'HOURS', 4.6, 'Предгорная тропа Гиссарского хребта', 'Hisor Range Foothill Trail', 'Ҳисор жотасы тау етегі соқпағы', 'Маршрут из Гиссара к открытым склонам и сельским видам, добавляющий природный сценарий к историческому выезду.', 'A route from Hisor toward open slopes and rural views, adding a nature plan to the historical day trip.', 'Гиссардан ашық беткейлерге және ауылдық көріністерге апаратын бағыт, тарихи сапарға табиғи сценарий қосады.', 38.57500000, 68.51500000, 'Dushanbe Tajikistan.jpg', ARRAY['hisor']::text[], ARRAY['dushanbe','hisor']::text[], ARRAY['tajikistan','hisor-range','foothills','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'safed-dara-ridge-trail', 'safed-dara', 'NATURE', 30, 5, 'HOURS', 4.7, 'Тропа хребта Сафед-Дара', 'Safed-Dara Ridge Trail', 'Сафед-Дара жотасы соқпағы', 'Горный маршрут над курортной долиной к обзорным участкам, снеговым полям в сезон и прохладному рельефу Варзобского направления.', 'A mountain route above the resort valley toward viewpoints, seasonal snowfields and cool terrain along the Varzob corridor.', 'Курорттық аңғар үстіндегі көрініс нүктелеріне, маусымдық қар алаңдарына және Варзоб бағытының салқын бедеріне апаратын тау бағыты.', 38.85500000, 68.93600000, 'Safed Dara Tajikistan.jpg', ARRAY['safed-dara','varzob']::text[], ARRAY['dushanbe','safed-dara']::text[], ARRAY['tajikistan','varzob','ridge','trekking']::text[]),
    ('TJ', 'TJS', 'nurek-ridge-view-trail', 'norak', 'NATURE', 0, 4, 'HOURS', 4.6, 'Смотровая тропа Нурекского гребня', 'Nurek Ridge View Trail', 'Нүрек жотасы көрініс соқпағы', 'Короткий маршрут над водной долиной с сухими склонами, ветром и широкими видами на юго-восток от Душанбе.', 'A short route above the water valley with dry slopes, wind and wide views southeast of Dushanbe.', 'Сулы аңғар үстіндегі құрғақ беткейлері, желі және Душанбеден оңтүстік-шығысқа кең көріністері бар қысқа бағыт.', 38.39500000, 69.35700000, 'Nurek Dam Tajikistan.jpg', ARRAY['norak']::text[], ARRAY['dushanbe','norak']::text[], ARRAY['tajikistan','khatlon','ridge','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'qayraqqum-north-shore-trail', 'guliston-qayraqqum', 'NATURE', 0, 3, 'HOURS', 4.5, 'Тропа северного берега Кайраккума', 'Qayraqqum North Shore Trail', 'Қайраққұм солтүстік жағалау соқпағы', 'Легкая прогулка у воды с камышами, ветром и открытым горизонтом, хорошо подходящая для отдыха после Худжанда.', 'An easy waterside walk with reeds, wind and an open horizon, pairing well with time after Khujand.', 'Су бойындағы қамысы, желі және ашық көкжиегі бар жеңіл серуен, Худжандтан кейінгі демалысқа лайық.', 40.31900000, 69.88000000, 'Kayrakkum Reservoir Tajikistan.jpg', ARRAY['guliston-qayraqqum']::text[], ARRAY['khujand','guliston-qayraqqum']::text[], ARRAY['tajikistan','sughd','shoreline','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'mug-teppa-ridge-walk', 'istaravshan', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка по гребню Муг-Теппа', 'Mug Teppa Ridge Walk', 'Муг-Теппа жотасы серуені', 'Небольшой маршрут по возвышенности Истарвшана с городскими видами, сухими тропами и шелковым контекстом региона.', 'A compact route on Istaravshan high ground with city views, dry paths and Silk Road context.', 'Истаравшан биігінде қала көріністері, құрғақ соқпақтар және өңірдің Жібек жолы контексті бар шағын бағыт.', 39.91600000, 69.00900000, 'Istaravshan Tajikistan.jpg', ARRAY['istaravshan']::text[], ARRAY['khujand','istaravshan']::text[], ARRAY['tajikistan','sughd','ridge','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'panjakent-zeravshan-bend-walk', 'panjakent', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка изгиба Зеравшана у Пенджикента', 'Panjakent Zeravshan Bend Walk', 'Пенджикент Зарафшан иіні серуені', 'Природная прогулка у Пенджикента вдоль речных террас, садов и открытых видов Зеравшанской долины.', 'A nature walk near Panjakent along river terraces, gardens and open views of the Zeravshan valley.', 'Пенджикент маңындағы өзен террасалары, бақтар және Зарафшан аңғарының ашық көріністері бойымен өтетін табиғи серуен.', 39.50000000, 67.64000000, 'Panjakent Museum.jpg', ARRAY['panjakent']::text[], ARRAY['panjakent']::text[], ARRAY['tajikistan','zeravshan','river','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'zeravshan-river-terrace-trail', 'sarazm', 'NATURE', 0, 3, 'HOURS', 4.5, 'Тропа речных террас Зеравшана', 'Zeravshan River Terrace Trail', 'Зарафшан өзені террасалары соқпағы', 'Пеший маршрут у Саразма по речным террасам, сухим полям и мягкому ландшафту между археологией и горами.', 'A walking route near Sarazm across river terraces, dry fields and gentle terrain between archaeology and mountains.', 'Саразм маңындағы өзен террасалары, құрғақ алқаптар және археология мен таулар арасындағы жұмсақ ландшафт арқылы өтетін бағыт.', 39.52400000, 67.47000000, 'Sarazm Tajikistan.jpg', ARRAY['sarazm','panjakent']::text[], ARRAY['panjakent','sarazm']::text[], ARRAY['tajikistan','zeravshan','terrace','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'panjrud-valley-rudaki-trail', 'panjrud', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа долины Панджруда', 'Panjrud Valley Rudaki Trail', 'Панжруд аңғары Рудаки соқпағы', 'Маршрут по зеленой долине Панджруда с сельскими видами, водой и литературным контекстом Зеравшанского региона.', 'A route through green Panjrud valley with rural views, water and literary context of the Zeravshan region.', 'Жасыл Панжруд аңғары арқылы өтетін бағыт: ауыл көріністері, су және Зарафшан өңірінің әдеби контексті.', 39.44800000, 67.90500000, 'Panjakent Museum.jpg', ARRAY['panjrud']::text[], ARRAY['panjakent','panjrud']::text[], ARRAY['tajikistan','zeravshan','valley','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'haft-kul-lake-to-lake-trail', 'seven-lakes', 'NATURE', 30, 7, 'HOURS', 4.9, 'Тропа от озера к озеру Хафт-Куля', 'Haft Kul Lake-to-Lake Trail', 'Хафт-Күл көлден көлге соқпағы', 'Маршрут между горными озерами с набором высоты, цветной водой и сильным дневным trekking-сценарием из Пенджикента.', 'A route between mountain lakes with elevation gain, colored water and a strong day-trekking scenario from Panjakent.', 'Таулы көлдер арасындағы биіктік жинайтын, түрлі түсті суы және Пенджикенттен күшті day-trekking сценарийі бар бағыт.', 39.24300000, 67.83000000, 'Seven Lakes Tajikistan.jpg', ARRAY['seven-lakes','fann-mountains']::text[], ARRAY['panjakent','seven-lakes']::text[], ARRAY['tajikistan','fann','lakes','trekking']::text[]),
    ('TJ', 'TJS', 'artuch-basin-trail', 'fann-mountains', 'NATURE', 30, 6, 'HOURS', 4.8, 'Тропа Артучского бассейна', 'Artuch Basin Trail', 'Артуч алабы соқпағы', 'Фанский маршрут по моренным долинам и альпийским лугам, который дает конкретную trail-карточку вместо общей горной зоны.', 'A Fann route through moraine valleys and alpine meadows, giving a concrete trail card instead of only a broad mountain area.', 'Мореналық аңғарлар мен альпілік шалғындар арқылы өтетін Фан бағыты, жалпы тау аймағынан бөлек нақты trail-карточка береді.', 39.24500000, 68.17000000, 'Seven Lakes Tajikistan.jpg', ARRAY['fann-mountains']::text[], ARRAY['panjakent','fann-mountains']::text[], ARRAY['tajikistan','fann','basin','trekking']::text[]),
    ('TJ', 'TJS', 'chukurak-pass-view-trail', 'kulikalon', 'NATURE', 30, 6, 'HOURS', 4.8, 'Смотровая тропа перевала Чукурак', 'Chukurak Pass View Trail', 'Чукурак асуы көрініс соқпағы', 'Маршрут к перевальному виду над Фанскими долинами, где каменные склоны и пастбища дают понятную горную цель.', 'A route toward a pass viewpoint above Fann valleys, where rocky slopes and pastures create a clear mountain objective.', 'Фан аңғарлары үстіндегі асу көрінісіне апаратын бағыт: тасты беткейлер мен жайылымдар айқын тау мақсатын береді.', 39.26500000, 68.14500000, 'Seven Lakes Tajikistan.jpg', ARRAY['kulikalon','fann-mountains']::text[], ARRAY['panjakent','fann-mountains']::text[], ARRAY['tajikistan','fann','pass','trekking']::text[]),
    ('TJ', 'TJS', 'alauddin-mutnye-lakes-trail', 'alauddin', 'NATURE', 30, 7, 'HOURS', 4.9, 'Тропа от Алаудина к Мутным озерам', 'Alauddin to Mutnye Lakes Trail', 'Алаудиннен Мутные көлдеріне соқпақ', 'Высокогорный маршрут Фанских гор с моренами, бирюзовой водой и более спортивным рельефом для подготовленных гостей.', 'A high Fann route with moraines, turquoise water and sportier terrain for prepared visitors.', 'Мореналары, көгілдір суы және дайын саяхатшыларға арналған спорттық бедері бар Фан тауларының биік бағыты.', 39.28600000, 68.27200000, 'Seven Lakes Tajikistan.jpg', ARRAY['alauddin','fann-mountains']::text[], ARRAY['panjakent','fann-mountains']::text[], ARRAY['tajikistan','fann','alpine-lakes','trekking']::text[]),
    ('TJ', 'TJS', 'snake-lake-waterfall-trail', 'iskanderkul', 'NATURE', 30, 4, 'HOURS', 4.8, 'Тропа Змеиного озера и водопада', 'Snake Lake and Waterfall Trail', 'Жылан көлі мен сарқырама соқпағы', 'Короткий маршрут в районе Искандеркуля к тихому озеру, водопадному участку и скальным видам для насыщенного полудня.', 'A short route in the Iskanderkul area toward a quiet lake, waterfall section and rock views for a rich half-day.', 'Искандеркөл маңындағы тыныш көлге, сарқырама бөлігіне және жартасты көріністерге апаратын қысқа бағыт.', 39.08100000, 68.38500000, 'Iskanderkul Tajikistan.jpg', ARRAY['iskanderkul','fann-mountains']::text[], ARRAY['dushanbe','iskanderkul']::text[], ARRAY['tajikistan','fann','waterfall','hiking']::text[]),
    ('TJ', 'TJS', 'garm-chashma-ridge-view-trail', 'garm-chashma', 'NATURE', 0, 3, 'HOURS', 4.6, 'Смотровая тропа гребня Гарм-Чашмы', 'Garm Chashma Ridge View Trail', 'Гарм-Чашма жотасы көрініс соқпағы', 'Короткий маршрут над долиной с минеральными источниками, сухими гребнями и видом на памирские склоны.', 'A short route above the mineral-spring valley with dry ridges and Pamir slope views.', 'Минералды бұлақтар аңғары үстіндегі құрғақ жоталар мен Памир беткейлеріне көрініс беретін қысқа бағыт.', 37.04500000, 71.53000000, 'Garm Chashma Tajikistan.jpg', ARRAY['garm-chashma']::text[], ARRAY['khorog','garm-chashma']::text[], ARRAY['tajikistan','pamir','ridge','gbao-permit','walking']::text[]),
    ('TJ', 'TJS', 'jelondy-valley-walk', 'jelondy', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка долины Джелонды', 'Jelondy Valley Walk', 'Желонды аңғары серуені', 'Спокойная памирская прогулка у дороги Хорог - Мургаб с суровыми склонами, прозрачным воздухом и короткой остановкой между переездами.', 'A calm Pamir walk along the Khorog-Murghab road with stark slopes, clear air and a short stop between drives.', 'Хорог - Мурғаб жолындағы қатал беткейлері, мөлдір ауасы және жол арасындағы қысқа аялдамасы бар тыныш Памир серуені.', 37.69200000, 72.58500000, 'Pamir Highway Tajikistan.jpg', ARRAY['jelondy']::text[], ARRAY['khorog','murghab','jelondy']::text[], ARRAY['tajikistan','pamir','valley','gbao-permit','walking']::text[]),
    ('TJ', 'TJS', 'yamchun-bibi-fatima-trail', 'yamchun', 'NATURE', 0, 3, 'HOURS', 4.8, 'Тропа Ямчун - Биби Фатима', 'Yamchun to Bibi Fatima Trail', 'Ямчуннан Биби Фатимаға соқпақ', 'Ваханский маршрут по сухому склону с видами на долину, каменными стенами и переходом к горячим источникам.', 'A Wakhan route across a dry slope with valley views, stone walls and a walk toward hot springs.', 'Вахандағы құрғақ беткеймен өтетін бағыт: аңғар көріністері, тас қабырғалар және ыстық бұлақтарға жаяу өту.', 36.96600000, 72.22000000, 'Wakhan Valley Tajikistan.jpg', ARRAY['yamchun','wakhan-valley']::text[], ARRAY['ishkashim','wakhan-valley','yamchun']::text[], ARRAY['tajikistan','wakhan','border-zone','gbao-permit','walking']::text[]),
    ('TJ', 'TJS', 'vrang-wakhan-terrace-trail', 'vrang', 'NATURE', 0, 3, 'HOURS', 4.6, 'Ваханская террасная тропа Вранга', 'Vrang Wakhan Terrace Trail', 'Вранг Вахан терраса соқпағы', 'Маршрут по террасам Ваханской долины с видом на реку Пяндж, сухие поля и горный горизонт Афганистана.', 'A route across Wakhan valley terraces with views of the Panj River, dry fields and the Afghan mountain horizon.', 'Вахан аңғары террасалары арқылы өтетін бағыт: Пяндж өзені, құрғақ алқаптар және Ауғанстан тауларының көкжиегі көрінеді.', 36.97300000, 72.49500000, 'Wakhan Valley Tajikistan.jpg', ARRAY['vrang','wakhan-valley']::text[], ARRAY['ishkashim','wakhan-valley','vrang']::text[], ARRAY['tajikistan','wakhan','terrace','border-zone','walking']::text[]),
    ('TJ', 'TJS', 'langar-ridge-petroglyph-trail', 'langar', 'NATURE', 0, 4, 'HOURS', 4.7, 'Петроглифная тропа гребня Лангара', 'Langar Ridge Petroglyph Trail', 'Лангар жотасы петроглиф соқпағы', 'Подъем над Лангаром к каменным плитам и видам на место встречи Памира и Гиндукуша.', 'A climb above Langar toward rock slabs and views where the Pamir meets the Hindu Kush.', 'Лангар үстінен тас тақталарға және Памир мен Гиндукуш түйісетін көріністерге көтерілетін бағыт.', 37.00200000, 72.66500000, 'Wakhan Valley Tajikistan.jpg', ARRAY['langar','wakhan-valley']::text[], ARRAY['ishkashim','wakhan-valley','langar']::text[], ARRAY['tajikistan','wakhan','petroglyph-route','border-zone','hiking']::text[]),
    ('TJ', 'TJS', 'bulunkul-yashilkul-shore-trail', 'bulunkul', 'NATURE', 0, 5, 'HOURS', 4.8, 'Береговая тропа Булункуль - Яшилькуль', 'Bulunkul-Yashilkul Shore Trail', 'Бұланкөл - Яшылкөл жағалау соқпағы', 'Высокогорная прогулка между памирскими берегами, болотистыми участками и суровым горизонтом Восточного Памира.', 'A highland walk between Pamir shores, marshy sections and the stark Eastern Pamir horizon.', 'Памир жағалаулары, батпақты бөліктер және Шығыс Памирдің қатал көкжиегі арасындағы биік таулы серуен.', 37.72000000, 72.96000000, 'Yashilkul Tajikistan.jpg', ARRAY['bulunkul']::text[], ARRAY['khorog','murghab','bulunkul']::text[], ARRAY['tajikistan','pamir','shoreline','gbao-permit','trekking']::text[]),
    ('TJ', 'TJS', 'karakul-shore-ridge-trail', 'karakul', 'NATURE', 0, 4, 'HOURS', 4.8, 'Береговая гряда Каракуля', 'Karakul Shore Ridge Trail', 'Қаракөл жағалау жотасы соқпағы', 'Маршрут по высокому берегу Восточного Памира с солончаками, ветром и видом на бескрайнее плато.', 'A route along the high Eastern Pamir shore with salt flats, wind and views across the vast plateau.', 'Шығыс Памирдің биік жағалауымен өтетін бағыт: тұзды жазықтар, жел және шексіз үстірт көрінісі.', 39.02600000, 73.46000000, 'Pamir Highway Tajikistan.jpg', ARRAY['karakul']::text[], ARRAY['murghab','karakul']::text[], ARRAY['tajikistan','pamir','shoreline','gbao-permit','walking']::text[]),
    ('TJ', 'TJS', 'bokhtar-tugai-nature-walk', 'bokhtar', 'NATURE', 0, 3, 'HOURS', 4.4, 'Тугайная прогулка Бохтара', 'Bokhtar Tugai Nature Walk', 'Бохтар тоғай табиғи серуені', 'Короткая прогулка к пойменной зелени Вахшской долины, где южный город получает простую outdoor-карточку.', 'A short walk to floodplain greenery in the Vakhsh valley, giving the southern city a simple outdoor card.', 'Вахш аңғарындағы жайылма жасылдығына қысқа серуен, оңтүстік қалаға қарапайым outdoor карточка береді.', 37.84800000, 68.79200000, 'Bokhtar Tajikistan.jpg', ARRAY['bokhtar']::text[], ARRAY['bokhtar']::text[], ARRAY['tajikistan','khatlon','tugai','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'vakhsh-river-floodplain-trail', 'vakhsh', 'NATURE', 0, 3, 'HOURS', 4.4, 'Пойменная тропа реки Вахш', 'Vakhsh River Floodplain Trail', 'Вахш өзені жайылма соқпағы', 'Маршрут по речной пойме с деревьями, каналами и сельским ландшафтом рядом с Бохтаром.', 'A route through river floodplain with trees, canals and rural landscape near Bokhtar.', 'Бохтар маңындағы ағаштары, каналдары және ауылдық ландшафты бар өзен жайылмасы арқылы өтетін бағыт.', 37.79000000, 68.94500000, 'Bokhtar Tajikistan.jpg', ARRAY['vakhsh','bokhtar']::text[], ARRAY['bokhtar','vakhsh']::text[], ARRAY['tajikistan','khatlon','river','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'khoja-mumin-salt-mountain-trail', 'vose-hulbuk', 'NATURE', 0, 5, 'HOURS', 4.7, 'Тропа соляной горы Ходжа-Мумин', 'Khoja Mumin Salt Mountain Trail', 'Қожа-Мумин тұз тауы соқпағы', 'Необычный маршрут южного Таджикистана к белым склонам, сухим гребням и открытым видам Кулябской зоны.', 'An unusual southern Tajikistan route toward pale slopes, dry ridges and open views of the Kulob area.', 'Оңтүстік Тәжікстандағы ақшыл беткейлерге, құрғақ жоталарға және Куляб аймағының ашық көріністеріне апаратын ерекше бағыт.', 37.76000000, 69.62000000, 'Hulbuk Tajikistan.jpg', ARRAY['vose-hulbuk']::text[], ARRAY['kulob','vose-hulbuk']::text[], ARRAY['tajikistan','khatlon','salt-mountain','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'sari-khosor-upper-gorge-trail', 'sari-khosor', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа верхнего ущелья Сары-Хосора', 'Sari Khosor Upper Gorge Trail', 'Сары-Хосор жоғарғы шатқалы соқпағы', 'Горный маршрут к зеленому ущелью, воде и прохладным склонам, который раскрывает Балджувонскую сторону региона.', 'A mountain route toward a green gorge, water and cool slopes, opening the Baljuvon side of the region.', 'Жасыл шатқалға, суға және салқын беткейлерге апаратын тау бағыты, өңірдің Балжувон жағын ашады.', 38.26000000, 69.96000000, 'Sari Khosor Tajikistan.jpg', ARRAY['sari-khosor','baljuvon']::text[], ARRAY['kulob','sari-khosor']::text[], ARRAY['tajikistan','khatlon','gorge','free-entry','hiking']::text[]),
    ('TJ', 'TJS', 'tigrovaya-balka-southern-tugai-trail', 'dusti', 'NATURE', 30, 5, 'HOURS', 4.8, 'Южная тугайная тропа Тигровой Балки', 'Tigrovaya Balka Southern Tugai Trail', 'Тигровая Балка оңтүстік тоғай соқпағы', 'Маршрут по южным тугайным участкам с птицами, речной растительностью и заповедным режимом посещения.', 'A route across southern tugai sections with birds, riverside vegetation and protected-area access rules.', 'Құстары, өзен бойы өсімдіктері және қорықтық кіру тәртібі бар оңтүстік тоғай бөліктерімен өтетін бағыт.', 37.16500000, 68.46200000, 'Tigrovaya Balka Tajikistan.jpg', ARRAY['dusti']::text[], ARRAY['bokhtar','dusti']::text[], ARRAY['tajikistan','khatlon','tugai','permit','hiking']::text[]),
    ('TJ', 'TJS', 'kyzylsu-tugai-trail', 'shahrituz', 'NATURE', 0, 3, 'HOURS', 4.4, 'Тугайная тропа Кызылсу', 'Kyzylsu Tugai Trail', 'Қызылсу тоғай соқпағы', 'Небольшая природная прогулка по южной пойме с кустарниками, водой и жарким степным горизонтом.', 'A compact nature walk through the southern floodplain with shrubs, water and a hot steppe horizon.', 'Бұталары, суы және ыстық дала көкжиегі бар оңтүстік жайылма арқылы өтетін шағын табиғи серуен.', 37.22000000, 68.18000000, 'Khoja Mashhad Tajikistan.jpg', ARRAY['shahrituz']::text[], ARRAY['bokhtar','shahrituz']::text[], ARRAY['tajikistan','khatlon','tugai','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'chiluchor-chashma-ridge-walk', 'nosiri-khusrav', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка гребня Чилучор Чашма', 'Chiluchor Chashma Ridge Walk', 'Чилучор Чашма жотасы серуені', 'Короткий маршрут над родниковой зоной к сухому гребню, сельским видам и спокойной южной панораме.', 'A short route above the spring area toward a dry ridge, rural views and a calm southern panorama.', 'Бұлақ аймағы үстінен құрғақ жотаға, ауыл көріністеріне және тыныш оңтүстік панорамаға апаратын қысқа бағыт.', 37.10500000, 68.31800000, 'Chiluchor Chashma Tajikistan.jpg', ARRAY['nosiri-khusrav']::text[], ARRAY['bokhtar','nosiri-khusrav']::text[], ARRAY['tajikistan','khatlon','ridge','free-entry','walking']::text[]),
    ('TJ', 'TJS', 'takhti-sangin-oxus-riverbank-trail', 'qubodiyon', 'NATURE', 0, 3, 'HOURS', 4.6, 'Прибрежная тропа Окса у Тахти-Сангина', 'Takhti Sangin Oxus Riverbank Trail', 'Тахти-Сангин Окс жағалау соқпағы', 'Маршрут по южной речной кромке с археологическим контекстом, сухими полями и видом на приграничный ландшафт.', 'A route along the southern river edge with archaeological context, dry fields and borderland landscape views.', 'Археологиялық контексті, құрғақ алқаптары және шекаралық ландшафт көріністері бар оңтүстік өзен жиегімен өтетін бағыт.', 37.10600000, 68.14500000, 'Takhti Sangin Tajikistan.jpg', ARRAY['qubodiyon']::text[], ARRAY['bokhtar','qubodiyon']::text[], ARRAY['tajikistan','khatlon','riverbank','border-zone','walking']::text[]),
    ('TJ', 'TJS', 'childukhtaron-ridge-trail', 'muminobod', 'NATURE', 0, 5, 'HOURS', 4.8, 'Тропа гребня Чилдухтарон', 'Childukhtaron Ridge Trail', 'Чилдухтарон жотасы соқпағы', 'Южный горный маршрут по скальным формам, зеленым склонам и обзорным точкам Муминободского района.', 'A southern mountain route across rock forms, green slopes and viewpoints of the Muminobod area.', 'Муминобод аймағының жартас пішіндері, жасыл беткейлері және көрініс нүктелері арқылы өтетін оңтүстік тау бағыты.', 38.03000000, 70.05500000, 'Childukhtaron Tajikistan.jpg', ARRAY['muminobod']::text[], ARRAY['kulob','muminobod']::text[], ARRAY['tajikistan','khatlon','ridge','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_tajikistan_gap_hiking_resolved_places AS
SELECT
    ('a1ad0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['tajikistan-gap-hiking-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_tajikistan_gap_hiking_places;

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
FROM seed_tajikistan_gap_hiking_resolved_places
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
FROM seed_tajikistan_gap_hiking_resolved_places
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
FROM seed_tajikistan_gap_hiking_resolved_places
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
FROM seed_tajikistan_gap_hiking_resolved_places
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
FROM seed_tajikistan_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_tajikistan_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_tajikistan_gap_hiking_places;
