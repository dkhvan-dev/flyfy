-- Further Kazakhstan route-level outdoor/hiking seed.
-- Adds additional non-duplicate hiking, geotrail and heritage-walk choices across Kazakhstan.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_further_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_further_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_further_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_further_outdoor_routes_places (
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
    ('KZ', 'KZT', 'pioneer-peak-ridge-trail', 'almaty', 'NATURE', 1000, 6, 'HOURS', 4.7, 'Гребневая тропа пика Пионер', 'Pioneer Peak Ridge Trail', 'Пионер шыңы жотасы соқпағы', 'Высотный маршрут над долиной Медеу и Шымбулака к открытым гребням, каменным участкам и быстрым панорамам Заилийского Алатау.', 'A high mountain route above the Medeu and Shymbulak valley toward open ridges, rocky sections and quick Trans-Ili Alatau panoramas.', 'Медеу мен Шымбұлақ аңғары үстіндегі биіктау бағыты: ашық жоталар, тасты бөліктер және Іле Алатауының жылдам панорамалары.', 43.09000000, 77.09500000, 'Shymbulak, Almaty (P1180189).jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','ile-alatau','pioneer-peak','ridge','trekking']::text[]),
    ('KZ', 'KZT', 'sovetov-peak-view-trail', 'almaty', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Тропа к виду на пик Советов', 'Sovetov Peak View Trail', 'Советов шыңы көрінісіне соқпақ', 'Маршрут из района Большого Алматинского озера к высокогорным видам, где хорошо читаются ледниковые цирки и главные пики южнее озера.', 'A route from the Big Almaty Lake area to high-alpine views where glacial bowls and the main peaks south of the lake are easy to read.', 'Үлкен Алматы көлі аймағынан биіктау көріністеріне апаратын бағыт, көлдің оңтүстігіндегі мұздық цирктері мен негізгі шыңдар айқын көрінеді.', 43.02700000, 77.07500000, 'Big Almaty Lake 2014.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','big-almaty-lake','sovetov-peak','trekking']::text[]),
    ('KZ', 'KZT', 'third-kolsai-lake-trek', 'almaty', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Трек к Третьему Кольсайскому озеру', 'Third Kolsai Lake Trek', 'Үшінші Көлсай көліне трек', 'Более глубокий кольсайский маршрут выше популярных берегов, с еловыми склонами, набором высоты и ощущением настоящего горного треккинга.', 'A deeper Kolsai route above the popular shores, with spruce slopes, elevation gain and a stronger mountain-trekking feel.', 'Танымал жағалардан жоғарырақ өтетін терең Көлсай бағыты: шыршалы беткейлер, биіктік жинау және нағыз тау треккингі әсері.', 42.92300000, 78.39300000, 'Kolsai lake.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','kolsai','upper-lake','trekking']::text[]),
    ('KZ', 'KZT', 'boguty-red-mountains-trail', 'almaty', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа Красных гор Богуты', 'Boguty Red Mountains Trail', 'Бөгеті қызыл таулары соқпағы', 'Полупустынный маршрут восточнее Алматы по цветным холмам, сухим логам и мягким гребням, который хорошо дополняет поездки к Чарыну.', 'A semi-desert route east of Almaty across colored hills, dry gullies and gentle ridges, pairing well with Charyn-side trips.', 'Алматының шығысындағы түрлі түсті төбелер, құрғақ сайлар және жұмсақ жоталар арқылы өтетін шөлейт бағыт, Шарын сапарын жақсы толықтырады.', 43.57000000, 78.83000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty-region','boguty','red-mountains','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'akkainar-zhartas-petroglyph-walk', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.5, 'Прогулка к петроглифам Аккайнара и Жартаса', 'Akkainar-Zhartas Petroglyph Walk', 'Аққайнар-Жартас петроглифтері серуені', 'Короткий маршрут по открытым доступным участкам Чу-Илийских предгорий с каменными выходами, ручьем и петроглифическим контекстом.', 'A short walk through publicly accessible Chu-Ili foothill sections with rocky outcrops, a small river and petroglyph context.', 'Шу-Іле тау етегіндегі ашық қолжетімді бөліктермен өтетін қысқа серуен: тасты жерлер, шағын өзен және петроглиф контексті.', 43.65000000, 75.45500000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','chu-ili','petroglyphs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'bayan-zhurek-petroglyph-ridge-walk', 'taldykorgan', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка по петроглифическому хребту Баян-Журек', 'Bayan-Zhurek Petroglyph Ridge Walk', 'Баян-Жүрек петроглиф жотасы серуені', 'Жетысуский маршрут по невысоким грядам, древним наскальным изображениям и тихому природному ландшафту между равниной и горами.', 'A Zhetysu route across low ridges, ancient rock art and a quiet natural landscape between plain and mountains.', 'Жетісудағы аласа жоталар, көне жартас суреттері және жазық пен тау арасындағы тыныш табиғи ландшафт арқылы өтетін бағыт.', 45.05000000, 79.01000000, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','bayan-zhurek','petroglyphs','free-entry','hiking']::text[]),
    ('KZ', 'KZT', 'akbaur-cave-hill-walk', 'ust-kamenogorsk', 'NATURE', 0, 3, 'HOURS', 4.6, 'Холмистая прогулка к пещере Акбаур', 'Akbaur Cave Hill Walk', 'Ақбауыр үңгірі төбе серуені', 'Короткий выезд из Оскемена к скальному холму, древним рисункам и степно-горному ландшафту Восточного Казахстана.', 'A short outing from Oskemen toward a rocky hill, ancient markings and the steppe-mountain landscape of East Kazakhstan.', 'Өскеменнен тасты төбеге, көне таңбаларға және Шығыс Қазақстанның дала-таулы ландшафтына апаратын қысқа сапар.', 50.03500000, 82.53000000, 'Beautiful view of the mountains (Katon-Karagay).jpg', ARRAY['ust-kamenogorsk']::text[], ARRAY['ust-kamenogorsk']::text[], ARRAY['kazakhstan','east-kazakhstan','akbaur','petroglyphs','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'sarykopa-steppe-lake-walk', 'kostanay', 'NATURE', 0, 4, 'HOURS', 4.5, 'Степная прогулка озера Сарыкопа', 'Sarykopa Steppe Lake Walk', 'Сарықопа далалық көлі серуені', 'Северный маршрут к солоноватому озеру, высоким берегам и открытой степи, где особенно интересны птицы и сезонные изменения воды.', 'A northern route to a saline lake, raised shores and open steppe, especially interesting for birds and seasonal water changes.', 'Сортаң көлге, биіктеу жағаларға және ашық далаға апаратын солтүстік бағыт, құстар мен маусымдық су өзгерістерімен қызықты.', 50.42000000, 65.00000000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay-region','sarykopa','lake','free-entry','birdwatching']::text[]),
    ('KZ', 'KZT', 'koktinkoli-lake-steppe-walk', 'karaganda', 'NATURE', 0, 3, 'HOURS', 4.4, 'Степная прогулка озера Коктинколи', 'Koktinkoli Lake Steppe Walk', 'Көктіңкөлі далалық көлі серуені', 'Центральноказахстанская прогулка у небольшого озера с пологими берегами, камышами и спокойным степным горизонтом.', 'A central Kazakhstan walk by a small lake with gentle shores, reed sections and a calm steppe horizon.', 'Орталық Қазақстандағы шағын көл маңындағы серуен: жайпақ жағалар, қамысты бөліктер және тыныш дала көкжиегі.', 48.46500000, 72.15000000, 'Karkaraly_National_Park.jpg', ARRAY['karaganda','zhezkazgan']::text[], ARRAY['karaganda','zhezkazgan']::text[], ARRAY['kazakhstan','central-kazakhstan','lake','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'zhamanshin-crater-rim-walk', 'aktobe', 'NATURE', 0, 4, 'HOURS', 4.6, 'Прогулка по краю кратера Жаманшин', 'Zhamanshin Crater Rim Walk', 'Жаманшың кратері жиегі серуені', 'Геологический маршрут Актюбинской области по открытому импактному ландшафту, сухим ложбинам и необычным формам рельефа.', 'A geotrail in Aktobe Region across an exposed impact landscape, dry hollows and unusual landforms.', 'Ақтөбе облысындағы ашық импакт ландшафты, құрғақ ойпаңдар және ерекше жер бедері арқылы өтетін геобағыт.', 48.40000000, 60.96600000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['aktobe']::text[], ARRAY['aktobe']::text[], ARRAY['kazakhstan','aktobe-region','zhamanshin','crater','free-entry','geotrail','hiking']::text[]),
    ('KZ', 'KZT', 'kyrshabakty-gorge-fossil-walk', 'taraz', 'NATURE', 0, 4, 'HOURS', 4.5, 'Прогулка по ископаемому ущелью Кыршабакты', 'Kyrshabakty Gorge Fossil Walk', 'Қыршабақты қазба шатқалы серуені', 'Каратауский маршрут по речному ущелью, известняковым стенкам и местам с палеонтологическим контекстом для спокойного природного выезда.', 'A Karatau route through a river gorge, limestone walls and fossil context for a calm nature outing.', 'Қаратаудағы өзен шатқалы, әктас қабырғалары және палеонтологиялық контексті бар тыныш табиғи бағыт.', 43.73000000, 69.10500000, 'Aksu-Zhabagly Nature Reserve.jpg', ARRAY['taraz','turkestan']::text[], ARRAY['taraz','turkestan']::text[], ARRAY['kazakhstan','karatau','gorge','fossils','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_further_outdoor_routes_resolved_places AS
SELECT
    ('107d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-further-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_further_outdoor_routes_places;

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
FROM seed_kazakhstan_further_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_further_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_further_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_further_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_further_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_further_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_further_outdoor_routes_places;
