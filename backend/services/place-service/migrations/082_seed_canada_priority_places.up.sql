-- Priority Canada destination places seed.
-- The seed covers city anchors, national parks, beaches, museums, malls, markets, food halls, and northern nature points.

DROP TABLE IF EXISTS seed_canada_resolved_places;
DROP TABLE IF EXISTS seed_canada_priority_places;

CREATE TEMP TABLE seed_canada_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    media_file text NOT NULL,
    extra_tags text[] NOT NULL DEFAULT ARRAY[]::text[]
);

INSERT INTO seed_canada_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    rating,
    title_ru,
    title_en,
    title_kk,
    latitude,
    longitude,
    media_file,
    extra_tags
) VALUES
    ('cn-tower', 'toronto', 'ARCHITECTURE', 2, 4.8, 'Си-Эн Тауэр', 'CN Tower', 'CN Tower', 43.64260000, -79.38710000, 'CN_Tower.jpg', ARRAY['toronto', 'landmark', 'viewpoint']::text[]),
    ('royal-ontario-museum', 'toronto', 'MUSEUM', 3, 4.7, 'Королевский музей Онтарио', 'Royal Ontario Museum', 'Онтарио корольдік музейі', 43.66770000, -79.39480000, 'Royal_Ontario_Museum.jpg', ARRAY['toronto', 'museum', 'indoor']::text[]),
    ('st-lawrence-market', 'toronto', 'MARKET', 1, 4.7, 'Рынок St. Lawrence', 'St. Lawrence Market', 'St. Lawrence базары', 43.64870000, -79.37160000, 'St._Lawrence_Market_Toronto.jpg', ARRAY['toronto', 'food-market', 'covered-market']::text[]),
    ('ripleys-aquarium-canada', 'toronto', 'ENTERTAINMENT', 2, 4.7, 'Аквариум Ripleys Aquarium of Canada', 'Ripleys Aquarium of Canada', 'Ripleys Aquarium of Canada', 43.64240000, -79.38600000, 'Ripleys_Aquarium_of_Canada.jpg', ARRAY['toronto', 'aquarium', 'family']::text[]),
    ('distillery-district', 'toronto', 'ARCHITECTURE', 2, 4.6, 'Distillery District', 'Distillery District', 'Distillery District', 43.65030000, -79.35960000, 'Distillery_District_Toronto.jpg', ARRAY['toronto', 'historic-district', 'evening']::text[]),
    ('toronto-islands', 'toronto', 'PARK', 3, 4.7, 'Острова Торонто', 'Toronto Islands', 'Торонто аралдары', 43.62050000, -79.37800000, 'Toronto_Islands.jpg', ARRAY['toronto', 'islands', 'skyline']::text[]),
    ('cf-toronto-eaton-centre', 'toronto', 'SHOPPING', 2, 4.5, 'CF Toronto Eaton Centre', 'CF Toronto Eaton Centre', 'CF Toronto Eaton Centre', 43.65440000, -79.38070000, 'Toronto_Eaton_Centre.jpg', ARRAY['toronto', 'mall', 'shopping']::text[]),
    ('harbourfront-centre', 'toronto', 'FOOD', 2, 4.5, 'Harbourfront Centre', 'Harbourfront Centre', 'Harbourfront Centre', 43.63890000, -79.38300000, 'Harbourfront_Centre_Toronto.jpg', ARRAY['toronto', 'waterfront', 'food']::text[]),

    ('niagara-falls', 'niagara-falls-ca', 'NATURE', 4, 4.9, 'Ниагарский водопад', 'Niagara Falls', 'Ниагара сарқырамасы', 43.08280000, -79.07420000, 'Niagara_Falls_Aerial_View.jpg', ARRAY['niagara-falls-ca', 'waterfall', 'must-see']::text[]),
    ('journey-behind-the-falls', 'niagara-falls-ca', 'ENTERTAINMENT', 2, 4.8, 'Journey Behind the Falls', 'Journey Behind the Falls', 'Journey Behind the Falls', 43.07910000, -79.07830000, 'Journey_Behind_the_Falls.jpg', ARRAY['niagara-falls-ca', 'waterfall', 'viewpoint']::text[]),
    ('niagara-city-cruises', 'niagara-falls-ca', 'ENTERTAINMENT', 2, 4.8, 'Niagara City Cruises', 'Niagara City Cruises', 'Niagara City Cruises', 43.09040000, -79.07310000, 'Niagara_City_Cruises.jpg', ARRAY['niagara-falls-ca', 'boat-tour', 'seasonal']::text[]),
    ('queen-victoria-park', 'niagara-falls-ca', 'PARK', 2, 4.7, 'Парк Queen Victoria', 'Queen Victoria Park', 'Queen Victoria саябағы', 43.08200000, -79.07460000, 'Queen_Victoria_Park_Niagara_Falls.jpg', ARRAY['niagara-falls-ca', 'park', 'viewpoint']::text[]),
    ('butterfly-conservatory', 'niagara-falls-ca', 'NATURE', 2, 4.6, 'Оранжерея бабочек Niagara Parks', 'Butterfly Conservatory', 'Көбелектер оранжереясы', 43.13500000, -79.05340000, 'Niagara_Parks_Butterfly_Conservatory.jpg', ARRAY['niagara-falls-ca', 'family', 'indoor']::text[]),
    ('clifton-hill', 'niagara-falls-ca', 'ENTERTAINMENT', 2, 4.4, 'Clifton Hill', 'Clifton Hill', 'Clifton Hill', 43.09100000, -79.07500000, 'Clifton_Hill_Niagara_Falls.jpg', ARRAY['niagara-falls-ca', 'nightlife', 'family']::text[]),

    ('parliament-hill', 'ottawa', 'ARCHITECTURE', 2, 4.8, 'Парламентский холм', 'Parliament Hill', 'Парламент төбесі', 45.42360000, -75.70090000, 'Parliament_Hill_Ottawa.jpg', ARRAY['ottawa', 'government', 'landmark']::text[]),
    ('rideau-canal', 'ottawa', 'NATURE', 3, 4.8, 'Канал Ридо', 'Rideau Canal', 'Ридо каналы', 45.42150000, -75.69720000, 'Rideau_Canal_Ottawa.jpg', ARRAY['ottawa', 'unesco', 'waterfront']::text[]),
    ('byward-market', 'ottawa', 'MARKET', 2, 4.6, 'ByWard Market', 'ByWard Market', 'ByWard Market', 45.42780000, -75.69230000, 'ByWard_Market_Ottawa.jpg', ARRAY['ottawa', 'market', 'food']::text[]),
    ('national-gallery-canada', 'ottawa', 'MUSEUM', 3, 4.7, 'Национальная галерея Канады', 'National Gallery of Canada', 'Канада ұлттық галереясы', 45.42950000, -75.69890000, 'National_Gallery_of_Canada.jpg', ARRAY['ottawa', 'art', 'indoor']::text[]),
    ('canadian-museum-nature', 'ottawa', 'MUSEUM', 2, 4.7, 'Канадский музей природы', 'Canadian Museum of Nature', 'Канада табиғат музейі', 45.41200000, -75.68880000, 'Canadian_Museum_of_Nature.jpg', ARRAY['ottawa', 'science', 'family']::text[]),
    ('canadian-museum-history', 'ottawa', 'MUSEUM', 3, 4.7, 'Канадский музей истории', 'Canadian Museum of History', 'Канада тарих музейі', 45.42940000, -75.70830000, 'Canadian_Museum_of_History.jpg', ARRAY['ottawa', 'history', 'indoor']::text[]),
    ('cf-rideau-centre', 'ottawa', 'SHOPPING', 2, 4.4, 'CF Rideau Centre', 'CF Rideau Centre', 'CF Rideau Centre', 45.42590000, -75.69120000, 'Rideau_Centre_Ottawa.jpg', ARRAY['ottawa', 'mall', 'central']::text[]),

    ('notre-dame-basilica-montreal', 'montreal', 'TEMPLE', 2, 4.8, 'Базилика Нотр-Дам в Монреале', 'Notre-Dame Basilica of Montreal', 'Монреаль Нотр-Дам базиликасы', 45.50450000, -73.55610000, 'Notre-Dame_Basilica_Montreal.jpg', ARRAY['montreal', 'church', 'old-montreal']::text[]),
    ('old-port-montreal', 'montreal', 'PARK', 3, 4.7, 'Старый порт Монреаля', 'Old Port of Montreal', 'Монреаль ескі порты', 45.50730000, -73.55160000, 'Old_Port_of_Montreal.jpg', ARRAY['montreal', 'waterfront', 'walk']::text[]),
    ('mount-royal-park', 'montreal', 'PARK', 3, 4.8, 'Парк Мон-Руаяль', 'Mount Royal Park', 'Мон-Руаяль саябағы', 45.50480000, -73.58780000, 'Mount_Royal_Park.jpg', ARRAY['montreal', 'viewpoint', 'green-space']::text[]),
    ('jean-talon-market', 'montreal', 'MARKET', 1, 4.7, 'Рынок Jean-Talon', 'Jean-Talon Market', 'Jean-Talon базары', 45.53610000, -73.61580000, 'Jean-Talon_Market_Montreal.jpg', ARRAY['montreal', 'food-market', 'local']::text[]),
    ('atwater-market', 'montreal', 'MARKET', 1, 4.6, 'Рынок Atwater', 'Atwater Market', 'Atwater базары', 45.47930000, -73.57750000, 'Atwater_Market_Montreal.jpg', ARRAY['montreal', 'food-market', 'canal']::text[]),
    ('montreal-museum-fine-arts', 'montreal', 'MUSEUM', 3, 4.7, 'Монреальский музей изящных искусств', 'Montreal Museum of Fine Arts', 'Монреаль бейнелеу өнері музейі', 45.49870000, -73.57930000, 'Montreal_Museum_of_Fine_Arts.jpg', ARRAY['montreal', 'art', 'indoor']::text[]),
    ('biodome-montreal', 'montreal', 'NATURE', 3, 4.6, 'Биодом Монреаля', 'Montreal Biodome', 'Монреаль биодомы', 45.55970000, -73.54920000, 'Montreal_Biodome.jpg', ARRAY['montreal', 'family', 'nature']::text[]),
    ('time-out-market-montreal', 'montreal', 'FOOD', 1, 4.5, 'Time Out Market Montreal', 'Time Out Market Montreal', 'Time Out Market Montreal', 45.50240000, -73.57140000, 'Time_Out_Market_Montreal.jpg', ARRAY['montreal', 'food-hall', 'downtown']::text[]),
    ('saint-josephs-oratory', 'montreal', 'TEMPLE', 2, 4.7, 'Ораторий Святого Иосифа', 'Saint Josephs Oratory', 'Әулие Жозеф ораториясы', 45.49250000, -73.61670000, 'Saint_Josephs_Oratory_Montreal.jpg', ARRAY['montreal', 'church', 'viewpoint']::text[]),

    ('old-quebec', 'quebec-city', 'ARCHITECTURE', 4, 4.9, 'Старый Квебек', 'Old Quebec', 'Ескі Квебек', 46.81230000, -71.20530000, 'Old_Quebec_City.jpg', ARRAY['quebec-city', 'unesco', 'old-town']::text[]),
    ('montmorency-falls', 'quebec-city', 'NATURE', 3, 4.8, 'Водопад Монморанси', 'Montmorency Falls Park', 'Монморанси сарқырамасы', 46.89000000, -71.14750000, 'Montmorency_Falls.jpg', ARRAY['quebec-city', 'waterfall', 'park']::text[]),
    ('quartier-petit-champlain', 'quebec-city', 'SHOPPING', 2, 4.7, 'Квартал Petit Champlain', 'Quartier Petit Champlain', 'Petit Champlain кварталы', 46.81210000, -71.20330000, 'Quartier_Petit_Champlain.jpg', ARRAY['quebec-city', 'old-town', 'shopping']::text[]),
    ('musee-civilisation', 'quebec-city', 'MUSEUM', 2, 4.6, 'Музей цивилизации', 'Musee de la civilisation', 'Өркениет музейі', 46.81570000, -71.20220000, 'Musee_de_la_civilisation_Quebec.jpg', ARRAY['quebec-city', 'museum', 'indoor']::text[]),
    ('plains-of-abraham', 'quebec-city', 'PARK', 2, 4.7, 'Поля Авраама', 'Plains of Abraham', 'Авраам жазықтары', 46.80120000, -71.22060000, 'Plains_of_Abraham_Quebec.jpg', ARRAY['quebec-city', 'park', 'history']::text[]),
    ('galeries-capitale', 'quebec-city', 'SHOPPING', 2, 4.5, 'Galeries de la Capitale', 'Galeries de la Capitale', 'Galeries de la Capitale', 46.83430000, -71.30070000, 'Galeries_de_la_Capitale.jpg', ARRAY['quebec-city', 'mall', 'family']::text[]),

    ('stanley-park', 'vancouver', 'PARK', 4, 4.9, 'Парк Стэнли', 'Stanley Park', 'Стэнли саябағы', 49.30430000, -123.14430000, 'Stanley_Park_Vancouver.jpg', ARRAY['vancouver', 'seawall', 'green-space']::text[]),
    ('granville-island-public-market', 'vancouver', 'MARKET', 2, 4.7, 'Общественный рынок Granville Island', 'Granville Island Public Market', 'Granville Island қоғамдық базары', 49.27110000, -123.13580000, 'Granville_Island_Public_Market.jpg', ARRAY['vancouver', 'food-market', 'waterfront']::text[]),
    ('vancouver-aquarium', 'vancouver', 'ENTERTAINMENT', 3, 4.6, 'Ванкуверский аквариум', 'Vancouver Aquarium', 'Ванкувер аквариумы', 49.30040000, -123.13030000, 'Vancouver_Aquarium.jpg', ARRAY['vancouver', 'family', 'aquarium']::text[]),
    ('capilano-suspension-bridge-park', 'vancouver', 'NATURE', 3, 4.7, 'Парк Capilano Suspension Bridge', 'Capilano Suspension Bridge Park', 'Capilano аспалы көпір саябағы', 49.34290000, -123.11490000, 'Capilano_Suspension_Bridge.jpg', ARRAY['vancouver', 'forest', 'bridge']::text[]),
    ('museum-anthropology-ubc', 'vancouver', 'MUSEUM', 2, 4.7, 'Музей антропологии UBC', 'Museum of Anthropology at UBC', 'UBC антропология музейі', 49.26940000, -123.25950000, 'Museum_of_Anthropology_at_UBC.jpg', ARRAY['vancouver', 'museum', 'culture']::text[]),
    ('english-bay-beach', 'vancouver', 'BEACH', 2, 4.7, 'Пляж English Bay', 'English Bay Beach', 'English Bay жағажайы', 49.28600000, -123.14250000, 'English_Bay_Vancouver.jpg', ARRAY['vancouver', 'beach', 'sunset']::text[]),
    ('canada-place', 'vancouver', 'ARCHITECTURE', 2, 4.6, 'Canada Place', 'Canada Place', 'Canada Place', 49.28870000, -123.11100000, 'Canada_Place_Vancouver.jpg', ARRAY['vancouver', 'waterfront', 'landmark']::text[]),
    ('flyover-canada', 'vancouver', 'ENTERTAINMENT', 1, 4.5, 'FlyOver Canada', 'FlyOver Canada', 'FlyOver Canada', 49.28860000, -123.11130000, 'FlyOver_Canada_Vancouver.jpg', ARRAY['vancouver', 'indoor', 'family']::text[]),
    ('cf-pacific-centre', 'vancouver', 'SHOPPING', 2, 4.4, 'CF Pacific Centre', 'CF Pacific Centre', 'CF Pacific Centre', 49.28320000, -123.11950000, 'Pacific_Centre_Vancouver.jpg', ARRAY['vancouver', 'mall', 'downtown']::text[]),

    ('butchart-gardens', 'victoria', 'PARK', 3, 4.9, 'Сады Бутчартов', 'Butchart Gardens', 'Butchart Gardens', 48.56530000, -123.47030000, 'Butchart_Gardens.jpg', ARRAY['victoria', 'garden', 'flowers']::text[]),
    ('royal-bc-museum', 'victoria', 'MUSEUM', 3, 4.7, 'Королевский музей Британской Колумбии', 'Royal BC Museum', 'Британдық Колумбия корольдік музейі', 48.41980000, -123.36730000, 'Royal_BC_Museum.jpg', ARRAY['victoria', 'museum', 'indoor']::text[]),
    ('victoria-inner-harbour', 'victoria', 'ARCHITECTURE', 2, 4.8, 'Внутренняя гавань Виктории', 'Victoria Inner Harbour', 'Виктория ішкі айлағы', 48.42180000, -123.36710000, 'Victoria_Inner_Harbour.jpg', ARRAY['victoria', 'waterfront', 'walk']::text[]),
    ('fishermans-wharf-victoria', 'victoria', 'FOOD', 1, 4.5, 'Fishermans Wharf Victoria', 'Fishermans Wharf Victoria', 'Fishermans Wharf Victoria', 48.42100000, -123.38210000, 'Fishermans_Wharf_Victoria.jpg', ARRAY['victoria', 'food', 'waterfront']::text[]),
    ('beacon-hill-park', 'victoria', 'PARK', 2, 4.7, 'Парк Beacon Hill', 'Beacon Hill Park', 'Beacon Hill саябағы', 48.41400000, -123.36320000, 'Beacon_Hill_Park_Victoria.jpg', ARRAY['victoria', 'park', 'family']::text[]),
    ('craigdarroch-castle', 'victoria', 'ARCHITECTURE', 2, 4.6, 'Замок Craigdarroch', 'Craigdarroch Castle', 'Craigdarroch қамалы', 48.42230000, -123.34300000, 'Craigdarroch_Castle.jpg', ARRAY['victoria', 'castle', 'history']::text[]),

    ('whistler-blackcomb', 'whistler', 'NATURE', 6, 4.8, 'Whistler Blackcomb', 'Whistler Blackcomb', 'Whistler Blackcomb', 50.11630000, -122.95740000, 'Whistler_Blackcomb.jpg', ARRAY['whistler', 'ski-resort', 'mountains']::text[]),
    ('peak-2-peak-gondola', 'whistler', 'NATURE', 3, 4.8, 'PEAK 2 PEAK Gondola', 'PEAK 2 PEAK Gondola', 'PEAK 2 PEAK Gondola', 50.08290000, -122.94640000, 'Peak_2_Peak_Gondola.jpg', ARRAY['whistler', 'gondola', 'viewpoint']::text[]),
    ('whistler-village', 'whistler', 'ENTERTAINMENT', 2, 4.7, 'Whistler Village', 'Whistler Village', 'Whistler Village', 50.11550000, -122.95980000, 'Whistler_Village.jpg', ARRAY['whistler', 'shopping', 'evening']::text[]),
    ('lost-lake-park', 'whistler', 'NATURE', 3, 4.7, 'Парк Lost Lake', 'Lost Lake Park', 'Lost Lake саябағы', 50.12660000, -122.93870000, 'Lost_Lake_Whistler.jpg', ARRAY['whistler', 'lake', 'trail']::text[]),

    ('banff-gondola', 'banff', 'NATURE', 3, 4.8, 'Гондола Банфа', 'Banff Gondola', 'Банф гондоласы', 51.14890000, -115.55550000, 'Banff_Gondola.jpg', ARRAY['banff', 'gondola', 'viewpoint']::text[]),
    ('lake-louise', 'banff', 'NATURE', 4, 4.9, 'Озеро Луиз', 'Lake Louise', 'Луиз көлі', 51.41700000, -116.21770000, 'Lake_Louise_Banff.jpg', ARRAY['banff', 'lake', 'mountains']::text[]),
    ('cave-and-basin', 'banff', 'MUSEUM', 2, 4.6, 'Cave and Basin', 'Cave and Basin National Historic Site', 'Cave and Basin ұлттық тарихи орны', 51.16980000, -115.59080000, 'Cave_and_Basin_Banff.jpg', ARRAY['banff', 'history', 'parks-canada']::text[]),
    ('banff-upper-hot-springs', 'banff', 'NATURE', 2, 4.6, 'Горячие источники Banff Upper', 'Banff Upper Hot Springs', 'Banff Upper ыстық бұлақтары', 51.15120000, -115.56060000, 'Banff_Upper_Hot_Springs.jpg', ARRAY['banff', 'hot-springs', 'wellness']::text[]),
    ('banff-avenue', 'banff', 'SHOPPING', 2, 4.6, 'Banff Avenue', 'Banff Avenue', 'Banff Avenue', 51.17710000, -115.57080000, 'Banff_Avenue.jpg', ARRAY['banff', 'shopping', 'restaurants']::text[]),
    ('moraine-lake', 'banff', 'NATURE', 4, 4.9, 'Озеро Морейн', 'Moraine Lake', 'Морейн көлі', 51.32750000, -116.18180000, 'Moraine_Lake_17092005.jpg', ARRAY['banff', 'lake', 'viewpoint']::text[]),

    ('maligne-canyon', 'jasper', 'NATURE', 3, 4.8, 'Каньон Малин', 'Maligne Canyon', 'Малин каньоны', 52.92000000, -117.99900000, 'Maligne_Canyon_Jasper.jpg', ARRAY['jasper', 'canyon', 'hiking']::text[]),
    ('maligne-lake', 'jasper', 'NATURE', 4, 4.8, 'Озеро Малин', 'Maligne Lake', 'Малин көлі', 52.72900000, -117.63800000, 'Maligne_Lake_Jasper.jpg', ARRAY['jasper', 'lake', 'boat-tour']::text[]),
    ('jasper-skytram', 'jasper', 'NATURE', 3, 4.7, 'Jasper SkyTram', 'Jasper SkyTram', 'Jasper SkyTram', 52.87640000, -118.08930000, 'Jasper_SkyTram.jpg', ARRAY['jasper', 'gondola', 'viewpoint']::text[]),
    ('miette-hot-springs', 'jasper', 'NATURE', 2, 4.6, 'Горячие источники Miette', 'Miette Hot Springs', 'Miette ыстық бұлақтары', 53.12970000, -117.76940000, 'Miette_Hot_Springs.jpg', ARRAY['jasper', 'hot-springs', 'wellness']::text[]),

    ('calgary-tower', 'calgary', 'ARCHITECTURE', 2, 4.6, 'Башня Калгари', 'Calgary Tower', 'Калгари мұнарасы', 51.04430000, -114.06310000, 'Calgary_Tower.jpg', ARRAY['calgary', 'viewpoint', 'landmark']::text[]),
    ('heritage-park-historical-village', 'calgary', 'MUSEUM', 4, 4.7, 'Историческая деревня Heritage Park', 'Heritage Park Historical Village', 'Heritage Park тарихи ауылы', 50.98260000, -114.10140000, 'Heritage_Park_Historical_Village.jpg', ARRAY['calgary', 'open-air-museum', 'family']::text[]),
    ('studio-bell', 'calgary', 'MUSEUM', 2, 4.6, 'Studio Bell', 'Studio Bell', 'Studio Bell', 51.04460000, -114.05240000, 'Studio_Bell_Calgary.jpg', ARRAY['calgary', 'music', 'museum']::text[]),
    ('telus-spark', 'calgary', 'MUSEUM', 3, 4.5, 'TELUS Spark', 'TELUS Spark Science Centre', 'TELUS Spark ғылым орталығы', 51.05390000, -114.02510000, 'TELUS_Spark_Calgary.jpg', ARRAY['calgary', 'science', 'family']::text[]),
    ('princes-island-park', 'calgary', 'PARK', 2, 4.7, 'Prince Island Park', 'Princes Island Park', 'Princes Island Park', 51.05560000, -114.07080000, 'Princes_Island_Park_Calgary.jpg', ARRAY['calgary', 'park', 'river']::text[]),
    ('calgary-farmers-market', 'calgary', 'MARKET', 1, 4.5, 'Calgary Farmers Market', 'Calgary Farmers Market', 'Calgary Farmers Market', 50.97330000, -114.07180000, 'Calgary_Farmers_Market.jpg', ARRAY['calgary', 'food-market', 'local']::text[]),

    ('west-edmonton-mall', 'edmonton', 'SHOPPING', 4, 4.7, 'West Edmonton Mall', 'West Edmonton Mall', 'West Edmonton Mall', 53.52250000, -113.62420000, 'West_Edmonton_Mall.jpg', ARRAY['edmonton', 'mall', 'family']::text[]),
    ('royal-alberta-museum', 'edmonton', 'MUSEUM', 3, 4.6, 'Королевский музей Альберты', 'Royal Alberta Museum', 'Альберта корольдік музейі', 53.54630000, -113.48960000, 'Royal_Alberta_Museum.jpg', ARRAY['edmonton', 'museum', 'indoor']::text[]),
    ('fort-edmonton-park', 'edmonton', 'MUSEUM', 4, 4.7, 'Fort Edmonton Park', 'Fort Edmonton Park', 'Fort Edmonton Park', 53.50250000, -113.57880000, 'Fort_Edmonton_Park.jpg', ARRAY['edmonton', 'open-air-museum', 'family']::text[]),
    ('muttart-conservatory', 'edmonton', 'NATURE', 2, 4.6, 'Muttart Conservatory', 'Muttart Conservatory', 'Muttart Conservatory', 53.53580000, -113.47710000, 'Muttart_Conservatory.jpg', ARRAY['edmonton', 'botanical', 'indoor']::text[]),

    ('the-forks', 'winnipeg', 'MARKET', 2, 4.7, 'The Forks', 'The Forks', 'The Forks', 49.88740000, -97.13090000, 'The_Forks_Winnipeg.jpg', ARRAY['winnipeg', 'market', 'riverfront']::text[]),
    ('wag-qaumajuq', 'winnipeg', 'MUSEUM', 3, 4.7, 'WAG-Qaumajuq', 'WAG-Qaumajuq', 'WAG-Qaumajuq', 49.88940000, -97.15000000, 'Winnipeg_Art_Gallery.jpg', ARRAY['winnipeg', 'art', 'indoor']::text[]),
    ('the-leaf-winnipeg', 'winnipeg', 'NATURE', 2, 4.6, 'The Leaf', 'The Leaf', 'The Leaf', 49.86850000, -97.23400000, 'The_Leaf_Winnipeg.jpg', ARRAY['winnipeg', 'botanical', 'indoor']::text[]),
    ('assiniboine-park-zoo', 'winnipeg', 'ENTERTAINMENT', 4, 4.6, 'Зоопарк Assiniboine Park', 'Assiniboine Park Zoo', 'Assiniboine Park зообағы', 49.87100000, -97.23920000, 'Assiniboine_Park_Zoo.jpg', ARRAY['winnipeg', 'zoo', 'family']::text[]),
    ('canadian-museum-human-rights', 'winnipeg', 'MUSEUM', 3, 4.7, 'Канадский музей прав человека', 'Canadian Museum for Human Rights', 'Канада адам құқықтары музейі', 49.89080000, -97.13190000, 'Canadian_Museum_for_Human_Rights.jpg', ARRAY['winnipeg', 'museum', 'architecture']::text[]),
    ('royal-canadian-mint-winnipeg', 'winnipeg', 'MUSEUM', 2, 4.5, 'Королевский монетный двор Канады', 'Royal Canadian Mint Winnipeg', 'Канада корольдік монет сарайы', 49.85290000, -97.05630000, 'Royal_Canadian_Mint_Winnipeg.jpg', ARRAY['winnipeg', 'museum', 'coins']::text[]),

    ('wanuskewin', 'saskatoon', 'MUSEUM', 3, 4.8, 'Wanuskewin', 'Wanuskewin', 'Wanuskewin', 52.20190000, -106.59400000, 'Wanuskewin_Heritage_Park.jpg', ARRAY['saskatoon', 'indigenous-culture', 'unesco-tentative']::text[]),
    ('remai-modern', 'saskatoon', 'MUSEUM', 2, 4.6, 'Remai Modern', 'Remai Modern', 'Remai Modern', 52.12360000, -106.66700000, 'Remai_Modern_Saskatoon.jpg', ARRAY['saskatoon', 'art', 'indoor']::text[]),
    ('western-development-museum-saskatoon', 'saskatoon', 'MUSEUM', 3, 4.7, 'Western Development Museum', 'Western Development Museum Saskatoon', 'Western Development Museum Saskatoon', 52.09870000, -106.65890000, 'Western_Development_Museum_Saskatoon.jpg', ARRAY['saskatoon', 'history', 'family']::text[]),
    ('nutrien-wonderhub', 'saskatoon', 'ENTERTAINMENT', 2, 4.5, 'Nutrien Wonderhub', 'Nutrien Wonderhub', 'Nutrien Wonderhub', 52.13520000, -106.66290000, 'Nutrien_Wonderhub.jpg', ARRAY['saskatoon', 'family', 'children']::text[]),
    ('meewasin-valley-trail', 'saskatoon', 'PARK', 3, 4.7, 'Meewasin Valley Trail', 'Meewasin Valley Trail', 'Meewasin Valley Trail', 52.13240000, -106.65120000, 'Meewasin_Valley_Trail.jpg', ARRAY['saskatoon', 'river', 'trail']::text[]),
    ('gather-local-market', 'saskatoon', 'MARKET', 1, 4.4, 'Gather Local Market', 'Gather Local Market', 'Gather Local Market', 52.12630000, -106.66840000, 'Gather_Local_Market_Saskatoon.jpg', ARRAY['saskatoon', 'food-market', 'local']::text[]),

    ('royal-saskatchewan-museum', 'regina', 'MUSEUM', 2, 4.6, 'Королевский музей Саскачевана', 'Royal Saskatchewan Museum', 'Саскачеван корольдік музейі', 50.44100000, -104.61790000, 'Royal_Saskatchewan_Museum.jpg', ARRAY['regina', 'museum', 'family']::text[]),
    ('rcmp-heritage-centre', 'regina', 'MUSEUM', 2, 4.6, 'RCMP Heritage Centre', 'RCMP Heritage Centre', 'RCMP Heritage Centre', 50.45270000, -104.66670000, 'RCMP_Heritage_Centre.jpg', ARRAY['regina', 'history', 'indoor']::text[]),
    ('wascana-centre', 'regina', 'PARK', 3, 4.7, 'Wascana Centre', 'Wascana Centre', 'Wascana Centre', 50.43690000, -104.60100000, 'Wascana_Centre_Regina.jpg', ARRAY['regina', 'park', 'lake']::text[]),
    ('saskatchewan-science-centre', 'regina', 'ENTERTAINMENT', 2, 4.5, 'Saskatchewan Science Centre', 'Saskatchewan Science Centre', 'Saskatchewan Science Centre', 50.43180000, -104.60220000, 'Saskatchewan_Science_Centre.jpg', ARRAY['regina', 'science', 'family']::text[]),
    ('mackenzie-art-gallery', 'regina', 'MUSEUM', 2, 4.5, 'MacKenzie Art Gallery', 'MacKenzie Art Gallery', 'MacKenzie Art Gallery', 50.42120000, -104.61980000, 'MacKenzie_Art_Gallery.jpg', ARRAY['regina', 'art', 'indoor']::text[]),
    ('regina-farmers-market', 'regina', 'MARKET', 1, 4.4, 'Regina Farmers Market', 'Regina Farmers Market', 'Regina Farmers Market', 50.44890000, -104.61290000, 'Regina_Farmers_Market.jpg', ARRAY['regina', 'food-market', 'local']::text[]),

    ('halifax-citadel', 'halifax', 'ARCHITECTURE', 3, 4.7, 'Цитадель Галифакса', 'Halifax Citadel', 'Галифакс цитаделі', 44.64750000, -63.58030000, 'Halifax_Citadel.jpg', ARRAY['halifax', 'fort', 'history']::text[]),
    ('halifax-waterfront-boardwalk', 'halifax', 'PARK', 2, 4.7, 'Набережная Галифакса', 'Halifax Waterfront Boardwalk', 'Галифакс жағалауы', 44.64550000, -63.56980000, 'Halifax_Waterfront_Boardwalk.jpg', ARRAY['halifax', 'waterfront', 'walk']::text[]),
    ('maritime-museum-atlantic', 'halifax', 'MUSEUM', 2, 4.6, 'Морской музей Атлантики', 'Maritime Museum of the Atlantic', 'Атлантика теңіз музейі', 44.64740000, -63.57130000, 'Maritime_Museum_of_the_Atlantic.jpg', ARRAY['halifax', 'maritime', 'indoor']::text[]),
    ('pier-21', 'halifax', 'MUSEUM', 2, 4.6, 'Канадский музей иммиграции Pier 21', 'Canadian Museum of Immigration at Pier 21', 'Pier 21 иммиграция музейі', 44.63750000, -63.56570000, 'Pier_21_Halifax.jpg', ARRAY['halifax', 'history', 'museum']::text[]),
    ('halifax-seaport-farmers-market', 'halifax', 'MARKET', 1, 4.5, 'Halifax Seaport Farmers Market', 'Halifax Seaport Farmers Market', 'Halifax Seaport Farmers Market', 44.63910000, -63.56700000, 'Halifax_Seaport_Farmers_Market.jpg', ARRAY['halifax', 'food-market', 'seaport']::text[]),
    ('halifax-public-gardens', 'halifax', 'PARK', 1, 4.7, 'Общественные сады Галифакса', 'Halifax Public Gardens', 'Галифакс қоғамдық бақтары', 44.64270000, -63.58260000, 'Halifax_Public_Gardens.jpg', ARRAY['halifax', 'garden', 'central']::text[]),

    ('confederation-centre-arts', 'charlottetown', 'ENTERTAINMENT', 2, 4.6, 'Confederation Centre of the Arts', 'Confederation Centre of the Arts', 'Confederation Centre of the Arts', 46.23430000, -63.12770000, 'Confederation_Centre_of_the_Arts.jpg', ARRAY['charlottetown', 'theatre', 'culture']::text[]),
    ('province-house', 'charlottetown', 'ARCHITECTURE', 1, 4.5, 'Province House', 'Province House', 'Province House', 46.23450000, -63.12650000, 'Province_House_Prince_Edward_Island.jpg', ARRAY['charlottetown', 'government', 'history']::text[]),
    ('victoria-row', 'charlottetown', 'SHOPPING', 1, 4.5, 'Victoria Row', 'Victoria Row', 'Victoria Row', 46.23400000, -63.12700000, 'Victoria_Row_Charlottetown.jpg', ARRAY['charlottetown', 'shopping-street', 'restaurants']::text[]),
    ('founders-food-hall', 'charlottetown', 'FOOD', 1, 4.4, 'Founders Food Hall', 'Founders Food Hall', 'Founders Food Hall', 46.23320000, -63.12260000, 'Founders_Food_Hall_Charlottetown.jpg', ARRAY['charlottetown', 'food-hall', 'market']::text[]),
    ('green-gables-heritage-place', 'charlottetown', 'ARCHITECTURE', 3, 4.7, 'Green Gables Heritage Place', 'Green Gables Heritage Place', 'Green Gables Heritage Place', 46.48830000, -63.38190000, 'Green_Gables_Heritage_Place.jpg', ARRAY['charlottetown', 'literary', 'parks-canada']::text[]),

    ('signal-hill', 'st-johns', 'ARCHITECTURE', 3, 4.8, 'Signal Hill', 'Signal Hill', 'Signal Hill', 47.57060000, -52.68190000, 'Signal_Hill_Newfoundland.jpg', ARRAY['st-johns', 'viewpoint', 'history']::text[]),
    ('the-rooms', 'st-johns', 'MUSEUM', 2, 4.6, 'The Rooms', 'The Rooms', 'The Rooms', 47.56660000, -52.71300000, 'The_Rooms_St_Johns.jpg', ARRAY['st-johns', 'museum', 'art']::text[]),
    ('quidi-vidi-village', 'st-johns', 'PARK', 2, 4.6, 'Quidi Vidi Village', 'Quidi Vidi Village', 'Quidi Vidi Village', 47.58470000, -52.67960000, 'Quidi_Vidi_Village.jpg', ARRAY['st-johns', 'harbour', 'walk']::text[]),
    ('george-street', 'st-johns', 'ENTERTAINMENT', 2, 4.5, 'George Street', 'George Street', 'George Street', 47.56170000, -52.71080000, 'George_Street_St_Johns.jpg', ARRAY['st-johns', 'nightlife', 'music']::text[]),
    ('johnson-geo-centre', 'st-johns', 'MUSEUM', 2, 4.5, 'Johnson Geo Centre', 'Johnson Geo Centre', 'Johnson Geo Centre', 47.56920000, -52.68840000, 'Johnson_Geo_Centre.jpg', ARRAY['st-johns', 'science', 'indoor']::text[]),
    ('cape-spear', 'st-johns', 'NATURE', 3, 4.8, 'Мыс Спир', 'Cape Spear Lighthouse National Historic Site', 'Кейп-Спир шамшырағы', 47.52360000, -52.62350000, 'Cape_Spear_Lighthouse.jpg', ARRAY['st-johns', 'lighthouse', 'easternmost']::text[]),

    ('ss-klondike', 'whitehorse', 'MUSEUM', 2, 4.6, 'S.S. Klondike', 'S.S. Klondike National Historic Site', 'S.S. Klondike ұлттық тарихи орны', 60.71350000, -135.04700000, 'SS_Klondike_Whitehorse.jpg', ARRAY['whitehorse', 'riverboat', 'history']::text[]),
    ('miles-canyon', 'whitehorse', 'NATURE', 3, 4.8, 'Каньон Miles', 'Miles Canyon', 'Miles Canyon', 60.65860000, -134.99340000, 'Miles_Canyon_Yukon.jpg', ARRAY['whitehorse', 'canyon', 'hiking']::text[]),
    ('yukon-wildlife-preserve', 'whitehorse', 'NATURE', 3, 4.7, 'Yukon Wildlife Preserve', 'Yukon Wildlife Preserve', 'Yukon Wildlife Preserve', 60.85600000, -135.20200000, 'Yukon_Wildlife_Preserve.jpg', ARRAY['whitehorse', 'wildlife', 'family']::text[]),
    ('macbride-museum', 'whitehorse', 'MUSEUM', 2, 4.5, 'MacBride Museum', 'MacBride Museum', 'MacBride Museum', 60.72120000, -135.05170000, 'MacBride_Museum_Whitehorse.jpg', ARRAY['whitehorse', 'museum', 'history']::text[]),
    ('beringia-interpretive-centre', 'whitehorse', 'MUSEUM', 2, 4.5, 'Yukon Beringia Interpretive Centre', 'Yukon Beringia Interpretive Centre', 'Yukon Beringia Interpretive Centre', 60.70900000, -135.07300000, 'Yukon_Beringia_Interpretive_Centre.jpg', ARRAY['whitehorse', 'museum', 'ice-age']::text[]),

    ('northern-lights-yellowknife', 'yellowknife', 'NATURE', 3, 4.9, 'Северное сияние в Йеллоунайфе', 'Northern Lights in Yellowknife', 'Йеллоунайфтағы солтүстік шұғыла', 62.45400000, -114.37180000, 'Aurora_borealis_Yellowknife.jpg', ARRAY['yellowknife', 'aurora', 'winter']::text[]),
    ('bush-pilots-monument', 'yellowknife', 'ARCHITECTURE', 1, 4.6, 'Bush Pilots Monument', 'Bush Pilots Monument', 'Bush Pilots Monument', 62.46090000, -114.34690000, 'Bush_Pilots_Monument_Yellowknife.jpg', ARRAY['yellowknife', 'viewpoint', 'old-town']::text[]),
    ('prince-of-wales-northern-heritage-centre', 'yellowknife', 'MUSEUM', 2, 4.6, 'Prince of Wales Northern Heritage Centre', 'Prince of Wales Northern Heritage Centre', 'Prince of Wales Northern Heritage Centre', 62.45480000, -114.37370000, 'Prince_of_Wales_Northern_Heritage_Centre.jpg', ARRAY['yellowknife', 'museum', 'north']::text[]),
    ('old-town-yellowknife', 'yellowknife', 'PARK', 2, 4.5, 'Old Town Yellowknife', 'Old Town Yellowknife', 'Old Town Yellowknife', 62.46070000, -114.34630000, 'Old_Town_Yellowknife.jpg', ARRAY['yellowknife', 'walk', 'waterfront']::text[]),

    ('polar-bears-churchill', 'churchill', 'NATURE', 5, 4.9, 'Белые медведи Черчилла', 'Polar Bears of Churchill', 'Черчилл ақ аюлары', 58.76840000, -94.16480000, 'Polar_Bear_Churchill_Manitoba.jpg', ARRAY['churchill', 'wildlife', 'seasonal']::text[]),
    ('beluga-whale-watching', 'churchill', 'NATURE', 4, 4.8, 'Наблюдение за белухами', 'Beluga Whale Watching', 'Ақ киттерді бақылау', 58.76800000, -94.16600000, 'Beluga_Whale_Churchill.jpg', ARRAY['churchill', 'wildlife', 'summer']::text[]),
    ('itsanitaq-museum', 'churchill', 'MUSEUM', 2, 4.6, 'Itsanitaq Museum', 'Itsanitaq Museum', 'Itsanitaq Museum', 58.76760000, -94.16670000, 'Itsanitaq_Museum_Churchill.jpg', ARRAY['churchill', 'museum', 'inuit-culture']::text[]),
    ('prince-of-wales-fort', 'churchill', 'ARCHITECTURE', 3, 4.6, 'Prince of Wales Fort', 'Prince of Wales Fort', 'Prince of Wales Fort', 58.78900000, -94.21300000, 'Prince_of_Wales_Fort_Churchill.jpg', ARRAY['churchill', 'fort', 'history']::text[]),
    ('churchill-northern-studies-centre', 'churchill', 'MUSEUM', 2, 4.5, 'Churchill Northern Studies Centre', 'Churchill Northern Studies Centre', 'Churchill Northern Studies Centre', 58.73420000, -93.81920000, 'Churchill_Northern_Studies_Centre.jpg', ARRAY['churchill', 'science', 'north']::text[]),
    ('northern-lights-churchill', 'churchill', 'NATURE', 3, 4.8, 'Северное сияние в Черчилле', 'Northern Lights in Churchill', 'Черчиллдегі солтүстік шұғыла', 58.76840000, -94.16480000, 'Aurora_Borealis_Churchill.jpg', ARRAY['churchill', 'aurora', 'winter']::text[]);

