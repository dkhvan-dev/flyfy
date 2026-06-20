-- Priority South Korea destination places seed.
-- South Korea is intentionally kept as one country destination, while every
-- place remains tied to a concrete city or tourist hub used by reference
-- and admin filters.

DROP TABLE IF EXISTS seed_south_korea_resolved_places;
DROP TABLE IF EXISTS seed_south_korea_priority_places;

CREATE TEMP TABLE seed_south_korea_priority_places (
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

INSERT INTO seed_south_korea_priority_places (
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
    ('gyeongbokgung-palace', 'seoul', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Дворец Кёнбоккун', 'Gyeongbokgung Palace', 'Кёнбоккун сарайы', 37.57960000, 126.97700000, 'Gyeongbokgung Palace Seoul South Korea', ARRAY['seoul', 'incheon', 'suwon']::text[], ARRAY['seoul', 'incheon', 'suwon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('changdeokgung-palace', 'seoul', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Дворец Чхандоккун', 'Changdeokgung Palace', 'Чхандоккун сарайы', 37.57940000, 126.99100000, 'Changdeokgung Palace Seoul South Korea', ARRAY['seoul', 'incheon']::text[], ARRAY['seoul', 'incheon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('bukchon-hanok-village', 'seoul', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Деревня ханок Пукчон', 'Bukchon Hanok Village', 'Пукчон ханок ауылы', 37.58260000, 126.98300000, 'Bukchon Hanok Village Seoul South Korea', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('n-seoul-tower', 'seoul', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Башня N Seoul', 'N Seoul Tower', 'N Seoul мұнарасы', 37.55120000, 126.98820000, 'N Seoul Tower South Korea', ARRAY['seoul', 'incheon', 'suwon']::text[], ARRAY['seoul', 'incheon', 'suwon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('national-museum-of-korea', 'seoul', 'MUSEUM', 3, 'HOURS', 4.8, 'Национальный музей Кореи', 'National Museum of Korea', 'Корея ұлттық музейі', 37.52390000, 126.98040000, 'National Museum of Korea Seoul', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('gwangjang-market', 'seoul', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Кванчжан', 'Gwangjang Market', 'Кванчжан базары', 37.57010000, 126.99960000, 'Gwangjang Market Seoul South Korea', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('myeongdong-shopping-street', 'seoul', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговая улица Мёндон', 'Myeongdong Shopping Street', 'Мёндон сауда көшесі', 37.56370000, 126.98360000, 'Myeongdong Shopping Street Seoul', ARRAY['seoul', 'incheon']::text[], ARRAY['seoul', 'incheon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('starfield-coex-mall', 'seoul', 'SHOPPING', 3, 'HOURS', 4.6, 'Starfield COEX Mall', 'Starfield COEX Mall', 'Starfield COEX Mall', 37.51190000, 127.05910000, 'Starfield COEX Mall Seoul', ARRAY['seoul', 'suwon']::text[], ARRAY['seoul', 'suwon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('lotte-world', 'seoul', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Лотте Ворлд', 'Lotte World', 'Лотте Ворлд', 37.51110000, 127.09820000, 'Lotte World Seoul South Korea', ARRAY['seoul', 'suwon']::text[], ARRAY['seoul', 'suwon']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('bongeunsa-temple', 'seoul', 'TEMPLE', 1, 'HOURS', 4.6, 'Храм Понынса', 'Bongeunsa Temple', 'Понынса храмы', 37.51500000, 127.05740000, 'Bongeunsa Temple Seoul South Korea', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('hangang-park', 'seoul', 'PARK', 2, 'HOURS', 4.6, 'Парк реки Ханган', 'Hangang Park', 'Ханган саябағы', 37.52800000, 126.93260000, 'Hangang Park Seoul South Korea', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('dongdaemun-design-plaza', 'seoul', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Dongdaemun Design Plaza', 'Dongdaemun Design Plaza', 'Dongdaemun Design Plaza', 37.56650000, 127.00940000, 'Dongdaemun Design Plaza Seoul', ARRAY['seoul']::text[], ARRAY['seoul']::text[], 'Front_view_of_the_Imperial_Throne_Hall_Geunjeongjeon_at_Gyeongbokgung_Palace_with_blue_sky_in_Seoul.jpg'),
    ('songdo-central-park', 'incheon', 'PARK', 2, 'HOURS', 4.6, 'Центральный парк Сонгдо', 'Songdo Central Park', 'Сонгдо орталық саябағы', 37.39260000, 126.63830000, 'Songdo Central Park Incheon South Korea', ARRAY['incheon', 'seoul']::text[], ARRAY['incheon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('incheon-chinatown', 'incheon', 'FOOD', 2, 'HOURS', 4.4, 'Китайский квартал Инчхона', 'Incheon Chinatown', 'Инчхон қытай кварталы', 37.47530000, 126.61930000, 'Incheon Chinatown South Korea', ARRAY['incheon', 'seoul']::text[], ARRAY['incheon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('wolmido-culture-street', 'incheon', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Культурная улица Вольмидо', 'Wolmido Culture Street', 'Вольмидо мәдениет көшесі', 37.47400000, 126.59870000, 'Wolmido Culture Street Incheon', ARRAY['incheon', 'seoul']::text[], ARRAY['incheon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('sinpo-international-market', 'incheon', 'MARKET', 2, 'HOURS', 4.4, 'Международный рынок Синпо', 'Sinpo International Market', 'Синпо халықаралық базары', 37.47130000, 126.62780000, 'Sinpo International Market Incheon', ARRAY['incheon']::text[], ARRAY['incheon']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('incheon-grand-park', 'incheon', 'PARK', 2, 'HOURS', 4.5, 'Большой парк Инчхона', 'Incheon Grand Park', 'Инчхон үлкен саябағы', 37.45670000, 126.75340000, 'Incheon Grand Park South Korea', ARRAY['incheon']::text[], ARRAY['incheon']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('songdo-triple-street', 'incheon', 'SHOPPING', 2, 'HOURS', 4.4, 'Songdo Triple Street', 'Songdo Triple Street', 'Songdo Triple Street', 37.37940000, 126.66270000, 'Songdo Triple Street Incheon South Korea', ARRAY['incheon']::text[], ARRAY['incheon']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('suwon-hwaseong-fortress', 'suwon', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Крепость Хвасон в Сувоне', 'Suwon Hwaseong Fortress', 'Сувон Хвасон қамалы', 37.28720000, 127.01170000, 'Suwon Hwaseong Fortress South Korea', ARRAY['suwon', 'seoul']::text[], ARRAY['suwon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('hwaseong-haenggung-palace', 'suwon', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Дворец Хвасон Хэнгун', 'Hwaseong Haenggung Palace', 'Хвасон Хэнгун сарайы', 37.28190000, 127.01420000, 'Hwaseong Haenggung Palace Suwon', ARRAY['suwon', 'seoul']::text[], ARRAY['suwon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('flying-suwon', 'suwon', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Flying Suwon', 'Flying Suwon', 'Flying Suwon', 37.28430000, 127.01830000, 'Flying Suwon South Korea', ARRAY['suwon', 'seoul']::text[], ARRAY['suwon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('korean-folk-village', 'yongin', 'MUSEUM', 3, 'HOURS', 4.7, 'Корейская фольклорная деревня', 'Korean Folk Village', 'Корей халық ауылы', 37.25980000, 127.12160000, 'Korean Folk Village Yongin South Korea', ARRAY['yongin', 'suwon', 'seoul']::text[], ARRAY['yongin', 'suwon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('everland', 'yongin', 'ENTERTAINMENT', 6, 'HOURS', 4.7, 'Эверленд', 'Everland', 'Эверленд', 37.29360000, 127.20260000, 'Everland Yongin South Korea', ARRAY['yongin', 'suwon', 'seoul']::text[], ARRAY['yongin', 'suwon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('imjingak-peace-park', 'paju', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Парк мира Имджингак', 'Imjingak Peace Park', 'Имджингак бейбітшілік саябағы', 37.88930000, 126.74000000, 'Imjingak Peace Park Paju South Korea', ARRAY['paju', 'seoul']::text[], ARRAY['paju', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('seoul-grand-park', 'gwacheon', 'PARK', 3, 'HOURS', 4.5, 'Сеульский большой парк', 'Seoul Grand Park', 'Сеул үлкен саябағы', 37.43680000, 127.01430000, 'Seoul Grand Park Gwacheon South Korea', ARRAY['gwacheon', 'seoul']::text[], ARRAY['gwacheon', 'seoul']::text[], 'Songdo_Convensia_and_Central_Park_View.jpg'),
    ('garden-of-morning-calm', 'gapyeong', 'NATURE', 3, 'HOURS', 4.7, 'Сад утреннего спокойствия', 'The Garden of Morning Calm', 'Таңғы тыныштық бағы', 37.74340000, 127.35270000, 'Garden of Morning Calm Gapyeong South Korea', ARRAY['gapyeong', 'chuncheon', 'seoul']::text[], ARRAY['gapyeong', 'chuncheon', 'seoul']::text[], 'Namiseom_1.jpg'),
    ('haeundae-beach', 'busan', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Хэундэ', 'Haeundae Beach', 'Хэундэ жағажайы', 35.15870000, 129.16040000, 'Haeundae Beach Busan South Korea', ARRAY['busan', 'gyeongju', 'daegu']::text[], ARRAY['busan', 'gyeongju', 'daegu']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('gwangalli-beach', 'busan', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Кваналли', 'Gwangalli Beach', 'Кваналли жағажайы', 35.15320000, 129.11870000, 'Gwangalli Beach Busan South Korea', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('gamcheon-culture-village', 'busan', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Культурная деревня Камчхон', 'Gamcheon Culture Village', 'Камчхон мәдени ауылы', 35.09750000, 129.01060000, 'Gamcheon Culture Village Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('jagalchi-fish-market', 'busan', 'MARKET', 2, 'HOURS', 4.5, 'Рыбный рынок Чагальчхи', 'Jagalchi Fish Market', 'Чагальчхи балық базары', 35.09690000, 129.03060000, 'Jagalchi Fish Market Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('haedong-yonggungsa-temple', 'busan', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Хэдон Ёнгунса', 'Haedong Yonggungsa Temple', 'Хэдон Ёнгунса храмы', 35.18830000, 129.22330000, 'Haedong Yonggungsa Temple Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('taejongdae-resort-park', 'busan', 'NATURE', 3, 'HOURS', 4.6, 'Парк Тхэджондэ', 'Taejongdae Resort Park', 'Тхэджондэ саябағы', 35.05140000, 129.08770000, 'Taejongdae Resort Park Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('songdo-marine-cable-car', 'busan', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Морская канатная дорога Сондо', 'Songdo Marine Cable Car', 'Сондо теңіз аспалы жолы', 35.07660000, 129.01930000, 'Songdo Marine Cable Car Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('shinsegae-centum-city', 'busan', 'SHOPPING', 3, 'HOURS', 4.6, 'Shinsegae Centum City', 'Shinsegae Centum City', 'Shinsegae Centum City', 35.16910000, 129.12910000, 'Shinsegae Centum City Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('biff-square', 'busan', 'FOOD', 2, 'HOURS', 4.4, 'BIFF Square', 'BIFF Square', 'BIFF Square', 35.09850000, 129.02860000, 'BIFF Square Busan South Korea', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('gukje-market', 'busan', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Кукче', 'Gukje Market', 'Кукче базары', 35.10130000, 129.02850000, 'Gukje Market Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('bupyeong-kkangtong-night-market', 'busan', 'MARKET', 2, 'HOURS', 4.5, 'Ночной рынок Бупхён Ккантхон', 'Bupyeong Kkangtong Night Market', 'Бупхён Ккантхон түнгі базары', 35.10070000, 129.02650000, 'Bupyeong Kkangtong Night Market Busan', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('busan-x-the-sky', 'busan', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Busan X The Sky', 'Busan X The Sky', 'Busan X The Sky', 35.16000000, 129.16970000, 'Busan X The Sky Haeundae', ARRAY['busan']::text[], ARRAY['busan']::text[], 'Haeundae_Beach_in_Busan.jpg'),
    ('bulguksa-temple', 'gyeongju', 'TEMPLE', 3, 'HOURS', 4.9, 'Храм Пульгукса', 'Bulguksa Temple', 'Пульгукса храмы', 35.79000000, 129.33190000, 'Bulguksa Temple Gyeongju South Korea', ARRAY['gyeongju', 'busan', 'daegu']::text[], ARRAY['gyeongju', 'busan', 'daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('seokguram-grotto', 'gyeongju', 'TEMPLE', 2, 'HOURS', 4.8, 'Грот Соккурам', 'Seokguram Grotto', 'Соккурам үңгірі', 35.79470000, 129.34810000, 'Seokguram Grotto Gyeongju', ARRAY['gyeongju', 'busan', 'daegu']::text[], ARRAY['gyeongju', 'busan', 'daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('donggung-palace-wolji-pond', 'gyeongju', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Тонгун и пруд Вольчи', 'Donggung Palace and Wolji Pond', 'Тонгун сарайы және Вольчи тоғаны', 35.83470000, 129.22660000, 'Donggung Palace and Wolji Pond Gyeongju', ARRAY['gyeongju', 'busan', 'daegu']::text[], ARRAY['gyeongju', 'busan', 'daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('cheomseongdae-observatory', 'gyeongju', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Обсерватория Чхомсондэ', 'Cheomseongdae Observatory', 'Чхомсондэ обсерваториясы', 35.83490000, 129.21910000, 'Cheomseongdae Observatory Gyeongju', ARRAY['gyeongju']::text[], ARRAY['gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('daereungwon-tomb-complex', 'gyeongju', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Комплекс гробниц Тэрынвон', 'Daereungwon Tomb Complex', 'Тэрынвон қорғандар кешені', 35.83730000, 129.21220000, 'Daereungwon Tomb Complex Gyeongju', ARRAY['gyeongju']::text[], ARRAY['gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('gyeongju-national-museum', 'gyeongju', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Кёнджу', 'Gyeongju National Museum', 'Кёнджу ұлттық музейі', 35.82930000, 129.22860000, 'Gyeongju National Museum South Korea', ARRAY['gyeongju']::text[], ARRAY['gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('woljeonggyo-bridge', 'gyeongju', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мост Вольчжонгё', 'Woljeonggyo Bridge', 'Вольчжонгё көпірі', 35.82780000, 129.21790000, 'Woljeonggyo Bridge Gyeongju', ARRAY['gyeongju']::text[], ARRAY['gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('hwangnidan-gil-street', 'gyeongju', 'FOOD', 2, 'HOURS', 4.5, 'Улица Хваннидан-гиль', 'Hwangnidan-gil Street', 'Хваннидан-гиль көшесі', 35.83760000, 129.20880000, 'Hwangnidan-gil Street Gyeongju', ARRAY['gyeongju']::text[], ARRAY['gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('seomun-market', 'daegu', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Сомун', 'Seomun Market', 'Сомун базары', 35.86900000, 128.58100000, 'Seomun Market Daegu South Korea', ARRAY['daegu', 'gyeongju']::text[], ARRAY['daegu', 'gyeongju']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('seomun-night-market', 'daegu', 'FOOD', 2, 'HOURS', 4.5, 'Ночной рынок Сомун', 'Seomun Night Market', 'Сомун түнгі базары', 35.86900000, 128.58100000, 'Seomun Night Market Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('apsan-park', 'daegu', 'NATURE', 3, 'HOURS', 4.6, 'Парк Апсан', 'Apsan Park', 'Апсан саябағы', 35.83640000, 128.58030000, 'Apsan Park Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('e-world-83-tower', 'daegu', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'E-World и башня 83', 'E-World and 83 Tower', 'E-World және 83 мұнарасы', 35.85310000, 128.56390000, 'E-World 83 Tower Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('suseongmot-lake', 'daegu', 'PARK', 2, 'HOURS', 4.5, 'Озеро Сусонмот', 'Suseongmot Lake', 'Сусонмот көлі', 35.82670000, 128.61780000, 'Suseongmot Lake Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('kim-kwangseok-gil-street', 'daegu', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Улица Ким Гвансока', 'Kim Kwangseok-gil Street', 'Ким Гвансок көшесі', 35.85940000, 128.60600000, 'Kim Kwangseok-gil Street Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('donghwasa-temple', 'daegu', 'TEMPLE', 2, 'HOURS', 4.5, 'Храм Тонхваса', 'Donghwasa Temple', 'Тонхваса храмы', 35.99030000, 128.70470000, 'Donghwasa Temple Daegu', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('daegu-national-museum', 'daegu', 'MUSEUM', 2, 'HOURS', 4.4, 'Национальный музей Тэгу', 'Daegu National Museum', 'Тэгу ұлттық музейі', 35.84560000, 128.63870000, 'Daegu National Museum South Korea', ARRAY['daegu']::text[], ARRAY['daegu']::text[], 'Courtyard_of_colorful_paper_lanterns_and_shadow_patterns_at_Bulguksa_temple_Gyeongju_South_Korea.jpg'),
    ('hallasan-national-park', 'jeju', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Халласан', 'Hallasan National Park', 'Халласан ұлттық паркі', 33.36170000, 126.52920000, 'Hallasan National Park Jeju South Korea', ARRAY['jeju', 'seogwipo']::text[], ARRAY['jeju', 'seogwipo']::text[], 'Hallasan_Above.jpg'),
    ('seongsan-ilchulbong-sunrise-peak', 'seogwipo', 'NATURE', 2, 'HOURS', 4.9, 'Пик Сонсан Ильчульбон', 'Seongsan Ilchulbong Sunrise Peak', 'Сонсан Ильчульбон шыңы', 33.45810000, 126.94250000, 'Seongsan Ilchulbong Jeju South Korea', ARRAY['seogwipo', 'jeju']::text[], ARRAY['seogwipo', 'jeju']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('hyeopjae-beach', 'jeju', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Хёпчжэ', 'Hyeopjae Beach', 'Хёпчжэ жағажайы', 33.39460000, 126.23980000, 'Hyeopjae Beach Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('hamdeok-beach', 'jeju', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Хамдок', 'Hamdeok Beach', 'Хамдок жағажайы', 33.54360000, 126.66950000, 'Hamdeok Beach Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('woljeongri-beach', 'jeju', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Вольчжонри', 'Woljeongri Beach', 'Вольчжонри жағажайы', 33.55670000, 126.79570000, 'Woljeongri Beach Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('jeongbang-waterfall', 'seogwipo', 'NATURE', 1, 'HOURS', 4.6, 'Водопад Чонбан', 'Jeongbang Waterfall', 'Чонбан сарқырамасы', 33.24480000, 126.57190000, 'Jeongbang Waterfall Seogwipo Jeju', ARRAY['seogwipo']::text[], ARRAY['seogwipo']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('cheonjiyeon-waterfall', 'seogwipo', 'NATURE', 1, 'HOURS', 4.6, 'Водопад Чхонджиён', 'Cheonjiyeon Waterfall', 'Чхонджиён сарқырамасы', 33.24600000, 126.55440000, 'Cheonjiyeon Waterfall Seogwipo', ARRAY['seogwipo']::text[], ARRAY['seogwipo']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('jusangjeolli-cliff', 'seogwipo', 'NATURE', 1, 'HOURS', 4.6, 'Скалы Чусан Чолли', 'Jusangjeolli Cliff', 'Чусан Чолли жартастары', 33.23790000, 126.42600000, 'Jusangjeolli Cliff Jeju', ARRAY['seogwipo']::text[], ARRAY['seogwipo']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('udo-island', 'seogwipo', 'NATURE', 4, 'HOURS', 4.7, 'Остров Удо', 'Udo Island', 'Удо аралы', 33.50560000, 126.95590000, 'Udo Island Jeju South Korea', ARRAY['seogwipo', 'jeju']::text[], ARRAY['seogwipo', 'jeju']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('hallim-park', 'jeju', 'PARK', 2, 'HOURS', 4.5, 'Парк Халлим', 'Hallim Park', 'Халлим саябағы', 33.39060000, 126.23940000, 'Hallim Park Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('jeju-stone-park', 'jeju', 'PARK', 2, 'HOURS', 4.6, 'Каменный парк Чеджу', 'Jeju Stone Park', 'Чеджу тас саябағы', 33.45230000, 126.65960000, 'Jeju Stone Park South Korea', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('jeju-haenyeo-museum', 'jeju', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей ныряльщиц хэнё', 'Jeju Haenyeo Museum', 'Чеджу хэнё музейі', 33.52300000, 126.86400000, 'Jeju Haenyeo Museum', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('osulloc-tea-museum', 'seogwipo', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей чая Osulloc', 'Osulloc Tea Museum', 'Osulloc шай музейі', 33.30590000, 126.28910000, 'Osulloc Tea Museum Jeju', ARRAY['seogwipo', 'jeju']::text[], ARRAY['seogwipo', 'jeju']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('arte-museum-jeju', 'jeju', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Arte Museum Jeju', 'Arte Museum Jeju', 'Arte Museum Jeju', 33.39640000, 126.34580000, 'Arte Museum Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('jeju-shinhwa-world', 'seogwipo', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'Jeju Shinhwa World', 'Jeju Shinhwa World', 'Jeju Shinhwa World', 33.30590000, 126.31890000, 'Jeju Shinhwa World South Korea', ARRAY['seogwipo', 'jeju']::text[], ARRAY['seogwipo', 'jeju']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('dongmun-traditional-market', 'jeju', 'MARKET', 2, 'HOURS', 4.6, 'Традиционный рынок Тонмун', 'Dongmun Traditional Market', 'Тонмун дәстүрлі базары', 33.51260000, 126.52600000, 'Dongmun Traditional Market Jeju', ARRAY['jeju']::text[], ARRAY['jeju']::text[], 'Hallasan_Above.jpg'),
    ('seogwipo-maeil-olle-market', 'seogwipo', 'MARKET', 2, 'HOURS', 4.5, 'Ежедневный рынок Олле в Согвипхо', 'Seogwipo Maeil Olle Market', 'Согвипхо Мэиль Олле базары', 33.25050000, 126.56350000, 'Seogwipo Maeil Olle Market', ARRAY['seogwipo']::text[], ARRAY['seogwipo']::text[], 'Seongsan,_Jeju_Island.jpg'),
    ('seoraksan-national-park', 'sokcho', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Сораксан', 'Seoraksan National Park', 'Сораксан ұлттық паркі', 38.11940000, 128.46560000, 'Seoraksan National Park South Korea', ARRAY['sokcho', 'yangyang']::text[], ARRAY['sokcho', 'yangyang']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('gwongeumseong-seoraksan-cable-car', 'sokcho', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Крепость Квонгымсон и канатная дорога Сораксана', 'Gwongeumseong Fortress and Seoraksan Cable Car', 'Квонгымсон қамалы және Сораксан аспалы жолы', 38.17300000, 128.48600000, 'Gwongeumseong Fortress Seoraksan Cable Car', ARRAY['sokcho', 'yangyang']::text[], ARRAY['sokcho', 'yangyang']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('sokcho-tourist-fishery-market', 'sokcho', 'MARKET', 2, 'HOURS', 4.5, 'Туристический и рыбный рынок Сокчхо', 'Sokcho Tourist and Fishery Market', 'Сокчхо туристік және балық базары', 38.20270000, 128.59070000, 'Sokcho Tourist and Fishery Market South Korea', ARRAY['sokcho']::text[], ARRAY['sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('abai-village', 'sokcho', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Деревня Абаи', 'Abai Village', 'Абаи ауылы', 38.20340000, 128.59480000, 'Abai Village Sokcho South Korea', ARRAY['sokcho']::text[], ARRAY['sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('sokcho-beach', 'sokcho', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Сокчхо', 'Sokcho Beach', 'Сокчхо жағажайы', 38.19020000, 128.60340000, 'Sokcho Beach South Korea', ARRAY['sokcho']::text[], ARRAY['sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('naksansa-temple', 'yangyang', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Наксанса', 'Naksansa Temple', 'Наксанса храмы', 38.12460000, 128.62710000, 'Naksansa Temple Yangyang South Korea', ARRAY['yangyang', 'sokcho']::text[], ARRAY['yangyang', 'sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('naksan-beach', 'yangyang', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Наксан', 'Naksan Beach', 'Наксан жағажайы', 38.11730000, 128.63220000, 'Naksan Beach Yangyang', ARRAY['yangyang', 'sokcho']::text[], ARRAY['yangyang', 'sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('gyeongpo-beach', 'gangneung', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Кёнпхо', 'Gyeongpo Beach', 'Кёнпхо жағажайы', 37.80560000, 128.90750000, 'Gyeongpo Beach Gangneung South Korea', ARRAY['gangneung', 'pyeongchang']::text[], ARRAY['gangneung', 'pyeongchang']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('ojukheon-house', 'gangneung', 'MUSEUM', 2, 'HOURS', 4.6, 'Дом Оджукхон', 'Ojukheon House', 'Оджукхон үйі', 37.77940000, 128.87860000, 'Ojukheon House Gangneung', ARRAY['gangneung']::text[], ARRAY['gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('anmok-coffee-street', 'gangneung', 'FOOD', 2, 'HOURS', 4.5, 'Кофейная улица Анмок', 'Anmok Coffee Street', 'Анмок кофе көшесі', 37.77130000, 128.94850000, 'Anmok Coffee Street Gangneung', ARRAY['gangneung']::text[], ARRAY['gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('jeongdongjin-beach', 'gangneung', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Чондонджин', 'Jeongdongjin Beach', 'Чондонджин жағажайы', 37.69110000, 129.03260000, 'Jeongdongjin Beach Gangneung', ARRAY['gangneung']::text[], ARRAY['gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('haslla-art-world', 'gangneung', 'MUSEUM', 2, 'HOURS', 4.5, 'Арт-мир Haslla', 'Haslla Art World', 'Haslla Art World', 37.70580000, 129.01080000, 'Haslla Art World Gangneung', ARRAY['gangneung']::text[], ARRAY['gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('nami-island', 'chuncheon', 'PARK', 3, 'HOURS', 4.7, 'Остров Нами', 'Nami Island', 'Нами аралы', 37.79160000, 127.52550000, 'Nami Island Chuncheon Gapyeong South Korea', ARRAY['chuncheon', 'gapyeong', 'seoul']::text[], ARRAY['chuncheon', 'gapyeong', 'seoul']::text[], 'Namiseom_1.jpg'),
    ('soyanggang-skywalk', 'chuncheon', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Скайуок Соянган', 'Soyanggang Skywalk', 'Соянган скайуок', 37.89230000, 127.72440000, 'Soyanggang Skywalk Chuncheon', ARRAY['chuncheon']::text[], ARRAY['chuncheon']::text[], 'Namiseom_1.jpg'),
    ('gangchon-rail-park', 'chuncheon', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Рельсовый парк Канчхон', 'Gangchon Rail Park', 'Канчхон рельс паркі', 37.80500000, 127.63460000, 'Gangchon Rail Park Chuncheon South Korea', ARRAY['chuncheon', 'gapyeong']::text[], ARRAY['chuncheon', 'gapyeong']::text[], 'Namiseom_1.jpg'),
    ('legoland-korea-resort', 'chuncheon', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'LEGOLAND Korea Resort', 'LEGOLAND Korea Resort', 'LEGOLAND Korea Resort', 37.88430000, 127.69930000, 'LEGOLAND Korea Resort Chuncheon', ARRAY['chuncheon', 'seoul']::text[], ARRAY['chuncheon', 'seoul']::text[], 'Namiseom_1.jpg'),
    ('chuncheon-dakgalbi-street', 'chuncheon', 'FOOD', 2, 'HOURS', 4.5, 'Улица таккальби в Чхунчхоне', 'Chuncheon Dakgalbi Street', 'Чхунчхон таккальби көшесі', 37.87940000, 127.72700000, 'Chuncheon Dakgalbi Street South Korea', ARRAY['chuncheon']::text[], ARRAY['chuncheon']::text[], 'Namiseom_1.jpg'),
    ('alpensia-resort', 'pyeongchang', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Курорт Alpensia', 'Alpensia Resort', 'Alpensia курорты', 37.65470000, 128.68090000, 'Alpensia Resort Pyeongchang South Korea', ARRAY['pyeongchang', 'gangneung']::text[], ARRAY['pyeongchang', 'gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('yongpyong-resort-balwangsan-skywalk', 'pyeongchang', 'NATURE', 4, 'HOURS', 4.6, 'Курорт Yongpyong и скайуок Балвансан', 'Yongpyong Resort and Balwangsan Skywalk', 'Yongpyong курорты және Балвансан скайуок', 37.64700000, 128.68160000, 'Yongpyong Resort Balwangsan Skywalk Pyeongchang', ARRAY['pyeongchang']::text[], ARRAY['pyeongchang']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('woljeongsa-temple', 'pyeongchang', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Вольчжонса', 'Woljeongsa Temple', 'Вольчжонса храмы', 37.73120000, 128.59200000, 'Woljeongsa Temple Pyeongchang', ARRAY['pyeongchang', 'gangneung']::text[], ARRAY['pyeongchang', 'gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('daegwallyeong-samyang-ranch', 'pyeongchang', 'NATURE', 3, 'HOURS', 4.6, 'Ранчо Самян в Тэгваллёне', 'Daegwallyeong Samyang Ranch', 'Тэгваллён Самян ранчосы', 37.72060000, 128.75290000, 'Daegwallyeong Samyang Ranch Pyeongchang', ARRAY['pyeongchang', 'gangneung']::text[], ARRAY['pyeongchang', 'gangneung']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('goseong-unification-observatory', 'goseong', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Обсерватория объединения в Косоне', 'Goseong Unification Observatory', 'Косон бірігу обсерваториясы', 38.58630000, 128.36570000, 'Goseong Unification Observatory South Korea', ARRAY['goseong', 'sokcho']::text[], ARRAY['goseong', 'sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('dmz-museum', 'goseong', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей DMZ', 'DMZ Museum', 'DMZ музейі', 38.58260000, 128.36710000, 'DMZ Museum Goseong South Korea', ARRAY['goseong', 'sokcho']::text[], ARRAY['goseong', 'sokcho']::text[], 'Seoraksan_National_Park_panorama_3.jpg'),
    ('cheorwon-peace-observatory', 'cheorwon', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Обсерватория мира в Чхорвоне', 'Cheorwon Peace Observatory', 'Чхорвон бейбітшілік обсерваториясы', 38.25660000, 127.21080000, 'Cheorwon Peace Observatory South Korea', ARRAY['cheorwon']::text[], ARRAY['cheorwon']::text[], 'Seoraksan_National_Park_panorama_3.jpg');

CREATE TEMP TABLE seed_south_korea_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-south-korea-place:' || seed.slug) AS place_hash,
        md5('id-south-korea-media:' || seed.slug) AS media_hash
    FROM seed_south_korea_priority_places seed
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
    ARRAY['south-korea', city_id, slug, lower(category), 'south-korea-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Южной Кореи: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'South Korea tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Оңтүстік Корея бағыты бойынша туристік орын: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'KR',
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
FROM seed_south_korea_resolved_places
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

INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT id, 'ru', title_ru, description_ru, NOW(), NOW()
FROM seed_south_korea_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_south_korea_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_south_korea_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE places a
SET
    latitude = s.latitude,
    longitude = s.longitude,
    location_source_url = s.location_source_url,
    updated_at = NOW()
FROM seed_south_korea_resolved_places s
WHERE a.id = s.id;

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
FROM seed_south_korea_resolved_places
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
SELECT gen_random_uuid(), s.id, link.kind, 'KR', link.city_id, link.position - 1, NOW()
FROM seed_south_korea_resolved_places s
CROSS JOIN LATERAL (
    SELECT 'ACCESS'::varchar(16) AS kind, city_id, ordinality AS position
    FROM unnest(s.access_city_ids) WITH ORDINALITY AS cities(city_id, ordinality)
    UNION ALL
    SELECT 'DEPARTURE'::varchar(16) AS kind, city_id, ordinality AS position
    FROM unnest(s.departure_city_ids) WITH ORDINALITY AS cities(city_id, ordinality)
) link
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_south_korea_resolved_places;
DROP TABLE IF EXISTS seed_south_korea_priority_places;
