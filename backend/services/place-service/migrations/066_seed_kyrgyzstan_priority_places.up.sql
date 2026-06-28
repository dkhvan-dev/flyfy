-- Priority Kyrgyzstan destination places seed.
-- The seed covers Bishkek, Issyk-Kul, Naryn highlands, southern heritage routes, western reservoirs and mountain recreation.

DROP TABLE IF EXISTS seed_kyrgyzstan_resolved_places;
DROP TABLE IF EXISTS seed_kyrgyzstan_priority_places;

CREATE TEMP TABLE seed_kyrgyzstan_priority_places (
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

INSERT INTO seed_kyrgyzstan_priority_places (
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
    ('ala-too-square', 'bishkek', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Ала-Тоо', 'Ala-Too Square', 'Ала-Тоо алаңы', 42.87660000, 74.60300000, 'Ala-Too Square Bishkek', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Ala-Too Square Bishkek.jpg'),
    ('state-history-museum-bishkek', 'bishkek', 'MUSEUM', 2, 'HOURS', 4.5, 'Государственный исторический музей Кыргызстана', 'State History Museum Bishkek', 'Бішкек мемлекеттік тарих музейі', 42.87730000, 74.60410000, 'State History Museum Bishkek Kyrgyzstan', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Kyrgyz State Historical Museum, Ala Too Square, Bishkek, Kyrgyzstan.jpg'),
    ('osh-bazaar-bishkek', 'bishkek', 'MARKET', 2, 'HOURS', 4.6, 'Ошский базар в Бишкеке', 'Osh Bazaar Bishkek', 'Бішкек Ош базары', 42.87400000, 74.57150000, 'Osh Bazaar Bishkek', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Osh bazaar Bishkek.jpg'),
    ('dordoi-bazaar', 'bishkek', 'MARKET', 3, 'HOURS', 4.4, 'Базар Дордой', 'Dordoi Bazaar', 'Дордой базары', 42.93510000, 74.62050000, 'Dordoi Bazaar Bishkek', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'E7919-Dordoy-Bazaar-clothing.jpg'),
    ('bishkek-park-mall', 'bishkek', 'SHOPPING', 2, 'HOURS', 4.4, 'Bishkek Park Mall', 'Bishkek Park Mall', 'Bishkek Park Mall', 42.87320000, 74.58830000, 'Bishkek Park Mall', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Bishkek.jpg'),
    ('oak-park-bishkek', 'bishkek', 'PARK', 1, 'HOURS', 4.5, 'Дубовый парк Бишкека', 'Oak Park Bishkek', 'Бішкек емен паркі', 42.87950000, 74.60900000, 'Oak Park Bishkek', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Oak Park in Bishkek.jpg'),
    ('supara-ethno-complex', 'bishkek', 'FOOD', 2, 'HOURS', 4.6, 'Этнокомплекс Супара', 'Supara Ethno Complex', 'Супара этно кешені', 42.79970000, 74.67650000, 'Supara Ethno Complex Bishkek', ARRAY['bishkek']::text[], ARRAY['bishkek']::text[], 'Bishkek, Kyrgyzstan (29724266627).jpg'),
    ('ala-archa-national-park', 'ala-archa', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Ала-Арча', 'Ala Archa National Park', 'Ала-Арча ұлттық паркі', 42.56700000, 74.48000000, 'Ala Archa National Park Kyrgyzstan', ARRAY['ala-archa']::text[], ARRAY['bishkek', 'ala-archa']::text[], 'Ala-Archa National Park in Kyrgyzstan.jpg'),
    ('burana-tower', 'tokmok', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Башня Бурана', 'Burana Tower', 'Бурана мұнарасы', 42.74670000, 75.25030000, 'Burana Tower Tokmok Kyrgyzstan', ARRAY['tokmok']::text[], ARRAY['bishkek', 'tokmok']::text[], 'Burana Tower, Kyrgyzstan.jpg'),
    ('chunkurchak-gorge', 'chunkurchak', 'NATURE', 4, 'HOURS', 4.6, 'Ущелье Чункурчак', 'Chunkurchak Gorge', 'Чункурчак шатқалы', 42.64000000, 74.65000000, 'Chunkurchak Gorge Kyrgyzstan', ARRAY['chunkurchak']::text[], ARRAY['bishkek', 'chunkurchak']::text[], 'Chunkurchak, Chuy region, Kyrgyzstan.jpg'),
    ('issyk-ata-gorge', 'issyk-ata', 'NATURE', 4, 'HOURS', 4.6, 'Ущелье Иссык-Ата', 'Issyk-Ata Gorge', 'Ыстық-Ата шатқалы', 42.60360000, 74.95050000, 'Issyk-Ata Gorge Kyrgyzstan', ARRAY['issyk-ata']::text[], ARRAY['bishkek', 'issyk-ata']::text[], 'Ysyk Ata waterfall view from the river, Ysyk Ata Gorge, Kyrgyzstan.jpg'),

    ('issyk-kul-lake', 'cholpon-ata', 'BEACH', 5, 'HOURS', 4.8, 'Озеро Иссык-Куль', 'Issyk-Kul Lake', 'Ыстықкөл көлі', 42.45400000, 77.17000000, 'Issyk-Kul Lake Kyrgyzstan', ARRAY['cholpon-ata', 'balykchy', 'karakol']::text[], ARRAY['bishkek', 'cholpon-ata', 'balykchy', 'karakol']::text[], 'Lake Issyk-Kul, Kyrgyzstan.jpg'),
    ('rukh-ordo-cultural-center', 'cholpon-ata', 'MUSEUM', 2, 'HOURS', 4.6, 'Культурный центр Рух Ордо', 'Rukh Ordo Cultural Center', 'Рух Ордо мәдени орталығы', 42.64600000, 77.08090000, 'Rukh Ordo Cultural Center Cholpon-Ata', ARRAY['cholpon-ata']::text[], ARRAY['cholpon-ata']::text[], 'Lake Issyk-Kul, Kyrgyzstan.jpg'),
    ('cholpon-ata-petroglyphs', 'cholpon-ata', 'MUSEUM', 2, 'HOURS', 4.6, 'Петроглифы Чолпон-Аты', 'Cholpon-Ata Petroglyphs', 'Шолпан-Ата петроглифтері', 42.66220000, 77.07030000, 'Cholpon-Ata Petroglyphs Kyrgyzstan', ARRAY['cholpon-ata']::text[], ARRAY['cholpon-ata']::text[], 'Petroglyph Museum of Cholpon-Ata 07.jpg'),
    ('balykchy-lakefront', 'balykchy', 'BEACH', 2, 'HOURS', 4.3, 'Набережная Балыкчы', 'Balykchy Lakefront', 'Балықшы жағалауы', 42.45500000, 76.18000000, 'Balykchy Lakefront Issyk-Kul', ARRAY['balykchy']::text[], ARRAY['bishkek', 'balykchy']::text[], 'Lake Issyk-Kul, Kyrgyzstan.jpg'),
    ('holy-trinity-cathedral-karakol', 'karakol', 'TEMPLE', 1, 'HOURS', 4.7, 'Свято-Троицкий собор Каракола', 'Holy Trinity Cathedral Karakol', 'Қаракөл Қасиетті Троица соборы', 42.49030000, 78.39350000, 'Holy Trinity Cathedral Karakol', ARRAY['karakol']::text[], ARRAY['karakol']::text[], 'Holy Trinity Church in Karakol.jpg'),
    ('dungan-mosque-karakol', 'karakol', 'TEMPLE', 1, 'HOURS', 4.7, 'Дунганская мечеть Каракола', 'Dungan Mosque Karakol', 'Қаракөл Дүнген мешіті', 42.49200000, 78.39680000, 'Dungan Mosque Karakol', ARRAY['karakol']::text[], ARRAY['karakol']::text[], 'Dungan mosque in Karakol.jpg'),
    ('karakol-animal-market', 'karakol', 'MARKET', 2, 'HOURS', 4.4, 'Скотный рынок Каракола', 'Karakol Animal Market', 'Қаракөл мал базары', 42.51670000, 78.38330000, 'Karakol Animal Market', ARRAY['karakol']::text[], ARRAY['karakol']::text[], 'Kyrgyzstan - Kyrgyz person in the market at Karakol.jpg'),
    ('jeti-oguz-rocks', 'jeti-oguz', 'NATURE', 3, 'HOURS', 4.8, 'Скалы Джети-Огуз', 'Jeti-Oguz Rocks', 'Жеті-Өгүз жартастары', 42.33330000, 78.23330000, 'Jeti-Oguz Rocks Kyrgyzstan', ARRAY['jeti-oguz']::text[], ARRAY['karakol', 'jeti-oguz']::text[], 'Jeti-Oguz rocks, Issyk Kul region, Kyrgyzstan 02.jpg'),
    ('barskoon-waterfalls', 'barskoon', 'NATURE', 3, 'HOURS', 4.7, 'Водопады Барскоон', 'Barskoon Waterfalls', 'Барскоон сарқырамалары', 42.16200000, 77.61800000, 'Barskoon Waterfalls Kyrgyzstan', ARRAY['barskoon']::text[], ARRAY['karakol', 'barskoon']::text[], 'Barskoön Waterfall.jpg'),
    ('skazka-fairy-tale-canyon', 'skazka-canyon', 'NATURE', 3, 'HOURS', 4.8, 'Каньон Сказка', 'Skazka Fairy Tale Canyon', 'Сказка ертегі шатқалы', 42.17420000, 77.35420000, 'Skazka Fairy Tale Canyon Kyrgyzstan', ARRAY['skazka-canyon']::text[], ARRAY['karakol', 'bokonbaevo', 'skazka-canyon']::text[], 'Skazka Canyon, Kyrgyzstan (43904244194).jpg'),
    ('bokonbaevo-eagle-hunting', 'bokonbaevo', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Шоу беркутчи в Боконбаево', 'Bokonbaevo Eagle Hunting', 'Боконбаево бүркітшілер шоуы', 42.11670000, 76.98330000, 'Bokonbaevo eagle hunting Kyrgyzstan', ARRAY['bokonbaevo']::text[], ARRAY['bokonbaevo', 'cholpon-ata']::text[], 'Bokonbaevo Eagle Hunter.jpg'),
    ('kaji-say-beach', 'kaji-say', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Каджи-Сай', 'Kaji-Say Beach', 'Қажы-Сай жағажайы', 42.16030000, 77.16730000, 'Kaji-Say Beach Issyk-Kul', ARRAY['kaji-say']::text[], ARRAY['bokonbaevo', 'kaji-say']::text[], 'Lake Issyk-Kul, Kyrgyzstan.jpg'),
    ('tamga-stone', 'tamga', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Камень Тамга-Таш', 'Tamga Tash Stone', 'Тамға-Таш тасы', 42.15000000, 77.53330000, 'Tamga Tash Stone Kyrgyzstan', ARRAY['tamga']::text[], ARRAY['karakol', 'tamga']::text[], 'Tamga Tash.jpg'),

    ('song-kul-lake', 'song-kul', 'NATURE', 6, 'HOURS', 4.9, 'Озеро Сон-Куль', 'Song-Kul Lake', 'Соңкөл көлі', 41.83330000, 75.15000000, 'Song-Kul Lake Kyrgyzstan', ARRAY['song-kul']::text[], ARRAY['kochkor', 'naryn', 'song-kul']::text[], 'Song-Kul, Kyrgyzstan (43670021735).jpg'),
    ('tash-rabat-caravanserai', 'tash-rabat', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Караван-сарай Таш-Рабат', 'Tash Rabat Caravanserai', 'Таш-Рабат керуен сарайы', 40.81780000, 75.28970000, 'Tash Rabat Caravanserai Kyrgyzstan', ARRAY['tash-rabat']::text[], ARRAY['naryn', 'at-bashy', 'tash-rabat']::text[], 'Tash Rabat.JPG'),
    ('kel-suu-lake', 'kel-suu', 'NATURE', 6, 'HOURS', 4.9, 'Озеро Кель-Суу', 'Kel-Suu Lake', 'Көл-Суу көлі', 40.63920000, 76.40690000, 'Kel-Suu Lake Kyrgyzstan', ARRAY['kel-suu']::text[], ARRAY['naryn', 'at-bashy', 'kel-suu']::text[], 'Kel-Suu.jpg'),
    ('kochkor-felt-workshops', 'kochkor', 'SHOPPING', 2, 'HOURS', 4.7, 'Войлочные мастерские Кочкора', 'Kochkor Felt Workshops', 'Кочкор киіз шеберханалары', 42.21670000, 75.75000000, 'Kochkor Felt Workshops Kyrgyzstan', ARRAY['kochkor']::text[], ARRAY['bishkek', 'kochkor']::text[], 'Kochkor Felt Workshops.jpg'),
    ('kochkor-sunday-livestock-market', 'kochkor', 'MARKET', 2, 'HOURS', 4.4, 'Воскресный скотный рынок Кочкора', 'Kochkor Sunday Livestock Market', 'Кочкор жексенбілік мал базары', 42.21600000, 75.75500000, 'Kochkor Sunday Livestock Market', ARRAY['kochkor']::text[], ARRAY['kochkor']::text[], 'Kochkor Livestock Market.jpg'),
    ('naryn-regional-museum', 'naryn', 'MUSEUM', 1, 'HOURS', 4.4, 'Нарынский областной музей', 'Naryn Regional Historical and Ethnographic Museum', 'Нарын тарихи-этнографиялық музейі', 41.42870000, 75.99110000, 'Naryn Regional Historical Ethnographic Museum', ARRAY['naryn']::text[], ARRAY['naryn']::text[], 'Naryn Kyrgyzstan Museum.jpg'),
    ('at-bashy-valley', 'at-bashy', 'NATURE', 4, 'HOURS', 4.6, 'Долина Ат-Башы', 'At-Bashy Valley', 'Ат-Башы аңғары', 41.17000000, 75.81000000, 'At-Bashy Valley Kyrgyzstan', ARRAY['at-bashy']::text[], ARRAY['naryn', 'at-bashy']::text[], 'At-Bashy Valley.jpg'),

    ('sulaiman-too-sacred-mountain', 'osh', 'TEMPLE', 3, 'HOURS', 4.9, 'Священная гора Сулайман-Тоо', 'Sulaiman-Too Sacred Mountain', 'Сулайман-Тоо қасиетті тауы', 40.52860000, 72.78330000, 'Sulaiman-Too Sacred Mountain Osh', ARRAY['osh']::text[], ARRAY['osh']::text[], 'Сулайман-Тоо музей.jpg'),
    ('jayma-bazaar-osh', 'osh', 'MARKET', 2, 'HOURS', 4.6, 'Базар Жайма в Оше', 'Jayma Bazaar Osh', 'Ош Жайма базары', 40.53000000, 72.79000000, 'Jayma Bazaar Osh Kyrgyzstan', ARRAY['osh']::text[], ARRAY['osh']::text[], 'Osh Bazaar Kyrgyzstan.jpg'),
    ('osh-national-historical-archaeological-museum', 'osh', 'MUSEUM', 2, 'HOURS', 4.5, 'Ошский историко-археологический музей', 'Osh National Historical and Archaeological Museum', 'Ош ұлттық тарихи-археологиялық музейі', 40.52980000, 72.78380000, 'Osh National Historical Archaeological Museum', ARRAY['osh']::text[], ARRAY['osh']::text[], 'Osh Museum Kyrgyzstan.jpg'),
    ('uzgen-minaret', 'uzgen', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Узгенский минарет', 'Uzgen Minaret', 'Өзгөн мұнарасы', 40.76940000, 73.30080000, 'Uzgen Minaret Kyrgyzstan', ARRAY['uzgen']::text[], ARRAY['osh', 'uzgen']::text[], 'Uzgen Minaret.jpg'),
    ('jalal-abad-resort-park', 'jalal-abad', 'PARK', 2, 'HOURS', 4.4, 'Курортный парк Джалал-Абада', 'Jalal-Abad Resort Park', 'Жалал-Абад курорттық паркі', 40.93330000, 73.00000000, 'Jalal-Abad resort park Kyrgyzstan', ARRAY['jalal-abad']::text[], ARRAY['jalal-abad']::text[], 'Jalal-Abad Kyrgyzstan.jpg'),
    ('arslanbob-walnut-forest', 'arslanbob', 'NATURE', 5, 'HOURS', 4.8, 'Ореховый лес Арсланбоб', 'Arslanbob Walnut Forest', 'Арсланбоб жаңғақ орманы', 41.33830000, 72.92640000, 'Arslanbob Walnut Forest Kyrgyzstan', ARRAY['arslanbob']::text[], ARRAY['jalal-abad', 'arslanbob']::text[], 'Walnut forest Arslanbob.jpg'),
    ('arslanbob-waterfalls', 'arslanbob', 'NATURE', 3, 'HOURS', 4.7, 'Водопады Арсланбоб', 'Arslanbob Waterfalls', 'Арсланбоб сарқырамалары', 41.33000000, 72.93000000, 'Arslanbob Waterfalls Kyrgyzstan', ARRAY['arslanbob']::text[], ARRAY['arslanbob']::text[], 'Walnut forest Arslanbob.jpg'),
    ('sary-chelek-biosphere-reserve', 'sary-chelek', 'PARK', 6, 'HOURS', 4.9, 'Биосферный заповедник Сары-Челек', 'Sary-Chelek Biosphere Reserve', 'Сары-Челек биосфералық қорығы', 41.87310000, 71.95670000, 'Sary-Chelek Biosphere Reserve Kyrgyzstan', ARRAY['sary-chelek']::text[], ARRAY['jalal-abad', 'sary-chelek']::text[], 'Sary Chelek Lake.jpg'),

    ('manas-ordo-complex', 'talas', 'MUSEUM', 2, 'HOURS', 4.7, 'Комплекс Манас Ордо', 'Manas Ordo Complex', 'Манас Ордо кешені', 42.51450000, 72.24050000, 'Manas Ordo Complex Talas', ARRAY['talas']::text[], ARRAY['bishkek', 'talas']::text[], 'Manas Ordo Kyrgyzstan.jpg'),
    ('toktogul-reservoir', 'toktogul', 'BEACH', 3, 'HOURS', 4.6, 'Токтогульское водохранилище', 'Toktogul Reservoir', 'Тоқтоғұл су қоймасы', 41.84490000, 72.98500000, 'Toktogul Reservoir Kyrgyzstan', ARRAY['toktogul']::text[], ARRAY['bishkek', 'toktogul']::text[], 'Toktogul Reservoir, Kyrgyzstan.jpg'),
    ('suusamyr-valley', 'suusamyr', 'NATURE', 5, 'HOURS', 4.7, 'Суусамырская долина', 'Suusamyr Valley', 'Суусамыр аңғары', 42.17000000, 73.84000000, 'Suusamyr Valley Kyrgyzstan', ARRAY['suusamyr']::text[], ARRAY['bishkek', 'suusamyr']::text[], 'Suusamyr Valley Kyrgyzstan.jpg');

CREATE TEMP TABLE seed_kyrgyzstan_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-kyrgyzstan-place:' || seed.slug) AS place_hash,
        md5('id-kyrgyzstan-media:' || seed.slug) AS media_hash
    FROM seed_kyrgyzstan_priority_places seed
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
    ARRAY['kyrgyzstan', city_id, slug, lower(category), 'kyrgyzstan-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Кыргызстана: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Kyrgyzstan tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Қырғызстан туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    country_code,
    city_id,
    category,
    default_locale,
    source,
    status,
    duration_value,
    duration_unit,
    price_amount,
    price_currency,
    rating,
    tags,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'KG',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 400::numeric
        ELSE 200::numeric
    END,
    'KGS',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_kyrgyzstan_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    default_locale = EXCLUDED.default_locale,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    rating = EXCLUDED.rating,
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
FROM seed_kyrgyzstan_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_kyrgyzstan_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_kyrgyzstan_resolved_places
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
FROM seed_kyrgyzstan_resolved_places seed
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
FROM seed_kyrgyzstan_resolved_places
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
    'KG',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_kyrgyzstan_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
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
    'DEPARTURE',
    'KG',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_kyrgyzstan_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
