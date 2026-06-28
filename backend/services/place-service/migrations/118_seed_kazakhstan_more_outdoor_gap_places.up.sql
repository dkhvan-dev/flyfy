-- Additional Kazakhstan outdoor place seed.
-- Adds distinct route-level places not covered by the dense Kazakhstan hiking/outdoor seed layers.
-- price_amount stores a conservative entry floor. Zero means free public access.

DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_gap_places_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_gap_places;

CREATE TEMP TABLE seed_kazakhstan_more_outdoor_gap_places (
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

INSERT INTO seed_kazakhstan_more_outdoor_gap_places (
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
    ('KZ', 'KZT', 'kosbastau-oasis-walk', 'taldykorgan', 'NATURE', 1000, 3, 'HOURS', 4.7, 'Прогулка оазиса Косбастау', 'Kosbastau Oasis Walk', 'Қосбастау оазисі серуені', 'Легкий маршрут Алтын-Эмеля к теплому роднику, старой иве, тенистой роще и мягкому пустынному ландшафту между Катутау и Калканами.', 'An easy Altyn-Emel route to a warm spring, old willow, shaded grove and soft desert landscape between Katutau and the Kalkan hills.', 'Алтын-Емелдегі жылы бұлаққа, көне талға, көлеңкелі тоғайға және Катутау мен Қалқан арасындағы жұмсақ шөл ландшафтына апаратын жеңіл бағыт.', 44.12000000, 78.73000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan','almaty']::text[], ARRAY['taldykorgan','almaty']::text[], ARRAY['kazakhstan','altyn-emel','oasis','spring','walking']::text[]),
    ('KZ', 'KZT', 'zhasylkol-lake-trail', 'taldykorgan', 'NATURE', 1000, 7, 'HOURS', 4.8, 'Тропа к озеру Жасылкөл', 'Zhasylkol Lake Trail', 'Жасылкөл көліне соқпақ', 'Жетысуский маршрут в Жоңғар Алатау к зеленому высокогорному озеру, лесным участкам и более дикому формату треккинга от Лепсинского направления.', 'A Zhetysu route in the Dzungarian Alatau toward a green highland lake, forest sections and a wilder trekking format from the Lepsinsk direction.', 'Жетісудағы Жоңғар Алатау бағыты: жасыл биіктау көліне, орманды бөліктерге және Лепсі бағыты жағынан жабайырақ треккинг форматына апарады.', 45.33000000, 80.28000000, 'Altyn Emel 1.jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','zhetysu','zhongar-alatau','lake','trekking']::text[]),
    ('KZ', 'KZT', 'aktogay-canyon-rim-walk', 'almaty', 'NATURE', 1000, 4, 'HOURS', 4.7, 'Прогулка по краю каньона Актогай', 'Aktogay Canyon Rim Walk', 'Ақтоғай каньоны жиегімен серуен', 'Отдельный сценарий Чарынской системы к широким светлым стенам, речному шуму и менее очевидным видовым точкам Заланашской долины.', 'A separate Charyn-system outing toward wide pale walls, river sound and less obvious viewpoints of the Zhalanash valley.', 'Шарын жүйесінің бөлек бағыты: кең ақшыл қабырғаларға, өзен үніне және Жалаңаш аңғарының аз танымал көрініс нүктелеріне апарады.', 43.23000000, 79.07000000, 'Charyn Canyon, Kazakhstan 01.jpg', ARRAY['almaty']::text[], ARRAY['almaty']::text[], ARRAY['kazakhstan','charyn','aktogay','canyon','walking']::text[]),
    ('KZ', 'KZT', 'zhalanashkol-wind-steppe-walk', 'taldykorgan', 'NATURE', 0, 3, 'HOURS', 4.5, 'Ветреная степная прогулка Жаланашколя', 'Zhalanashkol Wind Steppe Walk', 'Жалаңашкөл желді дала серуені', 'Маршрут у восточного края Алакольской системы с галькой, камышами, сильным ветром Джунгарских ворот и открытым горизонтом приграничной степи.', 'A route on the eastern edge of the Alakol system with pebble shore, reeds, fierce Dzungarian Gate wind and an open border-steppe horizon.', 'Алакөл жүйесінің шығыс шетіндегі бағыт: малтатас жағалау, қамыс, Жоңғар қақпасының қатты желі және шекаралық даланың ашық көкжиегі.', 45.60000000, 82.18000000, 'Alakol District, Kazakhstan - panoramio (3).jpg', ARRAY['taldykorgan']::text[], ARRAY['taldykorgan']::text[], ARRAY['kazakhstan','alakol','zhalanashkol','dzungarian-gate','free-entry','walking']::text[]),
    ('KZ', 'KZT', 'ybyqty-sai-canyon-trail', 'aktau', 'NATURE', 0, 4, 'HOURS', 4.7, 'Тропа каньона Ыбықты-Сай', 'Ybyqty Sai Canyon Trail', 'Ыбықты-Сай каньоны соқпағы', 'Мангистауский маршрут по узким известняковым стенкам, сухим руслам и мягкому свету плато для короткой, но выразительной desert-прогулки.', 'A Mangystau route through narrow limestone walls, dry washes and soft plateau light for a short but expressive desert walk.', 'Маңғыстаудағы тар әктас қабырғалар, құрғақ сайлар және үстірттің жұмсақ жарығы арқылы өтетін қысқа, бірақ әсерлі шөл серуені.', 44.08500000, 51.87000000, 'Sherkala_Mountain.jpg', ARRAY['aktau']::text[], ARRAY['aktau']::text[], ARRAY['kazakhstan','mangystau','canyon','limestone','free-entry','hiking']::text[]);

CREATE TEMP TABLE seed_kazakhstan_more_outdoor_gap_places_resolved_places AS
SELECT
    ('118d0000-0000-4000-8000-' || substr(md5(country_code || ':' || slug), 1, 12))::uuid AS id,
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
    ARRAY['kazakhstan-more-outdoor-gap-places-v1', country_code, lower(country_code), city_id, slug, lower(category), 'hiking']::text[] || extra_tags AS tags
FROM seed_kazakhstan_more_outdoor_gap_places;

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
FROM seed_kazakhstan_more_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_more_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_more_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_more_outdoor_gap_places_resolved_places
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
FROM seed_kazakhstan_more_outdoor_gap_places_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure_city(city_id, ord)
ON CONFLICT (place_id, city_id, kind) DO UPDATE SET
    sort_order = EXCLUDED.sort_order;

DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_gap_places_resolved_places;
DROP TABLE IF EXISTS seed_kazakhstan_more_outdoor_gap_places;
