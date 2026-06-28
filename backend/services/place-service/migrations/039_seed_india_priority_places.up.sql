-- Priority India destination places seed.
-- India is seeded as one country destination with curated city hubs for
-- admin filters, route search and localized mobile discovery.

DROP TABLE IF EXISTS seed_india_resolved_places;
DROP TABLE IF EXISTS seed_india_priority_places;

CREATE TEMP TABLE seed_india_priority_places (
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

INSERT INTO seed_india_priority_places (
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
    ('red-fort-delhi', 'delhi', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Красный форт', 'Red Fort', 'Қызыл форт', 28.65620000, 77.24100000, 'Red Fort Delhi India', ARRAY['delhi', 'agra', 'jaipur']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('qutub-minar', 'delhi', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Кутб-Минар', 'Qutub Minar', 'Кутб-Минар', 28.52440000, 77.18550000, 'Qutub Minar Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('humayuns-tomb', 'delhi', 'ARCHITECTURE', 2, 'HOURS', 4.8, 'Гробница Хумаюна', $$Humayun's Tomb$$, 'Хумаюн кесенесі', 28.59330000, 77.25070000, 'Humayun Tomb Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('india-gate', 'delhi', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Ворота Индии в Дели', 'India Gate', 'Үндістан қақпасы', 28.61290000, 77.22950000, 'India Gate New Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('jama-masjid-delhi', 'delhi', 'TEMPLE', 1, 'HOURS', 4.6, 'Джама-Масджид', 'Jama Masjid', 'Жама мешіті', 28.65070000, 77.23340000, 'Jama Masjid Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('chandni-chowk', 'delhi', 'MARKET', 2, 'HOURS', 4.5, 'Чандни-Чоук', 'Chandni Chowk', 'Чандни-Чоук базары', 28.65050000, 77.23030000, 'Chandni Chowk Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('national-museum-delhi', 'delhi', 'MUSEUM', 2, 'HOURS', 4.5, 'Национальный музей Дели', 'National Museum Delhi', 'Дели ұлттық музейі', 28.61180000, 77.21950000, 'National Museum Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('dilli-haat', 'delhi', 'FOOD', 2, 'HOURS', 4.4, 'Dilli Haat', 'Dilli Haat', 'Dilli Haat', 28.57330000, 77.20740000, 'Dilli Haat Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),
    ('select-citywalk', 'delhi', 'SHOPPING', 3, 'HOURS', 4.4, 'Select Citywalk', 'Select Citywalk', 'Select Citywalk', 28.52890000, 77.21950000, 'Select Citywalk Delhi India', ARRAY['delhi']::text[], ARRAY['delhi']::text[], 'Delhi_Red_fort.jpg'),

    ('taj-mahal', 'agra', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Тадж-Махал', 'Taj Mahal', 'Тәж-Махал', 27.17510000, 78.04210000, 'Taj Mahal Agra India', ARRAY['agra', 'delhi', 'jaipur']::text[], ARRAY['agra', 'delhi']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('agra-fort', 'agra', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Форт Агры', 'Agra Fort', 'Агра форты', 27.17950000, 78.02110000, 'Agra Fort India', ARRAY['agra', 'delhi']::text[], ARRAY['agra', 'delhi']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('fatehpur-sikri', 'agra', 'ARCHITECTURE', 4, 'HOURS', 4.7, 'Фатехпур-Сикри', 'Fatehpur Sikri', 'Фатехпур-Сикри', 27.09450000, 77.66790000, 'Fatehpur Sikri India', ARRAY['agra', 'delhi', 'jaipur']::text[], ARRAY['agra']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('itimad-ud-daulah', 'agra', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Гробница Итимад-уд-Даула', 'Itimad-ud-Daulah Tomb', 'Итимад-уд-Даула кесенесі', 27.19290000, 78.03100000, 'Itimad ud Daulah Agra India', ARRAY['agra']::text[], ARRAY['agra']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('mehtab-bagh', 'agra', 'PARK', 1, 'HOURS', 4.5, 'Мехтаб-Баг', 'Mehtab Bagh', 'Мехтаб-Баг бағы', 27.17970000, 78.04190000, 'Mehtab Bagh Agra India', ARRAY['agra']::text[], ARRAY['agra']::text[], 'Taj_Mahal_(Edited).jpeg'),

    ('jaipur-city-palace', 'jaipur', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Городской дворец Джайпура', 'Jaipur City Palace', 'Джайпур қалалық сарайы', 26.92580000, 75.82370000, 'City Palace Jaipur India', ARRAY['jaipur', 'delhi', 'agra']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),
    ('hawa-mahal', 'jaipur', 'ARCHITECTURE', 1, 'HOURS', 4.7, 'Хава-Махал', 'Hawa Mahal', 'Хава-Махал', 26.92390000, 75.82670000, 'Hawa Mahal Jaipur India', ARRAY['jaipur']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),
    ('amber-fort', 'jaipur', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Форт Амбер', 'Amber Fort', 'Амбер форты', 26.98550000, 75.85130000, 'Amber Fort Jaipur India', ARRAY['jaipur']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),
    ('jantar-mantar-jaipur', 'jaipur', 'MUSEUM', 1, 'HOURS', 4.6, 'Джантар-Мантар Джайпур', 'Jantar Mantar Jaipur', 'Джайпур Джантар-Мантар', 26.92480000, 75.82460000, 'Jantar Mantar Jaipur India', ARRAY['jaipur']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),
    ('johari-bazaar', 'jaipur', 'MARKET', 2, 'HOURS', 4.5, 'Джохари-Базар', 'Johari Bazaar', 'Джохари базары', 26.92190000, 75.82720000, 'Johari Bazaar Jaipur India', ARRAY['jaipur']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),
    ('nahargarh-fort', 'jaipur', 'ENTERTAINMENT', 2, 'HOURS', 4.6, 'Форт Нахаргарх', 'Nahargarh Fort', 'Нахаргарх форты', 26.93730000, 75.81550000, 'Nahargarh Fort Jaipur India', ARRAY['jaipur']::text[], ARRAY['jaipur']::text[], 'Hawa_Mahal_2011.jpg'),

    ('varanasi-ghats', 'varanasi', 'TEMPLE', 3, 'HOURS', 4.9, 'Гхаты Варанаси', 'Varanasi Ghats', 'Варанаси гхаттары', 25.30690000, 83.01070000, 'Varanasi Ghats India', ARRAY['varanasi']::text[], ARRAY['varanasi']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('kashi-vishwanath-temple', 'varanasi', 'TEMPLE', 2, 'HOURS', 4.9, 'Храм Каши Вишванатх', 'Kashi Vishwanath Temple', 'Каши Вишванатх ғибадатханасы', 25.31090000, 83.01070000, 'Kashi Vishwanath Temple Varanasi India', ARRAY['varanasi']::text[], ARRAY['varanasi']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('dashashwamedh-ghat-aarti', 'varanasi', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Ганга Аарти на Дашашвамедх-гхате', 'Dashashwamedh Ghat Aarti', 'Дашашвамедх Ганга Аарти', 25.30660000, 83.01040000, 'Dashashwamedh Ghat Aarti Varanasi India', ARRAY['varanasi']::text[], ARRAY['varanasi']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('sarnath', 'varanasi', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Сарнатх', 'Sarnath', 'Сарнатх', 25.38070000, 83.02450000, 'Sarnath Varanasi India', ARRAY['varanasi']::text[], ARRAY['varanasi']::text[], 'Taj_Mahal_(Edited).jpeg'),
    ('ramnagar-fort', 'varanasi', 'MUSEUM', 2, 'HOURS', 4.4, 'Форт Рамнагар', 'Ramnagar Fort', 'Рамнагар форты', 25.26980000, 83.02650000, 'Ramnagar Fort Varanasi India', ARRAY['varanasi']::text[], ARRAY['varanasi']::text[], 'Taj_Mahal_(Edited).jpeg'),

    ('golden-temple', 'amritsar', 'TEMPLE', 3, 'HOURS', 4.9, 'Золотой храм', 'Golden Temple', 'Алтын ғибадатхана', 31.62000000, 74.87650000, 'Golden Temple Amritsar India', ARRAY['amritsar']::text[], ARRAY['amritsar', 'delhi']::text[], 'Golden_Temple_India.jpg'),
    ('jallianwala-bagh', 'amritsar', 'MUSEUM', 1, 'HOURS', 4.7, 'Джаллаинвала-Багх', 'Jallianwala Bagh', 'Джаллаинвала-Багх', 31.62060000, 74.88010000, 'Jallianwala Bagh Amritsar India', ARRAY['amritsar']::text[], ARRAY['amritsar']::text[], 'Golden_Temple_India.jpg'),
    ('wagah-border', 'amritsar', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Церемония на границе Вагах', 'Wagah Border Ceremony', 'Вагах шекара рәсімі', 31.60480000, 74.57380000, 'Wagah Border Ceremony India', ARRAY['amritsar']::text[], ARRAY['amritsar']::text[], 'Golden_Temple_India.jpg'),
    ('hall-bazaar-amritsar', 'amritsar', 'MARKET', 2, 'HOURS', 4.4, 'Hall Bazaar', 'Hall Bazaar Amritsar', 'Hall Bazaar Амритсар', 31.63090000, 74.87350000, 'Hall Bazaar Amritsar India', ARRAY['amritsar']::text[], ARRAY['amritsar']::text[], 'Golden_Temple_India.jpg'),

    ('gateway-of-india', 'mumbai', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Ворота Индии в Мумбаи', 'Gateway of India', 'Мумбай Үндістан қақпасы', 18.92200000, 72.83470000, 'Gateway of India Mumbai', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('csmt-mumbai', 'mumbai', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Вокзал Чхатрапати Шиваджи Махарадж', 'Chhatrapati Shivaji Maharaj Terminus', 'Чхатрапати Шиваджи Махарадж вокзалы', 18.94020000, 72.83560000, 'Chhatrapati Shivaji Maharaj Terminus Mumbai India', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('elephanta-caves', 'mumbai', 'ARCHITECTURE', 4, 'HOURS', 4.7, 'Пещеры Элефанта', 'Elephanta Caves', 'Элефанта үңгірлері', 18.96330000, 72.93150000, 'Elephanta Caves Mumbai India', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('marine-drive', 'mumbai', 'PARK', 2, 'HOURS', 4.6, 'Marine Drive', 'Marine Drive', 'Marine Drive', 18.94320000, 72.82340000, 'Marine Drive Mumbai India', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('colaba-causeway', 'mumbai', 'MARKET', 2, 'HOURS', 4.4, 'Colaba Causeway', 'Colaba Causeway', 'Colaba Causeway', 18.91560000, 72.82660000, 'Colaba Causeway Mumbai India', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('phoenix-palladium-mumbai', 'mumbai', 'SHOPPING', 3, 'HOURS', 4.5, 'Phoenix Palladium Mumbai', 'Phoenix Palladium Mumbai', 'Phoenix Palladium Mumbai', 18.99460000, 72.82580000, 'Phoenix Palladium Mumbai India', ARRAY['mumbai']::text[], ARRAY['mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),

    ('baga-beach', 'goa', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Бага', 'Baga Beach', 'Бага жағажайы', 15.55530000, 73.75170000, 'Baga Beach Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('calangute-beach', 'goa', 'BEACH', 4, 'HOURS', 4.6, 'Пляж Калангут', 'Calangute Beach', 'Калангут жағажайы', 15.54940000, 73.75350000, 'Calangute Beach Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('anjuna-flea-market', 'goa', 'MARKET', 2, 'HOURS', 4.5, 'Блошиный рынок Анджуны', 'Anjuna Flea Market', 'Анджуна базары', 15.57520000, 73.74070000, 'Anjuna Flea Market Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('basilica-bom-jesus', 'goa', 'TEMPLE', 1, 'HOURS', 4.7, 'Базилика Бом-Жезуш', 'Basilica of Bom Jesus', 'Бом-Жезуш базиликасы', 15.50090000, 73.91160000, 'Basilica of Bom Jesus Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('dudhsagar-falls', 'goa', 'NATURE', 5, 'HOURS', 4.8, 'Водопад Дудхсагар', 'Dudhsagar Falls', 'Дудхсагар сарқырамасы', 15.31440000, 74.31430000, 'Dudhsagar Falls Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('fort-aguada', 'goa', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Форт Агуада', 'Fort Aguada', 'Агуада форты', 15.49270000, 73.77300000, 'Fort Aguada Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),
    ('palolem-beach', 'goa', 'BEACH', 4, 'HOURS', 4.7, 'Пляж Палолем', 'Palolem Beach', 'Палолем жағажайы', 15.00990000, 74.02310000, 'Palolem Beach Goa India', ARRAY['goa']::text[], ARRAY['goa']::text[], 'Baga beach goa.jpg'),

    ('city-palace-udaipur', 'udaipur', 'ARCHITECTURE', 3, 'HOURS', 4.8, 'Городской дворец Удайпура', 'City Palace Udaipur', 'Удайпур қалалық сарайы', 24.57640000, 73.68350000, 'City Palace Udaipur India', ARRAY['udaipur', 'jodhpur', 'jaipur']::text[], ARRAY['udaipur']::text[], 'Udaipur_City_Palace.jpg'),
    ('lake-pichola', 'udaipur', 'NATURE', 2, 'HOURS', 4.7, 'Озеро Пичола', 'Lake Pichola', 'Пичола көлі', 24.57200000, 73.67940000, 'Lake Pichola Udaipur India', ARRAY['udaipur']::text[], ARRAY['udaipur']::text[], 'Udaipur_City_Palace.jpg'),
    ('saheliyon-ki-bari', 'udaipur', 'PARK', 1, 'HOURS', 4.5, 'Сахелион-ки-Бари', 'Saheliyon Ki Bari', 'Сахелион-ки-Бари', 24.60330000, 73.68520000, 'Saheliyon Ki Bari Udaipur India', ARRAY['udaipur']::text[], ARRAY['udaipur']::text[], 'Udaipur_City_Palace.jpg'),
    ('hathi-pol-bazaar', 'udaipur', 'MARKET', 2, 'HOURS', 4.4, 'Hathi Pol Bazaar', 'Hathi Pol Bazaar', 'Hathi Pol Bazaar', 24.58620000, 73.68790000, 'Hathi Pol Bazaar Udaipur India', ARRAY['udaipur']::text[], ARRAY['udaipur']::text[], 'Udaipur_City_Palace.jpg'),
    ('mehrangarh-fort', 'jodhpur', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Форт Мехрангарх', 'Mehrangarh Fort', 'Мехрангарх форты', 26.29780000, 73.01800000, 'Mehrangarh Fort Jodhpur India', ARRAY['jodhpur', 'udaipur', 'jaipur']::text[], ARRAY['jodhpur']::text[], 'Mehrangarh_Fort,_Jodhpur.jpg'),
    ('jaswant-thada', 'jodhpur', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Джасвант-Тхада', 'Jaswant Thada', 'Джасвант-Тхада', 26.30300000, 73.01930000, 'Jaswant Thada Jodhpur India', ARRAY['jodhpur']::text[], ARRAY['jodhpur']::text[], 'Mehrangarh_Fort,_Jodhpur.jpg'),
    ('clock-tower-jodhpur-market', 'jodhpur', 'MARKET', 2, 'HOURS', 4.4, 'Рынок у часовой башни Джодхпура', 'Jodhpur Clock Tower Market', 'Джодхпур сағат мұнарасы базары', 26.29470000, 73.02310000, 'Clock Tower Market Jodhpur India', ARRAY['jodhpur']::text[], ARRAY['jodhpur']::text[], 'Mehrangarh_Fort,_Jodhpur.jpg'),
    ('umaid-bhawan-palace', 'jodhpur', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Умайд-Бхаван', 'Umaid Bhawan Palace Museum', 'Умайд-Бхаван сарай музейі', 26.28190000, 73.04770000, 'Umaid Bhawan Palace Jodhpur India', ARRAY['jodhpur']::text[], ARRAY['jodhpur']::text[], 'Mehrangarh_Fort,_Jodhpur.jpg'),
    ('sabarmati-ashram', 'ahmedabad', 'MUSEUM', 2, 'HOURS', 4.8, 'Ашрам Сабармати', 'Sabarmati Ashram', 'Сабармати ашрамы', 23.06080000, 72.58090000, 'Sabarmati Ashram Ahmedabad India', ARRAY['ahmedabad']::text[], ARRAY['ahmedabad']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('ahmedabad-old-city', 'ahmedabad', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Исторический город Ахмадабад', 'Historic City of Ahmedabad', 'Ахмадабад тарихи қаласы', 23.02250000, 72.57140000, 'Historic City of Ahmedabad India', ARRAY['ahmedabad']::text[], ARRAY['ahmedabad']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('law-garden-night-market', 'ahmedabad', 'MARKET', 2, 'HOURS', 4.5, 'Ночной рынок Law Garden', 'Law Garden Night Market', 'Law Garden түнгі базары', 23.02730000, 72.56020000, 'Law Garden Night Market Ahmedabad India', ARRAY['ahmedabad']::text[], ARRAY['ahmedabad']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('aga-khan-palace', 'pune', 'MUSEUM', 2, 'HOURS', 4.6, 'Дворец Ага-хана', 'Aga Khan Palace', 'Ага-хан сарайы', 18.55240000, 73.90150000, 'Aga Khan Palace Pune India', ARRAY['pune', 'mumbai']::text[], ARRAY['pune', 'mumbai']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('shaniwar-wada', 'pune', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Шанивар-Вада', 'Shaniwar Wada', 'Шанивар-Вада', 18.51950000, 73.85530000, 'Shaniwar Wada Pune India', ARRAY['pune']::text[], ARRAY['pune']::text[], 'Gateway_of_India,_Mumbai.jpg'),
    ('phoenix-marketcity-pune', 'pune', 'SHOPPING', 3, 'HOURS', 4.4, 'Phoenix Marketcity Pune', 'Phoenix Marketcity Pune', 'Phoenix Marketcity Pune', 18.56160000, 73.91690000, 'Phoenix Marketcity Pune India', ARRAY['pune']::text[], ARRAY['pune']::text[], 'Gateway_of_India,_Mumbai.jpg'),

    ('lalbagh-bengaluru', 'bengaluru', 'PARK', 2, 'HOURS', 4.7, 'Ботанический сад Лалбаг', 'Lalbagh Botanical Garden', 'Лалбаг ботаникалық бағы', 12.95070000, 77.58480000, 'Lalbagh Botanical Garden Bengaluru India', ARRAY['bengaluru', 'mysuru']::text[], ARRAY['bengaluru']::text[], 'Lalbagh Botanical Garden in Bangalore 2024 10.jpg'),
    ('bangalore-palace', 'bengaluru', 'ARCHITECTURE', 2, 'HOURS', 4.5, 'Бангалорский дворец', 'Bangalore Palace', 'Бангалор сарайы', 12.99870000, 77.59200000, 'Bangalore Palace India', ARRAY['bengaluru']::text[], ARRAY['bengaluru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('cubbon-park', 'bengaluru', 'PARK', 2, 'HOURS', 4.6, 'Парк Каббон', 'Cubbon Park', 'Каббон паркі', 12.97630000, 77.59290000, 'Cubbon Park Bengaluru India', ARRAY['bengaluru']::text[], ARRAY['bengaluru']::text[], 'Lalbagh Botanical Garden in Bangalore 2024 10.jpg'),
    ('ub-city', 'bengaluru', 'SHOPPING', 2, 'HOURS', 4.4, 'UB City', 'UB City', 'UB City', 12.97170000, 77.59630000, 'UB City Bengaluru India', ARRAY['bengaluru']::text[], ARRAY['bengaluru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('marina-beach', 'chennai', 'BEACH', 3, 'HOURS', 4.6, 'Пляж Марина', 'Marina Beach', 'Марина жағажайы', 13.05000000, 80.28240000, 'Marina Beach Chennai India', ARRAY['chennai']::text[], ARRAY['chennai']::text[], 'Mysore_Palace_Morning.jpg'),
    ('kapaleeshwarar-temple', 'chennai', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Капалишварар', 'Kapaleeshwarar Temple', 'Капалишварар ғибадатханасы', 13.03370000, 80.26870000, 'Kapaleeshwarar Temple Chennai India', ARRAY['chennai']::text[], ARRAY['chennai']::text[], 'Mysore_Palace_Morning.jpg'),
    ('government-museum-chennai', 'chennai', 'MUSEUM', 2, 'HOURS', 4.5, 'Правительственный музей Ченнаи', 'Government Museum Chennai', 'Ченнаи мемлекеттік музейі', 13.07140000, 80.25690000, 'Government Museum Chennai India', ARRAY['chennai']::text[], ARRAY['chennai']::text[], 'Mysore_Palace_Morning.jpg'),
    ('phoenix-marketcity-chennai', 'chennai', 'SHOPPING', 3, 'HOURS', 4.4, 'Phoenix Marketcity Chennai', 'Phoenix Marketcity Chennai', 'Phoenix Marketcity Chennai', 12.99240000, 80.21700000, 'Phoenix Marketcity Chennai India', ARRAY['chennai']::text[], ARRAY['chennai']::text[], 'Mysore_Palace_Morning.jpg'),
    ('fort-kochi', 'kochi', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Форт Кочи', 'Fort Kochi', 'Форт Кочи', 9.96580000, 76.24210000, 'Fort Kochi Kerala India', ARRAY['kochi', 'alappuzha']::text[], ARRAY['kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('chinese-fishing-nets', 'kochi', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Китайские рыболовные сети', 'Chinese Fishing Nets Kochi', 'Кочи қытай балық аулау торлары', 9.96670000, 76.24260000, 'Chinese Fishing Nets Kochi India', ARRAY['kochi']::text[], ARRAY['kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('mattancherry-palace', 'kochi', 'MUSEUM', 1, 'HOURS', 4.5, 'Дворец Маттанчерри', 'Mattancherry Palace', 'Маттанчерри сарайы', 9.95710000, 76.25970000, 'Mattancherry Palace Kochi India', ARRAY['kochi']::text[], ARRAY['kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('broadway-market-kochi', 'kochi', 'MARKET', 2, 'HOURS', 4.3, 'Broadway Market Kochi', 'Broadway Market Kochi', 'Broadway Market Kochi', 9.98160000, 76.27630000, 'Broadway Market Kochi India', ARRAY['kochi']::text[], ARRAY['kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('mysore-palace', 'mysuru', 'ARCHITECTURE', 3, 'HOURS', 4.9, 'Майсурский дворец', 'Mysore Palace', 'Майсур сарайы', 12.30520000, 76.65520000, 'Mysore Palace India', ARRAY['mysuru', 'bengaluru']::text[], ARRAY['mysuru', 'bengaluru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('brindavan-gardens', 'mysuru', 'PARK', 2, 'HOURS', 4.6, 'Сады Бриндаван', 'Brindavan Gardens', 'Бриндаван бақтары', 12.42170000, 76.57280000, 'Brindavan Gardens Mysuru India', ARRAY['mysuru']::text[], ARRAY['mysuru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('devaraja-market', 'mysuru', 'MARKET', 1, 'HOURS', 4.5, 'Рынок Девараджа', 'Devaraja Market', 'Девараджа базары', 12.31240000, 76.65290000, 'Devaraja Market Mysore India', ARRAY['mysuru']::text[], ARRAY['mysuru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('chamundi-hills', 'mysuru', 'TEMPLE', 2, 'HOURS', 4.7, 'Холмы Чамунди', 'Chamundi Hills', 'Чамунди төбелері', 12.27280000, 76.67070000, 'Chamundi Hills Mysuru India', ARRAY['mysuru']::text[], ARRAY['mysuru']::text[], 'Mysore_Palace_Morning.jpg'),
    ('charminar', 'hyderabad', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Чарминар', 'Charminar', 'Чарминар', 17.36160000, 78.47470000, 'Charminar Hyderabad India', ARRAY['hyderabad']::text[], ARRAY['hyderabad']::text[], 'Charminar_Hyderabad_1.jpg'),
    ('golconda-fort', 'hyderabad', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Форт Голконда', 'Golconda Fort', 'Голконда форты', 17.38330000, 78.40110000, 'Golconda Fort Hyderabad India', ARRAY['hyderabad']::text[], ARRAY['hyderabad']::text[], 'Charminar_Hyderabad_1.jpg'),
    ('salar-jung-museum', 'hyderabad', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей Салар Джанг', 'Salar Jung Museum', 'Салар Джанг музейі', 17.37130000, 78.48040000, 'Salar Jung Museum Hyderabad India', ARRAY['hyderabad']::text[], ARRAY['hyderabad']::text[], 'Charminar_Hyderabad_1.jpg'),
    ('laad-bazaar', 'hyderabad', 'MARKET', 2, 'HOURS', 4.5, 'Лаад-Базар', 'Laad Bazaar', 'Лаад базары', 17.36100000, 78.47310000, 'Laad Bazaar Hyderabad India', ARRAY['hyderabad']::text[], ARRAY['hyderabad']::text[], 'Charminar_Hyderabad_1.jpg'),
    ('ramoji-film-city', 'hyderabad', 'ENTERTAINMENT', 5, 'HOURS', 4.6, 'Ramoji Film City', 'Ramoji Film City', 'Ramoji Film City', 17.25430000, 78.68080000, 'Ramoji Film City Hyderabad India', ARRAY['hyderabad']::text[], ARRAY['hyderabad']::text[], 'Charminar_Hyderabad_1.jpg'),
    ('hampi-group-of-monuments', 'hampi', 'ARCHITECTURE', 5, 'HOURS', 4.9, 'Памятники Хампи', 'Hampi Group of Monuments', 'Хампи ескерткіштері', 15.33500000, 76.46000000, 'Hampi Group of Monuments India', ARRAY['hampi', 'bengaluru', 'mysuru']::text[], ARRAY['hampi', 'bengaluru']::text[], 'Hampi_virupaksha_temple.jpg'),
    ('virupaksha-temple-hampi', 'hampi', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Вирупакша', 'Virupaksha Temple Hampi', 'Вирупакша ғибадатханасы', 15.33540000, 76.45670000, 'Virupaksha Temple Hampi India', ARRAY['hampi']::text[], ARRAY['hampi']::text[], 'Hampi_virupaksha_temple.jpg'),
    ('vittala-temple', 'hampi', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Виттала', 'Vittala Temple', 'Виттала ғибадатханасы', 15.34270000, 76.47530000, 'Vittala Temple Hampi India', ARRAY['hampi']::text[], ARRAY['hampi']::text[], 'Hampi_virupaksha_temple.jpg'),
    ('hampi-bazaar', 'hampi', 'MARKET', 1, 'HOURS', 4.5, 'Хампи-Базар', 'Hampi Bazaar', 'Хампи базары', 15.33570000, 76.45800000, 'Hampi Bazaar India', ARRAY['hampi']::text[], ARRAY['hampi']::text[], 'Hampi_virupaksha_temple.jpg'),
    ('munnar-tea-gardens', 'munnar', 'NATURE', 3, 'HOURS', 4.8, 'Чайные плантации Муннара', 'Munnar Tea Gardens', 'Муннар шай плантациялары', 10.08890000, 77.05950000, 'Munnar Tea Gardens India', ARRAY['munnar', 'kochi']::text[], ARRAY['munnar', 'kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('eravikulam-national-park', 'munnar', 'PARK', 4, 'HOURS', 4.8, 'Национальный парк Эравикулам', 'Eravikulam National Park', 'Эравикулам ұлттық паркі', 10.20000000, 77.08330000, 'Eravikulam National Park Munnar India', ARRAY['munnar']::text[], ARRAY['munnar']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('alleppey-backwaters', 'alappuzha', 'NATURE', 4, 'HOURS', 4.8, 'Заводи Аллеппи', 'Alleppey Backwaters', 'Аллеппи каналдары', 9.49810000, 76.33880000, 'Alleppey Backwaters Kerala India', ARRAY['alappuzha', 'kochi']::text[], ARRAY['alappuzha', 'kochi']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('alappuzha-beach', 'alappuzha', 'BEACH', 2, 'HOURS', 4.5, 'Пляж Алаппужа', 'Alappuzha Beach', 'Алаппужа жағажайы', 9.49420000, 76.31700000, 'Alappuzha Beach Kerala India', ARRAY['alappuzha']::text[], ARRAY['alappuzha']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('kovalam-beach', 'kovalam', 'BEACH', 3, 'HOURS', 4.7, 'Пляж Ковалам', 'Kovalam Beach', 'Ковалам жағажайы', 8.40040000, 76.97870000, 'Kovalam Beach Kerala India', ARRAY['kovalam']::text[], ARRAY['kovalam']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),
    ('lighthouse-beach-kovalam', 'kovalam', 'BEACH', 3, 'HOURS', 4.7, 'Lighthouse Beach Kovalam', 'Lighthouse Beach Kovalam', 'Lighthouse Beach Kovalam', 8.38630000, 76.97880000, 'Lighthouse Beach Kovalam India', ARRAY['kovalam']::text[], ARRAY['kovalam']::text[], 'Fort_Kochi_Chinese_fishing_nets.jpg'),

    ('victoria-memorial', 'kolkata', 'MUSEUM', 2, 'HOURS', 4.8, 'Мемориал Виктории', 'Victoria Memorial', 'Виктория мемориалы', 22.54480000, 88.34260000, 'Victoria Memorial Kolkata India', ARRAY['kolkata']::text[], ARRAY['kolkata']::text[], 'Victoria_Memorial,_Kolkata.jpg'),
    ('howrah-bridge', 'kolkata', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Мост Ховрах', 'Howrah Bridge', 'Ховрах көпірі', 22.58510000, 88.34680000, 'Howrah Bridge Kolkata India', ARRAY['kolkata']::text[], ARRAY['kolkata']::text[], 'Victoria_Memorial,_Kolkata.jpg'),
    ('new-market-kolkata', 'kolkata', 'MARKET', 2, 'HOURS', 4.4, 'New Market Kolkata', 'New Market Kolkata', 'New Market Kolkata', 22.55970000, 88.35240000, 'New Market Kolkata India', ARRAY['kolkata']::text[], ARRAY['kolkata']::text[], 'Victoria_Memorial,_Kolkata.jpg'),
    ('dakshineswar-kali-temple', 'kolkata', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Дакшинешвар Кали', 'Dakshineswar Kali Temple', 'Дакшинешвар Кали ғибадатханасы', 22.65490000, 88.35730000, 'Dakshineswar Kali Temple Kolkata India', ARRAY['kolkata']::text[], ARRAY['kolkata']::text[], 'Victoria_Memorial,_Kolkata.jpg'),
    ('darjeeling-himalayan-railway', 'darjeeling', 'ENTERTAINMENT', 3, 'HOURS', 4.8, 'Дарджилингская гималайская железная дорога', 'Darjeeling Himalayan Railway', 'Дарджилинг гималай теміржолы', 27.04100000, 88.26360000, 'Darjeeling Himalayan Railway India', ARRAY['darjeeling']::text[], ARRAY['darjeeling', 'kolkata']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('tiger-hill-darjeeling', 'darjeeling', 'NATURE', 2, 'HOURS', 4.7, 'Тайгер-Хилл', 'Tiger Hill Darjeeling', 'Тайгер-Хилл', 26.99470000, 88.28560000, 'Tiger Hill Darjeeling India', ARRAY['darjeeling']::text[], ARRAY['darjeeling']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('darjeeling-mall-road', 'darjeeling', 'MARKET', 2, 'HOURS', 4.5, 'Mall Road Darjeeling', 'Darjeeling Mall Road', 'Darjeeling Mall Road', 27.04170000, 88.26630000, 'Darjeeling Mall Road India', ARRAY['darjeeling']::text[], ARRAY['darjeeling']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('umiam-lake', 'shillong', 'NATURE', 3, 'HOURS', 4.7, 'Озеро Умиам', 'Umiam Lake', 'Умиам көлі', 25.65000000, 91.88330000, 'Umiam Lake Shillong India', ARRAY['shillong', 'guwahati']::text[], ARRAY['shillong', 'guwahati']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('police-bazaar-shillong', 'shillong', 'MARKET', 2, 'HOURS', 4.4, 'Police Bazaar Shillong', 'Police Bazaar Shillong', 'Police Bazaar Shillong', 25.57880000, 91.89330000, 'Police Bazaar Shillong India', ARRAY['shillong']::text[], ARRAY['shillong']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('kamakhya-temple', 'guwahati', 'TEMPLE', 3, 'HOURS', 4.8, 'Храм Камакхья', 'Kamakhya Temple', 'Камакхья ғибадатханасы', 26.16640000, 91.70560000, 'Kamakhya Temple Guwahati India', ARRAY['guwahati', 'shillong']::text[], ARRAY['guwahati']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('brahmaputra-riverfront', 'guwahati', 'NATURE', 2, 'HOURS', 4.5, 'Набережная Брахмапутры', 'Brahmaputra Riverfront', 'Брахмапутра жағалауы', 26.18600000, 91.74500000, 'Brahmaputra Riverfront Guwahati India', ARRAY['guwahati']::text[], ARRAY['guwahati']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('mg-marg-gangtok', 'gangtok', 'MARKET', 2, 'HOURS', 4.6, 'MG Marg Gangtok', 'MG Marg Gangtok', 'MG Marg Gangtok', 27.33140000, 88.61380000, 'MG Marg Gangtok India', ARRAY['gangtok']::text[], ARRAY['gangtok']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('rumtek-monastery', 'gangtok', 'TEMPLE', 2, 'HOURS', 4.6, 'Монастырь Румтек', 'Rumtek Monastery', 'Румтек монастыры', 27.28930000, 88.56160000, 'Rumtek Monastery Gangtok India', ARRAY['gangtok']::text[], ARRAY['gangtok']::text[], 'Darjeeling_Himalayan_Railway.jpg'),
    ('rishikesh-ganga-aarti', 'rishikesh', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Ганга Аарти в Ришикеше', 'Rishikesh Ganga Aarti', 'Ришикеш Ганга Аарти', 30.10340000, 78.29480000, 'Rishikesh Ganga Aarti India', ARRAY['rishikesh', 'haridwar']::text[], ARRAY['rishikesh', 'haridwar']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('laxman-jhula', 'rishikesh', 'ARCHITECTURE', 1, 'HOURS', 4.5, 'Лакшман-Джула', 'Laxman Jhula', 'Лакшман-Джула', 30.12630000, 78.32420000, 'Laxman Jhula Rishikesh India', ARRAY['rishikesh']::text[], ARRAY['rishikesh']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('rishikesh-rafting', 'rishikesh', 'ENTERTAINMENT', 4, 'HOURS', 4.7, 'Рафтинг в Ришикеше', 'Rishikesh White Water Rafting', 'Ришикеш рафтингі', 30.10800000, 78.30000000, 'Rishikesh rafting India', ARRAY['rishikesh']::text[], ARRAY['rishikesh']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('har-ki-pauri', 'haridwar', 'TEMPLE', 2, 'HOURS', 4.8, 'Хар-ки-Паури', 'Har Ki Pauri', 'Хар-ки-Паури', 29.95610000, 78.17130000, 'Har Ki Pauri Haridwar India', ARRAY['haridwar', 'rishikesh']::text[], ARRAY['haridwar', 'rishikesh']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('haridwar-market', 'haridwar', 'MARKET', 2, 'HOURS', 4.4, 'Рынок Харидвара', 'Haridwar Market', 'Харидвар базары', 29.94570000, 78.16420000, 'Haridwar Market India', ARRAY['haridwar']::text[], ARRAY['haridwar']::text[], 'Ganga_Aarti_ceremony_with_rows_of_lamps.jpg'),
    ('manali-mall-road', 'manali', 'MARKET', 2, 'HOURS', 4.5, 'Mall Road Manali', 'Manali Mall Road', 'Manali Mall Road', 32.24320000, 77.18920000, 'Manali Mall Road India', ARRAY['manali']::text[], ARRAY['manali']::text[], 'Manali,_Himachal_Pradesh.jpg'),
    ('hidimba-devi-temple', 'manali', 'TEMPLE', 1, 'HOURS', 4.7, 'Храм Хидимба Деви', 'Hidimba Devi Temple', 'Хидимба Деви ғибадатханасы', 32.24860000, 77.17960000, 'Hidimba Devi Temple Manali India', ARRAY['manali']::text[], ARRAY['manali']::text[], 'Manali,_Himachal_Pradesh.jpg'),
    ('leh-palace', 'leh', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Дворец Лех', 'Leh Palace', 'Лех сарайы', 34.16620000, 77.58480000, 'Leh Palace Ladakh India', ARRAY['leh']::text[], ARRAY['leh']::text[], 'Leh,_Ladakh,_India.jpg'),
    ('thiksey-monastery', 'leh', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Тикси', 'Thiksey Monastery', 'Тикси монастыры', 34.05600000, 77.66670000, 'Thiksey Monastery Leh Ladakh India', ARRAY['leh']::text[], ARRAY['leh']::text[], 'Thiksey Monastery, Leh, Ladakh.jpg');

CREATE TEMP TABLE seed_india_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-india-place:' || seed.slug) AS place_hash,
        md5('id-india-media:' || seed.slug) AS media_hash
    FROM seed_india_priority_places seed
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
    ARRAY['india', city_id, slug, lower(category), 'india-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    'Туристическая точка Индии: ' || title_ru || '. Подходит для поиска по стране, городу и категории.' AS description_ru,
    'India tourist place: ' || title_en || '. Useful for search by country, city and category.' AS description_en,
    'Үндістан туристік орны: ' || title_kk || '. Ел, қала және санат бойынша іздеуге арналған.' AS description_kk,
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
    'IN',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 200::numeric
        ELSE 100::numeric
    END,
    'INR',
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
FROM seed_india_resolved_places
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
FROM seed_india_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_india_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_india_resolved_places
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
FROM seed_india_resolved_places seed
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
FROM seed_india_resolved_places
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
    'IN',
    access_city_id,
    ordinality - 1,
    NOW()
FROM seed_india_resolved_places
CROSS JOIN LATERAL unnest(access_city_ids) WITH ORDINALITY AS access(access_city_id, ordinality)
UNION ALL
SELECT
    gen_random_uuid(),
    id,
    'DEPARTURE',
    'IN',
    departure_city_id,
    ordinality - 1,
    NOW()
FROM seed_india_resolved_places
CROSS JOIN LATERAL unnest(departure_city_ids) WITH ORDINALITY AS departure(departure_city_id, ordinality)
ON CONFLICT (place_id, kind, city_id) DO UPDATE SET
    country_code = EXCLUDED.country_code,
    position = EXCLUDED.position;

DROP TABLE IF EXISTS seed_india_resolved_places;
DROP TABLE IF EXISTS seed_india_priority_places;
