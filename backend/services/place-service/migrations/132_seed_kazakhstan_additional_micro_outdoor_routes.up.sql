-- Additional Kazakhstan micro outdoor route seed.
-- Adds non-duplicate public city-nature walks and short active routes for Kazakhstan hubs.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_additional_micro_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_micro_outdoor_routes_places;

CREATE TEMP TABLE seed_kazakhstan_additional_micro_outdoor_routes_places (
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

INSERT INTO seed_kazakhstan_additional_micro_outdoor_routes_places (
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
    ('KZ', 'KZT', 'medeu-dam-stairs-walk', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.7, 'Лестничная прогулка плотины Медеу', 'Medeu Dam Stairs Walk', 'Медеу бөгеті баспалдақ серуені', 'Короткий активный маршрут от катка Медеу к плотине и обзорным ступеням, где быстро открываются виды на Малую Алматинку и горную чашу.', 'A short active route from Medeu rink to the dam and viewpoint stairs, quickly opening views of Little Almatinka and the mountain bowl.', 'Медеу мұз айдынынан бөгетке және көрініс баспалдақтарына апаратын қысқа белсенді бағыт, Кіші Алматы мен тау аңғарына тез көрініс ашады.', 43.15300000, 77.05800000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty','medeu','dam-stairs','city-view','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'kok-tobe-footpath-ascent', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.6, 'Пешеходный подъем на Кок-Тобе', 'Kok Tobe Footpath Ascent', 'Көктөбеге жаяу көтерілу', 'Городской маршрут к смотровой зоне Кок-Тобе: короткий подъем, зелень предгорий и открытая панорама Алматы без отдельной карточки канатной дороги.', 'An urban route toward the Kok Tobe viewpoint, combining a short ascent, foothill greenery and an open Almaty panorama without duplicating the cable car card.', 'Көктөбе көрініс алаңына апаратын қалалық бағыт: қысқа көтерілу, тау етегіндегі жасыл белдеу және канат жолы карточкасын қайталамайтын Алматы панорамасы.', 43.23300000, 76.97500000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty','kok-tobe','city-view','foothill','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'esentai-river-green-walk', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.5, 'Зеленая прогулка вдоль Есентая', 'Esentai River Green Walk', 'Есентай өзені жасыл серуені', 'Легкий городской outdoor-маршрут вдоль русла Есентая с пешеходными участками, зелеными карманами и спокойным форматом без выезда из Алматы.', 'An easy urban outdoor route along the Esentai river channel, with pedestrian sections, green pockets and a calm format without leaving Almaty.', 'Есентай өзені арнасы бойындағы жеңіл қалалық outdoor бағыты: жаяу бөліктер, жасыл қалталар және Алматыдан шықпай-ақ тыныш серуен форматы.', 43.22900000, 76.92800000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty','esentai','riverbank','urban-green','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'sayran-lake-loop-walk', 'almaty', 'NATURE', 0, 2, 'HOURS', 4.5, 'Круговая прогулка озера Сайран', 'Sayran Lake Loop Walk', 'Сайран көлі шеңберлі серуені', 'Доступная прогулка вокруг городского озера Сайран с водной линией, открытым небом и удобным коротким маршрутом для жителей и гостей Алматы.', 'An accessible walk around the urban Sayran Lake, with a waterside line, open sky and a convenient short route for Almaty residents and visitors.', 'Қалалық Сайран көлі айналасындағы қолжетімді серуен: су жиегі, ашық аспан және Алматы тұрғындары мен қонақтарына ыңғайлы қысқа бағыт.', 43.23800000, 76.85900000, 'AlmaAtaMedeu.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','almaty','sayran','lake-loop','urban-nature','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'tobol-river-embankment-walk', 'kostanay', 'NATURE', 0, 2, 'HOURS', 4.4, 'Прогулка по набережной Тобола', 'Tobol River Embankment Walk', 'Тобыл өзені жағалауы серуені', 'Спокойный маршрут в Костанае вдоль Тобола: городская вода, степной воздух и простой формат прогулки без сложной логистики.', 'A calm Kostanay route along the Tobol, with city water, steppe air and a simple walking format without complex logistics.', 'Қостанайдағы Тобыл бойымен өтетін тыныш бағыт: қалалық су айдыны, дала ауасы және күрделі логистикасыз жеңіл серуен форматы.', 53.21400000, 63.63500000, 'Sunset in Korgalzhyn Nature Reserve.jpg', ARRAY['kostanay']::text[], ARRAY['kostanay']::text[], ARRAY['kazakhstan','kostanay','tobol','riverbank','steppe-city','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'irtysh-river-embankment-walk', 'pavlodar', 'NATURE', 0, 2, 'HOURS', 4.5, 'Прогулка по набережной Иртыша', 'Irtysh River Embankment Walk', 'Ертіс өзені жағалауы серуені', 'Городской outdoor-маршрут в Павлодаре вдоль Иртыша: широкая река, набережная и удобная короткая прогулка в центре северо-восточного Казахстана.', 'An urban outdoor route in Pavlodar along the Irtysh, with a broad river, embankment and an easy short walk in northeastern Kazakhstan.', 'Павлодардағы Ертіс бойындағы қалалық outdoor бағыты: кең өзен, жағалау және солтүстік-шығыс Қазақстан ортасындағы ыңғайлы қысқа серуен.', 52.28700000, 76.96700000, 'Bayanaul National Park.jpg', ARRAY['pavlodar']::text[], ARRAY['pavlodar']::text[], ARRAY['kazakhstan','pavlodar','irtysh','riverbank','northeast-kazakhstan','free-entry','walking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_additional_micro_outdoor_routes_resolved_places AS
SELECT
    ('132d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-additional-micro-outdoor-routes-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_additional_micro_outdoor_routes_places;

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
FROM seed_kazakhstan_additional_micro_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_micro_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_micro_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_micro_outdoor_routes_resolved_places
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
FROM seed_kazakhstan_additional_micro_outdoor_routes_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_additional_micro_outdoor_routes_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_additional_micro_outdoor_routes_places;
