-- Priority Malta destination places seed.
-- Malta is seeded as a compact country destination with city-like tourist hubs
-- for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_malta_resolved_places;
DROP TABLE IF EXISTS seed_malta_priority_places;

CREATE TEMP TABLE seed_malta_priority_places (
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

INSERT INTO seed_malta_priority_places (
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
    ('st-johns-co-cathedral', 'valletta', 'TEMPLE', 2, 'HOURS', 4.9, 'Собор Святого Иоанна', $$St John's Co-Cathedral$$, 'Әулие Иоанн соборы', 35.89790000, 14.51250000, 'St Johns Co Cathedral Valletta Malta', ARRAY['valletta', 'sliema', 'st-julians']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('upper-barrakka-gardens', 'valletta', 'PARK', 1, 'HOURS', 4.8, 'Верхние сады Баракка', 'Upper Barrakka Gardens', 'Жоғарғы Баракка бақтары', 35.89530000, 14.51280000, 'Upper Barrakka Gardens Valletta Malta', ARRAY['valletta', 'birgu', 'sliema']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('lower-barrakka-gardens', 'valletta', 'PARK', 1, 'HOURS', 4.6, 'Нижние сады Баракка', 'Lower Barrakka Gardens', 'Төменгі Баракка бақтары', 35.89900000, 14.51800000, 'Lower Barrakka Gardens Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('grand-masters-palace', 'valletta', 'MUSEUM', 2, 'HOURS', 4.8, 'Дворец Великого магистра', $$Grand Master's Palace$$, 'Ұлы магистр сарайы', 35.89890000, 14.51460000, 'Grand Masters Palace Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('national-museum-archaeology-valletta', 'valletta', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей археологии', 'National Museum of Archaeology', 'Ұлттық археология музейі', 35.89850000, 14.51210000, 'National Museum of Archaeology Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('fort-st-elmo-war-museum', 'valletta', 'MUSEUM', 2, 'HOURS', 4.7, 'Форт Сент-Эльмо и Национальный военный музей', 'Fort St Elmo and National War Museum', 'Сент-Эльмо форты және әскери музей', 35.90270000, 14.51860000, 'Fort St Elmo National War Museum Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('is-suq-tal-belt', 'valletta', 'FOOD', 2, 'HOURS', 4.5, 'Is-Suq tal-Belt', 'Is-Suq tal-Belt', 'Is-Suq tal-Belt', 35.89770000, 14.51330000, 'Is-Suq tal-Belt Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('lascaris-war-rooms', 'valletta', 'MUSEUM', 2, 'HOURS', 4.7, 'Военные комнаты Ласкарис', 'Lascaris War Rooms', 'Ласкарис әскери бөлмелері', 35.89500000, 14.51290000, 'Lascaris War Rooms Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('manoel-theatre', 'valletta', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Театр Маноэль', 'Manoel Theatre', 'Маноэль театры', 35.90010000, 14.51370000, 'Manoel Theatre Valletta Malta', ARRAY['valletta']::text[], ARRAY['valletta']::text[], 'Valletta_Lower_Barrakka_gardens_Malta_2014_2.jpg'),
    ('valletta-waterfront', 'valletta', 'FOOD', 2, 'HOURS', 4.6, 'Набережная Валлетты', 'Valletta Waterfront', 'Валлетта жағалауы', 35.88660000, 14.50860000, 'Valletta Waterfront Malta', ARRAY['valletta', 'sliema']::text[], ARRAY['valletta']::text[], 'Malta_-_Floriana_-_Valletta_Waterfront_+_Laguna_Marina_01_ies.jpg'),

    ('the-point-shopping-mall', 'sliema', 'SHOPPING', 3, 'HOURS', 4.5, 'The Point Shopping Mall', 'The Point Shopping Mall', 'The Point Shopping Mall', 35.90790000, 14.50940000, 'The Point Shopping Mall Sliema Malta', ARRAY['sliema', 'valletta', 'st-julians']::text[], ARRAY['sliema']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('sliema-promenade', 'sliema', 'PARK', 2, 'HOURS', 4.6, 'Набережная Слимы', 'Sliema Promenade', 'Слима жағалауы', 35.91430000, 14.50050000, 'Sliema Promenade Malta', ARRAY['sliema', 'st-julians']::text[], ARRAY['sliema']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('plaza-shopping-centre-sliema', 'sliema', 'SHOPPING', 2, 'HOURS', 4.3, 'Plaza Shopping Centre', 'Plaza Shopping Centre', 'Plaza Shopping Centre', 35.91150000, 14.50360000, 'Plaza Shopping Centre Sliema Malta', ARRAY['sliema']::text[], ARRAY['sliema']::text[], 'Malta,_Spinola_Bay.jpg'),

    ('spinola-bay', 'st-julians', 'FOOD', 2, 'HOURS', 4.7, 'Залив Спинола', 'Spinola Bay', 'Спинола шығанағы', 35.91840000, 14.49290000, 'Spinola Bay St Julians Malta', ARRAY['st-julians', 'sliema']::text[], ARRAY['st-julians']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('paceville', 'st-julians', 'ENTERTAINMENT', 3, 'HOURS', 4.3, 'Пачевиль', 'Paceville', 'Пачевиль', 35.92320000, 14.48970000, 'Paceville St Julians Malta', ARRAY['st-julians', 'sliema']::text[], ARRAY['st-julians']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('st-georges-bay', 'st-julians', 'BEACH', 3, 'HOURS', 4.4, 'Залив Сент-Джордж', 'St George''s Bay', 'Сент-Джордж шығанағы', 35.92460000, 14.48880000, 'St Georges Bay St Julians Malta', ARRAY['st-julians']::text[], ARRAY['st-julians']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('bay-street-shopping-complex', 'st-julians', 'SHOPPING', 2, 'HOURS', 4.3, 'Bay Street Shopping Complex', 'Bay Street Shopping Complex', 'Bay Street Shopping Complex', 35.92400000, 14.48890000, 'Bay Street Shopping Complex St Julians Malta', ARRAY['st-julians']::text[], ARRAY['st-julians']::text[], 'Malta,_Spinola_Bay.jpg'),
    ('portomaso-marina', 'st-julians', 'FOOD', 2, 'HOURS', 4.5, 'Марина Портомасо', 'Portomaso Marina', 'Портомасо маринасы', 35.92100000, 14.49350000, 'Portomaso Marina St Julians Malta', ARRAY['st-julians']::text[], ARRAY['st-julians']::text[], 'Malta,_Spinola_Bay.jpg'),

    ('fort-st-angelo', 'birgu', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Форт Сент-Анджело', 'Fort St Angelo', 'Сент-Анджело форты', 35.89290000, 14.51890000, 'Fort St Angelo Birgu Malta', ARRAY['birgu', 'valletta']::text[], ARRAY['birgu', 'valletta']::text[], 'Fort_Saint_Angelo_at_night,_Birgu,_Malta.jpg'),
    ('inquisitors-palace', 'birgu', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Инквизитора', 'Inquisitor''s Palace', 'Инквизитор сарайы', 35.88710000, 14.52380000, 'Inquisitors Palace Birgu Malta', ARRAY['birgu']::text[], ARRAY['birgu']::text[], 'Fort_Saint_Angelo_at_night,_Birgu,_Malta.jpg'),
    ('malta-maritime-museum', 'birgu', 'MUSEUM', 2, 'HOURS', 4.5, 'Морской музей Мальты', 'Malta Maritime Museum', 'Мальта теңіз музейі', 35.88970000, 14.52190000, 'Malta Maritime Museum Birgu Malta', ARRAY['birgu']::text[], ARRAY['birgu']::text[], 'Fort_Saint_Angelo_at_night,_Birgu,_Malta.jpg'),
    ('vittoriosa-waterfront', 'birgu', 'FOOD', 2, 'HOURS', 4.6, 'Набережная Витториозы', 'Vittoriosa Waterfront', 'Витториоза жағалауы', 35.88790000, 14.52060000, 'Vittoriosa Waterfront Birgu Malta', ARRAY['birgu', 'valletta']::text[], ARRAY['birgu']::text[], 'Fort_Saint_Angelo_at_night,_Birgu,_Malta.jpg'),

    ('mdina-silent-city', 'mdina', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Мдина, Тихий город', 'Mdina Silent City', 'Мдина тыныш қаласы', 35.88640000, 14.40310000, 'Mdina Silent City Malta', ARRAY['mdina', 'rabat-malta', 'valletta']::text[], ARRAY['mdina', 'valletta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('mdina-main-gate', 'mdina', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Главные ворота Мдины', 'Mdina Main Gate', 'Мдина бас қақпасы', 35.88590000, 14.40380000, 'Mdina Main Gate Malta', ARRAY['mdina']::text[], ARRAY['mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('st-pauls-cathedral-mdina', 'mdina', 'TEMPLE', 1, 'HOURS', 4.7, 'Собор Святого Павла в Мдине', 'St Paul''s Cathedral Mdina', 'Мдинадағы Әулие Павел соборы', 35.88650000, 14.40390000, 'St Pauls Cathedral Mdina Malta', ARRAY['mdina']::text[], ARRAY['mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('palazzo-falson', 'mdina', 'MUSEUM', 1, 'HOURS', 4.6, 'Палаццо Фальсон', 'Palazzo Falson Historic House Museum', 'Палаццо Фальсон музейі', 35.88700000, 14.40270000, 'Palazzo Falson Mdina Malta', ARRAY['mdina']::text[], ARRAY['mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('national-museum-natural-history-mdina', 'mdina', 'MUSEUM', 1, 'HOURS', 4.4, 'Национальный музей естественной истории', 'National Museum of Natural History', 'Ұлттық табиғат тарихы музейі', 35.88570000, 14.40390000, 'National Museum of Natural History Mdina Malta', ARRAY['mdina']::text[], ARRAY['mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('mdina-dungeons', 'mdina', 'ENTERTAINMENT', 1, 'HOURS', 4.3, 'Подземелья Мдины', 'Mdina Dungeons', 'Мдина зындандары', 35.88590000, 14.40360000, 'Mdina Dungeons Malta', ARRAY['mdina']::text[], ARRAY['mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),

    ('st-pauls-catacombs', 'rabat-malta', 'MUSEUM', 2, 'HOURS', 4.7, 'Катакомбы Святого Павла', $$St Paul's Catacombs$$, 'Әулие Павел катакомбалары', 35.88090000, 14.39760000, 'St Pauls Catacombs Rabat Malta', ARRAY['rabat-malta', 'mdina']::text[], ARRAY['rabat-malta', 'mdina']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('domvs-romana', 'rabat-malta', 'MUSEUM', 1, 'HOURS', 4.5, 'Домус Романа', 'Domvs Romana', 'Domvs Romana', 35.88100000, 14.40000000, 'Domvs Romana Rabat Malta', ARRAY['rabat-malta', 'mdina']::text[], ARRAY['rabat-malta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('st-pauls-grotto-rabat', 'rabat-malta', 'TEMPLE', 1, 'HOURS', 4.5, 'Грот Святого Павла', 'St Paul''s Grotto', 'Әулие Павел гроты', 35.88010000, 14.39800000, 'St Pauls Grotto Rabat Malta', ARRAY['rabat-malta']::text[], ARRAY['rabat-malta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('crystal-palace-pastizzi', 'rabat-malta', 'FOOD', 1, 'HOURS', 4.5, 'Crystal Palace Pastizzi', 'Crystal Palace Pastizzi', 'Crystal Palace Pastizzi', 35.88260000, 14.39860000, 'Crystal Palace Pastizzi Rabat Malta', ARRAY['rabat-malta', 'mdina']::text[], ARRAY['rabat-malta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),

    ('mosta-rotunda', 'mosta', 'TEMPLE', 1, 'HOURS', 4.7, 'Ротонда Мосты', 'Mosta Rotunda', 'Моста ротондасы', 35.90920000, 14.42550000, 'Mosta Rotunda Malta', ARRAY['mosta', 'mdina', 'valletta']::text[], ARRAY['mosta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('ta-bistra-catacombs', 'mosta', 'MUSEUM', 1, 'HOURS', 4.3, 'Катакомбы Та-Бистра', 'Ta Bistra Catacombs', 'Та-Бистра катакомбалары', 35.91610000, 14.42740000, 'Ta Bistra Catacombs Mosta Malta', ARRAY['mosta']::text[], ARRAY['mosta']::text[], 'Malta_-_Mdina_-_Gate_01_ies.jpg'),
    ('dingli-cliffs', 'dingli', 'NATURE', 2, 'HOURS', 4.8, 'Утесы Дингли', 'Dingli Cliffs', 'Дингли жартастары', 35.86160000, 14.38360000, 'Dingli Cliffs Malta', ARRAY['dingli', 'mdina']::text[], ARRAY['dingli', 'mdina']::text[], 'Dingli_Cliffs_Malta.jpg'),
    ('st-mary-magdalene-chapel-dingli', 'dingli', 'TEMPLE', 1, 'HOURS', 4.3, 'Часовня Святой Марии Магдалины', 'St Mary Magdalene Chapel Dingli', 'Динглидегі Әулие Мария Магдалина шіркеуі', 35.86050000, 14.38280000, 'St Mary Magdalene Chapel Dingli Malta', ARRAY['dingli']::text[], ARRAY['dingli']::text[], 'Dingli_Cliffs_Malta.jpg'),
    ('san-anton-gardens', 'attard', 'PARK', 1, 'HOURS', 4.6, 'Сады Сан-Антон', 'San Anton Gardens', 'Сан-Антон бақтары', 35.89630000, 14.44630000, 'San Anton Gardens Attard Malta', ARRAY['attard', 'mdina']::text[], ARRAY['attard']::text[], 'Dingli_Cliffs_Malta.jpg'),
    ('ta-qali-artisan-village', 'ta-qali', 'SHOPPING', 2, 'HOURS', 4.4, 'Ремесленная деревня Та-Кали', 'Ta Qali Artisan Village', 'Та-Кали қолөнер ауылы', 35.89400000, 14.42030000, 'Ta Qali Crafts Village Malta', ARRAY['ta-qali', 'attard']::text[], ARRAY['ta-qali']::text[], 'Dingli_Cliffs_Malta.jpg'),
    ('ta-qali-national-park', 'ta-qali', 'PARK', 2, 'HOURS', 4.5, 'Национальный парк Та-Кали', 'Ta Qali National Park', 'Та-Кали ұлттық паркі', 35.89500000, 14.42000000, 'Ta Qali National Park Malta', ARRAY['ta-qali', 'attard']::text[], ARRAY['ta-qali']::text[], 'Dingli_Cliffs_Malta.jpg'),
    ('malta-aviation-museum', 'ta-qali', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей авиации Мальты', 'Malta Aviation Museum', 'Мальта авиация музейі', 35.89580000, 14.41860000, 'Malta Aviation Museum Ta Qali', ARRAY['ta-qali']::text[], ARRAY['ta-qali']::text[], 'Dingli_Cliffs_Malta.jpg'),

    ('mellieha-bay-ghadira', 'mellieha', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Меллиха / Гадира', 'Mellieha Bay Ghadira', 'Меллиха шығанағы', 35.97060000, 14.35030000, 'Mellieha Bay Ghadira Malta', ARRAY['mellieha', 'st-pauls-bay']::text[], ARRAY['mellieha']::text[], 'Red_tower_Mellieha_Malta.jpg'),
    ('golden-bay', 'mellieha', 'BEACH', 4, 'HOURS', 4.7, 'Голден-Бэй', 'Golden Bay', 'Голден-Бэй', 35.93450000, 14.34450000, 'Golden Bay Malta', ARRAY['mellieha']::text[], ARRAY['mellieha']::text[], 'Red_tower_Mellieha_Malta.jpg'),
    ('ghajn-tuffieha-bay', 'mellieha', 'BEACH', 4, 'HOURS', 4.8, 'Бухта Айн-Туффиха', 'Ghajn Tuffieha Bay', 'Айн-Туффиха шығанағы', 35.92820000, 14.34360000, 'Ghajn Tuffieha Bay Malta', ARRAY['mellieha']::text[], ARRAY['mellieha']::text[], 'Red_tower_Mellieha_Malta.jpg'),
    ('popeye-village', 'mellieha', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Деревня Попай', 'Popeye Village', 'Попай ауылы', 35.96020000, 14.34170000, 'Popeye Village Malta', ARRAY['mellieha', 'st-pauls-bay']::text[], ARRAY['mellieha']::text[], 'Popeye_Village.jpeg'),
    ('red-tower-mellieha', 'mellieha', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Красная башня Святой Агаты', 'St Agatha''s Tower Red Tower', 'Әулие Агата қызыл мұнарасы', 35.97060000, 14.35050000, 'Red Tower Mellieha Malta', ARRAY['mellieha']::text[], ARRAY['mellieha']::text[], 'Red_tower_Mellieha_Malta.jpg'),
    ('ghadira-nature-reserve', 'mellieha', 'NATURE', 1, 'HOURS', 4.4, 'Заповедник Гадира', 'Ghadira Nature Reserve', 'Гадира қорығы', 35.96970000, 14.35430000, 'Ghadira Nature Reserve Malta', ARRAY['mellieha']::text[], ARRAY['mellieha']::text[], 'Red_tower_Mellieha_Malta.jpg'),

    ('malta-national-aquarium', 'st-pauls-bay', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Национальный аквариум Мальты', 'Malta National Aquarium', 'Мальта ұлттық аквариумы', 35.95830000, 14.42520000, 'Malta National Aquarium Qawra Malta', ARRAY['st-pauls-bay', 'mellieha']::text[], ARRAY['st-pauls-bay']::text[], 'Malta_National_Aquarium.jpg'),
    ('bugibba-square', 'st-pauls-bay', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Площадь Буджибба', 'Bugibba Square', 'Буджибба алаңы', 35.95080000, 14.41220000, 'Bugibba Square Malta', ARRAY['st-pauls-bay']::text[], ARRAY['st-pauls-bay']::text[], 'Malta_National_Aquarium.jpg'),
    ('qawra-point-beach', 'st-pauls-bay', 'BEACH', 2, 'HOURS', 4.3, 'Пляж Qawra Point', 'Qawra Point Beach', 'Qawra Point жағажайы', 35.95890000, 14.42680000, 'Qawra Point Beach Malta', ARRAY['st-pauls-bay']::text[], ARRAY['st-pauls-bay']::text[], 'Malta_National_Aquarium.jpg'),
    ('malta-classic-car-collection', 'st-pauls-bay', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей классических автомобилей Мальты', 'Malta Classic Car Collection', 'Мальта классикалық автомобильдер музейі', 35.95470000, 14.41990000, 'Malta Classic Car Collection Qawra', ARRAY['st-pauls-bay']::text[], ARRAY['st-pauls-bay']::text[], 'Malta_National_Aquarium.jpg'),
    ('st-pauls-bay-promenade', 'st-pauls-bay', 'PARK', 2, 'HOURS', 4.4, 'Набережная Сент-Полс-Бей', 'St Pauls Bay Promenade', 'Сент-Полс-Бей жағалауы', 35.94960000, 14.41020000, 'St Pauls Bay Promenade Malta', ARRAY['st-pauls-bay']::text[], ARRAY['st-pauls-bay']::text[], 'Malta_National_Aquarium.jpg'),

    ('marsaxlokk-fish-market', 'marsaxlokk', 'MARKET', 2, 'HOURS', 4.7, 'Рыбный рынок Марсашлокка', 'Marsaxlokk Fish Market', 'Марсашлокк балық базары', 35.84190000, 14.54400000, 'Marsaxlokk Fish Market Malta', ARRAY['marsaxlokk', 'valletta']::text[], ARRAY['marsaxlokk', 'valletta']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),
    ('marsaxlokk-seafood-waterfront', 'marsaxlokk', 'FOOD', 2, 'HOURS', 4.6, 'Набережная Марсашлокка', 'Marsaxlokk Seafood Waterfront', 'Марсашлокк теңіз өнімдері жағалауы', 35.84120000, 14.54370000, 'Marsaxlokk Seafood Waterfront Malta', ARRAY['marsaxlokk']::text[], ARRAY['marsaxlokk']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),
    ('st-peters-pool', 'marsaxlokk', 'BEACH', 3, 'HOURS', 4.7, 'Бассейн Святого Петра', 'St Peters Pool', 'Әулие Петр бассейні', 35.83390000, 14.56260000, 'St Peters Pool Marsaxlokk Malta', ARRAY['marsaxlokk']::text[], ARRAY['marsaxlokk']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),
    ('il-kalanka-bay', 'marsaxlokk', 'BEACH', 3, 'HOURS', 4.5, 'Бухта Il-Kalanka', 'Il-Kalanka Bay', 'Il-Kalanka шығанағы', 35.82860000, 14.56570000, 'Il Kalanka Bay Marsaxlokk Malta', ARRAY['marsaxlokk']::text[], ARRAY['marsaxlokk']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),

    ('pretty-bay', 'birzebbuga', 'BEACH', 3, 'HOURS', 4.3, 'Претти-Бэй', 'Pretty Bay', 'Претти-Бэй', 35.82540000, 14.52800000, 'Pretty Bay Birzebbuga Malta', ARRAY['birzebbuga', 'marsaxlokk']::text[], ARRAY['birzebbuga']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),
    ('ghar-dalam', 'birzebbuga', 'MUSEUM', 1, 'HOURS', 4.6, 'Пещера и музей Гар-Далам', 'Ghar Dalam Cave and Museum', 'Гар-Далам үңгірі және музейі', 35.84090000, 14.52690000, 'Ghar Dalam Cave and Museum Malta', ARRAY['birzebbuga', 'tarxien']::text[], ARRAY['birzebbuga']::text[], 'Tarxien_Temples.jpeg'),
    ('playmobil-funpark-malta', 'birzebbuga', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Playmobil FunPark Malta', 'Playmobil FunPark Malta', 'Playmobil FunPark Malta', 35.81100000, 14.50780000, 'Playmobil FunPark Malta', ARRAY['birzebbuga']::text[], ARRAY['birzebbuga']::text[], 'Luzzu_in_Marsaxlokk_01.jpg'),

    ('blue-grotto', 'qrendi', 'NATURE', 2, 'HOURS', 4.8, 'Голубой грот', 'Blue Grotto', 'Көк грот', 35.82170000, 14.45720000, 'Blue Grotto Malta', ARRAY['qrendi', 'valletta']::text[], ARRAY['qrendi', 'valletta']::text[], 'Blue_Grotto_Malta.jpg'),
    ('hagar-qim-temples', 'qrendi', 'TEMPLE', 2, 'HOURS', 4.8, 'Хаджар-Ким', 'Hagar Qim Temples', 'Хаджар-Ким храмдары', 35.82730000, 14.44220000, 'Hagar Qim Temples Malta', ARRAY['qrendi']::text[], ARRAY['qrendi']::text[], 'Hagar_Qim06.jpg'),
    ('mnajdra-temples', 'qrendi', 'TEMPLE', 2, 'HOURS', 4.8, 'Мнайдра', 'Mnajdra Temples', 'Мнайдра храмдары', 35.82670000, 14.43690000, 'Mnajdra Temples Malta', ARRAY['qrendi']::text[], ARRAY['qrendi']::text[], 'Hagar_Qim06.jpg'),
    ('wied-iz-zurrieq', 'qrendi', 'NATURE', 2, 'HOURS', 4.5, 'Вид-из-Зуррик', 'Wied iz-Zurrieq', 'Вид-из-Зуррик', 35.82130000, 14.45790000, 'Wied iz-Zurrieq Malta', ARRAY['qrendi']::text[], ARRAY['qrendi']::text[], 'Blue_Grotto_Malta.jpg'),
    ('hypogeum-hal-saflieni', 'paola', 'MUSEUM', 2, 'HOURS', 4.9, 'Гипогей Хал-Сафлиени', 'Hypogeum of Hal Saflieni', 'Хал-Сафлиени гипогейі', 35.86960000, 14.50690000, 'Hal Saflieni Hypogeum Paola Malta', ARRAY['paola', 'tarxien']::text[], ARRAY['paola']::text[], 'Tarxien_Temples.jpeg'),
    ('tarxien-temples', 'tarxien', 'TEMPLE', 2, 'HOURS', 4.7, 'Храмы Таршиен', 'Tarxien Temples', 'Таршиен храмдары', 35.86960000, 14.51260000, 'Tarxien Temples Malta', ARRAY['tarxien', 'paola']::text[], ARRAY['tarxien']::text[], 'Tarxien_Temples.jpeg'),

    ('ta-pinu-basilica', 'gozo', 'TEMPLE', 2, 'HOURS', 4.8, 'Базилика Та-Пину', 'Ta Pinu Basilica', 'Та-Пину базиликасы', 36.06120000, 14.21440000, 'Ta Pinu Basilica Gozo Malta', ARRAY['gozo', 'victoria-gozo']::text[], ARRAY['gozo', 'victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('xwejni-salt-pans', 'gozo', 'NATURE', 1, 'HOURS', 4.6, 'Солончаки Швейни', 'Xwejni Salt Pans', 'Швейни тұз алаңдары', 36.07700000, 14.25190000, 'Xwejni Salt Pans Gozo Malta', ARRAY['gozo', 'marsalforn']::text[], ARRAY['gozo', 'marsalforn']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('ta-dbiegi-crafts-village', 'gozo', 'SHOPPING', 2, 'HOURS', 4.4, 'Ремесленная деревня Та-Дбиеги', 'Ta Dbiegi Crafts Village', 'Та-Дбиеги қолөнер ауылы', 36.06240000, 14.20360000, 'Ta Dbiegi Crafts Village Gozo Malta', ARRAY['gozo', 'victoria-gozo']::text[], ARRAY['gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('dwejra-bay', 'gozo', 'NATURE', 3, 'HOURS', 4.8, 'Бухта Двейра', 'Dwejra Bay', 'Двейра шығанағы', 36.05070000, 14.18840000, 'Dwejra Bay Gozo Malta', ARRAY['gozo', 'victoria-gozo']::text[], ARRAY['gozo', 'victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('cittadella-gozo', 'victoria-gozo', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Цитадель Гозо', 'The Citadel Gozo', 'Гозо цитаделі', 36.04670000, 14.23920000, 'Cittadella Victoria Gozo Malta', ARRAY['victoria-gozo', 'gozo']::text[], ARRAY['victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('gozo-old-prison', 'victoria-gozo', 'MUSEUM', 1, 'HOURS', 4.5, 'Старая тюрьма Гозо', 'The Old Prison Gozo', 'Гозо ескі түрмесі', 36.04670000, 14.23950000, 'Old Prison Gozo Malta', ARRAY['victoria-gozo']::text[], ARRAY['victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('villa-rundle-gardens', 'victoria-gozo', 'PARK', 1, 'HOURS', 4.4, 'Сады Вилла Рандл', 'Villa Rundle Gardens', 'Вилла Рандл бақтары', 36.04270000, 14.24230000, 'Villa Rundle Gardens Gozo Malta', ARRAY['victoria-gozo']::text[], ARRAY['victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('it-tokk-market', 'victoria-gozo', 'MARKET', 1, 'HOURS', 4.4, 'Ит-Токк и рынок Савина', 'It-Tokk and Savina Market', 'Ит-Токк және Савина базары', 36.04420000, 14.23960000, 'It-Tokk Victoria Gozo Malta', ARRAY['victoria-gozo']::text[], ARRAY['victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('ggantija-temples', 'xaghra', 'TEMPLE', 2, 'HOURS', 4.9, 'Храмы Джгантия', 'Ggantija Temples', 'Джгантия храмдары', 36.04910000, 14.26750000, 'Ggantija Temples Xaghra Gozo Malta', ARRAY['xaghra', 'gozo']::text[], ARRAY['xaghra', 'victoria-gozo']::text[], 'Ggantija_Temples,_Xaghra,_Gozo.jpg'),
    ('ramla-bay', 'xaghra', 'BEACH', 4, 'HOURS', 4.8, 'Бухта Рамла', 'Ramla Bay', 'Рамла шығанағы', 36.06110000, 14.28400000, 'Ramla Bay Gozo Malta', ARRAY['xaghra', 'gozo']::text[], ARRAY['xaghra']::text[], 'Ggantija_Temples,_Xaghra,_Gozo.jpg'),
    ('ta-kola-windmill', 'xaghra', 'MUSEUM', 1, 'HOURS', 4.5, 'Ветряная мельница Та-Кола', 'Ta Kola Windmill', 'Та-Кола жел диірмені', 36.05060000, 14.26740000, 'Ta Kola Windmill Xaghra Gozo Malta', ARRAY['xaghra']::text[], ARRAY['xaghra']::text[], 'Ggantija_Temples,_Xaghra,_Gozo.jpg'),
    ('calypso-cave', 'xaghra', 'NATURE', 1, 'HOURS', 4.3, 'Пещера Калипсо', 'Calypso Cave', 'Калипсо үңгірі', 36.06170000, 14.27770000, 'Calypso Cave Xaghra Gozo Malta', ARRAY['xaghra', 'gozo']::text[], ARRAY['xaghra']::text[], 'Ggantija_Temples,_Xaghra,_Gozo.jpg'),
    ('xlendi-bay', 'xlendi', 'BEACH', 3, 'HOURS', 4.7, 'Бухта Шленди', 'Xlendi Bay', 'Шленди шығанағы', 36.03080000, 14.21790000, 'Xlendi Bay Gozo Malta', ARRAY['xlendi', 'gozo']::text[], ARRAY['xlendi', 'victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('xlendi-tower', 'xlendi', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Башня Шленди', 'Xlendi Tower', 'Шленди мұнарасы', 36.02760000, 14.21640000, 'Xlendi Tower Gozo Malta', ARRAY['xlendi']::text[], ARRAY['xlendi']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('marsalforn-bay', 'marsalforn', 'BEACH', 3, 'HOURS', 4.5, 'Бухта Марсалфорн', 'Marsalforn Bay', 'Марсалфорн шығанағы', 36.07110000, 14.25810000, 'Marsalforn Bay Gozo Malta', ARRAY['marsalforn', 'gozo']::text[], ARRAY['marsalforn', 'victoria-gozo']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('marsalforn-waterfront', 'marsalforn', 'FOOD', 2, 'HOURS', 4.4, 'Набережная Марсалфорна', 'Marsalforn Waterfront', 'Марсалфорн жағалауы', 36.07140000, 14.25890000, 'Marsalforn Waterfront Gozo Malta', ARRAY['marsalforn']::text[], ARRAY['marsalforn']::text[], 'Cittadella_Fortifications,_in_Gozo.jpg'),
    ('blue-lagoon-comino', 'comino', 'BEACH', 4, 'HOURS', 4.9, 'Голубая лагуна', 'Blue Lagoon', 'Көк лагуна', 36.01430000, 14.32690000, 'Blue Lagoon Comino Malta', ARRAY['comino', 'gozo', 'mellieha']::text[], ARRAY['comino', 'gozo', 'mellieha']::text[], 'Blue_Lagoon,_Comino.jpg'),
    ('crystal-lagoon-comino', 'comino', 'NATURE', 3, 'HOURS', 4.7, 'Кристальная лагуна', 'Crystal Lagoon', 'Кристалл лагунасы', 36.01160000, 14.32890000, 'Crystal Lagoon Comino Malta', ARRAY['comino']::text[], ARRAY['comino']::text[], 'Blue_Lagoon,_Comino.jpg'),
    ('santa-marija-bay-comino', 'comino', 'BEACH', 3, 'HOURS', 4.5, 'Бухта Санта-Мария', 'Santa Marija Bay', 'Санта-Мария шығанағы', 36.01890000, 14.33770000, 'Santa Marija Bay Comino Malta', ARRAY['comino']::text[], ARRAY['comino']::text[], 'Blue_Lagoon,_Comino.jpg'),
    ('santa-marija-tower-comino', 'comino', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Башня Санта-Мария', 'Santa Marija Tower', 'Санта-Мария мұнарасы', 36.01050000, 14.33540000, 'Santa Marija Tower Comino Malta', ARRAY['comino']::text[], ARRAY['comino']::text[], 'Blue_Lagoon,_Comino.jpg');

CREATE TEMP TABLE seed_malta_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-malta-place:' || seed.slug) AS place_hash,
        md5('id-malta-media:' || seed.slug) AS media_hash
    FROM seed_malta_priority_places seed
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
    ARRAY['malta', city_id, slug, lower(category), 'malta-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Мальты: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Malta tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Мальта туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'MT',
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
FROM seed_malta_resolved_places
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
FROM seed_malta_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_malta_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_malta_resolved_places
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
FROM seed_malta_resolved_places seed
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
FROM seed_malta_resolved_places
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
    'MT',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_malta_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'MT',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_malta_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_malta_resolved_places;
DROP TABLE IF EXISTS seed_malta_priority_places;
