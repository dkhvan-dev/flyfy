-- Seed Denmark visit-planning details from the 2026 attractions workbook.
CREATE TEMP TABLE seed_denmark_visit_planning (
    title_ru text PRIMARY KEY,
    price_amount numeric NULL,
    visit_info jsonb NOT NULL
);

INSERT INTO seed_denmark_visit_planning (title_ru, price_amount, visit_info)
VALUES
    ('Сады Тиволи', 180, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "апрель-сентябрь; вечер для подсветки, будни меньше очередей",
                        "en": "Best in April-September; evening or sunset gives the best atmosphere; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: сәуір-қыркүйек; кешкі уақыт немесе күн батар кез жақсы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезоны 2026: лето 7.04-20.09, Halloween 2.10-1.11, Christmas 13.11-3.01; часы по календарю.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Входной билет динамический, ориентир от 180 DKK; аттракционы/ride pass оплачиваются отдельно.",
                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 360,
                "note": {
                        "ru": "3-6 ч / вечер",
                        "en": "3 h-6 h; evening visit",
                        "kk": "3 сағ-6 сағ; кешкі сапар"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Входной билет динамический, ориентир от 180 DKK; аттракционы/ride pass оплачиваются отдельно.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 180,
                        "maxAmount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Входной билет динамический, ориентир от 180 DKK; аттракционы/ride pass оплачиваются отдельно.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
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
                                "ru": "Входной билет динамический, ориентир от 180 DKK; аттракционы/ride pass оплачиваются отдельно.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Сады Тиволи; 5-15 мин",
                                "en": "from central Copenhagen to Tivoli Gardens; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Проверять дату: цена и часы меняются по сезону и событиям.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Гавань Клинтхольм', 0, $${
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
                        "ru": "май-сентябрь, закат и ясная погода",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Публичная зона обычно доступна круглосуточно; сервисы/кафе сезонно.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Публичная гавань бесплатно; платно только еда, парковка/марина и туры.",
                "en": "Entry is free. Paid extras may include parking, tours or transport, food, events or optional services.",
                "kk": "Кіру тегін. тұрақ, тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 25,
                "maxMinutes": 30,
                "note": {
                        "ru": "25-30 мин",
                        "en": "25-30 min by car",
                        "kk": "25-30 мин көлікпен"
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
                                "ru": "Публичная гавань бесплатно; платно только еда, парковка/марина и туры.",
                                "en": "Entry is free. Paid extras may include parking, tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичная гавань бесплатно; платно только еда, парковка/марина и туры.",
                                "en": "Entry is free. Paid extras may include parking, tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "sortOrder": 40
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
                                "ru": "Публичная гавань бесплатно; платно только еда, парковка/марина и туры.",
                                "en": "Entry is free. Paid extras may include parking, tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 30,
                        "routeHint": {
                                "ru": "из Стеге / Мён к Гавань Клинтхольм; 25-30 мин",
                                "en": "from Stege / Møn to Klintholm Havn; 25-30 min by car",
                                "kk": "Стеге / Мён бағыты; 25-30 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "25-30 мин",
                                "en": "25-30 min by car",
                                "kk": "25-30 мин көлікпен"
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
                                "ru": "Удобная база перед Мёнс-Клинт; зимой часть сервисов закрыта.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Пляжный парк Амагер', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8,
                        5,
                        9
                ],
                "note": {
                        "ru": "июнь-август; май/сентябрь для прогулок",
                        "en": "Best in June, July, August, May, September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: маусым, шілде, тамыз, мамыр, қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая общественная зона 24/7; купание комфортно летом.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; платные опции — кафе, прокат, парковка.",
                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 240,
                "note": {
                        "ru": "1,5-4 ч",
                        "en": "1.5 h-4 h",
                        "kk": "1.5 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Вход бесплатный; платные опции — кафе, прокат, парковка.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; платные опции — кафе, прокат, парковка.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; платные опции — кафе, прокат, парковка.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Пляжный парк Амагер; 15-25 мин",
                                "en": "from central Copenhagen to Amager Strandpark; 15-25 min by car",
                                "kk": "Копенгаген орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Вода прохладная, ветер с пролива часто сильный.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальник",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF",
                                "en": "SPF",
                                "kk": "SPF"
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
    ('Купальня Islands Brygge', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8
                ],
                "note": {
                        "ru": "июнь-август; в жаркие будни утром",
                        "en": "Best in June-August; go in the morning for lighter crowds; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: маусым-тамыз; таңертең адам аздау; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 06:00-22:00; спасатели и полноценный режим в летний сезон.",
                        "en": "Typical listed hours include 06:00-22:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 06:00-22:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; шкафчики/сервисы могут отличаться по сезону.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Вход бесплатный; шкафчики/сервисы могут отличаться по сезону.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; шкафчики/сервисы могут отличаться по сезону.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; шкафчики/сервисы могут отличаться по сезону.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Купальня Islands Brygge; 5-15 мин",
                                "en": "from central Copenhagen to Islands Brygge Harbour Bath; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Купаться только при зеленом статусе воды/открытых зонах.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальник",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF",
                                "en": "SPF",
                                "kk": "SPF"
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
    ('TorvehallerneKBH', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; лучше будни до обеда",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-19:00 пн-пт, 10:00-18:00 сб-вс; отдельные лавки могут отличаться.",
                        "en": "Typical listed hours include 10:00-18:00, 10:00-19:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 10:00-19:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда и напитки по меню.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Вход бесплатный; еда и напитки по меню.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда и напитки по меню.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; еда и напитки по меню.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к TorvehallerneKBH; 5-15 мин",
                                "en": "from central Copenhagen to TorvehallerneKBH; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Пиковые часы обеда и выходные — толпы.",
                                "en": "Arrive outside peak hours to avoid crowds.",
                                "kk": "Адам көп уақыттан тыс барсаңыз ыңғайлырақ."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Aarhus Street Food', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер пятницы/субботы оживленнее",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно с 11:30 до 21:00; бары/события могут работать дольше.",
                        "en": "Typical listed hours include 11:30, 21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:30, 21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; блюда/напитки оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; блюда/напитки оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; блюда/напитки оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; блюда/напитки оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Aarhus Street Food; 5-10 мин",
                                "en": "from central Aarhus to Aarhus Street Food; 5-10 min by car",
                                "kk": "Орхус орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Свою еду приносить обычно нельзя; места быстрее заняты в пик.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Bruuns Galleri', 0, $${
        "bestTime": "AFTERNOON",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; для шопинга - будни",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн-пт 10:00-20:00, сб-вс 10:00-18:00.",
                        "en": "Typical listed hours include 10:00-18:00, 10:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 10:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Bruuns Galleri; 5-10 мин",
                                "en": "from central Aarhus to Bruuns Galleri; 5-10 min by car",
                                "kk": "Орхус орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Рядом с вокзалом, удобно в дождливую погоду.",
                                "en": "Paths can be wet or slippery after rain.",
                                "kk": "Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOPPER_BAG",
                        "title": {
                                "ru": "Сумка-шоппер",
                                "en": "Shopper bag",
                                "kk": "Шоппер сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Storms Pakhus', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер и выходные для атмосферы",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Food stalls: пн-чт 11:00-21:00, пт-сб 11:00-22:00, вс 11:00-21:00; бары дольше.",
                        "en": "Typical listed hours include 11:00-21:00, 11:00-22:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:00-21:00, 11:00-22:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда/бар отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Оденсе к Storms Pakhus; 5-10 мин",
                                "en": "from central Odense to Storms Pakhus; 5-10 min by car",
                                "kk": "Оденсе орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "В пиковые часы может быть шумно и тесно.",
                                "en": "Arrive outside peak hours to avoid crowds.",
                                "kk": "Адам көп уақыттан тыс барсаңыз ыңғайлырақ."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Rosengardcentret', 0, $${
        "bestTime": "AFTERNOON",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн-пт 10:00-19:00, сб-вс 10:00-17:00; отдельные магазины отличаются.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-19:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-19:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки/еда/кино отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Вход бесплатный; покупки/еда/кино отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки/еда/кино отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки/еда/кино отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Оденсе к Rosengardcentret; 10-15 мин",
                                "en": "from central Odense to Rosengårdcentret; 10-15 min by car",
                                "kk": "Оденсе орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Крупный торговый центр; удобно на авто.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOPPER_BAG",
                        "title": {
                                "ru": "Сумка-шоппер",
                                "en": "Shopper bag",
                                "kk": "Шоппер сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Aalborg Street Food', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [
                        3,
                        4,
                        5,
                        6,
                        7,
                        8,
                        9,
                        10
                ],
                "note": {
                        "ru": "март-октябрь/летние вечера",
                        "en": "Best in March-October; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: наурыз-қазан; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезон 2026 стартовал 13.03; в начале сезона пт-вс, далее часы расширяются - проверять афишу.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; блюда/бар/события отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; блюда/бар/события отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; блюда/бар/события отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; блюда/бар/события отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Aalborg Street Food; 5-10 мин",
                                "en": "from central Aalborg to Aalborg Street Food / The Lighthouse; 5-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Режим сильно сезонный и событийный.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Пляж Сённерстранд', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8,
                        4,
                        10
                ],
                "note": {
                        "ru": "июнь-август для пляжа; апрель-октябрь для прогулок/ветра",
                        "en": "Best in June, July, August, April, October; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: маусым, шілде, тамыз, сәуір, қазан; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая пляжная зона 24/7; сервисы сезонно.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; платны активности вроде blokart/прокат.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 240,
                "note": {
                        "ru": "1,5-4 ч",
                        "en": "1.5 h-4 h",
                        "kk": "1.5 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 60,
                "note": {
                        "ru": "45-60 мин от Рибе",
                        "en": "0.75 h-1 h by car",
                        "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Вход бесплатный; платны активности вроде blokart/прокат.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; платны активности вроде blokart/прокат.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; платны активности вроде blokart/прокат.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "из Рибе / Рёмё к Пляж Сённерстранд; 45-60 мин от Рибе",
                                "en": "from Ribe / Rømø to Sønderstrand, Rømø; 0.75 h-1 h by car",
                                "kk": "Рибе / Рёмё бағыты; 0.75 сағ-1 сағ көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "45-60 мин от Рибе",
                                "en": "0.75 h-1 h by car",
                                "kk": "0.75 сағ-1 сағ көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Очень широкий пляж; учитывайте ветер, приливы и правила заезда на песок.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальник",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF",
                                "en": "SPF",
                                "kk": "SPF"
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
    ('Пляж Фанё', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "июнь-август; сентябрь для прогулок и янтаря после штормов",
                        "en": "Best in June-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: маусым-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона 24/7; спасатели/сервисы летом на популярных участках.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Пляж бесплатный; паром на Фанё, прокат и туры к тюленям оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 300,
                "note": {
                        "ru": "2-5 ч / полдня",
                        "en": "2 h-5 h; half day",
                        "kk": "2 сағ-5 сағ; жарты күн"
                }
        },
        "carTravelTime": {
                "minMinutes": 27,
                "maxMinutes": 42,
                "note": {
                        "ru": "10-15 мин до парома + 12 мин паром + 5-15 мин",
                        "en": "27-42 min by car",
                        "kk": "27-42 мин көлікпен"
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
                                "ru": "Пляж бесплатный; паром на Фанё, прокат и туры к тюленям оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Пляж бесплатный; паром на Фанё, прокат и туры к тюленям оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Паром / транспорт",
                                "en": "Ferry / transport",
                                "kk": "Паром / көлік"
                        },
                        "description": {
                                "ru": "Паром или местный транспорт оплачивается отдельно.",
                                "en": "Ferry or local transport is paid separately.",
                                "kk": "Паром немесе жергілікті көлік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Паром или местный транспорт оплачивается отдельно.",
                                "en": "Ferry or local transport is paid separately.",
                                "kk": "Паром немесе жергілікті көлік бөлек төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "sortOrder": 40
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
                                "ru": "Пляж бесплатный; паром на Фанё, прокат и туры к тюленям оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Паром / транспорт",
                                "en": "Ferry / transport",
                                "kk": "Паром / көлік"
                        },
                        "description": {
                                "ru": "Паром или местный транспорт оплачивается отдельно.",
                                "en": "Ferry or local transport is paid separately.",
                                "kk": "Паром немесе жергілікті көлік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 27,
                        "durationMaxMinutes": 42,
                        "routeHint": {
                                "ru": "из Эсбьерг + паром к Пляж Фанё; 10-15 мин до парома + 12 мин паром + 5-15 мин",
                                "en": "from Esbjerg plus ferry to Fanø Beach; 27-42 min by car",
                                "kk": "Эсбьерг және паром бағыты; 27-42 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин до парома + 12 мин паром + 5-15 мин",
                                "en": "27-42 min by car",
                                "kk": "27-42 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Проверять расписание парома и ветер; часть пляжа используется для авто/кайтов.",
                                "en": "Check the current date schedule because hours or prices can change. Expect wind and dress for exposed weather. Check ferry times before leaving.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Жел болуы мүмкін, ашық ауаға сай киініңіз. Жолға шығар алдында паром уақытын тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальник",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF",
                                "en": "SPF",
                                "kk": "SPF"
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
    ('Esbjerg Street Food', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер выходного",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно: food stalls вс-чт 11:30-20:00, пт-сб 11:30-21:00; бары дольше.",
                        "en": "Typical listed hours include 11:30-20:00, 11:30-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:30-20:00, 11:30-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда/напитки отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Эсбьерга к Esbjerg Street Food; 5-10 мин",
                                "en": "from central Esbjerg to Esbjerg Street Food; 5-10 min by car",
                                "kk": "Эсбьерг орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "В соцсетях чаще появляются изменения часов и события.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Центр Хиллерёда', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        12
                ],
                "note": {
                        "ru": "май-сентябрь; декабрь для рождественской атмосферы",
                        "en": "Best in May, June, July, August, September, December; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр, маусым, шілде, тамыз, қыркүйек, желтоқсан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улицы доступны 24/7; магазины обычно дневные часы.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Публичный центр бесплатно; музеи, кафе и парковка отдельно.",
                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч + замок",
                        "en": "1 h-2 h; plus castle time",
                        "kk": "1 сағ-2 сағ; қамалға қосымша уақыт"
                }
        },
        "carTravelTime": {
                "minMinutes": 40,
                "maxMinutes": 55,
                "note": {
                        "ru": "40-55 мин",
                        "en": "40-55 min by car",
                        "kk": "40-55 мин көлікпен"
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
                                "ru": "Публичный центр бесплатно; музеи, кафе и парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичный центр бесплатно; музеи, кафе и парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Публичный центр бесплатно; музеи, кафе и парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 40,
                        "durationMaxMinutes": 55,
                        "routeHint": {
                                "ru": "из Копенгаген к Центр Хиллерёда; 40-55 мин",
                                "en": "from Copenhagen to Hillerød town centre; 40-55 min by car",
                                "kk": "Копенгаген бағыты; 40-55 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "40-55 мин",
                                "en": "40-55 min by car",
                                "kk": "40-55 мин көлікпен"
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
                                "ru": "Логично совместить с Фредериксборгом и садами.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Нюхавн', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "май-сентябрь; раннее утро для фото без толп",
                        "en": "Best in May-September; go in the morning for lighter crowds",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; таңертең адам аздау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Публичная зона 24/7; рестораны работают по своим графикам.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Бесплатная прогулка; канальные туры/кафе отдельно.",
                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "0,5-1,5 ч",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Бесплатная прогулка; канальные туры/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатная прогулка; канальные туры/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Бесплатная прогулка; канальные туры/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Нюхавн; 5-15 мин",
                                "en": "from central Copenhagen to Nyhavn; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Очень туристическое место; цены в кафе выше среднего.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Русалочка', 0, $${
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
                        "ru": "май-сентябрь; утро/закат для фото",
                        "en": "Best in May-September; go in the morning for lighter crowds; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; таңертең адам аздау; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Публичный памятник 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Осмотр бесплатно.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 40,
                "note": {
                        "ru": "20-40 мин",
                        "en": "20-40 min",
                        "kk": "20-40 мин"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин",
                        "en": "10-20 min by car",
                        "kk": "10-20 мин көлікпен"
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
                                "ru": "Осмотр бесплатно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр бесплатно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Осмотр бесплатно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Русалочка; 10-20 мин",
                                "en": "from central Copenhagen to The Little Mermaid; 10-20 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-20 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car",
                                "kk": "10-20 мин көлікпен"
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
                                "ru": "Лучше совмещать с Кастеллетом, набережной и Амалиенборгом.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера/телефон",
                                "en": "Camera or phone",
                                "kk": "Камера немесе телефон"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Дворец Амалиенборг', 140, $${
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
                        "ru": "апрель-октябрь; смена караула около полудня",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Музей обычно вт-вс 10:00-16:00; в высокий сезон ежедневно и иногда до 17:00.",
                        "en": "Typical listed hours include 10:00-16:00, 17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-16:00, 17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Площадь бесплатна; музей ориентир 140 DKK, онлайн часто дешевле примерно на 10 DKK; дети до 18 бесплатно.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Площадь бесплатна; музей ориентир 140 DKK, онлайн часто дешевле примерно на 10 DKK; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Площадь бесплатна; музей ориентир 140 DKK, онлайн часто дешевле примерно на 10 DKK; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Площадь бесплатна; музей ориентир 140 DKK, онлайн часто дешевле примерно на 10 DKK; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Дворец Амалиенборг; 5-15 мин",
                                "en": "from central Copenhagen to Amalienborg Museum / Palace Square; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Проверять закрытия из-за королевских мероприятий.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Reffen - Copenhagen Street Food', 0, $${
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
                        "ru": "май-сентябрь; теплый вечер",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Food stalls примерно 11:30-21:30; бары вс-чт до 22:00, пт-сб до 01:00; сезонно.",
                        "en": "Typical listed hours include 01:00, 11:30-21:30, 22:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 01:00, 11:30-21:30, 22:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда/бар отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1,5-3 ч",
                        "en": "1.5 h-3 h",
                        "kk": "1.5 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; еда/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Reffen - Copenhagen Street Food; 15-25 мин",
                                "en": "from central Copenhagen to Reffen; 15-25 min by car",
                                "kk": "Копенгаген орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
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
                                "ru": "На открытом воздухе: при ветре/дожде атмосфера хуже.",
                                "en": "Paths can be wet or slippery after rain.",
                                "kk": "Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Broens Street Food', 0, $${
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
                        "ru": "май-сентябрь; вечером после Нюхавна/Кристиансхавна",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Food stalls: вс-чт 11:30-20:30, пт-сб 11:00-21:00; бары могут работать дольше.",
                        "en": "Typical listed hours include 11:00-21:00, 11:30-20:30; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:00-21:00, 11:30-20:30; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда/напитки отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; еда/напитки отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Broens Street Food; 5-15 мин",
                                "en": "from central Copenhagen to Broens Street Food; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Зимой часть форматов может меняться.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Мясной квартал Кёдбюэн', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер четверга-субботы",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Район доступен 24/7; заведения открываются в основном днем/вечером.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Публичный район бесплатно; бары, галереи и рестораны отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Публичный район бесплатно; бары, галереи и рестораны отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичный район бесплатно; бары, галереи и рестораны отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Публичный район бесплатно; бары, галереи и рестораны отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Мясной квартал Кёдбюэн; 5-15 мин",
                                "en": "from central Copenhagen to Kødbyen / Meatpacking District; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Ночная зона: стандартная городская осторожность.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Стрёгет', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни утром меньше людей",
                        "en": "Best in year-round; go in the morning for lighter crowds; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең адам аздау; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пешеходная улица 24/7; магазины обычно 10:00-18:00/20:00.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Прогулка бесплатно; покупки/кафе отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Прогулка бесплатно; покупки/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Прогулка бесплатно; покупки/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Прогулка бесплатно; покупки/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Стрёгет; 0-10 мин",
                                "en": "from central Copenhagen to Strøget; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Одна из главных туристических улиц; много карманников в толпе.",
                                "en": "Arrive outside peak hours to avoid crowds.",
                                "kk": "Адам көп уақыттан тыс барсаңыз ыңғайлырақ."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Торговый центр Fisketorvet', 0, $${
        "bestTime": "AFTERNOON",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно 10:00-20:00; кино и рестораны могут работать дольше.",
                        "en": "Typical listed hours include 10:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки/кино/еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Торговый центр Fisketorvet; 10-15 мин",
                                "en": "from central Copenhagen to Fisketorvet Copenhagen Mall; 10-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Уточнять парковку/лимиты перед поездкой.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOPPER_BAG",
                        "title": {
                                "ru": "Сумка-шоппер",
                                "en": "Shopper bag",
                                "kk": "Шоппер сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('BROEN Shopping', 0, $${
        "bestTime": "AFTERNOON",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир: магазины пн-пт 10:00-19:00, сб-вс 10:00-17:00; рестораны дольше.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-19:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-19:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки и еда отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; покупки и еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки и еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки и еда отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Эсбьерга к BROEN Shopping; 5-10 мин",
                                "en": "from central Esbjerg to BROEN Shopping Esbjerg; 5-10 min by car",
                                "kk": "Эсбьерг орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Парковочный диск обязателен; режим отдельных арендаторов отличается.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SHOPPER_BAG",
                        "title": {
                                "ru": "Сумка-шоппер",
                                "en": "Shopper bag",
                                "kk": "Шоппер сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Лесная тропа утесов Клинтесковен', 0, $${
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
                        "ru": "май-сентябрь; сухая погода, утро",
                        "en": "Best in May-September; go in the morning for lighter crowds; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; таңертең адам аздау; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Тропы доступны круглый год в светлое время; лестницы/участки могут закрываться после осыпей.",
                        "en": "Natural area is best visited in daylight; trails may close after bad weather.",
                        "kk": "Табиғи аймаққа күн жарығында барған дұрыс; қолайсыз ауа райынан кейін соқпақ жабылуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Лесные тропы бесплатны; парковка у GeoCenter обычно платная, музей отдельно.",
                "en": "Entry is free. Paid extras may include parking.",
                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2 h-4 h",
                        "kk": "2 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 35,
                "note": {
                        "ru": "30-35 мин",
                        "en": "30-35 min by car",
                        "kk": "30-35 мин көлікпен"
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
                                "ru": "Лесные тропы бесплатны; парковка у GeoCenter обычно платная, музей отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лесные тропы бесплатны; парковка у GeoCenter обычно платная, музей отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Лесные тропы бесплатны; парковка у GeoCenter обычно платная, музей отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "из Стеге / Мён к Лесная тропа утесов Клинтесковен; 30-35 мин",
                                "en": "from Stege / Møn to Klinteskoven / Møns Klint forest trails; 30-35 min by car",
                                "kk": "Стеге / Мён бағыты; 30-35 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "30-35 мин",
                                "en": "30-35 min by car",
                                "kk": "30-35 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Держаться разметки и не подходить к краям меловых обрывов.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
    ('Дворец Кристиансборг', 215, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни утром",
                        "en": "Best in year-round; go in the morning for lighter crowds; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең адам аздау; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-17:00; отдельные королевские залы могут закрываться для мероприятий.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Комбинированный билет по основным зонам ориентир 215 DKK; онлайн может быть дешевле примерно на 10 DKK.",
                "en": "Adult/base admission is about 215 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 215 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Комбинированный билет по основным зонам ориентир 215 DKK; онлайн может быть дешевле примерно на 10 DKK.",
                                "en": "Adult/base admission is about 215 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 215 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 215,
                        "maxAmount": 215,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Комбинированный билет по основным зонам ориентир 215 DKK; онлайн может быть дешевле примерно на 10 DKK.",
                                "en": "Adult/base admission is about 215 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 215 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Комбинированный билет по основным зонам ориентир 215 DKK; онлайн может быть дешевле примерно на 10 DKK.",
                                "en": "Adult/base admission is about 215 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 215 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 215,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Дворец Кристиансборг; 0-10 мин",
                                "en": "from central Copenhagen to Christiansborg Palace; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Проверяйте закрытия Royal Reception Rooms.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Замок Розенборг', 140, $${
        "bestTime": "EARLY_MORNING",
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
                        "ru": "апрель-октябрь; раннее утро",
                        "en": "Best in April-October; go in the morning for lighter crowds",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; таңертең адам аздау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-17:00, летом может открываться с 09:00; сезонные исключения.",
                        "en": "Typical listed hours include 09:00, 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00, 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Ориентир взрослый 140 DKK; дети до 18 бесплатно; онлайн часто дешевле на 10 DKK.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Ориентир взрослый 140 DKK; дети до 18 бесплатно; онлайн часто дешевле на 10 DKK.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Ориентир взрослый 140 DKK; дети до 18 бесплатно; онлайн часто дешевле на 10 DKK.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Ориентир взрослый 140 DKK; дети до 18 бесплатно; онлайн часто дешевле на 10 DKK.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Замок Розенборг; 5-15 мин",
                                "en": "from central Copenhagen to Rosenborg Castle; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Сокровищница популярна, бывают очереди.",
                                "en": "Arrive outside peak hours to avoid crowds.",
                                "kk": "Адам көп уақыттан тыс барсаңыз ыңғайлырақ."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Круглая башня', 60, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; ясный день/закат",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыта большую часть года; часто 10:00-18:00, летом/вечерами до 20:00.",
                        "en": "Typical listed hours include 10:00-18:00, 20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый билет ориентир 60 DKK; дети/льготы дешевле.",
                "en": "Adult/base admission is about 60 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 60 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый билет ориентир 60 DKK; дети/льготы дешевле.",
                                "en": "Adult/base admission is about 60 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 60 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 60,
                        "maxAmount": 60,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый билет ориентир 60 DKK; дети/льготы дешевле.",
                                "en": "Adult/base admission is about 60 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 60 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый билет ориентир 60 DKK; дети/льготы дешевле.",
                                "en": "Adult/base admission is about 60 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 60 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 60,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Круглая башня; 0-10 мин",
                                "en": "from central Copenhagen to Rundetaarn / Round Tower; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Спиральный подъем без лифта до смотровой площадки.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера/телефон",
                                "en": "Camera or phone",
                                "kk": "Камера немесе телефон"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Церковь Спасителя', 75, $${
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
                        "ru": "апрель-октябрь; ясная погода без сильного ветра",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Башня в 2026: закрыта в январе; в сезон часто ежедневно 09:00-20:00.",
                        "en": "Typical listed hours include 09:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Церковь обычно бесплатна; башня ориентир 75 DKK, нужен слот.",
                "en": "Adult/base admission is about 75 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 75 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Церковь обычно бесплатна; башня ориентир 75 DKK, нужен слот.",
                                "en": "Adult/base admission is about 75 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 75 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 75,
                        "maxAmount": 75,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Церковь обычно бесплатна; башня ориентир 75 DKK, нужен слот.",
                                "en": "Adult/base admission is about 75 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 75 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Церковь обычно бесплатна; башня ориентир 75 DKK, нужен слот.",
                                "en": "Adult/base admission is about 75 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 75 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 75,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Церковь Спасителя; 5-15 мин",
                                "en": "from central Copenhagen to Church of Our Saviour / Vor Frelsers Kirke tower; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Внешняя лестница может закрываться из-за погоды; не всем комфортна высота.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Ұстамды киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Национальный музей Дании', 150, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливые/холодные дни",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно апр-окт ежедневно 10:00-17:00; ноя-март пн закрыт, вт-вс 10:00-17:00.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 150 DKK; онлайн ориентир 135 DKK; до 18 лет бесплатно.",
                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2 h-4 h",
                        "kk": "2 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый 150 DKK; онлайн ориентир 135 DKK; до 18 лет бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 150,
                        "maxAmount": 150,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 150 DKK; онлайн ориентир 135 DKK; до 18 лет бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 150 DKK; онлайн ориентир 135 DKK; до 18 лет бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 150,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Национальный музей Дании; 0-10 мин",
                                "en": "from central Copenhagen to National Museum of Denmark; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Большой музей: лучше выбрать 2–3 секции заранее.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Государственный музей искусств Дании', 140, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Вт-вс 10:00-18:00, ср до 20:00; пн закрыт.",
                        "en": "Typical listed hours include 10:00-18:00, 20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 140 DKK; до 18 бесплатно, youth/student дешевле.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Взрослый 140 DKK; до 18 бесплатно, youth/student дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 140 DKK; до 18 бесплатно, youth/student дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 140 DKK; до 18 бесплатно, youth/student дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Государственный музей искусств Дании; 5-15 мин",
                                "en": "from central Copenhagen to SMK – National Gallery of Denmark; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Хорошо совмещается с Розенборгом и Ботсадом.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Новая глиптотека Карлсберга', 145, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будний день",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно вт-вс 10:00-17:00, чт до 21:00; пн закрыт.",
                        "en": "Typical listed hours include 10:00-17:00, 21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 145 DKK; отдельные скидки/бесплатные дни проверять.",
                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1,5-3 ч",
                        "en": "1.5 h-3 h",
                        "kk": "1.5 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 145 DKK; отдельные скидки/бесплатные дни проверять.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 145,
                        "maxAmount": 145,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 145 DKK; отдельные скидки/бесплатные дни проверять.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 145 DKK; отдельные скидки/бесплатные дни проверять.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 145,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Новая глиптотека Карлсберга; 0-10 мин",
                                "en": "from central Copenhagen to Ny Carlsberg Glyptotek; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Зимний сад — отдельная причина зайти даже ненадолго.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Датский музей дизайна', 130, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Вт-вс 10:00-18:00, чт до 20:00; пн закрыт.",
                        "en": "Typical listed hours include 10:00-18:00, 20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 130 DKK; до 18 бесплатно.",
                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Взрослый ориентир 130 DKK; до 18 бесплатно.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 130,
                        "maxAmount": 130,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 130 DKK; до 18 бесплатно.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 130 DKK; до 18 бесплатно.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 130,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Датский музей дизайна; 5-15 мин",
                                "en": "from central Copenhagen to Designmuseum Danmark; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Удобно после Амалиенборга/набережной.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Художественный музей ARoS Aarhus', 190, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; ясный день для Rainbow Panorama",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно; в летний сезон часто 09:00-20:00 пн-пт и 09:00-17:00 выходные.",
                        "en": "Typical listed hours include 09:00-17:00, 09:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-17:00, 09:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый билет ориентир 190 DKK; цены/скидки могут зависеть от сезона.",
                "en": "Adult/base admission is about 190 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 190 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Взрослый билет ориентир 190 DKK; цены/скидки могут зависеть от сезона.",
                                "en": "Adult/base admission is about 190 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 190 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 190,
                        "maxAmount": 190,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый билет ориентир 190 DKK; цены/скидки могут зависеть от сезона.",
                                "en": "Adult/base admission is about 190 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 190 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый билет ориентир 190 DKK; цены/скидки могут зависеть от сезона.",
                                "en": "Adult/base admission is about 190 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 190 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 190,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Художественный музей ARoS Aarhus; 5-10 мин",
                                "en": "from central Aarhus to ARoS Aarhus Art Museum; 5-10 min by car",
                                "kk": "Орхус орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Смотровой круг на крыше лучше в ясную погоду.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Датский архитектурный центр', 135, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; послеобеденные часы",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн/чт/пт 10:00-21:00; остальные дни 10:00-18:00.",
                        "en": "Typical listed hours include 10:00-18:00, 10:00-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 10:00-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 135 DKK; молодежь/студенты около 60 DKK; дети до 18 бесплатно с платящим взрослым.",
                "en": "Adult/base admission is about 135 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 135 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Взрослый 135 DKK; молодежь/студенты около 60 DKK; дети до 18 бесплатно с платящим взрослым.",
                                "en": "Adult/base admission is about 135 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 135 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 135,
                        "maxAmount": 135,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 135 DKK; молодежь/студенты около 60 DKK; дети до 18 бесплатно с платящим взрослым.",
                                "en": "Adult/base admission is about 135 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 135 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 135 DKK; молодежь/студенты около 60 DKK; дети до 18 бесплатно с платящим взрослым.",
                                "en": "Adult/base admission is about 135 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 135 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 135,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Датский архитектурный центр; 5-15 мин",
                                "en": "from central Copenhagen to Danish Architecture Center / DAC; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
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
                                "ru": "Удобно совместить с Кристиансборгом и набережной.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Copenhagen Contemporary', 140, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн закрыт; вт/ср/пт/сб/вс 11:00-18:00, чт 11:00-21:00.",
                        "en": "Typical listed hours include 11:00-18:00, 11:00-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:00-18:00, 11:00-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 140 DKK; до 18 обычно бесплатно.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Взрослый ориентир 140 DKK; до 18 обычно бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 140 DKK; до 18 обычно бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 140 DKK; до 18 обычно бесплатно.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Copenhagen Contemporary; 15-25 мин",
                                "en": "from central Copenhagen to Copenhagen Contemporary; 15-25 min by car",
                                "kk": "Копенгаген орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
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
                                "ru": "Совместить с Reffen/Refshaleøen.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Ботанический сад Копенгагена', 0, $${
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
                        "ru": "апрель-октябрь; весна для цветения",
                        "en": "Best in April-October; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сад: примерно 08:30-18:00 в сезон и 08:30-16:00 зимой; оранжереи по отдельному графику.",
                        "en": "Typical listed hours include 08:30-16:00, 08:30-18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 08:30-16:00, 08:30-18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Сад бесплатный; Palm House/Butterfly House отдельно, ориентир около 70 DKK.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car",
                        "kk": "5-15 мин көлікпен"
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
                                "ru": "Сад бесплатный; Palm House/Butterfly House отдельно, ориентир около 70 DKK.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сад бесплатный; Palm House/Butterfly House отдельно, ориентир около 70 DKK.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Сад бесплатный; Palm House/Butterfly House отдельно, ориентир около 70 DKK.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Ботанический сад Копенгагена; 5-15 мин",
                                "en": "from central Copenhagen to Botanical Garden Copenhagen; 5-15 min by car",
                                "kk": "Копенгаген орталығы бағыты; 5-15 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car",
                                "kk": "5-15 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Бесплатная часть хороша для короткой паузы между музеями.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Королевский сад', 0, $${
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
                        "ru": "май-сентябрь; утро/пикник",
                        "en": "Best in May-September; go in the morning for lighter crowds; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; таңертең адам аздау; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 07:00-17:00/22:00 по сезону; летом дольше.",
                        "en": "Typical listed hours include 07:00-17:00, 22:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:00-17:00, 22:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Королевский сад; 0-10 мин",
                                "en": "from central Copenhagen to Kongens Have / King's Garden; 0-10 min by car",
                                "kk": "Копенгаген орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Сады вокруг Розенборга; зимой закрываются раньше.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Сады Фредериксберг', 0, $${
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
                        "ru": "апрель-октябрь; золотая осень",
                        "en": "Best in April-October; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно с 06:00 до сезонного закрытия 17:00-22:00.",
                        "en": "Typical listed hours include 06:00, 17:00-22:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 06:00, 17:00-22:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин",
                        "en": "10-20 min by car",
                        "kk": "10-20 мин көлікпен"
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Сады Фредериксберг; 10-20 мин",
                                "en": "from central Copenhagen to Frederiksberg Gardens; 10-20 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-20 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car",
                                "kk": "10-20 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Рядом с зоопарком; можно совместить.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Парк Суперкилен', 0, $${
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
                        "ru": "май-сентябрь; дневной свет для фото",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Публичный парк 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин",
                        "en": "10-20 min by car",
                        "kk": "10-20 мин көлікпен"
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Парк Суперкилен; 10-20 мин",
                                "en": "from central Copenhagen to Superkilen Park; 10-20 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-20 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car",
                                "kk": "10-20 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Городской парк-дизайн; ночью обычная городская осторожность.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Королевская опера Дании', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер с подсветкой/спектаклем",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Здание/фойе по расписанию спектаклей и экскурсий; наружная зона доступна ежедневно.",
                        "en": "Usually open daily during the listed season; holiday hours may differ.",
                        "kk": "Көрсетілген маусымда әдетте күн сайын ашық; мереке күндері өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Осмотр здания снаружи бесплатно; спектакли и экскурсии по отдельным билетам.",
                "en": "Entry is free. Paid extras may include tours or transport.",
                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 240,
                "note": {
                        "ru": "30-60 мин / спектакль 2-4 ч",
                        "en": "0.5 h-4 h",
                        "kk": "0.5 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин",
                        "en": "10-20 min by car",
                        "kk": "10-20 мин көлікпен"
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
                                "ru": "Осмотр здания снаружи бесплатно; спектакли и экскурсии по отдельным билетам.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр здания снаружи бесплатно; спектакли и экскурсии по отдельным билетам.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
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
                                "ru": "Осмотр здания снаружи бесплатно; спектакли и экскурсии по отдельным билетам.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Королевская опера Дании; 10-20 мин",
                                "en": "from central Copenhagen to Royal Danish Opera House; 10-20 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-20 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car",
                                "kk": "10-20 мин көлікпен"
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
                                "ru": "Билеты на постановки сильно зависят от даты и мест.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Копенгагенский зоопарк', 260, $${
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
                        "ru": "май-сентябрь; будний день",
                        "en": "Best in May-September; weekdays are usually quieter; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; жұмыс күндері тынышырақ; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно; летом может работать 09:00-20:00, в межсезонье короче.",
                        "en": "Typical listed hours include 09:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 260 DKK; ребенок 160 DKK; башня обычно 25 DKK отдельно.",
                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 20,
                "note": {
                        "ru": "10-20 мин",
                        "en": "10-20 min by car",
                        "kk": "10-20 мин көлікпен"
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
                                "ru": "Взрослый 260 DKK; ребенок 160 DKK; башня обычно 25 DKK отдельно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 260,
                        "maxAmount": 260,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 260 DKK; ребенок 160 DKK; башня обычно 25 DKK отдельно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 260 DKK; ребенок 160 DKK; башня обычно 25 DKK отдельно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 260,
                        "currency": "DKK",
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
                                "ru": "из центр Копенгагена к Копенгагенский зоопарк; 10-20 мин",
                                "en": "from central Copenhagen to Copenhagen Zoo; 10-20 min by car",
                                "kk": "Копенгаген орталығы бағыты; 10-20 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car",
                                "kk": "10-20 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Рядом с садами Фредериксберг; удобен для семей.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
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
                }
        ]
}$$::jsonb),
    ('Национальный аквариум Den Bla Planet', 249, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно 10:00-17:00; каникулы/праздники могут быть дольше.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 249 DKK, online 219 DKK; в peak day до 259 DKK, online 229 DKK.",
                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Взрослый 249 DKK, online 219 DKK; в peak day до 259 DKK, online 229 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 249,
                        "maxAmount": 249,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 249 DKK, online 219 DKK; в peak day до 259 DKK, online 229 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 249 DKK, online 219 DKK; в peak day до 259 DKK, online 229 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 249,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Национальный аквариум Den Bla Planet; 15-25 мин",
                                "en": "from central Copenhagen to Den Blå Planet / National Aquarium Denmark; 15-25 min by car",
                                "kk": "Копенгаген орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Близко к аэропорту; удобно в день прилета/вылета.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
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
                }
        ]
}$$::jsonb),
    ('CopenHill', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; для крыши - ясная погода, для лыж - по расписанию",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Летом rooftop часто 10:00-18:00/19:00; ski slope по отдельному графику, пн часто закрыт.",
                        "en": "Typical listed hours include 10:00-18:00, 19:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 19:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Руфтоп/лестница/лифт обычно бесплатно; лыжи, аренда, инструктор и climbing wall отдельно.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Руфтоп/лестница/лифт обычно бесплатно; лыжи, аренда, инструктор и climbing wall отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Руфтоп/лестница/лифт обычно бесплатно; лыжи, аренда, инструктор и climbing wall отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Руфтоп/лестница/лифт обычно бесплатно; лыжи, аренда, инструктор и climbing wall отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Копенгагена к CopenHill; 15-25 мин",
                                "en": "from central Copenhagen to CopenHill / Amager Bakke; 15-25 min by car",
                                "kk": "Копенгаген орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
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
                                "ru": "Ветрено на крыше; лыжи на искусственном покрытии.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Bakken', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8
                ],
                "note": {
                        "ru": "апрель-август; будни",
                        "en": "Best in April-August; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: сәуір-тамыз; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезон обычно конец марта-август/сентябрь + спецсезоны; часы по календарю.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аттракционы по билетам/ride pass отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car",
                        "kk": "20-35 мин көлікпен"
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
                                "ru": "Вход бесплатный; аттракционы по билетам/ride pass отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аттракционы по билетам/ride pass отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
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
                                "ru": "Вход бесплатный; аттракционы по билетам/ride pass отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "из центр Копенгагена к Bakken; 20-35 мин",
                                "en": "from central Copenhagen to Dyrehavsbakken / Bakken; 20-35 min by car",
                                "kk": "Копенгаген орталығы бағыты; 20-35 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car",
                                "kk": "20-35 мин көлікпен"
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
                                "ru": "Старейший парк аттракционов рядом с Dyrehaven.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Старый город Den Gamle By', 205, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        5,
                        6,
                        7,
                        8,
                        9,
                        12
                ],
                "note": {
                        "ru": "май-сентябрь; декабрь для рождественских декораций",
                        "en": "Best in May, June, July, August, September, December; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр, маусым, шілде, тамыз, қыркүйек, желтоқсан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыт 365 дней; часто 10:00-16:00 зимой и 10:00-17:00 в основной сезон.",
                        "en": "Typical listed hours include 10:00-16:00, 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-16:00, 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Сезонный взрослый билет ориентир 155–205 DKK; в высокий сезон/Рождество дороже.",
                "en": "Adult/base admission is about 205 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 205 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Сезонный взрослый билет ориентир 155–205 DKK; в высокий сезон/Рождество дороже.",
                                "en": "Adult/base admission is about 205 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 205 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 205,
                        "maxAmount": 205,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сезонный взрослый билет ориентир 155–205 DKK; в высокий сезон/Рождество дороже.",
                                "en": "Adult/base admission is about 205 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 205 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Сезонный взрослый билет ориентир 155–205 DKK; в высокий сезон/Рождество дороже.",
                                "en": "Adult/base admission is about 205 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 205 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 205,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Старый город Den Gamle By; 5-10 мин",
                                "en": "from central Aarhus to Den Gamle By; 5-10 min by car",
                                "kk": "Орхус орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Большой open-air музей: лучше идти в сухую погоду.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Музей Moesgaard', 180, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно вт/пт/сб/вс 10:00-17:00, ср 10:00-21:00, пн закрыт; каникулы могут отличаться.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 180 DKK; дети/молодежь дешевле/бесплатно по правилам музея.",
                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2 h-4 h",
                        "kk": "2 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car",
                        "kk": "15-25 мин көлікпен"
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
                                "ru": "Взрослый ориентир 180 DKK; дети/молодежь дешевле/бесплатно по правилам музея.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 180,
                        "maxAmount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 180 DKK; дети/молодежь дешевле/бесплатно по правилам музея.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 180 DKK; дети/молодежь дешевле/бесплатно по правилам музея.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из центр Орхуса к Музей Moesgaard; 15-25 мин",
                                "en": "from central Aarhus to Moesgaard Museum; 15-25 min by car",
                                "kk": "Орхус орталығы бағыты; 15-25 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car",
                                "kk": "15-25 мин көлікпен"
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
                                "ru": "Современный музей археологии; крыша/окрестности хороши для прогулки.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Орхусский собор', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дневной свет",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно дневные часы, часто 10:00-16:00/17:00; во время служб доступ ограничен.",
                        "en": "Typical listed hours include 10:00-16:00, 17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-16:00, 17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования/концерты отдельно.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 60,
                "note": {
                        "ru": "30-60 мин",
                        "en": "0.5 h-1 h",
                        "kk": "0.5 сағ-1 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Вход обычно бесплатный; пожертвования/концерты отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования/концерты отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход обычно бесплатный; пожертвования/концерты отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Орхусский собор; 0-10 мин",
                                "en": "from central Aarhus to Aarhus Cathedral; 0-10 min by car",
                                "kk": "Орхус орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Уточнять режим служб и концертов.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Ұстамды киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Dokk1', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Библиотека обычно пн-пт 08:00-22:00, выходные 10:00-16:00; отдельные сервисы отличаются.",
                        "en": "Typical listed hours include 08:00-22:00, 10:00-16:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 08:00-22:00, 10:00-16:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; события/парковка отдельно.",
                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; события/парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; события/парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; события/парковка отдельно.",
                                "en": "Entry is free. Paid extras may include parking, food, events or optional services.",
                                "kk": "Кіру тегін. тұрақ, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Dokk1; 0-10 мин",
                                "en": "from central Aarhus to Dokk1; 0-10 min by car",
                                "kk": "Орхус орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Хорошо для паузы, вида на гавань и семей с детьми.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Tivoli Friheden', 180, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "апрель-сентябрь; будни и вечерние события",
                        "en": "Best in April-September; evening or sunset gives the best atmosphere; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: сәуір-қыркүйек; кешкі уақыт немесе күн батар кез жақсы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезонный парк; летом часто открывается около 11:00-11:30, часы по календарю.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход ориентир 180 DKK; ride pass/аттракционы отдельно или пакетами.",
                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Вход ориентир 180 DKK; ride pass/аттракционы отдельно или пакетами.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 180,
                        "maxAmount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход ориентир 180 DKK; ride pass/аттракционы отдельно или пакетами.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
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
                                "ru": "Вход ориентир 180 DKK; ride pass/аттракционы отдельно или пакетами.",
                                "en": "Adult/base admission is about 180 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 180 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 180,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аттракционы / ride pass",
                                "en": "Rides / ride pass",
                                "kk": "Аттракциондар / ride pass"
                        },
                        "description": {
                                "ru": "Аттракционы и ride pass оплачиваются отдельно.",
                                "en": "Rides and ride passes are paid separately.",
                                "kk": "Аттракциондар мен ride pass бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Орхуса к Tivoli Friheden; 10-15 мин",
                                "en": "from central Aarhus to Tivoli Friheden; 10-15 min by car",
                                "kk": "Орхус орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Цены и часы зависят от концертов и сезона.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Олений парк Марселисборг', 0, $${
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
                        "ru": "апрель-октябрь; утро",
                        "en": "Best in April-October; go in the morning for lighter crowds; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; таңертең адам аздау; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно открыт от восхода до заката; закрытия возможны по уходу за животными.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Орхуса к Олений парк Марселисборг; 10-15 мин",
                                "en": "from central Aarhus to Marselisborg Deer Park; 10-15 min by car",
                                "kk": "Орхус орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Не кормить животных хлебом; соблюдать дистанцию.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Ботанический сад Орхуса', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "апрель-октябрь; оранжереи - круглый год",
                        "en": "Best in year-round; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: жыл бойы; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сад открыт день/ночь; Greenhouses обычно 09:00-16:00/17:00 по сезону, выходные с 10:00.",
                        "en": "Typical listed hours include 09:00-16:00, 10:00, 17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-16:00, 10:00, 17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Сад и оранжереи обычно бесплатны.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Сад и оранжереи обычно бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сад и оранжереи обычно бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Сад и оранжереи обычно бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Ботанический сад Орхуса; 5-10 мин",
                                "en": "from central Aarhus to Aarhus Botanical Garden; 5-10 min by car",
                                "kk": "Орхус орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Хорошее бесплатное место рядом с Den Gamle By.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Salling Rooftop Aarhus', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; ясный закат",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно пн-пт 10:00-20:00, сб 10:00-19:00, вс 10:00-18:00.",
                        "en": "Typical listed hours include 10:00-18:00, 10:00-19:00, 10:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 10:00-19:00, 10:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; кафе/бар отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 60,
                "note": {
                        "ru": "30-60 мин",
                        "en": "0.5 h-1 h",
                        "kk": "0.5 сағ-1 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; кафе/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; кафе/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход бесплатный; кафе/бар отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Орхуса к Salling Rooftop Aarhus; 0-10 мин",
                                "en": "from central Aarhus to Salling Rooftop Aarhus; 0-10 min by car",
                                "kk": "Орхус орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Может закрываться из-за частных событий/погоды.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін."
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
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера/телефон",
                                "en": "Camera or phone",
                                "kk": "Камера немесе телефон"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Дом Ханса Кристиана Андерсена', 165, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будний день",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-17:00, летом до 18:00; сезонные дни закрытия возможны.",
                        "en": "Typical listed hours include 10:00-17:00, 18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 165 DKK; дети/молодежь по правилам музея.",
                "en": "Adult/base admission is about 165 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 165 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1,5-3 ч",
                        "en": "1.5 h-3 h",
                        "kk": "1.5 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 165 DKK; дети/молодежь по правилам музея.",
                                "en": "Adult/base admission is about 165 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 165 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 165,
                        "maxAmount": 165,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 165 DKK; дети/молодежь по правилам музея.",
                                "en": "Adult/base admission is about 165 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 165 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аудиогид / приложение",
                                "en": "Audio guide / app",
                                "kk": "Аудиогид / қолданба"
                        },
                        "description": {
                                "ru": "Аудиогид или приложение лучше взять при посещении; условия и язык уточняйте на месте.",
                                "en": "Audio guide or app is useful for the visit; check availability and language on site.",
                                "kk": "Аудиогид немесе қолданба сапарға пайдалы; қолжетімділік пен тілді орнында нақтылаңыз."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аудиогид или приложение лучше взять при посещении; условия и язык уточняйте на месте.",
                                "en": "Audio guide or app is useful for the visit; check availability and language on site.",
                                "kk": "Аудиогид немесе қолданба сапарға пайдалы; қолжетімділік пен тілді орнында нақтылаңыз."
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
                                "ru": "Взрослый ориентир 165 DKK; дети/молодежь по правилам музея.",
                                "en": "Adult/base admission is about 165 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 165 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 165,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аудиогид / приложение",
                                "en": "Audio guide / app",
                                "kk": "Аудиогид / қолданба"
                        },
                        "description": {
                                "ru": "Аудиогид или приложение лучше взять при посещении; условия и язык уточняйте на месте.",
                                "en": "Audio guide or app is useful for the visit; check availability and language on site.",
                                "kk": "Аудиогид немесе қолданба сапарға пайдалы; қолжетімділік пен тілді орнында нақтылаңыз."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Оденсе к Дом Ханса Кристиана Андерсена; 0-10 мин",
                                "en": "from central Odense to H.C. Andersen House; 0-10 min by car",
                                "kk": "Оденсе орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Лучше брать аудиогид/приложение и не спешить.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Фюнская деревня', 125, $${
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
                        "ru": "май-сентябрь; сухая погода",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезонно, часто 10:00-17:00 в основной период; зимой ограниченно/закрыто.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 125 DKK; сезонные скидки/семейные билеты проверять.",
                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Взрослый ориентир 125 DKK; сезонные скидки/семейные билеты проверять.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 125,
                        "maxAmount": 125,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 125 DKK; сезонные скидки/семейные билеты проверять.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 125 DKK; сезонные скидки/семейные билеты проверять.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 125,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Оденсе к Фюнская деревня; 10-15 мин",
                                "en": "from central Odense to The Funen Village; 10-15 min by car",
                                "kk": "Оденсе орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Open-air музей; обувь по погоде.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Зоопарк Оденсе', 225, $${
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
                        "ru": "апрель-октябрь; будни",
                        "en": "Best in April-October; weekdays are usually quieter; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; жұмыс күндері тынышырақ; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открывается обычно с 09:00; закрытие 17:00-19:00 по сезону.",
                        "en": "Typical listed hours include 09:00, 17:00-19:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00, 17:00-19:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 225 DKK; детский билет дешевле; цены могут меняться по дате.",
                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Взрослый ориентир 225 DKK; детский билет дешевле; цены могут меняться по дате.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 225,
                        "maxAmount": 225,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 225 DKK; детский билет дешевле; цены могут меняться по дате.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 225 DKK; детский билет дешевле; цены могут меняться по дате.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 225,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Оденсе к Зоопарк Оденсе; 10-15 мин",
                                "en": "from central Odense to Odense Zoo; 10-15 min by car",
                                "kk": "Оденсе орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Хорошо для семей; закладывайте время на кормления/шоу.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
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
                }
        ]
}$$::jsonb),
    ('Музей Brandts', 130, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн закрыт; вт/ср/пт/вс 10:00-17:00, чт 10:00-20:00, сб 10:00-18:00.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-18:00, 10:00-20:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-18:00, 10:00-20:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 130 DKK; студенты/молодежь дешевле.",
                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 130 DKK; студенты/молодежь дешевле.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 130,
                        "maxAmount": 130,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 130 DKK; студенты/молодежь дешевле.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 130 DKK; студенты/молодежь дешевле.",
                                "en": "Adult/base admission is about 130 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 130 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 130,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Оденсе к Музей Brandts; 0-10 мин",
                                "en": "from central Odense to Brandts; 0-10 min by car",
                                "kk": "Оденсе орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Современное искусство и фото; удобно в центре.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Датский железнодорожный музей', 120, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; семьи с детьми",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно пн/вт/чт/пт 10:00-16:00, ср 09:00-21:00, выходные 09:00-16:00; летом дольше.",
                        "en": "Typical listed hours include 09:00-16:00, 09:00-21:00, 10:00-16:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-16:00, 09:00-21:00, 10:00-16:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 120 DKK; детям часто бесплатно/льготно по возрасту.",
                "en": "Adult/base admission is about 120 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 120 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1,5-3 ч",
                        "en": "1.5 h-3 h",
                        "kk": "1.5 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 120 DKK; детям часто бесплатно/льготно по возрасту.",
                                "en": "Adult/base admission is about 120 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 120 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 120,
                        "maxAmount": 120,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 120 DKK; детям часто бесплатно/льготно по возрасту.",
                                "en": "Adult/base admission is about 120 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 120 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 120 DKK; детям часто бесплатно/льготно по возрасту.",
                                "en": "Adult/base admission is about 120 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 120 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 120,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Оденсе к Датский железнодорожный музей; 0-10 мин",
                                "en": "from central Odense to Danish Railway Museum; 0-10 min by car",
                                "kk": "Оденсе орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Проверять спецпоезда и праздничные закрытия.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Парк Munke Mose', 0, $${
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
                        "ru": "май-сентябрь; пикник/лодки",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Парк 24/7; лодки и кафе сезонно.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; лодки/круизы по реке платные.",
                "en": "Entry is free. Paid extras may include tours or transport.",
                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 120,
                "note": {
                        "ru": "45-120 мин",
                        "en": "0.75 h-2 h",
                        "kk": "0.75 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Вход бесплатный; лодки/круизы по реке платные.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; лодки/круизы по реке платные.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
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
                                "ru": "Вход бесплатный; лодки/круизы по реке платные.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Оденсе к Парк Munke Mose; 0-10 мин",
                                "en": "from central Odense to Munke Mose; 0-10 min by car",
                                "kk": "Оденсе орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Хорошо совместить с прогулкой по реке Odense Å.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Замок Эгесков', 300, $${
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
                        "ru": "май-сентябрь; июнь для садов",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезонно: весна-осень, обычно 10:00-17:00/18:00; отдельные зоны по расписанию.",
                        "en": "Typical listed hours include 10:00-17:00, 18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Дневной билет сезонный, ориентир 300 DKK; онлайн/пакеты и annual pass отличаются.",
                "en": "Adult/base admission is about 300 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 300 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car",
                        "kk": "30-40 мин көлікпен"
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
                                "ru": "Дневной билет сезонный, ориентир 300 DKK; онлайн/пакеты и annual pass отличаются.",
                                "en": "Adult/base admission is about 300 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 300 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 300,
                        "maxAmount": 300,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Дневной билет сезонный, ориентир 300 DKK; онлайн/пакеты и annual pass отличаются.",
                                "en": "Adult/base admission is about 300 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 300 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Дневной билет сезонный, ориентир 300 DKK; онлайн/пакеты и annual pass отличаются.",
                                "en": "Adult/base admission is about 300 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 300 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 300,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 40,
                        "routeHint": {
                                "ru": "из Оденсе к Замок Эгесков; 30-40 мин",
                                "en": "from Odense to Egeskov Castle; 30-40 min by car",
                                "kk": "Оденсе бағыты; 30-40 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car",
                                "kk": "30-40 мин көлікпен"
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
                                "ru": "Большая территория с садами и музеями; лучше сухая погода.",
                                "en": "Allow extra time for walking across a large area.",
                                "kk": "Аумағы кең, жаяу жүруге қосымша уақыт қалдырыңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Зоопарк Ольборга', 249, $${
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
                        "ru": "апрель-октябрь; будни",
                        "en": "Best in April-October; weekdays are usually quieter; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; жұмыс күндері тынышырақ; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыт почти круглый год; обычно 10:00-17:00/18:00, летом дольше.",
                        "en": "Typical listed hours include 10:00-17:00, 18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый 249 DKK; ребенок 149 DKK; онлайн обычно скидка около 10 DKK.",
                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Взрослый 249 DKK; ребенок 149 DKK; онлайн обычно скидка около 10 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 249,
                        "maxAmount": 249,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый 249 DKK; ребенок 149 DKK; онлайн обычно скидка около 10 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый 249 DKK; ребенок 149 DKK; онлайн обычно скидка около 10 DKK.",
                                "en": "Adult/base admission is about 249 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 249 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 249,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Зоопарк Ольборга; 5-10 мин",
                                "en": "from central Aalborg to Aalborg Zoo; 5-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Уточнять кормления и вечерние события.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
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
                }
        ]
}$$::jsonb),
    ('Центр Утзона', 110, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будний день",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно пн закрыт; вт/ср/пт 11:00-17:00, чт 11:00-21:00, сб-вс 10:00-17:00.",
                        "en": "Typical listed hours include 10:00-17:00, 11:00-17:00, 11:00-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 11:00-17:00, 11:00-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 110 DKK; студенты/дети дешевле.",
                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 110 DKK; студенты/дети дешевле.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 110,
                        "maxAmount": 110,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 110 DKK; студенты/дети дешевле.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 110 DKK; студенты/дети дешевле.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 110,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Центр Утзона; 0-10 мин",
                                "en": "from central Aalborg to Utzon Center; 0-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Архитектура у набережной; удобно совместить с прогулкой.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Музей современного искусства Kunsten', 140, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Пн закрыт; вт 10:00-17:00, ср-чт 10:00-21:00, пт-вс 10:00-17:00.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-21:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-21:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 140 DKK; молодежь/студенты дешевле.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 140 DKK; молодежь/студенты дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 140 DKK; молодежь/студенты дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 140 DKK; молодежь/студенты дешевле.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Музей современного искусства Kunsten; 5-10 мин",
                                "en": "from central Aalborg to Kunsten Museum of Modern Art Aalborg; 5-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Здание Аалто — часть впечатления.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Линдхольм Хёйе', 110, $${
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
                        "ru": "апрель-октябрь; сухая погода",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "2026: янв-март вт-вс 10-16; апр-июн вт-вс 10-17; июл-авг ежедневно 10-17; сент-окт вт-вс 10-17; ноя-13.12 вт-вс 10-16.",
                        "en": "Usually open daily during the listed season; holiday hours may differ.",
                        "kk": "Көрсетілген маусымда әдетте күн сайын ашық; мереке күндері өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Музей: взрослый 110 DKK, до 17 лет бесплатно; само поле курганов можно смотреть бесплатно снаружи.",
                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Музей: взрослый 110 DKK, до 17 лет бесплатно; само поле курганов можно смотреть бесплатно снаружи.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 110,
                        "maxAmount": 110,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Музей: взрослый 110 DKK, до 17 лет бесплатно; само поле курганов можно смотреть бесплатно снаружи.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Музей: взрослый 110 DKK, до 17 лет бесплатно; само поле курганов можно смотреть бесплатно снаружи.",
                                "en": "Adult/base admission is about 110 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 110 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 110,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Ольборга к Линдхольм Хёйе; 10-15 мин",
                                "en": "from central Aalborg to Viking Museum Lindholm Høje; 10-15 min by car",
                                "kk": "Ольборг орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Снаружи открытое поле: ветер и дождь ощущаются сильнее.",
                                "en": "Expect wind and dress for exposed weather. Paths can be wet or slippery after rain.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз. Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Набережная Ольборга', 0, $${
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
                        "ru": "май-сентябрь; закат",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая городская зона 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Публичная прогулка бесплатно; кафе/музеи отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 120,
                "note": {
                        "ru": "45-120 мин",
                        "en": "0.75 h-2 h",
                        "kk": "0.75 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Публичная прогулка бесплатно; кафе/музеи отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичная прогулка бесплатно; кафе/музеи отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Публичная прогулка бесплатно; кафе/музеи отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Набережная Ольборга; 0-10 мин",
                                "en": "from central Aalborg to Aalborg Waterfront; 0-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Совместить с Utzon Center и Musikkens Hus.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Jomfru Ane Gade', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вечер пятницы/субботы",
                        "en": "Best in year-round; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улица 24/7; рестораны днем/вечером, бары и клубы - поздно ночью.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Улица бесплатна; бары/клубы/еда по меню, иногда вход на мероприятия платный.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 180,
                "note": {
                        "ru": "1-3 ч",
                        "en": "1 h-3 h",
                        "kk": "1 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Улица бесплатна; бары/клубы/еда по меню, иногда вход на мероприятия платный.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Улица бесплатна; бары/клубы/еда по меню, иногда вход на мероприятия платный.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Улица бесплатна; бары/клубы/еда по меню, иногда вход на мероприятия платный.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Ольборга к Jomfru Ane Gade; 0-10 мин",
                                "en": "from central Aalborg to Jomfru Ane Gade; 0-10 min by car",
                                "kk": "Ольборг орталығы бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Ночная барная улица: беречь документы и телефон.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('LEGOLAND Billund Resort', 349, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        4,
                        5,
                        6,
                        7,
                        8,
                        9
                ],
                "note": {
                        "ru": "апрель-сентябрь; июнь и сентябрь меньше очередей",
                        "en": "Best in April-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезонный парк, более 200 дней в сезоне; летом часто 10:00-18:00, аттракционы закрываются за 1 ч до парка.",
                        "en": "Typical listed hours include 10:00-18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "1-day ticket 2026: online from 349 DKK, у входа 519 DKK; дети до 2 лет бесплатно; парковка отдельно.",
                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": null,
                "maxMinutes": null,
                "note": {
                        "ru": "1 день",
                        "en": "Check the timing before visiting",
                        "kk": "уақытты барар алдында тексеріңіз"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "1-day ticket 2026: online from 349 DKK, у входа 519 DKK; дети до 2 лет бесплатно; парковка отдельно.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 349,
                        "maxAmount": 349,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "1-day ticket 2026: online from 349 DKK, у входа 519 DKK; дети до 2 лет бесплатно; парковка отдельно.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "1-day ticket 2026: online from 349 DKK, у входа 519 DKK; дети до 2 лет бесплатно; парковка отдельно.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 349,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из аэропорт/центр Биллунда к LEGOLAND Billund Resort; 5-10 мин",
                                "en": "from Billund airport / town centre to LEGOLAND Billund Resort; 5-10 min by car",
                                "kk": "аэропорт/центр Биллунда бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Цена зависит от даты; онлайн заранее сильно дешевле.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('LEGO House', 219, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будний день",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "По календарю; часто 10:00-16:00/17:00, магазин открыт чуть дольше.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "LEGO House ticket price from 219 DKK; комбибилет с LEGOLAND from 649 DKK; мастер-классы отдельно.",
                "en": "Adult/base admission is about 219 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 219 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 5,
                "note": {
                        "ru": "5 мин",
                        "en": "5 min by car",
                        "kk": "5 мин көлікпен"
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
                                "ru": "LEGO House ticket price from 219 DKK; комбибилет с LEGOLAND from 649 DKK; мастер-классы отдельно.",
                                "en": "Adult/base admission is about 219 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 219 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 219,
                        "maxAmount": 219,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "LEGO House ticket price from 219 DKK; комбибилет с LEGOLAND from 649 DKK; мастер-классы отдельно.",
                                "en": "Adult/base admission is about 219 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 219 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "LEGO House ticket price from 219 DKK; комбибилет с LEGOLAND from 649 DKK; мастер-классы отдельно.",
                                "en": "Adult/base admission is about 219 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 219 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 219,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 5,
                        "routeHint": {
                                "ru": "из аэропорт/центр Биллунда к LEGO House; 5 мин",
                                "en": "from Billund airport / town centre to LEGO House; 5 min by car",
                                "kk": "аэропорт/центр Биллунда бағыты; 5 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5 мин",
                                "en": "5 min by car",
                                "kk": "5 мин көлікпен"
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
                                "ru": "Билеты по слотам/датам; часть зон бесплатна, но Experience Zones платные.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Lalandia Billund', 349, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; будни вне школьных каникул",
                        "en": "Best in year-round; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: жыл бойы; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Aquadome по календарю, часто 09:30/10:00-18:30/19:30; на часть дней day guests не допускаются.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Aquadome day ticket: ориентир full day 349 DKK, half day 199 DKK; цены зависят от дня/сезона; парковка после 1 ч — 70 DKK.",
                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 360,
                "note": {
                        "ru": "3-6 ч",
                        "en": "3 h-6 h",
                        "kk": "3 сағ-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Aquadome day ticket: ориентир full day 349 DKK, half day 199 DKK; цены зависят от дня/сезона; парковка после 1 ч — 70 DKK.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 349,
                        "maxAmount": 349,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Aquadome day ticket: ориентир full day 349 DKK, half day 199 DKK; цены зависят от дня/сезона; парковка после 1 ч — 70 DKK.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Aquadome day ticket: ориентир full day 349 DKK, half day 199 DKK; цены зависят от дня/сезона; парковка после 1 ч — 70 DKK.",
                                "en": "Adult/base admission is about 349 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 349 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 349,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из аэропорт/центр Биллунда к Lalandia Billund; 5-10 мин",
                                "en": "from Billund airport / town centre to Lalandia Billund Aquadome; 5-10 min by car",
                                "kk": "аэропорт/центр Биллунда бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Доступ дневных гостей ограничен в пиковые дни; бронировать заранее.",
                                "en": "Arrive outside peak hours to avoid crowds.",
                                "kk": "Адам көп уақыттан тыс барсаңыз ыңғайлырақ."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('WOW PARK Billund', 199, $${
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
                        "ru": "апрель-октябрь; сухой день",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыт в сезон, большинство дней 10:00-17:00; вечерами обычно не работает.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Day ticket online from 199 DKK; входной билет на месте может быть выше.",
                "en": "Adult/base admission is about 199 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 199 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Day ticket online from 199 DKK; входной билет на месте может быть выше.",
                                "en": "Adult/base admission is about 199 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 199 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 199,
                        "maxAmount": 199,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Day ticket online from 199 DKK; входной билет на месте может быть выше.",
                                "en": "Adult/base admission is about 199 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 199 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Day ticket online from 199 DKK; входной билет на месте может быть выше.",
                                "en": "Adult/base admission is about 199 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 199 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 199,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из аэропорт/центр Биллунда к WOW PARK Billund; 5-10 мин",
                                "en": "from Billund airport / town centre to WOW PARK Billund; 5-10 min by car",
                                "kk": "аэропорт/центр Биллунда бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Лесной парк: после дождя нужна обувь, которую не жалко.",
                                "en": "Paths can be wet or slippery after rain.",
                                "kk": "Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Givskud Zoo', 260, $${
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
                        "ru": "апрель-октябрь; будни",
                        "en": "Best in April-October; weekdays are usually quieter; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; жұмыс күндері тынышырақ; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезонно; в высокий сезон может работать 10:00-19:00, в межсезонье короче - по календарю.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Adults 260 DKK; children 3–11 — 160 DKK; 0–2 бесплатно.",
                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 25,
                "note": {
                        "ru": "20-25 мин",
                        "en": "20-25 min by car",
                        "kk": "20-25 мин көлікпен"
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
                                "ru": "Adults 260 DKK; children 3–11 — 160 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 260,
                        "maxAmount": 260,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Adults 260 DKK; children 3–11 — 160 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Adults 260 DKK; children 3–11 — 160 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 260 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 260 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 260,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из Биллунд к Givskud Zoo; 20-25 мин",
                                "en": "from Billund to Givskud Zoo / Zootopia; 20-25 min by car",
                                "kk": "Биллунд бағыты; 20-25 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "20-25 мин",
                                "en": "20-25 min by car",
                                "kk": "20-25 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Сафари можно проехать на своем авто; билет включает zoo+safari+dinosaur park.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Дождевик",
                                "en": "Rain jacket",
                                "kk": "Жаңбырлық"
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
                }
        ]
}$$::jsonb),
    ('Гренен в Скагене', 0, $${
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
                        "ru": "май-сентябрь; рассвет/закат",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая природная зона 24/7; Sandormen и сервисы сезонно.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Природная точка бесплатна; парковка и трактор Sandormen до косы оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include parking.",
                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Природная точка бесплатна; парковка и трактор Sandormen до косы оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Природная точка бесплатна; парковка и трактор Sandormen до косы оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Природная точка бесплатна; парковка и трактор Sandormen до косы оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Скагена к Гренен в Скагене; 5-10 мин",
                                "en": "from central Skagen to Grenen; 5-10 min by car",
                                "kk": "центр Скагена бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Не купаться на самом мысе из-за течений; сильный ветер.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
    ('Дюна Рабьерг Миле', 0, $${
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
                        "ru": "май-сентябрь; сухой безветренный день",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая природная зона 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; парковка обычно бесплатная/локальная.",
                "en": "Entry is free. Paid extras may include parking.",
                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 25,
                "note": {
                        "ru": "20-25 мин",
                        "en": "20-25 min by car",
                        "kk": "20-25 мин көлікпен"
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
                                "ru": "Вход бесплатный; парковка обычно бесплатная/локальная.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; парковка обычно бесплатная/локальная.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Вход бесплатный; парковка обычно бесплатная/локальная.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "из Скаген к Дюна Рабьерг Миле; 20-25 мин",
                                "en": "from Skagen to Råbjerg Mile; 20-25 min by car",
                                "kk": "Скаген бағыты; 20-25 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "20-25 мин",
                                "en": "20-25 min by car",
                                "kk": "20-25 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Песок, ветер и отсутствие тени: взять воду и очки.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
    ('Музей Скагена', 140, $${
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
                        "ru": "май-сентябрь; дождливый день в Скагене",
                        "en": "Best in May-September; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Теплый сезон ежедневно; зимой чаще закрыт в январе и по понедельникам - проверять календарь.",
                        "en": "Usually open daily during the listed season; holiday hours may differ.",
                        "kk": "Көрсетілген маусымда әдетте күн сайын ашық; мереке күндері өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 140 DKK; комбибилеты с Anchers Hus/Drachmanns Hus дороже.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 10,
                "note": {
                        "ru": "0-10 мин",
                        "en": "0-10 min by car",
                        "kk": "0-10 мин көлікпен"
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
                                "ru": "Взрослый ориентир 140 DKK; комбибилеты с Anchers Hus/Drachmanns Hus дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 140 DKK; комбибилеты с Anchers Hus/Drachmanns Hus дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 140 DKK; комбибилеты с Anchers Hus/Drachmanns Hus дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Скагена к Музей Скагена; 0-10 мин",
                                "en": "from central Skagen to Skagens Museum; 0-10 min by car",
                                "kk": "центр Скагена бағыты; 0-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-10 мин",
                                "en": "0-10 min by car",
                                "kk": "0-10 мин көлікпен"
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
                                "ru": "Часть домов-музеев закрыта до 1 апреля 2026.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Занесённая песком церковь', 30, $${
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
                        "ru": "май-сентябрь; сухая погода",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона 24/7; башня сезонно, обычно апрель-октябрь дневные часы.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Осмотр снаружи бесплатный; подъем/вход в башню ориентир 30 DKK.",
                "en": "Adult/base admission is about 30 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 30 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Осмотр снаружи бесплатный; подъем/вход в башню ориентир 30 DKK.",
                                "en": "Adult/base admission is about 30 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 30 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 30,
                        "maxAmount": 30,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр снаружи бесплатный; подъем/вход в башню ориентир 30 DKK.",
                                "en": "Adult/base admission is about 30 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 30 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Осмотр снаружи бесплатный; подъем/вход в башню ориентир 30 DKK.",
                                "en": "Adult/base admission is about 30 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 30 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 30,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Скагена к Занесённая песком церковь; 5-10 мин",
                                "en": "from central Skagen to Den Tilsandede Kirke / Sand-Covered Church; 5-10 min by car",
                                "kk": "центр Скагена бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Песчаные дорожки; башня может быть закрыта вне сезона.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін."
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
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера/телефон",
                                "en": "Camera or phone",
                                "kk": "Камера немесе телефон"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Викинг-центр Рибе', 160, $${
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
                        "ru": "май-сентябрь; дни с реконструкциями",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Сезон 2026 с апреля; часы зависят от периода, часто 10:00-15:30/17:00.",
                        "en": "Typical listed hours include 10:00-15:30, 17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-15:30, 17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Admission 2026: adult 160 DKK, child 3–13 — 85 DKK.",
                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 240,
                "note": {
                        "ru": "2-4 ч",
                        "en": "2 h-4 h",
                        "kk": "2 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Admission 2026: adult 160 DKK, child 3–13 — 85 DKK.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 160,
                        "maxAmount": 160,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Admission 2026: adult 160 DKK, child 3–13 — 85 DKK.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Admission 2026: adult 160 DKK, child 3–13 — 85 DKK.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 160,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Рибе к Викинг-центр Рибе; 5-10 мин",
                                "en": "from central Ribe to Ribe VikingeCenter; 5-10 min by car",
                                "kk": "центр Рибе бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Open-air реконструкция: погода сильно влияет.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Собор Рибе', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; ясный день для башни",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "1.07-15.08 10:00-17:30; май-сент 10:00-17:00; апр/окт 11:00-16:00; зима 11:00-15:00; вс/праздники после 12:00.",
                        "en": "Typical listed hours include 10:00-17:00, 10:00-17:30, 11:00-15:00, 11:00-16:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 10:00-17:30, 11:00-15:00, 11:00-16:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход в собор бесплатный; башня/музей Commoners' Tower 30 DKK взрослый.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 90,
                "note": {
                        "ru": "45-90 мин",
                        "en": "0.75 h-1.5 h",
                        "kk": "0.75 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 5,
                "note": {
                        "ru": "0-5 мин",
                        "en": "0-5 min by car",
                        "kk": "0-5 мин көлікпен"
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
                                "ru": "Вход в собор бесплатный; башня/музей Commoners' Tower 30 DKK взрослый.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в собор бесплатный; башня/музей Commoners' Tower 30 DKK взрослый.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Вход в собор бесплатный; башня/музей Commoners' Tower 30 DKK взрослый.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 5,
                        "routeHint": {
                                "ru": "из центр Рибе к Собор Рибе; 0-5 мин",
                                "en": "from central Ribe to Ribe Cathedral; 0-5 min by car",
                                "kk": "центр Рибе бағыты; 0-5 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-5 мин",
                                "en": "0-5 min by car",
                                "kk": "0-5 мин көлікпен"
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
                                "ru": "Башня с лестницей; в службы туристический доступ ограничен.",
                                "en": "Temporary closures or event rules are possible.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Ұстамды киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Центр Ваттового моря', 140, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        3,
                        4,
                        5,
                        8,
                        10
                ],
                "note": {
                        "ru": "март-май и август-октябрь для птиц; лето для семейных туров",
                        "en": "Best in March, April, May, August, October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: наурыз, сәуір, мамыр, тамыз, қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-17:00 в высокий сезон и 10:00-16:00 в низкий; закрытия по календарю.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Exhibition adult 140 DKK; guided tours separately, например Sea Explorer/Black Sun дороже.",
                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 300,
                "note": {
                        "ru": "2-3 ч / с туром 4-5 ч",
                        "en": "2 h-5 h",
                        "kk": "2 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 20,
                "note": {
                        "ru": "15-20 мин",
                        "en": "15-20 min by car",
                        "kk": "15-20 мин көлікпен"
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
                                "ru": "Exhibition adult 140 DKK; guided tours separately, например Sea Explorer/Black Sun дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 140,
                        "maxAmount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Exhibition adult 140 DKK; guided tours separately, например Sea Explorer/Black Sun дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Exhibition adult 140 DKK; guided tours separately, например Sea Explorer/Black Sun дороже.",
                                "en": "Adult/base admission is about 140 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 140 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 140,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "из Рибе к Центр Ваттового моря; 15-20 мин",
                                "en": "from Ribe to Vadehavscentret / Wadden Sea Centre; 15-20 min by car",
                                "kk": "Рибе бағыты; 15-20 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "15-20 мин",
                                "en": "15-20 min by car",
                                "kk": "15-20 мин көлікпен"
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
                                "ru": "Для ваттовых прогулок нужны резиновые сапоги/одежда по погоде.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Старый город Рибе', 0, $${
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
                        "ru": "май-сентябрь; вечер для атмосферы",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улицы 24/7; магазины/кафе по графику.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Прогулка бесплатно; музеи/башня/кафе отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 0,
                "maxMinutes": 5,
                "note": {
                        "ru": "0-5 мин",
                        "en": "0-5 min by car",
                        "kk": "0-5 мин көлікпен"
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
                                "ru": "Прогулка бесплатно; музеи/башня/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Прогулка бесплатно; музеи/башня/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Прогулка бесплатно; музеи/башня/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 0,
                        "durationMaxMinutes": 5,
                        "routeHint": {
                                "ru": "из центр Рибе к Старый город Рибе; 0-5 мин",
                                "en": "from central Ribe to Old Ribe; 0-5 min by car",
                                "kk": "центр Рибе бағыты; 0-5 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "0-5 мин",
                                "en": "0-5 min by car",
                                "kk": "0-5 мин көлікпен"
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
                                "ru": "Лучше совместить с собором и Viking Center.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Люди у моря', 0, $${
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
                        "ru": "май-сентябрь; закат",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Осмотр бесплатно; парковка обычно рядом.",
                "en": "Entry is free. Paid extras may include parking.",
                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 45,
                "note": {
                        "ru": "20-45 мин",
                        "en": "20-45 min",
                        "kk": "20-45 мин"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Осмотр бесплатно; парковка обычно рядом.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр бесплатно; парковка обычно рядом.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Осмотр бесплатно; парковка обычно рядом.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Эсбьерга к Люди у моря; 10-15 мин",
                                "en": "from central Esbjerg to Man Meets the Sea; 10-15 min by car",
                                "kk": "Эсбьерг орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Ветрено; рядом Fisheries and Maritime Museum.",
                                "en": "Expect wind and dress for exposed weather.",
                                "kk": "Жел болуы мүмкін, ашық ауаға сай киініңіз."
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
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "CAMERA",
                        "title": {
                                "ru": "Камера/телефон",
                                "en": "Camera or phone",
                                "kk": "Камера немесе телефон"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Музей рыболовства и мореходства', 175, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; дождливый день",
                        "en": "Best in year-round; works well as a rainy-day stop",
                        "kk": "Ең қолайлы кезең: жыл бойы; жаңбырлы күнге қолайлы орын"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно 10:00-17:00; спецчасы на праздники.",
                        "en": "Typical listed hours include 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Adults 175 DKK; children under 18 free; students 125 DKK.",
                "en": "Adult/base admission is about 175 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 175 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 15,
                "note": {
                        "ru": "10-15 мин",
                        "en": "10-15 min by car",
                        "kk": "10-15 мин көлікпен"
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
                                "ru": "Adults 175 DKK; children under 18 free; students 125 DKK.",
                                "en": "Adult/base admission is about 175 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 175 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 175,
                        "maxAmount": 175,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Adults 175 DKK; children under 18 free; students 125 DKK.",
                                "en": "Adult/base admission is about 175 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 175 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Adults 175 DKK; children under 18 free; students 125 DKK.",
                                "en": "Adult/base admission is about 175 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 175 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 175,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "из центр Эсбьерга к Музей рыболовства и мореходства; 10-15 мин",
                                "en": "from central Esbjerg to Fisheries and Maritime Museum; 10-15 min by car",
                                "kk": "Эсбьерг орталығы бағыты; 10-15 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car",
                                "kk": "10-15 мин көлікпен"
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
                                "ru": "Хорошо совместить с «Люди у моря» и пляжем.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Роскилльский собор', 80, $${
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
                        "ru": "апрель-октябрь; будний день",
                        "en": "Best in April-October; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Часы меняются по сезону; ориентир 10:00-16:00/18:00, воскресенье позже из-за служб.",
                        "en": "Typical listed hours include 10:00-16:00, 18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-16:00, 18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "До 1.07.2026 взрослый 70 DKK; с 1.07.2026 — 80 DKK; дети 0–17 бесплатно.",
                "en": "Adult/base admission is about 80 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 80 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 35,
                "maxMinutes": 50,
                "note": {
                        "ru": "35-50 мин",
                        "en": "35-50 min by car",
                        "kk": "35-50 мин көлікпен"
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
                                "ru": "До 1.07.2026 взрослый 70 DKK; с 1.07.2026 — 80 DKK; дети 0–17 бесплатно.",
                                "en": "Adult/base admission is about 80 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 80 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 80,
                        "maxAmount": 80,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "До 1.07.2026 взрослый 70 DKK; с 1.07.2026 — 80 DKK; дети 0–17 бесплатно.",
                                "en": "Adult/base admission is about 80 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 80 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "До 1.07.2026 взрослый 70 DKK; с 1.07.2026 — 80 DKK; дети 0–17 бесплатно.",
                                "en": "Adult/base admission is about 80 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 80 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 80,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 35,
                        "durationMaxMinutes": 50,
                        "routeHint": {
                                "ru": "из Копенгаген к Роскилльский собор; 35-50 мин",
                                "en": "from Copenhagen to Roskilde Cathedral; 35-50 min by car",
                                "kk": "Копенгаген бағыты; 35-50 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "35-50 мин",
                                "en": "35-50 min by car",
                                "kk": "35-50 мин көлікпен"
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
                                "ru": "UNESCO; может закрываться для королевских/церковных мероприятий.",
                                "en": "Temporary closures or event rules are possible. UNESCO site; special access rules can apply.",
                                "kk": "Уақытша жабылу немесе шара ережелері болуы мүмкін. UNESCO нысаны; кіру ережесі ерекше болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "MODEST_CLOTHES",
                        "title": {
                                "ru": "Скромная одежда",
                                "en": "Modest clothing",
                                "kk": "Ұстамды киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                }
        ]
}$$::jsonb),
    ('Музей кораблей викингов', 160, $${
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
                        "ru": "май-сентябрь; летом для лодочных программ",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-16:00 в низкий сезон, 10:00-17:00 в высокий.",
                        "en": "Typical listed hours include 10:00-16:00, 10:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-16:00, 10:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 160 DKK; дети до 18 обычно бесплатно; летние sailing trips отдельно.",
                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 35,
                "maxMinutes": 50,
                "note": {
                        "ru": "35-50 мин",
                        "en": "35-50 min by car",
                        "kk": "35-50 мин көлікпен"
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
                                "ru": "Взрослый ориентир 160 DKK; дети до 18 обычно бесплатно; летние sailing trips отдельно.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 160,
                        "maxAmount": 160,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 160 DKK; дети до 18 обычно бесплатно; летние sailing trips отдельно.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
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
                                "ru": "Взрослый ориентир 160 DKK; дети до 18 обычно бесплатно; летние sailing trips отдельно.",
                                "en": "Adult/base admission is about 160 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 160 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 160,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 35,
                        "durationMaxMinutes": 50,
                        "routeHint": {
                                "ru": "из Копенгаген к Музей кораблей викингов; 35-50 мин",
                                "en": "from Copenhagen to Viking Ship Museum Roskilde; 35-50 min by car",
                                "kk": "Копенгаген бағыты; 35-50 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "35-50 мин",
                                "en": "35-50 min by car",
                                "kk": "35-50 мин көлікпен"
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
                                "ru": "Лодочные прогулки зависят от погоды и сезона.",
                                "en": "Check the current date schedule because hours or prices can change.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Земля легенд Лейре', 225, $${
        "bestTime": "MORNING",
        "season": {
                "months": [
                        6,
                        7,
                        8
                ],
                "note": {
                        "ru": "июнь-август; каникулы с программами",
                        "en": "Best in June-August; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: маусым-тамыз; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "2026: Easter 28.03-6.04 ежедневно 10-17; summer 27.06-31.08 ежедневно 10-17; межсезонье отдельные дни.",
                        "en": "Usually open daily during the listed season; holiday hours may differ.",
                        "kk": "Көрсетілген маусымда әдетте күн сайын ашық; мереке күндері өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Admission 2026: adult 12+ — 225 DKK; child 3–11 — 140 DKK; 0–2 бесплатно.",
                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 300,
                "note": {
                        "ru": "3-5 ч",
                        "en": "3 h-5 h",
                        "kk": "3 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 55,
                "note": {
                        "ru": "40-55 мин / 15-20 мин от Роскилле",
                        "en": "15-55 min by car",
                        "kk": "15-55 мин көлікпен"
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
                                "ru": "Admission 2026: adult 12+ — 225 DKK; child 3–11 — 140 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 225,
                        "maxAmount": 225,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Admission 2026: adult 12+ — 225 DKK; child 3–11 — 140 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Admission 2026: adult 12+ — 225 DKK; child 3–11 — 140 DKK; 0–2 бесплатно.",
                                "en": "Adult/base admission is about 225 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 225 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 225,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 55,
                        "routeHint": {
                                "ru": "из Копенгаген / Роскилле к Земля легенд Лейре; 40-55 мин / 15-20 мин от Роскилле",
                                "en": "from Copenhagen / Roskilde to Land of Legends Lejre / Sagnlandet Lejre; 15-55 min by car",
                                "kk": "Копенгаген / Роскилле бағыты; 15-55 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "40-55 мин / 15-20 мин от Роскилле",
                                "en": "15-55 min by car",
                                "kk": "15-55 мин көлікпен"
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
                                "ru": "Большая территория на улице; программа зависит от дня.",
                                "en": "Allow extra time for walking across a large area.",
                                "kk": "Аумағы кең, жаяу жүруге қосымша уақыт қалдырыңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Гавань Роскилле', 0, $${
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
                        "ru": "май-сентябрь; закат",
                        "en": "Best in May-September; evening or sunset gives the best atmosphere",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; кешкі уақыт немесе күн батар кез жақсы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Набережная доступна 24/7; сервисы сезонно.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Публичная прогулка бесплатно; музеи, лодки и кафе отдельно.",
                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 120,
                "note": {
                        "ru": "45-120 мин",
                        "en": "0.75 h-2 h",
                        "kk": "0.75 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car",
                        "kk": "5-10 мин көлікпен"
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
                                "ru": "Публичная прогулка бесплатно; музеи, лодки и кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичная прогулка бесплатно; музеи, лодки и кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Публичная прогулка бесплатно; музеи, лодки и кафе отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport, food, events or optional services.",
                                "kk": "Кіру тегін. тур немесе көлік, тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 10,
                        "routeHint": {
                                "ru": "из центр Роскилле к Гавань Роскилле; 5-10 мин",
                                "en": "from central Roskilde to Roskilde Harbour; 5-10 min by car",
                                "kk": "Роскилле орталығы бағыты; 5-10 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car",
                                "kk": "5-10 мин көлікпен"
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
                                "ru": "Совместить с Viking Ship Museum.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Замок Кронборг', 150, $${
        "bestTime": "EARLY_MORNING",
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
                        "ru": "апрель-октябрь; будни утром",
                        "en": "Best in April-October; go in the morning for lighter crowds; weekdays are usually quieter",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; таңертең адам аздау; жұмыс күндері тынышырақ"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "2026: 2.01-28.03 вт-вс 10-16; 28.03-31.10 ежедневно 10-17; летом по Copenhagen Card может быть до 18:00; 25.05 закрыт.",
                        "en": "Typical listed hours include 18:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 18:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 150 DKK; онлайн часто −10%; дети до 18 бесплатно.",
                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 60,
                "note": {
                        "ru": "45-60 мин",
                        "en": "0.75 h-1 h by car",
                        "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Взрослый ориентир 150 DKK; онлайн часто −10%; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 150,
                        "maxAmount": 150,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 150 DKK; онлайн часто −10%; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 150 DKK; онлайн часто −10%; дети до 18 бесплатно.",
                                "en": "Adult/base admission is about 150 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 150 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 150,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "из Копенгаген к Замок Кронборг; 45-60 мин",
                                "en": "from Copenhagen to Kronborg Castle; 0.75 h-1 h by car",
                                "kk": "Копенгаген бағыты; 0.75 сағ-1 сағ көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "45-60 мин",
                                "en": "0.75 h-1 h by car",
                                "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "UNESCO/Hamlet; проверять особые закрытия.",
                                "en": "Check the current date schedule because hours or prices can change. Temporary closures or event rules are possible. UNESCO site; special access rules can apply.",
                                "kk": "Кесте мен баға өзгеруі мүмкін, нақты күнді алдын ала тексеріңіз. Уақытша жабылу немесе шара ережелері болуы мүмкін. UNESCO нысаны; кіру ережесі ерекше болуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Морской музей Дании', 145, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вместе с Кронборгом",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 11:00-17:00, летом 10:00-18:00; пн может быть закрыт вне сезона.",
                        "en": "Typical listed hours include 10:00-18:00, 11:00-17:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 11:00-17:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Adult 145 DKK; children under 18 free; Copenhagen Card accepted.",
                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 150,
                "note": {
                        "ru": "1,5-2,5 ч",
                        "en": "1.5 h-2.5 h",
                        "kk": "1.5 сағ-2.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 60,
                "note": {
                        "ru": "45-60 мин",
                        "en": "0.75 h-1 h by car",
                        "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Adult 145 DKK; children under 18 free; Copenhagen Card accepted.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 145,
                        "maxAmount": 145,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Adult 145 DKK; children under 18 free; Copenhagen Card accepted.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Adult 145 DKK; children under 18 free; Copenhagen Card accepted.",
                                "en": "Adult/base admission is about 145 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 145 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 145,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "из Копенгаген к Морской музей Дании; 45-60 мин",
                                "en": "from Copenhagen to M/S Maritime Museum of Denmark; 0.75 h-1 h by car",
                                "kk": "Копенгаген бағыты; 0.75 сағ-1 сағ көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "45-60 мин",
                                "en": "0.75 h-1 h by car",
                                "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Находится рядом с Кронборгом в бывшем сухом доке.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Старый город Хельсингёра', 0, $${
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
                        "ru": "май-сентябрь; день с Кронборгом",
                        "en": "Best in May-September; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улицы 24/7; магазины/кафе по графику.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Прогулка бесплатно; музеи/кафе отдельно.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 60,
                "note": {
                        "ru": "45-60 мин",
                        "en": "0.75 h-1 h by car",
                        "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Прогулка бесплатно; музеи/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Прогулка бесплатно; музеи/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Прогулка бесплатно; музеи/кафе отдельно.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "из Копенгаген к Старый город Хельсингёра; 45-60 мин",
                                "en": "from Copenhagen to Old Helsingør; 0.75 h-1 h by car",
                                "kk": "Копенгаген бағыты; 0.75 сағ-1 сағ көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "45-60 мин",
                                "en": "0.75 h-1 h by car",
                                "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Компактный центр между вокзалом и Кронборгом.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Культурная верфь Хельсингёра', 0, $${
        "bestTime": "MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "круглый год; вместе с Кронборгом",
                        "en": "Best in year-round; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: жыл бойы; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Библиотека/центр обычно дневные часы; библиотека ориентир пн 10-18, вт-ср 10-19, чт 10-20, пт 10-18, сб 10-16, вс 11-16.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход в общественные зоны обычно бесплатный; концерты/кино/события по билетам.",
                "en": "Entry is free. Paid extras may include food, events or optional services.",
                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 45,
                "maxMinutes": 60,
                "note": {
                        "ru": "45-60 мин",
                        "en": "0.75 h-1 h by car",
                        "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Вход в общественные зоны обычно бесплатный; концерты/кино/события по билетам.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в общественные зоны обычно бесплатный; концерты/кино/события по билетам.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
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
                                "ru": "Вход в общественные зоны обычно бесплатный; концерты/кино/события по билетам.",
                                "en": "Entry is free. Paid extras may include food, events or optional services.",
                                "kk": "Кіру тегін. тамақ, шара немесе қосымша қызмет бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Дополнительные опции",
                                "en": "Optional services",
                                "kk": "Қосымша қызметтер"
                        },
                        "description": {
                                "ru": "Еда, события, прокат или другие выбранные опции оплачиваются отдельно.",
                                "en": "Food, events, rentals or other selected options are paid separately.",
                                "kk": "Тамақ, шара, жалға алу немесе басқа таңдалған қызметтер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 45,
                        "durationMaxMinutes": 60,
                        "routeHint": {
                                "ru": "из Копенгаген к Культурная верфь Хельсингёра; 45-60 мин",
                                "en": "from Copenhagen to Kulturværftet / The Culture Yard; 0.75 h-1 h by car",
                                "kk": "Копенгаген бағыты; 0.75 сағ-1 сағ көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "45-60 мин",
                                "en": "0.75 h-1 h by car",
                                "kk": "0.75 сағ-1 сағ көлікпен"
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
                                "ru": "Рядом фудмаркет и M/S Maritime Museum.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Замок Фредериксборг', 125, $${
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
                        "ru": "апрель-октябрь; май/сентябрь для садов",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыт ежедневно весь год; regular hours 10:00-17:00, зимой некоторые периоды 11:00-15:00.",
                        "en": "Typical listed hours include 10:00-17:00, 11:00-15:00; check holiday and event changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 11:00-15:00; мереке мен шара күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый ориентир 125 DKK; дети до 17 бесплатно; Copenhagen Card принимается.",
                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 180,
                "note": {
                        "ru": "2-3 ч",
                        "en": "2 h-3 h",
                        "kk": "2 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 40,
                "maxMinutes": 55,
                "note": {
                        "ru": "40-55 мин",
                        "en": "40-55 min by car",
                        "kk": "40-55 мин көлікпен"
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
                                "ru": "Взрослый ориентир 125 DKK; дети до 17 бесплатно; Copenhagen Card принимается.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 125,
                        "maxAmount": 125,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый ориентир 125 DKK; дети до 17 бесплатно; Copenhagen Card принимается.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Взрослый ориентир 125 DKK; дети до 17 бесплатно; Copenhagen Card принимается.",
                                "en": "Adult/base admission is about 125 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 125 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 125,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 40,
                        "durationMaxMinutes": 55,
                        "routeHint": {
                                "ru": "из Копенгаген к Замок Фредериксборг; 40-55 мин",
                                "en": "from Copenhagen to Frederiksborg Castle; 40-55 min by car",
                                "kk": "Копенгаген бағыты; 40-55 мин көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "40-55 мин",
                                "en": "40-55 min by car",
                                "kk": "40-55 мин көлікпен"
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
                                "ru": "Комбинировать с садами и центром Хиллерёда.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
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
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Сады Фредериксборга', 0, $${
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
                        "ru": "май-сентябрь; осень для цвета",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Baroque Gardens: круглый год 10:00 до заката, но не позже 21:00; другие сады 24/7.",
                        "en": "Public areas are usually open 24/7; seasonal services may keep shorter hours.",
                        "kk": "Қоғамдық аймақ әдетте тәулік бойы ашық; маусымдық қызметтердің уақыты қысқа болуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Сады бесплатны.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 40,
                "maxMinutes": 55,
                "note": {
                        "ru": "40-55 мин",
                        "en": "40-55 min by car",
                        "kk": "40-55 мин көлікпен"
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
                                "ru": "Сады бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сады бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                                "ru": "Сады бесплатны.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 40,
                        "durationMaxMinutes": 55,
                        "routeHint": {
                                "ru": "из Копенгаген к Сады Фредериксборга; 40-55 мин",
                                "en": "from Copenhagen to Frederiksborg Castle Gardens; 40-55 min by car",
                                "kk": "Копенгаген бағыты; 40-55 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "40-55 мин",
                                "en": "40-55 min by car",
                                "kk": "40-55 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Логично после замка; зимой фонтаны/цветники ограничены.",
                                "en": "Weather and local access rules matter for this outdoor stop.",
                                "kk": "Бұл ашық орынға ауа райы мен жергілікті ереже маңызды."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Мёнс-Клинт', 0, $${
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
                        "ru": "май-сентябрь; сухая ясная погода",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Природная зона доступна круглый год в светлое время; лестницы/тропы могут закрываться после обвалов.",
                        "en": "Natural area is best visited in daylight; trails may close after bad weather.",
                        "kk": "Табиғи аймаққа күн жарығында барған дұрыс; қолайсыз ауа райынан кейін соқпақ жабылуы мүмкін."
                }
        },
        "priceNote": {
                "ru": "Сами утесы и пляж бесплатны; парковка у GeoCenter и музей оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include parking.",
                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 120,
                "maxMinutes": 300,
                "note": {
                        "ru": "2-5 ч",
                        "en": "2 h-5 h",
                        "kk": "2 сағ-5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 120,
                "note": {
                        "ru": "1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                        "en": "0.5 h-2 h by car",
                        "kk": "0.5 сағ-2 сағ көлікпен"
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
                                "ru": "Сами утесы и пляж бесплатны; парковка у GeoCenter и музей оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Сами утесы и пляж бесплатны; парковка у GeoCenter и музей оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
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
                                "ru": "Сами утесы и пляж бесплатны; парковка у GeoCenter и музей оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include parking.",
                                "kk": "Кіру тегін. тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
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
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 120,
                        "routeHint": {
                                "ru": "из Копенгаген / Стеге к Мёнс-Клинт; 1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                                "en": "from Copenhagen / Stege to Møns Klint; 0.5 h-2 h by car",
                                "kk": "Копенгаген / Стеге бағыты; 0.5 сағ-2 сағ көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                                "en": "0.5 h-2 h by car",
                                "kk": "0.5 сағ-2 сағ көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Не стоять под обрывами; лестницы длинные, после дождя скользко.",
                                "en": "Paths can be wet or slippery after rain. Allow extra time for walking across a large area.",
                                "kk": "Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін. Аумағы кең, жаяу жүруге қосымша уақыт қалдырыңыз."
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
                        "itemType": "POWERBANK",
                        "title": {
                                "ru": "Пауэрбанк",
                                "en": "Power bank",
                                "kk": "Қуаттау құрылғысы"
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
    ('GeoCenter Møns Klint', 155, $${
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
                        "ru": "апрель-октябрь; вместе с прогулкой по утесам",
                        "en": "Best in April-October; check weather and the daily schedule before visiting",
                        "kk": "Ең қолайлы кезең: сәуір-қазан; ауа райы мен күндік кестені алдын ала тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно открыт с Пасхи до конца октября; часы по календарю, часто 10:00-17:00.",
                        "en": "2026 opening depends on the seasonal calendar; check the exact visit date.",
                        "kk": "2026 ашылу уақыты маусымдық күнтізбеге тәуелді; нақты күнді тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Adult 155 DKK; child 100 DKK; online обычно −10 DKK.",
                "en": "Adult/base admission is about 155 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                "kk": "Ересек адамға негізгі кіру шамамен 155 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 90,
                "maxMinutes": 180,
                "note": {
                        "ru": "1,5-3 ч",
                        "en": "1.5 h-3 h",
                        "kk": "1.5 сағ-3 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 120,
                "note": {
                        "ru": "1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                        "en": "0.5 h-2 h by car",
                        "kk": "0.5 сағ-2 сағ көлікпен"
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
                                "ru": "Adult 155 DKK; child 100 DKK; online обычно −10 DKK.",
                                "en": "Adult/base admission is about 155 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 155 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "minAmount": 155,
                        "maxAmount": 155,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Adult 155 DKK; child 100 DKK; online обычно −10 DKK.",
                                "en": "Adult/base admission is about 155 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 155 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
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
                                "ru": "Adult 155 DKK; child 100 DKK; online обычно −10 DKK.",
                                "en": "Adult/base admission is about 155 DKK. Children, discounts, online prices and optional extras can differ by ticket type.",
                                "kk": "Ересек адамға негізгі кіру шамамен 155 DKK. Балалар, жеңілдік, онлайн баға және қосымша қызмет билет түріне қарай өзгеруі мүмкін."
                        },
                        "amount": 155,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 120,
                        "routeHint": {
                                "ru": "из Копенгаген / Стеге к GeoCenter Møns Klint; 1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                                "en": "from Copenhagen / Stege to GeoCenter Møns Klint; 0.5 h-2 h by car",
                                "kk": "Копенгаген / Стеге бағыты; 0.5 сағ-2 сағ көлікпен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Планируйте парковку заранее.",
                                "en": "Plan parking ahead.",
                                "kk": "Тұрақты алдын ала жоспарлаңыз."
                        },
                        "note": {
                                "ru": "1 ч 45 мин-2 ч от Копенгагена / 30 мин от Стеге",
                                "en": "0.5 h-2 h by car",
                                "kk": "0.5 сағ-2 сағ көлікпен"
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
                                "ru": "Хорошая база с туалетами/кафе перед тропами.",
                                "en": "Check current hours and local rules before visiting.",
                                "kk": "Барар алдында кесте мен жергілікті ережені тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "TICKETS",
                        "title": {
                                "ru": "Онлайн-билет",
                                "en": "Online ticket",
                                "kk": "Онлайн билет"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Карта/наличные",
                                "en": "Card or cash",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "SMALL_BAG",
                        "title": {
                                "ru": "Легкая сумка",
                                "en": "Light bag",
                                "kk": "Жеңіл сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Карта",
                                "en": "Map",
                                "kk": "Карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Парк Лиселунд', 0, $${
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
                        "ru": "май-сентябрь; вместе с Мёнс-Клинт",
                        "en": "Best in May-September; dry and calm weather is preferable",
                        "kk": "Ең қолайлы кезең: мамыр-қыркүйек; құрғақ әрі тынық ауа райы ыңғайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Романтический сад открыт бесплатно круглый год; дом может быть закрыт/экскурсии сезонны.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Парк бесплатный; дом/экскурсии при наличии оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include tours or transport.",
                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 120,
                "note": {
                        "ru": "1-2 ч",
                        "en": "1 h-2 h",
                        "kk": "1 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 10,
                "maxMinutes": 30,
                "note": {
                        "ru": "25-30 мин от Стеге / 10-15 мин от Мёнс-Клинт",
                        "en": "10-30 min by car",
                        "kk": "10-30 мин көлікпен"
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
                                "ru": "Парк бесплатный; дом/экскурсии при наличии оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парк бесплатный; дом/экскурсии при наличии оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "GUIDE",
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
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
                                "ru": "Парк бесплатный; дом/экскурсии при наличии оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include tours or transport.",
                                "kk": "Кіру тегін. тур немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Туры / экскурсии",
                                "en": "Tours / guided experiences",
                                "kk": "Турлар / экскурсиялар"
                        },
                        "description": {
                                "ru": "Туры, лодочные программы или экскурсии покупаются отдельно.",
                                "en": "Tours, boat programs or guided experiences are bought separately.",
                                "kk": "Турлар, қайық бағдарламалары немесе экскурсиялар бөлек алынады."
                        },
                        "amount": 0,
                        "currency": "DKK",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 30,
                        "routeHint": {
                                "ru": "из Стеге / Мёнс-Клинт к Парк Лиселунд; 25-30 мин от Стеге / 10-15 мин от Мёнс-Клинт",
                                "en": "from Stege / Møns Klint to Liselund Park; 10-30 min by car",
                                "kk": "Стеге / Мёнс-Клинт бағыты; 10-30 мин көлікпен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка может быть ограничена или оплачиваться отдельно.",
                                "en": "Parking may be limited or charged separately.",
                                "kk": "Тұрақ шектеулі немесе бөлек төленуі мүмкін."
                        },
                        "note": {
                                "ru": "25-30 мин от Стеге / 10-15 мин от Мёнс-Клинт",
                                "en": "10-30 min by car",
                                "kk": "10-30 мин көлікпен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за погодой, ветром и состоянием троп/пляжа.",
                                "en": "Watch weather, wind and path or beach conditions.",
                                "kk": "Ауа райын, желді және соқпақ не жағажай жағдайын бақылаңыз."
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
                                "ru": "Тихая остановка рядом с утесами; после дождя тропы влажные.",
                                "en": "Paths can be wet or slippery after rain.",
                                "kk": "Жаңбырдан кейін жол ылғалды немесе тайғақ болуы мүмкін."
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
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 30
                },
                {
                        "itemType": "PICNIC_BLANKET",
                        "title": {
                                "ru": "Плед для пикника",
                                "en": "Picnic blanket",
                                "kk": "Пикник көрпесі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
     AND p.deleted_at IS NULL
)
UPDATE places p
SET
    price_amount = COALESCE(m.price_amount, p.price_amount),
    price_currency = CASE WHEN m.price_amount IS NULL THEN p.price_currency ELSE 'DKK' END,
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
     AND p.deleted_at IS NULL
)
INSERT INTO place_fee_items (
    place_id, fee_type, title, description, amount_min, amount_max, currency, unit, is_required, is_approximate, note, sort_order
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
     AND p.deleted_at IS NULL
)
INSERT INTO place_access_options (
    place_id, transport_type, duration_min_minutes, duration_max_minutes, route_hint, road_condition, requires_4x4, parking_note, last_segment_note, note, sort_order
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
     AND p.deleted_at IS NULL
)
INSERT INTO place_practical_notes (
    place_id, note_type, title, body, priority, sort_order
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
    FROM seed_denmark_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'DK'
     AND p.deleted_at IS NULL
)
INSERT INTO place_recommended_items (
    place_id, item_type, title, importance, season, note, sort_order
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

DROP TABLE seed_denmark_visit_planning;
