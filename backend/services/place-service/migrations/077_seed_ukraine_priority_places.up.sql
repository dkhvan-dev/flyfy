-- Priority Ukraine destination places seed.
-- The seed covers large city anchors, western heritage routes, Black Sea destinations, Carpathian resort points, malls, markets, parks, museums, beaches, and family places.

DROP TABLE IF EXISTS seed_ukraine_resolved_places;
DROP TABLE IF EXISTS seed_ukraine_priority_places;

CREATE TEMP TABLE seed_ukraine_priority_places (
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
    media_file text NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_ukraine_priority_places (
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
    media_file,
    extra_tags
) VALUES
    ('saint-sophia-cathedral-kyiv', 'kyiv', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'София Киевская', 'Saint Sophia Cathedral Kyiv', 'Киев София соборы', 50.45290000, 30.51440000, 'Saint Sophia Cathedral Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Saint_Sophia_Cathedral_Kyiv.jpg', ARRAY['unesco', 'old-kyiv']::text[]),
    ('kyiv-pechersk-lavra', 'kyiv', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Киево-Печерская лавра', 'Kyiv Pechersk Lavra', 'Киев-Печерск лаврасы', 50.43470000, 30.55730000, 'Kyiv Pechersk Lavra Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Kyiv_Pechersk_Lavra.jpg', ARRAY['unesco', 'monastery']::text[]),
    ('golden-gate-kyiv', 'kyiv', 'MUSEUM', 1, 'HOURS', 4.7, 'Золотые ворота Киева', 'Golden Gate Kyiv', 'Киев Алтын қақпасы', 50.44890000, 30.51330000, 'Golden Gate Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Golden_Gate_Kyiv.jpg', ARRAY['old-kyiv', 'museum']::text[]),
    ('andriyivskyi-descent', 'kyiv', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Андреевский спуск', 'Andriyivskyi Descent', 'Андреевский түсуі', 50.45910000, 30.51750000, 'Andriyivskyi Descent Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Andriyivskyi_Descent_Kyiv.jpg', ARRAY['historic-street', 'souvenirs']::text[]),
    ('motherland-monument-war-museum', 'kyiv', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей истории Украины во Второй мировой войне и монумент Родина-Мать', 'National Museum of the History of Ukraine in the Second World War and Motherland Monument', 'Украина Екінші дүниежүзілік соғыс тарихы музейі', 50.42650000, 30.56300000, 'Motherland Monument Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Motherland_Monument_Kyiv.jpg', ARRAY['history', 'viewpoint']::text[]),
    ('mystetskyi-arsenal', 'kyiv', 'MUSEUM', 2, 'HOURS', 4.7, 'Мыстецкий Арсенал', 'Mystetskyi Arsenal', 'Мыстецкий Арсенал', 50.43480000, 30.55730000, 'Mystetskyi Arsenal Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Mystetskyi_Arsenal_Kyiv.jpg', ARRAY['art', 'events']::text[]),
    ('museum-history-kyiv', 'kyiv', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей истории города Киева', 'Museum of the History of Kyiv', 'Киев қаласы тарихы музейі', 50.44530000, 30.51340000, 'Museum of the History of Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Museum_of_the_History_of_Kyiv.jpg', ARRAY['city-history', 'indoor']::text[]),
    ('landscape-alley-kyiv', 'kyiv', 'PARK', 1, 'HOURS', 4.7, 'Пейзажная аллея', 'Landscape Alley Kyiv', 'Киев Пейзаж аллеясы', 50.46020000, 30.51390000, 'Landscape Alley Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Landscape_Alley_Kyiv.jpg', ARRAY['family', 'photo-stop']::text[]),
    ('mariinskyi-park', 'kyiv', 'PARK', 2, 'HOURS', 4.7, 'Мариинский парк', 'Mariinskyi Park', 'Мариинский саябағы', 50.44900000, 30.53900000, 'Mariinskyi Park Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Mariinskyi_Park_Kyiv.jpg', ARRAY['green-space', 'viewpoint']::text[]),
    ('besarabsky-market', 'kyiv', 'MARKET', 1, 'HOURS', 4.5, 'Бессарабский рынок', 'Besarabsky Market', 'Бессараб базары', 50.44240000, 30.52120000, 'Besarabsky Market Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Besarabsky_Market_Kyiv.jpg', ARRAY['covered-market', 'food-market']::text[]),
    ('kyiv-food-market', 'kyiv', 'FOOD', 1, 'HOURS', 4.5, 'Kyiv Food Market', 'Kyiv Food Market', 'Kyiv Food Market', 50.44120000, 30.54600000, 'Kyiv Food Market Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Kyiv_Food_Market.jpg', ARRAY['food-hall', 'evening']::text[]),
    ('tsum-kyiv', 'kyiv', 'SHOPPING', 2, 'HOURS', 4.5, 'ЦУМ Киев', 'TSUM Kyiv', 'Киев ЦУМ', 50.44530000, 30.52230000, 'TSUM Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'TSUM_Kyiv.jpg', ARRAY['department-store', 'central']::text[]),
    ('ocean-plaza-kyiv', 'kyiv', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Ocean Plaza', 'Ocean Plaza Kyiv', 'Ocean Plaza Киев', 50.41170000, 30.52170000, 'Ocean Plaza Kyiv Ukraine', ARRAY['kyiv']::text[], ARRAY['kyiv']::text[], 'Ocean_Plaza_Kyiv.jpg', ARRAY['mall', 'indoor']::text[]),

    ('national-pirogov-estate-museum', 'vinnytsia', 'MUSEUM', 2, 'HOURS', 4.8, 'Национальный музей-усадьба Пирогова', 'National Pirogov Estate Museum', 'Пирогов ұлттық музей-усадьбасы', 49.21700000, 28.40200000, 'National Pirogov Estate Museum Vinnytsia Ukraine', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'National_Pirogov_Estate_Museum.jpg', ARRAY['medicine-history', 'estate']::text[]),
    ('roshen-fountain-vinnytsia', 'vinnytsia', 'ENTERTAINMENT', 1, 'HOURS', 4.7, 'Фонтан Roshen на Южном Буге', 'Roshen Fountain on the Pivdennyi Buh', 'Roshen фонтаны', 49.23200000, 28.48700000, 'Roshen Fountain Vinnytsia Ukraine', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'Roshen_Fountain_Vinnytsia.jpg', ARRAY['seasonal', 'evening-show']::text[]),
    ('leontovych-park-vinnytsia', 'vinnytsia', 'PARK', 2, 'HOURS', 4.6, 'Центральный городской парк им. Леонтовича', 'Mykola Leontovych Central City Park', 'Леонтович орталық саябағы', 49.23500000, 28.46400000, 'Mykola Leontovych Central City Park Vinnytsia', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'Leontovych_Park_Vinnytsia.jpg', ARRAY['green-space', 'family']::text[]),
    ('vinnytsia-water-tower', 'vinnytsia', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Винницкая водонапорная башня', 'Vinnytsia Water Tower', 'Винница су мұнарасы', 49.23300000, 28.46800000, 'Vinnytsia Water Tower Ukraine', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'Vinnytsia_Water_Tower.jpg', ARRAY['city-symbol', 'viewpoint']::text[]),
    ('podilskyi-zoo', 'vinnytsia', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Подольский зоопарк', 'Podilskyi Zoo', 'Подольский зообағы', 49.26300000, 28.52700000, 'Podilskyi Zoo Vinnytsia Ukraine', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'Podilskyi_Zoo_Vinnytsia.jpg', ARRAY['family', 'wildlife']::text[]),
    ('museum-transport-models-vinnytsia', 'vinnytsia', 'MUSEUM', 1, 'HOURS', 4.7, 'Музей моделей транспорта', 'Museum of Transport Models', 'Көлік модельдері музейі', 49.23300000, 28.46900000, 'Museum of Transport Models Vinnytsia Ukraine', ARRAY['vinnytsia']::text[], ARRAY['vinnytsia']::text[], 'Museum_of_Transport_Models_Vinnytsia.jpg', ARRAY['family', 'technical-museum']::text[]),

    ('cherkasy-regional-museum', 'cherkasy', 'MUSEUM', 2, 'HOURS', 4.6, 'Черкасский областной краеведческий музей', 'Cherkasy Regional Museum of Local Lore', 'Черкассы өлкетану музейі', 49.44500000, 32.06400000, 'Cherkasy Regional Museum of Local Lore Ukraine', ARRAY['cherkasy']::text[], ARRAY['cherkasy']::text[], 'Cherkasy_Regional_Museum.jpg', ARRAY['regional-history', 'indoor']::text[]),
    ('hill-of-glory-cherkasy', 'cherkasy', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Холм Славы / Замковая гора', 'Hill of Glory and Castle Hill Cherkasy', 'Черкассы Даңқ төбесі', 49.44500000, 32.06500000, 'Hill of Glory Cherkasy Ukraine', ARRAY['cherkasy']::text[], ARRAY['cherkasy']::text[], 'Hill_of_Glory_Cherkasy.jpg', ARRAY['viewpoint', 'memorial']::text[]),
    ('sosnovyi-bir-park', 'cherkasy', 'PARK', 2, 'HOURS', 4.7, 'Парк Сосновый бор', 'Sosnovyi Bir Park', 'Сосновый бор саябағы', 49.47200000, 32.04800000, 'Sosnovyi Bir Park Cherkasy Ukraine', ARRAY['cherkasy']::text[], ARRAY['cherkasy']::text[], 'Sosnovyi_Bir_Park_Cherkasy.jpg', ARRAY['green-space', 'family']::text[]),
    ('rose-valley-cherkasy', 'cherkasy', 'PARK', 1, 'HOURS', 4.5, 'Долина роз', 'Rose Valley Park Cherkasy', 'Раушан аңғары', 49.43900000, 32.07900000, 'Rose Valley Cherkasy Ukraine', ARRAY['cherkasy']::text[], ARRAY['cherkasy']::text[], 'Rose_Valley_Cherkasy.jpg', ARRAY['riverside', 'walk']::text[]),
    ('cherkasy-zoo', 'cherkasy', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Черкасский зоопарк', 'Cherkasy Zoo', 'Черкассы зообағы', 49.41600000, 32.01300000, 'Cherkasy Zoo Ukraine', ARRAY['cherkasy']::text[], ARRAY['cherkasy']::text[], 'Cherkasy_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),

    ('sofiyivka-park-uman', 'uman', 'PARK', 4, 'HOURS', 4.9, 'Национальный дендрологический парк Софиевка', 'Sofiyivka Park Uman', 'Софиевка дендрологиялық саябағы', 48.76200000, 30.23400000, 'Sofiyivka Park Uman Ukraine', ARRAY['uman']::text[], ARRAY['uman', 'kyiv']::text[], 'Sofiyivka_Park_Uman.jpg', ARRAY['dendropark', 'garden']::text[]),
    ('nova-sofiyivka', 'uman', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Фэнтези-парк Новая Софиевка', 'Nova Sofiyivka Fantasy Park', 'Жаңа Софиевка фэнтези паркі', 48.76000000, 30.23500000, 'Nova Sofiyivka Uman Ukraine', ARRAY['uman']::text[], ARRAY['uman']::text[], 'Nova_Sofiyivka_Uman.jpg', ARRAY['family', 'seasonal']::text[]),
    ('rabbi-nachman-tomb', 'uman', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Могила цадика Рабби Нахмана', 'Rabbi Nachman Tomb', 'Рабби Нахман қабірі', 48.74700000, 30.23400000, 'Rabbi Nachman Tomb Uman Ukraine', ARRAY['uman']::text[], ARRAY['uman']::text[], 'Rabbi_Nachman_Tomb_Uman.jpg', ARRAY['pilgrimage', 'religion']::text[]),
    ('old-uman-reserve', 'uman', 'ARCHITECTURE', 2, 'HOURS', 4.4, 'Заповедник Старая Умань', 'Old Uman Historical and Architectural Reserve', 'Ескі Умань қорығы', 48.74900000, 30.22100000, 'Old Uman Historical Architectural Reserve Ukraine', ARRAY['uman']::text[], ARRAY['uman']::text[], 'Old_Uman_Reserve.jpg', ARRAY['historic-center', 'walk']::text[]),
    ('pearl-of-love-fountain', 'uman', 'ENTERTAINMENT', 1, 'HOURS', 4.5, 'Светомузыкальный фонтан Перлина кохання', 'Pearl of Love Music and Light Fountain', 'Махаббат маржаны фонтаны', 48.74700000, 30.21900000, 'Pearl of Love Fountain Uman Ukraine', ARRAY['uman']::text[], ARRAY['uman']::text[], 'Pearl_of_Love_Fountain_Uman.jpg', ARRAY['evening-show', 'seasonal']::text[]),
    ('uman-central-market', 'uman', 'MARKET', 1, 'HOURS', 4.2, 'Центральный рынок Умани', 'Uman Central Market', 'Умань орталық базары', 48.74800000, 30.22200000, 'Uman Central Market Ukraine', ARRAY['uman']::text[], ARRAY['uman']::text[], 'Uman_Central_Market.jpg', ARRAY['local-market', 'food-market']::text[]),

    ('poltava-local-lore-museum', 'poltava', 'MUSEUM', 2, 'HOURS', 4.7, 'Полтавский краеведческий музей им. Василия Кричевского', 'Poltava Museum of Local Lore named after Vasyl Krychevsky', 'Полтава өлкетану музейі', 49.58800000, 34.55600000, 'Poltava Museum of Local Lore Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'Poltava_Local_Lore_Museum.jpg', ARRAY['regional-history', 'architecture']::text[]),
    ('korpusnyi-garden', 'poltava', 'PARK', 1, 'HOURS', 4.6, 'Корпусный сад / Круглая площадь', 'Korpusnyi Garden and Round Square', 'Корпус бағы', 49.59100000, 34.55000000, 'Korpusnyi Garden Poltava Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'Korpusnyi_Garden_Poltava.jpg', ARRAY['central-square', 'walk']::text[]),
    ('white-arbor-poltava', 'poltava', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Белая беседка / Иванова гора', 'White Arbor and Ivanova Hill', 'Ақ ротонда', 49.58400000, 34.56900000, 'White Arbor Poltava Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'White_Arbor_Poltava.jpg', ARRAY['viewpoint', 'city-symbol']::text[]),
    ('poltava-art-museum', 'poltava', 'MUSEUM', 1, 'HOURS', 4.5, 'Полтавский художественный музей им. Ярошенко', 'Poltava Art Museum named after Mykola Yaroshenko', 'Полтава өнер музейі', 49.59000000, 34.55200000, 'Poltava Art Museum Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'Poltava_Art_Museum.jpg', ARRAY['art', 'indoor']::text[]),
    ('battle-of-poltava-museum', 'poltava', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей истории Полтавской битвы', 'Museum of the History of the Battle of Poltava', 'Полтава шайқасы тарихы музейі', 49.63700000, 34.55200000, 'Museum of the History of the Battle of Poltava Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'Battle_of_Poltava_Museum.jpg', ARRAY['military-history', 'indoor']::text[]),
    ('kotlyarevsky-estate-museum', 'poltava', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей-усадьба Ивана Котляревского', 'Ivan Kotlyarevsky Estate Museum', 'Иван Котляревский музей-усадьбасы', 49.58400000, 34.56800000, 'Ivan Kotlyarevsky Estate Museum Poltava Ukraine', ARRAY['poltava']::text[], ARRAY['poltava']::text[], 'Kotlyarevsky_Estate_Museum.jpg', ARRAY['literary', 'heritage']::text[]),

    ('rynok-square-lviv', 'lviv', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Площадь Рынок во Львове', 'Rynok Square Lviv', 'Львов Рынок алаңы', 49.84200000, 24.03200000, 'Rynok Square Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Rynok_Square_Lviv.jpg', ARRAY['unesco', 'old-town']::text[]),
    ('lviv-national-opera', 'lviv', 'ENTERTAINMENT', 2, 'HOURS', 4.9, 'Львовская опера', 'Lviv National Opera', 'Львов ұлттық операсы', 49.84400000, 24.02600000, 'Lviv National Opera Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Lviv_National_Opera.jpg', ARRAY['theater', 'architecture']::text[]),
    ('lviv-high-castle-park', 'lviv', 'PARK', 2, 'HOURS', 4.7, 'Парк Высокий Замок', 'Lviv High Castle Park', 'Львов Биік қамал саябағы', 49.84900000, 24.03900000, 'Lviv High Castle Park Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Lviv_High_Castle_Park.jpg', ARRAY['viewpoint', 'green-space']::text[]),
    ('lychakiv-cemetery', 'lviv', 'MUSEUM', 2, 'HOURS', 4.8, 'Лычаковское кладбище', 'Lychakiv Cemetery', 'Лычаков зираты', 49.83200000, 24.05600000, 'Lychakiv Cemetery Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Lychakiv_Cemetery_Lviv.jpg', ARRAY['heritage', 'memorial']::text[]),
    ('shevchenkivskyi-hai', 'lviv', 'MUSEUM', 2, 'HOURS', 4.7, 'Шевченковский гай', 'Shevchenkivskyi Hai Open-Air Museum', 'Шевченковский гай ашық аспан музейі', 49.84400000, 24.06400000, 'Shevchenkivskyi Hai Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Shevchenkivskyi_Hai_Lviv.jpg', ARRAY['open-air-museum', 'folk-architecture']::text[]),
    ('potocki-palace-lviv', 'lviv', 'MUSEUM', 1, 'HOURS', 4.6, 'Дворец Потоцких во Львове', 'Potocki Palace Lviv', 'Львов Потоцкий сарайы', 49.83900000, 24.02700000, 'Potocki Palace Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Potocki_Palace_Lviv.jpg', ARRAY['palace', 'art']::text[]),
    ('museum-arsenal-lviv', 'lviv', 'MUSEUM', 1, 'HOURS', 4.6, 'Музей-Арсенал', 'Museum-Arsenal Lviv', 'Львов Арсенал музейі', 49.84100000, 24.03600000, 'Museum Arsenal Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Museum_Arsenal_Lviv.jpg', ARRAY['history', 'indoor']::text[]),
    ('vernissage-lviv', 'lviv', 'MARKET', 1, 'HOURS', 4.5, 'Вернисаж во Львове', 'Vernissage Art and Souvenir Market', 'Львов Вернисаж базары', 49.84400000, 24.02900000, 'Vernissage Market Lviv Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Vernissage_Lviv.jpg', ARRAY['souvenir-market', 'crafts']::text[]),
    ('forum-lviv', 'lviv', 'SHOPPING', 2, 'HOURS', 4.5, 'ТРЦ Forum Lviv', 'Forum Lviv Mall', 'Forum Lviv сауда орталығы', 49.84900000, 24.02300000, 'Forum Lviv Mall Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Forum_Lviv.jpg', ARRAY['mall', 'indoor']::text[]),
    ('lviv-food-market', 'lviv', 'FOOD', 1, 'HOURS', 4.5, 'Львовский городской фуд-маркет', 'Lviv City Food Market', 'Львов қалалық фуд-маркеті', 49.84200000, 24.03100000, 'Lviv City Food Market Ukraine', ARRAY['lviv']::text[], ARRAY['lviv']::text[], 'Lviv_City_Food_Market.jpg', ARRAY['food-hall', 'evening']::text[]),

    ('bukovinian-metropolitans-residence', 'chernivtsi', 'ARCHITECTURE', 2, 'HOURS', 4.9, 'Резиденция митрополитов Буковины и Далмации', 'Residence of Bukovinian and Dalmatian Metropolitans', 'Буковина және Далмация митрополиттері резиденциясы', 48.29700000, 25.92500000, 'Residence of Bukovinian and Dalmatian Metropolitans Chernivtsi Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Residence_of_Bukovinian_and_Dalmatian_Metropolitans.jpg', ARRAY['unesco', 'university']::text[]),
    ('olha-kobylianska-street', 'chernivtsi', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Улица Ольги Кобылянской', 'Olha Kobylianska Street', 'Ольга Кобылянская көшесі', 48.29100000, 25.93600000, 'Olha Kobylianska Street Chernivtsi Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Olha_Kobylianska_Street_Chernivtsi.jpg', ARRAY['pedestrian-street', 'historic-center']::text[]),
    ('theatre-square-chernivtsi', 'chernivtsi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Театральная площадь Черновцов', 'Theatre Square Chernivtsi', 'Черновцы театр алаңы', 48.29200000, 25.93400000, 'Theatre Square Chernivtsi Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Theatre_Square_Chernivtsi.jpg', ARRAY['square', 'architecture']::text[]),
    ('chernivtsi-art-museum', 'chernivtsi', 'MUSEUM', 1, 'HOURS', 4.6, 'Черновицкий художественный музей', 'Chernivtsi Art Museum', 'Черновцы өнер музейі', 48.29100000, 25.93700000, 'Chernivtsi Art Museum Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Chernivtsi_Art_Museum.jpg', ARRAY['art', 'indoor']::text[]),
    ('chernivtsi-open-air-museum', 'chernivtsi', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей народной архитектуры и быта в Черновцах', 'Chernivtsi Open-Air Folk Architecture Museum', 'Черновцы халық сәулеті музейі', 48.25400000, 25.96400000, 'Chernivtsi Open-Air Folk Architecture Museum Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Chernivtsi_Open_Air_Museum.jpg', ARRAY['open-air-museum', 'folk-architecture']::text[]),
    ('shevchenko-park-chernivtsi', 'chernivtsi', 'PARK', 2, 'HOURS', 4.5, 'Центральный парк им. Шевченко в Черновцах', 'Shevchenko Central Park Chernivtsi', 'Черновцы Шевченко саябағы', 48.28400000, 25.92200000, 'Shevchenko Central Park Chernivtsi Ukraine', ARRAY['chernivtsi']::text[], ARRAY['chernivtsi']::text[], 'Shevchenko_Park_Chernivtsi.jpg', ARRAY['green-space', 'family']::text[]),

    ('ivano-frankivsk-town-hall', 'ivano-frankivsk', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Ратуша Ивано-Франковска', 'Ivano-Frankivsk Town Hall', 'Ивано-Франковск ратушасы', 48.92300000, 24.71100000, 'Ivano-Frankivsk Town Hall Ukraine', ARRAY['ivano-frankivsk']::text[], ARRAY['ivano-frankivsk']::text[], 'Ivano_Frankivsk_Town_Hall.jpg', ARRAY['city-symbol', 'viewpoint']::text[]),
    ('bastion-ivano-frankivsk', 'ivano-frankivsk', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Бастион в Ивано-Франковске', 'Bastion Gallery and Fortification', 'Ивано-Франковск Бастион галереясы', 48.92200000, 24.71400000, 'Bastion Ivano-Frankivsk Ukraine', ARRAY['ivano-frankivsk']::text[], ARRAY['ivano-frankivsk']::text[], 'Bastion_Ivano_Frankivsk.jpg', ARRAY['fortification', 'gallery']::text[]),
    ('shevchenko-park-city-lake-ivano-frankivsk', 'ivano-frankivsk', 'PARK', 2, 'HOURS', 4.6, 'Парк Шевченко и городское озеро', 'Shevchenko Park and City Lake Ivano-Frankivsk', 'Шевченко саябағы және қала көлі', 48.91400000, 24.70100000, 'Shevchenko Park City Lake Ivano-Frankivsk Ukraine', ARRAY['ivano-frankivsk']::text[], ARRAY['ivano-frankivsk']::text[], 'Shevchenko_Park_Ivano_Frankivsk.jpg', ARRAY['lake', 'green-space']::text[]),
    ('stometrivka-promenade', 'ivano-frankivsk', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Стометровка', 'Nezalezhnosti Street Promenade', 'Тәуелсіздік көшесі серуені', 48.92200000, 24.70900000, 'Nezalezhnosti Street Ivano-Frankivsk Ukraine', ARRAY['ivano-frankivsk']::text[], ARRAY['ivano-frankivsk']::text[], 'Stometrivka_Ivano_Frankivsk.jpg', ARRAY['pedestrian-street', 'central']::text[]),

    ('probiy-waterfall', 'yaremche', 'NATURE', 2, 'HOURS', 4.8, 'Водопад Пробий', 'Probiy Waterfall', 'Пробий сарқырамасы', 48.44000000, 24.54000000, 'Probiy Waterfall Yaremche Ukraine', ARRAY['yaremche']::text[], ARRAY['ivano-frankivsk', 'yaremche']::text[], 'Probiy_Waterfall_Yaremche.jpg', ARRAY['waterfall', 'carpathians']::text[]),
    ('yaremche-souvenir-market', 'yaremche', 'MARKET', 1, 'HOURS', 4.5, 'Яремчанский сувенирный рынок', 'Yaremche Souvenir Market', 'Яремче кәдесый базары', 48.44000000, 24.54100000, 'Yaremche Souvenir Market Ukraine', ARRAY['yaremche']::text[], ARRAY['yaremche']::text[], 'Yaremche_Souvenir_Market.jpg', ARRAY['souvenir-market', 'crafts']::text[]),
    ('dovbush-trail-yaremche', 'yaremche', 'NATURE', 3, 'HOURS', 4.7, 'Тропа Довбуша', 'Dovbush Trail', 'Довбуш соқпағы', 48.45200000, 24.53500000, 'Dovbush Trail Yaremche Ukraine', ARRAY['yaremche']::text[], ARRAY['yaremche']::text[], 'Dovbush_Trail_Yaremche.jpg', ARRAY['hiking', 'carpathians']::text[]),
    ('carpathian-nnp-visitor-center', 'yaremche', 'MUSEUM', 1, 'HOURS', 4.4, 'Экотуристический визит-центр Карпатского НПП', 'Carpathian NNP Ecotourism Visitor Center', 'Карпат ұлттық паркі визит-орталығы', 48.44800000, 24.54700000, 'Carpathian NNP Visitor Center Yaremche Ukraine', ARRAY['yaremche']::text[], ARRAY['yaremche']::text[], 'Carpathian_NNP_Visitor_Center.jpg', ARRAY['eco-center', 'nature']::text[]),
    ('bukovel-resort', 'bukovel', 'ENTERTAINMENT', 5, 'HOURS', 4.8, 'Курорт Буковель', 'Bukovel Resort', 'Буковель курорты', 48.35300000, 24.41300000, 'Bukovel Resort Ukraine', ARRAY['bukovel', 'yaremche']::text[], ARRAY['ivano-frankivsk', 'yaremche', 'bukovel']::text[], 'Bukovel_Resort.jpg', ARRAY['ski-resort', 'mountains']::text[]),
    ('lake-of-youth-bukovel', 'bukovel', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Молодости в Буковеле', 'Lake of Youth Bukovel', 'Буковель Жастық көлі', 48.35700000, 24.40600000, 'Lake of Youth Bukovel Ukraine', ARRAY['bukovel']::text[], ARRAY['bukovel']::text[], 'Lake_of_Youth_Bukovel.jpg', ARRAY['lake', 'resort']::text[]),
    ('hutsul-land-ethnopark', 'bukovel', 'MUSEUM', 2, 'HOURS', 4.6, 'Этнопарк Гуцул Ленд', 'Hutsul Land Ethnopark', 'Гуцул Ленд этнопаркі', 48.35500000, 24.40300000, 'Hutsul Land Ethnopark Bukovel Ukraine', ARRAY['bukovel']::text[], ARRAY['bukovel']::text[], 'Hutsul_Land_Ethnopark.jpg', ARRAY['ethnopark', 'family']::text[]),
    ('voda-club-bukovel', 'bukovel', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'VODA club', 'VODA Club Bukovel', 'VODA Club Буковель', 48.35300000, 24.41100000, 'VODA Club Bukovel Ukraine', ARRAY['bukovel']::text[], ARRAY['bukovel']::text[], 'VODA_Club_Bukovel.jpg', ARRAY['wellness', 'pool']::text[]),

    ('uzhhorod-castle', 'uzhhorod', 'MUSEUM', 2, 'HOURS', 4.7, 'Ужгородский замок', 'Uzhhorod Castle', 'Ужгород қамалы', 48.62300000, 22.30500000, 'Uzhhorod Castle Ukraine', ARRAY['uzhhorod']::text[], ARRAY['uzhhorod']::text[], 'Uzhhorod_Castle.jpg', ARRAY['castle', 'museum']::text[]),
    ('linden-alley-uzhhorod', 'uzhhorod', 'PARK', 1, 'HOURS', 4.5, 'Липовая аллея в Ужгороде', 'Linden Alley Uzhhorod', 'Ужгород жөке аллеясы', 48.62500000, 22.29400000, 'Linden Alley Uzhhorod Ukraine', ARRAY['uzhhorod']::text[], ARRAY['uzhhorod']::text[], 'Linden_Alley_Uzhhorod.jpg', ARRAY['walk', 'riverside']::text[]),
    ('uzhhorod-botanical-garden', 'uzhhorod', 'PARK', 1, 'HOURS', 4.4, 'Ужгородский ботанический сад', 'Uzhhorod Botanical Garden', 'Ужгород ботаникалық бағы', 48.62400000, 22.30500000, 'Uzhhorod Botanical Garden Ukraine', ARRAY['uzhhorod']::text[], ARRAY['uzhhorod']::text[], 'Uzhhorod_Botanical_Garden.jpg', ARRAY['garden', 'green-space']::text[]),
    ('holy-cross-cathedral-uzhhorod', 'uzhhorod', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Кафедральный собор в Ужгороде', 'Holy Cross Cathedral Uzhhorod', 'Ужгород Қасиетті Крест соборы', 48.62300000, 22.30100000, 'Holy Cross Cathedral Uzhhorod Ukraine', ARRAY['uzhhorod']::text[], ARRAY['uzhhorod']::text[], 'Holy_Cross_Cathedral_Uzhhorod.jpg', ARRAY['cathedral', 'heritage']::text[]),
    ('bozdosh-park', 'uzhhorod', 'PARK', 2, 'HOURS', 4.4, 'Боздошский парк', 'Bozdosh Park', 'Боздош саябағы', 48.62500000, 22.26300000, 'Bozdosh Park Uzhhorod Ukraine', ARRAY['uzhhorod']::text[], ARRAY['uzhhorod']::text[], 'Bozdosh_Park_Uzhhorod.jpg', ARRAY['family', 'green-space']::text[]),
    ('palanok-castle', 'mukachevo', 'MUSEUM', 2, 'HOURS', 4.8, 'Замок Паланок', 'Palanok Castle', 'Паланок қамалы', 48.43100000, 22.68700000, 'Palanok Castle Mukachevo Ukraine', ARRAY['mukachevo']::text[], ARRAY['uzhhorod', 'mukachevo']::text[], 'Palanok_Castle.jpg', ARRAY['castle', 'museum']::text[]),
    ('mukachevo-town-hall', 'mukachevo', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Мукачевская ратуша', 'Mukachevo Town Hall', 'Мукачево ратушасы', 48.44300000, 22.71800000, 'Mukachevo Town Hall Ukraine', ARRAY['mukachevo']::text[], ARRAY['mukachevo']::text[], 'Mukachevo_Town_Hall.jpg', ARRAY['city-symbol', 'central']::text[]),
    ('st-nicholas-monastery-mukachevo', 'mukachevo', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Монастырь Святого Николая в Мукачево', 'St Nicholas Monastery Mukachevo', 'Мукачево Әулие Николай монастыры', 48.45900000, 22.73000000, 'St Nicholas Monastery Mukachevo Ukraine', ARRAY['mukachevo']::text[], ARRAY['mukachevo']::text[], 'St_Nicholas_Monastery_Mukachevo.jpg', ARRAY['monastery', 'heritage']::text[]),
    ('schonborn-palace', 'mukachevo', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Дворец Шенборнов', 'Schonborn Palace', 'Шенборн сарайы', 48.52600000, 22.87500000, 'Schonborn Palace Mukachevo Ukraine', ARRAY['mukachevo']::text[], ARRAY['mukachevo', 'uzhhorod']::text[], 'Schonborn_Palace_Mukachevo.jpg', ARRAY['palace', 'park']::text[]),
    ('dastor-mukachevo', 'mukachevo', 'SHOPPING', 1, 'HOURS', 4.3, 'Dastor Mukachevo', 'Dastor Mukachevo Mall', 'Dastor Mukachevo сауда орталығы', 48.44800000, 22.72200000, 'Dastor Mukachevo Ukraine', ARRAY['mukachevo']::text[], ARRAY['mukachevo']::text[], 'Dastor_Mukachevo.jpg', ARRAY['mall', 'indoor']::text[]),

    ('kamianets-podilskyi-castle', 'kamianets-podilskyi', 'MUSEUM', 3, 'HOURS', 4.9, 'Старая крепость Каменца-Подольского', 'Kamianets-Podilskyi Castle', 'Каменец-Подольский қамалы', 48.67300000, 26.56300000, 'Kamianets-Podilskyi Castle Ukraine', ARRAY['kamianets-podilskyi']::text[], ARRAY['chernivtsi', 'kamianets-podilskyi']::text[], 'Kamianets_Podilskyi_Castle.jpg', ARRAY['castle', 'fortress']::text[]),
    ('kamianets-podilskyi-old-town', 'kamianets-podilskyi', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Старый город Каменца-Подольского', 'Kamianets-Podilskyi Old Town', 'Каменец-Подольский ескі қаласы', 48.67700000, 26.57400000, 'Kamianets-Podilskyi Old Town Ukraine', ARRAY['kamianets-podilskyi']::text[], ARRAY['kamianets-podilskyi']::text[], 'Kamianets_Podilskyi_Old_Town.jpg', ARRAY['old-town', 'walk']::text[]),
    ('smotrych-canyon', 'kamianets-podilskyi', 'NATURE', 2, 'HOURS', 4.8, 'Смотричский каньон', 'Smotrych Canyon', 'Смотрич каньоны', 48.67400000, 26.57600000, 'Smotrych Canyon Kamianets-Podilskyi Ukraine', ARRAY['kamianets-podilskyi']::text[], ARRAY['kamianets-podilskyi']::text[], 'Smotrych_Canyon.jpg', ARRAY['canyon', 'viewpoint']::text[]),
    ('castle-bridge-kamianets', 'kamianets-podilskyi', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Замковый мост Каменца-Подольского', 'Castle Bridge Kamianets-Podilskyi', 'Қамал көпірі', 48.67400000, 26.56600000, 'Castle Bridge Kamianets-Podilskyi Ukraine', ARRAY['kamianets-podilskyi']::text[], ARRAY['kamianets-podilskyi']::text[], 'Castle_Bridge_Kamianets_Podilskyi.jpg', ARRAY['bridge', 'photo-stop']::text[]),
    ('miniature-castles-museum', 'kamianets-podilskyi', 'MUSEUM', 1, 'HOURS', 4.5, 'Музей миниатюр Замки Украины', 'Miniature Castle Museum', 'Украина қамалдары миниатюра музейі', 48.67400000, 26.56400000, 'Miniature Castle Museum Kamianets-Podilskyi Ukraine', ARRAY['kamianets-podilskyi']::text[], ARRAY['kamianets-podilskyi']::text[], 'Miniature_Castle_Museum_Kamianets.jpg', ARRAY['family', 'museum']::text[]),

    ('historic-centre-odesa', 'odesa', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Исторический центр Одессы', 'Historic Centre of Odesa', 'Одесса тарихи орталығы', 46.48500000, 30.74000000, 'Historic Centre of Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Historic_Centre_of_Odesa.jpg', ARRAY['unesco', 'old-town']::text[]),
    ('potemkin-stairs', 'odesa', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Потёмкинская лестница', 'Potemkin Stairs', 'Потемкин баспалдағы', 46.48900000, 30.74100000, 'Potemkin Stairs Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Potemkin_Stairs_Odesa.jpg', ARRAY['city-symbol', 'photo-stop']::text[]),
    ('prymorskyi-boulevard', 'odesa', 'PARK', 1, 'HOURS', 4.7, 'Приморский бульвар', 'Prymorskyi Boulevard', 'Приморский бульвары', 46.48800000, 30.74200000, 'Prymorskyi Boulevard Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Prymorskyi_Boulevard_Odesa.jpg', ARRAY['waterfront', 'walk']::text[]),
    ('odesa-opera', 'odesa', 'ENTERTAINMENT', 2, 'HOURS', 4.9, 'Одесский театр оперы и балета', 'Odesa Opera and Ballet Theater', 'Одесса опера және балет театры', 46.48500000, 30.74100000, 'Odesa Opera and Ballet Theater Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Odesa_Opera_and_Ballet_Theater.jpg', ARRAY['theater', 'architecture']::text[]),
    ('odesa-fine-arts-museum', 'odesa', 'MUSEUM', 2, 'HOURS', 4.7, 'Одесский художественный музей', 'Odesa Fine Arts Museum', 'Одесса өнер музейі', 46.49200000, 30.72900000, 'Odesa Fine Arts Museum Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Odesa_Fine_Arts_Museum.jpg', ARRAY['art', 'indoor']::text[]),
    ('odesa-archaeological-museum', 'odesa', 'MUSEUM', 2, 'HOURS', 4.6, 'Одесский археологический музей', 'Odesa Archaeological Museum', 'Одесса археология музейі', 46.48500000, 30.74400000, 'Odesa Archaeological Museum Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Odesa_Archaeological_Museum.jpg', ARRAY['archaeology', 'black-sea']::text[]),
    ('pryvoz-market', 'odesa', 'MARKET', 1, 'HOURS', 4.6, 'Рынок Привоз', 'Privoz Market Odesa', 'Одесса Привоз базары', 46.46800000, 30.73300000, 'Privoz Market Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Privoz_Market_Odesa.jpg', ARRAY['local-market', 'food-market']::text[]),
    ('starokonny-market', 'odesa', 'MARKET', 1, 'HOURS', 4.4, 'Староконный рынок', 'Starokonny Market', 'Староконный базары', 46.47700000, 30.71900000, 'Starokonny Market Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Starokonny_Market_Odesa.jpg', ARRAY['local-market', 'antiques']::text[]),
    ('shevchenko-park-odesa', 'odesa', 'PARK', 2, 'HOURS', 4.6, 'Парк Шевченко в Одессе', 'Shevchenko Park Odesa', 'Одесса Шевченко саябағы', 46.47900000, 30.75600000, 'Shevchenko Park Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Shevchenko_Park_Odesa.jpg', ARRAY['green-space', 'coast']::text[]),
    ('lanzheron-beach', 'odesa', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Ланжерон', 'Lanzheron Beach', 'Ланжерон жағажайы', 46.47800000, 30.76700000, 'Lanzheron Beach Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Lanzheron_Beach_Odesa.jpg', ARRAY['city-beach', 'summer']::text[]),
    ('arcadia-beach', 'odesa', 'BEACH', 3, 'HOURS', 4.5, 'Аркадия', 'Arcadia Beach', 'Аркадия жағажайы', 46.43100000, 30.76500000, 'Arcadia Beach Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Arcadia_Beach_Odesa.jpg', ARRAY['beach', 'nightlife']::text[]),
    ('gagarinn-plaza', 'odesa', 'SHOPPING', 2, 'HOURS', 4.4, 'Gagarinn Plaza', 'Gagarinn Plaza', 'Gagarinn Plaza', 46.43300000, 30.76000000, 'Gagarinn Plaza Odesa Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Gagarinn_Plaza_Odesa.jpg', ARRAY['mall', 'arcadia']::text[]),
    ('odesa-zoo', 'odesa', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Одесский зоопарк', 'Odesa Zoo', 'Одесса зообағы', 46.46900000, 30.73600000, 'Odesa Zoo Ukraine', ARRAY['odesa']::text[], ARRAY['odesa']::text[], 'Odesa_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),

    ('akkerman-fortress', 'bilhorod-dnistrovskyi', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Аккерманская крепость', 'Akkerman Fortress', 'Аккерман қамалы', 46.20100000, 30.34900000, 'Akkerman Fortress Bilhorod-Dnistrovskyi Ukraine', ARRAY['bilhorod-dnistrovskyi']::text[], ARRAY['odesa', 'bilhorod-dnistrovskyi']::text[], 'Akkerman_Fortress.jpg', ARRAY['fortress', 'day-trip']::text[]),
    ('bilhorod-dnistrovskyi-local-lore-museum', 'bilhorod-dnistrovskyi', 'MUSEUM', 1, 'HOURS', 4.4, 'Белгород-Днестровский краеведческий музей', 'Bilhorod-Dnistrovskyi Local Lore Museum', 'Белгород-Днестровский өлкетану музейі', 46.19000000, 30.34400000, 'Bilhorod-Dnistrovskyi Local Lore Museum Ukraine', ARRAY['bilhorod-dnistrovskyi']::text[], ARRAY['bilhorod-dnistrovskyi']::text[], 'Bilhorod_Dnistrovskyi_Local_Lore_Museum.jpg', ARRAY['local-history', 'indoor']::text[]),
    ('john-suchavskyi-underground-church', 'bilhorod-dnistrovskyi', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Подземная церковь Иоанна Сучавского', 'John Suchavskyi Underground Church', 'Иоанн Сучавский жерасты шіркеуі', 46.19300000, 30.34600000, 'John Suchavskyi Underground Church Bilhorod-Dnistrovskyi Ukraine', ARRAY['bilhorod-dnistrovskyi']::text[], ARRAY['bilhorod-dnistrovskyi']::text[], 'John_Suchavskyi_Underground_Church.jpg', ARRAY['religion', 'heritage']::text[]),
    ('lower-dniester-national-park', 'bilhorod-dnistrovskyi', 'NATURE', 4, 'HOURS', 4.7, 'Нижнеднестровский национальный природный парк', 'Lower Dniester National Nature Park', 'Төменгі Днестр ұлттық табиғи паркі', 46.40000000, 30.22000000, 'Lower Dniester National Nature Park Ukraine', ARRAY['bilhorod-dnistrovskyi', 'odesa']::text[], ARRAY['odesa', 'bilhorod-dnistrovskyi']::text[], 'Lower_Dniester_National_Nature_Park.jpg', ARRAY['wetlands', 'birding']::text[]),
    ('shabo-wine-culture-center', 'shabo', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Центр культуры вина SHABO', 'SHABO Wine Culture Center', 'SHABO шарап мәдениеті орталығы', 46.13300000, 30.39000000, 'SHABO Wine Culture Center Ukraine', ARRAY['shabo', 'bilhorod-dnistrovskyi', 'odesa']::text[], ARRAY['odesa', 'bilhorod-dnistrovskyi']::text[], 'SHABO_Wine_Culture_Center.jpg', ARRAY['wine', 'adult']::text[]),

    ('mykolaiv-zoo', 'mykolaiv', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Николаевский зоопарк', 'Mykolaiv Zoo', 'Николаев зообағы', 46.96100000, 32.03600000, 'Mykolaiv Zoo Ukraine', ARRAY['mykolaiv']::text[], ARRAY['mykolaiv']::text[], 'Mykolaiv_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),
    ('museum-shipbuilding-fleet', 'mykolaiv', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей судостроения и флота', 'Museum of Shipbuilding and Fleet', 'Кеме жасау және флот музейі', 46.97400000, 31.99500000, 'Museum of Shipbuilding and Fleet Mykolaiv Ukraine', ARRAY['mykolaiv']::text[], ARRAY['mykolaiv']::text[], 'Museum_of_Shipbuilding_and_Fleet_Mykolaiv.jpg', ARRAY['maritime-history', 'indoor']::text[]),
    ('mykolaiv-local-lore-museum', 'mykolaiv', 'MUSEUM', 2, 'HOURS', 4.5, 'Николаевский краеведческий музей', 'Mykolaiv Regional Museum of Local History', 'Николаев өлкетану музейі', 46.97600000, 31.99500000, 'Mykolaiv Regional Museum of Local History Ukraine', ARRAY['mykolaiv']::text[], ARRAY['mykolaiv']::text[], 'Mykolaiv_Local_Lore_Museum.jpg', ARRAY['regional-history', 'indoor']::text[]),
    ('flotskyi-boulevard', 'mykolaiv', 'PARK', 1, 'HOURS', 4.5, 'Флотский бульвар', 'Flotskyi Boulevard', 'Флотский бульвары', 46.97300000, 31.99800000, 'Flotskyi Boulevard Mykolaiv Ukraine', ARRAY['mykolaiv']::text[], ARRAY['mykolaiv']::text[], 'Flotskyi_Boulevard_Mykolaiv.jpg', ARRAY['riverside', 'walk']::text[]),
    ('soborna-street-mykolaiv', 'mykolaiv', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Соборная улица в Николаеве', 'Soborna Street Mykolaiv', 'Николаев Соборная көшесі', 46.97000000, 32.00000000, 'Soborna Street Mykolaiv Ukraine', ARRAY['mykolaiv']::text[], ARRAY['mykolaiv']::text[], 'Soborna_Street_Mykolaiv.jpg', ARRAY['pedestrian-street', 'central']::text[]),

    ('freedom-square-kharkiv', 'kharkiv', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Площадь Свободы в Харькове', 'Freedom Square Kharkiv', 'Харьков Бостандық алаңы', 50.00400000, 36.23200000, 'Freedom Square Kharkiv Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Freedom_Square_Kharkiv.jpg', ARRAY['central-square', 'city-symbol']::text[]),
    ('derzhprom-kharkiv', 'kharkiv', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Госпром / Держпром', 'Derzhprom Kharkiv', 'Харьков Держпром', 50.00600000, 36.22800000, 'Derzhprom Kharkiv Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Derzhprom_Kharkiv.jpg', ARRAY['constructivism', 'architecture']::text[]),
    ('kharkiv-central-park', 'kharkiv', 'PARK', 3, 'HOURS', 4.7, 'Центральный парк Харькова', 'Kharkiv Central Park', 'Харьков орталық саябағы', 50.01800000, 36.24600000, 'Kharkiv Central Park Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Kharkiv_Central_Park.jpg', ARRAY['family', 'green-space']::text[]),
    ('sumtsov-kharkiv-historical-museum', 'kharkiv', 'MUSEUM', 2, 'HOURS', 4.6, 'Харьковский исторический музей им. М. Ф. Сумцова', 'M. F. Sumtsov Kharkiv Historical Museum', 'Сумцов атындағы Харьков тарихи музейі', 49.99300000, 36.23100000, 'Sumtsov Kharkiv Historical Museum Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Sumtsov_Kharkiv_Historical_Museum.jpg', ARRAY['regional-history', 'indoor']::text[]),
    ('kharkiv-zoo', 'kharkiv', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Харьковский зоопарк', 'Kharkiv Zoo', 'Харьков зообағы', 50.00600000, 36.23700000, 'Kharkiv Zoo Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Kharkiv_Zoo.jpg', ARRAY['family', 'wildlife']::text[]),
    ('mirror-stream-fountain', 'kharkiv', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Зеркальная струя', 'Mirror Stream Fountain', 'Айна ағыны фонтаны', 49.99900000, 36.23400000, 'Mirror Stream Kharkiv Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Mirror_Stream_Fountain_Kharkiv.jpg', ARRAY['photo-stop', 'city-symbol']::text[]),
    ('annunciation-cathedral-kharkiv', 'kharkiv', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Благовещенский собор в Харькове', 'Annunciation Cathedral Kharkiv', 'Харьков Благовещенский соборы', 49.98900000, 36.22100000, 'Annunciation Cathedral Kharkiv Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Annunciation_Cathedral_Kharkiv.jpg', ARRAY['cathedral', 'heritage']::text[]),
    ('nikolsky-mall-kharkiv', 'kharkiv', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Nikolsky', 'Nikolsky Shopping Mall', 'Nikolsky сауда орталығы', 49.99000000, 36.23500000, 'Nikolsky Shopping Mall Kharkiv Ukraine', ARRAY['kharkiv']::text[], ARRAY['kharkiv']::text[], 'Nikolsky_Mall_Kharkiv.jpg', ARRAY['mall', 'central']::text[]),

    ('yavornytsky-national-historical-museum', 'dnipro', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный исторический музей им. Д. Яворницкого', 'Dmytro Yavornytsky National Historical Museum', 'Яворницкий ұлттық тарихи музейі', 48.45400000, 35.06500000, 'Dmytro Yavornytsky National Historical Museum Dnipro Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Yavornytsky_National_Historical_Museum.jpg', ARRAY['history', 'indoor']::text[]),
    ('menorah-center-dnipro', 'dnipro', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Центр Менора', 'Menorah Center', 'Менора орталығы', 48.46400000, 35.04700000, 'Menorah Center Dnipro Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Menorah_Center_Dnipro.jpg', ARRAY['cultural-center', 'city-symbol']::text[]),
    ('jewish-memory-holocaust-museum', 'dnipro', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Память еврейского народа и Холокост в Украине', 'Jewish Memory and Holocaust in Ukraine Museum', 'Украинадағы Холокост және еврей халқы жады музейі', 48.46400000, 35.04700000, 'Jewish Memory and Holocaust in Ukraine Museum Dnipro', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Jewish_Memory_and_Holocaust_in_Ukraine_Museum.jpg', ARRAY['history', 'indoor']::text[]),
    ('shevchenko-park-monastyrskyi-island', 'dnipro', 'PARK', 2, 'HOURS', 4.6, 'Парк Шевченко и Монастырский остров', 'Taras Shevchenko Park Dnipro and Monastyrskyi Island', 'Шевченко саябағы және Монастырский аралы', 48.45700000, 35.07300000, 'Shevchenko Park Monastyrskyi Island Dnipro Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Shevchenko_Park_Monastyrskyi_Island.jpg', ARRAY['riverside', 'green-space']::text[]),
    ('dnipro-embankment', 'dnipro', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Набережная Днепра', 'Dnipro Embankment', 'Днепр жағалауы', 48.46600000, 35.05200000, 'Dnipro Embankment Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Dnipro_Embankment.jpg', ARRAY['waterfront', 'walk']::text[]),
    ('rocket-park-dnipro', 'dnipro', 'MUSEUM', 1, 'HOURS', 4.5, 'Ракетный парк / Медиапростир', 'Rocket Park and Mediaprostir', 'Зымыран паркі', 48.46700000, 35.04400000, 'Rocket Park Dnipro Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Rocket_Park_Dnipro.jpg', ARRAY['space-history', 'technical-museum']::text[]),
    ('most-city-mall', 'dnipro', 'SHOPPING', 2, 'HOURS', 4.4, 'ТРЦ Most-City', 'Most-City Mall', 'Most-City сауда орталығы', 48.46600000, 35.05000000, 'Most-City Mall Dnipro Ukraine', ARRAY['dnipro']::text[], ARRAY['dnipro']::text[], 'Most_City_Mall_Dnipro.jpg', ARRAY['mall', 'central']::text[]),

    ('khortytsia-island', 'zaporizhzhia', 'NATURE', 4, 'HOURS', 4.8, 'Остров Хортица', 'Khortytsia Island', 'Хортица аралы', 47.82500000, 35.07900000, 'Khortytsia Island Zaporizhzhia Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Khortytsia_Island.jpg', ARRAY['national-reserve', 'dnipro']::text[]),
    ('zaporizhian-sich-complex', 'zaporizhzhia', 'MUSEUM', 2, 'HOURS', 4.7, 'Историко-культурный комплекс Запорожская Сечь', 'Zaporizhian Sich Historical and Cultural Complex', 'Запорожская Сечь тарихи-мәдени кешені', 47.81900000, 35.07000000, 'Zaporizhian Sich Historical Cultural Complex Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Zaporizhian_Sich_Complex.jpg', ARRAY['cossack-history', 'open-air-museum']::text[]),
    ('khortytsia-museum-space', 'zaporizhzhia', 'MUSEUM', 2, 'HOURS', 4.6, 'Музейное пространство Хортицы', 'Khortytsia Museum Space', 'Хортица музей кеңістігі', 47.82300000, 35.07100000, 'Khortytsia Museum Space Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Khortytsia_Museum_Space.jpg', ARRAY['museum', 'national-reserve']::text[]),
    ('dniprohes-dam', 'zaporizhzhia', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'ДнепроГЭС', 'DniproHES Dam', 'ДнепроГЭС бөгеті', 47.86900000, 35.08600000, 'DniproHES Dam Zaporizhzhia Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'DniproHES_Dam.jpg', ARRAY['industrial-heritage', 'landmark']::text[]),
    ('faeton-retro-car-museum', 'zaporizhzhia', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей техники Фаэтон', 'Faeton Retro Car Museum', 'Фаэтон ретро техника музейі', 47.85900000, 35.16600000, 'Faeton Retro Car Museum Zaporizhzhia Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Faeton_Retro_Car_Museum.jpg', ARRAY['technical-museum', 'family']::text[]),
    ('motor-sich-technical-museum', 'zaporizhzhia', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей техники Богуслаева / Motor Sich', 'Boguslayev Motor Sich Technical Museum', 'Motor Sich техника музейі', 47.84900000, 35.11700000, 'Boguslayev Motor Sich Technical Museum Zaporizhzhia Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Motor_Sich_Technical_Museum.jpg', ARRAY['aviation', 'technical-museum']::text[]),
    ('zaporizhzhia-local-lore-museum', 'zaporizhzhia', 'MUSEUM', 2, 'HOURS', 4.5, 'Запорожский областной краеведческий музей', 'Zaporizhzhia Regional Museum of Local Lore', 'Запорожье өлкетану музейі', 47.83700000, 35.13900000, 'Zaporizhzhia Regional Museum of Local Lore Ukraine', ARRAY['zaporizhzhia']::text[], ARRAY['zaporizhzhia']::text[], 'Zaporizhzhia_Local_Lore_Museum.jpg', ARRAY['regional-history', 'indoor']::text[]),

    ('altanka-sumy', 'sumy', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Альтанка в Сумах', 'Altanka Gazebo Sumy', 'Сумы Альтанкасы', 50.90700000, 34.79900000, 'Altanka Gazebo Sumy Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Altanka_Sumy.jpg', ARRAY['city-symbol', 'photo-stop']::text[]),
    ('kazka-childrens-park', 'sumy', 'PARK', 2, 'HOURS', 4.5, 'Детский парк Сказка', 'Kazka Childrens Park', 'Ертегі балалар саябағы', 50.91000000, 34.81200000, 'Kazka Childrens Park Sumy Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Kazka_Childrens_Park_Sumy.jpg', ARRAY['family', 'green-space']::text[]),
    ('onatsky-art-museum', 'sumy', 'MUSEUM', 1, 'HOURS', 4.5, 'Сумской художественный музей им. Н. Онацкого', 'Nikanor Onatsky Sumy Regional Art Museum', 'Онацкий атындағы Сумы өнер музейі', 50.90700000, 34.79800000, 'Nikanor Onatsky Sumy Regional Art Museum Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Onatsky_Art_Museum_Sumy.jpg', ARRAY['art', 'indoor']::text[]),
    ('sumy-local-lore-museum', 'sumy', 'MUSEUM', 1, 'HOURS', 4.5, 'Сумской областной краеведческий музей', 'Sumy Regional Museum of Local Lore', 'Сумы өлкетану музейі', 50.90900000, 34.79900000, 'Sumy Regional Museum of Local Lore Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Sumy_Local_Lore_Museum.jpg', ARRAY['regional-history', 'indoor']::text[]),
    ('lake-chekha', 'sumy', 'NATURE', 2, 'HOURS', 4.4, 'Озеро Чеха', 'Lake Chekha', 'Чеха көлі', 50.92800000, 34.77500000, 'Lake Chekha Sumy Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Lake_Chekha_Sumy.jpg', ARRAY['lake', 'recreation']::text[]),
    ('holy-resurrection-cathedral-sumy', 'sumy', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Свято-Воскресенский кафедральный собор', 'Holy Resurrection Cathedral Sumy', 'Сумы Қасиетті Воскресенский соборы', 50.90700000, 34.80300000, 'Holy Resurrection Cathedral Sumy Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Holy_Resurrection_Cathedral_Sumy.jpg', ARRAY['cathedral', 'heritage']::text[]),
    ('manufactura-mall-sumy', 'sumy', 'SHOPPING', 2, 'HOURS', 4.3, 'ТРЦ Мануфактура', 'Manufactura Mall Sumy', 'Мануфактура сауда орталығы', 50.90700000, 34.79700000, 'Manufactura Mall Sumy Ukraine', ARRAY['sumy']::text[], ARRAY['sumy']::text[], 'Manufactura_Mall_Sumy.jpg', ARRAY['mall', 'central']::text[]),

    ('dytynets-park-val', 'chernihiv', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Детинец / Вал в Чернигове', 'Dytynets Park and Val Chernihiv', 'Чернигов Детинец және Вал', 51.48900000, 31.30600000, 'Dytynets Park Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Dytynets_Park_Chernihiv.jpg', ARRAY['old-city', 'viewpoint']::text[]),
    ('transfiguration-cathedral-chernihiv', 'chernihiv', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Спасо-Преображенский собор в Чернигове', 'Transfiguration Cathedral Chernihiv', 'Чернигов Спасо-Преображенский соборы', 51.48900000, 31.30700000, 'Transfiguration Cathedral Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Transfiguration_Cathedral_Chernihiv.jpg', ARRAY['ancient-architecture', 'cathedral']::text[]),
    ('borys-hlib-cathedral', 'chernihiv', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Борисоглебский собор', 'Borys and Hlib Cathedral', 'Борис және Глеб соборы', 51.48900000, 31.30700000, 'Borys and Hlib Cathedral Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Borys_and_Hlib_Cathedral.jpg', ARRAY['ancient-architecture', 'heritage']::text[]),
    ('pyatnytska-church-chernihiv', 'chernihiv', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Пятницкая церковь в Чернигове', 'Pyatnytska Church Chernihiv', 'Чернигов Пятницкая шіркеуі', 51.49100000, 31.29900000, 'Pyatnytska Church Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Pyatnytska_Church_Chernihiv.jpg', ARRAY['ancient-architecture', 'heritage']::text[]),
    ('st-catherine-church-chernihiv', 'chernihiv', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Екатерининская церковь', 'St Catherine Church Chernihiv', 'Чернигов Әулие Екатерина шіркеуі', 51.48700000, 31.30900000, 'St Catherine Church Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'St_Catherine_Church_Chernihiv.jpg', ARRAY['city-symbol', 'heritage']::text[]),
    ('tarnovskyi-historical-museum', 'chernihiv', 'MUSEUM', 2, 'HOURS', 4.6, 'Исторический музей им. В. Тарновского', 'V. V. Tarnovskyi Chernihiv Regional Historical Museum', 'Тарновский атындағы Чернигов тарихи музейі', 51.49000000, 31.30600000, 'Tarnovskyi Chernihiv Regional Historical Museum Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Tarnovskyi_Historical_Museum_Chernihiv.jpg', ARRAY['regional-history', 'indoor']::text[]),
    ('boldyni-hills-anthony-caves', 'chernihiv', 'NATURE', 2, 'HOURS', 4.7, 'Болдины горы и Антониевы пещеры', 'Boldyni Hills and Anthony Caves', 'Болдин таулары және Антоний үңгірлері', 51.47800000, 31.28500000, 'Boldyni Hills Anthony Caves Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Boldyni_Hills_Anthony_Caves.jpg', ARRAY['caves', 'heritage']::text[]),
    ('chernihiv-central-park', 'chernihiv', 'PARK', 2, 'HOURS', 4.5, 'Центральный парк культуры и отдыха Чернигова', 'Chernihiv Central Park', 'Чернигов орталық саябағы', 51.50400000, 31.28400000, 'Chernihiv Central Park Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Chernihiv_Central_Park.jpg', ARRAY['family', 'green-space']::text[]),
    ('hollywood-mall-chernihiv', 'chernihiv', 'SHOPPING', 2, 'HOURS', 4.3, 'ТРЦ Hollywood', 'Hollywood Mall Chernihiv', 'Hollywood Чернигов сауда орталығы', 51.52300000, 31.29300000, 'Hollywood Mall Chernihiv Ukraine', ARRAY['chernihiv']::text[], ARRAY['chernihiv']::text[], 'Hollywood_Mall_Chernihiv.jpg', ARRAY['mall', 'indoor']::text[]);

CREATE TEMP TABLE seed_ukraine_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-ukraine-place:' || seed.slug) AS place_hash,
        md5('id-ukraine-media:' || seed.slug) AS media_hash
    FROM seed_ukraine_priority_places seed
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
    ARRAY['ukraine', city_id, slug, lower(category), 'ukraine-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Украины: ' || title_ru || '. Перед посещением проверяйте актуальные правила безопасности, расписание и доступность.' AS description_ru,
    'Ukraine tourist place: ' || title_en || '. Check current safety rules, schedule, and availability before visiting.' AS description_en,
    'Украина туристік орны: ' || title_kk || '. Бармас бұрын қауіпсіздік ережелерін, кестені және қолжетімділікті тексеріңіз.' AS description_kk,
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
    'UA',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 200::numeric
        ELSE 100::numeric
    END,
    'UAH',
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
FROM seed_ukraine_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
    price_amount = EXCLUDED.price_amount,
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
FROM seed_ukraine_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_ukraine_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_ukraine_resolved_places
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
FROM seed_ukraine_resolved_places seed
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
FROM seed_ukraine_resolved_places
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
    'UA',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_ukraine_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'UA',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_ukraine_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
