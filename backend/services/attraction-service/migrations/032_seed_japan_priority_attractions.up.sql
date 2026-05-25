-- Priority Japan destination attractions seed.
-- Japan is kept as one country destination, while every attraction is tied to
-- a concrete city or tourist hub for reference/admin filters and route search.

DROP TABLE IF EXISTS seed_japan_resolved_attractions;
DROP TABLE IF EXISTS seed_japan_priority_attractions;

CREATE TEMP TABLE seed_japan_priority_attractions (
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

INSERT INTO seed_japan_priority_attractions (
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
    ('sensoji-temple', 'tokyo', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Сэнсо-дзи', 'Senso-ji Temple', 'Сэнсо-дзи храмы', 35.71480000, 139.79670000, 'Senso-ji Temple Tokyo Japan', ARRAY['tokyo', 'yokohama']::text[], ARRAY['tokyo', 'yokohama']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('nakamise-shopping-street', 'tokyo', 'MARKET', 1, 'HOURS', 4.5, 'Торговая улица Накамисэ', 'Nakamise Shopping Street', 'Накамисэ сауда көшесі', 35.71190000, 139.79610000, 'Nakamise Shopping Street Tokyo Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('meiji-jingu', 'tokyo', 'TEMPLE', 2, 'HOURS', 4.8, 'Святилище Мэйдзи', 'Meiji Jingu', 'Мэйдзи ғибадатханасы', 35.67640000, 139.69930000, 'Meiji Jingu Tokyo Japan', ARRAY['tokyo', 'yokohama']::text[], ARRAY['tokyo', 'yokohama']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('shibuya-scramble-crossing', 'tokyo', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Перекресток Сибуя', 'Shibuya Scramble Crossing', 'Сибуя қиылысы', 35.65950000, 139.70050000, 'Shibuya Scramble Crossing Tokyo Japan', ARRAY['tokyo', 'yokohama']::text[], ARRAY['tokyo', 'yokohama']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('shibuya-sky', 'tokyo', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Сибуя Скай', 'Shibuya Sky', 'Сибуя Скай', 35.65860000, 139.70200000, 'Shibuya Sky Tokyo Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('shinjuku-gyoen-national-garden', 'tokyo', 'PARK', 2, 'HOURS', 4.7, 'Национальный сад Синдзюку-гёэн', 'Shinjuku Gyoen National Garden', 'Синдзюку-гёэн ұлттық бағы', 35.68520000, 139.71010000, 'Shinjuku Gyoen National Garden Tokyo Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('ueno-park', 'tokyo', 'PARK', 2, 'HOURS', 4.6, 'Парк Уэно', 'Ueno Park', 'Уэно саябағы', 35.71560000, 139.77300000, 'Ueno Park Tokyo Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('tokyo-national-museum', 'tokyo', 'MUSEUM', 3, 'HOURS', 4.8, 'Токийский национальный музей', 'Tokyo National Museum', 'Токио ұлттық музейі', 35.71880000, 139.77650000, 'Tokyo National Museum Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('toyosu-market', 'tokyo', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Тоёсу', 'Toyosu Market', 'Тоёсу базары', 35.64560000, 139.78500000, 'Toyosu Market Tokyo Japan', ARRAY['tokyo']::text[], ARRAY['tokyo']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('tokyo-disneyland', 'tokyo', 'ENTERTAINMENT', 6, 'HOURS', 4.8, 'Токио Диснейленд', 'Tokyo Disneyland', 'Токио Диснейленд', 35.63290000, 139.88040000, 'Tokyo Disneyland Urayasu Japan', ARRAY['tokyo', 'yokohama']::text[], ARRAY['tokyo', 'yokohama']::text[], '20100725_Tokyo_Five-storied_Pagoda_Sensoji_5379.jpg'),
    ('minato-mirai-21', 'yokohama', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Минато Мирай 21', 'Minato Mirai 21', 'Минато Мирай 21', 35.45790000, 139.63230000, 'Minato Mirai Yokohama Japan', ARRAY['yokohama', 'tokyo', 'kamakura']::text[], ARRAY['yokohama', 'tokyo', 'kamakura']::text[], '070203_MM21%26FUJI.jpg'),
    ('yokohama-red-brick-warehouse', 'yokohama', 'SHOPPING', 2, 'HOURS', 4.6, 'Краснокирпичные склады Йокогамы', 'Yokohama Red Brick Warehouse', 'Йокогама қызыл кірпіш қоймалары', 35.45260000, 139.64290000, 'Yokohama Red Brick Warehouse Japan', ARRAY['yokohama', 'tokyo']::text[], ARRAY['yokohama', 'tokyo']::text[], '070203_MM21%26FUJI.jpg'),
    ('yokohama-chinatown', 'yokohama', 'FOOD', 2, 'HOURS', 4.6, 'Китайский квартал Йокогамы', 'Yokohama Chinatown', 'Йокогама қытай кварталы', 35.44370000, 139.64530000, 'Yokohama Chinatown Japan', ARRAY['yokohama', 'tokyo', 'kamakura']::text[], ARRAY['yokohama', 'tokyo', 'kamakura']::text[], '070203_MM21%26FUJI.jpg'),
    ('sankeien-garden', 'yokohama', 'PARK', 2, 'HOURS', 4.6, 'Сад Санкэйэн', 'Sankeien Garden', 'Санкэйэн бағы', 35.41770000, 139.66030000, 'Sankeien Garden Yokohama Japan', ARRAY['yokohama', 'kamakura']::text[], ARRAY['yokohama', 'kamakura']::text[], '070203_MM21%26FUJI.jpg'),
    ('cupnoodles-museum-yokohama', 'yokohama', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей CupNoodles Йокогама', 'CupNoodles Museum Yokohama', 'CupNoodles Йокогама музейі', 35.45550000, 139.63870000, 'CupNoodles Museum Yokohama Japan', ARRAY['yokohama', 'tokyo']::text[], ARRAY['yokohama', 'tokyo']::text[], '070203_MM21%26FUJI.jpg'),
    ('kotoku-in-great-buddha', 'kamakura', 'TEMPLE', 1, 'HOURS', 4.7, 'Большой Будда Камакуры', 'Kotoku-in Great Buddha', 'Камакура Ұлы Буддасы', 35.31670000, 139.53580000, 'Kotoku-in Great Buddha Kamakura Japan', ARRAY['kamakura', 'yokohama', 'tokyo']::text[], ARRAY['kamakura', 'yokohama', 'tokyo']::text[], '070203_MM21%26FUJI.jpg'),
    ('tsurugaoka-hachimangu', 'kamakura', 'TEMPLE', 2, 'HOURS', 4.6, 'Цуругаока Хатимангу', 'Tsurugaoka Hachimangu', 'Цуругаока Хатимангу', 35.32600000, 139.55650000, 'Tsurugaoka Hachimangu Kamakura Japan', ARRAY['kamakura', 'yokohama']::text[], ARRAY['kamakura', 'yokohama']::text[], '070203_MM21%26FUJI.jpg'),
    ('hasedera-temple-kamakura', 'kamakura', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Хасэдэра', 'Hasedera Temple', 'Хасэдэра храмы', 35.31250000, 139.53390000, 'Hasedera Temple Kamakura Japan', ARRAY['kamakura', 'yokohama']::text[], ARRAY['kamakura', 'yokohama']::text[], '070203_MM21%26FUJI.jpg'),
    ('yuigahama-beach', 'kamakura', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Юигахама', 'Yuigahama Beach', 'Юигахама жағажайы', 35.30990000, 139.54160000, 'Yuigahama Beach Kamakura Japan', ARRAY['kamakura', 'yokohama', 'tokyo']::text[], ARRAY['kamakura', 'yokohama', 'tokyo']::text[], '070203_MM21%26FUJI.jpg'),
    ('nikko-toshogu-shrine', 'nikko', 'TEMPLE', 3, 'HOURS', 4.9, 'Святилище Никко Тосёгу', 'Nikko Toshogu Shrine', 'Никко Тосёгу ғибадатханасы', 36.75810000, 139.59880000, 'Nikko Toshogu Shrine Japan', ARRAY['nikko', 'tokyo']::text[], ARRAY['nikko', 'tokyo']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('rinnoji-temple', 'nikko', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Риннодзи', 'Rinnoji Temple', 'Риннодзи храмы', 36.75470000, 139.60040000, 'Rinnoji Temple Nikko Japan', ARRAY['nikko', 'tokyo']::text[], ARRAY['nikko', 'tokyo']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('lake-chuzenji', 'nikko', 'NATURE', 3, 'HOURS', 4.7, 'Озеро Тюдзэндзи', 'Lake Chuzenji', 'Тюдзэндзи көлі', 36.73920000, 139.49290000, 'Lake Chuzenji Nikko Japan', ARRAY['nikko', 'tokyo']::text[], ARRAY['nikko', 'tokyo']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('kegon-falls', 'nikko', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Кэгон', 'Kegon Falls', 'Кэгон сарқырамасы', 36.73830000, 139.50350000, 'Kegon Falls Nikko Japan', ARRAY['nikko', 'tokyo']::text[], ARRAY['nikko', 'tokyo']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('hakone-open-air-museum', 'hakone', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей под открытым небом Хаконе', 'Hakone Open-Air Museum', 'Хаконе ашық аспан музейі', 35.24460000, 139.05070000, 'Hakone Open-Air Museum Japan', ARRAY['hakone', 'tokyo', 'yokohama']::text[], ARRAY['hakone', 'tokyo', 'yokohama']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('owakudani', 'hakone', 'NATURE', 2, 'HOURS', 4.7, 'Овакудани', 'Owakudani', 'Овакудани', 35.24030000, 139.01700000, 'Owakudani Hakone Japan', ARRAY['hakone', 'fujikawaguchiko', 'gotemba']::text[], ARRAY['hakone', 'fujikawaguchiko', 'gotemba']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('lake-ashi', 'hakone', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Аси', 'Lake Ashi', 'Аси көлі', 35.20480000, 139.02550000, 'Lake Ashi Hakone Japan', ARRAY['hakone', 'gotemba', 'tokyo']::text[], ARRAY['hakone', 'gotemba', 'tokyo']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('hakone-shrine', 'hakone', 'TEMPLE', 2, 'HOURS', 4.7, 'Святилище Хаконе', 'Hakone Shrine', 'Хаконе ғибадатханасы', 35.20490000, 139.02500000, 'Hakone Shrine Japan', ARRAY['hakone', 'gotemba']::text[], ARRAY['hakone', 'gotemba']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('lake-kawaguchiko', 'fujikawaguchiko', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Кавагутико', 'Lake Kawaguchiko', 'Кавагутико көлі', 35.51710000, 138.75180000, 'Lake Kawaguchiko Japan', ARRAY['fujikawaguchiko', 'fujiyoshida', 'tokyo']::text[], ARRAY['fujikawaguchiko', 'fujiyoshida', 'tokyo']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('oishi-park', 'fujikawaguchiko', 'PARK', 2, 'HOURS', 4.6, 'Парк Оиси', 'Oishi Park', 'Оиси саябағы', 35.52120000, 138.74330000, 'Oishi Park Lake Kawaguchiko Japan', ARRAY['fujikawaguchiko', 'fujiyoshida']::text[], ARRAY['fujikawaguchiko', 'fujiyoshida']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('arakurayama-sengen-park-chureito-pagoda', 'fujiyoshida', 'PARK', 2, 'HOURS', 4.8, 'Парк Аракураяма Сэнгэн и пагода Тюрэйто', 'Arakurayama Sengen Park and Chureito Pagoda', 'Аракураяма Сэнгэн саябағы және Тюрэйто пагодасы', 35.50130000, 138.80140000, 'Arakurayama Sengen Park Chureito Pagoda Japan', ARRAY['fujiyoshida', 'fujikawaguchiko', 'tokyo']::text[], ARRAY['fujiyoshida', 'fujikawaguchiko', 'tokyo']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('oshino-hakkai', 'oshino', 'NATURE', 2, 'HOURS', 4.6, 'Осино Хаккай', 'Oshino Hakkai', 'Осино Хаккай', 35.46010000, 138.83240000, 'Oshino Hakkai Japan', ARRAY['oshino', 'fujiyoshida', 'fujikawaguchiko']::text[], ARRAY['oshino', 'fujiyoshida', 'fujikawaguchiko']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('fuji-q-highland', 'fujiyoshida', 'ENTERTAINMENT', 6, 'HOURS', 4.6, 'Fuji-Q Highland', 'Fuji-Q Highland', 'Fuji-Q Highland', 35.48680000, 138.78030000, 'Fuji-Q Highland Japan', ARRAY['fujiyoshida', 'fujikawaguchiko', 'tokyo']::text[], ARRAY['fujiyoshida', 'fujikawaguchiko', 'tokyo']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('gotemba-premium-outlets', 'gotemba', 'SHOPPING', 3, 'HOURS', 4.5, 'Готэмба Премиум Аутлетс', 'Gotemba Premium Outlets', 'Готэмба Премиум Аутлетс', 35.30670000, 138.96370000, 'Gotemba Premium Outlets Japan', ARRAY['gotemba', 'hakone', 'fujikawaguchiko']::text[], ARRAY['gotemba', 'hakone', 'fujikawaguchiko']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('osaka-castle', 'osaka', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Осака', 'Osaka Castle', 'Осака қамалы', 34.68730000, 135.52620000, 'Osaka Castle Japan', ARRAY['osaka', 'kyoto', 'nara', 'kobe']::text[], ARRAY['osaka', 'kyoto', 'nara', 'kobe']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('dotonbori', 'osaka', 'FOOD', 2, 'HOURS', 4.7, 'Дотонбори', 'Dotonbori', 'Дотонбори', 34.66870000, 135.50130000, 'Dotonbori Osaka Japan', ARRAY['osaka', 'kyoto', 'nara', 'kobe']::text[], ARRAY['osaka', 'kyoto', 'nara', 'kobe']::text[], 'Dotonbori,_Osaka,_at_night,_November_2016.jpg'),
    ('kuromon-market', 'osaka', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Куромон', 'Kuromon Market', 'Куромон базары', 34.66540000, 135.50630000, 'Kuromon Market Osaka Japan', ARRAY['osaka', 'kyoto', 'nara']::text[], ARRAY['osaka', 'kyoto', 'nara']::text[], 'Dotonbori,_Osaka,_at_night,_November_2016.jpg'),
    ('universal-studios-japan', 'osaka', 'ENTERTAINMENT', 6, 'HOURS', 4.8, 'Юниверсал Студиос Япония', 'Universal Studios Japan', 'Юниверсал Студиос Жапония', 34.66540000, 135.43230000, 'Universal Studios Japan Osaka', ARRAY['osaka', 'kyoto', 'kobe', 'nara']::text[], ARRAY['osaka', 'kyoto', 'kobe', 'nara']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('osaka-aquarium-kaiyukan', 'osaka', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Океанариум Кайюкан', 'Osaka Aquarium Kaiyukan', 'Кайюкан океанариумы', 34.65450000, 135.42890000, 'Osaka Aquarium Kaiyukan Japan', ARRAY['osaka', 'kobe']::text[], ARRAY['osaka', 'kobe']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('kiyomizu-dera-temple', 'kyoto', 'TEMPLE', 3, 'HOURS', 4.9, 'Храм Киёмидзу-дэра', 'Kiyomizu-dera Temple', 'Киёмидзу-дэра храмы', 34.99490000, 135.78500000, 'Kiyomizu-dera Temple Kyoto Japan', ARRAY['kyoto', 'osaka', 'nara']::text[], ARRAY['kyoto', 'osaka', 'nara']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('fushimi-inari-taisha', 'kyoto', 'TEMPLE', 3, 'HOURS', 4.9, 'Фусими Инари Тайся', 'Fushimi Inari Taisha', 'Фусими Инари Тайся', 34.96710000, 135.77270000, 'Fushimi Inari Taisha Kyoto Japan', ARRAY['kyoto', 'osaka', 'nara']::text[], ARRAY['kyoto', 'osaka', 'nara']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('kinkaku-ji', 'kyoto', 'TEMPLE', 2, 'HOURS', 4.8, 'Кинкаку-дзи', 'Kinkaku-ji', 'Кинкаку-дзи', 35.03940000, 135.72920000, 'Kinkaku-ji Kyoto Japan', ARRAY['kyoto', 'osaka']::text[], ARRAY['kyoto', 'osaka']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('nijo-jo-castle', 'kyoto', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Замок Нидзё', 'Nijo-jo Castle', 'Нидзё қамалы', 35.01420000, 135.74810000, 'Nijo-jo Castle Kyoto Japan', ARRAY['kyoto', 'osaka']::text[], ARRAY['kyoto', 'osaka']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('arashiyama-bamboo-grove', 'kyoto', 'NATURE', 3, 'HOURS', 4.7, 'Арасияма и бамбуковая роща', 'Arashiyama Bamboo Grove and Togetsukyo', 'Арасияма бамбук тоғайы және Тогэцу-кё', 35.01700000, 135.67160000, 'Arashiyama Bamboo Grove Kyoto Japan', ARRAY['kyoto', 'osaka', 'kobe']::text[], ARRAY['kyoto', 'osaka', 'kobe']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('nishiki-food-market', 'kyoto', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Нисики', 'Nishiki Food Market', 'Нисики азық-түлік базары', 35.00500000, 135.76470000, 'Nishiki Market Kyoto Japan', ARRAY['kyoto', 'osaka', 'nara']::text[], ARRAY['kyoto', 'osaka', 'nara']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('nara-park', 'nara', 'PARK', 3, 'HOURS', 4.8, 'Парк Нара', 'Nara Park', 'Нара саябағы', 34.68510000, 135.84300000, 'Nara Park Japan', ARRAY['nara', 'kyoto', 'osaka']::text[], ARRAY['nara', 'kyoto', 'osaka']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('todaiji-temple', 'nara', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Тодай-дзи', 'Todaiji Temple', 'Тодай-дзи храмы', 34.68900000, 135.83980000, 'Todaiji Temple Nara Japan', ARRAY['nara', 'kyoto', 'osaka']::text[], ARRAY['nara', 'kyoto', 'osaka']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('kasugataisha-shrine', 'nara', 'TEMPLE', 2, 'HOURS', 4.7, 'Святилище Касуга Тайся', 'Kasugataisha Shrine', 'Касуга Тайся ғибадатханасы', 34.68140000, 135.84830000, 'Kasugataisha Shrine Nara Japan', ARRAY['nara', 'kyoto']::text[], ARRAY['nara', 'kyoto']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('naramachi', 'nara', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Нарамати', 'Naramachi', 'Нарамати', 34.67600000, 135.83280000, 'Naramachi Nara Japan', ARRAY['nara', 'kyoto', 'osaka']::text[], ARRAY['nara', 'kyoto', 'osaka']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('nara-national-museum', 'nara', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей Нары', 'Nara National Museum', 'Нара ұлттық музейі', 34.68370000, 135.83620000, 'Nara National Museum Japan', ARRAY['nara', 'kyoto']::text[], ARRAY['nara', 'kyoto']::text[], 'Kiyomizu-dera,_Kyoto,_November_2016_-01.jpg'),
    ('kobe-harborland', 'kobe', 'SHOPPING', 2, 'HOURS', 4.6, 'Кобе Харборленд', 'Kobe Harborland', 'Кобе Харборленд', 34.67970000, 135.18100000, 'Kobe Harborland Japan', ARRAY['kobe', 'osaka', 'himeji']::text[], ARRAY['kobe', 'osaka', 'himeji']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('meriken-park-kobe-port-tower', 'kobe', 'PARK', 2, 'HOURS', 4.6, 'Мерикен-парк и башня порта Кобе', 'Meriken Park and Kobe Port Tower', 'Мерикен саябағы және Кобе порт мұнарасы', 34.68200000, 135.18660000, 'Meriken Park Kobe Port Tower Japan', ARRAY['kobe', 'osaka']::text[], ARRAY['kobe', 'osaka']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('kobe-chinatown-nankinmachi', 'kobe', 'FOOD', 2, 'HOURS', 4.5, 'Китайский квартал Нанкинмати', 'Kobe Chinatown Nankinmachi', 'Кобе Нанкинмати қытай кварталы', 34.68870000, 135.18710000, 'Kobe Chinatown Nankinmachi Japan', ARRAY['kobe', 'osaka', 'himeji']::text[], ARRAY['kobe', 'osaka', 'himeji']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('kobe-nunobiki-herb-gardens-ropeway', 'kobe', 'NATURE', 3, 'HOURS', 4.6, 'Сады Нунобики и канатная дорога', 'Kobe Nunobiki Herb Gardens and Ropeway', 'Кобе Нунобики бақтары және аспалы жол', 34.70700000, 135.19060000, 'Kobe Nunobiki Herb Gardens Ropeway Japan', ARRAY['kobe', 'osaka']::text[], ARRAY['kobe', 'osaka']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('suma-beach', 'kobe', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Сума', 'Suma Beach', 'Сума жағажайы', 34.64390000, 135.11990000, 'Suma Beach Kobe Japan', ARRAY['kobe', 'osaka', 'himeji']::text[], ARRAY['kobe', 'osaka', 'himeji']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('himeji-castle', 'himeji', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Замок Химэдзи', 'Himeji Castle', 'Химэдзи қамалы', 34.83940000, 134.69390000, 'Himeji Castle Japan', ARRAY['himeji', 'kobe', 'osaka', 'kyoto']::text[], ARRAY['himeji', 'kobe', 'osaka', 'kyoto']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('koko-en-garden', 'himeji', 'PARK', 2, 'HOURS', 4.6, 'Сад Коко-эн', 'Koko-en Garden', 'Коко-эн бағы', 34.83900000, 134.68880000, 'Koko-en Garden Himeji Japan', ARRAY['himeji', 'kobe']::text[], ARRAY['himeji', 'kobe']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('shoshazan-engyoji-temple', 'himeji', 'TEMPLE', 3, 'HOURS', 4.7, 'Храм Сёсядзан Энгё-дзи', 'Shoshazan Engyoji Temple', 'Сёсядзан Энгё-дзи храмы', 34.89060000, 134.65870000, 'Shoshazan Engyoji Temple Himeji Japan', ARRAY['himeji', 'kobe', 'osaka']::text[], ARRAY['himeji', 'kobe', 'osaka']::text[], 'Himeji_Castle_0804_1.jpg'),
    ('wakayama-castle', 'wakayama', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Замок Вакаяма', 'Wakayama Castle', 'Вакаяма қамалы', 34.22770000, 135.17190000, 'Wakayama Castle Japan', ARRAY['wakayama', 'osaka', 'kyoto']::text[], ARRAY['wakayama', 'osaka', 'kyoto']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('koyasan-danjo-garan', 'wakayama', 'TEMPLE', 3, 'HOURS', 4.8, 'Коясан Дандзё Гаран', 'Koyasan Danjo Garan', 'Коясан Дандзё Гаран', 34.21300000, 135.58600000, 'Koyasan Danjo Garan Wakayama Japan', ARRAY['wakayama', 'osaka', 'nara', 'kyoto']::text[], ARRAY['wakayama', 'osaka', 'nara', 'kyoto']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('shirarahama-beach', 'wakayama', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Сирарахама', 'Shirarahama Beach', 'Сирарахама жағажайы', 33.68250000, 135.34540000, 'Shirarahama Beach Wakayama Japan', ARRAY['wakayama', 'osaka']::text[], ARRAY['wakayama', 'osaka']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('kuroshio-market', 'wakayama', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Куросио', 'Kuroshio Market', 'Куросио базары', 34.15370000, 135.18070000, 'Kuroshio Market Wakayama Japan', ARRAY['wakayama', 'osaka', 'kobe']::text[], ARRAY['wakayama', 'osaka', 'kobe']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('nachi-waterfall', 'wakayama', 'NATURE', 3, 'HOURS', 4.8, 'Водопад Нати', 'Nachi Waterfall', 'Нати сарқырамасы', 33.67530000, 135.88890000, 'Nachi Waterfall Wakayama Japan', ARRAY['wakayama', 'osaka', 'nara']::text[], ARRAY['wakayama', 'osaka', 'nara']::text[], 'Osaka_Castle_02bs3200.jpg'),
    ('nagoya-castle', 'nagoya', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Замок Нагоя', 'Nagoya Castle', 'Нагоя қамалы', 35.18560000, 136.89900000, 'Nagoya Castle Japan', ARRAY['nagoya', 'kanazawa', 'takayama']::text[], ARRAY['nagoya', 'kanazawa', 'takayama']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('atsuta-jingu-shrine', 'nagoya', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Ацута-дзингу', 'Atsuta Jingu Shrine', 'Ацута-дзингу храмы', 35.12710000, 136.90860000, 'Atsuta Jingu Shrine Nagoya Japan', ARRAY['nagoya']::text[], ARRAY['nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('toyota-commemorative-museum', 'nagoya', 'MUSEUM', 3, 'HOURS', 4.7, 'Мемориальный музей промышленности Toyota', 'Toyota Commemorative Museum', 'Toyota өнеркәсіп музейі', 35.18370000, 136.87940000, 'Toyota Commemorative Museum Nagoya Japan', ARRAY['nagoya']::text[], ARRAY['nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('osu-shopping-district', 'nagoya', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговый район Осу', 'Osu Shopping District', 'Осу сауда ауданы', 35.15900000, 136.90590000, 'Osu Shopping District Nagoya Japan', ARRAY['nagoya']::text[], ARRAY['nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('yanagibashi-central-market', 'nagoya', 'MARKET', 2, 'HOURS', 4.4, 'Центральный рынок Янагибаси', 'Yanagibashi Central Market', 'Янагибаси орталық базары', 35.17130000, 136.88860000, 'Yanagibashi Central Market Nagoya Japan', ARRAY['nagoya']::text[], ARRAY['nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('legoland-japan-resort', 'nagoya', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'LEGOLAND Japan Resort', 'LEGOLAND Japan Resort', 'LEGOLAND Japan Resort', 35.05090000, 136.84380000, 'LEGOLAND Japan Resort Nagoya', ARRAY['nagoya']::text[], ARRAY['nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('ghibli-park', 'nagakute', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Парк Гибли', 'Ghibli Park', 'Гибли саябағы', 35.17390000, 137.09030000, 'Ghibli Park Nagakute Japan', ARRAY['nagakute', 'nagoya']::text[], ARRAY['nagakute', 'nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('kenrokuen-garden', 'kanazawa', 'PARK', 3, 'HOURS', 4.9, 'Сад Кэнрокуэн', 'Kenrokuen Garden', 'Кэнрокуэн бағы', 36.56210000, 136.66250000, 'Kenrokuen Garden Kanazawa Japan', ARRAY['kanazawa', 'nagoya', 'takayama']::text[], ARRAY['kanazawa', 'nagoya', 'takayama']::text[], '20190705_Kenroku-en-7.jpg'),
    ('kanazawa-castle-park', 'kanazawa', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Парк замка Канадзава', 'Kanazawa Castle Park', 'Канадзава қамал саябағы', 36.56580000, 136.65920000, 'Kanazawa Castle Park Japan', ARRAY['kanazawa']::text[], ARRAY['kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('higashi-chaya-district', 'kanazawa', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Район Хигаси Тяя', 'Higashi Chaya District', 'Хигаси Тяя ауданы', 36.57200000, 136.66660000, 'Higashi Chaya District Kanazawa Japan', ARRAY['kanazawa']::text[], ARRAY['kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('omicho-market', 'kanazawa', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Омитё', 'Omicho Market', 'Омитё базары', 36.57220000, 136.65660000, 'Omicho Market Kanazawa Japan', ARRAY['kanazawa']::text[], ARRAY['kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('21st-century-museum-kanazawa', 'kanazawa', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей современного искусства XXI века', '21st Century Museum of Contemporary Art', 'XXI ғасыр заманауи өнер музейі', 36.56100000, 136.65840000, '21st Century Museum of Contemporary Art Kanazawa Japan', ARRAY['kanazawa']::text[], ARRAY['kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('sanmachi-traditional-buildings-area', 'takayama', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Исторический район Санмати', 'Sanmachi Traditional Buildings Area', 'Санмати тарихи ауданы', 36.14220000, 137.25950000, 'Sanmachi Traditional Buildings Area Takayama Japan', ARRAY['takayama', 'nagoya', 'kanazawa']::text[], ARRAY['takayama', 'nagoya', 'kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('miyagawa-morning-market', 'takayama', 'MARKET', 1, 'HOURS', 4.5, 'Утренний рынок Миягава', 'Miyagawa Morning Market', 'Миягава таңғы базары', 36.14360000, 137.26090000, 'Miyagawa Morning Market Takayama Japan', ARRAY['takayama']::text[], ARRAY['takayama']::text[], '20190705_Kenroku-en-7.jpg'),
    ('hida-folk-village', 'takayama', 'MUSEUM', 2, 'HOURS', 4.7, 'Фольклорная деревня Хида', 'Hida Folk Village', 'Хида халық ауылы', 36.13470000, 137.23600000, 'Hida Folk Village Takayama Japan', ARRAY['takayama', 'shirakawa-go']::text[], ARRAY['takayama', 'shirakawa-go']::text[], '20190705_Kenroku-en-7.jpg'),
    ('shirakawa-go-ogimachi-village', 'shirakawa-go', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Деревня Оги-мати в Сиракава-го', 'Shirakawa-go Ogimachi Village', 'Сиракава-го Оги-мати ауылы', 36.25780000, 136.90610000, 'Shirakawa-go Ogimachi Village Japan', ARRAY['shirakawa-go', 'takayama', 'kanazawa']::text[], ARRAY['shirakawa-go', 'takayama', 'kanazawa']::text[], '20190705_Kenroku-en-7.jpg'),
    ('shirayama-observatory', 'shirakawa-go', 'NATURE', 1, 'HOURS', 4.6, 'Обзорная площадка Сираяма', 'Shirayama Observatory', 'Сираяма қарау алаңы', 36.26300000, 136.90890000, 'Shirayama Observatory Shirakawa-go Japan', ARRAY['shirakawa-go', 'takayama']::text[], ARRAY['shirakawa-go', 'takayama']::text[], '20190705_Kenroku-en-7.jpg'),
    ('matsumoto-castle', 'matsumoto', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Замок Мацумото', 'Matsumoto Castle', 'Мацумото қамалы', 36.23860000, 137.96900000, 'Matsumoto Castle Japan', ARRAY['matsumoto', 'takayama', 'nagoya']::text[], ARRAY['matsumoto', 'takayama', 'nagoya']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('matsumoto-city-museum', 'matsumoto', 'MUSEUM', 2, 'HOURS', 4.4, 'Городской музей Мацумото', 'Matsumoto City Museum', 'Мацумото қалалық музейі', 36.23690000, 137.96960000, 'Matsumoto City Museum Japan', ARRAY['matsumoto']::text[], ARRAY['matsumoto']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('nawate-street', 'matsumoto', 'SHOPPING', 1, 'HOURS', 4.4, 'Улица Наватэ', 'Nawate Street', 'Наватэ көшесі', 36.23490000, 137.96900000, 'Nawate Street Matsumoto Japan', ARRAY['matsumoto']::text[], ARRAY['matsumoto']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('daio-wasabi-farm', 'azumino', 'FOOD', 2, 'HOURS', 4.6, 'Васаби-ферма Дайо', 'Daio Wasabi Farm', 'Дайо васаби фермасы', 36.33970000, 137.90500000, 'Daio Wasabi Farm Azumino Japan', ARRAY['azumino', 'matsumoto']::text[], ARRAY['azumino', 'matsumoto']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('kamikochi', 'kamikochi', 'NATURE', 5, 'HOURS', 4.9, 'Камикоти', 'Kamikochi', 'Камикоти', 36.25090000, 137.63700000, 'Kamikochi Japan Alps', ARRAY['kamikochi', 'matsumoto', 'takayama']::text[], ARRAY['kamikochi', 'matsumoto', 'takayama']::text[], 'Nagoya_Castle(Edit2).jpg'),
    ('miho-no-matsubara', 'shizuoka', 'BEACH', 2, 'HOURS', 4.6, 'Михо-но-Мацубара', 'Miho no Matsubara', 'Михо-но-Мацубара', 35.00550000, 138.52290000, 'Miho no Matsubara Shizuoka Japan', ARRAY['shizuoka', 'shimizu', 'fujikawaguchiko']::text[], ARRAY['shizuoka', 'shimizu', 'fujikawaguchiko']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('kunozan-toshogu-shrine', 'shizuoka', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Кунодзан Тосёгу', 'Kunozan Toshogu Shrine', 'Кунодзан Тосёгу храмы', 34.96480000, 138.46760000, 'Kunozan Toshogu Shrine Shizuoka Japan', ARRAY['shizuoka', 'shimizu']::text[], ARRAY['shizuoka', 'shimizu']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('nihondaira-yume-terrace', 'shizuoka', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Смотровая терраса Нихондайра Юмэ', 'Nihondaira Yume Terrace', 'Нихондайра Юмэ террасасы', 34.97500000, 138.46400000, 'Nihondaira Yume Terrace Shizuoka Japan', ARRAY['shizuoka', 'shimizu']::text[], ARRAY['shizuoka', 'shimizu']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('shimizu-fish-market-kashi-no-ichi', 'shimizu', 'MARKET', 2, 'HOURS', 4.5, 'Рыбный рынок Каси-но-Ити в Симидзу', 'Shimizu Fish Market Kashi-no-Ichi', 'Симидзу Каси-но-Ити балық базары', 35.02330000, 138.48960000, 'Shimizu Fish Market Kashi-no-Ichi Japan', ARRAY['shimizu', 'shizuoka']::text[], ARRAY['shimizu', 'shizuoka']::text[], 'Lake_Kawaguchiko_Sakura_Mount_Fuji_4.JPG'),
    ('odori-park', 'sapporo', 'PARK', 2, 'HOURS', 4.6, 'Парк Одори', 'Sapporo Odori Park', 'Одори саябағы', 43.05980000, 141.34690000, 'Odori Park Sapporo Japan', ARRAY['sapporo', 'otaru']::text[], ARRAY['sapporo', 'otaru']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('sapporo-clock-tower', 'sapporo', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Часовая башня Саппоро', 'Sapporo Clock Tower', 'Саппоро сағат мұнарасы', 43.06250000, 141.35370000, 'Sapporo Clock Tower Japan', ARRAY['sapporo']::text[], ARRAY['sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('sapporo-beer-museum', 'sapporo', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей пива Саппоро', 'Sapporo Beer Museum', 'Саппоро сыра музейі', 43.07150000, 141.36880000, 'Sapporo Beer Museum Japan', ARRAY['sapporo']::text[], ARRAY['sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('nijo-fish-market', 'sapporo', 'MARKET', 1, 'HOURS', 4.4, 'Рыбный рынок Нидзё', 'Nijo Fish Market', 'Нидзё балық базары', 43.05860000, 141.35860000, 'Nijo Fish Market Sapporo Japan', ARRAY['sapporo']::text[], ARRAY['sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('tanukikoji-shopping-street', 'sapporo', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговая улица Танукикодзи', 'Tanukikoji Shopping Street', 'Танукикодзи сауда көшесі', 43.05660000, 141.35180000, 'Tanukikoji Shopping Street Sapporo Japan', ARRAY['sapporo']::text[], ARRAY['sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('moerenuma-park', 'sapporo', 'PARK', 3, 'HOURS', 4.6, 'Парк Моэрэнума', 'Moerenuma Park', 'Моэрэнума саябағы', 43.12260000, 141.43060000, 'Moerenuma Park Sapporo Japan', ARRAY['sapporo']::text[], ARRAY['sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('otaru-canal', 'otaru', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Канал Отару', 'Otaru Canal', 'Отару каналы', 43.19870000, 141.00250000, 'Otaru Canal Japan', ARRAY['otaru', 'sapporo']::text[], ARRAY['otaru', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('otaru-sankaku-market', 'otaru', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Санкаку в Отару', 'Otaru Sankaku Market', 'Отару Санкаку базары', 43.19790000, 140.99340000, 'Otaru Sankaku Market Japan', ARRAY['otaru', 'sapporo']::text[], ARRAY['otaru', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('otaru-music-box-museum', 'otaru', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей музыкальных шкатулок Отару', 'Otaru Music Box Museum', 'Отару музыкалық қораптар музейі', 43.19060000, 141.00780000, 'Otaru Music Box Museum Japan', ARRAY['otaru', 'sapporo']::text[], ARRAY['otaru', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('mount-hakodate', 'hakodate', 'NATURE', 2, 'HOURS', 4.8, 'Гора Хакодате', 'Mount Hakodate', 'Хакодате тауы', 41.75920000, 140.70470000, 'Mount Hakodate Japan', ARRAY['hakodate', 'aomori', 'sapporo']::text[], ARRAY['hakodate', 'aomori', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('goryokaku-park', 'hakodate', 'PARK', 2, 'HOURS', 4.6, 'Парк Горёкаку', 'Goryokaku Park', 'Горёкаку саябағы', 41.79690000, 140.75690000, 'Goryokaku Park Hakodate Japan', ARRAY['hakodate']::text[], ARRAY['hakodate']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('hakodate-morning-market', 'hakodate', 'MARKET', 1, 'HOURS', 4.5, 'Утренний рынок Хакодате', 'Hakodate Morning Market', 'Хакодате таңғы базары', 41.77390000, 140.72650000, 'Hakodate Morning Market Japan', ARRAY['hakodate', 'aomori']::text[], ARRAY['hakodate', 'aomori']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('kanemori-red-brick-warehouse', 'hakodate', 'SHOPPING', 2, 'HOURS', 4.5, 'Краснокирпичные склады Канэмори', 'Kanemori Red Brick Warehouse', 'Канэмори қызыл кірпіш қоймалары', 41.76620000, 140.71690000, 'Kanemori Red Brick Warehouse Hakodate Japan', ARRAY['hakodate']::text[], ARRAY['hakodate']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('farm-tomita', 'furano', 'NATURE', 2, 'HOURS', 4.7, 'Ферма Томита', 'Farm Tomita', 'Томита фермасы', 43.41700000, 142.42560000, 'Farm Tomita Furano Japan', ARRAY['furano', 'asahikawa', 'sapporo']::text[], ARRAY['furano', 'asahikawa', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('aoiike-blue-pond', 'biei', 'NATURE', 1, 'HOURS', 4.7, 'Голубой пруд Сироганэ', 'Aoiike Blue Pond', 'Аои-икэ көк тоғаны', 43.49350000, 142.61470000, 'Shirogane Blue Pond Biei Japan', ARRAY['biei', 'furano', 'asahikawa']::text[], ARRAY['biei', 'furano', 'asahikawa']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('asahiyama-zoo', 'asahikawa', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Зоопарк Асахияма', 'Asahiyama Zoo', 'Асахияма зоопаркі', 43.76800000, 142.48000000, 'Asahiyama Zoo Asahikawa Japan', ARRAY['asahikawa', 'biei', 'furano', 'sapporo']::text[], ARRAY['asahikawa', 'biei', 'furano', 'sapporo']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('sendai-castle-site', 'sendai', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Руины замка Сэндай', 'Sendai Castle Site', 'Сэндай қамалы орны', 38.25290000, 140.85600000, 'Sendai Castle Site Japan', ARRAY['sendai', 'matsushima', 'yamagata']::text[], ARRAY['sendai', 'matsushima', 'yamagata']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('zuihoden-mausoleum', 'sendai', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Мавзолей Дзуйходэн', 'Zuihoden Mausoleum', 'Дзуйходэн мавзолейі', 38.25020000, 140.86290000, 'Zuihoden Mausoleum Sendai Japan', ARRAY['sendai', 'matsushima']::text[], ARRAY['sendai', 'matsushima']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('matsushima-bay', 'matsushima', 'NATURE', 3, 'HOURS', 4.7, 'Залив Мацусима', 'Matsushima Bay', 'Мацусима шығанағы', 38.37090000, 141.06130000, 'Matsushima Bay Japan', ARRAY['matsushima', 'sendai']::text[], ARRAY['matsushima', 'sendai']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('nebuta-museum-wa-rasse', 'aomori', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Нэбута WA RASSE', 'Nebuta Museum WA RASSE', 'Нэбута WA RASSE музейі', 40.82870000, 140.73480000, 'Nebuta Museum WA RASSE Aomori Japan', ARRAY['aomori', 'hakodate']::text[], ARRAY['aomori', 'hakodate']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('sannai-maruyama-site', 'aomori', 'MUSEUM', 2, 'HOURS', 4.6, 'Археологический комплекс Саннай-Маруяма', 'Sannai Maruyama Site', 'Саннай-Маруяма археологиялық орны', 40.81120000, 140.69700000, 'Sannai Maruyama Site Aomori Japan', ARRAY['aomori']::text[], ARRAY['aomori']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('furukawa-fish-market-nokke-don', 'aomori', 'MARKET', 1, 'HOURS', 4.5, 'Рыбный рынок Фурукава', 'Furukawa Fish Market Nokke-don', 'Фурукава балық базары', 40.82560000, 140.73610000, 'Furukawa Fish Market Aomori Japan', ARRAY['aomori', 'hakodate']::text[], ARRAY['aomori', 'hakodate']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('aomori-museum-of-art', 'aomori', 'MUSEUM', 2, 'HOURS', 4.5, 'Художественный музей Аомори', 'Aomori Museum of Art', 'Аомори өнер музейі', 40.81320000, 140.69510000, 'Aomori Museum of Art Japan', ARRAY['aomori']::text[], ARRAY['aomori']::text[], 'Odori_Park_in_Sapporo_-_Hokkaido_Prefecture_at_night_in_March_2026.jpg'),
    ('kakunodate-samurai-district', 'kakunodate', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Самурайский квартал Какунодатэ', 'Kakunodate Samurai District', 'Какунодатэ самурай ауданы', 39.59600000, 140.56000000, 'Kakunodate Samurai District Japan', ARRAY['kakunodate', 'akita', 'sendai']::text[], ARRAY['kakunodate', 'akita', 'sendai']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('senshu-park', 'akita', 'PARK', 2, 'HOURS', 4.4, 'Парк Сэнсю', 'Senshu Park', 'Сэнсю саябағы', 39.71920000, 140.12390000, 'Senshu Park Akita Japan', ARRAY['akita', 'kakunodate']::text[], ARRAY['akita', 'kakunodate']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('yamadera-risshakuji-temple', 'yamagata', 'TEMPLE', 3, 'HOURS', 4.8, 'Ямадэра и храм Риссякудзи', 'Yamadera Risshakuji Temple', 'Ямадэра Риссякудзи храмы', 38.31180000, 140.43480000, 'Yamadera Risshakuji Temple Yamagata Japan', ARRAY['yamagata', 'sendai']::text[], ARRAY['yamagata', 'sendai']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('ginzan-onsen', 'ginzan-onsen', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Гиндзан-онсэн', 'Ginzan Onsen', 'Гиндзан-онсэн', 38.57060000, 140.53180000, 'Ginzan Onsen Japan', ARRAY['ginzan-onsen', 'yamagata', 'sendai']::text[], ARRAY['ginzan-onsen', 'yamagata', 'sendai']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('zao-onsen-mount-zao', 'zao-onsen', 'NATURE', 4, 'HOURS', 4.7, 'Дзао-онсэн и гора Дзао', 'Zao Onsen and Mount Zao', 'Дзао-онсэн және Дзао тауы', 38.16860000, 140.39540000, 'Zao Onsen Mount Zao Japan', ARRAY['zao-onsen', 'yamagata', 'sendai']::text[], ARRAY['zao-onsen', 'yamagata', 'sendai']::text[], 'Nikko_Toshogu_Yomeimon_Gate_2024.jpg'),
    ('ohori-park', 'fukuoka', 'PARK', 2, 'HOURS', 4.6, 'Парк Охори', 'Ohori Park', 'Охори саябағы', 33.58650000, 130.37640000, 'Ohori Park Fukuoka Japan', ARRAY['fukuoka']::text[], ARRAY['fukuoka']::text[], 'Itsukushima_Gate.jpg'),
    ('kushida-shrine', 'fukuoka', 'TEMPLE', 1, 'HOURS', 4.5, 'Святилище Кусида', 'Kushida Shrine', 'Кусида ғибадатханасы', 33.59300000, 130.41000000, 'Kushida Shrine Fukuoka Japan', ARRAY['fukuoka']::text[], ARRAY['fukuoka']::text[], 'Itsukushima_Gate.jpg'),
    ('canal-city-hakata', 'fukuoka', 'SHOPPING', 2, 'HOURS', 4.5, 'Канал-Сити Хаката', 'Canal City Hakata', 'Канал-Сити Хаката', 33.58980000, 130.41110000, 'Canal City Hakata Fukuoka Japan', ARRAY['fukuoka']::text[], ARRAY['fukuoka']::text[], 'Itsukushima_Gate.jpg'),
    ('fukuoka-tower', 'fukuoka', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Башня Фукуока', 'Fukuoka Tower', 'Фукуока мұнарасы', 33.59330000, 130.35150000, 'Fukuoka Tower Japan', ARRAY['fukuoka']::text[], ARRAY['fukuoka']::text[], 'Itsukushima_Gate.jpg'),
    ('hiroshima-peace-memorial-park', 'hiroshima', 'PARK', 3, 'HOURS', 4.9, 'Мемориальный парк мира Хиросимы', 'Hiroshima Peace Memorial Park', 'Хиросима бейбітшілік мемориалдық саябағы', 34.39290000, 132.45260000, 'Hiroshima Peace Memorial Park Japan', ARRAY['hiroshima', 'hatsukaichi']::text[], ARRAY['hiroshima', 'hatsukaichi']::text[], 'Hiroshima_Peace_Memorial_Park,_20240817_1032_4210.jpg'),
    ('hiroshima-peace-memorial-museum', 'hiroshima', 'MUSEUM', 2, 'HOURS', 4.8, 'Мемориальный музей мира Хиросимы', 'Hiroshima Peace Memorial Museum', 'Хиросима бейбітшілік мемориалдық музейі', 34.39140000, 132.45360000, 'Hiroshima Peace Memorial Museum Japan', ARRAY['hiroshima', 'hatsukaichi']::text[], ARRAY['hiroshima', 'hatsukaichi']::text[], 'Hiroshima_Peace_Memorial_Park,_20240817_1032_4210.jpg'),
    ('okonomimura', 'hiroshima', 'FOOD', 2, 'HOURS', 4.5, 'Окономимура', 'Okonomimura', 'Окономимура', 34.39170000, 132.46250000, 'Okonomimura Hiroshima Japan', ARRAY['hiroshima']::text[], ARRAY['hiroshima']::text[], 'Hiroshima_Peace_Memorial_Park,_20240817_1032_4210.jpg'),
    ('itsukushima-shrine', 'hatsukaichi', 'TEMPLE', 3, 'HOURS', 4.9, 'Святилище Ицукусима', 'Itsukushima Shrine', 'Ицукусима ғибадатханасы', 34.29590000, 132.31990000, 'Itsukushima Shrine Miyajima Japan', ARRAY['hatsukaichi', 'hiroshima']::text[], ARRAY['hatsukaichi', 'hiroshima']::text[], 'Itsukushima_Gate.jpg'),
    ('mount-misen', 'hatsukaichi', 'NATURE', 4, 'HOURS', 4.7, 'Гора Мисэн', 'Mount Misen', 'Мисэн тауы', 34.27940000, 132.31940000, 'Mount Misen Miyajima Japan', ARRAY['hatsukaichi', 'hiroshima']::text[], ARRAY['hatsukaichi', 'hiroshima']::text[], 'Itsukushima_Gate.jpg'),
    ('momijidani-park', 'hatsukaichi', 'PARK', 2, 'HOURS', 4.6, 'Парк Момидзидани', 'Momijidani Park', 'Момидзидани саябағы', 34.29400000, 132.32150000, 'Momijidani Park Miyajima Japan', ARRAY['hatsukaichi', 'hiroshima']::text[], ARRAY['hatsukaichi', 'hiroshima']::text[], 'Itsukushima_Gate.jpg'),
    ('nagasaki-peace-park', 'nagasaki', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей атомной бомбы и Парк мира Нагасаки', 'Nagasaki Peace Park and Atomic Bomb Museum', 'Нагасаки бейбітшілік саябағы және атом бомбасы музейі', 32.77360000, 129.86300000, 'Nagasaki Peace Park Atomic Bomb Museum Japan', ARRAY['nagasaki', 'sasebo', 'fukuoka']::text[], ARRAY['nagasaki', 'sasebo', 'fukuoka']::text[], '20190202_Nagasaki_Peace_Park_Statue_of_Peace-2.jpg'),
    ('glover-garden', 'nagasaki', 'PARK', 2, 'HOURS', 4.6, 'Сад Гловера', 'Glover Garden', 'Гловер бағы', 32.73430000, 129.86940000, 'Glover Garden Nagasaki Japan', ARRAY['nagasaki']::text[], ARRAY['nagasaki']::text[], '20190202_Nagasaki_Peace_Park_Statue_of_Peace-2.jpg'),
    ('dejima', 'nagasaki', 'MUSEUM', 2, 'HOURS', 4.5, 'Дэдзима', 'Dejima', 'Дэдзима', 32.74410000, 129.87310000, 'Dejima Nagasaki Japan', ARRAY['nagasaki']::text[], ARRAY['nagasaki']::text[], '20190202_Nagasaki_Peace_Park_Statue_of_Peace-2.jpg'),
    ('huis-ten-bosch', 'sasebo', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Хаус-тен-Бос', 'Huis Ten Bosch', 'Хаус-тен-Бос', 33.08620000, 129.78780000, 'Huis Ten Bosch Sasebo Japan', ARRAY['sasebo', 'nagasaki', 'fukuoka']::text[], ARRAY['sasebo', 'nagasaki', 'fukuoka']::text[], '20190202_Nagasaki_Peace_Park_Statue_of_Peace-2.jpg'),
    ('kumamoto-castle', 'kumamoto', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Кумамото', 'Kumamoto Castle', 'Кумамото қамалы', 32.80620000, 130.70590000, 'Kumamoto Castle Japan', ARRAY['kumamoto', 'fukuoka', 'kagoshima']::text[], ARRAY['kumamoto', 'fukuoka', 'kagoshima']::text[], 'Itsukushima_Gate.jpg'),
    ('suizenji-jojuen-garden', 'kumamoto', 'PARK', 2, 'HOURS', 4.6, 'Сад Суйдзэндзи Дзёдзюэн', 'Suizenji Jojuen Garden', 'Суйдзэндзи Дзёдзюэн бағы', 32.79180000, 130.73310000, 'Suizenji Jojuen Garden Kumamoto Japan', ARRAY['kumamoto']::text[], ARRAY['kumamoto']::text[], 'Itsukushima_Gate.jpg'),
    ('hells-of-beppu', 'beppu', 'NATURE', 3, 'HOURS', 4.7, 'Ады Бэппу', 'Beppu Jigoku Meguri', 'Бэппу ыстық көздері', 33.31620000, 131.47880000, 'Beppu Jigoku Meguri Hells of Beppu Japan', ARRAY['beppu', 'fukuoka', 'kumamoto']::text[], ARRAY['beppu', 'fukuoka', 'kumamoto']::text[], 'Itsukushima_Gate.jpg'),
    ('beppu-ropeway-mount-tsurumi', 'beppu', 'NATURE', 3, 'HOURS', 4.6, 'Канатная дорога Бэппу и гора Цуруми', 'Beppu Ropeway and Mount Tsurumi', 'Бэппу аспалы жолы және Цуруми тауы', 33.28470000, 131.42930000, 'Beppu Ropeway Mount Tsurumi Japan', ARRAY['beppu']::text[], ARRAY['beppu']::text[], 'Itsukushima_Gate.jpg'),
    ('sengan-en', 'kagoshima', 'PARK', 2, 'HOURS', 4.7, 'Сэнган-эн', 'Sengan-en', 'Сэнган-эн', 31.61730000, 130.57800000, 'Sengan-en Kagoshima Japan', ARRAY['kagoshima', 'kumamoto']::text[], ARRAY['kagoshima', 'kumamoto']::text[], 'Itsukushima_Gate.jpg'),
    ('sakurajima', 'kagoshima', 'NATURE', 4, 'HOURS', 4.8, 'Сакурадзима', 'Sakurajima', 'Сакурадзима', 31.58500000, 130.65780000, 'Sakurajima Kagoshima Japan', ARRAY['kagoshima']::text[], ARRAY['kagoshima']::text[], 'Itsukushima_Gate.jpg'),
    ('shiroyama-observatory', 'kagoshima', 'NATURE', 1, 'HOURS', 4.6, 'Обзорная площадка Сирояма', 'Shiroyama Observatory', 'Сирояма қарау алаңы', 31.59660000, 130.54680000, 'Shiroyama Observatory Kagoshima Japan', ARRAY['kagoshima']::text[], ARRAY['kagoshima']::text[], 'Itsukushima_Gate.jpg'),
    ('kokusai-dori-street', 'naha', 'SHOPPING', 2, 'HOURS', 4.5, 'Улица Кокусай-дори', 'Kokusai-dori Street', 'Кокусай-дори көшесі', 26.21450000, 127.67920000, 'Kokusai-dori Street Naha Okinawa Japan', ARRAY['naha', 'chatan', 'motobu']::text[], ARRAY['naha', 'chatan', 'motobu']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('first-makishi-public-market', 'naha', 'MARKET', 1, 'HOURS', 4.5, 'Первый общественный рынок Макиси', 'First Makishi Public Market', 'Бірінші Макиси қоғамдық базары', 26.21490000, 127.68730000, 'First Makishi Public Market Naha Japan', ARRAY['naha']::text[], ARRAY['naha']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('naminoue-beach', 'naha', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Наминоуэ', 'Naminoue Beach', 'Наминоуэ жағажайы', 26.22080000, 127.67030000, 'Naminoue Beach Naha Okinawa Japan', ARRAY['naha']::text[], ARRAY['naha']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('shurijo-castle-park', 'naha', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Парк замка Сюри', 'Shuri Castle Park', 'Сюри қамал саябағы', 26.21700000, 127.71940000, 'Shuri Castle Park Okinawa Japan', ARRAY['naha']::text[], ARRAY['naha']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('okinawa-churaumi-aquarium', 'motobu', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Аквариум Тюрауми', 'Okinawa Churaumi Aquarium', 'Окинава Тюрауми аквариумы', 26.69420000, 127.87770000, 'Okinawa Churaumi Aquarium Japan', ARRAY['motobu', 'naha', 'onna']::text[], ARRAY['motobu', 'naha', 'onna']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('mihama-american-village', 'chatan', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Американская деревня Михама', 'Mihama American Village', 'Михама Американ ауылы', 26.31680000, 127.75560000, 'Mihama American Village Okinawa Japan', ARRAY['chatan', 'naha', 'onna']::text[], ARRAY['chatan', 'naha', 'onna']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('manza-beach', 'onna', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Манза', 'Manza Beach', 'Манза жағажайы', 26.50260000, 127.85050000, 'Manza Beach Onna Okinawa Japan', ARRAY['onna', 'naha', 'motobu']::text[], ARRAY['onna', 'naha', 'motobu']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('kabira-bay', 'ishigaki', 'BEACH', 3, 'HOURS', 4.8, 'Бухта Кабира', 'Kabira Bay', 'Кабира шығанағы', 24.45670000, 124.14420000, 'Kabira Bay Ishigaki Japan', ARRAY['ishigaki']::text[], ARRAY['ishigaki']::text[], 'Onna_Okinawa_ANA-InterContinental-Manza-Beach-Resort-01.jpg'),
    ('ritsurin-garden', 'takamatsu', 'PARK', 3, 'HOURS', 4.8, 'Сад Рицурин', 'Ritsurin Garden', 'Рицурин бағы', 34.32940000, 134.04410000, 'Ritsurin Garden Takamatsu Japan', ARRAY['takamatsu', 'matsuyama']::text[], ARRAY['takamatsu', 'matsuyama']::text[], 'Itsukushima_Gate.jpg'),
    ('yashima', 'takamatsu', 'NATURE', 3, 'HOURS', 4.5, 'Ясима', 'Yashima', 'Ясима', 34.35700000, 134.10100000, 'Yashima Takamatsu Japan', ARRAY['takamatsu']::text[], ARRAY['takamatsu']::text[], 'Itsukushima_Gate.jpg'),
    ('matsuyama-castle', 'matsuyama', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Мацуяма', 'Matsuyama Castle', 'Мацуяма қамалы', 33.84560000, 132.76570000, 'Matsuyama Castle Japan', ARRAY['matsuyama', 'takamatsu']::text[], ARRAY['matsuyama', 'takamatsu']::text[], 'Itsukushima_Gate.jpg'),
    ('dogo-onsen-honkan', 'matsuyama', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дого Онсэн Хонкан', 'Dogo Onsen Honkan', 'Дого Онсэн Хонкан', 33.85200000, 132.78680000, 'Dogo Onsen Honkan Matsuyama Japan', ARRAY['matsuyama']::text[], ARRAY['matsuyama']::text[], 'Itsukushima_Gate.jpg');

CREATE TEMP TABLE seed_japan_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-japan-attraction:' || seed.slug) AS attraction_hash,
        md5('id-japan-media:' || seed.slug) AS media_hash
    FROM seed_japan_priority_attractions seed
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
    ARRAY['japan', city_id, slug, lower(category), 'japan-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Японии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Japan tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Жапония бағыты бойынша туристік орын: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'JP',
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
FROM seed_japan_resolved_attractions
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
FROM seed_japan_resolved_attractions
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_japan_resolved_attractions
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_japan_resolved_attractions
ON CONFLICT (attraction_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE attractions a
SET
    latitude = seed.latitude,
    longitude = seed.longitude,
    location_source_url = seed.location_source_url,
    updated_at = NOW()
FROM seed_japan_resolved_attractions seed
WHERE a.id = seed.id;

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
FROM seed_japan_resolved_attractions
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
SELECT
    gen_random_uuid(),
    id,
    'ACCESS',
    'JP',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_japan_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'JP',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_japan_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_japan_resolved_attractions;
DROP TABLE IF EXISTS seed_japan_priority_attractions;
