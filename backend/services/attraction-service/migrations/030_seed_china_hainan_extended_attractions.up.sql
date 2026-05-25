-- Extended Hainan destination seed.
-- Hainan is a tourist region inside China, while every attraction remains tied
-- to a concrete city or practical island-area reference.

DROP TABLE IF EXISTS seed_china_hainan_resolved_attractions;
DROP TABLE IF EXISTS seed_china_hainan_attractions;

UPDATE attractions
SET
    tags = array_append(COALESCE(tags, ARRAY[]::text[]), 'hainan'),
    updated_at = NOW()
WHERE country_code = 'CN'
  AND city_id = 'sanya'
  AND tags @> ARRAY['china-seed-v1']::text[]
  AND NOT tags @> ARRAY['hainan']::text[];

CREATE TEMP TABLE seed_china_hainan_attractions (
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
    media_file text NOT NULL
);

INSERT INTO seed_china_hainan_attractions (
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
    media_file
) VALUES
    ('haikou-qilou-old-street', 'haikou', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старая улица Цилоу в Хайкоу', 'Haikou Qilou Old Street', 'Хайкоу Цилоу ескі көшесі', 20.04560000, 110.34080000, 'Haikou Qilou Old Street Hainan China', 'Yalong_Bay_01.jpg'),
    ('hainan-museum', 'haikou', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Хайнаня', 'Hainan Museum', 'Хайнань музейі', 20.01750000, 110.37470000, 'Hainan Museum Haikou China', 'Hainan Science and Technology Museum 01.jpg'),
    ('holiday-beach-haikou', 'haikou', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Holiday Beach', 'Holiday Beach', 'Holiday Beach жағажайы', 20.03600000, 110.20300000, 'Holiday Beach Haikou Hainan China', 'Yalong_Bay_01.jpg'),
    ('mission-hills-haikou', 'haikou', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Mission Hills Haikou', 'Mission Hills Haikou', 'Mission Hills Haikou', 19.93100000, 110.33000000, 'Mission Hills Haikou Hainan China', 'Yalong_Bay_01.jpg'),
    ('haikou-international-duty-free-city', 'haikou', 'SHOPPING', 3, 'HOURS', 4.4, 'Haikou International Duty Free City', 'Haikou International Duty Free City', 'Haikou International Duty Free City', 20.04250000, 110.16200000, 'Haikou International Duty Free City Hainan China', 'Yalong_Bay_01.jpg'),
    ('wugong-temple-haikou', 'haikou', 'TEMPLE', 1, 'HOURS', 4.4, 'Храм Угун в Хайкоу', 'Wugong Temple Haikou', 'Хайкоу Угун храмы', 20.01820000, 110.35560000, 'Wugong Temple Haikou Hainan China', 'Yalong_Bay_01.jpg'),
    ('haikou-dingcun-seafood-night-market', 'haikou', 'FOOD', 2, 'HOURS', 4.4, 'Ночной рынок морепродуктов Динцунь', 'Dingcun Seafood Night Market', 'Динцунь теңіз өнімдері түнгі базары', 20.00600000, 110.32900000, 'Dingcun Seafood Night Market Haikou Hainan China', 'Yalong_Bay_01.jpg'),
    ('dadonghai-beach', 'sanya', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Дадунхай', 'Dadonghai Beach', 'Дадунхай жағажайы', 18.22000000, 109.51200000, 'Dadonghai Beach Sanya Hainan China', 'Sanya_Bay.jpg'),
    ('sanya-bay', 'sanya', 'BEACH', 3, 'HOURS', 4.5, 'Бухта Санья', 'Sanya Bay', 'Санья шығанағы', 18.25700000, 109.45000000, 'Sanya Bay Hainan China', 'Sanya_Bay.jpg'),
    ('luhuitou-park', 'sanya', 'PARK', 2, 'HOURS', 4.6, 'Парк Лухуэйтоу', 'Luhuitou Park', 'Лухуэйтоу саябағы', 18.21700000, 109.50500000, 'Luhuitou Park Sanya Hainan China', 'Sanya_Bay.jpg'),
    ('yalong-bay-tropical-paradise-forest-park', 'sanya', 'PARK', 4, 'HOURS', 4.7, 'Лесной парк тропического рая Ялунвань', 'Yalong Bay Tropical Paradise Forest Park', 'Ялунвань тропикалық жұмақ орман паркі', 18.23600000, 109.65500000, 'Yalong Bay Tropical Paradise Forest Park Sanya China', 'Yalong_Bay_01.jpg'),
    ('sanya-romance-park', 'sanya', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Sanya Romance Park', 'Sanya Romance Park', 'Sanya Romance Park', 18.29600000, 109.50300000, 'Sanya Romance Park Hainan China', 'Sanya_Bay.jpg'),
    ('first-market-sanya', 'sanya', 'MARKET', 2, 'HOURS', 4.3, 'Первый рынок Саньи', 'Sanya First Market', 'Санья бірінші базары', 18.25200000, 109.51200000, 'Sanya First Market Hainan China', 'Sanya_Bay.jpg'),
    ('riyue-bay', 'wanning', 'BEACH', 4, 'HOURS', 4.7, 'Бухта Жиюэ', 'Riyue Bay', 'Жиюэ шығанағы', 18.63000000, 110.23000000, 'Riyue Bay Wanning Hainan China', 'Yalong_Bay_01.jpg'),
    ('shimei-bay', 'wanning', 'BEACH', 3, 'HOURS', 4.6, 'Бухта Шимэй', 'Shimei Bay', 'Шимэй шығанағы', 18.67000000, 110.25000000, 'Shimei Bay Wanning Hainan China', 'Yalong_Bay_01.jpg'),
    ('xinglong-tropical-botanical-garden', 'wanning', 'NATURE', 2, 'HOURS', 4.6, 'Тропический ботанический сад Синлун', 'Xinglong Tropical Botanical Garden', 'Синлун тропикалық ботаникалық бағы', 18.73500000, 110.19000000, 'Xinglong Tropical Botanical Garden Wanning Hainan China', 'Yalong_Bay_01.jpg'),
    ('xinglong-coffee-valley', 'wanning', 'FOOD', 2, 'HOURS', 4.4, 'Кофейная долина Синлун', 'Xinglong Coffee Valley', 'Синлун кофе аңғары', 18.74600000, 110.18800000, 'Xinglong Coffee Valley Wanning Hainan China', 'Yalong_Bay_01.jpg'),
    ('boundary-island', 'lingshui', 'NATURE', 4, 'HOURS', 4.7, 'Остров Фэньцзечжоу', 'Boundary Island', 'Фэньцзечжоу аралы', 18.57600000, 110.19600000, 'Boundary Island Lingshui Hainan China', 'Yalong_Bay_01.jpg'),
    ('nanwan-monkey-island', 'lingshui', 'NATURE', 3, 'HOURS', 4.6, 'Остров обезьян Наньвань', 'Nanwan Monkey Island', 'Наньвань маймылдар аралы', 18.39700000, 109.96900000, 'Nanwan Monkey Island Lingshui Hainan China', 'Yalong_Bay_01.jpg'),
    ('hainan-ocean-paradise', 'lingshui', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Hainan Ocean Paradise', 'Hainan Ocean Paradise', 'Hainan Ocean Paradise', 18.51400000, 110.03700000, 'Hainan Ocean Paradise Lingshui China', 'Yalong_Bay_01.jpg'),
    ('perfume-bay', 'lingshui', 'BEACH', 3, 'HOURS', 4.4, 'Бухта Сяншуй', 'Perfume Bay', 'Сяншуй шығанағы', 18.45400000, 110.02000000, 'Perfume Bay Lingshui Hainan China', 'Yalong_Bay_01.jpg'),
    ('boao-forum-for-asia-permanent-site', 'qionghai', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Постоянная площадка Боаоского азиатского форума', 'Boao Forum for Asia Permanent Site', 'Боао Азия форумы тұрақты алаңы', 19.15900000, 110.58100000, 'Boao Forum for Asia Permanent Site Qionghai China', 'Yalong_Bay_01.jpg'),
    ('yudai-beach', 'qionghai', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Юйдай', 'Yudai Beach', 'Юйдай жағажайы', 19.15500000, 110.59000000, 'Yudai Beach Boao Qionghai Hainan China', 'Yalong_Bay_01.jpg'),
    ('tanmen-fishing-port-market', 'qionghai', 'MARKET', 2, 'HOURS', 4.3, 'Рыбный порт и рынок Таньмэнь', 'Tanmen Fishing Port Market', 'Таньмэнь балық порты базары', 19.24100000, 110.61500000, 'Tanmen Fishing Port Market Qionghai Hainan China', 'Yalong_Bay_01.jpg'),
    ('wanquan-river', 'qionghai', 'NATURE', 2, 'HOURS', 4.4, 'Река Ваньцюань', 'Wanquan River', 'Ваньцюань өзені', 19.24200000, 110.47500000, 'Wanquan River Qionghai Hainan China', 'Yalong_Bay_01.jpg'),
    ('wenchang-space-launch-site', 'wenchang', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Космодром Вэньчан', 'Wenchang Space Launch Site', 'Вэньчан ғарыш айлағы', 19.61400000, 110.95100000, 'Wenchang Space Launch Site Hainan China', 'Yalong_Bay_01.jpg'),
    ('dongjiao-coconut-plantation', 'wenchang', 'NATURE', 2, 'HOURS', 4.4, 'Кокосовая плантация Дунцзяо', 'Dongjiao Coconut Plantation', 'Дунцзяо кокос плантациясы', 19.62000000, 110.86500000, 'Dongjiao Coconut Plantation Wenchang Hainan China', 'Yalong_Bay_01.jpg'),
    ('tongguling-scenic-area', 'wenchang', 'NATURE', 3, 'HOURS', 4.5, 'Гора Тунгулин', 'Tongguling Scenic Area', 'Тунгулин көрікті аймағы', 19.63700000, 111.03000000, 'Tongguling Scenic Area Wenchang Hainan China', 'Yalong_Bay_01.jpg'),
    ('ocean-flower-island', 'danzhou', 'ENTERTAINMENT', 4, 'HOURS', 4.4, 'Остров Ocean Flower', 'Ocean Flower Island', 'Ocean Flower аралы', 19.70600000, 109.15500000, 'Ocean Flower Island Danzhou Hainan China', 'Yalong_Bay_01.jpg'),
    ('dongpo-academy-danzhou', 'danzhou', 'MUSEUM', 2, 'HOURS', 4.4, 'Академия Дунпо в Даньчжоу', 'Dongpo Academy Danzhou', 'Даньчжоу Дунпо академиясы', 19.51800000, 109.58500000, 'Dongpo Academy Danzhou Hainan China', 'Yalong_Bay_01.jpg');

CREATE TEMP TABLE seed_china_hainan_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-china-hainan-attraction:' || seed.slug) AS attraction_hash,
        md5('id-china-hainan-media:' || seed.slug) AS media_hash
    FROM seed_china_hainan_attractions seed
)
SELECT
    (
        substr(attraction_hash, 1, 8) || '-' ||
        substr(attraction_hash, 9, 4) || '-4' ||
        substr(attraction_hash, 14, 3) || '-8' ||
        substr(attraction_hash, 18, 3) || '-' ||
        substr(attraction_hash, 21, 12)
    )::uuid AS id,
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    ARRAY['china', 'hainan', city_id, slug, lower(category), 'china-hainan-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Хайнаня: ' || title_ru || '. Подходит для поиска по Китаю, Хайнаню, городу и категории.' AS description_ru,
    'Hainan tourist place: ' || title_en || '. Useful for search by China, Hainan, city and category.' AS description_en,
    'Хайнань бағыты бойынша туристік орын: ' || title_kk || '. Қытай, Хайнань, қала және санат бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
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

INSERT INTO attractions (
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
    'CN',
    city_id,
    category,
    NULL::numeric,
    NULL::varchar(3),
    duration_value,
    duration_unit,
    rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    tags,
    NOW(),
    NOW()
FROM seed_china_hainan_resolved_attractions
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    updated_at = NOW();

INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT id, 'ru', title_ru, description_ru, NOW(), NOW()
FROM seed_china_hainan_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_china_hainan_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_china_hainan_resolved_attractions
ON CONFLICT (attraction_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE attractions a
SET
    latitude = s.latitude,
    longitude = s.longitude,
    location_source_url = s.location_source_url,
    updated_at = NOW()
FROM seed_china_hainan_resolved_attractions s
WHERE a.id = s.id;

INSERT INTO attraction_media (
    id,
    attraction_id,
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
FROM seed_china_hainan_resolved_attractions
ON CONFLICT (id) DO UPDATE SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO attraction_city_links (
    id,
    attraction_id,
    kind,
    country_code,
    city_id,
    position,
    created_at
)
SELECT gen_random_uuid(), id, kind, 'CN', city_id, 0, NOW()
FROM seed_china_hainan_resolved_attractions
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_china_hainan_resolved_attractions;
DROP TABLE IF EXISTS seed_china_hainan_attractions;
