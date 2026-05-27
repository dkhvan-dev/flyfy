-- Priority Brazil destination attractions seed.
-- Brazil is seeded as a broad country destination with city-like tourist hubs
-- for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_brazil_resolved_attractions;
DROP TABLE IF EXISTS seed_brazil_priority_attractions;

CREATE TEMP TABLE seed_brazil_priority_attractions (
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

INSERT INTO seed_brazil_priority_attractions (
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
    ('christ-the-redeemer', 'rio-de-janeiro', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Христос-Искупитель', 'Christ the Redeemer', 'Құтқарушы Христос', -22.95190000, -43.21050000, 'Christ the Redeemer Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('sugarloaf-mountain', 'rio-de-janeiro', 'NATURE', 3, 'HOURS', 4.9, 'Гора Сахарная Голова', 'Sugarloaf Mountain', 'Қант басы тауы', -22.94920000, -43.15450000, 'Sugarloaf Mountain Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('copacabana-beach', 'rio-de-janeiro', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Копакабана', 'Copacabana Beach', 'Копакабана жағажайы', -22.97110000, -43.18220000, 'Copacabana Beach Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('ipanema-beach', 'rio-de-janeiro', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Ипанема', 'Ipanema Beach', 'Ипанема жағажайы', -22.98380000, -43.20960000, 'Ipanema Beach Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('museum-of-tomorrow', 'rio-de-janeiro', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей завтрашнего дня', 'Museum of Tomorrow', 'Ертеңгі күн музейі', -22.89470000, -43.17990000, 'Museum of Tomorrow Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('rio-botanical-garden', 'rio-de-janeiro', 'PARK', 3, 'HOURS', 4.8, 'Ботанический сад Рио-де-Жанейро', 'Rio de Janeiro Botanical Garden', 'Рио-де-Жанейро ботаникалық бағы', -22.96750000, -43.22460000, 'Rio de Janeiro Botanical Garden Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('tijuca-national-park', 'rio-de-janeiro', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Тижука', 'Tijuca National Park', 'Тижука ұлттық паркі', -22.95150000, -43.28320000, 'Tijuca National Park Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('maracana-stadium', 'rio-de-janeiro', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Стадион Маракана', 'Maracana Stadium', 'Маракана стадионы', -22.91220000, -43.23020000, 'Maracana Stadium Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('saara-market', 'rio-de-janeiro', 'MARKET', 2, 'HOURS', 4.4, 'Рынок SAARA', 'SAARA Market Rio', 'Рио SAARA базары', -22.90410000, -43.18250000, 'SAARA Market Rio de Janeiro Brazil', ARRAY['rio-de-janeiro']::text[], ARRAY['rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('petropolis-imperial-museum', 'petropolis', 'MUSEUM', 2, 'HOURS', 4.8, 'Императорский музей Петрополиса', 'Imperial Museum Petropolis', 'Петрополис императорлық музейі', -22.50590000, -43.17760000, 'Imperial Museum Petropolis Brazil', ARRAY['petropolis', 'rio-de-janeiro']::text[], ARRAY['petropolis', 'rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('paraty-historic-center', 'paraty', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Парати', 'Paraty Historic Center', 'Парати тарихи орталығы', -23.21700000, -44.71300000, 'Paraty Historic Center Brazil', ARRAY['paraty', 'rio-de-janeiro']::text[], ARRAY['paraty', 'rio-de-janeiro']::text[], 'Christ the Redeemer - Cristo Redentor.jpg'),
    ('buzios-rua-das-pedras', 'buzios', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Руа-дас-Педрас в Бузиосе', 'Rua das Pedras Buzios', 'Бузиос Руа-дас-Педрас', -22.75590000, -41.88760000, 'Rua das Pedras Buzios Brazil', ARRAY['buzios']::text[], ARRAY['buzios', 'rio-de-janeiro']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('ilha-grande-angra', 'angra-dos-reis', 'NATURE', 6, 'HOURS', 4.8, 'Илья-Гранде', 'Ilha Grande Angra dos Reis', 'Илья-Гранде', -23.15000000, -44.23000000, 'Ilha Grande Angra dos Reis Brazil', ARRAY['angra-dos-reis', 'rio-de-janeiro']::text[], ARRAY['angra-dos-reis', 'rio-de-janeiro']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),

    ('ibirapuera-park', 'sao-paulo', 'PARK', 4, 'HOURS', 4.8, 'Парк Ибирапуэра', 'Ibirapuera Park', 'Ибирапуэра саябағы', -23.58740000, -46.65760000, 'Ibirapuera Park Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'Ibirapuera Park in São Paulo.jpg'),
    ('masp', 'sao-paulo', 'MUSEUM', 2, 'HOURS', 4.8, 'MASP', 'MASP', 'MASP', -23.56140000, -46.65590000, 'MASP Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('pinacoteca-sao-paulo', 'sao-paulo', 'MUSEUM', 2, 'HOURS', 4.7, 'Пинакотека Сан-Паулу', 'Pinacoteca de Sao Paulo', 'Сан-Паулу пинакотекасы', -23.53410000, -46.63390000, 'Pinacoteca de Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('municipal-market-sao-paulo', 'sao-paulo', 'MARKET', 2, 'HOURS', 4.6, 'Муниципальный рынок Сан-Паулу', 'Municipal Market of Sao Paulo', 'Сан-Паулу муниципалдық базары', -23.54190000, -46.62930000, 'Municipal Market of Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('paulista-avenue', 'sao-paulo', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Авенида Паулиста', 'Paulista Avenue', 'Паулиста даңғылы', -23.56170000, -46.65600000, 'Paulista Avenue Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('liberdade-sao-paulo', 'sao-paulo', 'FOOD', 3, 'HOURS', 4.6, 'Район Либердаде', 'Liberdade District Sao Paulo', 'Сан-Паулу Либердаде ауданы', -23.55500000, -46.63500000, 'Liberdade Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('shopping-morumbi', 'sao-paulo', 'SHOPPING', 3, 'HOURS', 4.5, 'Shopping Morumbi', 'Shopping Morumbi', 'Shopping Morumbi', -23.62300000, -46.69900000, 'Shopping Morumbi Sao Paulo Brazil', ARRAY['sao-paulo']::text[], ARRAY['sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('santos-coffee-museum', 'santos', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей кофе в Сантусе', 'Coffee Museum Santos', 'Сантус кофе музейі', -23.93380000, -46.32880000, 'Coffee Museum Santos Brazil', ARRAY['santos', 'sao-paulo']::text[], ARRAY['santos', 'sao-paulo']::text[], 'MASP Brazil.jpg'),
    ('santos-beach-gardens', 'santos', 'BEACH', 3, 'HOURS', 4.6, 'Пляжные сады Сантуса', 'Santos Beach Gardens', 'Сантус жағажай бақтары', -23.96910000, -46.33390000, 'Santos Beach Gardens Brazil', ARRAY['santos']::text[], ARRAY['santos', 'sao-paulo']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('curitiba-botanical-garden', 'curitiba', 'PARK', 3, 'HOURS', 4.8, 'Ботанический сад Куритибы', 'Botanical Garden of Curitiba', 'Куритиба ботаникалық бағы', -25.44290000, -49.24050000, 'Botanical Garden of Curitiba Brazil', ARRAY['curitiba']::text[], ARRAY['curitiba']::text[], 'Ibirapuera Park in São Paulo.jpg'),
    ('oscar-niemeyer-museum', 'curitiba', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Оскара Нимейера', 'Oscar Niemeyer Museum', 'Оскар Нимейер музейі', -25.41030000, -49.26770000, 'Oscar Niemeyer Museum Curitiba Brazil', ARRAY['curitiba']::text[], ARRAY['curitiba']::text[], 'Ibirapuera Park in São Paulo.jpg'),
    ('public-market-curitiba', 'curitiba', 'MARKET', 2, 'HOURS', 4.5, 'Муниципальный рынок Куритибы', 'Curitiba Municipal Market', 'Куритиба муниципалдық базары', -25.42870000, -49.25770000, 'Curitiba Municipal Market Brazil', ARRAY['curitiba']::text[], ARRAY['curitiba']::text[], 'Ibirapuera Park in São Paulo.jpg'),
    ('iguazu-falls', 'foz-do-iguacu', 'NATURE', 5, 'HOURS', 4.9, 'Водопады Игуасу', 'Iguazu Falls', 'Игуасу сарқырамалары', -25.69530000, -54.43670000, 'Iguazu Falls Foz do Iguacu Brazil', ARRAY['foz-do-iguacu']::text[], ARRAY['foz-do-iguacu', 'curitiba']::text[], 'Iguazu-Falls-January-2013.jpg'),
    ('bird-park-foz', 'foz-do-iguacu', 'PARK', 3, 'HOURS', 4.7, 'Парк птиц Фос-ду-Игуасу', 'Bird Park Foz do Iguacu', 'Фос-ду-Игуасу құстар паркі', -25.61350000, -54.48300000, 'Parque das Aves Foz do Iguacu Brazil', ARRAY['foz-do-iguacu']::text[], ARRAY['foz-do-iguacu']::text[], 'Iguazu-Falls-January-2013.jpg'),
    ('itaipu-dam', 'foz-do-iguacu', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Плотина Итайпу', 'Itaipu Dam', 'Итайпу бөгеті', -25.40770000, -54.58830000, 'Itaipu Dam Foz do Iguacu Brazil', ARRAY['foz-do-iguacu']::text[], ARRAY['foz-do-iguacu']::text[], 'Iguazu-Falls-January-2013.jpg'),
    ('joaquina-beach', 'florianopolis', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Жоакина', 'Joaquina Beach', 'Жоакина жағажайы', -27.62980000, -48.44930000, 'Joaquina Beach Florianopolis Brazil', ARRAY['florianopolis']::text[], ARRAY['florianopolis']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('lagoa-conceicao', 'florianopolis', 'NATURE', 3, 'HOURS', 4.7, 'Лагоа-да-Консейсан', 'Lagoa da Conceicao', 'Лагоа-да-Консейсан', -27.59490000, -48.46320000, 'Lagoa da Conceicao Florianopolis Brazil', ARRAY['florianopolis']::text[], ARRAY['florianopolis']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('gramado-mini-mundo', 'gramado', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Mini Mundo', 'Mini Mundo Gramado', 'Грамаду Mini Mundo', -29.38150000, -50.87410000, 'Mini Mundo Gramado Brazil', ARRAY['gramado']::text[], ARRAY['gramado', 'porto-alegre']::text[], 'Ibirapuera Park in São Paulo.jpg'),
    ('porto-alegre-public-market', 'porto-alegre', 'MARKET', 2, 'HOURS', 4.6, 'Публичный рынок Порту-Алегри', 'Porto Alegre Public Market', 'Порту-Алегри қоғамдық базары', -30.02760000, -51.22870000, 'Porto Alegre Public Market Brazil', ARRAY['porto-alegre']::text[], ARRAY['porto-alegre']::text[], 'Ibirapuera Park in São Paulo.jpg'),

    ('pelourinho', 'salvador', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Пелуринью', 'Pelourinho', 'Пелуринью', -12.97110000, -38.51080000, 'Pelourinho Salvador Bahia Brazil', ARRAY['salvador']::text[], ARRAY['salvador']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('mercado-modelo-salvador', 'salvador', 'MARKET', 2, 'HOURS', 4.6, 'Mercado Modelo Salvador', 'Mercado Modelo Salvador', 'Mercado Modelo Salvador', -12.97350000, -38.51360000, 'Mercado Modelo Salvador Brazil', ARRAY['salvador']::text[], ARRAY['salvador']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('elevador-lacerda', 'salvador', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Лифт Ласерда', 'Elevador Lacerda', 'Ласерда лифті', -12.97310000, -38.51220000, 'Elevador Lacerda Salvador Brazil', ARRAY['salvador']::text[], ARRAY['salvador']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('bonfim-church', 'salvador', 'TEMPLE', 2, 'HOURS', 4.8, 'Церковь Бонфин', 'Bonfim Church Salvador', 'Салвадор Бонфин шіркеуі', -12.92370000, -38.50850000, 'Bonfim Church Salvador Brazil', ARRAY['salvador']::text[], ARRAY['salvador']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('barra-lighthouse-salvador', 'salvador', 'MUSEUM', 2, 'HOURS', 4.7, 'Маяк Барра', 'Barra Lighthouse Salvador', 'Салвадор Барра маягы', -13.01080000, -38.53280000, 'Barra Lighthouse Salvador Brazil', ARRAY['salvador']::text[], ARRAY['salvador']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('recife-antigo', 'recife', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Старый Ресифи', 'Recife Antigo', 'Ескі Ресифи', -8.06320000, -34.87110000, 'Recife Antigo Brazil', ARRAY['recife']::text[], ARRAY['recife']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('instituto-ricardo-brennand', 'recife', 'MUSEUM', 3, 'HOURS', 4.8, 'Институт Рикарду Бреннанда', 'Instituto Ricardo Brennand', 'Рикарду Бреннанд институты', -8.06550000, -34.95840000, 'Instituto Ricardo Brennand Recife Brazil', ARRAY['recife']::text[], ARRAY['recife']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('boa-viagem-beach', 'recife', 'BEACH', 4, 'HOURS', 4.5, 'Пляж Боа-Виажем', 'Boa Viagem Beach', 'Боа-Виажем жағажайы', -8.12590000, -34.90000000, 'Boa Viagem Beach Recife Brazil', ARRAY['recife']::text[], ARRAY['recife']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('olinda-historic-center', 'olinda', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Исторический центр Олинды', 'Olinda Historic Center', 'Олинда тарихи орталығы', -8.01370000, -34.84960000, 'Olinda Historic Center Brazil', ARRAY['olinda', 'recife']::text[], ARRAY['olinda', 'recife']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('porto-galinhas-natural-pools', 'porto-de-galinhas', 'NATURE', 4, 'HOURS', 4.8, 'Природные бассейны Порту-де-Галиньяс', 'Porto de Galinhas Natural Pools', 'Порту-де-Галиньяс табиғи бассейндері', -8.50450000, -35.00020000, 'Porto de Galinhas Natural Pools Brazil', ARRAY['porto-de-galinhas', 'recife']::text[], ARRAY['porto-de-galinhas', 'recife']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('ponta-negra-beach', 'natal', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Понта-Негра', 'Ponta Negra Beach Natal', 'Натал Понта-Негра жағажайы', -5.87990000, -35.17100000, 'Ponta Negra Beach Natal Brazil', ARRAY['natal']::text[], ARRAY['natal']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('genipabu-dunes', 'natal', 'NATURE', 4, 'HOURS', 4.7, 'Дюны Женипабу', 'Genipabu Dunes', 'Женипабу құмдары', -5.70050000, -35.19860000, 'Genipabu Dunes Natal Brazil', ARRAY['natal']::text[], ARRAY['natal']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('pipa-beach', 'pipa', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Пипа', 'Pipa Beach', 'Пипа жағажайы', -6.22850000, -35.04870000, 'Pipa Beach Brazil', ARRAY['pipa', 'natal']::text[], ARRAY['pipa', 'natal']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('praia-do-futuro', 'fortaleza', 'BEACH', 4, 'HOURS', 4.6, 'Прайя-ду-Футуру', 'Praia do Futuro', 'Прайя-ду-Футуру', -3.73530000, -38.45050000, 'Praia do Futuro Fortaleza Brazil', ARRAY['fortaleza']::text[], ARRAY['fortaleza']::text[], 'Vista aérea das praias de Copacabana e de Ipanema (007ALA112).jpg'),
    ('dragao-do-mar-center', 'fortaleza', 'MUSEUM', 3, 'HOURS', 4.6, 'Культурный центр Драган-ду-Мар', 'Dragao do Mar Center', 'Драган-ду-Мар мәдени орталығы', -3.72160000, -38.51460000, 'Dragao do Mar Center Fortaleza Brazil', ARRAY['fortaleza']::text[], ARRAY['fortaleza']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('central-market-fortaleza', 'fortaleza', 'MARKET', 2, 'HOURS', 4.5, 'Центральный рынок Форталезы', 'Central Market Fortaleza', 'Форталеза орталық базары', -3.72480000, -38.52450000, 'Central Market Fortaleza Brazil', ARRAY['fortaleza']::text[], ARRAY['fortaleza']::text[], 'Largo do Pelourinho, Salvador 20150719-DSC05452.JPG'),
    ('jericoacoara-national-park', 'jericoacoara', 'NATURE', 6, 'HOURS', 4.9, 'Национальный парк Жерикоакоара', 'Jericoacoara National Park', 'Жерикоакоара ұлттық паркі', -2.80000000, -40.51000000, 'Jericoacoara National Park Brazil', ARRAY['jericoacoara', 'fortaleza']::text[], ARRAY['jericoacoara', 'fortaleza']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('sao-luis-historic-center', 'sao-luis', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Исторический центр Сан-Луиса', 'Sao Luis Historic Center', 'Сан-Луис тарихи орталығы', -2.52970000, -44.30280000, 'Sao Luis Historic Center Brazil', ARRAY['sao-luis']::text[], ARRAY['sao-luis']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('lencois-maranhenses', 'lencois-maranhenses', 'NATURE', 6, 'HOURS', 4.9, 'Национальный парк Ленсойс-Мараньенсис', 'Lencois Maranhenses National Park', 'Ленсойс-Мараньенсис ұлттық паркі', -2.53330000, -43.11670000, 'Lencois Maranhenses National Park Brazil', ARRAY['lencois-maranhenses', 'sao-luis']::text[], ARRAY['lencois-maranhenses', 'sao-luis']::text[], 'Lençóis Maranhenses 2018.jpg'),

    ('amazon-theatre', 'manaus', 'MUSEUM', 2, 'HOURS', 4.8, 'Театр Амазонас', 'Amazon Theatre', 'Амазонас театры', -3.13030000, -60.02360000, 'Amazon Theatre Manaus Brazil', ARRAY['manaus']::text[], ARRAY['manaus']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('meeting-of-waters', 'manaus', 'NATURE', 4, 'HOURS', 4.8, 'Слияние вод', 'Meeting of Waters Manaus', 'Сулар тоғысы', -3.13640000, -59.90530000, 'Meeting of Waters Manaus Brazil', ARRAY['manaus']::text[], ARRAY['manaus']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('adolpho-lisboa-market', 'manaus', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Адолфо Лисбоа', 'Adolpho Lisboa Market', 'Адолфо Лисбоа базары', -3.13920000, -60.02370000, 'Adolpho Lisboa Market Manaus Brazil', ARRAY['manaus']::text[], ARRAY['manaus']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('musa-manaus', 'manaus', 'PARK', 3, 'HOURS', 4.7, 'MUSA Манаус', 'MUSA Manaus', 'MUSA Манаус', -3.00160000, -59.93820000, 'MUSA Manaus Brazil', ARRAY['manaus']::text[], ARRAY['manaus']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('ver-o-peso-market', 'belem', 'MARKET', 2, 'HOURS', 4.7, 'Рынок Вер-у-Пезу', 'Ver-o-Peso Market', 'Вер-у-Пезу базары', -1.45420000, -48.50440000, 'Ver-o-Peso Market Belem Brazil', ARRAY['belem']::text[], ARRAY['belem']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('mangal-das-garcas', 'belem', 'PARK', 3, 'HOURS', 4.7, 'Парк Мангал-дас-Гарсас', 'Mangal das Garcas', 'Мангал-дас-Гарсас паркі', -1.46620000, -48.50060000, 'Mangal das Garcas Belem Brazil', ARRAY['belem']::text[], ARRAY['belem']::text[], 'Amazon Theatre, Teatro Amazonas. Manaus, Brazil. 03.jpg'),
    ('brasilia-cathedral', 'brasilia', 'TEMPLE', 1, 'HOURS', 4.8, 'Кафедральный собор Бразилиа', 'Brasilia Cathedral', 'Бразилиа кафедралды соборы', -15.79800000, -47.87550000, 'Brasilia Cathedral Brazil', ARRAY['brasilia']::text[], ARRAY['brasilia']::text[], 'Brasilia, Brazil National Cathedral (3124402502).jpg'),
    ('national-congress-brasilia', 'brasilia', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Национальный конгресс Бразилии', 'National Congress of Brazil', 'Бразилия ұлттық конгресі', -15.79960000, -47.86430000, 'National Congress of Brazil Brasilia', ARRAY['brasilia']::text[], ARRAY['brasilia']::text[], 'Brasilia, Brazil National Cathedral (3124402502).jpg'),
    ('pontao-lago-sul', 'brasilia', 'FOOD', 3, 'HOURS', 4.6, 'Понтан-ду-Лагу-Сул', 'Pontao do Lago Sul', 'Понтан-ду-Лагу-Сул', -15.83290000, -47.87280000, 'Pontao do Lago Sul Brasilia Brazil', ARRAY['brasilia']::text[], ARRAY['brasilia']::text[], 'Brasilia, Brazil National Cathedral (3124402502).jpg'),
    ('bonito-blue-lake-cave', 'bonito', 'NATURE', 3, 'HOURS', 4.8, 'Пещера Голубого озера Бонито', 'Bonito Blue Lake Cave', 'Бонито көгілдір көл үңгірі', -21.14690000, -56.58980000, 'Gruta do Lago Azul Bonito Brazil', ARRAY['bonito']::text[], ARRAY['bonito']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('rio-da-prata-bonito', 'bonito', 'NATURE', 4, 'HOURS', 4.8, 'Рио-да-Прата', 'Rio da Prata Bonito', 'Бонито Рио-да-Прата', -21.43700000, -56.44300000, 'Rio da Prata Bonito Brazil', ARRAY['bonito']::text[], ARRAY['bonito']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('pantanal', 'pantanal', 'NATURE', 6, 'HOURS', 4.9, 'Пантанал', 'Pantanal', 'Пантанал', -17.65000000, -57.43000000, 'Pantanal Brazil', ARRAY['pantanal', 'cuiaba']::text[], ARRAY['pantanal', 'cuiaba']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('chapada-guimaraes', 'cuiaba', 'NATURE', 5, 'HOURS', 4.8, 'Шапада-дус-Гимарайнс', 'Chapada dos Guimaraes', 'Шапада-дус-Гимарайнс', -15.46060000, -55.74970000, 'Chapada dos Guimaraes Cuiaba Brazil', ARRAY['cuiaba']::text[], ARRAY['cuiaba']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('chapada-dos-veadeiros', 'chapada-dos-veadeiros', 'NATURE', 6, 'HOURS', 4.9, 'Национальный парк Шапада-дус-Веадейрус', 'Chapada dos Veadeiros National Park', 'Шапада-дус-Веадейрус ұлттық паркі', -14.12000000, -47.65000000, 'Chapada dos Veadeiros National Park Brazil', ARRAY['chapada-dos-veadeiros', 'brasilia']::text[], ARRAY['chapada-dos-veadeiros', 'brasilia']::text[], 'Lençóis Maranhenses 2018.jpg'),
    ('ouro-preto-historic-center', 'ouro-preto', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Исторический центр Ору-Прету', 'Ouro Preto Historic Center', 'Ору-Прету тарихи орталығы', -20.38560000, -43.50350000, 'Ouro Preto Historic Center Brazil', ARRAY['ouro-preto', 'belo-horizonte']::text[], ARRAY['ouro-preto', 'belo-horizonte']::text[], 'Ouro Preto November 2009-11.jpg'),
    ('sao-francisco-assis-ouro-preto', 'ouro-preto', 'TEMPLE', 1, 'HOURS', 4.8, 'Церковь Сан-Франсиску-де-Ассис', 'Sao Francisco de Assis Church Ouro Preto', 'Ору-Прету Сан-Франсиску-де-Ассис шіркеуі', -20.38500000, -43.50390000, 'Sao Francisco de Assis Church Ouro Preto Brazil', ARRAY['ouro-preto']::text[], ARRAY['ouro-preto']::text[], 'Ouro Preto November 2009-11.jpg'),
    ('inhotim', 'belo-horizonte', 'MUSEUM', 6, 'HOURS', 4.9, 'Институт Иньотим', 'Inhotim', 'Иньотим институты', -20.12460000, -44.22040000, 'Inhotim Brumadinho Brazil', ARRAY['belo-horizonte']::text[], ARRAY['belo-horizonte']::text[], 'Ouro Preto November 2009-11.jpg'),
    ('liberdade-square-belo-horizonte', 'belo-horizonte', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Площадь Свободы Белу-Оризонти', 'Liberdade Square Belo Horizonte', 'Белу-Оризонти Еркіндік алаңы', -19.93270000, -43.93870000, 'Liberdade Square Belo Horizonte Brazil', ARRAY['belo-horizonte']::text[], ARRAY['belo-horizonte']::text[], 'Ouro Preto November 2009-11.jpg');

CREATE TEMP TABLE seed_brazil_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-brazil-attraction:' || seed.slug) AS attraction_hash,
        md5('id-brazil-media:' || seed.slug) AS media_hash
    FROM seed_brazil_priority_attractions seed
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
    ARRAY['brazil', city_id, slug, lower(category), 'brazil-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Бразилии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Brazil tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Бразилия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'BR',
    city_id,
    category,
    NULL::numeric,
    'BRL',
    duration_value,
    duration_unit,
    rating,
    0,
    NULL,
    'IMPORT',
    'PUBLISHED',
    tags,
    NOW(),
    NOW()
FROM seed_brazil_resolved_attractions
ON CONFLICT (id) DO UPDATE SET
    default_locale = EXCLUDED.default_locale,
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
    price_currency = EXCLUDED.price_currency,
    duration_value = EXCLUDED.duration_value,
    duration_unit = EXCLUDED.duration_unit,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    spots = EXCLUDED.spots,
    source = EXCLUDED.source,
    status = EXCLUDED.status,
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
FROM seed_brazil_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_brazil_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_brazil_resolved_attractions
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
FROM seed_brazil_resolved_attractions seed
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
FROM seed_brazil_resolved_attractions
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
    'BR',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_brazil_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'BR',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_brazil_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_brazil_resolved_attractions;
DROP TABLE IF EXISTS seed_brazil_priority_attractions;
