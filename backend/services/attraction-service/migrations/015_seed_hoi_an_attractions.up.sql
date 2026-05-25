-- Curated Hoi An attractions seed.
-- Texts are original FlyFy editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons for representative cover media.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always VN and city_id is hoi-an;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets, shows and opening conditions change by season/operator.

WITH seed_base (
    id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 'NATURE', 2, 'HOURS', 4.6, ARRAY['vietnam', 'hoi-an', 'cam-thanh', 'coconut-village', 'basket-boat', 'nature', 'family']::text[]),
        ('5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 'MUSEUM', 1, 'HOURS', 4.7, ARRAY['vietnam', 'hoi-an', 'precious-heritage', 'museum', 'photography', 'ethnic-groups', 'culture']::text[]),
        ('355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 'ENTERTAINMENT', 3, 'HOURS', 4.6, ARRAY['vietnam', 'hoi-an', 'hoi-an-memories-land', 'show', 'theme-park', 'evening', 'culture']::text[])
)
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
    seed_base.id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'VN',
    'hoi-an',
    seed_base.category,
    NULL::numeric,
    NULL::varchar(3),
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
WHERE attractions.source = 'IMPORT';

WITH seed_translations (
    attraction_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 'ru', 'Cam Thanh Coconut Village', 'Кокосовая деревня Кам Тхань рядом с Хойаном, известная зарослями водяных пальм, круглыми лодками-корзинами и спокойной речной атмосферой. Хороший короткий маршрут для природы, фото и знакомства с сельской стороной Хойана.'),
        ('a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 'en', 'Cam Thanh Coconut Village', 'A coconut village near Hoi An known for water coconut palms, round basket boats and a calm river setting. It is a good short route for nature, photos and a softer countryside view of Hoi An.'),
        ('a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 'kk', 'Cam Thanh кокос ауылы', 'Хойан маңындағы су кокос пальмалары, дөңгелек себет-қайықтары және тыныш өзен атмосферасымен белгілі кокос ауылы. Табиғатқа, фотоға және Хойанның ауылдық қырын көруге арналған қысқа маршрут.'),

        ('5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 'ru', 'Precious Heritage Art Gallery Museum', 'Бесплатная галерея-музей Réhahn в Хойане, посвященная культуре, костюмам и портретам этнических групп Вьетнама. Это спокойная indoor-точка для тех, кто хочет добавить к прогулке по старому городу больше контекста и человеческих историй.'),
        ('5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 'en', 'Precious Heritage Art Gallery Museum', 'A free Réhahn gallery museum in Hoi An focused on the culture, costumes and portraits of Vietnams ethnic groups. It is a calm indoor stop for travelers who want more context and human stories around the old town walk.'),
        ('5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 'kk', 'Precious Heritage Art Gallery Museum', 'Хойандағы Вьетнам этникалық топтарының мәдениеті, киімдері және портреттеріне арналған тегін Réhahn галерея-музейі. Ескі қала серуеніне көбірек контекст пен адам оқиғаларын қосқысы келетіндерге тыныш indoor-аялдама.'),

        ('355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 'ru', 'Hoi An Memories Land', 'Культурно-развлекательный комплекс на острове рядом со старым Хойаном с тематическим парком и вечерним шоу Hoi An Memories. Лучше всего подходит для вечернего маршрута, когда хочется зрелищно завершить день историей города, светом и сценой под открытым небом.'),
        ('355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 'en', 'Hoi An Memories Land', 'A culture and entertainment complex on an island near old Hoi An with a themed park and the evening Hoi An Memories Show. It works best as an evening route to end the day with city history, light and an open-air stage.'),
        ('355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 'kk', 'Hoi An Memories Land', 'Ескі Хойан жанындағы аралдағы тақырыптық паркі және кешкі Hoi An Memories Show қойылымы бар мәдени-ойын-сауық кешені. Қала тарихы, жарық және ашық аспан астындағы сахнамен күнді аяқтайтын кешкі маршрутқа жақсы.')
)
INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed_translations.attraction_id,
    seed_translations.locale,
    seed_translations.title,
    seed_translations.description,
    NOW(),
    NOW()
FROM seed_translations
ON CONFLICT (attraction_id, locale) DO UPDATE
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
        ('a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 15.87940000, 108.36260000, 'https://www.openstreetmap.org/search?query=Cam%20Thanh%20Coconut%20Village%20Hoi%20An'),
        ('5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 15.87680000, 108.33340000, 'https://www.openstreetmap.org/search?query=Precious%20Heritage%20Art%20Gallery%20Museum%20Hoi%20An'),
        ('355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 15.87190000, 108.33770000, 'https://www.openstreetmap.org/search?query=Hoi%20An%20Memories%20Land')
)
UPDATE attractions
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE attractions.id = seed_locations.id
    AND attractions.source = 'IMPORT';

WITH curated_media (
    id,
    attraction_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('47000000-0000-4000-8000-000000000001'::uuid, 'a3de94cc-f3f7-4a2c-a3c2-3019e723cae8'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Basket%20Boat%20and%20the%20Bamboo%20forest%20%28Unsplash%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Basket_Boat_and_the_Bamboo_forest_(Unsplash).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('47000000-0000-4000-8000-000000000002'::uuid, '5bf15e75-29bc-427a-b404-27c14c351405'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hoi%20An%20Ancient%20Town%20%2812537%29.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hoi_An_Ancient_Town_(12537).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('47000000-0000-4000-8000-000000000003'::uuid, '355accac-cc7e-4272-b475-d31f9fd77a42'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Hoi%20An%20by%20night.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Hoi_An_by_night.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
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
    curated_media.id,
    curated_media.attraction_id,
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
    FROM attractions a
    WHERE a.id = curated_media.attraction_id
)
ON CONFLICT (id) DO UPDATE
SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO attraction_city_links (id, attraction_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM attractions
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    'a3de94cc-f3f7-4a2c-a3c2-3019e723cae8',
    '5bf15e75-29bc-427a-b404-27c14c351405',
    '355accac-cc7e-4272-b475-d31f9fd77a42'
)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;
