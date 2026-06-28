-- Priority Abkhazia destination places seed.
-- Abkhazia is stored with internal country code AB because it has no ISO 3166-1 alpha-2 code.
-- The seed keeps city-like tourist hubs explicit for admin filters and localized mobile discovery.

DROP TABLE IF EXISTS seed_abkhazia_resolved_places;
DROP TABLE IF EXISTS seed_abkhazia_priority_places;

CREATE TEMP TABLE seed_abkhazia_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_query text NOT NULL,
    access_city_ids text[] NOT NULL,
    departure_city_ids text[] NOT NULL,
    media_file text NOT NULL
);

INSERT INTO seed_abkhazia_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    latitude,
    longitude,
    location_query,
    access_city_ids,
    departure_city_ids,
    media_file
) VALUES
    ('sukhum-botanical-garden', 'sukhum', 'PARK', 2, 'HOURS', 4.7, 'Сухумский ботанический сад', 'Sukhum Botanical Garden', 'Сухум ботаникалық бағы', 43.00370000, 41.02150000, 'Sukhum Botanical Garden Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('sukhum-monkey-nursery', 'sukhum', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Сухумский обезьяний питомник', 'Sukhum Monkey Nursery', 'Сухум маймыл питомнигі', 43.00570000, 41.01940000, 'Sukhum Monkey Nursery Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('abkhazian-state-museum', 'sukhum', 'MUSEUM', 2, 'HOURS', 4.5, 'Абхазский государственный музей', 'Abkhazian State Museum', 'Абхазия мемлекеттік музейі', 43.00520000, 41.01880000, 'Abkhazian State Museum Sukhum', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('sukhum-central-market', 'sukhum', 'MARKET', 2, 'HOURS', 4.4, 'Центральный рынок Сухума', 'Sukhum Central Market', 'Сухум орталық базары', 43.00140000, 41.01890000, 'Sukhum Central Market Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('sukhum-promenade', 'sukhum', 'FOOD', 2, 'HOURS', 4.6, 'Набережная Сухума', 'Sukhum Promenade', 'Сухум жағалауы', 42.99980000, 41.02150000, 'Sukhum Promenade Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('sukhum-beach', 'sukhum', 'BEACH', 3, 'HOURS', 4.4, 'Центральный пляж Сухума', 'Sukhum Central Beach', 'Сухум орталық жағажайы', 42.99790000, 41.02220000, 'Sukhum Central Beach Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),
    ('sukhum-shopping-rows', 'sukhum', 'SHOPPING', 2, 'HOURS', 4.2, 'Торговые ряды Сухума', 'Sukhum Shopping Rows', 'Сухум сауда қатарлары', 43.00100000, 41.01930000, 'Sukhum shopping rows Abkhazia', ARRAY['sukhum']::text[], ARRAY['sukhum']::text[], 'Botanical garden.Sukhum.jpg'),

    ('gagra-colonnade', 'gagra', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Гагрская колоннада', 'Gagra Colonnade', 'Гагра колоннадасы', 43.32150000, 40.23690000, 'Gagra Colonnade Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('gagra-seaside-park', 'gagra', 'PARK', 3, 'HOURS', 4.7, 'Приморский парк Гагры', 'Gagra Seaside Park', 'Гагра теңіз жағалауы саябағы', 43.32300000, 40.22950000, 'Gagra Seaside Park Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('oldenburg-prince-castle', 'gagra', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Замок принца Ольденбургского', 'Oldenburg Prince Castle', 'Ольденбург князі қамалы', 43.32550000, 40.22570000, 'Oldenburg Prince Castle Gagra Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('gagripsh-restaurant', 'gagra', 'FOOD', 2, 'HOURS', 4.6, 'Ресторан Гагрипш', 'Gagripsh Restaurant', 'Гагрипш мейрамханасы', 43.32270000, 40.23400000, 'Gagripsh Restaurant Gagra Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('abaata-fortress', 'gagra', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Крепость Абаата', 'Abaata Fortress', 'Абаата бекінісі', 43.32560000, 40.22360000, 'Abaata Fortress Gagra Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('gagra-aquapark', 'gagra', 'ENTERTAINMENT', 3, 'HOURS', 4.3, 'Аквапарк Гагра', 'Gagra Aquapark', 'Гагра аквапаркі', 43.28400000, 40.26450000, 'Gagra Aquapark Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('gagra-market', 'gagra', 'MARKET', 2, 'HOURS', 4.3, 'Гагрский рынок', 'Gagra Market', 'Гагра базары', 43.27960000, 40.26590000, 'Gagra Market Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Gagra. Colonnade in Primorsky Park P9090058 2600.jpg'),
    ('mount-mamzyshkha', 'gagra', 'NATURE', 4, 'HOURS', 4.8, 'Гора Мамзышха', 'Mount Mamzyshkha', 'Мамзышха тауы', 43.32300000, 40.32400000, 'Mount Mamzyshkha Gagra Abkhazia', ARRAY['gagra']::text[], ARRAY['gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),

    ('pitsunda-cathedral', 'pitsunda', 'TEMPLE', 1, 'HOURS', 4.8, 'Пицундский собор', 'Pitsunda Cathedral', 'Пицунда соборы', 43.15990000, 40.33900000, 'Pitsunda Cathedral Abkhazia', ARRAY['pitsunda']::text[], ARRAY['pitsunda']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('great-pitiunt-reserve', 'pitsunda', 'MUSEUM', 2, 'HOURS', 4.6, 'Заповедник Великий Питиунт', 'Great Pitiunt Reserve', 'Ұлы Питиунт қорығы', 43.15990000, 40.33900000, 'Great Pitiunt Pitsunda Abkhazia', ARRAY['pitsunda']::text[], ARRAY['pitsunda']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('pitsunda-pine-grove', 'pitsunda', 'NATURE', 3, 'HOURS', 4.7, 'Пицундская сосновая роща', 'Pitsunda Pine Grove', 'Пицунда қарағай тоғайы', 43.16650000, 40.33550000, 'Pitsunda Pine Grove Abkhazia', ARRAY['pitsunda']::text[], ARRAY['pitsunda']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('pitsunda-central-beach', 'pitsunda', 'BEACH', 4, 'HOURS', 4.6, 'Центральный пляж Пицунды', 'Pitsunda Central Beach', 'Пицунда орталық жағажайы', 43.16150000, 40.33200000, 'Pitsunda Central Beach Abkhazia', ARRAY['pitsunda']::text[], ARRAY['pitsunda']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('pitsunda-dolphinarium', 'pitsunda', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Дельфинарий в Пицунде', 'Pitsunda Dolphinarium', 'Пицунда дельфинарийі', 43.16300000, 40.33370000, 'Pitsunda Dolphinarium Abkhazia', ARRAY['pitsunda']::text[], ARRAY['pitsunda']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),

    ('lake-ritsa', 'lake-ritsa', 'NATURE', 4, 'HOURS', 4.9, 'Озеро Рица', 'Lake Ritsa', 'Рица көлі', 43.48110000, 40.54150000, 'Lake Ritsa Abkhazia', ARRAY['lake-ritsa', 'gagra']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),
    ('ritsa-relict-national-park', 'lake-ritsa', 'PARK', 5, 'HOURS', 4.9, 'Рицинский реликтовый национальный парк', 'Ritsa Relict National Park', 'Рица реликт ұлттық паркі', 43.48000000, 40.54000000, 'Ritsa Relict National Park Abkhazia', ARRAY['lake-ritsa', 'gagra']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),
    ('blue-lake-abkhazia', 'lake-ritsa', 'NATURE', 1, 'HOURS', 4.7, 'Голубое озеро', 'Blue Lake', 'Көгілдір көл', 43.35670000, 40.44360000, 'Blue Lake Abkhazia Lake Ritsa', ARRAY['lake-ritsa', 'gagra']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),
    ('yupshara-canyon', 'lake-ritsa', 'NATURE', 1, 'HOURS', 4.7, 'Юпшарский каньон', 'Yupshara Canyon', 'Юпшара каньоны', 43.43100000, 40.50400000, 'Yupshara Canyon Abkhazia', ARRAY['lake-ritsa', 'gagra']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),
    ('gegsky-waterfall', 'lake-ritsa', 'NATURE', 2, 'HOURS', 4.8, 'Гегский водопад', 'Gegsky Waterfall', 'Гег сарқырамасы', 43.44200000, 40.44400000, 'Gegsky Waterfall Abkhazia', ARRAY['lake-ritsa', 'gagra']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Gegsky waterfall P9100123 2600.jpg'),
    ('stalin-dacha-lake-ritsa', 'lake-ritsa', 'MUSEUM', 2, 'HOURS', 4.5, 'Дача Сталина на Рице', 'Stalin Dacha at Lake Ritsa', 'Рицадағы Сталин саяжайы', 43.48200000, 40.54600000, 'Stalin Dacha Lake Ritsa Abkhazia', ARRAY['lake-ritsa']::text[], ARRAY['lake-ritsa', 'gagra']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),

    ('new-athos-cave', 'new-athos', 'NATURE', 3, 'HOURS', 4.9, 'Новоафонская пещера', 'New Athos Cave', 'Жаңа Афон үңгірі', 43.09140000, 40.80870000, 'New Athos Cave Abkhazia', ARRAY['new-athos']::text[], ARRAY['new-athos', 'sukhum']::text[], 'Abkhazia. New Athos Cave P9110233 2925.jpg'),
    ('new-athos-monastery', 'new-athos', 'TEMPLE', 2, 'HOURS', 4.8, 'Новоафонский монастырь', 'New Athos Monastery', 'Жаңа Афон монастыры', 43.08770000, 40.82030000, 'New Athos Monastery Abkhazia', ARRAY['new-athos']::text[], ARRAY['new-athos', 'sukhum']::text[], '2014 Nowy Aton, Monaster Nowy Athos (19).jpg'),
    ('anakopia-fortress', 'new-athos', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Анакопийская крепость', 'Anakopia Fortress', 'Анакопия бекінісі', 43.08880000, 40.81090000, 'Anakopia Fortress New Athos Abkhazia', ARRAY['new-athos']::text[], ARRAY['new-athos']::text[], '2014 Nowy Aton, Twierdza Anakopia (02).jpg'),
    ('psyrtskha-station-waterfall', 'new-athos', 'PARK', 1, 'HOURS', 4.6, 'Станция Псырцха и водопад', 'Psyrtskha Station and Waterfall', 'Псырцха станциясы және сарқырама', 43.09050000, 40.81200000, 'Psyrtskha Station Waterfall New Athos Abkhazia', ARRAY['new-athos']::text[], ARRAY['new-athos']::text[], '2014 Nowy Aton, Monaster Nowy Athos (19).jpg'),
    ('simon-canaanite-church', 'new-athos', 'TEMPLE', 1, 'HOURS', 4.6, 'Храм Симона Кананита', 'Simon the Canaanite Church', 'Симон Кананит шіркеуі', 43.08750000, 40.81520000, 'Simon the Canaanite Church New Athos Abkhazia', ARRAY['new-athos']::text[], ARRAY['new-athos']::text[], '2014 Nowy Aton, Monaster Nowy Athos (19).jpg'),

    ('lykhny-church', 'gudauta', 'TEMPLE', 1, 'HOURS', 4.7, 'Лыхненский храм', 'Lykhny Church', 'Лыхны шіркеуі', 43.14360000, 40.61500000, 'Lykhny Church Gudauta Abkhazia', ARRAY['gudauta']::text[], ARRAY['gudauta', 'new-athos']::text[], '2014 Nowy Aton, Monaster Nowy Athos (19).jpg'),
    ('gudauta-beach', 'gudauta', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Гудауты', 'Gudauta Beach', 'Гудаута жағажайы', 43.10210000, 40.62670000, 'Gudauta Beach Abkhazia', ARRAY['gudauta']::text[], ARRAY['gudauta']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('gudauta-market', 'gudauta', 'MARKET', 2, 'HOURS', 4.2, 'Рынок Гудауты', 'Gudauta Market', 'Гудаута базары', 43.10570000, 40.62310000, 'Gudauta Market Abkhazia', ARRAY['gudauta']::text[], ARRAY['gudauta']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),

    ('tkvarcheli-akarmara', 'tkvarcheli', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Акармара в Ткуарчале', 'Tkvarcheli Akarmara', 'Ткуарчал Акармара', 42.85940000, 41.77120000, 'Akarmara Tkvarcheli Abkhazia', ARRAY['tkvarcheli']::text[], ARRAY['tkvarcheli', 'sukhum']::text[], 'Abkhazia. Gegsky waterfall P9100123 2600.jpg'),
    ('velikan-waterfall', 'tkvarcheli', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Великан', 'Velikan Waterfall', 'Великан сарқырамасы', 42.88420000, 41.81080000, 'Velikan Waterfall Tkvarcheli Abkhazia', ARRAY['tkvarcheli']::text[], ARRAY['tkvarcheli']::text[], 'Abkhazia. Gegsky waterfall P9100123 2600.jpg'),
    ('abrskil-cave', 'otap', 'NATURE', 2, 'HOURS', 4.7, 'Пещера Абрскила', 'Abrskil Cave', 'Абрскил үңгірі', 42.81000000, 41.54000000, 'Abrskil Cave Otap Abkhazia', ARRAY['otap', 'ochamchira']::text[], ARRAY['otap', 'ochamchira']::text[], 'Abkhazia. New Athos Cave P9110233 2925.jpg'),
    ('mokva-cathedral', 'ochamchira', 'TEMPLE', 1, 'HOURS', 4.6, 'Моквский собор', 'Mokva Cathedral', 'Моква соборы', 42.83500000, 41.50780000, 'Mokva Cathedral Abkhazia', ARRAY['ochamchira']::text[], ARRAY['ochamchira', 'sukhum']::text[], 'Pitsunda Cathedral, Abkhazia.jpg'),
    ('kyndyg-hot-springs', 'ochamchira', 'NATURE', 3, 'HOURS', 4.5, 'Кындыгские термальные источники', 'Kyndyg Hot Springs', 'Кындыг термалды көздері', 42.79890000, 41.25830000, 'Kyndyg Hot Springs Abkhazia', ARRAY['ochamchira']::text[], ARRAY['ochamchira', 'sukhum']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg'),
    ('ochamchira-central-market', 'ochamchira', 'MARKET', 1, 'HOURS', 4.1, 'Центральный рынок Очамчиры', 'Ochamchira Central Market', 'Очамчира орталық базары', 42.71230000, 41.46860000, 'Ochamchira Central Market Abkhazia', ARRAY['ochamchira']::text[], ARRAY['ochamchira']::text[], 'Botanical garden.Sukhum.jpg'),
    ('ochamchira-beach', 'ochamchira', 'BEACH', 3, 'HOURS', 4.3, 'Пляж Очамчиры', 'Ochamchira Beach', 'Очамчира жағажайы', 42.70430000, 41.46520000, 'Ochamchira Beach Abkhazia', ARRAY['ochamchira']::text[], ARRAY['ochamchira']::text[], 'Botanical garden.Sukhum.jpg'),
    ('gali-market', 'gali', 'MARKET', 2, 'HOURS', 4.2, 'Гальский рынок', 'Gali Market', 'Гал базары', 42.62660000, 41.73810000, 'Gali Market Abkhazia', ARRAY['gali']::text[], ARRAY['gali']::text[], 'Botanical garden.Sukhum.jpg'),
    ('gali-reservoir', 'gali', 'NATURE', 2, 'HOURS', 4.4, 'Гальское водохранилище', 'Gali Reservoir', 'Гал су қоймасы', 42.65410000, 41.80190000, 'Gali Reservoir Abkhazia', ARRAY['gali']::text[], ARRAY['gali']::text[], 'Abkhazia. Lake Ritsa P9100146 2600.jpg');

CREATE TEMP TABLE seed_abkhazia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-abkhazia-place:' || seed.slug) AS place_hash,
        md5('id-abkhazia-media:' || seed.slug) AS media_hash
    FROM seed_abkhazia_priority_places seed
)
SELECT
    (
        substr(place_hash, 1, 8) || '-' ||
        substr(place_hash, 9, 4) || '-4' ||
        substr(place_hash, 14, 3) || '-8' ||
        substr(place_hash, 18, 3) || '-' ||
        substr(place_hash, 21, 12)
    )::uuid AS id,
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    ARRAY['abkhazia', city_id, slug, lower(category), 'abkhazia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Абхазии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Abkhazia tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Абхазия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
    access_city_ids,
    departure_city_ids,
    (
        substr(media_hash, 1, 8) || '-' ||
        substr(media_hash, 9, 4) || '-4' ||
        substr(media_hash, 14, 3) || '-8' ||
        substr(media_hash, 18, 3) || '-' ||
        substr(media_hash, 21, 12)
    )::uuid AS media_id,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || media_file || '?width=1400' AS media_url,
    'https://commons.wikimedia.org/wiki/File:' || media_file AS source_url
FROM hashed;

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
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'AB',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 1000::numeric
        ELSE 500::numeric
    END,
    'RUB',
    duration_value,
    duration_unit,
    rating,
    0,
    NULL,
    'IMPORT',
    'PUBLISHED',
    tags,
    NOW(),
    NOW()
FROM seed_abkhazia_resolved_places
ON CONFLICT (id) DO UPDATE SET
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
    'ru',
    title_ru,
    description_ru,
    NOW(),
    NOW()
FROM seed_abkhazia_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_abkhazia_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_abkhazia_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE places a
SET
    latitude = seed.latitude,
    longitude = seed.longitude,
    location_source_url = seed.location_source_url,
    updated_at = NOW()
FROM seed_abkhazia_resolved_places seed
WHERE a.id = seed.id;

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
    source_url,
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM seed_abkhazia_resolved_places
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
    id,
    place_id,
    kind,
    country_code,
    city_id,
    position,
    created_at
)
SELECT
    gen_random_uuid(),
    id,
    'ACCESS',
    'AB',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_abkhazia_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'AB',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_abkhazia_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_abkhazia_resolved_places;
DROP TABLE IF EXISTS seed_abkhazia_priority_places;
