-- Seed Russia visit-planning details from the 2026 attractions workbook.
CREATE TEMP TABLE seed_russia_visit_planning (
    title_ru text PRIMARY KEY,
    price_amount numeric NULL,
    visit_info jsonb NOT NULL
);

INSERT INTO seed_russia_visit_planning (title_ru, price_amount, visit_info)
VALUES
    ('Красная площадь', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10,
                        12,
                        1
                ],
                "note": {
                        "ru": "апрель-октябрь; раннее утро или вечер; декабрь-январь ради подсветки",
                        "en": "April-October; early morning or evening; December-January for lights",
                        "kk": "Сәуір-қазан; ерте таң немесе кеш; желтоқсан-қаңтар жарық үшін"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "обычно свободный доступ; возможны закрытия на парады, репетиции и крупные события",
                        "en": "Usually open access; closures are possible for parades, rehearsals and major events",
                        "kk": "Әдетте еркін кіру; парад, дайындық және ірі шара кезінде жабылуы мүмкін"
                }
        },
        "priceNote": {
                "ru": "Свободный проход; Мавзолей бесплатный по отдельному графику; музеи Кремля оплачиваются отдельно.",
                "en": "Free public access; the Mausoleum is free on its own schedule; Kremlin museums are paid separately.",
                "kk": "Қоғамдық кіру тегін; Мавзолей жеке кестемен тегін; Кремль музейлері бөлек төленеді."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1-2 h",
                        "kk": "1-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин от центра Москвы",
                        "en": "10-25 min from central Moscow",
                        "kk": "Мәскеу орталығынан 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный проход; Мавзолей бесплатный по отдельному графику; музеи Кремля оплачиваются отдельно.",
                                "en": "Free public access; the Mausoleum is free on its own schedule; Kremlin museums are paid separately.",
                                "kk": "Қоғамдық кіру тегін; Мавзолей жеке кестемен тегін; Кремль музейлері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Свободный проход; Мавзолей бесплатный по отдельному графику; музеи Кремля оплачиваются отдельно.",
                                "en": "Free public access; the Mausoleum is free on its own schedule; Kremlin museums are paid separately.",
                                "kk": "Қоғамдық кіру тегін; Мавзолей жеке кестемен тегін; Кремль музейлері бөлек төленеді."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Кремлевские музеи, события и парковка оплачиваются отдельно при выборе таких опций.",
                                "en": "Kremlin museums, events and parking are paid separately when chosen.",
                                "kk": "Кремль музейлері, іс-шаралар және тұрақ таңдалса бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Кремлевские музеи, события и парковка оплачиваются отдельно при выборе таких опций.",
                                "en": "Kremlin museums, events and parking are paid separately when chosen.",
                                "kk": "Кремль музейлері, іс-шаралар және тұрақ таңдалса бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный проход; Мавзолей бесплатный по отдельному графику; музеи Кремля оплачиваются отдельно.",
                                "en": "Free public access; the Mausoleum is free on its own schedule; Kremlin museums are paid separately.",
                                "kk": "Қоғамдық кіру тегін; Мавзолей жеке кестемен тегін; Кремль музейлері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Кремлевские музеи, события и парковка оплачиваются отдельно при выборе таких опций.",
                                "en": "Kremlin museums, events and parking are paid separately when chosen.",
                                "kk": "Кремль музейлері, іс-шаралар және тұрақ таңдалса бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "от центра Москвы; парковка сложная, удобнее метро или такси",
                                "en": "from central Moscow; parking is difficult, metro or taxi is easier",
                                "kk": "Мәскеу орталығынан; тұрақ қиын, метро немесе такси ыңғайлы"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "парковка в центре сложная",
                                "en": "central parking is difficult",
                                "kk": "орталықта тұрақ қиын"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "проверяйте перекрытия; брусчатка неудобна с чемоданами и тонкими каблуками",
                                "en": "Check closures; cobblestones are awkward with suitcases and thin heels",
                                "kk": "жабылуларды тексеріңіз; тас төсем чемоданмен және жіңішке өкшемен ыңғайсыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 40
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Power bank",
                                "en": "Power bank",
                                "kk": "Пауэрбанк"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Мамаев курган', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        9,
                        10
                ],
                "note": {
                        "ru": "апрель-июнь и сентябрь-октябрь; 9 мая символично, но очень многолюдно",
                        "en": "April-June and September-October; May 9 is symbolic but very crowded",
                        "kk": "Сәуір-маусым және қыркүйек-қазан; 9 мамыр мәнді, бірақ адам көп"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "мемориал открыт круглосуточно; экскурсии обычно ежедневно 10:00-15:30",
                        "en": "Memorial is open around the clock; tours are usually daily 10:00-15:30",
                        "kk": "Мемориал тәулік бойы ашық; экскурсиялар әдетте күн сайын 10:00-15:30"
                }
        },
        "priceNote": {
                "ru": "Самостоятельное посещение бесплатно; экскурсия примерно от 600 ₽ за человека или от 4 000 ₽ за группу.",
                "en": "Self-guided visit is free; guided tour is roughly from 600 RUB per person or from 4,000 RUB per group.",
                "kk": "Өз бетімен бару тегін; экскурсия шамамен адамға 600 RUB-дан немесе топқа 4 000 RUB-дан басталады."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин от центра Волгограда",
                        "en": "10-25 min from central Volgograd",
                        "kk": "Волгоград орталығынан 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Самостоятельное посещение мемориала бесплатно.",
                                "en": "Self-guided memorial visit is free.",
                                "kk": "Мемориалды өз бетімен көру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Самостоятельное посещение мемориала бесплатно.",
                                "en": "Self-guided memorial visit is free.",
                                "kk": "Мемориалды өз бетімен көру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия примерно от 600 ₽ за человека; групповая программа от 4 000 ₽.",
                                "en": "Guided tour roughly from 600 RUB per person; group program from 4,000 RUB.",
                                "kk": "Экскурсия шамамен адамға 600 RUB-дан; топтық бағдарлама 4 000 RUB-дан."
                        },
                        "minAmount": 600,
                        "maxAmount": 4000,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Экскурсия примерно от 600 ₽ за человека; групповая программа от 4 000 ₽.",
                                "en": "Guided tour roughly from 600 RUB per person; group program from 4,000 RUB.",
                                "kk": "Экскурсия шамамен адамға 600 RUB-дан; топтық бағдарлама 4 000 RUB-дан."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Самостоятельное посещение мемориала бесплатно.",
                                "en": "Self-guided memorial visit is free.",
                                "kk": "Мемориалды өз бетімен көру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия примерно от 600 ₽ за человека; групповая программа от 4 000 ₽.",
                                "en": "Guided tour roughly from 600 RUB per person; group program from 4,000 RUB.",
                                "kk": "Экскурсия шамамен адамға 600 RUB-дан; топтық бағдарлама 4 000 RUB-дан."
                        },
                        "amount": 600,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "от центра Волгограда к подъездам у подножия мемориала",
                                "en": "from central Volgograd to the access points below the memorial",
                                "kk": "Волгоград орталығынан мемориал етегіндегі кіреберістерге"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "парковки зависят от мероприятий",
                                "en": "parking depends on events",
                                "kk": "тұрақ іс-шараларға байланысты"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "много ступеней и открытых пространств; летом жарко, зимой ветрено",
                                "en": "Many stairs and open spaces; hot in summer and windy in winter",
                                "kk": "саты көп және ашық кеңістік бар; жазда ыстық, қыста желді"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Дудергофские высоты', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-октябрь; апрель ради первоцветов; зимой только с хорошей обувью",
                        "en": "May-October; April for spring flowers; winter only with good footwear",
                        "kk": "Мамыр-қазан; сәуірде алғашқы гүлдер; қыста тек жақсы аяқ киіммен"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "свободный доступ в светлое время; после дождя и гололеда лучше не идти",
                        "en": "Free access in daylight; avoid after heavy rain or ice",
                        "kk": "Күндіз еркін кіру; қатты жаңбырдан немесе көктайғақтан кейін бармаған дұрыс"
                }
        },
        "priceNote": {
                "ru": "Вход свободный; оборудованная экотропа около 3 км, кассы нет.",
                "en": "Free entry; the marked eco-trail is about 3 km and has no ticket office.",
                "kk": "Кіру тегін; жабдықталған экосоқпақ шамамен 3 км, касса жоқ."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1.5-3 ч",
                        "en": "1.5-3 h",
                        "kk": "1,5-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 75,
                "note": {
                        "ru": "45-75 мин из центра Санкт-Петербурга",
                        "en": "45-75 min from central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығынан 45-75 мин"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; оборудованная экотропа около 3 км, кассы нет.",
                                "en": "Free entry; the marked eco-trail is about 3 km and has no ticket office.",
                                "kk": "Кіру тегін; жабдықталған экосоқпақ шамамен 3 км, касса жоқ."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход свободный; оборудованная экотропа около 3 км, кассы нет.",
                                "en": "Free entry; the marked eco-trail is about 3 km and has no ticket office.",
                                "kk": "Кіру тегін; жабдықталған экосоқпақ шамамен 3 км, касса жоқ."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; оборудованная экотропа около 3 км, кассы нет.",
                                "en": "Free entry; the marked eco-trail is about 3 km and has no ticket office.",
                                "kk": "Кіру тегін; жабдықталған экосоқпақ шамамен 3 км, касса жоқ."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 75,
                        "routeHint": {
                                "ru": "из центра Санкт-Петербурга через Красное Село и Таллинское шоссе",
                                "en": "from central Saint Petersburg via Krasnoye Selo and Tallinn Highway",
                                "kk": "Санкт-Петербург орталығынан Красное Село және Таллин тас жолы арқылы"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "45-75 мин",
                                "en": "45-75 min",
                                "kk": "45-75 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "нельзя разводить костры, ставить палатки, собирать растения и парковаться вне разрешенных мест",
                                "en": "No fires, camping, plant picking or parking outside permitted areas",
                        "kk": "алау жағуға, шатыр тігуге, өсімдік жинауға және рұқсатсыз жерде тұрақтауға болмайды"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Треккинговая обувь",
                                "en": "Trekking shoes",
                                "kk": "Треккинг аяқ киімі"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Третьяковская галерея', 700, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; лучше будни утром или вечерние сеансы; зимой меньше людей",
                        "en": "Year-round; weekdays in the morning or evening slots are best; winter is quieter",
                        "kk": "Жыл бойы; жұмыс күндері таңертең немесе кешкі сеанс жақсы; қыста тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Лаврушинский переулок обычно Вт-Вс по сеансам, понедельник выходной; слоты проверять при покупке",
                        "en": "Lavrushinsky Lane is usually Tue-Sun by timed slots, Monday closed; check slots when buying",
                        "kk": "Лаврушинский тұйығы әдетте Сс-Жс уақыттық сеанспен, дүйсенбі жабық; сатып аларда слотты тексеріңіз"
                }
        },
        "priceNote": {
                "ru": "Взрослый билет на основную экспозицию около 700 ₽; льготы 0/350/400 ₽ по документам.",
                "en": "Adult ticket for the main exhibition is about 700 RUB; concessions are 0/350/400 RUB with documents.",
                "kk": "Негізгі экспозицияға ересек билет шамамен 700 RUB; жеңілдіктер құжатпен 0/350/400 RUB."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин от центра Москвы",
                        "en": "10-25 min from central Moscow",
                        "kk": "Мәскеу орталығынан 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Взрослый билет на основную экспозицию около 700 ₽; льготы 0/350/400 ₽ по документам.",
                                "en": "Adult ticket for the main exhibition is about 700 RUB; concessions are 0/350/400 RUB with documents.",
                                "kk": "Негізгі экспозицияға ересек билет шамамен 700 RUB; жеңілдіктер құжатпен 0/350/400 RUB."
                        },
                        "minAmount": 700,
                        "maxAmount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый билет на основную экспозицию около 700 ₽; льготы 0/350/400 ₽ по документам.",
                                "en": "Adult ticket for the main exhibition is about 700 RUB; concessions are 0/350/400 RUB with documents.",
                                "kk": "Негізгі экспозицияға ересек билет шамамен 700 RUB; жеңілдіктер құжатпен 0/350/400 RUB."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Взрослый билет на основную экспозицию около 700 ₽; льготы 0/350/400 ₽ по документам.",
                                "en": "Adult ticket for the main exhibition is about 700 RUB; concessions are 0/350/400 RUB with documents.",
                                "kk": "Негізгі экспозицияға ересек билет шамамен 700 RUB; жеңілдіктер құжатпен 0/350/400 RUB."
                        },
                        "amount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "от центра Москвы; парковка ограничена, лучше метро или такси",
                                "en": "from central Moscow; parking is limited, metro or taxi is easier",
                                "kk": "Мәскеу орталығынан; тұрақ шектеулі, метро немесе такси ыңғайлы"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "парковка ограничена",
                                "en": "parking is limited",
                                "kk": "тұрақ шектеулі"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "большие рюкзаки сдавать в гардероб или камеру хранения; билеты лучше покупать заранее",
                                "en": "Large backpacks go to cloakroom or lockers; buying tickets ahead is easier",
                                "kk": "үлкен рюкзакты гардеробқа немесе сақтау орнына тапсырыңыз; билетті алдын ала алған ыңғайлы"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "HEADPHONES",
                        "title": {
                                "ru": "Наушники",
                                "en": "Headphones",
                                "kk": "Құлаққап"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Небольшая сумка",
                                "en": "Small bag",
                                "kk": "Шағын сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Государственный Эрмитаж', 700, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни и зима спокойнее; май-сентябрь и праздники самые загруженные",
                        "en": "Year-round; weekdays and winter are quieter; May-September and holidays are busiest",
                        "kk": "Жыл бойы; жұмыс күндері және қыс тынышырақ; мамыр-қыркүйек пен мерекелер ең тығыз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Главный музейный комплекс: Вт/Пт/Сб 11:00-20:00, Ср/Чт/Вс 11:00-18:00, Пн выходной",
                        "en": "Main Museum Complex: Tue/Fri/Sat 11:00-20:00, Wed/Thu/Sun 11:00-18:00, Mon closed",
                        "kk": "Негізгі музей кешені: Сс/Жм/Сб 11:00-20:00, Ср/Бс/Жс 11:00-18:00, Дс жабық"
                }
        },
        "priceNote": {
                "ru": "Главный музейный комплекс 700 ₽; билет с открытой датой 1 200 ₽; дети до 14 лет обычно бесплатно.",
                "en": "Main Museum Complex is 700 RUB; open-date ticket is 1,200 RUB; children under 14 are usually free.",
                "kk": "Негізгі музей кешені 700 RUB; ашық күнді билет 1 200 RUB; 14 жасқа дейінгі балалар әдетте тегін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3-5 h",
                        "kk": "3-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин по центру Санкт-Петербурга",
                        "en": "10-25 min within central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығында 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Главный музейный комплекс 700 ₽.",
                                "en": "Main Museum Complex ticket is 700 RUB.",
                                "kk": "Негізгі музей кешеніне билет 700 RUB."
                        },
                        "minAmount": 700,
                        "maxAmount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Главный музейный комплекс 700 ₽.",
                                "en": "Main Museum Complex ticket is 700 RUB.",
                                "kk": "Негізгі музей кешеніне билет 700 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Билет с открытой датой около 1 200 ₽; отдельные программы могут оплачиваться отдельно.",
                                "en": "Open-date ticket is about 1,200 RUB; separate programs may cost extra.",
                                "kk": "Ашық күнді билет шамамен 1 200 RUB; жеке бағдарламалар бөлек төленуі мүмкін."
                        },
                        "minAmount": 1200,
                        "maxAmount": 1200,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Билет с открытой датой около 1 200 ₽; отдельные программы могут оплачиваться отдельно.",
                                "en": "Open-date ticket is about 1,200 RUB; separate programs may cost extra.",
                                "kk": "Ашық күнді билет шамамен 1 200 RUB; жеке бағдарламалар бөлек төленуі мүмкін."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Главный музейный комплекс 700 ₽.",
                                "en": "Main Museum Complex ticket is 700 RUB.",
                                "kk": "Негізгі музей кешеніне билет 700 RUB."
                        },
                        "amount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Билет с открытой датой около 1 200 ₽; отдельные программы могут оплачиваться отдельно.",
                                "en": "Open-date ticket is about 1,200 RUB; separate programs may cost extra.",
                                "kk": "Ашық күнді билет шамамен 1 200 RUB; жеке бағдарламалар бөлек төленуі мүмкін."
                        },
                        "amount": 1200,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "по центру Санкт-Петербурга; парковка ограничена",
                                "en": "within central Saint Petersburg; parking is limited",
                                "kk": "Санкт-Петербург орталығында; тұрақ шектеулі"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "парковка ограничена",
                                "en": "parking is limited",
                                "kk": "тұрақ шектеулі"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "планируйте маршрут заранее: за один визит весь музей не посмотреть",
                                "en": "Plan halls ahead; the whole museum is impossible in one visit",
                                "kk": "залдарды алдын ала жоспарлаңыз; бүкіл музейді бір барғанда көру мүмкін емес"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Небольшая сумка",
                                "en": "Small bag",
                                "kk": "Шағын сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Петергоф', 1100, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-сентябрь/октябрь - сезон фонтанов; лучше будни и утро",
                        "en": "May-September/October for fountains; weekdays and morning are best",
                        "kk": "Мамыр-қыркүйек/қазан - субұрқақ маусымы; жұмыс күндері және таң жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Нижний парк 09:00-20:00, вход до 19:45; фонтаны 10:00-19:45; кассы до 19:30",
                        "en": "Lower Park 09:00-20:00, entry until 19:45; fountains 10:00-19:45; ticket offices until 19:30",
                        "kk": "Төменгі парк 09:00-20:00, кіру 19:45-ке дейін; субұрқақтар 10:00-19:45; касса 19:30-ға дейін"
                }
        },
        "priceNote": {
                "ru": "Нижний парк 1 100 ₽ для РФ/ЕАЭС; полная цена без льгот 2 500 ₽; отдельные дворцы оплачиваются отдельно.",
                "en": "Lower Park is 1,100 RUB for Russia/EAEU visitors; full non-concession price is 2,500 RUB; palaces are paid separately.",
                "kk": "Төменгі парк Ресей/ЕАЭО келушілеріне 1 100 RUB; жеңілдіксіз толық баға 2 500 RUB; сарайлар бөлек төленеді."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 360,
                "note": {
                        "ru": "3-6 ч",
                        "en": "3-6 h",
                        "kk": "3-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 80,
                "note": {
                        "ru": "45-80 мин из центра Санкт-Петербурга",
                        "en": "45-80 min from central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығынан 45-80 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Нижний парк и фонтаны в рабочее время: 1 100 ₽ для РФ/ЕАЭС.",
                                "en": "Lower Park and fountains during operating hours: 1,100 RUB for Russia/EAEU visitors.",
                                "kk": "Жұмыс уақытындағы Төменгі парк пен субұрқақтар: Ресей/ЕАЭО келушілеріне 1 100 RUB."
                        },
                        "minAmount": 1100,
                        "maxAmount": 1100,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Нижний парк и фонтаны в рабочее время: 1 100 ₽ для РФ/ЕАЭС.",
                                "en": "Lower Park and fountains during operating hours: 1,100 RUB for Russia/EAEU visitors.",
                                "kk": "Жұмыс уақытындағы Төменгі парк пен субұрқақтар: Ресей/ЕАЭО келушілеріне 1 100 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Полная цена без льгот около 2 500 ₽; дворцы и отдельные музеи оплачиваются отдельно.",
                                "en": "Full non-concession price is about 2,500 RUB; palaces and separate museums cost extra.",
                                "kk": "Жеңілдіксіз толық баға шамамен 2 500 RUB; сарайлар мен бөлек музейлер қосымша төленеді."
                        },
                        "minAmount": 2500,
                        "maxAmount": 2500,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Полная цена без льгот около 2 500 ₽; дворцы и отдельные музеи оплачиваются отдельно.",
                                "en": "Full non-concession price is about 2,500 RUB; palaces and separate museums cost extra.",
                                "kk": "Жеңілдіксіз толық баға шамамен 2 500 RUB; сарайлар мен бөлек музейлер қосымша төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Нижний парк и фонтаны в рабочее время: 1 100 ₽ для РФ/ЕАЭС.",
                                "en": "Lower Park and fountains during operating hours: 1,100 RUB for Russia/EAEU visitors.",
                                "kk": "Жұмыс уақытындағы Төменгі парк пен субұрқақтар: Ресей/ЕАЭО келушілеріне 1 100 RUB."
                        },
                        "amount": 1100,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Полная цена без льгот около 2 500 ₽; дворцы и отдельные музеи оплачиваются отдельно.",
                                "en": "Full non-concession price is about 2,500 RUB; palaces and separate museums cost extra.",
                                "kk": "Жеңілдіксіз толық баға шамамен 2 500 RUB; сарайлар мен бөлек музейлер қосымша төленеді."
                        },
                        "amount": 2500,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 80,
                        "routeHint": {
                                "ru": "из центра Санкт-Петербурга в Петергоф; время зависит от пробок и парковки",
                                "en": "from central Saint Petersburg to Peterhof; time depends on traffic and parking",
                                "kk": "Санкт-Петербург орталығынан Петергофқа; уақыт кептеліс пен тұраққа байланысты"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "45-80 мин",
                                "en": "45-80 min",
                                "kk": "45-80 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "летом парковки быстро заполняются",
                                "en": "parking fills quickly in summer",
                                "kk": "жазда тұрақ тез толады"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "отдельные дворцы и музеи оплачиваются отдельно; летом в выходные очень людно",
                                "en": "Separate palaces and museums cost extra; summer weekends are very crowded",
                                "kk": "жеке сарайлар мен музейлер бөлек төленеді; жазғы демалыста адам өте көп"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "FOOD",
                        "title": {
                                "ru": "Перекус",
                                "en": "Snack",
                                "kk": "Жеңіл тамақ"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Куршская коса', 400, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-сентябрь; апрель и октябрь спокойнее, но ветренее",
                        "en": "May-September; April and October are quieter but windier",
                        "kk": "Мамыр-қыркүйек; сәуір мен қазан тынышырақ, бірақ желдірек"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "въезд по электронному билету или на КПП; маршруты лучше проходить засветло",
                        "en": "Entry by e-ticket or checkpoint; routes are best done in daylight",
                        "kk": "электрондық билетпен немесе бекет арқылы кіру; маршруттарды күндіз өткен дұрыс"
                }
        },
        "priceNote": {
                "ru": "Разовое разрешение 400 ₽ с человека; дети до 18 лет и льготники бесплатно при документе.",
                "en": "One-time permit is 400 RUB per person; children under 18 and eligible visitors are free with documents.",
                "kk": "Бір реттік рұқсат адамға 400 RUB; 18 жасқа дейінгі балалар және жеңілдігі бар келушілер құжатпен тегін."
        },
        "timeOnSite": {
                "minMinutes": 240,
                "maxMinutes": 480,
                "note": {
                        "ru": "4-8 ч",
                        "en": "4-8 h",
                        "kk": "4-8 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 120,
                "note": {
                        "ru": "45-60 мин до КПП; 1.5-2 ч до дальней части косы",
                        "en": "45-60 min to checkpoint; 1.5-2 h to the far end of the spit",
                        "kk": "Бекетке 45-60 мин; түбектің алыс бөлігіне 1,5-2 сағ"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовое разрешение 400 ₽ с человека; дети до 18 лет и льготники бесплатно при документе.",
                                "en": "One-time permit is 400 RUB per person; children under 18 and eligible visitors are free with documents.",
                                "kk": "Бір реттік рұқсат адамға 400 RUB; 18 жасқа дейінгі балалар және жеңілдігі бар келушілер құжатпен тегін."
                        },
                        "minAmount": 400,
                        "maxAmount": 400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Разовое разрешение 400 ₽ с человека; дети до 18 лет и льготники бесплатно при документе.",
                                "en": "One-time permit is 400 RUB per person; children under 18 and eligible visitors are free with documents.",
                                "kk": "Бір реттік рұқсат адамға 400 RUB; 18 жасқа дейінгі балалар және жеңілдігі бар келушілер құжатпен тегін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовое разрешение 400 ₽ с человека; дети до 18 лет и льготники бесплатно при документе.",
                                "en": "One-time permit is 400 RUB per person; children under 18 and eligible visitors are free with documents.",
                                "kk": "Бір реттік рұқсат адамға 400 RUB; 18 жасқа дейінгі балалар және жеңілдігі бар келушілер құжатпен тегін."
                        },
                        "amount": 400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 120,
                        "routeHint": {
                                "ru": "Калининград - КПП - маршруты Куршской косы",
                                "en": "Kaliningrad - checkpoint - Curonian Spit routes",
                                "kk": "Калининград - бекет - Курш түбегі бағыттары"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "45-120 мин",
                                "en": "45-120 min",
                                "kk": "45-120 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "в сезон возможны очереди и проблемы с парковкой",
                                "en": "queues and parking pressure are possible in season",
                                "kk": "маусымда кезек және тұрақ қиындығы болуы мүмкін"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "не сходить с настилов на дюнах; в сезон закладывать время на въезд и парковку",
                                "en": "Stay on dune boardwalks; in season allow time for entry and parking",
                                "kk": "құм төбедегі төсеніштен шықпаңыз; маусымда кіру мен тұраққа уақыт қалдырыңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 40
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 60
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Тропа Бердских скал', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-октябрь; зимой только с нескользящей обувью или кошками",
                        "en": "May-October; winter only with anti-slip footwear or spikes",
                        "kk": "Мамыр-қазан; қыста тек таймайтын аяқ киіммен немесе тікенмен"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "круглогодично, безопаснее в светлое время; после дождя и зимой скользко",
                        "en": "Year-round, safer in daylight; slippery after rain and in winter",
                        "kk": "Жыл бойы, күндіз қауіпсіз; жаңбырдан кейін және қыста тайғақ"
                }
        },
        "priceNote": {
                "ru": "Свободный доступ; официальной кассы на тропе нет.",
                "en": "Free access; there is no official ticket office on the trail.",
                "kk": "Еркін кіру; соқпақта ресми касса жоқ."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 120,
                "maxMinutes": 150,
                "note": {
                        "ru": "2-2.5 ч от Новосибирска",
                        "en": "2-2.5 h from Novosibirsk",
                        "kk": "Новосибирскіден 2-2,5 сағ"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный доступ; официальной кассы на тропе нет.",
                                "en": "Free access; there is no official ticket office on the trail.",
                                "kk": "Еркін кіру; соқпақта ресми касса жоқ."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Свободный доступ; официальной кассы на тропе нет.",
                                "en": "Free access; there is no official ticket office on the trail.",
                                "kk": "Еркін кіру; соқпақта ресми касса жоқ."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный доступ; официальной кассы на тропе нет.",
                                "en": "Free access; there is no official ticket office on the trail.",
                                "kk": "Еркін кіру; соқпақта ресми касса жоқ."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 120,
                        "durationMaxMinutes": 150,
                        "routeHint": {
                                "ru": "Новосибирск - Новососедово - район Легостаевского заказника",
                                "en": "Novosibirsk - Novososedovo - Legostayevsky reserve area",
                                "kk": "Новосибирск - Новососедово - Легостаевский қорықшасы маңы"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "2-2.5 ч",
                                "en": "2-2.5 h",
                                "kk": "2-2,5 сағ"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "не подходить к краю скал в дождь или ветер; не повреждать мхи и растения",
                                "en": "Avoid cliff edges in rain or wind; do not damage mosses and plants",
                                "kk": "жаңбырда немесе желде жар шетіне жақындамаңыз; мүк пен өсімдікті бүлдірмеңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Треккинговая обувь",
                                "en": "Trekking shoes",
                                "kk": "Треккинг аяқ киімі"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20,
                        "note": {
                                "ru": "1-1.5 л воды",
                                "en": "1-1.5 L of water",
                                "kk": "1-1,5 л су"
                        }
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "FIRST_AID",
                        "title": {
                                "ru": "Аптечка",
                                "en": "First aid kit",
                                "kk": "Алғашқы көмек қобдишасы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Природная тропа Птичьей гавани', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "апрель-октябрь; весна и осень интересны миграцией птиц",
                        "en": "April-October; spring and autumn are good for bird migration",
                        "kk": "Сәуір-қазан; көктем мен күз құс көші үшін қызық"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "парк указан как круглосуточный; безопаснее и интереснее в светлое время",
                        "en": "Park is listed as open around the clock; daylight is safer and more interesting",
                        "kk": "Парк тәулік бойы ашық деп көрсетілген; күндіз қауіпсіз әрі қызығырақ"
                }
        },
        "priceNote": {
                "ru": "Вход свободный; экотропа По следам пернатых около 3 км.",
                "en": "Free entry; the bird-themed eco-trail is about 3 km.",
                "kk": "Кіру тегін; құстарға арналған экосоқпақ шамамен 3 км."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1-2 h",
                        "kk": "1-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин от центра Омска",
                        "en": "10-20 min from central Omsk",
                        "kk": "Омбы орталығынан 10-20 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; экотропа По следам пернатых около 3 км.",
                                "en": "Free entry; the bird-themed eco-trail is about 3 km.",
                                "kk": "Кіру тегін; құстарға арналған экосоқпақ шамамен 3 км."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход свободный; экотропа По следам пернатых около 3 км.",
                                "en": "Free entry; the bird-themed eco-trail is about 3 km.",
                                "kk": "Кіру тегін; құстарға арналған экосоқпақ шамамен 3 км."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; экотропа По следам пернатых около 3 км.",
                                "en": "Free entry; the bird-themed eco-trail is about 3 km.",
                                "kk": "Кіру тегін; құстарға арналған экосоқпақ шамамен 3 км."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "от центра Омска к природному парку Птичья гавань",
                                "en": "from central Omsk to Bird Harbor nature park",
                                "kk": "Омбы орталығынан Құс айлағы табиғи паркіне"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min",
                                "kk": "10-20 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "не шуметь у водоемов и не кормить птиц неподходящей едой",
                                "en": "Keep quiet near ponds and do not feed birds unsuitable food",
                                "kk": "су маңында шуламаңыз және құстарға жарамсыз тамақ бермеңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "BINOCULARS",
                        "title": {
                                "ru": "Бинокль",
                                "en": "Binoculars",
                                "kk": "Дүрбі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера",
                                "en": "Camera",
                                "kk": "Камера"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 40
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Экотропа Лосиного Острова', 900, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "май-сентябрь; утром в жару комфортнее",
                        "en": "May-September; morning is more comfortable in heat",
                        "kk": "Мамыр-қыркүйек; ыстықта таңертең жайлырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "ежедневно 10:00-20:00, касса до 19:00",
                        "en": "Daily 10:00-20:00, ticket office until 19:00",
                        "kk": "Күн сайын 10:00-20:00, касса 19:00-ге дейін"
                }
        },
        "priceNote": {
                "ru": "Босоногая тропа: взрослый около 900 ₽, детский около 700 ₽; самостоятельное посещение без записи.",
                "en": "Barefoot Trail: adult about 900 RUB, child about 700 RUB; self-guided visit without booking.",
                "kk": "Жалаңаяқ соқпақ: ересекке шамамен 900 RUB, балаға шамамен 700 RUB; жазылусыз өз бетімен бару."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1.5-3 ч",
                        "en": "1.5-3 h",
                        "kk": "1,5-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 35,
                "maxMinutes": 70,
                "note": {
                        "ru": "35-70 мин от центра Москвы",
                        "en": "35-70 min from central Moscow",
                        "kk": "Мәскеу орталығынан 35-70 мин"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Босоногая тропа: взрослый около 900 ₽, детский около 700 ₽; самостоятельное посещение без записи.",
                                "en": "Barefoot Trail: adult about 900 RUB, child about 700 RUB; self-guided visit without booking.",
                                "kk": "Жалаңаяқ соқпақ: ересекке шамамен 900 RUB, балаға шамамен 700 RUB; жазылусыз өз бетімен бару."
                        },
                        "minAmount": 900,
                        "maxAmount": 900,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Босоногая тропа: взрослый около 900 ₽, детский около 700 ₽; самостоятельное посещение без записи.",
                                "en": "Barefoot Trail: adult about 900 RUB, child about 700 RUB; self-guided visit without booking.",
                                "kk": "Жалаңаяқ соқпақ: ересекке шамамен 900 RUB, балаға шамамен 700 RUB; жазылусыз өз бетімен бару."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Босоногая тропа: взрослый около 900 ₽, детский около 700 ₽; самостоятельное посещение без записи.",
                                "en": "Barefoot Trail: adult about 900 RUB, child about 700 RUB; self-guided visit without booking.",
                                "kk": "Жалаңаяқ соқпақ: ересекке шамамен 900 RUB, балаға шамамен 700 RUB; жазылусыз өз бетімен бару."
                        },
                        "amount": 900,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 35,
                        "durationMaxMinutes": 70,
                        "routeHint": {
                                "ru": "от центра Москвы к экокомплексу Лосиного Острова; от МКАД около 5 км",
                                "en": "from central Moscow to the Losiny Ostrov eco-complex; about 5 km from MKAD",
                                "kk": "Мәскеу орталығынан Лосиный Остров экокешеніне; МКАД-тан шамамен 5 км"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "35-70 мин",
                                "en": "35-70 min",
                                "kk": "35-70 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "на территорию экокомплекса с животными вход с маршрута запрещен; после непогоды проверяйте работу",
                                "en": "Entry from the route into the animal eco-complex is prohibited; check operation after bad weather",
                                "kk": "маршруттан жануарлар экокешеніне кіруге болмайды; ауа райынан кейін жұмысын тексеріңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Полотенце для ног",
                                "en": "Towel for feet",
                                "kk": "Аяққа арналған сүлгі"
                        }
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 40
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Береговая экотропа Комарово', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-октябрь; зимой спокойная прогулка при хорошей обуви",
                        "en": "May-October; winter is a quiet walk with good footwear",
                        "kk": "Мамыр-қазан; қыста жақсы аяқ киіммен тыныш серуен"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "свободный доступ; лучше ходить в светлое время",
                        "en": "Free access; daylight is best",
                        "kk": "Еркін кіру; күндіз жүрген дұрыс"
                }
        },
        "priceNote": {
                "ru": "Вход свободный; оборудованная береговая экотропа 2.8 км.",
                "en": "Free entry; the marked shore eco-trail is 2.8 km.",
                "kk": "Кіру тегін; жабдықталған жағалау экосоқпағы 2,8 км."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1.5-3 ч",
                        "en": "1.5-3 h",
                        "kk": "1,5-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 50,
                "maxMinutes": 90,
                "note": {
                        "ru": "50-90 мин из центра Санкт-Петербурга",
                        "en": "50-90 min from central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығынан 50-90 мин"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; оборудованная береговая экотропа 2.8 км.",
                                "en": "Free entry; the marked shore eco-trail is 2.8 km.",
                                "kk": "Кіру тегін; жабдықталған жағалау экосоқпағы 2,8 км."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход свободный; оборудованная береговая экотропа 2.8 км.",
                                "en": "Free entry; the marked shore eco-trail is 2.8 km.",
                                "kk": "Кіру тегін; жабдықталған жағалау экосоқпағы 2,8 км."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход свободный; оборудованная береговая экотропа 2.8 км.",
                                "en": "Free entry; the marked shore eco-trail is 2.8 km.",
                                "kk": "Кіру тегін; жабдықталған жағалау экосоқпағы 2,8 км."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 50,
                        "durationMaxMinutes": 90,
                        "routeHint": {
                                "ru": "из центра Санкт-Петербурга в Курортный район к Комарово",
                                "en": "from central Saint Petersburg to Komarovo in the Kurortny District",
                                "kk": "Санкт-Петербург орталығынан Курортный ауданындағы Комаровоға"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "50-90 мин",
                                "en": "50-90 min",
                                "kk": "50-90 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "берегите настилы и дюны; не разводите костры и не заходите в закрытые зоны",
                                "en": "Protect boardwalks and dunes; no fires and no entry to closed zones",
                        "kk": "төсеніштер мен құм төбелерді сақтаңыз; алау жақпаңыз және жабық аймаққа кірмеңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Водостойкая обувь",
                                "en": "Water-resistant shoes",
                                "kk": "Су өткізбейтін аяқ киім"
                        }
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Тропа к скалам Семь Братьев', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-октябрь; зимой только при опыте и правильной экипировке",
                        "en": "May-October; winter only with experience and proper gear",
                        "kk": "Мамыр-қазан; қыста тек тәжірибе және дұрыс жабдықпен"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "круглогодично в светлое время; маршрут около 15 км и 4-6 ч пешком",
                        "en": "Year-round in daylight; route is about 15 km and 4-6 h on foot",
                        "kk": "Жыл бойы күндіз; маршрут шамамен 15 км және жаяу 4-6 сағ"
                }
        },
        "priceNote": {
                "ru": "Свободный доступ; кассы нет.",
                "en": "Free access; there is no ticket office.",
                "kk": "Кіру тегін; касса жоқ."
        },
        "timeOnSite": {
                "minMinutes": 240,
                "maxMinutes": 360,
                "note": {
                        "ru": "4-6 ч",
                        "en": "4-6 h",
                        "kk": "4-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 90,
                "maxMinutes": 120,
                "note": {
                        "ru": "1.5-2 ч от Екатеринбурга",
                        "en": "1.5-2 h from Yekaterinburg",
                        "kk": "Екатеринбургтен 1,5-2 сағ"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный доступ; кассы нет.",
                                "en": "Free access; there is no ticket office.",
                                "kk": "Кіру тегін; касса жоқ."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Свободный доступ; кассы нет.",
                                "en": "Free access; there is no ticket office.",
                                "kk": "Кіру тегін; касса жоқ."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Свободный доступ; кассы нет.",
                                "en": "Free access; there is no ticket office.",
                                "kk": "Кіру тегін; касса жоқ."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 90,
                        "durationMaxMinutes": 120,
                        "routeHint": {
                                "ru": "Екатеринбург - Верх-Нейвинский - старт тропы к скалам",
                                "en": "Yekaterinburg - Verkh-Neyvinsky - trailhead for the rocks",
                                "kk": "Екатеринбург - Верх-Нейвинский - жартастар соқпағының бастауы"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "1.5-2 ч",
                                "en": "1.5-2 h",
                                "kk": "1,5-2 сағ"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "на скалах соблюдать осторожность; мобильная связь местами может пропадать",
                                "en": "Be careful on the rocks; mobile signal may disappear in places",
                                "kk": "жартаста сақ болыңыз; кей жерде байланыс жоғалуы мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Треккинговая обувь",
                                "en": "Trekking shoes",
                                "kk": "Треккинг аяқ киімі"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20,
                        "note": {
                                "ru": "1.5-2 л воды",
                                "en": "1.5-2 L of water",
                                "kk": "1,5-2 л су"
                        }
                },
                {
                        "itemType": "FOOD",
                        "title": {
                                "ru": "Перекус",
                                "en": "Snack",
                                "kk": "Жеңіл тамақ"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                },
                {
                        "itemType": "FIRST_AID",
                        "title": {
                                "ru": "Аптечка",
                                "en": "First aid kit",
                                "kk": "Алғашқы көмек қобдишасы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Лесная петля Голубых озер', 100, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; лето для прогулок, зима для контрастных видов, межсезонье грязное",
                        "en": "Year-round; summer for walks, winter for contrast views, shoulder seasons can be muddy",
                        "kk": "Жыл бойы; жазда серуен, қыста контраст көрініс, маусымаралықта лай болуы мүмкін"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "территория Большого Голубого озера указана как круглосуточная; оплату обычно делают по QR или через инфо-точки",
                        "en": "Bolshoye Goluboye Lake area is listed as open around the clock; payment is usually by QR or information points",
                        "kk": "Үлкен Көк көл аумағы тәулік бойы ашық деп көрсетілген; төлем әдетте QR немесе ақпарат нүктелері арқылы"
                }
        },
        "priceNote": {
                "ru": "Вход на территорию около 100 ₽; дети, пенсионеры и льготники могут проходить бесплатно по правилам.",
                "en": "Area entry is about 100 RUB; children, pensioners and eligible visitors may be free under the rules.",
                "kk": "Аумаққа кіру шамамен 100 RUB; балалар, зейнеткерлер және жеңілдігі бар келушілер ереже бойынша тегін болуы мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1.5-3 ч",
                        "en": "1.5-3 h",
                        "kk": "1,5-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 25,
                "maxMinutes": 40,
                "note": {
                        "ru": "25-40 мин от центра Казани",
                        "en": "25-40 min from central Kazan",
                        "kk": "Қазан орталығынан 25-40 мин"
                }
        },
        "roadCondition": "MIXED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию около 100 ₽; дети, пенсионеры и льготники могут проходить бесплатно по правилам.",
                                "en": "Area entry is about 100 RUB; children, pensioners and eligible visitors may be free under the rules.",
                                "kk": "Аумаққа кіру шамамен 100 RUB; балалар, зейнеткерлер және жеңілдігі бар келушілер ереже бойынша тегін болуы мүмкін."
                        },
                        "minAmount": 100,
                        "maxAmount": 100,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход на территорию около 100 ₽; дети, пенсионеры и льготники могут проходить бесплатно по правилам.",
                                "en": "Area entry is about 100 RUB; children, pensioners and eligible visitors may be free under the rules.",
                                "kk": "Аумаққа кіру шамамен 100 RUB; балалар, зейнеткерлер және жеңілдігі бар келушілер ереже бойынша тегін болуы мүмкін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию около 100 ₽; дети, пенсионеры и льготники могут проходить бесплатно по правилам.",
                                "en": "Area entry is about 100 RUB; children, pensioners and eligible visitors may be free under the rules.",
                                "kk": "Аумаққа кіру шамамен 100 RUB; балалар, зейнеткерлер және жеңілдігі бар келушілер ереже бойынша тегін болуы мүмкін."
                        },
                        "amount": 100,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 40,
                        "routeHint": {
                                "ru": "от центра Казани к Голубым озерам",
                                "en": "from central Kazan to the Blue Lakes",
                                "kk": "Қазан орталығынан Көк көлдерге"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "note": {
                                "ru": "25-40 мин",
                                "en": "25-40 min",
                                "kk": "25-40 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "вода круглый год холодная 6-8 C; купаться только в разрешенных местах и не мусорить",
                                "en": "Water is cold year-round at 6-8 C; swim only in permitted areas and leave no trash",
                                "kk": "су жыл бойы суық, 6-8 C; тек рұқсат етілген жерде шомылыңыз және қоқыс қалдырмаңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40,
                        "note": {
                                "ru": "Теплая одежда после воды",
                                "en": "Warm clothes after swimming",
                                "kk": "Судан кейін жылы киім"
                        }
                },
                {
                        "itemType": "THERMOS",
                        "title": {
                                "ru": "Термос",
                                "en": "Thermos",
                                "kk": "Термос"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Парк Горького в Москве', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        12,
                        1,
                        2
                ],
                "note": {
                        "ru": "май-сентябрь для прогулок; зима для катка и сезонных активностей",
                        "en": "May-September for walks; winter for skating rink and seasonal activities",
                        "kk": "Мамыр-қыркүйек серуенге; қыс мұзайдын мен маусымдық белсенділікке"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "круглосуточно ежедневно; временные закрытия возможны из-за погоды или мероприятий",
                        "en": "Open daily around the clock; temporary closures are possible for weather or events",
                        "kk": "Күн сайын тәулік бойы ашық; ауа райы немесе шараларға байланысты уақытша жабылуы мүмкін"
                }
        },
        "priceNote": {
                "ru": "Вход в парк свободный; парковка, каток и отдельные активности оплачиваются отдельно.",
                "en": "Park entry is free; parking, skating rink and separate activities cost extra.",
                "kk": "Паркке кіру тегін; тұрақ, мұзайдын және жеке белсенділіктер бөлек төленеді."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 240,
                "note": {
                        "ru": "1.5-4 ч",
                        "en": "1.5-4 h",
                        "kk": "1,5-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 40,
                "note": {
                        "ru": "15-40 мин от центра Москвы",
                        "en": "15-40 min from central Moscow",
                        "kk": "Мәскеу орталығынан 15-40 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход в парк свободный.",
                                "en": "Park entry is free.",
                                "kk": "Паркке кіру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в парк свободный.",
                                "en": "Park entry is free.",
                                "kk": "Паркке кіру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "PARKING",
                        "title": {
                                "ru": "Парковка",
                                "en": "Parking",
                                "kk": "Тұрақ"
                        },
                        "description": {
                                "ru": "Парковка и сезонные активности оплачиваются отдельно.",
                                "en": "Parking and seasonal activities are paid separately.",
                                "kk": "Тұрақ пен маусымдық белсенділіктер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка и сезонные активности оплачиваются отдельно.",
                                "en": "Parking and seasonal activities are paid separately.",
                                "kk": "Тұрақ пен маусымдық белсенділіктер бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход в парк свободный.",
                                "en": "Park entry is free.",
                                "kk": "Паркке кіру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Парковка",
                                "en": "Parking",
                                "kk": "Тұрақ"
                        },
                        "description": {
                                "ru": "Парковка и сезонные активности оплачиваются отдельно.",
                                "en": "Parking and seasonal activities are paid separately.",
                                "kk": "Тұрақ пен маусымдық белсенділіктер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 40,
                        "routeHint": {
                                "ru": "от центра Москвы к парку у Москвы-реки",
                                "en": "from central Moscow to the riverside park",
                                "kk": "Мәскеу орталығынан өзен жағасындағы паркке"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "15-40 мин",
                                "en": "15-40 min",
                                "kk": "15-40 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "парковка платная и загруженная",
                                "en": "parking is paid and busy",
                                "kk": "тұрақ ақылы әрі толы болуы мүмкін"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "расписание сезонных объектов проверяйте отдельно",
                                "en": "Check seasonal facilities separately",
                                "kk": "маусымдық нысандардың кестесін бөлек тексеріңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Power bank",
                                "en": "Power bank",
                                "kk": "Пауэрбанк"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "BLANKET",
                        "title": {
                                "ru": "Плед",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('ВДНХ', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; май-сентябрь для фонтанов, зима для катка",
                        "en": "Year-round; May-September for fountains, winter for skating rink",
                        "kk": "Жыл бойы; мамыр-қыркүйек субұрқаққа, қыс мұзайдынға"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "входы и КПП работают круглосуточно; режим павильонов по отдельным расписаниям",
                        "en": "Entrances and checkpoints operate around the clock; pavilion hours vary separately",
                        "kk": "кіреберістер мен бекеттер тәулік бойы; павильон кестелері бөлек"
                }
        },
        "priceNote": {
                "ru": "Вход на территорию свободный; музеи, павильоны, каток и события оплачиваются отдельно.",
                "en": "Grounds are free; museums, pavilions, skating rink and events are paid separately.",
                "kk": "Аумаққа кіру тегін; музейлер, павильондар, мұзайдын және шаралар бөлек төленеді."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 360,
                "note": {
                        "ru": "2-6 ч",
                        "en": "2-6 h",
                        "kk": "2-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 25,
                "maxMinutes": 50,
                "note": {
                        "ru": "25-50 мин от центра Москвы",
                        "en": "25-50 min from central Moscow",
                        "kk": "Мәскеу орталығынан 25-50 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Музеи, павильоны, каток и события оплачиваются отдельно.",
                                "en": "Museums, pavilions, skating rink and events are paid separately.",
                                "kk": "Музейлер, павильондар, мұзайдын және шаралар бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музеи, павильоны, каток и события оплачиваются отдельно.",
                                "en": "Museums, pavilions, skating rink and events are paid separately.",
                                "kk": "Музейлер, павильондар, мұзайдын және шаралар бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Музеи, павильоны, каток и события оплачиваются отдельно.",
                                "en": "Museums, pavilions, skating rink and events are paid separately.",
                                "kk": "Музейлер, павильондар, мұзайдын және шаралар бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 50,
                        "routeHint": {
                                "ru": "от центра Москвы к ВДНХ; есть круглосуточный многоуровневый паркинг",
                                "en": "from central Moscow to VDNKh; a multilevel parking garage operates around the clock",
                                "kk": "Мәскеу орталығынан ВДНХ-ға; көпқабатты тұрақ тәулік бойы істейді"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "25-50 мин",
                                "en": "25-50 min",
                                "kk": "25-50 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "есть многоуровневый паркинг",
                                "en": "multilevel parking is available",
                                "kk": "көпқабатты тұрақ бар"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "территория большая: заранее выберите павильоны и маршрут",
                                "en": "The area is large: choose pavilions and route ahead",
                                "kk": "аумақ үлкен: павильондар мен бағытты алдын ала таңдаңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Power bank",
                                "en": "Power bank",
                                "kk": "Пауэрбанк"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Спас на Крови', 550, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; лучше утром или в будни; летом билет покупать заранее",
                        "en": "Year-round; morning or weekdays are best; buy ahead in summer",
                        "kk": "Жыл бойы; таңертең немесе жұмыс күні жақсы; жазда билетті алдын ала алыңыз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "обычно 10:00-18:00, кассы до 17:30; среда выходной; летом возможны вечерние часы",
                        "en": "Usually 10:00-18:00, ticket office until 17:30; Wednesday closed; evening hours possible in summer",
                        "kk": "Әдетте 10:00-18:00, касса 17:30-ға дейін; сәрсенбі жабық; жазда кешкі уақыт болуы мүмкін"
                }
        },
        "priceNote": {
                "ru": "Входной билет 550 ₽; льготные 300/330 ₽; аудиогид 300 ₽; вечерние программы отдельно.",
                "en": "Entrance ticket is 550 RUB; concessions 300/330 RUB; audio guide 300 RUB; evening programs separate.",
                "kk": "Кіру билеті 550 RUB; жеңілдік 300/330 RUB; аудиогид 300 RUB; кешкі бағдарламалар бөлек."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 90,
                "note": {
                        "ru": "1-1.5 ч",
                        "en": "1-1.5 h",
                        "kk": "1-1,5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин по центру Санкт-Петербурга",
                        "en": "10-25 min within central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығында 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Входной билет 550 ₽.",
                                "en": "Entrance ticket is 550 RUB.",
                                "kk": "Кіру билеті 550 RUB."
                        },
                        "minAmount": 550,
                        "maxAmount": 550,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Входной билет 550 ₽.",
                                "en": "Entrance ticket is 550 RUB.",
                                "kk": "Кіру билеті 550 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аудиогид / программа",
                                "en": "Audio guide / program",
                                "kk": "Аудиогид / бағдарлама"
                        },
                        "description": {
                                "ru": "Аудиогид около 300 ₽; вечерние программы оплачиваются отдельно.",
                                "en": "Audio guide is about 300 RUB; evening programs cost extra.",
                                "kk": "Аудиогид шамамен 300 RUB; кешкі бағдарламалар бөлек төленеді."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аудиогид около 300 ₽; вечерние программы оплачиваются отдельно.",
                                "en": "Audio guide is about 300 RUB; evening programs cost extra.",
                                "kk": "Аудиогид шамамен 300 RUB; кешкі бағдарламалар бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Входной билет 550 ₽.",
                                "en": "Entrance ticket is 550 RUB.",
                                "kk": "Кіру билеті 550 RUB."
                        },
                        "amount": 550,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аудиогид / программа",
                                "en": "Audio guide / program",
                                "kk": "Аудиогид / бағдарлама"
                        },
                        "description": {
                                "ru": "Аудиогид около 300 ₽; вечерние программы оплачиваются отдельно.",
                                "en": "Audio guide is about 300 RUB; evening programs cost extra.",
                                "kk": "Аудиогид шамамен 300 RUB; кешкі бағдарламалар бөлек төленеді."
                        },
                        "amount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "по центру Санкт-Петербурга рядом с каналами и Невским проспектом",
                                "en": "within central Saint Petersburg near canals and Nevsky Prospekt",
                                "kk": "Санкт-Петербург орталығында каналдар мен Невский даңғылы маңында"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "это музей-памятник: внутри соблюдать тишину; расписание может меняться по датам",
                                "en": "This is a museum monument: keep quiet inside; schedule may vary by date",
                                "kk": "бұл музей-ескерткіш: ішінде тыныштық сақтаңыз; кесте күнге қарай өзгеруі мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Қарапайым киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Небольшая сумка",
                                "en": "Small bag",
                                "kk": "Шағын сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Новая Голландия', 0, $${
        "bestTime": "AFTERNOON",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; май-сентябрь для двора и террас, зима для катка",
                        "en": "Year-round; May-September for courtyard and terraces, winter for skating rink",
                        "kk": "Жыл бойы; мамыр-қыркүйек аула мен террасаларға, қыс мұзайдынға"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн-Чт 09:00-22:00, Пт-Вс 09:00-23:00; вход закрывается за 30 минут до окончания",
                        "en": "Mon-Thu 09:00-22:00, Fri-Sun 09:00-23:00; entry closes 30 minutes before closing",
                        "kk": "Дс-Бс 09:00-22:00, Жм-Жс 09:00-23:00; кіру жабылудан 30 минут бұрын тоқтайды"
                }
        },
        "priceNote": {
                "ru": "Вход на остров свободный; Сообщество 300 ₽, каток, события и арендаторы отдельно.",
                "en": "Island entry is free; Community space is 300 RUB, skating rink, events and tenants are separate.",
                "kk": "Аралға кіру тегін; Қауымдастық кеңістігі 300 RUB, мұзайдын, шаралар және жалға алушылар бөлек."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1-3 h",
                        "kk": "1-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 25,
                "note": {
                        "ru": "10-25 мин по центру Санкт-Петербурга",
                        "en": "10-25 min within central Saint Petersburg",
                        "kk": "Санкт-Петербург орталығында 10-25 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на остров свободный.",
                                "en": "Island entry is free.",
                                "kk": "Аралға кіру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход на остров свободный.",
                                "en": "Island entry is free.",
                                "kk": "Аралға кіру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Сообщество около 300 ₽; каток, события и арендаторы оплачиваются отдельно.",
                                "en": "Community space is about 300 RUB; skating rink, events and tenants are paid separately.",
                                "kk": "Қауымдастық кеңістігі шамамен 300 RUB; мұзайдын, шаралар және жалға алушылар бөлек төленеді."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сообщество около 300 ₽; каток, события и арендаторы оплачиваются отдельно.",
                                "en": "Community space is about 300 RUB; skating rink, events and tenants are paid separately.",
                                "kk": "Қауымдастық кеңістігі шамамен 300 RUB; мұзайдын, шаралар және жалға алушылар бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на остров свободный.",
                                "en": "Island entry is free.",
                                "kk": "Аралға кіру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Сообщество около 300 ₽; каток, события и арендаторы оплачиваются отдельно.",
                                "en": "Community space is about 300 RUB; skating rink, events and tenants are paid separately.",
                                "kk": "Қауымдастық кеңістігі шамамен 300 RUB; мұзайдын, шаралар және жалға алушылар бөлек төленеді."
                        },
                        "amount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "по центру Санкт-Петербурга; собственной парковки нет",
                                "en": "within central Saint Petersburg; no dedicated parking",
                                "kk": "Санкт-Петербург орталығында; жеке тұрақ жоқ"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "10-25 мин",
                                "en": "10-25 min",
                                "kk": "10-25 мин"
                        },
                        "sortOrder": 10,
                        "parkingNote": {
                                "ru": "собственной парковки нет",
                                "en": "no dedicated parking",
                                "kk": "жеке тұрақ жоқ"
                        }
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "с домашними животными нельзя; парковку лучше планировать заранее",
                                "en": "Pets are not allowed; plan parking ahead",
                                "kk": "үй жануарларымен кіруге болмайды; тұрақты алдын ала жоспарлаңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "BLANKET",
                        "title": {
                                "ru": "Плед",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Казанский Кремль', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        12,
                        1,
                        2
                ],
                "note": {
                        "ru": "май-сентябрь и вечерняя подсветка; зимой красиво, но холодно",
                        "en": "May-September and evening lights; winter is beautiful but cold",
                        "kk": "Мамыр-қыркүйек және кешкі жарық; қыста әдемі, бірақ суық"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Спасская башня круглосуточно; Тайницкая башня 06:00-20:00 зимой и 06:00-22:00 летом; Кул Шариф и собор 08:00-20:00",
                        "en": "Spasskaya Tower around the clock; Taynitskaya Tower 06:00-20:00 in winter and 06:00-22:00 in summer; Kul Sharif and cathedral 08:00-20:00",
                        "kk": "Спасская мұнарасы тәулік бойы; Тайницкая мұнарасы қыста 06:00-20:00, жазда 06:00-22:00; Құл Шариф пен собор 08:00-20:00"
                }
        },
        "priceNote": {
                "ru": "Вход на территорию свободный; музеи и экскурсии оплачиваются отдельно.",
                "en": "Grounds are free; museums and tours are paid separately.",
                "kk": "Аумаққа кіру тегін; музейлер мен экскурсиялар бөлек төленеді."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин от центра Казани",
                        "en": "5-15 min from central Kazan",
                        "kk": "Қазан орталығынан 5-15 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Музеи и экскурсии оплачиваются отдельно.",
                                "en": "Museums and tours are paid separately.",
                                "kk": "Музейлер мен экскурсиялар бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музеи и экскурсии оплачиваются отдельно.",
                                "en": "Museums and tours are paid separately.",
                                "kk": "Музейлер мен экскурсиялар бөлек төленеді."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию свободный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Музеи и экскурсии оплачиваются отдельно.",
                                "en": "Museums and tours are paid separately.",
                                "kk": "Музейлер мен экскурсиялар бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "от центра Казани к Кремлю",
                                "en": "from central Kazan to the Kremlin",
                                "kk": "Қазан орталығынан Кремльге"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min",
                                "kk": "5-15 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "в мечети бывают ограничения во время молитв; музейные часы отличаются от доступа на территорию",
                                "en": "Mosque access may be limited during prayers; museum hours differ from grounds access",
                                "kk": "мешітке намаз кезінде шектеу болуы мүмкін; музей уақыты аумаққа кіруден бөлек"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Қарапайым киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30,
                        "note": {
                                "ru": "Платок или скромная одежда для мечети",
                                "en": "Scarf or modest clothing for the mosque",
                                "kk": "Мешітке орамал немесе қарапайым киім"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Сочинский дендрарий', 700, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10,
                        11
                ],
                "note": {
                        "ru": "апрель-ноябрь; весна для цветения, летом жарко, зимой мягче и спокойнее",
                        "en": "April-November; spring for blooms, summer is hot, winter is milder and quieter",
                        "kk": "Сәуір-қараша; көктем гүлдеу үшін, жаз ыстық, қыс жұмсақ әрі тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "парк 09:00-20:00 ежедневно; кассы 09:00-19:00; с 19:00 до 20:00 парк работает на выход",
                        "en": "Park daily 09:00-20:00; ticket offices 09:00-19:00; 19:00-20:00 exit only",
                        "kk": "Парк күн сайын 09:00-20:00; касса 09:00-19:00; 19:00-20:00 тек шығу"
                }
        },
        "priceNote": {
                "ru": "Вход в парк 700 ₽; билет с канатной дорогой ориентировочно 1 400 ₽.",
                "en": "Park entry is 700 RUB; ticket with cable car is roughly 1,400 RUB.",
                "kk": "Паркке кіру 700 RUB; аспалы жолмен билет шамамен 1 400 RUB."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин от центра Сочи",
                        "en": "5-15 min from central Sochi",
                        "kk": "Сочи орталығынан 5-15 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход в парк 700 ₽.",
                                "en": "Park entry is 700 RUB.",
                                "kk": "Паркке кіру 700 RUB."
                        },
                        "minAmount": 700,
                        "maxAmount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в парк 700 ₽.",
                                "en": "Park entry is 700 RUB.",
                                "kk": "Паркке кіру 700 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Авто / доп. транспорт",
                                "en": "Transport / add-on",
                                "kk": "Көлік / қосымша төлем"
                        },
                        "description": {
                                "ru": "Билет с канатной дорогой ориентировочно 1 400 ₽.",
                                "en": "Ticket with cable car is roughly 1,400 RUB.",
                                "kk": "Аспалы жолмен билет шамамен 1 400 RUB."
                        },
                        "minAmount": 1400,
                        "maxAmount": 1400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Билет с канатной дорогой ориентировочно 1 400 ₽.",
                                "en": "Ticket with cable car is roughly 1,400 RUB.",
                                "kk": "Аспалы жолмен билет шамамен 1 400 RUB."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход в парк 700 ₽.",
                                "en": "Park entry is 700 RUB.",
                                "kk": "Паркке кіру 700 RUB."
                        },
                        "amount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Авто / доп. транспорт",
                                "en": "Transport / add-on",
                                "kk": "Көлік / қосымша төлем"
                        },
                        "description": {
                                "ru": "Билет с канатной дорогой ориентировочно 1 400 ₽.",
                                "en": "Ticket with cable car is roughly 1,400 RUB.",
                                "kk": "Аспалы жолмен билет шамамен 1 400 RUB."
                        },
                        "amount": 1400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "от центра Сочи к дендрарию",
                                "en": "from central Sochi to the arboretum",
                                "kk": "Сочи орталығынан дендрарийге"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min",
                                "kk": "5-15 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "верхняя и нижняя части разделены дорогой; канатная дорога оплачивается отдельно",
                                "en": "Upper and lower parts are separated by a road; cable car is paid separately",
                                "kk": "жоғарғы және төменгі бөлік жолмен бөлінген; аспалы жол бөлек төленеді"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера",
                                "en": "Camera",
                                "kk": "Камера"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Горный курорт Роза Хутор', 2950, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8,
                        9,
                        10,
                        12,
                        1,
                        2,
                        3
                ],
                "note": {
                        "ru": "июнь-октябрь для горных прогулок; декабрь-март для зимнего сезона",
                        "en": "June-October for mountain walks; December-March for winter season",
                        "kk": "Маусым-қазан тау серуеніне; желтоқсан-наурыз қысқы маусымға"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "режим зависит от сезона, погоды и работы канатных дорог; билет выбирается на дату",
                        "en": "Hours depend on season, weather and lift operation; ticket is date-specific",
                        "kk": "кесте маусымға, ауа райына және көтергіш жұмысына байланысты; билет нақты күнге алынады"
                }
        },
        "priceNote": {
                "ru": "Летний прогулочный билет Путь к вершинам + Парк водопадов от 2 950 ₽ за взрослого; дети до 6 лет бесплатно.",
                "en": "Summer walking ticket Peaks Route plus Waterfall Park starts from 2,950 RUB per adult; children under 6 are free.",
                "kk": "Жазғы серуен билеті Шыңдарға жол + Сарқырамалар паркі ересекке 2 950 RUB-дан; 6 жасқа дейінгі балалар тегін."
        },
        "timeOnSite": {
                "minMinutes": 300,
                "maxMinutes": 480,
                "note": {
                        "ru": "5-8 ч",
                        "en": "5-8 h",
                        "kk": "5-8 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 40,
                "maxMinutes": 120,
                "note": {
                        "ru": "40-60 мин от Адлера/Сириуса; 1.5-2 ч от центра Сочи",
                        "en": "40-60 min from Adler/Sirius; 1.5-2 h from central Sochi",
                        "kk": "Адлер/Сириустан 40-60 мин; Сочи орталығынан 1,5-2 сағ"
                }
        },
        "roadCondition": "MOUNTAIN",
        "feeItems": [
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Прогулочный билет / подъемники",
                                "en": "Walking ticket / lifts",
                                "kk": "Серуен билеті / көтергіштер"
                        },
                        "description": {
                                "ru": "Летний прогулочный билет Путь к вершинам + Парк водопадов от 2 950 ₽ за взрослого; дети до 6 лет бесплатно.",
                                "en": "Summer walking ticket Peaks Route plus Waterfall Park starts from 2,950 RUB per adult; children under 6 are free.",
                                "kk": "Жазғы серуен билеті Шыңдарға жол + Сарқырамалар паркі ересекке 2 950 RUB-дан; 6 жасқа дейінгі балалар тегін."
                        },
                        "minAmount": 2950,
                        "maxAmount": 2950,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Летний прогулочный билет Путь к вершинам + Парк водопадов от 2 950 ₽ за взрослого; дети до 6 лет бесплатно.",
                                "en": "Summer walking ticket Peaks Route plus Waterfall Park starts from 2,950 RUB per adult; children under 6 are free.",
                                "kk": "Жазғы серуен билеті Шыңдарға жол + Сарқырамалар паркі ересекке 2 950 RUB-дан; 6 жасқа дейінгі балалар тегін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Прогулочный билет / подъемники",
                                "en": "Walking ticket / lifts",
                                "kk": "Серуен билеті / көтергіштер"
                        },
                        "description": {
                                "ru": "Летний прогулочный билет Путь к вершинам + Парк водопадов от 2 950 ₽ за взрослого; дети до 6 лет бесплатно.",
                                "en": "Summer walking ticket Peaks Route plus Waterfall Park starts from 2,950 RUB per adult; children under 6 are free.",
                                "kk": "Жазғы серуен билеті Шыңдарға жол + Сарқырамалар паркі ересекке 2 950 RUB-дан; 6 жасқа дейінгі балалар тегін."
                        },
                        "amount": 2950,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 40,
                        "durationMaxMinutes": 120,
                        "routeHint": {
                                "ru": "Адлер/Сириус или центр Сочи - Красная Поляна - Роза Хутор",
                                "en": "Adler/Sirius or central Sochi - Krasnaya Polyana - Rosa Khutor",
                                "kk": "Адлер/Сириус немесе Сочи орталығы - Красная Поляна - Роза Хутор"
                        },
                        "roadCondition": "MOUNTAIN",
                        "requires4x4": false,
                        "note": {
                                "ru": "40-120 мин",
                                "en": "40-120 min",
                                "kk": "40-120 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "на высоте погода быстро меняется; подъемники могут закрываться при ветре или грозе",
                                "en": "Weather changes quickly at altitude; lifts can close in wind or thunderstorms",
                                "kk": "биікте ауа райы тез өзгереді; жел немесе найзағайда көтергіштер жабылуы мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_LAYER",
                        "title": {
                                "ru": "Тёплый слой",
                                "en": "Warm layer",
                                "kk": "Жылы қабат"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 50
                },
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 60
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Нижегородский Кремль', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "май-сентябрь; вечером красивые виды на Волгу и Стрелку",
                        "en": "May-September; evening has beautiful views of the Volga and Strelka",
                        "kk": "Мамыр-қыркүйек; кешке Еділ мен Стрелка көрінісі әдемі"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "территория: весна-лето примерно 06:00-02:00; зима 06:00-21:00/22:00; музеи имеют свои часы",
                        "en": "Grounds: spring-summer roughly 06:00-02:00; winter 06:00-21:00/22:00; museums have separate hours",
                        "kk": "Аумақ: көктем-жаз шамамен 06:00-02:00; қыс 06:00-21:00/22:00; музейлердің уақыты бөлек"
                }
        },
        "priceNote": {
                "ru": "Территория бесплатная; кремлевская стена, музеи и экскурсии обычно 500-800 ₽ по программе.",
                "en": "Grounds are free; wall route, museums and tours are usually 500-800 RUB depending on program.",
                "kk": "Аумақ тегін; қабырға маршруты, музейлер және экскурсиялар бағдарламаға қарай әдетте 500-800 RUB."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1.5-3 ч",
                        "en": "1.5-3 h",
                        "kk": "1,5-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин от центра Нижнего Новгорода",
                        "en": "5-15 min from central Nizhny Novgorod",
                        "kk": "Нижний Новгород орталығынан 5-15 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию бесплатный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход на территорию бесплатный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Кремлевская стена, музеи и экскурсии обычно 500-800 ₽ по программе.",
                                "en": "Wall route, museums and tours are usually 500-800 RUB depending on program.",
                                "kk": "Қабырға маршруты, музейлер және экскурсиялар бағдарламаға қарай әдетте 500-800 RUB."
                        },
                        "minAmount": 500,
                        "maxAmount": 800,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Кремлевская стена, музеи и экскурсии обычно 500-800 ₽ по программе.",
                                "en": "Wall route, museums and tours are usually 500-800 RUB depending on program.",
                                "kk": "Қабырға маршруты, музейлер және экскурсиялар бағдарламаға қарай әдетте 500-800 RUB."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Вход на территорию бесплатный.",
                                "en": "Grounds entry is free.",
                                "kk": "Аумаққа кіру тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Кремлевская стена, музеи и экскурсии обычно 500-800 ₽ по программе.",
                                "en": "Wall route, museums and tours are usually 500-800 RUB depending on program.",
                                "kk": "Қабырға маршруты, музейлер және экскурсиялар бағдарламаға қарай әдетте 500-800 RUB."
                        },
                        "amount": 500,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "от центра Нижнего Новгорода к Кремлю",
                                "en": "from central Nizhny Novgorod to the Kremlin",
                                "kk": "Нижний Новгород орталығынан Кремльге"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min",
                                "kk": "5-15 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "некоторые башни и проходы могут закрываться на работы и мероприятия",
                                "en": "Some towers and passages may close for works or events",
                                "kk": "кейбір мұнаралар мен өтпелер жөндеу немесе шаралар үшін жабылуы мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера",
                                "en": "Camera",
                                "kk": "Камера"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Ельцин Центр', 400, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; удобен в плохую погоду, лучше будни",
                        "en": "Year-round; good for bad weather, weekdays are best",
                        "kk": "Жыл бойы; ауа райы қолайсызда ыңғайлы, жұмыс күні жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Вт-Вс 10:00-21:00; понедельник выходной",
                        "en": "Tue-Sun 10:00-21:00; Monday closed",
                        "kk": "Сс-Жс 10:00-21:00; дүйсенбі жабық"
                }
        },
        "priceNote": {
                "ru": "Музей 400 ₽; музей + арт-галерея 500 ₽; семейный 800 ₽; экскурсия 500 ₽; аудиогид 150 ₽.",
                "en": "Museum is 400 RUB; museum plus art gallery 500 RUB; family ticket 800 RUB; tour 500 RUB; audio guide 150 RUB.",
                "kk": "Музей 400 RUB; музей және арт-галерея 500 RUB; отбасылық билет 800 RUB; экскурсия 500 RUB; аудиогид 150 RUB."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2-4 h",
                        "kk": "2-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин от центра Екатеринбурга",
                        "en": "5-15 min from central Yekaterinburg",
                        "kk": "Екатеринбург орталығынан 5-15 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Музей 400 ₽.",
                                "en": "Museum ticket is 400 RUB.",
                                "kk": "Музей билеті 400 RUB."
                        },
                        "minAmount": 400,
                        "maxAmount": 400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музей 400 ₽.",
                                "en": "Museum ticket is 400 RUB.",
                                "kk": "Музей билеті 400 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Музей + арт-галерея 500 ₽; семейный билет 800 ₽.",
                                "en": "Museum plus art gallery 500 RUB; family ticket 800 RUB.",
                                "kk": "Музей және арт-галерея 500 RUB; отбасылық билет 800 RUB."
                        },
                        "minAmount": 500,
                        "maxAmount": 800,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музей + арт-галерея 500 ₽; семейный билет 800 ₽.",
                                "en": "Museum plus art gallery 500 RUB; family ticket 800 RUB.",
                                "kk": "Музей және арт-галерея 500 RUB; отбасылық билет 800 RUB."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия 500 ₽; аудиогид 150 ₽.",
                                "en": "Tour 500 RUB; audio guide 150 RUB.",
                                "kk": "Экскурсия 500 RUB; аудиогид 150 RUB."
                        },
                        "minAmount": 150,
                        "maxAmount": 500,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Экскурсия 500 ₽; аудиогид 150 ₽.",
                                "en": "Tour 500 RUB; audio guide 150 RUB.",
                                "kk": "Экскурсия 500 RUB; аудиогид 150 RUB."
                        },
                        "sortOrder": 30
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Музей 400 ₽.",
                                "en": "Museum ticket is 400 RUB.",
                                "kk": "Музей билеті 400 RUB."
                        },
                        "amount": 400,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Музей + арт-галерея 500 ₽; семейный билет 800 ₽.",
                                "en": "Museum plus art gallery 500 RUB; family ticket 800 RUB.",
                                "kk": "Музей және арт-галерея 500 RUB; отбасылық билет 800 RUB."
                        },
                        "amount": 500,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия 500 ₽; аудиогид 150 ₽.",
                                "en": "Tour 500 RUB; audio guide 150 RUB.",
                                "kk": "Экскурсия 500 RUB; аудиогид 150 RUB."
                        },
                        "amount": 150,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "от центра Екатеринбурга к Ельцин Центру",
                                "en": "from central Yekaterinburg to Yeltsin Center",
                                "kk": "Екатеринбург орталығынан Ельцин орталығына"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min",
                                "kk": "5-15 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "на временные выставки и события могут быть отдельные билеты",
                                "en": "Temporary exhibitions and events may require separate tickets",
                                "kk": "уақытша көрмелер мен шараларға бөлек билет қажет болуы мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "HEADPHONES",
                        "title": {
                                "ru": "Наушники",
                                "en": "Headphones",
                                "kk": "Құлаққап"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Небольшая сумка",
                                "en": "Small bag",
                                "kk": "Шағын сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Русский мост', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "май-октябрь; закат и ночная подсветка особенно удачны",
                        "en": "May-October; sunset and night lighting are especially good",
                        "kk": "Мамыр-қазан; күн батуы мен түнгі жарық ерекше жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "круглосуточно; пеший проход по мосту запрещен, смотреть с разрешенных площадок",
                        "en": "Open around the clock; walking on the bridge is prohibited, use permitted viewpoints",
                        "kk": "Тәулік бойы; көпірмен жаяу жүруге болмайды, рұқсат етілген алаңдардан қараңыз"
                }
        },
        "priceNote": {
                "ru": "Проезд и осмотр с разрешенных видовых точек бесплатны.",
                "en": "Driving across and viewing from permitted viewpoints are free.",
                "kk": "Өту және рұқсат етілген көрініс орындарынан қарау тегін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 120,
                "note": {
                        "ru": "0.5-2 ч",
                        "en": "0.5-2 h",
                        "kk": "0,5-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 45,
                "note": {
                        "ru": "20-45 мин от центра Владивостока",
                        "en": "20-45 min from central Vladivostok",
                        "kk": "Владивосток орталығынан 20-45 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Проезд и осмотр с разрешенных видовых точек бесплатны.",
                                "en": "Driving across and viewing from permitted viewpoints are free.",
                                "kk": "Өту және рұқсат етілген көрініс орындарынан қарау тегін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Проезд и осмотр с разрешенных видовых точек бесплатны.",
                                "en": "Driving across and viewing from permitted viewpoints are free.",
                                "kk": "Өту және рұқсат етілген көрініс орындарынан қарау тегін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Проезд и осмотр с разрешенных видовых точек бесплатны.",
                                "en": "Driving across and viewing from permitted viewpoints are free.",
                                "kk": "Өту және рұқсат етілген көрініс орындарынан қарау тегін."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 45,
                        "routeHint": {
                                "ru": "от центра Владивостока к видовым точкам и острову Русский",
                                "en": "from central Vladivostok to viewpoints and Russky Island",
                                "kk": "Владивосток орталығынан көрініс нүктелері мен Русский аралына"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "20-45 мин",
                                "en": "20-45 min",
                                "kk": "20-45 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "нельзя останавливаться и ходить по мосту; выбирайте официальные смотровые точки",
                                "en": "Do not stop or walk on the bridge; choose official viewpoints",
                                "kk": "көпірде тоқтауға немесе жаяу жүруге болмайды; ресми көрініс орындарын таңдаңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Одежда по погоде",
                                "en": "Weather-appropriate clothes",
                                "kk": "Ауа райына сай киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера",
                                "en": "Camera",
                                "kk": "Камера"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "THERMOS",
                        "title": {
                                "ru": "Термос",
                                "en": "Thermos",
                                "kk": "Термос"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Приморский океанариум', 1200, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; лучше будни и утренние сеансы",
                        "en": "Year-round; weekdays and morning sessions are best",
                        "kk": "Жыл бойы; жұмыс күндері және таңғы сеанстар жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "основное здание обычно Вт-Вс 10:00-20:00, вход до 18:45; понедельник выходной; территория до 20:00",
                        "en": "Main building usually Tue-Sun 10:00-20:00, entry until 18:45; Monday closed; grounds until 20:00",
                        "kk": "Негізгі ғимарат әдетте Сс-Жс 10:00-20:00, кіру 18:45-ке дейін; дүйсенбі жабық; аумақ 20:00-ге дейін"
                }
        },
        "priceNote": {
                "ru": "Океанариум: взрослый 1 200 ₽, детский и социальный 600 ₽; океанариум + дельфинарий 2 000-3 200 ₽.",
                "en": "Oceanarium: adult 1,200 RUB, child/social 600 RUB; oceanarium plus dolphinarium 2,000-3,200 RUB.",
                "kk": "Океанариум: ересек 1 200 RUB, бала/әлеуметтік 600 RUB; океанариум және дельфинарий 2 000-3 200 RUB."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3-5 h",
                        "kk": "3-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 35,
                "maxMinutes": 60,
                "note": {
                        "ru": "35-60 мин от центра Владивостока",
                        "en": "35-60 min from central Vladivostok",
                        "kk": "Владивосток орталығынан 35-60 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Океанариум: взрослый 1 200 ₽, детский и социальный 600 ₽.",
                                "en": "Oceanarium: adult 1,200 RUB, child/social 600 RUB.",
                                "kk": "Океанариум: ересек 1 200 RUB, бала/әлеуметтік 600 RUB."
                        },
                        "minAmount": 1200,
                        "maxAmount": 1200,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Океанариум: взрослый 1 200 ₽, детский и социальный 600 ₽.",
                                "en": "Oceanarium: adult 1,200 RUB, child/social 600 RUB.",
                                "kk": "Океанариум: ересек 1 200 RUB, бала/әлеуметтік 600 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Океанариум + дельфинарий 2 000-3 200 ₽.",
                                "en": "Oceanarium plus dolphinarium 2,000-3,200 RUB.",
                                "kk": "Океанариум және дельфинарий 2 000-3 200 RUB."
                        },
                        "minAmount": 2000,
                        "maxAmount": 3200,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Океанариум + дельфинарий 2 000-3 200 ₽.",
                                "en": "Oceanarium plus dolphinarium 2,000-3,200 RUB.",
                                "kk": "Океанариум және дельфинарий 2 000-3 200 RUB."
                        },
                        "sortOrder": 20
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Океанариум: взрослый 1 200 ₽, детский и социальный 600 ₽.",
                                "en": "Oceanarium: adult 1,200 RUB, child/social 600 RUB.",
                                "kk": "Океанариум: ересек 1 200 RUB, бала/әлеуметтік 600 RUB."
                        },
                        "amount": 1200,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Океанариум + дельфинарий 2 000-3 200 ₽.",
                                "en": "Oceanarium plus dolphinarium 2,000-3,200 RUB.",
                                "kk": "Океанариум және дельфинарий 2 000-3 200 RUB."
                        },
                        "amount": 2000,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 35,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "от центра Владивостока по Русскому мосту на остров Русский",
                                "en": "from central Vladivostok across Russky Bridge to Russky Island",
                                "kk": "Владивосток орталығынан Русский көпірі арқылы Русский аралына"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "35-60 мин",
                                "en": "35-60 min",
                                "kk": "35-60 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "дельфинарий работает по сеансам; льготные билеты могут продаваться только в кассе",
                                "en": "Dolphinarium runs by sessions; concession tickets may be sold only at the ticket office",
                                "kk": "дельфинарий сеанспен жұмыс істейді; жеңілдік билеті тек кассада сатылуы мүмкін"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "KIDS_PROOF",
                        "title": {
                                "ru": "Документ ребенка",
                                "en": "Child ID document",
                                "kk": "Баланың құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "WARM_LAYER",
                        "title": {
                                "ru": "Тёплый слой",
                                "en": "Warm layer",
                                "kk": "Жылы қабат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Power bank",
                                "en": "Power bank",
                                "kk": "Пауэрбанк"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "PHONE",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone and map",
                                "kk": "Телефон және карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Кафедральный собор Калининграда', 300, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; органные концерты по афише, лучше бронировать заранее",
                        "en": "Year-round; organ concerts by schedule, booking ahead is best",
                        "kk": "Жыл бойы; орган концерттері афиша бойынша, алдын ала брондаған дұрыс"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "обычно 10:00-19:00; музей и концерты по расписанию",
                        "en": "Usually 10:00-19:00; museum and concerts follow schedule",
                        "kk": "Әдетте 10:00-19:00; музей мен концерттер кесте бойынша"
                }
        },
        "priceNote": {
                "ru": "Музей Иммануила Канта 300 ₽; экскурсия Знакомство с музеем 700 ₽; концерты и программы по афише.",
                "en": "Immanuel Kant Museum is 300 RUB; intro museum tour is 700 RUB; concerts and programs follow the schedule.",
                "kk": "Иммануил Кант музейі 300 RUB; музеймен танысу экскурсиясы 700 RUB; концерттер мен бағдарламалар афиша бойынша."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 150,
                "note": {
                        "ru": "1-2.5 ч",
                        "en": "1-2.5 h",
                        "kk": "1-2,5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин от центра Калининграда",
                        "en": "5-15 min from central Kaliningrad",
                        "kk": "Калининград орталығынан 5-15 мин"
                }
        },
        "roadCondition": "PAVED",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Музей Иммануила Канта 300 ₽.",
                                "en": "Immanuel Kant Museum ticket is 300 RUB.",
                                "kk": "Иммануил Кант музейіне билет 300 RUB."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музей Иммануила Канта 300 ₽.",
                                "en": "Immanuel Kant Museum ticket is 300 RUB.",
                                "kk": "Иммануил Кант музейіне билет 300 RUB."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия Знакомство с музеем 700 ₽.",
                                "en": "Intro museum tour is 700 RUB.",
                                "kk": "Музеймен танысу экскурсиясы 700 RUB."
                        },
                        "minAmount": 700,
                        "maxAmount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Экскурсия Знакомство с музеем 700 ₽.",
                                "en": "Intro museum tour is 700 RUB.",
                                "kk": "Музеймен танысу экскурсиясы 700 RUB."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Органные концерты и отдельные программы оплачиваются по афише.",
                                "en": "Organ concerts and separate programs are paid according to the schedule.",
                                "kk": "Орган концерттері мен жеке бағдарламалар афиша бойынша төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Органные концерты и отдельные программы оплачиваются по афише.",
                                "en": "Organ concerts and separate programs are paid according to the schedule.",
                                "kk": "Орган концерттері мен жеке бағдарламалар афиша бойынша төленеді."
                        },
                        "sortOrder": 30
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Музей Иммануила Канта 300 ₽.",
                                "en": "Immanuel Kant Museum ticket is 300 RUB.",
                                "kk": "Иммануил Кант музейіне билет 300 RUB."
                        },
                        "amount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Экскурсия",
                                "en": "Guided tour",
                                "kk": "Экскурсия"
                        },
                        "description": {
                                "ru": "Экскурсия Знакомство с музеем 700 ₽.",
                                "en": "Intro museum tour is 700 RUB.",
                                "kk": "Музеймен танысу экскурсиясы 700 RUB."
                        },
                        "amount": 700,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Отдельная опция",
                                "en": "Separate option",
                                "kk": "Жеке опция"
                        },
                        "description": {
                                "ru": "Органные концерты и отдельные программы оплачиваются по афише.",
                                "en": "Organ concerts and separate programs are paid according to the schedule.",
                                "kk": "Орган концерттері мен жеке бағдарламалар афиша бойынша төленеді."
                        },
                        "amount": 0,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "от центра Калининграда к острову Канта",
                                "en": "from central Kaliningrad to Kant Island",
                                "kk": "Калининград орталығынан Кант аралына"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min",
                                "kk": "5-15 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "GENERAL",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "во время концертов и служб действуют ограничения; на льготный билет нужен документ",
                                "en": "Access is limited during concerts and services; documents are needed for concessions",
                                "kk": "концерт пен қызмет кезінде шектеу болады; жеңілдік билеті үшін құжат керек"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Электронный билет",
                                "en": "E-ticket",
                                "kk": "Электрондық билет"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ",
                                "en": "Documents",
                                "kk": "Құжат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "WARM_LAYER",
                        "title": {
                                "ru": "Тёплый слой",
                                "en": "Warm layer",
                                "kk": "Жылы қабат"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "HEADPHONES",
                        "title": {
                                "ru": "Наушники",
                                "en": "Headphones",
                                "kk": "Құлаққап"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Агурские водопады', 300, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        3,
                        4,
                        5,
                        6,
                        9,
                        10,
                        11
                ],
                "note": {
                        "ru": "март-июнь и сентябрь-ноябрь; после дождей водопады полноводнее, в засуху могут пересыхать",
                        "en": "March-June and September-November; waterfalls are fuller after rain and may dry in drought",
                        "kk": "Наурыз-маусым және қыркүйек-қараша; жаңбырдан кейін сарқырама мол, құрғақта тартылуы мүмкін"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "высокий сезон июнь-август 09:00-19:00; зима 09:00-16:00; межсезонье 09:00-18:00, по погоде",
                        "en": "High season June-August 09:00-19:00; winter 09:00-16:00; shoulder seasons 09:00-18:00, weather dependent",
                        "kk": "Жоғары маусым маусым-тамыз 09:00-19:00; қыс 09:00-16:00; маусымаралық 09:00-18:00, ауа райына қарай"
                }
        },
        "priceNote": {
                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; на популярных КПП тарифы могут уточняться на месте.",
                "en": "One-time Sochi National Park pass is 300 RUB per person; popular checkpoints may confirm fees on site.",
                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; танымал бекеттерде төлем орнында нақтылануы мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3-5 h",
                        "kk": "3-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 60,
                "note": {
                        "ru": "20-35 мин от центра Сочи; 35-60 мин от Адлера",
                        "en": "20-35 min from central Sochi; 35-60 min from Adler",
                        "kk": "Сочи орталығынан 20-35 мин; Адлерден 35-60 мин"
                }
        },
        "roadCondition": "MOUNTAIN",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; на популярных КПП тарифы могут уточняться на месте.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; popular checkpoints may confirm fees on site.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; танымал бекеттерде төлем орнында нақтылануы мүмкін."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; на популярных КПП тарифы могут уточняться на месте.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; popular checkpoints may confirm fees on site.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; танымал бекеттерде төлем орнында нақтылануы мүмкін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; на популярных КПП тарифы могут уточняться на месте.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; popular checkpoints may confirm fees on site.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; танымал бекеттерде төлем орнында нақтылануы мүмкін."
                        },
                        "amount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "центр Сочи или Адлер - вход на Агурское ущелье",
                                "en": "central Sochi or Adler - entrance to Agura Gorge",
                                "kk": "Сочи орталығы немесе Адлер - Агура шатқалы кіреберісі"
                        },
                        "roadCondition": "MOUNTAIN",
                        "requires4x4": false,
                        "note": {
                                "ru": "20-60 мин",
                                "en": "20-60 min",
                                "kk": "20-60 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "тропа около 6.5 км; на мокрых камнях скользко, под обрывы не заходить",
                                "en": "Trail is about 6.5 km; wet rocks are slippery, do not go under cliffs",
                                "kk": "соқпақ шамамен 6,5 км; дымқыл тас тайғақ, жар астына кірмеңіз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Треккинговая обувь",
                                "en": "Trekking shoes",
                                "kk": "Треккинг аяқ киімі"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20,
                        "note": {
                                "ru": "1-1.5 л воды",
                                "en": "1-1.5 L of water",
                                "kk": "1-1,5 л су"
                        }
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные",
                                "en": "Cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Тропа Орлиные скалы и Мацеста', 300, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        9,
                        10,
                        11
                ],
                "note": {
                        "ru": "апрель-июнь и сентябрь-ноябрь; летом стартовать рано из-за жары",
                        "en": "April-June and September-November; start early in summer heat",
                        "kk": "Сәуір-маусым және қыркүйек-қараша; жазғы ыстықта ерте бастаңыз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "маршрут доступен круглый год; ориентируйтесь на часы Сочи НП: лето 09:00-19:00, зима 09:00-16:00, межсезонье 09:00-18:00",
                        "en": "Route is available year-round; use Sochi NP hours: summer 09:00-19:00, winter 09:00-16:00, shoulder seasons 09:00-18:00",
                        "kk": "Маршрут жыл бойы қолжетімді; Сочи ҰП уақытына сүйеніңіз: жаз 09:00-19:00, қыс 09:00-16:00, маусымаралық 09:00-18:00"
                }
        },
        "priceNote": {
                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; возможна отдельная касса или КПП.",
                "en": "One-time Sochi National Park pass is 300 RUB per person; a separate ticket point or checkpoint may apply.",
                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; бөлек касса немесе бекет болуы мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 150,
                "maxMinutes": 270,
                "note": {
                        "ru": "2.5-4.5 ч; 4-6 ч при связке с Агурой",
                        "en": "2.5-4.5 h; 4-6 h if combined with Agura",
                        "kk": "2,5-4,5 сағ; Агурамен бірге 4-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин от центра Сочи до Старой Мацесты",
                        "en": "20-35 min from central Sochi to Staraya Matsesta",
                        "kk": "Сочи орталығынан Старая Мацестаға 20-35 мин"
                }
        },
        "roadCondition": "MOUNTAIN",
        "feeItems": [
                {
                        "type": "ENTRANCE",
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; возможна отдельная касса или КПП.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; a separate ticket point or checkpoint may apply.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; бөлек касса немесе бекет болуы мүмкін."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; возможна отдельная касса или КПП.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; a separate ticket point or checkpoint may apply.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; бөлек касса немесе бекет болуы мүмкін."
                        },
                        "sortOrder": 10
                }
        ],
        "feeDetails": [
                {
                        "title": {
                                "ru": "Вход / базовый билет",
                                "en": "Entrance / base ticket",
                                "kk": "Кіру / негізгі билет"
                        },
                        "description": {
                                "ru": "Разовый пропуск в Сочинский нацпарк 300 ₽ с человека; возможна отдельная касса или КПП.",
                                "en": "One-time Sochi National Park pass is 300 RUB per person; a separate ticket point or checkpoint may apply.",
                                "kk": "Сочи ұлттық паркіне бір реттік рұқсат адамға 300 RUB; бөлек касса немесе бекет болуы мүмкін."
                        },
                        "amount": 300,
                        "currency": "RUB",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "центр Сочи - Старая Мацеста - КПП или старт тропы",
                                "en": "central Sochi - Staraya Matsesta - checkpoint or trailhead",
                                "kk": "Сочи орталығы - Старая Мацеста - бекет немесе соқпақ бастауы"
                        },
                        "roadCondition": "MOUNTAIN",
                        "requires4x4": false,
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min",
                                "kk": "20-35 мин"
                        },
                        "sortOrder": 10
                }
        ],
        "practicalNotes": [
                {
                        "noteType": "SAFETY",
                        "title": {
                                "ru": "Практическое примечание",
                                "en": "Practical note",
                                "kk": "Практикалық ескерту"
                        },
                        "body": {
                                "ru": "тропа около 5.3 км по гребню; в ветер или дождь не подходить к краю обрывов",
                                "en": "Trail is about 5.3 km along the ridge; in wind or rain keep away from cliff edges",
                                "kk": "соқпақ жота бойымен шамамен 5,3 км; желде немесе жаңбырда жар шетіне жақындамаңыз"
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOES",
                        "title": {
                                "ru": "Удобная обувь",
                                "en": "Comfortable shoes",
                                "kk": "Ыңғайлы аяқ киім"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 10,
                        "note": {
                                "ru": "Треккинговая обувь",
                                "en": "Trekking shoes",
                                "kk": "Треккинг аяқ киімі"
                        }
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Офлайн-карта",
                                "en": "Offline map",
                                "kk": "Офлайн карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные",
                                "en": "Cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
DELETE FROM place_fee_items f
USING matched_places m
WHERE f.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
DELETE FROM place_access_options a
USING matched_places m
WHERE a.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
DELETE FROM place_practical_notes p
USING matched_places m
WHERE p.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
DELETE FROM place_recommended_items r
USING matched_places m
WHERE r.place_id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
UPDATE places p
SET
    price_amount = COALESCE(m.price_amount, p.price_amount),
    price_currency = CASE WHEN m.price_amount IS NULL THEN p.price_currency ELSE 'RUB' END,
    visit_info = jsonb_strip_nulls(
        COALESCE(p.visit_info, '{}'::jsonb)
        || m.visit_info
        || jsonb_build_object('lastVerifiedAt', '2026-06-27')
    ),
    updated_at = NOW()
FROM matched_places m
WHERE p.id = m.place_id;

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
INSERT INTO place_visit_info (
    place_id,
    best_season_months,
    opening_hours,
    time_on_site_min_minutes,
    time_on_site_max_minutes,
    car_travel_time_min_minutes,
    car_travel_time_max_minutes,
    car_route_hint,
    road_condition,
    price_note,
    planning_note,
    last_verified_at
)
SELECT
    m.place_id,
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(COALESCE(m.visit_info #> '{season,months}', '[]'::jsonb))::smallint), '{}'),
    COALESCE(m.visit_info -> 'openingHours', '{}'::jsonb),
    NULLIF(m.visit_info #>> '{timeOnSite,minMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{timeOnSite,maxMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{carTravelTime,minMinutes}', '')::int,
    NULLIF(m.visit_info #>> '{carTravelTime,maxMinutes}', '')::int,
    COALESCE(m.visit_info #> '{accessOptions,0,routeHint}', '{}'::jsonb),
    COALESCE(m.visit_info ->> 'roadCondition', ''),
    COALESCE(m.visit_info -> 'priceNote', '{}'::jsonb),
    COALESCE(m.visit_info #> '{timeOnSite,note}', '{}'::jsonb),
    DATE '2026-06-27'
FROM matched_places m
ON CONFLICT (place_id) DO UPDATE SET
    best_season_months = EXCLUDED.best_season_months,
    opening_hours = EXCLUDED.opening_hours,
    time_on_site_min_minutes = EXCLUDED.time_on_site_min_minutes,
    time_on_site_max_minutes = EXCLUDED.time_on_site_max_minutes,
    car_travel_time_min_minutes = EXCLUDED.car_travel_time_min_minutes,
    car_travel_time_max_minutes = EXCLUDED.car_travel_time_max_minutes,
    car_route_hint = EXCLUDED.car_route_hint,
    road_condition = EXCLUDED.road_condition,
    price_note = EXCLUDED.price_note,
    planning_note = EXCLUDED.planning_note,
    last_verified_at = EXCLUDED.last_verified_at,
    updated_at = NOW();

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
INSERT INTO place_fee_items (
    place_id,
    fee_type,
    title,
    description,
    amount_min,
    amount_max,
    currency,
    unit,
    is_required,
    is_approximate,
    note,
    sort_order
)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'type', 'other')),
    COALESCE(item -> 'title', '{}'::jsonb),
    COALESCE(item -> 'description', '{}'::jsonb),
    NULLIF(item ->> 'minAmount', '')::numeric,
    NULLIF(item ->> 'maxAmount', '')::numeric,
    COALESCE(item ->> 'currency', ''),
    COALESCE(item ->> 'unit', ''),
    COALESCE((item ->> 'required')::boolean, false),
    COALESCE((item ->> 'isApproximate')::boolean, false),
    COALESCE(item -> 'note', '{}'::jsonb),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'feeItems', '[]'::jsonb)) WITH ORDINALITY AS fee(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
INSERT INTO place_access_options (
    place_id,
    transport_type,
    duration_min_minutes,
    duration_max_minutes,
    route_hint,
    road_condition,
    requires_4x4,
    parking_note,
    last_segment_note,
    note,
    sort_order
)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'transportType', 'car')),
    NULLIF(item ->> 'durationMinMinutes', '')::int,
    NULLIF(item ->> 'durationMaxMinutes', '')::int,
    COALESCE(item -> 'routeHint', '{}'::jsonb),
    COALESCE(item ->> 'roadCondition', ''),
    COALESCE((item ->> 'requires4x4')::boolean, false),
    COALESCE(item -> 'parkingNote', '{}'::jsonb),
    COALESCE(item -> 'lastSegmentNote', '{}'::jsonb),
    COALESCE(item -> 'note', '{}'::jsonb),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'accessOptions', '[]'::jsonb)) WITH ORDINALITY AS access(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
INSERT INTO place_practical_notes (
    place_id,
    note_type,
    title,
    body,
    priority,
    sort_order
)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'noteType', 'general')),
    COALESCE(item -> 'title', '{}'::jsonb),
    COALESCE(item -> 'body', '{}'::jsonb),
    lower(COALESCE(item ->> 'priority', '')),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'practicalNotes', '[]'::jsonb)) WITH ORDINALITY AS note(item, ordinality);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_russia_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'RU'
     AND p.deleted_at IS NULL
)
INSERT INTO place_recommended_items (
    place_id,
    item_type,
    title,
    importance,
    season,
    note,
    sort_order
)
SELECT
    m.place_id,
    lower(COALESCE(item ->> 'itemType', 'other')),
    COALESCE(item -> 'title', '{}'::jsonb),
    lower(COALESCE(item ->> 'importance', 'recommended')),
    lower(COALESCE(item ->> 'season', '')),
    COALESCE(item -> 'note', '{}'::jsonb),
    COALESCE((item ->> 'sortOrder')::int, ordinality::int * 10)
FROM matched_places m
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(m.visit_info -> 'recommendedItems', '[]'::jsonb)) WITH ORDINALITY AS rec(item, ordinality);

DROP TABLE seed_russia_visit_planning;
