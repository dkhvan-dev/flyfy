-- Priority Egypt destination places seed.
-- Egypt is seeded as a country destination with concrete city hubs for
-- admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_egypt_resolved_places;
DROP TABLE IF EXISTS seed_egypt_priority_places;

CREATE TEMP TABLE seed_egypt_priority_places (
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

INSERT INTO seed_egypt_priority_places (
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
    ('pyramids-of-giza', 'giza', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Пирамиды Гизы', 'Pyramids of Giza', 'Гиза пирамидалары', 29.97920000, 31.13420000, 'Pyramids of Giza Egypt', ARRAY['giza', 'cairo']::text[], ARRAY['giza', 'cairo']::text[], 'All_Gizah_Pyramids.jpg'),
    ('great-sphinx-of-giza', 'giza', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Большой сфинкс Гизы', 'Great Sphinx of Giza', 'Гиза Ұлы сфинксі', 29.97530000, 31.13760000, 'Great Sphinx of Giza Egypt', ARRAY['giza', 'cairo']::text[], ARRAY['giza', 'cairo']::text[], 'Great_Sphinx_of_Giza_-_20080716a.jpg'),
    ('grand-egyptian-museum', 'giza', 'MUSEUM', 3, 'HOURS', 4.8, 'Большой египетский музей', 'Grand Egyptian Museum', 'Үлкен Египет музейі', 29.99380000, 31.11940000, 'Grand Egyptian Museum Giza Egypt', ARRAY['giza', 'cairo']::text[], ARRAY['giza', 'cairo']::text[], 'Grand_Egyptian_Museum.jpg'),
    ('saqqara-step-pyramid', 'giza', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Ступенчатая пирамида Саккары', 'Saqqara Step Pyramid', 'Саккара сатылы пирамидасы', 29.87120000, 31.21650000, 'Saqqara Step Pyramid Egypt', ARRAY['giza', 'cairo']::text[], ARRAY['giza', 'cairo']::text[], 'Djoser_Step_Pyramid.jpg'),
    ('egyptian-museum', 'cairo', 'MUSEUM', 3, 'HOURS', 4.7, 'Египетский музей', 'Egyptian Museum', 'Египет музейі', 30.04780000, 31.23360000, 'Egyptian Museum Cairo Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Egyptian_Museum_Cairo.jpg'),
    ('national-museum-egyptian-civilization', 'cairo', 'MUSEUM', 2, 'HOURS', 4.7, 'Национальный музей египетской цивилизации', 'National Museum of Egyptian Civilization', 'Египет өркениеті ұлттық музейі', 30.00860000, 31.24820000, 'National Museum of Egyptian Civilization Cairo', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'National_Museum_of_Egyptian_Civilization.jpg'),
    ('khan-el-khalili-bazaar', 'cairo', 'MARKET', 2, 'HOURS', 4.7, 'Базар Хан-эль-Халили', 'Khan El Khalili Bazaar', 'Хан әл-Халили базары', 30.04770000, 31.26250000, 'Khan El Khalili Bazaar Cairo Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Khan_el-Khalili.jpg'),
    ('cairo-citadel', 'cairo', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Каирская цитадель', 'Cairo Citadel', 'Каир цитаделі', 30.02990000, 31.25970000, 'Cairo Citadel Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Cairo_Citadel.jpg'),
    ('al-azhar-mosque', 'cairo', 'TEMPLE', 1, 'HOURS', 4.7, 'Мечеть Аль-Азхар', 'Al Azhar Mosque', 'Әл-Азхар мешіті', 30.04570000, 31.26240000, 'Al Azhar Mosque Cairo Egypt', ARRAY['cairo']::text[], ARRAY['cairo']::text[], 'Al-Azhar_Mosque_Cairo.jpg'),
    ('hanging-church', 'cairo', 'TEMPLE', 1, 'HOURS', 4.6, 'Висячая церковь', 'The Hanging Church', 'Аспалы шіркеу', 30.00530000, 31.23010000, 'The Hanging Church Cairo Egypt', ARRAY['cairo']::text[], ARRAY['cairo']::text[], 'Hanging_Church_Cairo.jpg'),
    ('al-azhar-park', 'cairo', 'PARK', 2, 'HOURS', 4.6, 'Парк Аль-Азхар', 'Al Azhar Park', 'Әл-Азхар саябағы', 30.04030000, 31.26550000, 'Al Azhar Park Cairo Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Al-Azhar_Park.jpg'),
    ('cairo-festival-city-mall', 'cairo', 'SHOPPING', 3, 'HOURS', 4.5, 'Cairo Festival City Mall', 'Cairo Festival City Mall', 'Cairo Festival City Mall', 30.02780000, 31.40750000, 'Cairo Festival City Mall Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Cairo_Festival_City.jpg'),
    ('citystars-mall', 'cairo', 'SHOPPING', 3, 'HOURS', 4.5, 'Citystars Mall', 'Citystars Mall', 'Citystars Mall', 30.07340000, 31.34690000, 'Citystars Mall Cairo Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Citystars_Cairo.jpg'),
    ('cairo-food-walk', 'cairo', 'FOOD', 2, 'HOURS', 4.5, 'Каирский гастрономический маршрут', 'Cairo Food Walk', 'Каир гастро маршруты', 30.04440000, 31.23570000, 'Cairo street food Egypt', ARRAY['cairo', 'giza']::text[], ARRAY['cairo']::text[], 'Cairo_Downtown.jpg'),

    ('citadel-of-qaitbay', 'alexandria', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Кайтбей', 'Citadel of Qaitbay', 'Қайтбай қамалы', 31.21390000, 29.88560000, 'Citadel of Qaitbay Alexandria Egypt', ARRAY['alexandria', 'north-coast']::text[], ARRAY['alexandria']::text[], 'Citadel_of_Qaitbay_Alexandria.jpg'),
    ('bibliotheca-alexandrina', 'alexandria', 'MUSEUM', 2, 'HOURS', 4.7, 'Александрийская библиотека', 'Bibliotheca Alexandrina', 'Александрия кітапханасы', 31.20890000, 29.90920000, 'Bibliotheca Alexandrina Egypt', ARRAY['alexandria', 'north-coast']::text[], ARRAY['alexandria']::text[], 'Bibliotheca_Alexandrina.jpg'),
    ('catacombs-kom-el-shoqafa', 'alexandria', 'MUSEUM', 2, 'HOURS', 4.6, 'Катакомбы Ком-эль-Шукафа', 'Catacombs of Kom El Shoqafa', 'Ком әл-Шукафа катакомбалары', 31.17860000, 29.89290000, 'Catacombs of Kom El Shoqafa Alexandria Egypt', ARRAY['alexandria']::text[], ARRAY['alexandria']::text[], 'Catacombs_of_Kom_el_Shoqafa.jpg'),
    ('montaza-palace-gardens', 'alexandria', 'PARK', 2, 'HOURS', 4.6, 'Сады дворца Монтаза', 'Montaza Palace Gardens', 'Монтаза сарай бақтары', 31.28630000, 30.01580000, 'Montaza Palace Gardens Alexandria Egypt', ARRAY['alexandria', 'north-coast']::text[], ARRAY['alexandria']::text[], 'Montaza_Palace_Alexandria.jpg'),
    ('alexandria-corniche', 'alexandria', 'FOOD', 2, 'HOURS', 4.5, 'Набережная Александрии', 'Alexandria Corniche', 'Александрия жағалауы', 31.21560000, 29.95530000, 'Alexandria Corniche Egypt', ARRAY['alexandria']::text[], ARRAY['alexandria']::text[], 'Alexandria_Corniche.jpg'),
    ('san-stefano-mall', 'alexandria', 'SHOPPING', 2, 'HOURS', 4.4, 'San Stefano Mall', 'San Stefano Mall', 'San Stefano Mall', 31.24540000, 29.96780000, 'San Stefano Mall Alexandria Egypt', ARRAY['alexandria']::text[], ARRAY['alexandria']::text[], 'San_Stefano_Alexandria.jpg'),
    ('el-alamein-war-museum', 'north-coast', 'MUSEUM', 2, 'HOURS', 4.5, 'Военный музей Эль-Аламейна', 'El Alamein War Museum', 'Әл-Аламейн әскери музейі', 30.83820000, 28.95590000, 'El Alamein War Museum Egypt', ARRAY['north-coast', 'alexandria']::text[], ARRAY['north-coast', 'alexandria']::text[], 'El_Alamein_War_Museum.jpg'),
    ('north-coast-beaches', 'north-coast', 'BEACH', 3, 'HOURS', 4.6, 'Пляжи Северного побережья', 'North Coast Beaches', 'Солтүстік жағалау жағажайлары', 30.93260000, 28.81760000, 'North Coast Beaches Egypt', ARRAY['north-coast', 'alexandria']::text[], ARRAY['north-coast', 'alexandria']::text[], 'Mediterranean_Sea_Egypt.jpg'),
    ('port-said-waterfront', 'port-said', 'FOOD', 2, 'HOURS', 4.4, 'Набережная Порт-Саида', 'Port Said Waterfront', 'Порт-Саид жағалауы', 31.26530000, 32.30190000, 'Port Said Waterfront Egypt', ARRAY['port-said', 'suez']::text[], ARRAY['port-said']::text[], 'Port_Said_Corniche.jpg'),
    ('port-said-market', 'port-said', 'MARKET', 1, 'HOURS', 4.3, 'Рынок Порт-Саида', 'Port Said Market', 'Порт-Саид базары', 31.25650000, 32.28410000, 'Port Said Market Egypt', ARRAY['port-said']::text[], ARRAY['port-said']::text[], 'Port_Said_Egypt.jpg'),
    ('suez-canal-viewpoint', 'suez', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Смотровая точка Суэцкого канала', 'Suez Canal Viewpoint', 'Суэц каналы көрінісі', 29.96680000, 32.54980000, 'Suez Canal Viewpoint Egypt', ARRAY['suez', 'ain-sokhna']::text[], ARRAY['suez']::text[], 'Suez_Canal.jpg'),
    ('ain-sokhna-beach', 'ain-sokhna', 'BEACH', 3, 'HOURS', 4.5, 'Пляж Айн-Сохна', 'Ain Sokhna Beach', 'Айн-Сохна жағажайы', 29.59200000, 32.33550000, 'Ain Sokhna Beach Egypt', ARRAY['ain-sokhna', 'suez', 'cairo']::text[], ARRAY['ain-sokhna', 'cairo']::text[], 'Ain_Sokhna.jpg'),

    ('karnak-temple', 'luxor', 'TEMPLE', 3, 'HOURS', 4.9, 'Карнакский храм', 'Karnak Temple', 'Карнак ғибадатханасы', 25.71880000, 32.65730000, 'Karnak Temple Luxor Egypt', ARRAY['luxor', 'aswan']::text[], ARRAY['luxor']::text[], 'Karnak_Temple_Complex.jpg'),
    ('valley-of-the-kings', 'luxor', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Долина царей', 'Valley of the Kings', 'Патшалар аңғары', 25.74020000, 32.60140000, 'Valley of the Kings Luxor Egypt', ARRAY['luxor']::text[], ARRAY['luxor']::text[], 'Valley_of_the_Kings_Egypt.jpg'),
    ('luxor-temple', 'luxor', 'TEMPLE', 2, 'HOURS', 4.8, 'Луксорский храм', 'Luxor Temple', 'Луксор ғибадатханасы', 25.69950000, 32.63910000, 'Luxor Temple Egypt', ARRAY['luxor']::text[], ARRAY['luxor']::text[], 'Luxor_Temple_R04.jpg'),
    ('hatshepsut-temple', 'luxor', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Хатшепсут', 'Temple of Hatshepsut', 'Хатшепсут ғибадатханасы', 25.73820000, 32.60660000, 'Temple of Hatshepsut Luxor Egypt', ARRAY['luxor']::text[], ARRAY['luxor']::text[], 'Hatshepsut_Temple.jpg'),
    ('luxor-museum', 'luxor', 'MUSEUM', 2, 'HOURS', 4.7, 'Луксорский музей', 'Luxor Museum', 'Луксор музейі', 25.70790000, 32.64490000, 'Luxor Museum Egypt', ARRAY['luxor']::text[], ARRAY['luxor']::text[], 'Luxor_Museum.jpg'),
    ('luxor-souk', 'luxor', 'MARKET', 1, 'HOURS', 4.4, 'Рынок Луксора', 'Luxor Souk', 'Луксор базары', 25.69540000, 32.63880000, 'Luxor Souk Egypt', ARRAY['luxor']::text[], ARRAY['luxor']::text[], 'Luxor_Souk.jpg'),
    ('philae-temple', 'aswan', 'TEMPLE', 2, 'HOURS', 4.9, 'Храм Филе', 'Philae Temple', 'Филе ғибадатханасы', 24.02500000, 32.88400000, 'Philae Temple Aswan Egypt', ARRAY['aswan', 'abu-simbel']::text[], ARRAY['aswan']::text[], 'Philae_Temple_Aswan.jpg'),
    ('nubian-museum', 'aswan', 'MUSEUM', 2, 'HOURS', 4.7, 'Нубийский музей', 'Nubian Museum', 'Нубия музейі', 24.08190000, 32.88700000, 'Nubian Museum Aswan Egypt', ARRAY['aswan', 'abu-simbel']::text[], ARRAY['aswan']::text[], 'Nubian_Museum_Aswan.jpg'),
    ('aswan-souk', 'aswan', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Асуана', 'Aswan Souk', 'Асуан базары', 24.09080000, 32.89960000, 'Aswan Souk Egypt', ARRAY['aswan']::text[], ARRAY['aswan']::text[], 'Aswan_Souk.jpg'),
    ('nubian-village-aswan', 'aswan', 'FOOD', 2, 'HOURS', 4.6, 'Нубийская деревня', 'Nubian Village Aswan', 'Асуан нубия ауылы', 24.04780000, 32.86970000, 'Nubian Village Aswan Egypt', ARRAY['aswan']::text[], ARRAY['aswan']::text[], 'Nubian_Village_Aswan.jpg'),
    ('abu-simbel-temples', 'abu-simbel', 'TEMPLE', 3, 'HOURS', 4.9, 'Храмы Абу-Симбела', 'Abu Simbel Temples', 'Абу-Симбел ғибадатханалары', 22.33720000, 31.62580000, 'Abu Simbel Temples Egypt', ARRAY['abu-simbel', 'aswan']::text[], ARRAY['abu-simbel', 'aswan']::text[], 'Abu_Simbel_Temple_May_30_2007.jpg'),

    ('giftun-islands', 'hurghada', 'BEACH', 4, 'HOURS', 4.8, 'Острова Гифтун', 'Giftun Islands', 'Гифтун аралдары', 27.21360000, 33.95460000, 'Giftun Islands Hurghada Egypt', ARRAY['hurghada', 'el-gouna']::text[], ARRAY['hurghada']::text[], 'Giftun_Island_Egypt.jpg'),
    ('hurghada-marina', 'hurghada', 'FOOD', 2, 'HOURS', 4.6, 'Марина Хургады', 'Hurghada Marina', 'Хургада маринасы', 27.22690000, 33.84210000, 'Hurghada Marina Egypt', ARRAY['hurghada', 'el-gouna']::text[], ARRAY['hurghada']::text[], 'Hurghada_Marina.jpg'),
    ('hurghada-grand-aquarium', 'hurghada', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Большой аквариум Хургады', 'Hurghada Grand Aquarium', 'Хургада үлкен аквариумы', 27.12210000, 33.82520000, 'Hurghada Grand Aquarium Egypt', ARRAY['hurghada']::text[], ARRAY['hurghada']::text[], 'Hurghada_Grand_Aquarium.jpg'),
    ('senzo-mall', 'hurghada', 'SHOPPING', 2, 'HOURS', 4.4, 'Senzo Mall', 'Senzo Mall', 'Senzo Mall', 27.09880000, 33.82310000, 'Senzo Mall Hurghada Egypt', ARRAY['hurghada']::text[], ARRAY['hurghada']::text[], 'Senzo_Mall_Hurghada.jpg'),
    ('el-gouna-marina', 'el-gouna', 'FOOD', 2, 'HOURS', 4.6, 'Марина Эль-Гуны', 'El Gouna Marina', 'Эль-Гуна маринасы', 27.40800000, 33.67860000, 'El Gouna Marina Egypt', ARRAY['el-gouna', 'hurghada']::text[], ARRAY['el-gouna', 'hurghada']::text[], 'El_Gouna_Marina.jpg'),
    ('abu-tig-marina', 'el-gouna', 'SHOPPING', 2, 'HOURS', 4.5, 'Абу-Тиг Марина', 'Abu Tig Marina', 'Абу-Тиг маринасы', 27.41440000, 33.67500000, 'Abu Tig Marina El Gouna Egypt', ARRAY['el-gouna', 'hurghada']::text[], ARRAY['el-gouna']::text[], 'Abu_Tig_Marina.jpg'),
    ('abu-dabbab-beach', 'marsa-alam', 'BEACH', 3, 'HOURS', 4.8, 'Пляж Абу-Даббаб', 'Abu Dabbab Beach', 'Абу-Даббаб жағажайы', 25.33850000, 34.73890000, 'Abu Dabbab Beach Marsa Alam Egypt', ARRAY['marsa-alam', 'hurghada']::text[], ARRAY['marsa-alam']::text[], 'Abu_Dabbab_Bay.jpg'),
    ('wadi-el-gemal-national-park', 'marsa-alam', 'NATURE', 4, 'HOURS', 4.8, 'Национальный парк Вади-эль-Гемаль', 'Wadi El Gemal National Park', 'Вади әл-Гемаль ұлттық паркі', 24.66420000, 35.16490000, 'Wadi El Gemal National Park Egypt', ARRAY['marsa-alam']::text[], ARRAY['marsa-alam']::text[], 'Wadi_El_Gemal.jpg'),
    ('ras-mohammed-national-park', 'sharm-el-sheikh', 'NATURE', 4, 'HOURS', 4.9, 'Национальный парк Рас-Мохаммед', 'Ras Mohammed National Park', 'Рас-Мохаммед ұлттық паркі', 27.74090000, 34.25990000, 'Ras Mohammed National Park Sharm El Sheikh Egypt', ARRAY['sharm-el-sheikh', 'dahab']::text[], ARRAY['sharm-el-sheikh']::text[], 'Ras_Mohammed_National_Park.jpg'),
    ('naama-bay', 'sharm-el-sheikh', 'BEACH', 2, 'HOURS', 4.6, 'Наама-Бей', 'Naama Bay', 'Наама шығанағы', 27.91410000, 34.31820000, 'Naama Bay Sharm El Sheikh Egypt', ARRAY['sharm-el-sheikh']::text[], ARRAY['sharm-el-sheikh']::text[], 'Naama_Bay.jpg'),
    ('soho-square-sharm', 'sharm-el-sheikh', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'SOHO Square', 'SOHO Square Sharm El Sheikh', 'SOHO Square', 27.96370000, 34.39490000, 'SOHO Square Sharm El Sheikh Egypt', ARRAY['sharm-el-sheikh']::text[], ARRAY['sharm-el-sheikh']::text[], 'Soho_Square_Sharm.jpg'),
    ('old-market-sharm', 'sharm-el-sheikh', 'MARKET', 2, 'HOURS', 4.5, 'Старый рынок Шарм-эль-Шейха', 'Old Market Sharm El Sheikh', 'Шарм ескі базары', 27.86180000, 34.29580000, 'Old Market Sharm El Sheikh Egypt', ARRAY['sharm-el-sheikh']::text[], ARRAY['sharm-el-sheikh']::text[], 'Old_Market_Sharm_El_Sheikh.jpg'),
    ('blue-hole-dahab', 'dahab', 'NATURE', 3, 'HOURS', 4.8, 'Голубая дыра Дахаба', 'Blue Hole Dahab', 'Дахаб көк шұңқыры', 28.57030000, 34.53700000, 'Blue Hole Dahab Egypt', ARRAY['dahab', 'sharm-el-sheikh']::text[], ARRAY['dahab', 'sharm-el-sheikh']::text[], 'Blue_Hole_Dahab.jpg'),
    ('dahab-lagoon', 'dahab', 'BEACH', 2, 'HOURS', 4.6, 'Лагуна Дахаба', 'Dahab Lagoon', 'Дахаб лагунасы', 28.48690000, 34.51370000, 'Dahab Lagoon Egypt', ARRAY['dahab', 'sharm-el-sheikh']::text[], ARRAY['dahab']::text[], 'Dahab_Lagoon.jpg'),
    ('saint-catherine-monastery', 'saint-catherine', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Святой Екатерины', 'Saint Catherine Monastery', 'Әулие Екатерина монастырі', 28.55590000, 33.97690000, 'Saint Catherine Monastery Sinai Egypt', ARRAY['saint-catherine', 'dahab', 'sharm-el-sheikh']::text[], ARRAY['saint-catherine', 'sharm-el-sheikh']::text[], 'Saint_Catherine_Monastery_Sinai.jpg'),
    ('mount-sinai', 'saint-catherine', 'NATURE', 4, 'HOURS', 4.8, 'Гора Синай', 'Mount Sinai', 'Синай тауы', 28.53930000, 33.97540000, 'Mount Sinai Egypt', ARRAY['saint-catherine', 'dahab', 'sharm-el-sheikh']::text[], ARRAY['saint-catherine']::text[], 'Mount_Sinai_Egypt.jpg'),

    ('siwa-oasis', 'siwa', 'NATURE', 4, 'HOURS', 4.8, 'Оазис Сива', 'Siwa Oasis', 'Сива оазисі', 29.20410000, 25.51950000, 'Siwa Oasis Egypt', ARRAY['siwa']::text[], ARRAY['siwa']::text[], 'Siwa_Oasis_Egypt.jpg'),
    ('shali-fortress', 'siwa', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Крепость Шали', 'Shali Fortress', 'Шали қамалы', 29.20300000, 25.51980000, 'Shali Fortress Siwa Egypt', ARRAY['siwa']::text[], ARRAY['siwa']::text[], 'Shali_Fortress_Siwa.jpg'),
    ('cleopatra-spring-siwa', 'siwa', 'NATURE', 1, 'HOURS', 4.5, 'Источник Клеопатры в Сиве', 'Cleopatra Spring Siwa', 'Сивадағы Клеопатра бұлағы', 29.20020000, 25.53380000, 'Cleopatra Spring Siwa Egypt', ARRAY['siwa']::text[], ARRAY['siwa']::text[], 'Cleopatra_Spring_Siwa.jpg'),
    ('wadi-el-hitan', 'fayoum', 'NATURE', 3, 'HOURS', 4.8, 'Вади-эль-Хитан', 'Wadi El Hitan', 'Вади әл-Хитан', 29.33330000, 30.18330000, 'Wadi El Hitan Fayoum Egypt', ARRAY['fayoum', 'cairo']::text[], ARRAY['fayoum', 'cairo']::text[], 'Wadi_El_Hitan.jpg'),
    ('wadi-el-rayan', 'fayoum', 'NATURE', 3, 'HOURS', 4.7, 'Вади-эль-Райян', 'Wadi El Rayan', 'Вади әл-Райян', 29.21050000, 30.40460000, 'Wadi El Rayan Fayoum Egypt', ARRAY['fayoum', 'cairo']::text[], ARRAY['fayoum', 'cairo']::text[], 'Wadi_El_Rayan_Egypt.jpg'),
    ('tunis-village-fayoum', 'fayoum', 'SHOPPING', 2, 'HOURS', 4.6, 'Деревня Тунис в Фаюме', 'Tunis Village Fayoum', 'Фаюм Тунис ауылы', 29.39470000, 30.49180000, 'Tunis Village Fayoum Egypt', ARRAY['fayoum', 'cairo']::text[], ARRAY['fayoum']::text[], 'Tunis_Village_Fayoum.jpg'),
    ('bahariya-oasis', 'bahariya-oasis', 'NATURE', 3, 'HOURS', 4.6, 'Оазис Бахария', 'Bahariya Oasis', 'Бахария оазисі', 28.34990000, 28.86540000, 'Bahariya Oasis Egypt', ARRAY['bahariya-oasis', 'white-desert']::text[], ARRAY['bahariya-oasis']::text[], 'Bahariya_Oasis.jpg'),
    ('black-desert', 'bahariya-oasis', 'NATURE', 2, 'HOURS', 4.6, 'Черная пустыня', 'Black Desert', 'Қара шөл', 28.35660000, 28.75140000, 'Black Desert Bahariya Egypt', ARRAY['bahariya-oasis', 'white-desert']::text[], ARRAY['bahariya-oasis']::text[], 'Black_Desert_Egypt.jpg'),
    ('white-desert-national-park', 'white-desert', 'NATURE', 4, 'HOURS', 4.9, 'Национальный парк Белая пустыня', 'White Desert National Park', 'Ақ шөл ұлттық паркі', 27.28810000, 28.20170000, 'White Desert National Park Egypt', ARRAY['white-desert', 'bahariya-oasis']::text[], ARRAY['white-desert', 'bahariya-oasis']::text[], 'White_Desert_Egypt.jpg'),
    ('crystal-mountain-egypt', 'white-desert', 'NATURE', 1, 'HOURS', 4.5, 'Хрустальная гора', 'Crystal Mountain Egypt', 'Хрусталь тауы', 27.64720000, 28.42360000, 'Crystal Mountain Egypt White Desert', ARRAY['white-desert', 'bahariya-oasis']::text[], ARRAY['white-desert']::text[], 'Crystal_Mountain_Egypt.jpg');

CREATE TEMP TABLE seed_egypt_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-egypt-place:' || seed.slug) AS place_hash,
        md5('id-egypt-media:' || seed.slug) AS media_hash
    FROM seed_egypt_priority_places seed
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
    ARRAY['egypt', city_id, slug, lower(category), 'egypt-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Египта: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'Egypt tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Египет туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'EG',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 400::numeric
        ELSE 200::numeric
    END,
    'EGP',
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
FROM seed_egypt_resolved_places
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
FROM seed_egypt_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_egypt_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_egypt_resolved_places
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
FROM seed_egypt_resolved_places seed
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
FROM seed_egypt_resolved_places
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
    'EG',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_egypt_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'EG',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_egypt_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_egypt_resolved_places;
DROP TABLE IF EXISTS seed_egypt_priority_places;
