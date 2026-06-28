INSERT INTO support_saved_replies (
    id,
    category,
    status,
    tags,
    translations,
    sort_order,
    created_at,
    updated_at
)
VALUES
    (
        'account_login_issue',
        'account',
        'published',
        ARRAY['account', 'login', 'auth']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Не получается войти',
                'body', 'Понимаем, что это мешает пользоваться приложением. Проверьте, пожалуйста, актуальность номера/почты и попробуйте запросить новый код входа. Если код не приходит, напишите, какой способ входа используете и в какой стране сейчас находитесь — проверим с нашей стороны.'
            ),
            'en', jsonb_build_object(
                'title', 'Cannot sign in',
                'body', 'We understand this blocks access to the app. Please check that your phone/email is current and request a new sign-in code. If the code does not arrive, tell us which sign-in method you use and which country you are in — we will check it on our side.'
            ),
            'kk', jsonb_build_object(
                'title', 'Кіру мүмкін емес',
                'body', 'Бұл қолданбаны пайдалануға кедергі екенін түсінеміз. Нөміріңіз/поштаңыз өзекті екенін тексеріп, жаңа кіру кодын сұраңыз. Код келмесе, қандай кіру тәсілін қолданатыныңызды және қай елде екеніңізді жазыңыз — біз өз жағымыздан тексереміз.'
            )
        ),
        10,
        now(),
        now()
    ),
    (
        'account_profile_update',
        'account',
        'published',
        ARRAY['account', 'profile', 'settings']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Изменение данных профиля',
                'body', 'Мы можем подсказать по настройкам профиля. Напишите, какое поле не получается изменить и что именно видите на экране. Если это чувствительные данные, не отправляйте документы или коды в чат — мы подскажем безопасный способ проверки.'
            ),
            'en', jsonb_build_object(
                'title', 'Profile data update',
                'body', 'We can help with profile settings. Please tell us which field you cannot update and what you see on the screen. If it involves sensitive data, do not send documents or codes in chat — we will suggest a safe verification path.'
            ),
            'kk', jsonb_build_object(
                'title', 'Профиль деректерін өзгерту',
                'body', 'Профиль баптаулары бойынша көмектесеміз. Қай өрісті өзгерте алмай жатқаныңызды және экранда не көрінетінін жазыңыз. Егер бұл құпия деректерге қатысты болса, құжаттарды немесе кодтарды чатқа жібермеңіз — қауіпсіз тексеру жолын ұсынамыз.'
            )
        ),
        20,
        now(),
        now()
    ),
    (
        'activity_meeting_point',
        'activities',
        'published',
        ARRAY['activities', 'meeting-point', 'route']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Место встречи по активности',
                'body', 'Проверьте, пожалуйста, блок с местом встречи в карточке активности. Если точка непонятна или отличается от сообщения организатора, отправьте нам название активности и скриншот — поможем уточнить детали.'
            ),
            'en', jsonb_build_object(
                'title', 'Activity meeting point',
                'body', 'Please check the meeting point block in the activity card. If the location is unclear or differs from the organizer message, send us the activity name and a screenshot — we will help clarify it.'
            ),
            'kk', jsonb_build_object(
                'title', 'Белсенділік кездесу орны',
                'body', 'Белсенділік карточкасындағы кездесу орны блогын тексеріңіз. Егер нүкте түсініксіз болса немесе ұйымдастырушы хабарламасынан өзгеше болса, белсенділік атауын және скриншот жіберіңіз — нақтылауға көмектесеміз.'
            )
        ),
        110,
        now(),
        now()
    ),
    (
        'activity_cancellation_policy',
        'activities',
        'published',
        ARRAY['activities', 'cancel', 'policy']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Отмена активности',
                'body', 'Условия отмены зависят от активности и времени до начала. Проверьте правила в карточке активности. Если кнопка отмены недоступна или правило выглядит спорно, пришлите название активности — проверим статус участия.'
            ),
            'en', jsonb_build_object(
                'title', 'Activity cancellation',
                'body', 'Cancellation terms depend on the activity and time before start. Please check the rules in the activity card. If the cancel button is unavailable or the rule looks unclear, send us the activity name — we will check your participation status.'
            ),
            'kk', jsonb_build_object(
                'title', 'Белсенділікті тоқтату',
                'body', 'Тоқтату шарттары белсенділікке және басталу уақытына байланысты. Карточкадағы ережені тексеріңіз. Егер тоқтату батырмасы жоқ болса немесе шарт түсініксіз көрінсе, белсенділік атауын жіберіңіз — қатысу статусын тексереміз.'
            )
        ),
        120,
        now(),
        now()
    ),
    (
        'excursion_booking_question',
        'excursions',
        'published',
        ARRAY['excursions', 'booking', 'guests']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Вопрос по бронированию экскурсии',
                'body', 'Напишите, пожалуйста, название экскурсии, дату, количество гостей и что именно не получается сделать. Мы проверим бронирование и подскажем следующий шаг.'
            ),
            'en', jsonb_build_object(
                'title', 'Excursion booking question',
                'body', 'Please send the excursion name, date, number of guests, and what exactly does not work. We will check the booking and suggest the next step.'
            ),
            'kk', jsonb_build_object(
                'title', 'Экскурсия брондау сұрағы',
                'body', 'Экскурсия атауын, күнін, қонақ санын және нақты не істелмей жатқанын жазыңыз. Брондауды тексеріп, келесі қадамды айтамыз.'
            )
        ),
        210,
        now(),
        now()
    ),
    (
        'excursion_guide_contact',
        'excursions',
        'published',
        ARRAY['excursions', 'guide', 'contact']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Связь с гидом',
                'body', 'Если гид не отвечает, напишите нам название экскурсии и дату. Мы проверим статус бронирования и поможем связаться с гидом или подобрать безопасный следующий шаг.'
            ),
            'en', jsonb_build_object(
                'title', 'Contacting the guide',
                'body', 'If the guide does not reply, send us the excursion name and date. We will check the booking status and help contact the guide or choose a safe next step.'
            ),
            'kk', jsonb_build_object(
                'title', 'Гидпен байланысу',
                'body', 'Гид жауап бермесе, экскурсия атауы мен күнін жазыңыз. Брондау статусын тексеріп, гидпен байланысуға немесе қауіпсіз келесі қадамды таңдауға көмектесеміз.'
            )
        ),
        220,
        now(),
        now()
    ),
    (
        'place_hours_or_price_check',
        'places',
        'published',
        ARRAY['places', 'hours', 'price']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Часы работы или цена места',
                'body', 'Информация по местам может меняться. Напишите, какое место вы смотрите и что именно отличается: часы работы, цена, адрес или правила входа. Мы проверим данные и обновим карточку при необходимости.'
            ),
            'en', jsonb_build_object(
                'title', 'Place hours or price',
                'body', 'Place information can change. Please tell us which place you are viewing and what differs: opening hours, price, address, or entry rules. We will verify the data and update the card if needed.'
            ),
            'kk', jsonb_build_object(
                'title', 'Орынның жұмыс уақыты немесе бағасы',
                'body', 'Орындар туралы ақпарат өзгеруі мүмкін. Қай орынды қарап отырғаныңызды және нақты не сәйкес емес екенін жазыңыз: жұмыс уақыты, баға, мекенжай немесе кіру ережесі. Деректі тексеріп, қажет болса карточканы жаңартамыз.'
            )
        ),
        310,
        now(),
        now()
    ),
    (
        'place_info_correction',
        'places',
        'published',
        ARRAY['places', 'correction', 'content']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Исправление информации о месте',
                'body', 'Спасибо, что помогаете улучшать данные. Пришлите, пожалуйста, название места, что нужно исправить и источник/скриншот, если он есть. Мы передадим информацию на проверку.'
            ),
            'en', jsonb_build_object(
                'title', 'Place information correction',
                'body', 'Thank you for helping improve the data. Please send the place name, what should be corrected, and a source or screenshot if available. We will pass it for review.'
            ),
            'kk', jsonb_build_object(
                'title', 'Орын туралы ақпаратты түзету',
                'body', 'Деректерді жақсартуға көмектескеніңізге рахмет. Орын атауын, нені түзету керегін және бар болса дереккөз/скриншот жіберіңіз. Ақпаратты тексеруге жібереміз.'
            )
        ),
        320,
        now(),
        now()
    ),
    (
        'payment_refund_status',
        'payments',
        'published',
        ARRAY['payments', 'refund', 'status']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Статус возврата',
                'body', 'Проверим статус возврата. Пришлите, пожалуйста, ID бронирования или название активности/экскурсии и дату оплаты. Не отправляйте полные данные карты — они не нужны для проверки.'
            ),
            'en', jsonb_build_object(
                'title', 'Refund status',
                'body', 'We will check the refund status. Please send the booking ID or the activity/excursion name and payment date. Do not send full card details — they are not needed for verification.'
            ),
            'kk', jsonb_build_object(
                'title', 'Қайтарым статусы',
                'body', 'Қайтарым статусын тексереміз. Брондау ID-ын немесе белсенділік/экскурсия атауын және төлем күнін жіберіңіз. Картаның толық деректерін жібермеңіз — тексеруге қажет емес.'
            )
        ),
        410,
        now(),
        now()
    ),
    (
        'payment_failed_charge',
        'payments',
        'published',
        ARRAY['payments', 'failed', 'charge']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Платеж не прошел или списание непонятно',
                'body', 'Понимаем беспокойство. Напишите сумму, дату платежа и что вы видите в приложении: ошибка, ожидание, списание или двойное списание. Не отправляйте полный номер карты или CVV.'
            ),
            'en', jsonb_build_object(
                'title', 'Payment failed or unclear charge',
                'body', 'We understand the concern. Please send the amount, payment date, and what you see in the app: error, pending state, charge, or duplicate charge. Do not send the full card number or CVV.'
            ),
            'kk', jsonb_build_object(
                'title', 'Төлем өтпеді немесе түсініксіз списание',
                'body', 'Уайымыңызды түсінеміз. Соманы, төлем күнін және қолданбада не көріп тұрғаныңызды жазыңыз: қате, күту, списание немесе екі рет списание. Картаның толық нөмірін немесе CVV жібермеңіз.'
            )
        ),
        420,
        now(),
        now()
    ),
    (
        'currency_rate_notice',
        'currency',
        'published',
        ARRAY['currency', 'rates', 'converter']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Курс валют отличается',
                'body', 'Курсы в приложении могут отличаться от курса банка, обменника или платежной системы из-за времени обновления и комиссии. Напишите валютную пару и пример суммы — проверим отображение.'
            ),
            'en', jsonb_build_object(
                'title', 'Currency rate differs',
                'body', 'Rates in the app may differ from a bank, exchange office, or payment system because of update timing and fees. Send the currency pair and example amount — we will check the display.'
            ),
            'kk', jsonb_build_object(
                'title', 'Валюта бағамы өзгеше',
                'body', 'Қолданбадағы бағам банк, айырбастау орны немесе төлем жүйесі бағамынан жаңарту уақыты мен комиссияға байланысты өзгеше болуы мүмкін. Валюта жұбын және мысал соманы жіберіңіз — көрсетілімді тексереміз.'
            )
        ),
        510,
        now(),
        now()
    ),
    (
        'technical_app_issue',
        'technical',
        'published',
        ARRAY['technical', 'app', 'bug']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Техническая ошибка в приложении',
                'body', 'Спасибо, что сообщили. Напишите, пожалуйста, что нажимали перед ошибкой, модель устройства, версию приложения и приложите скриншот, если возможно. Это поможет быстрее найти причину.'
            ),
            'en', jsonb_build_object(
                'title', 'Technical issue in the app',
                'body', 'Thank you for reporting this. Please tell us what you tapped before the error, your device model, app version, and attach a screenshot if possible. This helps us find the cause faster.'
            ),
            'kk', jsonb_build_object(
                'title', 'Қолданбадағы техникалық қате',
                'body', 'Хабарлағаныңызға рахмет. Қате алдында нені басқаныңызды, құрылғы моделін, қолданба нұсқасын жазыңыз және мүмкін болса скриншот тіркеңіз. Бұл себепті тезірек табуға көмектеседі.'
            )
        ),
        610,
        now(),
        now()
    ),
    (
        'technical_notifications_issue',
        'technical',
        'published',
        ARRAY['technical', 'notifications', 'push']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Не приходят уведомления',
                'body', 'Проверьте, пожалуйста, что уведомления разрешены в настройках телефона и в приложении. Если все включено, напишите модель устройства, систему iOS/Android и какие уведомления не приходят.'
            ),
            'en', jsonb_build_object(
                'title', 'Notifications do not arrive',
                'body', 'Please check that notifications are allowed in phone settings and inside the app. If everything is enabled, send your device model, iOS/Android version, and which notifications are missing.'
            ),
            'kk', jsonb_build_object(
                'title', 'Хабарландырулар келмейді',
                'body', 'Телефон баптауларында және қолданба ішінде хабарландыруларға рұқсат берілгенін тексеріңіз. Барлығы қосулы болса, құрылғы моделін, iOS/Android нұсқасын және қандай хабарландыру келмейтінін жазыңыз.'
            )
        ),
        620,
        now(),
        now()
    ),
    (
        'technical_need_more_details',
        'technical',
        'published',
        ARRAY['technical', 'details', 'diagnostics']::TEXT[],
        jsonb_build_object(
            'ru', jsonb_build_object(
                'title', 'Нужны детали для проверки',
                'body', 'Чтобы помочь быстрее, уточните, пожалуйста: что вы хотели сделать, на каком экране возникла проблема, когда это произошло и повторяется ли ошибка сейчас. Если есть скриншот, приложите его.'
            ),
            'en', jsonb_build_object(
                'title', 'More details needed',
                'body', 'To help faster, please clarify: what you wanted to do, which screen had the issue, when it happened, and whether it still repeats. If you have a screenshot, please attach it.'
            ),
            'kk', jsonb_build_object(
                'title', 'Тексеру үшін қосымша дерек керек',
                'body', 'Тезірек көмектесу үшін нақтылаңыз: не істегіңіз келді, мәселе қай экранда болды, қашан болды және қазір қайталана ма. Скриншот болса, тіркеңіз.'
            )
        ),
        630,
        now(),
        now()
    )
ON CONFLICT (id) DO UPDATE SET
    category = EXCLUDED.category,
    status = EXCLUDED.status,
    tags = EXCLUDED.tags,
    translations = EXCLUDED.translations,
    sort_order = EXCLUDED.sort_order,
    updated_at = now();
