-- Priority Germany destination attractions seed.
-- The seed keeps major city, nature, culture, shopping, market, and entertainment hubs explicit for localized discovery.

DROP TABLE IF EXISTS seed_germany_resolved_attractions;
DROP TABLE IF EXISTS seed_germany_priority_attractions;

CREATE TEMP TABLE seed_germany_priority_attractions (
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

INSERT INTO seed_germany_priority_attractions (
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
    ('brandenburg-gate', 'berlin', 'ARCHITECTURE', 1, 'HOURS', 4.9, 'Бранденбургские ворота', 'Brandenburg Gate', 'Бранденбург қақпасы', 52.51630000, 13.37770000, 'Brandenburg Gate Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('reichstag-building', 'berlin', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Рейхстаг', 'Reichstag Building', 'Рейхстаг ғимараты', 52.51860000, 13.37620000, 'Reichstag Building Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('museum-island', 'berlin', 'MUSEUM', 4, 'HOURS', 4.9, 'Музейный остров', 'Museum Island', 'Музей аралы', 52.51690000, 13.40100000, 'Museum Island Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('east-side-gallery', 'berlin', 'MUSEUM', 2, 'HOURS', 4.8, 'Галерея East Side', 'East Side Gallery', 'East Side галереясы', 52.50500000, 13.43970000, 'East Side Gallery Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('berlin-tv-tower', 'berlin', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Берлинская телебашня', 'Berlin TV Tower', 'Берлин телемұнарасы', 52.52080000, 13.40940000, 'Berlin TV Tower Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('berlin-cathedral', 'berlin', 'TEMPLE', 1, 'HOURS', 4.7, 'Берлинский кафедральный собор', 'Berlin Cathedral', 'Берлин кафедралды соборы', 52.51910000, 13.40110000, 'Berlin Cathedral Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('tiergarten', 'berlin', 'PARK', 2, 'HOURS', 4.7, 'Тиргартен', 'Tiergarten', 'Тиргартен', 52.51450000, 13.35010000, 'Tiergarten Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('strandbad-wannsee', 'berlin', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Ванзее', 'Strandbad Wannsee', 'Ванзее жағажайы', 52.43370000, 13.16500000, 'Strandbad Wannsee Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('mauerpark-flea-market', 'berlin', 'MARKET', 2, 'HOURS', 4.6, 'Блошиный рынок Мауэрпарк', 'Mauerpark Flea Market', 'Мауэрпарк базары', 52.54180000, 13.40270000, 'Mauerpark Flea Market Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('markthalle-neun', 'berlin', 'MARKET', 2, 'HOURS', 4.6, 'Markthalle Neun', 'Markthalle Neun', 'Markthalle Neun', 52.50220000, 13.43180000, 'Markthalle Neun Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('mall-of-berlin', 'berlin', 'SHOPPING', 2, 'HOURS', 4.4, 'Mall of Berlin', 'Mall of Berlin', 'Mall of Berlin', 52.51000000, 13.37900000, 'Mall of Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),
    ('zoo-berlin', 'berlin', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Берлинский зоопарк', 'Zoo Berlin', 'Берлин хайуанаттар бағы', 52.50800000, 13.33700000, 'Zoo Berlin Germany', ARRAY['berlin']::text[], ARRAY['berlin']::text[], 'Brandenburger_Tor_morgens.jpg'),

    ('sanssouci-palace', 'potsdam', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Дворец Сан-Суси', 'Sanssouci Palace', 'Сан-Суси сарайы', 52.40330000, 13.03860000, 'Sanssouci Palace Potsdam Germany', ARRAY['potsdam']::text[], ARRAY['potsdam', 'berlin']::text[], 'Aerial_image_of_Sanssouci_(view_from_the_south).jpg'),
    ('sanssouci-park', 'potsdam', 'PARK', 3, 'HOURS', 4.8, 'Парк Сан-Суси', 'Sanssouci Park', 'Сан-Суси саябағы', 52.40080000, 13.02980000, 'Sanssouci Park Potsdam Germany', ARRAY['potsdam']::text[], ARRAY['potsdam', 'berlin']::text[], 'Aerial_image_of_Sanssouci_(view_from_the_south).jpg'),
    ('cecilienhof-palace', 'potsdam', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Цецилиенхоф', 'Cecilienhof Palace', 'Цецилиенхоф сарайы', 52.41940000, 13.07090000, 'Cecilienhof Palace Potsdam Germany', ARRAY['potsdam']::text[], ARRAY['potsdam', 'berlin']::text[], 'Aerial_image_of_Sanssouci_(view_from_the_south).jpg'),
    ('museum-barberini', 'potsdam', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Барберини', 'Museum Barberini', 'Барберини музейі', 52.39560000, 13.06160000, 'Museum Barberini Potsdam Germany', ARRAY['potsdam']::text[], ARRAY['potsdam']::text[], 'Aerial_image_of_Sanssouci_(view_from_the_south).jpg'),
    ('filmpark-babelsberg', 'potsdam', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Фильмпарк Бабельсберг', 'Babelsberg Film Park', 'Бабельсберг фильмпаркі', 52.38330000, 13.11870000, 'Babelsberg Film Park Potsdam Germany', ARRAY['potsdam']::text[], ARRAY['potsdam', 'berlin']::text[], 'Aerial_image_of_Sanssouci_(view_from_the_south).jpg'),

    ('speicherstadt', 'hamburg', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Шпайхерштадт', 'Speicherstadt', 'Шпайхерштадт', 53.54360000, 9.99400000, 'Speicherstadt Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('elbphilharmonie', 'hamburg', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Эльбская филармония', 'Elbphilharmonie', 'Эльба филармониясы', 53.54130000, 9.98400000, 'Elbphilharmonie Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Elbphilharmonie_--_2023_--_6610_(bw).jpg'),
    ('miniatur-wunderland', 'hamburg', 'ENTERTAINMENT', 3, 'HOURS', 4.9, 'Miniatur Wunderland', 'Miniatur Wunderland', 'Miniatur Wunderland', 53.54380000, 9.98820000, 'Miniatur Wunderland Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('hamburg-fish-market', 'hamburg', 'MARKET', 2, 'HOURS', 4.7, 'Рыбный рынок Гамбурга', 'Hamburg Fish Market', 'Гамбург балық базары', 53.54690000, 9.95070000, 'Hamburg Fish Market Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('st-pauli-reeperbahn', 'hamburg', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Репербан', 'Reeperbahn', 'Репербан', 53.54970000, 9.95950000, 'Reeperbahn Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Elbphilharmonie_--_2023_--_6610_(bw).jpg'),
    ('planten-un-blomen', 'hamburg', 'PARK', 2, 'HOURS', 4.6, 'Плантен ун Бломен', 'Planten un Blomen', 'Плантен ун Бломен', 53.56150000, 9.98000000, 'Planten un Blomen Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('europa-passage-hamburg', 'hamburg', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Europa Passage', 'Europa Passage Hamburg', 'Europa Passage Hamburg', 53.55160000, 9.99920000, 'Europa Passage Hamburg Germany', ARRAY['hamburg']::text[], ARRAY['hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),

    ('bremen-town-musicians', 'bremen', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Бременские музыканты', 'Bremen Town Musicians', 'Бремен музыканттары', 53.07590000, 8.80720000, 'Bremen Town Musicians Germany', ARRAY['bremen']::text[], ARRAY['bremen', 'hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('bremen-market-square', 'bremen', 'MARKET', 2, 'HOURS', 4.8, 'Рыночная площадь Бремена', 'Bremen Market Square', 'Бремен базар алаңы', 53.07560000, 8.80710000, 'Bremen Market Square Germany', ARRAY['bremen']::text[], ARRAY['bremen']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('universum-bremen', 'bremen', 'MUSEUM', 2, 'HOURS', 4.5, 'Universum Bremen', 'Universum Bremen', 'Universum Bremen', 53.10860000, 8.85190000, 'Universum Bremen Germany', ARRAY['bremen']::text[], ARRAY['bremen']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),

    ('lubeck-old-town', 'lubeck', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Любека', 'Lubeck Old Town', 'Любек ескі қаласы', 53.86670000, 10.68470000, 'Lubeck Old Town Germany', ARRAY['lubeck']::text[], ARRAY['lubeck', 'hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('holstentor', 'lubeck', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Голштинские ворота', 'Holstentor', 'Гольштентор', 53.86610000, 10.67970000, 'Holstentor Lubeck Germany', ARRAY['lubeck']::text[], ARRAY['lubeck', 'hamburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('travemunde-beach', 'lubeck', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Травемюнде', 'Travemunde Beach', 'Травемюнде жағажайы', 53.96390000, 10.87020000, 'Travemunde Beach Lubeck Germany', ARRAY['lubeck']::text[], ARRAY['lubeck', 'hamburg']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),

    ('sylt-westerland-beach', 'sylt', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Вестерланд', 'Sylt Westerland Beach', 'Зюльт Вестерланд жағажайы', 54.90790000, 8.29920000, 'Westerland Beach Sylt Germany', ARRAY['sylt']::text[], ARRAY['sylt', 'hamburg']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),
    ('kampen-red-cliff', 'sylt', 'NATURE', 2, 'HOURS', 4.7, 'Красный утес Кампена', 'Kampen Red Cliff', 'Кампен қызыл жартастары', 54.95900000, 8.34200000, 'Kampen Red Cliff Sylt Germany', ARRAY['sylt']::text[], ARRAY['sylt']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),
    ('rugen-chalk-cliffs', 'rugen', 'NATURE', 4, 'HOURS', 4.9, 'Меловые скалы Рюгена', 'Rugen Chalk Cliffs', 'Рюген бор жартастары', 54.56670000, 13.66670000, 'Rugen Chalk Cliffs Germany', ARRAY['rugen']::text[], ARRAY['rugen', 'hamburg']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),
    ('sellin-pier', 'rugen', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Пирс Зеллина', 'Sellin Pier', 'Зеллин пирсі', 54.37850000, 13.69770000, 'Sellin Pier Rugen Germany', ARRAY['rugen']::text[], ARRAY['rugen']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),
    ('sellin-beach', 'rugen', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Зеллина', 'Sellin Beach', 'Зеллин жағажайы', 54.37880000, 13.70040000, 'Sellin Beach Rugen Germany', ARRAY['rugen']::text[], ARRAY['rugen']::text[], 'Rügen,_Beach_at_Sellin_--_2009_--_1173.jpg'),
    ('herrenhausen-gardens', 'hannover', 'PARK', 3, 'HOURS', 4.7, 'Сады Херренхаузен', 'Herrenhausen Gardens', 'Херренхаузен бақтары', 52.39100000, 9.69710000, 'Herrenhausen Gardens Hannover Germany', ARRAY['hannover']::text[], ARRAY['hannover']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('maschsee-hannover', 'hannover', 'PARK', 2, 'HOURS', 4.6, 'Машзее', 'Maschsee', 'Машзее', 52.35980000, 9.73770000, 'Maschsee Hannover Germany', ARRAY['hannover']::text[], ARRAY['hannover']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('autostadt-wolfsburg', 'wolfsburg', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Autostadt Wolfsburg', 'Autostadt Wolfsburg', 'Autostadt Wolfsburg', 52.43270000, 10.79050000, 'Autostadt Wolfsburg Germany', ARRAY['wolfsburg']::text[], ARRAY['wolfsburg', 'hannover']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),
    ('phaeno-wolfsburg', 'wolfsburg', 'MUSEUM', 2, 'HOURS', 4.6, 'Phaeno Wolfsburg', 'Phaeno Wolfsburg', 'Phaeno Wolfsburg', 52.42890000, 10.79150000, 'Phaeno Wolfsburg Germany', ARRAY['wolfsburg']::text[], ARRAY['wolfsburg']::text[], 'Hamburg,_Speicherstadt,_Block_P_--_2016_--_3330-6.jpg'),

    ('marienplatz', 'munich', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Мариенплац', 'Marienplatz', 'Мариенплац', 48.13730000, 11.57550000, 'Marienplatz Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('frauenkirche-munich', 'munich', 'TEMPLE', 1, 'HOURS', 4.7, 'Фрауэнкирхе Мюнхена', 'Frauenkirche Munich', 'Мюнхен Фрауэнкирхе', 48.13860000, 11.57390000, 'Frauenkirche Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('deutsches-museum', 'munich', 'MUSEUM', 4, 'HOURS', 4.8, 'Немецкий музей', 'Deutsches Museum', 'Неміс музейі', 48.13000000, 11.58330000, 'Deutsches Museum Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('bmw-museum', 'munich', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей BMW', 'BMW Museum', 'BMW музейі', 48.17670000, 11.55920000, 'BMW Museum Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('englischer-garten', 'munich', 'PARK', 3, 'HOURS', 4.8, 'Английский сад', 'Englischer Garten', 'Ағылшын бағы', 48.15280000, 11.59190000, 'Englischer Garten Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('viktualienmarkt', 'munich', 'MARKET', 2, 'HOURS', 4.7, 'Виктуалиенмаркт', 'Viktualienmarkt', 'Виктуалиенмаркт', 48.13530000, 11.57610000, 'Viktualienmarkt Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('hofbrauhaus-am-platzl', 'munich', 'FOOD', 2, 'HOURS', 4.6, 'Хофбройхаус-ам-Плацль', 'Hofbrauhaus am Platzl', 'Хофбройхаус-ам-Плацль', 48.13750000, 11.57970000, 'Hofbrauhaus am Platzl Munich Germany', ARRAY['munich']::text[], ARRAY['munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('nuremberg-castle', 'nuremberg', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Нюрнбергская крепость', 'Nuremberg Castle', 'Нюрнберг қамалы', 49.45780000, 11.07580000, 'Nuremberg Castle Germany', ARRAY['nuremberg']::text[], ARRAY['nuremberg', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('germanisches-nationalmuseum', 'nuremberg', 'MUSEUM', 2, 'HOURS', 4.7, 'Германский национальный музей', 'Germanisches Nationalmuseum', 'Герман ұлттық музейі', 49.44830000, 11.07560000, 'Germanisches Nationalmuseum Nuremberg Germany', ARRAY['nuremberg']::text[], ARRAY['nuremberg']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('hauptmarkt-nuremberg', 'nuremberg', 'MARKET', 2, 'HOURS', 4.7, 'Главная рыночная площадь Нюрнберга', 'Hauptmarkt Nuremberg', 'Нюрнберг басты базары', 49.45370000, 11.07730000, 'Hauptmarkt Nuremberg Germany', ARRAY['nuremberg']::text[], ARRAY['nuremberg']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('st-lorenz-nuremberg', 'nuremberg', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Святого Лаврентия', 'St Lorenz Nuremberg', 'Әулие Лаврентий шіркеуі', 49.45100000, 11.07810000, 'St Lorenz Nuremberg Germany', ARRAY['nuremberg']::text[], ARRAY['nuremberg']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('ploenlein', 'rothenburg-ob-der-tauber', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Плёнляйн', 'Plonlein', 'Пленляйн', 49.37450000, 10.18010000, 'Plonlein Rothenburg ob der Tauber Germany', ARRAY['rothenburg-ob-der-tauber']::text[], ARRAY['rothenburg-ob-der-tauber', 'nuremberg']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('medieval-crime-museum', 'rothenburg-ob-der-tauber', 'MUSEUM', 2, 'HOURS', 4.6, 'Средневековый криминальный музей', 'Medieval Crime Museum', 'Ортағасырлық қылмыс музейі', 49.37560000, 10.17890000, 'Medieval Crime Museum Rothenburg Germany', ARRAY['rothenburg-ob-der-tauber']::text[], ARRAY['rothenburg-ob-der-tauber']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('neuschwanstein-castle', 'fussen', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Замок Нойшванштайн', 'Neuschwanstein Castle', 'Нойшванштайн қамалы', 47.55750000, 10.74940000, 'Neuschwanstein Castle Germany', ARRAY['fussen']::text[], ARRAY['fussen', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('hohenschwangau-castle', 'fussen', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Хоэншвангау', 'Hohenschwangau Castle', 'Хоэншвангау қамалы', 47.55560000, 10.73610000, 'Hohenschwangau Castle Germany', ARRAY['fussen']::text[], ARRAY['fussen', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('museum-bavarian-kings', 'fussen', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей баварских королей', 'Museum of the Bavarian Kings', 'Бавария корольдері музейі', 47.55360000, 10.73620000, 'Museum of the Bavarian Kings Fussen Germany', ARRAY['fussen']::text[], ARRAY['fussen']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('zugspitze', 'garmisch-partenkirchen', 'NATURE', 5, 'HOURS', 4.9, 'Цугшпитце', 'Zugspitze', 'Цугшпитце', 47.42110000, 10.98530000, 'Zugspitze Garmisch-Partenkirchen Germany', ARRAY['garmisch-partenkirchen']::text[], ARRAY['garmisch-partenkirchen', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('partnach-gorge', 'garmisch-partenkirchen', 'NATURE', 3, 'HOURS', 4.8, 'Ущелье Партнахкламм', 'Partnach Gorge', 'Партнах шатқалы', 47.46920000, 11.11860000, 'Partnach Gorge Germany', ARRAY['garmisch-partenkirchen']::text[], ARRAY['garmisch-partenkirchen', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('eibsee', 'garmisch-partenkirchen', 'NATURE', 3, 'HOURS', 4.8, 'Айбзе', 'Eibsee', 'Айбзе', 47.45780000, 10.97310000, 'Eibsee Germany', ARRAY['garmisch-partenkirchen']::text[], ARRAY['garmisch-partenkirchen']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('berchtesgaden-national-park', 'berchtesgaden', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Берхтесгаден', 'Berchtesgaden National Park', 'Берхтесгаден ұлттық паркі', 47.57000000, 12.96000000, 'Berchtesgaden National Park Germany', ARRAY['berchtesgaden']::text[], ARRAY['berchtesgaden', 'munich']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('konigssee', 'berchtesgaden', 'NATURE', 4, 'HOURS', 4.9, 'Кёнигсзе', 'Konigssee', 'Кенигсзе', 47.55000000, 12.96670000, 'Konigssee Berchtesgaden Germany', ARRAY['berchtesgaden']::text[], ARRAY['berchtesgaden']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('kehlsteinhaus', 'berchtesgaden', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Кельштайнхаус', 'Kehlsteinhaus', 'Кельштайнхаус', 47.61110000, 13.04170000, 'Kehlsteinhaus Germany', ARRAY['berchtesgaden']::text[], ARRAY['berchtesgaden']::text[], 'Schloss_Neuschwanstein_2013.jpg'),
    ('europa-park', 'rust', 'ENTERTAINMENT', 6, 'HOURS', 4.9, 'Европа-парк', 'Europa-Park', 'Еуропа-парк', 48.26830000, 7.72080000, 'Europa-Park Rust Germany', ARRAY['rust']::text[], ARRAY['rust', 'freiburg']::text[], 'Europa_Park_Entrance_2016.jpg'),
    ('rulantica', 'rust', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Rulantica', 'Rulantica', 'Rulantica', 48.26060000, 7.74000000, 'Rulantica Rust Germany', ARRAY['rust']::text[], ARRAY['rust', 'freiburg']::text[], 'Europa_Park_Entrance_2016.jpg'),

    ('cologne-cathedral', 'cologne', 'TEMPLE', 2, 'HOURS', 4.9, 'Кёльнский собор', 'Cologne Cathedral', 'Кельн соборы', 50.94130000, 6.95830000, 'Cologne Cathedral Germany', ARRAY['cologne']::text[], ARRAY['cologne', 'dusseldorf']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('museum-ludwig', 'cologne', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Людвига', 'Museum Ludwig', 'Людвиг музейі', 50.94090000, 6.95980000, 'Museum Ludwig Cologne Germany', ARRAY['cologne']::text[], ARRAY['cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('hohenzollern-bridge', 'cologne', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мост Гогенцоллернов', 'Hohenzollern Bridge', 'Гогенцоллерн көпірі', 50.94180000, 6.96500000, 'Hohenzollern Bridge Cologne Germany', ARRAY['cologne']::text[], ARRAY['cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('rhine-boulevard-cologne', 'cologne', 'PARK', 2, 'HOURS', 4.6, 'Рейнский бульвар', 'Rhine Boulevard', 'Рейн бульвары', 50.93840000, 6.97060000, 'Rhine Boulevard Cologne Germany', ARRAY['cologne']::text[], ARRAY['cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('schildergasse', 'cologne', 'SHOPPING', 2, 'HOURS', 4.5, 'Шильдергассе', 'Schildergasse', 'Шильдергассе', 50.93650000, 6.95280000, 'Schildergasse Cologne Germany', ARRAY['cologne']::text[], ARRAY['cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('konigsallee', 'dusseldorf', 'SHOPPING', 2, 'HOURS', 4.8, 'Кёнигсаллее', 'Konigsallee', 'Кенигсаллее', 51.22450000, 6.77820000, 'Konigsallee Dusseldorf Germany', ARRAY['dusseldorf']::text[], ARRAY['dusseldorf', 'cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('carlsplatz-market', 'dusseldorf', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Карлсплац', 'Carlsplatz Market', 'Карлсплац базары', 51.22360000, 6.77240000, 'Carlsplatz Market Dusseldorf Germany', ARRAY['dusseldorf']::text[], ARRAY['dusseldorf']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('media-harbour', 'dusseldorf', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Медиа-гавань', 'Media Harbour', 'Медиа айлақ', 51.21650000, 6.75570000, 'Media Harbour Dusseldorf Germany', ARRAY['dusseldorf']::text[], ARRAY['dusseldorf']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('beethoven-house', 'bonn', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом Бетховена', 'Beethoven House', 'Бетховен үйі', 50.73690000, 7.10130000, 'Beethoven House Bonn Germany', ARRAY['bonn']::text[], ARRAY['bonn', 'cologne']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('haus-der-geschichte', 'bonn', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом истории ФРГ', 'Haus der Geschichte', 'Германия тарих үйі', 50.71720000, 7.11880000, 'Haus der Geschichte Bonn Germany', ARRAY['bonn']::text[], ARRAY['bonn']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('rheinaue-park', 'bonn', 'PARK', 2, 'HOURS', 4.6, 'Парк Рейнауэ', 'Rheinaue Park', 'Рейнауэ саябағы', 50.70480000, 7.14230000, 'Rheinaue Park Bonn Germany', ARRAY['bonn']::text[], ARRAY['bonn']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('romerberg', 'frankfurt', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Рёмерберг', 'Romerberg', 'Ремерберг', 50.11050000, 8.68210000, 'Romerberg Frankfurt Germany', ARRAY['frankfurt']::text[], ARRAY['frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('frankfurt-cathedral', 'frankfurt', 'TEMPLE', 1, 'HOURS', 4.6, 'Франкфуртский собор', 'Frankfurt Cathedral', 'Франкфурт соборы', 50.11060000, 8.68520000, 'Frankfurt Cathedral Germany', ARRAY['frankfurt']::text[], ARRAY['frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('staedel-museum', 'frankfurt', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Штеделя', 'Stadel Museum', 'Штедель музейі', 50.10300000, 8.67380000, 'Stadel Museum Frankfurt Germany', ARRAY['frankfurt']::text[], ARRAY['frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('kleinmarkthalle', 'frankfurt', 'MARKET', 2, 'HOURS', 4.7, 'Клайнмаркхалле', 'Kleinmarkthalle', 'Клайнмаркхалле', 50.11280000, 8.68200000, 'Kleinmarkthalle Frankfurt Germany', ARRAY['frankfurt']::text[], ARRAY['frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('myzeil', 'frankfurt', 'SHOPPING', 2, 'HOURS', 4.4, 'MyZeil', 'MyZeil', 'MyZeil', 50.11400000, 8.68140000, 'MyZeil Frankfurt Germany', ARRAY['frankfurt']::text[], ARRAY['frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('mainz-cathedral', 'mainz', 'TEMPLE', 1, 'HOURS', 4.7, 'Майнцский собор', 'Mainz Cathedral', 'Майнц соборы', 49.99940000, 8.27440000, 'Mainz Cathedral Germany', ARRAY['mainz']::text[], ARRAY['mainz', 'frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('gutenberg-museum', 'mainz', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Гутенберга', 'Gutenberg Museum', 'Гутенберг музейі', 50.00290000, 8.27050000, 'Gutenberg Museum Mainz Germany', ARRAY['mainz']::text[], ARRAY['mainz']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('mainz-weekly-market', 'mainz', 'MARKET', 1, 'HOURS', 4.5, 'Еженедельный рынок Майнца', 'Mainz Weekly Market', 'Майнц апталық базары', 49.99970000, 8.27480000, 'Mainz Weekly Market Germany', ARRAY['mainz']::text[], ARRAY['mainz']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('deutsches-eck', 'koblenz', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Немецкий угол', 'Deutsches Eck', 'Неміс бұрышы', 50.36470000, 7.60560000, 'Deutsches Eck Koblenz Germany', ARRAY['koblenz']::text[], ARRAY['koblenz', 'frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('ehrenbreitstein-fortress', 'koblenz', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Эренбрайтштайн', 'Ehrenbreitstein Fortress', 'Эренбрайтштайн қамалы', 50.36360000, 7.61520000, 'Ehrenbreitstein Fortress Koblenz Germany', ARRAY['koblenz']::text[], ARRAY['koblenz']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('koblenz-cable-car', 'koblenz', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канатная дорога Кобленца', 'Koblenz Cable Car', 'Кобленц аспалы жолы', 50.36520000, 7.60730000, 'Koblenz Cable Car Germany', ARRAY['koblenz']::text[], ARRAY['koblenz']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('porta-nigra', 'trier', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Порта Нигра', 'Trier Porta Nigra', 'Трир Порта Нигра', 49.75960000, 6.64420000, 'Porta Nigra Trier Germany', ARRAY['trier']::text[], ARRAY['trier', 'frankfurt']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('trier-cathedral', 'trier', 'TEMPLE', 1, 'HOURS', 4.7, 'Трирский собор', 'Trier Cathedral', 'Трир соборы', 49.75670000, 6.64360000, 'Trier Cathedral Germany', ARRAY['trier']::text[], ARRAY['trier']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('karl-marx-house', 'trier', 'MUSEUM', 1, 'HOURS', 4.5, 'Дом Карла Маркса', 'Karl Marx House', 'Карл Маркс үйі', 49.75450000, 6.63860000, 'Karl Marx House Trier Germany', ARRAY['trier']::text[], ARRAY['trier']::text[], 'Skyline_Frankfurt_am_Main_2015.jpg'),
    ('gasometer-oberhausen', 'oberhausen', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Газометр Оберхаузен', 'Gasometer Oberhausen', 'Оберхаузен газометрі', 51.49440000, 6.87000000, 'Gasometer Oberhausen Germany', ARRAY['oberhausen']::text[], ARRAY['oberhausen', 'dusseldorf']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),
    ('westfield-centro', 'oberhausen', 'SHOPPING', 3, 'HOURS', 4.5, 'Westfield Centro', 'Westfield Centro', 'Westfield Centro', 51.49180000, 6.87950000, 'Westfield Centro Oberhausen Germany', ARRAY['oberhausen']::text[], ARRAY['oberhausen', 'dusseldorf']::text[], 'Cologne_-_Panoramic_Image_of_the_old_town_at_dusk.jpg'),

    ('heidelberg-castle', 'heidelberg', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Гейдельбергский замок', 'Heidelberg Castle', 'Гейдельберг қамалы', 49.41060000, 8.71530000, 'Heidelberg Castle Germany', ARRAY['heidelberg']::text[], ARRAY['heidelberg', 'frankfurt']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('old-bridge-heidelberg', 'heidelberg', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Старый мост Гейдельберга', 'Old Bridge Heidelberg', 'Гейдельберг ескі көпірі', 49.41420000, 8.70990000, 'Old Bridge Heidelberg Germany', ARRAY['heidelberg']::text[], ARRAY['heidelberg']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('philosophers-walk', 'heidelberg', 'NATURE', 2, 'HOURS', 4.7, 'Тропа философов', 'Philosophers Walk', 'Философтар жолы', 49.41750000, 8.70460000, 'Philosophers Walk Heidelberg Germany', ARRAY['heidelberg']::text[], ARRAY['heidelberg']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('mercedes-benz-museum', 'stuttgart', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Mercedes-Benz', 'Mercedes-Benz Museum', 'Mercedes-Benz музейі', 48.78810000, 9.23410000, 'Mercedes-Benz Museum Stuttgart Germany', ARRAY['stuttgart']::text[], ARRAY['stuttgart']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('porsche-museum', 'stuttgart', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Porsche', 'Porsche Museum', 'Porsche музейі', 48.83460000, 9.15270000, 'Porsche Museum Stuttgart Germany', ARRAY['stuttgart']::text[], ARRAY['stuttgart']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('schlossplatz-stuttgart', 'stuttgart', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Дворцовая площадь Штутгарта', 'Schlossplatz Stuttgart', 'Штутгарт сарай алаңы', 48.77840000, 9.18000000, 'Schlossplatz Stuttgart Germany', ARRAY['stuttgart']::text[], ARRAY['stuttgart']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('milaneo', 'stuttgart', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Milaneo', 'Milaneo', 'Milaneo', 48.79290000, 9.18200000, 'Milaneo Stuttgart Germany', ARRAY['stuttgart']::text[], ARRAY['stuttgart']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('baden-baden-kurhaus', 'baden-baden', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Курхаус Баден-Бадена', 'Baden-Baden Kurhaus', 'Баден-Баден курхаусы', 48.76060000, 8.23980000, 'Baden-Baden Kurhaus Germany', ARRAY['baden-baden']::text[], ARRAY['baden-baden', 'stuttgart']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('caracalla-therme', 'baden-baden', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Термы Каракалла', 'Caracalla Therme', 'Каракалла термалары', 48.76290000, 8.24610000, 'Caracalla Therme Baden-Baden Germany', ARRAY['baden-baden']::text[], ARRAY['baden-baden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('black-forest-scenic-route', 'freiburg', 'NATURE', 5, 'HOURS', 4.8, 'Живописный маршрут Шварцвальда', 'Black Forest Scenic Route', 'Қара орман көрікті маршруты', 47.99590000, 7.85220000, 'Black Forest Scenic Route Freiburg Germany', ARRAY['freiburg']::text[], ARRAY['freiburg', 'baden-baden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('freiburg-minster', 'freiburg', 'TEMPLE', 1, 'HOURS', 4.8, 'Фрайбургский мюнстер', 'Freiburg Minster', 'Фрайбург мюнстері', 47.99580000, 7.85270000, 'Freiburg Minster Germany', ARRAY['freiburg']::text[], ARRAY['freiburg']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('freiburg-munster-market', 'freiburg', 'MARKET', 2, 'HOURS', 4.7, 'Рынок у Фрайбургского мюнстера', 'Freiburg Munster Market', 'Фрайбург мюнстер базары', 47.99570000, 7.85240000, 'Freiburg Munster Market Germany', ARRAY['freiburg']::text[], ARRAY['freiburg']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('dresden-frauenkirche', 'dresden', 'TEMPLE', 1, 'HOURS', 4.9, 'Дрезденская Фрауэнкирхе', 'Dresden Frauenkirche', 'Дрезден Фрауэнкирхе', 51.05190000, 13.74150000, 'Dresden Frauenkirche Germany', ARRAY['dresden']::text[], ARRAY['dresden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('zwinger-palace', 'dresden', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Дворец Цвингер', 'Zwinger Palace', 'Цвингер сарайы', 51.05310000, 13.73380000, 'Zwinger Palace Dresden Germany', ARRAY['dresden']::text[], ARRAY['dresden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('green-vault', 'dresden', 'MUSEUM', 2, 'HOURS', 4.8, 'Зелёные своды', 'Green Vault', 'Жасыл күмбездер', 51.05200000, 13.73690000, 'Green Vault Dresden Germany', ARRAY['dresden']::text[], ARRAY['dresden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('bruhl-terrace', 'dresden', 'PARK', 1, 'HOURS', 4.7, 'Терраса Брюля', 'Bruhl Terrace', 'Брюль террасасы', 51.05380000, 13.74200000, 'Bruhl Terrace Dresden Germany', ARRAY['dresden']::text[], ARRAY['dresden']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('leipzig-zoo', 'leipzig', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Лейпцигский зоопарк', 'Leipzig Zoo', 'Лейпциг хайуанаттар бағы', 51.34900000, 12.36700000, 'Leipzig Zoo Germany', ARRAY['leipzig']::text[], ARRAY['leipzig']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('monument-battle-nations', 'leipzig', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Памятник Битве народов', 'Monument to the Battle of the Nations', 'Халықтар шайқасы ескерткіші', 51.31220000, 12.41310000, 'Monument to the Battle of the Nations Leipzig Germany', ARRAY['leipzig']::text[], ARRAY['leipzig']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('st-thomas-church-leipzig', 'leipzig', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Святого Фомы', 'St Thomas Church Leipzig', 'Лейпциг Әулие Фома шіркеуі', 51.33940000, 12.37310000, 'St Thomas Church Leipzig Germany', ARRAY['leipzig']::text[], ARRAY['leipzig']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('museumsquartier-weimar', 'weimar', 'MUSEUM', 2, 'HOURS', 4.6, 'Музейный квартал Веймара', 'MuseumsQuartier Weimar', 'Веймар музей кварталы', 50.97950000, 11.32900000, 'MuseumsQuartier Weimar Germany', ARRAY['weimar']::text[], ARRAY['weimar']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('goethe-house-weimar', 'weimar', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом Гёте в Веймаре', 'Goethe House Weimar', 'Веймар Гете үйі', 50.97870000, 11.32980000, 'Goethe House Weimar Germany', ARRAY['weimar']::text[], ARRAY['weimar']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('egapark-erfurt', 'erfurt', 'PARK', 3, 'HOURS', 4.6, 'Egapark Erfurt', 'Egapark Erfurt', 'Egapark Erfurt', 50.96390000, 10.99970000, 'Egapark Erfurt Germany', ARRAY['erfurt']::text[], ARRAY['erfurt']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('kramerbrucke-erfurt', 'erfurt', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Кремербрюкке', 'Kramerbrucke Erfurt', 'Эрфурт Кремербрюкке', 50.97800000, 11.03090000, 'Kramerbrucke Erfurt Germany', ARRAY['erfurt']::text[], ARRAY['erfurt']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('goslar-old-town', 'goslar', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Старый город Гослара', 'Goslar Old Town', 'Гослар ескі қаласы', 51.90500000, 10.42900000, 'Goslar Old Town Germany', ARRAY['goslar']::text[], ARRAY['goslar']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('rammelsberg-museum', 'goslar', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей Раммельсберг', 'Rammelsberg Museum', 'Раммельсберг музейі', 51.88920000, 10.41860000, 'Rammelsberg Museum Goslar Germany', ARRAY['goslar']::text[], ARRAY['goslar']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('wernigerode-castle', 'wernigerode', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Вернигероде', 'Wernigerode Castle', 'Вернигероде қамалы', 51.83070000, 10.79570000, 'Wernigerode Castle Germany', ARRAY['wernigerode']::text[], ARRAY['wernigerode']::text[], 'Dresden-nightpanorama-dri.jpg'),
    ('brocken-railway', 'wernigerode', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Брокенская железная дорога', 'Brocken Railway', 'Брокен теміржолы', 51.83630000, 10.78290000, 'Brocken Railway Wernigerode Germany', ARRAY['wernigerode']::text[], ARRAY['wernigerode', 'goslar']::text[], 'Dresden-nightpanorama-dri.jpg');

CREATE TEMP TABLE seed_germany_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-germany-attraction:' || seed.slug) AS attraction_hash,
        md5('id-germany-media:' || seed.slug) AS media_hash
    FROM seed_germany_priority_attractions seed
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
    ARRAY['germany', city_id, slug, lower(category), 'germany-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Германии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Germany tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Германия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'DE',
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
FROM seed_germany_resolved_attractions
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
FROM seed_germany_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_germany_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_germany_resolved_attractions
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
FROM seed_germany_resolved_attractions seed
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
FROM seed_germany_resolved_attractions
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
    'DE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_germany_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'DE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_germany_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_germany_resolved_attractions;
DROP TABLE IF EXISTS seed_germany_priority_attractions;
