-- Priority Armenia destination places seed.
-- Armenia is a country destination, while every place stays attached to
-- a concrete city, resort, village, or practical regional reference used by admin filters.

DROP TABLE IF EXISTS seed_armenia_resolved_places;
DROP TABLE IF EXISTS seed_armenia_priority_places;

CREATE TEMP TABLE seed_armenia_priority_places (
    slug varchar(96) PRIMARY KEY,
    city_id varchar(64) NOT NULL,
    category varchar(32) NOT NULL,
    duration_value int NOT NULL,
    duration_unit varchar(16) NOT NULL,
    rating numeric(2, 1) NOT NULL,
    title_ru varchar(200) NOT NULL,
    title_en varchar(200) NOT NULL,
    title_kk varchar(200) NOT NULL,
    description_ru text NOT NULL,
    description_en text NOT NULL,
    latitude numeric(10, 8) NOT NULL,
    longitude numeric(11, 8) NOT NULL,
    location_query text NOT NULL,
    media_file text NOT NULL
);

INSERT INTO seed_armenia_priority_places (
    slug,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    latitude,
    longitude,
    location_query,
    media_file
) VALUES
    ('republic-square-yerevan', 'yerevan', 'ARCHITECTURE', 1, 'HOURS', 4.8, 'Площадь Республики', 'Republic Square', 'Республика алаңы', 'Главная площадь Еревана с туфовой архитектурой, музеями и вечерними поющими фонтанами.', 'The main square of Yerevan with tuff architecture, museums and evening singing fountains.', 40.17760000, 44.51260000, 'Republic Square Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('cascade-complex-yerevan', 'yerevan', 'MUSEUM', 2, 'HOURS', 4.8, 'Каскад и Центр искусств Гафесчяна', 'Cascade Complex', 'Каскад кешені', 'Лестничный комплекс, скульптурный сад, современное искусство и панорама на город.', 'A stairway complex, sculpture garden, contemporary art space and city panorama.', 40.19110000, 44.51500000, 'Cascade Complex Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('matenadaran', 'yerevan', 'MUSEUM', 2, 'HOURS', 4.8, 'Матенадаран', 'Matenadaran', 'Матенадаран', 'Институт древних рукописей и один из важнейших культурных музеев Армении.', 'An institute of ancient manuscripts and one of Armenia most important cultural museums.', 40.19210000, 44.52080000, 'Matenadaran Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('history-museum-armenia', 'yerevan', 'MUSEUM', 2, 'HOURS', 4.7, 'Музей истории Армении', 'History Museum of Armenia', 'Армения тарихы музейі', 'Национальный музей на площади Республики с археологией, историей и культурой Армении.', 'A national museum on Republic Square covering Armenian archaeology, history and culture.', 40.17840000, 44.51440000, 'History Museum of Armenia Yerevan', 'Yerevan,_Armenia.jpg'),
    ('armenian-genocide-memorial-museum', 'yerevan', 'MUSEUM', 2, 'HOURS', 4.8, 'Мемориал и музей Геноцида армян', 'Armenian Genocide Memorial and Museum', 'Армян геноциді мемориалы мен музейі', 'Мемориальный комплекс Цицернакаберд и музей-институт с историческим контекстом.', 'The Tsitsernakaberd memorial complex and museum institute with historical context.', 40.18580000, 44.49060000, 'Armenian Genocide Memorial Museum Yerevan', 'Yerevan,_Armenia.jpg'),
    ('erebuni-fortress-museum', 'yerevan', 'MUSEUM', 2, 'HOURS', 4.6, 'Крепость Эребуни', 'Erebuni Fortress and Museum', 'Эребуни қамалы мен музейі', 'Урартская крепость 782 года до н.э. и музей, связанный с ранней историей Еревана.', 'A Urartian fortress from 782 BCE and museum connected with early Yerevan history.', 40.14140000, 44.53530000, 'Erebuni Fortress Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('blue-mosque-yerevan', 'yerevan', 'TEMPLE', 1, 'HOURS', 4.5, 'Голубая мечеть', 'Blue Mosque', 'Көк мешіт', 'Персидская мечеть XVIII века и редкий исламский памятник в центре Еревана.', 'An eighteenth century Persian mosque and a rare Islamic monument in central Yerevan.', 40.17800000, 44.50520000, 'Blue Mosque Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('vernissage-market-yerevan', 'yerevan', 'MARKET', 2, 'HOURS', 4.6, 'Вернисаж', 'Vernissage Market', 'Вернисаж базары', 'Открытый рынок ремесел, сувениров, ковров, картин, украшений и антиквариата.', 'An open market for crafts, souvenirs, carpets, paintings, jewellery and antiques.', 40.17670000, 44.51960000, 'Vernissage Market Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('gum-market-yerevan', 'yerevan', 'MARKET', 2, 'HOURS', 4.5, 'Рынок ГУМ', 'GUM Market', 'GUM базары', 'Локальный продуктовый рынок с фруктами, специями, сухофруктами, сладостями и сырами.', 'A local food market with fruit, spices, dried fruit, sweets and cheeses.', 40.16960000, 44.51680000, 'GUM Market Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('yerevan-2800-park', 'yerevan', 'PARK', 1, 'HOURS', 4.5, 'Парк 2800-летия Еревана', 'Yerevan 2800th Anniversary Park', 'Ереванның 2800 жылдығы саябағы', 'Центральный парк с фонтанами, скульптурами и орнаментами армянских ковров.', 'A central park with fountains, sculptures and Armenian carpet ornaments.', 40.17480000, 44.51380000, 'Yerevan 2800th Anniversary Park Armenia', 'Yerevan,_Armenia.jpg'),
    ('lovers-park-yerevan', 'yerevan', 'PARK', 1, 'HOURS', 4.5, 'Парк влюбленных', 'Lovers Park', 'Ғашықтар саябағы', 'Уютный городской парк у проспекта Баграмяна для спокойной прогулки и отдыха.', 'A cosy urban park near Baghramyan Avenue for calm walks and breaks.', 40.19170000, 44.50690000, 'Lovers Park Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('victory-park-mother-armenia', 'yerevan', 'PARK', 2, 'HOURS', 4.6, 'Парк Победы и Мать Армения', 'Victory Park and Mother Armenia', 'Жеңіс саябағы және Ана Армения', 'Большой парк с панорамой, аттракционами, озером и мемориальной доминантой.', 'A large park with panoramas, rides, a lake and the Mother Armenia memorial.', 40.19750000, 44.52380000, 'Victory Park Mother Armenia Yerevan', 'Yerevan,_Armenia.jpg'),
    ('yerevan-botanical-garden', 'yerevan', 'NATURE', 2, 'HOURS', 4.4, 'Ботанический сад Еревана', 'Yerevan Botanical Garden', 'Ереван ботаникалық бағы', 'Большая зеленая научно-просветительская территория в районе Аван.', 'A large green scientific and educational garden in the Avan district.', 40.21100000, 44.55850000, 'Yerevan Botanical Garden Armenia', 'Yerevan,_Armenia.jpg'),
    ('yerevan-zoo', 'yerevan', 'ENTERTAINMENT', 2, 'HOURS', 4.3, 'Ереванский зоопарк', 'Yerevan Zoo', 'Ереван зообағы', 'Семейная точка рядом с ботаническим садом, животными и образовательными программами.', 'A family place near the botanical garden with animals and educational programmes.', 40.19600000, 44.55050000, 'Yerevan Zoo Armenia', 'Yerevan,_Armenia.jpg'),
    ('water-world-yerevan', 'yerevan', 'ENTERTAINMENT', 3, 'HOURS', 4.2, 'Аквапарк Джрашхар', 'Water World', 'Water World аквапаркі', 'Летний аквапарк с бассейнами, водными горками и семейной инфраструктурой.', 'A summer water park with pools, slides and family infrastructure.', 40.20440000, 44.55680000, 'Water World Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('yerevan-mall', 'yerevan', 'SHOPPING', 3, 'HOURS', 4.5, 'Ереван Молл', 'Yerevan Mall', 'Ереван моллы', 'Крупный торгово-развлекательный центр с магазинами, кинотеатром, фудкортом и детской зоной.', 'A large shopping and entertainment centre with stores, cinema, food court and kids area.', 40.15470000, 44.50260000, 'Yerevan Mall Armenia', 'Yerevan,_Armenia.jpg'),
    ('dalma-garden-mall', 'yerevan', 'SHOPPING', 3, 'HOURS', 4.5, 'Далма Гарден Молл', 'Dalma Garden Mall', 'Dalma Garden Mall', 'Современный молл с брендами, кино, ресторанами и семейным досугом.', 'A modern mall with brands, cinema, restaurants and family leisure.', 40.17990000, 44.48850000, 'Dalma Garden Mall Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('saryan-wine-street', 'yerevan', 'FOOD', 2, 'HOURS', 4.6, 'Винная улица Сарьяна', 'Saryan Wine and Gastro Cluster', 'Сарьян шарап және гастро аймағы', 'Городской кластер винных баров, ресторанов и фестивальной вечерней атмосферы.', 'An urban cluster of wine bars, restaurants and festive evening atmosphere.', 40.18460000, 44.50860000, 'Saryan Street Wine Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('seasonal-holiday-market-yerevan', 'yerevan', 'MARKET', 1, 'HOURS', 4.2, 'Сезонный праздничный рынок Еревана', 'Seasonal Holiday Market', 'Ереван маусымдық мерекелік базары', 'Зимний и праздничный market-сценарий у центральных площадей с едой, декором и огнями.', 'A winter and holiday market scenario around central squares with food, decor and lights.', 40.17760000, 44.51260000, 'Holiday Market Yerevan Armenia', 'Yerevan,_Armenia.jpg'),
    ('etchmiadzin-cathedral', 'vagharshapat', 'TEMPLE', 2, 'HOURS', 4.8, 'Кафедральный собор Эчмиадзин', 'Etchmiadzin Cathedral', 'Эчмиадзин кафедралды соборы', 'Главный духовный центр Армянской апостольской церкви и объект наследия ЮНЕСКО.', 'The main spiritual centre of the Armenian Apostolic Church and a UNESCO heritage site.', 40.16180000, 44.29100000, 'Etchmiadzin Cathedral Vagharshapat Armenia', 'Yerevan,_Armenia.jpg'),
    ('saint-hripsime-church', 'vagharshapat', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Святой Рипсимэ', 'Saint Hripsime Church', 'Әулие Рипсимэ шіркеуі', 'Церковь VII века и часть церковного ансамбля Эчмиадзина.', 'A seventh century church and part of the Etchmiadzin church ensemble.', 40.16660000, 44.30900000, 'Saint Hripsime Church Vagharshapat Armenia', 'Yerevan,_Armenia.jpg'),
    ('saint-gayane-church', 'vagharshapat', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Святой Гаянэ', 'Saint Gayane Church', 'Әулие Гаянэ шіркеуі', 'Раннесредневековая церковь рядом с кафедральным комплексом Эчмиадзина.', 'An early medieval church near the Etchmiadzin cathedral complex.', 40.15750000, 44.29120000, 'Saint Gayane Church Vagharshapat Armenia', 'Yerevan,_Armenia.jpg'),
    ('shoghakat-church', 'vagharshapat', 'TEMPLE', 1, 'HOURS', 4.5, 'Церковь Шогакат', 'Shoghakat Church', 'Шоғакат шіркеуі', 'Церковь XVII века, дополняющая маршрут по храмам Вагаршапата.', 'A seventeenth century church that completes the Vagharshapat church route.', 40.16990000, 44.30520000, 'Shoghakat Church Vagharshapat Armenia', 'Yerevan,_Armenia.jpg'),
    ('zvartnots-archaeological-site', 'vagharshapat', 'TEMPLE', 2, 'HOURS', 4.7, 'Археологический комплекс Звартноц', 'Zvartnots Archaeological Site', 'Звартноц археологиялық кешені', 'Руины храма VII века и музей-заповедник с сильным визуальным силуэтом.', 'Ruins of a seventh century cathedral and museum-reserve with a strong visual silhouette.', 40.15940000, 44.33690000, 'Zvartnots Archaeological Site Armenia', 'Yerevan,_Armenia.jpg'),
    ('garni-temple', 'garni', 'TEMPLE', 2, 'HOURS', 4.8, 'Храм Гарни', 'Garni Temple', 'Гарни храмы', 'Античный храм и музей-заповедник в ущелье Азата, популярный day-trip из Еревана.', 'An ancient temple and museum-reserve in the Azat Gorge, a popular day trip from Yerevan.', 40.11260000, 44.73010000, 'Garni Temple Armenia', 'Garni_Temple,_Armenia.jpg'),
    ('symphony-of-stones', 'garni', 'NATURE', 1, 'HOURS', 4.8, 'Симфония камней', 'Symphony of Stones', 'Тастар симфониясы', 'Базальтовые колонны в ущелье Гарни и одна из самых фотогеничных природных точек Армении.', 'Basalt columns in Garni Gorge and one of Armenia most photogenic natural sites.', 40.11470000, 44.74170000, 'Symphony of Stones Garni Armenia', 'Garni_Temple,_Armenia.jpg'),
    ('geghard-monastery', 'geghard', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Гегард', 'Geghard Monastery', 'Гегард монастыры', 'Скальный монастырь и долина Верхнего Азата, включенные в список ЮНЕСКО.', 'A rock-cut monastery and Upper Azat Valley inscribed on the UNESCO list.', 40.14050000, 44.81860000, 'Geghard Monastery Armenia', 'Geghard_Monastery,_Armenia.jpg'),
    ('amberd-fortress', 'byurakan', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Крепость Амберд', 'Amberd Fortress', 'Амберд қамалы', 'Средневековая крепость на склонах Арагаца с горными видами и историческим маршрутом.', 'A medieval fortress on the slopes of Aragats with mountain views and a historical route.', 40.38990000, 44.22600000, 'Amberd Fortress Armenia', 'Yerevan,_Armenia.jpg'),
    ('byurakan-observatory', 'byurakan', 'MUSEUM', 2, 'HOURS', 4.5, 'Бюраканская обсерватория', 'Byurakan Observatory', 'Бюракан обсерваториясы', 'Научная обсерватория на склонах Арагаца, связанная с астрономическим наследием Армении.', 'A scientific observatory on the slopes of Aragats tied to Armenia astronomical heritage.', 40.33030000, 44.27360000, 'Byurakan Observatory Armenia', 'Yerevan,_Armenia.jpg'),
    ('saghmosavank-monastery', 'ashtarak', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Сагмосаванк', 'Saghmosavank Monastery', 'Сағмосаванк монастыры', 'Монастырь над ущельем Касах с красивым видом и коротким выездом из Еревана.', 'A monastery above the Kasagh Gorge with a beautiful view and short access from Yerevan.', 40.38030000, 44.39600000, 'Saghmosavank Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('lake-sevan', 'sevan', 'NATURE', 4, 'HOURS', 4.8, 'Озеро Севан', 'Lake Sevan', 'Севан көлі', 'Главное высокогорное озеро Армении с пляжами, кафе, водными активностями и панорамами.', 'Armenia main highland lake with beaches, cafes, water activities and panoramas.', 40.31700000, 45.35000000, 'Lake Sevan Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('sevan-national-park', 'sevan', 'PARK', 4, 'HOURS', 4.6, 'Национальный парк Севан', 'Sevan National Park', 'Севан ұлттық паркі', 'Охраняемая территория вокруг озера, важная для природы, птиц и экосистемы Севана.', 'A protected area around the lake, important for nature, birds and the Sevan ecosystem.', 40.56000000, 45.00000000, 'Sevan National Park Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('sevanavank-monastery', 'sevan', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Севанаванк', 'Sevanavank Monastery', 'Севанаванк монастыры', 'Монастырь IX века на полуострове с панорамой озера Севан.', 'A ninth century monastery on the peninsula with a panorama of Lake Sevan.', 40.56460000, 45.01010000, 'Sevanavank Monastery Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('sevan-writers-house', 'sevan', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Дом писателей Севана', 'Sevan Writers House', 'Севан жазушылар үйі', 'Объект советского модернизма на полуострове и культурная видовая точка.', 'A Soviet modernist retreat on the peninsula and a cultural viewpoint.', 40.56300000, 45.00400000, 'Sevan Writers House Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('lake-sevan-public-beach', 'sevan', 'BEACH', 3, 'HOURS', 4.4, 'Общественный пляж озера Севан', 'Lake Sevan Public Beach', 'Севан қоғамдық жағажайы', 'Летняя пляжная зона у озера для купания, SUP, лодок и семейного отдыха.', 'A summer lakeside beach area for swimming, SUP, boats and family leisure.', 40.55300000, 45.01000000, 'Lake Sevan Public Beach Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('sevan-peninsula-fish-market', 'sevan', 'MARKET', 1, 'HOURS', 4.2, 'Рыбный и сувенирный кластер Севана', 'Sevan Peninsula Fish and Souvenir Cluster', 'Севан балық және сувенир аймағы', 'Кафе, сувениры, рыба и ремесленные лавки у полуострова Севан.', 'Cafes, souvenirs, fish and craft stalls around the Sevan peninsula.', 40.56300000, 45.00800000, 'Sevan Peninsula Fish Souvenir Market Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('shorzha-beach', 'shorzha', 'BEACH', 3, 'HOURS', 4.3, 'Пляж Шоржа', 'Shorzha Beach', 'Шоржа жағажайы', 'Более спокойный северный берег Севана с пляжами, гостевыми домами и кафе.', 'A calmer northern shore of Sevan with beaches, guesthouses and cafes.', 40.50300000, 45.27400000, 'Shorzha Beach Lake Sevan Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('hayravank-monastery', 'gavar', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Айраванк', 'Hayravank Monastery', 'Айраванк монастыры', 'Средневековый монастырь на скале над южным берегом Севана.', 'A medieval monastery on a cliff above the southern shore of Sevan.', 40.43390000, 45.10840000, 'Hayravank Monastery Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('noratus-cemetery', 'noratus', 'OTHER', 2, 'HOURS', 4.7, 'Кладбище хачкаров Норатус', 'Noratus Cemetery', 'Норатус хачкарлары', 'Крупнейшее поле хачкаров и open-air heritage site у озера Севан.', 'The largest field of khachkars and an open-air heritage site near Lake Sevan.', 40.37700000, 45.18200000, 'Noratus Cemetery Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('mount-artanish', 'artanish', 'NATURE', 4, 'HOURS', 4.7, 'Гора Артаниш', 'Mount Artanish', 'Артаниш тауы', 'Хайкинг с панорамой Большого и Малого Севана и природным маршрутом.', 'A hiking route with a panorama of Big and Small Sevan.', 40.44400000, 45.31500000, 'Mount Artanish Armenia', 'Lake_Sevan,_Armenia.jpg'),
    ('dilijan-national-park', 'dilijan', 'PARK', 5, 'HOURS', 4.8, 'Дилижанский национальный парк', 'Dilijan National Park', 'Дилижан ұлттық паркі', 'Леса, тропы, озера, монастыри и минеральные источники в главном зеленом кластере Армении.', 'Forests, trails, lakes, monasteries and mineral springs in Armenia main green cluster.', 40.74100000, 44.86600000, 'Dilijan National Park Armenia', 'Yerevan,_Armenia.jpg'),
    ('lake-parz', 'dilijan', 'NATURE', 2, 'HOURS', 4.6, 'Озеро Парз', 'Lake Parz', 'Парз көлі', 'Лесное озеро в Дилижанском национальном парке для прогулок, пикников и семейного отдыха.', 'A forest lake in Dilijan National Park for walks, picnics and family leisure.', 40.75290000, 44.96160000, 'Lake Parz Dilijan Armenia', 'Yerevan,_Armenia.jpg'),
    ('parz-lake-extreme-park', 'dilijan', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Экстрим-парк Парз', 'Parz Lake Extreme Park', 'Парз көлі экстрим паркі', 'Зиплайн и активный отдых у озера Парз для семей и групп.', 'Zipline and active leisure by Lake Parz for families and groups.', 40.75300000, 44.96200000, 'Parz Lake Extreme Park Armenia', 'Yerevan,_Armenia.jpg'),
    ('haghartsin-monastery', 'haghartsin', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Агарцин', 'Haghartsin Monastery', 'Агарцин монастыры', 'Монастырский комплекс X-XIII веков в лесной долине Дилижана.', 'A tenth to thirteenth century monastery complex in a forested Dilijan valley.', 40.80250000, 44.89160000, 'Haghartsin Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('goshavank-monastery', 'gosh', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Гошаванк', 'Goshavank Monastery', 'Гошаванк монастыры', 'Средневековый монастырь, школа Мхитара Гоша и знаменитые хачкары.', 'A medieval monastery, Mkhitar Gosh school and famous khachkars.', 40.72900000, 45.00070000, 'Goshavank Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('lake-gosh', 'gosh', 'NATURE', 3, 'HOURS', 4.5, 'Озеро Гош', 'Lake Gosh', 'Гош көлі', 'Малое лесное горное озеро рядом с Гошаванком и тропами Дилижана.', 'A small forest mountain lake near Goshavank and Dilijan trails.', 40.73300000, 45.02600000, 'Lake Gosh Armenia', 'Yerevan,_Armenia.jpg'),
    ('old-dilijan-sharambeyan', 'dilijan', 'SHOPPING', 2, 'HOURS', 4.5, 'Старый Дилижан и улица Шарамбеяна', 'Old Dilijan and Sharambeyan Street', 'Ескі Дилижан және Шарамбеян көшесі', 'Ремесленные лавки, сувениры и реконструированная историческая атмосфера Дилижана.', 'Craft shops, souvenirs and restored historic atmosphere of Dilijan.', 40.74100000, 44.86400000, 'Old Dilijan Sharambeyan Street Armenia', 'Yerevan,_Armenia.jpg'),
    ('dilijan-local-lore-museum', 'dilijan', 'MUSEUM', 2, 'HOURS', 4.4, 'Краеведческий музей и галерея Дилижана', 'Dilijan Local Lore Museum and Art Gallery', 'Дилижан өлкетану музейі және галереясы', 'Археология, этнография и живопись в центральном музее Дилижана.', 'Archaeology, ethnography and painting in central Dilijan museum.', 40.74100000, 44.86400000, 'Dilijan Local Lore Museum Armenia', 'Yerevan,_Armenia.jpg'),
    ('yell-extreme-park', 'yenokavan', 'ENTERTAINMENT', 4, 'HOURS', 4.8, 'Yell Extreme Park', 'Yell Extreme Park', 'Yell Extreme Park', 'Adventure-парк в Енокаване с зиплайном, via ferrata, off-road и активностями.', 'An adventure park in Yenokavan with zipline, via ferrata, off-road and activities.', 40.91200000, 45.07800000, 'Yell Extreme Park Armenia', 'Yerevan,_Armenia.jpg'),
    ('lastiver-caves-waterfall', 'yenokavan', 'NATURE', 4, 'HOURS', 4.8, 'Пещеры и водопад Ластивер', 'Lastiver Caves and Waterfall', 'Ластивер үңгірлері мен сарқырамасы', 'Лесной каньон, пещеры, водопад и хайкинг рядом с Енокаваном.', 'A forest canyon, caves, waterfall and hiking route near Yenokavan.', 40.92800000, 45.08700000, 'Lastiver Caves Waterfall Armenia', 'Yerevan,_Armenia.jpg'),
    ('tsaghkadzor-ropeway', 'tsaghkadzor', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Канатная дорога Цахкадзора', 'Tsaghkadzor Ropeway', 'Цахкадзор аспалы жолы', 'Круглогодичная канатная дорога, горные виды и зимне-летний resort-сценарий.', 'A year-round ropeway, mountain views and winter-summer resort scenario.', 40.53300000, 44.70700000, 'Tsaghkadzor Ropeway Armenia', 'Yerevan,_Armenia.jpg'),
    ('kecharis-monastery', 'tsaghkadzor', 'TEMPLE', 1, 'HOURS', 4.7, 'Монастырь Кечарис', 'Kecharis Monastery', 'Кечарис монастыры', 'Монастырский комплекс XI-XIII веков в центре курортного Цахкадзора.', 'An eleventh to thirteenth century monastery complex in central Tsaghkadzor.', 40.53200000, 44.72100000, 'Kecharis Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('orbeli-brothers-museum', 'tsaghkadzor', 'MUSEUM', 1, 'HOURS', 4.3, 'Дом-музей братьев Орбели', 'Orbeli Brothers House-Museum', 'Орбели ағайындылары музейі', 'Мемориальный музей ученых братьев Орбели и культурная точка Цахкадзора.', 'A memorial museum of the Orbeli brothers and a cultural point in Tsaghkadzor.', 40.53100000, 44.72000000, 'Orbeli Brothers Museum Tsaghkadzor Armenia', 'Yerevan,_Armenia.jpg'),
    ('kumayri-historic-district', 'gyumri', 'ARCHITECTURE', 3, 'HOURS', 4.7, 'Исторический район Кумайри', 'Kumayri Historic District', 'Кумайри тарихи ауданы', 'Старый Гюмри с черно-туфовой архитектурой, ремесленными точками, кафе и городской прогулкой.', 'Old Gyumri with black tuff architecture, craft points, cafes and city walks.', 40.78620000, 43.84100000, 'Kumayri Historic District Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('vardanants-square-gyumri', 'gyumri', 'ARCHITECTURE', 1, 'HOURS', 4.6, 'Площадь Вардананц', 'Vardanants Square', 'Вардананц алаңы', 'Центральная площадь Гюмри и точка старта для маршрута по старому городу.', 'The central square of Gyumri and a starting point for an old city route.', 40.78690000, 43.84730000, 'Vardanants Square Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('holy-saviour-church-gyumri', 'gyumri', 'TEMPLE', 1, 'HOURS', 4.7, 'Церковь Святого Всеспасителя', 'Holy Saviour Church', 'Қасиетті Құтқарушы шіркеуі', 'Один из главных символов Гюмри, восстановленный после землетрясения.', 'One of Gyumri main symbols, restored after the earthquake.', 40.78590000, 43.84580000, 'Holy Saviour Church Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('dzitoghtsyan-museum', 'gyumri', 'MUSEUM', 2, 'HOURS', 4.6, 'Музей городского быта и национальной архитектуры', 'Museum of Urban Life and National Architecture', 'Қалалық тұрмыс және ұлттық сәулет музейі', 'Музей в историческом особняке о быте, ремеслах и архитектуре старого Гюмри.', 'A museum in a historic mansion about everyday life, crafts and architecture of old Gyumri.', 40.78590000, 43.83890000, 'Museum of Urban Life Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('aslamazyan-sisters-gallery', 'gyumri', 'MUSEUM', 1, 'HOURS', 4.5, 'Галерея сестер Асламазян', 'Gallery of Mariam and Eranuhi Aslamazyan Sisters', 'Асламазян әпкелері галереясы', 'Галерея художниц Асламазян и сильный культурный POI Гюмри.', 'A gallery of the Aslamazyan sisters and a strong cultural POI in Gyumri.', 40.78625000, 43.84095000, 'Aslamazyan Sisters Gallery Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('black-fortress-gyumri', 'gyumri', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Черная крепость Сев Берд', 'Black Fortress', 'Қара қамал', 'Круглая крепость XIX века из черного туфа с панорамой города.', 'A nineteenth century round fortress of black tuff with a panorama of the city.', 40.77330000, 43.83060000, 'Black Fortress Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('gyumri-central-park', 'gyumri', 'PARK', 1, 'HOURS', 4.3, 'Центральный парк Гюмри', 'Gyumri Central Park', 'Гюмри орталық саябағы', 'Городской парк для семейной прогулки и отдыха между музеями и крепостью.', 'An urban park for family walks and breaks between museums and the fortress.', 40.78300000, 43.83300000, 'Gyumri Central Park Armenia', 'Yerevan,_Armenia.jpg'),
    ('gyumri-shuka-bazaar', 'gyumri', 'MARKET', 2, 'HOURS', 4.4, 'Гюмрийская шука', 'Gyumri Bazaar', 'Гюмри базары', 'Открытый рынок продуктов, специй, сыров и локального повседневного опыта.', 'An open market for produce, spices, cheese and local everyday experience.', 40.78600000, 43.84500000, 'Gyumri Bazaar Armenia', 'Yerevan,_Armenia.jpg'),
    ('aregak-inclusive-bakery', 'gyumri', 'FOOD', 1, 'HOURS', 4.6, 'Инклюзивная пекарня-кафе Арегак', 'Aregak Inclusive Bakery-Cafe', 'Арегак инклюзивті наубайхана-кафесі', 'Социальное кафе и пекарня с инклюзивной миссией в городском маршруте Гюмри.', 'A social cafe and bakery with an inclusive mission in the Gyumri city route.', 40.78900000, 43.84600000, 'Aregak Bakery Gyumri Armenia', 'Yerevan,_Armenia.jpg'),
    ('marmashen-monastery', 'gyumri', 'TEMPLE', 2, 'HOURS', 4.7, 'Монастырь Мармашен', 'Marmashen Monastery', 'Мармашен монастыры', 'Средневековый монастырский комплекс у реки Ахурян, удобный выезд из Гюмри.', 'A medieval monastery complex by the Akhuryan River, an easy trip from Gyumri.', 40.84250000, 43.75940000, 'Marmashen Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('harichavank-monastery', 'gyumri', 'TEMPLE', 2, 'HOURS', 4.6, 'Монастырь Аричаванк', 'Harichavank Monastery', 'Аричаванк монастыры', 'Монастырь VII-XIII веков у Артика с историей школы и скриптория.', 'A seventh to thirteenth century monastery near Artik with a school and scriptorium history.', 40.60860000, 43.99900000, 'Harichavank Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('vanadzor-fine-arts-museum', 'vanadzor', 'MUSEUM', 2, 'HOURS', 4.3, 'Ванадзорский музей изобразительных искусств', 'Vanadzor Fine Arts Museum', 'Ванадзор бейнелеу өнері музейі', 'Центральный музей искусства Ванадзора и культурная точка для маршрутов Лори.', 'The central art museum of Vanadzor and a cultural point for Lori routes.', 40.80720000, 44.49640000, 'Vanadzor Fine Arts Museum Armenia', 'Yerevan,_Armenia.jpg'),
    ('vanadzor-dendropark', 'vanadzor', 'PARK', 2, 'HOURS', 4.4, 'Ванадзорский дендропарк', 'Vanadzor Dendropark', 'Ванадзор дендропаркі', 'Зеленая семейная зона с местной и экзотической флорой для спокойной прогулки.', 'A green family area with native and exotic flora for a calm walk.', 40.78900000, 44.46900000, 'Vanadzor Dendropark Armenia', 'Yerevan,_Armenia.jpg'),
    ('haghpat-monastery', 'alaverdi', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Ахпат', 'Haghpat Monastery', 'Ахпат монастыры', 'Монастырь X-XIII веков и объект ЮНЕСКО в Дебедском ущелье.', 'A tenth to thirteenth century monastery and UNESCO site in Debed Canyon.', 41.09380000, 44.71240000, 'Haghpat Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('sanahin-monastery', 'alaverdi', 'TEMPLE', 2, 'HOURS', 4.8, 'Монастырь Санаин', 'Sanahin Monastery', 'Санаин монастыры', 'Монастырь ЮНЕСКО, известный средневековой школой, рукописной традицией и архитектурой.', 'A UNESCO monastery known for its medieval school, manuscript tradition and architecture.', 41.08740000, 44.66640000, 'Sanahin Monastery Armenia', 'Yerevan,_Armenia.jpg'),
    ('akhtala-monastery-fortress', 'alaverdi', 'TEMPLE', 2, 'HOURS', 4.7, 'Ахтальский монастырь-крепость', 'Akhtala Monastery and Fortress', 'Ахтала монастырь-қамалы', 'Монастырь-крепость с выразительными средневековыми фресками в регионе Лори.', 'A monastery-fortress with expressive medieval frescoes in Lori region.', 41.15070000, 44.76460000, 'Akhtala Monastery Fortress Armenia', 'Yerevan,_Armenia.jpg'),
    ('odzun-church', 'odzun', 'TEMPLE', 1, 'HOURS', 4.6, 'Одзунская церковь', 'Odzun Church', 'Одзун шіркеуі', 'Раннесредневековая церковь с уникальным каменным монументом рядом.', 'An early medieval church with a unique stone monument nearby.', 41.05300000, 44.61300000, 'Odzun Church Armenia', 'Yerevan,_Armenia.jpg'),
    ('lori-fortress', 'stepanavan', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Лорийская крепость', 'Lori Fortress', 'Лори қамалы', 'Средневековая крепость на плато у Степанавана с панорамой ущелья.', 'A medieval fortress on a plateau near Stepanavan with canyon panoramas.', 41.00600000, 44.38900000, 'Lori Fortress Armenia', 'Yerevan,_Armenia.jpg'),
    ('debed-canyon', 'alaverdi', 'NATURE', 4, 'HOURS', 4.7, 'Дебедское ущелье', 'Debed Canyon', 'Дебед шатқалы', 'Главная природно-культурная ось Лори с рекой, каньоном, монастырями и outdoor-маршрутами.', 'The main nature and culture axis of Lori with river, canyon, monasteries and outdoor routes.', 41.06000000, 44.65000000, 'Debed Canyon Armenia', 'Yerevan,_Armenia.jpg'),
    ('trchkan-waterfall', 'stepanavan', 'NATURE', 3, 'HOURS', 4.6, 'Водопад Трчкан', 'Trchkan Waterfall', 'Трчкан сарқырамасы', 'Один из самых высоких водопадов Армении на границе Лори и Ширака.', 'One of Armenia tallest waterfalls on the Lori-Shirak border.', 40.91500000, 44.05000000, 'Trchkan Waterfall Armenia', 'Yerevan,_Armenia.jpg'),
    ('sochut-dendropark', 'stepanavan', 'PARK', 2, 'HOURS', 4.5, 'Сочутский дендропарк', 'Sochut Dendropark', 'Сочут дендропаркі', 'Дендропарк у Степанавана для семейной прогулки, экотуризма и тихого отдыха.', 'A dendropark near Stepanavan for family walks, ecotourism and calm leisure.', 40.99300000, 44.47600000, 'Sochut Dendropark Armenia', 'Yerevan,_Armenia.jpg'),
    ('noravank-monastery', 'areni', 'TEMPLE', 2, 'HOURS', 4.9, 'Монастырь Нораванк', 'Noravank Monastery', 'Нораванк монастыры', 'Фотогеничный монастырь в красном каньоне Вайоц Дзора на маршруте Арени.', 'A photogenic monastery in the red canyon of Vayots Dzor on the Areni route.', 39.68470000, 45.23280000, 'Noravank Monastery Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('noravank-canyon', 'areni', 'NATURE', 2, 'HOURS', 4.7, 'Каньон Нораванк', 'Noravank Canyon', 'Нораванк каньоны', 'Красный каньон вокруг монастыря, сильная фото- и видовая остановка.', 'The red canyon around the monastery, a strong photo and viewpoint stop.', 39.68600000, 45.23000000, 'Noravank Canyon Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('areni-1-cave', 'areni', 'MUSEUM', 1, 'HOURS', 4.6, 'Пещера Арени-1', 'Areni-1 Cave', 'Арени-1 үңгірі', 'Археологическая пещера с древним винодельческим комплексом и находками энеолита.', 'An archaeological cave with an ancient winemaking complex and Chalcolithic finds.', 39.73100000, 45.20300000, 'Areni-1 Cave Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('areni-wine-village', 'areni', 'FOOD', 2, 'HOURS', 4.6, 'Винное село Арени', 'Areni Wine Village', 'Арени шарап ауылы', 'Кластер дегустаций, виноделен и локальной кухни на южном маршруте.', 'A cluster of tastings, wineries and local food on the southern route.', 39.71900000, 45.18300000, 'Areni Wine Village Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('hin-areni-winery', 'areni', 'FOOD', 2, 'HOURS', 4.6, 'Винодельня Hin Areni', 'Hin Areni Winery', 'Hin Areni шарап зауыты', 'Современная винодельня с дегустациями сортов Areni Noir и Voskehat.', 'A modern winery with tastings of Areni Noir and Voskehat varieties.', 39.72050000, 45.18250000, 'Hin Areni Winery Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('jermuk-waterfall', 'jermuk', 'NATURE', 1, 'HOURS', 4.7, 'Джермукский водопад', 'Jermuk Waterfall', 'Джермук сарқырамасы', 'Высокий каскадный водопад Волосы русалки и ключевая природная точка курорта.', 'A tall cascading waterfall known as Mermaid Hair and a key natural point of the resort.', 39.84000000, 45.67200000, 'Jermuk Waterfall Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('jermuk-gallery-of-water', 'jermuk', 'OTHER', 1, 'HOURS', 4.5, 'Галерея минеральных вод Джермука', 'Jermuk Gallery of Water', 'Джермук минералды су галереясы', 'Питьевая галерея с минеральными источниками разной температуры и wellness-контекстом.', 'A drinking gallery with mineral springs of different temperatures and wellness context.', 39.84100000, 45.67250000, 'Jermuk Gallery of Water Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('jermuk-ropeway', 'jermuk', 'ENTERTAINMENT', 2, 'HOURS', 4.2, 'Канатная дорога Джермука', 'Jermuk Ropeway', 'Джермук аспалы жолы', 'Канатная дорога с видами на леса, горы и курортную зону Джермука.', 'A ropeway with views of forests, mountains and the Jermuk resort area.', 39.85200000, 45.66800000, 'Jermuk Ropeway Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('gndevank-monastery', 'jermuk', 'TEMPLE', 2, 'HOURS', 4.5, 'Монастырь Гндеванк', 'Gndevank Monastery', 'Гндеванк монастыры', 'Монастырь X века в каньоне Арпы, связанный с пешими маршрутами Джермука.', 'A tenth century monastery in the Arpa canyon connected with Jermuk hiking routes.', 39.76000000, 45.61000000, 'Gndevank Monastery Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('old-goris-cave-dwellings', 'goris', 'ARCHITECTURE', 2, 'HOURS', 4.6, 'Старый Горис и пещерный Кёрес', 'Old Goris Cave Dwellings', 'Ескі Горис үңгір үйлері', 'Исторический район пещерных жилищ к востоку от современного Гориса.', 'A historic cave dwelling district east of modern Goris.', 39.51200000, 46.35600000, 'Old Goris Cave Dwellings Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('stone-forest-goris', 'goris', 'NATURE', 2, 'HOURS', 4.6, 'Каменный лес Гориса', 'Stone Forest of Goris', 'Горис тас орманы', 'Скальные башни, пирамиды и пещерный ландшафт вокруг города.', 'Rock towers, pyramids and cave landscape around the city.', 39.51000000, 46.35000000, 'Stone Forest Goris Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('aksel-bakunts-house-museum', 'goris', 'MUSEUM', 1, 'HOURS', 4.4, 'Дом-музей Акселя Бакунца', 'Aksel Bakunts House-Museum', 'Аксел Бакунц музей-үйі', 'Мемориальный музей писателя в традиционном доме Сюника.', 'A memorial museum of the writer in a traditional Syunik house.', 39.51110000, 46.34080000, 'Aksel Bakunts House Museum Goris Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('goris-local-lore-museum', 'goris', 'MUSEUM', 1, 'HOURS', 4.3, 'Краеведческий музей Гориса', 'Goris Local Lore Museum', 'Горис өлкетану музейі', 'Региональный музей истории, археологии и локального контекста Сюника.', 'A regional museum for the history, archaeology and local context of Syunik.', 39.51000000, 46.34100000, 'Goris Local Lore Museum Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('tatev-monastery', 'tatev', 'TEMPLE', 3, 'HOURS', 4.9, 'Татевский монастырь', 'Tatev Monastery', 'Татев монастыры', 'Главный монастырский комплекс Сюника на краю ущелья Воротан.', 'The main monastery complex of Syunik on the edge of the Vorotan Gorge.', 39.37930000, 46.24860000, 'Tatev Monastery Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('wings-of-tatev', 'tatev', 'ENTERTAINMENT', 2, 'HOURS', 4.8, 'Канатная дорога Крылья Татева', 'Wings of Tatev', 'Татев қанаттары', 'Длинная реверсивная канатная дорога к Татевскому монастырю и один из главных аттракционов региона.', 'A long reversible aerial tramway to Tatev Monastery and one of the region main places.', 39.41700000, 46.29700000, 'Wings of Tatev Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('devils-bridge-tatev', 'tatev', 'NATURE', 1, 'HOURS', 4.6, 'Чёртов мост', 'Devils Bridge', 'Шайтан көпірі', 'Природный мост, источники и ущелье Воротан рядом с дорогой к Татеву.', 'A natural bridge, springs and Vorotan Gorge near the road to Tatev.', 39.38600000, 46.25600000, 'Devils Bridge Tatev Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('old-khndzoresk-cave-village', 'khndzoresk', 'ARCHITECTURE', 2, 'HOURS', 4.7, 'Старый Хндзореск', 'Old Khndzoresk Cave Village', 'Ескі Хндзореск үңгір ауылы', 'Заброшенное пещерное село с домами, церквями и каньонным ландшафтом.', 'An abandoned cave village with homes, churches and canyon landscape.', 39.50000000, 46.43200000, 'Old Khndzoresk Cave Village Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('khndzoresk-swinging-bridge', 'khndzoresk', 'ENTERTAINMENT', 1, 'HOURS', 4.6, 'Подвесной мост Хндзореска', 'Khndzoresk Swinging Bridge', 'Хндзореск аспалы көпірі', 'Пешеходный подвесной мост в каньоне, ведущий к старому пещерному селу.', 'A pedestrian swinging bridge in the canyon leading to the old cave village.', 39.50100000, 46.43100000, 'Khndzoresk Swinging Bridge Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('vahanavank-monastery', 'kapan', 'TEMPLE', 2, 'HOURS', 4.5, 'Монастырь Ваганаванк', 'Vahanavank Monastery', 'Ваганаванк монастыры', 'Монастырский комплекс X-XI веков рядом с Капаном.', 'A tenth to eleventh century monastery complex near Kapan.', 39.21600000, 46.35700000, 'Vahanavank Monastery Kapan Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('mount-khustup', 'kapan', 'NATURE', 5, 'HOURS', 4.7, 'Гора Хуступ', 'Mount Khustup', 'Хуступ тауы', 'Иконическая гора над Капаном, hiking-объект и символ южного Сюника.', 'An iconic mountain above Kapan, a hiking object and symbol of southern Syunik.', 39.13000000, 46.33000000, 'Mount Khustup Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('baghaberd-fortress', 'kapan', 'ARCHITECTURE', 2, 'HOURS', 4.4, 'Крепость Багаберд', 'Baghaberd Fortress', 'Багаберд қамалы', 'Средневековая крепость над ущельем Вохчи и историческая остановка Капана.', 'A medieval fortress above the Voghji Gorge and a historic stop near Kapan.', 39.22500000, 46.29800000, 'Baghaberd Fortress Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('kapan-local-lore-museum', 'kapan', 'MUSEUM', 1, 'HOURS', 4.2, 'Капанский краеведческий музей', 'Kapan Museum of Local Lore', 'Капан өлкетану музейі', 'Музей локальной истории Капана и Сюника.', 'A museum of local history of Kapan and Syunik.', 39.20700000, 46.40500000, 'Kapan Museum of Local Lore Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('shikahogh-state-reserve', 'kapan', 'PARK', 5, 'HOURS', 4.6, 'Шикахохский заповедник', 'Shikahogh State Reserve', 'Шикахох қорығы', 'Лесной заповедник южной Армении с биоразнообразием и nature-маршрутами.', 'A forest reserve of southern Armenia with biodiversity and nature routes.', 39.08000000, 46.47000000, 'Shikahogh State Reserve Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('meghri-fortress', 'meghri', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Крепость Мегри', 'Meghri Fortress', 'Мегри қамалы', 'Крепость XVII века в историческом Мегри и важная heritage-точка юга Армении.', 'A seventeenth century fortress in historic Meghri and an important heritage point of southern Armenia.', 38.90200000, 46.24400000, 'Meghri Fortress Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('holy-mother-god-meghri', 'meghri', 'TEMPLE', 1, 'HOURS', 4.3, 'Церковь Сурб Аствацацин в Мегри', 'Holy Mother of God Church Meghri', 'Мегри Қасиетті Құдай Ана шіркеуі', 'Одна из ключевых церквей исторических кварталов Мегри.', 'One of the key churches of the historic quarters of Meghri.', 38.90250000, 46.24500000, 'Holy Mother of God Church Meghri Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('arevik-national-park', 'meghri', 'PARK', 5, 'HOURS', 4.6, 'Национальный парк Аревик', 'Arevik National Park', 'Аревик ұлттық паркі', 'Национальный парк южного Сюника с редкой природой, вертикальными зонами и wildlife-потенциалом.', 'A national park of southern Syunik with rare nature, vertical zones and wildlife potential.', 38.89800000, 46.16500000, 'Arevik National Park Armenia', 'Tatev_Monastery,_Armenia.jpg'),
    ('meghri-fruit-market', 'meghri', 'MARKET', 1, 'HOURS', 4.2, 'Фруктовые лавки и сухофрукты Мегри', 'Meghri Fruit and Dried Fruit Market', 'Мегри жеміс және кепкен жеміс базары', 'Локальный кластер фруктов, сухофруктов, варенья и продуктов теплой долины Мегри.', 'A local cluster of fruit, dried fruit, jam and products of the warm Meghri valley.', 38.90200000, 46.24400000, 'Meghri fruit dried fruit market Armenia', 'Tatev_Monastery,_Armenia.jpg');

CREATE TEMP TABLE seed_armenia_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-armenia-place:' || seed.slug) AS place_hash,
        md5('id-armenia-media:' || seed.slug) AS media_hash
    FROM seed_armenia_priority_places seed
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
    ARRAY['armenia', city_id, slug, lower(category), 'armenia-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    'Армения бағыты бойынша туристік орын: ' || title_kk || '. Ел, қала және маршрут бойынша іздеуге арналған.' AS description_kk,
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
    'AM',
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
FROM seed_armenia_resolved_places
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
FROM seed_armenia_resolved_places
UNION ALL
SELECT id, 'en', title_en, description_en, NOW(), NOW()
FROM seed_armenia_resolved_places
UNION ALL
SELECT id, 'kk', title_kk, description_kk, NOW(), NOW()
FROM seed_armenia_resolved_places
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
FROM seed_armenia_resolved_places s
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
FROM seed_armenia_resolved_places
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
SELECT gen_random_uuid(), id, kind, 'AM', city_id, 0, NOW()
FROM seed_armenia_resolved_places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_armenia_resolved_places;
DROP TABLE IF EXISTS seed_armenia_priority_places;
