-- Priority Seychelles destination places seed.
-- Seychelles is seeded as an island-country destination with city-like tourist
-- hubs for admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_seychelles_resolved_places;
DROP TABLE IF EXISTS seed_seychelles_priority_places;

CREATE TEMP TABLE seed_seychelles_priority_places (
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

INSERT INTO seed_seychelles_priority_places (
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
    ('sir-selwyn-selwyn-clarke-market', 'victoria', 'MARKET', 2, 'HOURS', 4.6, 'Рынок сэра Селвина Селвина-Кларка', 'Sir Selwyn Selwyn-Clarke Market', 'Сэр Селвин Селвин-Кларк базары', -4.62060000, 55.45310000, 'Sir Selwyn Selwyn-Clarke Market Victoria Seychelles', ARRAY['victoria', 'beau-vallon', 'eden-island']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('victoria-clock-tower', 'victoria', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Часовая башня Виктории', 'Victoria Clock Tower', 'Виктория сағат мұнарасы', -4.62310000, 55.45240000, 'Victoria Clock Tower Seychelles', ARRAY['victoria']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('seychelles-national-museum-history', 'victoria', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный исторический музей Сейшел', 'Seychelles National Museum of History', 'Сейшел ұлттық тарих музейі', -4.62350000, 55.45270000, 'Seychelles National Museum of History Victoria', ARRAY['victoria']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('seychelles-natural-history-museum', 'victoria', 'MUSEUM', 1, 'HOURS', 4.3, 'Музей естественной истории Сейшел', 'Seychelles Natural History Museum', 'Сейшел табиғат тарихы музейі', -4.62370000, 55.45290000, 'Seychelles Natural History Museum Victoria', ARRAY['victoria']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('immaculate-conception-cathedral-victoria', 'victoria', 'TEMPLE', 1, 'HOURS', 4.4, 'Собор Непорочного Зачатия', 'Immaculate Conception Cathedral Victoria', 'Викториядағы Мінсіз Ұрықтану соборы', -4.62150000, 55.45300000, 'Immaculate Conception Cathedral Victoria Seychelles', ARRAY['victoria']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('arul-mihu-navasakthi-vinayagar-temple', 'victoria', 'TEMPLE', 1, 'HOURS', 4.4, 'Храм Арул Миху Навасакти Винаягар', 'Arul Mihu Navasakthi Vinayagar Temple', 'Арул Миху Навасакти Винаягар храмы', -4.62090000, 55.45380000, 'Arul Mihu Navasakthi Vinayagar Temple Victoria Seychelles', ARRAY['victoria']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('seychelles-national-botanical-garden', 'victoria', 'PARK', 2, 'HOURS', 4.7, 'Национальный ботанический сад Сейшел', 'Seychelles National Botanical Garden', 'Сейшел ұлттық ботаникалық бағы', -4.63100000, 55.45120000, 'Seychelles National Botanical Garden Victoria', ARRAY['victoria', 'beau-vallon', 'eden-island']::text[], ARRAY['victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('beau-vallon-beach', 'beau-vallon', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Бо-Валлон', 'Beau Vallon Beach', 'Бо-Валлон жағажайы', -4.60010000, 55.43190000, 'Beau Vallon Beach Mahe Seychelles', ARRAY['beau-vallon', 'victoria']::text[], ARRAY['beau-vallon', 'victoria']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('bazar-labrin-beau-vallon', 'beau-vallon', 'MARKET', 2, 'HOURS', 4.5, 'Вечерний рынок Bazar Labrin', 'Bazar Labrin Beau Vallon', 'Бо-Валлон Bazar Labrin базары', -4.61200000, 55.42760000, 'Bazar Labrin Beau Vallon Seychelles', ARRAY['beau-vallon', 'victoria']::text[], ARRAY['beau-vallon']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('beau-vallon-night-food-stalls', 'beau-vallon', 'FOOD', 2, 'HOURS', 4.4, 'Вечерние киоски Бо-Валлона', 'Beau Vallon Night Food Stalls', 'Бо-Валлон кешкі тағам дүңгіршектері', -4.61220000, 55.42750000, 'Beau Vallon food stalls Seychelles', ARRAY['beau-vallon']::text[], ARRAY['beau-vallon']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('morne-seychellois-national-park', 'mahe', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Морн-Сейшелуа', 'Morne Seychellois National Park', 'Морн-Сейшелуа ұлттық паркі', -4.65000000, 55.43330000, 'Morne Seychellois National Park Mahe Seychelles', ARRAY['mahe', 'victoria', 'port-glaud']::text[], ARRAY['mahe', 'victoria']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('copolia-trail', 'mahe', 'NATURE', 3, 'HOURS', 4.8, 'Тропа Кополия', 'Copolia Trail', 'Кополия соқпағы', -4.65090000, 55.44420000, 'Copolia Trail Mahe Seychelles', ARRAY['mahe', 'victoria']::text[], ARRAY['mahe', 'victoria']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('mission-lodge', 'mahe', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мишн-Лодж', 'Mission Lodge', 'Мишн-Лодж', -4.65370000, 55.43470000, 'Mission Lodge Mahe Seychelles', ARRAY['mahe', 'victoria']::text[], ARRAY['mahe']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('morne-blanc-trail', 'mahe', 'NATURE', 3, 'HOURS', 4.7, 'Тропа Морн-Блан', 'Morne Blanc Trail', 'Морн-Блан соқпағы', -4.65770000, 55.43010000, 'Morne Blanc Trail Seychelles', ARRAY['mahe', 'victoria']::text[], ARRAY['mahe']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('anse-major-trail', 'mahe', 'NATURE', 3, 'HOURS', 4.7, 'Тропа Анс-Мажор', 'Anse Major Trail', 'Анс-Мажор соқпағы', -4.56670000, 55.38690000, 'Anse Major Trail Mahe Seychelles', ARRAY['mahe', 'beau-vallon']::text[], ARRAY['beau-vallon']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('port-launay-marine-national-park', 'port-glaud', 'PARK', 4, 'HOURS', 4.7, 'Морской национальный парк Порт-Лоне', 'Port Launay Marine National Park', 'Порт-Лоне теңіз ұлттық паркі', -4.65100000, 55.39400000, 'Port Launay Marine National Park Seychelles', ARRAY['port-glaud', 'mahe']::text[], ARRAY['port-glaud', 'victoria']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('port-launay-beach', 'port-glaud', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Порт-Лоне', 'Port Launay Beach', 'Порт-Лоне жағажайы', -4.65060000, 55.39080000, 'Port Launay Beach Seychelles', ARRAY['port-glaud', 'mahe']::text[], ARRAY['port-glaud']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('sauzier-waterfall', 'port-glaud', 'NATURE', 1, 'HOURS', 4.4, 'Водопад Созье', 'Sauzier Waterfall', 'Созье сарқырамасы', -4.65600000, 55.40600000, 'Sauzier Waterfall Port Glaud Seychelles', ARRAY['port-glaud', 'mahe']::text[], ARRAY['port-glaud']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('eden-plaza', 'eden-island', 'SHOPPING', 2, 'HOURS', 4.4, 'Eden Plaza', 'Eden Plaza', 'Eden Plaza', -4.64150000, 55.47700000, 'Eden Plaza Seychelles', ARRAY['eden-island', 'victoria']::text[], ARRAY['eden-island', 'victoria']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('eden-island-marina', 'eden-island', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Марина Eden Island', 'Eden Island Marina', 'Eden Island маринасы', -4.64110000, 55.47640000, 'Eden Island Marina Seychelles', ARRAY['eden-island', 'victoria']::text[], ARRAY['eden-island']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('eden-island-waterfront-restaurants', 'eden-island', 'FOOD', 2, 'HOURS', 4.4, 'Рестораны набережной Eden Island', 'Eden Island Waterfront Restaurants', 'Eden Island жағалауы мейрамханалары', -4.64100000, 55.47770000, 'Eden Island restaurants Seychelles', ARRAY['eden-island']::text[], ARRAY['eden-island']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('anse-royale-beach', 'anse-royale', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Анс-Руаяль', 'Anse Royale Beach', 'Анс-Руаяль жағажайы', -4.74060000, 55.52280000, 'Anse Royale Beach Seychelles', ARRAY['anse-royale', 'mahe']::text[], ARRAY['anse-royale']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('domaine-val-des-pres-craft-village', 'anse-royale', 'SHOPPING', 2, 'HOURS', 4.3, 'Ремесленная деревня Domaine de Val des Pres', 'Domaine de Val des Pres Craft Village', 'Domaine de Val des Pres қолөнер ауылы', -4.72250000, 55.51870000, 'Domaine de Val des Pres Seychelles', ARRAY['anse-royale', 'mahe']::text[], ARRAY['anse-royale']::text[], 'Victoria clock tower Seychelles.jpg'),
    ('jardin-du-roi-spice-garden', 'anse-royale', 'PARK', 2, 'HOURS', 4.6, 'Сад специй Jardin du Roi', 'Jardin du Roi Spice Garden', 'Jardin du Roi дәмдеуіш бағы', -4.74620000, 55.51190000, 'Jardin du Roi Spice Garden Seychelles', ARRAY['anse-royale', 'takamaka']::text[], ARRAY['anse-royale']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('takamaka-beach', 'takamaka', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Такамака', 'Takamaka Beach', 'Такамака жағажайы', -4.79570000, 55.50220000, 'Takamaka Beach Mahe Seychelles', ARRAY['takamaka', 'mahe']::text[], ARRAY['takamaka']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('anse-intendance', 'takamaka', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Анс-Интенданс', 'Anse Intendance', 'Анс-Интенданс жағажайы', -4.78560000, 55.49770000, 'Anse Intendance Mahe Seychelles', ARRAY['takamaka', 'mahe']::text[], ARRAY['takamaka']::text[], 'Beau Vallon Beach (11177463746).jpg'),
    ('takamaka-rum-distillery', 'takamaka', 'FOOD', 2, 'HOURS', 4.5, 'Дистиллерия Takamaka Rum', 'Takamaka Rum Distillery', 'Takamaka Rum дистиллериясы', -4.72090000, 55.51940000, 'Takamaka Rum Distillery Seychelles', ARRAY['takamaka', 'anse-royale']::text[], ARRAY['takamaka']::text[], 'Victoria clock tower Seychelles.jpg'),

    ('vallee-de-mai-nature-reserve', 'praslin', 'NATURE', 3, 'HOURS', 4.9, 'Заповедник Валле-де-Мэ', 'Vallee de Mai Nature Reserve', 'Валле-де-Мэ қорығы', -4.32970000, 55.73700000, 'Vallee de Mai Praslin Seychelles', ARRAY['praslin', 'grand-anse-praslin', 'baie-sainte-anne']::text[], ARRAY['praslin']::text[], 'Vallée de Mai, Praslin, Seychelles.jpg'),
    ('praslin-national-park', 'baie-sainte-anne', 'PARK', 3, 'HOURS', 4.7, 'Национальный парк Праслин', 'Praslin National Park', 'Праслин ұлттық паркі', -4.32900000, 55.73900000, 'Praslin National Park Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Vallée de Mai, Praslin, Seychelles.jpg'),
    ('glacis-noire-trail', 'baie-sainte-anne', 'NATURE', 2, 'HOURS', 4.6, 'Тропа Гласис-Нуар', 'Glacis Noire Trail', 'Гласис-Нуар соқпағы', -4.32290000, 55.74400000, 'Glacis Noire Trail Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Vallée de Mai, Praslin, Seychelles.jpg'),
    ('fond-ferdinand-nature-reserve', 'grand-anse-praslin', 'NATURE', 3, 'HOURS', 4.7, 'Заповедник Фонд-Фердинанд', 'Fond Ferdinand Nature Reserve', 'Фонд-Фердинанд қорығы', -4.35080000, 55.75600000, 'Fond Ferdinand Nature Reserve Praslin Seychelles', ARRAY['grand-anse-praslin', 'praslin']::text[], ARRAY['grand-anse-praslin']::text[], 'Vallée de Mai, Praslin, Seychelles.jpg'),
    ('anse-lazio', 'praslin', 'BEACH', 4, 'HOURS', 4.9, 'Пляж Анс-Лацио', 'Anse Lazio', 'Анс-Лацио жағажайы', -4.29360000, 55.70170000, 'Anse Lazio Praslin Seychelles', ARRAY['praslin', 'grand-anse-praslin']::text[], ARRAY['praslin']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('anse-georgette', 'grand-anse-praslin', 'BEACH', 4, 'HOURS', 4.8, 'Пляж Анс-Жоржетт', 'Anse Georgette', 'Анс-Жоржетт жағажайы', -4.29490000, 55.68100000, 'Anse Georgette Praslin Seychelles', ARRAY['grand-anse-praslin', 'praslin']::text[], ARRAY['grand-anse-praslin']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('anse-volbert-cote-dor', 'baie-sainte-anne', 'BEACH', 4, 'HOURS', 4.7, 'Анс-Вольбер / Кот-д’Ор', 'Anse Volbert Cote d''Or', 'Анс-Вольбер Кот-д’Ор', -4.31350000, 55.74390000, 'Anse Volbert Cote d Or Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('anse-kerlan', 'grand-anse-praslin', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Анс-Керлан', 'Anse Kerlan', 'Анс-Керлан жағажайы', -4.31800000, 55.68200000, 'Anse Kerlan Praslin Seychelles', ARRAY['grand-anse-praslin', 'praslin']::text[], ARRAY['grand-anse-praslin']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('anse-boudin', 'baie-sainte-anne', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Анс-Буден', 'Anse Boudin', 'Анс-Буден жағажайы', -4.29450000, 55.71300000, 'Anse Boudin Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('curieuse-marine-national-park', 'curieuse-island', 'PARK', 4, 'HOURS', 4.8, 'Морской национальный парк Кюрьёз', 'Curieuse Marine National Park', 'Кюрьёз теңіз ұлттық паркі', -4.28280000, 55.72440000, 'Curieuse Marine National Park Seychelles', ARRAY['curieuse-island', 'praslin']::text[], ARRAY['curieuse-island', 'praslin']::text[], 'Beach on Curieuse island Seychelles (27839924989).jpg'),
    ('baie-laraie-tortoise-sanctuary', 'curieuse-island', 'NATURE', 2, 'HOURS', 4.7, 'Бэ-Ларе и черепахи Альдабра', 'Baie Laraie Tortoise Sanctuary', 'Бэ-Ларе Альдабра тасбақалары', -4.27950000, 55.71900000, 'Baie Laraie tortoise Curieuse Seychelles', ARRAY['curieuse-island']::text[], ARRAY['curieuse-island']::text[], 'Beach on Curieuse island Seychelles (27839924989).jpg'),
    ('anse-jose-curieuse', 'curieuse-island', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Анс-Жозе', 'Anse Jose Curieuse', 'Кюрьёз Анс-Жозе жағажайы', -4.28650000, 55.73500000, 'Anse Jose Curieuse Seychelles', ARRAY['curieuse-island']::text[], ARRAY['curieuse-island']::text[], 'Beach on Curieuse island Seychelles (27839924989).jpg'),
    ('doctors-house-curieuse', 'curieuse-island', 'MUSEUM', 1, 'HOURS', 4.4, 'Дом доктора на Кюрьёзе', 'Doctor''s House Curieuse', 'Кюрьёз дәрігер үйі', -4.28600000, 55.73500000, 'Doctors House Curieuse Seychelles', ARRAY['curieuse-island']::text[], ARRAY['curieuse-island']::text[], 'Beach on Curieuse island Seychelles (27839924989).jpg'),
    ('cousin-island-special-reserve', 'cousin-island', 'NATURE', 3, 'HOURS', 4.8, 'Специальный заповедник острова Кузен', 'Cousin Island Special Reserve', 'Кузен аралы арнайы қорығы', -4.33140000, 55.66310000, 'Cousin Island Special Reserve Seychelles', ARRAY['cousin-island', 'praslin']::text[], ARRAY['cousin-island', 'praslin']::text[], 'Cousin island.jpg'),
    ('st-pierre-islet-praslin', 'baie-sainte-anne', 'NATURE', 2, 'HOURS', 4.6, 'Островок Сен-Пьер', 'St Pierre Islet Praslin', 'Праслин Сен-Пьер аралшасы', -4.30500000, 55.75000000, 'St Pierre Island Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('praslin-museum', 'baie-sainte-anne', 'MUSEUM', 1, 'HOURS', 4.3, 'Музей Праслина', 'Praslin Museum', 'Праслин музейі', -4.31600000, 55.75200000, 'Praslin Museum Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Vallée de Mai, Praslin, Seychelles.jpg'),
    ('cote-dor-fruit-fish-market', 'baie-sainte-anne', 'MARKET', 1, 'HOURS', 4.3, 'Фруктово-рыбный рынок Кот-д’Ор', 'Cote d''Or Fruit and Fish Market', 'Кот-д’Ор жеміс-балық базары', -4.31500000, 55.75000000, 'Cote d Or Market Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('cote-dor-esplanade', 'baie-sainte-anne', 'SHOPPING', 2, 'HOURS', 4.3, 'Эспланада Кот-д’Ор', 'Cote d''Or Esplanade', 'Кот-д’Ор эспланадасы', -4.31300000, 55.74500000, 'Cote d Or Esplanade Praslin Seychelles', ARRAY['baie-sainte-anne', 'praslin']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),
    ('cafe-des-arts-praslin', 'baie-sainte-anne', 'FOOD', 2, 'HOURS', 4.4, 'Cafe des Arts', 'Cafe des Arts Praslin', 'Cafe des Arts Праслин', -4.31300000, 55.74600000, 'Cafe des Arts Praslin Seychelles', ARRAY['baie-sainte-anne']::text[], ARRAY['baie-sainte-anne']::text[], 'Anse Lazio beach Praslin Seychelles.jpg'),

    ('lunion-estate', 'anse-reunion', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Усадьба Л’Юньон', $$L'Union Estate$$, 'Л’Юньон усадьбасы', -4.36600000, 55.82850000, 'L Union Estate La Digue Seychelles', ARRAY['anse-reunion', 'la-digue']::text[], ARRAY['la-digue']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('anse-source-dargent', 'anse-reunion', 'BEACH', 4, 'HOURS', 4.9, 'Пляж Анс-Сурс-д’Аржан', $$Anse Source d'Argent$$, 'Анс-Сурс-д’Аржан жағажайы', -4.37170000, 55.82730000, 'Anse Source d Argent La Digue Seychelles', ARRAY['anse-reunion', 'la-digue']::text[], ARRAY['la-digue']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('grand-anse-la-digue', 'la-digue', 'BEACH', 3, 'HOURS', 4.8, 'Гранд-Анс Ла-Диг', 'Grand Anse La Digue', 'Ла-Диг Гранд-Анс', -4.35690000, 55.84190000, 'Grand Anse La Digue Seychelles', ARRAY['la-digue']::text[], ARRAY['la-digue']::text[], 'Grand Anse-La Digue-Seychellen.jpg'),
    ('petite-anse-la-digue', 'la-digue', 'BEACH', 3, 'HOURS', 4.7, 'Пти-Анс Ла-Диг', 'Petite Anse La Digue', 'Ла-Диг Пти-Анс', -4.36100000, 55.84670000, 'Petite Anse La Digue Seychelles', ARRAY['la-digue']::text[], ARRAY['la-digue']::text[], 'Grand Anse-La Digue-Seychellen.jpg'),
    ('anse-cocos', 'la-digue', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Анс-Кокос', 'Anse Cocos', 'Анс-Кокос жағажайы', -4.36510000, 55.85260000, 'Anse Cocos La Digue Seychelles', ARRAY['la-digue']::text[], ARRAY['la-digue']::text[], 'Anse Cocos-La Digue-Seychelles.jpg'),
    ('anse-severe', 'la-digue', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Анс-Север', 'Anse Severe', 'Анс-Север жағажайы', -4.33880000, 55.82680000, 'Anse Severe La Digue Seychelles', ARRAY['la-digue', 'la-passe']::text[], ARRAY['la-digue']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('nid-daigle', 'la-digue', 'NATURE', 3, 'HOURS', 4.7, 'Тропа Нид д’Эгль', $$Nid d'Aigle$$, 'Нид д’Эгль соқпағы', -4.35440000, 55.83610000, 'Nid d Aigle La Digue Seychelles', ARRAY['la-digue']::text[], ARRAY['la-digue']::text[], 'Grand Anse-La Digue-Seychellen.jpg'),
    ('veuve-special-reserve', 'anse-reunion', 'PARK', 2, 'HOURS', 4.5, 'Специальный заповедник Вёв', 'Veuve Special Reserve', 'Вёв арнайы қорығы', -4.35600000, 55.82900000, 'Veuve Special Reserve La Digue Seychelles', ARRAY['anse-reunion', 'la-digue']::text[], ARRAY['anse-reunion']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('plantation-house-la-digue', 'anse-reunion', 'MUSEUM', 1, 'HOURS', 4.4, 'Плантационный дом Гран Каз', 'Grand Kaz Plantation House', 'Гран Каз плантациялық үйі', -4.36580000, 55.82840000, 'Grand Kaz Plantation House La Digue Seychelles', ARRAY['anse-reunion']::text[], ARRAY['anse-reunion']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('la-passe-local-shops', 'la-passe', 'SHOPPING', 2, 'HOURS', 4.3, 'Лавки Ла-Пасс', 'La Passe Local Shops', 'Ла-Пасс жергілікті дүкендері', -4.34800000, 55.82700000, 'La Passe La Digue Seychelles shops', ARRAY['la-passe', 'la-digue']::text[], ARRAY['la-passe']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('le-repaire-la-digue', 'la-passe', 'FOOD', 2, 'HOURS', 4.5, 'Le Repaire', 'Le Repaire La Digue', 'Le Repaire Ла-Диг', -4.35250000, 55.82700000, 'Le Repaire La Digue Seychelles', ARRAY['la-passe', 'la-digue']::text[], ARRAY['la-passe']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),
    ('ile-cocos-marine-national-park', 'ile-cocos', 'PARK', 4, 'HOURS', 4.8, 'Морской национальный парк Иль-Кокос', 'Ile Cocos Marine National Park', 'Иль-Кокос теңіз ұлттық паркі', -4.28100000, 55.86700000, 'Ile Cocos Marine National Park Seychelles', ARRAY['ile-cocos', 'la-digue', 'praslin']::text[], ARRAY['ile-cocos', 'la-digue']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG'),

    ('sainte-anne-marine-national-park', 'sainte-anne-island', 'PARK', 4, 'HOURS', 4.8, 'Морской национальный парк Сент-Анн', 'Sainte Anne Marine National Park', 'Сент-Анн теңіз ұлттық паркі', -4.61670000, 55.50000000, 'Sainte Anne Marine National Park Seychelles', ARRAY['sainte-anne-island', 'cerf-island', 'moyenne-island', 'victoria']::text[], ARRAY['victoria', 'sainte-anne-island']::text[], 'Sainte Anne Marine Park asv2024-10 img19.jpg'),
    ('sainte-anne-island', 'sainte-anne-island', 'NATURE', 3, 'HOURS', 4.6, 'Остров Сент-Анн', 'Sainte Anne Island', 'Сент-Анн аралы', -4.60000000, 55.50000000, 'Sainte Anne Island Seychelles', ARRAY['sainte-anne-island']::text[], ARRAY['sainte-anne-island', 'victoria']::text[], 'Sainte Anne Marine Park asv2024-10 img19.jpg'),
    ('cerf-island-snorkeling', 'cerf-island', 'BEACH', 3, 'HOURS', 4.6, 'Сноркелинг у острова Серф', 'Cerf Island Snorkeling', 'Серф аралы снорклингі', -4.63300000, 55.50000000, 'Cerf Island snorkeling Seychelles', ARRAY['cerf-island', 'sainte-anne-island']::text[], ARRAY['victoria', 'cerf-island']::text[], 'Sainte Anne Marine Park asv2024-10 img19.jpg'),
    ('moyenne-island-national-park', 'moyenne-island', 'PARK', 3, 'HOURS', 4.7, 'Национальный парк острова Муаен', 'Moyenne Island National Park', 'Муаен аралы ұлттық паркі', -4.61670000, 55.50000000, 'Moyenne Island National Park Seychelles', ARRAY['moyenne-island', 'sainte-anne-island']::text[], ARRAY['victoria', 'moyenne-island']::text[], 'Moyenne Island Seychelles.jpg'),
    ('moyenne-tortoise-garden', 'moyenne-island', 'NATURE', 2, 'HOURS', 4.6, 'Черепахи и пиратские могилы Муаена', 'Moyenne Tortoise Garden and Pirates Graves', 'Муаен тасбақалары және пират қабірлері', -4.61670000, 55.50000000, 'Moyenne Island tortoise garden Seychelles', ARRAY['moyenne-island']::text[], ARRAY['moyenne-island']::text[], 'Moyenne Island Seychelles.jpg'),
    ('silhouette-national-park', 'silhouette-island', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк острова Силуэт', 'Silhouette National Park', 'Силуэт аралы ұлттық паркі', -4.48750000, 55.23000000, 'Silhouette Island National Park Seychelles', ARRAY['silhouette-island']::text[], ARRAY['silhouette-island', 'beau-vallon']::text[], 'Silhouette Island remote view asv2024-10.jpg'),
    ('mount-dauban', 'silhouette-island', 'NATURE', 5, 'HOURS', 4.7, 'Гора Добан', 'Mount Dauban', 'Добан тауы', -4.49300000, 55.23400000, 'Mount Dauban Silhouette Seychelles', ARRAY['silhouette-island']::text[], ARRAY['silhouette-island']::text[], 'Silhouette Island remote view asv2024-10.jpg'),
    ('anse-mondon', 'silhouette-island', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Анс-Мондон', 'Anse Mondon', 'Анс-Мондон жағажайы', -4.46600000, 55.23500000, 'Anse Mondon Silhouette Seychelles', ARRAY['silhouette-island']::text[], ARRAY['silhouette-island']::text[], 'Silhouette Island remote view asv2024-10.jpg'),
    ('felicite-island-nature-retreat', 'felicite-island', 'NATURE', 3, 'HOURS', 4.6, 'Природный отдых на острове Фелисите', 'Felicite Island Nature Retreat', 'Фелисите аралындағы табиғи демалыс', -4.32500000, 55.87100000, 'Felicite Island Seychelles', ARRAY['felicite-island', 'la-digue']::text[], ARRAY['felicite-island', 'la-digue']::text[], 'La Digue,Seychelles, Anse Source d´Argent.JPG');

CREATE TEMP TABLE seed_seychelles_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-seychelles-place:' || seed.slug) AS place_hash,
        md5('id-seychelles-media:' || seed.slug) AS media_hash
    FROM seed_seychelles_priority_places seed
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
    ARRAY['seychelles', city_id, slug, lower(category), 'seychelles-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Сейшел: ' || title_ru || '. Подходит для поиска по стране, острову и категории.' AS description_ru,
    'Seychelles tourist place: ' || title_en || '. Useful for search by country, island and category.' AS description_en,
    'Сейшел туристік орны: ' || title_kk || '. Ел, арал және санат бойынша іздеуге арналған.' AS description_kk,
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
    'SC',
    city_id,
    category,
    NULL::numeric,
    'SCR',
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
FROM seed_seychelles_resolved_places
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
FROM seed_seychelles_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_seychelles_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_seychelles_resolved_places
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
FROM seed_seychelles_resolved_places seed
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
FROM seed_seychelles_resolved_places
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
    'SC',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_seychelles_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'SC',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_seychelles_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_seychelles_resolved_places;
DROP TABLE IF EXISTS seed_seychelles_priority_places;
