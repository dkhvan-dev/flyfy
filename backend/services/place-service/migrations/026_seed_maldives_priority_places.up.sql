-- Priority Maldives destination places seed.
-- Maldives is a country destination, while every place stays attached to
-- a concrete island, city, or practical atoll reference used by admin filters.

DROP TABLE IF EXISTS seed_maldives_resolved_places;
DROP TABLE IF EXISTS seed_maldives_priority_places;

CREATE TEMP TABLE seed_maldives_priority_places (
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

INSERT INTO seed_maldives_priority_places (
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
    ('national-museum-maldives', 'male', 'MUSEUM', 2, 'HOURS', 4.0, 'Национальный музей Мальдив', 'National Museum of Maldives', 'Мальдив ұлттық музейі', 'Главный музей страны в центре Мале с королевскими артефактами, историей султаната и культурным контекстом перед поездками по островам.', 'The country''s main museum in central Male, with royal artefacts, sultanate history and cultural context before island trips.', 4.17530000, 73.50950000, 'National Museum of Maldives Male', 'Male''_National_Museum_Innen_K%C3%B6nigssitz.jpg'),
    ('sultan-park-male', 'male', 'PARK', 1, 'HOURS', 4.2, 'Парк Султана', 'Sultan Park', 'Сұлтан саябағы', 'Зеленая пауза рядом с Национальным музеем и бывшим дворцовым комплексом. Удобен для короткой прогулки по Мале.', 'A green pause beside the National Museum and former palace compound, useful for a short Male walking route.', 4.17510000, 73.50980000, 'Sultan Park Male Maldives', 'Male-total.jpg'),
    ('male-fish-market', 'male', 'MARKET', 1, 'HOURS', 4.3, 'Рыбный рынок Мале', 'Male Fish Market', 'Мале балық базары', 'Живой рынок у северной набережной, где видна повседневная культура ловли тунца на Мальдивах и работа рыбацких лодок.', 'A lively north waterfront market showing everyday Maldivian tuna culture and fishing boat activity.', 4.17710000, 73.50790000, 'Male Fish Market Maldives', 'Buiobuione_Maldive_Mal%C3%A9_fish_market.jpg'),
    ('male-local-market', 'male', 'MARKET', 1, 'HOURS', 4.1, 'Местный рынок Мале', 'Male Local Market', 'Мале жергілікті базары', 'Крытый рынок рядом с рыбным рынком с фруктами, специями, кокосами и повседневными товарами местных жителей.', 'A covered market near the fish market with fruit, spices, coconuts and everyday local goods.', 4.17700000, 73.50680000, 'Male Local Market Maldives', '2005-02-09_360%C2%B0_Male''_Fish_Market.jpg'),
    ('hukuru-miskiy-male', 'male', 'ARCHITECTURE', 1, 'HOURS', 4.4, 'Пятничная мечеть Хукуру Мискии', 'Hukuru Miskiy and Munnaaru', 'Хукуру Мискии мешіті', 'Историческая коралловая мечеть XVII века с минаретом и резьбой. Важная культурная точка старого Мале.', 'A historic 17th-century coral stone mosque with a minaret and carvings, an essential old Male cultural stop.', 4.17760000, 73.51240000, 'Hukuru Miskiy Male Maldives', 'Male''_Hukuru_Miskiy_1.jpg'),
    ('muleeaage', 'male', 'ARCHITECTURE', 1, 'HOURS', 4.1, 'Мулиаге', 'Muleeaage', 'Мулиаге', 'Официальная президентская резиденция рядом с Хукуру Мискии, полезная для короткого маршрута по историческому центру.', 'The official presidential residence near Hukuru Miskiy, useful for a compact historic-centre route.', 4.17790000, 73.51280000, 'Muleeaage Male Maldives', 'Male-total.jpg'),
    ('artificial-beach-male', 'male', 'BEACH', 1, 'HOURS', 4.0, 'Искусственный пляж Мале', 'Artificial Beach Male', 'Мале жасанды жағажайы', 'Городской пляж на востоке Мале для короткой прогулки, вечернего воздуха и вида на оживленную столицу.', 'An urban beach on east Male for a short walk, evening air and a view of the busy capital.', 4.17420000, 73.51760000, 'Artificial Beach Male Maldives', 'Maldives_island_beach_1.jpg'),
    ('rasfannu-beach', 'male', 'BEACH', 1, 'HOURS', 4.1, 'Пляж Расфанну', 'Rasfannu Beach', 'Расфанну жағажайы', 'Западная waterfront-зона Мале с небольшой пляжной полосой, закатами и городской прогулкой.', 'A west Male waterfront area with a small beach strip, sunsets and an easy city walk.', 4.17200000, 73.50090000, 'Rasfannu Beach Male Maldives', 'Male_City_Aerial,_The_Capital_city_of_Maldives_-_panoramio.jpg'),
    ('chaandhanee-magu', 'male', 'SHOPPING', 1, 'HOURS', 4.0, 'Улица Чаандани Магу', 'Chaandhanee Magu', 'Чаандани Магу көшесі', 'Торговая улица Мале с сувенирами, небольшими магазинами и удобной пешей связкой между рынками и историческим центром.', 'A Male shopping street with souvenirs, small stores and an easy walking link between markets and the historic centre.', 4.17630000, 73.50900000, 'Chaandhanee Magu Male Maldives', 'Male-total.jpg'),
    ('sto-trade-centre', 'male', 'SHOPPING', 1, 'HOURS', 4.0, 'STO Trade Centre', 'STO Trade Centre', 'STO Trade Centre', 'Практичный торговый центр в Мале для повседневных покупок, супермаркета и короткой indoor-паузы.', 'A practical Male shopping centre for everyday purchases, supermarket runs and a short indoor break.', 4.17650000, 73.50690000, 'STO Trade Centre Male Maldives', 'Male-total.jpg'),
    ('hulhumale-beach', 'hulhumale', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Хулхумале', 'Hulhumale Beach', 'Хулхумале жағажайы', 'Длинный городской пляж рядом с аэропортом и отелями Хулхумале, удобный для первого или последнего дня поездки.', 'A long urban beach near the airport and Hulhumale hotels, convenient for the first or last trip day.', 4.21160000, 73.54400000, 'Hulhumale Beach Maldives', 'Aerial_shot,_Maldives.jpg'),
    ('hulhumale-central-park', 'hulhumale', 'PARK', 1, 'HOURS', 4.1, 'Центральный парк Хулхумале', 'Hulhumale Central Park', 'Хулхумале орталық саябағы', 'Городской парк в Хулхумале для прогулки, семейной паузы и ориентира между пляжем и жилыми кварталами.', 'An urban park in Hulhumale for a walk, a family pause and orientation between the beach and residential blocks.', 4.21420000, 73.53950000, 'Hulhumale Central Park Maldives', 'Flora_of_Male_islands,_Maldives_04.jpg'),
    ('centro-mall-hulhumale', 'hulhumale', 'SHOPPING', 1, 'HOURS', 3.9, 'Centro Mall', 'Centro Mall', 'Centro Mall', 'Современный торговый центр Хулхумале с магазинами и кафе, полезный при плохой погоде или ожидании трансфера.', 'A modern Hulhumale shopping centre with stores and cafes, useful in bad weather or while waiting for transfers.', 4.21390000, 73.54100000, 'Centro Mall Hulhumale Maldives', 'Aerial_shot,_Maldives.jpg'),
    ('redwave-mega-mall', 'hulhumale', 'SHOPPING', 1, 'HOURS', 4.2, 'Redwave Mega Mall', 'Redwave Mega Mall', 'Redwave Mega Mall', 'Большой магазин/молл в Хулхумале для бытовых товаров, одежды, сувениров и быстрых покупок перед островами.', 'A large Hulhumale retail stop for daily goods, clothes, souvenirs and quick shopping before island transfers.', 4.21600000, 73.53970000, 'Redwave Mega Mall Hulhumale Maldives', 'Aerial_shot,_Maldives.jpg'),
    ('hulhumale-water-sports', 'hulhumale', 'ENTERTAINMENT', 2, 'HOURS', 4.4, 'Водные развлечения Хулхумале', 'Hulhumale Water Sports', 'Хулхумале су ойын-сауығы', 'Пляжный кластер для SUP, каяков, снорклинга и коротких морских активностей рядом с Мале и аэропортом.', 'A beach activity cluster for SUP, kayaking, snorkeling and short sea activities close to Male and the airport.', 4.21220000, 73.54550000, 'Hulhumale water sports Maldives', 'Maldives_island_beach_2.jpg'),
    ('villingili-beach', 'villingili', 'BEACH', 2, 'HOURS', 4.3, 'Пляж Виллингили', 'Villingili Beach', 'Виллингили жағажайы', 'Тихая пляжная остановка на острове Виллингили, куда удобно добраться короткой паромной поездкой из Мале.', 'A quieter beach stop on Villingili, easily reached by a short ferry ride from Male.', 4.17270000, 73.48540000, 'Villingili Beach Maldives', 'Maldives_island_beach_3.jpg'),
    ('villingili-beach-park', 'villingili', 'PARK', 1, 'HOURS', 4.1, 'Пляжный парк Виллингили', 'Villingili Beach Park', 'Виллингили жағажай саябағы', 'Небольшая зеленая зона у берега с локальной атмосферой, подходящая для спокойной прогулки без курортного формата.', 'A small seaside green area with local atmosphere, suitable for a calm non-resort walk.', 4.17320000, 73.48640000, 'Villingili Beach Park Maldives', 'Flora_of_Male_islands,_Maldives_12.jpg'),
    ('maafushi-bikini-beach', 'maafushi', 'BEACH', 3, 'HOURS', 4.2, 'Bikini Beach Маафуши', 'Maafushi Bikini Beach', 'Маафуши Bikini Beach', 'Главная туристическая пляжная зона Маафуши с понятной инфраструктурой для гостей локального острова.', 'The main tourist beach zone on Maafushi, with clear infrastructure for local-island guests.', 3.94350000, 73.49130000, 'Maafushi Bikini Beach Maldives', 'Maldives_island_beach_5.jpg'),
    ('maafushi-sandbank', 'maafushi', 'NATURE', 4, 'HOURS', 4.6, 'Песчаная коса Маафуши', 'Maafushi Sandbank', 'Маафуши құм қайраңы', 'Популярная морская экскурсия с песчаной косой, прозрачной лагуной и снорклингом рядом с Маафуши.', 'A popular boat excursion with a sandbank, clear lagoon and snorkeling near Maafushi.', 3.91000000, 73.47000000, 'Maafushi sandbank Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg'),
    ('maafushi-water-sports', 'maafushi', 'ENTERTAINMENT', 2, 'HOURS', 4.5, 'Водные развлечения Маафуши', 'Maafushi Water Sports', 'Маафуши су ойын-сауығы', 'Островной центр активностей: джет-ски, парасейлинг, лодочные туры, снорклинг и быстрые маршруты по Южному Мале атоллу.', 'An island activity hub for jet skis, parasailing, boat tours, snorkeling and quick South Male Atoll routes.', 3.94410000, 73.49080000, 'Maafushi water sports Maldives', 'Maldives_island_beach_6.jpg'),
    ('maafushi-souvenir-street', 'maafushi', 'SHOPPING', 1, 'HOURS', 4.1, 'Сувенирная улица Маафуши', 'Maafushi Souvenir Street', 'Маафуши сувенир көшесі', 'Небольшие сувенирные лавки и туристические магазины рядом с пляжной и отельной частью Маафуши.', 'Small souvenir and tourist shops near Maafushi beach and guesthouse zone.', 3.94320000, 73.49020000, 'Maafushi souvenir shops Maldives', 'Maldives_island_beach_5.jpg'),
    ('gulhi-bikini-beach', 'gulhi', 'BEACH', 3, 'HOURS', 4.5, 'Bikini Beach Гулхи', 'Gulhi Bikini Beach', 'Гулхи Bikini Beach', 'Компактный локальный остров с красивой туристической пляжной зоной и более спокойным ритмом, чем Маафуши.', 'A compact local island with a beautiful tourist beach zone and a calmer rhythm than Maafushi.', 3.99040000, 73.50820000, 'Gulhi Bikini Beach Maldives', 'Maldives_island_beach_2.jpg'),
    ('guraidhoo-bikini-beach', 'guraidhoo', 'BEACH', 3, 'HOURS', 4.3, 'Bikini Beach Гурайду', 'Guraidhoo Bikini Beach', 'Гурайду Bikini Beach', 'Пляжная зона локального острова Гурайду, удобная для бюджетных маршрутов и наблюдения за жизнью острова.', 'A beach zone on local Guraidhoo island, useful for budget routes and island-life context.', 3.90030000, 73.46630000, 'Guraidhoo Bikini Beach Maldives', 'Guriadhoo-2019-aerial-view-Luka-Peternel.jpg'),
    ('dhiffushi-bikini-beach', 'dhiffushi', 'BEACH', 3, 'HOURS', 4.5, 'Bikini Beach Диффуши', 'Dhiffushi Bikini Beach', 'Диффуши Bikini Beach', 'Северный локальный остров с пляжем, песком и видом на соседние курортные лагуны.', 'A northern local island beach with sand and views toward nearby resort lagoons.', 4.44110000, 73.71480000, 'Dhiffushi Bikini Beach Maldives', 'Maldives_RBR_beach_5.jpg'),
    ('thulusdhoo-cokes-surf-break', 'thulusdhoo', 'ENTERTAINMENT', 3, 'HOURS', 4.7, 'Серф-спот Cokes', 'Thulusdhoo Cokes Surf Break', 'Cokes серф нүктесі', 'Один из самых известных серф-спотов Северного Мале атолла, вокруг которого строится активный маршрут Тулусду.', 'One of North Male Atoll''s best-known surf breaks, anchoring active Thulusdhoo itineraries.', 4.37300000, 73.65500000, 'Cokes surf break Thulusdhoo Maldives', 'Maldives_island_beach_6.jpg'),
    ('thulusdhoo-bikini-beach', 'thulusdhoo', 'BEACH', 2, 'HOURS', 4.4, 'Bikini Beach Тулусду', 'Thulusdhoo Bikini Beach', 'Тулусду Bikini Beach', 'Пляжная зона Тулусду для отдыха между серфингом, кафе и прогулками по локальному острову.', 'The tourist beach zone on Thulusdhoo for resting between surf, cafes and local-island walks.', 4.37430000, 73.65360000, 'Thulusdhoo Bikini Beach Maldives', 'Maldives_island_beach_1.jpg'),
    ('himmafushi-jailbreaks', 'himmafushi', 'ENTERTAINMENT', 3, 'HOURS', 4.6, 'Серф-спот Jailbreaks', 'Himmafushi Jailbreaks Surf Break', 'Jailbreaks серф нүктесі', 'Классический surf break рядом с Химмафуши, подходящий для опытных серферов и boat-trip маршрутов.', 'A classic surf break near Himmafushi, suited to experienced surfers and boat-trip routes.', 4.30970000, 73.56950000, 'Jailbreaks surf break Himmafushi Maldives', 'Maldives_island_beach_6.jpg'),
    ('huraa-mangrove-boardwalk', 'huraa', 'NATURE', 2, 'HOURS', 4.4, 'Мангровая прогулка Хураа', 'Huraa Mangrove Boardwalk', 'Хураа мангр жолы', 'Спокойная природная зона Хураа с мангровыми участками и локальным островным контекстом рядом с Северным Мале атоллом.', 'A calm nature area on Huraa with mangrove pockets and local-island context near North Male Atoll.', 4.33370000, 73.60190000, 'Huraa mangrove Maldives', 'Flora_of_Male_islands,_Maldives_20.jpg'),
    ('fulidhoo-bikini-beach', 'fulidhoo', 'BEACH', 3, 'HOURS', 4.6, 'Bikini Beach Фулиду', 'Fulidhoo Bikini Beach', 'Фулиду Bikini Beach', 'Небольшой пляж локального острова Вааву атолла с расслабленным ритмом и прозрачной водой.', 'A small Vaavu Atoll local-island beach with a relaxed rhythm and clear water.', 3.68070000, 73.41520000, 'Fulidhoo Bikini Beach Maldives', 'Maldives_island_beach_3.jpg'),
    ('fulidhoo-shark-point', 'fulidhoo', 'NATURE', 2, 'HOURS', 4.7, 'Shark Point Фулиду', 'Fulidhoo Shark Point', 'Фулиду Shark Point', 'Популярная морская точка рядом с Фулиду для наблюдения за акулами и скатами только с ответственным гидом.', 'A popular marine point near Fulidhoo for observing sharks and rays with a responsible guide only.', 3.67900000, 73.41400000, 'Fulidhoo Shark Point Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg'),
    ('vaadhoo-sea-of-stars', 'vaadhoo', 'NATURE', 1, 'HOURS', 4.5, 'Море звезд Ваадху', 'Vaadhoo Sea of Stars', 'Ваадху жұлдызды теңізі', 'Пляж, известный сезонным биолюминесцентным свечением планктона. Важно показывать как природное явление, не гарантированное каждый день.', 'A beach known for seasonal bioluminescent plankton glow; it should be framed as a natural phenomenon, not a daily guarantee.', 5.83600000, 72.99300000, 'Vaadhoo Sea of Stars Maldives', 'Maldives_island_beach_1.jpg'),
    ('rasdhoo-madivaru-sandbank', 'rasdhoo', 'NATURE', 4, 'HOURS', 4.8, 'Песчаная коса Мадивару', 'Rasdhoo Madivaru Sandbank', 'Мадивару құм қайраңы', 'Красивая песчаная коса и лагуна рядом с Расду, популярная для лодочных поездок, снорклинга и фото-маршрутов.', 'A beautiful sandbank and lagoon near Rasdhoo, popular for boat trips, snorkeling and photo routes.', 4.26340000, 72.99440000, 'Madivaru Sandbank Rasdhoo Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg'),
    ('rasdhoo-bikini-beach', 'rasdhoo', 'BEACH', 2, 'HOURS', 4.4, 'Bikini Beach Расду', 'Rasdhoo Bikini Beach', 'Расду Bikini Beach', 'Пляж локального острова Расду, удобный как база для снорклинга, дайвинга и поездок к Мадивару.', 'The local-island beach on Rasdhoo, useful as a base for snorkeling, diving and Madivaru trips.', 4.26390000, 72.99130000, 'Rasdhoo Bikini Beach Maldives', 'Maldives_RBR_beach_6.jpg'),
    ('ukulhas-bikini-beach', 'ukulhas', 'BEACH', 3, 'HOURS', 4.6, 'Bikini Beach Укулхас', 'Ukulhas Bikini Beach', 'Укулхас Bikini Beach', 'Длинный чистый пляж Укулхаса, хорошо подходящий для семейного отдыха и локального island-stay формата.', 'A long clean beach on Ukulhas, well suited to family stays and local-island trips.', 4.21480000, 72.86460000, 'Ukulhas Bikini Beach Maldives', 'Maldives_RBR_beach_5.jpg'),
    ('ukulhas-house-reef', 'ukulhas', 'NATURE', 2, 'HOURS', 4.5, 'Домашний риф Укулхаса', 'Ukulhas House Reef', 'Укулхас үй рифі', 'Доступный риф у острова для снорклинга с берега и наблюдения за морской жизнью без сложной логистики.', 'An accessible island reef for shore snorkeling and marine-life watching without complex logistics.', 4.21400000, 72.86300000, 'Ukulhas House Reef Maldives', 'Maldives_island_beach_6.jpg'),
    ('dhigurah-long-beach', 'dhigurah', 'BEACH', 3, 'HOURS', 4.8, 'Длинный пляж Дигура', 'Dhigurah Long Beach', 'Дигура ұзын жағажайы', 'Длинная песчаная линия острова Дигура, одна из сильных баз Южного Ари атолла для пляжа и whale-shark маршрутов.', 'The long sandy shoreline of Dhigurah, one of South Ari Atoll''s strong bases for beach and whale-shark routes.', 3.53500000, 72.92700000, 'Dhigurah Long Beach Maldives', 'Maldives_island_beach_2.jpg'),
    ('maamigili-whale-shark-point', 'maamigili', 'NATURE', 4, 'HOURS', 4.7, 'Whale Shark Point Маамигили', 'Maamigili Whale Shark Point', 'Маамигили кит акула нүктесі', 'Морская зона Южного Ари атолла, известная турами на наблюдение за китовыми акулами с ответственными операторами.', 'A South Ari Atoll marine zone known for whale-shark observation trips with responsible operators.', 3.47600000, 72.83600000, 'Maamigili Whale Shark Point Maldives', 'Aerial_shot,_Maldives.jpg'),
    ('dharavandhoo-island-beach', 'dharavandhoo', 'BEACH', 2, 'HOURS', 4.4, 'Пляж Дхаравандху', 'Dharavandhoo Island Beach', 'Дхаравандху жағажайы', 'Пляжная зона локального острова Дхаравандху, удобная база для поездок к Hanifaru Bay в сезон мант.', 'A local-island beach on Dharavandhoo, a useful base for Hanifaru Bay trips during manta season.', 5.15630000, 73.13020000, 'Dharavandhoo Island Beach Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg'),
    ('hanifaru-bay', 'baa-atoll', 'NATURE', 4, 'HOURS', 4.9, 'Бухта Ханифару', 'Hanifaru Bay', 'Ханифару шығанағы', 'Охраняемая зона биосферного резервата Баа, известная сезонными скоплениями мант. Посещение должно быть только по правилам заповедника.', 'A protected area in the Baa Atoll Biosphere Reserve, known for seasonal manta gatherings and strict conservation rules.', 5.18100000, 73.14500000, 'Hanifaru Bay Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg'),
    ('baa-atoll-biosphere-reserve', 'baa-atoll', 'NATURE', 4, 'HOURS', 4.8, 'Биосферный резерват атолла Баа', 'Baa Atoll Biosphere Reserve', 'Баа атоллы биосфералық резерваты', 'UNESCO-биосферный регион с коралловыми рифами, островами и экологичными морскими маршрутами.', 'A UNESCO biosphere region with coral reefs, islands and eco-conscious marine itineraries.', 5.17000000, 73.08000000, 'Baa Atoll Biosphere Reserve Maldives', 'Maldives_Resort,_Indian_Ocean.jpg'),
    ('addu-nature-park', 'addu-city', 'PARK', 3, 'HOURS', 4.7, 'Природный парк Адду', 'Addu Nature Park', 'Адду табиғи саябағы', 'Крупная природная зона Адду с влажными угодьями, мангровыми тропами, пирсами и веломаршрутами.', 'A major Addu nature area with wetlands, mangrove paths, piers and cycling routes.', -0.61080000, 73.10360000, 'Addu Nature Park Maldives', 'Maldives_small_island.jpg'),
    ('addu-link-road', 'addu-city', 'ARCHITECTURE', 1, 'HOURS', 4.2, 'Дорога Addu Link Road', 'Addu Link Road', 'Addu Link Road', 'Длинная дорожная связка островов Адду, полезная для веломаршрута и понимания необычной географии южного атолла.', 'A long road link connecting Addu islands, useful for cycling routes and understanding the southern atoll geography.', -0.65000000, 73.13000000, 'Addu Link Road Maldives', 'Aerial_shot,_Maldives.jpg'),
    ('addu-manta-point', 'addu-city', 'NATURE', 3, 'HOURS', 4.7, 'Manta Point Адду', 'Addu Manta Point', 'Адду Manta Point', 'Дайв-точка Адду, где возможны встречи с мантами при подходящих условиях и с сертифицированным дайв-центром.', 'An Addu dive point where manta encounters are possible under suitable conditions with a certified dive centre.', -0.61500000, 73.12000000, 'Addu Manta Point Maldives', 'Maldives_island_6.jpg'),
    ('gan-british-war-memorial', 'gan', 'OTHER', 1, 'HOURS', 4.0, 'Британский военный мемориал Ган', 'Gan British War Memorial', 'Ган британдық әскери мемориалы', 'Историческая остановка на острове Ган, связанная с военной и авиационной историей южных Мальдив.', 'A historical stop on Gan island connected with the military and aviation history of the southern Maldives.', -0.69330000, 73.15560000, 'Gan British War Memorial Maldives', 'Male_City_Aerial,_The_Capital_city_of_Maldives_-_panoramio.jpg'),
    ('thoondu-beach', 'fuvahmulah', 'BEACH', 2, 'HOURS', 4.7, 'Пляж Тунду', 'Thoondu Beach', 'Тунду жағажайы', 'Известный галечный пляж Фувахмулаха с мощным прибоем и необычной береговой линией для Мальдив.', 'A famous pebble beach on Fuvahmulah with strong surf and an unusual shoreline for the Maldives.', -0.28330000, 73.42500000, 'Thoondu Beach Fuvahmulah Maldives', 'Thoondu_Fuvahmulah.jpg'),
    ('fuvahmulah-tiger-shark-point', 'fuvahmulah', 'NATURE', 3, 'HOURS', 4.8, 'Tiger Shark Point Фувахмулах', 'Fuvahmulah Tiger Shark Point', 'Фувахмулах Tiger Shark Point', 'Одна из самых известных дайв-зон страны для наблюдения за тигровыми акулами с опытными лицензированными операторами.', 'One of the country''s best-known dive zones for tiger-shark observation with experienced licensed operators.', -0.29200000, 73.43000000, 'Fuvahmulah Tiger Shark Point Maldives', 'Thoondu_-_Aerial_view_of_the_the_pebble_beach_of_Fuvahmulah.jpg'),
    ('bandaara-kilhi', 'fuvahmulah', 'NATURE', 1, 'HOURS', 4.4, 'Озеро Бандаара Килхи', 'Bandaara Kilhi Lake', 'Бандаара Килхи көлі', 'Пресноводное озеро Фувахмулаха с зеленым окружением, редкое для островной географии Мальдив.', 'A freshwater lake on Fuvahmulah with green surroundings, rare in the island geography of the Maldives.', -0.29920000, 73.42480000, 'Bandaara Kilhi Fuvahmulah Maldives', 'Thoondu_-_The_pebble_beach_of_Fuvahmulah.jpg'),
    ('utheeemu-ganduvaru', 'utheemu', 'MUSEUM', 1, 'HOURS', 4.5, 'Утиму Гандувару', 'Utheemu Ganduvaru', 'Утиму Гандувару', 'Исторический дворцовый дом на Утиму, связанный с султаном Мухаммедом Такуруфаану и национальной историей Мальдив.', 'A historic palace-house on Utheemu connected with Sultan Mohamed Thakurufaanu and Maldivian national history.', 6.83700000, 73.11500000, 'Utheemu Ganduvaru Maldives', 'Male''_National_Museum_Innen_2.jpg'),
    ('isdhoo-old-mosque', 'isdhoo', 'ARCHITECTURE', 1, 'HOURS', 4.3, 'Старая мечеть Исду', 'Isdhoo Old Mosque', 'Исду ескі мешіті', 'Историческая мечеть на атолле Лааму, важная для культурных маршрутов вне классических курортных островов.', 'A historic mosque in Laamu Atoll, important for cultural routes beyond the classic resort islands.', 2.11900000, 73.58200000, 'Isdhoo Old Mosque Maldives', 'Male''_Hukuru_Miskiy_3.jpg'),
    ('shipyard-lhaviyani', 'lhaviyani-atoll', 'NATURE', 3, 'HOURS', 4.7, 'Дайв-сайт The Shipyard', 'The Shipyard Lhaviyani Atoll', 'The Shipyard дайв орны', 'Известный дайв-сайт Лавияни с двумя затонувшими судами и насыщенной морской жизнью для сертифицированных дайверов.', 'A well-known Lhaviyani dive site with two wrecks and rich marine life for certified divers.', 5.44300000, 73.36500000, 'The Shipyard Lhaviyani Atoll Maldives', 'Aerial_shot_of_a_small_island_on_a_coral_reef_in_the_Maldives.jpg');

CREATE TEMP TABLE seed_maldives_resolved_places AS
WITH hashed AS (
    SELECT
        seed.*,
        md5('id-maldives-place:' || seed.slug) AS place_hash,
        md5('id-maldives-media:' || seed.slug) AS media_hash
    FROM seed_maldives_priority_places seed
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
    ARRAY['maldives', city_id, slug, lower(category), 'maldives-seed-v1']::text[] AS tags,
    title_ru,
    title_en,
    title_kk,
    description_ru,
    description_en,
    'Мальдив бағыты бойынша туристік орын: ' || title_kk || '. Ел, арал және маршрут бойынша іздеуге арналған.' AS description_kk,
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
    'MV',
    city_id,
    category,
    CASE
        WHEN category IN ('BEACH', 'FOOD', 'MARKET', 'SHOPPING') THEN 0::numeric
        WHEN category = 'ENTERTAINMENT' THEN 20::numeric
        ELSE 10::numeric
    END,
    'USD',
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
FROM seed_maldives_resolved_places
ON CONFLICT (id) DO UPDATE
SET
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
    updated_at = NOW(),
    deleted_at = NULL
WHERE places.source = 'IMPORT';

INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed.id,
    locale_rows.locale,
    CASE locale_rows.locale
        WHEN 'ru' THEN seed.title_ru
        WHEN 'kk' THEN seed.title_kk
        ELSE seed.title_en
    END,
    CASE locale_rows.locale
        WHEN 'ru' THEN seed.description_ru
        WHEN 'kk' THEN seed.description_kk
        ELSE seed.description_en
    END,
    NOW(),
    NOW()
FROM seed_maldives_resolved_places seed
CROSS JOIN (VALUES ('ru'), ('en'), ('kk')) AS locale_rows(locale)
ON CONFLICT (place_id, locale) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

WITH seed_locations (
    id,
    latitude,
    longitude,
    location_source_url
) AS (
    SELECT
        id,
        latitude,
        longitude,
        location_source_url
    FROM seed_maldives_resolved_places
)
UPDATE places
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE places.id = seed_locations.id
    AND places.source = 'IMPORT';

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
FROM seed_maldives_resolved_places
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = seed_maldives_resolved_places.id
)
ON CONFLICT (id) DO UPDATE
SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO place_city_links (id, place_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, 'MV', city_id, 0, NOW()
FROM seed_maldives_resolved_places
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
ON CONFLICT (place_id, kind, city_id) DO NOTHING;

DROP TABLE IF EXISTS seed_maldives_resolved_places;
DROP TABLE IF EXISTS seed_maldives_priority_places;
