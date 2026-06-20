-- Priority Montenegro destination places seed.
-- Montenegro is seeded as a country destination with coastal, central and
-- mountain hubs for localized admin filters and mobile discovery.

DROP TABLE IF EXISTS seed_montenegro_resolved_places;
DROP TABLE IF EXISTS seed_montenegro_priority_places;

CREATE TEMP TABLE seed_montenegro_priority_places (
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

INSERT INTO seed_montenegro_priority_places (
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
    ('millennium-bridge-podgorica', 'podgorica', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Мост Миллениум', 'Millennium Bridge Podgorica', 'Подгорица Миллениум көпірі', 42.44490000, 19.25910000, 'Millennium Bridge Podgorica Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Millennium_Bridge_in_Podgorica.JPG'),
    ('old-ribnica-bridge', 'podgorica', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Старый мост Рибница', 'Old Ribnica River Bridge', 'Ескі Рибница көпірі', 42.43820000, 19.26430000, 'Old Ribnica River Bridge Podgorica Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Podgorica_Montenegro.jpg'),
    ('cathedral-resurrection-podgorica', 'podgorica', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Воскресения Христова', 'Cathedral of the Resurrection of Christ', 'Христос қайта тірілуі соборы', 42.44180000, 19.24630000, 'Cathedral of the Resurrection of Christ Podgorica Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Millennium_Bridge_in_Podgorica.JPG'),
    ('gorica-park', 'podgorica', 'PARK', 2, 'HOURS', 4.5, 'Парк Горица', 'Gorica Park', 'Горица паркі', 42.44970000, 19.26260000, 'Gorica Park Podgorica Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Gorica_Podgorica.jpg'),
    ('mall-of-montenegro', 'podgorica', 'SHOPPING', 2, 'HOURS', 4.3, 'Mall of Montenegro', 'Mall of Montenegro', 'Mall of Montenegro', 42.43570000, 19.26260000, 'Mall of Montenegro Podgorica', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Millennium_Bridge_in_Podgorica.JPG'),
    ('podgorica-green-market', 'podgorica', 'MARKET', 1, 'HOURS', 4.3, 'Зеленый рынок Подгорицы', 'Podgorica Green Market', 'Подгорица жасыл базары', 42.43490000, 19.26220000, 'Podgorica Green Market Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Millennium_Bridge_in_Podgorica.JPG'),
    ('sipcanik-wine-cellar', 'podgorica', 'FOOD', 2, 'HOURS', 4.6, 'Винный погреб Шипчаник', 'Plantaze Sipcanik Wine Cellar', 'Шипчаник шарап жертөлесі', 42.38580000, 19.21160000, 'Plantaze Sipcanik Wine Cellar Podgorica Montenegro', ARRAY['podgorica']::text[], ARRAY['podgorica']::text[], 'Millennium_Bridge_in_Podgorica.JPG'),

    ('cetinje-monastery', 'cetinje', 'TEMPLE', 1, 'HOURS', 4.8, 'Цетинский монастырь', 'Cetinje Monastery', 'Цетине монастыры', 42.38780000, 18.92170000, 'Cetinje Monastery Montenegro', ARRAY['cetinje', 'lovcen']::text[], ARRAY['cetinje', 'podgorica']::text[], 'Cetinje_monastery.jpg'),
    ('national-museum-montenegro', 'cetinje', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей Черногории', 'National Museum of Montenegro', 'Черногория ұлттық музейі', 42.39090000, 18.92350000, 'National Museum of Montenegro Cetinje', ARRAY['cetinje']::text[], ARRAY['cetinje', 'podgorica']::text[], 'Cetinje_monastery.jpg'),
    ('king-nikola-museum-cetinje', 'cetinje', 'MUSEUM', 1, 'HOURS', 4.5, 'Дворец короля Николы', 'King Nikola Museum', 'Король Никола музейі', 42.38990000, 18.92280000, 'King Nikola Museum Cetinje Montenegro', ARRAY['cetinje']::text[], ARRAY['cetinje']::text[], 'Cetinje_monastery.jpg'),
    ('lipa-cave', 'cetinje', 'NATURE', 2, 'HOURS', 4.7, 'Липская пещера', 'Lipa Cave', 'Липа үңгірі', 42.37780000, 18.97760000, 'Lipa Cave Cetinje Montenegro', ARRAY['cetinje', 'podgorica']::text[], ARRAY['cetinje', 'podgorica']::text[], 'Cetinje_monastery.jpg'),
    ('lovcen-national-park', 'lovcen', 'PARK', 4, 'HOURS', 4.9, 'Национальный парк Ловчен', 'Lovcen National Park', 'Ловчен ұлттық паркі', 42.39900000, 18.83700000, 'Lovcen National Park Montenegro', ARRAY['lovcen', 'cetinje', 'kotor']::text[], ARRAY['cetinje', 'kotor', 'podgorica']::text[], 'Lovcen.JPG'),
    ('njegos-mausoleum', 'lovcen', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Мавзолей Негоша', 'Njegos Mausoleum', 'Негош кесенесі', 42.39860000, 18.83750000, 'Njegos Mausoleum Lovcen Montenegro', ARRAY['lovcen', 'cetinje', 'kotor']::text[], ARRAY['cetinje', 'kotor']::text[], 'Mausoleum_of_Petar_II_Petrovic_Njegos.jpg'),
    ('ostrog-monastery', 'ostrog', 'TEMPLE', 3, 'HOURS', 4.9, 'Монастырь Острог', 'Ostrog Monastery', 'Острог монастыры', 42.67500000, 19.02920000, 'Ostrog Monastery Montenegro', ARRAY['ostrog', 'podgorica', 'niksic']::text[], ARRAY['podgorica', 'niksic']::text[], 'Ostrog_monastery_1.jpg'),
    ('niksic-bedem-fortress', 'niksic', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Крепость Бедем', 'Bedem Fortress', 'Бедем қамалы', 42.77580000, 18.94960000, 'Bedem Fortress Niksic Montenegro', ARRAY['niksic']::text[], ARRAY['niksic', 'podgorica']::text[], 'Niksic_Montenegro.jpg'),
    ('lake-krupac', 'niksic', 'NATURE', 2, 'HOURS', 4.5, 'Озеро Крупац', 'Lake Krupac', 'Крупац көлі', 42.77250000, 18.87930000, 'Lake Krupac Niksic Montenegro', ARRAY['niksic']::text[], ARRAY['niksic']::text[], 'Niksic_Montenegro.jpg'),

    ('lake-skadar-national-park', 'virpazar', 'PARK', 4, 'HOURS', 4.9, 'Национальный парк Скадарское озеро', 'Lake Skadar National Park', 'Скадар көлі ұлттық паркі', 42.24600000, 19.09100000, 'Lake Skadar National Park Montenegro', ARRAY['virpazar', 'podgorica', 'cetinje', 'bar']::text[], ARRAY['virpazar', 'podgorica', 'bar']::text[], 'Skadar_lake_montenegro.jpg'),
    ('virpazar-boat-tours', 'virpazar', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Лодочные прогулки из Вирпазара', 'Lake Skadar Boat Tour', 'Скадар көлі қайық туры', 42.24560000, 19.09120000, 'Virpazar boat tour Lake Skadar Montenegro', ARRAY['virpazar']::text[], ARRAY['virpazar', 'podgorica', 'bar']::text[], 'View_on_Skadar_Lake.jpg'),
    ('pavlova-strana-viewpoint', 'virpazar', 'NATURE', 1, 'HOURS', 4.8, 'Видовая точка Павлова Страна', 'Pavlova Strana Viewpoint', 'Павлова Страна көрініс алаңы', 42.36140000, 19.06060000, 'Pavlova Strana Viewpoint Montenegro', ARRAY['virpazar', 'cetinje']::text[], ARRAY['cetinje', 'virpazar']::text[], 'Skadar_Lake,_Montenegro_39.jpg'),
    ('virpazar-market', 'virpazar', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Вирпазара', 'Virpazar Market', 'Вирпазар базары', 42.24620000, 19.09130000, 'Virpazar Market Montenegro', ARRAY['virpazar']::text[], ARRAY['virpazar']::text[], 'Skadar_lake_montenegro.jpg'),

    ('kotor-old-town', 'kotor', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Старый город Котора', 'Kotor Old Town', 'Котор ескі қаласы', 42.42470000, 18.77120000, 'Kotor Old Town Montenegro', ARRAY['kotor', 'perast', 'tivat']::text[], ARRAY['kotor', 'tivat']::text[], 'Kotor_Old_Town.JPG'),
    ('bay-of-kotor', 'kotor', 'NATURE', 4, 'HOURS', 4.9, 'Бока-Которская бухта', 'Bay of Kotor', 'Котор шығанағы', 42.44900000, 18.69000000, 'Bay of Kotor Montenegro', ARRAY['kotor', 'perast', 'tivat', 'herceg-novi']::text[], ARRAY['kotor', 'tivat', 'herceg-novi']::text[], 'Perast,_Bay_of_Kotor,_Montenegro_(38105080686).jpg'),
    ('kotor-fortress', 'kotor', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Крепость Сан-Джованни', 'Kotor Fortress', 'Котор қамалы', 42.42740000, 18.77470000, 'Kotor Fortress Montenegro', ARRAY['kotor']::text[], ARRAY['kotor']::text[], 'Kotor_city_walls.jpg'),
    ('st-tryphon-cathedral', 'kotor', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святого Трифона', 'St Tryphon Cathedral', 'Әулие Трифон соборы', 42.42460000, 18.77060000, 'St Tryphon Cathedral Kotor Montenegro', ARRAY['kotor']::text[], ARRAY['kotor']::text[], 'Cathedral_of_Saint_Tryphon,_Kotor,_Montenegro,_2012.jpg'),
    ('maritime-museum-kotor', 'kotor', 'MUSEUM', 1, 'HOURS', 4.6, 'Морской музей Котора', 'Maritime Museum Kotor', 'Котор теңіз музейі', 42.42520000, 18.77100000, 'Maritime Museum Kotor Montenegro', ARRAY['kotor']::text[], ARRAY['kotor']::text[], 'Kotor_Old_Town.JPG'),
    ('kotor-cable-car', 'kotor', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Канатная дорога Котор-Ловчен', 'Kotor Cable Car', 'Котор-Ловчен аспалы жолы', 42.40250000, 18.76520000, 'Kotor Lovcen Cable Car Montenegro', ARRAY['kotor', 'lovcen', 'tivat']::text[], ARRAY['kotor', 'tivat']::text[], 'Kotor_Old_Town.JPG'),
    ('kotor-farmers-market', 'kotor', 'MARKET', 1, 'HOURS', 4.5, 'Городской рынок Котора', 'Kotor Farmers Market', 'Котор қалалық базары', 42.42420000, 18.77010000, 'Kotor Farmers Market Montenegro', ARRAY['kotor']::text[], ARRAY['kotor']::text[], 'Kotor_Old_Town.JPG'),
    ('perast-old-town', 'perast', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый город Пераста', 'Perast Old Town', 'Пераст ескі қаласы', 42.48630000, 18.69920000, 'Perast Old Town Montenegro', ARRAY['perast', 'kotor', 'risan']::text[], ARRAY['kotor']::text[], 'Perast,_Bay_of_Kotor,_Montenegro_(38105080686).jpg'),
    ('our-lady-of-the-rocks', 'perast', 'TEMPLE', 2, 'HOURS', 4.8, 'Госпа од Шкрпьела', 'Our Lady of the Rocks', 'Жартастағы Құдай Ана аралы', 42.48670000, 18.68890000, 'Our Lady of the Rocks Perast Montenegro', ARRAY['perast', 'kotor']::text[], ARRAY['perast', 'kotor']::text[], 'Church_of_Our_Lady_of_the_Rocks,_Perast.jpg'),
    ('risan-roman-mosaics', 'risan', 'MUSEUM', 1, 'HOURS', 4.5, 'Римские мозаики Рисана', 'Roman Mosaics Risan', 'Рисан рим мозаикалары', 42.51430000, 18.69650000, 'Roman Mosaics Risan Montenegro', ARRAY['risan', 'perast', 'kotor']::text[], ARRAY['kotor']::text[], 'Risan-Montenegro.RomanMosaics.jpg'),
    ('porto-montenegro', 'tivat', 'SHOPPING', 3, 'HOURS', 4.7, 'Порто Монтенегро', 'Porto Montenegro', 'Порто Монтенегро', 42.43390000, 18.69480000, 'Porto Montenegro Tivat', ARRAY['tivat', 'kotor']::text[], ARRAY['tivat', 'kotor']::text[], 'Porto_Montenegro.jpg'),
    ('naval-heritage-collection', 'tivat', 'MUSEUM', 1, 'HOURS', 4.5, 'Коллекция морского наследия', 'Naval Heritage Collection', 'Теңіз мұрасы коллекциясы', 42.43350000, 18.69380000, 'Naval Heritage Collection Tivat Montenegro', ARRAY['tivat']::text[], ARRAY['tivat']::text[], 'Porto_Montenegro.jpg'),
    ('plavi-horizonti-beach', 'tivat', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Плави Хоризонти', 'Plavi Horizonti Beach', 'Плави Хоризонти жағажайы', 42.39750000, 18.65630000, 'Plavi Horizonti Beach Montenegro', ARRAY['tivat']::text[], ARRAY['tivat']::text[], 'Radovici_-_Plavi_horizonti.jpg'),
    ('herceg-novi-old-town', 'herceg-novi', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый город Херцег-Нови', 'Herceg Novi Old Town', 'Херцег-Нови ескі қаласы', 42.45290000, 18.53690000, 'Herceg Novi Old Town Montenegro', ARRAY['herceg-novi']::text[], ARRAY['herceg-novi', 'tivat']::text[], '2024-02-04_Forte_Mare,_Herceg_Novi.jpg'),
    ('forte-mare', 'herceg-novi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Крепость Форте-Маре', 'Forte Mare', 'Форте-Маре қамалы', 42.45210000, 18.53750000, 'Forte Mare Herceg Novi Montenegro', ARRAY['herceg-novi']::text[], ARRAY['herceg-novi']::text[], '2024-02-04_Forte_Mare,_Herceg_Novi.jpg'),
    ('kanli-kula', 'herceg-novi', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канли Кула', 'Kanli Kula', 'Канли Кула', 42.45390000, 18.53740000, 'Kanli Kula Herceg Novi Montenegro', ARRAY['herceg-novi']::text[], ARRAY['herceg-novi']::text[], 'Twierdza_Kanli_Kula_w_Herceg_Novi.jpg'),
    ('savina-monastery', 'herceg-novi', 'TEMPLE', 1, 'HOURS', 4.6, 'Монастырь Савина', 'Savina Monastery', 'Савина монастыры', 42.45110000, 18.56080000, 'Savina Monastery Herceg Novi Montenegro', ARRAY['herceg-novi']::text[], ARRAY['herceg-novi']::text[], 'Herceg_Novi,_Montenegro_-_Savina_monastery.jpg'),
    ('blue-cave-montenegro', 'herceg-novi', 'NATURE', 3, 'HOURS', 4.7, 'Голубая пещера', 'Blue Cave Montenegro', 'Көк үңгір', 42.39580000, 18.57530000, 'Blue Cave Lustica Montenegro', ARRAY['herceg-novi', 'tivat']::text[], ARRAY['herceg-novi', 'tivat']::text[], 'Porto_Montenegro.jpg'),
    ('herceg-novi-city-market', 'herceg-novi', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Херцег-Нови', 'Herceg Novi City Market', 'Херцег-Нови базары', 42.45310000, 18.53700000, 'Herceg Novi City Market Montenegro', ARRAY['herceg-novi']::text[], ARRAY['herceg-novi']::text[], '2024-02-04_Forte_Mare,_Herceg_Novi.jpg'),

    ('budva-old-town', 'budva', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Будвы', 'Budva Old Town', 'Будва ескі қаласы', 42.27820000, 18.83750000, 'Budva Old Town Montenegro', ARRAY['budva', 'becici', 'sveti-stefan']::text[], ARRAY['budva', 'tivat']::text[], 'Old_Town_Budva,_Montenegro.jpg'),
    ('budva-citadel', 'budva', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Цитадель Будвы', 'Citadel Budva', 'Будва цитаделі', 42.27800000, 18.83820000, 'Budva Citadel Montenegro', ARRAY['budva']::text[], ARRAY['budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('mogren-beach', 'budva', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Могрен', 'Mogren Beach', 'Могрен жағажайы', 42.27610000, 18.83280000, 'Mogren Beach Budva Montenegro', ARRAY['budva']::text[], ARRAY['budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('jaz-beach', 'budva', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Яз', 'Jaz Beach', 'Яз жағажайы', 42.28340000, 18.79340000, 'Jaz Beach Budva Montenegro', ARRAY['budva', 'kotor']::text[], ARRAY['budva', 'kotor']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('tq-plaza', 'budva', 'SHOPPING', 2, 'HOURS', 4.3, 'TQ Plaza', 'TQ Plaza', 'TQ Plaza', 42.28630000, 18.83790000, 'TQ Plaza Budva Montenegro', ARRAY['budva']::text[], ARRAY['budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('budva-market', 'budva', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Будвы', 'Budva Market', 'Будва базары', 42.28570000, 18.83800000, 'Budva Market Montenegro', ARRAY['budva']::text[], ARRAY['budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('aquapark-budva', 'budva', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Аквапарк Будвы', 'Aquapark Budva', 'Будва аквапаркі', 42.29510000, 18.82440000, 'Aquapark Budva Montenegro', ARRAY['budva', 'becici']::text[], ARRAY['budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('becici-beach', 'becici', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Бечичи', 'Becici Beach', 'Бечичи жағажайы', 42.28380000, 18.86970000, 'Becici Beach Montenegro', ARRAY['becici', 'budva']::text[], ARRAY['becici', 'budva']::text[], 'Budva_Old_Town,_Montenegro.jpg'),
    ('sveti-stefan', 'sveti-stefan', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Свети-Стефан', 'Sveti Stefan', 'Свети-Стефан', 42.25530000, 18.89670000, 'Sveti Stefan Montenegro', ARRAY['sveti-stefan', 'budva', 'petrovac']::text[], ARRAY['budva']::text[], 'Sveti_stefan_montenegro.JPG'),
    ('milocer-park', 'sveti-stefan', 'PARK', 2, 'HOURS', 4.6, 'Милочерский парк', 'Milocer Park', 'Милочер паркі', 42.25950000, 18.89410000, 'Milocer Park Montenegro', ARRAY['sveti-stefan', 'budva']::text[], ARRAY['budva']::text[], 'Sveti_stefan_montenegro.JPG'),
    ('petrovac-beach', 'petrovac', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Петровац', 'Petrovac Beach', 'Петровац жағажайы', 42.20500000, 18.94260000, 'Petrovac Beach Montenegro', ARRAY['petrovac', 'sveti-stefan']::text[], ARRAY['petrovac', 'budva']::text[], 'Sveti_stefan_montenegro.JPG'),
    ('old-bar', 'bar', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый Бар', 'Old Bar', 'Ескі Бар', 42.09750000, 19.13690000, 'Old Bar Montenegro', ARRAY['bar']::text[], ARRAY['bar', 'podgorica']::text[], 'Stari_Bar_(2012).jpg'),
    ('stara-maslina', 'bar', 'NATURE', 1, 'HOURS', 4.6, 'Старая олива Мировица', 'Stara Maslina', 'Стара Маслина', 42.08190000, 19.13070000, 'Stara Maslina Bar Montenegro', ARRAY['bar']::text[], ARRAY['bar']::text[], 'Stari_Bar_(2012).jpg'),
    ('king-nikola-palace-bar', 'bar', 'MUSEUM', 1, 'HOURS', 4.5, 'Дворец короля Николы в Баре', 'King Nikola Palace', 'Бардағы Король Никола сарайы', 42.09960000, 19.09500000, 'King Nikola Palace Bar Montenegro', ARRAY['bar']::text[], ARRAY['bar']::text[], 'Stari_Bar_(2012).jpg'),
    ('bar-green-market', 'bar', 'MARKET', 1, 'HOURS', 4.3, 'Зеленый рынок Бара', 'Bar Green Market', 'Бар жасыл базары', 42.09940000, 19.09800000, 'Bar Green Market Montenegro', ARRAY['bar']::text[], ARRAY['bar']::text[], 'Stari_Bar_(2012).jpg'),
    ('ulcinj-old-town', 'ulcinj', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый город Улциня', 'Ulcinj Old Town', 'Ульцинь ескі қаласы', 41.92390000, 19.20170000, 'Ulcinj Old Town Montenegro', ARRAY['ulcinj']::text[], ARRAY['ulcinj', 'bar']::text[], 'Ulcinj_old_town.jpg'),
    ('velika-plaza', 'ulcinj', 'BEACH', 4, 'HOURS', 4.8, 'Велика Плажа', 'Velika Plaza', 'Велика Плажа жағажайы', 41.89250000, 19.30000000, 'Velika Plaza Ulcinj Montenegro', ARRAY['ulcinj', 'ada-bojana']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),
    ('ulcinj-salina', 'ulcinj', 'NATURE', 3, 'HOURS', 4.6, 'Ульциньская солана', 'Ulcinj Salina', 'Ульцинь тұзды көлі', 41.92430000, 19.29490000, 'Ulcinj Salina Montenegro', ARRAY['ulcinj']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),
    ('ulcinj-bazaar', 'ulcinj', 'MARKET', 1, 'HOURS', 4.4, 'Базар Улциня', 'Ulcinj Bazaar', 'Ульцинь базары', 41.92900000, 19.22400000, 'Ulcinj Bazaar Montenegro', ARRAY['ulcinj']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),
    ('ada-bojana', 'ada-bojana', 'BEACH', 4, 'HOURS', 4.7, 'Ада-Бояна', 'Ada Bojana', 'Ада-Бояна', 41.86200000, 19.36100000, 'Ada Bojana Montenegro', ARRAY['ada-bojana', 'ulcinj']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),
    ('bojana-kitesurfing', 'ada-bojana', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Кайтсерфинг на Бояне', 'Bojana River Kite Surfing', 'Бояна кайтсерфингі', 41.86300000, 19.35900000, 'Ada Bojana kitesurfing Montenegro', ARRAY['ada-bojana', 'ulcinj']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),
    ('ada-bojana-seafood', 'ada-bojana', 'FOOD', 2, 'HOURS', 4.5, 'Рыбные рестораны Ада-Бояны', 'Ada Bojana Seafood', 'Ада-Бояна теңіз тағамдары', 41.87000000, 19.34000000, 'Ada Bojana seafood restaurants Montenegro', ARRAY['ada-bojana', 'ulcinj']::text[], ARRAY['ulcinj']::text[], 'Ulcinj_old_town.jpg'),

    ('durmitor-national-park', 'durmitor', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Дурмитор', 'Durmitor National Park', 'Дурмитор ұлттық паркі', 43.12800000, 19.01700000, 'Durmitor National Park Montenegro', ARRAY['durmitor', 'zabljak']::text[], ARRAY['zabljak']::text[], 'Durmitor_-_Crno_jezero.jpg'),
    ('black-lake', 'zabljak', 'NATURE', 3, 'HOURS', 4.9, 'Черное озеро', 'Black Lake', 'Қара көл', 43.14620000, 19.09370000, 'Black Lake Durmitor Montenegro', ARRAY['zabljak', 'durmitor']::text[], ARRAY['zabljak']::text[], 'Montenegro_NP_Durmitor_Black_Lake_02.jpg'),
    ('tara-canyon', 'durmitor', 'NATURE', 4, 'HOURS', 4.9, 'Каньон Тары', 'Tara Canyon', 'Тара каньоны', 43.20680000, 19.08250000, 'Tara Canyon Montenegro', ARRAY['durmitor', 'zabljak']::text[], ARRAY['zabljak']::text[], 'Montenegro_Tara_bridge.JPG'),
    ('tara-bridge', 'zabljak', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Мост Джурджевича-Тара', 'Tara Bridge', 'Тара көпірі', 43.15050000, 19.29500000, 'Durdevica Tara Bridge Montenegro', ARRAY['zabljak', 'durmitor']::text[], ARRAY['zabljak']::text[], 'Montenegro_Tara_bridge.JPG'),
    ('savin-kuk-ski-centre', 'zabljak', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Savin Kuk Ski Centre', 'Savin Kuk Ski Centre', 'Savin Kuk Ski Centre', 43.11810000, 19.08670000, 'Savin Kuk Ski Centre Montenegro', ARRAY['zabljak', 'durmitor']::text[], ARRAY['zabljak']::text[], 'Durmitor_-_Crno_jezero.jpg'),
    ('zabljak-mountain-market', 'zabljak', 'MARKET', 1, 'HOURS', 4.3, 'Горный рынок Жабляка', 'Zabljak Mountain Market', 'Жабляк тау базары', 43.15460000, 19.12270000, 'Zabljak market Montenegro', ARRAY['zabljak']::text[], ARRAY['zabljak']::text[], 'Durmitor_-_Crno_jezero.jpg'),
    ('biogradska-gora-national-park', 'biogradska-gora', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Биоградская гора', 'Biogradska Gora National Park', 'Биоградская гора ұлттық паркі', 42.90000000, 19.59000000, 'Biogradska Gora National Park Montenegro', ARRAY['biogradska-gora', 'kolasin']::text[], ARRAY['kolasin']::text[], 'Biogradska_gora.jpg'),
    ('biogradsko-lake', 'biogradska-gora', 'NATURE', 2, 'HOURS', 4.8, 'Биоградское озеро', 'Biogradsko Lake', 'Биоград көлі', 42.89900000, 19.59900000, 'Biogradsko Lake Montenegro', ARRAY['biogradska-gora', 'kolasin']::text[], ARRAY['kolasin']::text[], 'Biogradska_gora.jpg'),
    ('kolasin-1450-ski-resort', 'kolasin', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Горнолыжный центр Колашин 1450', 'Kolasin 1450 Ski Resort', 'Колашин 1450 шаңғы орталығы', 42.82370000, 19.65820000, 'Kolasin 1450 Ski Resort Montenegro', ARRAY['kolasin']::text[], ARRAY['kolasin', 'podgorica']::text[], 'Biogradska_gora.jpg'),
    ('kolasin-1600-ski-centre', 'kolasin', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Ski Center Kolasin 1600', 'Kolasin 1600 Ski Centre', 'Колашин 1600 шаңғы орталығы', 42.84200000, 19.66600000, 'Kolasin 1600 Ski Centre Montenegro', ARRAY['kolasin']::text[], ARRAY['kolasin', 'podgorica']::text[], 'Biogradska_gora.jpg'),
    ('moraca-monastery', 'kolasin', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Морача', 'Moraca Monastery', 'Морача монастыры', 42.76520000, 19.39050000, 'Moraca Monastery Montenegro', ARRAY['kolasin', 'podgorica']::text[], ARRAY['kolasin', 'podgorica']::text[], 'Biogradska_gora.jpg'),
    ('prokletije-national-park', 'gusinje', 'PARK', 5, 'HOURS', 4.9, 'Национальный парк Проклетие', 'Prokletije National Park', 'Проклетие ұлттық паркі', 42.56100000, 19.83300000, 'Prokletije National Park Montenegro', ARRAY['gusinje', 'plav']::text[], ARRAY['gusinje', 'plav']::text[], 'Prokletije_Mountains.jpg'),
    ('lake-plav', 'plav', 'NATURE', 2, 'HOURS', 4.6, 'Плавское озеро', 'Lake Plav', 'Плав көлі', 42.59600000, 19.94500000, 'Lake Plav Montenegro', ARRAY['plav', 'gusinje']::text[], ARRAY['plav', 'gusinje']::text[], 'Prokletije_Mountains.jpg'),
    ('ali-pasha-springs', 'gusinje', 'NATURE', 2, 'HOURS', 4.7, 'Источники Али-паши', 'Ali Pasha Springs', 'Али-паша бұлақтары', 42.55850000, 19.83700000, 'Ali Pasha Springs Gusinje Montenegro', ARRAY['gusinje', 'plav']::text[], ARRAY['gusinje', 'plav']::text[], 'Prokletije_Mountains.jpg'),
    ('redzepagic-tower', 'plav', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Башня Реджепагича', 'Redzepagic Tower', 'Реджепагич мұнарасы', 42.59680000, 19.94430000, 'Redzepagic Tower Plav Montenegro', ARRAY['plav']::text[], ARRAY['plav']::text[], 'Prokletije_Mountains.jpg'),
    ('grlja-waterfall', 'gusinje', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Грля', 'Grlja Waterfall', 'Грля сарқырамасы', 42.53590000, 19.80030000, 'Grlja Waterfall Gusinje Montenegro', ARRAY['gusinje', 'plav']::text[], ARRAY['gusinje']::text[], 'Prokletije_Mountains.jpg');

CREATE TEMP TABLE seed_montenegro_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-montenegro-place:' || seed.slug) AS place_hash,
        md5('id-montenegro-media:' || seed.slug) AS media_hash
    FROM seed_montenegro_priority_places seed
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
    ARRAY['montenegro', city_id, slug, lower(category), 'montenegro-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Черногории: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Montenegro tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Черногория туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'ME',
    city_id,
    category,
    NULL::numeric,
    'EUR',
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
FROM seed_montenegro_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_currency = EXCLUDED.price_currency,
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
FROM seed_montenegro_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_montenegro_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_montenegro_resolved_places
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
FROM seed_montenegro_resolved_places seed
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
FROM seed_montenegro_resolved_places
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
    'ME',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_montenegro_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'ME',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_montenegro_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_montenegro_resolved_places;
DROP TABLE IF EXISTS seed_montenegro_priority_places;
