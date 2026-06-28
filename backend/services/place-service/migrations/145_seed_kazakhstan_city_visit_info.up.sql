-- Phase A: per-place visit_info for the 35 Kazakhstan city anchor places (migration 009).
-- Overlay migration in the style of 003 / 142 / 143: it shallow-merges (||) v2 visit_info
-- fields onto each place so the feeDetails written by 143 are preserved.
-- Texts are original Inflap editorial summaries localized for en, ru, kk.
-- Prices/hours audited from public 2026 sources (Kok Tobe, Almaty Zoo, Fantasy World,
-- Nur Alem, National Museum, Astana Opera, Shymkent Zoo, Karavansaray, KarLag, Azret
-- Sultan, Semey Abai museum, qaztravel and city tourism portals). Hours are approximate
-- and human-maintained; unverified ticket prices are framed as "from".

WITH seed_city_visit_info (place_id, vi) AS (
    VALUES
    -- ========================= ALMATY =========================
    ('2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","COUPLES","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Cable car daily, Mon/Wed/Thu 10:00-23:00, Fri-Sun 10:00-00:00, Tue from 13:00",
            "ru": "Канатка ежедневно: Пн/Ср/Чт 10:00-23:00, Пт-Вс 10:00-00:00, Вт с 13:00",
            "kk": "Аспалы жол күн сайын: Дс/Ср/Бс 10:00-23:00, Жм-Жс 10:00-00:00, Сс 13:00-ден"}},
        "gettingThere": {
            "en": "Lower cable-car station near the Palace of Republic, Dostyk Ave 104B; or drive up Kok Tobe road",
            "ru": "Нижняя станция канатки у Дворца Республики, пр. Достык 104Б; либо подъём на машине по дороге на Кок-Тобе",
            "kk": "Аспалы жолдың төменгі станциясы Республика сарайы жанында, Достық даңғ. 104Б; немесе көлікпен жоғары шығу"},
        "included": [{"en": "One-way cable-car ride","ru": "Проезд по канатке в одну сторону","kk": "Аспалы жолмен бір жаққа жол"}],
        "excluded": [{"en": "Return ride, attractions and cafes on top","ru": "Обратная дорога, аттракционы и кафе наверху","kk": "Кері жол, аттракциондар және төбедегі кафе"}],
        "localizedTips": {
            "en": "Round-trip is about 10000 KZT; come before sunset for city views, then stay for the evening lights.",
            "ru": "Билет туда-обратно около 10000 тенге; приезжайте к закату ради видов, затем останьтесь на вечерние огни.",
            "kk": "Екі жаққа билет шамамен 10000 тенге; күн батарда келіп, кейін кешкі шамдарды тамашалаңыз."}
    } $$::jsonb),
    ('6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY"],
        "audience": ["HISTORY","PHOTO","FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Park open daily around the clock; Ascension Cathedral open daytime, mind services",
            "ru": "Парк открыт круглосуточно; Вознесенский собор работает днём, учитывайте службы",
            "kk": "Парк тәулік бойы ашық; Вознесенск соборы күндіз ашық, ғибадат уақытын ескеріңіз"}},
        "gettingThere": {
            "en": "Central Almaty, on Gogol/Kazybek bi; walkable from Green Bazaar and metro Zhibek Zholy",
            "ru": "Центр Алматы, ул. Гоголя/Казыбек би; пешком от Зелёного базара и метро Жибек Жолы",
            "kk": "Алматы орталығы, Гоголь/Қазыбек би көш.; Көк базар мен Жібек Жолы метросынан жаяу"},
        "localizedTips": {
            "en": "Free to enter; combine the memorial, the wooden cathedral and the nearby museums in one calm walk.",
            "ru": "Вход бесплатный; совместите мемориал, деревянный собор и музеи рядом в одной спокойной прогулке.",
            "kk": "Кіру тегін; мемориалды, ағаш соборды және жақын музейлерді бір тыныш серуенде біріктіріңіз."}
    } $$::jsonb),
    ('3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","OUTDOOR"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Park open daily ~10:00-22:00; rides run mainly in the warm season",
            "ru": "Парк ежедневно ~10:00-22:00; аттракционы работают в основном в тёплый сезон",
            "kk": "Парк күн сайын ~10:00-22:00; аттракциондар негізінен жылы маусымда жұмыс істейді"}},
        "season": {"months": [4,5,6,7,8,9,10], "note": {
            "en": "Best spring to autumn, when boats and rides operate",
            "ru": "Лучше с весны по осень, когда работают лодки и аттракционы",
            "kk": "Көктемнен күзге дейін жақсы, қайық пен аттракциондар істегенде"}},
        "gettingThere": {
            "en": "Gagarin Ave entrance, east of the centre; buses and taxi from downtown",
            "ru": "Вход с пр. Гагарина, восточнее центра; автобусы и такси из центра",
            "kk": "Кіреберіс Гагарин даңғ., орталықтан шығысқа қарай; орталықтан автобус пен такси"},
        "localizedTips": {
            "en": "Park entry is free; you pay per ride. Good half-day plan for families without leaving the city.",
            "ru": "Вход в парк бесплатный; платите за каждый аттракцион. Хороший план на полдня для семьи в городе.",
            "kk": "Паркке кіру тегін; әр аттракционға бөлек төлейсіз. Қала ішінде отбасыға жарты күндік жоспар."}
    } $$::jsonb),
    ('396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Weekdays 12:00-20:00, weekends 11:00-21:00; weather dependent",
            "ru": "Будни 12:00-20:00, выходные 11:00-21:00; зависит от погоды",
            "kk": "Жұмыс күндері 12:00-20:00, демалыс 11:00-21:00; ауа райына байланысты"}},
        "season": {"months": [3,4,5,6,7,8,9,10], "note": {
            "en": "Open March to October only",
            "ru": "Работает только с марта по октябрь",
            "kk": "Тек наурыздан қазанға дейін ашық"}},
        "gettingThere": {
            "en": "Abay Ave 50a/1, near the circus; buses and taxi across the city",
            "ru": "пр. Абая 50а/1, рядом с цирком; автобусы и такси по городу",
            "kk": "Абай даңғ. 50а/1, цирк маңында; қала бойынша автобус пен такси"},
        "included": [{"en": "Unlimited rides on the day ticket","ru": "Безлимит аттракционов по дневному билету","kk": "Күндік билетпен шексіз аттракциондар"}],
        "excluded": [{"en": "Food, games and lockers","ru": "Еда, игры и камеры хранения","kk": "Тамақ, ойындар және сақтау камералары"}],
        "localizedTips": {
            "en": "Weekend tickets cost a bit more (about 8000 KZT). Closed in cold months, so check before a winter trip.",
            "ru": "В выходные билет чуть дороже (около 8000 тенге). Зимой закрыт, поэтому проверяйте перед поездкой.",
            "kk": "Демалыста билет сәл қымбат (~8000 тенге). Қыста жабық, сапардан бұрын тексеріңіз."}
    } $$::jsonb),
    ('8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Summer 9:00-20:00, winter 10:00-18:00; ticket office closes earlier",
            "ru": "Лето 9:00-20:00, зима 10:00-18:00; касса закрывается раньше",
            "kk": "Жазда 9:00-20:00, қыста 10:00-18:00; касса ертерек жабылады"}},
        "gettingThere": {
            "en": "Yesenberlin St 166, Medeu district at the foot of Kok Tobe; buses and taxi",
            "ru": "ул. Есенберлина 166, Медеуский район у подножия Кок-Тобе; автобусы и такси",
            "kk": "Есенберлин көш. 166, Көк-Төбе етегіндегі Медеу ауданы; автобус пен такси"},
        "localizedTips": {
            "en": "Adult ticket about 1427 KZT, children 7-12 about 562 KZT, under 7 free. Come early on weekends.",
            "ru": "Взрослый билет около 1427 тенге, дети 7-12 около 562 тенге, до 7 лет бесплатно. В выходные приходите раньше.",
            "kk": "Ересек билет ~1427 тенге, 7-12 жас ~562 тенге, 7-ге дейін тегін. Демалыста ертерек келіңіз."}
    } $$::jsonb),
    ('ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY"],
        "audience": ["FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Daily about 8:00-19:00; quieter on weekday mornings",
            "ru": "Ежедневно примерно 8:00-19:00; тише в будни утром",
            "kk": "Күн сайын шамамен 8:00-19:00; жұмыс күндері таңертең тынышырақ"}},
        "gettingThere": {
            "en": "Zhibek Zholy / Pushkin St in the centre; near metro Zhibek Zholy",
            "ru": "ул. Жибек Жолы / Пушкина в центре; рядом метро Жибек Жолы",
            "kk": "Орталықтағы Жібек Жолы / Пушкин көш.; Жібек Жолы метросы жанында"},
        "localizedTips": {
            "en": "Free to enter. Try dried fruit, kurt and local sweets; mild bargaining is normal away from fixed-price stalls.",
            "ru": "Вход бесплатный. Попробуйте сухофрукты, курт и местные сладости; лёгкий торг уместен вне прилавков с фикс-ценой.",
            "kk": "Кіру тегін. Кепкен жеміс, құрт пен жергілікті тәтті татыңыз; тұрақты бағасы жоқ жерде сауаласуға болады."}
    } $$::jsonb),
    ('bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "LIMITED", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Busiest on weekends; many sections closed Mondays, open roughly 9:00-18:00",
            "ru": "Оживлённее по выходным; многие ряды закрыты по понедельникам, работа примерно 9:00-18:00",
            "kk": "Демалыста қарбалас; көп қатарлар дүйсенбіде жабық, шамамен 9:00-18:00"}},
        "gettingThere": {
            "en": "North-west of the centre on Sayakhat side; bus or taxi, allow time in traffic",
            "ru": "Северо-западнее центра, район Саяхата; автобус или такси, закладывайте время на пробки",
            "kk": "Орталықтан солтүстік-батыста, Саяхат жағында; автобус не такси, кептелісті ескеріңіз"},
        "localizedTips": {
            "en": "Free to enter, cash is king and crowds are dense. Keep valuables close; it is a real local market, not polished tourism.",
            "ru": "Вход бесплатный, главное наличные, и много людей. Берегите ценные вещи; это настоящий местный рынок, не глянец.",
            "kk": "Кіру тегін, негізі қолма-қол ақша, адам көп. Бағалы заттарды сақтаңыз; бұл шынайы базар."}
    } $$::jsonb),
    ('33192bba-1776-48e6-918b-198e81b17eae'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["FAMILY","COUPLES","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily; fountains run in the warm season",
            "ru": "Открыт ежедневно; фонтаны работают в тёплый сезон",
            "kk": "Күн сайын ашық; фонтандар жылы маусымда жұмыс істейді"}},
        "season": {"months": [4,5,6,7,8,9,10], "note": {
            "en": "Fountains and gardens are best spring to autumn",
            "ru": "Фонтаны и сады лучше с весны по осень",
            "kk": "Фонтандар мен бақтар көктемнен күзге дейін әсем"}},
        "gettingThere": {
            "en": "Upper part of the city near Navoi/Al-Farabi; taxi or bus, then a short uphill walk",
            "ru": "Верхняя часть города у Навои/аль-Фараби; такси или автобус, затем короткий подъём пешком",
            "kk": "Қаланың жоғары бөлігі Навои/әл-Фараби маңында; такси не автобус, кейін аздап жоғары жаяу"},
        "localizedTips": {
            "en": "Free to enter. Go up the terraces for mountain views; calm spot for families and evening walks.",
            "ru": "Вход бесплатный. Поднимитесь по террасам ради видов на горы; спокойное место для семьи и вечерних прогулок.",
            "kk": "Кіру тегін. Тау көрінісі үшін террасаларға көтеріліңіз; отбасы мен кешкі серуенге тыныш орын."}
    } $$::jsonb),
    -- ========================= ASTANA =========================
    ('39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Mall open daily ~10:00-22:00; aquapark and attractions keep their own hours",
            "ru": "ТРЦ ежедневно ~10:00-22:00; аквапарк и аттракционы по своему графику",
            "kk": "Сауда орталығы күн сайын ~10:00-22:00; аквапарк пен аттракциондар өз кестесімен"}},
        "gettingThere": {
            "en": "Turan Ave on the main axis, walkable from Nurzhol Boulevard; buses and taxi",
            "ru": "пр. Туран на главной оси, пешком от бульвара Нуржол; автобусы и такси",
            "kk": "Басты осьтегі Тұран даңғ., Нұржол бульварынан жаяу; автобус пен такси"},
        "localizedTips": {
            "en": "Entry to the tent is free; the indoor aquapark and rides are paid separately. Great weather-proof stop.",
            "ru": "Вход в шатёр бесплатный; крытый аквапарк и аттракционы оплачиваются отдельно. Отличная точка в любую погоду.",
            "kk": "Шатырға кіру тегін; ішкі аквапарк пен аттракциондар бөлек төленеді. Кез келген ауа райына ыңғайлы."}
    } $$::jsonb),
    ('abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Closed since December 2024 for conversion into the Alem.AI technology centre; no public admission in 2026",
            "ru": "Закрыт с декабря 2024 года для переоборудования в технологический центр Alem.AI; в 2026 году приём посетителей не ведётся",
            "kk": "2024 жылдың желтоқсанынан бері Alem.AI технологиялық орталығына айналдыру үшін жабық; 2026 жылы келушілер қабылданбайды"}},
        "gettingThere": {
            "en": "Former EXPO site on the left bank; taxi or bus to the EXPO / Mangilik El area; building visible from outside",
            "ru": "Бывшая территория EXPO на левом берегу; такси или автобус до района EXPO / Мангилик Ел; здание видно снаружи",
            "kk": "Сол жағалаудағы бұрынғы EXPO аумағы; EXPO / Мәңгілік Ел ауданына такси не автобус; ғимарат сыртынан көрінеді"},
        "localizedTips": {
            "en": "The sphere closed to visitors in December 2024 and is being converted into the Alem.AI innovation hub. No reopening date confirmed for 2026.",
            "ru": "Сфера закрылась для посетителей в декабре 2024 и переоборудуется в инновационный центр Alem.AI. Дата открытия для 2026 года не подтверждена.",
            "kk": "Сфера 2024 жылдың желтоқсанынан бастап келушілер үшін жабық, Alem.AI инновациялық орталығына айналдырылуда. 2026 жылға арналған ашылу күні расталмаған."}
    } $$::jsonb),
    ('a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","OUTDOOR","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily in the warm season; shorter hours in winter",
            "ru": "Открыт ежедневно в тёплый сезон; зимой часы короче",
            "kk": "Жылы маусымда күн сайын ашық; қыста уақыт қысқа"}},
        "season": {"months": [5,6,7,8,9,10], "note": {
            "en": "Greenery and water features are best late spring to autumn",
            "ru": "Зелень и водные элементы лучше с конца весны по осень",
            "kk": "Көгал мен су нысандары көктем соңынан күзге дейін әсем"}},
        "gettingThere": {
            "en": "Left bank near the government district; taxi or bus, walkable from Mangilik El",
            "ru": "Левый берег у правительственного района; такси или автобус, пешком от Мангилик Ел",
            "kk": "Үкімет ауданы маңындағы сол жағалау; такси не автобус, Мәңгілік Елден жаяу"},
        "localizedTips": {
            "en": "Free or low-cost entry. A calm green break that balances Astana's monument-heavy routes.",
            "ru": "Вход бесплатный или недорогой. Спокойная зелёная пауза, балансирующая монументальные маршруты Астаны.",
            "kk": "Кіру тегін немесе арзан. Астананың монументті бағытын теңестіретін тыныш жасыл аялдама."}
    } $$::jsonb),
    ('1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily outside prayer times; dress modestly",
            "ru": "Открыта ежедневно вне времени молитв; одевайтесь скромно",
            "kk": "Намаз уақытынан тыс күн сайын ашық; қарапайым киініңіз"}},
        "gettingThere": {
            "en": "Near Independence Square and the National Museum on the left bank; taxi or bus",
            "ru": "У площади Независимости и Национального музея на левом берегу; такси или автобус",
            "kk": "Сол жағалаудағы Тәуелсіздік алаңы мен Ұлттық музей жанында; такси не автобус"},
        "localizedTips": {
            "en": "Free to visit. Cover shoulders and knees; women are given headscarves at the entrance. Pair with the National Museum.",
            "ru": "Вход бесплатный. Прикройте плечи и колени; женщинам выдают платок на входе. Совместите с Нацмузеем.",
            "kk": "Кіру тегін. Иық пен тізені жабыңыз; әйелдерге кіреберісте орамал беріледі. Ұлттық музеймен біріктіріңіз."}
    } $$::jsonb),
    ('12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["HISTORY","FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Tue-Sun 10:00-18:00 (ticket office to 17:00); closed Mondays",
            "ru": "Вт-Вс 10:00-18:00 (касса до 17:00); понедельник выходной",
            "kk": "Сс-Жс 10:00-18:00 (касса 17:00-ге дейін); дүйсенбі демалыс"},
            "days": {"mon": "closed"}},
        "gettingThere": {
            "en": "Tauelsizdik Ave 54 by Independence Square, left bank; taxi or bus",
            "ru": "пр. Тауелсиздик 54 у площади Независимости, левый берег; такси или автобус",
            "kk": "Сол жағалаудағы Тәуелсіздік алаңы жанындағы Тәуелсіздік даңғ. 54; такси не автобус"},
        "localizedTips": {
            "en": "Adult ticket about 300 KZT with concessions. Best single stop to understand the country before touring the regions.",
            "ru": "Взрослый билет около 300 тенге, есть льготы. Лучшая единая точка, чтобы понять страну перед поездками по регионам.",
            "kk": "Ересек билет ~300 тенге, жеңілдіктер бар. Өңірлерге сапардан бұрын елді тануға ең қолайлы аялдама."}
    } $$::jsonb),
    ('adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": true,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["COUPLES","HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Box office and tours daytime; performances in the evening - check the schedule",
            "ru": "Касса и экскурсии днём; спектакли вечером - смотрите афишу",
            "kk": "Касса мен экскурсиялар күндіз; қойылымдар кешке - афишаны қараңыз"}},
        "gettingThere": {
            "en": "Dinmukhamed Kunayev St 1 on the left bank; taxi or bus",
            "ru": "ул. Динмухамеда Кунаева 1 на левом берегу; такси или автобус",
            "kk": "Сол жағалаудағы Дінмұхамед Қонаев көш. 1; такси не автобус"},
        "localizedTips": {
            "en": "Guided building tours start around 5400 KZT; performance tickets vary by show and seat. Book ahead for premieres.",
            "ru": "Экскурсии по зданию от ~5400 тенге; билеты на спектакли зависят от постановки и места. На премьеры бронируйте заранее.",
            "kk": "Ғимарат бойынша экскурсия ~5400 тенге-ден; қойылым билеті спектакль мен орынға байланысты. Премьераға алдын ала брондаңыз."}
    } $$::jsonb),
    -- ========================= SHYMKENT =========================
    ('9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY"],
        "audience": ["HISTORY","PHOTO","FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open-air old-city area accessible daily; museum spaces keep daytime hours",
            "ru": "Территория старого города открыта ежедневно; музейные пространства работают днём",
            "kk": "Ескі қала аумағы күн сайын ашық; музей кеңістіктері күндіз жұмыс істейді"}},
        "gettingThere": {
            "en": "Central Shymkent near the Ordabasy area; walkable from the centre, taxi nearby",
            "ru": "Центр Шымкента у площади Ордабасы; пешком из центра, такси рядом",
            "kk": "Шымкент орталығы, Ордабасы маңы; орталықтан жаяу, такси жақын"},
        "localizedTips": {
            "en": "Walking the reconstructed citadel is free; pair it with the central museums for a compact Silk Road route.",
            "ru": "Прогулка по реконструированной цитадели бесплатна; совместите с центральными музеями для компактного маршрута Шёлкового пути.",
            "kk": "Қайта жаңғыртылған цитадельмен серуен тегін; Жібек жолы маршрутына орталық музейлермен біріктіріңіз."}
    } $$::jsonb),
    ('92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Summer 9:00-20:00, winter 9:00-18:00; closed Wednesdays (sanitary day)",
            "ru": "Лето 9:00-20:00, зима 9:00-18:00; среда - санитарный день",
            "kk": "Жазда 9:00-20:00, қыста 9:00-18:00; сәрсенбі - санитарлық күн"},
            "days": {"wed": "closed"}},
        "gettingThere": {
            "en": "Baydibek bi Ave 113a; city buses and taxi",
            "ru": "пр. Байдибек би 113а; городские автобусы и такси",
            "kk": "Байдібек би даңғ. 113а; қалалық автобус пен такси"},
        "localizedTips": {
            "en": "Adult ticket about 800 KZT, children 6-17 about 400 KZT, under 6 free. Note the Wednesday closure.",
            "ru": "Взрослый билет около 800 тенге, дети 6-17 около 400 тенге, до 6 лет бесплатно. Учтите выходной в среду.",
            "kk": "Ересек билет ~800 тенге, 6-17 жас ~400 тенге, 6-ға дейін тегін. Сәрсенбідегі демалысты ескеріңіз."}
    } $$::jsonb),
    ('d3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["OUTDOOR","FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily in daylight; greener and busier in the warm season",
            "ru": "Открыт ежедневно в светлое время; зеленее и оживлённее в тёплый сезон",
            "kk": "Күндіз күн сайын ашық; жылы маусымда көгалды әрі қарбалас"}},
        "season": {"months": [4,5,6,7,8,9,10], "note": {
            "en": "Best late spring to autumn",
            "ru": "Лучше с конца весны по осень",
            "kk": "Көктем соңынан күзге дейін жақсы"}},
        "gettingThere": {
            "en": "Northern Shymkent arboretum; taxi or bus from the centre",
            "ru": "Дендропарк на севере Шымкента; такси или автобус из центра",
            "kk": "Шымкенттің солтүстігіндегі дендропарк; орталықтан такси не автобус"},
        "localizedTips": {
            "en": "Entry is low cost (from about 300 KZT) and sometimes free for short visits; the strongest green walk in the city.",
            "ru": "Вход недорогой (примерно от 300 тенге), иногда бесплатный на короткое посещение; самая сильная зелёная прогулка города.",
            "kk": "Кіру арзан (~300 тенге-ден), кейде қысқа кіру тегін; қаладағы ең әсем жасыл серуен."}
    } $$::jsonb),
    ('f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY"],
        "audience": ["FAMILY","HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "City park open daily around the clock",
            "ru": "Городской парк открыт ежедневно круглосуточно",
            "kk": "Қалалық парк күн сайын тәулік бойы ашық"}},
        "gettingThere": {
            "en": "Central Shymkent on Tauke Khan Ave; walkable downtown",
            "ru": "Центр Шымкента, пр. Тауке хана; пешком в центре",
            "kk": "Шымкент орталығы, Тәуке хан даңғ.; орталықта жаяу"},
        "localizedTips": {
            "en": "Free to enter. An easy connector between memorials, museums and everyday city life.",
            "ru": "Вход бесплатный. Удобный мост между мемориалами, музеями и повседневной жизнью города.",
            "kk": "Кіру тегін. Мемориалдар, музейлер мен қала тұрмысын байланыстыратын жеңіл орын."}
    } $$::jsonb),
    ('0e06eed4-e871-4f78-919c-a11322eda453'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily, daytime into the evening",
            "ru": "Открыт ежедневно, днём и вечером",
            "kk": "Күн сайын ашық, күндіз және кешке"}},
        "gettingThere": {
            "en": "Ken Baba ethno park in Shymkent; taxi or bus",
            "ru": "Этнопарк Кен Баба в Шымкенте; такси или автобус",
            "kk": "Шымкенттегі Кен Баба этнопаркі; такси не автобус"},
        "localizedTips": {
            "en": "Free or low-cost entry; small fees for some rides. A light family stop with oriental-style details and cafes.",
            "ru": "Вход бесплатный или недорогой; за отдельные аттракционы небольшая плата. Лёгкая семейная точка с восточными деталями и кафе.",
            "kk": "Кіру тегін немесе арзан; кейбір аттракционға аз төлем. Шығыс стиліндегі жеңіл отбасылық орын."}
    } $$::jsonb),
    -- ========================= TURKESTAN =========================
    ('b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Complex open daily; flying theatre sessions run roughly 9:00-18:00",
            "ru": "Комплекс открыт ежедневно; сеансы летающего театра примерно 9:00-18:00",
            "kk": "Кешен күн сайын ашық; ұшатын театр сеанстары шамамен 9:00-18:00"}},
        "gettingThere": {
            "en": "Next to the Yasawi mausoleum in Turkestan; walkable from the old town, taxi nearby",
            "ru": "Рядом с мавзолеем Ясави в Туркестане; пешком от старого города, такси рядом",
            "kk": "Түркістандағы Ясауи кесенесі жанында; ескі қаладан жаяу, такси жақын"},
        "included": [{"en": "One flying-theatre session","ru": "Один сеанс летающего театра","kk": "Ұшатын театрдың бір сеансы"}],
        "excluded": [{"en": "Boat rides, other attractions and dining","ru": "Катание на лодках, другие аттракционы и питание","kk": "Қайық, басқа аттракциондар және тамақ"}],
        "localizedTips": {
            "en": "Flying-theatre ticket about 5000 KZT (children about 4000). Walking the canals and bazaar area is free.",
            "ru": "Билет на летающий театр около 5000 тенге (дети около 4000). Прогулка по каналам и базарной части бесплатна.",
            "kk": "Ұшатын театр билеті ~5000 тенге (балалар ~4000). Арналар мен базар бойымен серуен тегін."}
    } $$::jsonb),
    ('788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","GUIDE_RECOMMENDED"],
        "audience": ["HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Reserve open daily in daylight; mausoleum interior has its own visiting order",
            "ru": "Заповедник открыт ежедневно в светлое время; вход в мавзолей по своему порядку",
            "kk": "Қорық күндіз күн сайын ашық; кесене ішіне кіру өз тәртібімен"}},
        "gettingThere": {
            "en": "Historic core of Turkestan; walkable, taxi from the train station and Karavansaray",
            "ru": "Историческое ядро Туркестана; пешком, такси от вокзала и Караван-сарая",
            "kk": "Түркістанның тарихи өзегі; жаяу, вокзал мен Керуен-сарайдан такси"},
        "included": [{"en": "Access to the Azret complex and Yasawi mausoleum","ru": "Доступ к комплексу Азрет и мавзолею Ясави","kk": "Әзірет кешені мен Ясауи кесенесіне кіру"}],
        "excluded": [{"en": "Guide service and separate museum halls","ru": "Услуги гида и отдельные музейные залы","kk": "Гид қызметі және жеке музей залдары"}],
        "localizedTips": {
            "en": "Combined ticket about 1000 KZT for locals (more for foreign visitors). Dress modestly near the mausoleum.",
            "ru": "Единый билет около 1000 тенге для местных (для иностранцев дороже). Одевайтесь скромно у мавзолея.",
            "kk": "Бірыңғай билет жергіліктілерге ~1000 тенге (шетелдіктерге қымбатырақ). Кесене жанында қарапайым киініңіз."}
    } $$::jsonb),
    ('877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, $$ {
        "bestTime": "EARLY_MORNING", "accessibility": "LIMITED", "bookingRequired": false,
        "amenities": ["PARKING","GUIDE_RECOMMENDED"],
        "audience": ["HISTORY","OUTDOOR","PHOTO"],
        "safetyNotes": ["CHECK_WEATHER","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Open-air site, daylight visits; little shade, no facilities on site",
            "ru": "Открытый объект, посещение в светлое время; мало тени, инфраструктуры на месте нет",
            "kk": "Ашық нысан, күндіз бару; көлеңке аз, орнында инфрақұрылым жоқ"}},
        "season": {"months": [4,5,6,9,10], "note": {
            "en": "Spring and autumn are most comfortable; summer is very hot",
            "ru": "Весна и осень комфортнее всего; летом очень жарко",
            "kk": "Көктем мен күз ыңғайлы; жазда өте ыстық"}},
        "gettingThere": {
            "en": "About 1.5 hours by car from Turkestan toward Otrar; a guide or driver helps a lot",
            "ru": "Около 1,5 часов на машине от Туркестана в сторону Отрара; гид или водитель сильно помогают",
            "kk": "Түркістаннан Отырарға қарай көлікпен ~1,5 сағат; гид не жүргізуші көмектеседі"},
        "localizedTips": {
            "en": "Entry is a small fee (from about 500 KZT); bring water and sun protection. Best as a half-day add-on to Turkestan.",
            "ru": "Вход - небольшая плата (примерно от 500 тенге); берите воду и защиту от солнца. Лучше как продолжение Туркестана на полдня.",
            "kk": "Кіру - аз төлем (~500 тенге-ден); су мен күннен қорғану алыңыз. Түркістанға жарты күндік қосымша ретінде жақсы."}
    } $$::jsonb),
    -- ========================= REGIONS =========================
    ('1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","GUIDE_RECOMMENDED"],
        "audience": ["HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "9:00-18:00, lunch 13:00-14:00; closed Mondays",
            "ru": "9:00-18:00, обед 13:00-14:00; понедельник выходной",
            "kk": "9:00-18:00, түскі ас 13:00-14:00; дүйсенбі демалыс"},
            "days": {"mon": "closed"}},
        "gettingThere": {
            "en": "Dolinka village near Karaganda, about 45 km; car or organised tour",
            "ru": "Посёлок Долинка под Карагандой, около 45 км; машина или организованный тур",
            "kk": "Қарағанды маңындағы Долинка ауылы, ~45 км; көлік не ұйымдастырылған тур"},
        "localizedTips": {
            "en": "Adult ticket about 250 KZT; a guided tour (about 500 KZT per group) adds a lot of context to this memorial site.",
            "ru": "Взрослый билет около 250 тенге; экскурсия (около 500 тенге с группы) добавляет много контекста этому мемориалу.",
            "kk": "Ересек билет ~250 тенге; экскурсия (~500 тенге топтан) бұл мемориалға көп мән береді."}
    } $$::jsonb),
    ('09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","OUTDOOR"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily; rides and boats run in the warm season",
            "ru": "Открыт ежедневно; аттракционы и лодки работают в тёплый сезон",
            "kk": "Күн сайын ашық; аттракциондар мен қайық жылы маусымда"}},
        "season": {"months": [5,6,7,8,9], "note": {
            "en": "Lake and rides are best in summer",
            "ru": "Озеро и аттракционы лучше летом",
            "kk": "Көл мен аттракциондар жазда жақсы"}},
        "gettingThere": {
            "en": "Central Karaganda; walkable from downtown, buses and taxi",
            "ru": "Центр Караганды; пешком из центра, автобусы и такси",
            "kk": "Қарағанды орталығы; орталықтан жаяу, автобус пен такси"},
        "localizedTips": {
            "en": "Free to enter; pay per ride. An easy city pause to balance the heavier KarLag route.",
            "ru": "Вход бесплатный; платите за аттракционы. Лёгкая городская пауза к более тяжёлому маршруту в КарЛаг.",
            "kk": "Кіру тегін; аттракционға бөлек төлем. КарЛаг бағытын теңестіретін жеңіл қала үзілісі."}
    } $$::jsonb),
    ('1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["CAFE_NEARBY"],
        "audience": ["COUPLES","PHOTO","OUTDOOR"],
        "safetyNotes": ["CHECK_WEATHER"],
        "openingHours": {"summary": {
            "en": "Open public embankment, accessible day and night",
            "ru": "Открытая набережная, доступна днём и ночью",
            "kk": "Ашық жағалау, күндіз де түнде де қолжетімді"}},
        "gettingThere": {
            "en": "Along the Ural River in central Atyrau; walkable, taxi nearby",
            "ru": "Вдоль реки Урал в центре Атырау; пешком, такси рядом",
            "kk": "Атырау орталығындағы Жайық бойында; жаяу, такси жақын"},
        "localizedTips": {
            "en": "Free. The pedestrian bridge links the European and Asian banks; evening lighting makes it especially photogenic.",
            "ru": "Бесплатно. Пешеходный мост соединяет европейский и азиатский берега; вечерняя подсветка особенно фотогенична.",
            "kk": "Тегін. Жаяу көпір еуропалық пен азиялық жағалауды жалғайды; кешкі жарық әсіресе әдемі."}
    } $$::jsonb),
    ('25f2452e-9943-463f-a135-27a72df7015d'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "LIMITED", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["OUTDOOR","PHOTO","COUPLES"],
        "safetyNotes": ["CHECK_WEATHER","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Open coastal trail, accessible daylight hours; little shade",
            "ru": "Открытая прибрежная тропа, доступна в светлое время; мало тени",
            "kk": "Ашық жағалау соқпағы, күндіз қолжетімді; көлеңке аз"}},
        "gettingThere": {
            "en": "Caspian shore in Aktau near the microdistricts; taxi to the seafront, then walk",
            "ru": "Каспийский берег Актау у микрорайонов; такси к набережной, далее пешком",
            "kk": "Ақтаудың Каспий жағалауы, шағын аудандар маңы; жағалауға такси, кейін жаяу"},
        "localizedTips": {
            "en": "Free. Strongest at sunset for photos; wear sturdy shoes and bring water on hot days.",
            "ru": "Бесплатно. Лучше всего на закате для фото; обувайтесь удобно и берите воду в жару.",
            "kk": "Тегін. Фото үшін күн батарда әсем; ыңғайлы аяқкиім киіп, ыстықта су алыңыз."}
    } $$::jsonb),
    ('7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY"],
        "audience": ["FAMILY","COUPLES","OUTDOOR"],
        "safetyNotes": ["CHECK_WEATHER"],
        "openingHours": {"summary": {
            "en": "Open promenade, accessible day and night",
            "ru": "Открытая набережная, доступна днём и ночью",
            "kk": "Ашық жағалау, күндіз де түнде де қолжетімді"}},
        "gettingThere": {
            "en": "Aktau seafront along the Caspian; walkable from the centre, taxi nearby",
            "ru": "Набережная Актау вдоль Каспия; пешком из центра, такси рядом",
            "kk": "Каспий бойындағы Ақтау жағалауы; орталықтан жаяу, такси жақын"},
        "localizedTips": {
            "en": "Free. The easiest plan in Aktau - sea air, cafes and sunset views with no effort.",
            "ru": "Бесплатно. Самый простой план в Актау - морской воздух, кафе и закаты без усилий.",
            "kk": "Тегін. Ақтаудағы ең жеңіл жоспар - теңіз ауасы, кафе және күн батуы."}
    } $$::jsonb),
    ('c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily outside prayer times; dress modestly",
            "ru": "Открыта ежедневно вне времени молитв; одевайтесь скромно",
            "kk": "Намаз уақытынан тыс күн сайын ашық; қарапайым киініңіз"}},
        "gettingThere": {
            "en": "Central Pavlodar; walkable downtown, taxi nearby",
            "ru": "Центр Павлодара; пешком в центре, такси рядом",
            "kk": "Павлодар орталығы; орталықта жаяу, такси жақын"},
        "localizedTips": {
            "en": "Free to visit. A short respectful stop with a striking blue dome and national motifs.",
            "ru": "Вход бесплатный. Короткая уважительная остановка с ярким голубым куполом и национальными мотивами.",
            "kk": "Кіру тегін. Көк күмбезі мен ұлттық сарыны бар қысқа әрі құрметті аялдама."}
    } $$::jsonb),
    ('b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["HISTORY","FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open Tue-Sun daytime; open-air sections best in the warm season",
            "ru": "Открыт Вт-Вс днём; открытые площадки лучше в тёплый сезон",
            "kk": "Сс-Жс күндіз ашық; ашық алаңдар жылы маусымда жақсы"}},
        "gettingThere": {
            "en": "Central Ust-Kamenogorsk; walkable, taxi or bus",
            "ru": "Центр Усть-Каменогорска; пешком, такси или автобус",
            "kk": "Өскемен орталығы; жаяу, такси не автобус"},
        "localizedTips": {
            "en": "Entry from about 500 KZT; the indoor and open-air ethnographic spaces work in any weather.",
            "ru": "Вход примерно от 500 тенге; крытые и открытые этнографические площадки подходят на любую погоду.",
            "kk": "Кіру ~500 тенге-ден; жабық және ашық этнографиялық алаңдар кез келген ауа райына жарайды."}
    } $$::jsonb),
    ('90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","GUIDE_RECOMMENDED"],
        "audience": ["HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daytime, closed one day a week - check before visiting",
            "ru": "Работает днём, один день в неделю выходной - уточняйте перед визитом",
            "kk": "Күндіз жұмыс істейді, аптасына бір күн демалыс - барар алдында тексеріңіз"}},
        "gettingThere": {
            "en": "Mukhamedkhanov St 29, central Semey; walkable, taxi nearby",
            "ru": "ул. Мухамедханова 29, центр Семея; пешком, такси рядом",
            "kk": "Мұхамедханов көш. 29, Семей орталығы; жаяу, такси жақын"},
        "localizedTips": {
            "en": "Adult ticket about 500 KZT. The natural first stop to understand Abai and the Abai region.",
            "ru": "Взрослый билет около 500 тенге. Естественная первая точка, чтобы понять Абая и область Абай.",
            "kk": "Ересек билет ~500 тенге. Абайды және Абай облысын тануды бастауға табиғи орын."}
    } $$::jsonb),
    ('1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "LIMITED", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["HISTORY","OUTDOOR","PHOTO"],
        "safetyNotes": ["CHECK_WEATHER","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Open-air memorial in the steppe, accessible daylight hours",
            "ru": "Открытый мемориал в степи, доступен в светлое время",
            "kk": "Даладағы ашық мемориал, күндіз қолжетімді"}},
        "gettingThere": {
            "en": "On the Kyzylorda-Aralsk road, about 18 km from Zhosaly; car or tour",
            "ru": "На трассе Кызылорда-Аральск, около 18 км от Жосалы; машина или тур",
            "kk": "Қызылорда-Арал жолында, Жосалыдан ~18 км; көлік не тур"},
        "localizedTips": {
            "en": "Free, open steppe site. The wind organ evokes the kobyz; combine with Syr Darya road trips.",
            "ru": "Бесплатно, открытый степной объект. Ветровой орган напоминает кобыз; совместите с поездками по Сырдарье.",
            "kk": "Тегін, ашық дала нысаны. Жел органы қобызды еске салады; Сырдария бағытымен біріктіріңіз."}
    } $$::jsonb),
    ('e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daily outside prayer times; dress modestly",
            "ru": "Открыта ежедневно вне времени молитв; одевайтесь скромно",
            "kk": "Намаз уақытынан тыс күн сайын ашық; қарапайым киініңіз"}},
        "gettingThere": {
            "en": "Central Aktobe; walkable downtown, taxi nearby",
            "ru": "Центр Актобе; пешком в центре, такси рядом",
            "kk": "Ақтөбе орталығы; орталықта жаяу, такси жақын"},
        "localizedTips": {
            "en": "Free to visit. A short city must-see with four tall minarets and a large gilded dome.",
            "ru": "Вход бесплатный. Короткая городская must-see точка с четырьмя минаретами и большим золочёным куполом.",
            "kk": "Кіру тегін. Төрт мұнарасы мен үлкен алтын күмбезі бар қысқа қалалық нысан."}
    } $$::jsonb),
    ('0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS"],
        "audience": ["HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daytime, one day off per week - check before visiting",
            "ru": "Работает днём, один выходной в неделю - уточняйте перед визитом",
            "kk": "Күндіз жұмыс істейді, аптасына бір демалыс - тексеріңіз"}},
        "gettingThere": {
            "en": "Central Kostanay; walkable, taxi nearby",
            "ru": "Центр Костаная; пешком, такси рядом",
            "kk": "Қостанай орталығы; жаяу, такси жақын"},
        "localizedTips": {
            "en": "Entry from about 500 KZT. A compact start for regional history before a city walk.",
            "ru": "Вход примерно от 500 тенге. Компактный старт по истории региона перед прогулкой по городу.",
            "kk": "Кіру ~500 тенге-ден. Қала серуенінен бұрын өңір тарихымен танысудың ықшам басы."}
    } $$::jsonb),
    ('eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS"],
        "audience": ["HISTORY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daytime, one day off per week - check before visiting",
            "ru": "Работает днём, один выходной в неделю - уточняйте перед визитом",
            "kk": "Күндіз жұмыс істейді, аптасына бір демалыс - тексеріңіз"}},
        "gettingThere": {
            "en": "Central Oral (Uralsk); walkable, taxi nearby",
            "ru": "Центр Уральска; пешком, такси рядом",
            "kk": "Орал орталығы; жаяу, такси жақын"},
        "localizedTips": {
            "en": "Entry from about 500 KZT. A strong cultural anchor for West Kazakhstan with a long museum history.",
            "ru": "Вход примерно от 500 тенге. Сильная культурная точка Западного Казахстана с долгой историей музея.",
            "kk": "Кіру ~500 тенге-ден. Ұзақ тарихы бар Батыс Қазақстанның мықты мәдени нүктесі."}
    } $$::jsonb),
    ('3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS"],
        "audience": ["HISTORY"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Open daytime, one day off per week - check before visiting",
            "ru": "Работает днём, один выходной в неделю - уточняйте перед визитом",
            "kk": "Күндіз жұмыс істейді, аптасына бір демалыс - тексеріңіз"}},
        "gettingThere": {
            "en": "Central Kokshetau; walkable, taxi nearby, gateway to Burabay",
            "ru": "Центр Кокшетау; пешком, такси рядом, ворота к Боровому",
            "kk": "Көкшетау орталығы; жаяу, такси жақын, Бурабайға қақпа"},
        "localizedTips": {
            "en": "Entry from about 500 KZT. One of Kazakhstan's older museums; a good indoor stop before Burabay.",
            "ru": "Вход примерно от 500 тенге. Один из старейших музеев Казахстана; хорошая крытая точка перед Боровым.",
            "kk": "Кіру ~500 тенге-ден. Қазақстанның көне музейлерінің бірі; Бурабайға дейін жақсы аялдама."}
    } $$::jsonb),
    -- =================== NATURE PLACES (migration 002) ===================
    ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["OUTDOOR","PHOTO","FAMILY"],
        "safetyNotes": ["HEAT_WARNING","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Checkpoint open 09:00–18:00; canyon trail accessible in daylight",
            "ru": "КПП открыт 09:00–18:00; тропа каньона доступна в светлое время суток",
            "kk": "КПП 09:00–18:00 ашық; шатқал жолы күндіз қолжетімді"}},
        "season": {"months": [3,4,5,9,10], "note": {
            "en": "Best Mar–May and Sep–Oct; July–August extremely hot in the canyon",
            "ru": "Лучшее время март–май и сентябрь–октябрь; в июле–августе в каньоне жара",
            "kk": "Наилучшее нау–мам мен қыр–қаз; шілде–тамызда шатқалда ыстық"}},
        "gettingThere": {
            "en": "About 3–3.5 h by car from Almaty via the Kegen highway; group tours depart Almaty daily",
            "ru": "Около 3–3,5 ч на машине от Алматы по трассе через Кеген; туры из Алматы ежедневно",
            "kk": "Алматыдан Кеген жолымен ~3–3,5 сағат; Алматыдан топтық турлар күн сайын"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Transfer, guided tours, meals, camping fees","ru":"Трансфер, гид, питание, сборы за кемпинг","kk":"Тасымал, гид, тамақ, кемпинг алымдары"}],
        "localizedTips": {
            "en": "Valley of Castles is the signature 3 km loop. Start early to avoid midday heat and tour-bus crowds.",
            "ru": "Долина замков — главная петлевая тропа 3 км. Стартуйте утром, чтобы избежать жары и автобусных туристов.",
            "kk": "Қамалдар аңғары — негізгі 3 км шеңберлі жол. Таңертең ерте шығыңыз — күндізгі ыстық пен автобустарды болдырмайсыз."}
    } $$::jsonb),
    ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["OUTDOOR","HIKING","FAMILY"],
        "safetyNotes": ["BRING_WATER","HIKING_GEAR"],
        "openingHours": {"summary": {
            "en": "Checkpoint open 09:00–18:00; trails accessible in daylight",
            "ru": "КПП открыт 09:00–18:00; тропы доступны в светлое время",
            "kk": "КПП 09:00–18:00 ашық; жолдар күндіз қолжетімді"}},
        "season": {"months": [5,6,7,8,9,10], "note": {
            "en": "June–September for hiking; October for golden autumn colours",
            "ru": "Июнь–сентябрь для трекинга; октябрь — золотая осень",
            "kk": "Маусым–қыркүйек жаяу жол үшін; қазан — алтын күз"}},
        "gettingThere": {
            "en": "About 4.5–5.5 h from Almaty; transfer to Saty village, then 1–2 km on foot or horseback to the lower lake",
            "ru": "Около 4,5–5,5 ч от Алматы; трансфер до Саты, затем 1–2 км пешком или верхом до нижнего озера",
            "kk": "Алматыдан ~4,5–5,5 сағат; Саты ауылына жеткенше, одан кейін 1–2 км жаяу немесе атпен"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Horse riding, camping, upper-lake guide, transfer from Almaty","ru":"Конный прокат, кемпинг, гид на верхние озёра, трансфер","kk":"Ат мінуге жалдау, кемпинг, жоғарғы көлге гид, тасымал"}],
        "localizedTips": {
            "en": "Upper lakes (2nd and 3rd) need a full day and good fitness. The lower lake is easy in 2–3 h. Local UAZ transfers from Saty available.",
            "ru": "Верхние озёра (2-е и 3-е) требуют целого дня и хорошей подготовки. Нижнее озеро — 2–3 ч. Из Сат ходит местный UAZ.",
            "kk": "Жоғарғы көлдер толық күн мен жақсы дайындықты қажет етеді. Төменгі көл — 2–3 сағат. Саты ауылынан UAZ жалдауға болады."}
    } $$::jsonb),
    ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "DIFFICULT", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["OUTDOOR","PHOTO","HIKING"],
        "safetyNotes": ["BRING_WATER","ROUGH_ROAD","HIKING_GEAR"],
        "openingHours": {"summary": {
            "en": "Checkpoint open 09:00–18:00; lake road can be impassable after rain",
            "ru": "КПП открыт 09:00–18:00; дорога к озеру может быть непроезжей после дождей",
            "kk": "КПП 09:00–18:00 ашық; жаңбырдан кейін жол қиын болуы мүмкін"}},
        "season": {"months": [6,7,8,9], "note": {
            "en": "June–September; road may wash out in spring or after heavy rain",
            "ru": "Июнь–сентябрь; дорога может смыться весной или после сильных дождей",
            "kk": "Маусым–қыркүйек; жол көктемде немесе жаңбырдан кейін жабылуы мүмкін"}},
        "gettingThere": {
            "en": "From Saty village: local UAZ or 4×4 recommended; last section may require on-foot approach",
            "ru": "Из Саты: рекомендуется местный UAZ или полный привод; последний участок иногда пешком",
            "kk": "Саты ауылынан: жергілікті UAZ немесе 4×4 ұсынылады; соңғы бөлікте жаяу жүру қажет болуы мүмкін"},
        "included": [{"en":"Park entry fee (Kolsai NP)","ru":"Вход в парк (НП Кольсай)","kk":"Паркке кіру (Қолсай ҰПА)"}],
        "excluded": [{"en":"Transfer from Saty, guided tours","ru":"Трансфер из Сат, экскурсии","kk":"Саты ауылынан тасымал, экскурсиялар"}],
        "localizedTips": {
            "en": "Famous for its drowned spruce trunks rising from turquoise water. Come early — day-trip crowds arrive mid-morning.",
            "ru": "Знаменито затопленными стволами ели в бирюзовой воде. Приезжайте утром — туры прибывают к середине утра.",
            "kk": "Қарагайдың батырылған діңдері мен бирюза суымен танымал. Ертеде келіңіз — күндізгі турлар таң сарысында жетеді."}
    } $$::jsonb),
    ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["OUTDOOR","PHOTO","HIKING"],
        "safetyNotes": ["WIND_COLD","BRING_WATER","NO_SWIMMING"],
        "openingHours": {"summary": {
            "en": "Checkpoint open 09:00–18:00; eco-transport from checkpoint to lake runs until ~17:00",
            "ru": "КПП открыт 09:00–18:00; экотранспорт от КПП до озера работает до ~17:00",
            "kk": "КПП 09:00–18:00 ашық; КПП-дан көлге экокөлік ~17:00 дейін жұмыс істейді"}},
        "season": {"months": [5,6,7,8,9,10], "note": {
            "en": "May–October; winter access restricted — SNO permit required",
            "ru": "Май–октябрь; зимний въезд ограничен — требуется разрешение СНО",
            "kk": "Мамыр–қазан; қысқы кіру шектелген — ҰТК рұқсаты қажет"}},
        "gettingThere": {
            "en": "About 30–45 min from central Almaty; personal cars stopped at the checkpoint in 2026 — walk or take eco-transport ~5 km to the lake",
            "ru": "Около 30–45 мин от центра Алматы; в 2026 году личные авто до озера не пропускают — идите пешком или на экотранспорте ~5 км",
            "kk": "Алматы орталығынан ~30–45 минут; 2026 жылы жеке автокөліктер КПП-дан өтпейді — жаяу немесе экокөлікпен ~5 км"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Eco-transport to lake, guided tours","ru":"Экотранспорт до озера, экскурсии","kk":"Көлге экокөлік, экскурсиялар"}],
        "localizedTips": {
            "en": "No swimming or picnics — the lake supplies drinking water for Almaty. Bring warm layers even in summer; wind off the glacier is cold.",
            "ru": "Купание и пикники запрещены — озеро питьевое для Алматы. Берите тёплые вещи даже летом: ветер с ледника холодный.",
            "kk": "Жуыну және пикник жасауға тыйым салынған — бұл Алматының ауыз суы. Жазда да жылы кийім алыңыз — мұздықтан соқ желі суық."}
    } $$::jsonb),
    ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["PARKING","CAFE_NEARBY"],
        "audience": ["OUTDOOR","FAMILY","PHOTO"],
        "safetyNotes": ["CHECK_HOURS"],
        "openingHours": {"summary": {
            "en": "Closed for reconstruction until end of 2027; the dam and its 842 stairs remain accessible for walks",
            "ru": "Закрыт на реконструкцию до конца 2027 года; плотина и её 842 ступени по-прежнему доступны для прогулок",
            "kk": "2027 жылдың соңына дейін реконструкция үшін жабық; бөгет пен 842 баспалдағы серуендеуге қолжетімді"}},
        "season": {"months": [1,2,3,4,5,6,7,8,9,10,11,12], "note": {
            "en": "Dam stairs accessible year-round; icy in winter — use traction devices",
            "ru": "Лестница к плотине доступна круглый год; зимой льдисто — используйте ледоступы",
            "kk": "Бөгет баспалдақтары жыл бойы қолжетімді; қыста мұзды — шиппер пайдаланыңыз"}},
        "gettingThere": {
            "en": "About 30–45 min from central Almaty by car along Dostyk Ave or Kerey-Zhanibek St; bus 12 also goes",
            "ru": "Около 30–45 мин от центра Алматы по проспекту Достык или ул. Керей Жанибек; ходит автобус 12",
            "kk": "Алматы орталығынан Достық даңғылымен немесе Керей-Жәнібек к-сімен ~30–45 минут; 12-автобус да жүреді"},
        "localizedTips": {
            "en": "The skating rink is closed until 2027. The dam walk and mountain views are still worthwhile; combine with a trip to Shymbulak.",
            "ru": "Каток закрыт до 2027 года. Прогулка по плотине и горные виды по-прежнему хороши; совмещайте с поездкой на Шымбулак.",
            "kk": "Шаңғы-конек майданы 2027 жылға дейін жабық. Бөгетте серуен мен тау-табиғат соқпасы әлі де мүмкін; Шымбұлаққа жол қосыңыз."}
    } $$::jsonb),
    ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["OUTDOOR","COUPLES","FAMILY"],
        "safetyNotes": ["CHECK_HOURS","WIND_COLD"],
        "openingHours": {"summary": {
            "en": "Medeu–Shymbulak gondola daily 09:00–18:00; Kombi-1 to 17:00, Kombi-2 to 16:30; schedule varies by season",
            "ru": "Гондола Медеу–Шымбулак ежедневно 09:00–18:00; Комби-1 до 17:00, Комби-2 до 16:30; расписание по сезону",
            "kk": "Медеу–Шымбұлақ гондоласы күн сайын 09:00–18:00; Комби-1 17:00 дейін, Комби-2 16:30 дейін; кесте маусымға қарай"}},
        "season": {"months": [12,1,2,3,6,7,8,9], "note": {
            "en": "Dec–Mar for skiing; Jun–Sep for summer hiking and sightseeing",
            "ru": "Декабрь–март для горных лыж; июнь–сентябрь для летних прогулок",
            "kk": "Желтоқсан–наурыз шаңғы тебу үшін; маусым–қыркүйек жазғы жаяу жол үшін"}},
        "gettingThere": {
            "en": "Drive or taxi to Medeu (30–45 min from Almaty), then take the gondola (~20 min up); tickets at Medeu lower station",
            "ru": "Доехать до Медеу (30–45 мин от Алматы), затем гондола (~20 мин вверх); билеты у нижней станции",
            "kk": "Медеуге көлікпен немесе такси арқылы (Алматыдан 30–45 мин), содан кейін гондоламен (~20 мин жоғары); билет төменгі станцияда"},
        "included": [{"en":"Gondola ride to Shymbulak","ru":"Проезд гондолой до Шымбулака","kk":"Шымбұлаққа гондоламен жол"}],
        "excluded": [{"en":"Kombi-1 and Kombi-2 lifts (separate ticket), ski pass, equipment rental, restaurants","ru":"Комби-1 и Комби-2 (отдельный билет), ски-пасс, прокат, рестораны","kk":"Комби-1 және Комби-2 (бөлек билет), ски-пасс, прокат, мейрамханалар"}],
        "localizedTips": {
            "en": "Check cable car status before going — weather can stop operations. Buy gondola tickets online to skip queues in peak season.",
            "ru": "Перед поездкой проверяйте работу канатки — плохая погода может остановить. Покупайте билеты онлайн, чтобы избежать очередей в сезон.",
            "kk": "Баруыңыздан бұрын аспалы жол жұмысын тексеріңіз. Маусымда кезекті болдырмас үшін билеттерді онлайн алыңыз."}
    } $$::jsonb),
    ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["PARKING","RESTROOMS"],
        "audience": ["OUTDOOR","PHOTO","HIKING"],
        "safetyNotes": ["HEAT_WARNING","BRING_WATER","LONG_DRIVE"],
        "openingHours": {"summary": {
            "en": "Visitor centre open 09:00–18:00; routes available by day permit",
            "ru": "Визит-центр открыт 09:00–18:00; маршруты по дневному разрешению",
            "kk": "Визит-орталық 09:00–18:00 ашық; бағыттар күндізгі рұқсатпен"}},
        "season": {"months": [3,4,5,9,10], "note": {
            "en": "Best Apr–Jun and Sep–Oct; summer heat extreme in the desert zones",
            "ru": "Лучшее время апрель–июнь и сентябрь–октябрь; летом жара в пустынных зонах",
            "kk": "Наилучшее сәу–маусым мен қыр–қаз; жазда шөл аймақтарында ыстық"}},
        "gettingThere": {
            "en": "About 3–4 h by car from Almaty or 2 h from Taldykorgan; no public transport — rent a 4×4 or join a guided tour",
            "ru": "Около 3–4 ч от Алматы или 2 ч от Талдыкоргана; общественного транспорта нет — аренда 4×4 или тур",
            "kk": "Алматыдан ~3–4 сағат немесе Талдықорғаннан ~2 сағат; қоғамдық көлік жоқ — 4×4 жалдау немесе тур"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Transfer, guided tour, camping","ru":"Трансфер, гид, кемпинг","kk":"Тасымал, гид, кемпинг"}],
        "localizedTips": {
            "en": "Key sites: Singing Dune, Aktau and Katutau coloured mountains, Besshatyr Saka burial mounds. A single day is tight — plan for two.",
            "ru": "Главные объекты: Поющий бархан, цветные горы Актау и Катутау, сакские курганы Бесшатыр. За день тесновато — планируйте на два.",
            "kk": "Негізгі нысандар: Əнші шоқы, Ақтау мен Қатутаудың таулары, Бесшатыр сақ обалары. Бір күнге тар — екі күнді жоспарлаңыз."}
    } $$::jsonb),
    ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["HISTORY","PHOTO","FAMILY"],
        "safetyNotes": ["HEAT_WARNING","NO_TOUCHING"],
        "openingHours": {"summary": {
            "en": "Tue–Sun 09:00–18:00; Mon closed (sanitary day); cashier closes at 17:00",
            "ru": "Вт–Вс 09:00–18:00; Пн закрыт (санитарный день); касса закрывается в 17:00",
            "kk": "Сс–Жс 09:00–18:00; Дс жабық (санитарлық күн); касса 17:00-де жабылады"}},
        "season": {"months": [4,5,6,9,10], "note": {
            "en": "Best Apr–Jun and Sep–Oct; avoid midday heat in summer",
            "ru": "Апрель–июнь и сентябрь–октябрь; летом избегайте полуденного зноя",
            "kk": "Сәу–маусым мен қыр–қаз; жазда күндізгі ыстықтан қашыңыз"}},
        "gettingThere": {
            "en": "About 3 h by car from Almaty via the Kapshagai highway; no public bus to the site",
            "ru": "Около 3 ч от Алматы по капшагайской трассе; автобуса до объекта нет",
            "kk": "Алматыдан Қапшағай тас жолымен ~3 сағат; нысанға дейін автобус жоқ"},
        "included": [{"en":"UNESCO Tamgaly site entry","ru":"Вход в ЮНЕСКО Тамгалы","kk":"ЮНЕСКО Таңбалы нысанына кіру"}],
        "excluded": [{"en":"Transfer, guided tour","ru":"Трансфер, гид","kk":"Тасымал, гид"}],
        "localizedTips": {
            "en": "Note: this is Tamgaly (Semirechye), NOT Tamgaly-Tas on the Ili River — different sites. A guide adds significant context to the petroglyphs.",
            "ru": "Важно: это Тамгалы (Семиречье), НЕ Тамгалы-Тас на Или — разные объекты. Гид значительно обогатит посещение петроглифов.",
            "kk": "Ескерту: бұл Таңбалы (Жетісу), Іле жағасындағы Таңбалы-Тас емес — әртүрлі нысандар. Гид петроглифтерді тамашалауды байытады."}
    } $$::jsonb),
    ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","CAFE_NEARBY"],
        "audience": ["HISTORY","FAMILY","PHOTO"],
        "safetyNotes": ["DRESS_CODE"],
        "openingHours": {"summary": {
            "en": "Daily 09:00–18:00; cashier may close earlier; closed on some national holidays",
            "ru": "Ежедневно 09:00–18:00; касса может закрыться раньше; закрыт в некоторые праздники",
            "kk": "Күн сайын 09:00–18:00; касса ертерек жабылуы мүмкін; кейбір мереке күндері жабық"}},
        "season": {"months": [3,4,5,9,10,11], "note": {
            "en": "Best Mar–May and Sep–Nov; summer possible but very hot — visit early morning",
            "ru": "Лучшее время март–май и сентябрь–ноябрь; летом возможно, но жарко — посещайте рано утром",
            "kk": "Наилучшее нау–мам мен қыр–қар; жазда мүмкін, бірақ ыстық — таң сарысында барыңыз"}},
        "gettingThere": {
            "en": "Central Turkestan, walkable from the Karavansaray hotel and EXPO area; direct trains from Almaty and Shymkent",
            "ru": "Центральный Туркестан, пешком от гостиницы Каравансарай и EXPO; прямые поезда из Алматы и Шымкента",
            "kk": "Орталық Түркістан, Керуен-сарай қонақүйі мен EXPO аймағынан жаяу; Алматыдан және Шымкенттен тікелей пойыздар"},
        "included": [{"en":"Mausoleum and museum entry","ru":"Вход в мавзолей и музей","kk":"Кесенеге және мұражайға кіру"}],
        "excluded": [{"en":"Guided tours, audio guide","ru":"Экскурсии, аудиогид","kk":"Экскурсиялар, аудиогид"}],
        "localizedTips": {
            "en": "Modest dress required — cover shoulders and knees; scarves available at entrance. Built on Timur's order in the 14th c., still an active pilgrimage site.",
            "ru": "Требуется скромная одежда — плечи и колени закрыты; платки у входа. Построен по приказу Тимура в XIV в., до сих пор место паломничества.",
            "kk": "Скромды киім талап етіледі — иықтар мен тізелер жабулы; кіре берісте орамал бар. XIV ғ. Тимур бұйрығымен салынған, қазір де қасиетті зиярат орны."}
    } $$::jsonb),
    ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","OUTDOOR","COUPLES"],
        "safetyNotes": ["SUMMER_TRAFFIC","BOOK_EARLY"],
        "openingHours": {"summary": {
            "en": "Park zones open in daylight; beach and water services seasonal; pedestrian entry to NP is free",
            "ru": "Зоны парка открыты в светлое время суток; пляж и водные сервисы по сезону; вход для пешеходов бесплатный",
            "kk": "Парк аймақтары күндіз ашық; жағажай мен су қызметтері маусымды; ҰПА-ға жаяу кіру тегін"}},
        "season": {"months": [6,7,8,9,1,2], "note": {
            "en": "June–Sep for swimming and hiking; Jan–Feb for winter sports and ice fishing",
            "ru": "Июнь–сентябрь для купания и треккинга; январь–февраль для зимних видов спорта и рыбалки",
            "kk": "Маусым–қыркүйек жүзу мен жаяу жол үшін; қаңтар–ақпан қысқы спорт пен балық аулау үшін"}},
        "gettingThere": {
            "en": "About 2–3 h by car from Astana; buses from Kokshetau to Burabay village run daily; heavy traffic on summer weekends",
            "ru": "Около 2–3 ч на машине от Астаны; автобусы из Кокшетау до посёлка Бурабай ежедневно; летом трафик в выходные",
            "kk": "Астанадан ~2–3 сағат; Көкшетаудан Бурабай кентіне автобустар күн сайын; жазда демалыс күндері кептелу"},
        "included": [{"en":"Pedestrian park access (free)","ru":"Пешеходный вход в парк (бесплатно)","kk":"Жаяу кіру (тегін)"}],
        "excluded": [{"en":"Car entry 1750 KZT, boat/kayak rental, resort accommodation","ru":"Въезд автомобиля 1750 тг, лодка/каяк, гостиницы курорта","kk":"Автокөлік кіруі 1750 тг, қайық/каяк жалдау, курорт мекемелері"}],
        "localizedTips": {
            "en": "Burabay is free for pedestrians. Cars pay 1750 KZT at the checkpoint. Book accommodation months ahead for July–August. Blue Lake (Kokshetau side) is cleanest for swimming.",
            "ru": "Бурабай бесплатен для пешеходов. Авто платят 1750 тг на КПП. Бронируйте жильё за месяцы до июля–августа. Синеглазка (кокшетауская сторона) — чистейшее озеро.",
            "kk": "Бурабай жаяу жүргіншілерге тегін. Автокөліктер КПП-да 1750 тг төлейді. Шілде–тамызға дейін бірнеше ай бұрын тұру жерін брондаңыз."}
    } $$::jsonb),
    ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","CAFE_NEARBY"],
        "audience": ["OUTDOOR","FAMILY","HIKING"],
        "safetyNotes": ["TICK_PROTECTION","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Checkpoint and routes accessible in daylight; beach areas open in summer",
            "ru": "КПП и маршруты доступны в светлое время; пляжные зоны открыты летом",
            "kk": "КПП мен жолдар күндіз қолжетімді; жаз айларында жағажай аймақтары ашық"}},
        "season": {"months": [5,6,7,8,9], "note": {
            "en": "May–Sep; July–August for lake swimming at Jasybay",
            "ru": "Май–сентябрь; июль–август для купания на Жасыбай",
            "kk": "Мамыр–қыркүйек; шілде–тамыз Жасыбайда жүзу үшін"}},
        "gettingThere": {
            "en": "About 2.5 h from Pavlodar or 4 h from Astana; buses from Pavlodar run regularly; download offline map — signage is sparse",
            "ru": "Около 2,5 ч от Павлодара или 4 ч от Астаны; автобусы из Павлодара ходят регулярно; скачайте офлайн-карту — знаков мало",
            "kk": "Павлодардан ~2,5 сағат немесе Астанадан ~4 сағат; Павлодардан автобустар жүреді; офлайн-картаны жүктеп алыңыз — белгілер аз"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Transfer, boat rental, camping fees","ru":"Трансфер, аренда лодки, сборы за кемпинг","kk":"Тасымал, қайық жалдау, кемпинг алымдары"}],
        "localizedTips": {
            "en": "Jasybay and Toraygyr lakes are the main draws. Ticks active May–June — use repellent and check after hikes. Crowded July–Aug; quieter in May and September.",
            "ru": "Жасыбай и Торайгыр — главные озёра. Клещи активны в мае–июне — используйте репеллент и проверяйтесь. Людно в июле–августе; тише в мае и сентябре.",
            "kk": "Жасыбай мен Торайғыр — негізгі тартымды нысандар. Кенелер мамыр–маусымда белсенді — репелент пайдаланыңыз. Шілде–тамыз адамды, мамыр мен қыркүйек тыныш."}
    } $$::jsonb),
    ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "DIFFICULT", "bookingRequired": true,
        "amenities": ["PARKING"],
        "audience": ["OUTDOOR","HIKING","ADVENTURE"],
        "safetyNotes": ["BORDER_PERMIT","ROUGH_ROAD","BRING_WATER"],
        "openingHours": {"summary": {
            "en": "Checkpoint and routes in daylight; border zone visits require separate permit ordered in advance",
            "ru": "КПП и маршруты в светлое время; посещение приграничной зоны — отдельное разрешение заранее",
            "kk": "КПП мен жолдар күндіз; шекара аймағына кіру — алдын ала тапсырылатын бөлек рұқсат"}},
        "season": {"months": [6,7,8,9], "note": {
            "en": "June–September; September for stunning golden larch forests",
            "ru": "Июнь–сентябрь; сентябрь — золотые лиственничные леса",
            "kk": "Маусым–қыркүйек; қыркүйек — алтын балқарағай ормандары"}},
        "gettingThere": {
            "en": "About 5–6 h from Ust-Kamenogorsk; 4×4 required for deeper routes; plan at least 2–3 days",
            "ru": "Около 5–6 ч от Усть-Каменогорска; 4×4 для дальних маршрутов; планируйте минимум 2–3 дня",
            "kk": "Өскеменнен ~5–6 сағат; терең бағыттарға 4×4 керек; ең кемі 2–3 күн жоспарлаңыз"},
        "included": [{"en":"Park entry fee","ru":"Вход в парк","kk":"Паркке кіру"}],
        "excluded": [{"en":"Border zone permit, transfer, guide, camping","ru":"Разрешение пограничной зоны, трансфер, гид, кемпинг","kk":"Шекара рұқсаты, тасымал, гид, кемпинг"}],
        "localizedTips": {
            "en": "Home to snow leopards, Altai argali and Siberian red deer. Berel valley has Scythian burial mounds. Border zone permit: apply at regional dept 1–2 weeks in advance.",
            "ru": "Обитатели: снежный барс, алтайский архар, марал. Долина Берел — скифские курганы. Разрешение погранзоны: подавать в региональный департамент за 1–2 недели.",
            "kk": "Тұрғындары: қар барысы, алтай архары, бұғы. Берел аңғарында скиф обалары. Шекара рұқсаты: 1–2 апта бұрын аймақтық департаментке өтінім беріңіз."}
    } $$::jsonb),
    ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "DIFFICULT", "bookingRequired": true,
        "amenities": ["PARKING"],
        "audience": ["OUTDOOR","HIKING","WILDLIFE"],
        "safetyNotes": ["GUIDE_REQUIRED","ROUGH_ROAD"],
        "openingHours": {"summary": {
            "en": "Reserve office 09:00–18:00; access only via pre-arranged route with mandatory staff escort",
            "ru": "Офис заповедника 09:00–18:00; доступ только по заранее согласованному маршруту с сопровождением",
            "kk": "Қорық кеңсесі 09:00–18:00; кіру тек алдын ала келісілген бағытпен және міндетті серіктеспен"}},
        "season": {"months": [4,5,6,9,10], "note": {
            "en": "April–May for wild Greig's tulips (UNESCO landscape); Sep–Oct for migratory birds",
            "ru": "Апрель–май для диких тюльпанов Грейга (ЮНЕСКО); сентябрь–октябрь для перелётных птиц",
            "kk": "Сәуір–мамыз ЮНЕСКО тізіміндегі Грейг қызғалдақтары үшін; қыр–қаз — өтпелі құстар"}},
        "gettingThere": {
            "en": "About 3 h from Shymkent or 2 h from Taraz; headquarters in Zhabagly village; independent access not permitted — book guided route in advance",
            "ru": "Около 3 ч от Шымкента или 2 ч от Тараза; штаб в посёлке Жабаглы; самостоятельный вход невозможен — маршрут бронируется заранее",
            "kk": "Шымкенттен ~3 сағат немесе Тараздан ~2 сағат; штаб Жабаглы кентінде; дербес кіру мүмкін емес — бағытты алдын ала брондаңыз"},
        "included": [{"en":"Reserve entry fee, mandatory guide","ru":"Вход в заповедник, обязательный гид","kk":"Қорыққа кіру алымы, міндетті гид"}],
        "excluded": [{"en":"Transfer, food and accommodation in Zhabagly","ru":"Трансфер, питание и проживание в Жабаглы","kk":"Тасымал, Жабаглыдағы тамақ пен тұру"}],
        "localizedTips": {
            "en": "Oldest nature reserve in Central Asia (est. 1926). Contact the reserve weeks ahead for April tulip season — groups fill quickly.",
            "ru": "Старейший заповедник Центральной Азии (с 1926 г.). Связывайтесь с дирекцией за несколько недель до апрельского сезона тюльпанов — группы быстро заполняются.",
            "kk": "Орталық Азияның ең ескі қорығы (1926 жылдан). Сәуір қызғалдақ маусымынан бірнеше апта бұрын қорық дирекциясымен хабарласыңыз — топтар тез толады."}
    } $$::jsonb),
    ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["PARKING"],
        "audience": ["WILDLIFE","OUTDOOR","PHOTO"],
        "safetyNotes": ["BRING_WATER","NO_OFFROAD"],
        "openingHours": {"summary": {
            "en": "Eco-trails and visitor centres accessible in daylight; seasonal flamingo viewing",
            "ru": "Экотропы и визит-центры доступны в светлое время; сезонное наблюдение за фламинго",
            "kk": "Экожолдар мен визит-орталықтар күндіз қолжетімді; фламинго бақылаудың маусымдық мүмкіндігі"}},
        "season": {"months": [4,5,6,7,8,9], "note": {
            "en": "Apr–May for flamingos and waterfowl; Aug–Sep for peak bird diversity",
            "ru": "Апрель–май для фламинго и водоплавающих птиц; август–сентябрь — пик птичьего разнообразия",
            "kk": "Сәуір–мамыр фламинго мен суқұстар үшін; тамыз–қыркүйек — құс алуантүрлілігінің шыңы"}},
        "gettingThere": {
            "en": "Korgalzhyn reserve 130 km south-west of Astana (~2 h); Naurzum is in Kostanay region 600 km from Astana — plan as separate trips",
            "ru": "Заповедник Коргалжын — 130 км к юго-западу от Астаны (~2 ч); Наурзум — в Костанайской обл., 600 км от Астаны — планируйте отдельно",
            "kk": "Қорғалжын қорығы Астанадан 130 км оңтүстік-батыста (~2 сағат); Наурзым Қостанай облысында, Астанадан 600 км — бөлек сапарды жоспарлаңыз"},
        "included": [{"en":"Reserve entry fee","ru":"Вход в заповедник","kk":"Қорыққа кіру алымы"}],
        "excluded": [{"en":"Transfer, binoculars rental, guided birdwatching tour","ru":"Трансфер, аренда бинокля, тур для наблюдения за птицами","kk":"Тасымал, дүрбі жалдау, ұйымдастырылған құс бақылауы"}],
        "localizedTips": {
            "en": "Bring quality binoculars. Flamingos nest at Teniz Lake in Korgalzhyn — up to 50,000 birds. Stay on designated roads; off-road driving damages the steppe.",
            "ru": "Возьмите хороший бинокль. Фламинго гнездятся на озере Тениз в Коргалжыне — до 50 000 особей. Придерживайтесь дорог — езда по степи наносит ущерб.",
            "kk": "Жақсы дүрбі алыңыз. Фламинго Тениз көлінде ұялайды — 50 000-ға дейін. Белгіленген жолда жүріңіз — тыс жерлерге шығу далаға зиян."}
    } $$::jsonb),
    ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","CAFE_NEARBY"],
        "audience": ["FAMILY","OUTDOOR","COUPLES"],
        "safetyNotes": ["WIND_WAVES","SUN_PROTECTION"],
        "openingHours": {"summary": {
            "en": "Open 24 h; beach services and lifeguards seasonal (Jun–Aug)",
            "ru": "Открыто круглосуточно; пляжные сервисы и спасатели сезонно (июнь–август)",
            "kk": "24 сағат ашық; жағажай қызметтері мен құтқарушылар маусымды (маусым–тамыз)"}},
        "season": {"months": [6,7,8], "note": {
            "en": "June–August for swimming; September quieter with cooler water",
            "ru": "Июнь–август для купания; сентябрь — тише, вода холоднее",
            "kk": "Маусым–тамыз жүзу үшін; қыркүйек — тыны, су салқынырақ"}},
        "gettingThere": {
            "en": "About 6 h from Almaty or 3 h from Taldykorgan; direct trains from Almaty to Druzhba station near the lake; car is most flexible",
            "ru": "Около 6 ч от Алматы или 3 ч от Талдыкоргана; прямые поезда из Алматы до станции Дружба; машина удобнее",
            "kk": "Алматыдан ~6 сағат немесе Талдықорғаннан ~3 сағат; Алматыдан Дружба станциясына тікелей пойыздар; автокөлік ыңғайлы"},
        "localizedTips": {
            "en": "Lake Alakol is slightly salty and mineral-rich. Strong afternoon winds common; waves can be dangerous — choose a resort beach with lifeguards.",
            "ru": "Алакол слегка солоноватый и минерализованный. Послеполуденные ветра часты; волны могут быть опасны — выбирайте пляж с спасателями.",
            "kk": "Алакөл сәл тұздысы және минерализацияланған. Күндізгі жел жиі; толқындар қауіпті болуы мүмкін — құтқарушылары бар жағажайды таңдаңыз."}
    } $$::jsonb),
    ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","CAFE_NEARBY"],
        "audience": ["FAMILY","OUTDOOR","FISHING"],
        "safetyNotes": ["SUN_PROTECTION","WIND_WAVES"],
        "openingHours": {"summary": {
            "en": "Open 24 h; beach services seasonal (Jun–Aug); fishing year-round",
            "ru": "Открыто круглосуточно; пляжные сервисы сезонно (июнь–август); рыбалка круглый год",
            "kk": "24 сағат ашық; жағажай қызметтері маусымды (маусым–тамыз); балық аулау жыл бойы"}},
        "season": {"months": [5,6,7,8,9], "note": {
            "en": "May and Sep for walks; June–August for swimming",
            "ru": "Май и сентябрь для прогулок; июнь–август для купания",
            "kk": "Мамыр мен қыркүйек серуен үшін; маусым–тамыз жүзу үшін"}},
        "gettingThere": {
            "en": "About 2 h from Karaganda or 5–6 h from Almaty via Kapshagai; train to Balkhash city then taxi to beach",
            "ru": "Около 2 ч от Карганды или 5–6 ч от Алматы через Капшагай; поезд до Балхаша, затем такси до пляжа",
            "kk": "Қарағандыдан ~2 сағат немесе Алматыдан Қапшағай арқылы ~5–6 сағат; Балқаш қаласына пойыз, содан кейін жағажайға такси"},
        "localizedTips": {
            "en": "Balkhash is unique: west half fresh water, east half salty. The western shore near the city has the clearest fresh-water beaches. Fishing for asp, pike and roach.",
            "ru": "Балхаш уникален: западная половина — пресная, восточная — солоноватая. Западный берег у города — чистейшие пресные пляжи. Рыбалка на жереха, щуку, плотву.",
            "kk": "Балқаш ерекше: батыс жартысы тұщы, шығыс жартысы тұзды. Қала жанындағы батыс жағалауы — таза тұщы су жағажайлары. Жайын, шортан, табан аулауға болады."}
    } $$::jsonb),
    ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "DIFFICULT", "bookingRequired": false,
        "amenities": [],
        "audience": ["OUTDOOR","PHOTO","ADVENTURE"],
        "safetyNotes": ["HEAT_WARNING","BRING_WATER","OFFROAD_ONLY","NO_SOLO"],
        "openingHours": {"summary": {
            "en": "No fixed hours; accessible in daylight; summer midday is dangerous (45°C+)",
            "ru": "Фиксированного расписания нет; доступно в светлое время; летний полдень опасен (45°C+)",
            "kk": "Белгіленген кесте жоқ; күндіз қолжетімді; жазғы күн ортасы қауіпті (45°C+)"}},
        "season": {"months": [3,4,5,9,10,11], "note": {
            "en": "Best Mar–May and Sep–Nov; summer only at sunrise or sunset (extreme heat)",
            "ru": "Лучшее время март–май и сентябрь–ноябрь; летом только на рассвете или закате (экстремальная жара)",
            "kk": "Наилучшее нау–мам мен қыр–қараша; жазда тек таң атқанда немесе кешкі батысқанда (шектен тыс ыстық)"}},
        "gettingThere": {
            "en": "About 3–4 h off-road from Aktau with experienced driver or guided 4×4 tour; no public transport; solo travel not recommended",
            "ru": "Около 3–4 ч по бездорожью от Актау с опытным водителем или на туре 4×4; общественный транспорт отсутствует; самостоятельный заезд не рекомендуется",
            "kk": "Актаудан тәжірибелі жүргізушімен немесе 4×4 тұрмен ~3–4 сағат жолсыз; қоғамдық көлік жоқ; дербес кіру ұсынылмайды"},
        "excluded": [{"en":"Transfer, guided tour (strongly recommended), food and water","ru":"Трансфер, гид (настоятельно рекомендуется), еда и вода","kk":"Тасымал, гид (мықтап ұсынылады), тамақ пен су"}],
        "localizedTips": {
            "en": "Do NOT drive onto the plateau surface — fragile chalk formations crack. Carry 5+ litres of water per person and extra fuel. A guided tour from Aktau is the safest option.",
            "ru": "НЕ заезжайте на поверхность плато — хрупкие меловые образования трескаются. Возите 5+ литров воды на человека и запас топлива. Тур из Актау — самый безопасный вариант.",
            "kk": "Плато бетіне ШЫҚПАҢЫЗ — сынғыш бор түзілімдері жарылады. Адамға 5+ литр су мен қосымша жанармай алыңыз. Актаудан тур — ең қауіпсіз нұсқа."}
    } $$::jsonb),
    ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, $$ {
        "bestTime": "AFTERNOON", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","CAFE_NEARBY","PARKING"],
        "audience": ["FAMILY","COUPLES","PHOTO"],
        "safetyNotes": ["QUEUE_WARNING"],
        "openingHours": {"summary": {
            "en": "Jun–Aug 10:00–22:00; Sep–May 10:00–21:00; closed last Monday of the month",
            "ru": "Июнь–август 10:00–22:00; сентябрь–май 10:00–21:00; закрыт в последний понедельник месяца",
            "kk": "Маусым–тамыз 10:00–22:00; қыркүйек–мамыр 10:00–21:00; айдың соңғы дүйсенбісінде жабық"}},
        "season": {"months": [1,2,3,4,5,6,7,8,9,10,11,12], "note": {
            "en": "Year-round; best on clear evenings for panoramic city views",
            "ru": "Круглый год; лучше всего в ясные вечера для панорамных видов на город",
            "kk": "Жыл бойы; қала панорамасы үшін мөлдір кешкілерде ең жақсы"}},
        "gettingThere": {
            "en": "Central Astana on Nurzhol Boulevard; 10–15 min walk from Khan Shatyr; taxi or bus from anywhere in the city",
            "ru": "Центр Астаны на бульваре Нурлы Жол; 10–15 мин пешком от Хан Шатыра; такси или автобус из любой точки города",
            "kk": "Нұрлы жол бульварындағы Астана орталығы; Хан Шатырынан 10–15 минут жаяу; қаланың кез келген жерінен такси немесе автобус"},
        "included": [{"en":"Observation deck entry","ru":"Вход на смотровую площадку","kk":"Бақылау алаңына кіру"}],
        "excluded": [{"en":"Restaurant on top, VIP level","ru":"Ресторан наверху, VIP уровень","kk":"Жоғарыдағы мейрамхана, VIP деңгейі"}],
        "localizedTips": {
            "en": "The golden sphere at 105 m holds Nursultan Nazarbayev's handprint. Come 1 h before closing for fewer crowds. The government district along Nurzhol Blvd looks best at night.",
            "ru": "Золотая сфера на 105 м — отпечаток руки Нурсултана Назарбаева. Приходите за 1 ч до закрытия — меньше народа. Правительственный квартал лучше смотреть ночью.",
            "kk": "105 м биіктіктегі алтын сфера — Нұрсұлтан Назарбаевтың қол ізі. Жабылудан 1 сағат бұрын барыңыз — аз халық. Үкімет кварталы түнде тамаша көрінеді."}
    } $$::jsonb),
    ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "GOOD", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING","CAFE_NEARBY"],
        "audience": ["HISTORY","FAMILY","PHOTO"],
        "safetyNotes": ["HEAT_WARNING"],
        "openingHours": {"summary": {
            "en": "Tue–Sun 09:00–18:00; Mon closed; outdoor ruins accessible in daylight",
            "ru": "Вт–Вс 09:00–18:00; Пн закрыт; уличные руины доступны в светлое время",
            "kk": "Сс–Жс 09:00–18:00; Дс жабық; сыртқы қирандылар күндіз қолжетімді"}},
        "season": {"months": [3,4,5,9,10,11], "note": {
            "en": "Best spring and autumn; summer visits possible but very hot midday",
            "ru": "Лучше весной и осенью; летом возможно, но жарко в полдень",
            "kk": "Наилучшее — көктем мен күз; жаз мүмкін, бірақ күнортада ыстық"}},
        "gettingThere": {
            "en": "Central Taraz; combine with Tekturmas Hill for panoramic views and Aulie-Ata mosque in the same walk",
            "ru": "Центр Тараза; совмещайте с горой Тектурмас (панорамные виды) и мечетью Аулие-Ата в одной прогулке",
            "kk": "Тараз орталығы; Тектұрмас тауымен (панорамды көрініс) және Әулие-Ата мешітімен бір серуенге біріктіріңіз"},
        "included": [{"en":"Open-air museum and indoor exhibits","ru":"Музей под открытым небом и залы","kk":"Ашық аспан астындағы музей мен залдар"}],
        "excluded": [{"en":"Guided tour","ru":"Экскурсия","kk":"Экскурсия"}],
        "localizedTips": {
            "en": "Taraz was a major Silk Road hub — one of the oldest continuously inhabited cities in Kazakhstan. Hire a local guide; plaques alone provide sparse context.",
            "ru": "Тараз — крупный узел Шёлкового пути, один из старейших непрерывно обитаемых городов Казахстана. Возьмите местного гида: одних табличек мало.",
            "kk": "Тараз — Жібек жолының маңызды торабы, Қазақстандағы ең ескі үздіксіз мекендеген қалалардың бірі. Жергілікті гид алыңыз; жалғыз тақтайша жеткіліксіз."}
    } $$::jsonb),
    ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, $$ {
        "bestTime": "MORNING", "accessibility": "MODERATE", "bookingRequired": false,
        "amenities": ["RESTROOMS","PARKING"],
        "audience": ["HISTORY","OUTDOOR","HIKING"],
        "safetyNotes": ["BRING_WATER","RESPECT_SITE"],
        "openingHours": {"summary": {
            "en": "Visitor centre 09:00–18:00; outdoor routes accessible in daylight with purchased permit",
            "ru": "Визит-центр 09:00–18:00; внешние маршруты доступны в светлое время с оплаченным разрешением",
            "kk": "Визит-орталық 09:00–18:00; сыртқы жолдар күндіз төленген рұқсатпен қолжетімді"}},
        "season": {"months": [4,5,6,7,8,9,10], "note": {
            "en": "Year-round; spring and autumn most comfortable",
            "ru": "Круглый год; весной и осенью комфортнее всего",
            "kk": "Жыл бойы; көктем мен күзде ыңғайлырақ"}},
        "gettingThere": {
            "en": "About 5 h from Karaganda or Zhezkazgan; remote — 4×4 recommended for trailhead access; plan an overnight stay",
            "ru": "Около 5 ч от Карганды или Жезказгана; отдалённое место — 4×4 для подъезда к тропам; планируйте ночёвку",
            "kk": "Қарағанды немесе Жезқазғаннан ~5 сағат; алыс нысан — жолдар бастауына 4×4 ұсынылады; түнде тоқтауды жоспарлаңыз"},
        "included": [{"en":"Reserve-museum entry and outdoor permit","ru":"Вход в музей-заповедник и разрешение на маршрут","kk":"Қорық-мұражайға кіру мен жол рұқсаты"}],
        "excluded": [{"en":"Transfer, camping, guided tour","ru":"Трансфер, кемпинг, гид","kk":"Тасымал, кемпинг, гид"}],
        "localizedTips": {
            "en": "Jochi Khan's mausoleum (son of Genghis Khan) is the centrepiece. The steppe landscape is vast — a guide helps locate petroglyphs and lesser-known burial mounds.",
            "ru": "Мавзолей Джучи-хана (сына Чингисхана) — главный объект. Степной пейзаж обширен — гид помогает найти петроглифы и малоизвестные курганы.",
            "kk": "Жошы ханның кесенесі (Шыңғыс ханның ұлы) — орталық нысан. Дала пейзажы кең — гид петроглифтер мен белгісіз обаларды табуға көмектеседі."}
    } $$::jsonb)
)
UPDATE places p
SET
    visit_info = COALESCE(p.visit_info, '{}'::jsonb) || s.vi,
    updated_at = NOW()
FROM seed_city_visit_info s
WHERE p.id = s.place_id
  AND p.source = 'IMPORT';
