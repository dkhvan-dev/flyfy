-- Priority France destination places seed.
-- The seed covers Paris and Ile-de-France, Loire, Normandy, Brittany, the Atlantic coast, Occitanie, Burgundy, Alsace, Champagne, Provence, the Riviera, and the Alps.

DROP TABLE IF EXISTS seed_france_resolved_places;
DROP TABLE IF EXISTS seed_france_priority_places;

CREATE TEMP TABLE seed_france_priority_places (
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

INSERT INTO seed_france_priority_places (
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
    ('eiffel-tower', 'paris', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Эйфелева башня', 'Eiffel Tower', 'Эйфель мұнарасы', 48.85837000, 2.29448100, 'Eiffel Tower Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Eiffel Tower Paris.jpg'),
    ('louvre-museum', 'paris', 'MUSEUM', 4, 'HOURS', 4.8, 'Лувр', 'Louvre Museum', 'Лувр музейі', 48.86061100, 2.33764400, 'Louvre Museum Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Louvre Museum Wikimedia Commons.jpg'),
    ('notre-dame-cathedral', 'paris', 'TEMPLE', 2, 'HOURS', 4.8, 'Собор Парижской Богоматери', 'Notre-Dame Cathedral', 'Нотр-Дам соборы', 48.85296800, 2.34990200, 'Notre-Dame Cathedral Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Notre Dame de Paris 2013-07-24.jpg'),
    ('musee-d-orsay', 'paris', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Орсе', 'Musee d''Orsay', 'Орсе музейі', 48.85996100, 2.32656100, 'Musee d Orsay Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Musee dOrsay Paris.jpg'),
    ('luxembourg-gardens', 'paris', 'PARK', 2, 'HOURS', 4.7, 'Люксембургский сад', 'Luxembourg Gardens', 'Люксембург бағы', 48.84622200, 2.33716000, 'Luxembourg Gardens Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Jardin du Luxembourg Paris.jpg'),
    ('sainte-chapelle', 'paris', 'TEMPLE', 1, 'HOURS', 4.8, 'Сент-Шапель', 'Sainte-Chapelle', 'Сент-Шапель', 48.85540000, 2.34500000, 'Sainte-Chapelle Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Sainte Chapelle Paris.jpg'),
    ('sacre-coeur-basilica', 'paris', 'TEMPLE', 2, 'HOURS', 4.7, 'Базилика Сакре-Кёр', 'Sacre-Coeur Basilica', 'Сакре-Кер базиликасы', 48.88670000, 2.34310000, 'Sacre Coeur Basilica Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Sacre Coeur Paris.jpg'),
    ('centre-pompidou', 'paris', 'MUSEUM', 3, 'HOURS', 4.6, 'Центр Помпиду', 'Centre Pompidou', 'Помпиду орталығы', 48.86060000, 2.35220000, 'Centre Pompidou Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Centre Georges Pompidou Paris.jpg'),
    ('jardin-des-plantes-paris', 'paris', 'PARK', 2, 'HOURS', 4.6, 'Сад растений Парижа', 'Jardin des Plantes Paris', 'Париж өсімдіктер бағы', 48.84300000, 2.35900000, 'Jardin des Plantes Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Jardin des Plantes Paris.jpg'),
    ('marche-des-enfants-rouges', 'paris', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Марше-де-Анфан-Руж', 'Marche des Enfants Rouges', 'Анфан-Руж базары', 48.86290000, 2.36190000, 'Marche des Enfants Rouges Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Marche des Enfants Rouges Paris.jpg'),
    ('galeries-lafayette-haussmann', 'paris', 'SHOPPING', 2, 'HOURS', 4.5, 'Galeries Lafayette Haussmann', 'Galeries Lafayette Haussmann', 'Galeries Lafayette Haussmann', 48.87210000, 2.33220000, 'Galeries Lafayette Haussmann Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Galeries Lafayette Haussmann.jpg'),
    ('bateaux-mouches-seine-cruises', 'paris', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Круизы Bateaux Mouches по Сене', 'Bateaux Mouches Seine Cruises', 'Сенадағы Bateaux Mouches круиздері', 48.86400000, 2.31000000, 'Bateaux Mouches Seine Paris', ARRAY['paris']::text[], ARRAY['paris']::text[], 'Bateaux Mouches Paris.jpg'),

    ('palace-of-versailles', 'versailles', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Версальский дворец', 'Palace of Versailles', 'Версаль сарайы', 48.80486500, 2.12035500, 'Palace of Versailles', ARRAY['versailles']::text[], ARRAY['paris', 'versailles']::text[], 'Palace of Versailles.jpg'),
    ('gardens-of-versailles', 'versailles', 'PARK', 3, 'HOURS', 4.8, 'Сады Версаля', 'Gardens of Versailles', 'Версаль бақтары', 48.80800000, 2.11000000, 'Gardens of Versailles', ARRAY['versailles']::text[], ARRAY['paris', 'versailles']::text[], 'Gardens of Versailles.jpg'),
    ('fontainebleau-palace', 'fontainebleau', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Дворец Фонтенбло', 'Fontainebleau Palace', 'Фонтенбло сарайы', 48.40210000, 2.69950000, 'Fontainebleau Palace France', ARRAY['fontainebleau']::text[], ARRAY['paris', 'fontainebleau']::text[], 'Chateau de Fontainebleau.jpg'),
    ('fontainebleau-forest', 'fontainebleau', 'NATURE', 4, 'HOURS', 4.7, 'Лес Фонтенбло', 'Fontainebleau Forest', 'Фонтенбло орманы', 48.40400000, 2.66900000, 'Fontainebleau Forest France', ARRAY['fontainebleau']::text[], ARRAY['paris', 'fontainebleau']::text[], 'Foret de Fontainebleau.jpg'),
    ('disneyland-paris', 'disneyland-paris', 'ENTERTAINMENT', 8, 'HOURS', 4.7, 'Диснейленд Париж', 'Disneyland Paris', 'Диснейленд Париж', 48.87220000, 2.77580000, 'Disneyland Paris', ARRAY['disneyland-paris']::text[], ARRAY['paris', 'disneyland-paris']::text[], 'Disneyland Paris Castle.jpg'),
    ('walt-disney-studios-park', 'disneyland-paris', 'ENTERTAINMENT', 6, 'HOURS', 4.5, 'Парк Walt Disney Studios', 'Walt Disney Studios Park', 'Walt Disney Studios паркі', 48.86740000, 2.77940000, 'Walt Disney Studios Park Paris', ARRAY['disneyland-paris']::text[], ARRAY['paris', 'disneyland-paris']::text[], 'Walt Disney Studios Park Paris.jpg'),

    ('chambord-castle', 'loire-valley', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Шамбор', 'Chambord Castle', 'Шамбор қамалы', 47.61600000, 1.51700000, 'Chambord Castle Loire Valley', ARRAY['loire-valley']::text[], ARRAY['paris', 'loire-valley']::text[], 'Chateau de Chambord.jpg'),
    ('chenonceau-castle', 'loire-valley', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Замок Шенонсо', 'Chenonceau Castle', 'Шенонсо қамалы', 47.32490000, 1.07030000, 'Chenonceau Castle Loire Valley', ARRAY['loire-valley']::text[], ARRAY['paris', 'loire-valley']::text[], 'Chateau de Chenonceau.jpg'),
    ('villandry-gardens', 'loire-valley', 'PARK', 2, 'HOURS', 4.7, 'Сады Вилландри', 'Villandry Gardens', 'Вилландри бақтары', 47.34010000, 0.51070000, 'Villandry Gardens Loire Valley', ARRAY['loire-valley']::text[], ARRAY['loire-valley']::text[], 'Chateau de Villandry gardens.jpg'),
    ('clos-luce-museum', 'loire-valley', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Кло-Люсе', 'Clos Luce Museum', 'Кло-Люсе музейі', 47.41030000, 0.99250000, 'Clos Luce Amboise', ARRAY['loire-valley']::text[], ARRAY['loire-valley']::text[], 'Clos Luce.jpg'),

    ('mont-saint-michel-abbey', 'mont-saint-michel', 'TEMPLE', 3, 'HOURS', 4.8, 'Аббатство Мон-Сен-Мишель', 'Mont Saint-Michel Abbey', 'Мон-Сен-Мишель аббаттығы', 48.63610000, -1.51150000, 'Mont Saint-Michel Abbey', ARRAY['mont-saint-michel']::text[], ARRAY['paris', 'mont-saint-michel']::text[], 'Mont Saint Michel 3.jpg'),
    ('omaha-beach', 'normandy', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Омаха', 'Omaha Beach', 'Омаха жағажайы', 49.37000000, -0.88000000, 'Omaha Beach Normandy', ARRAY['normandy']::text[], ARRAY['paris', 'normandy']::text[], 'Omaha Beach Normandy.jpg'),
    ('d-day-museum-arromanches', 'normandy', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей высадки в Арроманше', 'D-Day Museum Arromanches', 'Арроманш D-Day музейі', 49.34060000, -0.62300000, 'D-Day Museum Arromanches', ARRAY['normandy']::text[], ARRAY['normandy']::text[], 'Arromanches D-Day Museum.jpg'),
    ('monet-house-gardens-giverny', 'normandy', 'PARK', 3, 'HOURS', 4.7, 'Дом и сады Клода Моне в Живерни', 'Claude Monet House and Gardens Giverny', 'Клод Моне үйі мен бақтары', 49.07540000, 1.53300000, 'Claude Monet House Gardens Giverny', ARRAY['normandy']::text[], ARRAY['paris', 'normandy']::text[], 'Giverny Monet Garden.jpg'),
    ('saint-malo-old-town', 'saint-malo', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый город Сен-Мало', 'Saint-Malo Old Town', 'Сен-Мало ескі қаласы', 48.64930000, -2.02570000, 'Saint-Malo Old Town', ARRAY['saint-malo']::text[], ARRAY['rennes', 'saint-malo']::text[], 'Saint-Malo intra-muros.jpg'),
    ('saint-malo-beach', 'saint-malo', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Сен-Мало', 'Saint-Malo Beach', 'Сен-Мало жағажайы', 48.65130000, -2.02100000, 'Saint-Malo Beach', ARRAY['saint-malo']::text[], ARRAY['saint-malo']::text[], 'Saint-Malo beach.jpg'),
    ('rennes-historic-centre', 'rennes', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Исторический центр Ренна', 'Rennes Historic Centre', 'Ренн тарихи орталығы', 48.11330000, -1.68000000, 'Rennes Historic Centre', ARRAY['rennes']::text[], ARRAY['rennes']::text[], 'Rennes old town.jpg'),
    ('marche-des-lices', 'rennes', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Марше-де-Лис', 'Marche des Lices', 'Лис базары', 48.11370000, -1.68440000, 'Marche des Lices Rennes', ARRAY['rennes']::text[], ARRAY['rennes']::text[], 'Marche des Lices Rennes.jpg'),
    ('les-machines-de-l-ile', 'nantes', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Машины острова Нант', 'Les Machines de l''Ile Nantes', 'Нант аралы машиналары', 47.20610000, -1.56430000, 'Les Machines de l Ile Nantes', ARRAY['nantes']::text[], ARRAY['nantes']::text[], 'Les Machines de lIle Nantes.jpg'),
    ('chateau-des-ducs-de-bretagne', 'nantes', 'MUSEUM', 3, 'HOURS', 4.6, 'Замок герцогов Бретани', 'Chateau des Ducs de Bretagne', 'Бретань герцогтары қамалы', 47.21590000, -1.54910000, 'Chateau des Ducs de Bretagne Nantes', ARRAY['nantes']::text[], ARRAY['nantes']::text[], 'Chateau des Ducs de Bretagne Nantes.jpg'),
    ('passage-pommeraye', 'nantes', 'SHOPPING', 1, 'HOURS', 4.6, 'Пассаж Поммере', 'Passage Pommeraye', 'Поммере пассажы', 47.21400000, -1.55880000, 'Passage Pommeraye Nantes', ARRAY['nantes']::text[], ARRAY['nantes']::text[], 'Passage Pommeraye Nantes.jpg'),

    ('la-cite-du-vin', 'bordeaux', 'MUSEUM', 3, 'HOURS', 4.6, 'Музей La Cite du Vin', 'La Cite du Vin', 'La Cite du Vin музейі', 44.86220000, -0.55080000, 'La Cite du Vin Bordeaux', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'La Cite du Vin Bordeaux.jpg'),
    ('place-de-la-bourse-bordeaux', 'bordeaux', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Биржи в Бордо', 'Place de la Bourse Bordeaux', 'Бордо Биржа алаңы', 44.84120000, -0.56900000, 'Place de la Bourse Bordeaux', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'Place de la Bourse Bordeaux.jpg'),
    ('miroir-d-eau-bordeaux', 'bordeaux', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Водное зеркало Бордо', 'Miroir d''Eau Bordeaux', 'Бордо су айнасы', 44.84100000, -0.56950000, 'Miroir d Eau Bordeaux', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'Miroir d eau Bordeaux.jpg'),
    ('capucins-market-bordeaux', 'bordeaux', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Капуцинов в Бордо', 'Capucins Market Bordeaux', 'Бордо Капуциндер базары', 44.83030000, -0.56860000, 'Marche des Capucins Bordeaux', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'Marche des Capucins Bordeaux.jpg'),
    ('rue-sainte-catherine', 'bordeaux', 'SHOPPING', 2, 'HOURS', 4.4, 'Улица Сент-Катрин', 'Rue Sainte-Catherine Bordeaux', 'Бордо Сент-Катрин көшесі', 44.83840000, -0.57310000, 'Rue Sainte-Catherine Bordeaux', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'Rue Sainte-Catherine Bordeaux.jpg'),
    ('dune-du-pilat', 'bordeaux', 'NATURE', 3, 'HOURS', 4.8, 'Дюна Пила', 'Dune du Pilat', 'Пила дюнасы', 44.58920000, -1.21330000, 'Dune du Pilat France', ARRAY['bordeaux']::text[], ARRAY['bordeaux']::text[], 'Dune du Pilat.jpg'),
    ('lascaux-iv', 'dordogne', 'MUSEUM', 3, 'HOURS', 4.7, 'Ласко IV', 'Lascaux IV', 'Ласко IV', 45.05390000, 1.17090000, 'Lascaux IV Dordogne', ARRAY['dordogne']::text[], ARRAY['bordeaux', 'dordogne']::text[], 'Lascaux IV.jpg'),
    ('chateau-de-castelnaud', 'dordogne', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Кастельно', 'Chateau de Castelnaud', 'Кастельно қамалы', 44.81580000, 1.14820000, 'Chateau de Castelnaud Dordogne', ARRAY['dordogne']::text[], ARRAY['dordogne']::text[], 'Chateau de Castelnaud.jpg'),
    ('jardins-de-marqueyssac', 'dordogne', 'PARK', 2, 'HOURS', 4.7, 'Сады Маркессак', 'Jardins de Marqueyssac', 'Маркессак бақтары', 44.82320000, 1.16290000, 'Jardins de Marqueyssac Dordogne', ARRAY['dordogne']::text[], ARRAY['dordogne']::text[], 'Jardins de Marqueyssac.jpg'),
    ('toulouse-capitole', 'toulouse', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Капитоль Тулузы', 'Toulouse Capitole', 'Тулуза Капитолийі', 43.60450000, 1.44390000, 'Capitole de Toulouse', ARRAY['toulouse']::text[], ARRAY['toulouse']::text[], 'Capitole de Toulouse.jpg'),
    ('cite-de-l-espace', 'toulouse', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Cite de l''Espace', 'Cite de l''Espace', 'Cite de l''Espace', 43.58610000, 1.49300000, 'Cite de l Espace Toulouse', ARRAY['toulouse']::text[], ARRAY['toulouse']::text[], 'Cite de lEspace Toulouse.jpg'),
    ('victor-hugo-market-toulouse', 'toulouse', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Виктор-Гюго в Тулузе', 'Victor Hugo Market Toulouse', 'Тулуза Виктор Гюго базары', 43.60600000, 1.44740000, 'Victor Hugo Market Toulouse', ARRAY['toulouse']::text[], ARRAY['toulouse']::text[], 'Marche Victor Hugo Toulouse.jpg'),
    ('carcassonne-medieval-city', 'carcassonne', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Средневековый город Каркассон', 'Carcassonne Medieval City', 'Каркассон ортағасырлық қаласы', 43.20670000, 2.36300000, 'Carcassonne Medieval City', ARRAY['carcassonne']::text[], ARRAY['toulouse', 'carcassonne']::text[], 'Carcassonne Medieval City.jpg'),
    ('saint-nazaire-basilica-carcassonne', 'carcassonne', 'TEMPLE', 1, 'HOURS', 4.6, 'Базилика Сен-Назер в Каркассоне', 'Saint-Nazaire Basilica Carcassonne', 'Каркассон Сен-Назер базиликасы', 43.20640000, 2.36220000, 'Saint Nazaire Basilica Carcassonne', ARRAY['carcassonne']::text[], ARRAY['carcassonne']::text[], 'Basilique Saint-Nazaire Carcassonne.jpg'),
    ('place-de-la-comedie-montpellier', 'montpellier', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Комедии в Монпелье', 'Place de la Comedie Montpellier', 'Монпелье Комедия алаңы', 43.60850000, 3.87980000, 'Place de la Comedie Montpellier', ARRAY['montpellier']::text[], ARRAY['montpellier']::text[], 'Place de la Comedie Montpellier.jpg'),
    ('jardin-des-plantes-montpellier', 'montpellier', 'PARK', 1, 'HOURS', 4.5, 'Сад растений Монпелье', 'Jardin des Plantes Montpellier', 'Монпелье өсімдіктер бағы', 43.61430000, 3.87390000, 'Jardin des Plantes Montpellier', ARRAY['montpellier']::text[], ARRAY['montpellier']::text[], 'Jardin des Plantes Montpellier.jpg'),
    ('musee-fabre', 'montpellier', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Фабра', 'Musee Fabre', 'Фабр музейі', 43.61180000, 3.88060000, 'Musee Fabre Montpellier', ARRAY['montpellier']::text[], ARRAY['montpellier']::text[], 'Musee Fabre Montpellier.jpg'),
    ('biarritz-grande-plage', 'biarritz', 'BEACH', 2, 'HOURS', 4.7, 'Гранд-Пляж Биаррица', 'Biarritz Grande Plage', 'Биарриц Гранд-Пляж', 43.48320000, -1.55860000, 'Biarritz Grande Plage', ARRAY['biarritz']::text[], ARRAY['biarritz']::text[], 'Grande Plage Biarritz.jpg'),
    ('rocher-de-la-vierge', 'biarritz', 'NATURE', 1, 'HOURS', 4.7, 'Скала Девы', 'Rocher de la Vierge', 'Қасиетті Ана жартасы', 43.48380000, -1.57060000, 'Rocher de la Vierge Biarritz', ARRAY['biarritz']::text[], ARRAY['biarritz']::text[], 'Rocher de la Vierge Biarritz.jpg'),
    ('les-halles-de-biarritz', 'biarritz', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Les Halles de Biarritz', 'Les Halles de Biarritz', 'Биарриц Les Halles базары', 43.48160000, -1.56050000, 'Les Halles de Biarritz', ARRAY['biarritz']::text[], ARRAY['biarritz']::text[], 'Les Halles de Biarritz.jpg'),
    ('lourdes-sanctuary', 'lourdes', 'TEMPLE', 3, 'HOURS', 4.8, 'Святилище Лурда', 'Lourdes Sanctuary', 'Лурд ғибадат орны', 43.09760000, -0.05830000, 'Lourdes Sanctuary France', ARRAY['lourdes']::text[], ARRAY['toulouse', 'lourdes']::text[], 'Sanctuary of Our Lady of Lourdes.jpg'),
    ('chateau-fort-lourdes', 'lourdes', 'MUSEUM', 2, 'HOURS', 4.6, 'Крепость Лурда и Пиренейский музей', 'Chateau Fort Lourdes', 'Лурд қамалы және Пиреней музейі', 43.09580000, -0.04950000, 'Chateau Fort Lourdes Musee Pyreneen', ARRAY['lourdes']::text[], ARRAY['lourdes']::text[], 'Chateau fort de Lourdes.jpg'),
    ('pic-du-midi', 'pyrenees', 'NATURE', 4, 'HOURS', 4.8, 'Пик-дю-Миди', 'Pic du Midi', 'Пик-дю-Миди', 42.93690000, 0.14260000, 'Pic du Midi de Bigorre', ARRAY['pyrenees']::text[], ARRAY['toulouse', 'lourdes', 'pyrenees']::text[], 'Pic du Midi de Bigorre.jpg'),
    ('gavarnie-cirque', 'pyrenees', 'NATURE', 5, 'HOURS', 4.8, 'Цирк Гаварни', 'Gavarnie Cirque', 'Гаварни циркі', 42.69690000, -0.00940000, 'Cirque de Gavarnie', ARRAY['pyrenees']::text[], ARRAY['lourdes', 'pyrenees']::text[], 'Cirque de Gavarnie.jpg'),

    ('basilica-fourviere', 'lyon', 'TEMPLE', 2, 'HOURS', 4.8, 'Базилика Нотр-Дам-де-Фурвьер', 'Basilica of Notre-Dame de Fourviere', 'Нотр-Дам-де-Фурвьер базиликасы', 45.76220000, 4.82280000, 'Basilica of Notre-Dame de Fourviere Lyon', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'Basilique Notre-Dame de Fourviere.jpg'),
    ('vieux-lyon', 'lyon', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый Лион', 'Vieux Lyon', 'Ескі Лион', 45.76360000, 4.82780000, 'Vieux Lyon France', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'Vieux Lyon.jpg'),
    ('musee-des-confluences', 'lyon', 'MUSEUM', 3, 'HOURS', 4.6, 'Музей слияний', 'Musee des Confluences', 'Конфлюанс музейі', 45.73350000, 4.81860000, 'Musee des Confluences Lyon', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'Musee des Confluences Lyon.jpg'),
    ('parc-de-la-tete-d-or', 'lyon', 'PARK', 2, 'HOURS', 4.7, 'Парк Тет-д''Ор', 'Parc de la Tete d''Or', 'Тет-д''Ор паркі', 45.77720000, 4.85530000, 'Parc de la Tete d Or Lyon', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'Parc de la Tete dOr Lyon.jpg'),
    ('les-halles-de-lyon-paul-bocuse', 'lyon', 'FOOD', 2, 'HOURS', 4.6, 'Les Halles de Lyon Paul Bocuse', 'Les Halles de Lyon Paul Bocuse', 'Les Halles de Lyon Paul Bocuse', 45.76230000, 4.85050000, 'Les Halles de Lyon Paul Bocuse', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'Les Halles de Lyon Paul Bocuse.jpg'),
    ('la-part-dieu', 'lyon', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ La Part-Dieu', 'La Part-Dieu Shopping Centre', 'La Part-Dieu сауда орталығы', 45.76070000, 4.85690000, 'La Part Dieu Lyon', ARRAY['lyon']::text[], ARRAY['lyon']::text[], 'La Part Dieu Lyon.jpg'),
    ('palace-of-the-dukes-dijon', 'dijon', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец герцогов Бургундских', 'Palace of the Dukes Dijon', 'Дижон герцогтар сарайы', 47.32110000, 5.04150000, 'Palace of the Dukes Dijon', ARRAY['dijon']::text[], ARRAY['lyon', 'dijon']::text[], 'Palace of the Dukes of Burgundy Dijon.jpg'),
    ('dijon-market-hall', 'dijon', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Дижона', 'Dijon Market Hall', 'Дижон базары', 47.32310000, 5.03850000, 'Dijon Market Hall', ARRAY['dijon']::text[], ARRAY['dijon']::text[], 'Les Halles Dijon.jpg'),
    ('hospices-de-beaune', 'beaune', 'MUSEUM', 2, 'HOURS', 4.8, 'Оспис-де-Бон', 'Hospices de Beaune', 'Бон госпиталі', 47.02220000, 4.83780000, 'Hospices de Beaune', ARRAY['beaune']::text[], ARRAY['lyon', 'dijon', 'beaune']::text[], 'Hospices de Beaune.jpg'),
    ('burgundy-wine-route', 'beaune', 'FOOD', 3, 'HOURS', 4.7, 'Бургундский винный маршрут', 'Burgundy Wine Route', 'Бургундия шарап жолы', 47.02600000, 4.84000000, 'Burgundy Wine Route Beaune', ARRAY['beaune']::text[], ARRAY['dijon', 'beaune']::text[], 'Burgundy vineyards Beaune.jpg'),
    ('strasbourg-cathedral', 'strasbourg', 'TEMPLE', 2, 'HOURS', 4.8, 'Страсбургский собор', 'Strasbourg Cathedral', 'Страсбург соборы', 48.58190000, 7.75060000, 'Strasbourg Cathedral', ARRAY['strasbourg']::text[], ARRAY['strasbourg']::text[], 'Strasbourg Cathedral.jpg'),
    ('petite-france-strasbourg', 'strasbourg', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Квартал Маленькая Франция', 'Petite France Strasbourg', 'Страсбург Кіші Франция кварталы', 48.58110000, 7.74060000, 'Petite France Strasbourg', ARRAY['strasbourg']::text[], ARRAY['strasbourg']::text[], 'Petite France Strasbourg.jpg'),
    ('colmar-old-town', 'colmar', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Кольмара', 'Colmar Old Town', 'Кольмар ескі қаласы', 48.07780000, 7.35800000, 'Colmar Old Town', ARRAY['colmar']::text[], ARRAY['strasbourg', 'colmar']::text[], 'Colmar Old Town.jpg'),
    ('unterlinden-museum', 'colmar', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Унтерлинден', 'Unterlinden Museum', 'Унтерлинден музейі', 48.08050000, 7.35590000, 'Unterlinden Museum Colmar', ARRAY['colmar']::text[], ARRAY['colmar']::text[], 'Unterlinden Museum Colmar.jpg'),
    ('reims-cathedral', 'reims', 'TEMPLE', 2, 'HOURS', 4.8, 'Реймсский собор', 'Reims Cathedral', 'Реймс соборы', 49.25390000, 4.03470000, 'Reims Cathedral', ARRAY['reims']::text[], ARRAY['paris', 'reims']::text[], 'Reims Cathedral.jpg'),
    ('champagne-houses-reims', 'reims', 'FOOD', 3, 'HOURS', 4.6, 'Шампанские дома Реймса', 'Champagne Houses Reims', 'Реймс шампан үйлері', 49.24600000, 4.04900000, 'Champagne Houses Reims', ARRAY['reims']::text[], ARRAY['reims']::text[], 'Champagne cellars Reims.jpg'),
    ('lille-grand-place', 'lille', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Гран-Плас Лилля', 'Lille Grand Place', 'Лилль Гран-Плас алаңы', 50.63720000, 3.06330000, 'Lille Grand Place', ARRAY['lille']::text[], ARRAY['lille']::text[], 'Grand Place Lille.jpg'),
    ('palais-des-beaux-arts-lille', 'lille', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец изящных искусств Лилля', 'Palais des Beaux-Arts Lille', 'Лилль бейнелеу өнері сарайы', 50.63060000, 3.06220000, 'Palais des Beaux Arts Lille', ARRAY['lille']::text[], ARRAY['lille']::text[], 'Palais des Beaux Arts Lille.jpg'),
    ('euralille', 'lille', 'SHOPPING', 2, 'HOURS', 4.4, 'Euralille', 'Euralille', 'Euralille', 50.63900000, 3.07610000, 'Euralille Shopping Centre', ARRAY['lille']::text[], ARRAY['lille']::text[], 'Euralille.jpg'),

    ('nice-promenade-des-anglais', 'nice', 'BEACH', 2, 'HOURS', 4.8, 'Английская набережная в Ницце', 'Nice Promenade des Anglais', 'Ницца Английская жағалауы', 43.69510000, 7.26570000, 'Promenade des Anglais Nice', ARRAY['nice']::text[], ARRAY['nice']::text[], 'Promenade des Anglais Nice.jpg'),
    ('castle-hill-nice', 'nice', 'PARK', 2, 'HOURS', 4.7, 'Замковая гора Ниццы', 'Castle Hill Nice', 'Ницца Қамал төбесі', 43.69590000, 7.28080000, 'Castle Hill Nice', ARRAY['nice']::text[], ARRAY['nice']::text[], 'Castle Hill Nice.jpg'),
    ('cours-saleya-market', 'nice', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Кур-Салея', 'Cours Saleya Market', 'Кур-Салея базары', 43.69550000, 7.27620000, 'Cours Saleya Market Nice', ARRAY['nice']::text[], ARRAY['nice']::text[], 'Cours Saleya Nice.jpg'),
    ('matisse-museum-nice', 'nice', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Матисса в Ницце', 'Matisse Museum Nice', 'Ницца Матисс музейі', 43.71940000, 7.27610000, 'Matisse Museum Nice', ARRAY['nice']::text[], ARRAY['nice']::text[], 'Matisse Museum Nice.jpg'),
    ('palais-des-festivals-cannes', 'cannes', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Дворец фестивалей в Каннах', 'Palais des Festivals Cannes', 'Канны фестивальдер сарайы', 43.55080000, 7.01740000, 'Palais des Festivals Cannes', ARRAY['cannes']::text[], ARRAY['nice', 'cannes']::text[], 'Palais des Festivals Cannes.jpg'),
    ('la-croisette-cannes', 'cannes', 'BEACH', 2, 'HOURS', 4.7, 'Набережная Круазетт', 'La Croisette Cannes', 'Канны Круазетт жағалауы', 43.55130000, 7.02850000, 'La Croisette Cannes', ARRAY['cannes']::text[], ARRAY['cannes']::text[], 'La Croisette Cannes.jpg'),
    ('antibes-old-town', 'antibes', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый город Антиба', 'Antibes Old Town', 'Антиб ескі қаласы', 43.58170000, 7.12780000, 'Antibes Old Town', ARRAY['antibes']::text[], ARRAY['nice', 'antibes']::text[], 'Antibes Old Town.jpg'),
    ('picasso-museum-antibes', 'antibes', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Пикассо в Антибе', 'Picasso Museum Antibes', 'Антиб Пикассо музейі', 43.58130000, 7.12860000, 'Picasso Museum Antibes', ARRAY['antibes']::text[], ARRAY['antibes']::text[], 'Musee Picasso Antibes.jpg'),
    ('saint-tropez-old-port', 'saint-tropez', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый порт Сен-Тропе', 'Saint-Tropez Old Port', 'Сен-Тропе ескі порты', 43.27150000, 6.63980000, 'Saint-Tropez Old Port', ARRAY['saint-tropez']::text[], ARRAY['nice', 'saint-tropez']::text[], 'Saint-Tropez Old Port.jpg'),
    ('pampelonne-beach', 'saint-tropez', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Пампелон', 'Pampelonne Beach', 'Пампелон жағажайы', 43.22290000, 6.66520000, 'Pampelonne Beach Saint Tropez', ARRAY['saint-tropez']::text[], ARRAY['saint-tropez']::text[], 'Pampelonne Beach.jpg'),
    ('old-port-of-marseille', 'marseille', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый порт Марселя', 'Old Port of Marseille', 'Марсель ескі порты', 43.29500000, 5.37400000, 'Old Port of Marseille', ARRAY['marseille']::text[], ARRAY['marseille']::text[], 'Vieux Port Marseille.jpg'),
    ('mucem-marseille', 'marseille', 'MUSEUM', 3, 'HOURS', 4.6, 'Mucem Marseille', 'Mucem Marseille', 'Mucem Marseille', 43.29670000, 5.36100000, 'Mucem Marseille', ARRAY['marseille']::text[], ARRAY['marseille']::text[], 'Mucem Marseille.jpg'),
    ('notre-dame-de-la-garde', 'marseille', 'TEMPLE', 2, 'HOURS', 4.8, 'Нотр-Дам-де-ла-Гард', 'Notre-Dame de la Garde', 'Нотр-Дам-де-ла-Гард', 43.28400000, 5.37100000, 'Notre-Dame de la Garde Marseille', ARRAY['marseille']::text[], ARRAY['marseille']::text[], 'Notre Dame de la Garde Marseille.jpg'),
    ('calanques-national-park', 'marseille', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Каланки', 'Calanques National Park', 'Каланк ұлттық паркі', 43.21400000, 5.43700000, 'Calanques National Park Marseille', ARRAY['marseille']::text[], ARRAY['marseille']::text[], 'Calanques National Park.jpg'),
    ('terrasses-du-port', 'marseille', 'SHOPPING', 2, 'HOURS', 4.4, 'Les Terrasses du Port', 'Les Terrasses du Port', 'Les Terrasses du Port', 43.31120000, 5.36520000, 'Les Terrasses du Port Marseille', ARRAY['marseille']::text[], ARRAY['marseille']::text[], 'Les Terrasses du Port Marseille.jpg'),
    ('cours-mirabeau', 'aix-en-provence', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Кур Мирабо', 'Cours Mirabeau', 'Мирабо даңғылы', 43.52650000, 5.44900000, 'Cours Mirabeau Aix-en-Provence', ARRAY['aix-en-provence']::text[], ARRAY['marseille', 'aix-en-provence']::text[], 'Cours Mirabeau Aix.jpg'),
    ('atelier-cezanne', 'aix-en-provence', 'MUSEUM', 2, 'HOURS', 4.5, 'Ателье Сезанна', 'Atelier Cezanne', 'Сезанн шеберханасы', 43.53620000, 5.44640000, 'Atelier Cezanne Aix-en-Provence', ARRAY['aix-en-provence']::text[], ARRAY['aix-en-provence']::text[], 'Atelier Cezanne Aix.jpg'),
    ('palais-des-papes-avignon', 'avignon', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Папский дворец в Авиньоне', 'Palais des Papes Avignon', 'Авиньон Папалар сарайы', 43.95080000, 4.80760000, 'Palais des Papes Avignon', ARRAY['avignon']::text[], ARRAY['marseille', 'avignon']::text[], 'Palais des Papes Avignon.jpg'),
    ('pont-d-avignon', 'avignon', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Мост Сен-Бенезе', 'Pont d''Avignon', 'Авиньон көпірі', 43.95390000, 4.80500000, 'Pont d Avignon', ARRAY['avignon']::text[], ARRAY['avignon']::text[], 'Pont d Avignon.jpg'),
    ('arles-roman-amphitheatre', 'arles', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Римский амфитеатр Арля', 'Arles Roman Amphitheatre', 'Арль Рим амфитеатры', 43.67760000, 4.63070000, 'Arles Roman Amphitheatre', ARRAY['arles']::text[], ARRAY['marseille', 'arles']::text[], 'Arles Amphitheatre.jpg'),
    ('fondation-vincent-van-gogh-arles', 'arles', 'MUSEUM', 2, 'HOURS', 4.5, 'Фонд Винсента ван Гога в Арле', 'Fondation Vincent van Gogh Arles', 'Арль Винсент ван Гог қоры', 43.67700000, 4.62790000, 'Fondation Vincent van Gogh Arles', ARRAY['arles']::text[], ARRAY['arles']::text[], 'Fondation Vincent van Gogh Arles.jpg'),
    ('verdon-gorge', 'verdon', 'NATURE', 5, 'HOURS', 4.8, 'Вердонское ущелье', 'Verdon Gorge', 'Вердон шатқалы', 43.73900000, 6.35000000, 'Verdon Gorge France', ARRAY['verdon']::text[], ARRAY['nice', 'aix-en-provence', 'verdon']::text[], 'Gorges du Verdon.jpg'),
    ('aiguille-du-midi', 'chamonix', 'NATURE', 4, 'HOURS', 4.8, 'Эгюий-дю-Миди', 'Aiguille du Midi', 'Эгюий-дю-Миди', 45.87910000, 6.88700000, 'Aiguille du Midi Chamonix', ARRAY['chamonix']::text[], ARRAY['lyon', 'chamonix']::text[], 'Aiguille du Midi.jpg'),
    ('mer-de-glace', 'chamonix', 'NATURE', 3, 'HOURS', 4.7, 'Ледник Мер-де-Глас', 'Mer de Glace', 'Мер-де-Глас мұздығы', 45.91810000, 6.93060000, 'Mer de Glace Chamonix', ARRAY['chamonix']::text[], ARRAY['chamonix']::text[], 'Mer de Glace.jpg'),
    ('annecy-old-town', 'annecy', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый город Анси', 'Annecy Old Town', 'Анси ескі қаласы', 45.89920000, 6.12890000, 'Annecy Old Town', ARRAY['annecy']::text[], ARRAY['lyon', 'annecy']::text[], 'Annecy Old Town.jpg'),
    ('lake-annecy', 'annecy', 'BEACH', 3, 'HOURS', 4.8, 'Озеро Анси', 'Lake Annecy', 'Анси көлі', 45.85900000, 6.15700000, 'Lake Annecy France', ARRAY['annecy']::text[], ARRAY['annecy']::text[], 'Lake Annecy.jpg');

CREATE TEMP TABLE seed_france_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-france-place:' || seed.slug) AS place_hash,
        md5('id-france-media:' || seed.slug) AS media_hash
    FROM seed_france_priority_places seed
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
    ARRAY['france', city_id, slug, lower(category), 'france-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Франции: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'France tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Франция туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'FR',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'EUR',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_france_resolved_places
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
FROM seed_france_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_france_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_france_resolved_places
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
FROM seed_france_resolved_places seed
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
FROM seed_france_resolved_places
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
    'FR',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_france_resolved_places
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
    'FR',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_france_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
