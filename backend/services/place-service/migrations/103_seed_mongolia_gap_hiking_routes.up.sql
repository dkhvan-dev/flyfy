-- Route-level hiking/day-hike enrichment for remaining Mongolia hubs.
-- These rows intentionally complement broad parks, monasteries, dunes and canyon anchors with concrete trail scenarios.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_mongolia_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_mongolia_gap_hiking_places;

CREATE TEMP TABLE seed_mongolia_gap_hiking_places (
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

INSERT INTO seed_mongolia_gap_hiking_places (
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
    ('MN', 'MNT', 'tuul-river-steppe-trail', 'tsonjin-boldog', 'NATURE', 0, 4, 'HOURS', 4.6, 'Степная тропа реки Туул', 'Tuul River Steppe Trail', 'Туул өзені дала соқпағы', 'Короткий маршрут у Цонжин-Болдога по открытой степи и берегам Туула, который добавляет природный сценарий к поездке из Улан-Батора.', 'A short route near Tsonjin Boldog across open steppe and Tuul riverbanks, adding a nature plan to the day trip from Ulaanbaatar.', 'Цонжин-Болдог маңындағы ашық дала мен Туул жағалаулары арқылы өтетін қысқа бағыт, Ұлан-Батордан шығатын сапарға табиғи сценарий қосады.', 47.82600000, 107.53000000, 'Genghis Khan Equestrian Statue.jpg', ARRAY['tsonjin-boldog']::text[], ARRAY['ulaanbaatar','tsonjin-boldog']::text[], ARRAY['mongolia','tuul-river','steppe','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'manzushir-forest-ridge-trail', 'zuunmod', 'NATURE', 10000, 5, 'HOURS', 4.7, 'Лесная жотная тропа Манзушира', 'Manzushir Forest Ridge Trail', 'Манзушир орман жотасы соқпағы', 'Маршрут из Зуунмода к лесным склонам Богдхан-Уула, каменным участкам и тихим видовым точкам южнее столицы.', 'A route from Zuunmod toward Bogd Khan Uul forest slopes, rocky sections and quiet viewpoints south of the capital.', 'Зуунмодтан Богдхан-Уулдың орманды беткейлеріне, тасты бөліктерге және астананың оңтүстігіндегі тыныш көрініс нүктелеріне апаратын бағыт.', 47.75800000, 106.98000000, 'Ulaanbaatar Bogd Khan Mountain.jpg', ARRAY['zuunmod']::text[], ARRAY['ulaanbaatar','zuunmod']::text[], ARRAY['mongolia','bogd-khan','forest','day-hike']::text[]),
    ('MN', 'MNT', 'khustai-takhi-steppe-trail', 'khustai', 'NATURE', 10000, 5, 'HOURS', 4.8, 'Степная тропа тахи в Хустае', 'Khustai Takhi Steppe Trail', 'Хустай тахи дала соқпағы', 'Пешеходный маршрут по волнистой степи Хустая с мягкими холмами, наблюдением за лошадьми Пржевальского и широким горизонтом.', 'A walking route through Khustai rolling steppe with gentle hills, Przewalski horse watching and a wide horizon.', 'Хустайдың толқынды даласы арқылы өтетін жаяу бағыт: жұмсақ төбелер, Пржевальский жылқыларын бақылау және кең көкжиек.', 47.70000000, 105.90000000, 'Przewalski horse Hustai National Park.jpg', ARRAY['khustai']::text[], ARRAY['ulaanbaatar','khustai']::text[], ARRAY['mongolia','takhi','wildlife','steppe','hiking']::text[]),
    ('MN', 'MNT', 'karakorum-riverbank-heritage-trail', 'kharkhorin', 'NATURE', 0, 3, 'HOURS', 4.6, 'Историческая тропа берега Каракорума', 'Karakorum Riverbank Heritage Trail', 'Қарақорым өзен жағасы тарихи соқпағы', 'Спокойный маршрут вокруг Хархорина вдоль речной долины, полевых дорог и панорам, связывающий исторические остановки с outdoor-прогулкой.', 'A calm route around Kharkhorin along a river valley, field roads and panoramas, connecting heritage stops with an outdoor walk.', 'Хархорин маңындағы өзен аңғары, дала жолдары және панорамалар арқылы өтетін тыныш бағыт, тарихи аялдамаларды outdoor-серуенмен байланыстырады.', 47.20000000, 102.84000000, 'Orkhon Valley Mongolia.jpg', ARRAY['kharkhorin','orkhon-valley']::text[], ARRAY['kharkhorin','ulaanbaatar']::text[], ARRAY['mongolia','kharkhorin','riverbank','free-entry','walking']::text[]),
    ('MN', 'MNT', 'orkhon-waterfall-rim-trail', 'orkhon-valley', 'NATURE', 0, 4, 'HOURS', 4.8, 'Тропа по краю водопада Орхона', 'Orkhon Waterfall Rim Trail', 'Орхон сарқырамасы жиегі соқпағы', 'Маршрут по краю лавового каньона и речной долины Орхона с обзорными точками, ветром степи и короткими спусками.', 'A route along the rim of Orkhon lava canyon and river valley with viewpoints, steppe wind and short descents.', 'Орхонның лава каньоны мен өзен аңғары жиегімен өтетін бағыт: көрініс нүктелері, дала желі және қысқа түсу жолдары.', 46.79000000, 101.96000000, 'Orkhon Waterfall Mongolia.jpg', ARRAY['orkhon-valley']::text[], ARRAY['kharkhorin','orkhon-valley']::text[], ARRAY['mongolia','orkhon','waterfall-rim','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'tuvkhun-forest-ascent-trail', 'tuvkhun', 'NATURE', 0, 5, 'HOURS', 4.7, 'Лесная тропа подъема к Тувхуну', 'Tuvkhun Forest Ascent Trail', 'Тувхун орман көтерілу соқпағы', 'Лесной подъем в горах Хангай к скальным седловинам и тихим обзорным точкам, удобный как активный день из долины Орхона.', 'A forest ascent in the Khangai Mountains toward rocky saddles and quiet viewpoints, useful as an active day from the Orkhon valley.', 'Хангай тауларындағы орманды көтерілу: тасты асулар мен тыныш көрініс нүктелеріне апарады, Орхон аңғарынан белсенді күнге ыңғайлы.', 47.02000000, 102.27000000, 'Orkhon Valley Mongolia.jpg', ARRAY['tuvkhun','orkhon-valley']::text[], ARRAY['kharkhorin','tuvkhun']::text[], ARRAY['mongolia','khangai','forest','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'tsenkher-river-valley-walk', 'tsenkher', 'NATURE', 0, 3, 'HOURS', 4.5, 'Прогулка долины реки Цэнхэр', 'Tsenkher River Valley Walk', 'Цэнхэр өзені аңғары серуені', 'Мягкий маршрут по речной долине Архангая с лугами, невысокими склонами и спокойным форматом после дороги из Цэцэрлэга.', 'A gentle Arkhangai river-valley route with meadows, low slopes and a calm format after the road from Tsetserleg.', 'Архангайдағы өзен аңғары арқылы өтетін жеңіл бағыт: шалғындар, аласа беткейлер және Цэцэрлэгтен кейінгі тыныш формат.', 47.32000000, 101.65000000, 'Tsetserleg Mongolia.jpg', ARRAY['tsenkher','tsetserleg']::text[], ARRAY['tsetserleg','tsenkher']::text[], ARRAY['mongolia','arkhangai','river-valley','free-entry','walking']::text[]),
    ('MN', 'MNT', 'amarbayasgalant-valley-ridge-trail', 'amarbayasgalant', 'NATURE', 0, 4, 'HOURS', 4.6, 'Жотная тропа долины Амарбаясгалант', 'Amarbayasgalant Valley Ridge Trail', 'Амарбаясгалант аңғары жота соқпағы', 'Маршрут по холмам и степной долине северной Монголии, который превращает дальний культурный выезд в полноценную природную прогулку.', 'A route across hills and a northern Mongolia steppe valley, turning a long cultural trip into a fuller nature walk.', 'Солтүстік Моңғолияның төбелері мен дала аңғары арқылы өтетін бағыт, ұзақ мәдени сапарды толық табиғи серуенге айналдырады.', 49.47000000, 105.09000000, 'Darkhan Mongolia.jpg', ARRAY['amarbayasgalant']::text[], ARRAY['darkhan','erdenet','amarbayasgalant']::text[], ARRAY['mongolia','northern-mongolia','steppe-valley','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'dalan-bulag-desert-steppe-trail', 'dalanzadgad', 'NATURE', 0, 4, 'HOURS', 4.6, 'Пустынно-степная тропа Далан-Булак', 'Dalan Bulag Desert Steppe Trail', 'Далан-Бұлақ шөл-дала соқпағы', 'Легкий маршрут у Даланзадгада по сухой степи, низким холмам и открытым видам Гоби перед дальними каньонами и дюнами.', 'An easy route near Dalanzadgad across dry steppe, low hills and open Gobi views before longer canyon and dune trips.', 'Даланзадгад маңындағы құрғақ дала, аласа төбелер және алыс каньондар мен құмдарға дейінгі ашық Гоби көріністері арқылы өтетін жеңіл бағыт.', 43.57000000, 104.43000000, 'Dalanzadgad Mongolia.jpg', ARRAY['dalanzadgad']::text[], ARRAY['dalanzadgad']::text[], ARRAY['mongolia','gobi','desert-steppe','free-entry','walking']::text[]),
    ('MN', 'MNT', 'yolyn-am-ice-gorge-trail', 'yolyn-am', 'NATURE', 10000, 4, 'HOURS', 4.8, 'Ледовая тропа Ёлын-Ама', 'Yolyn Am Ice Gorge Trail', 'Ёлын-Ам мұзды шатқал соқпағы', 'Маршрут по узкому горному проходу Гоби с тенистыми стенами, сезонным льдом и ощутимым контрастом к пустынной равнине.', 'A route through a narrow Gobi mountain passage with shaded walls, seasonal ice and a strong contrast to the desert plain.', 'Гобидегі тар тау өткелі арқылы өтетін бағыт: көлеңкелі қабырғалар, маусымдық мұз және шөл жазығына айқын контраст.', 43.48000000, 104.07000000, 'Yolyn Am Mongolia.jpg', ARRAY['yolyn-am','dalanzadgad']::text[], ARRAY['dalanzadgad','yolyn-am']::text[], ARRAY['mongolia','gobi','ice-gorge','hiking']::text[]),
    ('MN', 'MNT', 'singing-dune-ridge-climb', 'khongoryn-els', 'NATURE', 0, 3, 'HOURS', 4.9, 'Подъем на гребень Поющей дюны', 'Singing Dune Ridge Climb', 'Әнші құм жотасына көтерілу', 'Короткий, но физически яркий подъем по песчаному гребню с видом на Гоби, вечерним светом и длинной линией дюн.', 'A short but physical climb along a sand ridge with Gobi views, evening light and a long dune line.', 'Гоби көріністері, кешкі жарық және ұзын құм сызығы бар құм жотасымен қысқа, бірақ күшті көтерілу.', 43.82000000, 102.28000000, 'Khongoryn Els Mongolia.jpg', ARRAY['khongoryn-els']::text[], ARRAY['dalanzadgad','khongoryn-els']::text[], ARRAY['mongolia','gobi','dune','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'bayanzag-cliffs-rim-trail', 'bayanzag', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа по краю скал Баянзага', 'Bayanzag Cliffs Rim Trail', 'Баянзаг жартастары жиегі соқпағы', 'Маршрут по сухому краю красных скал с пустынными видами, палеонтологическим контекстом и хорошим светом на закате.', 'A route along the dry rim of red cliffs with desert views, paleontology context and strong sunset light.', 'Қызыл жартастардың құрғақ жиегімен өтетін бағыт: шөл көріністері, палеонтологиялық контекст және күн батардағы әдемі жарық.', 44.15000000, 103.72000000, 'Flaming Cliffs Bayanzag Mongolia.jpg', ARRAY['bayanzag']::text[], ARRAY['dalanzadgad','bayanzag']::text[], ARRAY['mongolia','gobi','cliff-rim','free-entry','walking']::text[]),
    ('MN', 'MNT', 'tsagaan-suvarga-escarpment-trail', 'tsagaan-suvarga', 'NATURE', 0, 3, 'HOURS', 4.7, 'Тропа уступа Цагаан-Суварга', 'Tsagaan Suvarga Escarpment Trail', 'Цагаан-Суварга кертпеші соқпағы', 'Короткая прогулка по светлому глинистому уступу с видами на слои пустынного плато и мягкой логистикой между Улан-Батором и Гоби.', 'A short walk along a pale clay escarpment with views of desert-plateau layers and easy logistics between Ulaanbaatar and the Gobi.', 'Ашық сазды кертпеш бойымен өтетін қысқа серуен: шөл үстірті қабаттарының көрінісі және Ұлан-Батор мен Гоби арасындағы жеңіл логистика.', 44.58000000, 105.76000000, 'Tsagaan Suvarga Mongolia.jpg', ARRAY['tsagaan-suvarga']::text[], ARRAY['ulaanbaatar','tsagaan-suvarga','dalanzadgad']::text[], ARRAY['mongolia','gobi','escarpment','free-entry','walking']::text[]),
    ('MN', 'MNT', 'baga-gazriin-rock-labyrinth-trail', 'baga-gazriin-chuluu', 'NATURE', 0, 4, 'HOURS', 4.6, 'Тропа скального лабиринта Бага-Газрын', 'Baga Gazriin Rock Labyrinth Trail', 'Бага-Газрын жартас лабиринті соқпағы', 'Маршрут среди гранитных форм Средней Гоби с узкими проходами, низкими вершинами и спокойными обзорными точками.', 'A route among Middle Gobi granite forms with narrow passages, low summits and calm viewpoints.', 'Орта Гобидегі гранит пішіндері арасындағы бағыт: тар өтпелер, аласа шыңдар және тыныш көрініс нүктелері.', 46.18000000, 106.01000000, 'Dalanzadgad Mongolia.jpg', ARRAY['baga-gazriin-chuluu']::text[], ARRAY['ulaanbaatar','baga-gazriin-chuluu']::text[], ARRAY['mongolia','middle-gobi','granite','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'khamar-steppe-viewpoint-trail', 'sainshand', 'NATURE', 0, 3, 'HOURS', 4.5, 'Степная тропа к виду Хамар', 'Khamar Steppe Viewpoint Trail', 'Хамар дала көрініс соқпағы', 'Короткий маршрут из Сайншанда к сухим холмам, ветру пустыни и открытой линии горизонта Восточной Гоби.', 'A short route from Sainshand toward dry hills, desert wind and the open horizon line of the eastern Gobi.', 'Сайншандтан құрғақ төбелерге, шөл желіне және Шығыс Гобидің ашық көкжиегіне апаратын қысқа бағыт.', 44.89000000, 110.14000000, 'Sainshand Mongolia.jpg', ARRAY['sainshand']::text[], ARRAY['sainshand']::text[], ARRAY['mongolia','eastern-gobi','steppe','free-entry','walking']::text[]),
    ('MN', 'MNT', 'shambhala-desert-energy-trail', 'khamaryn-khiid', 'NATURE', 0, 3, 'HOURS', 4.6, 'Пустынная тропа Шамбалы', 'Shambhala Desert Energy Trail', 'Шамбала шөл соқпағы', 'Маршрут по сухой пустынной местности вокруг паломнического района с мягкими холмами, песком и тихими остановками.', 'A route across dry desert terrain around the pilgrimage area with gentle hills, sand and quiet stops.', 'Қажылық аймағы маңындағы құрғақ шөл арқылы өтетін бағыт: жұмсақ төбелер, құм және тыныш аялдамалар.', 44.60000000, 110.18000000, 'Khamaryn Khiid Mongolia.jpg', ARRAY['khamaryn-khiid','sainshand']::text[], ARRAY['sainshand','khamaryn-khiid']::text[], ARRAY['mongolia','eastern-gobi','desert','free-entry','walking']::text[]),
    ('MN', 'MNT', 'khermen-tsav-rim-trail', 'khermen-tsav', 'NATURE', 0, 6, 'HOURS', 4.8, 'Тропа по краю Хэрмэн-Цав', 'Khermen Tsav Rim Trail', 'Хэрмэн-Цав жиегі соқпағы', 'Удаленный маршрут по краю красных стен и сухих русел Южной Гоби, рассчитанный на подготовленную поездку с гидом и запасом воды.', 'A remote route along red walls and dry washes of the southern Gobi, suited for a prepared trip with a guide and enough water.', 'Оңтүстік Гобидің қызыл қабырғалары мен құрғақ сайлары жиегімен өтетін шалғай бағыт, гидпен және су қорымен дайын сапарға лайық.', 43.45000000, 100.50000000, 'Khermen Tsav Mongolia.jpg', ARRAY['khermen-tsav']::text[], ARRAY['dalanzadgad','khermen-tsav']::text[], ARRAY['mongolia','gobi','remote','free-entry','trekking']::text[]),
    ('MN', 'MNT', 'darkhan-kharaa-river-trail', 'darkhan', 'NATURE', 0, 3, 'HOURS', 4.4, 'Тропа реки Хараа в Дархане', 'Darkhan Kharaa River Trail', 'Дархан Хараа өзені соқпағы', 'Легкая прогулка у Дархана вдоль речной долины, пойменной зелени и открытой северной степи.', 'An easy walk near Darkhan along a river valley, floodplain greenery and open northern steppe.', 'Дархан маңындағы өзен аңғары, жайылма жасылдығы және ашық солтүстік дала бойымен өтетін жеңіл серуен.', 49.48600000, 105.92200000, 'Darkhan Mongolia.jpg', ARRAY['darkhan']::text[], ARRAY['darkhan']::text[], ARRAY['mongolia','northern-mongolia','river','free-entry','walking']::text[]),
    ('MN', 'MNT', 'bayan-undur-hill-trail', 'erdenet', 'NATURE', 0, 4, 'HOURS', 4.5, 'Тропа холмов Баян-Ундур', 'Bayan-Undur Hill Trail', 'Баян-Өндөр төбелері соқпағы', 'Маршрут над Эрдэнэтом к сухим холмам, обзорным точкам и степному горизонту Орхонского региона.', 'A route above Erdenet toward dry hills, viewpoints and the steppe horizon of the Orkhon region.', 'Эрдэнэт үстіндегі құрғақ төбелерге, көрініс нүктелеріне және Орхон өңірінің дала көкжиегіне апаратын бағыт.', 49.02700000, 104.04500000, 'Erdenet Mongolia.jpg', ARRAY['erdenet']::text[], ARRAY['erdenet']::text[], ARRAY['mongolia','orkhon-region','hills','free-entry','hiking']::text[]),
    ('MN', 'MNT', 'kherlen-riverbank-steppe-trail', 'choibalsan', 'NATURE', 0, 3, 'HOURS', 4.4, 'Степная тропа берега Хэрлэна', 'Kherlen Riverbank Steppe Trail', 'Хэрлэн жағалауы дала соқпағы', 'Пешеходный маршрут у Чойбалсана вдоль реки, луговых участков и широких восточных степей.', 'A walking route near Choibalsan along the river, meadow sections and wide eastern steppe.', 'Чойбалсан маңындағы өзен, шалғынды бөліктер және кең шығыс дала бойымен өтетін жаяу бағыт.', 48.08000000, 114.54000000, 'Choibalsan Mongolia.jpg', ARRAY['choibalsan']::text[], ARRAY['choibalsan']::text[], ARRAY['mongolia','eastern-steppe','riverbank','free-entry','walking']::text[]),
    ('MN', 'MNT', 'khalkh-gol-riverbank-trail', 'khalkh-gol', 'NATURE', 0, 3, 'HOURS', 4.5, 'Береговая тропа Халхин-Гола', 'Khalkh Gol Riverbank Trail', 'Халхин-Гол жағалау соқпағы', 'Маршрут по восточной речной долине с историческим фоном, открытой травяной степью и тихими обзорными остановками.', 'A route through an eastern river valley with historical context, open grass steppe and quiet viewpoint stops.', 'Шығыс өзен аңғары арқылы өтетін бағыт: тарихи контекст, ашық шөпті дала және тыныш көрініс аялдамалары.', 47.76000000, 118.58000000, 'Ikh Burkhant Mongolia.jpg', ARRAY['khalkh-gol']::text[], ARRAY['choibalsan','khalkh-gol']::text[], ARRAY['mongolia','eastern-steppe','riverbank','history','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_mongolia_gap_hiking_resolved_places AS
SELECT
    ('103d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['mongolia-gap-hiking-v1', lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_mongolia_gap_hiking_places;

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
FROM seed_mongolia_gap_hiking_resolved_places
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
FROM seed_mongolia_gap_hiking_resolved_places
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
FROM seed_mongolia_gap_hiking_resolved_places
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
FROM seed_mongolia_gap_hiking_resolved_places
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
FROM seed_mongolia_gap_hiking_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_mongolia_gap_hiking_resolved_places;
DROP TABLE IF EXISTS seed_mongolia_gap_hiking_places;
