-- Priority Argentina destination places seed.
-- The seed covers Buenos Aires and the Atlantic coast, Patagonia, Iguazu and Litoral, Northwest Argentina, Cuyo, and Central Argentina.

DROP TABLE IF EXISTS seed_argentina_resolved_places;
DROP TABLE IF EXISTS seed_argentina_priority_places;

CREATE TEMP TABLE seed_argentina_priority_places (
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

INSERT INTO seed_argentina_priority_places (
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
    ('teatro-colon', 'buenos-aires', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Театр Колон', 'Teatro Colon', 'Колон театры', -34.60110000, -58.38310000, 'Teatro Colon Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('recoleta-cemetery', 'buenos-aires', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Кладбище Реколета', 'Recoleta Cemetery', 'Реколета зираты', -34.58740000, -58.39310000, 'Recoleta Cemetery Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('caminito-la-boca', 'buenos-aires', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Каминито в Ла-Боке', 'Caminito La Boca', 'Ла-Бока Каминито', -34.63990000, -58.36310000, 'Caminito La Boca Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('plaza-de-mayo-casa-rosada', 'buenos-aires', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Площадь Майо и Каса-Росада', 'Plaza de Mayo and Casa Rosada', 'Майо алаңы және Каса-Росада', -34.60810000, -58.37020000, 'Plaza de Mayo Casa Rosada Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('obelisco-avenida-9-de-julio', 'buenos-aires', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Обелиск и Авенида 9 июля', 'Obelisk and Avenida 9 de Julio', 'Обелиск және 9 шілде даңғылы', -34.60370000, -58.38160000, 'Obelisco Avenida 9 de Julio Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('el-ateneo-grand-splendid', 'buenos-aires', 'SHOPPING', 1, 'HOURS', 4.8, 'Эль Атенео Гранд Сплендид', 'El Ateneo Grand Splendid', 'El Ateneo Grand Splendid', -34.59590000, -58.39770000, 'El Ateneo Grand Splendid Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('malba', 'buenos-aires', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей MALBA', 'MALBA Museum', 'MALBA музейі', -34.57630000, -58.40390000, 'MALBA Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('national-museum-fine-arts', 'buenos-aires', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей изящных искусств', 'National Museum of Fine Arts', 'Ұлттық бейнелеу өнері музейі', -34.58450000, -58.39290000, 'Museo Nacional de Bellas Artes Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('san-telmo-market', 'buenos-aires', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Сан-Тельмо', 'San Telmo Market', 'Сан-Тельмо базары', -34.61900000, -58.37130000, 'Mercado de San Telmo Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('feria-de-mataderos', 'buenos-aires', 'MARKET', 2, 'HOURS', 4.6, 'Ярмарка Матадерос', 'Feria de Mataderos', 'Матадерос жәрмеңкесі', -34.65840000, -58.50120000, 'Feria de Mataderos Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('palermo-parks-rosedal', 'buenos-aires', 'PARK', 2, 'HOURS', 4.7, 'Парки Палермо и Розедаль', 'Palermo Parks and Rosedal', 'Палермо саябақтары және Розедаль', -34.57230000, -58.41590000, 'Bosques de Palermo Rosedal Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('costanera-sur-ecological-reserve', 'buenos-aires', 'NATURE', 2, 'HOURS', 4.7, 'Экологический заповедник Костанера-Сур', 'Costanera Sur Ecological Reserve', 'Костанера-Сур қорығы', -34.61180000, -58.35090000, 'Reserva Ecologica Costanera Sur Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('galerias-pacifico', 'buenos-aires', 'SHOPPING', 2, 'HOURS', 4.5, 'Галериас Пасифико', 'Galerias Pacifico', 'Galerias Pacifico', -34.59990000, -58.37450000, 'Galerias Pacifico Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('palermo-soho', 'buenos-aires', 'FOOD', 2, 'HOURS', 4.6, 'Палермо Сохо', 'Palermo Soho', 'Палермо Сохо', -34.58890000, -58.43060000, 'Palermo Soho Buenos Aires restaurants', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('puerto-madero-waterfront', 'buenos-aires', 'FOOD', 2, 'HOURS', 4.7, 'Набережная Пуэрто-Мадеро', 'Puerto Madero Waterfront', 'Пуэрто-Мадеро жағалауы', -34.61160000, -58.36390000, 'Puerto Madero Waterfront Buenos Aires', ARRAY['buenos-aires']::text[], ARRAY['buenos-aires']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),

    ('la-plata-cathedral', 'la-plata', 'TEMPLE', 2, 'HOURS', 4.8, 'Кафедральный собор Ла-Платы', 'La Plata Cathedral', 'Ла-Плата соборы', -34.92130000, -57.95430000, 'La Plata Cathedral Plaza Moreno', ARRAY['la-plata', 'buenos-aires']::text[], ARRAY['buenos-aires', 'la-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('museo-de-la-plata', 'la-plata', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Ла-Платы', 'Museo de La Plata', 'Ла-Плата музейі', -34.90890000, -57.93370000, 'Museo de La Plata natural history museum', ARRAY['la-plata']::text[], ARRAY['buenos-aires', 'la-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('paseo-del-bosque', 'la-plata', 'PARK', 2, 'HOURS', 4.6, 'Пасео-дель-Боске', 'Paseo del Bosque', 'Пасео-дель-Боске', -34.90880000, -57.93650000, 'Paseo del Bosque La Plata', ARRAY['la-plata']::text[], ARRAY['la-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('republica-de-los-ninos', 'la-plata', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Республика детей', 'Republica de los Ninos', 'Балалар республикасы', -34.87280000, -58.02980000, 'Republica de los Ninos La Plata', ARRAY['la-plata']::text[], ARRAY['buenos-aires', 'la-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('casa-curutchet', 'la-plata', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Дом Куручет', 'Casa Curutchet', 'Куручет үйі', -34.91180000, -57.94100000, 'Casa Curutchet La Plata', ARRAY['la-plata']::text[], ARRAY['la-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('puerto-de-frutos', 'tigre', 'MARKET', 2, 'HOURS', 4.6, 'Пуэрто-де-Фрутос', 'Puerto de Frutos', 'Пуэрто-де-Фрутос базары', -34.41900000, -58.57780000, 'Puerto de Frutos Tigre', ARRAY['tigre', 'buenos-aires']::text[], ARRAY['buenos-aires', 'tigre']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('tigre-art-museum', 'tigre', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей искусств Тигре', 'Tigre Art Museum', 'Тигре өнер музейі', -34.41050000, -58.58080000, 'Museo de Arte Tigre', ARRAY['tigre']::text[], ARRAY['buenos-aires', 'tigre']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('parque-de-la-costa', 'tigre', 'ENTERTAINMENT', 5, 'HOURS', 4.5, 'Парк де ла Коста', 'Parque de la Costa', 'Парке-де-ла-Коста', -34.42080000, -58.57630000, 'Parque de la Costa Tigre', ARRAY['tigre']::text[], ARRAY['buenos-aires', 'tigre']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('tigre-delta', 'tigre', 'NATURE', 4, 'HOURS', 4.7, 'Дельта Тигре', 'Tigre Delta', 'Тигре дельтасы', -34.40260000, -58.59450000, 'Tigre Delta boat tour', ARRAY['tigre', 'buenos-aires']::text[], ARRAY['buenos-aires', 'tigre']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('paseo-victorica', 'tigre', 'FOOD', 2, 'HOURS', 4.5, 'Пасео Викторика', 'Paseo Victorica', 'Пасео Викторика', -34.40990000, -58.57680000, 'Paseo Victorica Tigre', ARRAY['tigre']::text[], ARRAY['tigre']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),

    ('mar-del-plata-central-beach', 'mar-del-plata', 'BEACH', 3, 'HOURS', 4.5, 'Центральный пляж Мар-дель-Платы', 'Mar del Plata Central Beach', 'Мар-дель-Плата орталық жағажайы', -38.00230000, -57.54300000, 'Bristol Beach Mar del Plata', ARRAY['mar-del-plata']::text[], ARRAY['buenos-aires', 'mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('playa-grande', 'mar-del-plata', 'BEACH', 3, 'HOURS', 4.6, 'Плайя-Гранде', 'Playa Grande', 'Плайя-Гранде', -38.03460000, -57.53260000, 'Playa Grande Mar del Plata', ARRAY['mar-del-plata']::text[], ARRAY['mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('torreon-del-monje', 'mar-del-plata', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Торреон-дель-Монхе', 'Torreon del Monje', 'Торреон-дель-Монхе', -38.01030000, -57.53780000, 'Torreon del Monje Mar del Plata', ARRAY['mar-del-plata']::text[], ARRAY['mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('mar-del-plata-port-banquina', 'mar-del-plata', 'FOOD', 2, 'HOURS', 4.5, 'Порт Мар-дель-Платы и Банкина', 'Mar del Plata Port and Banquina', 'Мар-дель-Плата порты', -38.04340000, -57.53790000, 'Mar del Plata Port Banquina seafood', ARRAY['mar-del-plata']::text[], ARRAY['mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('museo-mar', 'mar-del-plata', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей MAR', 'MAR Museum', 'MAR музейі', -37.96320000, -57.54370000, 'Museo MAR Mar del Plata', ARRAY['mar-del-plata']::text[], ARRAY['mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('paseo-aldrey-shopping', 'mar-del-plata', 'SHOPPING', 2, 'HOURS', 4.4, 'Пасео Алдрей', 'Paseo Aldrey Shopping', 'Paseo Aldrey сауда орталығы', -38.00950000, -57.54550000, 'Paseo Aldrey Shopping Mar del Plata', ARRAY['mar-del-plata']::text[], ARRAY['mar-del-plata']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('pinamar-beaches', 'pinamar', 'BEACH', 3, 'HOURS', 4.5, 'Пляжи Пинамара', 'Pinamar Beaches', 'Пинамар жағажайлары', -37.10790000, -56.85920000, 'Pinamar beaches Argentina', ARRAY['pinamar']::text[], ARRAY['buenos-aires', 'pinamar']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('carilo-forest-commercial-center', 'carilo', 'NATURE', 3, 'HOURS', 4.5, 'Лес и центр Карило', 'Carilo Forest and Commercial Center', 'Карило орманы және орталығы', -37.16530000, -56.89920000, 'Carilo forest commercial center', ARRAY['carilo']::text[], ARRAY['buenos-aires', 'carilo']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('villa-gesell-beach-pinar-norte', 'villa-gesell', 'NATURE', 3, 'HOURS', 4.5, 'Пляж Вилья-Хесель и Пинар Норте', 'Villa Gesell Beach and Pinar Norte', 'Вилья-Хесель жағажайы', -37.26390000, -56.97730000, 'Villa Gesell beach Pinar Norte', ARRAY['villa-gesell']::text[], ARRAY['buenos-aires', 'villa-gesell']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('mar-de-las-pampas-village', 'mar-de-las-pampas', 'NATURE', 3, 'HOURS', 4.5, 'Мар-де-лас-Пампас', 'Mar de las Pampas Village', 'Мар-де-лас-Пампас ауылы', -37.33070000, -57.02420000, 'Mar de las Pampas forest beach village', ARRAY['mar-de-las-pampas']::text[], ARRAY['buenos-aires', 'mar-de-las-pampas']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),
    ('mundo-marino', 'san-clemente-del-tuyu', 'ENTERTAINMENT', 5, 'HOURS', 4.2, 'Мундо Марино', 'Mundo Marino', 'Мундо Марино', -36.33150000, -56.72090000, 'Mundo Marino San Clemente del Tuyu', ARRAY['san-clemente-del-tuyu']::text[], ARRAY['buenos-aires', 'san-clemente-del-tuyu']::text[], 'Obelisco Buenos Aires desde chalet Diaz.jpg'),

    ('nahuel-huapi-national-park', 'bariloche', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Науэль-Уапи', 'Nahuel Huapi National Park', 'Науэль-Уапи ұлттық паркі', -41.13560000, -71.31030000, 'Nahuel Huapi National Park Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('circuito-chico', 'bariloche', 'NATURE', 4, 'HOURS', 4.8, 'Малый круг Барилоче', 'Circuito Chico', 'Барилоче кіші айналымы', -41.06190000, -71.53180000, 'Circuito Chico Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('cerro-campanario', 'bariloche', 'NATURE', 2, 'HOURS', 4.8, 'Серро Кампанарио', 'Cerro Campanario', 'Серро Кампанарио', -41.04640000, -71.46320000, 'Cerro Campanario Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('llao-llao-peninsula', 'bariloche', 'NATURE', 3, 'HOURS', 4.8, 'Полуостров Льяо-Льяо', 'Llao Llao Peninsula', 'Льяо-Льяо түбегі', -41.05870000, -71.53040000, 'Llao Llao Peninsula Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('civic-center-bariloche', 'bariloche', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Гражданский центр Барилоче', 'Civic Center Bariloche', 'Барилоче азаматтық орталығы', -41.13350000, -71.31030000, 'Centro Civico Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('museum-of-patagonia', 'bariloche', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Патагонии', 'Museum of Patagonia', 'Патагония музейі', -41.13350000, -71.31070000, 'Museo de la Patagonia Bariloche', ARRAY['bariloche']::text[], ARRAY['bariloche']::text[], 'Llao Llao Peninsula.jpg'),
    ('perito-moreno-glacier', 'el-calafate', 'NATURE', 6, 'HOURS', 4.9, 'Ледник Перито-Морено', 'Perito Moreno Glacier', 'Перито-Морено мұздығы', -50.49670000, -73.13770000, 'Perito Moreno Glacier Argentina', ARRAY['el-calafate']::text[], ARRAY['el-calafate']::text[], 'PeritoMoreno005.jpg'),
    ('los-glaciares-national-park', 'el-calafate', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Лос-Гласьярес', 'Los Glaciares National Park', 'Лос-Гласьярес ұлттық паркі', -50.00000000, -73.24900000, 'Los Glaciares National Park Argentina', ARRAY['el-calafate', 'el-chalten']::text[], ARRAY['el-calafate', 'el-chalten']::text[], 'PeritoMoreno005.jpg'),
    ('glaciarium', 'el-calafate', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Glaciarium', 'Glaciarium', 'Glaciarium музейі', -50.33770000, -72.30060000, 'Glaciarium El Calafate', ARRAY['el-calafate']::text[], ARRAY['el-calafate']::text[], 'PeritoMoreno005.jpg'),
    ('laguna-nimez-reserve', 'el-calafate', 'NATURE', 2, 'HOURS', 4.5, 'Заповедник Лагуна Нимес', 'Laguna Nimez Reserve', 'Лагуна Нимес қорығы', -50.33510000, -72.26610000, 'Laguna Nimez El Calafate', ARRAY['el-calafate']::text[], ARRAY['el-calafate']::text[], 'PeritoMoreno005.jpg'),
    ('mount-fitz-roy', 'el-chalten', 'NATURE', 7, 'HOURS', 4.9, 'Гора Фицрой', 'Mount Fitz Roy', 'Фицрой тауы', -49.27130000, -73.04390000, 'Mount Fitz Roy El Chalten', ARRAY['el-chalten']::text[], ARRAY['el-chalten']::text[], 'PeritoMoreno005.jpg'),
    ('laguna-de-los-tres', 'el-chalten', 'NATURE', 7, 'HOURS', 4.9, 'Лагуна де лос Трес', 'Laguna de los Tres', 'Лагуна-де-лос-Трес', -49.27360000, -73.03230000, 'Laguna de los Tres Fitz Roy', ARRAY['el-chalten']::text[], ARRAY['el-chalten']::text[], 'PeritoMoreno005.jpg'),
    ('chorrillo-del-salto', 'el-chalten', 'NATURE', 2, 'HOURS', 4.6, 'Водопад Чоррильо-дель-Сальто', 'Chorrillo del Salto', 'Чоррильо-дель-Сальто сарқырамасы', -49.30620000, -72.90380000, 'Chorrillo del Salto El Chalten', ARRAY['el-chalten']::text[], ARRAY['el-chalten']::text[], 'PeritoMoreno005.jpg'),
    ('tierra-del-fuego-national-park', 'ushuaia', 'PARK', 5, 'HOURS', 4.8, 'Национальный парк Огненная Земля', 'Tierra del Fuego National Park', 'Отты Жер ұлттық паркі', -54.84390000, -68.56580000, 'Tierra del Fuego National Park Ushuaia', ARRAY['ushuaia']::text[], ARRAY['ushuaia']::text[], 'PeritoMoreno005.jpg'),
    ('beagle-channel', 'ushuaia', 'NATURE', 4, 'HOURS', 4.8, 'Канал Бигл', 'Beagle Channel', 'Бигл бұғазы', -54.86700000, -68.15000000, 'Beagle Channel Ushuaia boat tour', ARRAY['ushuaia']::text[], ARRAY['ushuaia']::text[], 'PeritoMoreno005.jpg'),
    ('end-of-world-train', 'ushuaia', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Поезд на краю света', 'End of the World Train', 'Әлем шетіндегі пойыз', -54.82380000, -68.41960000, 'End of the World Train Ushuaia', ARRAY['ushuaia']::text[], ARRAY['ushuaia']::text[], 'PeritoMoreno005.jpg'),
    ('maritime-prison-museum', 'ushuaia', 'MUSEUM', 2, 'HOURS', 4.6, 'Морской музей и музей тюрьмы', 'Maritime and Prison Museum', 'Теңіз және түрме музейі', -54.80550000, -68.30200000, 'Maritime Prison Museum Ushuaia', ARRAY['ushuaia']::text[], ARRAY['ushuaia']::text[], 'PeritoMoreno005.jpg'),
    ('playa-el-doradillo', 'puerto-madryn', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Эль-Дорадильо', 'Playa El Doradillo', 'Эль-Дорадильо жағажайы', -42.65030000, -64.99490000, 'Playa El Doradillo Puerto Madryn', ARRAY['puerto-madryn']::text[], ARRAY['puerto-madryn']::text[], 'PeritoMoreno005.jpg'),
    ('ecocentro-pampa-azul', 'puerto-madryn', 'MUSEUM', 2, 'HOURS', 4.5, 'Экоцентр Pampa Azul', 'Ecocentro Pampa Azul', 'Pampa Azul экоорталығы', -42.78560000, -65.01890000, 'Ecocentro Pampa Azul Puerto Madryn', ARRAY['puerto-madryn']::text[], ARRAY['puerto-madryn']::text[], 'PeritoMoreno005.jpg'),
    ('punta-tombo', 'puerto-madryn', 'NATURE', 6, 'HOURS', 4.8, 'Пунта-Томбо', 'Punta Tombo', 'Пунта-Томбо', -44.04670000, -65.23300000, 'Punta Tombo penguins Argentina', ARRAY['puerto-madryn']::text[], ARRAY['puerto-madryn']::text[], 'PeritoMoreno005.jpg'),
    ('peninsula-valdes', 'peninsula-valdes', 'NATURE', 6, 'HOURS', 4.9, 'Полуостров Вальдес', 'Peninsula Valdes', 'Вальдес түбегі', -42.50000000, -63.95000000, 'Peninsula Valdes Argentina', ARRAY['peninsula-valdes', 'puerto-madryn']::text[], ARRAY['puerto-madryn', 'peninsula-valdes']::text[], 'PeritoMoreno005.jpg'),
    ('whale-watching-golfo-nuevo', 'peninsula-valdes', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Наблюдение за китами в Гольфо-Нуэво', 'Golfo Nuevo Whale Watching', 'Гольфо-Нуэво киттерін бақылау', -42.57350000, -64.28230000, 'Peninsula Valdes whale watching', ARRAY['peninsula-valdes', 'puerto-madryn']::text[], ARRAY['puerto-madryn', 'peninsula-valdes']::text[], 'PeritoMoreno005.jpg'),
    ('puerto-piramides', 'peninsula-valdes', 'BEACH', 3, 'HOURS', 4.6, 'Пуэрто-Пирамидес', 'Puerto Piramides', 'Пуэрто-Пирамидес', -42.57180000, -64.27960000, 'Puerto Piramides Peninsula Valdes', ARRAY['peninsula-valdes']::text[], ARRAY['puerto-madryn', 'peninsula-valdes']::text[], 'PeritoMoreno005.jpg'),

    ('iguazu-falls', 'iguazu-falls', 'NATURE', 6, 'HOURS', 4.9, 'Водопады Игуасу', 'Iguazu Falls', 'Игуасу сарқырамалары', -25.69530000, -54.43670000, 'Iguazu Falls Argentina', ARRAY['iguazu-falls', 'puerto-iguazu']::text[], ARRAY['puerto-iguazu', 'iguazu-falls']::text[], 'Cataratas027.jpg'),
    ('iguazu-devils-throat', 'iguazu-falls', 'NATURE', 3, 'HOURS', 4.9, 'Глотка Дьявола', 'Devils Throat Iguazu', 'Ібіліс тамағы Игуасу', -25.69580000, -54.43740000, 'Garganta del Diablo Iguazu Argentina', ARRAY['iguazu-falls', 'puerto-iguazu']::text[], ARRAY['puerto-iguazu', 'iguazu-falls']::text[], 'Cataratas027.jpg'),
    ('iguazu-national-park', 'iguazu-falls', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Игуасу', 'Iguazu National Park', 'Игуасу ұлттық паркі', -25.68350000, -54.45460000, 'Iguazu National Park Argentina', ARRAY['iguazu-falls', 'puerto-iguazu']::text[], ARRAY['puerto-iguazu', 'iguazu-falls']::text[], 'Cataratas027.jpg'),
    ('three-borders-landmark', 'puerto-iguazu', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Обелиск Трёх границ', 'Three Borders Landmark', 'Үш шекара белгісі', -25.59860000, -54.58420000, 'Hito Tres Fronteras Puerto Iguazu', ARRAY['puerto-iguazu']::text[], ARRAY['puerto-iguazu']::text[], 'Cataratas027.jpg'),
    ('la-aripuca', 'puerto-iguazu', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Ла-Арипука', 'La Aripuca', 'Ла-Арипука', -25.61690000, -54.56050000, 'La Aripuca Puerto Iguazu', ARRAY['puerto-iguazu']::text[], ARRAY['puerto-iguazu']::text[], 'Cataratas027.jpg'),
    ('duty-free-shop-puerto-iguazu', 'puerto-iguazu', 'SHOPPING', 2, 'HOURS', 4.4, 'Duty Free Shop Пуэрто-Игуасу', 'Duty Free Shop Puerto Iguazu', 'Пуэрто-Игуасу Duty Free', -25.59680000, -54.57770000, 'Duty Free Shop Puerto Iguazu', ARRAY['puerto-iguazu']::text[], ARRAY['puerto-iguazu']::text[], 'Cataratas027.jpg'),
    ('posadas-waterfront', 'posadas', 'PARK', 2, 'HOURS', 4.6, 'Набережная Посадаса', 'Posadas Waterfront', 'Посадас жағалауы', -27.36710000, -55.89610000, 'Costanera de Posadas', ARRAY['posadas']::text[], ARRAY['posadas']::text[], 'Cataratas027.jpg'),
    ('costa-sur-beach', 'posadas', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Коста-Сур', 'Costa Sur Beach', 'Коста-Сур жағажайы', -27.42100000, -55.90210000, 'Playa Costa Sur Posadas', ARRAY['posadas']::text[], ARRAY['posadas']::text[], 'Cataratas027.jpg'),
    ('la-placita-market', 'posadas', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Ла-Пласита', 'La Placita Market', 'Ла-Пласита базары', -27.36790000, -55.89640000, 'Mercado La Placita Posadas', ARRAY['posadas']::text[], ARRAY['posadas']::text[], 'Cataratas027.jpg'),
    ('corrientes-waterfront', 'corrientes', 'PARK', 2, 'HOURS', 4.6, 'Набережная Корриентеса', 'Corrientes Waterfront', 'Корриентес жағалауы', -27.46740000, -58.83830000, 'Costanera Corrientes Argentina', ARRAY['corrientes']::text[], ARRAY['corrientes']::text[], 'Cataratas027.jpg'),
    ('arazaty-beach', 'corrientes', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Аразати', 'Arazaty Beach', 'Аразати жағажайы', -27.47610000, -58.84810000, 'Playa Arazaty Corrientes', ARRAY['corrientes']::text[], ARRAY['corrientes']::text[], 'Cataratas027.jpg'),
    ('ibera-wetlands', 'esteros-del-ibera', 'NATURE', 6, 'HOURS', 4.9, 'Болота Ибера', 'Ibera Wetlands', 'Ибера батпақтары', -28.53330000, -57.16670000, 'Esteros del Ibera Argentina', ARRAY['esteros-del-ibera', 'corrientes']::text[], ARRAY['corrientes', 'esteros-del-ibera']::text[], 'Cataratas027.jpg'),
    ('ibera-boat-safari', 'esteros-del-ibera', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Лодочное сафари по Ибере', 'Ibera Boat Safari', 'Ибера қайық сафариі', -28.54440000, -57.16860000, 'Ibera wetlands boat safari', ARRAY['esteros-del-ibera']::text[], ARRAY['corrientes', 'esteros-del-ibera']::text[], 'Cataratas027.jpg'),
    ('national-flag-memorial', 'rosario', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Национальный монумент флагу', 'National Flag Memorial', 'Ұлттық ту монументі', -32.94770000, -60.63050000, 'Monumento Nacional a la Bandera Rosario', ARRAY['rosario']::text[], ARRAY['rosario']::text[], 'Cataratas027.jpg'),
    ('independence-park-rosario', 'rosario', 'PARK', 2, 'HOURS', 4.6, 'Парк Независимости Росарио', 'Independence Park Rosario', 'Росарио тәуелсіздік саябағы', -32.95490000, -60.66590000, 'Parque Independencia Rosario', ARRAY['rosario']::text[], ARRAY['rosario']::text[], 'Cataratas027.jpg'),
    ('mercado-del-patio', 'rosario', 'FOOD', 2, 'HOURS', 4.5, 'Меркадо-дель-Патио', 'Mercado del Patio', 'Меркадо-дель-Патио', -32.94350000, -60.66440000, 'Mercado del Patio Rosario', ARRAY['rosario']::text[], ARRAY['rosario']::text[], 'Cataratas027.jpg'),

    ('salta-cathedral', 'salta', 'TEMPLE', 2, 'HOURS', 4.8, 'Кафедральный собор Сальты', 'Salta Cathedral', 'Сальта соборы', -24.78940000, -65.41090000, 'Salta Cathedral Basilica Argentina', ARRAY['salta']::text[], ARRAY['salta']::text[], 'Cathedral of Salta 02.jpg'),
    ('maam-museum', 'salta', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей высокогорной археологии MAAM', 'MAAM High Mountain Archaeology Museum', 'MAAM биіктау археология музейі', -24.78910000, -65.41150000, 'MAAM Salta Museum', ARRAY['salta']::text[], ARRAY['salta']::text[], 'Cathedral of Salta 02.jpg'),
    ('cerro-san-bernardo', 'salta', 'NATURE', 2, 'HOURS', 4.6, 'Холм Сан-Бернардо', 'Cerro San Bernardo', 'Сан-Бернардо төбесі', -24.78970000, -65.38660000, 'Cerro San Bernardo Salta', ARRAY['salta']::text[], ARRAY['salta']::text[], 'Cathedral of Salta 02.jpg'),
    ('train-to-clouds', 'salta', 'ENTERTAINMENT', 7, 'HOURS', 4.6, 'Поезд в облака', 'Train to the Clouds', 'Бұлттарға пойыз', -24.78590000, -65.41170000, 'Tren a las Nubes Salta', ARRAY['salta']::text[], ARRAY['salta']::text[], 'Cathedral of Salta 02.jpg'),
    ('salta-artisan-market', 'salta', 'MARKET', 2, 'HOURS', 4.5, 'Ремесленный рынок Сальты', 'Salta Artisan Market', 'Сальта қолөнер базары', -24.79250000, -65.42960000, 'Mercado Artesanal Salta', ARRAY['salta']::text[], ARRAY['salta']::text[], 'Cathedral of Salta 02.jpg'),
    ('jujuy-cathedral', 'jujuy', 'TEMPLE', 1, 'HOURS', 4.6, 'Кафедральный собор Жужуя', 'Jujuy Cathedral', 'Жужуй соборы', -24.18580000, -65.29950000, 'Jujuy Cathedral Basilica', ARRAY['jujuy']::text[], ARRAY['jujuy']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('hill-of-seven-colors', 'purmamarca', 'NATURE', 2, 'HOURS', 4.9, 'Гора семи цветов', 'Hill of Seven Colors', 'Жеті түсті тау', -23.74670000, -65.49840000, 'Cerro de los Siete Colores Purmamarca', ARRAY['purmamarca', 'jujuy']::text[], ARRAY['jujuy', 'purmamarca']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('paseo-colorados', 'purmamarca', 'NATURE', 2, 'HOURS', 4.7, 'Пасео-де-лос-Колорадос', 'Paseo de los Colorados', 'Пасео-де-лос-Колорадос', -23.74600000, -65.49930000, 'Paseo de los Colorados Purmamarca', ARRAY['purmamarca']::text[], ARRAY['purmamarca']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('purmamarca-artisan-market', 'purmamarca', 'MARKET', 1, 'HOURS', 4.5, 'Ремесленный рынок Пурмамарки', 'Purmamarca Artisan Market', 'Пурмамарка қолөнер базары', -23.74670000, -65.49900000, 'Purmamarca artisan market', ARRAY['purmamarca']::text[], ARRAY['purmamarca']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('pucara-tilcara', 'tilcara', 'MUSEUM', 2, 'HOURS', 4.7, 'Пукара-де-Тилкара', 'Pucara de Tilcara', 'Пукара-де-Тилкара', -23.57860000, -65.39440000, 'Pucara de Tilcara Jujuy', ARRAY['tilcara', 'jujuy']::text[], ARRAY['jujuy', 'tilcara']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('quebrada-de-humahuaca', 'humahuaca', 'NATURE', 5, 'HOURS', 4.9, 'Кебрада-де-Умауака', 'Quebrada de Humahuaca', 'Кебрада-де-Умауака', -23.20000000, -65.35000000, 'Quebrada de Humahuaca Argentina', ARRAY['humahuaca', 'tilcara', 'purmamarca']::text[], ARRAY['jujuy', 'humahuaca']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('hornocal', 'humahuaca', 'NATURE', 4, 'HOURS', 4.8, 'Серрания-де-Орнокаль', 'Serrania de Hornocal', 'Орнокаль жотасы', -23.21450000, -65.17110000, 'Serrania de Hornocal Humahuaca', ARRAY['humahuaca']::text[], ARRAY['humahuaca']::text[], 'Cerro de los Siete Colores 03.jpg'),
    ('cafayate-wineries', 'cafayate', 'FOOD', 4, 'HOURS', 4.8, 'Винодельни Кафайате', 'Cafayate Wineries', 'Кафаяте шараптары', -26.07310000, -65.97600000, 'Cafayate wineries Argentina', ARRAY['cafayate', 'salta']::text[], ARRAY['salta', 'cafayate']::text[], 'Cathedral of Salta 02.jpg'),
    ('quebrada-de-las-conchas', 'cafayate', 'NATURE', 4, 'HOURS', 4.8, 'Ущелье Лас-Кончас', 'Quebrada de las Conchas', 'Лас-Кончас шатқалы', -25.88300000, -65.70000000, 'Quebrada de las Conchas Cafayate', ARRAY['cafayate', 'salta']::text[], ARRAY['salta', 'cafayate']::text[], 'Cathedral of Salta 02.jpg'),
    ('tucuman-historic-house', 'tucuman', 'MUSEUM', 2, 'HOURS', 4.8, 'Исторический дом независимости', 'Historic House of Independence', 'Тәуелсіздік тарихи үйі', -26.83090000, -65.20360000, 'Casa Historica de la Independencia Tucuman', ARRAY['tucuman']::text[], ARRAY['tucuman']::text[], 'Cathedral of Salta 02.jpg'),

    ('mendoza-wine-route', 'mendoza', 'FOOD', 5, 'HOURS', 4.8, 'Винный маршрут Мендосы', 'Mendoza Wine Route', 'Мендоса шарап маршруты', -32.88950000, -68.84580000, 'Mendoza wine route Argentina', ARRAY['mendoza']::text[], ARRAY['mendoza']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('general-san-martin-park', 'mendoza', 'PARK', 3, 'HOURS', 4.7, 'Парк Генерала Сан-Мартина', 'General San Martin Park', 'Генерал Сан-Мартин саябағы', -32.89080000, -68.87880000, 'General San Martin Park Mendoza', ARRAY['mendoza']::text[], ARRAY['mendoza']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('mendoza-central-market', 'mendoza', 'MARKET', 1, 'HOURS', 4.5, 'Центральный рынок Мендосы', 'Mendoza Central Market', 'Мендоса орталық базары', -32.88660000, -68.84060000, 'Mercado Central Mendoza', ARRAY['mendoza']::text[], ARRAY['mendoza']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('palmares-open-mall', 'mendoza', 'SHOPPING', 2, 'HOURS', 4.4, 'Palmares Open Mall', 'Palmares Open Mall', 'Palmares Open Mall', -32.96040000, -68.85770000, 'Palmares Open Mall Mendoza', ARRAY['mendoza']::text[], ARRAY['mendoza']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('aconcagua-provincial-park', 'aconcagua', 'PARK', 5, 'HOURS', 4.9, 'Провинциальный парк Аконкагуа', 'Aconcagua Provincial Park', 'Аконкагуа провинциялық паркі', -32.65320000, -70.01090000, 'Aconcagua Provincial Park Mendoza', ARRAY['aconcagua', 'mendoza', 'uspallata']::text[], ARRAY['mendoza', 'uspallata', 'aconcagua']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('puente-del-inca', 'uspallata', 'NATURE', 2, 'HOURS', 4.7, 'Мост Инков', 'Puente del Inca', 'Инка көпірі', -32.82470000, -69.91470000, 'Puente del Inca Mendoza', ARRAY['uspallata', 'aconcagua']::text[], ARRAY['mendoza', 'uspallata']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('atuel-canyon', 'san-rafael', 'NATURE', 5, 'HOURS', 4.8, 'Каньон Атуэль', 'Atuel Canyon', 'Атуэль каньоны', -34.83600000, -68.44400000, 'Canon del Atuel San Rafael Mendoza', ARRAY['san-rafael']::text[], ARRAY['mendoza', 'san-rafael']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('borges-labyrinth', 'san-rafael', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Лабиринт Борхеса', 'Borges Labyrinth', 'Борхес лабиринті', -34.61890000, -68.33210000, 'Laberinto de Borges San Rafael', ARRAY['san-rafael']::text[], ARRAY['san-rafael']::text[], 'Aconcagua Provincial Park 01.jpg'),
    ('cordoba-jesuit-block', 'cordoba-argentina', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Иезуитский квартал Кордовы', 'Cordoba Jesuit Block', 'Кордова иезуиттер кварталы', -31.41860000, -64.18700000, 'Manzana Jesuitica Cordoba Argentina', ARRAY['cordoba-argentina']::text[], ARRAY['cordoba-argentina']::text[], 'Cordoba-derecho1.JPG'),
    ('cordoba-cathedral', 'cordoba-argentina', 'TEMPLE', 2, 'HOURS', 4.7, 'Кафедральный собор Кордовы', 'Cordoba Cathedral', 'Кордова соборы', -31.41650000, -64.18360000, 'Catedral de Cordoba Argentina', ARRAY['cordoba-argentina']::text[], ARRAY['cordoba-argentina']::text[], 'Cordoba-derecho1.JPG'),
    ('patio-olmos-shopping', 'cordoba-argentina', 'SHOPPING', 2, 'HOURS', 4.4, 'Торговый центр Patio Olmos', 'Patio Olmos Shopping', 'Patio Olmos сауда орталығы', -31.42160000, -64.18850000, 'Patio Olmos Shopping Cordoba Argentina', ARRAY['cordoba-argentina']::text[], ARRAY['cordoba-argentina']::text[], 'Cordoba-derecho1.JPG'),
    ('mercado-norte-cordoba', 'cordoba-argentina', 'MARKET', 2, 'HOURS', 4.4, 'Северный рынок Кордовы', 'Mercado Norte Cordoba', 'Кордова солтүстік базары', -31.40990000, -64.18200000, 'Mercado Norte Cordoba Argentina', ARRAY['cordoba-argentina']::text[], ARRAY['cordoba-argentina']::text[], 'Cordoba-derecho1.JPG'),
    ('villa-carlos-paz-cuckoo-clock', 'villa-carlos-paz', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Часы с кукушкой Вилья-Карлос-Пас', 'Villa Carlos Paz Cuckoo Clock', 'Вилья-Карлос-Пас көкек сағаты', -31.41960000, -64.49710000, 'Reloj Cu Cu Villa Carlos Paz', ARRAY['villa-carlos-paz']::text[], ARRAY['cordoba-argentina', 'villa-carlos-paz']::text[], 'Cordoba-derecho1.JPG'),
    ('aerosilla-carlos-paz', 'villa-carlos-paz', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Комплекс Aerosilla', 'Aerosilla Carlos Paz', 'Aerosilla Carlos Paz', -31.42170000, -64.50680000, 'Complejo Aerosilla Villa Carlos Paz', ARRAY['villa-carlos-paz']::text[], ARRAY['cordoba-argentina', 'villa-carlos-paz']::text[], 'Cordoba-derecho1.JPG');

CREATE TEMP TABLE seed_argentina_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-argentina-place:' || seed.slug) AS place_hash,
        md5('id-argentina-media:' || seed.slug) AS media_hash
    FROM seed_argentina_priority_places seed
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
    ARRAY['argentina', city_id, slug, lower(category), 'argentina-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Аргентины: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Argentina tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Аргентина туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'AR',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'ARS',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_argentina_resolved_places
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
FROM seed_argentina_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_argentina_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_argentina_resolved_places
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
FROM seed_argentina_resolved_places seed
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
FROM seed_argentina_resolved_places
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
    'AR',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_argentina_resolved_places
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
    'AR',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_argentina_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
