-- Curated Phu Quoc places seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN and city_id is phu-quoc;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price_amount stores a conservative entry-price floor; 0 means free entry.

WITH seed_base (
    id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 'BEACH', 3, 'HOURS', 4.6, ARRAY['vietnam', 'phu-quoc', 'starfish-beach', 'rach-vem', 'beach', 'sea', 'family']::text[]),
        ('b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 'ENTERTAINMENT', 5, 'HOURS', 4.7, ARRAY['vietnam', 'phu-quoc', 'vinwonders', 'theme-park', 'family', 'water-park', 'entertainment']::text[]),
        ('68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 'ENTERTAINMENT', 5, 'HOURS', 4.7, ARRAY['vietnam', 'phu-quoc', 'sunworld', 'hon-thom', 'cable-car', 'island', 'entertainment']::text[]),
        ('6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 'NATURE', 2, 'HOURS', 4.5, ARRAY['vietnam', 'phu-quoc', 'suoi-tranh-waterfall', 'waterfall', 'forest', 'nature', 'short-walk']::text[]),
        ('8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 'BEACH', 3, 'HOURS', 4.6, ARRAY['vietnam', 'phu-quoc', 'khem-beach', 'beach', 'white-sand', 'seafood', 'relax']::text[]),
        ('0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 'ENTERTAINMENT', 2, 'HOURS', 4.6, ARRAY['vietnam', 'phu-quoc', 'kiss-of-the-sea', 'sunset-town', 'show', 'evening', 'family']::text[]),
        ('a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 'ENTERTAINMENT', 1, 'HOURS', 4.4, ARRAY['vietnam', 'phu-quoc', 'ice-jungle', 'indoor', 'family', 'grand-world', 'entertainment']::text[]),
        ('fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 'MUSEUM', 2, 'HOURS', 4.5, ARRAY['vietnam', 'phu-quoc', 'prison-history-museum', 'history', 'museum', 'war-memory', 'culture']::text[]),
        ('dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 'SHOPPING', 1, 'HOURS', 4.4, ARRAY['vietnam', 'phu-quoc', 'kingkong-mart', 'shopping', 'supermarket', 'souvenirs', 'city']::text[])
)
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
    seed_base.id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'VN',
    'phu-quoc',
    seed_base.category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 100000::numeric
        ELSE 50000::numeric
    END,
    'VND',
    seed_base.duration_value,
    seed_base.duration_unit,
    seed_base.rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    seed_base.tags,
    NOW(),
    NOW()
FROM seed_base
ON CONFLICT (id) DO UPDATE
SET
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
    updated_at = NOW(),
    deleted_at = NULL
WHERE places.source = 'IMPORT';

WITH seed_translations (
    place_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 'ru', 'Пляж морских звезд', 'Пляж на севере Фукуока рядом с рыбацкой зоной Рач Вем, известный мелкой водой, деревянными настилами и морскими звездами у берега. Это спокойная поездка на несколько часов, где важно не трогать животных и выбирать чистые участки пляжа.'),
        ('1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 'en', 'Starfish Beach', 'A northern Phu Quoc beach near the Rach Vem fishing area, known for shallow water, wooden walkways and starfish close to shore. It is a calm several-hour trip where visitors should avoid touching wildlife and choose clean beach sections.'),
        ('1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 'kk', 'Теңіз жұлдыздары жағажайы', 'Фукуоктың солтүстігіндегі Рач Вем балықшылар аймағы жанындағы таяз суы, ағаш өткелдері және жағалауға жақын теңіз жұлдыздарымен белгілі жағажай. Жануарларға тимей, таза бөліктерін таңдаған дұрыс тыныш бірнеше сағаттық сапар.'),

        ('b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 'ru', 'VinWonders Phu Quoc', 'Крупный парк развлечений на Фукуоке с аттракционами, аквапарком, шоу, тематическими зонами и семейной инфраструктурой. Подходит для полного дня, когда нужен понятный досуг с детьми или легкая пауза между пляжами.'),
        ('b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 'en', 'VinWonders Phu Quoc', 'A large Phu Quoc entertainment park with rides, a water park, shows, themed zones and family infrastructure. It works best as a full-day plan for travelers with children or an easy break between beach days.'),
        ('b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 'kk', 'VinWonders Фукуок', 'Фукуоктағы аттракциондары, аквапаркі, шоулары, тақырыптық аймақтары және отбасылық инфрақұрылымы бар үлкен ойын-сауық паркі. Балалармен толық күнге немесе жағажайлар арасындағы жеңіл үзіліске қолайлы.'),

        ('68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 'ru', 'SunWorld Hon Thom', 'Развлекательный комплекс на юге Фукуока, связанный с островом Хон Том канатной дорогой над морем. Маршрут хорошо сочетает виды с высоты, пляжный отдых, аквапарк и легкий островной формат на большую часть дня.'),
        ('68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 'en', 'SunWorld Hon Thom', 'An entertainment complex in southern Phu Quoc connected to Hon Thom Island by an over-sea cable car. The route combines high views, beach time, a water park and an easy island format for most of the day.'),
        ('68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 'kk', 'SunWorld Hon Thom', 'Фукуоктың оңтүстігіндегі Хон Том аралына теңіз үстіндегі аспалы жолмен қосылған ойын-сауық кешені. Биіктен көрініс, жағажай, аквапарк және жеңіл аралдық форматты күннің көп бөлігіне біріктіреді.'),

        ('6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 'ru', 'Водопад Суой Чань', 'Зеленая природная точка Фукуока с короткой прогулкой по лесу, ручьями, камнями и небольшим водопадом. Лучше подходит как легкий маршрут на пару часов в сезон, когда есть вода и тропы не перегружены.'),
        ('6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 'en', 'Suoi Tranh Waterfall', 'A green nature stop on Phu Quoc with a short forest walk, streams, rocks and a small waterfall. It is best as an easy couple-hour route in the season when there is water and the paths are not overcrowded.'),
        ('6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 'kk', 'Суой Чань сарқырамасы', 'Фукуоктағы қысқа орман серуені, бұлақтары, тастары және шағын сарқырамасы бар жасыл табиғи нүкте. Су бар және соқпақтар тым толы емес маусымда бірнеше сағаттық жеңіл маршрутқа жақсы.'),

        ('8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 'ru', 'Пляж Кхем', 'Южный пляж Фукуока с мягким светлым песком, спокойной водой и курортной инфраструктурой. Хорош для расслабленного отдыха, фото, плавания и маршрута, который можно совместить с Ан Тхой или Sunset Town.'),
        ('8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 'en', 'Khem Beach', 'A southern Phu Quoc beach with soft pale sand, calm water and resort infrastructure. It is good for relaxed time, photos, swimming and a route that can be paired with An Thoi or Sunset Town.'),
        ('8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 'kk', 'Кхем жағажайы', 'Фукуоктың оңтүстігіндегі жұмсақ ашық құмы, тыныш суы және курорттық инфрақұрылымы бар жағажай. Демалуға, фотоға, жүзуге және Ан Тхой немесе Sunset Town бағытымен біріктіруге қолайлы.'),

        ('0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 'ru', 'Kiss of the Sea show', 'Вечернее шоу в Sunset Town на юге Фукуока с водой, светом, музыкой, сценическими эффектами и видом на морскую набережную. Хорошо работает как финальная точка дня после пляжа, канатной дороги или прогулки по Ан Тхой.'),
        ('0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 'en', 'Kiss of the Sea show', 'An evening show in southern Phu Quocs Sunset Town with water, lights, music, stage effects and sea promenade views. It works well as the final stop after a beach, cable-car route or An Thoi walk.'),
        ('0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 'kk', 'Kiss of the Sea шоуы', 'Фукуоктың оңтүстігіндегі Sunset Town аймағында су, жарық, музыка, сахналық эффектілер және теңіз жағалауы көрінісі бар кешкі шоу. Жағажайдан, аспалы жолдан немесе Ан Тхой серуенінен кейін күнді аяқтауға жақсы.'),

        ('a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 'ru', 'Ice Jungle', 'Крытая тематическая зона на Фукуоке с холодной атмосферой, декорациями и семейным форматом для короткой паузы от жары. Удобна как часть маршрута по Grand World или северным развлечениям острова.'),
        ('a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 'en', 'Ice Jungle', 'An indoor themed zone on Phu Quoc with a cool atmosphere, decorations and a family format for a short break from the heat. It is convenient as part of a Grand World or northern-island entertainment route.'),
        ('a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 'kk', 'Ice Jungle', 'Фукуоктағы салқын атмосферасы, декорациялары және ыстықтан қысқа үзіліске арналған отбасылық форматы бар жабық тақырыптық аймақ. Grand World немесе аралдың солтүстік ойын-сауық бағытына ыңғайлы қосылады.'),

        ('fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 'ru', 'Prison History Museum', 'Исторический музей на территории бывшей тюрьмы Фукуока в Ан Тхой, связанный с военной памятью и тяжелыми страницами истории острова. Маршрут требует спокойного темпа и уважительного отношения к теме.'),
        ('fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 'en', 'Prison History Museum', 'A historical museum on the grounds of the former Phu Quoc prison in An Thoi, connected with wartime memory and difficult parts of the islands history. The route needs a calm pace and respectful tone.'),
        ('fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 'kk', 'Prison History Museum', 'Ан Тхойдағы бұрынғы Фукуок түрмесі аумағындағы соғыс жадымен және арал тарихының ауыр беттерімен байланысты тарихи музей. Маршрут тыныш қарқын мен құрметті көзқарасты қажет етеді.'),

        ('dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 'ru', 'Kingkong Mart', 'Популярный супермаркет на Фукуоке для покупки воды, снеков, фруктов, средств первой необходимости и сувениров перед поездками по острову. Это практичная короткая точка для самостоятельных путешественников и семей.'),
        ('dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 'en', 'Kingkong Mart', 'A popular Phu Quoc supermarket for water, snacks, fruit, essentials and souvenirs before trips around the island. It is a practical short stop for independent travelers and families.'),
        ('dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 'kk', 'Kingkong Mart', 'Фукуоктағы арал бойынша сапар алдында су, снек, жеміс, қажетті заттар және кәдесыйлар алуға арналған танымал супермаркет. Өз бетімен жүретін саяхатшылар мен отбасыларға практикалық қысқа аялдама.')
)
INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed_translations.place_id,
    seed_translations.locale,
    seed_translations.title,
    seed_translations.description,
    NOW(),
    NOW()
FROM seed_translations
ON CONFLICT (place_id, locale) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

WITH seed_locations (
    id,
    latitude,
    longitude,
    location_source_url
) AS (
    VALUES
        ('1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 10.39190000, 103.95320000, 'https://www.openstreetmap.org/search?query=Starfish%20Beach%20Rach%20Vem%20Phu%20Quoc'),
        ('b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 10.33840000, 103.85420000, 'https://www.openstreetmap.org/search?query=VinWonders%20Phu%20Quoc'),
        ('68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 9.95690000, 104.01780000, 'https://www.openstreetmap.org/search?query=SunWorld%20Hon%20Thom%20Phu%20Quoc'),
        ('6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 10.18120000, 104.00580000, 'https://www.openstreetmap.org/search?query=Suoi%20Tranh%20Waterfall%20Phu%20Quoc'),
        ('8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 10.00620000, 104.02650000, 'https://www.openstreetmap.org/search?query=Khem%20Beach%20Phu%20Quoc'),
        ('0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 10.03070000, 104.00580000, 'https://www.openstreetmap.org/search?query=Kiss%20of%20the%20Sea%20show%20Phu%20Quoc'),
        ('a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 10.33590000, 103.85770000, 'https://www.openstreetmap.org/search?query=Ice%20Jungle%20Phu%20Quoc'),
        ('fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 10.02030000, 104.01410000, 'https://www.openstreetmap.org/search?query=Phu%20Quoc%20Prison%20History%20Museum'),
        ('dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 10.21650000, 103.96040000, 'https://www.openstreetmap.org/search?query=Kingkong%20Mart%20Phu%20Quoc')
)
UPDATE places
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE places.id = seed_locations.id
    AND places.source = 'IMPORT';

WITH curated_media (
    id,
    place_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('45000000-0000-4000-8000-000000000001'::uuid, '1e717005-4895-4c39-bcbf-5f44cf27d7b4'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Bai-sao-phu-quoc-tuonglamphotos.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Bai-sao-phu-quoc-tuonglamphotos.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000002'::uuid, 'b581361f-03b8-4cbd-aa9f-059c76a3a9f8'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/2023-07-30%20Grand%20World%20Ph%C3%BA%20Qu%E1%BB%91c%20204809.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:2023-07-30_Grand_World_Ph%C3%BA_Qu%E1%BB%91c_204809.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000003'::uuid, '68c2a8e2-47b1-4216-9e9c-46c325018dcb'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Cap-treo-hon-thom-3.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Cap-treo-hon-thom-3.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000004'::uuid, '6af2d076-d948-4469-96d0-0dbf3be6c493'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Con%20suoi%201.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Con_suoi_1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000005'::uuid, '8c93e281-d815-4956-b3cc-183e42c1fbc2'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Bai-kem-dong-khach-1.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Bai-kem-dong-khach-1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000006'::uuid, '0ab67113-f0f5-4e9a-8dc1-c11912282dc9'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Artist%20Symphony%20of%20the%20Sea.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Artist_Symphony_of_the_Sea.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000007'::uuid, 'a7d39ceb-dee2-4cad-af7c-e1390d68d821'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/2023-07-30%20Grand%20World%20Ph%C3%BA%20Qu%E1%BB%91c%20212124.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:2023-07-30_Grand_World_Ph%C3%BA_Qu%E1%BB%91c_212124.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000008'::uuid, 'fa67cf61-f366-4d8c-a9cd-bd684d3503dd'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Di%20t%C3%ADch%20L%E1%BB%8Bch%20s%E1%BB%AD%20Nh%C3%A0%20t%C3%B9%20Ph%C3%BA%20qu%E1%BB%91c%2CAn%20Th%E1%BB%9Bi%2C%20Ki%C3%AAn%20Giang%2C%20vn%20-%20panoramio.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Di_t%C3%ADch_L%E1%BB%8Bch_s%E1%BB%AD_Nh%C3%A0_t%C3%B9_Ph%C3%BA_qu%E1%BB%91c,An_Th%E1%BB%9Bi,_Ki%C3%AAn_Giang,_vn_-_panoramio.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('45000000-0000-4000-8000-000000000009'::uuid, 'dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Ch%E1%BB%A3%20%C4%90%C3%AAm%20Ph%C3%BA%20qu%E1%BB%91c%2C%20Duong%20Dong%20Vietnam%20-%20panoramio.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Ch%E1%BB%A3_%C4%90%C3%AAm_Ph%C3%BA_qu%E1%BB%91c,_Duong_Dong_Vietnam_-_panoramio.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
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
    curated_media.id,
    curated_media.place_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    curated_media.external_url,
    curated_media.source_url,
    curated_media.credit,
    curated_media.license,
    'PHOTO',
    0,
    NOW()
FROM curated_media
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = curated_media.place_id
)
ON CONFLICT (id) DO UPDATE
SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    '1e717005-4895-4c39-bcbf-5f44cf27d7b4',
    'b581361f-03b8-4cbd-aa9f-059c76a3a9f8',
    '68c2a8e2-47b1-4216-9e9c-46c325018dcb',
    '6af2d076-d948-4469-96d0-0dbf3be6c493',
    '8c93e281-d815-4956-b3cc-183e42c1fbc2',
    '0ab67113-f0f5-4e9a-8dc1-c11912282dc9',
    'a7d39ceb-dee2-4cad-af7c-e1390d68d821',
    'fa67cf61-f366-4d8c-a9cd-bd684d3503dd',
    'dfba89d0-99fb-4a55-aa9a-e9bc6a22a6d0'
)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;
