-- Priority Portugal destination attractions seed.
-- The seed keeps tourist hubs explicit for admin filters and localized mobile discovery.

DROP TABLE IF EXISTS seed_portugal_resolved_attractions;
DROP TABLE IF EXISTS seed_portugal_priority_attractions;

CREATE TEMP TABLE seed_portugal_priority_attractions (
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

INSERT INTO seed_portugal_priority_attractions (
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
    ('jeronimos-monastery', 'lisbon', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Монастырь Жеронимуш', 'Jeronimos Monastery', 'Жеронимуш монастыры', 38.69790000, -9.20650000, 'Jeronimos Monastery Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('belem-tower', 'lisbon', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Башня Белен', 'Belem Tower', 'Белен мұнарасы', 38.69160000, -9.21600000, 'Belem Tower Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('sao-jorge-castle', 'lisbon', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Святого Георгия', 'Sao Jorge Castle', 'Сан-Жорже қамалы', 38.71390000, -9.13350000, 'Sao Jorge Castle Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('praca-do-comercio', 'lisbon', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Площадь Коммерции', 'Praca do Comercio', 'Коммерция алаңы', 38.70770000, -9.13660000, 'Praca do Comercio Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('oceanario-lisboa', 'lisbon', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Лиссабонский океанариум', 'Oceanario de Lisboa', 'Лиссабон океанариумы', 38.76360000, -9.09590000, 'Oceanario de Lisboa Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('maat-lisbon', 'lisbon', 'MUSEUM', 2, 'HOURS', 4.6, 'МААТ', 'MAAT', 'MAAT', 38.69580000, -9.19470000, 'MAAT Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('national-tile-museum', 'lisbon', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей азулежу', 'National Tile Museum', 'Ұлттық азулежу музейі', 38.72420000, -9.11380000, 'National Tile Museum Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('gulbenkian-museum', 'lisbon', 'MUSEUM', 2, 'HOURS', 4.8, 'Музей Калушта Гюльбенкяна', 'Calouste Gulbenkian Museum', 'Калуст Гюльбенкян музейі', 38.73760000, -9.15460000, 'Calouste Gulbenkian Museum Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('time-out-market-lisboa', 'lisbon', 'FOOD', 2, 'HOURS', 4.7, 'Time Out Market Lisboa', 'Time Out Market Lisboa', 'Time Out Market Lisboa', 38.70680000, -9.14550000, 'Time Out Market Lisboa Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('lx-factory', 'lisbon', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'LX Factory', 'LX Factory', 'LX Factory', 38.70330000, -9.17820000, 'LX Factory Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('colombo-shopping-center', 'lisbon', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Colombo', 'Colombo Shopping Center', 'Colombo сауда орталығы', 38.75390000, -9.18880000, 'Colombo Shopping Center Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('bairro-alto-nightlife', 'lisbon', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Вечерний Байрру-Алту', 'Bairro Alto Nightlife', 'Байрру-Алту кешкі ауданы', 38.71100000, -9.14470000, 'Bairro Alto Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),

    ('pena-palace', 'sintra', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Дворец Пена', 'Pena Palace', 'Пена сарайы', 38.78790000, -9.39040000, 'Pena Palace Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),
    ('moorish-castle-sintra', 'sintra', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок мавров', 'Moorish Castle', 'Маврлар қамалы', 38.79010000, -9.38930000, 'Moorish Castle Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),
    ('sintra-national-palace', 'sintra', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Национальный дворец Синтры', 'National Palace of Sintra', 'Синтра ұлттық сарайы', 38.79750000, -9.39060000, 'National Palace of Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),
    ('quinta-da-regaleira', 'sintra', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Кинта да Регалейра', 'Quinta da Regaleira', 'Кинта да Регалейра', 38.79640000, -9.39650000, 'Quinta da Regaleira Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),
    ('monserrate-palace-park', 'sintra', 'PARK', 2, 'HOURS', 4.7, 'Парк и дворец Монсеррат', 'Park and Palace of Monserrate', 'Монсеррат бағы мен сарайы', 38.79280000, -9.42060000, 'Monserrate Palace Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),
    ('cabo-da-roca', 'sintra', 'NATURE', 2, 'HOURS', 4.8, 'Мыс Рока', 'Cabo da Roca', 'Рока мүйісі', 38.78040000, -9.49890000, 'Cabo da Roca Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Praia_da_adraga_portugal.jpg'),
    ('praia-da-adraga', 'sintra', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Адрага', 'Praia da Adraga', 'Адрага жағажайы', 38.80320000, -9.48500000, 'Praia da Adraga Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Praia_da_adraga_portugal.jpg'),

    ('boca-do-inferno', 'cascais', 'NATURE', 1, 'HOURS', 4.6, 'Бока-ду-Инферну', 'Boca do Inferno', 'Бока-ду-Инферну', 38.69160000, -9.43170000, 'Boca do Inferno Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('praia-do-guincho', 'cascais', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Гиншу', 'Praia do Guincho', 'Гиншу жағажайы', 38.73080000, -9.47410000, 'Praia do Guincho Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('praia-de-carcavelos', 'cascais', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Каркавелуш', 'Praia de Carcavelos', 'Каркавелуш жағажайы', 38.67970000, -9.33520000, 'Praia de Carcavelos Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('paula-rego-house', 'cascais', 'MUSEUM', 2, 'HOURS', 4.5, 'Дом историй Паулы Регу', 'Paula Rego House of Stories', 'Паула Регу тарих үйі', 38.69480000, -9.42370000, 'Paula Rego House of Stories Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('cascais-marina', 'cascais', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Кашкайша', 'Cascais Marina', 'Кашкайш маринасы', 38.69270000, -9.42050000, 'Cascais Marina Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('cascaishopping', 'cascais', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ CascaiShopping', 'CascaiShopping', 'CascaiShopping', 38.74280000, -9.39720000, 'CascaiShopping Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),

    ('arrabida-natural-park', 'setubal', 'NATURE', 4, 'HOURS', 4.8, 'Природный парк Аррабида', 'Arrabida Natural Park', 'Аррабида табиғи паркі', 38.48200000, -8.98400000, 'Arrabida Natural Park Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('praia-de-galapinhos', 'setubal', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Галапиньюш', 'Praia de Galapinhos', 'Галапиньюш жағажайы', 38.48220000, -8.97090000, 'Praia de Galapinhos Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('praia-da-figueirinha', 'setubal', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Фигейринья', 'Praia da Figueirinha', 'Фигейринья жағажайы', 38.48470000, -8.93440000, 'Praia da Figueirinha Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('mercado-do-livramento', 'setubal', 'MARKET', 2, 'HOURS', 4.7, 'Рынок Ливраменту', 'Mercado do Livramento', 'Ливраменту базары', 38.52330000, -8.89370000, 'Mercado do Livramento Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('sao-filipe-fortress', 'setubal', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Крепость Сан-Филипе', 'Sao Filipe Fortress', 'Сан-Филипе қамалы', 38.51970000, -8.90980000, 'Sao Filipe Fortress Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('roman-ruins-troia', 'setubal', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Римские руины Трои', 'Roman Ruins of Troia', 'Троя рим қирандылары', 38.48600000, -8.88400000, 'Roman Ruins of Troia Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),

    ('ribeira-district', 'porto', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Район Рибейра', 'Ribeira District', 'Рибейра ауданы', 41.14090000, -8.61380000, 'Ribeira Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('dom-luis-i-bridge', 'porto', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Мост Дом-Луиш I', 'Dom Luis I Bridge', 'Дом Луиш I көпірі', 41.13990000, -8.60910000, 'Dom Luis I Bridge Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('sao-bento-station', 'porto', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Вокзал Сан-Бенту', 'Sao Bento Railway Station', 'Сан-Бенту вокзалы', 41.14560000, -8.61080000, 'Sao Bento Railway Station Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('livraria-lello', 'porto', 'SHOPPING', 1, 'HOURS', 4.7, 'Книжный магазин Леллу', 'Livraria Lello', 'Леллу кітап дүкені', 41.14690000, -8.61480000, 'Livraria Lello Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('clerigos-tower', 'porto', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Башня Клеригуш', 'Clerigos Tower', 'Клеригуш мұнарасы', 41.14570000, -8.61470000, 'Clerigos Tower Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('palacio-da-bolsa', 'porto', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Биржи', 'Palacio da Bolsa', 'Биржа сарайы', 41.14120000, -8.61570000, 'Palacio da Bolsa Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('mercado-do-bolhao', 'porto', 'MARKET', 2, 'HOURS', 4.7, 'Рынок Больян', 'Mercado do Bolhao', 'Больян базары', 41.14910000, -8.60700000, 'Mercado do Bolhao Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('serralves-museum-park', 'porto', 'MUSEUM', 3, 'HOURS', 4.7, 'Музей и парк Серралвеш', 'Serralves Museum and Park', 'Серралвеш музейі мен паркі', 41.15980000, -8.65990000, 'Serralves Museum Park Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('casa-da-musica', 'porto', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Дом музыки', 'Casa da Musica', 'Музыка үйі', 41.15900000, -8.63070000, 'Casa da Musica Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('porto-city-park', 'porto', 'PARK', 2, 'HOURS', 4.6, 'Городской парк Порту', 'Porto City Park', 'Порту қалалық саябағы', 41.16840000, -8.68920000, 'Porto City Park Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),

    ('wow-world-of-wine', 'vila-nova-de-gaia', 'MUSEUM', 3, 'HOURS', 4.6, 'WOW - Мир вина', 'WOW - World of Wine', 'WOW - Шарап әлемі', 41.13380000, -8.61380000, 'WOW World of Wine Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('port-wine-lodges', 'vila-nova-de-gaia', 'FOOD', 2, 'HOURS', 4.7, 'Погреба портвейна', 'Port Wine Lodges', 'Портвейн жертөлелері', 41.13700000, -8.61300000, 'Port Wine Lodges Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('jardim-do-morro', 'vila-nova-de-gaia', 'PARK', 1, 'HOURS', 4.7, 'Сад Морру', 'Jardim do Morro', 'Морру бағы', 41.13820000, -8.60940000, 'Jardim do Morro Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('serra-do-pilar-monastery', 'vila-nova-de-gaia', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Серра-ду-Пилар', 'Monastery of Serra do Pilar', 'Серра-ду-Пилар монастыры', 41.13840000, -8.60810000, 'Monastery of Serra do Pilar Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('arrabidashopping', 'vila-nova-de-gaia', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ ArrabidaShopping', 'ArrabidaShopping', 'ArrabidaShopping', 41.14450000, -8.64070000, 'ArrabidaShopping Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),

    ('bom-jesus-do-monte', 'braga', 'TEMPLE', 2, 'HOURS', 4.9, 'Бон-Жезуш-ду-Монте', 'Bom Jesus do Monte', 'Бон-Жезуш-ду-Монте', 41.55470000, -8.37760000, 'Bom Jesus do Monte Braga Portugal', ARRAY['braga']::text[], ARRAY['braga', 'porto']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('braga-cathedral', 'braga', 'TEMPLE', 1, 'HOURS', 4.7, 'Кафедральный собор Браги', 'Braga Cathedral', 'Брага кафедралды соборы', 41.55090000, -8.42750000, 'Braga Cathedral Portugal', ARRAY['braga']::text[], ARRAY['braga', 'porto']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('biscainhos-palace-museum', 'braga', 'MUSEUM', 2, 'HOURS', 4.5, 'Дворец-музей Бискаиньюш', 'Biscainhos Palace Museum', 'Бискаиньюш сарай-музейі', 41.55220000, -8.43060000, 'Biscainhos Palace Museum Braga Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('theatro-circo', 'braga', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Театр Сирку', 'Theatro Circo', 'Сирку театры', 41.55040000, -8.42170000, 'Theatro Circo Braga Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('braga-parque', 'braga', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Braga Parque', 'Braga Parque', 'Braga Parque', 41.56060000, -8.40780000, 'Braga Parque Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),

    ('guimaraes-historic-centre', 'guimaraes', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Гимарайнша', 'Historic Centre of Guimaraes', 'Гимарайнш тарихи орталығы', 41.44360000, -8.29200000, 'Historic Centre of Guimaraes Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes', 'porto']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('guimaraes-castle', 'guimaraes', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Замок Гимарайнша', 'Guimaraes Castle', 'Гимарайнш қамалы', 41.44700000, -8.29070000, 'Guimaraes Castle Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes', 'porto']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('dukes-palace-guimaraes', 'guimaraes', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец герцогов Браганса', 'Palace of the Dukes of Braganza', 'Браганса герцогтары сарайы', 41.44680000, -8.29130000, 'Palace of the Dukes of Braganza Guimaraes Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes', 'porto']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('penha-mountain-park', 'guimaraes', 'NATURE', 3, 'HOURS', 4.6, 'Гора и парк Пенья', 'Penha Mountain and Park', 'Пенья тауы мен саябағы', 41.43060000, -8.26590000, 'Penha Mountain Guimaraes Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes']::text[], 'Guimaraes_castle_exterior.jpg'),

    ('santa-luzia-sanctuary', 'viana-do-castelo', 'TEMPLE', 2, 'HOURS', 4.8, 'Святилище Санта-Лузия', 'Sanctuary of Santa Luzia', 'Санта-Лузия ғибадатханасы', 41.70150000, -8.83400000, 'Sanctuary of Santa Luzia Viana do Castelo Portugal', ARRAY['viana-do-castelo']::text[], ARRAY['viana-do-castelo', 'porto']::text[], 'Monte_de_Santa_Luzia_sanctuary_in_Viana_do_Castelo_12.jpg'),
    ('gil-eannes-museum-ship', 'viana-do-castelo', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей-корабль Жил Эанеш', 'Gil Eannes Museum Ship', 'Жил Эанеш музей-кемесі', 41.69020000, -8.82960000, 'Gil Eannes Museum Ship Viana do Castelo Portugal', ARRAY['viana-do-castelo']::text[], ARRAY['viana-do-castelo']::text[], 'Monte_de_Santa_Luzia_sanctuary_in_Viana_do_Castelo_12.jpg'),
    ('cabedelo-beach', 'viana-do-castelo', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Кабеделу', 'Cabedelo Beach', 'Кабеделу жағажайы', 41.68060000, -8.82780000, 'Cabedelo Beach Viana do Castelo Portugal', ARRAY['viana-do-castelo']::text[], ARRAY['viana-do-castelo']::text[], 'Monte_de_Santa_Luzia_sanctuary_in_Viana_do_Castelo_12.jpg'),
    ('viana-ecological-park', 'viana-do-castelo', 'PARK', 2, 'HOURS', 4.4, 'Городской экологический парк', 'Urban Ecological Park', 'Қалалық экологиялық парк', 41.69700000, -8.81380000, 'Urban Ecological Park Viana do Castelo Portugal', ARRAY['viana-do-castelo']::text[], ARRAY['viana-do-castelo']::text[], 'Monte_de_Santa_Luzia_sanctuary_in_Viana_do_Castelo_12.jpg'),

    ('douro-museum', 'douro-valley', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Дору', 'Douro Museum', 'Дору музейі', 41.16240000, -7.79120000, 'Douro Museum Peso da Regua Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley', 'porto']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('douro-river-cruises', 'douro-valley', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Круизы по реке Дору', 'Douro River Cruises', 'Дору өзені круиздері', 41.15880000, -7.78990000, 'Douro River Cruises Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley', 'porto']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('sao-leonardo-galafura-viewpoint', 'douro-valley', 'NATURE', 2, 'HOURS', 4.8, 'Смотровая Сан-Леонарду-да-Галафура', 'Sao Leonardo da Galafura Viewpoint', 'Сан-Леонарду-да-Галафура көрінісі', 41.17270000, -7.67210000, 'Sao Leonardo da Galafura viewpoint Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('douro-wine-estates', 'douro-valley', 'FOOD', 3, 'HOURS', 4.7, 'Винные усадьбы Дору', 'Douro Wine Estates', 'Дору шарап үйлері', 41.17000000, -7.68000000, 'Douro Valley wine estates Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley', 'porto']::text[], 'The_Douro_Valley_vineyards.jpg'),

    ('university-of-coimbra', 'coimbra', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Университет Коимбры', 'University of Coimbra', 'Коимбра университеті', 40.20760000, -8.42650000, 'University of Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('joanina-library', 'coimbra', 'MUSEUM', 1, 'HOURS', 4.8, 'Библиотека Жуанина', 'Joanina Library', 'Жуанина кітапханасы', 40.20760000, -8.42650000, 'Joanina Library Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('machado-castro-museum', 'coimbra', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей Машаду де Каштру', 'Machado de Castro National Museum', 'Машаду де Каштру ұлттық музейі', 40.20900000, -8.42600000, 'Machado de Castro National Museum Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('portugal-dos-pequenitos', 'coimbra', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Португалия в миниатюре', 'Portugal dos Pequenitos', 'Кішкентайлар Португалиясы', 40.20300000, -8.43450000, 'Portugal dos Pequenitos Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('quinta-das-lagrimas-gardens', 'coimbra', 'PARK', 2, 'HOURS', 4.5, 'Сады Кинта-даш-Лагримаш', 'Quinta das Lagrimas Gardens', 'Кинта-даш-Лагримаш бақтары', 40.19880000, -8.43590000, 'Quinta das Lagrimas Gardens Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),

    ('aveiro-canals-moliceiro', 'aveiro', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Каналы Авейру и лодки молисейру', 'Aveiro Canals and Moliceiro Boats', 'Авейру арналары мен молисейру қайықтары', 40.64120000, -8.65360000, 'Aveiro canals moliceiro boats Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('aveiro-museum-santa-joana', 'aveiro', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Авейру Санта-Жоана', 'Aveiro Museum Santa Joana', 'Авейру Санта-Жоана музейі', 40.63890000, -8.65070000, 'Aveiro Museum Santa Joana Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('forum-aveiro', 'aveiro', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Forum Aveiro', 'Forum Aveiro', 'Forum Aveiro', 40.64160000, -8.65300000, 'Forum Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('costa-nova-beach', 'aveiro', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Кошта-Нова', 'Costa Nova Beach', 'Кошта-Нова жағажайы', 40.61390000, -8.75160000, 'Costa Nova Beach Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('aveiro-salt-pans', 'aveiro', 'NATURE', 2, 'HOURS', 4.4, 'Соляные лагуны Авейру', 'Aveiro Salt Pans', 'Авейру тұз алаңдары', 40.64500000, -8.65700000, 'Aveiro salt pans Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),

    ('praia-do-norte-nazare', 'nazare', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Прая-ду-Норте', 'Praia da Nazare', 'Назаре жағажайы', 39.60940000, -9.08460000, 'Praia do Norte Nazare Portugal', ARRAY['nazare']::text[], ARRAY['nazare']::text[], 'Nazaré_February_2013-15.jpg'),
    ('nazare-beach', 'nazare', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Назаре', 'Nazare Beach', 'Назаре жағажайы', 39.60140000, -9.07320000, 'Nazare Beach Portugal', ARRAY['nazare']::text[], ARRAY['nazare']::text[], 'Nazaré_February_2013-15.jpg'),
    ('fort-sao-miguel-arcanjo', 'nazare', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Форт Святого Михаила Архангела', 'Fort of Sao Miguel Arcanjo', 'Сан-Мигел Арканжу форты', 39.60460000, -9.08580000, 'Fort of Sao Miguel Arcanjo Nazare Portugal', ARRAY['nazare']::text[], ARRAY['nazare']::text[], 'Nazaré_February_2013-15.jpg'),
    ('nazare-sanctuary', 'nazare', 'TEMPLE', 1, 'HOURS', 4.6, 'Святилище Богоматери Назаре', 'Sanctuary of Our Lady of Nazare', 'Назаре Құдай Анасы ғибадатханасы', 39.60470000, -9.07690000, 'Sanctuary of Our Lady of Nazare Portugal', ARRAY['nazare']::text[], ARRAY['nazare']::text[], 'Nazaré_February_2013-15.jpg'),

    ('obidos-castle', 'obidos', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Обидуш', 'Obidos Castle', 'Обидуш қамалы', 39.36320000, -9.15760000, 'Obidos Castle Portugal', ARRAY['obidos']::text[], ARRAY['obidos', 'lisbon']::text[], 'Obidos_April_2009-4b.jpg'),
    ('obidos-walled-town', 'obidos', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Исторический город-крепость Обидуш', 'Walled Historic Town of Obidos', 'Обидуш қабырғалы тарихи қаласы', 39.36090000, -9.15790000, 'Obidos walled town Portugal', ARRAY['obidos']::text[], ARRAY['obidos', 'lisbon']::text[], 'Obidos_April_2009-4b.jpg'),
    ('obidos-lagoon', 'obidos', 'NATURE', 3, 'HOURS', 4.6, 'Лагуна Обидуш', 'Obidos Lagoon', 'Обидуш лагунасы', 39.41700000, -9.22200000, 'Obidos Lagoon Portugal', ARRAY['obidos']::text[], ARRAY['obidos', 'lisbon']::text[], 'Obidos_April_2009-4b.jpg'),
    ('obidos-biological-market', 'obidos', 'MARKET', 1, 'HOURS', 4.4, 'Биологический рынок Обидуш', 'Obidos Biological Market', 'Обидуш биологиялық базары', 39.36130000, -9.15720000, 'Obidos Biological Market Portugal', ARRAY['obidos']::text[], ARRAY['obidos']::text[], 'Obidos_April_2009-4b.jpg'),

    ('sanctuary-of-fatima', 'fatima', 'TEMPLE', 3, 'HOURS', 4.9, 'Святилище Фатимы', 'Sanctuary of Fatima', 'Фатима ғибадатханасы', 39.63210000, -8.67180000, 'Sanctuary of Fatima Portugal', ARRAY['fatima']::text[], ARRAY['fatima', 'lisbon']::text[], 'Portugal,_Fatima,_Sanctuary_of_Our_Lady_of_Fatima_(52593373732).jpg'),
    ('chapel-of-apparitions-fatima', 'fatima', 'TEMPLE', 1, 'HOURS', 4.8, 'Часовня Явлений', 'Chapel of the Apparitions', 'Көріністер капелласы', 39.63290000, -8.67170000, 'Chapel of the Apparitions Fatima Portugal', ARRAY['fatima']::text[], ARRAY['fatima']::text[], 'Portugal,_Fatima,_Sanctuary_of_Our_Lady_of_Fatima_(52593373732).jpg'),
    ('wax-museum-fatima', 'fatima', 'MUSEUM', 1, 'HOURS', 4.4, 'Музей восковых фигур Фатимы', 'Wax Museum of Fatima', 'Фатима балауыз музейі', 39.63090000, -8.67510000, 'Wax Museum Fatima Portugal', ARRAY['fatima']::text[], ARRAY['fatima']::text[], 'Portugal,_Fatima,_Sanctuary_of_Our_Lady_of_Fatima_(52593373732).jpg'),
    ('grutas-da-moeda', 'fatima', 'NATURE', 2, 'HOURS', 4.5, 'Пещеры Груташ-да-Моэда', 'Grutas da Moeda', 'Груташ-да-Моэда үңгірлері', 39.59830000, -8.71170000, 'Grutas da Moeda Fatima Portugal', ARRAY['fatima']::text[], ARRAY['fatima']::text[], 'Portugal,_Fatima,_Sanctuary_of_Our_Lady_of_Fatima_(52593373732).jpg'),

    ('roman-temple-evora', 'evora', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Римский храм Эворы', 'Roman Temple of Evora', 'Эвора рим храмы', 38.57260000, -7.90730000, 'Roman Temple of Evora Portugal', ARRAY['evora']::text[], ARRAY['evora', 'lisbon']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('chapel-of-bones-evora', 'evora', 'TEMPLE', 1, 'HOURS', 4.7, 'Капелла костей', 'Chapel of Bones', 'Сүйектер капелласы', 38.56890000, -7.90830000, 'Chapel of Bones Evora Portugal', ARRAY['evora']::text[], ARRAY['evora', 'lisbon']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('evora-cathedral', 'evora', 'TEMPLE', 1, 'HOURS', 4.6, 'Кафедральный собор Эворы', 'Evora Cathedral', 'Эвора кафедралды соборы', 38.57200000, -7.90770000, 'Evora Cathedral Portugal', ARRAY['evora']::text[], ARRAY['evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('freimanuel-cenaculo-museum', 'evora', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный музей Фрея Мануэла ду Сенакулу', 'Frei Manuel do Cenaculo National Museum', 'Фрей Мануэл ду Сенакулу ұлттық музейі', 38.57220000, -7.90710000, 'Frei Manuel do Cenaculo National Museum Evora Portugal', ARRAY['evora']::text[], ARRAY['evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('evora-municipal-market', 'evora', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок Эворы', 'Municipal Market of Evora', 'Эвора муниципалдық базары', 38.56830000, -7.90960000, 'Municipal Market of Evora Portugal', ARRAY['evora']::text[], ARRAY['evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),

    ('faro-cathedral', 'faro', 'TEMPLE', 1, 'HOURS', 4.6, 'Кафедральный собор Фару', 'Faro Cathedral', 'Фару кафедралды соборы', 37.01410000, -7.93540000, 'Faro Cathedral Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('arco-da-vila-faro', 'faro', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Арка да Вила', 'Arco da Vila', 'Арку да Вила', 37.01670000, -7.93530000, 'Arco da Vila Faro Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('faro-municipal-museum', 'faro', 'MUSEUM', 2, 'HOURS', 4.5, 'Муниципальный музей Фару', 'Faro Municipal Museum', 'Фару муниципалдық музейі', 37.01380000, -7.93430000, 'Faro Municipal Museum Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('ria-formosa-natural-park', 'faro', 'NATURE', 4, 'HOURS', 4.8, 'Природный парк Риа-Формоза', 'Ria Formosa Natural Park', 'Риа-Формоза табиғи паркі', 37.01930000, -7.93060000, 'Ria Formosa Natural Park Faro Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('forum-algarve', 'faro', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Forum Algarve', 'Forum Algarve', 'Forum Algarve', 37.02520000, -7.94820000, 'Forum Algarve Faro Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),

    ('praia-dos-pescadores-albufeira', 'albufeira', 'BEACH', 3, 'HOURS', 4.7, 'Пляж рыбаков', 'Praia dos Pescadores', 'Балықшылар жағажайы', 37.08720000, -8.25000000, 'Praia dos Pescadores Albufeira Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-da-falesia', 'albufeira', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Фалезия', 'Praia da Falesia', 'Фалезия жағажайы', 37.08890000, -8.16660000, 'Praia da Falesia Albufeira Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('albufeira-marina', 'albufeira', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Албуфейры', 'Albufeira Marina', 'Албуфейра маринасы', 37.08150000, -8.26500000, 'Albufeira Marina Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('zoomarine-algarve', 'albufeira', 'ENTERTAINMENT', 5, 'HOURS', 4.7, 'Zoomarine Algarve', 'Zoomarine Algarve', 'Zoomarine Algarve', 37.12750000, -8.31460000, 'Zoomarine Algarve Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('algarveshopping', 'albufeira', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ AlgarveShopping', 'AlgarveShopping', 'AlgarveShopping', 37.12960000, -8.28140000, 'AlgarveShopping Albufeira Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('benagil-cave', 'lagoa', 'NATURE', 3, 'HOURS', 4.9, 'Пещера Бенажил', 'Benagil Cave', 'Бенажил үңгірі', 37.08690000, -8.42680000, 'Benagil Cave Lagoa Algarve Portugal', ARRAY['lagoa']::text[], ARRAY['lagoa', 'albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-da-marinha', 'lagoa', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Маринья', 'Praia da Marinha', 'Маринья жағажайы', 37.08920000, -8.41280000, 'Praia da Marinha Lagoa Portugal', ARRAY['lagoa']::text[], ARRAY['lagoa', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('slide-splash', 'lagoa', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Аквапарк Slide and Splash', 'Slide and Splash', 'Slide and Splash аквапаркі', 37.13660000, -8.44970000, 'Slide and Splash Lagoa Portugal', ARRAY['lagoa']::text[], ARRAY['lagoa', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('ponta-da-piedade', 'lagos', 'NATURE', 3, 'HOURS', 4.9, 'Понта-да-Пьедаде', 'Ponta da Piedade', 'Понта-да-Пьедаде', 37.08070000, -8.66900000, 'Ponta da Piedade Lagos Portugal', ARRAY['lagos']::text[], ARRAY['lagos', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-dona-ana', 'lagos', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Дона-Ана', 'Praia de Dona Ana', 'Дона-Ана жағажайы', 37.09170000, -8.66900000, 'Praia de Dona Ana Lagos Portugal', ARRAY['lagos']::text[], ARRAY['lagos', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-do-camilo', 'lagos', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Камилу', 'Praia do Camilo', 'Камилу жағажайы', 37.08780000, -8.66860000, 'Praia do Camilo Lagos Portugal', ARRAY['lagos']::text[], ARRAY['lagos']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('lagos-marina', 'lagos', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Лагуша', 'Marina de Lagos', 'Лагуш маринасы', 37.10880000, -8.67250000, 'Marina de Lagos Portugal', ARRAY['lagos']::text[], ARRAY['lagos']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('lagos-municipal-museum', 'lagos', 'MUSEUM', 1, 'HOURS', 4.4, 'Муниципальный музей Жозе Формозинью', 'Dr. Jose Formosinho Municipal Museum', 'Жозе Формозинью муниципалдық музейі', 37.10100000, -8.67300000, 'Dr Jose Formosinho Municipal Museum Lagos Portugal', ARRAY['lagos']::text[], ARRAY['lagos']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('praia-da-rocha', 'portimao', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Роша', 'Praia da Rocha', 'Роша жағажайы', 37.11800000, -8.53700000, 'Praia da Rocha Portimao Portugal', ARRAY['portimao']::text[], ARRAY['portimao', 'faro']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('portimao-museum', 'portimao', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Портимана', 'Portimao Museum', 'Портиман музейі', 37.13120000, -8.53520000, 'Portimao Museum Portugal', ARRAY['portimao']::text[], ARRAY['portimao']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('portimao-marina', 'portimao', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Марина Портимана', 'Portimao Marina', 'Портиман маринасы', 37.11970000, -8.52850000, 'Portimao Marina Portugal', ARRAY['portimao']::text[], ARRAY['portimao']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('aqua-portimao', 'portimao', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Aqua Portimao', 'Aqua Portimao', 'Aqua Portimao', 37.14900000, -8.54870000, 'Aqua Portimao Portugal', ARRAY['portimao']::text[], ARRAY['portimao']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('portimao-municipal-market', 'portimao', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок Портимана', 'Portimao Municipal Market', 'Портиман муниципалдық базары', 37.13650000, -8.53780000, 'Portimao Municipal Market Portugal', ARRAY['portimao']::text[], ARRAY['portimao']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),

    ('tavira-island-beach', 'tavira', 'BEACH', 4, 'HOURS', 4.8, 'Пляж острова Тавира', 'Praia da Ilha de Tavira', 'Тавира аралы жағажайы', 37.08740000, -7.66380000, 'Praia da Ilha de Tavira Portugal', ARRAY['tavira']::text[], ARRAY['tavira', 'faro']::text[], 'FaroKesklinn.jpg'),
    ('tavira-castle', 'tavira', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Замок Тавиры', 'Tavira Castle', 'Тавира қамалы', 37.12670000, -7.65020000, 'Tavira Castle Portugal', ARRAY['tavira']::text[], ARRAY['tavira', 'faro']::text[], 'FaroKesklinn.jpg'),
    ('mercado-da-ribeira-tavira', 'tavira', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Рибейра', 'Mercado da Ribeira', 'Рибейра базары', 37.12460000, -7.64900000, 'Mercado da Ribeira Tavira Portugal', ARRAY['tavira']::text[], ARRAY['tavira']::text[], 'FaroKesklinn.jpg'),
    ('jardim-do-coreto-tavira', 'tavira', 'PARK', 1, 'HOURS', 4.4, 'Сад Корету', 'Jardim do Coreto', 'Корету бағы', 37.12500000, -7.64860000, 'Jardim do Coreto Tavira Portugal', ARRAY['tavira']::text[], ARRAY['tavira']::text[], 'FaroKesklinn.jpg'),

    ('sagres-fortress', 'sagres', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Сагреш', 'Sagres Fortress', 'Сагреш қамалы', 37.00080000, -8.94760000, 'Sagres Fortress Portugal', ARRAY['sagres']::text[], ARRAY['sagres', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('cape-st-vincent', 'sagres', 'NATURE', 2, 'HOURS', 4.8, 'Мыс Сан-Висенте', 'Cape St. Vincent', 'Сан-Висенте мүйісі', 37.02300000, -8.99690000, 'Cape St Vincent Portugal', ARRAY['sagres']::text[], ARRAY['sagres', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-do-beliche', 'sagres', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Белише', 'Praia do Beliche', 'Белише жағажайы', 37.02590000, -8.96340000, 'Praia do Beliche Sagres Portugal', ARRAY['sagres']::text[], ARRAY['sagres']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-da-mareta', 'sagres', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Марета', 'Praia da Mareta', 'Марета жағажайы', 37.00690000, -8.93720000, 'Praia da Mareta Sagres Portugal', ARRAY['sagres']::text[], ARRAY['sagres']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('vilamoura-marina', 'vilamoura', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Марина Виламоры', 'Vilamoura Marina', 'Виламора маринасы', 37.07770000, -8.11900000, 'Vilamoura Marina Portugal', ARRAY['vilamoura']::text[], ARRAY['vilamoura', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('cerro-da-vila', 'vilamoura', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей и археологический комплекс Серру-да-Вила', 'Cerro da Vila Museum and Archaeological Site', 'Серру-да-Вила музейі және археологиялық орны', 37.08050000, -8.11780000, 'Cerro da Vila Vilamoura Portugal', ARRAY['vilamoura']::text[], ARRAY['vilamoura']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-de-vilamoura', 'vilamoura', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Виламора', 'Praia de Vilamoura', 'Виламора жағажайы', 37.07070000, -8.11750000, 'Praia de Vilamoura Portugal', ARRAY['vilamoura']::text[], ARRAY['vilamoura']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('vilamoura-casino', 'vilamoura', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Казино Виламоры', 'Vilamoura Casino', 'Виламора казиносы', 37.07470000, -8.11520000, 'Vilamoura Casino Portugal', ARRAY['vilamoura']::text[], ARRAY['vilamoura']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('mercado-dos-lavradores', 'funchal', 'MARKET', 2, 'HOURS', 4.7, 'Рынок Меркаду-душ-Лаврадореш', 'Mercado dos Lavradores', 'Лаврадореш базары', 32.64810000, -16.90280000, 'Mercado dos Lavradores Funchal Madeira Portugal', ARRAY['funchal', 'madeira']::text[], ARRAY['funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('monte-palace-tropical-garden', 'funchal', 'PARK', 3, 'HOURS', 4.8, 'Тропический сад Монте-Палас', 'Monte Palace Madeira Tropical Garden', 'Монте-Палас тропикалық бағы', 32.67560000, -16.90200000, 'Monte Palace Tropical Garden Funchal Madeira', ARRAY['funchal', 'madeira']::text[], ARRAY['funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('madeira-botanical-garden', 'funchal', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Мадейры', 'Madeira Botanical Garden', 'Мадейра ботаникалық бағы', 32.66260000, -16.89530000, 'Madeira Botanical Garden Funchal Portugal', ARRAY['funchal', 'madeira']::text[], ARRAY['funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('funchal-cable-car', 'funchal', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канатная дорога Фуншала', 'Funchal Cable Car', 'Фуншал аспалы жолы', 32.64850000, -16.90180000, 'Funchal Cable Car Madeira Portugal', ARRAY['funchal', 'madeira']::text[], ARRAY['funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('praia-formosa', 'funchal', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Формоза', 'Praia Formosa', 'Формоза жағажайы', 32.63530000, -16.94860000, 'Praia Formosa Funchal Madeira Portugal', ARRAY['funchal', 'madeira']::text[], ARRAY['funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),

    ('cabo-girao-skywalk', 'madeira', 'NATURE', 2, 'HOURS', 4.8, 'Скайуок Кабу-Жиран', 'Cabo Girao Skywalk', 'Кабу-Жиран шыны алаңы', 32.65780000, -17.00470000, 'Cabo Girao Skywalk Madeira Portugal', ARRAY['madeira', 'funchal']::text[], ARRAY['madeira', 'funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('pico-do-arieiro', 'madeira', 'NATURE', 4, 'HOURS', 4.9, 'Пику-ду-Ариейру', 'Pico do Arieiro', 'Пику-ду-Ариейру', 32.73570000, -16.92820000, 'Pico do Arieiro Madeira Portugal', ARRAY['madeira']::text[], ARRAY['madeira', 'funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('porto-moniz-natural-pools', 'madeira', 'NATURE', 3, 'HOURS', 4.8, 'Природные бассейны Порту-Мониш', 'Porto Moniz Natural Pools', 'Порту-Мониш табиғи бассейндері', 32.86610000, -17.16670000, 'Porto Moniz Natural Pools Madeira Portugal', ARRAY['madeira']::text[], ARRAY['madeira', 'funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('santana-traditional-houses', 'madeira', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Традиционные дома Сантаны', 'Santana Traditional Houses', 'Сантана дәстүрлі үйлері', 32.80300000, -16.88100000, 'Santana traditional houses Madeira Portugal', ARRAY['madeira']::text[], ARRAY['madeira', 'funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),

    ('portas-da-cidade-ponta-delgada', 'ponta-delgada', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Городские ворота Понта-Делгады', 'Portas da Cidade', 'Қала қақпалары', 37.73990000, -25.66870000, 'Portas da Cidade Ponta Delgada Azores Portugal', ARRAY['ponta-delgada', 'sao-miguel']::text[], ARRAY['ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('mercado-da-graca', 'ponta-delgada', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Меркаду-да-Граса', 'Mercado da Graca', 'Граса базары', 37.74230000, -25.66440000, 'Mercado da Graca Ponta Delgada Portugal', ARRAY['ponta-delgada', 'sao-miguel']::text[], ARRAY['ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('parque-atlantico', 'ponta-delgada', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Parque Atlantico', 'Parque Atlantico', 'Parque Atlantico', 37.74720000, -25.67300000, 'Parque Atlantico Ponta Delgada Portugal', ARRAY['ponta-delgada', 'sao-miguel']::text[], ARRAY['ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('whale-watching-ponta-delgada', 'ponta-delgada', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Наблюдение за китами и дельфинами', 'Whale and Dolphin Watching', 'Киттер мен дельфиндерді бақылау', 37.73890000, -25.66080000, 'Whale watching Ponta Delgada Azores Portugal', ARRAY['ponta-delgada', 'sao-miguel']::text[], ARRAY['ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),

    ('sete-cidades', 'sao-miguel', 'NATURE', 4, 'HOURS', 4.9, 'Сете-Сидадеш', 'Sete Cidades', 'Сете-Сидадеш', 37.86200000, -25.79400000, 'Sete Cidades Sao Miguel Azores Portugal', ARRAY['sao-miguel', 'ponta-delgada']::text[], ARRAY['ponta-delgada', 'sao-miguel']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('lagoa-do-fogo', 'sao-miguel', 'NATURE', 4, 'HOURS', 4.9, 'Лагоа-ду-Фогу', 'Lagoa do Fogo', 'Лагоа-ду-Фогу', 37.75900000, -25.47100000, 'Lagoa do Fogo Sao Miguel Azores Portugal', ARRAY['sao-miguel']::text[], ARRAY['ponta-delgada', 'sao-miguel']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('furnas-terra-nostra', 'sao-miguel', 'PARK', 4, 'HOURS', 4.8, 'Фурнаш и парк Терра-Ноштра', 'Furnas and Terra Nostra Park', 'Фурнаш және Терра-Ноштра паркі', 37.77300000, -25.31500000, 'Furnas Terra Nostra Park Sao Miguel Azores Portugal', ARRAY['sao-miguel']::text[], ARRAY['ponta-delgada', 'sao-miguel']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('praia-das-milicias', 'sao-miguel', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Милисиаш', 'Praia das Milicias', 'Милисиаш жағажайы', 37.74850000, -25.60680000, 'Praia das Milicias Sao Miguel Azores Portugal', ARRAY['sao-miguel', 'ponta-delgada']::text[], ARRAY['ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg');

CREATE TEMP TABLE seed_portugal_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-portugal-attraction:' || seed.slug) AS attraction_hash,
        md5('id-portugal-media:' || seed.slug) AS media_hash
    FROM seed_portugal_priority_attractions seed
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
    ARRAY['portugal', city_id, slug, lower(category), 'portugal-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Португалии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Portugal tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Португалия туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'PT',
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
FROM seed_portugal_resolved_attractions
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
    highlights,
    created_at,
    updated_at
)
SELECT
    id,
    'ru',
    title_ru,
    description_ru,
    ARRAY[title_ru, 'Португалия', city_id]::text[],
    NOW(),
    NOW()
FROM seed_portugal_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    ARRAY[title_en, 'Portugal', city_id]::text[],
    NOW(),
    NOW()
FROM seed_portugal_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    ARRAY[title_kk, 'Португалия', city_id]::text[],
    NOW(),
    NOW()
FROM seed_portugal_resolved_attractions
ON CONFLICT (attraction_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    highlights = EXCLUDED.highlights,
    updated_at = NOW();

UPDATE attractions a
SET
    latitude = seed.latitude,
    longitude = seed.longitude,
    location_source_url = seed.location_source_url,
    updated_at = NOW()
FROM seed_portugal_resolved_attractions seed
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
FROM seed_portugal_resolved_attractions
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
    'PT',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_portugal_resolved_attractions
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'PT',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_portugal_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_portugal_resolved_attractions;
DROP TABLE IF EXISTS seed_portugal_priority_attractions;
