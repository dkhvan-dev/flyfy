-- Curated Russia attractions seed.
-- Texts are original Inflap editorial summaries localized for ru, en, kk.
-- Sources audited in May 2026:
-- - Wikimedia Commons and Wikipedia for representative cover media and source pages.
-- - OpenStreetMap search URLs for lightweight location verification anchors.
-- Selection policy:
-- - country_code is always RU, because federal subjects/regions are not modeled as countries;
-- - city_id stores a practical departure/search hub inside Russia;
-- - ratings are editorial baselines for imported curated content until user reviews take over;
-- - price is left NULL because tickets and opening conditions change by season/operator.

WITH seed_base (
    id,
    city_id,
    category,
    duration_value,
    duration_unit,
    rating,
    tags
) AS (
    VALUES
        ('5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 'moscow', 'ARCHITECTURE', 2, 'HOURS', 4.9, ARRAY['russia', 'moscow', 'red-square', 'kremlin', 'history', 'architecture', 'must-visit']::text[]),
        ('e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 'moscow', 'MUSEUM', 3, 'HOURS', 4.8, ARRAY['russia', 'moscow', 'tretyakov-gallery', 'art', 'museum', 'culture', 'classic']::text[]),
        ('de526545-792c-4c0e-86fe-f837f5085761'::uuid, 'moscow', 'PARK', 2, 'HOURS', 4.7, ARRAY['russia', 'moscow', 'gorky-park', 'park', 'walk', 'family', 'city']::text[]),
        ('38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 'moscow', 'ENTERTAINMENT', 3, 'HOURS', 4.7, ARRAY['russia', 'moscow', 'vdnkh', 'exhibition', 'pavilions', 'fountains', 'family']::text[]),
        ('e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 'saint-petersburg', 'MUSEUM', 4, 'HOURS', 4.9, ARRAY['russia', 'saint-petersburg', 'hermitage', 'museum', 'art', 'winter-palace', 'must-visit']::text[]),
        ('fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 'saint-petersburg', 'PARK', 4, 'HOURS', 4.8, ARRAY['russia', 'saint-petersburg', 'peterhof', 'palace', 'fountains', 'park', 'architecture']::text[]),
        ('d751994b-5412-4a5c-8d35-883a676c3932'::uuid, 'saint-petersburg', 'TEMPLE', 1, 'HOURS', 4.8, ARRAY['russia', 'saint-petersburg', 'savior-on-blood', 'church', 'mosaics', 'architecture', 'landmark']::text[]),
        ('8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 'saint-petersburg', 'ENTERTAINMENT', 2, 'HOURS', 4.6, ARRAY['russia', 'saint-petersburg', 'new-holland', 'island', 'park', 'food', 'creative-space']::text[]),
        ('e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 'kazan', 'ARCHITECTURE', 3, 'HOURS', 4.8, ARRAY['russia', 'kazan', 'kazan-kremlin', 'unesco', 'kul-sharif', 'history', 'architecture']::text[]),
        ('c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 'sochi', 'PARK', 2, 'HOURS', 4.6, ARRAY['russia', 'sochi', 'arboretum', 'park', 'botanical', 'cable-car', 'family']::text[]),
        ('0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 'sochi', 'NATURE', 5, 'HOURS', 4.7, ARRAY['russia', 'sochi', 'rosa-khutor', 'mountains', 'resort', 'caucasus', 'outdoor']::text[]),
        ('bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 'nizhny-novgorod', 'ARCHITECTURE', 2, 'HOURS', 4.7, ARRAY['russia', 'nizhny-novgorod', 'kremlin', 'volga', 'oka', 'history', 'architecture']::text[]),
        ('0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 'yekaterinburg', 'MUSEUM', 2, 'HOURS', 4.6, ARRAY['russia', 'yekaterinburg', 'yeltsin-center', 'museum', 'history', 'modern-russia', 'culture']::text[]),
        ('918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 'vladivostok', 'ARCHITECTURE', 1, 'HOURS', 4.7, ARRAY['russia', 'vladivostok', 'russky-bridge', 'bridge', 'viewpoint', 'far-east', 'architecture']::text[]),
        ('22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 'vladivostok', 'ENTERTAINMENT', 3, 'HOURS', 4.6, ARRAY['russia', 'vladivostok', 'primorsky-oceanarium', 'aquarium', 'family', 'science', 'russky-island']::text[]),
        ('60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 'kaliningrad', 'ARCHITECTURE', 2, 'HOURS', 4.6, ARRAY['russia', 'kaliningrad', 'koenigsberg-cathedral', 'kant-island', 'organ', 'history', 'architecture']::text[]),
        ('8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 'kaliningrad', 'NATURE', 5, 'HOURS', 4.8, ARRAY['russia', 'kaliningrad', 'curonian-spit', 'national-park', 'dunes', 'baltic', 'nature']::text[]),
        ('cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 'volgograd', 'MUSEUM', 3, 'HOURS', 4.8, ARRAY['russia', 'volgograd', 'mamayev-kurgan', 'memorial', 'history', 'stalingrad', 'monument']::text[])
)
INSERT INTO attractions (
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
    seed_base.id,
    '21c40900-2090-43ca-b7f8-4bb962b2d275'::uuid,
    'ru',
    'RU',
    seed_base.city_id,
    seed_base.category,
    NULL::numeric,
    NULL::varchar(3),
    seed_base.duration_value,
    seed_base.duration_unit,
    seed_base.rating,
    0,
    NULL::int,
    'IMPORT',
    'PUBLISHED',
    seed_base.tags,
    NOW(),
    NOW()
FROM seed_base
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
WHERE attractions.source = 'IMPORT';

WITH seed_translations (
    attraction_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 'ru', 'Красная площадь', 'Главная историческая площадь Москвы рядом с Кремлем, собором Василия Блаженного и ГУМом. Это самая понятная первая точка маршрута по столице: архитектура, история, фото и вечерняя подсветка в одном месте.'),
        ('5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 'en', 'Red Square', 'The main historic square of Moscow beside the Kremlin, Saint Basil Cathedral and GUM. It is the clearest first stop in the capital, combining architecture, history, photos and evening lights in one place.'),
        ('5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 'kk', 'Қызыл алаң', 'Мәскеудің Кремль, Василий Блаженный соборы және ГУМ жанындағы басты тарихи алаңы. Елорданы танудың ең түсінікті алғашқы нүктесі: сәулет, тарих, фото және кешкі жарық бір жерде.'),

        ('e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 'ru', 'Третьяковская галерея', 'Ключевой музей русского искусства в Москве с иконами, классической живописью и работами XIX-XX веков. Хороший indoor-маршрут для тех, кто хочет понять культурный код страны без перегруженного темпа.'),
        ('e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 'en', 'Tretyakov Gallery', 'A key museum of Russian art in Moscow, with icons, classic painting and works from the nineteenth and twentieth centuries. It is a strong indoor route for travelers who want cultural context at a calm pace.'),
        ('e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 'kk', 'Третьяков галереясы', 'Мәскеудегі орыс өнерінің негізгі музейі: иконалар, классикалық кескіндеме және XIX-XX ғасыр туындылары. Елдің мәдени кодын асықпай түсінуге арналған жақсы жабық маршрут.'),

        ('de526545-792c-4c0e-86fe-f837f5085761'::uuid, 'ru', 'Парк Горького в Москве', 'Большой городской парк у Москвы-реки с набережной, прокатом, сезонными событиями и спокойными прогулочными зонами. Подходит для отдыха между музеями и плотной архитектурной программой.'),
        ('de526545-792c-4c0e-86fe-f837f5085761'::uuid, 'en', 'Gorky Park Moscow', 'A large city park by the Moskva River with embankments, rentals, seasonal events and relaxed walking areas. It is useful as a lighter stop between museums and architecture-heavy plans.'),
        ('de526545-792c-4c0e-86fe-f837f5085761'::uuid, 'kk', 'Мәскеудегі Горький паркі', 'Мәскеу өзені жағасындағы үлкен қалалық парк: жағалау, жалға алу нүктелері, маусымдық шаралар және тыныш серуен аймақтары бар. Музейлер мен сәулеттік бағдарлама арасында демалуға қолайлы.'),

        ('38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 'ru', 'ВДНХ', 'Большая выставочно-парковая территория Москвы с павильонами, фонтанами, музеями и семейными развлечениями. Удобна для маршрута на полдня, где можно совместить прогулку, архитектуру и легкий досуг.'),
        ('38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 'en', 'VDNKh', 'A large Moscow exhibition and park area with pavilions, fountains, museums and family entertainment. It works well for a half-day plan that combines walking, architecture and easy leisure.'),
        ('38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 'kk', 'ВДНХ', 'Мәскеудегі павильондары, субұрқақтары, музейлері және отбасылық демалысы бар үлкен көрме-парк аумағы. Серуен, сәулет және жеңіл демалысты біріктіретін жарты күндік жоспарға ыңғайлы.'),

        ('e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 'ru', 'Государственный Эрмитаж', 'Один из главных музеев мира в комплексе Зимнего дворца, где искусство, интерьеры и история Петербурга объединены в сильный культурный маршрут. Лучше закладывать несколько часов и выбирать приоритетные залы.'),
        ('e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 'en', 'State Hermitage Museum', 'One of the worlds major museums in the Winter Palace complex, where art, interiors and Saint Petersburg history form a deep cultural route. It is best to reserve several hours and choose priority halls.'),
        ('e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 'kk', 'Мемлекеттік Эрмитаж', 'Қысқы сарай кешеніндегі әлемдегі басты музейлердің бірі, мұнда өнер, интерьер және Санкт-Петербург тарихы терең мәдени маршрутқа бірігеді. Бірнеше сағат бөліп, басты залдарды алдын ала таңдаған дұрыс.'),

        ('fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 'ru', 'Петергоф', 'Дворцово-парковый ансамбль рядом с Санкт-Петербургом, знаменитый фонтанами, регулярными садами и видами на Финский залив. Это сильная выездная точка на полдня или полный день из города.'),
        ('fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 'en', 'Peterhof Museum-Reserve', 'A palace and park ensemble near Saint Petersburg, known for fountains, formal gardens and views of the Gulf of Finland. It is a strong half-day or full-day trip from the city.'),
        ('fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 'kk', 'Петергоф музей-қорығы', 'Санкт-Петербург маңындағы субұрқақтарымен, жүйелі бақтарымен және Фин шығанағы көріністерімен белгілі сарай-парк ансамблі. Қаладан жарты күндік немесе толық күндік сапарға мықты нүкте.'),

        ('d751994b-5412-4a5c-8d35-883a676c3932'::uuid, 'ru', 'Спас на Крови', 'Один из самых узнаваемых храмов Санкт-Петербурга с яркими фасадами и мозаиками. Хорошо подходит для короткой, но насыщенной остановки рядом с Невским проспектом и каналами.'),
        ('d751994b-5412-4a5c-8d35-883a676c3932'::uuid, 'en', 'Church of the Savior on Blood', 'One of the most recognizable churches in Saint Petersburg, with vivid facades and mosaics. It is a compact but rich stop near Nevsky Prospekt and the canals.'),
        ('d751994b-5412-4a5c-8d35-883a676c3932'::uuid, 'kk', 'Қан төгілген жерде Құтқарушы шіркеуі', 'Санкт-Петербургтің ең танымал ғибадатханаларының бірі, ашық қасбеттері мен мозаикаларымен белгілі. Невский даңғылы мен каналдар жанындағы қысқа әрі мазмұнды аялдама.'),

        ('8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 'ru', 'Новая Голландия', 'Островное городское пространство Петербурга с парком, кафе, событиями, детскими зонами и спокойной атмосферой. Хорошая легкая точка после музеев и прогулок по центру.'),
        ('8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 'en', 'New Holland Island', 'An island urban space in Saint Petersburg with a park, cafes, events, family zones and a relaxed atmosphere. It is a good light stop after museums and central walks.'),
        ('8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 'kk', 'Новая Голландия аралы', 'Санкт-Петербургтегі паркі, кафелері, оқиғалары, балалар аймақтары және тыныш атмосферасы бар аралдық қалалық кеңістік. Музейлер мен орталық серуеннен кейінгі жеңіл аялдама.'),

        ('e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 'ru', 'Казанский Кремль', 'Исторический комплекс Казани, где рядом находятся башни, музеи, мечеть Кул-Шариф и православные памятники. Это главная точка города для понимания татарской, русской и волжской истории.'),
        ('e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 'en', 'Kazan Kremlin', 'The historic core of Kazan, combining towers, museums, the Kul Sharif Mosque and Orthodox landmarks. It is the main city stop for understanding Tatar, Russian and Volga history.'),
        ('e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 'kk', 'Қазан Кремлі', 'Қазанның тарихи өзегі: мұнаралар, музейлер, Құл Шариф мешіті және православ ескерткіштері қатар орналасқан. Татар, орыс және Еділ тарихын түсінуге арналған басты қалалық нүкте.'),

        ('c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 'ru', 'Сочинский дендрарий', 'Зеленая классика Сочи с субтропическими растениями, прогулочными дорожками и видами с канатной дороги. Удобен для спокойной семейной прогулки без выезда далеко из города.'),
        ('c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 'en', 'Sochi Arboretum', 'A classic green stop in Sochi with subtropical plants, walking paths and cable car views. It is convenient for a calm family walk without going far from the city.'),
        ('c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 'kk', 'Сочи дендрарийі', 'Субтропикалық өсімдіктері, серуен жолдары және аспалы жол көріністері бар Сочидің классикалық жасыл орны. Қаладан алыс шықпай, тыныш отбасылық серуенге ыңғайлы.'),

        ('0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 'ru', 'Горный курорт Роза Хутор', 'Горный курорт в Красной Поляне с видами Кавказа, канатными дорогами, прогулками, зимним спортом и летними outdoor-маршрутами. Сильная точка для активного отдыха из Сочи.'),
        ('0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 'en', 'Rosa Khutor Mountain Resort', 'A mountain resort in Krasnaya Polyana with Caucasus views, cable cars, walking routes, winter sports and summer outdoor plans. It is a strong active leisure option from Sochi.'),
        ('0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 'kk', 'Роза Хутор тау курорты', 'Красная Полянадағы Кавказ көріністері, аспалы жолдары, серуен бағыттары, қысқы спорт және жазғы outdoor жоспарлары бар тау курорты. Сочиден белсенді демалысқа арналған мықты нүкте.'),

        ('bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 'ru', 'Нижегородский Кремль', 'Краснокирпичная крепость в историческом центре Нижнего Новгорода с видами на Волгу и Оку. Хорошая первая точка для прогулки по городу, где сразу понятны рельеф, история и панорамы.'),
        ('bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 'en', 'Nizhny Novgorod Kremlin', 'A red-brick fortress in the historic center of Nizhny Novgorod, with views over the Volga and Oka rivers. It is a strong first stop for understanding the city layout, history and panoramas.'),
        ('bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 'kk', 'Нижний Новгород Кремлі', 'Еділ мен Ока өзендеріне көрініс ашатын Нижний Новгородтың тарихи орталығындағы қызыл кірпішті бекініс. Қаланың бедерін, тарихын және панорамаларын түсінуге жақсы алғашқы нүкте.'),

        ('0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 'ru', 'Ельцин Центр', 'Современный музейно-культурный центр Екатеринбурга о новейшей истории России, городской культуре и общественных дискуссиях. Подходит для indoor-плана и более взрослого исторического маршрута.'),
        ('0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 'en', 'Yeltsin Center', 'A modern museum and cultural center in Yekaterinburg focused on recent Russian history, urban culture and public discussions. It works well for an indoor plan and a more mature historical route.'),
        ('0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 'kk', 'Ельцин орталығы', 'Екатеринбургтегі Ресейдің жаңа тарихына, қалалық мәдениетке және қоғамдық талқылауларға арналған заманауи музей-мәдени орталық. Жабық жоспарға және ересек тарихи маршрутқа қолайлы.'),

        ('918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 'ru', 'Русский мост', 'Вантовый мост Владивостока на остров Русский, который стал одним из главных визуальных символов города. Лучше всего воспринимается со смотровых точек и в маршрутах по бухтам.'),
        ('918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 'en', 'Russky Bridge', 'A cable-stayed bridge from Vladivostok to Russky Island and one of the main visual symbols of the city. It is best experienced from viewpoints and bay routes.'),
        ('918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 'kk', 'Русский көпірі', 'Владивостоктан Русский аралына өтетін вантты көпір және қаланың басты визуалды символдарының бірі. Оны қарау алаңдарынан және шығанақ маршруттарынан жақсы қабылдауға болады.'),

        ('22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 'ru', 'Приморский океанариум', 'Крупный океанариум на острове Русский с морскими экспозициями, образовательным форматом и семейным маршрутом. Хорошая точка для плохой погоды и поездки за пределы центра Владивостока.'),
        ('22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 'en', 'Primorsky Oceanarium', 'A large oceanarium on Russky Island with marine exhibits, educational content and a family-friendly route. It is useful for poor weather and trips beyond central Vladivostok.'),
        ('22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 'kk', 'Приморский океанариумы', 'Русский аралындағы теңіз экспозициялары, танымдық формат және отбасылық маршрут ұсынатын ірі океанариум. Ауа райы қолайсыз кезде және Владивосток орталығынан тыс сапарға ыңғайлы.'),

        ('60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 'ru', 'Кафедральный собор Калининграда', 'Исторический собор на острове Канта, связанный с архитектурой старого Кенигсберга, органными концертами и городскими прогулками. Компактная культурная точка в центре Калининграда.'),
        ('60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 'en', 'Koenigsberg Cathedral', 'A historic cathedral on Kant Island, connected with old Koenigsberg architecture, organ concerts and central city walks. It is a compact cultural stop in Kaliningrad.'),
        ('60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 'kk', 'Калининград кафедралды соборы', 'Кант аралындағы ескі Кенигсберг сәулетімен, орган концерттерімен және қала серуенімен байланысты тарихи собор. Калининград орталығындағы ықшам мәдени нүкте.'),

        ('8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 'ru', 'Куршская коса', 'Балтийский природный маршрут Калининградской области с дюнами, лесами, пляжами и необычным ландшафтом между морем и заливом. Лучше подходит для поездки на полдня или полный день.'),
        ('8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 'en', 'Curonian Spit', 'A Baltic nature route in Kaliningrad Oblast with dunes, forests, beaches and a distinctive landscape between the sea and the lagoon. It is best planned as a half-day or full-day trip.'),
        ('8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 'kk', 'Курш түбегі', 'Калининград облысындағы Балтық табиғи бағыты: құм төбелері, ормандар, жағажайлар және теңіз бен шығанақ арасындағы ерекше ландшафт. Жарты күндік немесе толық күндік сапарға жақсы.'),

        ('cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 'ru', 'Мамаев курган', 'Мемориальный комплекс Волгограда, связанный с историей Сталинградской битвы и монументом Родина-мать зовет. Это сильная историческая точка, требующая спокойного и уважительного темпа.'),
        ('cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 'en', 'Mamayev Kurgan', 'A memorial complex in Volgograd connected with the Battle of Stalingrad and The Motherland Calls monument. It is a powerful historical stop that needs a calm and respectful pace.'),
        ('cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 'kk', 'Мамаев қорғаны', 'Сталинград шайқасы тарихымен және Отан-ана шақырады монументімен байланысты Волгоградтағы мемориалдық кешен. Тыныш әрі құрметті қарқын қажет ететін күшті тарихи нүкте.')
)
INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    seed_translations.attraction_id,
    seed_translations.locale,
    seed_translations.title,
    seed_translations.description,
    NOW(),
    NOW()
FROM seed_translations
ON CONFLICT (attraction_id, locale) DO UPDATE
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
    VALUES
        ('5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 55.7539, 37.6208, 'https://www.openstreetmap.org/search?query=Red%20Square%20Moscow'),
        ('e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 55.7415, 37.6208, 'https://www.openstreetmap.org/search?query=Tretyakov%20Gallery%20Moscow'),
        ('de526545-792c-4c0e-86fe-f837f5085761'::uuid, 55.7298, 37.6030, 'https://www.openstreetmap.org/search?query=Gorky%20Park%20Moscow'),
        ('38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 55.8298, 37.6325, 'https://www.openstreetmap.org/search?query=VDNKh%20Moscow'),
        ('e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 59.9398, 30.3146, 'https://www.openstreetmap.org/search?query=State%20Hermitage%20Museum%20Saint%20Petersburg'),
        ('fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 59.8845, 29.9080, 'https://www.openstreetmap.org/search?query=Peterhof%20Palace'),
        ('d751994b-5412-4a5c-8d35-883a676c3932'::uuid, 59.9400, 30.3287, 'https://www.openstreetmap.org/search?query=Church%20of%20the%20Savior%20on%20Blood'),
        ('8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 59.9290, 30.2894, 'https://www.openstreetmap.org/search?query=New%20Holland%20Island%20Saint%20Petersburg'),
        ('e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 55.7998, 49.1066, 'https://www.openstreetmap.org/search?query=Kazan%20Kremlin'),
        ('c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 43.5686, 39.7413, 'https://www.openstreetmap.org/search?query=Sochi%20Arboretum'),
        ('0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 43.6727, 40.2975, 'https://www.openstreetmap.org/search?query=Rosa%20Khutor%20Sochi'),
        ('bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 56.3287, 44.0020, 'https://www.openstreetmap.org/search?query=Nizhny%20Novgorod%20Kremlin'),
        ('0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 56.8441, 60.5915, 'https://www.openstreetmap.org/search?query=Yeltsin%20Center%20Yekaterinburg'),
        ('918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 43.0631, 131.9004, 'https://www.openstreetmap.org/search?query=Russky%20Bridge%20Vladivostok'),
        ('22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 43.0113, 131.9238, 'https://www.openstreetmap.org/search?query=Primorsky%20Oceanarium%20Vladivostok'),
        ('60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 54.7064, 20.5113, 'https://www.openstreetmap.org/search?query=Koenigsberg%20Cathedral%20Kaliningrad'),
        ('8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 55.1667, 20.8500, 'https://www.openstreetmap.org/search?query=Curonian%20Spit%20Kaliningrad'),
        ('cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 48.7422, 44.5360, 'https://www.openstreetmap.org/search?query=Mamayev%20Kurgan%20Volgograd')
)
UPDATE attractions
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE attractions.id = seed_locations.id
    AND attractions.source = 'IMPORT';

WITH curated_media (
    id,
    attraction_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('33000000-0000-4000-8000-000000000001'::uuid, '5d5ebfed-9a11-4b17-8710-85e08c8eb9bd'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/e/ee/Kremlin_and_Red_Square.1.jpg', 'https://en.wikipedia.org/wiki/Red_Square', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000002'::uuid, 'e7891871-76f9-443e-8bef-176277bdd3be'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Moscow_05-2012_TretyakovGallery.jpg/3840px-Moscow_05-2012_TretyakovGallery.jpg', 'https://en.wikipedia.org/wiki/Tretyakov_Gallery', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000003'::uuid, 'de526545-792c-4c0e-86fe-f837f5085761'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Moscow_Gorky_Park_main_portal_08-2016_img1.jpg/3840px-Moscow_Gorky_Park_main_portal_08-2016_img1.jpg', 'https://en.wikipedia.org/wiki/Gorky_Park_(Moscow)', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000004'::uuid, '38ea9d41-97be-4d8f-b094-cf5531df72c2'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/VDNKh%20Main%20Entrance%20Arch%201.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:VDNKh_Main_Entrance_Arch_1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000005'::uuid, 'e8a575ba-7601-4dff-b166-91a6ced0c519'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/1/16/5174-3._St._Petersburg._Greater_Hermitage.jpg', 'https://en.wikipedia.org/wiki/Hermitage_Museum', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000006'::uuid, 'fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/3/36/Peterhof_Palace%2C_Saint_Petersburg%2C_Russia_%2844408938295%29.jpg', 'https://en.wikipedia.org/wiki/Peterhof_Palace', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000007'::uuid, 'd751994b-5412-4a5c-8d35-883a676c3932'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Auferstehungskirche_%28Sankt_Petersburg%29.JPG/3840px-Auferstehungskirche_%28Sankt_Petersburg%29.JPG', 'https://en.wikipedia.org/wiki/Church_of_the_Savior_on_Blood', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000008'::uuid, '8c3f6b2e-5300-4dda-803c-6925926eea0d'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Spb_06-2017_img33_New_Holland.jpg/3840px-Spb_06-2017_img33_New_Holland.jpg', 'https://en.wikipedia.org/wiki/New_Holland_Island', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000009'::uuid, 'e7adb0e1-4533-4717-a651-8aa4dfa25b16'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/b/b3/%D0%9A%D0%B0%D0%B7%D0%B0%D0%BD%D1%81%D0%BA%D0%B8%D0%B9_%D0%BA%D1%80%D0%B5%D0%BC%D0%BB%D1%8C._%D0%9F%D0%B0%D0%BD%D0%BE%D1%80%D0%B0%D0%BC%D0%B0_%D1%81_%D0%BA%D0%BE%D0%BB%D0%B5%D1%81%D0%B0_%D0%BE%D0%B1%D0%BE%D0%B7%D1%80%D0%B5%D0%BD%D0%B8%D1%8F.jpg', 'https://en.wikipedia.org/wiki/Kazan_Kremlin', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000010'::uuid, 'c719ca75-9b21-45e9-b34e-51bfaad2b1eb'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Dendrarium_Sochi_Mauritanian_arbour.jpg', 'https://en.wikipedia.org/wiki/Sochi_Arboretum', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000011'::uuid, '0523f916-2f45-4ccc-9bbc-f55aae4db530'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Rosa%20Khutor%20alpine%20resort.JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:Rosa_Khutor_alpine_resort.JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000012'::uuid, 'bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Nizhny%20Novgorod%20Kremlin.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Nizhny_Novgorod_Kremlin.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000013'::uuid, '0950a134-fee3-4dbf-93f3-d226c816872e'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/Yekaterinburg._Yeltsin_Center._2021.jpg/3840px-Yekaterinburg._Yeltsin_Center._2021.jpg', 'https://en.wikipedia.org/wiki/Boris_Yeltsin_Presidential_Center', 'Wikimedia contributors', 'See Wikimedia source page'),
        ('33000000-0000-4000-8000-000000000014'::uuid, '918a79bf-7734-4c69-b7e0-794db0c557d0'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Russki%20Island%20Bridge,%20Russia1.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Russki_Island_Bridge,_Russia1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000015'::uuid, '22976b07-8e74-49ae-88c3-4a7bde1284c9'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Primorskiy%20Oceanarium%20%28October%202024%29-1.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Primorskiy_Oceanarium_(October_2024)-1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000016'::uuid, '60dd38a5-6c88-47f3-9399-0c475d0a0750'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Koenigsberg%20Cathedral%20-%20panoramio.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Koenigsberg_Cathedral_-_panoramio.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000017'::uuid, '8485cd1c-d85f-416b-a1f1-6b6463ef0714'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Curonian%20Spit1.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Curonian_Spit1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('33000000-0000-4000-8000-000000000018'::uuid, 'cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/The%20Motherland%20Calls%20and%20All%20Saints%20church%20on%20Mamayev%20Kurgan.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:The_Motherland_Calls_and_All_Saints_church_on_Mamayev_Kurgan.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
INSERT INTO attraction_media (
    id,
    attraction_id,
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
    curated_media.id,
    curated_media.attraction_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    curated_media.external_url,
    curated_media.source_url,
    curated_media.credit,
    curated_media.license,
    'PHOTO',
    0,
    NOW()
FROM curated_media
WHERE EXISTS (
    SELECT 1
    FROM attractions a
    WHERE a.id = curated_media.attraction_id
)
ON CONFLICT (id) DO UPDATE
SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;

INSERT INTO attraction_city_links (id, attraction_id, kind, country_code, city_id, position, created_at)
SELECT gen_random_uuid(), id, kind, UPPER(country_code), city_id, 0, NOW()
FROM attractions
CROSS JOIN (VALUES ('ACCESS'), ('DEPARTURE')) AS link(kind)
WHERE id IN (
    '5d5ebfed-9a11-4b17-8710-85e08c8eb9bd',
    'e7891871-76f9-443e-8bef-176277bdd3be',
    'de526545-792c-4c0e-86fe-f837f5085761',
    '38ea9d41-97be-4d8f-b094-cf5531df72c2',
    'e8a575ba-7601-4dff-b166-91a6ced0c519',
    'fc20e31e-1fe7-4945-bb6e-1bd5b9b24a7e',
    'd751994b-5412-4a5c-8d35-883a676c3932',
    '8c3f6b2e-5300-4dda-803c-6925926eea0d',
    'e7adb0e1-4533-4717-a651-8aa4dfa25b16',
    'c719ca75-9b21-45e9-b34e-51bfaad2b1eb',
    '0523f916-2f45-4ccc-9bbc-f55aae4db530',
    'bc9dffeb-7a16-4ee7-8e23-4c2a65dabe6b',
    '0950a134-fee3-4dbf-93f3-d226c816872e',
    '918a79bf-7734-4c69-b7e0-794db0c557d0',
    '22976b07-8e74-49ae-88c3-4a7bde1284c9',
    '60dd38a5-6c88-47f3-9399-0c475d0a0750',
    '8485cd1c-d85f-416b-a1f1-6b6463ef0714',
    'cf5d37e3-9fb7-4bf1-b8f1-73098af22c48'
)
ON CONFLICT (attraction_id, kind, city_id) DO NOTHING;
