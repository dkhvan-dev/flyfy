-- Priority Spain destination places seed.
-- The seed covers Madrid and central day trips, Catalonia, Valencia and the Balearics, Andalusia, the Canary Islands, and northern Spain.

DROP TABLE IF EXISTS seed_spain_resolved_places;
DROP TABLE IF EXISTS seed_spain_priority_places;

CREATE TEMP TABLE seed_spain_priority_places (
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

INSERT INTO seed_spain_priority_places (
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
    ('prado-museum', 'madrid', 'MUSEUM', 3, 'HOURS', 4.9, 'Музей Прадо', 'Prado Museum', 'Прадо музейі', 40.41380000, -3.69210000, 'Prado Museum Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('royal-palace-madrid', 'madrid', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Королевский дворец Мадрида', 'Royal Palace of Madrid', 'Мадрид король сарайы', 40.41790000, -3.71430000, 'Royal Palace of Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('reina-sofia-museum', 'madrid', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей королевы Софии', 'Reina Sofia Museum', 'Рейна София музейі', 40.40810000, -3.69420000, 'Reina Sofia Museum Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('thyssen-bornemisza-museum', 'madrid', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Тиссена-Борнемисы', 'Thyssen-Bornemisza Museum', 'Тиссен-Борнемиса музейі', 40.41600000, -3.69470000, 'Thyssen Bornemisza Museum Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('retiro-park', 'madrid', 'PARK', 2, 'HOURS', 4.8, 'Парк Эль-Ретиро', 'Retiro Park', 'Ретиро паркі', 40.41530000, -3.68440000, 'Retiro Park Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('temple-of-debod', 'madrid', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Дебод', 'Temple of Debod', 'Дебод ғибадатханасы', 40.42400000, -3.71780000, 'Temple of Debod Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('plaza-mayor-madrid', 'madrid', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Пласа-Майор', 'Plaza Mayor Madrid', 'Пласа-Майор', 40.41550000, -3.70740000, 'Plaza Mayor Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('gran-via-madrid', 'madrid', 'SHOPPING', 2, 'HOURS', 4.7, 'Гран-Виа', 'Gran Via', 'Гран-Виа', 40.42030000, -3.70580000, 'Gran Via Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('mercado-san-miguel', 'madrid', 'FOOD', 2, 'HOURS', 4.6, 'Рынок Сан-Мигель', 'Mercado de San Miguel', 'Сан-Мигель базары', 40.41540000, -3.70890000, 'Mercado de San Miguel Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('el-rastro-market', 'madrid', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Эль-Растро', 'El Rastro Market', 'Эль-Растро базары', 40.40780000, -3.70700000, 'El Rastro Market Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('santiago-bernabeu-stadium', 'madrid', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Стадион Сантьяго Бернабеу', 'Santiago Bernabeu Stadium', 'Сантьяго Бернабеу стадионы', 40.45310000, -3.68830000, 'Santiago Bernabeu Stadium Madrid', ARRAY['madrid']::text[], ARRAY['madrid']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('toledo-cathedral', 'toledo', 'TEMPLE', 2, 'HOURS', 4.8, 'Толедский собор', 'Toledo Cathedral', 'Толедо соборы', 39.85700000, -4.02360000, 'Toledo Cathedral Spain', ARRAY['toledo', 'madrid']::text[], ARRAY['madrid', 'toledo']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('alcazar-of-toledo', 'toledo', 'MUSEUM', 2, 'HOURS', 4.7, 'Алькасар Толедо', 'Alcazar of Toledo', 'Толедо Алькасары', 39.85880000, -4.02030000, 'Alcazar of Toledo', ARRAY['toledo', 'madrid']::text[], ARRAY['madrid', 'toledo']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('el-greco-museum', 'toledo', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Эль Греко', 'El Greco Museum', 'Эль Греко музейі', 39.85580000, -4.02960000, 'El Greco Museum Toledo', ARRAY['toledo']::text[], ARRAY['madrid', 'toledo']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('aqueduct-of-segovia', 'segovia', 'ARCHITECTURE', 1, 'HOURS', 4.9, 'Акведук Сеговии', 'Aqueduct of Segovia', 'Сеговия акведугі', 40.94800000, -4.11790000, 'Aqueduct of Segovia', ARRAY['segovia', 'madrid']::text[], ARRAY['madrid', 'segovia']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('alcazar-of-segovia', 'segovia', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Алькасар Сеговии', 'Alcazar of Segovia', 'Сеговия Алькасары', 40.95250000, -4.13260000, 'Alcazar of Segovia', ARRAY['segovia', 'madrid']::text[], ARRAY['madrid', 'segovia']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('royal-monastery-el-escorial', 'el-escorial', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Королевский монастырь Эль-Эскориал', 'Royal Monastery of El Escorial', 'Эль-Эскориал монастыры', 40.58900000, -4.14780000, 'Royal Monastery of El Escorial', ARRAY['el-escorial', 'madrid']::text[], ARRAY['madrid', 'el-escorial']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('royal-palace-aranjuez', 'aranjuez', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Королевский дворец Аранхуэса', 'Royal Palace of Aranjuez', 'Аранхуэс король сарайы', 40.03600000, -3.60910000, 'Royal Palace of Aranjuez', ARRAY['aranjuez', 'madrid']::text[], ARRAY['madrid', 'aranjuez']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),
    ('sierra-guadarrama-national-park', 'sierra-guadarrama', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Сьерра-де-Гвадаррама', 'Sierra de Guadarrama National Park', 'Сьерра-де-Гвадаррама ұлттық паркі', 40.85000000, -3.95000000, 'Sierra de Guadarrama National Park', ARRAY['sierra-guadarrama', 'madrid', 'segovia']::text[], ARRAY['madrid', 'segovia']::text[], 'Museo_del_Prado_2016_(25185969599).jpg'),

    ('sagrada-familia', 'barcelona', 'TEMPLE', 2, 'HOURS', 4.9, 'Саграда Фамилия', 'Sagrada Familia', 'Саграда Фамилия', 41.40360000, 2.17440000, 'Sagrada Familia Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('park-guell', 'barcelona', 'PARK', 2, 'HOURS', 4.8, 'Парк Гуэль', 'Park Guell', 'Гуэль паркі', 41.41450000, 2.15270000, 'Park Guell Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('casa-batllo', 'barcelona', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Дом Бальо', 'Casa Batllo', 'Бальо үйі', 41.39170000, 2.16490000, 'Casa Batllo Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('casa-mila', 'barcelona', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Дом Мила', 'Casa Mila La Pedrera', 'Мила үйі', 41.39540000, 2.16190000, 'Casa Mila La Pedrera Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('palau-musica-catalana', 'barcelona', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Дворец каталонской музыки', 'Palau de la Musica Catalana', 'Каталон музыка сарайы', 41.38750000, 2.17530000, 'Palau de la Musica Catalana Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('picasso-museum-barcelona', 'barcelona', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Пикассо в Барселоне', 'Picasso Museum Barcelona', 'Барселона Пикассо музейі', 41.38520000, 2.18090000, 'Picasso Museum Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('la-boqueria-market', 'barcelona', 'MARKET', 2, 'HOURS', 4.7, 'Рынок Бокерия', 'La Boqueria Market', 'Бокерия базары', 41.38180000, 2.17190000, 'La Boqueria Market Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('sant-antoni-market', 'barcelona', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Сант-Антони', 'Mercat de Sant Antoni', 'Сант-Антони базары', 41.37860000, 2.16280000, 'Mercat de Sant Antoni Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('maremagnum-barcelona', 'barcelona', 'SHOPPING', 2, 'HOURS', 4.5, 'Торговый центр Maremagnum', 'Maremagnum', 'Maremagnum сауда орталығы', 41.37480000, 2.18280000, 'Maremagnum Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('barceloneta-beach', 'barcelona', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Барселонета', 'Barceloneta Beach', 'Барселонета жағажайы', 41.37840000, 2.19260000, 'Barceloneta Beach Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('tibidabo-amusement-park', 'barcelona', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Парк аттракционов Тибидабо', 'Tibidabo Amusement Park', 'Тибидабо ойын-сауық паркі', 41.42100000, 2.11910000, 'Tibidabo Amusement Park Barcelona', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('el-nacional-barcelona', 'barcelona', 'FOOD', 2, 'HOURS', 4.5, 'El Nacional Barcelona', 'El Nacional Barcelona', 'El Nacional Barcelona', 41.39030000, 2.16880000, 'El Nacional Barcelona food hall', ARRAY['barcelona']::text[], ARRAY['barcelona']::text[], 'Sagrada_Familia_01.jpg'),
    ('girona-cathedral', 'girona', 'TEMPLE', 2, 'HOURS', 4.7, 'Кафедральный собор Жироны', 'Girona Cathedral', 'Жирона соборы', 41.98730000, 2.82530000, 'Girona Cathedral', ARRAY['girona', 'barcelona']::text[], ARRAY['barcelona', 'girona']::text[], 'Sagrada_Familia_01.jpg'),
    ('dali-theatre-museum', 'figueres', 'MUSEUM', 2, 'HOURS', 4.7, 'Театр-музей Дали', 'Dali Theatre-Museum', 'Дали театр-музейі', 42.26770000, 2.95970000, 'Dali Theatre Museum Figueres', ARRAY['figueres', 'girona']::text[], ARRAY['barcelona', 'girona']::text[], 'Sagrada_Familia_01.jpg'),
    ('montserrat-abbey', 'montserrat', 'TEMPLE', 3, 'HOURS', 4.8, 'Аббатство Монсеррат', 'Santa Maria de Montserrat Abbey', 'Монсеррат аббаттығы', 41.59310000, 1.83790000, 'Santa Maria de Montserrat Abbey', ARRAY['montserrat', 'barcelona']::text[], ARRAY['barcelona', 'montserrat']::text[], 'Sagrada_Familia_01.jpg'),
    ('montserrat-natural-park', 'montserrat', 'NATURE', 5, 'HOURS', 4.8, 'Природный парк Монсеррат', 'Montserrat Natural Park', 'Монсеррат табиғи паркі', 41.59500000, 1.82900000, 'Montserrat Natural Park', ARRAY['montserrat', 'barcelona']::text[], ARRAY['barcelona', 'montserrat']::text[], 'Sagrada_Familia_01.jpg'),
    ('tossa-de-mar-vila-vella', 'costa-brava', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый город Тосса-де-Мар', 'Vila Vella Tossa de Mar', 'Тосса-де-Мар ескі қаласы', 41.71890000, 2.93330000, 'Vila Vella Tossa de Mar', ARRAY['costa-brava', 'girona']::text[], ARRAY['barcelona', 'girona', 'costa-brava']::text[], 'Sagrada_Familia_01.jpg'),
    ('cadaques-seafront', 'costa-brava', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый город и набережная Кадакеса', 'Cadaques Old Town and Seafront', 'Кадакес ескі қаласы', 42.28870000, 3.27780000, 'Cadaques Old Town Seafront', ARRAY['costa-brava', 'girona']::text[], ARRAY['barcelona', 'girona', 'costa-brava']::text[], 'Sagrada_Familia_01.jpg'),
    ('cap-de-creus', 'costa-brava', 'NATURE', 4, 'HOURS', 4.8, 'Природный парк Кап-де-Креус', 'Cap de Creus Natural Park', 'Кап-де-Креус табиғи паркі', 42.31920000, 3.31580000, 'Cap de Creus Natural Park', ARRAY['costa-brava', 'girona']::text[], ARRAY['barcelona', 'girona', 'costa-brava']::text[], 'Sagrada_Familia_01.jpg'),
    ('aiguablava-beach', 'costa-brava', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Айгуаблава', 'Aiguablava Beach', 'Айгуаблава жағажайы', 41.93420000, 3.21680000, 'Aiguablava Beach Begur', ARRAY['costa-brava', 'girona']::text[], ARRAY['barcelona', 'girona', 'costa-brava']::text[], 'Sagrada_Familia_01.jpg'),
    ('portaventura-world', 'salou', 'ENTERTAINMENT', 7, 'HOURS', 4.7, 'PortAventura World', 'PortAventura World', 'PortAventura World', 41.08740000, 1.15790000, 'PortAventura World Salou', ARRAY['salou', 'barcelona']::text[], ARRAY['barcelona', 'salou']::text[], 'Sagrada_Familia_01.jpg'),
    ('ferrari-land', 'salou', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Ferrari Land', 'Ferrari Land', 'Ferrari Land', 41.08780000, 1.15710000, 'Ferrari Land PortAventura', ARRAY['salou', 'barcelona']::text[], ARRAY['barcelona', 'salou']::text[], 'Sagrada_Familia_01.jpg'),

    ('city-arts-sciences-valencia', 'valencia', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Город искусств и наук', 'City of Arts and Sciences', 'Өнер және ғылым қаласы', 39.45490000, -0.35050000, 'City of Arts and Sciences Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('oceanografic-valencia', 'valencia', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Океанографик Валенсии', 'Oceanografic Valencia', 'Валенсия Океанографигі', 39.45260000, -0.34800000, 'Oceanografic Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('lonja-de-la-seda', 'valencia', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Шелковая биржа Ла-Лонха-де-ла-Седа', 'La Lonja de la Seda', 'Ла Лонха-де-ла-Седа', 39.47430000, -0.37830000, 'La Lonja de la Seda Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('central-market-valencia', 'valencia', 'MARKET', 2, 'HOURS', 4.7, 'Центральный рынок Валенсии', 'Central Market of Valencia', 'Валенсия орталық базары', 39.47400000, -0.37880000, 'Central Market of Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('turia-gardens', 'valencia', 'PARK', 2, 'HOURS', 4.7, 'Сады Турии', 'Turia Gardens', 'Турия бақтары', 39.46990000, -0.36460000, 'Turia Gardens Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('albufera-natural-park', 'valencia', 'NATURE', 4, 'HOURS', 4.7, 'Природный парк Альбуфера', 'Albufera Natural Park', 'Альбуфера табиғи паркі', 39.32100000, -0.35000000, 'Albufera Natural Park Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('malvarrosa-beach', 'valencia', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Мальварроса', 'Malvarrosa Beach', 'Мальварроса жағажайы', 39.47500000, -0.32360000, 'Malvarrosa Beach Valencia', ARRAY['valencia']::text[], ARRAY['valencia']::text[], 'Sagrada_Familia_01.jpg'),
    ('santa-barbara-castle', 'alicante', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Санта-Барбара', 'Santa Barbara Castle', 'Санта-Барбара қамалы', 38.34870000, -0.47860000, 'Santa Barbara Castle Alicante', ARRAY['alicante']::text[], ARRAY['alicante']::text[], 'Sagrada_Familia_01.jpg'),
    ('postiguet-beach', 'alicante', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Постигет', 'Postiguet Beach', 'Постигет жағажайы', 38.34690000, -0.47720000, 'Postiguet Beach Alicante', ARRAY['alicante']::text[], ARRAY['alicante']::text[], 'Sagrada_Familia_01.jpg'),
    ('marq-archaeological-museum', 'alicante', 'MUSEUM', 2, 'HOURS', 4.6, 'Археологический музей MARQ', 'MARQ Archaeological Museum', 'MARQ археологиялық музейі', 38.35250000, -0.47800000, 'MARQ Archaeological Museum Alicante', ARRAY['alicante']::text[], ARRAY['alicante']::text[], 'Sagrada_Familia_01.jpg'),
    ('tabarca-island', 'alicante', 'NATURE', 5, 'HOURS', 4.7, 'Остров Табарка', 'Tabarca Island', 'Табарка аралы', 38.16530000, -0.48160000, 'Tabarca Island Alicante', ARRAY['alicante']::text[], ARRAY['alicante']::text[], 'Sagrada_Familia_01.jpg'),
    ('levante-beach-benidorm', 'benidorm', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Леванте', 'Benidorm Levante Beach', 'Бенидорм Леванте жағажайы', 38.53890000, -0.11730000, 'Levante Beach Benidorm', ARRAY['benidorm', 'alicante']::text[], ARRAY['alicante', 'benidorm']::text[], 'Sagrada_Familia_01.jpg'),
    ('terra-mitica', 'benidorm', 'ENTERTAINMENT', 6, 'HOURS', 4.5, 'Терра Митика', 'Terra Mitica', 'Терра Митика', 38.56060000, -0.16150000, 'Terra Mitica Benidorm', ARRAY['benidorm', 'alicante']::text[], ARRAY['alicante', 'benidorm']::text[], 'Sagrada_Familia_01.jpg'),
    ('murcia-cathedral', 'murcia', 'TEMPLE', 2, 'HOURS', 4.7, 'Кафедральный собор Мурсии', 'Murcia Cathedral', 'Мурсия соборы', 37.98410000, -1.12860000, 'Murcia Cathedral', ARRAY['murcia']::text[], ARRAY['murcia']::text[], 'Sagrada_Familia_01.jpg'),
    ('cartagena-roman-theatre', 'cartagena', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Римского театра Картахены', 'Roman Theatre Museum Cartagena', 'Картахена рим театры музейі', 37.59930000, -0.98420000, 'Roman Theatre Museum Cartagena Murcia', ARRAY['cartagena', 'murcia']::text[], ARRAY['murcia', 'cartagena']::text[], 'Sagrada_Familia_01.jpg'),
    ('palma-cathedral', 'mallorca', 'TEMPLE', 2, 'HOURS', 4.8, 'Кафедральный собор Пальмы', 'Palma Cathedral', 'Пальма соборы', 39.56740000, 2.64820000, 'Palma Cathedral Mallorca', ARRAY['mallorca']::text[], ARRAY['mallorca']::text[], 'Sagrada_Familia_01.jpg'),
    ('bellver-castle', 'mallorca', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Бельвер', 'Bellver Castle', 'Бельвер қамалы', 39.56380000, 2.61950000, 'Bellver Castle Mallorca', ARRAY['mallorca']::text[], ARRAY['mallorca']::text[], 'Sagrada_Familia_01.jpg'),
    ('olivar-market', 'mallorca', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Оливар', 'Olivar Market', 'Оливар базары', 39.57310000, 2.65260000, 'Mercat de Olivar Palma Mallorca', ARRAY['mallorca']::text[], ARRAY['mallorca']::text[], 'Sagrada_Familia_01.jpg'),
    ('es-trenc-beach', 'mallorca', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Эс-Тренк', 'Es Trenc Beach', 'Эс-Тренк жағажайы', 39.34350000, 2.98190000, 'Es Trenc Beach Mallorca', ARRAY['mallorca']::text[], ARRAY['mallorca']::text[], 'Sagrada_Familia_01.jpg'),
    ('ibiza-dalt-vila', 'ibiza', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дальт-Вила', 'Ibiza Dalt Vila', 'Ибица Дальт-Вила', 38.90670000, 1.43690000, 'Dalt Vila Ibiza', ARRAY['ibiza']::text[], ARRAY['ibiza']::text[], 'Sagrada_Familia_01.jpg'),
    ('las-dalias-market', 'ibiza', 'MARKET', 2, 'HOURS', 4.5, 'Хиппи-рынок Лас-Далиас', 'Las Dalias Hippy Market', 'Лас-Далиас базары', 39.03290000, 1.56560000, 'Las Dalias Hippy Market Ibiza', ARRAY['ibiza']::text[], ARRAY['ibiza']::text[], 'Sagrada_Familia_01.jpg'),
    ('es-vedra', 'ibiza', 'NATURE', 3, 'HOURS', 4.8, 'Эс-Ведра', 'Es Vedra', 'Эс-Ведра', 38.87260000, 1.19790000, 'Es Vedra Ibiza', ARRAY['ibiza']::text[], ARRAY['ibiza']::text[], 'Sagrada_Familia_01.jpg'),
    ('cala-macarella', 'menorca', 'BEACH', 4, 'HOURS', 4.8, 'Кала-Макарелья', 'Cala Macarella', 'Кала-Макарелья', 39.93760000, 3.93800000, 'Cala Macarella Menorca', ARRAY['menorca']::text[], ARRAY['menorca']::text[], 'Sagrada_Familia_01.jpg'),

    ('alhambra', 'granada', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Альгамбра', 'Alhambra', 'Альгамбра', 37.17610000, -3.58810000, 'Alhambra Granada Spain', ARRAY['granada']::text[], ARRAY['granada']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('generalife', 'granada', 'PARK', 2, 'HOURS', 4.8, 'Хенералифе', 'Generalife', 'Хенералифе', 37.17690000, -3.58410000, 'Generalife Granada', ARRAY['granada']::text[], ARRAY['granada']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('albaicin-mirador-san-nicolas', 'granada', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Альбайсин и мирадор Сан-Николас', 'Albaicin and Mirador San Nicolas', 'Альбайсин және Сан-Николас алаңы', 37.18100000, -3.59290000, 'Albaicin Mirador San Nicolas Granada', ARRAY['granada']::text[], ARRAY['granada']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('granada-cathedral', 'granada', 'TEMPLE', 2, 'HOURS', 4.7, 'Кафедральный собор Гранады', 'Granada Cathedral', 'Гранада соборы', 37.17610000, -3.59930000, 'Granada Cathedral Spain', ARRAY['granada']::text[], ARRAY['granada']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('seville-cathedral', 'seville', 'TEMPLE', 2, 'HOURS', 4.9, 'Севильский собор', 'Seville Cathedral', 'Севилья соборы', 37.38600000, -5.99260000, 'Seville Cathedral La Giralda', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('royal-alcazar-seville', 'seville', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Королевский Алькасар Севильи', 'Royal Alcazar of Seville', 'Севилья король Алькасары', 37.38310000, -5.99020000, 'Royal Alcazar of Seville', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('plaza-de-espana-seville', 'seville', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Испании в Севилье', 'Plaza de Espana Seville', 'Севилья Испания алаңы', 37.37720000, -5.98690000, 'Plaza de Espana Seville', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('maria-luisa-park', 'seville', 'PARK', 2, 'HOURS', 4.7, 'Парк Марии Луизы', 'Maria Luisa Park', 'Мария Луиза паркі', 37.37490000, -5.98830000, 'Maria Luisa Park Seville', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('mercado-de-triana', 'seville', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Трианы', 'Mercado de Triana', 'Триана базары', 37.38480000, -6.00140000, 'Mercado de Triana Seville', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('isla-magica', 'seville', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'Исла-Махика', 'Isla Magica', 'Исла-Махика', 37.40890000, -5.99690000, 'Isla Magica Seville', ARRAY['seville']::text[], ARRAY['seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('cordoba-mosque-cathedral', 'cordoba', 'TEMPLE', 2, 'HOURS', 4.9, 'Мескита-собор Кордовы', 'Cordoba Mosque-Cathedral', 'Кордова мешіт-соборы', 37.87910000, -4.77940000, 'Mosque Cathedral of Cordoba', ARRAY['cordoba']::text[], ARRAY['cordoba', 'seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('medina-azahara', 'cordoba', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Медина Асахара', 'Medina Azahara', 'Медина Асахара', 37.88700000, -4.86700000, 'Medina Azahara Cordoba', ARRAY['cordoba']::text[], ARRAY['cordoba', 'seville']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('viana-palace', 'cordoba', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Виана', 'Viana Palace', 'Виана сарайы', 37.88790000, -4.77290000, 'Viana Palace Cordoba', ARRAY['cordoba']::text[], ARRAY['cordoba']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('alcazaba-malaga', 'malaga', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Алькасаба Малаги', 'Alcazaba of Malaga', 'Малага Алькасабасы', 36.72140000, -4.41510000, 'Alcazaba Malaga', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('malaga-picasso-museum', 'malaga', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Пикассо в Малаге', 'Malaga Picasso Museum', 'Малага Пикассо музейі', 36.72120000, -4.41830000, 'Picasso Museum Malaga', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('atarazanas-market', 'malaga', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Атарасанас', 'Atarazanas Market', 'Атарасанас базары', 36.71920000, -4.42410000, 'Mercado Central de Atarazanas Malaga', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('la-malagueta-beach', 'malaga', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Ла-Малагета', 'La Malagueta Beach', 'Ла-Малагета жағажайы', 36.71790000, -4.40440000, 'La Malagueta Beach Malaga', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('muelle-uno', 'malaga', 'SHOPPING', 2, 'HOURS', 4.5, 'Muelle Uno', 'Muelle Uno', 'Muelle Uno', 36.71730000, -4.41420000, 'Muelle Uno Malaga', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('pedregalejo-food', 'malaga', 'FOOD', 2, 'HOURS', 4.6, 'Набережная Педрегалехо', 'Pedregalejo Seafront', 'Педрегалехо жағалауы', 36.72010000, -4.35930000, 'Pedregalejo Malaga food', ARRAY['malaga']::text[], ARRAY['malaga']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('puerto-banus', 'marbella', 'SHOPPING', 3, 'HOURS', 4.6, 'Пуэрто-Банус', 'Puerto Banus', 'Пуэрто-Банус', 36.48430000, -4.95260000, 'Puerto Banus Marbella', ARRAY['marbella']::text[], ARRAY['malaga', 'marbella']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('cabopino-beach', 'marbella', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Кабопино', 'Cabopino Beach', 'Кабопино жағажайы', 36.48810000, -4.74000000, 'Cabopino Beach Marbella', ARRAY['marbella']::text[], ARRAY['malaga', 'marbella']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('puente-nuevo-ronda', 'ronda', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Новый мост Ронды', 'Puente Nuevo', 'Ронда жаңа көпірі', 36.74160000, -5.16670000, 'Puente Nuevo Ronda', ARRAY['ronda']::text[], ARRAY['malaga', 'ronda']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('cadiz-cathedral', 'cadiz', 'TEMPLE', 2, 'HOURS', 4.7, 'Кафедральный собор Кадиса', 'Cadiz Cathedral', 'Кадис соборы', 36.52970000, -6.29470000, 'Cadiz Cathedral', ARRAY['cadiz']::text[], ARRAY['seville', 'cadiz']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('la-caleta-beach', 'cadiz', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Ла-Калета', 'La Caleta Beach', 'Ла-Калета жағажайы', 36.52930000, -6.30800000, 'La Caleta Beach Cadiz', ARRAY['cadiz']::text[], ARRAY['cadiz']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('bolonia-beach', 'tarifa', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Болония', 'Bolonia Beach', 'Болония жағажайы', 36.08970000, -5.76900000, 'Bolonia Beach Tarifa', ARRAY['tarifa']::text[], ARRAY['cadiz', 'tarifa']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('baelo-claudia', 'tarifa', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Археологический комплекс Баэло-Клаудия', 'Baelo Claudia Archaeological Site', 'Баэло-Клаудия археологиялық орны', 36.08900000, -5.77430000, 'Baelo Claudia Tarifa', ARRAY['tarifa']::text[], ARRAY['cadiz', 'tarifa']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('caminito-del-rey', 'andalusia', 'NATURE', 4, 'HOURS', 4.8, 'Каминито-дель-Рей', 'Caminito del Rey', 'Каминито-дель-Рей', 36.91470000, -4.75940000, 'Caminito del Rey Malaga', ARRAY['andalusia', 'malaga']::text[], ARRAY['malaga', 'andalusia']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),
    ('donana-national-park', 'andalusia', 'NATURE', 6, 'HOURS', 4.7, 'Национальный парк Доньяна', 'Donana National Park', 'Доньяна ұлттық паркі', 37.00000000, -6.50000000, 'Donana National Park Andalusia', ARRAY['andalusia', 'seville', 'cadiz']::text[], ARRAY['seville', 'cadiz', 'andalusia']::text[], 'Alhambra_evening_panorama_Mirador_San_Nicolas_sRGB-1.jpg'),

    ('teide-national-park', 'tenerife', 'NATURE', 6, 'HOURS', 4.9, 'Национальный парк Тейде', 'Teide National Park', 'Тейде ұлттық паркі', 28.27230000, -16.64250000, 'Teide National Park Tenerife', ARRAY['tenerife']::text[], ARRAY['tenerife']::text[], 'Teide_Canadas.jpg'),
    ('las-teresitas-beach', 'tenerife', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Лас-Тереситас', 'Las Teresitas Beach', 'Лас-Тереситас жағажайы', 28.50870000, -16.18570000, 'Las Teresitas Beach Tenerife', ARRAY['tenerife']::text[], ARRAY['tenerife']::text[], 'Teide_Canadas.jpg'),
    ('mercado-africa-tenerife', 'tenerife', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Нуэстра-Сеньора-де-Африка', 'Mercado Nuestra Senora de Africa', 'Нуэстра-Сеньора-де-Африка базары', 28.46550000, -16.25000000, 'Mercado Nuestra Senora de Africa Tenerife', ARRAY['tenerife']::text[], ARRAY['tenerife']::text[], 'Teide_Canadas.jpg'),
    ('maspalomas-dunes', 'gran-canaria', 'NATURE', 3, 'HOURS', 4.8, 'Дюны Маспаломас', 'Maspalomas Dunes', 'Маспаломас құмдары', 27.74390000, -15.58000000, 'Maspalomas Dunes Gran Canaria', ARRAY['gran-canaria']::text[], ARRAY['gran-canaria']::text[], 'Teide_Canadas.jpg'),
    ('las-canteras-beach', 'gran-canaria', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Лас-Кантерас', 'Las Canteras Beach', 'Лас-Кантерас жағажайы', 28.14040000, -15.43660000, 'Las Canteras Beach Gran Canaria', ARRAY['gran-canaria']::text[], ARRAY['gran-canaria']::text[], 'Teide_Canadas.jpg'),
    ('poema-del-mar', 'gran-canaria', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Аквариум Поэма-дель-Мар', 'Poema del Mar Aquarium', 'Поэма-дель-Мар аквариумы', 28.14410000, -15.42750000, 'Poema del Mar Aquarium Gran Canaria', ARRAY['gran-canaria']::text[], ARRAY['gran-canaria']::text[], 'Teide_Canadas.jpg'),
    ('timanfaya-national-park', 'lanzarote', 'NATURE', 4, 'HOURS', 4.8, 'Национальный парк Тиманфайя', 'Timanfaya National Park', 'Тиманфайя ұлттық паркі', 29.01000000, -13.75390000, 'Timanfaya National Park Lanzarote', ARRAY['lanzarote']::text[], ARRAY['lanzarote']::text[], 'Teide_Canadas.jpg'),
    ('jameos-del-agua', 'lanzarote', 'NATURE', 2, 'HOURS', 4.7, 'Хамеос-дель-Агуа', 'Jameos del Agua', 'Хамеос-дель-Агуа', 29.15720000, -13.43240000, 'Jameos del Agua Lanzarote', ARRAY['lanzarote']::text[], ARRAY['lanzarote']::text[], 'Teide_Canadas.jpg'),
    ('corralejo-dunes', 'fuerteventura', 'NATURE', 3, 'HOURS', 4.8, 'Дюны Корралехо', 'Corralejo Dunes Natural Park', 'Корралехо құмдары', 28.73080000, -13.84080000, 'Corralejo Dunes Natural Park Fuerteventura', ARRAY['fuerteventura']::text[], ARRAY['fuerteventura']::text[], 'Teide_Canadas.jpg'),
    ('cofete-beach', 'fuerteventura', 'BEACH', 5, 'HOURS', 4.8, 'Пляж Кофете', 'Cofete Beach', 'Кофете жағажайы', 28.10970000, -14.37700000, 'Cofete Beach Fuerteventura', ARRAY['fuerteventura']::text[], ARRAY['fuerteventura']::text[], 'Teide_Canadas.jpg'),
    ('guggenheim-bilbao', 'bilbao', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Гуггенхайма в Бильбао', 'Guggenheim Museum Bilbao', 'Бильбао Гуггенхайм музейі', 43.26870000, -2.93400000, 'Guggenheim Museum Bilbao', ARRAY['bilbao']::text[], ARRAY['bilbao']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('casco-viejo-bilbao', 'bilbao', 'MARKET', 2, 'HOURS', 4.6, 'Старый город Бильбао', 'Bilbao Old Town Casco Viejo', 'Бильбао ескі қаласы', 43.25890000, -2.92360000, 'Casco Viejo Bilbao', ARRAY['bilbao']::text[], ARRAY['bilbao']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('mercado-ribera-bilbao', 'bilbao', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Рибера', 'Mercado de la Ribera', 'Рибера базары', 43.25620000, -2.92430000, 'Mercado de la Ribera Bilbao', ARRAY['bilbao']::text[], ARRAY['bilbao']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('la-concha-beach', 'san-sebastian', 'BEACH', 3, 'HOURS', 4.9, 'Пляж Ла-Конча', 'La Concha Beach', 'Ла-Конча жағажайы', 43.31690000, -1.98650000, 'La Concha Beach San Sebastian', ARRAY['san-sebastian']::text[], ARRAY['san-sebastian', 'bilbao']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('monte-igueldo', 'san-sebastian', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Монте-Игельдо', 'Monte Igueldo', 'Монте-Игельдо', 43.32120000, -2.00990000, 'Monte Igueldo San Sebastian', ARRAY['san-sebastian']::text[], ARRAY['san-sebastian']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('san-telmo-museum', 'san-sebastian', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Сан-Тельмо', 'San Telmo Museum', 'Сан-Тельмо музейі', 43.32400000, -1.98530000, 'San Telmo Museum San Sebastian', ARRAY['san-sebastian']::text[], ARRAY['san-sebastian']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('san-sebastian-pintxos', 'san-sebastian', 'FOOD', 2, 'HOURS', 4.8, 'Старый город и пинчос-бары', 'Old Town Pintxos Quarter', 'Пинчос кварталы', 43.32360000, -1.98630000, 'San Sebastian Old Town Pintxos', ARRAY['san-sebastian']::text[], ARRAY['san-sebastian']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('pamplona-cathedral', 'pamplona', 'TEMPLE', 2, 'HOURS', 4.6, 'Кафедральный собор Памплоны', 'Pamplona Cathedral', 'Памплона соборы', 42.81830000, -1.64420000, 'Pamplona Cathedral', ARRAY['pamplona']::text[], ARRAY['pamplona']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('ciudadela-pamplona', 'pamplona', 'PARK', 2, 'HOURS', 4.6, 'Цитадель и парк Памплоны', 'Ciudadela and Vuelta del Castillo Park', 'Памплона цитаделі', 42.81320000, -1.65020000, 'Ciudadela Pamplona Park', ARRAY['pamplona']::text[], ARRAY['pamplona']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('magdalena-palace', 'santander', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Магдалены', 'Magdalena Palace', 'Магдалена сарайы', 43.46920000, -3.76690000, 'Magdalena Palace Santander', ARRAY['santander']::text[], ARRAY['santander']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('el-sardinero-beach', 'santander', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Эль-Сардинеро', 'El Sardinero Beach', 'Эль-Сардинеро жағажайы', 43.47640000, -3.78390000, 'El Sardinero Beach Santander', ARRAY['santander']::text[], ARRAY['santander']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('picos-de-europa', 'asturias', 'NATURE', 6, 'HOURS', 4.9, 'Национальный парк Пикос-де-Эуропа', 'Picos de Europa National Park', 'Пикос-де-Эуропа ұлттық паркі', 43.20000000, -4.80000000, 'Picos de Europa National Park Asturias', ARRAY['asturias']::text[], ARRAY['asturias']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('covadonga-lakes', 'asturias', 'NATURE', 5, 'HOURS', 4.8, 'Озера Ковадонга', 'Covadonga Lakes', 'Ковадонга көлдері', 43.27190000, -4.98970000, 'Covadonga Lakes Asturias', ARRAY['asturias']::text[], ARRAY['asturias']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('santiago-cathedral', 'santiago-de-compostela', 'TEMPLE', 2, 'HOURS', 4.9, 'Кафедральный собор Сантьяго-де-Компостела', 'Santiago de Compostela Cathedral', 'Сантьяго-де-Компостела соборы', 42.88060000, -8.54440000, 'Santiago de Compostela Cathedral', ARRAY['santiago-de-compostela']::text[], ARRAY['santiago-de-compostela']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('mercado-abastos-santiago', 'santiago-de-compostela', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Абастос', 'Mercado de Abastos Santiago', 'Абастос базары', 42.88020000, -8.54080000, 'Mercado de Abastos Santiago de Compostela', ARRAY['santiago-de-compostela']::text[], ARRAY['santiago-de-compostela']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('tower-of-hercules', 'a-coruna', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Башня Геркулеса', 'Tower of Hercules', 'Геркулес мұнарасы', 43.38580000, -8.40610000, 'Tower of Hercules A Coruna', ARRAY['a-coruna']::text[], ARRAY['a-coruna']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('aquarium-finisterrae', 'a-coruna', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Аквариум Финистерре', 'Aquarium Finisterrae', 'Финистерре аквариумы', 43.38180000, -8.40610000, 'Aquarium Finisterrae A Coruna', ARRAY['a-coruna']::text[], ARRAY['a-coruna']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('basilica-del-pilar', 'zaragoza', 'TEMPLE', 2, 'HOURS', 4.9, 'Базилика Нуэстра-Сеньора-дель-Пилар', 'Basilica del Pilar', 'Пилар базиликасы', 41.65610000, -0.87830000, 'Basilica del Pilar Zaragoza', ARRAY['zaragoza']::text[], ARRAY['zaragoza']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('aljaferia-palace', 'zaragoza', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Альхаферия', 'Aljaferia Palace', 'Альхаферия сарайы', 41.65640000, -0.89690000, 'Aljaferia Palace Zaragoza', ARRAY['zaragoza']::text[], ARRAY['zaragoza']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg'),
    ('zaragoza-central-market', 'zaragoza', 'MARKET', 2, 'HOURS', 4.5, 'Центральный рынок Сарагосы', 'Central Market Zaragoza', 'Сарагоса орталық базары', 41.65560000, -0.88250000, 'Central Market Zaragoza', ARRAY['zaragoza']::text[], ARRAY['zaragoza']::text[], 'Bilbao_-_Museo_Guggenheim_01.jpg');

CREATE TEMP TABLE seed_spain_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-spain-place:' || seed.slug) AS place_hash,
        md5('id-spain-media:' || seed.slug) AS media_hash
    FROM seed_spain_priority_places seed
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
    ARRAY['spain', city_id, slug, lower(category), 'spain-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Испании: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Spain tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Испания туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'ES',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20::numeric
        ELSE 10::numeric
    END,
    'EUR',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_spain_resolved_places
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
FROM seed_spain_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_spain_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_spain_resolved_places
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
FROM seed_spain_resolved_places seed
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
FROM seed_spain_resolved_places
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
    'ES',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_spain_resolved_places
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
    'ES',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_spain_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
