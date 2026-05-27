-- Priority Sweden destination attractions seed.
-- The seed covers Stockholm, Gothenburg, Malmo, Swedish Lapland, Gotland, Smaland, Blekinge, Oland, Dalarna, Jamtland, and key inland cities.

DROP TABLE IF EXISTS seed_sweden_resolved_attractions;
DROP TABLE IF EXISTS seed_sweden_priority_attractions;

CREATE TEMP TABLE seed_sweden_priority_attractions (
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

INSERT INTO seed_sweden_priority_attractions (
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
    ('vasa-museum', 'stockholm', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Васа', 'Vasa Museum', 'Васа музейі', 59.32800000, 18.09130000, 'Vasa Museum Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Vasa museum Vasamuset Stockholm Sweden (1).jpg'),
    ('stockholm-old-town-gamla-stan', 'stockholm', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый город Гамла Стан', 'Stockholm Old Town Gamla Stan', 'Стокгольм ескі қаласы Гамла Стан', 59.32500000, 18.07100000, 'Gamla Stan Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Gamla stan Stockholm July 2015.jpg'),
    ('royal-palace-stockholm', 'stockholm', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Королевский дворец Стокгольма', 'The Royal Palace Stockholm', 'Стокгольм король сарайы', 59.32680000, 18.07170000, 'Royal Palace Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Royal Palace, Stockholm 02100.JPG'),
    ('stockholm-city-hall', 'stockholm', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Стокгольмская ратуша', 'Stockholm City Hall', 'Стокгольм ратушасы', 59.32750000, 18.05430000, 'Stockholm City Hall', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Stockholm City Hall-147795.jpg'),
    ('skansen-open-air-museum', 'stockholm', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей под открытым небом Скансен', 'Skansen Open-Air Museum', 'Скансен ашық аспан музейі', 59.32520000, 18.10300000, 'Skansen Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Skansen Stockholm 2017 13.jpg'),
    ('abba-the-museum', 'stockholm', 'MUSEUM', 2, 'HOURS', 4.6, 'ABBA The Museum', 'ABBA The Museum', 'ABBA The Museum', 59.32540000, 18.09650000, 'ABBA The Museum Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'ABBA The Museum Stockholm.jpg'),
    ('grona-lund', 'stockholm', 'ENTERTAINMENT', 4, 'HOURS', 4.6, 'Парк аттракционов Грёна Лунд', 'Grona Lund Amusement Park', 'Грёна Лунд ойын-сауық паркі', 59.32330000, 18.09660000, 'Grona Lund Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Gröna Lund 2006.jpg'),
    ('fotografiska-stockholm', 'stockholm', 'MUSEUM', 2, 'HOURS', 4.6, 'Фотографиска Стокгольм', 'Fotografiska Stockholm', 'Фотографиска Стокгольм', 59.31770000, 18.08460000, 'Fotografiska Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Fotografiska Stockholm 2012.jpg'),
    ('nationalmuseum-stockholm', 'stockholm', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей Швеции', 'Nationalmuseum Stockholm', 'Швеция ұлттық музейі', 59.32860000, 18.07860000, 'Nationalmuseum Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Nationalmuseum Stockholm 2019.jpg'),
    ('moderna-museet-stockholm', 'stockholm', 'MUSEUM', 2, 'HOURS', 4.6, 'Модерна Музеет', 'Moderna Museet Stockholm', 'Модерна Музеет', 59.32590000, 18.08430000, 'Moderna Museet Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Moderna museet Stockholm.jpg'),
    ('ostermalm-market-hall', 'stockholm', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Эстермальмс Салухалль', 'Ostermalm Market Hall', 'Эстермальм базар залы', 59.33600000, 18.07850000, 'Ostermalm Market Hall Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Östermalms saluhall 2016.jpg'),
    ('hotorgshallen', 'stockholm', 'FOOD', 1, 'HOURS', 4.5, 'Хёторгсхаллен', 'Hotorgshallen', 'Хёторгсхаллен', 59.33560000, 18.06330000, 'Hotorgshallen Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Hötorgshallen.jpg'),
    ('westfield-mall-of-scandinavia', 'stockholm', 'SHOPPING', 3, 'HOURS', 4.5, 'Westfield Mall of Scandinavia', 'Westfield Mall of Scandinavia', 'Westfield Mall of Scandinavia', 59.37040000, 18.00320000, 'Westfield Mall of Scandinavia Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Mall of Scandinavia 2015.jpg'),
    ('langholmen-beach', 'stockholm', 'BEACH', 2, 'HOURS', 4.5, 'Лонгхольмен', 'Langholmen Beach', 'Лонгхольмен жағажайы', 59.32010000, 18.02960000, 'Langholmen Stockholm', ARRAY['stockholm']::text[], ARRAY['stockholm']::text[], 'Långholmen Stockholm 2006.jpg'),

    ('uppsala-cathedral', 'uppsala', 'TEMPLE', 1, 'HOURS', 4.8, 'Уппсальский собор', 'Uppsala Cathedral', 'Уппсала соборы', 59.85850000, 17.63350000, 'Uppsala Cathedral', ARRAY['uppsala']::text[], ARRAY['stockholm', 'uppsala']::text[], 'UppsalaCathedral.jpg'),
    ('uppsala-castle', 'uppsala', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Уппсальский замок', 'Uppsala Castle', 'Уппсала қамалы', 59.85380000, 17.63570000, 'Uppsala Castle', ARRAY['uppsala']::text[], ARRAY['stockholm', 'uppsala']::text[], 'Uppsala Castle 02.jpg'),
    ('gamla-uppsala-museum', 'uppsala', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Гамла Уппсала', 'Gamla Uppsala Museum', 'Гамла Уппсала музейі', 59.89890000, 17.63230000, 'Gamla Uppsala Museum', ARRAY['uppsala']::text[], ARRAY['uppsala']::text[], 'Royal mounds.JPG'),
    ('royal-mounds-gamla-uppsala', 'uppsala', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Королевские курганы Гамла Уппсала', 'Royal Mounds Gamla Uppsala', 'Гамла Уппсала патша қорғандары', 59.89910000, 17.63290000, 'Royal Mounds Gamla Uppsala', ARRAY['uppsala']::text[], ARRAY['uppsala']::text[], 'Royal mounds.JPG'),
    ('uppsala-botanical-garden', 'uppsala', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Уппсалы', 'Uppsala Botanical Garden', 'Уппсала ботаникалық бағы', 59.85300000, 17.63210000, 'Uppsala Botanical Garden', ARRAY['uppsala']::text[], ARRAY['uppsala']::text[], 'The botanical garden Uppsala Sweden 001.JPG'),
    ('vaksala-square-market', 'uppsala', 'MARKET', 1, 'HOURS', 4.4, 'Рынок на площади Ваксала', 'Vaksala Square Market', 'Ваксала алаңы базары', 59.85840000, 17.64560000, 'Vaksala Square Market Uppsala', ARRAY['uppsala']::text[], ARRAY['uppsala']::text[], 'UppsalaCathedral.jpg'),

    ('sigtuna-museum', 'sigtuna', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Сигтуны', 'Sigtuna Museum', 'Сигтуна музейі', 59.61630000, 17.72200000, 'Sigtuna Museum', ARRAY['sigtuna']::text[], ARRAY['stockholm', 'sigtuna']::text[], 'Sigtuna, Stora gatan, juni 2019.jpg'),
    ('stora-gatan-sigtuna', 'sigtuna', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Улица Стура Гатан', 'Stora Gatan Sigtuna', 'Сигтуна Стора Гатан', 59.61700000, 17.72250000, 'Stora Gatan Sigtuna', ARRAY['sigtuna']::text[], ARRAY['stockholm', 'sigtuna']::text[], 'Sigtuna, Stora gatan, juni 2019.jpg'),
    ('sigtuna-town-hall', 'sigtuna', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Старая ратуша Сигтуны', 'Sigtuna Town Hall', 'Сигтуна ратушасы', 59.61690000, 17.72260000, 'Sigtuna Town Hall', ARRAY['sigtuna']::text[], ARRAY['sigtuna']::text[], 'Sigtuna old city hall 2015.JPG'),
    ('sigtuna-runestones-walk', 'sigtuna', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Маршрут рунных камней Сигтуны', 'Sigtuna Runestones Walk', 'Сигтуна руна тастары бағыты', 59.61720000, 17.72280000, 'Sigtuna Runestones Walk', ARRAY['sigtuna']::text[], ARRAY['stockholm', 'sigtuna']::text[], 'Sigtuna, Stora gatan, juni 2019.jpg'),
    ('steninge-castle-village', 'sigtuna', 'SHOPPING', 2, 'HOURS', 4.4, 'Деревня замка Стенинге', 'Steninge Castle Village', 'Стенинге қамал ауылы', 59.57980000, 17.79080000, 'Steninge Castle Village Sigtuna', ARRAY['sigtuna']::text[], ARRAY['stockholm', 'sigtuna']::text[], 'Sigtuna, Stora gatan, juni 2019.jpg'),

    ('drottningholm-palace', 'drottningholm', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Дворец Дроттнингхольм', 'Drottningholm Palace', 'Дроттнингхольм сарайы', 59.32170000, 17.88680000, 'Drottningholm Palace', ARRAY['drottningholm', 'stockholm']::text[], ARRAY['stockholm', 'drottningholm']::text[], 'DrottningholmRoyalPalaceEast.jpg'),
    ('drottningholm-palace-theatre', 'drottningholm', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Театр дворца Дроттнингхольм', 'Drottningholm Palace Theatre', 'Дроттнингхольм сарай театры', 59.32220000, 17.88550000, 'Drottningholm Palace Theatre', ARRAY['drottningholm']::text[], ARRAY['stockholm', 'drottningholm']::text[], 'Drottningholm June 2013 07.jpg'),
    ('chinese-pavilion-drottningholm', 'drottningholm', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Китайский павильон Дроттнингхольм', 'Chinese Pavilion Drottningholm', 'Дроттнингхольм Қытай павильоны', 59.31850000, 17.88490000, 'Chinese Pavilion Drottningholm', ARRAY['drottningholm']::text[], ARRAY['stockholm', 'drottningholm']::text[], 'DrottningholmRoyalPalaceEast.jpg'),
    ('drottningholm-palace-park', 'drottningholm', 'PARK', 2, 'HOURS', 4.7, 'Парк дворца Дроттнингхольм', 'Drottningholm Palace Park', 'Дроттнингхольм сарай бағы', 59.32050000, 17.88460000, 'Drottningholm Palace Park', ARRAY['drottningholm']::text[], ARRAY['stockholm', 'drottningholm']::text[], 'Drottningholm Palace from the park.jpg'),

    ('liseberg-amusement-park', 'gothenburg', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Парк аттракционов Лисеберг', 'Liseberg Amusement Park', 'Лисеберг ойын-сауық паркі', 57.69500000, 11.99240000, 'Liseberg Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Liseberg 2013.jpg'),
    ('universeum', 'gothenburg', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Юниверсеум', 'Universeum', 'Юниверсеум', 57.69580000, 11.98960000, 'Universeum Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Universeum 2014.jpg'),
    ('slottsskogen', 'gothenburg', 'PARK', 2, 'HOURS', 4.7, 'Парк Слоттсскуген', 'Slottsskogen City Park', 'Слоттсскуген қалалық паркі', 57.68690000, 11.94270000, 'Slottsskogen Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Rönnbär i slottsskogen, Göteborg 2011 - panoramio.jpg'),
    ('gothenburg-botanical-garden', 'gothenburg', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Гётеборга', 'Gothenburg Botanical Garden', 'Гётеборг ботаникалық бағы', 57.68130000, 11.95140000, 'Gothenburg Botanical Garden', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Botaniska trädgården Göteborg.JPG'),
    ('museum-of-gothenburg', 'gothenburg', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Гётеборга', 'Museum of Gothenburg', 'Гётеборг музейі', 57.70850000, 11.96370000, 'Museum of Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Ostindiska huset Göteborg 2012.jpg'),
    ('gothenburg-museum-of-art', 'gothenburg', 'MUSEUM', 2, 'HOURS', 4.6, 'Художественный музей Гётеборга', 'Gothenburg Museum of Art', 'Гётеборг өнер музейі', 57.69660000, 11.97960000, 'Gothenburg Museum of Art', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Göteborgs konstmuseum.jpg'),
    ('feskekorka', 'gothenburg', 'MARKET', 1, 'HOURS', 4.5, 'Фескекёрка', 'Feskekorka', 'Фескекёрка', 57.70350000, 11.95890000, 'Feskekorka Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Sweden feskekorka by fred pettersonic.jpg'),
    ('stora-saluhallen-gothenburg', 'gothenburg', 'FOOD', 1, 'HOURS', 4.5, 'Стура Салухаллен', 'Stora Saluhallen Gothenburg', 'Стура Салухаллен', 57.70360000, 11.96970000, 'Stora Saluhallen Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Stora Saluhallen, Göteborg.JPG'),
    ('nordstan', 'gothenburg', 'SHOPPING', 2, 'HOURS', 4.4, 'Нордстан', 'Nordstan', 'Нордстан', 57.70880000, 11.97160000, 'Nordstan Gothenburg', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Nordstan Gothenburg.jpg'),
    ('gothenburg-archipelago', 'gothenburg', 'NATURE', 4, 'HOURS', 4.8, 'Гётеборгский архипелаг', 'Gothenburg Archipelago', 'Гётеборг архипелагы', 57.64700000, 11.77500000, 'Gothenburg Archipelago Saltholmen', ARRAY['gothenburg']::text[], ARRAY['gothenburg']::text[], 'Göteborg archipelago.jpg'),

    ('turning-torso', 'malmo', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Turning Torso', 'Turning Torso', 'Turning Torso', 55.61310000, 12.97660000, 'Turning Torso Malmo', ARRAY['malmo']::text[], ARRAY['malmo', 'lund']::text[], 'Malmo turning torso.jpg'),
    ('vastra-hamnen', 'malmo', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Район Вэстра Хамнен', 'Vastra Hamnen', 'Вэстра Хамнен', 55.61190000, 12.98090000, 'Vastra Hamnen Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Malmö - Turning Torso.jpg'),
    ('oresund-bridge', 'malmo', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Эресуннский мост', 'Oresund Bridge', 'Эресунн көпірі', 55.56500000, 12.88200000, 'Oresund Bridge Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Oresund Bridge from Lernacken.jpg'),
    ('malmohus-castle', 'malmo', 'MUSEUM', 2, 'HOURS', 4.6, 'Замок Мальмёхус', 'Malmohus Castle', 'Мальмёхус қамалы', 55.60480000, 12.98760000, 'Malmohus Castle Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Malmöhus slott.jpg'),
    ('moderna-museet-malmo', 'malmo', 'MUSEUM', 2, 'HOURS', 4.5, 'Модерна Музеет Мальмё', 'Moderna Museet Malmo', 'Модерна Музеет Мальмё', 55.60470000, 13.00720000, 'Moderna Museet Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Moderna Museet Malmö.jpg'),
    ('folkets-park-malmo', 'malmo', 'PARK', 2, 'HOURS', 4.5, 'Фолькетс Парк', 'Folkets Park Malmo', 'Фолькетс Парк', 55.59470000, 13.01450000, 'Folkets Park Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Folkets park Malmö.jpg'),
    ('ribersborg-beach', 'malmo', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Риберсборг', 'Ribersborg Beach', 'Риберсборг жағажайы', 55.60250000, 12.96450000, 'Ribersborg Beach Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Ribersborgsstranden Malmö.jpg'),
    ('mollevangstorget-market', 'malmo', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Мёллевонгсторгет', 'Mollevangstorget Market', 'Мёллевонгсторгет базары', 55.58990000, 13.00920000, 'Mollevangstorget Market Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Möllevångstorget.jpg'),
    ('malmo-saluhall', 'malmo', 'FOOD', 1, 'HOURS', 4.6, 'Мальмё Салухалль', 'Malmo Saluhall', 'Мальмё Салухалль', 55.60740000, 12.99480000, 'Malmo Saluhall', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Malmö Saluhall.jpg'),
    ('emporia-malmo', 'malmo', 'SHOPPING', 2, 'HOURS', 4.5, 'Emporia', 'Emporia Malmo', 'Emporia Malmo', 55.56330000, 12.97310000, 'Emporia Malmo', ARRAY['malmo']::text[], ARRAY['malmo']::text[], 'Emporia Malmö.jpg'),

    ('lund-cathedral', 'lund', 'TEMPLE', 1, 'HOURS', 4.8, 'Лундский собор', 'Lund Cathedral', 'Лунд соборы', 55.70470000, 13.19330000, 'Lund Cathedral', ARRAY['lund']::text[], ARRAY['malmo', 'lund']::text[], 'Lund Cathedral 2019.jpg'),
    ('kulturen-lund', 'lund', 'MUSEUM', 2, 'HOURS', 4.6, 'Культюрен в Лунде', 'Kulturen in Lund', 'Лунд Культюрен музейі', 55.70450000, 13.19650000, 'Kulturen Lund', ARRAY['lund']::text[], ARRAY['lund']::text[], 'Kulturen Lund Sweden.jpg'),
    ('skissernas-museum', 'lund', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Скиссернас', 'Skissernas Museum', 'Скиссернас музейі', 55.70670000, 13.20200000, 'Skissernas Museum Lund', ARRAY['lund']::text[], ARRAY['lund']::text[], 'Skissernas museum Lund.jpg'),
    ('botanical-garden-lund', 'lund', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Лунда', 'Botanical Garden Lund', 'Лунд ботаникалық бағы', 55.70420000, 13.20450000, 'Botanical Garden Lund', ARRAY['lund']::text[], ARRAY['lund']::text[], 'Lund Botanical Garden - Botaniska trädgården (51327462484).jpg'),
    ('saluhallen-lund', 'lund', 'FOOD', 1, 'HOURS', 4.5, 'Салухаллен Лунд', 'Saluhallen Lund', 'Салухаллен Лунд', 55.70240000, 13.19440000, 'Saluhallen Lund', ARRAY['lund']::text[], ARRAY['lund']::text[], 'Lundagård Lund.jpg'),

    ('karnan-helsingborg', 'helsingborg', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Башня Кернан', 'Karnan Helsingborg', 'Кернан мұнарасы', 56.04650000, 12.69520000, 'Karnan Helsingborg', ARRAY['helsingborg']::text[], ARRAY['malmo', 'helsingborg']::text[], 'Karnan Helsingborg 20161025 750A9908 (30930508123).jpg'),
    ('sofiero-palace-gardens', 'helsingborg', 'PARK', 2, 'HOURS', 4.7, 'Дворец и сады Софиеро', 'Sofiero Palace and Gardens', 'Софиеро сарайы мен бақтары', 56.08430000, 12.66050000, 'Sofiero Palace Helsingborg', ARRAY['helsingborg']::text[], ARRAY['helsingborg']::text[], 'Sofiero slott Helsingborg.jpg'),
    ('fredriksdal-museums-gardens', 'helsingborg', 'MUSEUM', 3, 'HOURS', 4.6, 'Фредриксдальские музеи и сады', 'Fredriksdal Museums and Gardens', 'Фредриксдаль музейлері мен бақтары', 56.05560000, 12.70520000, 'Fredriksdal Helsingborg', ARRAY['helsingborg']::text[], ARRAY['helsingborg']::text[], 'Fredriksdal Helsingborg.jpg'),
    ('tropikariet-helsingborg', 'helsingborg', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Тропикариет', 'Tropikariet Helsingborg', 'Тропикариет', 56.05650000, 12.70680000, 'Tropikariet Helsingborg', ARRAY['helsingborg']::text[], ARRAY['helsingborg']::text[], 'Karnan Helsingborg 20161025 750A9908 (30930508123).jpg'),
    ('tropical-beach-helsingborg', 'helsingborg', 'BEACH', 2, 'HOURS', 4.5, 'Тропический пляж', 'Tropical Beach Helsingborg', 'Тропикалық жағажай', 56.04120000, 12.68990000, 'Tropical Beach Helsingborg', ARRAY['helsingborg']::text[], ARRAY['helsingborg']::text[], 'Tropical Beach Helsingborg.jpg'),
    ('kullagatan-shopping', 'helsingborg', 'SHOPPING', 1, 'HOURS', 4.4, 'Куллагатан', 'Kullagatan Shopping Street', 'Куллагатан сауда көшесі', 56.04620000, 12.69300000, 'Kullagatan Helsingborg', ARRAY['helsingborg']::text[], ARRAY['helsingborg']::text[], 'Kullagatan Helsingborg.jpg'),

    ('kiruna-church', 'kiruna', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Кирунская церковь', 'Kiruna Church', 'Кируна шіркеуі', 67.85580000, 20.22530000, 'Kiruna Church', ARRAY['kiruna']::text[], ARRAY['kiruna']::text[], 'Kiruna Church in February 2016.jpg'),
    ('lkab-visitor-centre', 'kiruna', 'MUSEUM', 3, 'HOURS', 4.6, 'Визит-центр LKAB', 'LKAB Visitor Centre', 'LKAB келушілер орталығы', 67.85360000, 20.22520000, 'LKAB Visitor Centre Kiruna', ARRAY['kiruna']::text[], ARRAY['kiruna']::text[], 'Kiruna iron mine.jpg'),
    ('kin-museum-kiruna', 'kiruna', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей современного искусства Kin', 'Kin Museum of Contemporary Art', 'Kin заманауи өнер музейі', 67.84800000, 20.30690000, 'Kin Museum Kiruna', ARRAY['kiruna']::text[], ARRAY['kiruna']::text[], 'Kiruna Church in February 2016.jpg'),
    ('kiruna-city-transformation', 'kiruna', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Городская трансформация Кируны', 'Kiruna City Transformation', 'Кируна қаласының көшуі', 67.84800000, 20.30600000, 'Kiruna city transformation new city centre', ARRAY['kiruna']::text[], ARRAY['kiruna']::text[], 'Kiruna Church in February 2016.jpg'),
    ('esrange-visitor-center', 'kiruna', 'MUSEUM', 2, 'HOURS', 4.4, 'Визит-центр Esrange', 'Esrange Visitor Center', 'Esrange келушілер орталығы', 67.89070000, 21.08310000, 'Esrange Visitor Center Kiruna', ARRAY['kiruna']::text[], ARRAY['kiruna']::text[], 'Kiruna Church in February 2016.jpg'),

    ('icehotel-jukkasjarvi', 'jukkasjarvi', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'ICEHOTEL Юккасъярви', 'ICEHOTEL Jukkasjarvi', 'ICEHOTEL Юккасъярви', 67.85080000, 20.59500000, 'ICEHOTEL Jukkasjarvi', ARRAY['jukkasjarvi', 'kiruna']::text[], ARRAY['kiruna', 'jukkasjarvi']::text[], 'Ice Hotel Church Jukkasjärvi.jpg'),
    ('markanbaiki-sami-open-air-museum', 'jukkasjarvi', 'MUSEUM', 2, 'HOURS', 4.6, 'Саамский музей Марканбайки', 'Markanbaiki Sami Open Air Museum', 'Марканбайки саам ашық музейі', 67.84690000, 20.62150000, 'Markanbaiki Sami Open Air Museum Jukkasjarvi', ARRAY['jukkasjarvi']::text[], ARRAY['kiruna', 'jukkasjarvi']::text[], 'Ice Hotel 250207.jpg'),
    ('jukkasjarvi-church', 'jukkasjarvi', 'TEMPLE', 1, 'HOURS', 4.5, 'Церковь Юккасъярви', 'Jukkasjarvi Church', 'Юккасъярви шіркеуі', 67.84790000, 20.62170000, 'Jukkasjarvi Church', ARRAY['jukkasjarvi']::text[], ARRAY['jukkasjarvi']::text[], 'Ice Hotel Church Jukkasjärvi.jpg'),
    ('reindeer-lodge-jukkasjarvi', 'jukkasjarvi', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Reindeer Lodge', 'Reindeer Lodge Jukkasjarvi', 'Reindeer Lodge Юккасъярви', 67.84600000, 20.62100000, 'Reindeer Lodge Jukkasjarvi', ARRAY['jukkasjarvi']::text[], ARRAY['kiruna', 'jukkasjarvi']::text[], 'Ice Hotel 250207.jpg'),

    ('abisko-national-park', 'abisko', 'NATURE', 5, 'HOURS', 4.9, 'Национальный парк Абиску', 'Abisko National Park', 'Абиску ұлттық паркі', 68.35800000, 18.78300000, 'Abisko National Park', ARRAY['abisko']::text[], ARRAY['kiruna', 'abisko']::text[], 'Aurora near Abisko, Sweden, 4.jpg'),
    ('aurora-sky-station', 'abisko', 'NATURE', 3, 'HOURS', 4.8, 'Aurora Sky Station', 'STF Aurora Sky Station', 'Aurora Sky Station', 68.35980000, 18.69600000, 'Aurora Sky Station Abisko', ARRAY['abisko']::text[], ARRAY['abisko', 'kiruna']::text[], 'Aurora sky station view.jpg'),
    ('kungsleden-trailhead-abisko', 'abisko', 'NATURE', 3, 'HOURS', 4.8, 'Начало маршрута Кунгследен', 'Kungsleden Trailhead Abisko', 'Абиску Кунгследен бағыты', 68.35820000, 18.78370000, 'Kungsleden Trailhead Abisko', ARRAY['abisko']::text[], ARRAY['abisko']::text[], 'Abisko National Park.jpg'),
    ('naturum-abisko', 'abisko', 'MUSEUM', 1, 'HOURS', 4.5, 'Натурум Абиску', 'Naturum Abisko', 'Абиску Naturum', 68.35680000, 18.78300000, 'Naturum Abisko', ARRAY['abisko']::text[], ARRAY['abisko']::text[], 'Abisko National Park.jpg'),
    ('tornetrask-lapporten-viewpoint', 'abisko', 'NATURE', 2, 'HOURS', 4.8, 'Смотровая точка Торнетреск и Лаппортен', 'Tornetrask and Lapporten Viewpoint', 'Торнетреск және Лаппортен көрінісі', 68.36050000, 18.80000000, 'Tornetrask Lapporten Abisko', ARRAY['abisko']::text[], ARRAY['abisko']::text[], 'Aurora near Abisko, Sweden, 4.jpg'),

    ('gammelstad-church-town', 'lulea', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Церковный город Гаммельстад', 'Gammelstad Church Town', 'Гаммельстад шіркеу қалашығы', 65.64610000, 22.02830000, 'Gammelstad Church Town Lulea', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'Gammelstad-church-12.JPG'),
    ('gammelstad-visitor-center', 'lulea', 'MUSEUM', 1, 'HOURS', 4.5, 'Визит-центр Гаммельстад', 'Gammelstad Visitor Center', 'Гаммельстад келушілер орталығы', 65.64630000, 22.02800000, 'Gammelstad Visitor Center', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'The Church Town of Gammelstad, Nederluleå, Norrbotten, Sweden (32876218058).jpg'),
    ('open-air-museum-hagnan', 'lulea', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей под открытым небом Хэгнан', 'Open-air Museum Hagnan', 'Хэгнан ашық аспан музейі', 65.64900000, 22.02390000, 'Open-air Museum Hagnan Lulea', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'Gammelstad-church-12.JPG'),
    ('teknikens-hus', 'lulea', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Teknikens Hus', 'Teknikens Hus', 'Teknikens Hus', 65.61770000, 22.14060000, 'Teknikens Hus Lulea', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'Gammelstad-church-12.JPG'),
    ('lulea-ice-track', 'lulea', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Ледовая трасса Лулео', 'Lulea Ice Track', 'Лулео мұз жолы', 65.58420000, 22.15460000, 'Lulea Ice Track', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'Gammelstad-church-12.JPG'),
    ('gultzauudden', 'lulea', 'BEACH', 2, 'HOURS', 4.5, 'Гюльтзауудден', 'Gultzauudden', 'Гюльтзауудден', 65.58170000, 22.14920000, 'Gultzauudden Lulea', ARRAY['lulea']::text[], ARRAY['lulea']::text[], 'Gammelstad-church-12.JPG'),

    ('bildmuseet', 'umea', 'MUSEUM', 2, 'HOURS', 4.6, 'Бильдмузеет', 'Bildmuseet', 'Бильдмузеет', 63.81920000, 20.29020000, 'Bildmuseet Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Bildmuseet 01.jpg'),
    ('vasterbottens-museum', 'umea', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Вестерботтена', 'Vasterbottens Museum', 'Вестерботтен музейі', 63.83320000, 20.30390000, 'Vasterbottens Museum Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Västerbottens museum.jpg'),
    ('vaven-cultural-centre', 'umea', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Культурный центр Вэвен', 'Vaven Cultural Centre', 'Вэвен мәдени орталығы', 63.82470000, 20.26360000, 'Vaven Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Väven Umeå.jpg'),
    ('umedalen-sculpture-park', 'umea', 'PARK', 2, 'HOURS', 4.6, 'Парк скульптур Умедален', 'Umedalen Sculpture Park', 'Умедален мүсін паркі', 63.82720000, 20.19120000, 'Umedalen Sculpture Park Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Eye benches II.jpg'),
    ('guitars-the-museum', 'umea', 'MUSEUM', 1, 'HOURS', 4.5, 'Guitars - The Museum', 'Guitars - The Museum', 'Guitars - The Museum', 63.82580000, 20.26810000, 'Guitars The Museum Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Guitars - The Museum.jpg'),
    ('avion-shopping', 'umea', 'SHOPPING', 2, 'HOURS', 4.4, 'Avion Shopping', 'Avion Shopping', 'Avion Shopping', 63.80760000, 20.25360000, 'Avion Shopping Umea', ARRAY['umea']::text[], ARRAY['umea']::text[], 'Bildmuseet 01.jpg'),

    ('visby-city-wall', 'visby', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Городская стена Висбю', 'Visby City Wall', 'Висбю қала қабырғасы', 57.64190000, 18.29600000, 'Visby City Wall', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby city wall.jpg'),
    ('hanseatic-town-of-visby', 'visby', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Ганзейский город Висбю', 'Hanseatic Town of Visby', 'Висбю ганза қаласы', 57.64090000, 18.29690000, 'Hanseatic Town of Visby', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby City Wall and the cathedral, Gotland.jpg'),
    ('gotlands-museum', 'visby', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Готланда', 'Gotlands Museum Fornsalen', 'Готланд музейі', 57.63950000, 18.29560000, 'Gotlands Museum Visby', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby city wall.jpg'),
    ('dbw-botanical-garden', 'visby', 'PARK', 1, 'HOURS', 4.6, 'Ботанический сад DBW', 'DBW Botanical Garden', 'DBW ботаникалық бағы', 57.64490000, 18.29250000, 'DBW Botanical Garden Visby', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby city wall.jpg'),
    ('lummelunda-cave', 'visby', 'NATURE', 2, 'HOURS', 4.6, 'Пещера Луммелунда', 'Lummelunda Cave', 'Луммелунда үңгірі', 57.76470000, 18.40780000, 'Lummelunda Cave Gotland', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby city wall.jpg'),
    ('tofta-beach', 'visby', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Тофта', 'Tofta Beach', 'Тофта жағажайы', 57.48980000, 18.13180000, 'Tofta Beach Gotland', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Tofta beach Gotland.jpg'),
    ('kneippbyn-summer-water-park', 'visby', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Kneippbyn Summer and Water Park', 'Kneippbyn Summer and Water Park', 'Kneippbyn Summer and Water Park', 57.61040000, 18.24030000, 'Kneippbyn Visby', ARRAY['visby']::text[], ARRAY['visby']::text[], 'Visby city wall.jpg'),

    ('kalmar-castle', 'kalmar', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Кальмарский замок', 'Kalmar Castle', 'Кальмар қамалы', 56.66060000, 16.35660000, 'Kalmar Castle', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),
    ('kalmar-old-town', 'kalmar', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый город Кальмара', 'Kalmar Old Town', 'Кальмар ескі қаласы', 56.66200000, 16.35900000, 'Kalmar Old Town', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),
    ('kalmar-county-museum', 'kalmar', 'MUSEUM', 2, 'HOURS', 4.6, 'Краеведческий музей Кальмара', 'Kalmar County Museum', 'Кальмар өлкелік музейі', 56.66370000, 16.36690000, 'Kalmar County Museum', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),
    ('kalmar-city-park', 'kalmar', 'PARK', 1, 'HOURS', 4.5, 'Городской парк Кальмара', 'Kalmar City Park', 'Кальмар қалалық паркі', 56.66170000, 16.35580000, 'Kalmar City Park', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),
    ('kattrumpan-beach', 'kalmar', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Каттрумпан', 'Kattrumpan Beach', 'Каттрумпан жағажайы', 56.66600000, 16.37060000, 'Kattrumpan Beach Kalmar', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),
    ('a-world-of-dinosaurs', 'kalmar', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'A World of Dinosaurs', 'A World of Dinosaurs', 'A World of Dinosaurs', 56.66790000, 16.32290000, 'A World of Dinosaurs Kalmar', ARRAY['kalmar']::text[], ARRAY['kalmar']::text[], 'KalmarCastle.JPG'),

    ('vaxjo-cathedral', 'vaxjo', 'TEMPLE', 1, 'HOURS', 4.6, 'Кафедральный собор Векшё', 'Vaxjo Cathedral', 'Векшё соборы', 56.87770000, 14.80970000, 'Vaxjo Cathedral', ARRAY['vaxjo']::text[], ARRAY['vaxjo']::text[], 'Växjö Cathedral.jpg'),
    ('smaland-museum', 'vaxjo', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Смоланда', 'Smaland Museum', 'Смоланд музейі', 56.87700000, 14.80520000, 'Smaland Museum Vaxjo', ARRAY['vaxjo']::text[], ARRAY['vaxjo']::text[], 'Växjö Cathedral.jpg'),
    ('swedish-glass-museum', 'vaxjo', 'MUSEUM', 2, 'HOURS', 4.5, 'Шведский музей стекла', 'Swedish Glass Museum', 'Швед шыны музейі', 56.87700000, 14.80540000, 'Swedish Glass Museum Vaxjo', ARRAY['vaxjo']::text[], ARRAY['vaxjo']::text[], 'Växjö Cathedral.jpg'),
    ('teleborg-castle', 'vaxjo', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Телеборг', 'Teleborg Castle', 'Телеборг қамалы', 56.85400000, 14.82970000, 'Teleborg Castle Vaxjo', ARRAY['vaxjo']::text[], ARRAY['vaxjo']::text[], 'Teleborgs slott, Växjö, 2015d.jpg'),
    ('grand-samarkand', 'vaxjo', 'SHOPPING', 2, 'HOURS', 4.4, 'Grand Samarkand', 'Grand Samarkand', 'Grand Samarkand', 56.88260000, 14.76310000, 'Grand Samarkand Vaxjo', ARRAY['vaxjo']::text[], ARRAY['vaxjo']::text[], 'Växjö Cathedral.jpg'),

    ('naval-port-of-karlskrona', 'karlskrona', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Военно-морской порт Карлскруны', 'Naval Port of Karlskrona', 'Карлскруна әскери-теңіз порты', 56.16120000, 15.58690000, 'Naval Port of Karlskrona', ARRAY['karlskrona']::text[], ARRAY['karlskrona']::text[], 'Marinmuseum, Karlskrona.jpg'),
    ('naval-museum-karlskrona', 'karlskrona', 'MUSEUM', 2, 'HOURS', 4.7, 'Военно-морской музей Карлскруны', 'Karlskrona Naval Museum', 'Карлскруна теңіз музейі', 56.16170000, 15.59520000, 'Marinmuseum Karlskrona', ARRAY['karlskrona']::text[], ARRAY['karlskrona']::text[], 'Marinmuseum, Karlskrona.jpg'),
    ('drottningskar-citadel', 'karlskrona', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Цитадель Дроттнингшер', 'Drottningskar Citadel', 'Дроттнингшер цитаделі', 56.11030000, 15.58600000, 'Drottningskar Citadel Karlskrona', ARRAY['karlskrona']::text[], ARRAY['karlskrona']::text[], 'Marinmuseum Karlskrona.jpg'),
    ('wamoparken', 'karlskrona', 'PARK', 2, 'HOURS', 4.5, 'Парк Вемо', 'Wamoparken', 'Вемо паркі', 56.18470000, 15.60700000, 'Wamoparken Karlskrona', ARRAY['karlskrona']::text[], ARRAY['karlskrona']::text[], 'Marinmuseum, Karlskrona.jpg'),
    ('salto-dragso-beaches', 'karlskrona', 'BEACH', 3, 'HOURS', 4.5, 'Пляжи Сальтё и Драгсё', 'Salto and Dragso Beaches', 'Сальтё және Драгсё жағажайлары', 56.16500000, 15.55800000, 'Salto Dragso Karlskrona', ARRAY['karlskrona']::text[], ARRAY['karlskrona']::text[], 'Marinmuseum, Karlskrona.jpg'),

    ('southern-oland-agricultural-landscape', 'oland', 'NATURE', 4, 'HOURS', 4.8, 'Сельскохозяйственный ландшафт южного Эланда', 'Southern Oland Agricultural Landscape', 'Оңтүстік Эланд ауылшаруашылық ландшафты', 56.30000000, 16.45000000, 'Southern Oland Agricultural Landscape', ARRAY['oland']::text[], ARRAY['kalmar', 'oland']::text[], 'Stora Alvaret, Öland 01.jpg'),
    ('stora-alvaret', 'oland', 'NATURE', 3, 'HOURS', 4.7, 'Стура Альварет', 'Stora Alvaret', 'Стура Альварет', 56.50000000, 16.50000000, 'Stora Alvaret Oland', ARRAY['oland']::text[], ARRAY['kalmar', 'oland']::text[], 'Stora Alvaret, Öland 01.jpg'),
    ('borgholm-castle', 'oland', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Боргхольм', 'Borgholm Castle', 'Боргхольм қамалы', 56.87690000, 16.65120000, 'Borgholm Castle Oland', ARRAY['oland']::text[], ARRAY['kalmar', 'oland']::text[], 'Borgholm Castle.JPG'),
    ('solliden-palace-gardens', 'oland', 'PARK', 2, 'HOURS', 4.6, 'Сады дворца Соллиден', 'Solliden Palace Gardens', 'Соллиден сарай бақтары', 56.87900000, 16.65390000, 'Solliden Palace Oland', ARRAY['oland']::text[], ARRAY['oland']::text[], 'Borgholm Castle.JPG'),
    ('eketorp-castle', 'oland', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Крепость Экеторп', 'Eketorp Castle', 'Экеторп қамалы', 56.33820000, 16.48670000, 'Eketorp Castle Oland', ARRAY['oland']::text[], ARRAY['oland']::text[], 'Eketorp Oland.jpg'),
    ('boda-sand', 'oland', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Бёда Санд', 'Boda Sand', 'Бёда Санд жағажайы', 57.23500000, 17.05500000, 'Boda Sand Oland', ARRAY['oland']::text[], ARRAY['oland']::text[], 'Boda Sand Öland.jpg'),

    ('orebro-castle', 'orebro', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Эребру', 'Orebro Castle', 'Эребру қамалы', 59.27410000, 15.21340000, 'Orebro Castle', ARRAY['orebro']::text[], ARRAY['stockholm', 'orebro']::text[], 'Örebro slott.jpg'),
    ('wadkoping-open-air-museum', 'orebro', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей под открытым небом Вадчёпинг', 'Wadkoping Open-Air Museum', 'Вадчёпинг ашық аспан музейі', 59.27650000, 15.23140000, 'Wadkoping Orebro', ARRAY['orebro']::text[], ARRAY['orebro']::text[], 'Wadköping Örebro.jpg'),
    ('stadsparken-orebro', 'orebro', 'PARK', 1, 'HOURS', 4.5, 'Городской парк Эребру', 'Stadsparken Orebro', 'Эребру қалалық паркі', 59.27600000, 15.22500000, 'Stadsparken Orebro', ARRAY['orebro']::text[], ARRAY['orebro']::text[], 'Örebro slott.jpg'),

    ('linkoping-cathedral', 'linkoping', 'TEMPLE', 1, 'HOURS', 4.6, 'Линчёпингский собор', 'Linkoping Cathedral', 'Линчёпинг соборы', 58.41120000, 15.61690000, 'Linkoping Cathedral', ARRAY['linkoping']::text[], ARRAY['linkoping']::text[], 'Linköping Cathedral.jpg'),
    ('gamla-linkoping', 'linkoping', 'MUSEUM', 2, 'HOURS', 4.6, 'Старый Линчёпинг', 'Gamla Linkoping Open-Air Museum', 'Ескі Линчёпинг ашық музейі', 58.40630000, 15.58910000, 'Gamla Linkoping', ARRAY['linkoping']::text[], ARRAY['linkoping']::text[], 'Gamla Linköping 2012.jpg'),
    ('air-force-museum-linkoping', 'linkoping', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей ВВС Швеции', 'Swedish Air Force Museum', 'Швеция әуе күштері музейі', 58.40980000, 15.52500000, 'Swedish Air Force Museum Linkoping', ARRAY['linkoping']::text[], ARRAY['linkoping']::text[], 'Flygvapenmuseum Linköping.jpg'),

    ('norrkoping-industrial-landscape', 'norrkoping', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Индустриальный ландшафт Норрчёпинга', 'Norrkoping Industrial Landscape', 'Норрчёпинг өндірістік ландшафты', 58.59000000, 16.18200000, 'Norrkoping Industrial Landscape', ARRAY['norrkoping']::text[], ARRAY['norrkoping']::text[], 'Norrköping Industrial Landscape.jpg'),
    ('arbetets-museum', 'norrkoping', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей труда', 'Arbetets Museum', 'Еңбек музейі', 58.59050000, 16.17920000, 'Arbetets Museum Norrkoping', ARRAY['norrkoping']::text[], ARRAY['norrkoping']::text[], 'Arbetets museum Norrköping.jpg'),
    ('kolmarden-wildlife-park', 'norrkoping', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Парк дикой природы Кольморден', 'Kolmarden Wildlife Park', 'Кольморден жабайы табиғат паркі', 58.66580000, 16.46630000, 'Kolmarden Wildlife Park', ARRAY['norrkoping']::text[], ARRAY['norrkoping']::text[], 'Kolmården zoo entrance.jpg'),

    ('vasteras-cathedral', 'vasteras', 'TEMPLE', 1, 'HOURS', 4.6, 'Вестеросский собор', 'Vasteras Cathedral', 'Вестерос соборы', 59.61190000, 16.54080000, 'Vasteras Cathedral', ARRAY['vasteras']::text[], ARRAY['vasteras']::text[], 'Västerås Cathedral.jpg'),
    ('anundshog', 'vasteras', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Анундсхёг', 'Anundshog', 'Анундсхёг', 59.63170000, 16.64470000, 'Anundshog Vasteras', ARRAY['vasteras']::text[], ARRAY['vasteras']::text[], 'Anundshög 2012.jpg'),
    ('kokpunkten-actionbad', 'vasteras', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Аквапарк Кокпунктен', 'Kokpunkten Actionbad', 'Кокпунктен аквапаркі', 59.60270000, 16.55780000, 'Kokpunkten Vasteras', ARRAY['vasteras']::text[], ARRAY['vasteras']::text[], 'Västerås Cathedral.jpg'),

    ('jonkoping-matchstick-museum', 'jonkoping', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей спичек Йёнчёпинга', 'Jonkoping Matchstick Museum', 'Йёнчёпинг сіріңке музейі', 57.78260000, 14.15890000, 'Matchstick Museum Jonkoping', ARRAY['jonkoping']::text[], ARRAY['jonkoping']::text[], 'Jönköping from Lake Vättern.jpg'),
    ('jonkoping-city-park', 'jonkoping', 'PARK', 2, 'HOURS', 4.5, 'Городской парк Йёнчёпинга', 'Jonkoping City Park', 'Йёнчёпинг қалалық паркі', 57.78150000, 14.13950000, 'Jonkoping City Park', ARRAY['jonkoping']::text[], ARRAY['jonkoping']::text[], 'Jönköping from Lake Vättern.jpg'),
    ('vattern-beach-jonkoping', 'jonkoping', 'BEACH', 2, 'HOURS', 4.5, 'Пляж озера Веттерн', 'Lake Vattern Beach Jonkoping', 'Веттерн көлі жағажайы', 57.78300000, 14.17000000, 'Lake Vattern Beach Jonkoping', ARRAY['jonkoping']::text[], ARRAY['jonkoping']::text[], 'Jönköping from Lake Vättern.jpg'),

    ('falun-copper-mine', 'falun', 'MUSEUM', 3, 'HOURS', 4.8, 'Медный рудник Фалуна', 'Falun Copper Mine', 'Фалун мыс кеніші', 60.60040000, 15.60420000, 'Falun Copper Mine', ARRAY['falun']::text[], ARRAY['falun']::text[], 'Falun mine 2015.jpg'),
    ('dalarna-museum-falun', 'falun', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Даларны', 'Dalarna Museum Falun', 'Даларна музейі', 60.60620000, 15.63240000, 'Dalarna Museum Falun', ARRAY['falun']::text[], ARRAY['falun']::text[], 'Falun mine 2015.jpg'),
    ('lugnet-falun', 'falun', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Лугнет Фалун', 'Lugnet Falun', 'Лугнет Фалун', 60.61740000, 15.65730000, 'Lugnet Falun', ARRAY['falun']::text[], ARRAY['falun']::text[], 'Falun mine 2015.jpg'),

    ('zorn-museum', 'mora', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Цорна', 'Zorn Museum', 'Цорн музейі', 61.00790000, 14.54340000, 'Zorn Museum Mora', ARRAY['mora']::text[], ARRAY['mora']::text[], 'Zornmuseet Mora.jpg'),
    ('vasa-ski-museum', 'mora', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей Васалоппета', 'Vasa Ski Museum', 'Васа шаңғы музейі', 61.00700000, 14.53970000, 'Vasaloppet Museum Mora', ARRAY['mora']::text[], ARRAY['mora']::text[], 'Vasaloppet Mora.jpg'),
    ('lake-siljan-mora', 'mora', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Сильян', 'Lake Siljan Mora', 'Сильян көлі', 60.95000000, 14.70000000, 'Lake Siljan Mora', ARRAY['mora']::text[], ARRAY['mora']::text[], 'Lake Siljan.jpg'),

    ('are-ski-resort', 'are', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Горнолыжный курорт Оре', 'Are Ski Resort', 'Оре тау шаңғы курорты', 63.39860000, 13.08160000, 'Are Ski Resort Sweden', ARRAY['are']::text[], ARRAY['ostersund', 'are']::text[], 'Åre ski resort.jpg'),
    ('areskutan', 'are', 'NATURE', 4, 'HOURS', 4.8, 'Гора Орескутан', 'Areskutan Mountain', 'Орескутан тауы', 63.43140000, 13.09060000, 'Areskutan Are', ARRAY['are']::text[], ARRAY['are']::text[], 'Åreskutan from Fröåvägen.jpg'),
    ('tannforsen-waterfall', 'are', 'NATURE', 2, 'HOURS', 4.7, 'Водопад Тэннфорсен', 'Tannforsen Waterfall', 'Тэннфорсен сарқырамасы', 63.44330000, 12.74080000, 'Tannforsen Waterfall Are', ARRAY['are']::text[], ARRAY['are', 'ostersund']::text[], 'Tännforsen waterfall.jpg'),

    ('jamtli-museum', 'ostersund', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей Jamtli', 'Jamtli Museum', 'Jamtli музейі', 63.18890000, 14.63530000, 'Jamtli Museum Ostersund', ARRAY['ostersund']::text[], ARRAY['ostersund']::text[], 'Jamtli Östersund.jpg'),
    ('ostersund-city-centre', 'ostersund', 'SHOPPING', 1, 'HOURS', 4.4, 'Центр Эстерсунда', 'Ostersund City Centre', 'Эстерсунд орталығы', 63.17920000, 14.63570000, 'Ostersund City Centre', ARRAY['ostersund']::text[], ARRAY['ostersund']::text[], 'Östersund city.jpg'),
    ('lake-storsjon', 'ostersund', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Стуршён', 'Lake Storsjon', 'Стуршён көлі', 63.18300000, 14.60000000, 'Lake Storsjon Ostersund', ARRAY['ostersund']::text[], ARRAY['ostersund']::text[], 'Storsjön Östersund.jpg');

CREATE TEMP TABLE seed_sweden_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-sweden-attraction:' || seed.slug) AS attraction_hash,
        md5('id-sweden-media:' || seed.slug) AS media_hash
    FROM seed_sweden_priority_attractions seed
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
    ARRAY['sweden', city_id, slug, lower(category), 'sweden-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Швеции: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Sweden tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Швеция туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'SE',
    city_id,
    category,
    'ru',
    'IMPORT',
    'PUBLISHED',
    duration_value,
    duration_unit,
    'SEK',
    rating,
    tags,
    NOW(),
    NOW()
FROM seed_sweden_resolved_attractions
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
FROM seed_sweden_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_sweden_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_sweden_resolved_attractions
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
FROM seed_sweden_resolved_attractions seed
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
FROM seed_sweden_resolved_attractions
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
    'SE',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_sweden_resolved_attractions
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
    'SE',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_sweden_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
