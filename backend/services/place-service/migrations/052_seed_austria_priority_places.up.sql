-- Priority Austria destination places seed.
-- The seed keeps major city, alpine, lake, shopping, market, museum, and entertainment hubs explicit for localized discovery.

DROP TABLE IF EXISTS seed_austria_resolved_places;
DROP TABLE IF EXISTS seed_austria_priority_places;

CREATE TEMP TABLE seed_austria_priority_places (
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

INSERT INTO seed_austria_priority_places (
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
    ('schonbrunn-palace', 'vienna', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Дворец Шёнбрунн', 'Schonbrunn Palace', 'Шёнбрунн сарайы', 48.18452000, 16.31224000, 'Schonbrunn Palace Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('hofburg-vienna', 'vienna', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Хофбург', 'Hofburg Vienna', 'Хофбург', 48.20652000, 16.36557000, 'Hofburg Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('st-stephens-cathedral', 'vienna', 'TEMPLE', 2, 'HOURS', 4.9, 'Собор Святого Стефана', 'St Stephens Cathedral', 'Әулие Стефан соборы', 48.20841000, 16.37347000, 'St Stephens Cathedral Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('belvedere-museum', 'vienna', 'MUSEUM', 3, 'HOURS', 4.8, 'Бельведер', 'Belvedere Museum', 'Бельведер музейі', 48.19161000, 16.38095000, 'Belvedere Museum Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Oberes_Belvedere_Wien,_Panorama_Variante.jpg'),
    ('kunsthistorisches-museum-vienna', 'vienna', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей истории искусств', 'Kunsthistorisches Museum Vienna', 'Өнер тарихы музейі', 48.20375000, 16.36162000, 'Kunsthistorisches Museum Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Oberes_Belvedere_Wien,_Panorama_Variante.jpg'),
    ('albertina-museum', 'vienna', 'MUSEUM', 2, 'HOURS', 4.7, 'Альбертина', 'Albertina Museum', 'Альбертина музейі', 48.20470000, 16.36889000, 'Albertina Museum Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Oberes_Belvedere_Wien,_Panorama_Variante.jpg'),
    ('museumsquartier-wien', 'vienna', 'MUSEUM', 3, 'HOURS', 4.7, 'Музейный квартал', 'MuseumsQuartier Wien', 'Музей кварталы', 48.20330000, 16.35860000, 'MuseumsQuartier Wien Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Oberes_Belvedere_Wien,_Panorama_Variante.jpg'),
    ('vienna-state-opera', 'vienna', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Венская государственная опера', 'Vienna State Opera', 'Вена мемлекеттік операсы', 48.20278000, 16.36944000, 'Vienna State Opera Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Wien,_Prater,_Riesenrad_--_2018_--_3161.jpg'),
    ('vienna-prater-giant-ferris-wheel', 'vienna', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Пратер и Венское колесо обозрения', 'Vienna Prater and Giant Ferris Wheel', 'Пратер және Вена шолу дөңгелегі', 48.21667000, 16.39583000, 'Vienna Prater Giant Ferris Wheel Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Wien,_Prater,_Riesenrad_--_2018_--_3161.jpg'),
    ('schonbrunn-zoo', 'vienna', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Зоопарк Шёнбрунн', 'Schonbrunn Zoo', 'Шёнбрунн хайуанаттар бағы', 48.18222000, 16.30278000, 'Schonbrunn Zoo Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Wien,_Prater,_Riesenrad_--_2018_--_3161.jpg'),
    ('stadtpark-vienna', 'vienna', 'PARK', 2, 'HOURS', 4.6, 'Городской парк Вены', 'Stadtpark Vienna', 'Вена қалалық саябағы', 48.20444000, 16.38056000, 'Stadtpark Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Wien,_Prater,_Riesenrad_--_2018_--_3161.jpg'),
    ('danube-island', 'vienna', 'BEACH', 3, 'HOURS', 4.6, 'Дунайский остров', 'Danube Island', 'Дунай аралы', 48.23100000, 16.41500000, 'Danube Island Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Wien,_Prater,_Riesenrad_--_2018_--_3161.jpg'),
    ('naschmarkt', 'vienna', 'MARKET', 2, 'HOURS', 4.7, 'Нашмаркт', 'Naschmarkt', 'Нашмаркт', 48.19833000, 16.36194000, 'Naschmarkt Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('karntner-strasse-graben-kohlmarkt', 'vienna', 'SHOPPING', 2, 'HOURS', 4.6, 'Кернтнерштрассе, Грабен и Кольмаркт', 'Karntner Strasse Graben and Kohlmarkt', 'Кернтнерштрассе, Грабен және Кольмаркт', 48.20700000, 16.37100000, 'Karntner Strasse Graben Kohlmarkt Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('hundertwasser-house', 'vienna', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Дом Хундертвассера', 'Hundertwasser House', 'Хундертвассер үйі', 48.20730000, 16.39400000, 'Hundertwasser House Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Oberes_Belvedere_Wien,_Panorama_Variante.jpg'),
    ('kahlenberg', 'vienna', 'NATURE', 2, 'HOURS', 4.7, 'Каленберг', 'Kahlenberg', 'Каленберг', 48.27600000, 16.33300000, 'Kahlenberg Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('figlmueller-wollzeile', 'vienna', 'FOOD', 2, 'HOURS', 4.6, 'Фигльмюллер Вольцайле', 'Figlmueller Wollzeile', 'Фигльмюллер Вольцайле', 48.20830000, 16.37540000, 'Figlmueller Wollzeile Vienna Austria', ARRAY['vienna']::text[], ARRAY['vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('klosterneuburg-abbey', 'klosterneuburg', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Клостернойбург', 'Klosterneuburg Abbey', 'Клостернойбург монастыры', 48.30540000, 16.32540000, 'Klosterneuburg Abbey Austria', ARRAY['klosterneuburg']::text[], ARRAY['klosterneuburg', 'vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('laxenburg-castle-park', 'laxenburg', 'PARK', 3, 'HOURS', 4.7, 'Замковый парк Лаксенбург', 'Laxenburg Castle Park', 'Лаксенбург қамал саябағы', 48.06750000, 16.35600000, 'Laxenburg Castle Park Austria', ARRAY['laxenburg']::text[], ARRAY['laxenburg', 'vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('westfield-shopping-city-sud', 'voesendorf', 'SHOPPING', 3, 'HOURS', 4.5, 'Westfield Shopping City Süd', 'Westfield Shopping City Sud', 'Westfield Shopping City Sud', 48.10970000, 16.31880000, 'Westfield Shopping City Sud Voesendorf Austria', ARRAY['voesendorf']::text[], ARRAY['voesendorf', 'vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('roman-city-carnuntum', 'petronell-carnuntum', 'MUSEUM', 3, 'HOURS', 4.6, 'Римский город Карнунтум', 'Roman City Carnuntum', 'Карнунтум рим қаласы', 48.11280000, 16.86470000, 'Roman City Carnuntum Austria', ARRAY['petronell-carnuntum']::text[], ARRAY['petronell-carnuntum', 'vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),
    ('seegrotte-hinterbruehl', 'hinterbruehl', 'NATURE', 2, 'HOURS', 4.5, 'Зеегротте Хинтербрюль', 'Seegrotte Hinterbruehl', 'Хинтербрюль Зеегротте', 48.08430000, 16.25440000, 'Seegrotte Hinterbruehl Austria', ARRAY['hinterbruehl']::text[], ARRAY['hinterbruehl', 'vienna']::text[], 'Schloss_Schönbrunn_Wien_2014_(Zuschnitt_1).jpg'),

    ('melk-abbey', 'melk', 'TEMPLE', 3, 'HOURS', 4.9, 'Аббатство Мельк', 'Melk Abbey', 'Мельк аббаттығы', 48.22843000, 15.33123000, 'Melk Abbey Austria', ARRAY['melk']::text[], ARRAY['melk', 'vienna']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('schallaburg-castle', 'melk', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Шаллабург', 'Schallaburg Castle', 'Шаллабург қамалы', 48.19070000, 15.35550000, 'Schallaburg Castle Austria', ARRAY['melk']::text[], ARRAY['melk', 'vienna']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('wachau-valley', 'wachau', 'NATURE', 5, 'HOURS', 4.9, 'Долина Вахау', 'Wachau Valley', 'Вахау аңғары', 48.38330000, 15.45000000, 'Wachau Valley Austria', ARRAY['wachau']::text[], ARRAY['wachau', 'vienna']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('steiner-tor', 'krems', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Штайнерские ворота', 'Steiner Tor', 'Штайнер қақпасы', 48.41080000, 15.59950000, 'Steiner Tor Krems Austria', ARRAY['krems']::text[], ARRAY['krems', 'wachau']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('kunstmeile-krems', 'krems', 'MUSEUM', 3, 'HOURS', 4.6, 'Художественная миля Кремса', 'Kunstmeile Krems', 'Кремс өнер милясы', 48.40900000, 15.60300000, 'Kunstmeile Krems Austria', ARRAY['krems']::text[], ARRAY['krems', 'wachau']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('duernstein-abbey', 'duernstein', 'TEMPLE', 1, 'HOURS', 4.7, 'Аббатство Дюрнштайн', 'Duernstein Abbey', 'Дюрнштайн аббаттығы', 48.39580000, 15.52020000, 'Duernstein Abbey Austria', ARRAY['duernstein']::text[], ARRAY['duernstein', 'wachau']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('duernstein-castle-ruins', 'duernstein', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Руины замка Дюрнштайн', 'Duernstein Castle Ruins', 'Дюрнштайн қамалының қирандылары', 48.39778000, 15.52194000, 'Duernstein Castle Ruins Austria', ARRAY['duernstein']::text[], ARRAY['duernstein', 'wachau']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('goettweig-abbey', 'goettweig', 'TEMPLE', 2, 'HOURS', 4.7, 'Аббатство Гёттвайг', 'Goettweig Abbey', 'Гёттвайг аббаттығы', 48.36660000, 15.61220000, 'Goettweig Abbey Austria', ARRAY['goettweig']::text[], ARRAY['goettweig', 'krems']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('st-polten-cathedral-domplatz', 'st-polten', 'TEMPLE', 1, 'HOURS', 4.6, 'Собор и Домплац Санкт-Пёльтена', 'St Polten Cathedral and Domplatz', 'Санкт-Пёльтен соборы және Домплац', 48.20470000, 15.62370000, 'St Polten Cathedral Domplatz Austria', ARRAY['st-polten']::text[], ARRAY['st-polten']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('museum-niederoesterreich', 'st-polten', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Нижней Австрии', 'Museum Niederoesterreich', 'Төменгі Австрия музейі', 48.19960000, 15.63390000, 'Museum Niederoesterreich St Polten Austria', ARRAY['st-polten']::text[], ARRAY['st-polten']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('viehofner-lakes', 'st-polten', 'BEACH', 3, 'HOURS', 4.5, 'Озёра Фихофнер', 'Viehofner Lakes', 'Фихофнер көлдері', 48.22219000, 15.64781000, 'Viehofner Lakes St Polten Austria', ARRAY['st-polten']::text[], ARRAY['st-polten']::text[], 'Stift_Melk_Nordseite_01.jpg'),
    ('wochenmarkt-domplatz-st-polten', 'st-polten', 'MARKET', 1, 'HOURS', 4.4, 'Еженедельный рынок на Домплац', 'Wochenmarkt Domplatz St Polten', 'Санкт-Пёльтен Домплац базары', 48.20470000, 15.62370000, 'Wochenmarkt Domplatz St Polten Austria', ARRAY['st-polten']::text[], ARRAY['st-polten']::text[], 'Stift_Melk_Nordseite_01.jpg'),

    ('historic-centre-salzburg', 'salzburg', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Исторический центр Зальцбурга', 'Historic Centre of Salzburg', 'Зальцбург тарихи орталығы', 47.80056000, 13.04361000, 'Historic Centre of Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('hohensalzburg-fortress', 'salzburg', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Крепость Хоэнзальцбург', 'Hohensalzburg Fortress', 'Хоэнзальцбург қамалы', 47.79509000, 13.04768000, 'Hohensalzburg Fortress Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('mirabell-palace-gardens', 'salzburg', 'PARK', 2, 'HOURS', 4.8, 'Дворец и сады Мирабель', 'Mirabell Palace and Gardens', 'Мирабель сарайы мен бақтары', 47.80576000, 13.04152000, 'Mirabell Palace Gardens Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('salzburg-cathedral', 'salzburg', 'TEMPLE', 1, 'HOURS', 4.7, 'Зальцбургский собор', 'Salzburg Cathedral', 'Зальцбург соборы', 47.79784000, 13.04677000, 'Salzburg Cathedral Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('domquartier-salzburg', 'salzburg', 'MUSEUM', 2, 'HOURS', 4.7, 'ДомКвартир Зальцбург', 'DomQuartier Salzburg', 'Зальцбург ДомКвартир', 47.79822000, 13.04616000, 'DomQuartier Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('mozarts-birthplace', 'salzburg', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом рождения Моцарта', 'Mozarts Birthplace', 'Моцарт туған үйі', 47.80017000, 13.04352000, 'Mozarts Birthplace Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('getreidegasse', 'salzburg', 'SHOPPING', 2, 'HOURS', 4.6, 'Гетрайдегассе', 'Getreidegasse', 'Гетрайдегассе', 47.80042000, 13.04214000, 'Getreidegasse Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('hellbrunn-palace-trick-fountains', 'salzburg', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Дворец Хелльбрунн и потешные фонтаны', 'Hellbrunn Palace and Trick Fountains', 'Хелльбрунн сарайы және көңілді субұрқақтар', 47.76267000, 13.06077000, 'Hellbrunn Palace Trick Fountains Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('salzburg-christkindlmarkt', 'salzburg', 'MARKET', 1, 'HOURS', 4.6, 'Рождественский рынок Зальцбурга', 'Salzburg Christkindlmarkt', 'Зальцбург рождестволық базары', 47.79806000, 13.04636000, 'Salzburg Christkindlmarkt Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('red-bull-hangar-7', 'salzburg', 'MUSEUM', 2, 'HOURS', 4.6, 'Ангар-7 Red Bull', 'Red Bull Hangar-7', 'Red Bull Hangar-7', 47.79361000, 13.00750000, 'Red Bull Hangar 7 Salzburg Austria', ARRAY['salzburg']::text[], ARRAY['salzburg']::text[], 'Salzburg_pano_2659-18-3246-1.jpg'),
    ('hallstatt-market-square', 'hallstatt', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Рыночная площадь Халльштата', 'Hallstatt Market Square', 'Халльштат базар алаңы', 47.56229000, 13.64983000, 'Hallstatt Market Square Austria', ARRAY['hallstatt']::text[], ARRAY['hallstatt', 'salzburg']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('world-heritage-museum-hallstatt', 'hallstatt', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей всемирного наследия Халльштата', 'World Heritage Museum Hallstatt', 'Халльштат әлемдік мұра музейі', 47.56202000, 13.64949000, 'World Heritage Museum Hallstatt Austria', ARRAY['hallstatt']::text[], ARRAY['hallstatt']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('salzwelten-hallstatt-salt-mine', 'hallstatt', 'MUSEUM', 3, 'HOURS', 4.8, 'Соляная шахта Зальцвельтен Халльштат', 'Salzwelten Hallstatt Salt Mine', 'Халльштат тұз шахтасы', 47.55450000, 13.64140000, 'Salzwelten Hallstatt Salt Mine Austria', ARRAY['hallstatt']::text[], ARRAY['hallstatt']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('hallstatt-skywalk', 'hallstatt', 'NATURE', 2, 'HOURS', 4.9, 'Смотровая площадка Skywalk Халльштат', 'Hallstatt Skywalk', 'Халльштат Skywalk көрініс алаңы', 47.56140000, 13.64330000, 'Hallstatt Skywalk World Heritage View Austria', ARRAY['hallstatt']::text[], ARRAY['hallstatt']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('lake-hallstatt', 'hallstatt', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Халльштеттер-Зее', 'Lake Hallstatt', 'Халльштат көлі', 47.58500000, 13.66100000, 'Lake Hallstatt Austria', ARRAY['hallstatt']::text[], ARRAY['hallstatt']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('schafbergbahn', 'st-wolfgang', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Зубчатая железная дорога Шафбергбан', 'SchafbergBahn Cog Railway', 'Шафбергбан тісті теміржолы', 47.73953000, 13.44820000, 'SchafbergBahn St Wolfgang Austria', ARRAY['st-wolfgang']::text[], ARRAY['st-wolfgang', 'salzburg']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('pilgrimage-church-st-wolfgang', 'st-wolfgang', 'TEMPLE', 1, 'HOURS', 4.7, 'Паломническая церковь Святого Вольфганга', 'Pilgrimage Church of St Wolfgang', 'Әулие Вольфганг қажылық шіркеуі', 47.73963000, 13.44685000, 'Pilgrimage Church St Wolfgang Austria', ARRAY['st-wolfgang']::text[], ARRAY['st-wolfgang']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('wolfgangsee-boat-service', 'st-wolfgang', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Судоходство по озеру Вольфгангзе', 'Wolfgangsee Boat Service', 'Вольфгангзе кеме қатынасы', 47.73920000, 13.44800000, 'Wolfgangsee Boat Service Austria', ARRAY['st-wolfgang']::text[], ARRAY['st-wolfgang']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('imperial-villa-bad-ischl', 'bad-ischl', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Императорская вилла Бад-Ишля', 'Imperial Villa Bad Ischl', 'Бад-Ишль императорлық вилласы', 47.71399000, 13.62242000, 'Imperial Villa Bad Ischl Austria', ARRAY['bad-ischl']::text[], ARRAY['bad-ischl', 'salzburg']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),
    ('katrin-cable-car', 'bad-ischl', 'NATURE', 3, 'HOURS', 4.7, 'Канатная дорога Катрин', 'Katrin Cable Car', 'Катрин аспалы жолы', 47.70062000, 13.62663000, 'Katrin Cable Car Bad Ischl Austria', ARRAY['bad-ischl']::text[], ARRAY['bad-ischl']::text[], 'Hallstatt_evangelische_Kirche_20180206.jpg'),

    ('golden-roof', 'innsbruck', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Золотая крыша', 'Golden Roof', 'Алтын шатыр', 47.26860000, 11.39330000, 'Golden Roof Innsbruck Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('nordkette', 'innsbruck', 'NATURE', 4, 'HOURS', 4.9, 'Нордкетте', 'Nordkette', 'Нордкетте', 47.31200000, 11.38370000, 'Nordkette Innsbruck Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('ambras-castle', 'innsbruck', 'MUSEUM', 2, 'HOURS', 4.7, 'Замок Амбрас', 'Ambras Castle', 'Амбрас қамалы', 47.25530000, 11.43420000, 'Ambras Castle Innsbruck Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('bergisel-ski-jump', 'innsbruck', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Трамплин Бергизель', 'Bergisel Ski Jump', 'Бергизель трамплині', 47.24890000, 11.39920000, 'Bergisel Ski Jump Innsbruck Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('markthalle-innsbruck', 'innsbruck', 'MARKET', 1, 'HOURS', 4.5, 'Рыночный зал Инсбрука', 'Markthalle Innsbruck', 'Инсбрук базар залы', 47.26790000, 11.39000000, 'Markthalle Innsbruck Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('swarovski-crystal-worlds', 'innsbruck', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Кристальные миры Swarovski', 'Swarovski Crystal Worlds', 'Swarovski кристалл әлемдері', 47.29480000, 11.60060000, 'Swarovski Crystal Worlds Wattens Austria', ARRAY['innsbruck']::text[], ARRAY['innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('ahornbahn-mayrhofen', 'mayrhofen', 'NATURE', 4, 'HOURS', 4.7, 'Канатная дорога Ахорнбан', 'Ahornbahn and Ahorn Plateau', 'Ахорнбан және Ахорн үстірті', 47.16320000, 11.86160000, 'Ahornbahn Mayrhofen Austria', ARRAY['mayrhofen']::text[], ARRAY['mayrhofen', 'innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('penkenbahn-mayrhofen', 'mayrhofen', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Канатная дорога Пенкенбан', 'Penkenbahn and Mount Penken', 'Пенкенбан және Пенкен тауы', 47.16640000, 11.86370000, 'Penkenbahn Mayrhofen Austria', ARRAY['mayrhofen']::text[], ARRAY['mayrhofen', 'innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('erlebnissennerei-zillertal', 'mayrhofen', 'FOOD', 2, 'HOURS', 4.5, 'Сыроварня ErlebnisSennerei Zillertal', 'ErlebnisSennerei Zillertal', 'Zillertal ірімшік фермасы', 47.18190000, 11.86290000, 'ErlebnisSennerei Zillertal Austria', ARRAY['mayrhofen']::text[], ARRAY['mayrhofen']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('hahnenkamm', 'kitzbuhel', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Ханенкамм и канатная дорога', 'Hahnenkamm and Hahnenkammbahn', 'Ханенкамм және аспалы жол', 47.44600000, 12.38930000, 'Hahnenkamm Kitzbuhel Austria', ARRAY['kitzbuhel']::text[], ARRAY['kitzbuhel', 'innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('kitzbuheler-horn', 'kitzbuhel', 'NATURE', 3, 'HOURS', 4.7, 'Китцбюэльский Хорн', 'Kitzbuheler Horn', 'Кицбюэль Хорн', 47.47530000, 12.42930000, 'Kitzbuheler Horn Austria', ARRAY['kitzbuhel']::text[], ARRAY['kitzbuhel']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('schwarzsee-kitzbuhel', 'kitzbuhel', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Шварцзе', 'Schwarzsee Lake', 'Шварцзе көлі', 47.45690000, 12.37510000, 'Schwarzsee Kitzbuhel Austria', ARRAY['kitzbuhel']::text[], ARRAY['kitzbuhel']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('gaislachkogl-big-3', 'solden', 'NATURE', 4, 'HOURS', 4.8, 'Гайслахкогль и платформа BIG 3', 'Gaislachkogl and BIG 3 Platform', 'Гайслахкогль және BIG 3 алаңы', 46.93690000, 10.99130000, 'Gaislachkogl BIG 3 Platform Solden Austria', ARRAY['solden']::text[], ARRAY['solden', 'innsbruck']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('007-elements', 'solden', 'MUSEUM', 2, 'HOURS', 4.6, '007 Elements', '007 Elements', '007 Elements', 46.93690000, 10.99120000, '007 Elements Solden Austria', ARRAY['solden']::text[], ARRAY['solden']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('ice-q-restaurant', 'solden', 'FOOD', 2, 'HOURS', 4.5, 'Ресторан ice Q', 'ice Q Restaurant', 'ice Q мейрамханасы', 46.93670000, 10.99150000, 'ice Q Restaurant Solden Austria', ARRAY['solden']::text[], ARRAY['solden']::text[], 'Goldenes_Dachl_(Innsbruck).jpg'),
    ('pfanderbahn-bregenz', 'bregenz', 'NATURE', 3, 'HOURS', 4.8, 'Пфендербан и смотровая площадка', 'Pfanderbahn and Pfander Viewpoint', 'Пфендербан және көрініс алаңы', 47.50690000, 9.77950000, 'Pfanderbahn Bregenz Austria', ARRAY['bregenz']::text[], ARRAY['bregenz']::text[], 'Bay_of_Bregenz_from_Eichenberg.jpg'),
    ('kunsthaus-bregenz', 'bregenz', 'MUSEUM', 2, 'HOURS', 4.6, 'Кунстхаус Брегенц', 'Kunsthaus Bregenz', 'Брегенц өнер үйі', 47.50490000, 9.74710000, 'Kunsthaus Bregenz Austria', ARRAY['bregenz']::text[], ARRAY['bregenz']::text[], 'Bay_of_Bregenz_from_Eichenberg.jpg'),
    ('bregenz-lake-stage', 'bregenz', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Озерная сцена Брегенца', 'Bregenz Lake Stage', 'Брегенц көл сахнасы', 47.50500000, 9.73860000, 'Bregenz Lake Stage Austria', ARRAY['bregenz']::text[], ARRAY['bregenz']::text[], 'Bay_of_Bregenz_from_Eichenberg.jpg'),
    ('lake-constance-promenade', 'bregenz', 'PARK', 2, 'HOURS', 4.6, 'Набережная Боденского озера', 'Lake Constance Promenade', 'Боден көлі жағалауы', 47.50500000, 9.74000000, 'Lake Constance Promenade Bregenz Austria', ARRAY['bregenz']::text[], ARRAY['bregenz']::text[], 'Bay_of_Bregenz_from_Eichenberg.jpg'),

    ('graz-schlossberg', 'graz', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Шлоссберг', 'Graz Schlossberg', 'Грац Шлоссберг', 47.07550000, 15.43750000, 'Graz Schlossberg Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('schloss-eggenberg', 'graz', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Дворец Эггенберг', 'Schloss Eggenberg', 'Эггенберг сарайы', 47.07390000, 15.39140000, 'Schloss Eggenberg Graz Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('kunsthaus-graz', 'graz', 'MUSEUM', 2, 'HOURS', 4.7, 'Кунстхаус Грац', 'Kunsthaus Graz', 'Кунстхаус Грац', 47.07140000, 15.43420000, 'Kunsthaus Graz Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('styrian-armoury', 'graz', 'MUSEUM', 2, 'HOURS', 4.8, 'Штирийский арсенал', 'Styrian Armoury', 'Штирия арсеналы', 47.07060000, 15.43920000, 'Styrian Armoury Graz Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('murinsel', 'graz', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Муринзель', 'Murinsel', 'Муринзель', 47.07220000, 15.43620000, 'Murinsel Graz Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('kaiser-josef-markt', 'graz', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Кайзер-Йозеф', 'Kaiser-Josef-Markt', 'Кайзер-Йозеф базары', 47.06960000, 15.44810000, 'Kaiser-Josef-Markt Graz Austria', ARRAY['graz']::text[], ARRAY['graz']::text[], 'Austria_Graz_2022-03.jpg'),
    ('minimundus', 'klagenfurt', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Минимундус', 'Minimundus', 'Минимундус', 46.62060000, 14.26390000, 'Minimundus Klagenfurt Austria', ARRAY['klagenfurt']::text[], ARRAY['klagenfurt', 'villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('strandbad-klagenfurt', 'klagenfurt', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Штрандбад Клагенфурт', 'Strandbad Klagenfurt', 'Клагенфурт жағажайы', 46.62030000, 14.25280000, 'Strandbad Klagenfurt Austria', ARRAY['klagenfurt']::text[], ARRAY['klagenfurt']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('lake-worthersee', 'klagenfurt', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Вёртерзе', 'Lake Worthersee', 'Вёртерзе көлі', 46.62600000, 14.20000000, 'Lake Worthersee Austria', ARRAY['klagenfurt']::text[], ARRAY['klagenfurt', 'villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('benediktinermarkt', 'klagenfurt', 'MARKET', 1, 'HOURS', 4.5, 'Бенедиктинский рынок', 'Benediktinermarkt', 'Бенедиктин базары', 46.62350000, 14.30550000, 'Benediktinermarkt Klagenfurt Austria', ARRAY['klagenfurt']::text[], ARRAY['klagenfurt']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('city-arkaden-klagenfurt', 'klagenfurt', 'SHOPPING', 2, 'HOURS', 4.4, 'City Arkaden Klagenfurt', 'City Arkaden Klagenfurt', 'City Arkaden Klagenfurt', 46.62630000, 14.30710000, 'City Arkaden Klagenfurt Austria', ARRAY['klagenfurt']::text[], ARRAY['klagenfurt']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('villach-old-town', 'villach', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый город Филлаха', 'Villach Old Town', 'Филлах ескі қаласы', 46.61360000, 13.84600000, 'Villach Old Town Austria', ARRAY['villach']::text[], ARRAY['villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('kaerntentherme-villach', 'villach', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Термы КернтенТерме', 'KarntenTherme Warmbad-Villach', 'КернтенТерме', 46.58800000, 13.82830000, 'KarntenTherme Villach Austria', ARRAY['villach']::text[], ARRAY['villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('dobratsch-nature-park', 'villach', 'NATURE', 4, 'HOURS', 4.7, 'Природный парк Добрач', 'Dobratsch Nature Park', 'Добрач табиғи паркі', 46.60310000, 13.67390000, 'Dobratsch Nature Park Austria', ARRAY['villach']::text[], ARRAY['villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('atrio-villach', 'villach', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ ATRIO Филлах', 'ATRIO Villach', 'ATRIO Villach', 46.59430000, 13.85050000, 'ATRIO Villach Austria', ARRAY['villach']::text[], ARRAY['villach']::text[], 'Klagenfurt_Domplatz_Stadtpfarrkirche_Hll_Peter_und_Paul_09092015_7245.jpg'),
    ('lake-zell', 'zell-am-see', 'NATURE', 3, 'HOURS', 4.8, 'Озеро Целль', 'Lake Zell', 'Целль көлі', 47.32200000, 12.81000000, 'Lake Zell Zell am See Austria', ARRAY['zell-am-see']::text[], ARRAY['zell-am-see', 'salzburg']::text[], 'Zell_am_See_und_Zeller_See.jpg'),
    ('kitzsteinhorn', 'kaprun', 'NATURE', 5, 'HOURS', 4.8, 'Китцштайнхорн', 'Kitzsteinhorn', 'Китцштайнхорн', 47.18890000, 12.68750000, 'Kitzsteinhorn Kaprun Austria', ARRAY['kaprun']::text[], ARRAY['kaprun', 'zell-am-see']::text[], 'Zell_am_See_und_Zeller_See.jpg'),
    ('sigmund-thun-gorge', 'kaprun', 'NATURE', 2, 'HOURS', 4.7, 'Ущелье Зигмунд-Тун', 'Sigmund Thun Gorge', 'Зигмунд-Тун шатқалы', 47.26220000, 12.74500000, 'Sigmund Thun Gorge Kaprun Austria', ARRAY['kaprun']::text[], ARRAY['kaprun']::text[], 'Zell_am_See_und_Zeller_See.jpg'),
    ('tauern-spa', 'kaprun', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'ТАУЭРН СПА Целль-ам-Зе-Капрун', 'TAUERN SPA Zell am See-Kaprun', 'TAUERN SPA', 47.28820000, 12.75540000, 'TAUERN SPA Zell am See Kaprun Austria', ARRAY['kaprun']::text[], ARRAY['kaprun', 'zell-am-see']::text[], 'Zell_am_See_und_Zeller_See.jpg'),
    ('grossglockner-high-alpine-road', 'grossglockner', 'NATURE', 5, 'HOURS', 4.9, 'Высокогорная дорога Гросглоккнер', 'Grossglockner High Alpine Road', 'Гросглоккнер биік альпі жолы', 47.07430000, 12.75390000, 'Grossglockner High Alpine Road Austria', ARRAY['grossglockner']::text[], ARRAY['grossglockner', 'zell-am-see']::text[], 'Grossglockner_High_Alpine_Road,_National_Park_Hohe_Tauern_Austria.jpg'),

    ('esterhazy-palace', 'eisenstadt', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Эстерхази', 'Esterhazy Palace', 'Эстерхази сарайы', 47.84650000, 16.52080000, 'Esterhazy Palace Eisenstadt Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt', 'vienna']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('haydn-house-eisenstadt', 'eisenstadt', 'MUSEUM', 1, 'HOURS', 4.5, 'Дом Гайдна', 'Haydn House Eisenstadt', 'Гайдн үйі', 47.84680000, 16.52740000, 'Haydn House Eisenstadt Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('schlosspark-eisenstadt', 'eisenstadt', 'PARK', 2, 'HOURS', 4.5, 'Дворцовый парк Айзенштадт', 'Schlosspark Eisenstadt', 'Айзенштадт сарай саябағы', 47.84290000, 16.52000000, 'Schlosspark Eisenstadt Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('designer-outlet-parndorf', 'eisenstadt', 'SHOPPING', 3, 'HOURS', 4.5, 'Дизайнерский аутлет Парндорф', 'Designer Outlet Parndorf', 'Парндорф дизайнерлік аутлеті', 47.98020000, 16.84280000, 'Designer Outlet Parndorf Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt', 'vienna']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('national-park-neusiedler-see', 'eisenstadt', 'NATURE', 4, 'HOURS', 4.7, 'Национальный парк Нойзидлер-Зе-Зеевинкель', 'National Park Neusiedler See-Seewinkel', 'Нойзидлер-Зе ұлттық паркі', 47.76940000, 16.80070000, 'National Park Neusiedler See-Seewinkel Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('familypark-st-margarethen', 'eisenstadt', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Фэмилипарк Санкт-Маргаретен', 'Familypark St Margarethen', 'St Margarethen Familypark', 47.80280000, 16.64020000, 'Familypark St Margarethen Austria', ARRAY['eisenstadt']::text[], ARRAY['eisenstadt']::text[], 'Aerial_image_of_Schloss_Esterházy_(view_from_the_south).jpg'),
    ('ars-electronica-center', 'linz', 'MUSEUM', 3, 'HOURS', 4.8, 'Центр Ars Electronica', 'Ars Electronica Center', 'Ars Electronica орталығы', 48.30917000, 14.28417000, 'Ars Electronica Center Linz Austria', ARRAY['linz']::text[], ARRAY['linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('lentos-art-museum', 'linz', 'MUSEUM', 2, 'HOURS', 4.6, 'Художественный музей Lentos', 'Lentos Art Museum', 'Lentos өнер музейі', 48.30861000, 14.28939000, 'Lentos Art Museum Linz Austria', ARRAY['linz']::text[], ARRAY['linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('poestlingberg-basilica', 'linz', 'TEMPLE', 2, 'HOURS', 4.7, 'Базилика и смотровая площадка Пёстлингберг', 'Poestlingberg Basilica and Viewpoint', 'Пёстлингберг базиликасы', 48.32460000, 14.25810000, 'Poestlingberg Basilica Linz Austria', ARRAY['linz']::text[], ARRAY['linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('grottenbahn-linz', 'linz', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Гроттенбан Линц', 'Grottenbahn Linz', 'Гроттенбан Линц', 48.32420000, 14.25630000, 'Grottenbahn Linz Austria', ARRAY['linz']::text[], ARRAY['linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('linz-main-square', 'linz', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Главная площадь Линца', 'Linz Main Square', 'Линц басты алаңы', 48.30690000, 14.28610000, 'Linz Main Square Austria', ARRAY['linz']::text[], ARRAY['linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('ledererturm-wels', 'wels', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Башня Ледерертурм', 'Ledererturm Tower', 'Ледерертурм мұнарасы', 48.15670000, 14.02480000, 'Ledererturm Wels Austria', ARRAY['wels']::text[], ARRAY['wels', 'linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('welios-science-center', 'wels', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Научный центр Welios', 'Welios Science Center', 'Welios ғылыми орталығы', 48.15230000, 14.02140000, 'Welios Science Center Wels Austria', ARRAY['wels']::text[], ARRAY['wels', 'linz']::text[], 'Linz_Ars_Electronica_center-5529.jpg'),
    ('max-center-wels', 'wels', 'SHOPPING', 2, 'HOURS', 4.3, 'Торговый центр max.center Wels', 'max.center Wels', 'max.center Wels', 48.16600000, 14.00060000, 'max.center Wels Austria', ARRAY['wels']::text[], ARRAY['wels']::text[], 'Linz_Ars_Electronica_center-5529.jpg');

CREATE TEMP TABLE seed_austria_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-austria-place:' || seed.slug) AS place_hash,
        md5('id-austria-media:' || seed.slug) AS media_hash
    FROM seed_austria_priority_places seed
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
    ARRAY['austria', city_id, slug, lower(category), 'austria-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Австрии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Austria tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Австрия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'AT',
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
FROM seed_austria_resolved_places
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
FROM seed_austria_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_austria_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_austria_resolved_places
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
FROM seed_austria_resolved_places seed
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
FROM seed_austria_resolved_places
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
    'AT',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_austria_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'AT',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_austria_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_austria_resolved_places;
DROP TABLE IF EXISTS seed_austria_priority_places;
