-- Priority Italy destination attractions seed.
-- The seed covers Rome and Lazio, Tuscany, Venice and Northern Italy, Campania, Sicily, Puglia, Basilicata, Calabria, and Sardinia.

DROP TABLE IF EXISTS seed_italy_resolved_attractions;
DROP TABLE IF EXISTS seed_italy_priority_attractions;

CREATE TEMP TABLE seed_italy_priority_attractions (
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

INSERT INTO seed_italy_priority_attractions (
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
    ('colosseum', 'rome', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Колизей', 'Colosseum', 'Колизей', 41.89020000, 12.49220000, 'Colosseum Rome Italy', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('roman-forum-palatine', 'rome', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Римский форум и Палатин', 'Roman Forum and Palatine', 'Рим форумы және Палатин', 41.89250000, 12.48530000, 'Roman Forum Palatine Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('pantheon-rome', 'rome', 'TEMPLE', 1, 'HOURS', 4.8, 'Пантеон', 'Pantheon', 'Пантеон', 41.89860000, 12.47690000, 'Pantheon Rome Italy', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('trevi-fountain', 'rome', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Фонтан Треви', 'Trevi Fountain', 'Треви субұрқағы', 41.90090000, 12.48330000, 'Trevi Fountain Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('piazza-navona', 'rome', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Пьяцца Навона', 'Piazza Navona', 'Навона алаңы', 41.89920000, 12.47310000, 'Piazza Navona Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('capitoline-museums', 'rome', 'MUSEUM', 2, 'HOURS', 4.7, 'Капитолийские музеи', 'Capitoline Museums', 'Капитолий музейлері', 41.89330000, 12.48280000, 'Capitoline Museums Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('castel-sant-angelo', 'rome', 'MUSEUM', 2, 'HOURS', 4.7, 'Замок Святого Ангела', 'Castel Sant Angelo', 'Қасиетті Ангел қамалы', 41.90310000, 12.46630000, 'Castel Sant Angelo Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('trajans-market', 'rome', 'MUSEUM', 2, 'HOURS', 4.6, 'Рынки Траяна', 'Trajan Markets', 'Траян базарлары', 41.89560000, 12.48630000, 'Trajan Markets Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('campo-dei-fiori-market', 'rome', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Кампо-деи-Фьори', 'Campo dei Fiori Market', 'Кампо-деи-Фьори базары', 41.89580000, 12.47220000, 'Campo dei Fiori Market Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('via-del-corso', 'rome', 'SHOPPING', 2, 'HOURS', 4.5, 'Виа дель Корсо', 'Via del Corso', 'Виа дель Корсо', 41.90380000, 12.47980000, 'Via del Corso Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('borghese-gallery', 'rome', 'MUSEUM', 2, 'HOURS', 4.8, 'Галерея Боргезе', 'Borghese Gallery', 'Боргезе галереясы', 41.91420000, 12.49220000, 'Borghese Gallery Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('villa-borghese', 'rome', 'PARK', 2, 'HOURS', 4.7, 'Вилла Боргезе', 'Villa Borghese', 'Вилла Боргезе', 41.91420000, 12.48330000, 'Villa Borghese Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('bioparco-roma', 'rome', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Биопарк Рима', 'Bioparco di Roma', 'Рим биопаркі', 41.91770000, 12.48990000, 'Bioparco di Roma', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('maxxi-rome', 'rome', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей MAXXI', 'MAXXI Museum', 'MAXXI музейі', 41.92850000, 12.46630000, 'MAXXI Museum Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('appian-way-regional-park', 'rome', 'PARK', 3, 'HOURS', 4.7, 'Парк Аппиевой дороги', 'Appian Way Regional Park', 'Аппий жолы паркі', 41.84650000, 12.54090000, 'Appian Way Regional Park Rome', ARRAY['rome', 'ostia']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('baths-of-caracalla', 'rome', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Термы Каракаллы', 'Baths of Caracalla', 'Каракалла термалары', 41.87900000, 12.49220000, 'Baths of Caracalla Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('ostia-antica', 'ostia', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Остия Антика', 'Ostia Antica Archaeological Park', 'Остия Антика археологиялық паркі', 41.75560000, 12.29000000, 'Ostia Antica Archaeological Park', ARRAY['ostia', 'rome']::text[], ARRAY['rome', 'ostia']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('ostia-beach', 'ostia', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Остии', 'Ostia Beach', 'Остия жағажайы', 41.73110000, 12.27650000, 'Ostia Beach Rome', ARRAY['ostia', 'rome']::text[], ARRAY['rome', 'ostia']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('porta-portese-market', 'rome', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Порта-Портезе', 'Porta Portese Market', 'Порта-Портезе базары', 41.88460000, 12.46990000, 'Porta Portese Market Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('trastevere-food', 'rome', 'FOOD', 2, 'HOURS', 4.6, 'Еда в Трастевере', 'Trastevere Food Streets', 'Трастевере тағам көшелері', 41.88940000, 12.46930000, 'Trastevere food Rome', ARRAY['rome']::text[], ARRAY['rome']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('hadrians-villa', 'tivoli', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Вилла Адриана', 'Hadrian Villa', 'Адриан вилласы', 41.94260000, 12.77460000, 'Hadrian Villa Tivoli', ARRAY['tivoli', 'rome']::text[], ARRAY['rome', 'tivoli']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('villa-deste', 'tivoli', 'PARK', 2, 'HOURS', 4.8, 'Вилла д Эсте', 'Villa d Este', 'Вилла д Эсте', 41.96330000, 12.79560000, 'Villa d Este Tivoli', ARRAY['tivoli', 'rome']::text[], ARRAY['rome', 'tivoli']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('lake-albano', 'castelli-romani', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Альбано', 'Lake Albano', 'Альбано көлі', 41.74810000, 12.66360000, 'Lake Albano Castelli Romani', ARRAY['castelli-romani', 'rome']::text[], ARRAY['rome', 'castelli-romani']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('rainbow-magicland', 'valmontone', 'ENTERTAINMENT', 6, 'HOURS', 4.5, 'Rainbow MagicLand', 'Rainbow MagicLand', 'Rainbow MagicLand', 41.77550000, 12.91990000, 'Rainbow MagicLand Valmontone', ARRAY['valmontone', 'rome']::text[], ARRAY['rome', 'valmontone']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),

    ('uffizi-gallery', 'florence', 'MUSEUM', 3, 'HOURS', 4.9, 'Галерея Уффици', 'Uffizi Gallery', 'Уффици галереясы', 43.76780000, 11.25530000, 'Uffizi Gallery Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('accademia-gallery', 'florence', 'MUSEUM', 2, 'HOURS', 4.8, 'Галерея Академии', 'Accademia Gallery', 'Академия галереясы', 43.77690000, 11.25880000, 'Accademia Gallery Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('ponte-vecchio', 'florence', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Понте Веккьо', 'Ponte Vecchio', 'Понте Веккьо', 43.76800000, 11.25310000, 'Ponte Vecchio Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('palazzo-vecchio', 'florence', 'MUSEUM', 2, 'HOURS', 4.7, 'Палаццо Веккьо', 'Palazzo Vecchio', 'Палаццо Веккьо', 43.76930000, 11.25610000, 'Palazzo Vecchio Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('boboli-gardens', 'florence', 'PARK', 2, 'HOURS', 4.7, 'Сады Боболи', 'Boboli Gardens', 'Боболи бақтары', 43.76290000, 11.24860000, 'Boboli Gardens Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('san-lorenzo-market', 'florence', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Сан-Лоренцо', 'San Lorenzo Market', 'Сан-Лоренцо базары', 43.77630000, 11.25320000, 'San Lorenzo Market Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('sant-ambrogio-market', 'florence', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Сант-Амброджо', 'Sant Ambrogio Market', 'Сант-Амброджо базары', 43.77170000, 11.26710000, 'Sant Ambrogio Market Florence', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('the-mall-firenze', 'florence', 'SHOPPING', 3, 'HOURS', 4.5, 'Аутлет The Mall Firenze', 'The Mall Firenze Luxury Outlet', 'The Mall Firenze аутлеті', 43.69940000, 11.46640000, 'The Mall Firenze Luxury Outlet', ARRAY['florence']::text[], ARRAY['florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('piazza-dei-miracoli', 'pisa', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Пьяцца деи Мираколи', 'Piazza dei Miracoli', 'Пьяцца деи Мираколи', 43.72300000, 10.39660000, 'Piazza dei Miracoli Pisa', ARRAY['pisa']::text[], ARRAY['pisa', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('leaning-tower-of-pisa', 'pisa', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Пизанская башня', 'Leaning Tower of Pisa', 'Пиза мұнарасы', 43.72290000, 10.39660000, 'Leaning Tower of Pisa', ARRAY['pisa']::text[], ARRAY['pisa', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('palazzo-blu', 'pisa', 'MUSEUM', 2, 'HOURS', 4.5, 'Палаццо Блу', 'Palazzo Blu', 'Палаццо Блу', 43.71540000, 10.40100000, 'Palazzo Blu Pisa', ARRAY['pisa']::text[], ARRAY['pisa']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('vettovaglie-market', 'pisa', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Пьяцца делле Веттовалье', 'Piazza delle Vettovaglie Market', 'Веттовалье базары', 43.71690000, 10.40280000, 'Piazza delle Vettovaglie Market Pisa', ARRAY['pisa']::text[], ARRAY['pisa']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('san-rossore-estate', 'pisa', 'NATURE', 4, 'HOURS', 4.6, 'Парк Сан-Россоре', 'San Rossore Estate', 'Сан-Россоре паркі', 43.72090000, 10.33770000, 'San Rossore Estate Pisa', ARRAY['pisa']::text[], ARRAY['pisa', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('marina-di-pisa', 'pisa', 'BEACH', 3, 'HOURS', 4.4, 'Марина-ди-Пиза', 'Marina di Pisa', 'Марина-ди-Пиза', 43.66820000, 10.27860000, 'Marina di Pisa', ARRAY['pisa']::text[], ARRAY['pisa']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('piazza-del-campo', 'siena', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Пьяцца-дель-Кампо', 'Piazza del Campo', 'Пьяцца-дель-Кампо', 43.31830000, 11.33170000, 'Piazza del Campo Siena', ARRAY['siena']::text[], ARRAY['siena', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('siena-cathedral', 'siena', 'TEMPLE', 2, 'HOURS', 4.8, 'Дуомо Сиены', 'Siena Cathedral Complex', 'Сиена соборы', 43.31770000, 11.32900000, 'Siena Cathedral Complex', ARRAY['siena']::text[], ARRAY['siena']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('santa-maria-della-scala', 'siena', 'MUSEUM', 2, 'HOURS', 4.6, 'Санта-Мария-делла-Скала', 'Santa Maria della Scala', 'Санта-Мария-делла-Скала', 43.31740000, 11.32850000, 'Santa Maria della Scala Siena', ARRAY['siena']::text[], ARRAY['siena']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('val-d-orcia', 'siena', 'NATURE', 5, 'HOURS', 4.8, 'Валь-д Орча', 'Val d Orcia', 'Валь-д Орча', 43.06330000, 11.55890000, 'Val d Orcia Tuscany', ARRAY['siena']::text[], ARRAY['siena', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('walls-of-lucca', 'lucca', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Стены Лукки', 'Walls of Lucca', 'Лукка қабырғалары', 43.84290000, 10.50330000, 'Walls of Lucca', ARRAY['lucca']::text[], ARRAY['lucca', 'pisa', 'florence']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('guinigi-tower', 'lucca', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Башня Гуиниджи', 'Guinigi Tower', 'Гуиниджи мұнарасы', 43.84360000, 10.50740000, 'Guinigi Tower Lucca', ARRAY['lucca']::text[], ARRAY['lucca']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('puccini-museum', 'lucca', 'MUSEUM', 2, 'HOURS', 4.5, 'Дом-музей Пуччини', 'Puccini Museum', 'Пуччини музейі', 43.84300000, 10.50230000, 'Puccini Museum Lucca', ARRAY['lucca']::text[], ARRAY['lucca']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),

    ('st-marks-square', 'venice', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Сан-Марко', 'St Marks Square', 'Сан-Марко алаңы', 45.43420000, 12.33840000, 'St Marks Square Venice', ARRAY['venice']::text[], ARRAY['venice']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('doge-palace', 'venice', 'MUSEUM', 2, 'HOURS', 4.8, 'Дворец Дожей', 'Doge Palace', 'Дождар сарайы', 45.43370000, 12.34040000, 'Doge Palace Venice', ARRAY['venice']::text[], ARRAY['venice']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('rialto-bridge', 'venice', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Мост Риальто', 'Rialto Bridge', 'Риальто көпірі', 45.43800000, 12.33580000, 'Rialto Bridge Venice', ARRAY['venice']::text[], ARRAY['venice']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('rialto-market', 'venice', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Риальто', 'Rialto Market', 'Риальто базары', 45.43840000, 12.33460000, 'Rialto Market Venice', ARRAY['venice']::text[], ARRAY['venice']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('venice-lido-beach', 'venice', 'BEACH', 3, 'HOURS', 4.5, 'Лидо ди Венеция', 'Venice Lido Beach', 'Венеция Лидо жағажайы', 45.41670000, 12.36670000, 'Venice Lido Beach', ARRAY['venice']::text[], ARRAY['venice']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('verona-arena', 'verona', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Арена ди Верона', 'Verona Arena', 'Верона аренасы', 45.43860000, 10.99440000, 'Verona Arena', ARRAY['verona']::text[], ARRAY['verona', 'venice', 'milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('juliet-house', 'verona', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Дом Джульетты', 'Juliet House', 'Джульетта үйі', 45.44200000, 10.99810000, 'Juliet House Verona', ARRAY['verona']::text[], ARRAY['verona']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('piazza-delle-erbe-market', 'verona', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Пьяцца делле Эрбе', 'Piazza delle Erbe Market', 'Пьяцца делле Эрбе базары', 45.44320000, 10.99780000, 'Piazza delle Erbe Market Verona', ARRAY['verona']::text[], ARRAY['verona']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('castelvecchio-museum', 'verona', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Кастельвеккьо', 'Castelvecchio Museum', 'Кастельвеккьо музейі', 45.43960000, 10.98770000, 'Castelvecchio Museum Verona', ARRAY['verona']::text[], ARRAY['verona']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('gardaland-resort', 'lake-garda', 'ENTERTAINMENT', 6, 'HOURS', 4.7, 'Гардаленд', 'Gardaland Resort', 'Гардаленд', 45.45500000, 10.71300000, 'Gardaland Resort Italy', ARRAY['lake-garda', 'verona']::text[], ARRAY['verona', 'milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('movieland-canevaworld', 'lake-garda', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Movieland и CanevaWorld', 'Movieland and CanevaWorld', 'Movieland және CanevaWorld', 45.47420000, 10.72500000, 'Movieland CanevaWorld Lake Garda', ARRAY['lake-garda', 'verona']::text[], ARRAY['verona']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('parco-natura-viva', 'lake-garda', 'PARK', 4, 'HOURS', 4.6, 'Парк Натура Вива', 'Parco Natura Viva', 'Натура Вива паркі', 45.48350000, 10.79600000, 'Parco Natura Viva', ARRAY['lake-garda', 'verona']::text[], ARRAY['verona']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('sirmione-scaliger-castle', 'lake-garda', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Скалигеров в Сирмионе', 'Scaliger Castle of Sirmione', 'Сирмионе Скалигер қамалы', 45.49290000, 10.60750000, 'Scaliger Castle Sirmione', ARRAY['lake-garda']::text[], ARRAY['verona', 'milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('jamaica-beach-sirmione', 'lake-garda', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Ямайка', 'Jamaica Beach', 'Ямайка жағажайы', 45.49740000, 10.60430000, 'Jamaica Beach Sirmione', ARRAY['lake-garda']::text[], ARRAY['verona', 'milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('milan-cathedral', 'milan', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Миланский собор', 'Milan Cathedral', 'Милан соборы', 45.46420000, 9.19160000, 'Milan Cathedral Duomo', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('galleria-vittorio-emanuele', 'milan', 'SHOPPING', 1, 'HOURS', 4.8, 'Галерея Виктора Эммануила II', 'Galleria Vittorio Emanuele II', 'Виктор Эммануил II галереясы', 45.46580000, 9.19000000, 'Galleria Vittorio Emanuele II Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('sforza-castle-museums', 'milan', 'MUSEUM', 2, 'HOURS', 4.7, 'Кастелло Сфорцеско и музеи', 'Sforza Castle Museums', 'Сфорца қамалы музейлері', 45.47050000, 9.17970000, 'Sforza Castle Museums Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('science-museum-milan', 'milan', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей науки и техники Леонардо да Винчи', 'Leonardo da Vinci Science Museum', 'Леонардо да Винчи ғылым музейі', 45.46270000, 9.17120000, 'Leonardo da Vinci Science Museum Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('parco-sempione', 'milan', 'PARK', 2, 'HOURS', 4.6, 'Парк Семпионе', 'Parco Sempione', 'Семпионе паркі', 45.47220000, 9.17360000, 'Parco Sempione Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('quadrilatero-moda', 'milan', 'SHOPPING', 2, 'HOURS', 4.6, 'Квартал моды', 'Quadrilatero della Moda', 'Мода кварталы', 45.46870000, 9.19590000, 'Quadrilatero della Moda Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('mercato-centrale-milano', 'milan', 'MARKET', 2, 'HOURS', 4.5, 'Меркато Чентрале Милано', 'Mercato Centrale Milano', 'Милан орталық базары', 45.48600000, 9.20560000, 'Mercato Centrale Milano', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('navigli-district', 'milan', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Навильи', 'Navigli District', 'Навильи ауданы', 45.45170000, 9.17400000, 'Navigli District Milan', ARRAY['milan']::text[], ARRAY['milan']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('lake-como-bellagio', 'lake-como', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Белладжо на озере Комо', 'Lake Como Bellagio', 'Комо көліндегі Белладжо', 45.98760000, 9.26150000, 'Bellagio Lake Como', ARRAY['lake-como', 'milan']::text[], ARRAY['milan', 'lake-como']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('villa-melzi-gardens', 'lake-como', 'PARK', 2, 'HOURS', 4.7, 'Сады виллы Мельци', 'Villa Melzi Gardens', 'Вилла Мельци бақтары', 45.98490000, 9.25740000, 'Villa Melzi Gardens Lake Como', ARRAY['lake-como']::text[], ARRAY['milan', 'lake-como']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('villa-carlotta', 'lake-como', 'MUSEUM', 2, 'HOURS', 4.7, 'Вилла Карлотта', 'Villa Carlotta', 'Вилла Карлотта', 45.98720000, 9.22810000, 'Villa Carlotta Lake Como', ARRAY['lake-como']::text[], ARRAY['milan', 'lake-como']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),

    ('naples-archaeological-museum', 'naples', 'MUSEUM', 3, 'HOURS', 4.8, 'Археологический музей Неаполя', 'Naples National Archaeological Museum', 'Неаполь археологиялық музейі', 40.85330000, 14.25070000, 'Naples National Archaeological Museum', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('capodimonte-museum-park', 'naples', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей и парк Каподимонте', 'Capodimonte Museum and Royal Park', 'Каподимонте музейі және паркі', 40.86700000, 14.25000000, 'Capodimonte Museum Naples', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('castel-dell-ovo', 'naples', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Кастель-дель-Ово', 'Castel dell Ovo', 'Кастель-дель-Ово', 40.82830000, 14.24750000, 'Castel dell Ovo Naples', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('galleria-umberto-i', 'naples', 'SHOPPING', 1, 'HOURS', 4.6, 'Галерея Умберто I', 'Galleria Umberto I', 'Умберто I галереясы', 40.83880000, 14.24910000, 'Galleria Umberto I Naples', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('pignasecca-market', 'naples', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Пиньясекка', 'Pignasecca Market', 'Пиньясекка базары', 40.84700000, 14.24500000, 'Pignasecca Market Naples', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('naples-pizza-streets', 'naples', 'FOOD', 2, 'HOURS', 4.8, 'Пицца-улицы Неаполя', 'Naples Pizza Streets', 'Неаполь пицца көшелері', 40.85180000, 14.26810000, 'Naples pizza historic center', ARRAY['naples']::text[], ARRAY['naples']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('amalfi-cathedral', 'amalfi-coast', 'TEMPLE', 2, 'HOURS', 4.7, 'Дуомо Амальфи', 'Amalfi Cathedral', 'Амальфи соборы', 40.63400000, 14.60260000, 'Amalfi Cathedral', ARRAY['amalfi-coast']::text[], ARRAY['naples', 'amalfi-coast']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('amalfi-paper-museum', 'amalfi-coast', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей бумаги Амальфи', 'Amalfi Paper Museum', 'Амальфи қағаз музейі', 40.63780000, 14.60270000, 'Amalfi Paper Museum', ARRAY['amalfi-coast']::text[], ARRAY['amalfi-coast']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('valle-delle-ferriere', 'amalfi-coast', 'NATURE', 4, 'HOURS', 4.7, 'Долина Феррьере', 'Valle delle Ferriere', 'Феррьере аңғары', 40.65000000, 14.59000000, 'Valle delle Ferriere Amalfi', ARRAY['amalfi-coast']::text[], ARRAY['amalfi-coast']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('fiordo-di-furore', 'amalfi-coast', 'BEACH', 3, 'HOURS', 4.7, 'Фьорд Фуроре', 'Fiordo di Furore', 'Фуроре фьорды', 40.61410000, 14.55280000, 'Fiordo di Furore Amalfi Coast', ARRAY['amalfi-coast']::text[], ARRAY['naples', 'amalfi-coast']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('villa-rufolo', 'amalfi-coast', 'PARK', 2, 'HOURS', 4.7, 'Вилла Руфоло', 'Villa Rufolo', 'Вилла Руфоло', 40.64940000, 14.61280000, 'Villa Rufolo Ravello', ARRAY['amalfi-coast']::text[], ARRAY['amalfi-coast']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('blue-grotto-capri', 'capri', 'NATURE', 2, 'HOURS', 4.7, 'Голубой грот', 'Blue Grotto', 'Көк үңгір', 40.56080000, 14.20560000, 'Blue Grotto Capri', ARRAY['capri']::text[], ARRAY['capri', 'naples']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('faraglioni-capri', 'capri', 'NATURE', 2, 'HOURS', 4.8, 'Фаральони', 'Faraglioni Rocks', 'Фаральони жартастары', 40.54400000, 14.24970000, 'Faraglioni Capri', ARRAY['capri']::text[], ARRAY['capri', 'naples']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('gardens-of-augustus', 'capri', 'PARK', 1, 'HOURS', 4.7, 'Сады Августа', 'Gardens of Augustus', 'Август бақтары', 40.54890000, 14.24480000, 'Gardens of Augustus Capri', ARRAY['capri']::text[], ARRAY['capri']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('pompeii-archaeological-park', 'pompeii', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Археологический парк Помпеи', 'Pompeii Archaeological Park', 'Помпеи археологиялық паркі', 40.74850000, 14.48470000, 'Pompeii Archaeological Park', ARRAY['pompeii', 'naples']::text[], ARRAY['naples', 'pompeii']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('pompeii-antiquarium', 'pompeii', 'MUSEUM', 2, 'HOURS', 4.6, 'Антиквариум Помпеи', 'Pompeii Antiquarium', 'Помпеи антиквариумы', 40.74900000, 14.48450000, 'Pompeii Antiquarium', ARRAY['pompeii']::text[], ARRAY['pompeii']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('mount-vesuvius-gran-cono', 'mount-vesuvius', 'NATURE', 4, 'HOURS', 4.8, 'Везувий, Большой конус', 'Mount Vesuvius Gran Cono', 'Везувий үлкен конусы', 40.82140000, 14.42650000, 'Mount Vesuvius Gran Cono', ARRAY['mount-vesuvius', 'naples']::text[], ARRAY['naples', 'mount-vesuvius']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('piazza-tasso', 'sorrento', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Пьяцца Тассо', 'Piazza Tasso', 'Тассо алаңы', 40.62630000, 14.37580000, 'Piazza Tasso Sorrento', ARRAY['sorrento']::text[], ARRAY['sorrento', 'naples']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('baths-queen-giovanna', 'sorrento', 'NATURE', 3, 'HOURS', 4.7, 'Баньи-делла-Регина-Джованна', 'Baths of Queen Giovanna', 'Джованна ханшайым моншалары', 40.62020000, 14.34390000, 'Baths of Queen Giovanna Sorrento', ARRAY['sorrento']::text[], ARRAY['sorrento']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),

    ('mount-etna', 'catania', 'NATURE', 6, 'HOURS', 4.9, 'Этна', 'Mount Etna', 'Этна', 37.75100000, 14.99340000, 'Mount Etna Sicily', ARRAY['catania']::text[], ARRAY['catania', 'palermo']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('valley-of-temples', 'agrigento', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Долина храмов', 'Valley of the Temples', 'Ғибадатханалар аңғары', 37.28970000, 13.58580000, 'Valley of the Temples Agrigento', ARRAY['agrigento']::text[], ARRAY['palermo', 'catania', 'agrigento']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('arab-norman-palermo', 'palermo', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Арабо-норманнский маршрут Палермо', 'Arab-Norman Palermo Route', 'Палермо араб-норман бағыты', 38.11570000, 13.36150000, 'Arab Norman Palermo Route', ARRAY['palermo']::text[], ARRAY['palermo']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('palermo-cathedral', 'palermo', 'TEMPLE', 2, 'HOURS', 4.8, 'Кафедральный собор Палермо', 'Palermo Cathedral', 'Палермо соборы', 38.11440000, 13.35660000, 'Palermo Cathedral', ARRAY['palermo']::text[], ARRAY['palermo']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('ballaro-market', 'palermo', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Балларо', 'Ballaro Market', 'Балларо базары', 38.11250000, 13.36420000, 'Ballaro Market Palermo', ARRAY['palermo']::text[], ARRAY['palermo']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('mondello-beach', 'palermo', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Монделло', 'Mondello Beach', 'Монделло жағажайы', 38.20440000, 13.32480000, 'Mondello Beach Palermo', ARRAY['palermo']::text[], ARRAY['palermo']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('zingaro-nature-reserve', 'zingaro', 'NATURE', 5, 'HOURS', 4.8, 'Заповедник Дзингаро', 'Zingaro Nature Reserve', 'Дзингаро қорығы', 38.11200000, 12.79000000, 'Zingaro Nature Reserve Sicily', ARRAY['zingaro', 'palermo']::text[], ARRAY['palermo', 'zingaro']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),

    ('bari-old-town', 'bari', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Бари Веккья и базилика Святого Николая', 'Bari Old Town', 'Бари ескі қаласы', 41.12830000, 16.86900000, 'Bari Old Town Basilica Saint Nicholas', ARRAY['bari']::text[], ARRAY['bari']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('norman-swabian-castle-bari', 'bari', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Норманно-Швабский замок', 'Norman Swabian Castle', 'Норман-Шваб қамалы', 41.12890000, 16.86650000, 'Norman Swabian Castle Bari', ARRAY['bari']::text[], ARRAY['bari']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('pane-pomodoro-beach', 'bari', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Пане-э-Помодоро', 'Pane e Pomodoro Beach', 'Пане-э-Помодоро жағажайы', 41.11660000, 16.88830000, 'Pane e Pomodoro Beach Bari', ARRAY['bari']::text[], ARRAY['bari']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('fiera-del-levante', 'bari', 'ENTERTAINMENT', 3, 'HOURS', 4.4, 'Фьера-дель-Леванте', 'Fiera del Levante', 'Фьера-дель-Леванте', 41.13660000, 16.84210000, 'Fiera del Levante Bari', ARRAY['bari']::text[], ARRAY['bari']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('lama-monachile', 'polignano-a-mare', 'BEACH', 3, 'HOURS', 4.8, 'Лама Монакиле', 'Lama Monachile Cala Porto', 'Лама Монакиле', 40.99520000, 17.21960000, 'Lama Monachile Polignano a Mare', ARRAY['polignano-a-mare', 'bari']::text[], ARRAY['bari', 'polignano-a-mare']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('castellana-caves', 'castellana-grotte', 'NATURE', 3, 'HOURS', 4.7, 'Гроты Кастеллана', 'Castellana Caves', 'Кастеллана үңгірлері', 40.87690000, 17.14790000, 'Castellana Caves Puglia', ARRAY['castellana-grotte', 'bari']::text[], ARRAY['bari', 'castellana-grotte']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('castel-del-monte', 'andria', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Кастель-дель-Монте', 'Castel del Monte', 'Кастель-дель-Монте', 41.08460000, 16.27030000, 'Castel del Monte Andria', ARRAY['andria', 'bari']::text[], ARRAY['bari', 'andria']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('trulli-of-alberobello', 'alberobello', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Трулли Альберобелло', 'Trulli of Alberobello', 'Альберобелло труллиі', 40.78290000, 17.23600000, 'Trulli of Alberobello', ARRAY['alberobello', 'bari']::text[], ARRAY['bari', 'alberobello']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('casa-pezzolla-museum', 'alberobello', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Casa Pezzolla', 'Casa Pezzolla Territory Museum', 'Casa Pezzolla музейі', 40.78460000, 17.23670000, 'Casa Pezzolla Museum Alberobello', ARRAY['alberobello']::text[], ARRAY['alberobello']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('sassi-of-matera', 'matera', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Сасси ди Матера', 'Sassi of Matera', 'Матера Сассиі', 40.66640000, 16.61000000, 'Sassi of Matera', ARRAY['matera']::text[], ARRAY['matera', 'bari']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('murgia-materana-park', 'matera', 'PARK', 4, 'HOURS', 4.8, 'Парк Мургия Матерана', 'Murgia Materana Park', 'Мургия Матерана паркі', 40.66190000, 16.62610000, 'Murgia Materana Park', ARRAY['matera']::text[], ARRAY['matera']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('ridola-archaeological-museum', 'matera', 'MUSEUM', 2, 'HOURS', 4.5, 'Археологический музей Доменико Ридола', 'Domenico Ridola Archaeological Museum', 'Доменико Ридола археологиялық музейі', 40.66380000, 16.61130000, 'Domenico Ridola Archaeological Museum Matera', ARRAY['matera']::text[], ARRAY['matera']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('tropea-old-town', 'tropea', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Тропеи', 'Tropea Old Town', 'Тропея ескі қаласы', 38.67860000, 15.89720000, 'Tropea Old Town', ARRAY['tropea']::text[], ARRAY['tropea', 'reggio-calabria']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('tropea-beaches', 'tropea', 'BEACH', 4, 'HOURS', 4.8, 'Пляжи Тропеи', 'Tropea Beaches', 'Тропея жағажайлары', 38.67750000, 15.89860000, 'Tropea Beaches Calabria', ARRAY['tropea']::text[], ARRAY['tropea']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('chianalea-scilla', 'scilla', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Кьяналеа ди Шилла', 'Chianalea di Scilla', 'Шилла Кьяналеа', 38.25270000, 15.71640000, 'Chianalea di Scilla', ARRAY['scilla', 'reggio-calabria']::text[], ARRAY['reggio-calabria', 'scilla']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('reggio-archaeological-museum', 'reggio-calabria', 'MUSEUM', 2, 'HOURS', 4.7, 'Археологический музей Реджо-Калабрии', 'National Archaeological Museum of Reggio Calabria', 'Реджо-Калабрия археологиялық музейі', 38.11440000, 15.65000000, 'National Archaeological Museum Reggio Calabria', ARRAY['reggio-calabria']::text[], ARRAY['reggio-calabria']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('pollino-national-park', 'pollino', 'PARK', 6, 'HOURS', 4.8, 'Национальный парк Поллино', 'Pollino National Park', 'Поллино ұлттық паркі', 39.90000000, 16.20000000, 'Pollino National Park Italy', ARRAY['pollino']::text[], ARRAY['pollino', 'matera']::text[], 'Florence_Duomo_from_Michelangelo_hill.jpg'),
    ('la-maddalena-archipelago', 'la-maddalena', 'PARK', 6, 'HOURS', 4.9, 'Архипелаг Ла-Маддалена', 'La Maddalena Archipelago National Park', 'Ла-Маддалена ұлттық паркі', 41.21470000, 9.40860000, 'La Maddalena Archipelago National Park', ARRAY['la-maddalena', 'sardinia']::text[], ARRAY['sardinia', 'la-maddalena']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('porto-cervo-costa-smeralda', 'costa-smeralda', 'SHOPPING', 3, 'HOURS', 4.6, 'Порто-Черво и Коста-Смеральда', 'Porto Cervo and Costa Smeralda', 'Порто-Черво және Коста-Смеральда', 41.13590000, 9.53150000, 'Porto Cervo Costa Smeralda', ARRAY['costa-smeralda', 'sardinia']::text[], ARRAY['sardinia', 'costa-smeralda']::text[], 'Milan_Cathedral_from_Piazza_del_Duomo.jpg'),
    ('cala-goloritze', 'baunei', 'BEACH', 5, 'HOURS', 4.9, 'Кала Голоритце', 'Cala Goloritze', 'Кала Голоритце', 40.10810000, 9.68920000, 'Cala Goloritze Sardinia', ARRAY['baunei', 'sardinia']::text[], ARRAY['sardinia', 'baunei']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg'),
    ('su-nuraxi-barumini', 'barumini', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Су-Нуракси Барумини', 'Su Nuraxi di Barumini', 'Су-Нуракси Барумини', 39.70600000, 8.99130000, 'Su Nuraxi di Barumini', ARRAY['barumini', 'sardinia']::text[], ARRAY['cagliari', 'barumini']::text[], 'Colosseum_in_Rome,_Italy_-_April_2007.jpg'),
    ('poetto-beach', 'cagliari', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Поэтто', 'Poetto Beach', 'Поэтто жағажайы', 39.20720000, 9.17110000, 'Poetto Beach Cagliari', ARRAY['cagliari', 'sardinia']::text[], ARRAY['cagliari']::text[], 'Trevi_Fountain,_Rome,_Italy_2_-_May_2007.jpg');

CREATE TEMP TABLE seed_italy_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-italy-attraction:' || seed.slug) AS attraction_hash,
        md5('id-italy-media:' || seed.slug) AS media_hash
    FROM seed_italy_priority_attractions seed
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
    ARRAY['italy', city_id, slug, lower(category), 'italy-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Италии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Italy tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Италия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'IT',
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
FROM seed_italy_resolved_attractions
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
FROM seed_italy_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_italy_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_italy_resolved_attractions
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
FROM seed_italy_resolved_attractions seed
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
FROM seed_italy_resolved_attractions
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
    'IT',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_italy_resolved_attractions
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
    'IT',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_italy_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