CREATE TEMP TABLE seed_canada_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-canada-place:' || seed.slug) AS place_hash,
        md5('id-canada-media:' || seed.slug) AS media_hash
    FROM seed_canada_priority_places seed
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
    'HOURS'::varchar(16) AS duration_unit,
    rating,
    ARRAY['canada', city_id, slug, lower(category), 'canada-seed-v1']::text[] || extra_tags AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Канады: ' || title_ru || '. Перед посещением проверяйте актуальное расписание, стоимость и правила доступа.' AS description_ru,
    'Canada tourist place: ' || title_en || '. Check current schedule, price, and access rules before visiting.' AS description_en,
    'Канада туристік орны: ' || title_kk || '. Бармас бұрын кестені, бағаны және кіру ережелерін тексеріңіз.' AS description_kk,
    latitude,
    longitude,
    'https://www.openstreetmap.org/search?query=' || replace(title_en || ' Canada', ' ', '%20') AS location_source_url,
    ARRAY[city_id]::text[] AS access_city_ids,
    ARRAY[city_id]::text[] AS departure_city_ids,
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
    'CA',
    city_id,
    category,
    NULL::numeric,
    'CAD',
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
FROM seed_canada_resolved_places
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
FROM seed_canada_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_canada_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_canada_resolved_places
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
FROM seed_canada_resolved_places seed
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
FROM seed_canada_resolved_places
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
    'CA',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_canada_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'CA',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_canada_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;
