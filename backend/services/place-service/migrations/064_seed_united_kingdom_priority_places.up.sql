-- Priority United Kingdom destination places seed.
-- The seed covers England, Scotland, Wales, and Northern Ireland tourist anchors with stable year-round POIs.

DROP TABLE IF EXISTS seed_united_kingdom_resolved_places;
DROP TABLE IF EXISTS seed_united_kingdom_priority_places;

CREATE TEMP TABLE seed_united_kingdom_priority_places (
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

INSERT INTO seed_united_kingdom_priority_places (
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
    ('big-ben-palace-westminster', 'london', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Биг-Бен и Вестминстерский дворец', 'Big Ben and Palace of Westminster', 'Биг-Бен және Вестминстер сарайы', 51.49950000, -0.12480000, 'Big Ben Palace of Westminster London', ARRAY['london']::text[], ARRAY['london']::text[], 'Palace of Westminster and Big Ben.jpg'),
    ('tower-of-london', 'london', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Лондонский Тауэр', 'Tower of London', 'Лондон Тауэры', 51.50810000, -0.07590000, 'Tower of London', ARRAY['london']::text[], ARRAY['london']::text[], 'Tower of London view.jpg'),
    ('british-museum', 'london', 'MUSEUM', 4, 'HOURS', 4.8, 'Британский музей', 'British Museum', 'Британ музейі', 51.51940000, -0.12700000, 'British Museum London', ARRAY['london']::text[], ARRAY['london']::text[], 'British Museum from NE 2.JPG'),
    ('national-gallery-london', 'london', 'MUSEUM', 3, 'HOURS', 4.8, 'Национальная галерея Лондона', 'National Gallery London', 'Лондон ұлттық галереясы', 51.50890000, -0.12830000, 'National Gallery London', ARRAY['london']::text[], ARRAY['london']::text[], 'National Gallery London.jpg'),
    ('westminster-abbey', 'london', 'TEMPLE', 2, 'HOURS', 4.8, 'Вестминстерское аббатство', 'Westminster Abbey', 'Вестминстер аббаттығы', 51.49930000, -0.12730000, 'Westminster Abbey London', ARRAY['london']::text[], ARRAY['london']::text[], 'Westminster Abbey - West Door.jpg'),
    ('st-pauls-cathedral', 'london', 'TEMPLE', 2, 'HOURS', 4.7, 'Собор Святого Павла', 'St Paul''s Cathedral', 'Әулие Павел соборы', 51.51380000, -0.09840000, 'St Paul Cathedral London', ARRAY['london']::text[], ARRAY['london']::text[], 'St Pauls Cathedral London.jpg'),
    ('hyde-park-london', 'london', 'PARK', 2, 'HOURS', 4.7, 'Гайд-парк', 'Hyde Park', 'Гайд-парк', 51.50730000, -0.16570000, 'Hyde Park London', ARRAY['london']::text[], ARRAY['london']::text[], 'Hyde Park London.jpg'),
    ('kew-gardens', 'london', 'PARK', 4, 'HOURS', 4.8, 'Королевские ботанические сады Кью', 'Kew Gardens', 'Кью бақтары', 51.47870000, -0.29560000, 'Kew Gardens London', ARRAY['london']::text[], ARRAY['london']::text[], 'Kew Gardens Palm House.jpg'),
    ('sky-garden-london', 'london', 'PARK', 1, 'HOURS', 4.6, 'Sky Garden London', 'Sky Garden London', 'Sky Garden London', 51.51130000, -0.08360000, 'Sky Garden London', ARRAY['london']::text[], ARRAY['london']::text[], 'Sky Garden London.jpg'),
    ('borough-market', 'london', 'MARKET', 2, 'HOURS', 4.7, 'Borough Market', 'Borough Market', 'Borough Market', 51.50550000, -0.09100000, 'Borough Market London', ARRAY['london']::text[], ARRAY['london']::text[], 'Borough Market London.jpg'),
    ('camden-market', 'london', 'MARKET', 2, 'HOURS', 4.6, 'Camden Market', 'Camden Market', 'Camden Market', 51.54130000, -0.14640000, 'Camden Market London', ARRAY['london']::text[], ARRAY['london']::text[], 'Camden Market London.jpg'),
    ('westfield-london', 'london', 'SHOPPING', 3, 'HOURS', 4.5, 'Westfield London', 'Westfield London', 'Westfield London', 51.50760000, -0.22170000, 'Westfield London Shepherds Bush', ARRAY['london']::text[], ARRAY['london']::text[], 'Westfield London.jpg'),
    ('warner-bros-studio-tour-london', 'london', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Warner Bros Studio Tour London', 'Warner Bros Studio Tour London', 'Warner Bros Studio Tour London', 51.69030000, -0.41830000, 'Warner Bros Studio Tour London', ARRAY['london']::text[], ARRAY['london']::text[], 'Warner Bros Studio Tour London.jpg'),
    ('maltby-street-market', 'london', 'FOOD', 2, 'HOURS', 4.5, 'Maltby Street Market', 'Maltby Street Market', 'Maltby Street Market', 51.50090000, -0.07570000, 'Maltby Street Market London', ARRAY['london']::text[], ARRAY['london']::text[], 'Maltby Street Market London.jpg'),

    ('windsor-castle', 'windsor', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Виндзорский замок', 'Windsor Castle', 'Виндзор қамалы', 51.48390000, -0.60440000, 'Windsor Castle', ARRAY['windsor']::text[], ARRAY['london', 'windsor']::text[], 'Windsor Castle at Sunset - Nov 2006.jpg'),
    ('windsor-great-park', 'windsor', 'PARK', 3, 'HOURS', 4.7, 'Виндзорский большой парк', 'Windsor Great Park', 'Виндзор үлкен паркі', 51.43770000, -0.62280000, 'Windsor Great Park', ARRAY['windsor']::text[], ARRAY['london', 'windsor']::text[], 'Windsor Great Park.jpg'),
    ('legoland-windsor-resort', 'windsor', 'ENTERTAINMENT', 6, 'HOURS', 4.5, 'LEGOLAND Windsor Resort', 'LEGOLAND Windsor Resort', 'LEGOLAND Windsor Resort', 51.46340000, -0.65110000, 'LEGOLAND Windsor Resort', ARRAY['windsor']::text[], ARRAY['london', 'windsor']::text[], 'Legoland Windsor.jpg'),
    ('oxford-university-bodleian-library', 'oxford', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Оксфордский университет и Бодлианская библиотека', 'Oxford University and Bodleian Library', 'Оксфорд университеті және Бодлиан кітапханасы', 51.75430000, -1.25440000, 'Bodleian Library Oxford', ARRAY['oxford']::text[], ARRAY['london', 'oxford']::text[], 'Bodleian Library Oxford.jpg'),
    ('ashmolean-museum', 'oxford', 'MUSEUM', 3, 'HOURS', 4.7, 'Ашмоловский музей', 'Ashmolean Museum', 'Ашмол музейі', 51.75540000, -1.26000000, 'Ashmolean Museum Oxford', ARRAY['oxford']::text[], ARRAY['oxford']::text[], 'Ashmolean Museum Oxford.jpg'),
    ('christ-church-oxford', 'oxford', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крайст-черч в Оксфорде', 'Christ Church Oxford', 'Оксфорд Крайст-черч', 51.75030000, -1.25500000, 'Christ Church Oxford', ARRAY['oxford']::text[], ARRAY['oxford']::text[], 'Christ Church Oxford.jpg'),
    ('oxford-covered-market', 'oxford', 'MARKET', 1, 'HOURS', 4.5, 'Крытый рынок Оксфорда', 'Oxford Covered Market', 'Оксфорд жабық базары', 51.75270000, -1.25600000, 'Oxford Covered Market', ARRAY['oxford']::text[], ARRAY['oxford']::text[], 'Oxford Covered Market.jpg'),
    ('kings-college-chapel-cambridge', 'cambridge', 'TEMPLE', 2, 'HOURS', 4.8, 'Часовня Королевского колледжа в Кембридже', 'King''s College Chapel Cambridge', 'Кембридж Король колледжі часовнясы', 52.20430000, 0.11660000, 'King College Chapel Cambridge', ARRAY['cambridge']::text[], ARRAY['london', 'cambridge']::text[], 'Kings College Chapel Cambridge.jpg'),
    ('fitzwilliam-museum', 'cambridge', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Фицуильяма', 'Fitzwilliam Museum', 'Фицуильям музейі', 52.19950000, 0.12000000, 'Fitzwilliam Museum Cambridge', ARRAY['cambridge']::text[], ARRAY['cambridge']::text[], 'Fitzwilliam Museum Cambridge.jpg'),
    ('cambridge-botanic-garden', 'cambridge', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Кембриджа', 'Cambridge University Botanic Garden', 'Кембридж университетінің ботаникалық бағы', 52.19390000, 0.12640000, 'Cambridge University Botanic Garden', ARRAY['cambridge']::text[], ARRAY['cambridge']::text[], 'Cambridge University Botanic Garden.jpg'),
    ('cambridge-market', 'cambridge', 'MARKET', 1, 'HOURS', 4.4, 'Кембриджский рынок', 'Cambridge Market', 'Кембридж базары', 52.20530000, 0.11900000, 'Cambridge Market Square', ARRAY['cambridge']::text[], ARRAY['cambridge']::text[], 'Cambridge Market Square.jpg'),
    ('canterbury-cathedral', 'canterbury', 'TEMPLE', 2, 'HOURS', 4.8, 'Кентерберийский собор', 'Canterbury Cathedral', 'Кентербери соборы', 51.27980000, 1.08310000, 'Canterbury Cathedral', ARRAY['canterbury']::text[], ARRAY['london', 'canterbury']::text[], 'Canterbury Cathedral.jpg'),
    ('canterbury-roman-museum', 'canterbury', 'MUSEUM', 1, 'HOURS', 4.5, 'Римский музей Кентербери', 'Canterbury Roman Museum', 'Кентербери Рим музейі', 51.27900000, 1.08160000, 'Canterbury Roman Museum', ARRAY['canterbury']::text[], ARRAY['canterbury']::text[], 'Canterbury Roman Museum.jpg'),
    ('westgate-gardens', 'canterbury', 'PARK', 1, 'HOURS', 4.5, 'Сады Вестгейт', 'Westgate Gardens', 'Вестгейт бақтары', 51.28120000, 1.07540000, 'Westgate Gardens Canterbury', ARRAY['canterbury']::text[], ARRAY['canterbury']::text[], 'Westgate Gardens Canterbury.jpg'),
    ('brighton-palace-pier', 'brighton', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Брайтонский пирс', 'Brighton Palace Pier', 'Брайтон пирсі', 50.81670000, -0.13690000, 'Brighton Palace Pier', ARRAY['brighton']::text[], ARRAY['london', 'brighton']::text[], 'Brighton Palace Pier.jpg'),
    ('royal-pavilion-brighton', 'brighton', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Королевский павильон в Брайтоне', 'Royal Pavilion Brighton', 'Брайтон Король павильоны', 50.82310000, -0.13790000, 'Royal Pavilion Brighton', ARRAY['brighton']::text[], ARRAY['brighton']::text[], 'Royal Pavilion Brighton.jpg'),
    ('brighton-beach', 'brighton', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Брайтона', 'Brighton Beach', 'Брайтон жағажайы', 50.81790000, -0.13490000, 'Brighton Beach UK', ARRAY['brighton']::text[], ARRAY['brighton']::text[], 'Brighton Beach.jpg'),
    ('the-lanes-brighton', 'brighton', 'SHOPPING', 2, 'HOURS', 4.5, 'Квартал The Lanes в Брайтоне', 'The Lanes Brighton', 'Брайтон The Lanes', 50.82140000, -0.14000000, 'The Lanes Brighton', ARRAY['brighton']::text[], ARRAY['brighton']::text[], 'The Lanes Brighton.jpg'),
    ('stonehenge', 'stonehenge', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Стоунхендж', 'Stonehenge', 'Стоунхендж', 51.17890000, -1.82620000, 'Stonehenge England', ARRAY['stonehenge']::text[], ARRAY['london', 'salisbury', 'stonehenge']::text[], 'Stonehenge2007 07 30.jpg'),
    ('salisbury-cathedral', 'salisbury', 'TEMPLE', 2, 'HOURS', 4.7, 'Солсберийский собор', 'Salisbury Cathedral', 'Солсбери соборы', 51.06480000, -1.79760000, 'Salisbury Cathedral', ARRAY['salisbury']::text[], ARRAY['salisbury']::text[], 'Salisbury Cathedral from the Bishop Grounds.jpg'),
    ('old-sarum', 'salisbury', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Олд-Сарум', 'Old Sarum', 'Олд-Сарум', 51.09340000, -1.80640000, 'Old Sarum Salisbury', ARRAY['salisbury']::text[], ARRAY['salisbury']::text[], 'Old Sarum aerial.jpg'),

    ('roman-baths', 'bath', 'MUSEUM', 3, 'HOURS', 4.8, 'Римские бани', 'Roman Baths', 'Рим моншалары', 51.38110000, -2.35900000, 'Roman Baths Bath England', ARRAY['bath']::text[], ARRAY['london', 'bath']::text[], 'Roman Baths in Bath Spa England - July 2006.jpg'),
    ('bath-abbey', 'bath', 'TEMPLE', 1, 'HOURS', 4.7, 'Аббатство Бата', 'Bath Abbey', 'Бат аббаттығы', 51.38140000, -2.35870000, 'Bath Abbey', ARRAY['bath']::text[], ARRAY['bath']::text[], 'Bath Abbey West Front.jpg'),
    ('royal-crescent-bath', 'bath', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Королевский полумесяц в Бате', 'The Royal Crescent Bath', 'Бат Король жарты айы', 51.38660000, -2.36700000, 'Royal Crescent Bath', ARRAY['bath']::text[], ARRAY['bath']::text[], 'Royal Crescent Bath.jpg'),
    ('clifton-suspension-bridge', 'bristol', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Клифтонский подвесной мост', 'Clifton Suspension Bridge', 'Клифтон аспалы көпірі', 51.45450000, -2.62790000, 'Clifton Suspension Bridge Bristol', ARRAY['bristol']::text[], ARRAY['bristol']::text[], 'Clifton Suspension Bridge Bristol.jpg'),
    ('ss-great-britain', 'bristol', 'MUSEUM', 2, 'HOURS', 4.7, 'SS Great Britain', 'SS Great Britain', 'SS Great Britain', 51.44970000, -2.60830000, 'SS Great Britain Bristol', ARRAY['bristol']::text[], ARRAY['bristol']::text[], 'SS Great Britain Bristol.jpg'),
    ('st-nicholas-market-bristol', 'bristol', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Святого Николая в Бристоле', 'St Nicholas Market Bristol', 'Бристоль Әулие Николай базары', 51.45520000, -2.59460000, 'St Nicholas Market Bristol', ARRAY['bristol']::text[], ARRAY['bristol']::text[], 'St Nicholas Market Bristol.jpg'),
    ('bibury-cotswolds', 'cotswolds', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Байбери в Котсуолдсе', 'Bibury Cotswolds', 'Котсуолдс Байбери', 51.75880000, -1.83300000, 'Bibury Cotswolds', ARRAY['cotswolds']::text[], ARRAY['oxford', 'bath', 'cotswolds']::text[], 'Bibury Arlington Row.jpg'),
    ('bourton-on-the-water', 'cotswolds', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Бортон-он-зе-Уотер', 'Bourton-on-the-Water', 'Бортон-он-зе-Уотер', 51.88530000, -1.75800000, 'Bourton on the Water Cotswolds', ARRAY['cotswolds']::text[], ARRAY['cotswolds']::text[], 'Bourton-on-the-Water.jpg'),
    ('shakespeare-birthplace', 'stratford-upon-avon', 'MUSEUM', 2, 'HOURS', 4.7, 'Дом-музей Шекспира', 'Shakespeare''s Birthplace', 'Шекспир туған үйі', 52.19380000, -1.70800000, 'Shakespeare Birthplace Stratford upon Avon', ARRAY['stratford-upon-avon']::text[], ARRAY['birmingham', 'stratford-upon-avon']::text[], 'Shakespeares Birthplace Stratford-upon-Avon.jpg'),
    ('royal-shakespeare-theatre', 'stratford-upon-avon', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Королевский шекспировский театр', 'Royal Shakespeare Theatre', 'Корольдік Шекспир театры', 52.19080000, -1.70340000, 'Royal Shakespeare Theatre Stratford upon Avon', ARRAY['stratford-upon-avon']::text[], ARRAY['stratford-upon-avon']::text[], 'Royal Shakespeare Theatre Stratford.jpg'),
    ('bournemouth-beach', 'bournemouth', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Борнмута', 'Bournemouth Beach', 'Борнмут жағажайы', 50.71690000, -1.87500000, 'Bournemouth Beach', ARRAY['bournemouth']::text[], ARRAY['bournemouth']::text[], 'Bournemouth Beach.jpg'),
    ('jurassic-coast', 'jurassic-coast', 'NATURE', 5, 'HOURS', 4.8, 'Юрское побережье', 'Jurassic Coast', 'Юра жағалауы', 50.64200000, -2.16800000, 'Jurassic Coast Dorset', ARRAY['jurassic-coast']::text[], ARRAY['bournemouth', 'jurassic-coast']::text[], 'Jurassic Coast Dorset.jpg'),
    ('durdle-door', 'jurassic-coast', 'BEACH', 3, 'HOURS', 4.8, 'Дердл-Дор', 'Durdle Door', 'Дердл-Дор', 50.62100000, -2.27670000, 'Durdle Door Jurassic Coast', ARRAY['jurassic-coast']::text[], ARRAY['bournemouth', 'jurassic-coast']::text[], 'Durdle Door overview.jpg'),
    ('eden-project', 'cornwall', 'PARK', 4, 'HOURS', 4.7, 'Eden Project', 'Eden Project', 'Eden Project', 50.36190000, -4.74470000, 'Eden Project Cornwall', ARRAY['cornwall']::text[], ARRAY['bristol', 'cornwall']::text[], 'Eden Project geodesic domes panorama.jpg'),
    ('st-michaels-mount', 'cornwall', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Гора Святого Михаила в Корнуолле', 'St Michael''s Mount Cornwall', 'Корнуолл Әулие Михаил тауы', 50.11710000, -5.47780000, 'St Michael Mount Cornwall', ARRAY['cornwall']::text[], ARRAY['cornwall']::text[], 'St Michaels Mount Cornwall.jpg'),
    ('newquay-fistral-beach', 'cornwall', 'BEACH', 3, 'HOURS', 4.7, 'Фистрал-Бич', 'Fistral Beach Newquay', 'Ньюки Фистрал жағажайы', 50.41690000, -5.09910000, 'Fistral Beach Newquay', ARRAY['cornwall']::text[], ARRAY['cornwall']::text[], 'Fistral Beach Newquay.jpg'),
    ('dartmoor-national-park', 'devon', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Дартмур', 'Dartmoor National Park', 'Дартмур ұлттық паркі', 50.57100000, -3.92000000, 'Dartmoor National Park', ARRAY['devon']::text[], ARRAY['bristol', 'devon']::text[], 'Dartmoor National Park.jpg'),
    ('exeter-cathedral', 'devon', 'TEMPLE', 2, 'HOURS', 4.7, 'Эксетерский собор', 'Exeter Cathedral', 'Эксетер соборы', 50.72250000, -3.52970000, 'Exeter Cathedral', ARRAY['devon']::text[], ARRAY['devon']::text[], 'Exeter Cathedral.jpg'),

    ('york-minster', 'york', 'TEMPLE', 2, 'HOURS', 4.8, 'Йоркский собор', 'York Minster', 'Йорк соборы', 53.96230000, -1.08190000, 'York Minster', ARRAY['york']::text[], ARRAY['manchester', 'york']::text[], 'York Minster from city walls.jpg'),
    ('national-railway-museum-york', 'york', 'MUSEUM', 3, 'HOURS', 4.7, 'Национальный железнодорожный музей Йорка', 'National Railway Museum York', 'Йорк ұлттық теміржол музейі', 53.95900000, -1.09740000, 'National Railway Museum York', ARRAY['york']::text[], ARRAY['york']::text[], 'National Railway Museum York.jpg'),
    ('shambles-market-york', 'york', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Шемблз в Йорке', 'Shambles Market York', 'Йорк Шемблз базары', 53.95990000, -1.08010000, 'Shambles Market York', ARRAY['york']::text[], ARRAY['york']::text[], 'Shambles Market York.jpg'),
    ('science-industry-museum-manchester', 'manchester', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей науки и промышленности Манчестера', 'Science and Industry Museum Manchester', 'Манчестер ғылым және өнеркәсіп музейі', 53.47730000, -2.25450000, 'Science and Industry Museum Manchester', ARRAY['manchester']::text[], ARRAY['manchester']::text[], 'Science and Industry Museum Manchester.jpg'),
    ('john-rylands-library', 'manchester', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Библиотека Джона Райлендса', 'John Rylands Library', 'Джон Райлендс кітапханасы', 53.48020000, -2.24800000, 'John Rylands Library Manchester', ARRAY['manchester']::text[], ARRAY['manchester']::text[], 'John Rylands Library Manchester.jpg'),
    ('mackie-mayor', 'manchester', 'FOOD', 2, 'HOURS', 4.5, 'Mackie Mayor', 'Mackie Mayor', 'Mackie Mayor', 53.48490000, -2.23740000, 'Mackie Mayor Manchester', ARRAY['manchester']::text[], ARRAY['manchester']::text[], 'Mackie Mayor Manchester.jpg'),
    ('liverpool-albert-dock', 'liverpool', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Альберт-док в Ливерпуле', 'Liverpool Albert Dock', 'Ливерпуль Альберт док', 53.40030000, -2.99270000, 'Royal Albert Dock Liverpool', ARRAY['liverpool']::text[], ARRAY['manchester', 'liverpool']::text[], 'Royal Albert Dock Liverpool.jpg'),
    ('museum-of-liverpool', 'liverpool', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Ливерпуля', 'Museum of Liverpool', 'Ливерпуль музейі', 53.40250000, -2.99500000, 'Museum of Liverpool', ARRAY['liverpool']::text[], ARRAY['liverpool']::text[], 'Museum of Liverpool.jpg'),
    ('the-beatles-story', 'liverpool', 'MUSEUM', 2, 'HOURS', 4.6, 'The Beatles Story', 'The Beatles Story', 'The Beatles Story', 53.39970000, -2.99290000, 'The Beatles Story Liverpool', ARRAY['liverpool']::text[], ARRAY['liverpool']::text[], 'The Beatles Story Liverpool.jpg'),
    ('baltic-market-liverpool', 'liverpool', 'FOOD', 2, 'HOURS', 4.5, 'Baltic Market Liverpool', 'Baltic Market Liverpool', 'Baltic Market Liverpool', 53.39390000, -2.98190000, 'Baltic Market Liverpool', ARRAY['liverpool']::text[], ARRAY['liverpool']::text[], 'Baltic Market Liverpool.jpg'),
    ('bullring-birmingham', 'birmingham', 'SHOPPING', 2, 'HOURS', 4.5, 'Bullring Birmingham', 'Bullring Birmingham', 'Bullring Birmingham', 52.47760000, -1.89490000, 'Bullring Birmingham', ARRAY['birmingham']::text[], ARRAY['birmingham']::text[], 'Bullring Birmingham.jpg'),
    ('thinktank-birmingham', 'birmingham', 'MUSEUM', 3, 'HOURS', 4.5, 'Thinktank Birmingham Science Museum', 'Thinktank Birmingham Science Museum', 'Thinktank Birmingham Science Museum', 52.48270000, -1.88680000, 'Thinktank Birmingham Science Museum', ARRAY['birmingham']::text[], ARRAY['birmingham']::text[], 'Thinktank Birmingham Science Museum.jpg'),
    ('birmingham-back-to-backs', 'birmingham', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Birmingham Back to Backs', 'Birmingham Back to Backs', 'Birmingham Back to Backs', 52.47480000, -1.89770000, 'Birmingham Back to Backs', ARRAY['birmingham']::text[], ARRAY['birmingham']::text[], 'Birmingham Back to Backs.jpg'),
    ('lake-district-national-park', 'lake-district', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Озерный край', 'Lake District National Park', 'Көлдер аймағы ұлттық паркі', 54.50000000, -3.16670000, 'Lake District National Park', ARRAY['lake-district']::text[], ARRAY['manchester', 'lake-district']::text[], 'Lake District National Park.jpg'),
    ('aira-force-ullswater', 'lake-district', 'NATURE', 3, 'HOURS', 4.7, 'Водопад Айра-Форс и Улсуотер', 'Aira Force and Ullswater', 'Айра-Форс және Улсуотер', 54.57590000, -2.92840000, 'Aira Force Ullswater Lake District', ARRAY['lake-district']::text[], ARRAY['lake-district']::text[], 'Aira Force waterfall.jpg'),
    ('windermere-lake-cruises', 'lake-district', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Круизы по озеру Уиндермир', 'Windermere Lake Cruises', 'Уиндермир көлі круиздері', 54.36370000, -2.92230000, 'Windermere Lake Cruises', ARRAY['lake-district']::text[], ARRAY['lake-district']::text[], 'Lake Windermere.jpg'),
    ('peak-district-national-park', 'peak-district', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Пик-Дистрикт', 'Peak District National Park', 'Пик-Дистрикт ұлттық паркі', 53.35000000, -1.83330000, 'Peak District National Park', ARRAY['peak-district']::text[], ARRAY['manchester', 'peak-district']::text[], 'Peak District National Park.jpg'),
    ('chatsworth-house', 'peak-district', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Чатсуорт-хаус', 'Chatsworth House', 'Чатсуорт-хаус', 53.22770000, -1.61020000, 'Chatsworth House Peak District', ARRAY['peak-district']::text[], ARRAY['peak-district']::text[], 'Chatsworth House.jpg'),
    ('mam-tor', 'peak-district', 'NATURE', 3, 'HOURS', 4.8, 'Мам-Тор', 'Mam Tor', 'Мам-Тор', 53.34900000, -1.80940000, 'Mam Tor Peak District', ARRAY['peak-district']::text[], ARRAY['peak-district']::text[], 'Mam Tor Peak District.jpg'),
    ('newcastle-castle', 'newcastle', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Ньюкасла', 'Newcastle Castle', 'Ньюкасл қамалы', 54.96820000, -1.61060000, 'Newcastle Castle UK', ARRAY['newcastle']::text[], ARRAY['newcastle']::text[], 'Newcastle Castle Keep.jpg'),
    ('great-north-museum', 'newcastle', 'MUSEUM', 2, 'HOURS', 4.5, 'Great North Museum Hancock', 'Great North Museum Hancock', 'Great North Museum Hancock', 54.97890000, -1.61470000, 'Great North Museum Hancock Newcastle', ARRAY['newcastle']::text[], ARRAY['newcastle']::text[], 'Great North Museum Hancock.jpg'),
    ('grainger-market', 'newcastle', 'MARKET', 1, 'HOURS', 4.5, 'Grainger Market', 'Grainger Market', 'Grainger Market', 54.97250000, -1.61550000, 'Grainger Market Newcastle', ARRAY['newcastle']::text[], ARRAY['newcastle']::text[], 'Grainger Market Newcastle.jpg'),
    ('royal-armouries-leeds', 'leeds', 'MUSEUM', 3, 'HOURS', 4.7, 'Royal Armouries Museum', 'Royal Armouries Museum', 'Royal Armouries Museum', 53.79190000, -1.53290000, 'Royal Armouries Museum Leeds', ARRAY['leeds']::text[], ARRAY['leeds']::text[], 'Royal Armouries Museum Leeds.jpg'),
    ('kirkstall-abbey', 'leeds', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Аббатство Киркстолл', 'Kirkstall Abbey', 'Киркстолл аббаттығы', 53.82030000, -1.60670000, 'Kirkstall Abbey Leeds', ARRAY['leeds']::text[], ARRAY['leeds']::text[], 'Kirkstall Abbey Leeds.jpg'),
    ('leeds-kirkgate-market', 'leeds', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Киркгейт в Лидсе', 'Leeds Kirkgate Market', 'Лидс Киркгейт базары', 53.79750000, -1.53790000, 'Leeds Kirkgate Market', ARRAY['leeds']::text[], ARRAY['leeds']::text[], 'Leeds Kirkgate Market.jpg'),

    ('edinburgh-castle', 'edinburgh', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Эдинбургский замок', 'Edinburgh Castle', 'Эдинбург қамалы', 55.94860000, -3.19990000, 'Edinburgh Castle', ARRAY['edinburgh']::text[], ARRAY['edinburgh']::text[], 'Edinburgh Castle from the south east.JPG'),
    ('national-museum-scotland', 'edinburgh', 'MUSEUM', 3, 'HOURS', 4.8, 'Национальный музей Шотландии', 'National Museum of Scotland', 'Шотландия ұлттық музейі', 55.94710000, -3.18900000, 'National Museum of Scotland Edinburgh', ARRAY['edinburgh']::text[], ARRAY['edinburgh']::text[], 'National Museum of Scotland.jpg'),
    ('arthurs-seat', 'edinburgh', 'NATURE', 3, 'HOURS', 4.8, 'Arthur''s Seat', 'Arthur''s Seat', 'Arthur''s Seat', 55.94420000, -3.16180000, 'Arthur Seat Edinburgh', ARRAY['edinburgh']::text[], ARRAY['edinburgh']::text[], 'Arthurs Seat Edinburgh.jpg'),
    ('royal-mile', 'edinburgh', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Королевская миля', 'Royal Mile Edinburgh', 'Эдинбург Корольдік милясы', 55.95030000, -3.18850000, 'Royal Mile Edinburgh', ARRAY['edinburgh']::text[], ARRAY['edinburgh']::text[], 'Royal Mile Edinburgh.jpg'),
    ('kelvingrove-art-gallery-museum', 'glasgow', 'MUSEUM', 3, 'HOURS', 4.8, 'Художественная галерея и музей Келвингроув', 'Kelvingrove Art Gallery and Museum', 'Келвингроув өнер галереясы және музейі', 55.86860000, -4.29060000, 'Kelvingrove Art Gallery and Museum Glasgow', ARRAY['glasgow']::text[], ARRAY['glasgow']::text[], 'Kelvingrove Art Gallery and Museum.jpg'),
    ('glasgow-cathedral', 'glasgow', 'TEMPLE', 2, 'HOURS', 4.7, 'Собор Глазго', 'Glasgow Cathedral', 'Глазго соборы', 55.86260000, -4.23430000, 'Glasgow Cathedral', ARRAY['glasgow']::text[], ARRAY['glasgow']::text[], 'Glasgow Cathedral.jpg'),
    ('barras-market', 'glasgow', 'MARKET', 2, 'HOURS', 4.4, 'The Barras Market', 'The Barras Market', 'The Barras Market', 55.85530000, -4.23490000, 'The Barras Market Glasgow', ARRAY['glasgow']::text[], ARRAY['glasgow']::text[], 'Barras Market Glasgow.jpg'),
    ('inverness-castle-viewpoint', 'inverness', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Смотровая площадка Инвернесского замка', 'Inverness Castle Viewpoint', 'Инвернесс қамалы көрінісі', 57.47610000, -4.22670000, 'Inverness Castle Viewpoint', ARRAY['inverness']::text[], ARRAY['inverness']::text[], 'Inverness Castle.jpg'),
    ('ullapool-harbour-highlands', 'highlands', 'NATURE', 2, 'HOURS', 4.6, 'Гавань Уллапула', 'Ullapool Harbour Highlands', 'Хайлендс Уллапул айлағы', 57.89540000, -5.16000000, 'Ullapool Harbour Highlands Scotland', ARRAY['highlands']::text[], ARRAY['inverness', 'highlands']::text[], 'Ullapool harbour.jpg'),
    ('glenfinnan-viaduct', 'highlands', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Виадук Гленфиннан', 'Glenfinnan Viaduct', 'Гленфиннан виадугы', 56.87630000, -5.43150000, 'Glenfinnan Viaduct Scotland', ARRAY['highlands']::text[], ARRAY['inverness', 'highlands']::text[], 'Glenfinnan Viaduct.jpg'),
    ('loch-ness', 'loch-ness', 'NATURE', 3, 'HOURS', 4.7, 'Лох-Несс', 'Loch Ness', 'Лох-Несс', 57.32290000, -4.42440000, 'Loch Ness Scotland', ARRAY['loch-ness']::text[], ARRAY['inverness', 'loch-ness']::text[], 'Loch Ness Urquhart Castle.jpg'),
    ('urquhart-castle', 'loch-ness', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Уркхарт', 'Urquhart Castle', 'Уркхарт қамалы', 57.32400000, -4.44270000, 'Urquhart Castle Loch Ness', ARRAY['loch-ness']::text[], ARRAY['inverness', 'loch-ness']::text[], 'Urquhart Castle Loch Ness.jpg'),
    ('old-man-of-storr', 'isle-of-skye', 'NATURE', 3, 'HOURS', 4.8, 'Старик Сторр', 'Old Man of Storr', 'Сторр қартасы', 57.50690000, -6.18330000, 'Old Man of Storr Isle of Skye', ARRAY['isle-of-skye']::text[], ARRAY['inverness', 'isle-of-skye']::text[], 'Old Man of Storr Skye.jpg'),
    ('fairy-pools-skye', 'isle-of-skye', 'NATURE', 3, 'HOURS', 4.7, 'Волшебные бассейны Ская', 'Fairy Pools Isle of Skye', 'Скай ертегі бассейндері', 57.25050000, -6.27270000, 'Fairy Pools Isle of Skye', ARRAY['isle-of-skye']::text[], ARRAY['isle-of-skye']::text[], 'Fairy Pools Isle of Skye.jpg'),
    ('eilean-donan-castle', 'highlands', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Эйлен-Донан', 'Eilean Donan Castle', 'Эйлен-Донан қамалы', 57.27400000, -5.51600000, 'Eilean Donan Castle Scotland', ARRAY['highlands']::text[], ARRAY['inverness', 'highlands', 'isle-of-skye']::text[], 'Eilean Donan Castle.jpg'),
    ('aberdeen-maritime-museum', 'aberdeen', 'MUSEUM', 2, 'HOURS', 4.5, 'Морской музей Абердина', 'Aberdeen Maritime Museum', 'Абердин теңіз музейі', 57.14760000, -2.09430000, 'Aberdeen Maritime Museum', ARRAY['aberdeen']::text[], ARRAY['aberdeen']::text[], 'Aberdeen Maritime Museum.jpg'),
    ('st-andrews-cathedral', 'st-andrews', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Собор Сент-Эндрюса', 'St Andrews Cathedral', 'Сент-Эндрюс соборы', 56.34030000, -2.78750000, 'St Andrews Cathedral Scotland', ARRAY['st-andrews']::text[], ARRAY['edinburgh', 'st-andrews']::text[], 'St Andrews Cathedral ruins.jpg'),

    ('cardiff-castle', 'cardiff', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Кардиффский замок', 'Cardiff Castle', 'Кардифф қамалы', 51.48100000, -3.18100000, 'Cardiff Castle', ARRAY['cardiff']::text[], ARRAY['cardiff']::text[], 'Cardiff Castle Keep.jpg'),
    ('national-museum-cardiff', 'cardiff', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей Кардиффа', 'National Museum Cardiff', 'Кардифф ұлттық музейі', 51.48560000, -3.17730000, 'National Museum Cardiff', ARRAY['cardiff']::text[], ARRAY['cardiff']::text[], 'National Museum Cardiff.jpg'),
    ('bute-park', 'cardiff', 'PARK', 2, 'HOURS', 4.6, 'Бьют-парк', 'Bute Park', 'Бьют-парк', 51.48670000, -3.19010000, 'Bute Park Cardiff', ARRAY['cardiff']::text[], ARRAY['cardiff']::text[], 'Bute Park Cardiff.jpg'),
    ('cardiff-market', 'cardiff', 'MARKET', 1, 'HOURS', 4.5, 'Кардиффский рынок', 'Cardiff Market', 'Кардифф базары', 51.48080000, -3.17800000, 'Cardiff Market', ARRAY['cardiff']::text[], ARRAY['cardiff']::text[], 'Cardiff Market.jpg'),
    ('eryri-snowdonia-national-park', 'snowdonia', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Сноудония', 'Eryri Snowdonia National Park', 'Сноудония ұлттық паркі', 52.90060000, -3.84930000, 'Eryri Snowdonia National Park', ARRAY['snowdonia']::text[], ARRAY['cardiff', 'snowdonia']::text[], 'Snowdonia National Park.jpg'),
    ('yr-wyddfa-snowdon', 'snowdonia', 'NATURE', 5, 'HOURS', 4.8, 'Гора Сноудон', 'Yr Wyddfa Snowdon', 'Сноудон тауы', 53.06850000, -4.07630000, 'Yr Wyddfa Snowdon Wales', ARRAY['snowdonia']::text[], ARRAY['snowdonia']::text[], 'Snowdon from Llyn Llydaw.jpg'),
    ('national-slate-museum', 'snowdonia', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей сланца', 'National Slate Museum', 'Ұлттық шифер музейі', 53.11740000, -4.11820000, 'National Slate Museum Wales', ARRAY['snowdonia']::text[], ARRAY['snowdonia']::text[], 'National Slate Museum Llanberis.jpg'),
    ('conwy-castle', 'conwy', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Конуи', 'Conwy Castle', 'Конуи қамалы', 53.28000000, -3.82560000, 'Conwy Castle Wales', ARRAY['conwy']::text[], ARRAY['snowdonia', 'conwy']::text[], 'Conwy Castle.jpg'),
    ('plas-mawr', 'conwy', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Плас-Маур', 'Plas Mawr', 'Плас-Маур', 53.28080000, -3.82900000, 'Plas Mawr Conwy', ARRAY['conwy']::text[], ARRAY['conwy']::text[], 'Plas Mawr Conwy.jpg'),
    ('pembrokeshire-coast-national-park', 'pembrokeshire', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк побережья Пембрукшира', 'Pembrokeshire Coast National Park', 'Пембрукшир жағалауы ұлттық паркі', 51.80000000, -5.10000000, 'Pembrokeshire Coast National Park', ARRAY['pembrokeshire']::text[], ARRAY['cardiff', 'pembrokeshire']::text[], 'Pembrokeshire Coast National Park.jpg'),
    ('barafundle-bay', 'pembrokeshire', 'BEACH', 3, 'HOURS', 4.8, 'Барафандл-Бей', 'Barafundle Bay', 'Барафандл шығанағы', 51.61690000, -4.89720000, 'Barafundle Bay Pembrokeshire', ARRAY['pembrokeshire']::text[], ARRAY['pembrokeshire']::text[], 'Barafundle Bay.jpg'),
    ('st-davids-cathedral', 'pembrokeshire', 'TEMPLE', 2, 'HOURS', 4.7, 'Собор Святого Давида', 'St Davids Cathedral', 'Әулие Дэвид соборы', 51.88200000, -5.26850000, 'St Davids Cathedral Wales', ARRAY['pembrokeshire']::text[], ARRAY['pembrokeshire']::text[], 'St Davids Cathedral.jpg'),
    ('titanic-belfast', 'belfast', 'MUSEUM', 3, 'HOURS', 4.8, 'Titanic Belfast', 'Titanic Belfast', 'Titanic Belfast', 54.60810000, -5.90970000, 'Titanic Belfast', ARRAY['belfast']::text[], ARRAY['belfast']::text[], 'Titanic Belfast.jpg'),
    ('ulster-museum', 'belfast', 'MUSEUM', 2, 'HOURS', 4.6, 'Ольстерский музей', 'Ulster Museum', 'Ольстер музейі', 54.58200000, -5.93500000, 'Ulster Museum Belfast', ARRAY['belfast']::text[], ARRAY['belfast']::text[], 'Ulster Museum Belfast.jpg'),
    ('st-georges-market-belfast', 'belfast', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Святого Георгия в Белфасте', 'St George''s Market Belfast', 'Белфаст Әулие Георгий базары', 54.59610000, -5.92440000, 'St Georges Market Belfast', ARRAY['belfast']::text[], ARRAY['belfast']::text[], 'St Georges Market Belfast.jpg'),
    ('botanic-gardens-belfast', 'belfast', 'PARK', 1, 'HOURS', 4.5, 'Ботанический сад Белфаста', 'Botanic Gardens Belfast', 'Белфаст ботаникалық бағы', 54.58270000, -5.93390000, 'Botanic Gardens Belfast', ARRAY['belfast']::text[], ARRAY['belfast']::text[], 'Botanic Gardens Belfast.jpg'),
    ('giants-causeway', 'giants-causeway', 'NATURE', 3, 'HOURS', 4.9, 'Дорога гигантов', 'Giant''s Causeway', 'Гиганттар жолы', 55.24080000, -6.51160000, 'Giant Causeway Northern Ireland', ARRAY['giants-causeway']::text[], ARRAY['belfast', 'giants-causeway']::text[], 'Giants Causeway Northern Ireland.jpg'),
    ('carrick-a-rede', 'giants-causeway', 'NATURE', 2, 'HOURS', 4.7, 'Кэррик-а-Рид', 'Carrick-a-Rede', 'Кэррик-а-Рид', 55.23930000, -6.33290000, 'Carrick-a-Rede Northern Ireland', ARRAY['giants-causeway']::text[], ARRAY['giants-causeway']::text[], 'Carrick-a-Rede Rope Bridge.jpg'),
    ('dunluce-castle', 'giants-causeway', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Замок Данлюс', 'Dunluce Castle', 'Данлюс қамалы', 55.21190000, -6.57930000, 'Dunluce Castle Northern Ireland', ARRAY['giants-causeway']::text[], ARRAY['giants-causeway']::text[], 'Dunluce Castle.jpg'),
    ('derry-city-walls', 'derry', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Городские стены Дерри', 'Derry City Walls', 'Дерри қала қабырғалары', 54.99580000, -7.32310000, 'Derry City Walls', ARRAY['derry']::text[], ARRAY['belfast', 'derry']::text[], 'Derry City Walls.jpg'),
    ('museum-of-free-derry', 'derry', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей свободного Дерри', 'Museum of Free Derry', 'Еркін Дерри музейі', 54.99770000, -7.32680000, 'Museum of Free Derry', ARRAY['derry']::text[], ARRAY['derry']::text[], 'Museum of Free Derry.jpg');

CREATE TEMP TABLE seed_united_kingdom_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-united-kingdom-place:' || seed.slug) AS place_hash,
        md5('id-united-kingdom-media:' || seed.slug) AS media_hash
    FROM seed_united_kingdom_priority_places seed
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
    ARRAY['united-kingdom', city_id, slug, lower(category), 'united-kingdom-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Великобритании: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'United Kingdom tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Ұлыбритания туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'GB',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 30::numeric
        ELSE 15::numeric
    END,
    'GBP',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_united_kingdom_resolved_places
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
FROM seed_united_kingdom_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_united_kingdom_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_united_kingdom_resolved_places
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
FROM seed_united_kingdom_resolved_places seed
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
FROM seed_united_kingdom_resolved_places
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
    'GB',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_united_kingdom_resolved_places
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
    'GB',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_united_kingdom_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
