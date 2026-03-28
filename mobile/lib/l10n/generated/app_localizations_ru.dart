// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'FlyFy';

  @override
  String get welcomeTitle => 'Ваш персональный мир.';

  @override
  String get welcomeDescription =>
      'Оцените все возможности идеального суперприложения для путешествий, созданного для современного исследователя.';

  @override
  String get welcomeToFlyFy => 'Добро пожаловать в FlyFy';

  @override
  String get authByPhone => 'Войти по номеру телефона';

  @override
  String get termsAgreementText =>
      'Продолжая, вы соглашаетесь с нашими <terms>Условиями использования</terms> и <privacy>Политикой конфиденциальности</privacy>';

  @override
  String get enterPhoneToContinue => 'Введите номер телефона, чтобы продолжить';

  @override
  String get verifyAndLogin => 'Подтвердить и войти';

  @override
  String get verifyYourPhone => 'Подтвердите свой номер телефона';

  @override
  String get enterAuthCode =>
      'Введите 6-значный код, который мы только что отправили на номер\n';

  @override
  String get didntReceiveOTP => 'Не получили код?';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get or => 'ИЛИ';

  @override
  String get error => 'Ошибка';

  @override
  String get ok => 'Понятно';

  @override
  String get googleLoginFailed => 'Не удалось выполнить вход через Google.';

  @override
  String get appleLoginFailed => 'Не удалось выполнить вход через Apple ID.';

  @override
  String get otpSendFailed => 'Не удалось отправить код.';

  @override
  String get otpInvalid => 'Неверный код подтверждения.';

  @override
  String get phoneRequiredError => 'Введите номер телефона';

  @override
  String get phoneInvalidError => 'Введите корректный номер телефона';

  @override
  String get homeWelcomeBack => 'С возвращением!';

  @override
  String get homeTravelQuestion => 'Куда вы хотите отправиться дальше?';

  @override
  String get homeExploreServices => 'Сервисы';

  @override
  String get serviceTours => 'Туры';

  @override
  String get serviceGuides => 'Гиды';

  @override
  String get serviceHotels => 'Отели';

  @override
  String get serviceTransport => 'Транспорт';

  @override
  String get logoutDialogTitle => 'Выйти из аккаунта?';

  @override
  String get logoutDialogMessage =>
      'Вы уверены, что хотите выйти из аккаунта? Для следующего входа может потребоваться повторная авторизация.';

  @override
  String get logoutConfirmButton => 'Выйти';

  @override
  String get cancel => 'Отмена';

  @override
  String get loginButton => 'Войти';

  @override
  String codeSentTo(Object phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileNotAvailable => 'Профиль недоступен';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Язык';

  @override
  String get profileTimezone => 'Часовой пояс';

  @override
  String get profileCountry => 'Страна';

  @override
  String get profileCurrency => 'Валюта';

  @override
  String get profileVisibility => 'Видимость профиля';

  @override
  String get profilePublic => 'Публичный';

  @override
  String get profilePrivate => 'Приватный';

  @override
  String get editProfileButton => 'Редактировать профиль';

  @override
  String get becomeGuideButton => 'Стать гидом';

  @override
  String get logoutButton => 'Выйти';

  @override
  String welcomeUser(Object name) {
    return 'Добро пожаловать, $name';
  }

  @override
  String get openProfileHint => 'Нажмите, чтобы открыть профиль';

  @override
  String get userFallbackName => 'друг';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get loginWithBiometrics => 'Войти по биометрии';

  @override
  String get biometricLoginFailed => 'Не удалось выполнить вход по биометрии';

  @override
  String get appLockLoading => 'Проверяем защищённую сессию';

  @override
  String get appLockSetupTitle => 'Создайте PIN-код';

  @override
  String get appLockSetupDescription =>
      'PIN-код понадобится для быстрого входа в приложение, если сессия завершится после повторного открытия.';

  @override
  String get appLockSetupConfirmDescription =>
      'Повторите PIN-код, чтобы подтвердить и сохранить его.';

  @override
  String get appLockSetupCreateButton => 'Продолжить';

  @override
  String get appLockSetupConfirmButton => 'Сохранить PIN-код';

  @override
  String get appLockSetupMismatch => 'PIN-коды не совпадают';

  @override
  String get appLockPinInvalid => 'Введите 4 цифры PIN-кода';

  @override
  String get appLockPinIncorrect => 'Неверный PIN-код';

  @override
  String get appLockUnlockTitle => 'Подтвердите вход';

  @override
  String get appLockPinUnlockDescription =>
      'Введите PIN-код, чтобы продолжить работу в приложении.';

  @override
  String get appLockBiometricUnlockDescription =>
      'Подтвердите вход с помощью Face ID или биометрии. После 3 неудачных попыток будет доступен PIN-код.';

  @override
  String get appLockUsePinButton => 'Ввести PIN-код';

  @override
  String get appLockUnlockButton => 'Разблокировать';

  @override
  String get appLockRetryBiometricButton => 'Сканировать лицо';

  @override
  String get appLockBiometricEnableTitle => 'Включить вход по биометрии?';

  @override
  String get appLockBiometricEnableDescription =>
      'При следующем входе можно будет быстро подтверждать доступ с помощью Face ID или отпечатка пальца.';

  @override
  String get appLockBiometricEnableButton => 'Включить';

  @override
  String get appLockBiometricSkipButton => 'Пока не нужно';

  @override
  String get appLockBiometricFailed =>
      'Биометрия не подтверждена. Попробуйте еще раз или перейдите к PIN-коду.';

  @override
  String get appLockBiometricFallback =>
      'Доступ по биометрии временно отключен. Введите PIN-код.';

  @override
  String get profileIncompleteTitle => 'Профиль заполнен не полностью';

  @override
  String get profileIncompleteDescription =>
      'Заполните имя и фамилию, чтобы пользоваться всеми возможностями FlyFy';

  @override
  String get fillNowButton => 'Заполнить';

  @override
  String get appLanguageTitle => 'Язык приложения';

  @override
  String get saveProfileButton => 'Сохранить';

  @override
  String get profileSaveFailed => 'Не удалось сохранить профиль';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get displayNameLabel => 'Отображаемое имя';

  @override
  String get bioLabel => 'О себе';

  @override
  String get firstNameRequired => 'Укажите имя';

  @override
  String get lastNameRequired => 'Укажите фамилию';

  @override
  String get profileRequiredTitle => 'Заполните профиль';

  @override
  String get profileRequiredDescription =>
      'Чтобы продолжить, укажите имя и фамилию в профиле. Это помогает снизить количество фейковых аккаунтов и повышает доверие между пользователями.';

  @override
  String get laterButton => 'Позже';

  @override
  String get detectLocationButton => 'Определить по геолокации';

  @override
  String get useDetectedLocationTitle => 'Использовать определённую локацию?';

  @override
  String useDetectedLocationDescription(Object location) {
    return 'Мы определили вашу локацию как: $location. Использовать её для профиля?';
  }

  @override
  String get locationDetectFailed => 'Не удалось определить локацию';

  @override
  String get locationServicesDisabled =>
      'Сервисы геолокации отключены на устройстве';

  @override
  String get locationPermissionDenied => 'Доступ к геолокации не предоставлен';

  @override
  String get locationPermissionDeniedForever =>
      'Доступ к геолокации запрещён. Разрешите его в настройках устройства';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get useButton => 'Использовать';

  @override
  String get activitiesTitle => 'Активности';

  @override
  String get activitiesLoadFailed => 'Не удалось загрузить активности';

  @override
  String get noActivitiesYet => 'Пока активностей нет';

  @override
  String get activitiesWillAppearHere =>
      'Когда появятся новые активности, они будут отображаться здесь';

  @override
  String get activityDetailsComingSoon => 'Страница активности скоро появится';

  @override
  String get detailsButton => 'Подробнее';

  @override
  String get retryButton => 'Повторить';

  @override
  String get freeLabel => 'Бесплатно';

  @override
  String get fromLabel => 'от';

  @override
  String get activityStatusDraft => 'Черновик';

  @override
  String get activityStatusReviewRequired => 'На проверке';

  @override
  String get activityStatusPublished => 'Опубликовано';

  @override
  String get activityStatusEnrollmentOpen => 'Открыта запись';

  @override
  String get activityStatusFull => 'Мест нет';

  @override
  String get activityStatusStarted => 'Началось';

  @override
  String get activityStatusCompleted => 'Завершено';

  @override
  String get activityStatusCancelled => 'Отменено';

  @override
  String get activityFormatOffline => 'Офлайн';

  @override
  String get activityFormatOnline => 'Онлайн';

  @override
  String get activityFormatHybrid => 'Гибрид';

  @override
  String get activityFormatLabel => 'Формат';

  @override
  String get activityDetailsTitle => 'Активность';

  @override
  String get activityDetailsLoadFailed => 'Не удалось загрузить активность';

  @override
  String get activityNotFound => 'Активность не найдена';

  @override
  String get activityAboutSection => 'Описание';

  @override
  String get activityInfoSection => 'Информация';

  @override
  String get activityTagsSection => 'Теги';

  @override
  String get activityAccessSection => 'Доступ и безопасность';

  @override
  String get activitySensitiveDetailsProtected =>
      'Точное место проведения, ссылка на онлайн-встречу и чувствительные детали доступны только после участия или подтверждения.';

  @override
  String get activitySensitiveDetailsHint =>
      'Это сделано для безопасности участников и организатора.';

  @override
  String get activityDateAndTime => 'Дата и время';

  @override
  String get activityCategory => 'Категория';

  @override
  String get activityLanguage => 'Язык';

  @override
  String get activityCapacity => 'Количество мест';

  @override
  String get activityPrice => 'Стоимость';

  @override
  String get activityLocation => 'Локация';

  @override
  String get activityUnlimitedCapacity => 'Количество участников не ограничено';

  @override
  String get activityLimitedCapacity => 'Количество мест ограничено';

  @override
  String get activityJoinButton => 'Записаться';

  @override
  String get activityLeaveButton => 'Покинуть';

  @override
  String get activityLeaveInlineButton => 'Покинуть активность';

  @override
  String get activityCancelButton => 'Отменить активность';

  @override
  String get activityCancelConfirmTitle => 'Отменить эту активность?';

  @override
  String get activityCancelConfirmDescription =>
      'Участники увидят, что активность отменена. Укажите причину, чтобы им было понятно, что произошло.';

  @override
  String get activityCancelReasonLabel => 'Причина отмены';

  @override
  String get activityCancelReasonPlaceholder =>
      'Например: организатор заболел или изменилась локация';

  @override
  String get activityCancelReasonRequired =>
      'Укажите причину отмены активности';

  @override
  String get activityCancelKeepButton => 'Назад';

  @override
  String get activityCancelConfirmButton => 'Подтвердить отмену';

  @override
  String get activityJoinSuccess => 'Вы записались на активность';

  @override
  String get activityLeaveSuccess => 'Вы покинули активность';

  @override
  String get activityCancelSuccess => 'Активность отменена';

  @override
  String get activityJoinFailed => 'Не удалось записаться на активность';

  @override
  String get activityJoinAlreadyJoined => 'Вы уже записаны на эту активность';

  @override
  String get activityJoinScheduleConflict =>
      'Нельзя записаться: вы уже записаны на другую активность с пересекающимся временем';

  @override
  String get activityLeaveFailed => 'Не удалось покинуть активность';

  @override
  String get activityCancelFailed => 'Не удалось отменить активность';

  @override
  String get activityCancelAlreadyCancelled => 'Активность уже отменена';

  @override
  String get activityCancelNotAllowed =>
      'Эту активность больше нельзя отменить';

  @override
  String activityGoingTitle(int count) {
    return 'Участвуют ($count)';
  }

  @override
  String get activityDetailsViewAll => 'Показать всех';

  @override
  String get activityDetailsLinkCopied => 'Ссылка скопирована';

  @override
  String get activityDetailsHostedBadge => 'Ваша активность';

  @override
  String get activityDetailsJoinedBadge => 'Вы участвуете';

  @override
  String get activityDetailsTotalLabel => 'Итого';

  @override
  String get activityDetailsChatButton => 'Чат активности';

  @override
  String get activityDetailsHostFallbackName => 'Организатор FlyFy';

  @override
  String get activityPaymentScreenTitle => 'FLYFY CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Сводка активности';

  @override
  String get activityPaymentBreakdownTitle => 'Состав суммы';

  @override
  String get activityPaymentMethodTitle => 'Способ оплаты';

  @override
  String activityPaymentHostedBy(Object host) {
    return 'Организатор: $host';
  }

  @override
  String get activityPaymentAdmissionLabel => '1x участие в активности';

  @override
  String get activityPaymentServiceFeeLabel => 'Сервисный сбор';

  @override
  String get activityPaymentSavedCardLabel => 'Сохраненная карта';

  @override
  String get activityPaymentCardHolderFallback => 'Участник FlyFy';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return 'Подтвердить и оплатить $amount';
  }

  @override
  String get activityPaymentSecureNote =>
      'Безопасная оплата с 256-битным SSL-шифрованием';

  @override
  String get activityPaymentPayButton => 'Оплатить';

  @override
  String get activityPaymentSuccess => 'Оплата отмечена как успешная';

  @override
  String get activityPaymentStatusLabel => 'Оплата';

  @override
  String get activityPaymentPaidValue => 'ОПЛАЧЕНО';

  @override
  String get activityParticipantFallbackName => 'Участник';

  @override
  String get activityParticipantsEmpty => 'Пока никто не записался';

  @override
  String get activityParticipantsLoadFailed =>
      'Не удалось загрузить участников';

  @override
  String get activityPrivateJoinTitle => 'Приватная активность';

  @override
  String get activityPrivateJoinDescription =>
      'Эта активность доступна только по приглашению. Введите пароль, чтобы присоединиться.';

  @override
  String get activityPrivateJoinPasswordLabel => 'Пароль доступа';

  @override
  String get activityPrivateJoinPasswordPlaceholder => 'Введите пароль доступа';

  @override
  String get activityPrivateJoinPasswordValidation =>
      'Введите пароль от 4 до 64 символов';

  @override
  String get activityPrivateJoinInvalidPassword =>
      'Неверный пароль. Попробуйте снова.';

  @override
  String get activityPrivateJoinSubmit => 'Проверить и присоединиться';

  @override
  String get homeTitle => 'FlyFy';

  @override
  String get homeSubtitle =>
      'Путешествуйте, находите активности и открывайте новые впечатления';

  @override
  String get servicesSectionTitle => 'Сервисы';

  @override
  String get homeToursTitle => 'Туры';

  @override
  String get homeToursSubtitle => 'Подберите интересные маршруты и поездки';

  @override
  String get homeGuidesTitle => 'Гиды';

  @override
  String get homeGuidesSubtitle => 'Найдите местных проводников и экспертов';

  @override
  String get homeHotelsTitle => 'Отели';

  @override
  String get homeHotelsSubtitle => 'Бронируйте проживание удобно и быстро';

  @override
  String get homeTransportTitle => 'Транспорт';

  @override
  String get homeTransportSubtitle => 'Планируйте перемещения заранее';

  @override
  String get homeCurrentLocationLabel => 'Текущая локация';

  @override
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint => 'Искать направления, жилье или авто';

  @override
  String get homeTopDestinations => 'Топ направления';

  @override
  String get homeSeeAll => 'Смотреть все';

  @override
  String get homeRecommendedBlogs => 'Рекомендованные блоги';

  @override
  String get homeEditorialBadge => 'Редакция';

  @override
  String get homeStoryTitle => 'Скрытые жемчужины Центральной Азии';

  @override
  String get homeStoryDescription =>
      'Откройте секретные тропы и культурные уголки вокруг Алматы.';

  @override
  String get homeReadStory => 'Читать';

  @override
  String get homeFeaturedStays => 'Рекомендуемое жилье';

  @override
  String get homeCarRentals => 'Аренда авто';

  @override
  String get homeRecommendedActivities => 'Рекомендованные активности';

  @override
  String get homeFilterButton => 'Фильтр';

  @override
  String get homeMoreButton => 'Ещё';

  @override
  String get homeDestinationCharynTitle => 'Чарынский каньон';

  @override
  String get homeDestinationCharynSubtitle => 'Природа и приключения';

  @override
  String get homeDestinationLakeTitle => 'Большое Алматинское озеро';

  @override
  String get homeDestinationLakeSubtitle => 'Живописные виды';

  @override
  String get homeDestinationKolsaiTitle => 'Кольсайские озёра';

  @override
  String get homeDestinationKolsaiSubtitle => 'Горный отдых';

  @override
  String homeDurationHours(Object hours) {
    return '$hours ч';
  }

  @override
  String get homeBookNow => 'Забронировать';

  @override
  String get homeNavHome => 'Главная';

  @override
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Карта';

  @override
  String get homeNavChats => 'Чаты';

  @override
  String get homeNavMy => 'Мои';

  @override
  String get activitiesEntryTitle => 'Активности';

  @override
  String get activitiesEntrySubtitle =>
      'Найдите офлайн и онлайн события, к которым можно присоединиться';

  @override
  String get comingSoon => 'Скоро появится';

  @override
  String get createActivityFab => 'Создать';

  @override
  String get createActivityTitle => 'Создать активность';

  @override
  String get createActivitySubmit => 'Создать активность';

  @override
  String get createActivitySuccess => 'Активность успешно создана';

  @override
  String get createActivityFailed => 'Не удалось создать активность';

  @override
  String get createStepBasic => 'Основная информация';

  @override
  String get createStepDetailsLogistics => 'Детали и логистика';

  @override
  String get createStepRulesPricing => 'Правила и стоимость';

  @override
  String get createStepSchedule => 'Формат и расписание';

  @override
  String get createStepParticipation => 'Участие';

  @override
  String get createStepLocation => 'Локация';

  @override
  String createStepCounter(Object current, Object total) {
    return 'Шаг $current из $total';
  }

  @override
  String get createHelpAction => 'Помощь';

  @override
  String get createStepNext => 'Следующий шаг';

  @override
  String get createStepBack => 'Назад';

  @override
  String get createCoverSection => 'Загрузить обложку активности';

  @override
  String get createCoverUploadTitle => 'Загрузить качественное изображение';

  @override
  String get createCoverChangeAction => 'Изменить обложку';

  @override
  String get createCoverUploadHint =>
      'JPG, PNG или WEBP. Рекомендуется 1600x900px, максимум 20MB';

  @override
  String get createCoverUploadFailed =>
      'Не удалось загрузить обложку. Попробуйте еще раз.';

  @override
  String get createCoverUploadTooLarge =>
      'Изображение слишком большое. Максимальный размер — 20MB.';

  @override
  String get createCoverUploadUnsupportedFormat =>
      'Неподдерживаемый формат изображения. Используйте JPG, PNG или WEBP.';

  @override
  String get createCoverUploadInProgress =>
      'Дождитесь завершения загрузки обложки.';

  @override
  String get createCoverUploadRetryRequired =>
      'Повторно загрузите обложку перед продолжением.';

  @override
  String get createBasicSection => 'ОСНОВНАЯ ИНФОРМАЦИЯ';

  @override
  String get createTitleLabel => 'Название активности';

  @override
  String get createTitleHint => 'Например, йога на закате у пирса';

  @override
  String get createTitleValidation =>
      'Название должно быть не менее 3 символов';

  @override
  String get createDescriptionLabel => 'Описание';

  @override
  String get createDescriptionHint => 'Расскажите подробнее об активности...';

  @override
  String get createDescriptionValidation =>
      'Описание должно быть не менее 10 символов';

  @override
  String get createCategoryLabel => 'Категория';

  @override
  String get createCategoryHint => 'Выберите категорию';

  @override
  String get createCategoryValidation => 'Выберите категорию';

  @override
  String get createCategoryLoading => 'Загружаем категории';

  @override
  String get createCategoryLoadFailed => 'Не удалось загрузить категории';

  @override
  String get createCategoryEmpty => 'Категории пока недоступны';

  @override
  String get createCategoryRetry => 'Повторить';

  @override
  String get createCategoryPickerTitle => 'Выберите категорию';

  @override
  String get createCategoryApply => 'Применить';

  @override
  String get createTagsLabel => 'Теги';

  @override
  String get createTagsHint => 'Через запятую: бег, утро, парк';

  @override
  String get createEventFormatLabel => 'Формат события';

  @override
  String get createFormatSection => 'ФОРМАТ ПРОВЕДЕНИЯ';

  @override
  String get createScheduleSection => 'РАСПИСАНИЕ';

  @override
  String get createDatePartLabel => 'Дата';

  @override
  String get createTimePartLabel => 'Время';

  @override
  String get createStartAtLabel => 'Начало';

  @override
  String get createEndAtLabel => 'Окончание';

  @override
  String get createStartDateLabel => 'Дата начала';

  @override
  String get createEndDateLabel => 'Дата окончания';

  @override
  String get createStartTimeLabel => 'Время начала';

  @override
  String get createEndTimeLabel => 'Время окончания';

  @override
  String get createScheduleInputValidation => 'Введите корректные дату и время';

  @override
  String get createRegistrationDeadlineLabel => 'Крайний срок регистрации';

  @override
  String get createEndDateValidation =>
      'Дата окончания должна быть после начала';

  @override
  String get createStartAtTooSoonValidation =>
      'Начало должно быть не менее чем через 1 час';

  @override
  String get createRegistrationDeadlineValidation =>
      'Крайний срок регистрации должен быть до начала';

  @override
  String get createRegistrationAutoHint =>
      'Регистрация закрывается автоматически за 1 час до начала активности';

  @override
  String get createSaveDraft => 'Сохранить черновик';

  @override
  String get createAndPublish => 'Опубликовать';

  @override
  String get createPublishActivityCta => 'Опубликовать активность';

  @override
  String get createLanguageSection => 'ЯЗЫК АКТИВНОСТИ';

  @override
  String get createVisibilitySection => 'ВИДИМОСТЬ';

  @override
  String get createVisibilityPublic => 'Публичная';

  @override
  String get createVisibilityPrivate => 'Приватная';

  @override
  String get createVisibilityUnlisted => 'По ссылке';

  @override
  String get createActivityPrivacyTitle => 'Приватность активности';

  @override
  String get createVisibilityPrivateWithPassword => 'Приватная с паролем';

  @override
  String get createVisibilityByLink => 'По ссылке';

  @override
  String get createVisibilityPublicDescription =>
      'Видно всем пользователям FlyFy';

  @override
  String get createVisibilityPrivateDescription =>
      'Видно только тем, у кого есть код';

  @override
  String get createVisibilityUnlistedDescription =>
      'Доступно только по пригласительной ссылке';

  @override
  String get createVisibilityPickerTitle => 'Выберите приватность';

  @override
  String get createVisibilityApply => 'Применить';

  @override
  String get createVisibilityPasswordLabel => 'Пароль активности';

  @override
  String get createVisibilityPasswordPlaceholder => 'Введите пароль';

  @override
  String get createVisibilityPasswordValidation =>
      'Введите пароль длиной от 4 до 64 символов';

  @override
  String get createVisibilityPasswordEditHint =>
      'Оставьте поле пустым, чтобы сохранить текущий пароль';

  @override
  String get createJoinModeSection => 'РЕЖИМ ЗАПИСИ';

  @override
  String get createJoinModeAuto => 'Автоматическое одобрение';

  @override
  String get createJoinModeManual => 'Ручное одобрение';

  @override
  String get createJoinApprovalTitle => 'Подтверждение участия';

  @override
  String get createJoinModeAutomaticShort => 'Автоматически';

  @override
  String get createJoinModeManualShort => 'Вручную';

  @override
  String get createJoinModePickerTitle => 'Выберите режим подтверждения';

  @override
  String get createJoinModeApply => 'Применить';

  @override
  String get createCapacitySection => 'КОЛИЧЕСТВО МЕСТ';

  @override
  String get createCapacityUnlimited => 'Без ограничений';

  @override
  String get createCapacityLimited => 'Ограничено';

  @override
  String get createMinParticipantsLabel => 'Минимум';

  @override
  String get createMaxParticipantsLabel => 'Максимум';

  @override
  String get createParticipantLimitsTitle => 'Лимиты участников';

  @override
  String get createUnlimitedParticipantsLabel => 'Безлимитное число участников';

  @override
  String get createParticipantsMinShort => 'МИН';

  @override
  String get createParticipantsMaxShort => 'МАКС';

  @override
  String get createNoLimitPlaceholder => 'Без лимита';

  @override
  String get createMaxParticipantsValidation =>
      'Укажите корректное максимальное число';

  @override
  String get createMinExceedsMaxValidation =>
      'Минимум не может превышать максимум';

  @override
  String get createPriceSection => 'СТОИМОСТЬ';

  @override
  String get createPriceFree => 'Бесплатно';

  @override
  String get createPricePaid => 'Платно';

  @override
  String get createPriceDeposit => 'Депозит';

  @override
  String get createPricingModelTitle => 'Модель оплаты';

  @override
  String get createPriceAmountLabel => 'Сумма';

  @override
  String get createPriceAmountOptionalLabel => 'Стоимость (необязательно)';

  @override
  String get createPriceAmountPlaceholder => '\$ 0.00';

  @override
  String get createCurrencyLabel => 'Валюта';

  @override
  String get createPricePerPersonHint => 'за человека';

  @override
  String get createPriceValidation => 'Укажите корректную сумму';

  @override
  String get createOnlineSection => 'ОНЛАЙН-ДОСТУП';

  @override
  String get createOnlineAccessHint =>
      'Укажите ссылку, по которой участники смогут подключиться онлайн';

  @override
  String get createMeetingUrlLabel => 'Ссылка на встречу';

  @override
  String get createMeetingUrlHint => 'https://zoom.us/...';

  @override
  String get createMeetingUrlValidation => 'Укажите ссылку на онлайн-встречу';

  @override
  String get createMeetingPointLocationLabel => 'Точка встречи / локация';

  @override
  String get createMeetingPointTitle => 'ТОЧКА ВСТРЕЧИ';

  @override
  String get createVenueOrAddressHint => 'Введите место или адрес';

  @override
  String get createMapLinkLabel => 'Ссылка на карту';

  @override
  String get createMapLinkHint => 'Вставьте ссылку на карту';

  @override
  String get createOfflineSection => 'МЕСТО ПРОВЕДЕНИЯ';

  @override
  String get createLocationPreviewHint =>
      'Добавьте город или адрес, чтобы участники понимали, где встречаться';

  @override
  String get createCountryLabel => 'Страна';

  @override
  String get createCityLabel => 'Город';

  @override
  String get createCityHint => 'Например: Алматы';

  @override
  String get createAddressLabel => 'Адрес';

  @override
  String get createAddressHint => 'Улица, дом, корпус';

  @override
  String get createMapTapHint =>
      'Нажмите на карту, чтобы отметить точку встречи';

  @override
  String get createMapResolvingHint => 'Определяем адрес...';

  @override
  String get createMapUnavailable =>
      'Google Maps доступен в настроенных iOS и Android сборках';

  @override
  String get createLocationValidation => 'Укажите город или адрес проведения';

  @override
  String get editActivityTitle => 'Редактирование';

  @override
  String get editActivityButton => 'Редактировать';

  @override
  String get editActivitySubmit => 'Сохранить';

  @override
  String get editActivitySuccess => 'Активность обновлена';

  @override
  String get editActivityFailed => 'Не удалось обновить активность';

  @override
  String get activityPublishButton => 'Опубликовать';

  @override
  String get activityPublishSuccess => 'Активность опубликована';

  @override
  String get activityPublishFailed => 'Не удалось опубликовать активность';

  @override
  String get editFormatLocked => 'Формат нельзя изменить после создания';

  @override
  String get editLocationLocked =>
      'Место проведения нельзя изменить после публикации';

  @override
  String get editPriceRestrictionHint =>
      'Цену нельзя изменить, если участники уже записались';

  @override
  String get myActivitiesTitle => 'Мои активности';

  @override
  String get myActivitiesEmpty => 'У вас пока нет созданных активностей';

  @override
  String get myActivitiesEmptyHint =>
      'Создайте первую активность, и она появится здесь';

  @override
  String get myActivitiesLoadFailed => 'Не удалось загрузить ваши активности';

  @override
  String get myActivitiesFilterAll => 'Все';

  @override
  String myActivitiesLastUpdated(Object date) {
    return 'Обновлено $date';
  }

  @override
  String get myActivitiesContinueButton => 'Продолжить';

  @override
  String get myActivitiesAttendedTab => 'Посещенные';

  @override
  String get myActivitiesAttendedEmpty => 'Вы пока не посещали активности';

  @override
  String get myActivitiesAttendedEmptyHint =>
      'Активности, в которые вы записались, появятся здесь';

  @override
  String get myActivitiesAttendedLoadFailed =>
      'Не удалось загрузить посещенные активности';

  @override
  String get myActivitiesFilterButton => 'Фильтры';

  @override
  String get myActivitiesFilterTitle => 'Фильтры';

  @override
  String get myActivitiesFilterDateRange => 'Диапазон дат';

  @override
  String get myActivitiesFilterStartDate => 'Дата начала';

  @override
  String get myActivitiesFilterEndDate => 'Дата окончания';

  @override
  String get myActivitiesFilterDatePlaceholder => 'dd.mm.yyyy';

  @override
  String get myActivitiesFilterDateHint =>
      'Введите дату вручную в формате dd.mm.yyyy';

  @override
  String get myActivitiesFilterInvalidDate => 'Введите корректную дату';

  @override
  String get myActivitiesFilterInvalidRange =>
      'Дата окончания не может быть раньше даты начала';

  @override
  String get myActivitiesFilterStatus => 'Фильтр по статусу';

  @override
  String get myActivitiesFilterClear => 'Очистить';

  @override
  String get myActivitiesFilterApply => 'Применить фильтры';

  @override
  String get myActivitiesRecreateButton => 'Повторить';

  @override
  String get myActivitiesRestrictedButton => 'Редактирование ограничено';

  @override
  String get myActivitiesOpenButton => 'Открыть активность';

  @override
  String get myActivitiesRetryButton => 'Повторить';

  @override
  String get myActivitiesPriceNoteFree => 'без оплаты';

  @override
  String get activityPerPerson => '/ чел.';

  @override
  String activitySpotsLeft(Object count) {
    return 'Осталось мест: $count';
  }

  @override
  String get activityUnlimitedSpots => 'Без ограничений';

  @override
  String get activityMeetingPoint => 'Место встречи';

  @override
  String get activityGetDirections => 'Как добраться';

  @override
  String get activityHostSection => 'Организатор';

  @override
  String get activityTotalCapacity => 'Всего мест';

  @override
  String get activityPricing => 'Стоимость';

  @override
  String activityPeopleMax(Object count) {
    return 'Макс. $count чел.';
  }

  @override
  String get activityJoinActivity => 'Записаться';

  @override
  String get activitiesSearchHint =>
      'Поиск активностей, организаторов, городов';

  @override
  String get activitiesFilterCategory => 'Категория';

  @override
  String get activitiesFilterDate => 'Дата';

  @override
  String get activitiesFilterPricing => 'Стоимость';

  @override
  String get activitiesFilterVisibility => 'Видимость';

  @override
  String get activitiesDiscoverTitle => 'Поиск активностей';

  @override
  String get activitiesFilteredEmptyTitle =>
      'По этим фильтрам ничего не найдено';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Попробуйте расширить категорию, диапазон дат или стоимость';

  @override
  String activitiesResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активности',
      many: '$count активностей',
      few: '$count активности',
      one: '$count активность',
      zero: 'Нет активностей',
    );
    return '$_temp0';
  }

  @override
  String get activitiesFiltersCategoriesTitle => 'Категории';

  @override
  String get activitiesFiltersSelectedCategories => 'Выбранные категории';

  @override
  String activitiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активности',
      many: '$count активностей',
      few: '$count активности',
      one: '$count активность',
      zero: '0 активностей',
    );
    return 'Показать $_temp0';
  }

  @override
  String get activitiesAllCategories => 'Все категории';

  @override
  String get activitiesFiltersPriceRangeTitle => 'Диапазон стоимости';

  @override
  String get activitiesFiltersVisibilityTitle => 'Видимость';

  @override
  String get activitiesFilterMinPrice => 'Цена от';

  @override
  String get activitiesFilterMaxPrice => 'Цена до';

  @override
  String get activitiesDatePresetToday => 'Сегодня';

  @override
  String get activitiesDatePresetTomorrow => 'Завтра';

  @override
  String get activitiesDatePresetThisWeekend => 'В эти выходные';

  @override
  String get activitiesDatePresetThisWeek => 'На этой неделе';

  @override
  String get activitiesDatePresetThisMonth => 'В этом месяце';

  @override
  String get activityViewDetails => 'Подробнее';

  @override
  String get activityJoinSession => 'Присоединиться';

  @override
  String get activityGetLink => 'Получить ссылку';

  @override
  String get activityAttendanceQrButton => 'QR для отметки';

  @override
  String get activityAttendanceQrTitle => 'QR активности';

  @override
  String get activityAttendanceQrFallbackTitle => 'Активность';

  @override
  String get activityAttendanceQrSubtitle =>
      'Покажите этот QR участнику, чтобы он подтвердил свое прибытие через приложение.';

  @override
  String get activityAttendanceQrHelper =>
      'QR автоматически обновляется. Участник должен сканировать актуальный код через кнопку QR в нижней панели.';

  @override
  String get activityAttendanceQrLoadFailed =>
      'Не удалось загрузить QR активности';

  @override
  String get activityAttendanceQrRefreshHint =>
      'Код обновляется автоматически для защиты от дублей и скриншотов.';

  @override
  String get activityAttendanceQrRefreshing => 'Обновляем QR…';

  @override
  String activityAttendanceQrExpiresIn(Object seconds) {
    return 'Обновление через $seconds сек.';
  }

  @override
  String get qrScannerTitle => 'Сканирование QR';

  @override
  String get qrScannerSubtitle =>
      'Наведите камеру на QR организатора, чтобы подтвердить свое прибытие на активность.';

  @override
  String get qrScannerReady => 'Наведите камеру на QR код';

  @override
  String get qrScannerInvalidCode => 'Это не QR активности FlyFy';

  @override
  String get qrScannerSessionUnavailable =>
      'Не удалось определить текущую сессию. Попробуйте открыть экран снова.';

  @override
  String get qrScannerAlreadyQueued => 'Эта отметка уже ожидает синхронизации';

  @override
  String get qrScannerQueuedOffline =>
      'Отметка сохранена и синхронизируется, когда появится соединение';

  @override
  String get qrScannerSuccess => 'Прибытие подтверждено';

  @override
  String get qrScannerAlreadyCheckedIn => 'Вы уже отмечены на этой активности';

  @override
  String get qrScannerNotRegistered => 'Вы не записаны на эту активность';

  @override
  String get qrScannerNotEligible => 'Для этой записи отметка пока недоступна';

  @override
  String get qrScannerQrExpired =>
      'QR уже устарел. Попросите организатора открыть новый код.';

  @override
  String get qrScannerHostNotAllowed =>
      'Организатор не может сканировать свой собственный QR';

  @override
  String get qrScannerActivityUnavailable =>
      'Для этой активности отметка сейчас недоступна';

  @override
  String get qrScannerCameraUnavailable =>
      'Камера недоступна. Проверьте разрешение на доступ к камере.';

  @override
  String get qrScannerSyncNow => 'Синхронизировать';

  @override
  String get qrScannerScanAgain => 'Сканировать снова';

  @override
  String qrScannerPendingCount(Object count) {
    return 'Ожидают синхронизации: $count';
  }

  @override
  String get qrScannerNoPending => 'Нет ожидающих отметок';
}
