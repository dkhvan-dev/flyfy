-- Extra Kazakhstan outdoor gap seed.
-- Adds non-duplicate route-level places after the dense Kazakhstan hiking and nature coverage layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_gap_routes_places;

CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_gap_routes_places (
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

INSERT INTO seed_kazakhstan_extra_outdoor_gap_routes_places (
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
    ('KZ', 'KZT', 'right-talgar-valley-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.8, 'Тропа долины Правого Талгара', 'Right Talgar Valley Trail', 'Оң Талғар аңғары соқпағы', 'Маршрут восточнее Алматы по более дикому талгарскому ущелью с еловыми склонами, речным шумом и длинным горным днем.', 'A route east of Almaty through a wilder Talgar valley with spruce slopes, river sound and a long mountain-day format.', 'Алматының шығысындағы жабайырақ Талғар аңғары арқылы өтетін бағыт: шыршалы беткейлер, өзен үні және ұзақ таулы күн форматы.', 43.15200000, 77.28800000, 'Ile-Alatau_National_Park.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','right-talgar','valley','hiking']::text[]),
    ('KZ', 'KZT', 'bartogay-reservoir-shore-walk', 'almaty', 'NATURE', 0, 3, 'HOURS', 4.6, 'Береговая прогулка Бартогайского водохранилища', 'Bartogay Reservoir Shore Walk', 'Бартогай су қоймасы жағалау серуені', 'Спокойный маршрут восточнее Алматы у водохранилища, сухих склонов и широкого вида на степь и предгорья по дороге к Чарыну.', 'A calm route east of Almaty by the reservoir, dry slopes and wide views of steppe and foothills on the way to Charyn.', 'Алматының шығысындағы су қоймасы, құрғақ беткейлер және Шарынға баратын жолдағы дала мен тау етегіне кең көрініс беретін тыныш бағыт.', 43.37800000, 78.50500000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','bartogay','reservoir','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'ketpen-ridge-foothill-trail', 'almaty', 'NATURE', 0, 6, 'HOURS', 4.6, 'Предгорная тропа хребта Кетпен', 'Ketpen Ridge Foothill Trail', 'Кетпен жотасы тау етегі соқпағы', 'Высокогорный маршрут Кегенской стороны к сухим гребням, пастбищам и открытым видам на восточные хребты без технического альпинизма.', 'A Kegen-side highland route toward dry ridges, pastures and open views of eastern ranges without technical climbing.', 'Кеген жағындағы құрғақ жоталарға, жайылымдарға және техникалық альпинизмсіз шығыс жоталарына ашық көріністерге апаратын биіктау бағыты.', 43.00500000, 79.64000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty','taldykorgan']::text[], ARRAY['almaty','taldykorgan']::text[], ARRAY['kazakhstan','almaty-region','ketpen','ridge','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'kaskabulak-gorge-trail', 'shymkent', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа ущелья Каскабулак', 'Kaskabulak Gorge Trail', 'Қасқабұлақ шатқалы соқпағы', 'Маршрут Аксу-Жабаглы к прохладному ущелью, ручьям и западно-тяньшанским склонам для полноценного природного дня.', 'An Aksu-Zhabagly route toward a cool gorge, streams and Western Tian Shan slopes for a complete nature day.', 'Ақсу-Жабағылыдағы салқын шатқалға, бұлақтарға және Батыс Тянь-Шань беткейлеріне апаратын толық табиғи күн бағыты.', 42.44800000, 70.43500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent','taraz']::text[], ARRAY['kazakhstan','aksu-zhabagly','kaskabulak','gorge','hiking']::text[]),
    ('KZ', 'KZT', 'kshi-kaindy-gorge-trail', 'shymkent', 'NATURE', 1000, 5, 'HOURS', 4.7, 'Тропа ущелья Кши-Каинды', 'Kshi-Kaindy Gorge Trail', 'Кіші Қайыңды шатқалы соқпағы', 'Южный маршрут в зоне Аксу-Жабаглы по зеленому ущелью, каменным стенкам и тенистым участкам для активного выезда.', 'A southern Aksu-Zhabagly route through a green gorge, stone walls and shaded sections for an active outing.', 'Ақсу-Жабағылы аймағындағы жасыл шатқал, тас қабырғалар және көлеңкелі бөліктер арқылы өтетін белсенді оңтүстік бағыт.', 42.34800000, 70.52800000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent','taraz']::text[], ARRAY['kazakhstan','aksu-zhabagly','kshi-kaindy','gorge','hiking']::text[]),
    ('KZ', 'KZT', 'zhabaglysu-river-trail', 'shymkent', 'NATURE', 1000, 4, 'HOURS', 4.6, 'Речная тропа Жабаглысу', 'Zhabaglysu River Trail', 'Жабағылысу өзені соқпағы', 'Мягкий маршрут у Жабаглы вдоль горной воды, лугов и обзорных участков, подходящий как более простой сценарий Аксу-Жабаглы.', 'A gentle Zhabagly route along mountain water, meadows and viewpoint sections, useful as an easier Aksu-Zhabagly scenario.', 'Жабағылы маңындағы тау суы, шалғындар және көрініс бөліктері бойымен өтетін, Ақсу-Жабағылының жеңілірек сценарийіне лайық жұмсақ бағыт.', 42.43600000, 70.48000000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['shymkent','taraz']::text[], ARRAY['shymkent','taraz']::text[], ARRAY['kazakhstan','zhabagly','river','meadows','walking']::text[]),
    ('KZ', 'KZT', 'yazevoye-lake-shore-trail', 'ust-kamenogorsk', 'NATURE', 1000, 5, 'HOURS', 4.8, 'Береговая тропа озера Язевое', 'Yazevoye Lake Shore Trail', 'Язевое көлі жағалау соқпағы', 'Алтайский маршрут к прозрачному горному озеру, хвойным склонам и спокойному пейзажу Катон-Карагайской стороны.', 'An Altai route to a clear mountain lake, conifer slopes and a calm Katon-Karagay-side landscape.', 'Алтайдағы мөлдір тау көліне, қылқанды беткейлерге және Қатонқарағай жағының тыныш пейзажына апаратын бағыт.', 49.34000000, 85.69000000, 'Katon-Karagay_National_Park.jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','altai','yazevoye','lake-shore','hiking']::text[]),
    ('KZ', 'KZT', 'koktau-ridge-sibiny-walk', 'ust-kamenogorsk', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка хребта Коктау у Сибинских озер', 'Koktau Ridge Sibiny Walk', 'Сібі көлдері жанындағы Көктау жотасы серуені', 'Восточноказахстанская прогулка над Сибинскими озерами к низким скальным грядам, сосновым участкам и видам на воду.', 'An East Kazakhstan walk above the Sibiny lakes toward low rocky ridges, pine pockets and water views.', 'Сібі көлдерінің үстіндегі аласа жартасты жоталарға, қарағайлы бөліктерге және су көріністеріне апаратын Шығыс Қазақстан серуені.', 49.20200000, 82.62200000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['ust-kamenogorsk','semey']::text[], ARRAY['kazakhstan','east-kazakhstan','sibiny','koktau','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'urkashar-ridge-trail', 'semey', 'NATURE', 0, 6, 'HOURS', 4.6, 'Тропа хребта Уркашар', 'Urkashar Ridge Trail', 'Үрқашар жотасы соқпағы', 'Тарбагатайский маршрут по сухим гребням, степным склонам и длинным открытым видам восточного Казахстана.', 'A Tarbagatai route across dry ridges, steppe slopes and long open views of eastern Kazakhstan.', 'Шығыс Қазақстанның құрғақ жоталары, дала беткейлері және ұзақ ашық көріністері арқылы өтетін Тарбағатай бағыты.', 47.16000000, 82.12000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['semey','ust-kamenogorsk']::text[], ARRAY['kazakhstan','tarbagatai','urkashar','ridge','free-entry','trekking']::text[]),
    ('KZ', 'KZT', 'saura-lake-shore-walk', 'aktau', 'NATURE', 0, 3, 'HOURS', 4.6, 'Береговая прогулка озера Саура', 'Saura Lake Shore Walk', 'Саура көлі жағалау серуені', 'Мангистауский маршрут к небольшому озеру среди сухих склонов, известняковых форм и тихого пустынного пейзажа.', 'A Mangystau route to a small lake among dry slopes, limestone forms and a quiet desert landscape.', 'Маңғыстаудағы құрғақ беткейлер, әктас пішіндер және тыныш шөл ландшафты арасындағы шағын көлге апаратын бағыт.', 44.34200000, 51.34200000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','saura','lake-shore','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kelinshiktau-ridge-walk', 'kyzylorda', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка хребта Келиншиктау', 'Kelinshiktau Ridge Walk', 'Келіншектау жотасы серуені', 'Приаральский маршрут по выразительным сухим гребням, каменным останцам и открытому горизонту между Кызылордой и Туркестаном.', 'An Aral-side route across expressive dry ridges, stone outcrops and open horizon between Kyzylorda and Turkestan.', 'Қызылорда мен Түркістан арасындағы айқын құрғақ жоталар, тас мүсіндер және ашық көкжиек арқылы өтетін Арал маңы бағыты.', 44.00600000, 66.87000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['kyzylorda','turkestan']::text[], ARRAY['kyzylorda','turkestan']::text[], ARRAY['kazakhstan','kyzylorda-region','kelinshiktau','ridge','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'karkaraly-komsomol-peak-trail', 'karaganda', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Тропа на пик Комсомольский в Каркаралы', 'Karkaraly Komsomol Peak Trail', 'Қарқаралы Комсомол шыңы соқпағы', 'Классический каркаралинский подъем к лесным склонам, гранитным участкам и обзорной точке над городом и национальным парком.', 'A classic Karkaraly ascent toward forested slopes, granite sections and a viewpoint above the town and national park.', 'Қарқаралыдағы орманды беткейлерге, гранитті бөліктерге және қала мен ұлттық парк үстіндегі көрініс нүктесіне апаратын классикалық көтерілу.', 49.39700000, 75.47000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda']::text[], ARRAY['karaganda']::text[], ARRAY['kazakhstan','karkaraly','komsomol-peak','granite','hiking']::text[]),
    ('KZ', 'KZT', 'jeke-batyr-ridge-walk', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка хребта Жеке-Батыр', 'Jeke Batyr Ridge Walk', 'Жеке-Батыр жотасы серуені', 'Бурабайская прогулка к узнаваемому силуэту горы, сосновым участкам и коротким обзорным точкам у озерной зоны.', 'A Burabay walk toward a recognizable mountain silhouette, pine sections and short viewpoints near the lake area.', 'Бурабайдағы танымал тау сұлбасына, қарағайлы бөліктерге және көл аймағындағы қысқа көрініс нүктелеріне апаратын серуен.', 53.07200000, 70.29400000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','burabay','jeke-batyr','ridge','walking']::text[]),
    ('KZ', 'KZT', 'katarkol-pine-shore-walk', 'kokshetau', 'NATURE', 1000, 3, 'HOURS', 4.6, 'Сосновая прогулка берега Катарколя', 'Katarkol Pine Shore Walk', 'Қатаркөл қарағайлы жағалау серуені', 'Спокойный северный маршрут у Катарколя с соснами, мягкой береговой линией и менее перегруженным сценарием Бурабайской зоны.', 'A calm northern route by Katarkol with pines, a gentle shoreline and a less crowded Burabay-area scenario.', 'Қатаркөл маңындағы қарағайлар, жұмсақ жағалау және Бурабай аймағының тынышырақ сценарийі бар солтүстік бағыт.', 53.00500000, 70.26000000, 'Burabay_National_Park_Kazakhstan.jpg', ARRAY['kokshetau','astana']::text[], ARRAY['kokshetau','astana']::text[], ARRAY['kazakhstan','akmola-region','katarkol','pine','walking']::text[]),
    ('KZ', 'KZT', 'kokzhide-sands-walk', 'aktobe', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка песков Кокжиде', 'Kokzhide Sands Walk', 'Көкжиде құмдары серуені', 'Западноказахстанский маршрут по песчаным участкам, редким кустарникам и открытому горизонту как спокойный геоприродный выезд из Актобе.', 'A western Kazakhstan route across sandy sections, sparse shrubs and open horizon as a calm geo-nature outing from Aktobe.', 'Ақтөбеден шығатын Батыс Қазақстан бағыты: құмды бөліктер, сирек бұталар және ашық көкжиек арқылы өтетін тыныш геотабиғи серуен.', 47.54800000, 56.30000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe','atyrau']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','kokzhide','sands','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_extra_outdoor_gap_routes_resolved_places AS
SELECT
    ('126d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-extra-outdoor-gap-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_extra_outdoor_gap_routes_places;

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
FROM seed_kazakhstan_extra_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_gap_routes_resolved_places
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
FROM seed_kazakhstan_extra_outdoor_gap_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_gap_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_extra_outdoor_gap_routes_places;
