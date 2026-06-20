-- Priority Kenya destination places seed.
-- The seed covers Nairobi, safari circuits, Rift Valley lakes, the coast, northern parks, western Kenya, museums, markets, malls, food, and entertainment hubs.

DROP TABLE IF EXISTS seed_kenya_resolved_places;
DROP TABLE IF EXISTS seed_kenya_priority_places;

CREATE TEMP TABLE seed_kenya_priority_places (
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

INSERT INTO seed_kenya_priority_places (
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
    ('nairobi-national-park', 'nairobi', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Найроби', 'Nairobi National Park', 'Найроби ұлттық паркі', -1.37330000, 36.85890000, 'Nairobi National Park Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_National_Park.jpg'),
    ('nairobi-national-museum', 'nairobi', 'MUSEUM', 3, 'HOURS', 4.7, 'Национальный музей Найроби', 'Nairobi National Museum', 'Найроби ұлттық музейі', -1.27390000, 36.81560000, 'Nairobi National Museum Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_National_Museum.jpg'),
    ('kenya-national-archives', 'nairobi', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный архив Кении', 'Kenya National Archives', 'Кения ұлттық архиві', -1.28480000, 36.82500000, 'Kenya National Archives Nairobi', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('kicc-helipad-viewpoint', 'nairobi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'KICC и смотровая площадка', 'KICC Helipad Viewpoint', 'KICC көрініс алаңы', -1.28860000, 36.82300000, 'Kenyatta International Convention Centre Nairobi', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'KICC_Nairobi.jpg'),
    ('jamia-mosque-nairobi', 'nairobi', 'TEMPLE', 1, 'HOURS', 4.6, 'Мечеть Джамия Найроби', 'Jamia Mosque Nairobi', 'Найроби Джамия мешіті', -1.28200000, 36.82060000, 'Jamia Mosque Nairobi Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('uhuru-park', 'nairobi', 'PARK', 2, 'HOURS', 4.5, 'Парк Ухуру', 'Uhuru Park', 'Ухуру паркі', -1.28930000, 36.81610000, 'Uhuru Park Nairobi Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('maasai-market-nairobi', 'nairobi', 'MARKET', 2, 'HOURS', 4.5, 'Рынок масаи в Найроби', 'Maasai Market Nairobi', 'Найроби масаи базары', -1.28640000, 36.81720000, 'Maasai Market Nairobi Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('village-market-nairobi', 'nairobi', 'SHOPPING', 2, 'HOURS', 4.5, 'The Village Market', 'The Village Market Nairobi', 'The Village Market Nairobi', -1.23050000, 36.80370000, 'The Village Market Nairobi', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('sarit-centre', 'nairobi', 'SHOPPING', 2, 'HOURS', 4.5, 'Sarit Centre', 'Sarit Centre', 'Sarit Centre', -1.26180000, 36.80200000, 'Sarit Centre Nairobi', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('karen-blixen-museum', 'karen', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Карен Бликсен', 'Karen Blixen Museum', 'Карен Бликсен музейі', -1.35100000, 36.71380000, 'Karen Blixen Museum Nairobi Kenya', ARRAY['karen', 'nairobi']::text[], ARRAY['nairobi', 'karen']::text[], 'Karen_Blixen_Museum_Nairobi.jpg'),
    ('ngong-hills', 'karen', 'NATURE', 4, 'HOURS', 4.6, 'Холмы Нгонг', 'Ngong Hills', 'Нгонг төбелері', -1.40000000, 36.65000000, 'Ngong Hills Kenya', ARRAY['karen', 'nairobi']::text[], ARRAY['nairobi', 'karen']::text[], 'Ngong_Hills.jpg'),
    ('giraffe-centre', 'langata', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Центр жирафов', 'Giraffe Centre', 'Керік орталығы', -1.37670000, 36.74420000, 'Giraffe Centre Nairobi Kenya', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Giraffe_Centre_Nairobi.jpg'),
    ('sheldrick-wildlife-trust', 'langata', 'NATURE', 2, 'HOURS', 4.8, 'Фонд Sheldrick Wildlife Trust', 'Sheldrick Wildlife Trust', 'Sheldrick Wildlife Trust', -1.37310000, 36.77160000, 'Sheldrick Wildlife Trust Nairobi', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Nairobi_National_Park.jpg'),
    ('bomas-of-kenya', 'langata', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Bomas of Kenya', 'Bomas of Kenya', 'Bomas of Kenya', -1.33740000, 36.76880000, 'Bomas of Kenya Nairobi', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Nairobi_National_Park.jpg'),
    ('karura-forest', 'kiambu', 'NATURE', 3, 'HOURS', 4.7, 'Лес Карура', 'Karura Forest', 'Карура орманы', -1.23940000, 36.83440000, 'Karura Forest Nairobi Kenya', ARRAY['kiambu', 'nairobi']::text[], ARRAY['nairobi', 'kiambu']::text[], 'Karura_Forest.jpg'),
    ('two-rivers-mall', 'kiambu', 'SHOPPING', 2, 'HOURS', 4.5, 'Two Rivers Mall', 'Two Rivers Mall', 'Two Rivers Mall', -1.21060000, 36.79430000, 'Two Rivers Mall Nairobi Kenya', ARRAY['kiambu', 'nairobi']::text[], ARRAY['nairobi', 'kiambu']::text[], 'Nairobi_CBD.jpg'),

    ('lake-naivasha', 'lake-naivasha', 'NATURE', 4, 'HOURS', 4.7, 'Озеро Найваша', 'Lake Naivasha', 'Найваша көлі', -0.76670000, 36.36670000, 'Lake Naivasha Kenya', ARRAY['lake-naivasha', 'naivasha']::text[], ARRAY['naivasha', 'nairobi']::text[], 'Lake_Naivasha.jpg'),
    ('crescent-island-game-sanctuary', 'lake-naivasha', 'PARK', 3, 'HOURS', 4.6, 'Заповедник Crescent Island', 'Crescent Island Game Sanctuary', 'Crescent Island қорығы', -0.78330000, 36.41670000, 'Crescent Island Game Sanctuary Kenya', ARRAY['lake-naivasha', 'naivasha']::text[], ARRAY['naivasha']::text[], 'Lake_Naivasha.jpg'),
    ('hells-gate-national-park', 'hells-gate', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Хеллс-Гейт', 'Hell''s Gate National Park', 'Хеллс-Гейт ұлттық паркі', -0.91670000, 36.31670000, 'Hell''s Gate National Park Kenya', ARRAY['hells-gate', 'naivasha']::text[], ARRAY['naivasha', 'nairobi']::text[], 'Hells_Gate_National_Park.jpg'),
    ('fischers-tower', 'hells-gate', 'NATURE', 2, 'HOURS', 4.5, 'Башня Фишера', 'Fischer''s Tower', 'Фишер мұнарасы', -0.90000000, 36.31670000, 'Fischer''s Tower Hell''s Gate Kenya', ARRAY['hells-gate']::text[], ARRAY['hells-gate', 'naivasha']::text[], 'Hells_Gate_National_Park.jpg'),
    ('mount-kenya-national-park', 'mount-kenya', 'PARK', 8, 'HOURS', 4.9, 'Национальный парк Гора Кения', 'Mount Kenya National Park', 'Кения тауы ұлттық паркі', -0.15210000, 37.30840000, 'Mount Kenya National Park', ARRAY['mount-kenya', 'nanyuki', 'nyeri']::text[], ARRAY['nanyuki', 'nyeri', 'nairobi']::text[], 'Mount_Kenya.jpg'),
    ('nanyuki-equator-marker', 'nanyuki', 'OTHER', 1, 'HOURS', 4.4, 'Экватор в Наньюки', 'Nanyuki Equator Marker', 'Наньюки экватор белгісі', 0.01670000, 37.06670000, 'Nanyuki Equator Marker Kenya', ARRAY['nanyuki']::text[], ARRAY['nanyuki']::text[], 'Mount_Kenya.jpg'),
    ('aberdare-national-park', 'aberdares', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Абердэр', 'Aberdare National Park', 'Абердэр ұлттық паркі', -0.41670000, 36.75000000, 'Aberdare National Park Kenya', ARRAY['aberdares', 'nyeri']::text[], ARRAY['nyeri', 'nairobi']::text[], 'Aberdare_National_Park.jpg'),
    ('solio-ranch', 'nyeri', 'NATURE', 4, 'HOURS', 4.6, 'Solio Ranch', 'Solio Ranch', 'Solio Ranch', -0.25880000, 36.88310000, 'Solio Ranch Nyeri Kenya', ARRAY['nyeri']::text[], ARRAY['nyeri', 'nairobi']::text[], 'Mount_Kenya.jpg'),
    ('nyeri-museum', 'nyeri', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Ньери', 'Nyeri Museum', 'Ньери музейі', -0.42130000, 36.94800000, 'Nyeri Museum Kenya', ARRAY['nyeri']::text[], ARRAY['nyeri']::text[], 'Mount_Kenya.jpg'),

    ('masai-mara-national-reserve', 'masai-mara', 'PARK', 8, 'HOURS', 4.9, 'Национальный заповедник Масаи-Мара', 'Masai Mara National Reserve', 'Масаи-Мара ұлттық қорығы', -1.49310000, 35.14390000, 'Masai Mara National Reserve Kenya', ARRAY['masai-mara']::text[], ARRAY['masai-mara', 'nairobi', 'narok']::text[], 'Masai_Mara_at_Sunset.jpg'),
    ('mara-river-crossing', 'masai-mara', 'NATURE', 4, 'HOURS', 4.9, 'Переход через реку Мара', 'Mara River Crossing', 'Мара өзені өткелі', -1.37640000, 34.95090000, 'Mara River Crossing Kenya', ARRAY['masai-mara']::text[], ARRAY['masai-mara', 'narok']::text[], 'Masai_Mara_at_Sunset.jpg'),
    ('maasai-village-experience', 'narok', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Культурная деревня масаи', 'Maasai Village Experience', 'Масаи ауылы тәжірибесі', -1.09000000, 35.87000000, 'Maasai Village Narok Kenya', ARRAY['narok', 'masai-mara']::text[], ARRAY['narok', 'masai-mara']::text[], 'Masai_Mara_at_Sunset.jpg'),
    ('narok-museum', 'narok', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Нарока', 'Narok Museum', 'Нарок музейі', -1.08770000, 35.87110000, 'Narok Museum Kenya', ARRAY['narok']::text[], ARRAY['narok']::text[], 'Masai_Mara_at_Sunset.jpg'),
    ('lake-nakuru-national-park', 'lake-nakuru', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Озеро Накуру', 'Lake Nakuru National Park', 'Накуру көлі ұлттық паркі', -0.36670000, 36.08330000, 'Lake Nakuru National Park Kenya', ARRAY['lake-nakuru', 'nakuru']::text[], ARRAY['nakuru', 'nairobi']::text[], 'Lake_Nakuru_National_Park.jpg'),
    ('menengai-crater', 'nakuru', 'NATURE', 3, 'HOURS', 4.6, 'Кратер Мененгай', 'Menengai Crater', 'Мененгай кратері', -0.20000000, 36.06670000, 'Menengai Crater Nakuru Kenya', ARRAY['nakuru']::text[], ARRAY['nakuru']::text[], 'Lake_Nakuru_National_Park.jpg'),
    ('hyrax-hill-museum', 'nakuru', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Hyrax Hill', 'Hyrax Hill Museum', 'Hyrax Hill музейі', -0.30350000, 36.10260000, 'Hyrax Hill Museum Nakuru Kenya', ARRAY['nakuru']::text[], ARRAY['nakuru']::text[], 'Lake_Nakuru_National_Park.jpg'),
    ('westside-mall-nakuru', 'nakuru', 'SHOPPING', 2, 'HOURS', 4.4, 'Westside Mall Nakuru', 'Westside Mall Nakuru', 'Westside Mall Nakuru', -0.28900000, 36.06500000, 'Westside Mall Nakuru Kenya', ARRAY['nakuru']::text[], ARRAY['nakuru']::text[], 'Lake_Nakuru_National_Park.jpg'),
    ('lake-elementaita', 'lake-elementaita', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Элементайта', 'Lake Elementaita', 'Элементайта көлі', -0.45000000, 36.25000000, 'Lake Elementaita Kenya', ARRAY['lake-elementaita']::text[], ARRAY['lake-elementaita', 'nakuru']::text[], 'Lake_Elementaita.jpg'),
    ('lake-bogoria', 'lake-bogoria', 'NATURE', 4, 'HOURS', 4.7, 'Озеро Богория', 'Lake Bogoria', 'Богория көлі', 0.25000000, 36.10000000, 'Lake Bogoria Kenya', ARRAY['lake-bogoria']::text[], ARRAY['lake-bogoria', 'nakuru']::text[], 'Lake_Bogoria.jpg'),
    ('lake-baringo', 'lake-baringo', 'NATURE', 4, 'HOURS', 4.6, 'Озеро Баринго', 'Lake Baringo', 'Баринго көлі', 0.63330000, 36.05000000, 'Lake Baringo Kenya', ARRAY['lake-baringo']::text[], ARRAY['lake-baringo', 'nakuru']::text[], 'Lake_Baringo.jpg'),
    ('eldoret-rupa-mall', 'eldoret', 'SHOPPING', 2, 'HOURS', 4.4, 'Rupa Mall Eldoret', 'Rupa Mall Eldoret', 'Rupa Mall Eldoret', 0.51430000, 35.26980000, 'Rupa Mall Eldoret Kenya', ARRAY['eldoret']::text[], ARRAY['eldoret']::text[], 'Eldoret_Kenya.jpg'),
    ('kericho-tea-estates', 'kericho', 'FOOD', 3, 'HOURS', 4.6, 'Чайные плантации Керичо', 'Kericho Tea Estates', 'Керичо шай плантациялары', -0.36700000, 35.28300000, 'Kericho Tea Estates Kenya', ARRAY['kericho']::text[], ARRAY['kericho', 'kisumu']::text[], 'Kericho_Tea_Estates.jpg'),

    ('fort-jesus', 'mombasa', 'MUSEUM', 2, 'HOURS', 4.8, 'Форт Иисус', 'Fort Jesus', 'Форт Иисус', -4.06250000, 39.67990000, 'Fort Jesus Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('mombasa-old-town', 'mombasa', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый город Момбасы', 'Mombasa Old Town', 'Момбаса ескі қаласы', -4.06050000, 39.67590000, 'Mombasa Old Town Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('mombasa-tusks', 'mombasa', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Бивни Момбасы', 'Mombasa Tusks', 'Момбаса азулары', -4.06340000, 39.67090000, 'Mombasa Tusks Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('marikiti-market-mombasa', 'mombasa', 'MARKET', 2, 'HOURS', 4.4, 'Рынок Марикити', 'Marikiti Market Mombasa', 'Марикити базары', -4.05600000, 39.66740000, 'Marikiti Market Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('haller-park', 'mombasa', 'PARK', 3, 'HOURS', 4.6, 'Парк Халлер', 'Haller Park', 'Халлер паркі', -4.02180000, 39.72060000, 'Haller Park Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Haller_Park_Mombasa.jpg'),
    ('nyali-beach', 'mombasa', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Ньяли', 'Nyali Beach', 'Ньяли жағажайы', -4.03500000, 39.72000000, 'Nyali Beach Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Mombasa_Beach.jpg'),
    ('city-mall-nyali', 'mombasa', 'SHOPPING', 2, 'HOURS', 4.4, 'City Mall Nyali', 'City Mall Nyali', 'City Mall Nyali', -4.02250000, 39.71990000, 'City Mall Nyali Mombasa', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Mombasa_Beach.jpg'),
    ('wild-waters-mombasa', 'mombasa', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Wild Waters Mombasa', 'Wild Waters Mombasa', 'Wild Waters Mombasa', -4.04010000, 39.71790000, 'Wild Waters Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Mombasa_Beach.jpg'),
    ('diani-beach', 'diani', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Диани', 'Diani Beach', 'Диани жағажайы', -4.27970000, 39.59420000, 'Diani Beach Kenya', ARRAY['diani']::text[], ARRAY['diani', 'mombasa']::text[], 'Diani_Beach_Kenya.jpg'),
    ('colobus-conservation', 'diani', 'NATURE', 2, 'HOURS', 4.6, 'Colobus Conservation', 'Colobus Conservation', 'Colobus Conservation', -4.31400000, 39.57900000, 'Colobus Conservation Diani Kenya', ARRAY['diani']::text[], ARRAY['diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('kaya-kinondo-sacred-forest', 'diani', 'NATURE', 3, 'HOURS', 4.7, 'Священный лес Kaya Kinondo', 'Kaya Kinondo Sacred Forest', 'Kaya Kinondo қасиетті орманы', -4.39000000, 39.57000000, 'Kaya Kinondo Sacred Forest Kenya', ARRAY['diani']::text[], ARRAY['diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('shimba-hills-national-reserve', 'diani', 'PARK', 5, 'HOURS', 4.7, 'Заповедник Шимба-Хиллс', 'Shimba Hills National Reserve', 'Шимба-Хиллс қорығы', -4.25000000, 39.41670000, 'Shimba Hills National Reserve Kenya', ARRAY['diani']::text[], ARRAY['diani', 'mombasa']::text[], 'Diani_Beach_Kenya.jpg'),
    ('malindi-marine-national-park', 'malindi', 'PARK', 4, 'HOURS', 4.7, 'Морской парк Малинди', 'Malindi Marine National Park', 'Малинди теңіз ұлттық паркі', -3.25000000, 40.13330000, 'Malindi Marine National Park Kenya', ARRAY['malindi']::text[], ARRAY['malindi']::text[], 'Malindi_Beach.jpg'),
    ('vasco-da-gama-pillar', 'malindi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Столб Васко да Гамы', 'Vasco da Gama Pillar', 'Васко да Гама бағаны', -3.21860000, 40.12530000, 'Vasco da Gama Pillar Malindi', ARRAY['malindi']::text[], ARRAY['malindi']::text[], 'Malindi_Beach.jpg'),
    ('portuguese-chapel-malindi', 'malindi', 'TEMPLE', 1, 'HOURS', 4.5, 'Португальская часовня Малинди', 'Portuguese Chapel Malindi', 'Малинди португал капелласы', -3.22090000, 40.12380000, 'Portuguese Chapel Malindi Kenya', ARRAY['malindi']::text[], ARRAY['malindi']::text[], 'Malindi_Beach.jpg'),
    ('watamu-beach', 'watamu', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Ватаму', 'Watamu Beach', 'Ватаму жағажайы', -3.35200000, 40.02000000, 'Watamu Beach Kenya', ARRAY['watamu']::text[], ARRAY['watamu', 'malindi']::text[], 'Watamu_Beach.jpg'),
    ('watamu-marine-national-park', 'watamu', 'PARK', 4, 'HOURS', 4.8, 'Морской парк Ватаму', 'Watamu Marine National Park', 'Ватаму теңіз ұлттық паркі', -3.36670000, 40.01670000, 'Watamu Marine National Park Kenya', ARRAY['watamu']::text[], ARRAY['watamu', 'malindi']::text[], 'Watamu_Beach.jpg'),
    ('gede-ruins', 'watamu', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Руины Геде', 'Gede Ruins', 'Геде қирандылары', -3.31330000, 40.01560000, 'Gede Ruins Watamu Kenya', ARRAY['watamu', 'malindi']::text[], ARRAY['watamu', 'malindi']::text[], 'Gede_Ruins_Kenya.jpg'),
    ('bio-ken-snake-farm', 'watamu', 'NATURE', 2, 'HOURS', 4.5, 'Bio-Ken Snake Farm', 'Bio-Ken Snake Farm', 'Bio-Ken Snake Farm', -3.35330000, 40.01810000, 'Bio-Ken Snake Farm Watamu', ARRAY['watamu']::text[], ARRAY['watamu']::text[], 'Watamu_Beach.jpg'),
    ('lamu-old-town', 'lamu', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Старый город Ламу', 'Lamu Old Town', 'Ламу ескі қаласы', -2.27070000, 40.90200000, 'Lamu Old Town Kenya', ARRAY['lamu']::text[], ARRAY['lamu']::text[], 'Lamu_Old_Town.jpg'),
    ('lamu-museum', 'lamu', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Ламу', 'Lamu Museum', 'Ламу музейі', -2.27080000, 40.90290000, 'Lamu Museum Kenya', ARRAY['lamu']::text[], ARRAY['lamu']::text[], 'Lamu_Old_Town.jpg'),
    ('lamu-fort', 'lamu', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Форт Ламу', 'Lamu Fort', 'Ламу қамалы', -2.27060000, 40.90260000, 'Lamu Fort Kenya', ARRAY['lamu']::text[], ARRAY['lamu']::text[], 'Lamu_Old_Town.jpg'),
    ('shela-beach', 'lamu', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Шела', 'Shela Beach', 'Шела жағажайы', -2.29290000, 40.91450000, 'Shela Beach Lamu Kenya', ARRAY['lamu']::text[], ARRAY['lamu']::text[], 'Lamu_Old_Town.jpg'),
    ('takwa-ruins', 'lamu', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Руины Таква', 'Takwa Ruins', 'Таква қирандылары', -2.27670000, 40.98280000, 'Takwa Ruins Lamu Kenya', ARRAY['lamu']::text[], ARRAY['lamu']::text[], 'Lamu_Old_Town.jpg'),
    ('kilifi-creek', 'kilifi', 'NATURE', 3, 'HOURS', 4.6, 'Залив Килифи', 'Kilifi Creek', 'Килифи шығанағы', -3.63330000, 39.85000000, 'Kilifi Creek Kenya', ARRAY['kilifi']::text[], ARRAY['kilifi', 'mombasa']::text[], 'Kilifi_Creek.jpg'),
    ('shimoni-caves', 'shimoni', 'MUSEUM', 2, 'HOURS', 4.5, 'Пещеры Шимони', 'Shimoni Caves', 'Шимони үңгірлері', -4.64710000, 39.38160000, 'Shimoni Caves Kenya', ARRAY['shimoni']::text[], ARRAY['shimoni', 'diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('kisite-mpunguti-marine-park', 'kisite-mpunguti', 'PARK', 5, 'HOURS', 4.8, 'Морской парк Кисите-Мпунгути', 'Kisite-Mpunguti Marine Park', 'Кисите-Мпунгути теңіз паркі', -4.71670000, 39.36670000, 'Kisite-Mpunguti Marine Park Kenya', ARRAY['kisite-mpunguti', 'shimoni']::text[], ARRAY['shimoni', 'diani']::text[], 'Kisite_Mpunguti_Marine_Park.jpg'),
    ('wasini-island', 'shimoni', 'FOOD', 4, 'HOURS', 4.6, 'Остров Васини', 'Wasini Island', 'Васини аралы', -4.66670000, 39.38330000, 'Wasini Island Kenya seafood', ARRAY['shimoni', 'kisite-mpunguti']::text[], ARRAY['shimoni', 'diani']::text[], 'Kisite_Mpunguti_Marine_Park.jpg'),

    ('amboseli-national-park', 'amboseli', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Амбосели', 'Amboseli National Park', 'Амбосели ұлттық паркі', -2.64500000, 37.25330000, 'Amboseli National Park Kenya', ARRAY['amboseli']::text[], ARRAY['amboseli', 'nairobi']::text[], 'Amboseli_National_Park.jpg'),
    ('amboseli-observation-hill', 'amboseli', 'NATURE', 2, 'HOURS', 4.7, 'Observation Hill в Амбосели', 'Amboseli Observation Hill', 'Амбосели Observation Hill', -2.65000000, 37.25000000, 'Observation Hill Amboseli Kenya', ARRAY['amboseli']::text[], ARRAY['amboseli']::text[], 'Amboseli_National_Park.jpg'),
    ('tsavo-east-national-park', 'tsavo-east', 'PARK', 8, 'HOURS', 4.8, 'Национальный парк Восточный Цаво', 'Tsavo East National Park', 'Шығыс Цаво ұлттық паркі', -2.90000000, 38.70000000, 'Tsavo East National Park Kenya', ARRAY['tsavo-east']::text[], ARRAY['tsavo-east', 'mombasa', 'nairobi']::text[], 'Tsavo_East_National_Park.jpg'),
    ('lugard-falls', 'tsavo-east', 'NATURE', 2, 'HOURS', 4.6, 'Водопады Лугард', 'Lugard Falls', 'Лугард сарқырамалары', -3.05500000, 38.65000000, 'Lugard Falls Tsavo East Kenya', ARRAY['tsavo-east']::text[], ARRAY['tsavo-east']::text[], 'Tsavo_East_National_Park.jpg'),
    ('yatta-plateau', 'tsavo-east', 'NATURE', 2, 'HOURS', 4.6, 'Плато Ятта', 'Yatta Plateau', 'Ятта үстірті', -2.80000000, 38.50000000, 'Yatta Plateau Tsavo East Kenya', ARRAY['tsavo-east']::text[], ARRAY['tsavo-east']::text[], 'Tsavo_East_National_Park.jpg'),
    ('tsavo-west-national-park', 'tsavo-west', 'PARK', 8, 'HOURS', 4.8, 'Национальный парк Западный Цаво', 'Tsavo West National Park', 'Батыс Цаво ұлттық паркі', -2.98330000, 38.03330000, 'Tsavo West National Park Kenya', ARRAY['tsavo-west']::text[], ARRAY['tsavo-west', 'mombasa', 'nairobi']::text[], 'Tsavo_West_National_Park.jpg'),
    ('mzima-springs', 'tsavo-west', 'NATURE', 2, 'HOURS', 4.7, 'Источники Мзима', 'Mzima Springs', 'Мзима бұлақтары', -2.99470000, 38.02350000, 'Mzima Springs Tsavo West Kenya', ARRAY['tsavo-west']::text[], ARRAY['tsavo-west']::text[], 'Tsavo_West_National_Park.jpg'),
    ('shetani-lava-flow', 'tsavo-west', 'NATURE', 2, 'HOURS', 4.6, 'Лавовое поле Shetani', 'Shetani Lava Flow', 'Shetani лава алқабы', -2.91670000, 37.91670000, 'Shetani Lava Flow Tsavo West Kenya', ARRAY['tsavo-west']::text[], ARRAY['tsavo-west']::text[], 'Tsavo_West_National_Park.jpg'),
    ('samburu-national-reserve', 'samburu', 'PARK', 6, 'HOURS', 4.8, 'Национальный заповедник Самбуру', 'Samburu National Reserve', 'Самбуру ұлттық қорығы', 0.62360000, 37.53000000, 'Samburu National Reserve Kenya', ARRAY['samburu']::text[], ARRAY['samburu', 'nairobi']::text[], 'Samburu_National_Reserve.jpg'),
    ('buffalo-springs-national-reserve', 'samburu', 'PARK', 5, 'HOURS', 4.7, 'Заповедник Buffalo Springs', 'Buffalo Springs National Reserve', 'Buffalo Springs қорығы', 0.53330000, 37.61670000, 'Buffalo Springs National Reserve Kenya', ARRAY['samburu']::text[], ARRAY['samburu']::text[], 'Samburu_National_Reserve.jpg'),
    ('reteti-elephant-sanctuary', 'samburu', 'NATURE', 2, 'HOURS', 4.7, 'Слоновий приют Reteti', 'Reteti Elephant Sanctuary', 'Reteti пілдер қорығы', 0.88330000, 37.11670000, 'Reteti Elephant Sanctuary Kenya', ARRAY['samburu']::text[], ARRAY['samburu', 'nanyuki']::text[], 'Samburu_National_Reserve.jpg'),
    ('ol-pejeta-conservancy', 'ol-pejeta', 'PARK', 5, 'HOURS', 4.8, 'Заповедник Ол-Педжета', 'Ol Pejeta Conservancy', 'Ол-Педжета қорығы', 0.01670000, 36.90000000, 'Ol Pejeta Conservancy Kenya', ARRAY['ol-pejeta', 'nanyuki']::text[], ARRAY['nanyuki', 'nairobi']::text[], 'Ol_Pejeta_Conservancy.jpg'),
    ('sweetwaters-chimpanzee-sanctuary', 'ol-pejeta', 'NATURE', 2, 'HOURS', 4.7, 'Приют шимпанзе Sweetwaters', 'Sweetwaters Chimpanzee Sanctuary', 'Sweetwaters шимпанзе қорығы', 0.01700000, 36.90000000, 'Sweetwaters Chimpanzee Sanctuary Kenya', ARRAY['ol-pejeta', 'nanyuki']::text[], ARRAY['nanyuki']::text[], 'Ol_Pejeta_Conservancy.jpg'),
    ('laikipia-plateau', 'laikipia', 'NATURE', 5, 'HOURS', 4.7, 'Плато Лайкипия', 'Laikipia Plateau', 'Лайкипия үстірті', 0.30000000, 36.90000000, 'Laikipia Plateau Kenya', ARRAY['laikipia', 'nanyuki']::text[], ARRAY['nanyuki', 'nairobi']::text[], 'Laikipia_Kenya.jpg'),
    ('meru-national-park', 'meru', 'PARK', 6, 'HOURS', 4.7, 'Национальный парк Меру', 'Meru National Park', 'Меру ұлттық паркі', 0.16670000, 38.20000000, 'Meru National Park Kenya', ARRAY['meru']::text[], ARRAY['meru', 'nairobi']::text[], 'Meru_National_Park_Kenya.jpg'),
    ('marsabit-national-park', 'marsabit', 'PARK', 5, 'HOURS', 4.6, 'Национальный парк Марсабит', 'Marsabit National Park', 'Марсабит ұлттық паркі', 2.33330000, 37.98330000, 'Marsabit National Park Kenya', ARRAY['marsabit']::text[], ARRAY['marsabit', 'nairobi']::text[], 'Marsabit_National_Park.jpg'),
    ('lake-turkana-national-parks', 'lake-turkana', 'PARK', 6, 'HOURS', 4.8, 'Национальные парки озера Туркана', 'Lake Turkana National Parks', 'Туркана көлі ұлттық парктері', 3.50000000, 36.00000000, 'Lake Turkana National Parks Kenya', ARRAY['lake-turkana']::text[], ARRAY['lake-turkana']::text[], 'Lake_Turkana.jpg'),
    ('sibiloi-national-park', 'lake-turkana', 'PARK', 5, 'HOURS', 4.7, 'Национальный парк Сибилои', 'Sibiloi National Park', 'Сибилои ұлттық паркі', 3.98330000, 36.33330000, 'Sibiloi National Park Kenya', ARRAY['lake-turkana']::text[], ARRAY['lake-turkana']::text[], 'Lake_Turkana.jpg'),

    ('kisumu-impala-sanctuary', 'kisumu', 'PARK', 3, 'HOURS', 4.6, 'Заповедник Kisumu Impala', 'Kisumu Impala Sanctuary', 'Кисуму импала қорығы', -0.10220000, 34.74220000, 'Kisumu Impala Sanctuary Kenya', ARRAY['kisumu']::text[], ARRAY['kisumu']::text[], 'Kisumu_Kenya.jpg'),
    ('kisumu-museum', 'kisumu', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Кисуму', 'Kisumu Museum', 'Кисуму музейі', -0.10250000, 34.76120000, 'Kisumu Museum Kenya', ARRAY['kisumu']::text[], ARRAY['kisumu']::text[], 'Kisumu_Kenya.jpg'),
    ('dunga-beach', 'lake-victoria', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Дунга', 'Dunga Beach', 'Дунга жағажайы', -0.13060000, 34.73280000, 'Dunga Beach Kisumu Kenya', ARRAY['lake-victoria', 'kisumu']::text[], ARRAY['kisumu']::text[], 'Lake_Victoria_Kenya.jpg'),
    ('kibuye-market', 'kisumu', 'MARKET', 2, 'HOURS', 4.4, 'Рынок Кибуйе', 'Kibuye Market', 'Кибуйе базары', -0.09530000, 34.76270000, 'Kibuye Market Kisumu Kenya', ARRAY['kisumu']::text[], ARRAY['kisumu']::text[], 'Kisumu_Kenya.jpg'),
    ('west-end-mall-kisumu', 'kisumu', 'SHOPPING', 2, 'HOURS', 4.4, 'West End Mall Kisumu', 'West End Mall Kisumu', 'West End Mall Kisumu', -0.10200000, 34.75330000, 'West End Mall Kisumu Kenya', ARRAY['kisumu']::text[], ARRAY['kisumu']::text[], 'Kisumu_Kenya.jpg'),
    ('kakamega-forest', 'kakamega', 'NATURE', 5, 'HOURS', 4.8, 'Лес Какамега', 'Kakamega Forest', 'Какамега орманы', 0.28330000, 34.86670000, 'Kakamega Forest Kenya', ARRAY['kakamega']::text[], ARRAY['kakamega', 'kisumu']::text[], 'Kakamega_Forest.jpg'),
    ('crying-stone-ilesi', 'kakamega', 'NATURE', 1, 'HOURS', 4.4, 'Плачущий камень Илеси', 'Crying Stone of Ilesi', 'Илеси жылаған тасы', 0.18330000, 34.76670000, 'Crying Stone of Ilesi Kenya', ARRAY['kakamega']::text[], ARRAY['kakamega']::text[], 'Kakamega_Forest.jpg'),
    ('kitale-museum', 'kitale', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Китале', 'Kitale Museum', 'Китале музейі', 1.01670000, 35.00000000, 'Kitale Museum Kenya', ARRAY['kitale']::text[], ARRAY['kitale']::text[], 'Kitale_Museum.jpg'),
    ('saiwa-swamp-national-park', 'kitale', 'PARK', 3, 'HOURS', 4.6, 'Национальный парк Saiwa Swamp', 'Saiwa Swamp National Park', 'Saiwa Swamp ұлттық паркі', 1.10000000, 35.10000000, 'Saiwa Swamp National Park Kenya', ARRAY['kitale']::text[], ARRAY['kitale']::text[], 'Saiwa_Swamp_National_Park.jpg'),
    ('rusinga-island', 'rusinga-island', 'NATURE', 3, 'HOURS', 4.5, 'Остров Русинга', 'Rusinga Island', 'Русинга аралы', -0.40000000, 34.13330000, 'Rusinga Island Kenya', ARRAY['rusinga-island', 'lake-victoria']::text[], ARRAY['kisumu', 'rusinga-island']::text[], 'Lake_Victoria_Kenya.jpg'),
    ('tom-mboya-mausoleum', 'rusinga-island', 'MUSEUM', 2, 'HOURS', 4.4, 'Мавзолей Тома Мбойи', 'Tom Mboya Mausoleum', 'Том Мбойя мавзолейі', -0.40000000, 34.13330000, 'Tom Mboya Mausoleum Rusinga Island Kenya', ARRAY['rusinga-island']::text[], ARRAY['rusinga-island', 'kisumu']::text[], 'Lake_Victoria_Kenya.jpg'),
    ('ndere-island-national-park', 'ndere-island', 'PARK', 4, 'HOURS', 4.6, 'Национальный парк острова Ндере', 'Ndere Island National Park', 'Ндере аралы ұлттық паркі', -0.23330000, 34.35000000, 'Ndere Island National Park Kenya', ARRAY['ndere-island', 'lake-victoria']::text[], ARRAY['kisumu', 'ndere-island']::text[], 'Lake_Victoria_Kenya.jpg'),
    ('nairobi-safari-walk', 'langata', 'PARK', 2, 'HOURS', 4.6, 'Сафари-прогулка Найроби', 'Nairobi Safari Walk', 'Найроби сафари серуені', -1.36100000, 36.78380000, 'Nairobi Safari Walk Kenya', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Nairobi_National_Park.jpg'),
    ('nairobi-gallery', 'nairobi', 'MUSEUM', 2, 'HOURS', 4.5, 'Галерея Найроби', 'Nairobi Gallery', 'Найроби галереясы', -1.28850000, 36.81920000, 'Nairobi Gallery Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('city-market-nairobi', 'nairobi', 'MARKET', 2, 'HOURS', 4.4, 'Городской рынок Найроби', 'City Market Nairobi', 'Найроби қалалық базары', -1.28270000, 36.81770000, 'City Market Nairobi Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('nairobi-railway-museum', 'nairobi', 'MUSEUM', 2, 'HOURS', 4.5, 'Железнодорожный музей Найроби', 'Nairobi Railway Museum', 'Найроби теміржол музейі', -1.29290000, 36.82500000, 'Nairobi Railway Museum Kenya', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('the-alchemist-westlands', 'nairobi', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'The Alchemist в Westlands', 'The Alchemist Westlands', 'Westlands The Alchemist', -1.26490000, 36.80050000, 'The Alchemist Westlands Nairobi', ARRAY['nairobi']::text[], ARRAY['nairobi']::text[], 'Nairobi_CBD.jpg'),
    ('kazuri-beads-workshop', 'karen', 'SHOPPING', 2, 'HOURS', 4.6, 'Мастерская Kazuri Beads', 'Kazuri Beads Workshop', 'Kazuri Beads шеберханасы', -1.34950000, 36.70390000, 'Kazuri Beads Workshop Karen Kenya', ARRAY['karen', 'nairobi']::text[], ARRAY['nairobi', 'karen']::text[], 'Karen_Blixen_Museum_Nairobi.jpg'),
    ('uhuru-gardens-national-monument', 'langata', 'MUSEUM', 2, 'HOURS', 4.5, 'Uhuru Gardens National Monument', 'Uhuru Gardens National Monument and Museum', 'Uhuru Gardens ұлттық монументі', -1.32690000, 36.79900000, 'Uhuru Gardens National Monument Kenya', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Nairobi_National_Park.jpg'),
    ('the-hub-karen', 'karen', 'SHOPPING', 2, 'HOURS', 4.5, 'The Hub Karen', 'The Hub Karen', 'The Hub Karen', -1.31810000, 36.70640000, 'The Hub Karen Nairobi Kenya', ARRAY['karen', 'nairobi']::text[], ARRAY['nairobi', 'karen']::text[], 'Karen_Blixen_Museum_Nairobi.jpg'),
    ('carnivore-restaurant', 'langata', 'FOOD', 2, 'HOURS', 4.6, 'Ресторан Carnivore', 'The Carnivore Restaurant', 'Carnivore мейрамханасы', -1.32850000, 36.79260000, 'The Carnivore Restaurant Nairobi', ARRAY['langata', 'nairobi']::text[], ARRAY['nairobi', 'langata']::text[], 'Nairobi_National_Park.jpg'),
    ('kiambethu-tea-farm', 'kiambu', 'FOOD', 3, 'HOURS', 4.6, 'Чайная ферма Киамбетху', 'Kiambethu Tea Farm', 'Киамбетху шай фермасы', -1.10110000, 36.64860000, 'Kiambethu Tea Farm Limuru Kenya', ARRAY['kiambu', 'nairobi']::text[], ARRAY['nairobi', 'kiambu']::text[], 'Kericho_Tea_Estates.jpg'),
    ('fourteen-falls', 'kiambu', 'NATURE', 3, 'HOURS', 4.5, 'Водопады Fourteen Falls', 'Fourteen Falls', 'Fourteen Falls сарқырамалары', -1.04990000, 37.15000000, 'Fourteen Falls Thika Kenya', ARRAY['kiambu']::text[], ARRAY['kiambu', 'nairobi']::text[], 'Karura_Forest.jpg'),
    ('mount-longonot-national-park', 'naivasha', 'PARK', 5, 'HOURS', 4.7, 'Национальный парк Mount Longonot', 'Mount Longonot National Park', 'Mount Longonot ұлттық паркі', -0.91490000, 36.45620000, 'Mount Longonot National Park Kenya', ARRAY['naivasha']::text[], ARRAY['naivasha', 'nairobi']::text[], 'Lake_Naivasha.jpg'),
    ('olkaria-geothermal-spa', 'naivasha', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Olkaria Geothermal Spa', 'Olkaria Geothermal Spa', 'Olkaria Geothermal Spa', -0.89100000, 36.30900000, 'Olkaria Geothermal Spa Kenya', ARRAY['naivasha', 'hells-gate']::text[], ARRAY['naivasha']::text[], 'Hells_Gate_National_Park.jpg'),
    ('elsamere-conservation-centre', 'naivasha', 'MUSEUM', 2, 'HOURS', 4.5, 'Центр Elsamere', 'Elsamere Conservation Centre', 'Elsamere табиғатты қорғау орталығы', -0.80000000, 36.36670000, 'Elsamere Conservation Centre Naivasha', ARRAY['naivasha', 'lake-naivasha']::text[], ARRAY['naivasha']::text[], 'Lake_Naivasha.jpg'),
    ('karuru-falls', 'aberdares', 'NATURE', 3, 'HOURS', 4.7, 'Водопад Каруру', 'Karuru Falls', 'Каруру сарқырамасы', -0.41670000, 36.75000000, 'Karuru Falls Aberdare Kenya', ARRAY['aberdares', 'nyeri']::text[], ARRAY['nyeri', 'aberdares']::text[], 'Aberdare_National_Park.jpg'),
    ('mau-mau-cave', 'nyeri', 'MUSEUM', 2, 'HOURS', 4.4, 'Пещера Мау-Мау', 'Mau Mau Cave', 'Мау-Мау үңгірі', -0.42000000, 36.95000000, 'Mau Mau Cave Nyeri Kenya', ARRAY['nyeri']::text[], ARRAY['nyeri']::text[], 'Mount_Kenya.jpg'),
    ('baden-powell-museum-paxtu', 'nyeri', 'MUSEUM', 2, 'HOURS', 4.4, 'Музей Баден-Пауэлла Paxtu', 'Baden-Powell Museum Paxtu', 'Baden-Powell Paxtu музейі', -0.41670000, 36.95000000, 'Baden-Powell Museum Paxtu Nyeri Kenya', ARRAY['nyeri']::text[], ARRAY['nyeri']::text[], 'Mount_Kenya.jpg'),
    ('mombasa-marine-national-park', 'mombasa', 'PARK', 4, 'HOURS', 4.7, 'Морской парк Момбасы', 'Mombasa Marine National Park and Reserve', 'Момбаса теңіз ұлттық паркі', -4.00000000, 39.75000000, 'Mombasa Marine National Park Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Mombasa_Beach.jpg'),
    ('mama-ngina-waterfront', 'mombasa', 'PARK', 2, 'HOURS', 4.5, 'Набережная Mama Ngina', 'Mama Ngina Waterfront', 'Mama Ngina жағалауы', -4.06840000, 39.67670000, 'Mama Ngina Waterfront Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('tamarind-dhow', 'mombasa', 'FOOD', 3, 'HOURS', 4.6, 'Tamarind Dhow', 'Tamarind Dhow', 'Tamarind Dhow', -4.03880000, 39.66970000, 'Tamarind Dhow Mombasa Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('mombasa-street-food', 'mombasa', 'FOOD', 2, 'HOURS', 4.5, 'Уличная еда Момбасы', 'Mombasa Street Food', 'Момбаса көше тағамдары', -4.05800000, 39.66700000, 'Mombasa Street Food Kenya', ARRAY['mombasa']::text[], ARRAY['mombasa']::text[], 'Fort_Jesus_Mombasa.jpg'),
    ('galu-beach', 'diani', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Галу', 'Galu Beach', 'Галу жағажайы', -4.34500000, 39.56700000, 'Galu Beach Diani Kenya', ARRAY['diani']::text[], ARRAY['diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('ali-barbours-cave', 'diani', 'FOOD', 2, 'HOURS', 4.6, 'Ресторан Ali Barbour Cave', 'Ali Barbour Cave Restaurant', 'Ali Barbour Cave мейрамханасы', -4.30670000, 39.57760000, 'Ali Barbour Cave Restaurant Diani', ARRAY['diani']::text[], ARRAY['diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('forty-thieves-beach-bar', 'diani', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Forty Thieves Beach Bar', 'Forty Thieves Beach Bar', 'Forty Thieves Beach Bar', -4.29240000, 39.59210000, 'Forty Thieves Beach Bar Diani Kenya', ARRAY['diani']::text[], ARRAY['diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('marafa-depression', 'malindi', 'NATURE', 3, 'HOURS', 4.6, 'Марафа, Кухня ада', 'Marafa Depression Hell''s Kitchen', 'Марафа Hell''s Kitchen', -3.17700000, 39.95800000, 'Marafa Depression Hell''s Kitchen Malindi Kenya', ARRAY['malindi']::text[], ARRAY['malindi']::text[], 'Malindi_Beach.jpg'),
    ('mida-creek', 'watamu', 'NATURE', 3, 'HOURS', 4.7, 'Мида-Крик', 'Mida Creek', 'Мида-Крик', -3.33330000, 39.98330000, 'Mida Creek Watamu Kenya', ARRAY['watamu']::text[], ARRAY['watamu']::text[], 'Watamu_Beach.jpg'),
    ('watamu-turtle-watch', 'watamu', 'NATURE', 2, 'HOURS', 4.6, 'Watamu Turtle Watch', 'Watamu Turtle Watch', 'Watamu Turtle Watch', -3.35000000, 40.02000000, 'Watamu Turtle Watch Kenya', ARRAY['watamu']::text[], ARRAY['watamu']::text[], 'Watamu_Beach.jpg'),
    ('mnarani-ruins', 'kilifi', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Руины Мнарани', 'Mnarani Ruins', 'Мнарани қирандылары', -3.63000000, 39.85000000, 'Mnarani Ruins Kilifi Kenya', ARRAY['kilifi']::text[], ARRAY['kilifi']::text[], 'Kilifi_Creek.jpg'),
    ('kuruwitu-marine-sanctuary', 'kilifi', 'PARK', 4, 'HOURS', 4.6, 'Морское святилище Курувиту', 'Kuruwitu Marine Sanctuary', 'Курувиту теңіз қорығы', -3.79200000, 39.83500000, 'Kuruwitu Marine Sanctuary Kenya', ARRAY['kilifi']::text[], ARRAY['kilifi', 'mombasa']::text[], 'Kilifi_Creek.jpg'),
    ('bofa-beach', 'kilifi', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Бофа', 'Bofa Beach', 'Бофа жағажайы', -3.61200000, 39.86000000, 'Bofa Beach Kilifi Kenya', ARRAY['kilifi']::text[], ARRAY['kilifi']::text[], 'Kilifi_Creek.jpg'),
    ('jumba-la-mtwana', 'kilifi', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Джумба-ла-Мтвана', 'Jumba la Mtwana', 'Джумба-ла-Мтвана', -3.95000000, 39.75000000, 'Jumba la Mtwana Kenya', ARRAY['kilifi', 'mombasa']::text[], ARRAY['mombasa', 'kilifi']::text[], 'Kilifi_Creek.jpg'),
    ('wasini-coral-gardens', 'kisite-mpunguti', 'NATURE', 3, 'HOURS', 4.6, 'Коралловые сады Васини', 'Wasini Coral Gardens Boardwalk', 'Васини маржан бақтары', -4.66670000, 39.38330000, 'Wasini Coral Gardens Kenya', ARRAY['kisite-mpunguti', 'shimoni']::text[], ARRAY['shimoni', 'diani']::text[], 'Kisite_Mpunguti_Marine_Park.jpg'),
    ('shimoni-slave-caves', 'shimoni', 'MUSEUM', 2, 'HOURS', 4.5, 'Пещеры рабов Шимони', 'Shimoni Slave Caves', 'Шимони құл үңгірлері', -4.64710000, 39.38160000, 'Shimoni Slave Caves Kenya', ARRAY['shimoni']::text[], ARRAY['shimoni', 'diani']::text[], 'Diani_Beach_Kenya.jpg'),
    ('enkong-narok-swamp', 'amboseli', 'NATURE', 2, 'HOURS', 4.7, 'Болота Энконг Нарок', 'Enkong Narok Swamp', 'Энконг Нарок батпағы', -2.65000000, 37.25000000, 'Enkong Narok Swamp Amboseli Kenya', ARRAY['amboseli']::text[], ARRAY['amboseli']::text[], 'Amboseli_National_Park.jpg'),
    ('mudanda-rock', 'tsavo-east', 'NATURE', 2, 'HOURS', 4.6, 'Скала Муданде', 'Mudanda Rock', 'Муданде жартасы', -3.06670000, 38.51670000, 'Mudanda Rock Tsavo East Kenya', ARRAY['tsavo-east']::text[], ARRAY['tsavo-east']::text[], 'Tsavo_East_National_Park.jpg'),
    ('ngulia-rhino-sanctuary', 'tsavo-west', 'PARK', 3, 'HOURS', 4.7, 'Заповедник носорогов Нгулия', 'Ngulia Rhino Sanctuary', 'Нгулия мүйізтұмсық қорығы', -3.00000000, 38.20000000, 'Ngulia Rhino Sanctuary Tsavo West', ARRAY['tsavo-west']::text[], ARRAY['tsavo-west']::text[], 'Tsavo_West_National_Park.jpg'),
    ('ewaso-nyiro-riverbanks', 'samburu', 'NATURE', 3, 'HOURS', 4.7, 'Берега реки Эвасо-Нгиро', 'Ewaso Nyiro Riverbanks', 'Эвасо-Нгиро өзені жағалауы', 0.62360000, 37.53000000, 'Ewaso Nyiro River Samburu Kenya', ARRAY['samburu']::text[], ARRAY['samburu']::text[], 'Samburu_National_Reserve.jpg'),
    ('lewa-wildlife-conservancy', 'laikipia', 'PARK', 5, 'HOURS', 4.8, 'Заповедник Lewa Wildlife Conservancy', 'Lewa Wildlife Conservancy', 'Lewa Wildlife Conservancy', 0.20000000, 37.45000000, 'Lewa Wildlife Conservancy Kenya', ARRAY['laikipia', 'nanyuki']::text[], ARRAY['nanyuki', 'laikipia']::text[], 'Laikipia_Kenya.jpg'),
    ('bisanadi-national-reserve', 'meru', 'PARK', 5, 'HOURS', 4.6, 'Национальный заповедник Бисанади', 'Bisanadi National Reserve', 'Бисанади ұлттық қорығы', 0.55000000, 38.35000000, 'Bisanadi National Reserve Kenya', ARRAY['meru']::text[], ARRAY['meru']::text[], 'Meru_National_Park_Kenya.jpg'),
    ('koobi-fora', 'lake-turkana', 'MUSEUM', 3, 'HOURS', 4.7, 'Кооби-Фора', 'Koobi Fora', 'Кооби-Фора', 3.95000000, 36.20000000, 'Koobi Fora Kenya', ARRAY['lake-turkana']::text[], ARRAY['lake-turkana']::text[], 'Lake_Turkana.jpg'),
    ('desert-museum-loiyangalani', 'lake-turkana', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей пустыни Лойянгалани', 'Desert Museum Loiyangalani', 'Лойянгалани шөл музейі', 2.74700000, 36.71900000, 'Desert Museum Loiyangalani Kenya', ARRAY['lake-turkana']::text[], ARRAY['lake-turkana']::text[], 'Lake_Turkana.jpg'),
    ('kit-mikayi', 'kisumu', 'NATURE', 3, 'HOURS', 4.6, 'Кит-Микайи', 'Kit-Mikayi', 'Кит-Микайи', -0.08270000, 34.54460000, 'Kit-Mikayi Kisumu Kenya', ARRAY['kisumu']::text[], ARRAY['kisumu']::text[], 'Kisumu_Kenya.jpg'),
    ('hippo-point-kisumu', 'lake-victoria', 'BEACH', 2, 'HOURS', 4.5, 'Хиппо-Пойнт Кисуму', 'Hippo Point Kisumu', 'Кисуму Хиппо-Пойнт', -0.10390000, 34.74250000, 'Hippo Point Kisumu Kenya', ARRAY['lake-victoria', 'kisumu']::text[], ARRAY['kisumu']::text[], 'Lake_Victoria_Kenya.jpg'),
    ('thimlich-ohinga', 'lake-victoria', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Тимлич Охинга', 'Thimlich Ohinga Archaeological Site', 'Тимлич Охинга археологиялық орны', -0.96670000, 34.30000000, 'Thimlich Ohinga Kenya', ARRAY['lake-victoria']::text[], ARRAY['kisumu', 'lake-victoria']::text[], 'Lake_Victoria_Kenya.jpg');

CREATE TEMP TABLE seed_kenya_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-kenya-place:' || seed.slug) AS place_hash,
        md5('id-kenya-media:' || seed.slug) AS media_hash
    FROM seed_kenya_priority_places seed
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
    ARRAY['kenya', city_id, slug, lower(category), 'kenya-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Кении: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Kenya tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Кения туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    price_currency,
    rating,
    tags,
    created_at,
    updated_at
)
SELECT
    id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'KE',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'KES',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_kenya_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    default_locale = EXCLUDED.default_locale,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
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
FROM seed_kenya_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_kenya_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_kenya_resolved_places
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
FROM seed_kenya_resolved_places seed
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
FROM seed_kenya_resolved_places
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
    'KE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_kenya_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'KE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_kenya_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_kenya_resolved_places;
DROP TABLE IF EXISTS seed_kenya_priority_places;
