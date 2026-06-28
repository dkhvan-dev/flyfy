-- Seed Singapore visit-planning details from the 2026 attractions workbook.
CREATE TEMP TABLE seed_singapore_visit_planning (
    title_ru text PRIMARY KEY,
    price_amount numeric NULL,
    visit_info jsonb NOT NULL
);

INSERT INTO seed_singapore_visit_planning (title_ru, price_amount, visit_info)
VALUES
    ('Сады у залива', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше 16:00-21:00, чтобы совместить дневной сад и вечернюю подсветку.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытые сады 05:00-02:00; ключевые платные павильоны 09:00-21:00, последний вход около 20:00.",
                        "en": "Outdoor gardens are open from early morning until late night; paid conservatories keep shorter hours.",
                        "kk": "Ашық бақтар таңнан түнге дейін ашық; ақылы павильондардың уақыты қысқарақ."
                }
        },
        "priceNote": {
                "ru": "Открытые сады бесплатны; Cloud Forest/Flower Dome/OCBC Skyway/Supertree Observatory оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Открытые сады бесплатны; Cloud Forest/Flower Dome/OCBC Skyway/Supertree Observatory оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Открытые сады бесплатны; Cloud Forest/Flower Dome/OCBC Skyway/Supertree Observatory оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Открытые сады бесплатны; Cloud Forest/Flower Dome/OCBC Skyway/Supertree Observatory оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси к Gardens by the Bay / Bayfront. 5-10 мин",
                                "en": "central Singapore to Gardens by the Bay / Bayfront by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан Gardens by the Bay / Bayfront бағытына көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Проверять календарь техобслуживания и закрытий.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Пляжный парк Чанги', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель и раннее утро/закат, днем жарко.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Доступ ежедневно; сервисы/спасатели по расписанию.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
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
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 40,
                        "routeHint": {
                                "ru": "По ECP/PIE в сторону Changi. 30-40 мин",
                                "en": "via ECP/PIE toward Changi; 30-40 min by car or taxi",
                                "kk": "ECP/PIE арқылы Changi бағытына; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Спокойный парк у аэропорта; хорош для пикника и наблюдения за самолетами.",
                                "en": "Good for plane views and an easy airport-side stop.",
                                "kk": "Ұшақ көруге және әуежай маңындағы жеңіл аялдамаға қолайлы."
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
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "DRY_BAG",
                        "title": {
                                "ru": "Сухой пакет",
                                "en": "Dry bag",
                                "kk": "Құрғақ сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Newton Food Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 12:00-02:00, лавки работают по-разному.",
                        "en": "Typical listed hours include 12:00-02:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 12:00-02:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; блюда обычно 5-20 SGD.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "10-15 min by car or taxi",
                        "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; блюда обычно 5-20 SGD.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; блюда обычно 5-20 SGD.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 5,
                        "maxAmount": 20,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; блюда обычно 5-20 SGD.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 5,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 10-15 мин",
                                "en": "central Singapore by car or taxi; 10-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car or taxi",
                                "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Lau Pa Sat', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Комплекс заявлен как 24 часа; Satay Street активнее вечером.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Makansutra Gluttons Bay', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно вечерний формат: около 16:00-23:00/23:30.",
                        "en": "Typical listed hours include 16:00-23:00, 23:30; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 16:00-23:00, 23:30; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('The Shoppes at Marina Bay Sands', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-22:00; часы арендаторов отличаются.",
                        "en": "Typical listed hours include 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "К Marina Bay Sands. 5-10 мин",
                                "en": "to Marina Bay Sands; 5-10 min by car or taxi",
                                "kk": "Marina Bay Sands бағытына; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Удобно совмещать с SkyPark, ArtScience Museum и Gardens by the Bay.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Торговый центр VivoCity', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-22:00; часы арендаторов отличаются.",
                        "en": "Typical listed hours include 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "15-25 min by car or taxi",
                        "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "К HarbourFront. 15-25 мин",
                                "en": "to HarbourFront; 15-25 min by car or taxi",
                                "kk": "HarbourFront бағытына; 15-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car or taxi",
                                "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Удобная точка перед Sentosa.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Уличный рынок Чайнатауна', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 09:00-22:00; отдельные лавки отличаются.",
                        "en": "Typical listed hours include 09:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 09:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 90,
                "note": {
                        "ru": "20-90 мин",
                        "en": "0.333333 h-1.5 h",
                        "kk": "0.333333 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Центр уличной еды Maxwell', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 08:00/10:00-22:00; по лавкам различается.",
                        "en": "Typical listed hours include 08:00, 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 08:00, 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 90,
                "note": {
                        "ru": "20-90 мин",
                        "en": "0.333333 h-1.5 h",
                        "kk": "0.333333 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Jewel Changi Airport', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Jewel доступен 24 часа; большинство магазинов около 10:00-22:00.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход в Jewel/Forest Valley бесплатный; Canopy Park и Changi Experience Studio платные.",
                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
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
                "minMinutes": 25,
                "maxMinutes": 35,
                "note": {
                        "ru": "25-35 мин",
                        "en": "25-35 min by car or taxi",
                        "kk": "25-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход в Jewel/Forest Valley бесплатный; Canopy Park и Changi Experience Studio платные.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в Jewel/Forest Valley бесплатный; Canopy Park и Changi Experience Studio платные.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Вход в Jewel/Forest Valley бесплатный; Canopy Park и Changi Experience Studio платные.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "По ECP/PIE к Changi Airport T1/Jewel. 25-35 мин",
                                "en": "via ECP/PIE to Changi Airport T1 / Jewel; 25-35 min by car or taxi",
                                "kk": "ECP/PIE арқылы Changi Airport T1 / Jewel бағытына; 25-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "25-35 мин",
                                "en": "25-35 min by car or taxi",
                                "kk": "25-35 мин көлікпен немесе таксимен"
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
                                "ru": "Закладывайте запас из-за аэропортовой логистики и толп у Rain Vortex.",
                                "en": "Good for plane views and an easy airport-side stop.",
                                "kk": "Ұшақ көруге және әуежай маңындағы жеңіл аялдамаға қолайлы."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Рынок и фуд-центр Geylang Serai', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир: рынок 06:30-12:00, food centre около 08:00-22:00.",
                        "en": "Typical listed hours include 06:30-12:00, 08:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 06:30-12:00, 08:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                "minMinutes": 15,
                "maxMinutes": 20,
                "note": {
                        "ru": "15-20 мин",
                        "en": "15-20 min by car or taxi",
                        "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-20 мин",
                                "en": "central Singapore by car or taxi; 15-20 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-20 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-20 мин",
                                "en": "15-20 min by car or taxi",
                                "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Old Airport Road Food Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 06:00-23:00; лавки по своим дням.",
                        "en": "Typical listed hours include 06:00-23:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 06:00-23:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "10-20 min by car or taxi",
                        "kk": "10-20 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 10-20 мин",
                                "en": "central Singapore by car or taxi; 10-20 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-20 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-20 мин",
                                "en": "10-20 min by car or taxi",
                                "kk": "10-20 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Chomp Chomp Food Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "После ремонта открыт с 27.01.2026; вечерний формат, ориентир 16:00-00:00/01:00.",
                        "en": "Typical listed hours include 01:00, 16:00-00:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 01:00, 16:00-00:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                "maxMinutes": 30,
                "note": {
                        "ru": "20-30 мин",
                        "en": "20-30 min by car or taxi",
                        "kk": "20-30 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 30,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-30 мин",
                                "en": "central Singapore by car or taxi; 20-30 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-30 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-30 мин",
                                "en": "20-30 min by car or taxi",
                                "kk": "20-30 мин көлікпен немесе таксимен"
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
                                "ru": "Проверять график отдельных лавок после ремонта.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Пулау-Убин', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Лучше посещать в светлое время; лодки ходят по набору пассажиров/спросу.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; bumboat от Changi Point оплачивается отдельно, ориентир 4-6 SGD в одну сторону наличными.",
                "en": "Entry is free. Paid extras may include boat or transport.",
                "kk": "Кіру тегін. қайық немесе көлік бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 240,
                "maxMinutes": 360,
                "note": {
                        "ru": "4-6 ч",
                        "en": "4 h-6 h",
                        "kk": "4 сағ-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 40,
                "maxMinutes": 55,
                "note": {
                        "ru": "30-40 мин + 10-15 мин лодка",
                        "en": "40-55 min by car or taxi",
                        "kk": "40-55 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; bumboat от Changi Point оплачивается отдельно, ориентир 4-6 SGD в одну сторону наличными.",
                                "en": "Entry is free. Paid extras may include boat or transport.",
                                "kk": "Кіру тегін. қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; bumboat от Changi Point оплачивается отдельно, ориентир 4-6 SGD в одну сторону наличными.",
                                "en": "Entry is free. Paid extras may include boat or transport.",
                                "kk": "Кіру тегін. қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 4,
                        "maxAmount": 6,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; bumboat от Changi Point оплачивается отдельно, ориентир 4-6 SGD в одну сторону наличными.",
                                "en": "Entry is free. Paid extras may include boat or transport.",
                                "kk": "Кіру тегін. қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 4,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 40,
                        "durationMaxMinutes": 55,
                        "routeHint": {
                                "ru": "На авто до Changi Point Ferry Terminal, далее bumboat. 30-40 мин + 10-15 мин лодка",
                                "en": "drive to Changi Point Ferry Terminal, then bumboat; 40-55 min by car or taxi",
                                "kk": "Changi Point Ferry Terminal бағытына көлікпен, кейін bumboat; 40-55 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин + 10-15 мин лодка",
                                "en": "40-55 min by car or taxi",
                                "kk": "40-55 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Автомобиль на остров не берут; по острову пешком/велосипед/местный van.",
                                "en": "Island or boat legs can change with weather and demand.",
                                "kk": "Арал немесе қайық бөлігі ауа райы мен сұранысқа қарай өзгеруі мүмкін."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Водно-болотные угодья Чек-Джава', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Boardwalk/visitor centre обычно 07:00-19:00.",
                        "en": "Typical listed hours include 07:00-19:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:00-19:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин + лодка/островная дорога",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 30,
                        "durationMaxMinutes": 40,
                        "routeHint": {
                                "ru": "До Changi Point на авто, далее bumboat и дорога по острову. 30-40 мин + лодка/островная дорога",
                                "en": "drive to Changi Point, then bumboat and island road; 30-40 min by car or taxi",
                                "kk": "Changi Point бағытына көлікпен, кейін bumboat және арал жолы; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин + лодка/островная дорога",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Проверяйте приливы и ограничения троп после дождей.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb),
    ('Парк водохранилища Мак-Ритчи', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Central Catchment обычно 07:00-19:00.",
                        "en": "Typical listed hours include 07:00-19:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:00-19:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                        "en": "15-25 min by car or taxi",
                        "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-25 мин",
                                "en": "central Singapore by car or taxi; 15-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car or taxi",
                                "kk": "15-25 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Не кормить обезьян и не показывать еду.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Raffles City Singapore', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-22:00; часы арендаторов отличаются.",
                        "en": "Typical listed hours include 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                "minMinutes": 3,
                "maxMinutes": 8,
                "note": {
                        "ru": "3-8 мин",
                        "en": "3-8 min by car or taxi",
                        "kk": "3-8 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 3,
                        "durationMaxMinutes": 8,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 3-8 мин",
                                "en": "central Singapore by car or taxi; 3-8 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 3-8 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "3-8 мин",
                                "en": "3-8 min by car or taxi",
                                "kk": "3-8 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и праздники больше людей; в дождь удобная альтернатива открытым местам.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Suntec City', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-22:00; часы арендаторов отличаются.",
                        "en": "Typical listed hours include 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Fountain of Wealth и отдельные зоны могут иметь собственный режим.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Orchard Road', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улица доступна всегда; большинство ТЦ около 10:00-22:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "10-15 min by car or taxi",
                        "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 10-15 мин",
                                "en": "central Singapore by car or taxi; 10-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car or taxi",
                                "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и праздники больше людей; в дождь удобная альтернатива открытым местам.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('ION Orchard', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно около 10:00-22:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "10-15 min by car or taxi",
                        "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 10-15 мин",
                                "en": "central Singapore by car or taxi; 10-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car or taxi",
                                "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и праздники больше людей; в дождь удобная альтернатива открытым местам.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Пляж Силосо', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель и раннее утро/закат, днем жарко.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Доступ ежедневно; сервисы/спасатели по расписанию.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-35 мин",
                                "en": "central Singapore by car or taxi; 20-35 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Самый активный пляж Sentosa, рядом бары и активности.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "DRY_BAG",
                        "title": {
                                "ru": "Сухой пакет",
                                "en": "Dry bag",
                                "kk": "Құрғақ сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Пляж Палаван', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель и раннее утро/закат, днем жарко.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Доступ ежедневно; сервисы/спасатели по расписанию.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-35 мин",
                                "en": "central Singapore by car or taxi; 20-35 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Более семейный формат, удобно совмещать с Sensoryscape.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "DRY_BAG",
                        "title": {
                                "ru": "Сухой пакет",
                                "en": "Dry bag",
                                "kk": "Құрғақ сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Пляж Танжонг', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель и раннее утро/закат, днем жарко.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Доступ ежедневно; сервисы/спасатели по расписанию.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды, лежаки, еда и активности оплачиваются отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, rentals and activities.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, жалға алу және белсенділік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-35 мин",
                                "en": "central Singapore by car or taxi; 20-35 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Спокойнее, beach club лучше бронировать отдельно.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 30
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "DRY_BAG",
                        "title": {
                                "ru": "Сухой пакет",
                                "en": "Dry bag",
                                "kk": "Құрғақ сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Центральный пляжный базар', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно ежедневно; киоски ориентир 11:00-21:00, шоу по расписанию.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                "minMinutes": 20,
                "maxMinutes": 30,
                "note": {
                        "ru": "20-30 мин",
                        "en": "20-30 min by car or taxi",
                        "kk": "20-30 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 30,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-30 мин",
                                "en": "central Singapore by car or taxi; 20-30 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-30 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-30 мин",
                                "en": "20-30 min by car or taxi",
                                "kk": "20-30 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Chinatown Complex Market and Food Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно около 07:00-22:00.",
                        "en": "Typical listed hours include 07:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Tekka Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; для hawker-центров лучше обед/вечер, но конкретные лавки работают по своим дням.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 06:30-21:00.",
                        "en": "Typical listed hours include 06:30-21:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 06:30-21:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                "en": "Entry is free. Paid extras may include food from individual stalls.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
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
                        "en": "10-15 min by car or taxi",
                        "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
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
                                "ru": "Вход бесплатный; еда оплачивается у отдельных лавок.",
                                "en": "Entry is free. Paid extras may include food from individual stalls.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 10-15 мин",
                                "en": "central Singapore by car or taxi; 10-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car or taxi",
                                "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Проверяйте рабочие дни популярных лавок: многие закрываются после распродажи порций.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Popular stalls can close after selling out.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Танымал дүңгіршектер тағам біткен соң жабылуы мүмкін."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "RAIN",
                        "title": {
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
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
                        "itemType": "WIPES",
                        "title": {
                                "ru": "Влажные салфетки",
                                "en": "Wet wipes",
                                "kk": "Ылғалды майлықтар"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Mustafa Centre', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открыт 24/7.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "10-15 min by car or taxi",
                        "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 30
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 10,
                        "durationMaxMinutes": 15,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 10-15 мин",
                                "en": "central Singapore by car or taxi; 10-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 10-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "10-15 мин",
                                "en": "10-15 min by car or taxi",
                                "kk": "10-15 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и праздники больше людей; в дождь удобная альтернатива открытым местам.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                }
        ]
}$$::jsonb),
    ('Haji Lane', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше после 15:00 или вечером.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улица доступна всегда; магазины/кафе часто 11:00-21:00/22:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 90,
                "note": {
                        "ru": "20-90 мин",
                        "en": "0.333333 h-1.5 h",
                        "kk": "0.333333 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Arab Street', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше вечер, совмещать с мечетью Султана.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Улица доступна всегда; магазины/рестораны примерно 10:00-22:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 90,
                "note": {
                        "ru": "20-90 мин",
                        "en": "0.333333 h-1.5 h",
                        "kk": "0.333333 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Bugis Street', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; удобнее в будни до вечера, в дождь - хороший вариант.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 10:00-22:00.",
                        "en": "Typical listed hours include 10:00-22:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
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
                                "ru": "Вход бесплатный; покупки, еда и развлечения отдельно.",
                                "en": "Entry is free. Paid extras may include food from individual stalls, shopping.",
                                "kk": "Кіру тегін. жеке дүңгіршектердегі тамақ, сауда бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Еда / напитки",
                                "en": "Food / drinks",
                                "kk": "Тамақ / сусын"
                        },
                        "description": {
                                "ru": "Еда и напитки оплачиваются у отдельных лавок или ресторанов.",
                                "en": "Food and drinks are paid at individual stalls or restaurants.",
                                "kk": "Тамақ пен сусын жеке дүңгіршектерде немесе мейрамханаларда төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и праздники больше людей; в дождь удобная альтернатива открытым местам.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "WATER",
                        "title": {
                                "ru": "Вода",
                                "en": "Water",
                                "kk": "Су"
                        },
                        "importance": "REQUIRED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Прогулка Southern Ridges', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно светлое время или 07:00-19:00; отдельные парки открыты 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 240,
                "note": {
                        "ru": "3-4 ч",
                        "en": "3 h-4 h",
                        "kk": "3 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 15,
                "maxMinutes": 20,
                "note": {
                        "ru": "15-20 мин",
                        "en": "15-20 min by car or taxi",
                        "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-20 мин",
                                "en": "central Singapore by car or taxi; 15-20 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-20 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-20 мин",
                                "en": "15-20 min by car or taxi",
                                "kk": "15-20 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Полный маршрут около 10 км; можно пройти только участок Henderson Waves.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Петля TreeTop Walk в MacRitchie', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Вт-пт 09:00-17:00, сб/вс/PH 08:30-17:00, пн закрыт кроме праздников; последний вход около 16:45.",
                        "en": "Typical listed hours include 08:30-17:00, 09:00-17:00, 16:45; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 08:30-17:00, 09:00-17:00, 16:45; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car or taxi",
                        "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-25 мин",
                                "en": "central Singapore by car or taxi; 15-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car or taxi",
                                "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "После сильного дождя тропы скользкие, возможны временные закрытия.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Облачный лес', 46, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше 16:00-21:00, чтобы совместить дневной сад и вечернюю подсветку.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 09:00-21:00, последний вход около 20:00; возможны даты техобслуживания.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Для туристов Cloud Forest продаётся через пакет Flower Dome & Cloud Forest: 46 SGD взрослый; резидентам доступен Cloud Forest от 26 SGD / пакет 34 SGD.",
                "en": "Adult/base admission starts around 46 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 46 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 60,
                "maxMinutes": 90,
                "note": {
                        "ru": "1-1,5 ч",
                        "en": "1 h-1.5 h",
                        "kk": "1 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Для туристов Cloud Forest продаётся через пакет Flower Dome & Cloud Forest: 46 SGD взрослый; резидентам доступен Cloud Forest от 26 SGD / пакет 34 SGD.",
                                "en": "Adult/base admission starts around 46 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 46 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 46,
                        "maxAmount": 46,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Для туристов Cloud Forest продаётся через пакет Flower Dome & Cloud Forest: 46 SGD взрослый; резидентам доступен Cloud Forest от 26 SGD / пакет 34 SGD.",
                                "en": "Adult/base admission starts around 46 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 46 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Для туристов Cloud Forest продаётся через пакет Flower Dome & Cloud Forest: 46 SGD взрослый; резидентам доступен Cloud Forest от 26 SGD / пакет 34 SGD.",
                                "en": "Adult/base admission starts around 46 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 46 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 46,
                        "currency": "SGD",
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
                                "ru": "На авто/такси к Gardens by the Bay / Bayfront. 5-10 мин",
                                "en": "central Singapore to Gardens by the Bay / Bayfront by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан Gardens by the Bay / Bayfront бағытына көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Проверять календарь техобслуживания и закрытий.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Роща Супердеревьев', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше 16:00-21:00, чтобы совместить дневной сад и вечернюю подсветку.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Роща 05:00-02:00; подсветка выключается в 23:30; платные обзорные зоны 09:00-21:00, последний вход около 20:30.",
                        "en": "Outdoor gardens are open from early morning until late night; paid conservatories keep shorter hours.",
                        "kk": "Ашық бақтар таңнан түнге дейін ашық; ақылы павильондардың уақыты қысқарақ."
                }
        },
        "priceNote": {
                "ru": "Supertree Grove бесплатна; OCBC Skyway и Supertree Observatory для non-resident по 14 SGD взрослый, для резидентов 10 SGD.",
                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 45,
                "maxMinutes": 120,
                "note": {
                        "ru": "45 мин-2 ч",
                        "en": "0.75 h-2 h",
                        "kk": "0.75 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Supertree Grove бесплатна; OCBC Skyway и Supertree Observatory для non-resident по 14 SGD взрослый, для резидентов 10 SGD.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Supertree Grove бесплатна; OCBC Skyway и Supertree Observatory для non-resident по 14 SGD взрослый, для резидентов 10 SGD.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 14,
                        "maxAmount": 14,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Supertree Grove бесплатна; OCBC Skyway и Supertree Observatory для non-resident по 14 SGD взрослый, для резидентов 10 SGD.",
                                "en": "Entry is free. Paid extras may include paid zones or exhibitions.",
                                "kk": "Кіру тегін. ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 14,
                        "currency": "SGD",
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
                                "ru": "На авто/такси к Gardens by the Bay / Bayfront. 5-10 мин",
                                "en": "central Singapore to Gardens by the Bay / Bayfront by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан Gardens by the Bay / Bayfront бағытына көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Проверять календарь техобслуживания и закрытий.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Марина Барраж', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытые общественные зоны обычно доступны 24 часа; галерея/инфоцентр по дневному расписанию.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Хорошее место для панорамы skyline и кайтов.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Парк Мерлион', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона доступна 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Marina Bay Sands', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона доступна ежедневно; у зданий и заведений часы различаются.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Публичные зоны/ТЦ бесплатны; SkyPark, музей, рестораны и развлечения платные.",
                "en": "Entry is free. Paid extras may include shopping, paid zones or exhibitions.",
                "kk": "Кіру тегін. сауда, ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Публичные зоны/ТЦ бесплатны; SkyPark, музей, рестораны и развлечения платные.",
                                "en": "Entry is free. Paid extras may include shopping, paid zones or exhibitions.",
                                "kk": "Кіру тегін. сауда, ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Публичные зоны/ТЦ бесплатны; SkyPark, музей, рестораны и развлечения платные.",
                                "en": "Entry is free. Paid extras may include shopping, paid zones or exhibitions.",
                                "kk": "Кіру тегін. сауда, ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Публичные зоны/ТЦ бесплатны; SkyPark, музей, рестораны и развлечения платные.",
                                "en": "Entry is free. Paid extras may include shopping, paid zones or exhibitions.",
                                "kk": "Кіру тегін. сауда, ақылы аймақтар немесе көрмелер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Покупки / развлечения",
                                "en": "Shopping / entertainment",
                                "kk": "Сауда / ойын-сауық"
                        },
                        "description": {
                                "ru": "Покупки, еда и развлечения оплачиваются отдельно.",
                                "en": "Shopping, food and entertainment are paid separately.",
                                "kk": "Сауда, тамақ және ойын-сауық бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Без проживания доступ к infinity pool обычно невозможен.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Смотровая площадка Sands SkyPark', 35, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-22:00, последний вход около 21:30.",
                        "en": "Typical listed hours include 10:00-22:00, 21:30; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-22:00, 21:30; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Взрослый: 35 SGD off-peak, 39 SGD peak; указана минимальная официальная цена.",
                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Взрослый: 35 SGD off-peak, 39 SGD peak; указана минимальная официальная цена.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 35,
                        "maxAmount": 35,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Взрослый: 35 SGD off-peak, 39 SGD peak; указана минимальная официальная цена.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Взрослый: 35 SGD off-peak, 39 SGD peak; указана минимальная официальная цена.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 35,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "При грозе/ливне открытые зоны могут закрываться.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Мост Хеликс', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая городская зона, доступна 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Заповедник Сунгей-Булох', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [
                        9,
                        10,
                        11,
                        12,
                        1,
                        2,
                        3
                ],
                "note": {
                        "ru": "Лучше миграционный сезон птиц сентябрь-март; для прогулки - утро.",
                        "en": "Best in September-March; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: қыркүйек-наурыз; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 07:00-19:00, последний вход около 18:30.",
                        "en": "Typical listed hours include 07:00-19:00, 18:30; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:00-19:00, 18:30; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 35,
                "maxMinutes": 50,
                "note": {
                        "ru": "35-50 мин",
                        "en": "35-50 min by car or taxi",
                        "kk": "35-50 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 35,
                        "durationMaxMinutes": 50,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 35-50 мин",
                                "en": "central Singapore by car or taxi; 35-50 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 35-50 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "35-50 мин",
                                "en": "35-50 min by car or taxi",
                                "kk": "35-50 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "После сильного дождя тропы скользкие, возможны временные закрытия.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Заповедник Букит-Тимах', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно светлое время или 07:00-19:00; отдельные парки открыты 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 30,
                "note": {
                        "ru": "20-30 мин",
                        "en": "20-30 min by car or taxi",
                        "kk": "20-30 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 30,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-30 мин",
                                "en": "central Singapore by car or taxi; 20-30 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-30 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-30 мин",
                                "en": "20-30 min by car or taxi",
                                "kk": "20-30 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Подъем короткий, но крутой; после дождя скользко.",
                                "en": "Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Сады озера Джуронг', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Lakeside Garden доступен 24 часа; отдельные зоны работают по своему расписанию.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 25,
                "maxMinutes": 35,
                "note": {
                        "ru": "25-35 мин",
                        "en": "25-35 min by car or taxi",
                        "kk": "25-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 25-35 мин",
                                "en": "central Singapore by car or taxi; 25-35 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 25-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "25-35 мин",
                                "en": "25-35 min by car or taxi",
                                "kk": "25-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "После сильного дождя тропы скользкие, возможны временные закрытия.",
                                "en": "Check the current schedule, maintenance days and closures before visiting. Heat, humidity and sudden rain are common, so plan shade and water.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз. Ыстық, ылғал және кенет жаңбыр жиі болады, көлеңке мен су жоспарлаңыз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Музей искусства и науки', 65, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Вс-чт 10:00-19:00, последний вход 18:00; пт-сб 10:00-21:00, последний вход 20:15.",
                        "en": "Typical listed hours include 10:00-19:00, 10:00-21:00, 18:00, 20:15; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-19:00, 10:00-21:00, 18:00, 20:15; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "The Museum Ticket 2026: стандартный adult 65 SGD в непиковые даты / 77 SGD в пиковые; локальные тарифы 55/63 SGD; отдельные выставки могут отличаться.",
                "en": "Adult/base admission starts around 65 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 65 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "The Museum Ticket 2026: стандартный adult 65 SGD в непиковые даты / 77 SGD в пиковые; локальные тарифы 55/63 SGD; отдельные выставки могут отличаться.",
                                "en": "Adult/base admission starts around 65 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 65 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 65,
                        "maxAmount": 65,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "The Museum Ticket 2026: стандартный adult 65 SGD в непиковые даты / 77 SGD в пиковые; локальные тарифы 55/63 SGD; отдельные выставки могут отличаться.",
                                "en": "Adult/base admission starts around 65 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 65 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 55,
                        "maxAmount": 63,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "The Museum Ticket 2026: стандартный adult 65 SGD в непиковые даты / 77 SGD в пиковые; локальные тарифы 55/63 SGD; отдельные выставки могут отличаться.",
                                "en": "Adult/base admission starts around 65 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 65 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 65,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 55,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Национальная галерея Сингапура', 20, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 10:00-19:00, последний вход 18:30.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "General Admission: туристы/иностранные резиденты 20 SGD; locals/PR бесплатно, All Access дороже.",
                "en": "Adult/base admission starts around 20 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 20 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "General Admission: туристы/иностранные резиденты 20 SGD; locals/PR бесплатно, All Access дороже.",
                                "en": "Adult/base admission starts around 20 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 20 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 20,
                        "maxAmount": 20,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "General Admission: туристы/иностранные резиденты 20 SGD; locals/PR бесплатно, All Access дороже.",
                                "en": "Adult/base admission starts around 20 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 20 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "General Admission: туристы/иностранные резиденты 20 SGD; locals/PR бесплатно, All Access дороже.",
                                "en": "Adult/base admission starts around 20 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 20 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 20,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Музей азиатских цивилизаций', 15, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 10:00-19:00; по пятницам до 21:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Permanent galleries: взрослый иностранный посетитель 15 SGD; locals/PR бесплатно.",
                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Permanent galleries: взрослый иностранный посетитель 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 15,
                        "maxAmount": 15,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Permanent galleries: взрослый иностранный посетитель 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Permanent galleries: взрослый иностранный посетитель 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 15,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Национальный музей Сингапура', 15, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 10:00-19:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "General Admission: Standard Adult для туристов/иностранных резидентов 15 SGD; locals/PR бесплатно.",
                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "General Admission: Standard Adult для туристов/иностранных резидентов 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 15,
                        "maxAmount": 15,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "General Admission: Standard Adult для туристов/иностранных резидентов 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "General Admission: Standard Adult для туристов/иностранных резидентов 15 SGD; locals/PR бесплатно.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 15,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Эспланада - Театры у залива', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно дневные часы; смотреть расписание объекта.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход в публичные зоны бесплатный; концерты/спектакли по билетам.",
                "en": "Entry is free. Paid extras may include shows or events.",
                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 120,
                "note": {
                        "ru": "30 мин-2 ч",
                        "en": "0.5 h-2 h",
                        "kk": "0.5 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 10,
                "note": {
                        "ru": "5-10 мин",
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Вход в публичные зоны бесплатный; концерты/спектакли по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в публичные зоны бесплатный; концерты/спектакли по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Шоу / событие",
                                "en": "Show / event",
                                "kk": "Шоу / шара"
                        },
                        "description": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
                        },
                        "sortOrder": 20
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Вход в публичные зоны бесплатный; концерты/спектакли по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Шоу / событие",
                                "en": "Show / event",
                                "kk": "Шоу / шара"
                        },
                        "description": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Сингапурское колесо обозрения', 40, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 10:00-22:00, последний вход 21:30.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Singapore Flyer + Time Capsule: взрослый 40 SGD, ребёнок 25 SGD; промо и комбинированные пакеты могут отличаться.",
                "en": "Adult/base admission starts around 40 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 40 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                        "en": "5-10 min by car or taxi",
                        "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Singapore Flyer + Time Capsule: взрослый 40 SGD, ребёнок 25 SGD; промо и комбинированные пакеты могут отличаться.",
                                "en": "Adult/base admission starts around 40 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 40 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 40,
                        "maxAmount": 40,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Singapore Flyer + Time Capsule: взрослый 40 SGD, ребёнок 25 SGD; промо и комбинированные пакеты могут отличаться.",
                                "en": "Adult/base admission starts around 40 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 40 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 40,
                        "maxAmount": 40,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Singapore Flyer + Time Capsule: взрослый 40 SGD, ребёнок 25 SGD; промо и комбинированные пакеты могут отличаться.",
                                "en": "Adult/base admission starts around 40 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 40 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 40,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 40,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-10 мин",
                                "en": "central Singapore by car or taxi; 5-10 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-10 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-10 мин",
                                "en": "5-10 min by car or taxi",
                                "kk": "5-10 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Старое здание полиции на Хилл-стрит', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона доступна ежедневно; у зданий и заведений часы различаются.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 15,
                "maxMinutes": 30,
                "note": {
                        "ru": "15-30 мин",
                        "en": "15-30 min",
                        "kk": "15-30 мин"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Отель Raffles Singapore', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Открытая зона доступна ежедневно; у зданий и заведений часы различаются.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Осмотр внешних публичных зон/аркад бесплатный; Long Bar, рестораны, туры и проживание платные.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Осмотр внешних публичных зон/аркад бесплатный; Long Bar, рестораны, туры и проживание платные.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр внешних публичных зон/аркад бесплатный; Long Bar, рестораны, туры и проживание платные.",
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
                                "ru": "Осмотр внешних публичных зон/аркад бесплатный; Long Bar, рестораны, туры и проживание платные.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Не все зоны доступны не-гостям.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Театр и концертный зал Виктория', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно дневные часы; смотреть расписание объекта.",
                        "en": "Check the current daily schedule before visiting.",
                        "kk": "Барар алдында күндік кестені тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Осмотр снаружи бесплатный; мероприятия по билетам.",
                "en": "Entry is free. Paid extras may include shows or events.",
                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 20,
                "maxMinutes": 120,
                "note": {
                        "ru": "20 мин-2 ч",
                        "en": "0.333333 h-2 h",
                        "kk": "0.333333 сағ-2 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 25,
                "note": {
                        "ru": "5-25 мин",
                        "en": "5-25 min by car or taxi",
                        "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Осмотр снаружи бесплатный; мероприятия по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Осмотр снаружи бесплатный; мероприятия по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Шоу / событие",
                                "en": "Show / event",
                                "kk": "Шоу / шара"
                        },
                        "description": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
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
                                "ru": "Осмотр снаружи бесплатный; мероприятия по билетам.",
                                "en": "Entry is free. Paid extras may include shows or events.",
                                "kk": "Кіру тегін. шоу немесе шара бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Шоу / событие",
                                "en": "Show / event",
                                "kk": "Шоу / шара"
                        },
                        "description": {
                                "ru": "Шоу, концерты и события проходят по отдельным билетам.",
                                "en": "Shows, concerts and events use separate tickets.",
                                "kk": "Шоу, концерт және шаралар жеке билетпен өтеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 5-25 мин",
                                "en": "central Singapore by car or taxi; 5-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-25 мин",
                                "en": "5-25 min by car or taxi",
                                "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Clarke Quay', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше вечер, после 18:00.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Набережная доступна всегда; заведения активнее вечером и ночью.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
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
                                "ru": "Бесплатный осмотр снаружи или в публичных зонах.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "DOCUMENTS",
                        "title": {
                                "ru": "Документ для льгот",
                                "en": "Discount document",
                                "kk": "Жеңілдік құжаты"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Universal Studios Singapore', 83, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "По календарю RWS/Sentosa; часто 10:00-19:00/20:00.",
                        "en": "Typical listed hours include 10:00-19:00, 20:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-19:00, 20:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Билеты обычно от 83 SGD для взрослого; цена зависит от даты/пакета.",
                "en": "Adult/base admission starts around 83 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 83 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 360,
                "maxMinutes": 480,
                "note": {
                        "ru": "6-8 ч",
                        "en": "6 h-8 h",
                        "kk": "6 сағ-8 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Билеты обычно от 83 SGD для взрослого; цена зависит от даты/пакета.",
                                "en": "Adult/base admission starts around 83 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 83 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 83,
                        "maxAmount": 83,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Билеты обычно от 83 SGD для взрослого; цена зависит от даты/пакета.",
                                "en": "Adult/base admission starts around 83 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 83 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Билеты обычно от 83 SGD для взрослого; цена зависит от даты/пакета.",
                                "en": "Adult/base admission starts around 83 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 83 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 83,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Сингапурский океанариум', 55, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 10:00-20:00; проверять календарь.",
                        "en": "Typical listed hours include 10:00-20:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-20:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Adult from 55 SGD; child/senior from 43 SGD.",
                "en": "Adult/base admission starts around 55 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 55 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Adult from 55 SGD; child/senior from 43 SGD.",
                                "en": "Adult/base admission starts around 55 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 55 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 55,
                        "maxAmount": 55,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Adult from 55 SGD; child/senior from 43 SGD.",
                                "en": "Adult/base admission starts around 55 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 55 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Adult from 55 SGD; child/senior from 43 SGD.",
                                "en": "Adult/base admission starts around 55 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 55 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 55,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Аквапарк Adventure Cove', 39, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "По календарю RWS; часто 10:00-17:00, по субботам/событиям может быть до 20:00.",
                        "en": "Typical listed hours include 10:00-17:00, 20:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-17:00, 20:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Цены 2026: adult from 39 SGD, child/senior from 34 SGD; промо, пики и пакеты RWS могут отличаться.",
                "en": "Adult/base admission starts around 39 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 39 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 240,
                "maxMinutes": 360,
                "note": {
                        "ru": "4-6 ч",
                        "en": "4 h-6 h",
                        "kk": "4 сағ-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Цены 2026: adult from 39 SGD, child/senior from 34 SGD; промо, пики и пакеты RWS могут отличаться.",
                                "en": "Adult/base admission starts around 39 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 39 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 39,
                        "maxAmount": 39,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Цены 2026: adult from 39 SGD, child/senior from 34 SGD; промо, пики и пакеты RWS могут отличаться.",
                                "en": "Adult/base admission starts around 39 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 39 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Цены 2026: adult from 39 SGD, child/senior from 34 SGD; промо, пики и пакеты RWS могут отличаться.",
                                "en": "Adult/base admission starts around 39 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 39 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 39,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                },
                {
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
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
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Форт Силосо', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 10:00-18:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
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
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Музей мадам Тюссо в Сингапуре', 24, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "С 15.06.2026 заявлено 10:00-18:00, последний вход 17:00.",
                        "en": "Typical listed hours include 10:00-18:00, 17:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00, 17:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Онлайн-билеты от 24 SGD по официальным промо; стандарт/комбо могут быть выше.",
                "en": "Adult/base admission starts around 24 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 24 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "maxMinutes": 25,
                "note": {
                        "ru": "5-25 мин",
                        "en": "5-25 min by car or taxi",
                        "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Онлайн-билеты от 24 SGD по официальным промо; стандарт/комбо могут быть выше.",
                                "en": "Adult/base admission starts around 24 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 24 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 24,
                        "maxAmount": 24,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Онлайн-билеты от 24 SGD по официальным промо; стандарт/комбо могут быть выше.",
                                "en": "Adult/base admission starts around 24 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 24 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Онлайн-билеты от 24 SGD по официальным промо; стандарт/комбо могут быть выше.",
                                "en": "Adult/base admission starts around 24 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 24 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 24,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 5-25 мин",
                                "en": "central Singapore by car or taxi; 5-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-25 мин",
                                "en": "5-25 min by car or taxi",
                                "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Sentosa Sensoryscape', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Доступ 24 часа; ночные световые эффекты лучше смотреть вечером.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Бесплатно.",
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Бесплатно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Бесплатно.",
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
                                "ru": "Бесплатно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Шоу Wings of Time Fireworks Symphony', 22, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ночные показы обычно 19:40 и 20:40.",
                        "en": "Typical listed hours include 19:40, 20:40; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 19:40, 20:40; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Билеты от 22 SGD; места/пакеты могут стоить дороже.",
                "en": "Adult/base admission starts around 22 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 22 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Билеты от 22 SGD; места/пакеты могут стоить дороже.",
                                "en": "Adult/base admission starts around 22 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 22 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 22,
                        "maxAmount": 22,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Билеты от 22 SGD; места/пакеты могут стоить дороже.",
                                "en": "Adult/base admission starts around 22 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 22 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Билеты от 22 SGD; места/пакеты могут стоить дороже.",
                                "en": "Adult/base admission starts around 22 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 22 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 22,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Skyline Luge Singapore', 34, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "По календарю; открытие 10:00/11:00, последний вход примерно за час до закрытия.",
                        "en": "Typical listed hours include 10:00, 11:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00, 11:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "4-ride combo Smart Saver от 34 SGD; 3-ride/фиксированные/пиковые пакеты отличаются.",
                "en": "Adult/base admission starts around 34 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 34 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "4-ride combo Smart Saver от 34 SGD; 3-ride/фиксированные/пиковые пакеты отличаются.",
                                "en": "Adult/base admission starts around 34 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 34 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 34,
                        "maxAmount": 34,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "4-ride combo Smart Saver от 34 SGD; 3-ride/фиксированные/пиковые пакеты отличаются.",
                                "en": "Adult/base admission starts around 34 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 34 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "4-ride combo Smart Saver от 34 SGD; 3-ride/фиксированные/пиковые пакеты отличаются.",
                                "en": "Adult/base admission starts around 34 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 34 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 34,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Парк приключений Mega Adventure', 59, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно 11:00-18:30; закрытия под мероприятия возможны.",
                        "en": "Typical listed hours include 11:00-18:30; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 11:00-18:30; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Цена зависит от активности; MegaZip/пакеты ориентировочно от 59 SGD.",
                "en": "Adult/base admission starts around 59 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 59 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "Цена зависит от активности; MegaZip/пакеты ориентировочно от 59 SGD.",
                                "en": "Adult/base admission starts around 59 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 59 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 59,
                        "maxAmount": 59,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Цена зависит от активности; MegaZip/пакеты ориентировочно от 59 SGD.",
                                "en": "Adult/base admission starts around 59 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 59 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
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
                                "ru": "Цена зависит от активности; MegaZip/пакеты ориентировочно от 59 SGD.",
                                "en": "Adult/base admission starts around 59 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 59 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 59,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Канатная дорога Сингапура', 35, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни и утренний слот, на шоу/пляжи - ближе к закату.",
                        "en": "Best in year-round; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 08:45-22:00, последний посадочный слот около 21:30.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "SkyPass round-trip adult from 35 SGD; Sentosa Line round-trip from 17 SGD.",
                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 20,
                "maxMinutes": 35,
                "note": {
                        "ru": "20-35 мин",
                        "en": "20-35 min by car or taxi",
                        "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "SkyPass round-trip adult from 35 SGD; Sentosa Line round-trip from 17 SGD.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 35,
                        "maxAmount": 35,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "SkyPass round-trip adult from 35 SGD; Sentosa Line round-trip from 17 SGD.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Канатная дорога",
                                "en": "Cable car",
                                "kk": "Аспалы жол"
                        },
                        "description": {
                                "ru": "Канатная дорога или отдельный транспортный билет оплачивается отдельно.",
                                "en": "Cable car or separate transport ticket is paid separately.",
                                "kk": "Аспалы жол немесе жеке көлік билеті бөлек төленеді."
                        },
                        "minAmount": 35,
                        "maxAmount": 35,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Канатная дорога или отдельный транспортный билет оплачивается отдельно.",
                                "en": "Cable car or separate transport ticket is paid separately.",
                                "kk": "Аспалы жол немесе жеке көлік билеті бөлек төленеді."
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
                                "ru": "SkyPass round-trip adult from 35 SGD; Sentosa Line round-trip from 17 SGD.",
                                "en": "Adult/base admission starts around 35 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 35 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 35,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Канатная дорога",
                                "en": "Cable car",
                                "kk": "Аспалы жол"
                        },
                        "description": {
                                "ru": "Канатная дорога или отдельный транспортный билет оплачивается отдельно.",
                                "en": "Cable car or separate transport ticket is paid separately.",
                                "kk": "Аспалы жол немесе жеке көлік билеті бөлек төленеді."
                        },
                        "amount": 35,
                        "currency": "SGD",
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
                                "ru": "На авто/такси через Sentosa Gateway. 20-35 мин",
                                "en": "via Sentosa Gateway by car or taxi; 20-35 min by car or taxi",
                                "kk": "Sentosa Gateway арқылы көлікпен немесе таксимен; 20-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-35 мин",
                                "en": "20-35 min by car or taxi",
                                "kk": "20-35 мин көлікпен немесе таксимен"
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
                                "ru": "В выходные и каникулы очереди выше; при грозе часть активностей закрывают.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                }
        ]
}$$::jsonb),
    ('Парк Маунт-Фейбер', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно светлое время или 07:00-19:00; отдельные парки открыты 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 15,
                "maxMinutes": 20,
                "note": {
                        "ru": "15-20 мин",
                        "en": "15-20 min by car or taxi",
                        "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-20 мин",
                                "en": "central Singapore by car or taxi; 15-20 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-20 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-20 мин",
                                "en": "15-20 min by car or taxi",
                                "kk": "15-20 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Можно совместить с канатной дорогой и Southern Ridges.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Мост Волны Хендерсона', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно светлое время или 07:00-19:00; отдельные парки открыты 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 15,
                "maxMinutes": 20,
                "note": {
                        "ru": "15-20 мин",
                        "en": "15-20 min by car or taxi",
                        "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 20,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-20 мин",
                                "en": "central Singapore by car or taxi; 15-20 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-20 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-20 мин",
                                "en": "15-20 min by car or taxi",
                                "kk": "15-20 мин көлікпен немесе таксимен"
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
                                "ru": "Красивый короткий участок Southern Ridges.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Природный заповедник Лабрадор', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно светлое время или 07:00-19:00; отдельные парки открыты 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                        "en": "20-25 min by car or taxi",
                        "kk": "20-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 20,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 20-25 мин",
                                "en": "central Singapore by car or taxi; 20-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 20-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "20-25 мин",
                                "en": "20-25 min by car or taxi",
                                "kk": "20-25 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Можно совместить с Berlayer Creek и Southern Ridges.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 20
                },
                {
                        "itemType": "MAP",
                        "title": {
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                        "itemType": "SPF",
                        "title": {
                                "ru": "SPF/головной убор",
                                "en": "SPF and hat",
                                "kk": "SPF және бас киім"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                }
        ]
}$$::jsonb),
    ('Храм и музей Зуба Будды', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше утро/до обеда, избегать времени молитв и крупных праздников без подготовки.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Храм: ежедневно около 07:00-17:00; музей обычно 09:00-17:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Соблюдайте дресс-код, снимайте обувь там, где требуется, не мешайте молитвам.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                }
        ]
}$$::jsonb),
    ('Храм Шри Мариамман', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше утро/до обеда, избегать времени молитв и крупных праздников без подготовки.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно: 07:00-12:00 и 18:00-21:00; по пятницам вечер до 21:15.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Соблюдайте дресс-код, снимайте обувь там, где требуется, не мешайте молитвам.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                }
        ]
}$$::jsonb),
    ('Храм Тхиан Хок Кенг', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше утро/до обеда, избегать времени молитв и крупных праздников без подготовки.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ориентир 07:30-17:30.",
                        "en": "Typical listed hours include 07:30-17:30; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 07:30-17:30; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Соблюдайте дресс-код, снимайте обувь там, где требуется, не мешайте молитвам.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                }
        ]
}$$::jsonb),
    ('Храм Шри Вирамакалиамман', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше утро/до обеда, избегать времени молитв и крупных праздников без подготовки.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Обычно split hours: утром и вечером; ориентир 05:30/06:00-12:00 и 16:00/18:00-21:00.",
                        "en": "Typical listed hours include 05:30, 06:00-12:00, 16:00, 18:00-21:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 05:30, 06:00-12:00, 16:00, 18:00-21:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Соблюдайте дресс-код, снимайте обувь там, где требуется, не мешайте молитвам.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                }
        ]
}$$::jsonb),
    ('Центр индийского наследия', 10, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "10:00-18:00, закрыт по понедельникам.",
                        "en": "Typical listed hours include 10:00-18:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-18:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Foreign residents & tourists adult 10 SGD; Singaporeans/PR бесплатно.",
                "en": "Adult/base admission starts around 10 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 10 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "maxMinutes": 25,
                "note": {
                        "ru": "5-25 мин",
                        "en": "5-25 min by car or taxi",
                        "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Foreign residents & tourists adult 10 SGD; Singaporeans/PR бесплатно.",
                                "en": "Adult/base admission starts around 10 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 10 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 10,
                        "maxAmount": 10,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Foreign residents & tourists adult 10 SGD; Singaporeans/PR бесплатно.",
                                "en": "Adult/base admission starts around 10 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 10 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Foreign residents & tourists adult 10 SGD; Singaporeans/PR бесплатно.",
                                "en": "Adult/base admission starts around 10 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 10 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 10,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 5,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 5-25 мин",
                                "en": "central Singapore by car or taxi; 5-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-25 мин",
                                "en": "5-25 min by car or taxi",
                                "kk": "5-25 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Мечеть Султана', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше утро/до обеда, избегать времени молитв и крупных праздников без подготовки.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Для посетителей обычно сб-чт 10:00-12:00 и 14:00-16:00; пятница ограничена из-за молитв.",
                        "en": "Typical listed hours include 10:00-12:00, 14:00-16:00; check event and holiday changes.",
                        "kk": "Көрсетілген әдеттегі уақыт: 10:00-12:00, 14:00-16:00; шара мен мереке күндерін тексеріңіз."
                }
        },
        "priceNote": {
                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 30,
                "maxMinutes": 90,
                "note": {
                        "ru": "30-90 мин",
                        "en": "0.5 h-1.5 h",
                        "kk": "0.5 сағ-1.5 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 5,
                "maxMinutes": 15,
                "note": {
                        "ru": "5-15 мин",
                        "en": "5-15 min by car or taxi",
                        "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
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
                                "ru": "Вход обычно бесплатный; пожертвования приветствуются.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 5-15 мин",
                                "en": "central Singapore by car or taxi; 5-15 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 5-15 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "5-15 мин",
                                "en": "5-15 min by car or taxi",
                                "kk": "5-15 мин көлікпен немесе таксимен"
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
                                "ru": "Соблюдайте дресс-код, снимайте обувь там, где требуется, не мешайте молитвам.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "CASH",
                        "title": {
                                "ru": "Наличные SGD",
                                "en": "Cash in SGD",
                                "kk": "Қолма-қол ақша"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 10
                }
        ]
}$$::jsonb),
    ('Сингапурский ботанический сад', 0, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 05:00-00:00.",
                        "en": "Outdoor gardens are open from early morning until late night; paid conservatories keep shorter hours.",
                        "kk": "Ашық бақтар таңнан түнге дейін ашық; ақылы павильондардың уақыты қысқарақ."
                }
        },
        "priceNote": {
                "ru": "Вход в Botanic Gardens бесплатный; National Orchid Garden оплачивается отдельно.",
                "en": "Entry is free. Paid extras may include selected extras.",
                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
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
                        "en": "15-25 min by car or taxi",
                        "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход в Botanic Gardens бесплатный; National Orchid Garden оплачивается отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход в Botanic Gardens бесплатный; National Orchid Garden оплачивается отдельно.",
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
                                "ru": "Вход в Botanic Gardens бесплатный; National Orchid Garden оплачивается отдельно.",
                                "en": "Entry is free. Paid extras may include selected extras.",
                                "kk": "Кіру тегін. таңдалған қосымша қызметтер бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 15-25 мин",
                                "en": "central Singapore by car or taxi; 15-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car or taxi",
                                "kk": "15-25 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Национальный сад орхидей', 15, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 08:30-19:00, последний вход около 18:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Стандартный взрослый билет для foreign visitors около 15 SGD; местные взрослые дешевле.",
                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "maxMinutes": 40,
                "note": {
                        "ru": "15-25 мин + 10-15 мин пешком",
                        "en": "25-40 min by car or taxi",
                        "kk": "25-40 мин көлікпен немесе таксимен"
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
                                "ru": "Стандартный взрослый билет для foreign visitors около 15 SGD; местные взрослые дешевле.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 15,
                        "maxAmount": 15,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Стандартный взрослый билет для foreign visitors около 15 SGD; местные взрослые дешевле.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Стандартный взрослый билет для foreign visitors около 15 SGD; местные взрослые дешевле.",
                                "en": "Adult/base admission starts around 15 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 15 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 15,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 15-25 мин + 10-15 мин пешком",
                                "en": "central Singapore by car or taxi; 25-40 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 25-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин + 10-15 мин пешком",
                                "en": "25-40 min by car or taxi",
                                "kk": "25-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                                "ru": "Телефон/карта",
                                "en": "Phone or map",
                                "kk": "Телефон немесе карта"
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
                }
        ]
}$$::jsonb),
    ('Сингапурский зоопарк', 49, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 08:30-18:00, последний вход 17:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Туристический взрослый билет около 49 SGD; локальные WildPass/промо могут быть дешевле.",
                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 240,
                "maxMinutes": 360,
                "note": {
                        "ru": "4-6 ч",
                        "en": "4 h-6 h",
                        "kk": "4 сағ-6 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Туристический взрослый билет около 49 SGD; локальные WildPass/промо могут быть дешевле.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 49,
                        "maxAmount": 49,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туристический взрослый билет около 49 SGD; локальные WildPass/промо могут быть дешевле.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Туристический взрослый билет около 49 SGD; локальные WildPass/промо могут быть дешевле.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 49,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 30-40 мин",
                                "en": "central Singapore by car or taxi; 30-40 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Ночное сафари', 58, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 18:00-00:00, последний вход 23:15.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Туристический взрослый билет ориентир 58 SGD; официальные промо/локальные цены могут начинаться ниже.",
                "en": "Adult/base admission starts around 58 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 58 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 240,
                "note": {
                        "ru": "3-4 ч",
                        "en": "3 h-4 h",
                        "kk": "3 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Туристический взрослый билет ориентир 58 SGD; официальные промо/локальные цены могут начинаться ниже.",
                                "en": "Adult/base admission starts around 58 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 58 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 58,
                        "maxAmount": 58,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туристический взрослый билет ориентир 58 SGD; официальные промо/локальные цены могут начинаться ниже.",
                                "en": "Adult/base admission starts around 58 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 58 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Туристический взрослый билет ориентир 58 SGD; официальные промо/локальные цены могут начинаться ниже.",
                                "en": "Adult/base admission starts around 58 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 58 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 58,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 30-40 мин",
                                "en": "central Singapore by car or taxi; 30-40 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('River Wonders', 45, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 09:00-18:00, последний вход 17:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Туристический взрослый билет около 45 SGD.",
                "en": "Adult/base admission starts around 45 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 45 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "minMinutes": 30,
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Туристический взрослый билет около 45 SGD.",
                                "en": "Adult/base admission starts around 45 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 45 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 45,
                        "maxAmount": 45,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туристический взрослый билет около 45 SGD.",
                                "en": "Adult/base admission starts around 45 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 45 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Туристический взрослый билет около 45 SGD.",
                                "en": "Adult/base admission starts around 45 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 45 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 45,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 30-40 мин",
                                "en": "central Singapore by car or taxi; 30-40 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Bird Paradise', 49, $${
        "bestTime": "SUNSET",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель или утро/вечер в сухие дни. В сезон ливней держать запас по времени.",
                        "en": "Best in year-round; morning is usually cooler; evening works well for lights or cooler weather",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; кешкі уақыт жарық пен салқын ауаға қолайлы"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 09:00-18:00, последний вход 17:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Туристический взрослый билет около 49 SGD.",
                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
        },
        "timeOnSite": {
                "minMinutes": 180,
                "maxMinutes": 240,
                "note": {
                        "ru": "3-4 ч",
                        "en": "3 h-4 h",
                        "kk": "3 сағ-4 сағ"
                }
        },
        "carTravelTime": {
                "minMinutes": 30,
                "maxMinutes": 40,
                "note": {
                        "ru": "30-40 мин",
                        "en": "30-40 min by car or taxi",
                        "kk": "30-40 мин көлікпен немесе таксимен"
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
                                "ru": "Туристический взрослый билет около 49 SGD.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 49,
                        "maxAmount": 49,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Туристический взрослый билет около 49 SGD.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                                "ru": "Туристический взрослый билет около 49 SGD.",
                                "en": "Adult/base admission starts around 49 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 49 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 49,
                        "currency": "SGD",
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
                                "ru": "На авто/такси от центра. 30-40 мин",
                                "en": "central Singapore by car or taxi; 30-40 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 30-40 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "30-40 мин",
                                "en": "30-40 min by car or taxi",
                                "kk": "30-40 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Лучше раннее утро или вечер для фото и меньшей жары.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                                "ru": "Зонт/дождевик",
                                "en": "Umbrella or rain jacket",
                                "kk": "Қолшатыр немесе жаңбырлық"
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
                        "itemType": "REPELLENT",
                        "title": {
                                "ru": "Репеллент",
                                "en": "Repellent",
                                "kk": "Репеллент"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                }
        ]
}$$::jsonb),
    ('Changi Experience Studio', 25, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше будни утром или за 2-3 часа до закрытия.",
                        "en": "Best in year-round; morning is usually cooler",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Ежедневно 11:00-20:00, последний вход 19:00.",
                        "en": "Usually accessible daily; individual services can follow their own schedule.",
                        "kk": "Әдетте күн сайын қолжетімді; жеке қызметтер өз кестесімен жұмыс істейді."
                }
        },
        "priceNote": {
                "ru": "Entry-only/промо-цены обычно около 20-25 SGD; официальные bundle-пакеты с Canopy Park могут быть 56/71 SGD.",
                "en": "Adult/base admission starts around 25 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                "kk": "Ересек адамға негізгі кіру шамамен 25 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
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
                "maxMinutes": 35,
                "note": {
                        "ru": "25-35 мин",
                        "en": "25-35 min by car or taxi",
                        "kk": "25-35 мин көлікпен немесе таксимен"
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
                                "ru": "Entry-only/промо-цены обычно около 20-25 SGD; официальные bundle-пакеты с Canopy Park могут быть 56/71 SGD.",
                                "en": "Adult/base admission starts around 25 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 25 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "minAmount": 25,
                        "maxAmount": 25,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": true,
                        "isApproximate": true,
                        "note": {
                                "ru": "Entry-only/промо-цены обычно около 20-25 SGD; официальные bundle-пакеты с Canopy Park могут быть 56/71 SGD.",
                                "en": "Adult/base admission starts around 25 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 25 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "minAmount": 20,
                        "maxAmount": 25,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
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
                                "ru": "Entry-only/промо-цены обычно около 20-25 SGD; официальные bundle-пакеты с Canopy Park могут быть 56/71 SGD.",
                                "en": "Adult/base admission starts around 25 SGD. Peak dates, bundles, resident prices and optional extras can differ.",
                                "kk": "Ересек адамға негізгі кіру шамамен 25 SGD-ден басталады. Пик күндер, пакет, резидент бағасы және қосымша қызмет өзгеруі мүмкін."
                        },
                        "amount": 25,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Платные зоны / выставки",
                                "en": "Paid zones / exhibitions",
                                "kk": "Ақылы аймақтар / көрмелер"
                        },
                        "description": {
                                "ru": "Павильоны, смотровые площадки, выставки или комбинированные билеты оплачиваются отдельно.",
                                "en": "Conservatories, observation decks, exhibitions or bundles are paid separately.",
                                "kk": "Павильондар, қарау алаңдары, көрмелер немесе пакеттер бөлек төленеді."
                        },
                        "amount": 20,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 25,
                        "durationMaxMinutes": 35,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 25-35 мин",
                                "en": "central Singapore by car or taxi; 25-35 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 25-35 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "PAVED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "25-35 мин",
                                "en": "25-35 min by car or taxi",
                                "kk": "25-35 мин көлікпен немесе таксимен"
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
                                "ru": "Цены и выставки меняются по календарю.",
                                "en": "Check the current schedule, maintenance days and closures before visiting.",
                                "kk": "Кесте, жөндеу күндері және жабылуларды алдын ала тексеріңіз."
                        },
                        "priority": "IMPORTANT",
                        "sortOrder": 10
                }
        ],
        "recommendedItems": [
                {
                        "itemType": "WARM_CLOTHES",
                        "title": {
                                "ru": "Легкая кофта",
                                "en": "Light layer",
                                "kk": "Жеңіл қабат киім"
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
    ('Парк Ист-Кост', 0, $${
        "bestTime": "EARLY_MORNING",
        "season": {
                "months": [],
                "note": {
                        "ru": "Круглый год; лучше февраль-апрель, раннее утро, не сразу после сильного дождя.",
                        "en": "Best in year-round; morning is usually cooler; check rain and heat before outdoor time",
                        "kk": "Ең қолайлы кезең: жыл бойы; таңертең салқындау; ашық ауаға жаңбыр мен ыстықты тексеріңіз"
                }
        },
        "openingHours": {
                "summary": {
                        "ru": "Парк открыт 24 часа.",
                        "en": "Public complex is listed as 24 hours; individual stalls can vary.",
                        "kk": "Қоғамдық кешен тәулік бойы деп көрсетіледі; жеке орындардың уақыты өзгеруі мүмкін."
                }
        },
        "priceNote": {
                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
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
                "minMinutes": 15,
                "maxMinutes": 25,
                "note": {
                        "ru": "15-25 мин",
                        "en": "15-25 min by car or taxi",
                        "kk": "15-25 мин көлікпен немесе таксимен"
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "sortOrder": 10
                },
                {
                        "type": "OTHER",
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Парковка может оплачиваться отдельно.",
                                "en": "Parking may be charged separately.",
                                "kk": "Тұрақ бөлек төленуі мүмкін."
                        },
                        "sortOrder": 30
                },
                {
                        "type": "TRANSPORT",
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "minAmount": 0,
                        "maxAmount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "required": false,
                        "isApproximate": true,
                        "note": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
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
                                "ru": "Вход бесплатный; аренды/парковка/лодка могут оплачиваться отдельно.",
                                "en": "Entry is free. Paid extras may include rentals and activities, boat or transport.",
                                "kk": "Кіру тегін. жалға алу және белсенділік, қайық немесе көлік бөлек төленуі мүмкін."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 10
                },
                {
                        "title": {
                                "ru": "Аренда / активности",
                                "en": "Rentals / activities",
                                "kk": "Жалға алу / белсенділік"
                        },
                        "description": {
                                "ru": "Аренда, лежаки и активности оплачиваются отдельно.",
                                "en": "Rentals, loungers and activities are paid separately.",
                                "kk": "Жалға алу, жатақ орындық және белсенділік бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 20
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
                        "currency": "SGD",
                        "unit": "CAR",
                        "isApproximate": true,
                        "sortOrder": 30
                },
                {
                        "title": {
                                "ru": "Лодка / трансфер",
                                "en": "Boat / transfer",
                                "kk": "Қайық / трансфер"
                        },
                        "description": {
                                "ru": "Лодка или островной трансфер оплачивается отдельно.",
                                "en": "Boat or island transfer is paid separately.",
                                "kk": "Қайық немесе арал трансфері бөлек төленеді."
                        },
                        "amount": 0,
                        "currency": "SGD",
                        "unit": "PERSON",
                        "isApproximate": true,
                        "sortOrder": 40
                }
        ],
        "accessOptions": [
                {
                        "transportType": "CAR",
                        "durationMinMinutes": 15,
                        "durationMaxMinutes": 25,
                        "routeHint": {
                                "ru": "На авто/такси от центра. 15-25 мин",
                                "en": "central Singapore by car or taxi; 15-25 min by car or taxi",
                                "kk": "Сингапур орталығынан көлікпен немесе таксимен; 15-25 мин көлікпен немесе таксимен"
                        },
                        "roadCondition": "MIXED",
                        "requires4x4": false,
                        "parkingNote": {
                                "ru": "Парковка и такси в пиковые часы могут быть дороже.",
                                "en": "Parking and taxis can cost more at peak times.",
                                "kk": "Пик уақытта тұрақ пен такси қымбаттауы мүмкін."
                        },
                        "note": {
                                "ru": "15-25 мин",
                                "en": "15-25 min by car or taxi",
                                "kk": "15-25 мин көлікпен немесе таксимен"
                        },
                        "sortOrder": 10,
                        "lastSegmentNote": {
                                "ru": "Следите за дождем, жарой и локальными правилами доступа.",
                                "en": "Watch rain, heat and local access rules.",
                                "kk": "Жаңбыр, ыстық және жергілікті кіру ережесін бақылаңыз."
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
                                "ru": "Большая береговая зона; заранее выберите парковку/участок.",
                                "en": "Check current access rules, weather and crowd levels before visiting.",
                                "kk": "Кіру ережесі, ауа райы және адам көптігін алдын ала тексеріңіз."
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
                        "itemType": "SWIMWEAR",
                        "title": {
                                "ru": "Купальные вещи",
                                "en": "Swimwear",
                                "kk": "Шомылу киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 40
                },
                {
                        "itemType": "TOWEL",
                        "title": {
                                "ru": "Полотенце",
                                "en": "Towel",
                                "kk": "Сүлгі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 50
                },
                {
                        "itemType": "DRY_BAG",
                        "title": {
                                "ru": "Сухой пакет",
                                "en": "Dry bag",
                                "kk": "Құрғақ сөмке"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 60
                },
                {
                        "itemType": "SANDALS",
                        "title": {
                                "ru": "Пляжная обувь",
                                "en": "Beach sandals",
                                "kk": "Жағажай аяқ киімі"
                        },
                        "importance": "RECOMMENDED",
                        "sortOrder": 70
                }
        ]
}$$::jsonb);

WITH matched_places AS (
    SELECT DISTINCT
        p.id AS place_id,
        seed.price_amount,
        seed.visit_info
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
     AND p.deleted_at IS NULL
)
UPDATE places p
SET
    price_amount = COALESCE(m.price_amount, p.price_amount),
    price_currency = CASE WHEN m.price_amount IS NULL THEN p.price_currency ELSE 'SGD' END,
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
     AND p.deleted_at IS NULL
)
INSERT INTO place_visit_info (
    place_id, best_season_months, opening_hours, time_on_site_min_minutes, time_on_site_max_minutes,
    car_travel_time_min_minutes, car_travel_time_max_minutes, car_route_hint, road_condition,
    price_note, planning_note, last_verified_at
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
     AND p.deleted_at IS NULL
)
INSERT INTO place_access_options (
    place_id, transport_type, duration_min_minutes, duration_max_minutes, route_hint, road_condition, requires_4x4,
    parking_note, last_segment_note, note, sort_order
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
     AND p.deleted_at IS NULL
)
INSERT INTO place_practical_notes (place_id, note_type, title, body, priority, sort_order)
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
    FROM seed_singapore_visit_planning seed
    JOIN place_translations pt
      ON pt.locale = 'ru'
     AND pt.title = seed.title_ru
    JOIN places p
      ON p.id = pt.place_id
     AND p.country_code = 'SG'
     AND p.deleted_at IS NULL
)
INSERT INTO place_recommended_items (place_id, item_type, title, importance, season, note, sort_order)
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

DROP TABLE seed_singapore_visit_planning;
