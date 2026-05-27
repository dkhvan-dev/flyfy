-- Priority Switzerland destination attractions seed.
-- The seed covers Zurich, Central Switzerland, Basel, Bernese Oberland, Lake Geneva, Valais, Ticino, and Graubunden.

DROP TABLE IF EXISTS seed_switzerland_resolved_attractions;
DROP TABLE IF EXISTS seed_switzerland_priority_attractions;

CREATE TEMP TABLE seed_switzerland_priority_attractions (
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

INSERT INTO seed_switzerland_priority_attractions (
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
    ('grossmuenster', 'zurich', 'TEMPLE', 1, 'HOURS', 4.7, 'Гроссмюнстер', 'Grossmuenster', 'Гроссмюнстер', 47.37000000, 8.54410000, 'Grossmuenster Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('fraumuenster', 'zurich', 'TEMPLE', 1, 'HOURS', 4.6, 'Фраумюнстер', 'Fraumuenster', 'Фраумюнстер', 47.36960000, 8.54190000, 'Fraumuenster Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('lindenhof-zurich', 'zurich', 'PARK', 1, 'HOURS', 4.7, 'Линденхоф', 'Lindenhof Zurich', 'Линденхоф', 47.37310000, 8.54060000, 'Lindenhof Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('lake-zurich-promenade', 'zurich', 'BEACH', 2, 'HOURS', 4.8, 'Променад Цюрихского озера', 'Lake Zurich Promenade', 'Цюрих көлі серуені', 47.35990000, 8.54660000, 'Lake Zurich Promenade', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Zürich Switzerland-Citiview-from-Quai-Bridge-01.jpg'),
    ('uetliberg', 'zurich', 'NATURE', 3, 'HOURS', 4.8, 'Утлиберг', 'Uetliberg', 'Утлиберг', 47.34990000, 8.49190000, 'Uetliberg Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Zürich Switzerland-Citiview-from-Quai-Bridge-01.jpg'),
    ('swiss-national-museum-zurich', 'zurich', 'MUSEUM', 2, 'HOURS', 4.7, 'Швейцарский национальный музей', 'National Museum Zurich', 'Швейцария ұлттық музейі', 47.37910000, 8.54050000, 'National Museum Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('kunsthaus-zurich', 'zurich', 'MUSEUM', 2, 'HOURS', 4.7, 'Кунстхаус Цюрих', 'Kunsthaus Zurich', 'Кунстхаус Цюрих', 47.37020000, 8.54810000, 'Kunsthaus Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('bahnhofstrasse-zurich', 'zurich', 'SHOPPING', 2, 'HOURS', 4.6, 'Банхофштрассе', 'Bahnhofstrasse', 'Банхофштрассе', 47.37200000, 8.53800000, 'Bahnhofstrasse Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('burkliplatz-weekly-market', 'zurich', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Бюрклиплац', 'Burkliplatz Weekly Market', 'Бюрклиплац базары', 47.36670000, 8.53960000, 'Burkliplatz Weekly Market Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('markthalle-im-viadukt', 'zurich', 'FOOD', 2, 'HOURS', 4.5, 'Марктхалле-им-Виадукт', 'Markthalle im Viadukt', 'Виадукттағы Марктхалле', 47.38690000, 8.52280000, 'Markthalle im Viadukt Zurich', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),
    ('zoo-zurich', 'zurich', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Зоопарк Цюриха', 'Zurich Zoo', 'Цюрих хайуанаттар бағы', 47.38500000, 8.57300000, 'Zurich Zoo', ARRAY['zurich']::text[], ARRAY['zurich']::text[], 'Altstadt Zürich 2015.jpg'),

    ('chapel-bridge-water-tower', 'lucerne', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Часовенный мост и Водонапорная башня', 'Chapel Bridge', 'Капелльбрюкке көпірі', 47.05160000, 8.30730000, 'Chapel Bridge Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne', 'zurich']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('lion-monument-lucerne', 'lucerne', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Памятник льву', 'Lion Monument', 'Арыстан ескерткіші', 47.05830000, 8.31060000, 'Lion Monument Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne', 'zurich']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('lake-lucerne', 'lucerne', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Люцерн', 'Lake Lucerne', 'Люцерн көлі', 47.00000000, 8.40000000, 'Lake Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne', 'zurich']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('swiss-museum-of-transport', 'lucerne', 'MUSEUM', 3, 'HOURS', 4.7, 'Швейцарский музей транспорта', 'Swiss Museum of Transport', 'Швейцария көлік музейі', 47.05200000, 8.33730000, 'Swiss Museum of Transport Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('lucerne-weekly-market', 'lucerne', 'MARKET', 1, 'HOURS', 4.5, 'Еженедельный рынок Люцерна', 'Lucerne Weekly Market', 'Люцерн апталық базары', 47.05200000, 8.30670000, 'Lucerne Weekly Market Reussquai', ARRAY['lucerne']::text[], ARRAY['lucerne']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('mall-of-switzerland', 'lucerne', 'SHOPPING', 2, 'HOURS', 4.4, 'Молл оф Свитцерленд', 'Mall of Switzerland', 'Mall of Switzerland', 47.09150000, 8.36370000, 'Mall of Switzerland Ebikon', ARRAY['lucerne']::text[], ARRAY['lucerne']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('mount-pilatus', 'lucerne', 'NATURE', 5, 'HOURS', 4.8, 'Гора Пилатус', 'Mount Pilatus', 'Пилатус тауы', 46.97930000, 8.25340000, 'Mount Pilatus Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne', 'zurich']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),
    ('buergenstock-funicular', 'lucerne', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Катамаран и фуникулер Бюргеншток', 'Burgenstock Catamaran and Funicular', 'Бюргеншток катамараны және фуникулері', 47.00130000, 8.38260000, 'Burgenstock Catamaran Funicular Lake Lucerne', ARRAY['lucerne']::text[], ARRAY['lucerne']::text[], 'Lucerne Pilatus Lake panoramic 1180662.jpg'),

    ('basel-minster', 'basel', 'TEMPLE', 1, 'HOURS', 4.7, 'Базельский собор', 'Basel Minster', 'Базель соборы', 47.55650000, 7.59240000, 'Basel Minster', ARRAY['basel']::text[], ARRAY['basel', 'zurich']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('basel-town-hall', 'basel', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Ратуша Базеля', 'Basel Town Hall', 'Базель ратушасы', 47.55810000, 7.58790000, 'Basel Town Hall Rathaus', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('kunstmuseum-basel', 'basel', 'MUSEUM', 2, 'HOURS', 4.7, 'Художественный музей Базеля', 'Kunstmuseum Basel', 'Базель өнер музейі', 47.55450000, 7.59460000, 'Kunstmuseum Basel', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('fondation-beyeler', 'basel', 'MUSEUM', 2, 'HOURS', 4.7, 'Фонд Бейелер', 'Fondation Beyeler', 'Бейелер қоры', 47.58880000, 7.65000000, 'Fondation Beyeler Basel', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('markthalle-basel', 'basel', 'FOOD', 2, 'HOURS', 4.5, 'Марктхалле Базель', 'Markthalle Basel', 'Базель Марктхалле', 47.54990000, 7.58710000, 'Markthalle Basel', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('stuecki-park-basel', 'basel', 'SHOPPING', 2, 'HOURS', 4.3, 'Штюки Парк Базель', 'Stuecki Park Basel', 'Stuecki Park Basel', 47.58030000, 7.60000000, 'Stuecki Park Basel', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('zoo-basel', 'basel', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Зоопарк Базеля', 'Basel Zoo', 'Базель хайуанаттар бағы', 47.54730000, 7.58120000, 'Basel Zoo', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),
    ('rhine-ferries-basel', 'basel', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Рейнские паромы Базеля', 'Basel Rhine Ferries', 'Базель Рейн паромдары', 47.55950000, 7.59290000, 'Basel Rhine Ferries', ARRAY['basel']::text[], ARRAY['basel']::text[], 'Basel - Münsterpfalz1.jpg'),

    ('rhine-falls', 'schaffhausen', 'NATURE', 2, 'HOURS', 4.8, 'Рейнский водопад', 'Rhine Falls', 'Рейн сарқырамасы', 47.67790000, 8.61520000, 'Rhine Falls Schaffhausen', ARRAY['schaffhausen', 'zurich']::text[], ARRAY['zurich', 'schaffhausen']::text[], 'Rheinfall Panorama revised.jpg'),
    ('schloss-laufen-rhine-falls', 'schaffhausen', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Лауфен у Рейнского водопада', 'Schloss Laufen Rhine Falls', 'Рейн сарқырамасындағы Лауфен қамалы', 47.67690000, 8.61580000, 'Schloss Laufen Rhine Falls', ARRAY['schaffhausen']::text[], ARRAY['zurich', 'schaffhausen']::text[], 'Rheinfall Panorama revised.jpg'),
    ('adventure-park-rhine-falls', 'schaffhausen', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Веревочный парк у Рейнского водопада', 'Adventure Park Rhine Falls', 'Рейн сарқырамасы adventure park', 47.67740000, 8.61360000, 'Adventure Park Rhine Falls', ARRAY['schaffhausen']::text[], ARRAY['zurich', 'schaffhausen']::text[], 'Rheinfall Panorama revised.jpg'),
    ('munot-fortress', 'schaffhausen', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Крепость Мунот', 'Munot Fortress', 'Мунот қамалы', 47.69600000, 8.63780000, 'Munot Fortress Schaffhausen', ARRAY['schaffhausen']::text[], ARRAY['schaffhausen']::text[], 'Rheinfall Panorama revised.jpg'),
    ('rhybadi-schaffhausen', 'schaffhausen', 'BEACH', 2, 'HOURS', 4.5, 'Рибади', 'Rhybadi Schaffhausen', 'Шаффхаузен Рибади', 47.69740000, 8.63470000, 'Rhybadi Schaffhausen Rhine', ARRAY['schaffhausen']::text[], ARRAY['schaffhausen']::text[], 'Rheinfall Panorama revised.jpg'),

    ('bern-old-city', 'bern', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый город Берна', 'Bern Old City', 'Берн ескі қаласы', 46.94810000, 7.44740000, 'Bern Old City', ARRAY['bern']::text[], ARRAY['bern', 'zurich']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('zytglogge-clock-tower', 'bern', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Часовая башня Цитглогге', 'Zytglogge Clock Tower', 'Цитглогге сағат мұнарасы', 46.94800000, 7.44740000, 'Zytglogge Bern', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('bern-minster', 'bern', 'TEMPLE', 1, 'HOURS', 4.7, 'Бернский собор', 'Bern Minster', 'Берн соборы', 46.94720000, 7.45110000, 'Bern Minster', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('bearpark-bern', 'bern', 'PARK', 1, 'HOURS', 4.6, 'Медвежий парк Берна', 'BearPark Bern', 'Берн аю паркі', 46.94700000, 7.45980000, 'BearPark Bern', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('zentrum-paul-klee', 'bern', 'MUSEUM', 2, 'HOURS', 4.6, 'Центр Пауля Клее', 'Zentrum Paul Klee', 'Пауль Клее орталығы', 46.94890000, 7.47400000, 'Zentrum Paul Klee Bern', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('bern-weekly-market', 'bern', 'MARKET', 1, 'HOURS', 4.5, 'Еженедельный рынок Берна', 'Bern Weekly Market', 'Берн апталық базары', 46.94890000, 7.44740000, 'Bern Weekly Market', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('westside-bern', 'bern', 'SHOPPING', 2, 'HOURS', 4.4, 'Вестсайд Берн', 'Westside Shopping and Leisure Center', 'Westside Bern', 46.94310000, 7.37440000, 'Westside Bern', ARRAY['bern']::text[], ARRAY['bern']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),

    ('harder-kulm', 'interlaken', 'NATURE', 3, 'HOURS', 4.8, 'Хардер Кульм', 'Harder Kulm', 'Хардер Кульм', 46.69760000, 7.85180000, 'Harder Kulm Interlaken', ARRAY['interlaken']::text[], ARRAY['interlaken', 'bern', 'zurich']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('hoeheweg-interlaken', 'interlaken', 'PARK', 1, 'HOURS', 4.5, 'Променад Хёэевег', 'Hoeheweg Interlaken', 'Интерлакен Hoeheweg', 46.68630000, 7.85940000, 'Hoeheweg Interlaken', ARRAY['interlaken']::text[], ARRAY['interlaken']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('lake-thun', 'interlaken', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Тун', 'Lake Thun', 'Тун көлі', 46.70000000, 7.71670000, 'Lake Thun Interlaken', ARRAY['interlaken', 'thun']::text[], ARRAY['interlaken', 'bern', 'thun']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('paragliding-interlaken', 'interlaken', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Параглайдинг в Интерлакене', 'Paragliding Interlaken', 'Интерлакен параглайдингі', 46.68630000, 7.86320000, 'Paragliding Interlaken', ARRAY['interlaken']::text[], ARRAY['interlaken']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('st-beatus-caves', 'interlaken', 'NATURE', 2, 'HOURS', 4.6, 'Пещеры Святого Беата', 'St Beatus Caves', 'Әулие Беат үңгірлері', 46.68360000, 7.77700000, 'St Beatus Caves Lake Thun', ARRAY['interlaken', 'thun']::text[], ARRAY['interlaken', 'thun']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),

    ('grindelwald-first', 'grindelwald', 'NATURE', 5, 'HOURS', 4.8, 'Гриндельвальд-Фирст', 'Grindelwald-First', 'Гриндельвальд-Фирст', 46.65950000, 8.05340000, 'Grindelwald First', ARRAY['grindelwald', 'interlaken']::text[], ARRAY['interlaken', 'grindelwald']::text[], 'Jungfreijoch.jpg'),
    ('bachalpsee', 'grindelwald', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Бахальпзее', 'Lake Bachalpsee', 'Бахальпзее көлі', 46.66900000, 8.02450000, 'Bachalpsee Grindelwald', ARRAY['grindelwald']::text[], ARRAY['grindelwald', 'interlaken']::text[], 'Jungfreijoch.jpg'),
    ('first-cliff-walk', 'grindelwald', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'First Cliff Walk', 'First Cliff Walk', 'First Cliff Walk', 46.65970000, 8.05320000, 'First Cliff Walk Grindelwald', ARRAY['grindelwald']::text[], ARRAY['grindelwald']::text[], 'Jungfreijoch.jpg'),
    ('grindelwald-glacier-canyon', 'grindelwald', 'NATURE', 2, 'HOURS', 4.6, 'Ледниковое ущелье Гриндельвальда', 'Grindelwald Glacier Canyon', 'Гриндельвальд мұздық шатқалы', 46.61950000, 8.03170000, 'Grindelwald Glacier Canyon', ARRAY['grindelwald']::text[], ARRAY['grindelwald']::text[], 'Jungfreijoch.jpg'),
    ('pfingstegg', 'grindelwald', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Пфингстегг', 'Pfingstegg', 'Пфингстегг', 46.63010000, 8.05030000, 'Pfingstegg Grindelwald', ARRAY['grindelwald']::text[], ARRAY['grindelwald']::text[], 'Jungfreijoch.jpg'),

    ('lauterbrunnen-valley', 'lauterbrunnen', 'NATURE', 3, 'HOURS', 4.9, 'Долина Лаутербруннен', 'Lauterbrunnen Valley', 'Лаутербруннен аңғары', 46.59370000, 7.90910000, 'Lauterbrunnen Valley', ARRAY['lauterbrunnen', 'interlaken']::text[], ARRAY['interlaken', 'lauterbrunnen']::text[], 'Jungfreijoch.jpg'),
    ('staubbach-falls', 'lauterbrunnen', 'NATURE', 1, 'HOURS', 4.8, 'Водопад Штауббах', 'Staubbach Falls', 'Штауббах сарқырамасы', 46.58970000, 7.90750000, 'Staubbach Falls Lauterbrunnen', ARRAY['lauterbrunnen']::text[], ARRAY['lauterbrunnen', 'interlaken']::text[], 'Jungfreijoch.jpg'),
    ('trummelbach-falls', 'lauterbrunnen', 'NATURE', 2, 'HOURS', 4.8, 'Водопады Трюммельбах', 'Trummelbach Falls', 'Трюммельбах сарқырамалары', 46.57050000, 7.91190000, 'Trummelbach Falls Lauterbrunnen', ARRAY['lauterbrunnen']::text[], ARRAY['lauterbrunnen', 'interlaken']::text[], 'Jungfreijoch.jpg'),
    ('schilthorn-piz-gloria', 'lauterbrunnen', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Шильтхорн Пиц Глория', 'Schilthorn Piz Gloria', 'Шильтхорн Пиц Глория', 46.55740000, 7.83560000, 'Schilthorn Piz Gloria', ARRAY['lauterbrunnen']::text[], ARRAY['interlaken', 'lauterbrunnen']::text[], 'Jungfreijoch.jpg'),

    ('jungfraujoch-top-of-europe', 'jungfraujoch', 'NATURE', 6, 'HOURS', 4.9, 'Юнгфрауйох Top of Europe', 'Jungfraujoch Top of Europe', 'Юнгфрауйох Top of Europe', 46.54750000, 7.98010000, 'Jungfraujoch Top of Europe', ARRAY['jungfraujoch', 'grindelwald', 'lauterbrunnen']::text[], ARRAY['interlaken', 'grindelwald', 'lauterbrunnen']::text[], 'Jungfreijoch.jpg'),
    ('sphinx-observation-terrace', 'jungfraujoch', 'NATURE', 1, 'HOURS', 4.8, 'Смотровая терраса Сфинкс', 'Sphinx Observation Terrace', 'Сфинкс бақылау террасасы', 46.54740000, 7.98530000, 'Sphinx Observation Terrace Jungfraujoch', ARRAY['jungfraujoch']::text[], ARRAY['jungfraujoch', 'interlaken']::text[], 'Jungfreijoch.jpg'),
    ('ice-palace-jungfraujoch', 'jungfraujoch', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Ледовый дворец', 'Ice Palace Jungfraujoch', 'Юнгфрауйох мұз сарайы', 46.54750000, 7.98010000, 'Ice Palace Jungfraujoch', ARRAY['jungfraujoch']::text[], ARRAY['jungfraujoch']::text[], 'Jungfreijoch.jpg'),

    ('thun-old-town', 'thun', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый город Туна', 'Thun Old Town', 'Тун ескі қаласы', 46.75800000, 7.62800000, 'Thun Old Town', ARRAY['thun']::text[], ARRAY['bern', 'thun', 'interlaken']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('thun-castle', 'thun', 'MUSEUM', 2, 'HOURS', 4.6, 'Замок Тун', 'Thun Castle', 'Тун қамалы', 46.75940000, 7.63030000, 'Thun Castle', ARRAY['thun']::text[], ARRAY['thun']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),
    ('schadau-castle', 'thun', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Замок Шадау', 'Schadau Castle', 'Шадау қамалы', 46.74470000, 7.63780000, 'Schadau Castle Thun', ARRAY['thun']::text[], ARRAY['thun']::text[], 'Bern Panorama von Rosengarten 20211007.jpg'),

    ('jet-deau', 'geneva', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Фонтан Же-д-О', 'Jet d Eau', 'Же-д-О фонтаны', 46.20740000, 6.15590000, 'Jet d Eau Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('st-pierre-cathedral', 'geneva', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Святого Петра', 'St Pierre Cathedral', 'Әулие Петр соборы', 46.20120000, 6.14820000, 'St Pierre Cathedral Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('palais-des-nations', 'geneva', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Дворец Наций', 'Palais des Nations', 'Ұлттар сарайы', 46.22660000, 6.14040000, 'Palais des Nations Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('patek-philippe-museum', 'geneva', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Patek Philippe', 'Patek Philippe Museum', 'Patek Philippe музейі', 46.19810000, 6.13810000, 'Patek Philippe Museum Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('bains-des-paquis', 'geneva', 'BEACH', 2, 'HOURS', 4.6, 'Бани Паки', 'Bains des Paquis', 'Паки жағажай моншалары', 46.21070000, 6.15260000, 'Bains des Paquis Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('plainpalais-flea-market', 'geneva', 'MARKET', 2, 'HOURS', 4.5, 'Блошиный рынок Пленпале', 'Plainpalais Flea Market', 'Пленпале базары', 46.19800000, 6.13960000, 'Plainpalais Flea Market Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('rue-du-rhone-geneva', 'geneva', 'SHOPPING', 2, 'HOURS', 4.5, 'Рю-дю-Рон', 'Rue du Rhone', 'Рю-дю-Рон', 46.20470000, 6.14970000, 'Rue du Rhone Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('halle-de-rive', 'geneva', 'FOOD', 1, 'HOURS', 4.5, 'Алль-де-Рив', 'Halle de Rive', 'Halle de Rive', 46.20170000, 6.15870000, 'Halle de Rive Geneva', ARRAY['geneva']::text[], ARRAY['geneva']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),

    ('olympic-museum', 'lausanne', 'MUSEUM', 2, 'HOURS', 4.8, 'Олимпийский музей', 'Olympic Museum', 'Олимпиада музейі', 46.50830000, 6.63390000, 'Olympic Museum Lausanne', ARRAY['lausanne']::text[], ARRAY['geneva', 'lausanne']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('lausanne-cathedral', 'lausanne', 'TEMPLE', 1, 'HOURS', 4.7, 'Лозаннский собор', 'Lausanne Cathedral', 'Лозанна соборы', 46.52230000, 6.63580000, 'Lausanne Cathedral', ARRAY['lausanne']::text[], ARRAY['lausanne']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('ouchy-quays', 'lausanne', 'PARK', 2, 'HOURS', 4.7, 'Набережные Уши', 'Ouchy Quays', 'Уши жағалауы', 46.50670000, 6.62690000, 'Ouchy Lausanne', ARRAY['lausanne']::text[], ARRAY['lausanne']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('lausanne-city-centre-market', 'lausanne', 'MARKET', 1, 'HOURS', 4.5, 'Центральный рынок Лозанны', 'Lausanne City Centre Market', 'Лозанна орталық базары', 46.52270000, 6.63250000, 'Lausanne City Centre Market', ARRAY['lausanne']::text[], ARRAY['lausanne']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('aquatis-lausanne', 'lausanne', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Акватис Лозанна', 'AQUATIS Aquarium Vivarium', 'AQUATIS Лозанна', 46.54250000, 6.65730000, 'AQUATIS Lausanne', ARRAY['lausanne']::text[], ARRAY['lausanne']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),

    ('chillon-castle', 'montreux', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Шильонский замок', 'Chillon Castle', 'Шильон қамалы', 46.41420000, 6.92750000, 'Chillon Castle Montreux', ARRAY['montreux']::text[], ARRAY['geneva', 'lausanne', 'montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('freddie-mercury-statue', 'montreux', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Статуя Фредди Меркьюри', 'Freddie Mercury Statue', 'Фредди Меркьюри мүсіні', 46.43190000, 6.91060000, 'Freddie Mercury Statue Montreux', ARRAY['montreux']::text[], ARRAY['montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('queen-studio-experience', 'montreux', 'MUSEUM', 1, 'HOURS', 4.5, 'Queen Studio Experience', 'Queen Studio Experience', 'Queen Studio Experience', 46.43220000, 6.91050000, 'Queen Studio Experience Montreux', ARRAY['montreux']::text[], ARRAY['montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('rochers-de-naye', 'montreux', 'NATURE', 4, 'HOURS', 4.7, 'Роше-де-Не', 'Rochers de Naye', 'Роше-де-Не', 46.43120000, 6.97610000, 'Rochers de Naye Montreux', ARRAY['montreux']::text[], ARRAY['montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),

    ('alimentarium', 'vevey', 'MUSEUM', 2, 'HOURS', 4.6, 'Алиментариум', 'Alimentarium', 'Алиментариум', 46.45710000, 6.84680000, 'Alimentarium Vevey', ARRAY['vevey']::text[], ARRAY['vevey', 'montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('chaplins-world', 'vevey', 'MUSEUM', 3, 'HOURS', 4.7, 'Мир Чаплина', 'Chaplins World', 'Чаплин әлемі', 46.47520000, 6.85200000, 'Chaplins World Vevey', ARRAY['vevey']::text[], ARRAY['vevey', 'montreux']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('vevey-quays', 'vevey', 'PARK', 1, 'HOURS', 4.6, 'Набережные Веве', 'Vevey Quays', 'Веве жағалауы', 46.45950000, 6.84490000, 'Vevey Quays Lake Geneva', ARRAY['vevey']::text[], ARRAY['vevey']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),

    ('gruyeres-castle', 'gruyeres', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Грюйер', 'Gruyeres Castle', 'Грюйер қамалы', 46.58490000, 7.08270000, 'Gruyeres Castle', ARRAY['gruyeres']::text[], ARRAY['montreux', 'vevey', 'gruyeres']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('maison-du-gruyere', 'gruyeres', 'FOOD', 2, 'HOURS', 4.6, 'Дом сыра Грюйер', 'La Maison du Gruyere', 'Грюйер ірімшік үйі', 46.58390000, 7.07290000, 'La Maison du Gruyere', ARRAY['gruyeres']::text[], ARRAY['gruyeres']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),
    ('hr-giger-museum', 'gruyeres', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей HR Giger', 'HR Giger Museum', 'HR Giger музейі', 46.58430000, 7.08170000, 'HR Giger Museum Gruyeres', ARRAY['gruyeres']::text[], ARRAY['gruyeres']::text[], 'Schweiz Schloss Chillon Gesamtansicht.jpg'),

    ('matterhorn', 'zermatt', 'NATURE', 4, 'HOURS', 4.9, 'Маттерхорн', 'Matterhorn', 'Маттерхорн', 45.97630000, 7.65860000, 'Matterhorn Zermatt', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('gornergrat-railway', 'zermatt', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Железная дорога Горнерграт', 'Gornergrat Railway', 'Горнерграт темір жолы', 45.98360000, 7.78440000, 'Gornergrat Railway Zermatt', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('matterhorn-glacier-paradise', 'zermatt', 'NATURE', 5, 'HOURS', 4.8, 'Маттерхорн Глейшер Парадайс', 'Matterhorn Glacier Paradise', 'Маттерхорн Glacier Paradise', 45.93830000, 7.72900000, 'Matterhorn Glacier Paradise', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('five-lakes-trail-zermatt', 'zermatt', 'NATURE', 5, 'HOURS', 4.8, 'Маршрут пяти озер', 'Five Lakes Trail', 'Бес көл бағыты', 46.01760000, 7.78270000, 'Five Lakes Trail Zermatt', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('matterhorn-museum-zermatlantis', 'zermatt', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Маттерхорна Zermatlantis', 'Matterhorn Museum Zermatlantis', 'Маттерхорн музейі Zermatlantis', 46.01950000, 7.74680000, 'Matterhorn Museum Zermatlantis', ARRAY['zermatt']::text[], ARRAY['zermatt']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),

    ('lake-lugano', 'lugano', 'NATURE', 2, 'HOURS', 4.8, 'Озеро Лугано', 'Lake Lugano', 'Лугано көлі', 45.98520000, 8.96670000, 'Lake Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('monte-san-salvatore', 'lugano', 'NATURE', 3, 'HOURS', 4.7, 'Монте-Сан-Сальваторе', 'Monte San Salvatore', 'Монте-Сан-Сальваторе', 45.97770000, 8.94750000, 'Monte San Salvatore Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('parco-ciani', 'lugano', 'PARK', 1, 'HOURS', 4.6, 'Парк Чиани', 'Parco Ciani', 'Чиани паркі', 46.00560000, 8.95570000, 'Parco Ciani Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('lac-lugano-arte-cultura', 'lugano', 'MUSEUM', 2, 'HOURS', 4.6, 'Культурный центр LAC', 'LAC Lugano Arte e Cultura', 'LAC Lugano Arte e Cultura', 45.99940000, 8.94900000, 'LAC Lugano Arte e Cultura', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('via-nassa-lugano', 'lugano', 'SHOPPING', 1, 'HOURS', 4.5, 'Виа Насса', 'Via Nassa', 'Виа Насса', 46.00330000, 8.95050000, 'Via Nassa Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('market-of-lugano', 'lugano', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Лугано', 'The Market of Lugano', 'Лугано базары', 46.00530000, 8.95200000, 'Market of Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),
    ('lido-di-lugano', 'lugano', 'BEACH', 3, 'HOURS', 4.6, 'Лидо ди Лугано', 'Lido di Lugano', 'Лугано Лидо', 46.00760000, 8.95690000, 'Lido di Lugano', ARRAY['lugano']::text[], ARRAY['lugano']::text[], 'Lugano from Sighignola.jpg'),

    ('piazza-grande-locarno', 'locarno', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Пьяцца-Гранде Локарно', 'Piazza Grande Locarno', 'Локарно Пьяцца-Гранде', 46.16900000, 8.79510000, 'Piazza Grande Locarno', ARRAY['locarno']::text[], ARRAY['lugano', 'locarno']::text[], 'Lugano from Sighignola.jpg'),
    ('madonna-del-sasso', 'locarno', 'TEMPLE', 2, 'HOURS', 4.7, 'Мадонна-дель-Сассо', 'Madonna del Sasso', 'Мадонна-дель-Сассо', 46.17420000, 8.79420000, 'Madonna del Sasso Locarno', ARRAY['locarno']::text[], ARRAY['locarno']::text[], 'Lugano from Sighignola.jpg'),
    ('falconeria-locarno', 'locarno', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Фальконерия Локарно', 'Falconeria Locarno', 'Локарно сұңқар шоуы', 46.16370000, 8.79500000, 'Falconeria Locarno', ARRAY['locarno']::text[], ARRAY['locarno']::text[], 'Lugano from Sighignola.jpg'),
    ('lido-locarno', 'locarno', 'BEACH', 3, 'HOURS', 4.6, 'Лидо Локарно', 'Lido Locarno', 'Локарно Лидо', 46.16250000, 8.80160000, 'Lido Locarno', ARRAY['locarno']::text[], ARRAY['locarno']::text[], 'Lugano from Sighignola.jpg'),

    ('three-castles-bellinzona', 'bellinzona', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Три замка Беллинцоны', 'Three Castles of Bellinzona', 'Беллинцонаның үш қамалы', 46.19200000, 9.02200000, 'Three Castles of Bellinzona', ARRAY['bellinzona']::text[], ARRAY['lugano', 'bellinzona']::text[], 'Lugano from Sighignola.jpg'),
    ('castelgrande', 'bellinzona', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Кастельгранде', 'Castelgrande', 'Кастельгранде', 46.19250000, 9.02120000, 'Castelgrande Bellinzona', ARRAY['bellinzona']::text[], ARRAY['bellinzona']::text[], 'Lugano from Sighignola.jpg'),
    ('bellinzona-saturday-market', 'bellinzona', 'MARKET', 1, 'HOURS', 4.5, 'Субботний рынок Беллинцоны', 'Bellinzona Saturday Market', 'Беллинцона сенбі базары', 46.19460000, 9.02460000, 'Bellinzona Saturday Market', ARRAY['bellinzona']::text[], ARRAY['bellinzona']::text[], 'Lugano from Sighignola.jpg'),
    ('museum-villa-dei-cedri', 'bellinzona', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Вилла-дей-Чедри', 'Museum Villa dei Cedri', 'Villa dei Cedri музейі', 46.18890000, 9.02130000, 'Museum Villa dei Cedri Bellinzona', ARRAY['bellinzona']::text[], ARRAY['bellinzona']::text[], 'Lugano from Sighignola.jpg'),

    ('ascona-lakeside-promenade', 'ascona', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Набережная Асконы', 'Ascona Lakeside Promenade', 'Аскона жағалауы', 46.15520000, 8.76910000, 'Ascona Lakeside Promenade', ARRAY['ascona']::text[], ARRAY['locarno', 'ascona']::text[], 'Lugano from Sighignola.jpg'),
    ('brissago-islands-botanical-garden', 'ascona', 'PARK', 3, 'HOURS', 4.7, 'Ботанический сад островов Бриссаго', 'Brissago Islands Botanical Garden', 'Бриссаго аралдары ботаникалық бағы', 46.12990000, 8.73510000, 'Brissago Islands Botanical Garden', ARRAY['ascona']::text[], ARRAY['ascona', 'locarno']::text[], 'Lugano from Sighignola.jpg'),
    ('lido-ascona', 'ascona', 'BEACH', 3, 'HOURS', 4.5, 'Лидо Аскона', 'Lido Ascona', 'Аскона Лидо', 46.15190000, 8.77300000, 'Lido Ascona', ARRAY['ascona']::text[], ARRAY['ascona']::text[], 'Lugano from Sighignola.jpg'),

    ('st-moritz-lake', 'st-moritz', 'NATURE', 2, 'HOURS', 4.8, 'Озеро Санкт-Мориц', 'St Moritz Lake', 'Санкт-Мориц көлі', 46.49560000, 9.83790000, 'Lake St Moritz', ARRAY['st-moritz']::text[], ARRAY['st-moritz', 'chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('muottas-muragl', 'st-moritz', 'NATURE', 4, 'HOURS', 4.8, 'Муоттас-Мурагль', 'Muottas Muragl', 'Муоттас-Мурагль', 46.52290000, 9.90140000, 'Muottas Muragl', ARRAY['st-moritz']::text[], ARRAY['st-moritz']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('segantini-museum', 'st-moritz', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Сегантини', 'Segantini Museum', 'Сегантини музейі', 46.49240000, 9.83830000, 'Segantini Museum St Moritz', ARRAY['st-moritz']::text[], ARRAY['st-moritz']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('corviglia-piz-nair', 'st-moritz', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Корвилья и Пиц-Наир', 'Corviglia Piz Nair', 'Корвилья және Пиц-Наир', 46.50790000, 9.78780000, 'Corviglia Piz Nair St Moritz', ARRAY['st-moritz']::text[], ARRAY['st-moritz']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),

    ('lake-davos', 'davos', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Давос', 'Lake Davos', 'Давос көлі', 46.81660000, 9.85390000, 'Lake Davos', ARRAY['davos']::text[], ARRAY['davos', 'chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('kirchner-museum-davos', 'davos', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Кирхнера в Давосе', 'Kirchner Museum Davos', 'Давос Кирхнер музейі', 46.79940000, 9.82430000, 'Kirchner Museum Davos', ARRAY['davos']::text[], ARRAY['davos']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('jakobshorn', 'davos', 'NATURE', 4, 'HOURS', 4.6, 'Якобсхорн', 'Jakobshorn', 'Якобсхорн', 46.77210000, 9.84830000, 'Jakobshorn Davos', ARRAY['davos']::text[], ARRAY['davos']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),

    ('chur-old-town', 'chur', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый город Кура', 'Chur Old Town', 'Кур ескі қаласы', 46.84800000, 9.53120000, 'Chur Old Town', ARRAY['chur']::text[], ARRAY['chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('cathedral-of-the-assumption-chur', 'chur', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор Успения Богородицы', 'Cathedral of the Assumption Chur', 'Кур Успение соборы', 46.84700000, 9.53270000, 'Cathedral of the Assumption Chur', ARRAY['chur']::text[], ARRAY['chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('rhaetian-museum', 'chur', 'MUSEUM', 2, 'HOURS', 4.5, 'Ретийский музей', 'Rhaetian Museum', 'Ретий музейі', 46.84730000, 9.53250000, 'Rhaetian Museum Chur', ARRAY['chur']::text[], ARRAY['chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),

    ('swiss-national-park', 'swiss-national-park', 'PARK', 5, 'HOURS', 4.8, 'Швейцарский национальный парк', 'Swiss National Park', 'Швейцария ұлттық паркі', 46.66670000, 10.16670000, 'Swiss National Park Graubunden', ARRAY['swiss-national-park']::text[], ARRAY['st-moritz', 'chur', 'davos']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('national-park-centre-zernez', 'swiss-national-park', 'MUSEUM', 2, 'HOURS', 4.6, 'Центр национального парка в Цернеце', 'National Park Centre Zernez', 'Цернец ұлттық парк орталығы', 46.69700000, 10.09030000, 'National Park Centre Zernez', ARRAY['swiss-national-park']::text[], ARRAY['st-moritz', 'chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg'),
    ('val-trupchun', 'swiss-national-park', 'NATURE', 5, 'HOURS', 4.7, 'Валь-Трупчун', 'Val Trupchun', 'Валь-Трупчун', 46.61750000, 10.02930000, 'Val Trupchun Swiss National Park', ARRAY['swiss-national-park']::text[], ARRAY['st-moritz', 'chur']::text[], 'Matterhorn Riffelsee 2005-06-11.jpg');

CREATE TEMP TABLE seed_switzerland_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-switzerland-attraction:' || seed.slug) AS attraction_hash,
        md5('id-switzerland-media:' || seed.slug) AS media_hash
    FROM seed_switzerland_priority_attractions seed
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
    ARRAY['switzerland', city_id, slug, lower(category), 'switzerland-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Швейцарии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Switzerland tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Швейцария туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'CH',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'CHF',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_switzerland_resolved_attractions
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

INSERT INTO attraction_translations (
    attraction_id,
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
FROM seed_switzerland_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_switzerland_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_switzerland_resolved_attractions
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
FROM seed_switzerland_resolved_attractions seed
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
FROM seed_switzerland_resolved_attractions
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
    'CH',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_switzerland_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
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
    'DEPARTURE',
    'CH',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_switzerland_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
