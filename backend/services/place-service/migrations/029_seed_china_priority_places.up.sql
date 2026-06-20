-- Priority China destination places seed.
-- China is intentionally kept as one country destination, while every place
-- remains tied to a concrete city or tourist hub used by reference and admin filters.

DROP TABLE IF EXISTS seed_china_resolved_places;
DROP TABLE IF EXISTS seed_china_priority_places;

CREATE TEMP TABLE seed_china_priority_places (
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
    media_file text NOT NULL
);

INSERT INTO seed_china_priority_places (
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
    media_file
) VALUES
    ('forbidden-city', 'beijing', 'MUSEUM', 3, 'HOURS', 4.9, 'Запретный город', 'Forbidden City', 'Тыйым салынған қала', 39.91630000, 116.39720000, 'Forbidden City Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('tiananmen-square', 'beijing', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Тяньаньмэнь', 'Tiananmen Square', 'Тяньаньмэнь алаңы', 39.90550000, 116.39760000, 'Tiananmen Square Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('temple-of-heaven', 'beijing', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Неба', 'Temple of Heaven', 'Аспан храмы', 39.88220000, 116.40660000, 'Temple of Heaven Beijing China', 'Temple_of_Heaven,_Beijing,_China.jpg'),
    ('summer-palace', 'beijing', 'PARK', 3, 'HOURS', 4.8, 'Летний дворец', 'Summer Palace', 'Жазғы сарай', 39.99990000, 116.27550000, 'Summer Palace Beijing China', 'Summer_Palace_Beijing.jpg'),
    ('mutianyu-great-wall', 'beijing', 'ARCHITECTURE', 4, 'HOURS', 4.9, 'Великая Китайская стена Мутяньюй', 'Mutianyu Great Wall', 'Мутяньюй Ұлы Қытай қорғаны', 40.43190000, 116.57040000, 'Mutianyu Great Wall Beijing China', 'Great_Wall_of_China_July_2006.JPG'),
    ('badaling-great-wall', 'beijing', 'ARCHITECTURE', 4, 'HOURS', 4.7, 'Великая Китайская стена Бадалин', 'Badaling Great Wall', 'Бадалин Ұлы Қытай қорғаны', 40.35420000, 116.00690000, 'Badaling Great Wall Beijing China', 'Great_Wall_of_China_July_2006.JPG'),
    ('beihai-park', 'beijing', 'PARK', 2, 'HOURS', 4.6, 'Парк Бэйхай', 'Beihai Park', 'Бэйхай саябағы', 39.92500000, 116.38900000, 'Beihai Park Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('jingshan-park', 'beijing', 'PARK', 1, 'HOURS', 4.7, 'Парк Цзиншань', 'Jingshan Park', 'Цзиншань саябағы', 39.92530000, 116.39650000, 'Jingshan Park Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('lama-temple', 'beijing', 'TEMPLE', 2, 'HOURS', 4.7, 'Храм Юнхэгун', 'Lama Temple', 'Юнхэгун храмы', 39.94600000, 116.41760000, 'Lama Temple Beijing China', 'Temple_of_Heaven,_Beijing,_China.jpg'),
    ('national-museum-china', 'beijing', 'MUSEUM', 3, 'HOURS', 4.7, 'Национальный музей Китая', 'National Museum of China', 'Қытай ұлттық музейі', 39.90470000, 116.40120000, 'National Museum of China Beijing', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('798-art-district', 'beijing', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Арт-квартал 798', '798 Art District', '798 өнер ауданы', 39.98430000, 116.49590000, '798 Art District Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('universal-beijing-resort', 'beijing', 'ENTERTAINMENT', 6, 'HOURS', 4.7, 'Universal Beijing Resort', 'Universal Beijing Resort', 'Universal Beijing Resort', 39.85470000, 116.67620000, 'Universal Beijing Resort China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('wangfujing-street', 'beijing', 'SHOPPING', 2, 'HOURS', 4.4, 'Улица Ванфуцзин', 'Wangfujing Street', 'Ванфуцзин көшесі', 39.91490000, 116.41100000, 'Wangfujing Street Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('qianmen-dashilar', 'beijing', 'MARKET', 2, 'HOURS', 4.5, 'Цяньмэнь и Дашилань', 'Qianmen and Dashilar', 'Цяньмэнь және Дашилань', 39.89540000, 116.39120000, 'Qianmen Dashilar Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('panjiayuan-antique-market', 'beijing', 'MARKET', 2, 'HOURS', 4.5, 'Антикварный рынок Паньцзяюань', 'Panjiayuan Antique Market', 'Паньцзяюань антиквариат базары', 39.87690000, 116.46120000, 'Panjiayuan Antique Market Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('taikoo-li-sanlitun', 'beijing', 'SHOPPING', 2, 'HOURS', 4.5, 'Taikoo Li Sanlitun', 'Taikoo Li Sanlitun', 'Taikoo Li Sanlitun', 39.93360000, 116.45480000, 'Taikoo Li Sanlitun Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('zhoukoudian-peking-man-site', 'beijing', 'MUSEUM', 2, 'HOURS', 4.5, 'Стоянка синантропа Чжоукоудянь', 'Zhoukoudian Peking Man Site', 'Чжоукоудянь Пекин адамы орны', 39.68960000, 115.92210000, 'Zhoukoudian Peking Man Site Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('olympic-forest-park', 'beijing', 'PARK', 2, 'HOURS', 4.5, 'Олимпийский лесной парк', 'Olympic Forest Park', 'Олимпиадалық орман саябағы', 40.01560000, 116.39070000, 'Olympic Forest Park Beijing China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('the-bund', 'shanghai', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Набережная Вайтань', 'The Bund', 'Вайтань жағалауы', 31.24000000, 121.49000000, 'The Bund Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('yu-garden', 'shanghai', 'PARK', 2, 'HOURS', 4.6, 'Сад Юйюань', 'Yu Garden', 'Юйюань бағы', 31.22720000, 121.49200000, 'Yu Garden Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('oriental-pearl-tower', 'shanghai', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Телебашня Восточная жемчужина', 'Oriental Pearl Tower', 'Шығыс інжу мұнарасы', 31.23970000, 121.49970000, 'Oriental Pearl Tower Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('shanghai-tower', 'shanghai', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Шанхайская башня', 'Shanghai Tower', 'Шанхай мұнарасы', 31.23350000, 121.50550000, 'Shanghai Tower China', 'Shanghai_-_The_Bund.jpg'),
    ('shanghai-museum-east', 'shanghai', 'MUSEUM', 3, 'HOURS', 4.7, 'Шанхайский музей Восточный корпус', 'Shanghai Museum East', 'Шанхай музейінің шығыс корпусы', 31.22840000, 121.54470000, 'Shanghai Museum East China', 'Shanghai_-_The_Bund.jpg'),
    ('nanjing-road', 'shanghai', 'SHOPPING', 2, 'HOURS', 4.5, 'Нанкинская улица', 'Nanjing Road', 'Нанкин жолы', 31.23470000, 121.47400000, 'Nanjing Road Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('xintiandi', 'shanghai', 'FOOD', 2, 'HOURS', 4.5, 'Синьтяньди', 'Xintiandi', 'Синьтяньди', 31.21970000, 121.47570000, 'Xintiandi Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('tianzifang', 'shanghai', 'MARKET', 2, 'HOURS', 4.4, 'Тяньцзыфан', 'Tianzifang', 'Тяньцзыфан', 31.21090000, 121.46800000, 'Tianzifang Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('shanghai-disneyland', 'shanghai', 'ENTERTAINMENT', 7, 'HOURS', 4.7, 'Шанхайский Диснейленд', 'Shanghai Disneyland', 'Шанхай Диснейленді', 31.14400000, 121.65700000, 'Shanghai Disneyland China', 'Shanghai_-_The_Bund.jpg'),
    ('zhujiajiao-ancient-town', 'shanghai', 'ARCHITECTURE', 4, 'HOURS', 4.5, 'Древний город Чжуцзяцзяо', 'Zhujiajiao Ancient Town', 'Чжуцзяцзяо көне қаласы', 31.11040000, 121.04880000, 'Zhujiajiao Ancient Town Shanghai China', 'Shanghai_-_The_Bund.jpg'),
    ('west-lake', 'hangzhou', 'NATURE', 4, 'HOURS', 4.9, 'Озеро Сиху', 'West Lake', 'Сиху көлі', 30.24600000, 120.14300000, 'West Lake Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('lingyin-temple', 'hangzhou', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Линъинь', 'Lingyin Temple', 'Линъинь храмы', 30.24020000, 120.10240000, 'Lingyin Temple Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('xixi-wetland', 'hangzhou', 'PARK', 3, 'HOURS', 4.6, 'Водно-болотный парк Сиси', 'Xixi Wetland', 'Сиси сулы-батпақты саябағы', 30.26700000, 120.06400000, 'Xixi Wetland Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('china-national-tea-museum', 'hangzhou', 'MUSEUM', 2, 'HOURS', 4.6, 'Национальный музей чая Китая', 'China National Tea Museum', 'Қытай ұлттық шай музейі', 30.23270000, 120.11500000, 'China National Tea Museum Hangzhou', 'West_Lake_in_Hangzhou.jpg'),
    ('hefang-street-night-market', 'hangzhou', 'MARKET', 2, 'HOURS', 4.4, 'Ночной рынок улицы Хэфан', 'Hefang Street Night Market', 'Хэфан көшесі түнгі базары', 30.24480000, 120.17110000, 'Hefang Street Night Market Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('gongchen-bridge-grand-canal', 'hangzhou', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Мост Гунчэнь и Великий канал', 'Gongchen Bridge and Grand Canal', 'Гунчэнь көпірі және Ұлы канал', 30.32220000, 120.14270000, 'Gongchen Bridge Grand Canal Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('hubin-yintai-in77', 'hangzhou', 'SHOPPING', 2, 'HOURS', 4.5, 'Hubin Yintai in77', 'Hubin Yintai in77', 'Hubin Yintai in77', 30.25540000, 120.16450000, 'Hubin Yintai in77 Hangzhou China', 'West_Lake_in_Hangzhou.jpg'),
    ('humble-administrator-garden', 'suzhou', 'PARK', 2, 'HOURS', 4.8, 'Сад скромного чиновника', 'Humble Administrator Garden', 'Қарапайым әкім бағы', 31.32460000, 120.62960000, 'Humble Administrator Garden Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('lingering-garden', 'suzhou', 'PARK', 2, 'HOURS', 4.7, 'Сад Лююань', 'Lingering Garden', 'Лююань бағы', 31.31100000, 120.58540000, 'Lingering Garden Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('suzhou-museum', 'suzhou', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей Сучжоу', 'Suzhou Museum', 'Сучжоу музейі', 31.32380000, 120.62780000, 'Suzhou Museum China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('pingjiang-road', 'suzhou', 'MARKET', 2, 'HOURS', 4.5, 'Улица Пинцзян', 'Pingjiang Road', 'Пинцзян көшесі', 31.31510000, 120.63550000, 'Pingjiang Road Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('shantang-street', 'suzhou', 'MARKET', 2, 'HOURS', 4.5, 'Улица Шаньтан', 'Shantang Street', 'Шаньтан көшесі', 31.32110000, 120.59820000, 'Shantang Street Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('tiger-hill', 'suzhou', 'PARK', 2, 'HOURS', 4.6, 'Тигровый холм', 'Tiger Hill', 'Жолбарыс төбесі', 31.33830000, 120.57630000, 'Tiger Hill Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('tongli-ancient-town', 'suzhou', 'ARCHITECTURE', 4, 'HOURS', 4.5, 'Древний город Тунли', 'Tongli Ancient Town', 'Тунли көне қаласы', 31.16090000, 120.71860000, 'Tongli Ancient Town Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('jinji-lake', 'suzhou', 'NATURE', 2, 'HOURS', 4.5, 'Озеро Цзиньцзи', 'Jinji Lake', 'Цзиньцзи көлі', 31.30460000, 120.70500000, 'Jinji Lake Suzhou China', 'Suzhou_Humble_Administrators_Garden.jpg'),
    ('sun-yat-sen-mausoleum', 'nanjing', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Мавзолей Сунь Ятсена', 'Sun Yat-sen Mausoleum', 'Сунь Ятсен кесенесі', 32.06150000, 118.84800000, 'Sun Yat-sen Mausoleum Nanjing China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('ming-xiaoling-mausoleum', 'nanjing', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Мавзолей Мин Сяолин', 'Ming Xiaoling Mausoleum', 'Мин Сяолин кесенесі', 32.05930000, 118.84290000, 'Ming Xiaoling Mausoleum Nanjing China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('confucius-temple-qinhuai', 'nanjing', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Конфуция и река Циньхуай', 'Confucius Temple Qinhuai Scenic Area', 'Конфуций храмы және Циньхуай', 32.02060000, 118.78860000, 'Confucius Temple Qinhuai Scenic Area Nanjing China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('nanjing-museum', 'nanjing', 'MUSEUM', 3, 'HOURS', 4.8, 'Нанкинский музей', 'Nanjing Museum', 'Нанкин музейі', 32.04070000, 118.82830000, 'Nanjing Museum China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('laomendong', 'nanjing', 'MARKET', 2, 'HOURS', 4.5, 'Лаомэньдун', 'Laomendong', 'Лаомэньдун', 32.01270000, 118.78350000, 'Laomendong Nanjing China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('nanjing-city-wall', 'nanjing', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Городская стена Нанкина', 'Nanjing City Wall', 'Нанкин қала қабырғасы', 32.06170000, 118.78950000, 'Nanjing City Wall China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('xuanwu-lake', 'nanjing', 'PARK', 2, 'HOURS', 4.6, 'Озеро Сюаньу', 'Xuanwu Lake', 'Сюаньу көлі', 32.07190000, 118.79660000, 'Xuanwu Lake Nanjing China', 'Nanjing_Ming_Xiaoling_Mausoleum.jpg'),
    ('terracotta-army', 'xian', 'MUSEUM', 4, 'HOURS', 4.9, 'Терракотовая армия', 'Terracotta Army', 'Терракота әскері', 34.38400000, 109.27800000, 'Terracotta Army Xian China', 'Terracotta_Army,_View_of_Pit_1.jpg'),
    ('xian-city-wall', 'xian', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Городская стена Сианя', 'Xian City Wall', 'Сиань қала қабырғасы', 34.26500000, 108.95300000, 'Xian City Wall China', 'Terracotta_Army,_View_of_Pit_1.jpg'),
    ('giant-wild-goose-pagoda', 'xian', 'TEMPLE', 2, 'HOURS', 4.7, 'Большая пагода диких гусей', 'Giant Wild Goose Pagoda', 'Үлкен жабайы қаздар пагодасы', 34.21870000, 108.95970000, 'Giant Wild Goose Pagoda Xian China', 'Giant_Wild_Goose_Pagoda.jpg'),
    ('shaanxi-history-museum', 'xian', 'MUSEUM', 3, 'HOURS', 4.7, 'Исторический музей Шэньси', 'Shaanxi History Museum', 'Шэньси тарих музейі', 34.22940000, 108.95570000, 'Shaanxi History Museum Xian China', 'Terracotta_Army,_View_of_Pit_1.jpg'),
    ('xian-muslim-quarter', 'xian', 'FOOD', 2, 'HOURS', 4.5, 'Мусульманский квартал Сианя', 'Xian Muslim Quarter', 'Сиань мұсылман кварталы', 34.26730000, 108.94270000, 'Xian Muslim Quarter China', 'Terracotta_Army,_View_of_Pit_1.jpg'),
    ('datang-everbright-city', 'xian', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Datang Everbright City', 'Datang Everbright City', 'Datang Everbright City', 34.20990000, 108.96330000, 'Datang Everbright City Xian China', 'Giant_Wild_Goose_Pagoda.jpg'),
    ('chengdu-panda-base', 'chengdu', 'NATURE', 4, 'HOURS', 4.9, 'Исследовательская база панд в Чэнду', 'Chengdu Research Base of Giant Panda Breeding', 'Чэнду алып панда зерттеу базасы', 30.73520000, 104.14560000, 'Chengdu Research Base of Giant Panda Breeding China', 'Chengdu_Panda_Base.jpg'),
    ('panda-valley-dujiangyan', 'chengdu', 'NATURE', 3, 'HOURS', 4.7, 'Долина панд Дуцзянъянь', 'Panda Valley Dujiangyan', 'Дуцзянъянь панда аңғары', 30.97880000, 103.63210000, 'Panda Valley Dujiangyan China', 'Chengdu_Panda_Base.jpg'),
    ('dujiangyan-irrigation-system', 'chengdu', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Ирригационная система Дуцзянъянь', 'Dujiangyan Irrigation System', 'Дуцзянъянь суару жүйесі', 31.00100000, 103.60500000, 'Dujiangyan Irrigation System China', 'Chengdu_Panda_Base.jpg'),
    ('wuhou-shrine', 'chengdu', 'TEMPLE', 2, 'HOURS', 4.6, 'Мемориальный храм Ухоу', 'Wuhou Shrine', 'Ухоу ғибадатханасы', 30.64620000, 104.04770000, 'Wuhou Shrine Chengdu China', 'Chengdu_Panda_Base.jpg'),
    ('jinli-ancient-street', 'chengdu', 'MARKET', 2, 'HOURS', 4.5, 'Старинная улица Цзиньли', 'Jinli Ancient Street', 'Цзиньли көне көшесі', 30.64570000, 104.04620000, 'Jinli Ancient Street Chengdu China', 'Chengdu_Panda_Base.jpg'),
    ('kuanzhai-alley', 'chengdu', 'FOOD', 2, 'HOURS', 4.6, 'Переулки Куаньчжай', 'Kuanzhai Alley', 'Куаньчжай аллеялары', 30.67450000, 104.05640000, 'Kuanzhai Alley Chengdu China', 'Chengdu_Panda_Base.jpg'),
    ('chengdu-peoples-park', 'chengdu', 'PARK', 2, 'HOURS', 4.5, 'Народный парк Чэнду', 'Chengdu Peoples Park', 'Чэнду халық саябағы', 30.66020000, 104.05960000, 'Chengdu Peoples Park China', 'Chengdu_Panda_Base.jpg'),
    ('sanxingdui-museum', 'chengdu', 'MUSEUM', 3, 'HOURS', 4.8, 'Музей Саньсиндуй', 'Sanxingdui Museum', 'Саньсиндуй музейі', 31.00890000, 104.20350000, 'Sanxingdui Museum China', 'Chengdu_Panda_Base.jpg'),
    ('taikoo-li-chengdu', 'chengdu', 'SHOPPING', 2, 'HOURS', 4.6, 'Taikoo Li Chengdu', 'Taikoo Li Chengdu', 'Taikoo Li Chengdu', 30.65350000, 104.08120000, 'Taikoo Li Chengdu China', 'Chengdu_Panda_Base.jpg'),
    ('hongya-cave', 'chongqing', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Хунъя Дун', 'Hongya Cave', 'Хунъя үңгірі', 29.56280000, 106.57900000, 'Hongya Cave Chongqing China', 'Hongyadong_Chongqing.jpg'),
    ('ciqikou-ancient-town', 'chongqing', 'MARKET', 3, 'HOURS', 4.5, 'Древний город Цыцикоу', 'Ciqikou Ancient Town', 'Цыцикоу көне қаласы', 29.58070000, 106.44930000, 'Ciqikou Ancient Town Chongqing China', 'Hongyadong_Chongqing.jpg'),
    ('china-three-gorges-museum', 'chongqing', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Трех ущелий', 'China Three Gorges Museum', 'Қытай Үш шатқал музейі', 29.56620000, 106.54910000, 'China Three Gorges Museum Chongqing', 'Hongyadong_Chongqing.jpg'),
    ('jiefangbei-bayi-food-street', 'chongqing', 'FOOD', 2, 'HOURS', 4.5, 'Улица еды Байи у Цзефанбэй', 'Jiefangbei Bayi Food Street', 'Цзефанбэй Байи тағам көшесі', 29.55670000, 106.57570000, 'Jiefangbei Bayi Food Street Chongqing China', 'Hongyadong_Chongqing.jpg'),
    ('yangtze-river-cableway', 'chongqing', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Канатная дорога через Янцзы', 'Yangtze River Cableway', 'Янцзы аспалы жолы', 29.55970000, 106.58220000, 'Yangtze River Cableway Chongqing China', 'Hongyadong_Chongqing.jpg'),
    ('dazu-rock-carvings', 'chongqing', 'TEMPLE', 3, 'HOURS', 4.8, 'Наскальные рельефы Дацзу', 'Dazu Rock Carvings', 'Дацзу жартас мүсіндері', 29.70490000, 105.80110000, 'Dazu Rock Carvings Chongqing China', 'Hongyadong_Chongqing.jpg'),
    ('canton-tower', 'guangzhou', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Кантонская башня', 'Canton Tower', 'Кантон мұнарасы', 23.10990000, 113.31900000, 'Canton Tower Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('chen-clan-ancestral-hall', 'guangzhou', 'MUSEUM', 2, 'HOURS', 4.6, 'Академия клана Чэнь', 'Chen Clan Ancestral Hall', 'Чэнь әулеті академиясы', 23.12910000, 113.24050000, 'Chen Clan Ancestral Hall Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('guangdong-museum', 'guangzhou', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Гуандуна', 'Guangdong Museum', 'Гуандун музейі', 23.11580000, 113.32670000, 'Guangdong Museum Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('yuexiu-park', 'guangzhou', 'PARK', 2, 'HOURS', 4.5, 'Парк Юэсю', 'Yuexiu Park', 'Юэсю саябағы', 23.14070000, 113.26360000, 'Yuexiu Park Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('chimelong-guangzhou', 'guangzhou', 'ENTERTAINMENT', 6, 'HOURS', 4.7, 'Chimelong Guangzhou', 'Chimelong Guangzhou', 'Chimelong Guangzhou', 23.00500000, 113.32300000, 'Chimelong Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('beijing-road-guangzhou', 'guangzhou', 'SHOPPING', 2, 'HOURS', 4.4, 'Пешеходная улица Бэйцзинлу', 'Beijing Road Guangzhou', 'Гуанчжоу Бэйцзин жолы', 23.12530000, 113.27080000, 'Beijing Road Guangzhou China', 'Canton_Tower,_Guangzhou.jpg'),
    ('dameisha-beach', 'shenzhen', 'BEACH', 3, 'HOURS', 4.4, 'Пляж Дамэйша', 'Dameisha Beach', 'Дамэйша жағажайы', 22.59360000, 114.30500000, 'Dameisha Beach Shenzhen China', 'Canton_Tower,_Guangzhou.jpg'),
    ('shenzhen-bay-park', 'shenzhen', 'PARK', 2, 'HOURS', 4.6, 'Парк Шэньчжэньского залива', 'Shenzhen Bay Park', 'Шэньчжэнь шығанағы саябағы', 22.52350000, 113.94340000, 'Shenzhen Bay Park China', 'Canton_Tower,_Guangzhou.jpg'),
    ('shenzhen-museum', 'shenzhen', 'MUSEUM', 2, 'HOURS', 4.5, 'Музей Шэньчжэня', 'Shenzhen Museum', 'Шэньчжэнь музейі', 22.54310000, 114.05790000, 'Shenzhen Museum China', 'Canton_Tower,_Guangzhou.jpg'),
    ('window-of-the-world', 'shenzhen', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Парк Окно в мир', 'Window of the World', 'Әлемге терезе паркі', 22.53620000, 113.97100000, 'Window of the World Shenzhen China', 'Window_of_the_World,_Shenzhen.jpg'),
    ('splendid-china-folk-village', 'shenzhen', 'ENTERTAINMENT', 4, 'HOURS', 4.5, 'Splendid China Folk Village', 'Splendid China Folk Village', 'Splendid China Folk Village', 22.53680000, 113.98270000, 'Splendid China Folk Village Shenzhen', 'Window_of_the_World,_Shenzhen.jpg'),
    ('dongmen-pedestrian-street', 'shenzhen', 'MARKET', 2, 'HOURS', 4.4, 'Пешеходная улица Дунмэнь', 'Dongmen Pedestrian Street', 'Дунмэнь жаяу көшесі', 22.54590000, 114.11750000, 'Dongmen Pedestrian Street Shenzhen China', 'Canton_Tower,_Guangzhou.jpg'),
    ('shenzhen-mixc', 'shenzhen', 'SHOPPING', 2, 'HOURS', 4.5, 'The MixC Shenzhen', 'The MixC Shenzhen', 'The MixC Shenzhen', 22.53970000, 114.10980000, 'The MixC Shenzhen China', 'Canton_Tower,_Guangzhou.jpg'),
    ('yalong-bay', 'sanya', 'BEACH', 4, 'HOURS', 4.7, 'Залив Ялунвань', 'Yalong Bay', 'Ялунвань шығанағы', 18.22950000, 109.63700000, 'Yalong Bay Sanya China', 'Yalong_Bay,_Sanya.jpg'),
    ('tianya-haijiao', 'sanya', 'NATURE', 2, 'HOURS', 4.5, 'Тянья Хайцзяо', 'Tianya Haijiao', 'Тянья Хайцзяо', 18.29250000, 109.34370000, 'Tianya Haijiao Sanya China', 'Yalong_Bay,_Sanya.jpg'),
    ('nanshan-culture-tourism-zone', 'sanya', 'TEMPLE', 4, 'HOURS', 4.7, 'Культурно-туристическая зона Наньшань', 'Nanshan Culture Tourism Zone', 'Наньшань мәдени-туристік аймағы', 18.29200000, 109.20440000, 'Nanshan Culture Tourism Zone Sanya China', 'Yalong_Bay,_Sanya.jpg'),
    ('wuzhizhou-island', 'sanya', 'BEACH', 5, 'HOURS', 4.6, 'Остров Учжичжоу', 'Wuzhizhou Island', 'Учжичжоу аралы', 18.31560000, 109.76350000, 'Wuzhizhou Island Sanya China', 'Yalong_Bay,_Sanya.jpg'),
    ('cdf-sanya-duty-free-city', 'sanya', 'SHOPPING', 3, 'HOURS', 4.4, 'CDF Sanya Duty Free City', 'CDF Sanya Duty Free City', 'CDF Sanya Duty Free City', 18.32950000, 109.73260000, 'CDF Sanya Duty Free City China', 'Yalong_Bay,_Sanya.jpg'),
    ('atlantis-sanya-aquaventure', 'sanya', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Аквапарк Atlantis Sanya', 'Atlantis Sanya Aquaventure', 'Atlantis Sanya Aquaventure', 18.33800000, 109.74140000, 'Atlantis Sanya Aquaventure China', 'Yalong_Bay,_Sanya.jpg'),
    ('gulangyu-island', 'xiamen', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Остров Гуланъюй', 'Gulangyu Island', 'Гуланъюй аралы', 24.44770000, 118.06790000, 'Gulangyu Island Xiamen China', 'Gulangyu_Island.jpg'),
    ('xiamen-botanical-garden', 'xiamen', 'PARK', 3, 'HOURS', 4.6, 'Ботанический сад Сямэня', 'Xiamen Botanical Garden', 'Сямэнь ботаникалық бағы', 24.44700000, 118.09800000, 'Xiamen Botanical Garden China', 'Gulangyu_Island.jpg'),
    ('nanputuo-temple', 'xiamen', 'TEMPLE', 2, 'HOURS', 4.6, 'Храм Наньпутуо', 'Nanputuo Temple', 'Наньпутуо храмы', 24.44570000, 118.10140000, 'Nanputuo Temple Xiamen China', 'Gulangyu_Island.jpg'),
    ('baicheng-beach', 'xiamen', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Байчэн', 'Baicheng Beach', 'Байчэн жағажайы', 24.43150000, 118.10070000, 'Baicheng Beach Xiamen China', 'Gulangyu_Island.jpg'),
    ('zhongshan-road-xiamen', 'xiamen', 'MARKET', 2, 'HOURS', 4.4, 'Улица Чжуншань в Сямэне', 'Zhongshan Road Xiamen', 'Сямэнь Чжуншань жолы', 24.45590000, 118.08060000, 'Zhongshan Road Xiamen China', 'Gulangyu_Island.jpg'),
    ('golden-sand-beach-qingdao', 'qingdao', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Золотые пески', 'Golden Sand Beach Qingdao', 'Циндао алтын құм жағажайы', 35.96640000, 120.24720000, 'Golden Sand Beach Qingdao China', 'Tsingtao_Beer_Museum.jpg'),
    ('laoshan-scenic-area', 'qingdao', 'NATURE', 5, 'HOURS', 4.7, 'Гора Лаошань', 'Laoshan Scenic Area', 'Лаошань көрікті аймағы', 36.19080000, 120.60140000, 'Laoshan Scenic Area Qingdao China', 'Tsingtao_Beer_Museum.jpg'),
    ('badaguan', 'qingdao', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Бадагуань', 'Badaguan', 'Бадагуань', 36.05510000, 120.34680000, 'Badaguan Qingdao China', 'Tsingtao_Beer_Museum.jpg'),
    ('tsingtao-beer-museum', 'qingdao', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей пива Tsingtao', 'Tsingtao Beer Museum', 'Tsingtao сыра музейі', 36.08600000, 120.34300000, 'Tsingtao Beer Museum Qingdao China', 'Tsingtao_Beer_Museum.jpg'),
    ('taidong-night-market', 'qingdao', 'MARKET', 2, 'HOURS', 4.4, 'Ночной рынок Тайдун', 'Taidong Night Market', 'Тайдун түнгі базары', 36.08400000, 120.36300000, 'Taidong Night Market Qingdao China', 'Tsingtao_Beer_Museum.jpg'),
    ('li-river', 'guilin', 'NATURE', 5, 'HOURS', 4.9, 'Река Ли', 'Li River', 'Ли өзені', 25.27360000, 110.29000000, 'Li River Guilin China', 'Li_River,_Guilin.jpg'),
    ('reed-flute-cave', 'guilin', 'NATURE', 2, 'HOURS', 4.5, 'Пещера Тростниковой флейты', 'Reed Flute Cave', 'Қамыс сыбызғы үңгірі', 25.30570000, 110.27440000, 'Reed Flute Cave Guilin China', 'Li_River,_Guilin.jpg'),
    ('longji-rice-terraces', 'guilin', 'NATURE', 5, 'HOURS', 4.8, 'Рисовые террасы Лунцзи', 'Longji Rice Terraces', 'Лунцзи күріш террасалары', 25.75950000, 110.11970000, 'Longji Rice Terraces Guilin China', 'Li_River,_Guilin.jpg'),
    ('yulong-river', 'yangshuo', 'NATURE', 4, 'HOURS', 4.8, 'Река Юйлун', 'Yulong River', 'Юйлун өзені', 24.78850000, 110.48500000, 'Yulong River Yangshuo China', 'Li_River,_Guilin.jpg'),
    ('west-street-yangshuo', 'yangshuo', 'MARKET', 2, 'HOURS', 4.4, 'Западная улица Яншо', 'West Street Yangshuo', 'Яншо Батыс көшесі', 24.77840000, 110.49690000, 'West Street Yangshuo China', 'Li_River,_Guilin.jpg'),
    ('zhangjiajie-national-forest-park', 'zhangjiajie', 'NATURE', 6, 'HOURS', 4.9, 'Национальный лесной парк Чжанцзяцзе', 'Zhangjiajie National Forest Park', 'Чжанцзяцзе ұлттық орман паркі', 29.31320000, 110.43470000, 'Zhangjiajie National Forest Park China', 'Zhangjiajie_National_Forest_Park.jpg'),
    ('tianmen-mountain', 'zhangjiajie', 'NATURE', 5, 'HOURS', 4.8, 'Гора Тяньмэнь', 'Tianmen Mountain', 'Тяньмэнь тауы', 29.05000000, 110.48300000, 'Tianmen Mountain Zhangjiajie China', 'Zhangjiajie_National_Forest_Park.jpg'),
    ('yellow-mountain', 'huangshan', 'NATURE', 6, 'HOURS', 4.9, 'Горы Хуаншань', 'Yellow Mountain', 'Хуаншань таулары', 30.13000000, 118.16500000, 'Yellow Mountain Huangshan China', 'Huangshan_pic_4.jpg'),
    ('hongcun-village', 'huangshan', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Деревня Хунцунь', 'Hongcun Village', 'Хунцунь ауылы', 29.92750000, 117.98700000, 'Hongcun Village Huangshan China', 'Huangshan_pic_4.jpg'),
    ('lijiang-old-town', 'lijiang', 'ARCHITECTURE', 4, 'HOURS', 4.8, 'Старый город Лицзян', 'Lijiang Old Town', 'Лицзян ескі қаласы', 26.87210000, 100.23450000, 'Lijiang Old Town China', 'Old_Town_of_Lijiang.jpg'),
    ('jade-dragon-snow-mountain', 'lijiang', 'NATURE', 5, 'HOURS', 4.8, 'Снежная гора Юйлун', 'Jade Dragon Snow Mountain', 'Юйлун қарлы тауы', 27.10000000, 100.17400000, 'Jade Dragon Snow Mountain Lijiang China', 'Old_Town_of_Lijiang.jpg'),
    ('tiger-leaping-gorge', 'lijiang', 'NATURE', 5, 'HOURS', 4.8, 'Ущелье Прыгающего тигра', 'Tiger Leaping Gorge', 'Жолбарыс секірген шатқал', 27.19200000, 100.13200000, 'Tiger Leaping Gorge Lijiang China', 'Old_Town_of_Lijiang.jpg'),
    ('erhai-lake', 'dali', 'NATURE', 4, 'HOURS', 4.7, 'Озеро Эрхай', 'Erhai Lake', 'Эрхай көлі', 25.80600000, 100.19600000, 'Erhai Lake Dali China', 'Old_Town_of_Lijiang.jpg'),
    ('dali-old-town', 'dali', 'MARKET', 3, 'HOURS', 4.5, 'Старый город Дали', 'Dali Old Town', 'Дали ескі қаласы', 25.69280000, 100.16150000, 'Dali Old Town China', 'Old_Town_of_Lijiang.jpg'),
    ('stone-forest-shilin', 'kunming', 'NATURE', 4, 'HOURS', 4.7, 'Каменный лес Шилинь', 'Stone Forest Shilin', 'Шилинь тас орманы', 24.81700000, 103.32400000, 'Stone Forest Shilin Kunming China', 'Stone_Forest,_Yunnan.jpg'),
    ('dianchi-lake', 'kunming', 'NATURE', 3, 'HOURS', 4.5, 'Озеро Дяньчи', 'Dianchi Lake', 'Дяньчи көлі', 24.88500000, 102.66500000, 'Dianchi Lake Kunming China', 'Stone_Forest,_Yunnan.jpg'),
    ('longmen-grottoes', 'luoyang', 'TEMPLE', 3, 'HOURS', 4.9, 'Гроты Лунмэнь', 'Longmen Grottoes', 'Лунмэнь үңгірлері', 34.55560000, 112.47080000, 'Longmen Grottoes Luoyang China', 'Longmen_Grottoes.jpg'),
    ('shaolin-temple-songshan', 'dengfeng', 'TEMPLE', 4, 'HOURS', 4.8, 'Храм Шаолинь и гора Суншань', 'Shaolin Temple and Songshan', 'Шаолинь храмы және Суншань', 34.50860000, 112.93560000, 'Shaolin Temple Songshan Dengfeng China', 'Longmen_Grottoes.jpg'),
    ('tianjin-italian-style-town', 'tianjin', 'ARCHITECTURE', 2, 'HOURS', 4.4, 'Итальянский квартал Тяньцзиня', 'Tianjin Italian Style Town', 'Тяньцзинь итальян кварталы', 39.13500000, 117.20400000, 'Tianjin Italian Style Town China', 'Shanghai_-_The_Bund.jpg'),
    ('chengde-mountain-resort', 'chengde', 'PARK', 4, 'HOURS', 4.8, 'Горная резиденция Чэндэ', 'Chengde Mountain Resort', 'Чэндэ тау резиденциясы', 40.98610000, 117.93920000, 'Chengde Mountain Resort China', 'Forbidden_City_Beijing_Shenwumen_Gate.JPG'),
    ('yungang-grottoes', 'datong', 'TEMPLE', 3, 'HOURS', 4.8, 'Гроты Юньган', 'Yungang Grottoes', 'Юньган үңгірлері', 40.10930000, 113.12200000, 'Yungang Grottoes Datong China', 'Longmen_Grottoes.jpg'),
    ('mount-wutai', 'xinzhou', 'TEMPLE', 5, 'HOURS', 4.8, 'Гора Утайшань', 'Mount Wutai', 'Утайшань тауы', 39.01000000, 113.59000000, 'Mount Wutai Xinzhou China', 'Temple_of_Heaven,_Beijing,_China.jpg'),
    ('laolongtou-great-wall', 'qinhuangdao', 'ARCHITECTURE', 3, 'HOURS', 4.6, 'Лаолунтоу', 'Laolongtou Great Wall', 'Лаолунтоу Ұлы қорғаны', 39.96860000, 119.79490000, 'Laolongtou Great Wall Qinhuangdao China', 'Great_Wall_of_China_July_2006.JPG');

CREATE TEMP TABLE seed_china_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-china-place:' || seed.slug) AS place_hash,
        md5('id-china-media:' || seed.slug) AS media_hash
    FROM seed_china_priority_places seed
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
    ARRAY['china', city_id, slug, lower(category), 'china-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Китая: ' || title_ru || '. Подходит для поиска по стране, городу, маршруту и категории.' AS description_ru,
    'China tourist place: ' || title_en || '. Useful for search by country, city, route and category.' AS description_en,
    'Қытай бағыты бойынша туристік орын: ' || title_kk || '. Ел, қала, маршрут және санат бойынша іздеуге арналған.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(location_query, ' ', '%20') AS location_source_url,
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
    'CN',
    city_id,
    category,
    NULL::numeric,
    NULL::varchar(3),
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
FROM seed_china_resolved_places
ON CONFLICT (id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    city_id = EXCLUDED.city_id,
    category = EXCLUDED.category,
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
FROM seed_china_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_china_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_china_resolved_places
ON CONFLICT (place_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

UPDATE places a
SET
    latitude = s.latitude,
    longitude = s.longitude,
    location_source_url = s.location_source_url,
    updated_at = NOW()
FROM seed_china_resolved_places s
WHERE a.id = s.id;

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
FROM seed_china_resolved_places
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
SELECT gen_random_uuid(), id, kind, 'CN', city_id, 0, NOW()
FROM seed_china_resolved_places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_china_resolved_places;
DROP TABLE IF EXISTS seed_china_priority_places;
