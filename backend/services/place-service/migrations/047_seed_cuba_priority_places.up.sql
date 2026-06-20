-- Priority Cuba destination places seed.
-- The seed keeps tourist hubs explicit for admin filters and localized mobile discovery.

DROP TABLE IF EXISTS seed_cuba_resolved_places;
DROP TABLE IF EXISTS seed_cuba_priority_places;

CREATE TEMP TABLE seed_cuba_priority_places (
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

INSERT INTO seed_cuba_priority_places (
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
    ('old-havana', 'havana', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Старая Гавана', 'Old Havana', 'Ескі Гавана', 23.13520000, -82.35900000, 'Old Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('havana-malecon', 'havana', 'PARK', 2, 'HOURS', 4.8, 'Набережная Малекон', 'El Malecon', 'Эль-Малекон жағалауы', 23.14510000, -82.38840000, 'El Malecon Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('el-capitolio-havana', 'havana', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Капитолий Гаваны', 'El Capitolio', 'Гавана Капитолийі', 23.13530000, -82.35940000, 'El Capitolio Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('plaza-de-la-catedral', 'havana', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Катедраль', 'Plaza de la Catedral', 'Катедраль алаңы', 23.14150000, -82.35150000, 'Plaza de la Catedral Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('plaza-vieja-havana', 'havana', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Вьеха', 'Plaza Vieja', 'Вьеха алаңы', 23.13670000, -82.35100000, 'Plaza Vieja Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('castillo-real-fuerza', 'havana', 'MUSEUM', 2, 'HOURS', 4.7, 'Крепость Реал-Фуэрса', 'Castillo de la Real Fuerza', 'Реал-Фуэрса қамалы', 23.14110000, -82.35050000, 'Castillo de la Real Fuerza Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('museum-revolution-havana', 'havana', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей революции', 'Museum of the Revolution', 'Революция музейі', 23.14180000, -82.35620000, 'Museum of the Revolution Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('national-museum-fine-arts-havana', 'havana', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей изящных искусств', 'National Museum of Fine Arts', 'Ұлттық көркем өнер музейі', 23.14030000, -82.35700000, 'National Museum of Fine Arts Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('fusterlandia', 'havana', 'ENTERTAINMENT', 2, 'HOURS', 4.7, 'Фустерландия', 'Fusterlandia', 'Фустерландия', 23.08850000, -82.50140000, 'Fusterlandia Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('fabrica-arte-cubano', 'havana', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Фабрика де Арте Кубано', 'Fabrica de Arte Cubano', 'Фабрика де Арте Кубано', 23.11360000, -82.41420000, 'Fabrica de Arte Cubano Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('callejon-de-hamel', 'havana', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Переулок Амель', 'Callejon de Hamel', 'Амель тұйық көшесі', 23.14070000, -82.37280000, 'Callejon de Hamel Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('tropicana-club', 'havana', 'ENTERTAINMENT', 3, 'HOURS', 4.5, 'Клуб Тропикана', 'Tropicana Club', 'Тропикана клубы', 23.08360000, -82.42430000, 'Tropicana Club Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('san-jose-artisans-market', 'havana', 'MARKET', 2, 'HOURS', 4.6, 'Ремесленный рынок Сан-Хосе', 'San Jose Artisans Market', 'Сан-Хосе қолөнер базары', 23.13520000, -82.34470000, 'San Jose Artisans Market Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('plaza-armas-book-market', 'havana', 'MARKET', 1, 'HOURS', 4.5, 'Книжный рынок Пласа-де-Армас', 'Plaza de Armas Book Market', 'Пласа-де-Армас кітап базары', 23.14050000, -82.35130000, 'Plaza de Armas Book Market Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),
    ('playas-del-este', 'havana', 'BEACH', 4, 'HOURS', 4.6, 'Пляжи Восточной Гаваны', 'Playas del Este', 'Шығыс Гавана жағажайлары', 23.17150000, -82.17860000, 'Playas del Este Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Varadero-Beach.jpg'),
    ('la-bodeguita-del-medio', 'havana', 'FOOD', 1, 'HOURS', 4.3, 'Ла-Бодегита-дель-Медио', 'La Bodeguita del Medio', 'Ла-Бодегита-дель-Медио', 23.14140000, -82.35200000, 'La Bodeguita del Medio Havana Cuba', ARRAY['havana']::text[], ARRAY['havana']::text[], 'Old_Havana_Cuba_(81058857).jpeg'),

    ('vinales-valley', 'vinales', 'NATURE', 5, 'HOURS', 4.9, 'Долина Виньялес', 'Vinales Valley', 'Виньялес аңғары', 22.61700000, -83.71670000, 'Vinales Valley Cuba', ARRAY['vinales']::text[], ARRAY['vinales', 'havana']::text[], 'CUBA._VINALES_(8).jpg'),
    ('mural-prehistory', 'vinales', 'ENTERTAINMENT', 1, 'HOURS', 4.3, 'Мураль де ла Преистория', 'Mural de la Prehistoria', 'Прехистория муралы', 22.62700000, -83.74600000, 'Mural de la Prehistoria Vinales Cuba', ARRAY['vinales']::text[], ARRAY['vinales']::text[], 'CUBA._VINALES_(8).jpg'),
    ('indian-cave-vinales', 'vinales', 'NATURE', 2, 'HOURS', 4.5, 'Пещера Индио', 'Indian Cave', 'Индио үңгірі', 22.64480000, -83.71170000, 'Cueva del Indio Vinales Cuba', ARRAY['vinales']::text[], ARRAY['vinales']::text[], 'CUBA._VINALES_(8).jpg'),
    ('cayo-jutias', 'vinales', 'BEACH', 6, 'HOURS', 4.7, 'Кайо-Хутиас', 'Cayo Jutias', 'Кайо-Хутиас', 22.69880000, -84.03390000, 'Cayo Jutias Cuba', ARRAY['vinales']::text[], ARRAY['vinales']::text[], 'Varadero-Beach.jpg'),
    ('vinales-tobacco-farms', 'vinales', 'FOOD', 3, 'HOURS', 4.8, 'Табачные фермы Виньялеса', 'Vinales Tobacco Farms', 'Виньялес темекі фермалары', 22.61960000, -83.71190000, 'Vinales tobacco farms Cuba', ARRAY['vinales']::text[], ARRAY['vinales']::text[], 'CUBA._VINALES_(8).jpg'),
    ('los-jazmines-lookout', 'vinales', 'NATURE', 1, 'HOURS', 4.8, 'Смотровая площадка Лос-Хасминес', 'Los Jazmines Lookout', 'Лос-Хасминес көрініс алаңы', 22.61890000, -83.69030000, 'Los Jazmines viewpoint Vinales Cuba', ARRAY['vinales']::text[], ARRAY['vinales']::text[], 'CUBA._VINALES_(8).jpg'),

    ('varadero-beach', 'varadero', 'BEACH', 5, 'HOURS', 4.9, 'Пляж Варадеро', 'Varadero Beach', 'Варадеро жағажайы', 23.15900000, -81.24500000, 'Varadero Beach Cuba', ARRAY['varadero']::text[], ARRAY['varadero', 'havana']::text[], 'Varadero-Beach.jpg'),
    ('josone-park', 'varadero', 'PARK', 2, 'HOURS', 4.6, 'Парк Хосоне', 'Josone Park', 'Хосоне саябағы', 23.14600000, -81.25500000, 'Josone Park Varadero Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('varahicacos-ecological-reserve', 'varadero', 'NATURE', 3, 'HOURS', 4.6, 'Экологический заповедник Вараикакос', 'Varahicacos Ecological Reserve', 'Вараикакос экологиялық қорығы', 23.19900000, -81.14600000, 'Varahicacos Ecological Reserve Varadero Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('ambrosio-cave', 'varadero', 'NATURE', 1, 'HOURS', 4.4, 'Пещера Амбросио', 'Ambrosio Cave', 'Амбросио үңгірі', 23.19200000, -81.15100000, 'Cueva de Ambrosio Varadero Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('saturn-cave', 'matanzas', 'NATURE', 2, 'HOURS', 4.6, 'Пещера Сатурно', 'Saturn Cave', 'Сатурно үңгірі', 23.06100000, -81.46400000, 'Cueva de Saturno Matanzas Cuba', ARRAY['matanzas', 'varadero']::text[], ARRAY['matanzas', 'varadero']::text[], 'Varadero-Beach.jpg'),
    ('bellamar-caves', 'matanzas', 'NATURE', 2, 'HOURS', 4.7, 'Пещеры Бельямар', 'Bellamar Caves', 'Бельямар үңгірлері', 23.02500000, -81.57300000, 'Bellamar Caves Matanzas Cuba', ARRAY['matanzas']::text[], ARRAY['matanzas', 'varadero']::text[], 'Varadero-Beach.jpg'),
    ('varadero-dolphinarium', 'varadero', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Дельфинарий Варадеро', 'Varadero Dolphinarium', 'Варадеро дельфинарийі', 23.18500000, -81.18300000, 'Varadero Dolphinarium Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('xanadu-mansion', 'varadero', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Особняк Ксанаду', 'Xanadu Mansion', 'Ксанаду сарайы', 23.17300000, -81.21500000, 'Xanadu Mansion Varadero Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('plaza-america-varadero', 'varadero', 'SHOPPING', 2, 'HOURS', 4.2, 'Торговый центр Пласа Америка', 'Plaza America Varadero', 'Пласа Америка сауда орталығы', 23.17600000, -81.21400000, 'Plaza America Varadero Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('varadero-craft-market', 'varadero', 'MARKET', 2, 'HOURS', 4.4, 'Ремесленный рынок Варадеро', 'Varadero Craft Market', 'Варадеро қолөнер базары', 23.14600000, -81.26400000, 'Varadero craft market Cuba', ARRAY['varadero']::text[], ARRAY['varadero']::text[], 'Varadero-Beach.jpg'),
    ('sauto-theater', 'matanzas', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Театр Сауто', 'Sauto Theater', 'Сауто театры', 23.04600000, -81.57400000, 'Sauto Theater Matanzas Cuba', ARRAY['matanzas']::text[], ARRAY['matanzas', 'varadero']::text[], 'Varadero-Beach.jpg'),
    ('pharmaceutical-museum-matanzas', 'matanzas', 'MUSEUM', 1, 'HOURS', 4.5, 'Фармацевтический музей Матансаса', 'Pharmaceutical Museum of Matanzas', 'Матансас фармацевтикалық музейі', 23.04700000, -81.57700000, 'Pharmaceutical Museum of Matanzas Cuba', ARRAY['matanzas']::text[], ARRAY['matanzas', 'varadero']::text[], 'Varadero-Beach.jpg'),

    ('bay-of-pigs-museum', 'playa-larga', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей залива Свиней', 'Bay of Pigs Museum', 'Шошқалар шығанағы музейі', 22.06600000, -81.03300000, 'Bay of Pigs Museum Playa Giron Cuba', ARRAY['playa-larga']::text[], ARRAY['playa-larga', 'varadero']::text[], 'Varadero-Beach.jpg'),
    ('playa-giron', 'playa-larga', 'BEACH', 4, 'HOURS', 4.6, 'Плая-Хирон', 'Playa Giron', 'Плая-Хирон', 21.79400000, -81.17900000, 'Playa Giron Cuba', ARRAY['playa-larga']::text[], ARRAY['playa-larga']::text[], 'Varadero-Beach.jpg'),
    ('cienaga-zapata-national-park', 'playa-larga', 'NATURE', 5, 'HOURS', 4.8, 'Национальный парк Сьенага-де-Сапата', 'Cienaga de Zapata National Park', 'Сьенага-де-Сапата ұлттық паркі', 22.35000000, -81.40000000, 'Cienaga de Zapata National Park Cuba', ARRAY['playa-larga']::text[], ARRAY['playa-larga']::text[], 'Varadero-Beach.jpg'),

    ('cayo-coco-beach', 'cayo-coco', 'BEACH', 5, 'HOURS', 4.8, 'Пляж Кайо-Коко', 'Cayo Coco Beach', 'Кайо-Коко жағажайы', 22.53500000, -78.41800000, 'Cayo Coco Beach Cuba', ARRAY['cayo-coco']::text[], ARRAY['cayo-coco']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('flamenco-beach-cayo-coco', 'cayo-coco', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Фламенко', 'Flamenco Beach', 'Фламенко жағажайы', 22.53500000, -78.41800000, 'Flamenco Beach Cayo Coco Cuba', ARRAY['cayo-coco']::text[], ARRAY['cayo-coco']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('la-cueva-del-jabali', 'cayo-coco', 'ENTERTAINMENT', 3, 'HOURS', 4.3, 'Пещера Хабали', 'La Cueva del Jabali', 'Хабали үңгірі', 22.54000000, -78.32400000, 'La Cueva del Jabali Cayo Coco Cuba', ARRAY['cayo-coco']::text[], ARRAY['cayo-coco']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('cayo-coco-dolphinarium', 'cayo-coco', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Дельфинарий Кайо-Коко', 'Cayo Coco Dolphinarium', 'Кайо-Коко дельфинарийі', 22.54000000, -78.34200000, 'Cayo Coco Dolphinarium Cuba', ARRAY['cayo-coco']::text[], ARRAY['cayo-coco']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('playa-pilar', 'cayo-guillermo', 'BEACH', 5, 'HOURS', 4.9, 'Пляж Пилар', 'Playa Pilar', 'Пилар жағажайы', 22.61200000, -78.70400000, 'Playa Pilar Cayo Guillermo Cuba', ARRAY['cayo-guillermo']::text[], ARRAY['cayo-guillermo', 'cayo-coco']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('pilar-dunes', 'cayo-guillermo', 'NATURE', 2, 'HOURS', 4.7, 'Дюны Пилар', 'Pilar Dunes', 'Пилар құм төбелері', 22.61000000, -78.70000000, 'Pilar Dunes Cayo Guillermo Cuba', ARRAY['cayo-guillermo']::text[], ARRAY['cayo-guillermo']::text[], 'Cuba_-_Cayo_Coco.jpg'),
    ('cayo-santa-maria-beach', 'cayo-santa-maria', 'BEACH', 5, 'HOURS', 4.8, 'Пляж Кайо-Санта-Мария', 'Cayo Santa Maria Beach', 'Кайо-Санта-Мария жағажайы', 22.66600000, -79.04700000, 'Cayo Santa Maria Beach Cuba', ARRAY['cayo-santa-maria']::text[], ARRAY['cayo-santa-maria', 'santa-clara']::text[], 'Varadero-Beach.jpg'),
    ('perla-blanca-beach', 'cayo-santa-maria', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Перла-Бланка', 'Perla Blanca Beach', 'Перла-Бланка жағажайы', 22.66400000, -78.94400000, 'Perla Blanca Beach Cayo Santa Maria Cuba', ARRAY['cayo-santa-maria']::text[], ARRAY['cayo-santa-maria']::text[], 'Varadero-Beach.jpg'),
    ('pueblo-la-estrella', 'cayo-santa-maria', 'SHOPPING', 2, 'HOURS', 4.2, 'Туристическая площадь Ла-Эстрелья', 'Pueblo La Estrella', 'Ла-Эстрелья туристік алаңы', 22.65600000, -79.01900000, 'Pueblo La Estrella Cayo Santa Maria Cuba', ARRAY['cayo-santa-maria']::text[], ARRAY['cayo-santa-maria']::text[], 'Varadero-Beach.jpg'),

    ('trinidad-historic-center', 'trinidad', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Исторический центр Тринидада', 'Trinidad Historic Center', 'Тринидад тарихи орталығы', 21.80200000, -79.98400000, 'Trinidad Historic Center Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('plaza-mayor-trinidad', 'trinidad', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Майор Тринидада', 'Plaza Mayor Trinidad', 'Тринидад Майор алаңы', 21.80420000, -79.98400000, 'Plaza Mayor Trinidad Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('museo-romantico-trinidad', 'trinidad', 'MUSEUM', 1, 'HOURS', 4.5, 'Романтический музей Тринидада', 'Museo Romantico Trinidad', 'Тринидад романтикалық музейі', 21.80420000, -79.98380000, 'Museo Romantico Trinidad Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('valle-de-los-ingenios', 'trinidad', 'NATURE', 4, 'HOURS', 4.8, 'Долина сахарных заводов', 'Valle de los Ingenios', 'Қант зауыттары аңғары', 21.80800000, -79.87000000, 'Valle de los Ingenios Trinidad Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('playa-ancon', 'trinidad', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Анкон', 'Playa Ancon', 'Анкон жағажайы', 21.73450000, -80.01980000, 'Playa Ancon Trinidad Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Varadero-Beach.jpg'),
    ('topes-de-collantes', 'trinidad', 'NATURE', 5, 'HOURS', 4.8, 'Топес-де-Кольянтес', 'Topes de Collantes', 'Топес-де-Кольянтес', 21.91300000, -80.02100000, 'Topes de Collantes Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('casa-musica-trinidad', 'trinidad', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Дом музыки Тринидада', 'Casa de la Musica Trinidad', 'Тринидад музыка үйі', 21.80460000, -79.98380000, 'Casa de la Musica Trinidad Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('trinidad-craft-market', 'trinidad', 'MARKET', 2, 'HOURS', 4.4, 'Ремесленный рынок Тринидада', 'Trinidad Craft Market', 'Тринидад қолөнер базары', 21.80400000, -79.98450000, 'Trinidad craft market Cuba', ARRAY['trinidad']::text[], ARRAY['trinidad']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),

    ('cienfuegos-historic-center', 'cienfuegos', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Исторический центр Сьенфуэгоса', 'Cienfuegos Historic Center', 'Сьенфуэгос тарихи орталығы', 22.14590000, -80.45220000, 'Cienfuegos Historic Center Cuba', ARRAY['cienfuegos']::text[], ARRAY['cienfuegos']::text[], 'DirkvdM_cienfuegos_palacio_de_valle.jpg'),
    ('palacio-de-valle', 'cienfuegos', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Паласио-де-Валье', 'Palacio de Valle', 'Валье сарайы', 22.12130000, -80.45170000, 'Palacio de Valle Cienfuegos Cuba', ARRAY['cienfuegos']::text[], ARRAY['cienfuegos']::text[], 'DirkvdM_cienfuegos_palacio_de_valle.jpg'),
    ('jose-marti-park-cienfuegos', 'cienfuegos', 'PARK', 1, 'HOURS', 4.7, 'Парк Хосе Марти в Сьенфуэгосе', 'Jose Marti Park Cienfuegos', 'Сьенфуэгос Хосе Марти саябағы', 22.14570000, -80.45260000, 'Jose Marti Park Cienfuegos Cuba', ARRAY['cienfuegos']::text[], ARRAY['cienfuegos']::text[], 'DirkvdM_cienfuegos_palacio_de_valle.jpg'),
    ('tomas-terry-theater', 'cienfuegos', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Театр Томаса Терри', 'Tomas Terry Theater', 'Томас Терри театры', 22.14570000, -80.45310000, 'Tomas Terry Theater Cienfuegos Cuba', ARRAY['cienfuegos']::text[], ARRAY['cienfuegos']::text[], 'DirkvdM_cienfuegos_palacio_de_valle.jpg'),
    ('paseo-del-prado-cienfuegos', 'cienfuegos', 'PARK', 1, 'HOURS', 4.5, 'Бульвар Прадо в Сьенфуэгосе', 'Paseo del Prado Cienfuegos', 'Сьенфуэгос Прадо бульвары', 22.14600000, -80.44570000, 'Paseo del Prado Cienfuegos Cuba', ARRAY['cienfuegos']::text[], ARRAY['cienfuegos']::text[], 'DirkvdM_cienfuegos_palacio_de_valle.jpg'),

    ('che-guevara-mausoleum', 'santa-clara', 'MUSEUM', 2, 'HOURS', 4.8, 'Мавзолей Че Гевары', 'Che Guevara Mausoleum', 'Че Гевара мавзолейі', 22.40260000, -79.97940000, 'Che Guevara Mausoleum Santa Clara Cuba', ARRAY['santa-clara']::text[], ARRAY['santa-clara']::text[], 'Che_Guevara_Mausoleum_Santa_Clara_Cuba.jpg'),
    ('armored-train-monument', 'santa-clara', 'MUSEUM', 1, 'HOURS', 4.6, 'Памятник бронепоезду', 'Armored Train Monument', 'Бронепойыз ескерткіші', 22.41090000, -79.96010000, 'Armored Train Monument Santa Clara Cuba', ARRAY['santa-clara']::text[], ARRAY['santa-clara']::text[], 'Che_Guevara_Mausoleum_Santa_Clara_Cuba.jpg'),
    ('leoncio-vidal-park', 'santa-clara', 'PARK', 1, 'HOURS', 4.5, 'Парк Леонсио Видаль', 'Leoncio Vidal Park', 'Леонсио Видаль саябағы', 22.40610000, -79.96580000, 'Leoncio Vidal Park Santa Clara Cuba', ARRAY['santa-clara']::text[], ARRAY['santa-clara']::text[], 'Che_Guevara_Mausoleum_Santa_Clara_Cuba.jpg'),

    ('camaguey-historic-center', 'camaguey', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Исторический центр Камагуэя', 'Camaguey Historic Center', 'Камагуэй тарихи орталығы', 21.38080000, -77.91690000, 'Camaguey Historic Center Cuba', ARRAY['camaguey']::text[], ARRAY['camaguey']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('plaza-san-juan-de-dios', 'camaguey', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Площадь Сан-Хуан-де-Диос', 'Plaza San Juan de Dios', 'Сан-Хуан-де-Диос алаңы', 21.38140000, -77.91940000, 'Plaza San Juan de Dios Camaguey Cuba', ARRAY['camaguey']::text[], ARRAY['camaguey']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('casino-campestre', 'camaguey', 'PARK', 2, 'HOURS', 4.5, 'Парк Касино Кампестре', 'Casino Campestre', 'Касино Кампестре саябағы', 21.38700000, -77.92700000, 'Casino Campestre Camaguey Cuba', ARRAY['camaguey']::text[], ARRAY['camaguey']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),
    ('camaguey-market', 'camaguey', 'MARKET', 2, 'HOURS', 4.2, 'Рынок Камагуэя', 'Camaguey Market', 'Камагуэй базары', 21.38100000, -77.91800000, 'Camaguey market Cuba', ARRAY['camaguey']::text[], ARRAY['camaguey']::text[], 'Plaza_Mayor,_Trinidad,_Cuba.jpg'),

    ('castillo-del-morro-santiago', 'santiago-de-cuba', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Крепость дель Морро в Сантьяго-де-Куба', 'Castillo del Morro', 'Сантьягодағы дель Морро қамалы', 19.96610000, -75.87030000, 'Castillo del Morro Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('parque-cespedes', 'santiago-de-cuba', 'PARK', 1, 'HOURS', 4.6, 'Парк Сеспедес', 'Parque Cespedes', 'Сеспедес саябағы', 20.02080000, -75.82940000, 'Parque Cespedes Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('casa-de-la-trova-santiago', 'santiago-de-cuba', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Каса-де-ла-Трова', 'Casa de la Trova', 'Трова үйі', 20.02060000, -75.82980000, 'Casa de la Trova Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('santa-ifigenia-cemetery', 'santiago-de-cuba', 'MUSEUM', 2, 'HOURS', 4.8, 'Кладбище Санта-Ифигения', 'Santa Ifigenia Cemetery', 'Санта-Ифигения зираты', 20.02700000, -75.84900000, 'Santa Ifigenia Cemetery Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('cuartel-moncada-museum', 'santiago-de-cuba', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей казарм Монкада', 'Cuartel Moncada Museum', 'Монкада казармалары музейі', 20.02450000, -75.80780000, 'Cuartel Moncada Museum Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('basilica-del-cobre', 'santiago-de-cuba', 'TEMPLE', 2, 'HOURS', 4.8, 'Базилика Эль-Кобре', 'Basilica del Cobre', 'Эль-Кобре базиликасы', 20.04830000, -75.94560000, 'Basilica del Cobre Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('baconao-park', 'santiago-de-cuba', 'PARK', 4, 'HOURS', 4.4, 'Парк Баконао', 'Baconao Park', 'Баконао саябағы', 19.90000000, -75.50000000, 'Baconao Park Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('gran-piedra', 'santiago-de-cuba', 'NATURE', 4, 'HOURS', 4.7, 'Гран-Пьедра', 'Gran Piedra', 'Гран-Пьедра', 20.01300000, -75.62600000, 'Gran Piedra Santiago de Cuba', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),
    ('santiago-market', 'santiago-de-cuba', 'MARKET', 2, 'HOURS', 4.3, 'Рынок Сантьяго-де-Куба', 'Santiago de Cuba Market', 'Сантьяго-де-Куба базары', 20.02100000, -75.82900000, 'Santiago de Cuba market', ARRAY['santiago-de-cuba']::text[], ARRAY['santiago-de-cuba']::text[], 'Castillo_del_Morro,_Santiago_de_Cuba_01.jpg'),

    ('loma-de-la-cruz', 'holguin', 'NATURE', 2, 'HOURS', 4.7, 'Лома-де-ла-Крус', 'Loma de la Cruz', 'Лома-де-ла-Крус', 20.89910000, -76.25740000, 'Loma de la Cruz Holguin Cuba', ARRAY['holguin']::text[], ARRAY['holguin']::text[], 'Loma_de_la_Cruz.jpg'),
    ('calixto-garcia-park', 'holguin', 'PARK', 1, 'HOURS', 4.5, 'Парк Каликсто Гарсия', 'Calixto Garcia Park', 'Каликсто Гарсия саябағы', 20.88730000, -76.26360000, 'Calixto Garcia Park Holguin Cuba', ARRAY['holguin']::text[], ARRAY['holguin']::text[], 'Loma_de_la_Cruz.jpg'),
    ('guardalavaca-beach', 'guardalavaca', 'BEACH', 5, 'HOURS', 4.7, 'Пляж Гуардалавака', 'Guardalavaca Beach', 'Гуардалавака жағажайы', 21.12270000, -75.83170000, 'Guardalavaca Beach Cuba', ARRAY['guardalavaca']::text[], ARRAY['guardalavaca', 'holguin']::text[], 'Varadero-Beach.jpg'),
    ('bahia-de-naranjo', 'guardalavaca', 'NATURE', 4, 'HOURS', 4.6, 'Бухта Наранхо', 'Bahia de Naranjo', 'Наранхо шығанағы', 21.09000000, -75.76000000, 'Bahia de Naranjo Guardalavaca Cuba', ARRAY['guardalavaca']::text[], ARRAY['guardalavaca', 'holguin']::text[], 'Varadero-Beach.jpg'),
    ('chorro-de-maita-museum', 'guardalavaca', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Чорро-де-Маита', 'Chorro de Maita Museum', 'Чорро-де-Маита музейі', 21.11000000, -75.93000000, 'Chorro de Maita Museum Cuba', ARRAY['guardalavaca']::text[], ARRAY['guardalavaca', 'holguin']::text[], 'Varadero-Beach.jpg'),

    ('baracoa-cathedral', 'baracoa', 'TEMPLE', 1, 'HOURS', 4.5, 'Собор Богоматери в Баракоа', 'Our Lady of the Assumption Cathedral', 'Баракоа Богоматерь соборы', 20.34820000, -74.49500000, 'Our Lady of the Assumption Cathedral Baracoa Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Baracoa_-_El_Yunque.jpg'),
    ('baracoa-malecon', 'baracoa', 'PARK', 1, 'HOURS', 4.5, 'Набережная Баракоа', 'Baracoa Malecon', 'Баракоа жағалауы', 20.34890000, -74.50130000, 'Baracoa Malecon Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Baracoa_-_El_Yunque.jpg'),
    ('el-yunque', 'baracoa', 'NATURE', 5, 'HOURS', 4.8, 'Гора Эль-Юнке', 'El Yunque', 'Эль-Юнке тауы', 20.34500000, -74.57100000, 'El Yunque Baracoa Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Baracoa_-_El_Yunque.jpg'),
    ('yumuri-canyon', 'baracoa', 'NATURE', 4, 'HOURS', 4.7, 'Каньон Юмури', 'Yumuri Canyon', 'Юмури каньоны', 20.34700000, -74.35000000, 'Yumuri Canyon Baracoa Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Baracoa_-_El_Yunque.jpg'),
    ('maguana-beach', 'baracoa', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Магуана', 'Maguana Beach', 'Магуана жағажайы', 20.46100000, -74.47400000, 'Maguana Beach Baracoa Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Varadero-Beach.jpg'),
    ('cueva-paraiso-museum', 'baracoa', 'MUSEUM', 2, 'HOURS', 4.4, 'Археологический музей Куэва-дель-Параисо', 'Cueva del Paraiso Museum', 'Куэва-дель-Параисо музейі', 20.35000000, -74.49500000, 'Cueva del Paraiso Museum Baracoa Cuba', ARRAY['baracoa']::text[], ARRAY['baracoa']::text[], 'Baracoa_-_El_Yunque.jpg');

CREATE TEMP TABLE seed_cuba_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-cuba-place:' || seed.slug) AS place_hash,
        md5('id-cuba-media:' || seed.slug) AS media_hash
    FROM seed_cuba_priority_places seed
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
    ARRAY['cuba', city_id, slug, lower(category), 'cuba-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Кубы: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Cuba tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Куба туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'CU',
    city_id,
    category,
    NULL::numeric,
    'CUP',
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
FROM seed_cuba_resolved_places
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
FROM seed_cuba_resolved_places
UNION ALL
SELECT
    id,
    'en',
    title_en,
    description_en,
    NOW(),
    NOW()
FROM seed_cuba_resolved_places
UNION ALL
SELECT
    id,
    'kk',
    title_kk,
    description_kk,
    NOW(),
    NOW()
FROM seed_cuba_resolved_places
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
FROM seed_cuba_resolved_places seed
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
FROM seed_cuba_resolved_places
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
    'CU',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_cuba_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'CU',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_cuba_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_cuba_resolved_places;
DROP TABLE IF EXISTS seed_cuba_priority_places;
