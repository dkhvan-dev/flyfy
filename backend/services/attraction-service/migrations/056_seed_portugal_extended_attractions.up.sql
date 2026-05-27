-- Extended Portugal destination attractions seed.
-- This migration complements the initial Portugal seed without rewriting already-applied historical migrations.

DROP TABLE IF EXISTS seed_portugal_extended_resolved_attractions;
DROP TABLE IF EXISTS seed_portugal_extended_attractions;

CREATE TEMP TABLE seed_portugal_extended_attractions (
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

INSERT INTO seed_portugal_extended_attractions (
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
    ('lisbon-zoo', 'lisbon', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Лиссабонский зоопарк', 'Lisbon Zoo', 'Лиссабон хайуанаттар бағы', 38.74330000, -9.17110000, 'Lisbon Zoo Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('feira-da-ladra', 'lisbon', 'MARKET', 2, 'HOURS', 4.5, 'Фейра да Ладра', 'Feira da Ladra', 'Фейра да Ладра базары', 38.71550000, -9.12650000, 'Feira da Ladra Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('amoreiras-shopping-center', 'lisbon', 'SHOPPING', 2, 'HOURS', 4.4, 'ТЦ Amoreiras', 'Amoreiras Shopping Center', 'Amoreiras сауда орталығы', 38.72300000, -9.16160000, 'Amoreiras Shopping Center Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('parque-eduardo-vii', 'lisbon', 'PARK', 2, 'HOURS', 4.6, 'Парк Эдуарда VII', 'Parque Eduardo VII', 'Эдуард VII саябағы', 38.72840000, -9.15270000, 'Parque Eduardo VII Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('jardim-da-estrela', 'lisbon', 'PARK', 1, 'HOURS', 4.5, 'Сад Эштрела', 'Jardim da Estrela', 'Эштрела бағы', 38.71500000, -9.16040000, 'Jardim da Estrela Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),
    ('fado-museum', 'lisbon', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей фаду', 'Fado Museum', 'Фаду музейі', 38.71170000, -9.12650000, 'Fado Museum Lisbon Portugal', ARRAY['lisbon']::text[], ARRAY['lisbon']::text[], 'Cloister_of_the_Jerónimos_Monastery_in_Belém,_Lisbon,_20250604_1313_9204.jpg'),

    ('praia-grande-sintra', 'sintra', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Гранде', 'Praia Grande', 'Гранде жағажайы', 38.81400000, -9.47660000, 'Praia Grande Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Praia_da_adraga_portugal.jpg'),
    ('praia-das-macas', 'sintra', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Машаш', 'Praia das Macas', 'Масаш жағажайы', 38.82440000, -9.46900000, 'Praia das Macas Sintra Portugal', ARRAY['sintra']::text[], ARRAY['sintra', 'lisbon']::text[], 'Praia_da_adraga_portugal.jpg'),
    ('musa-sintra-museum', 'sintra', 'MUSEUM', 2, 'HOURS', 4.4, 'MU.SA - Музей искусств Синтры', 'MU.SA - Sintra Museum of Arts', 'MU.SA Синтра өнер музейі', 38.80050000, -9.38280000, 'MU.SA Sintra Museum of Arts Portugal', ARRAY['sintra']::text[], ARRAY['sintra']::text[], 'Pena_Palace,_Sintra,_Portugal,_20250606_1037_0005.jpg'),

    ('praia-da-rainha', 'cascais', 'BEACH', 2, 'HOURS', 4.6, 'Пляж Раинья', 'Praia da Rainha', 'Раинья жағажайы', 38.70000000, -9.41850000, 'Praia da Rainha Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('praia-do-tamariz', 'cascais', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Тамариз', 'Praia do Tamariz', 'Тамариз жағажайы', 38.70320000, -9.39840000, 'Praia do Tamariz Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('condes-castro-guimaraes-museum', 'cascais', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей графов Каштру Гимарайнш', 'Condes de Castro Guimaraes Museum', 'Каштру Гимарайнш музейі', 38.69360000, -9.42110000, 'Condes de Castro Guimaraes Museum Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('santa-marta-lighthouse-museum', 'cascais', 'MUSEUM', 1, 'HOURS', 4.5, 'Маяк-музей Санта-Марта', 'Santa Marta Lighthouse Museum', 'Санта-Марта шамшырақ музейі', 38.69190000, -9.42140000, 'Santa Marta Lighthouse Museum Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('marechal-carmona-park', 'cascais', 'PARK', 2, 'HOURS', 4.6, 'Парк Марешал Кармона', 'Marechal Carmona Park', 'Марешал Кармона саябағы', 38.69480000, -9.42260000, 'Marechal Carmona Park Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('mercado-da-vila-cascais', 'cascais', 'MARKET', 2, 'HOURS', 4.5, 'Mercado da Vila Cascais', 'Mercado da Vila Cascais', 'Mercado da Vila Cascais', 38.69970000, -9.42180000, 'Mercado da Vila Cascais Portugal', ARRAY['cascais']::text[], ARRAY['cascais']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),
    ('casino-estoril', 'cascais', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Казино Эшторил', 'Casino Estoril', 'Эшторил казиносы', 38.70940000, -9.39770000, 'Casino Estoril Portugal', ARRAY['cascais']::text[], ARRAY['cascais', 'lisbon']::text[], 'Boca_do_inferno_cascais_lisbonne_(1413027741).jpg'),

    ('praia-de-galapos', 'setubal', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Галапуш', 'Praia de Galapos', 'Галапуш жағажайы', 38.48290000, -8.96830000, 'Praia de Galapos Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('praia-de-albarquel', 'setubal', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Албаркел', 'Praia de Albarquel', 'Албаркел жағажайы', 38.51360000, -8.91430000, 'Praia de Albarquel Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('museu-setubal-convento-jesus', 'setubal', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Сетубала и монастырь Иисуса', 'Museu de Setubal and Convento de Jesus', 'Сетубал музейі және Иса монастыры', 38.52560000, -8.89230000, 'Museu de Setubal Convento de Jesus Portugal', ARRAY['setubal']::text[], ARRAY['setubal']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('sado-dolphin-watching', 'setubal', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Наблюдение за дельфинами в Саду', 'Sado Dolphin Watching', 'Саду дельфиндерін бақылау', 38.52380000, -8.88970000, 'Sado Dolphin Watching Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('alegro-setubal', 'setubal', 'SHOPPING', 2, 'HOURS', 4.3, 'ТЦ Alegro Setubal', 'Alegro Setubal', 'Alegro Setubal', 38.53230000, -8.88120000, 'Alegro Setubal Portugal', ARRAY['setubal']::text[], ARRAY['setubal']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('sesimbra-castle', 'sesimbra', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Замок Сезимбры', 'Sesimbra Castle', 'Сезимбра қамалы', 38.45070000, -9.10150000, 'Sesimbra Castle Portugal', ARRAY['sesimbra', 'setubal']::text[], ARRAY['sesimbra', 'setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('praia-ribeira-do-cavalo', 'sesimbra', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Рибейра-ду-Кавалу', 'Praia da Ribeira do Cavalo', 'Рибейра-ду-Кавалу жағажайы', 38.43460000, -9.10680000, 'Praia da Ribeira do Cavalo Sesimbra Portugal', ARRAY['sesimbra']::text[], ARRAY['sesimbra', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('arrabida-beaches', 'sesimbra', 'BEACH', 4, 'HOURS', 4.8, 'Пляжи Аррабиды', 'Arrabida Beaches', 'Аррабида жағажайлары', 38.47700000, -8.98000000, 'Arrabida Beaches Portugal', ARRAY['sesimbra', 'setubal']::text[], ARRAY['sesimbra', 'setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),
    ('comporta-beach', 'comporta', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Компорта', 'Comporta Beach', 'Компорта жағажайы', 38.38060000, -8.80380000, 'Comporta Beach Portugal', ARRAY['comporta', 'setubal']::text[], ARRAY['comporta', 'setubal', 'lisbon']::text[], 'PRAIA_DE_GALAPOS_ARRABIDA.jpg'),

    ('crystal-palace-gardens', 'porto', 'PARK', 2, 'HOURS', 4.6, 'Сады Хрустального дворца', 'Crystal Palace Gardens', 'Хрусталь сарай бақтары', 41.14850000, -8.62570000, 'Crystal Palace Gardens Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('porto-cathedral', 'porto', 'TEMPLE', 1, 'HOURS', 4.7, 'Кафедральный собор Порту', 'Porto Cathedral', 'Порту кафедралды соборы', 41.14280000, -8.61100000, 'Porto Cathedral Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('sea-life-porto', 'porto', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'SEA LIFE Porto', 'SEA LIFE Porto', 'SEA LIFE Porto', 41.16990000, -8.68810000, 'SEA LIFE Porto Portugal', ARRAY['porto']::text[], ARRAY['porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('beira-rio-market', 'vila-nova-de-gaia', 'MARKET', 2, 'HOURS', 4.5, 'Рынок Бейра-Рио', 'Beira-Rio Market', 'Бейра-Рио базары', 41.13680000, -8.61570000, 'Beira Rio Market Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('senhor-da-pedra-beach', 'vila-nova-de-gaia', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Сеньор-да-Педра', 'Senhor da Pedra Beach', 'Сеньор-да-Педра жағажайы', 41.06990000, -8.65740000, 'Senhor da Pedra Beach Vila Nova de Gaia Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('gaia-biological-park', 'vila-nova-de-gaia', 'PARK', 3, 'HOURS', 4.5, 'Биологический парк Гайи', 'Gaia Biological Park', 'Гайя биологиялық саябағы', 41.09190000, -8.55980000, 'Gaia Biological Park Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('douro-estuary-nature-reserve', 'vila-nova-de-gaia', 'NATURE', 2, 'HOURS', 4.5, 'Природный заповедник эстуария Дору', 'Douro Estuary Nature Reserve', 'Дору сағасы табиғи қорығы', 41.14230000, -8.66560000, 'Douro Estuary Nature Reserve Portugal', ARRAY['vila-nova-de-gaia', 'porto']::text[], ARRAY['vila-nova-de-gaia', 'porto']::text[], 'Ribeira_from_Dom_Luis_I_bridge_(4).jpg'),
    ('bom-jesus-funicular', 'braga', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Фуникулер Бон-Жезуш', 'Bom Jesus Funicular', 'Бон-Жезуш фуникулері', 41.55460000, -8.37700000, 'Bom Jesus Funicular Braga Portugal', ARRAY['braga']::text[], ARRAY['braga', 'porto']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('sameiro-sanctuary', 'braga', 'TEMPLE', 2, 'HOURS', 4.7, 'Святилище Самейру', 'Sameiro Sanctuary', 'Самейру ғибадатханасы', 41.54180000, -8.36980000, 'Sameiro Sanctuary Braga Portugal', ARRAY['braga']::text[], ARRAY['braga', 'porto']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('santa-barbara-garden-braga', 'braga', 'PARK', 1, 'HOURS', 4.5, 'Сад Санта-Барбара', 'Santa Barbara Garden Braga', 'Санта-Барбара бағы', 41.55190000, -8.42620000, 'Santa Barbara Garden Braga Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('raio-palace', 'braga', 'MUSEUM', 1, 'HOURS', 4.5, 'Дворец Райу', 'Raio Palace', 'Райу сарайы', 41.54890000, -8.42180000, 'Raio Palace Braga Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('picoto-urban-park', 'braga', 'PARK', 2, 'HOURS', 4.4, 'Городской парк Пикоту', 'Picoto Urban Park', 'Пикоту қалалық саябағы', 41.53520000, -8.41950000, 'Picoto Urban Park Braga Portugal', ARRAY['braga']::text[], ARRAY['braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('alberto-sampaio-museum', 'guimaraes', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Алберту Сампайу', 'Alberto Sampaio Museum', 'Алберту Сампайу музейі', 41.44360000, -8.29160000, 'Alberto Sampaio Museum Guimaraes Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes', 'porto']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('ciajg-guimaraes', 'guimaraes', 'MUSEUM', 2, 'HOURS', 4.4, 'Международный центр искусств Жозе де Гимарайнш', 'Jose de Guimaraes International Arts Centre', 'Жозе де Гимарайнш өнер орталығы', 41.44230000, -8.29540000, 'Jose de Guimaraes International Arts Centre Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('guimaraes-cable-car', 'guimaraes', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канатная дорога Гимарайнша', 'Guimaraes Cable Car', 'Гимарайнш аспалы жолы', 41.44010000, -8.28960000, 'Guimaraes Cable Car Portugal', ARRAY['guimaraes']::text[], ARRAY['guimaraes']::text[], 'Guimaraes_castle_exterior.jpg'),
    ('douro-historical-train', 'douro-valley', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Исторический поезд Дору', 'Douro Historical Train', 'Дору тарихи пойызы', 41.16190000, -7.78890000, 'Douro Historical Train Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley', 'porto']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('pinhao-railway-station', 'douro-valley', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Станция Пиньян', 'Pinhao Railway Station', 'Пиньян теміржол станциясы', 41.19000000, -7.54570000, 'Pinhao Railway Station Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('nossa-senhora-remedios-sanctuary', 'douro-valley', 'TEMPLE', 2, 'HOURS', 4.7, 'Святилище Носа-Сеньора-душ-Ремедиуш', 'Sanctuary of Nossa Senhora dos Remedios', 'Носа-Сеньора-душ-Ремедиуш ғибадатханасы', 41.09890000, -7.80920000, 'Sanctuary of Nossa Senhora dos Remedios Lamego Portugal', ARRAY['douro-valley']::text[], ARRAY['douro-valley']::text[], 'The_Douro_Valley_vineyards.jpg'),
    ('barra-beach-lighthouse', 'aveiro', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Барра и маяк', 'Barra Beach and Lighthouse', 'Барра жағажайы және шамшырағы', 40.64030000, -8.74930000, 'Barra Beach Lighthouse Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('vista-alegre-museum', 'aveiro', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Vista Alegre', 'Vista Alegre Museum', 'Vista Alegre музейі', 40.58760000, -8.68170000, 'Vista Alegre Museum Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('troncalhada-salt-ecomuseum', 'aveiro', 'MUSEUM', 1, 'HOURS', 4.4, 'Экомузей соли Тронкальяда', 'Troncalhada Marine Ecomuseum', 'Тронкальяда тұз экомұражайы', 40.64730000, -8.65370000, 'Troncalhada Marine Ecomuseum Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('aveiro-walkways', 'aveiro', 'NATURE', 2, 'HOURS', 4.5, 'Настилы Авейру', 'Aveiro Walkways', 'Авейру серуен жолдары', 40.66500000, -8.65300000, 'Aveiro Walkways Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),
    ('costa-nova-palheiros', 'aveiro', 'BEACH', 3, 'HOURS', 4.6, 'Кошта-Нова и полосатые дома', 'Costa Nova', 'Кошта-Нова', 40.61390000, -8.75160000, 'Costa Nova Aveiro Portugal', ARRAY['aveiro']::text[], ARRAY['aveiro']::text[], 'Canal_in_Aveiro_12.jpg'),

    ('convent-of-christ', 'tomar', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Монастырь ордена Христа', 'Convent of Christ', 'Христос монастыры', 39.60430000, -8.41780000, 'Convent of Christ Tomar Portugal', ARRAY['tomar']::text[], ARRAY['tomar', 'lisbon', 'coimbra']::text[], 'Obidos_April_2009-4b.jpg'),
    ('tomar-synagogue', 'tomar', 'MUSEUM', 1, 'HOURS', 4.5, 'Синагога Томара', 'Tomar Synagogue', 'Томар синагогасы', 39.60240000, -8.41100000, 'Tomar Synagogue Portugal', ARRAY['tomar']::text[], ARRAY['tomar']::text[], 'Obidos_April_2009-4b.jpg'),
    ('mouchao-park', 'tomar', 'PARK', 1, 'HOURS', 4.4, 'Парк Моушан', 'Mouchao Park', 'Моушан саябағы', 39.60120000, -8.41480000, 'Mouchao Park Tomar Portugal', ARRAY['tomar']::text[], ARRAY['tomar']::text[], 'Obidos_April_2009-4b.jpg'),
    ('batalha-monastery', 'batalha', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Монастырь Баталья', 'Batalha Monastery', 'Баталья монастыры', 39.65950000, -8.82600000, 'Batalha Monastery Portugal', ARRAY['batalha']::text[], ARRAY['batalha', 'fatima', 'lisbon']::text[], 'Portugal,_Fatima,_Sanctuary_of_Our_Lady_of_Fatima_(52593373732).jpg'),
    ('alcobaca-monastery', 'alcobaca', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Монастырь Алкобаса', 'Alcobaca Monastery', 'Алкобаса монастыры', 39.54890000, -8.97970000, 'Alcobaca Monastery Portugal', ARRAY['alcobaca']::text[], ARRAY['alcobaca', 'nazare', 'lisbon']::text[], 'Nazaré_February_2013-15.jpg'),
    ('peniche-fortress', 'peniche', 'MUSEUM', 2, 'HOURS', 4.6, 'Крепость Пениши', 'Peniche Fortress', 'Пениши қамалы', 39.35500000, -9.38100000, 'Peniche Fortress Portugal', ARRAY['peniche']::text[], ARRAY['peniche', 'lisbon']::text[], 'Nazaré_February_2013-15.jpg'),
    ('supertubos-beach', 'peniche', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Супертубуш', 'Supertubos Beach', 'Супертубуш жағажайы', 39.34190000, -9.36160000, 'Supertubos Beach Peniche Portugal', ARRAY['peniche']::text[], ARRAY['peniche', 'lisbon']::text[], 'Nazaré_February_2013-15.jpg'),
    ('baleal-beach', 'peniche', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Балеал', 'Baleal Beach', 'Балеал жағажайы', 39.37200000, -9.33900000, 'Baleal Beach Peniche Portugal', ARRAY['peniche']::text[], ARRAY['peniche']::text[], 'Nazaré_February_2013-15.jpg'),
    ('berlengas-nature-reserve', 'berlengas', 'NATURE', 5, 'HOURS', 4.9, 'Природный заповедник Берленгаш', 'Berlengas Nature Reserve', 'Берленгаш табиғи қорығы', 39.41560000, -9.50890000, 'Berlengas Nature Reserve Portugal', ARRAY['berlengas', 'peniche']::text[], ARRAY['peniche', 'lisbon']::text[], 'Nazaré_February_2013-15.jpg'),
    ('sao-joao-baptista-fort-berlengas', 'berlengas', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Форт Сан-Жуан-Баптиста', 'Sao Joao Baptista Fort Berlengas', 'Берленгаш Сан-Жуан-Баптиста қамалы', 39.41260000, -9.50840000, 'Sao Joao Baptista Fort Berlengas Portugal', ARRAY['berlengas', 'peniche']::text[], ARRAY['peniche']::text[], 'Nazaré_February_2013-15.jpg'),
    ('serra-da-estrela-natural-park', 'serra-da-estrela', 'PARK', 6, 'HOURS', 4.8, 'Природный парк Серра-да-Эштрела', 'Serra da Estrela Natural Park', 'Серра-да-Эштрела табиғи саябағы', 40.32190000, -7.61360000, 'Serra da Estrela Natural Park Portugal', ARRAY['serra-da-estrela']::text[], ARRAY['serra-da-estrela', 'coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('torre-serra-da-estrela', 'serra-da-estrela', 'NATURE', 3, 'HOURS', 4.7, 'Торре Серра-да-Эштрела', 'Torre Serra da Estrela', 'Серра-да-Эштрела Торре', 40.32190000, -7.61360000, 'Torre Serra da Estrela Portugal', ARRAY['serra-da-estrela']::text[], ARRAY['serra-da-estrela', 'coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('covao-dos-conchos', 'serra-da-estrela', 'NATURE', 4, 'HOURS', 4.6, 'Кован-душ-Коншуш', 'Covao dos Conchos', 'Кован-душ-Коншуш', 40.36350000, -7.61290000, 'Covao dos Conchos Portugal', ARRAY['serra-da-estrela']::text[], ARRAY['serra-da-estrela']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('monsaraz-castle', 'monsaraz', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Замок Монсараш', 'Monsaraz Castle', 'Монсараш қамалы', 38.44300000, -7.38150000, 'Monsaraz Castle Portugal', ARRAY['monsaraz', 'evora']::text[], ARRAY['evora', 'lisbon']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('alqueva-lake', 'monsaraz', 'NATURE', 3, 'HOURS', 4.6, 'Озеро Алкева', 'Alqueva Lake', 'Алкева көлі', 38.45000000, -7.46670000, 'Alqueva Lake Monsaraz Portugal', ARRAY['monsaraz']::text[], ARRAY['monsaraz', 'evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),

    ('peneda-geres-national-park', 'peneda-geres', 'PARK', 6, 'HOURS', 4.9, 'Национальный парк Пенеда-Жереш', 'Peneda-Geres National Park', 'Пенеда-Жереш ұлттық паркі', 41.72480000, -8.15900000, 'Peneda-Geres National Park Portugal', ARRAY['peneda-geres', 'braga']::text[], ARRAY['braga', 'porto']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),
    ('tahiti-waterfall-geres', 'peneda-geres', 'NATURE', 3, 'HOURS', 4.7, 'Водопад Тахити', 'Tahiti Waterfall Geres', 'Жереш Тахити сарқырамасы', 41.70250000, -8.12470000, 'Tahiti Waterfall Geres Portugal', ARRAY['peneda-geres']::text[], ARRAY['peneda-geres', 'braga']::text[], 'Basílica_Bom_Jesus_do_Monte_(Braga)_01.jpg'),

    ('loule-market', 'loule', 'MARKET', 2, 'HOURS', 4.6, 'Рынок Лоле', 'Loule Market', 'Лоле базары', 37.13790000, -8.02390000, 'Loule Market Portugal', ARRAY['loule', 'faro']::text[], ARRAY['loule', 'faro']::text[], 'FaroKesklinn.jpg'),
    ('aquashow-park', 'loule', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Аквапарк Aquashow', 'Aquashow Park', 'Aquashow аквапаркі', 37.09220000, -8.06630000, 'Aquashow Park Algarve Portugal', ARRAY['loule', 'vilamoura', 'faro']::text[], ARRAY['loule', 'vilamoura', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('algarve-international-sand-sculpture-festival', 'carvoeiro', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Международный фестиваль песчаных скульптур Алгарве', 'Algarve International Sand Sculpture Festival', 'Алгарве құм мүсіндері халықаралық фестивалі', 37.14000000, -8.41000000, 'Algarve International Sand Sculpture Festival Portugal', ARRAY['carvoeiro', 'lagoa']::text[], ARRAY['carvoeiro', 'lagoa', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('carvoeiro-boardwalk', 'carvoeiro', 'NATURE', 2, 'HOURS', 4.7, 'Променад Карвоэйру', 'Carvoeiro Boardwalk', 'Карвоэйру серуен жолы', 37.09600000, -8.46650000, 'Carvoeiro Boardwalk Portugal', ARRAY['carvoeiro', 'lagoa']::text[], ARRAY['carvoeiro', 'lagoa']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-do-carvalho', 'carvoeiro', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Карвалью', 'Praia do Carvalho', 'Карвалью жағажайы', 37.08630000, -8.43160000, 'Praia do Carvalho Carvoeiro Portugal', ARRAY['carvoeiro', 'lagoa']::text[], ARRAY['carvoeiro', 'lagoa']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('faro-municipal-market', 'faro', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок Фару', 'Faro Municipal Market', 'Фару муниципалдық базары', 37.01920000, -7.92890000, 'Faro Municipal Market Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('albufeira-strip', 'albufeira', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Вечерний район The Strip', 'Albufeira Strip', 'Албуфейра The Strip', 37.08980000, -8.22720000, 'Albufeira Strip Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('lagos-municipal-market', 'lagos', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок Лагуша', 'Lagos Municipal Market', 'Лагуш муниципалдық базары', 37.10260000, -8.67170000, 'Lagos Municipal Market Portugal', ARRAY['lagos']::text[], ARRAY['lagos']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('fort-santa-catarina-portimao', 'portimao', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Форт Санта-Катарина', 'Fort of Santa Catarina Portimao', 'Портиман Санта-Катарина қамалы', 37.11890000, -8.52930000, 'Fort of Santa Catarina Portimao Portugal', ARRAY['portimao']::text[], ARRAY['portimao']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('camera-obscura-tavira', 'tavira', 'ENTERTAINMENT', 1, 'HOURS', 4.4, 'Камера-обскура Тавиры', 'Tavira Camera Obscura', 'Тавира камера-обскурасы', 37.12670000, -7.65020000, 'Tavira Camera Obscura Portugal', ARRAY['tavira']::text[], ARRAY['tavira']::text[], 'FaroKesklinn.jpg'),
    ('sagres-surf-schools', 'sagres', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Серфинг в Сагреше', 'Sagres Surf Schools', 'Сагреш серфинг мектептері', 37.00690000, -8.93720000, 'Sagres Surf Schools Portugal', ARRAY['sagres']::text[], ARRAY['sagres', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('porto-santo-beach', 'porto-santo', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Порту-Санту', 'Porto Santo Beach', 'Порту-Санту жағажайы', 33.06080000, -16.33370000, 'Porto Santo Beach Portugal', ARRAY['porto-santo', 'madeira']::text[], ARRAY['porto-santo', 'madeira', 'funchal']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('porto-santo-columbus-house', 'porto-santo', 'MUSEUM', 1, 'HOURS', 4.4, 'Дом-музей Колумба', 'Columbus House Museum Porto Santo', 'Порту-Санту Колумб үй-музейі', 33.05930000, -16.33620000, 'Columbus House Museum Porto Santo Portugal', ARRAY['porto-santo']::text[], ARRAY['porto-santo']::text[], 'Funchal_(Madeira,_Portugal),_Teleférico_Funchal-Monte,_Talstation_--_2025_--_1192.jpg'),
    ('angra-do-heroismo', 'terceira', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Ангра-ду-Эроижму', 'Angra do Heroismo', 'Ангра-ду-Эроижму', 38.65570000, -27.22090000, 'Angra do Heroismo Terceira Portugal', ARRAY['terceira']::text[], ARRAY['terceira']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('algar-do-carvao', 'terceira', 'NATURE', 2, 'HOURS', 4.8, 'Алгар-ду-Карван', 'Algar do Carvao', 'Алгар-ду-Карван', 38.72800000, -27.21600000, 'Algar do Carvao Terceira Portugal', ARRAY['terceira']::text[], ARRAY['terceira']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('praia-da-vitoria', 'terceira', 'BEACH', 3, 'HOURS', 4.5, 'Прайя-да-Витория', 'Praia da Vitoria', 'Прайя-да-Витория', 38.73330000, -27.06670000, 'Praia da Vitoria Terceira Portugal', ARRAY['terceira']::text[], ARRAY['terceira']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('mount-pico', 'pico', 'NATURE', 6, 'HOURS', 4.9, 'Гора Пику', 'Mount Pico', 'Пику тауы', 38.46870000, -28.39990000, 'Mount Pico Azores Portugal', ARRAY['pico']::text[], ARRAY['pico', 'ponta-delgada']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('pico-vineyard-culture', 'pico', 'NATURE', 3, 'HOURS', 4.8, 'Виноградники острова Пику', 'Pico Vineyard Culture', 'Пику жүзімдіктері', 38.51290000, -28.52080000, 'Pico Island Vineyard Culture Portugal', ARRAY['pico']::text[], ARRAY['pico']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('whalers-museum-pico', 'pico', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей китобоев Пику', 'Whalers Museum Pico', 'Пику кит аулаушылар музейі', 38.52350000, -28.31780000, 'Whalers Museum Pico Portugal', ARRAY['pico']::text[], ARRAY['pico']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('capelinhos-volcano', 'faial', 'NATURE', 3, 'HOURS', 4.8, 'Вулкан Капелиньюш', 'Capelinhos Volcano', 'Капелиньюш жанартауы', 38.60060000, -28.82670000, 'Capelinhos Volcano Faial Portugal', ARRAY['faial']::text[], ARRAY['faial']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('horta-marina', 'faial', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Марина Орты', 'Horta Marina', 'Орта маринасы', 38.53570000, -28.63030000, 'Horta Marina Faial Portugal', ARRAY['faial']::text[], ARRAY['faial']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),
    ('peter-cafe-sport', 'faial', 'FOOD', 2, 'HOURS', 4.5, 'Peter Cafe Sport', 'Peter Cafe Sport', 'Peter Cafe Sport', 38.53600000, -28.62890000, 'Peter Cafe Sport Horta Faial Portugal', ARRAY['faial']::text[], ARRAY['faial']::text[], 'Lagoa_Rasa_(Sete_Cidades)_2.jpg'),

    ('praia-de-faro', 'faro', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Фару', 'Praia de Faro', 'Фару жағажайы', 37.00890000, -7.99450000, 'Praia de Faro Portugal', ARRAY['faro']::text[], ARRAY['faro']::text[], 'FaroKesklinn.jpg'),
    ('lagos-zoo', 'lagos', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Зоопарк Лагуша', 'Lagos Zoo', 'Лагуш хайуанаттар бағы', 37.14580000, -8.74000000, 'Lagos Zoo Portugal', ARRAY['lagos']::text[], ARRAY['lagos', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('albufeira-archaeology-museum', 'albufeira', 'MUSEUM', 1, 'HOURS', 4.4, 'Муниципальный археологический музей Албуфейры', 'Municipal Archaeology Museum of Albufeira', 'Албуфейра археология музейі', 37.08810000, -8.25240000, 'Municipal Archaeology Museum of Albufeira Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('mercado-municipal-calicos', 'albufeira', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок Калисуш', 'Mercado Municipal dos Calicos', 'Калисуш муниципалдық базары', 37.09530000, -8.24440000, 'Mercado Municipal dos Calicos Albufeira Portugal', ARRAY['albufeira']::text[], ARRAY['albufeira']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('algarve-international-circuit', 'portimao', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Автодром Алгарве', 'Algarve International Circuit', 'Алгарве халықаралық автодромы', 37.23190000, -8.62830000, 'Algarve International Circuit Portimao Portugal', ARRAY['portimao']::text[], ARRAY['portimao', 'faro']::text[], 'Praia_da_Rocha,_Portimão_2.jpg'),
    ('praia-do-barril', 'tavira', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Баррил', 'Praia do Barril', 'Баррил жағажайы', 37.08890000, -7.66830000, 'Praia do Barril Tavira Portugal', ARRAY['tavira']::text[], ARRAY['tavira', 'faro']::text[], 'FaroKesklinn.jpg'),
    ('tavira-islamic-museum', 'tavira', 'MUSEUM', 1, 'HOURS', 4.4, 'Исламский музейный центр Тавиры', 'Tavira Islamic Museum Centre', 'Тавира ислам музей орталығы', 37.12600000, -7.65010000, 'Tavira Islamic Museum Centre Portugal', ARRAY['tavira']::text[], ARRAY['tavira']::text[], 'FaroKesklinn.jpg'),
    ('seven-hanging-valleys-trail', 'carvoeiro', 'NATURE', 4, 'HOURS', 4.8, 'Тропа семи висячих долин', 'Seven Hanging Valleys Trail', 'Жеті аспалы аңғар соқпағы', 37.09080000, -8.45560000, 'Seven Hanging Valleys Trail Lagoa Portugal', ARRAY['carvoeiro', 'lagoa']::text[], ARRAY['carvoeiro', 'lagoa', 'faro']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),
    ('praia-do-carvoeiro', 'carvoeiro', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Карвоэйру', 'Praia do Carvoeiro', 'Карвоэйру жағажайы', 37.09690000, -8.47160000, 'Praia do Carvoeiro Portugal', ARRAY['carvoeiro', 'lagoa']::text[], ARRAY['carvoeiro', 'lagoa']::text[], 'Benagil_Cave,_July_2012_edited.jpg'),

    ('santa-clara-a-velha-monastery', 'coimbra', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Монастырь Санта-Клара-а-Велья', 'Santa Clara-a-Velha Monastery', 'Санта-Клара-а-Велья монастыры', 40.20410000, -8.43380000, 'Santa Clara-a-Velha Monastery Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('coimbra-botanical-garden', 'coimbra', 'PARK', 2, 'HOURS', 4.6, 'Ботанический сад Университета Коимбры', 'Botanical Garden of the University of Coimbra', 'Коимбра университетінің ботаникалық бағы', 40.20590000, -8.42180000, 'Botanical Garden University of Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('mercado-d-pedro-v-coimbra', 'coimbra', 'MARKET', 1, 'HOURS', 4.4, 'Муниципальный рынок D. Pedro V', 'Mercado Municipal D. Pedro V', 'D. Pedro V муниципалдық базары', 40.21120000, -8.42810000, 'Mercado Municipal D Pedro V Coimbra Portugal', ARRAY['coimbra']::text[], ARRAY['coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('almendres-cromlech', 'evora', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Кромлех Алмендриш', 'Almendres Cromlech', 'Алмендриш кромлехы', 38.55740000, -8.06100000, 'Almendres Cromlech Evora Portugal', ARRAY['evora']::text[], ARRAY['evora', 'lisbon']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('monsaraz-river-beach', 'monsaraz', 'BEACH', 3, 'HOURS', 4.6, 'Речной пляж Монсараш', 'Monsaraz River Beach', 'Монсараш өзен жағажайы', 38.42660000, -7.35610000, 'Monsaraz River Beach Portugal', ARRAY['monsaraz']::text[], ARRAY['monsaraz', 'evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('dark-sky-alqueva-observatory', 'monsaraz', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Обсерватория Dark Sky Alqueva', 'Dark Sky Alqueva Observatory', 'Dark Sky Alqueva обсерваториясы', 38.44420000, -7.38180000, 'Dark Sky Alqueva Observatory Monsaraz Portugal', ARRAY['monsaraz']::text[], ARRAY['monsaraz', 'evora']::text[], 'Evora_-_Roman_Temple_-_Wall.jpg'),
    ('pegoes-aqueduct', 'tomar', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Акведук Пегоеш', 'Pegoes Aqueduct', 'Пегоеш акведугы', 39.61580000, -8.44400000, 'Pegoes Aqueduct Tomar Portugal', ARRAY['tomar']::text[], ARRAY['tomar']::text[], 'Obidos_April_2009-4b.jpg'),
    ('castelo-de-bode-reservoir', 'tomar', 'NATURE', 3, 'HOURS', 4.5, 'Водохранилище Каштелу-де-Боде', 'Castelo de Bode Reservoir', 'Каштелу-де-Боде су қоймасы', 39.65000000, -8.30000000, 'Castelo de Bode Reservoir Tomar Portugal', ARRAY['tomar']::text[], ARRAY['tomar', 'coimbra']::text[], 'Obidos_April_2009-4b.jpg'),
    ('loriga-river-beach', 'serra-da-estrela', 'BEACH', 3, 'HOURS', 4.6, 'Речной пляж Лорига', 'Loriga River Beach', 'Лорига өзен жағажайы', 40.32950000, -7.68960000, 'Loriga River Beach Serra da Estrela Portugal', ARRAY['serra-da-estrela']::text[], ARRAY['serra-da-estrela', 'coimbra']::text[], 'Coimbra_December_2011-19a.jpg'),
    ('bread-museum-seia', 'serra-da-estrela', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей хлеба в Сейе', 'Bread Museum', 'Нан музейі', 40.41970000, -7.70350000, 'Bread Museum Seia Portugal', ARRAY['serra-da-estrela']::text[], ARRAY['serra-da-estrela', 'coimbra']::text[], 'Coimbra_December_2011-19a.jpg');

CREATE TEMP TABLE seed_portugal_extended_resolved_attractions AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-portugal-extended-attraction:' || seed.slug) AS attraction_hash,
        md5('id-portugal-extended-media:' || seed.slug) AS media_hash
    FROM seed_portugal_extended_attractions seed
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
    ARRAY['portugal', city_id, slug, lower(category), 'portugal-extended-seed-v1']::text[] AS tags,
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
FROM seed_portugal_extended_resolved_attractions
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
FROM seed_portugal_extended_resolved_attractions
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_portugal_extended_resolved_attractions
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_portugal_extended_resolved_attractions
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
FROM seed_portugal_extended_resolved_attractions seed
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
FROM seed_portugal_extended_resolved_attractions
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
FROM seed_portugal_extended_resolved_attractions
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
FROM seed_portugal_extended_resolved_attractions
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (attraction_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_portugal_extended_resolved_attractions;
DROP TABLE IF EXISTS seed_portugal_extended_attractions;
