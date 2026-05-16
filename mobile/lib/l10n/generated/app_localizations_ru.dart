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
  String get serviceExcursions => 'Экскурсии';

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
  String get commonPaginationPrevious => 'Предыдущая страница';

  @override
  String get commonPaginationNext => 'Следующая страница';

  @override
  String commonPaginationLabel(Object current, Object total) {
    return 'Страница $current из $total';
  }

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
  String get guideVerificationTitle => 'Заявка на статус гида';

  @override
  String guideVerificationStepCounter(Object current, Object total) {
    return 'Шаг $current из $total';
  }

  @override
  String get guideVerificationStepIdentity => 'Личность';

  @override
  String get guideVerificationStepDocument => 'Документ';

  @override
  String get guideVerificationStepLicense => 'Квалификация';

  @override
  String get guideVerificationStepSubmit => 'Отправка';

  @override
  String get guideVerificationHeroTitle => 'Подтвердите статус гида';

  @override
  String get guideVerificationHeroSubtitle =>
      'Заполните анкету и загрузите документы, чтобы мы могли проверить ваш профиль и открыть профессиональные возможности.';

  @override
  String get guideVerificationIdentitySection => 'Основная информация';

  @override
  String get guideVerificationFullNameLabel => 'Полное имя';

  @override
  String get guideVerificationFullNameHint => 'Как в удостоверении личности';

  @override
  String get guideVerificationBirthDateLabel => 'Дата рождения';

  @override
  String get guideVerificationBirthDateHint => 'ДД.ММ.ГГГГ';

  @override
  String get guideVerificationNationalityLabel => 'Гражданство';

  @override
  String get guideVerificationSelectCountry => 'Выберите страну';

  @override
  String get guideVerificationIdentityNotice =>
      'Мы используем эти данные только для проверки личности и статуса гида.';

  @override
  String get guideVerificationContinueToDocuments => 'Перейти к документам';

  @override
  String get guideVerificationDocumentTypeLabel => 'Тип документа';

  @override
  String get guideVerificationPassport => 'Паспорт';

  @override
  String get guideVerificationNationalId => 'Удостоверение личности';

  @override
  String get guideVerificationUploadPhotoTitle => 'Загрузите фото документа';

  @override
  String get guideVerificationUploadPhotoSubtitle =>
      'Нужна четкая фотография или скан лицевой стороны документа.';

  @override
  String get guideVerificationNoGlare => 'Без бликов';

  @override
  String get guideVerificationNoGlareHint =>
      'Сделайте фото при ровном освещении, чтобы текст был читаемым.';

  @override
  String get guideVerificationFullFrame => 'Полностью в кадре';

  @override
  String get guideVerificationFullFrameHint =>
      'Все края документа должны быть видны на изображении.';

  @override
  String get guideVerificationTapToCapturePassport =>
      'Нажмите, чтобы выбрать файл документа';

  @override
  String get guideVerificationFileFormatsShort =>
      'Поддерживаются JPG, PNG, PDF до 10 МБ';

  @override
  String get guideVerificationChooseFile => 'Выбрать файл';

  @override
  String get guideVerificationDocumentConfirm =>
      'Я подтверждаю, что этот документ действителен, не просрочен, а предоставленное фото четкое и хорошо читается автоматическими системами проверки.';

  @override
  String get guideVerificationVerifyContinue => 'Продолжить проверку';

  @override
  String get guideVerificationCredentialsTitle => 'Квалификация и лицензии';

  @override
  String get guideVerificationCredentialsSubtitle =>
      'Расскажите, какой документ подтверждает ваш опыт и право работать гидом.';

  @override
  String get guideVerificationLicenseLabel => 'Тип подтверждающего документа';

  @override
  String get guideVerificationSelectLicenseType => 'Выберите тип документа';

  @override
  String get guideVerificationOfficialExcursionGuideLicense =>
      'Лицензия официального гида';

  @override
  String get guideVerificationCityGuidePermit => 'Разрешение городского гида';

  @override
  String get guideVerificationMuseumAccreditation =>
      'Аккредитация музея или площадки';

  @override
  String get guideVerificationUploadLicenseTitle =>
      'Загрузите подтверждающий документ';

  @override
  String get guideVerificationUploadLicenseSubtitle =>
      'Подойдет сертификат, лицензия или другой профессиональный документ.';

  @override
  String get guideVerificationAdditionalCertifications =>
      'Дополнительные навыки';

  @override
  String get guideVerificationUploadFirstAidTitle =>
      'Загрузите сертификат первой помощи';

  @override
  String get guideVerificationUploadFirstAidSubtitle =>
      'Необязательно: добавьте сертификат, если хотите усилить заявку.';

  @override
  String get guideVerificationUploadLanguageTitle =>
      'Загрузите языковой сертификат';

  @override
  String get guideVerificationUploadLanguageSubtitle =>
      'Необязательно: добавьте сертификат, подтверждающий знание языков.';

  @override
  String get guideVerificationFirstAid => 'Первая помощь';

  @override
  String get guideVerificationFirstAidHint =>
      'Есть действующее обучение или сертификат по первой помощи.';

  @override
  String get guideVerificationLanguageProficiency => 'Иностранные языки';

  @override
  String get guideVerificationLanguageProficiencyHint =>
      'Можете проводить активности и экскурсии более чем на одном языке.';

  @override
  String get guideVerificationTimelineTitle => 'Срок проверки';

  @override
  String get guideVerificationTimelineText =>
      'Обычно мы рассматриваем заявку в течение 1–3 рабочих дней. Если потребуется дополнительная информация, мы сообщим в профиле.';

  @override
  String get guideVerificationReviewHeroTitle =>
      'Проверьте данные перед отправкой';

  @override
  String get guideVerificationReviewHeroSubtitle =>
      'Убедитесь, что все поля заполнены верно. После отправки заявка уйдет на проверку.';

  @override
  String get guideVerificationReviewTitle => 'Сводка заявки';

  @override
  String get guideVerificationEditInfo => 'Редактировать';

  @override
  String get guideVerificationIdentityDocumentCard => 'Документ личности';

  @override
  String get guideVerificationProfessionalLicenseCard =>
      'Профессиональный документ';

  @override
  String get guideVerificationFirstAidCertificateCard =>
      'Сертификат первой помощи';

  @override
  String get guideVerificationLanguageCertificateCard => 'Языковой сертификат';

  @override
  String get guideVerificationVerifiedUpload => 'Файл загружен';

  @override
  String get guideVerificationTermsTitle => 'Подтверждение';

  @override
  String get guideVerificationTermsHeading =>
      'Я подтверждаю достоверность данных';

  @override
  String get guideVerificationTermsBody =>
      'Я понимаю, что FlyFy может отклонить заявку при обнаружении недостоверной информации или неподходящих документов.';

  @override
  String get guideVerificationAgreement =>
      'Соглашаюсь на проверку документов и обработку данных для подтверждения статуса гида.';

  @override
  String get guideVerificationSubmit => 'Отправить заявку';

  @override
  String get guideVerificationReviewNote =>
      'После отправки вы сможете отслеживать статус заявки в профиле.';

  @override
  String get guideVerificationPendingTitle => 'Заявка уже на проверке';

  @override
  String get guideVerificationPendingSubtitle =>
      'Мы получили ваши документы и сейчас проверяем их. Как только статус изменится, вы увидите обновление в профиле.';

  @override
  String get guideVerificationActiveTitle => 'Статус гида уже подтвержден';

  @override
  String get guideVerificationActiveSubtitle =>
      'Ваш профиль уже активен как профиль гида. Ничего дополнительно отправлять не нужно.';

  @override
  String get guideVerificationRejectedTitle => 'Заявка требует доработки';

  @override
  String get guideVerificationRejectedSubtitle =>
      'Предыдущая заявка была отклонена. Вы можете обновить данные и отправить документы повторно.';

  @override
  String get guideVerificationDraftSubtitle =>
      'У вас уже есть черновик заявки. Можно продолжить с текущими данными и отправить ее на проверку.';

  @override
  String get guideVerificationViewApplicationButton => 'Посмотреть заявку';

  @override
  String get guideVerificationContinueButton => 'Продолжить';

  @override
  String get guideVerificationBackToProfile => 'Вернуться в профиль';

  @override
  String get guideVerificationFullNameRequired => 'Укажите полное имя';

  @override
  String get guideVerificationFullNameInvalid =>
      'Введите имя и фамилию полностью';

  @override
  String get guideVerificationBirthDateRequired => 'Укажите дату рождения';

  @override
  String get guideVerificationBirthDateInvalid =>
      'Введите корректную дату в формате ДД.ММ.ГГГГ';

  @override
  String get guideVerificationNationalityRequired => 'Выберите гражданство';

  @override
  String get guideVerificationIdentityFileRequired =>
      'Загрузите документ личности';

  @override
  String get guideVerificationProfessionalFileRequired =>
      'Загрузите подтверждающий документ';

  @override
  String get guideVerificationConfirmationRequired =>
      'Подтвердите, что документ действителен и фото читаемо';

  @override
  String get guideVerificationAgreementRequired =>
      'Нужно согласие на проверку документов';

  @override
  String get guideVerificationUploadFailed => 'Не удалось загрузить файл';

  @override
  String get guideVerificationUnsupportedFormat =>
      'Поддерживаются только JPG, PNG, WEBP и PDF';

  @override
  String get guideVerificationSubmitFailed => 'Не удалось отправить заявку';

  @override
  String get guideVerificationDocumentsRequired =>
      'Для отправки заявки нужны документ личности и профессиональный документ';

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
      'Подтвердите вход с помощью Face ID, отпечатка пальца или другой доступной биометрии. После 3 неудачных попыток будет доступен PIN-код.';

  @override
  String get appLockUsePinButton => 'Ввести PIN-код';

  @override
  String get appLockUnlockButton => 'Разблокировать';

  @override
  String get appLockRetryBiometricButton => 'Войти по биометрии';

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
  String get profileDisplayNameTaken => 'Это отображаемое имя уже занято';

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
  String get myProfileTitle => 'Мой профиль';

  @override
  String get profileLinkCopied => 'Ссылка на профиль скопирована';

  @override
  String get profileVerifiedExplorer => 'ПОДТВЕРЖДЕННЫЙ ГИД';

  @override
  String get profileGuideTitle => 'Гид FlyFy';

  @override
  String get profileEmptyBioPlaceholder =>
      'Пока здесь нет описания. Когда профиль будет заполнен, здесь появится краткая информация о пользователе.';

  @override
  String get profileBecomeGuideTitle => 'Станьте гидом';

  @override
  String get profileBecomeGuideSubtitle =>
      'Скоро здесь можно будет подать заявку и открыть доступ к профессиональному профилю гида.';

  @override
  String get profileActivitiesStat => 'Активности';

  @override
  String get profileHostedCompletedStat => 'Завершено как автор';

  @override
  String get profileJoinedCompletedStat => 'Завершено как участник';

  @override
  String get profileReviewsStat => 'Отзывы';

  @override
  String get profileBlogsStat => 'Блоги';

  @override
  String get profileFollowersStat => 'Фолловеры';

  @override
  String get profileFollowersTitle => 'Фолловеры';

  @override
  String get profileFollowersSearchHint => 'Поиск фолловеров';

  @override
  String get profileFollowersEmptyTitle => 'Пока нет фолловеров';

  @override
  String get profileFollowersEmptySubtitle =>
      'Когда на этот профиль подпишутся пользователи, они появятся здесь.';

  @override
  String get profileFollowersSearchEmptyTitle => 'Ничего не найдено';

  @override
  String get profileFollowersSearchEmptySubtitle =>
      'Попробуйте изменить запрос или очистить поиск.';

  @override
  String get profileFollowersLoadFailed => 'Не удалось загрузить фолловеров';

  @override
  String get profileJourneyTitle => 'Мой путь';

  @override
  String get profileSavedItemsTitle => 'Сохраненное';

  @override
  String get profileSavedItemsSubtitle =>
      'Собранные активности, места и подборки появятся здесь позже.';

  @override
  String get profileBookingsTitle => 'Мои бронирования';

  @override
  String get profileBookingsSubtitle =>
      'Список заказов и подтвержденных бронирований скоро появится здесь.';

  @override
  String get profileMyActivitiesSubtitle =>
      'Управляйте своими активностями и отслеживайте участия.';

  @override
  String get profilePreferencesTitle => 'Предпочтения';

  @override
  String get profileNotificationsRowTitle => 'Уведомления';

  @override
  String get profileNotificationsRowSubtitle =>
      'Push, email и SMS-уведомления по вашим активностям.';

  @override
  String get profileSecurityRowTitle => 'Безопасность и данные';

  @override
  String get profileSecurityRowSubtitle =>
      'PIN-код, биометрия и защищенная локальная сессия.';

  @override
  String get profileHostedActivitiesTitle => 'Активности пользователя';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Список опубликованных активностей появится здесь, когда backend отдаст публичную витрину автора.';

  @override
  String get profileBlogsTitle => 'Последние Блоги';

  @override
  String get profileBlogsUnavailable =>
      'Публичные заметки и истории путешествий пока недоступны в приложении.';

  @override
  String get profileUnavailableTitle => 'Скоро появится';

  @override
  String get profileFollowAction => 'Подписаться';

  @override
  String get profileFollowingAction => 'Вы подписаны';

  @override
  String get profileFollowUpdateFailed => 'Не удалось обновить подписку';

  @override
  String get profileMessageAction => 'Написать';

  @override
  String get profileMessageOpenFailed =>
      'Не удалось открыть чат. Попробуйте еще раз.';

  @override
  String get profileSettingsPageTitle => 'Настройки';

  @override
  String get profileSaveChangesButton => 'Сохранить изменения';

  @override
  String get profileDeactivateAccountLabel => 'Деактивировать аккаунт';

  @override
  String get profileSettingsAvatarDisabledHint =>
      'Изменение фото профиля появится в одном из следующих обновлений.';

  @override
  String get profileSettingsAvatarUploadHint =>
      'Нажмите на аватар или иконку редактирования, чтобы выбрать фото профиля.';

  @override
  String get profileSettingsAvatarUploading =>
      'Загружаем новое фото профиля...';

  @override
  String get profileSettingsAvatarUploadFailed =>
      'Не удалось загрузить фото профиля';

  @override
  String get profileSettingsAvatarUnsupportedFormat =>
      'Фото профиля должно быть в формате JPG, PNG или WEBP';

  @override
  String get profileSettingsDescriptionSection => 'Описание';

  @override
  String get profileSettingsDetailsSection => 'Данные профиля';

  @override
  String get profileSettingsServiceCitiesSection => 'Города сервиса';

  @override
  String get profileSettingsServiceCitiesUnavailable =>
      'Публичные города сервиса пока не поддерживаются на backend, поэтому этот блок остается неактивным.';

  @override
  String get profileSettingsAddNew => 'Добавить';

  @override
  String get profileSettingsSecuritySection => 'Безопасность';

  @override
  String get profileSettingsSecurityPinTitle => 'PIN-код и биометрия';

  @override
  String get profileSettingsSecurityPinSubtitle =>
      'Откройте экран безопасности, чтобы управлять локальной защитой входа.';

  @override
  String get profileAccountSectionTitle => 'Аккаунт';

  @override
  String get profileSettingsEditSubtitle =>
      'Измените имя, фото, описание и базовые данные профиля.';

  @override
  String get profileOverviewSectionTitle => 'Параметры профиля';

  @override
  String get profileMoreSectionTitle => 'Дополнительно';

  @override
  String get profileGuideWorkspaceTitle => 'Кабинет гида';

  @override
  String get profileGuideWorkspaceSubtitle =>
      'Инструменты для работы гида пока недоступны в мобильной версии.';

  @override
  String get profileSupportTitle => 'Помощь и поддержка';

  @override
  String get profileSupportSubtitle =>
      'Справочный центр и обращения в поддержку появятся позже.';

  @override
  String get profileNotificationsPageTitle => 'Уведомления';

  @override
  String get profileNotificationsHeroTitle => 'Будьте в курсе';

  @override
  String get profileNotificationsHeroSubtitle =>
      'Управляйте тем, как FlyFy сообщает вам об изменениях в активностях, участии и новых возможностях.';

  @override
  String get profileNotificationsActivitySection => 'Активности и участие';

  @override
  String get profileNotificationsDiscoverySection => 'Подборки и предложения';

  @override
  String get profileNotificationsPushTitle => 'Push-уведомления';

  @override
  String get profileNotificationsPushSubtitle =>
      'Мгновенные обновления по активностям, изменениям статуса и новым сообщениям.';

  @override
  String get profileNotificationsEmailTitle => 'Email-уведомления';

  @override
  String get profileNotificationsEmailSubtitle =>
      'Подтверждения, напоминания и полезные письма на вашу почту.';

  @override
  String get profileNotificationsSmsTitle => 'SMS-уведомления';

  @override
  String get profileNotificationsSmsSubtitle =>
      'Короткие сообщения для критичных обновлений и подтверждений.';

  @override
  String get profileNotificationsMarketingTitle => 'Подборки и спецпредложения';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Новые идеи для поездок, подборки мест и специальные предложения FlyFy.';

  @override
  String get profileNotificationsDarkModeTitle => 'Темная тема';

  @override
  String get profileNotificationsDarkModeSubtitle =>
      'Настройка появится позже. Пока приложение использует текущую палитру интерфейса.';

  @override
  String get profileNotificationsSaveFailed =>
      'Не удалось обновить настройки уведомлений';

  @override
  String get profileSecurityPageTitle => 'Безопасность и данные';

  @override
  String get profileSecurityHeroTitle => 'Защитите доступ';

  @override
  String get profileSecurityHeroSubtitle =>
      'Здесь собраны локальные способы входа и будущие инструменты защиты аккаунта.';

  @override
  String get profileSecurityLocalAccessSection => 'Локальный доступ';

  @override
  String get profileSecurityAccountSection => 'Защита аккаунта';

  @override
  String get profileSecurityDataSection => 'Данные и конфиденциальность';

  @override
  String get profileSecurityPinTitle => 'PIN-код приложения';

  @override
  String get profileSecurityPinEnabledSubtitle =>
      'PIN-код настроен и используется для быстрой разблокировки приложения.';

  @override
  String get profileSecurityPinMissingSubtitle =>
      'PIN-код еще не настроен. После следующей авторизации приложение предложит его создать.';

  @override
  String get profileSecurityBiometricTitle => 'Вход по биометрии';

  @override
  String get profileSecurityBiometricSubtitle =>
      'Разрешите разблокировку приложения через Face ID, отпечаток пальца или доступную биометрию.';

  @override
  String get profileSecurityBiometricNeedsPin =>
      'Сначала должен быть настроен PIN-код приложения.';

  @override
  String get profileSecurityBiometricUnavailable =>
      'На этом устройстве биометрия недоступна или не настроена.';

  @override
  String get profileSecurityProtectedSessionTitle => 'Защищенная сессия';

  @override
  String get profileSecurityProtectedSessionSubtitle =>
      'Локальная сессия сохранена. После перезапуска приложения можно быстро разблокироваться.';

  @override
  String get profileSecurityNoStoredSessionSubtitle =>
      'Активная сохраненная сессия не найдена. После нового входа защита включится автоматически.';

  @override
  String get profileSecurityTwoFactorTitle => 'Дополнительная верификация';

  @override
  String get profileSecurityTwoFactorSubtitle =>
      'Отдельные сценарии подтверждения входа и чувствительных действий появятся позже.';

  @override
  String get profileSecurityDataExportTitle => 'Экспорт данных';

  @override
  String get profileSecurityDataExportSubtitle =>
      'Выгрузка ваших данных пока не реализована на backend.';

  @override
  String get profileSecurityDeleteTitle => 'Удаление аккаунта';

  @override
  String get profileSecurityDeleteSubtitle =>
      'Управляемое удаление аккаунта появится после завершения backend-процесса.';

  @override
  String get profileStatusEnabled => 'Активно';

  @override
  String get profileStatusDisabled => 'Неактивно';

  @override
  String get profileDisabledSoon => 'Скоро';

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
  String get activityStatusCompletedEarly => 'Завершена раньше времени';

  @override
  String get activityStatusCancelled => 'Отменено';

  @override
  String get activityStatusArchived => 'В архиве';

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
  String get activityExtend30MinutesButton => 'Продлить на 30 мин';

  @override
  String get activityExtend60MinutesButton => 'Продлить на 1 час';

  @override
  String get activityExtendSuccess => 'Время окончания активности обновлено';

  @override
  String get activityExtendFailed => 'Не удалось продлить активность';

  @override
  String get activityExtendNotAllowed => 'Эту активность уже нельзя продлить';

  @override
  String get activityCompleteNowButton => 'Завершить сейчас';

  @override
  String get activityCompleteSuccess => 'Активность завершена';

  @override
  String get activityCompleteEarlySuccess =>
      'Активность завершена раньше запланированного времени';

  @override
  String get activityCompleteFailed => 'Не удалось завершить активность';

  @override
  String get activityCompleteTooEarly =>
      'Завершить активность можно только в последние 25% запланированного времени';

  @override
  String get activityCompleteNotAllowed =>
      'Эту активность сейчас нельзя завершить';

  @override
  String get activityCompleteAlreadyCompleted => 'Активность уже завершена';

  @override
  String get activityCompleteConfirmTitle => 'Завершить активность раньше?';

  @override
  String get activityCompleteConfirmDescription =>
      'Активность завершится раньше запланированного времени. Укажите причину, чтобы участники понимали, почему событие закончилось досрочно.';

  @override
  String get activityCompleteReasonLabel => 'Причина досрочного завершения';

  @override
  String get activityCompleteReasonPlaceholder =>
      'Например: программа выполнена быстрее, чем планировалось';

  @override
  String get activityCompleteReasonRequired =>
      'Укажите причину досрочного завершения';

  @override
  String get activityCompleteConfirmButton => 'Подтвердить завершение';

  @override
  String get activityCompleteCancelInsteadTitle =>
      'Сейчас активность будет отменена';

  @override
  String get activityCompleteCancelInsteadDescription =>
      'До планового завершения еще слишком много времени. Если продолжить сейчас, участники увидят, что активность была отменена, а не завершена. Укажите причину отмены.';

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
  String get participantStatusRequested => 'Запрос отправлен';

  @override
  String get participantStatusApproved => 'Подтвержден';

  @override
  String get participantStatusWaitlisted => 'В листе ожидания';

  @override
  String get participantStatusPendingPayment => 'Ожидает оплаты';

  @override
  String get participantStatusConfirmed => 'Подтверждено';

  @override
  String get participantStatusDeclined => 'Отклонено';

  @override
  String get participantStatusCancelled => 'Отменено';

  @override
  String get participantStatusExpired => 'Истекло';

  @override
  String get participantStatusCheckedIn => 'Отметился';

  @override
  String get participantStatusAttended => 'Посетил';

  @override
  String get participantStatusNoShow => 'Не пришел';

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
  String get homeExcursionsTitle => 'Экскурсии';

  @override
  String get homeExcursionsSubtitle =>
      'Подберите интересные маршруты и поездки';

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
  String get homeSearchHint => 'Искать активности, места, экскурсии...';

  @override
  String get homeTopDestinations => 'Топ направления';

  @override
  String get homeSeeAll => 'Смотреть все';

  @override
  String get homeTopStories => 'Топ историй';

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
  String get homeServiceActivities => 'Активности';

  @override
  String get homeServiceStories => 'Истории';

  @override
  String get homeServiceAttractions => 'Места';

  @override
  String get homeServiceStays => 'Жилье';

  @override
  String get homeServiceDelivery => 'Доставка';

  @override
  String get homeServiceTaxi => 'Такси';

  @override
  String get homePromoExclusive => 'Эксклюзив';

  @override
  String get homePromoAdventure => 'Приключения';

  @override
  String get homePromoYachtTitle => 'Yacht Parties';

  @override
  String get homePromoYachtDescription =>
      'Роскошный отдых на воде в авторском формате...';

  @override
  String get homePromoMountainTitle => 'Горные экскурсии';

  @override
  String get homePromoMountainDescription =>
      'Маршруты с живописными видами и локальными экспертами...';

  @override
  String get homePromoExplore => 'Открыть';

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
  String get mapNearbyPlacesLabel => 'Места рядом';

  @override
  String get mapSearchingNearbyPlaces => 'Ищем заведения и места поблизости';

  @override
  String get mapPlacesLoadFailed => 'Не удалось загрузить места поблизости';

  @override
  String get mapNoPlacesTitle => 'Места рядом не найдены';

  @override
  String get mapNoPlacesSubtitle =>
      'Переместите карту или обновите геолокацию, чтобы посмотреть другие ближайшие заведения и точки интереса.';

  @override
  String get mapTapPlaceHint =>
      'Нажмите на маркер или карточку места, чтобы посмотреть его и скопировать ссылку.';

  @override
  String get mapCopyPlaceLink => 'Скопировать ссылку';

  @override
  String get mapPlaceLinkCopied => 'Ссылка на место скопирована';

  @override
  String get mapUsingFallbackLocation =>
      'Показываем карту по резервной локации';

  @override
  String mapPlacesCount(int count) {
    return 'Найдено мест: $count';
  }

  @override
  String get attractionsTitle => 'Достопримечательности';

  @override
  String get attractionsSearchHint => 'Куда отправимся?';

  @override
  String get attractionsLoadFailed =>
      'Не удалось загрузить достопримечательности';

  @override
  String get attractionsSeeAll => 'Смотреть все';

  @override
  String get attractionsNoResults => 'Достопримечательности не найдены';

  @override
  String get attractionsFiltersTitle => 'Фильтры';

  @override
  String get attractionsSortLabel => 'Сортировать';

  @override
  String get attractionsSortRating => 'Рейтинг';

  @override
  String get attractionsSortDuration => 'Длительность';

  @override
  String get attractionsSortPrice => 'Цена';

  @override
  String get attractionFilterClearAll => 'Очистить всё';

  @override
  String get attractionFilterCategoriesSection => 'Категории';

  @override
  String get attractionFilterCategoryAll => 'Все места';

  @override
  String get attractionFilterCategoryParks => 'Парки';

  @override
  String get attractionFilterCategoryMuseums => 'Музеи';

  @override
  String get attractionFilterCategoryNature => 'Природа';

  @override
  String get attractionFilterCategoryHistory => 'История';

  @override
  String get attractionFilterCategoryAdventure => 'Приключения';

  @override
  String get attractionFilterMinRatingSection => 'Минимальный рейтинг';

  @override
  String get attractionFilterRatingAny => 'Любой';

  @override
  String get attractionFilterDurationSection => 'Длительность';

  @override
  String get attractionFilterDurationShort => 'Короткое < 2 ч';

  @override
  String get attractionFilterDurationMedium => 'Среднее 2–5 ч';

  @override
  String get attractionFilterDurationFullDay => 'Целый день 5 ч+';

  @override
  String get attractionFilterDurationMultiDay => 'Несколько дней';

  @override
  String get attractionFilterRangeSection => 'Точный диапазон';

  @override
  String attractionFilterRangeValue(int min, int max) {
    return '$min ч – $max ч';
  }

  @override
  String get attractionFilterRangeMinTick => '1 ч';

  @override
  String get attractionFilterRangeMaxTick => '12 ч+';

  @override
  String get attractionFilterPriceRangeSection => 'Диапазон цен';

  @override
  String attractionFilterShowSpots(int count) {
    return 'Показать $count мест';
  }

  @override
  String get attractionFilterClear => 'Очистить';

  @override
  String get attractionMinPriceLabel => 'Мин. цена';

  @override
  String get attractionMaxPriceLabel => 'Макс. цена';

  @override
  String get attractionPriceValidationError => 'Введите корректную цену';

  @override
  String get attractionPriceRangeValidationError =>
      'Максимальная цена должна быть больше минимальной';

  @override
  String get attractionHoursUnit => 'Часы';

  @override
  String get attractionDaysUnit => 'Дни';

  @override
  String get attractionHoursUnitShort => 'ч';

  @override
  String get attractionDaysUnitShort => 'дн';

  @override
  String get attractionMinLabel => 'Мин.';

  @override
  String get attractionMaxLabel => 'Макс.';

  @override
  String get attractionDurationValidationError =>
      'Введите корректную длительность';

  @override
  String get attractionDurationRangeValidationError =>
      'Максимальная длительность должна быть больше минимальной';

  @override
  String get attractionDetailsLoadFailed =>
      'Не удалось загрузить достопримечательность';

  @override
  String get attractionDetailsTitle => 'Детали места';

  @override
  String get attractionMustVisitBadge => 'Стоит посетить';

  @override
  String get attractionStatRating => 'Рейтинг';

  @override
  String get attractionStatDuration => 'Длительность';

  @override
  String get attractionStatPrice => 'Цена';

  @override
  String get attractionExperienceSection => 'Впечатление';

  @override
  String get attractionExpectSection => 'Что ожидать';

  @override
  String get attractionVisitPlanSection => 'План визита';

  @override
  String get attractionFlyFyTipTitle => 'Совет FlyFy';

  @override
  String get attractionVisitDurationLabel => 'Время на месте';

  @override
  String get attractionVisitDurationFlexible => 'Гибко';

  @override
  String get attractionVisitTicketsLabel => 'Билеты';

  @override
  String get attractionVisitFreeEntry => 'Бесплатно или зависит от сезона';

  @override
  String get attractionVisitBookingRecommended => 'лучше бронировать';

  @override
  String get attractionVisitBestTimeLabel => 'Лучшее время';

  @override
  String get attractionVisitBestTimeEarlyMorning => 'Раннее утро';

  @override
  String get attractionVisitBestTimeMorning => 'Утро';

  @override
  String get attractionVisitBestTimeAfternoon => 'День';

  @override
  String get attractionVisitBestTimeSunset => 'Закат';

  @override
  String get attractionVisitBestTimeAnytime => 'В любое время';

  @override
  String get attractionVisitGoodForLabel => 'Подходит для';

  @override
  String get attractionVisitAccessLabel => 'Доступ';

  @override
  String get attractionVisitAccessGood => 'Удобный доступ';

  @override
  String get attractionVisitAccessLimited => 'Ограниченный доступ';

  @override
  String get attractionVisitAccessUnknown => 'Уточните на месте';

  @override
  String get attractionVisitSafetyLabel => 'Подготовка';

  @override
  String get attractionVisitSafetyCheckWeather => 'Проверьте погоду';

  @override
  String get attractionVisitSafetyBringWater => 'Возьмите воду';

  @override
  String get attractionVisitSafetyCheckHours => 'Проверьте часы работы';

  @override
  String get attractionVisitAudienceCouples => 'Пары';

  @override
  String get attractionVisitAudienceWellness => 'Оздоровление';

  @override
  String get attractionVisitTipNature =>
      'Заранее проверьте транспорт и погоду: с гидом маршрут обычно безопаснее и предсказуемее.';

  @override
  String get attractionVisitTipCulture =>
      'Приходите пораньше: будет спокойнее для фото, а рядом останется время на культурные точки.';

  @override
  String get attractionVisitTipDefault =>
      'Проверьте актуальное расписание и совместите локацию с соседними активностями, чтобы не терять время на дорогу.';

  @override
  String get attractionReviewsSection => 'Голоса путешественников';

  @override
  String attractionSeeAllReviews(int count) {
    return 'Все отзывы ($count)';
  }

  @override
  String get attractionNoReviews => 'Отзывов пока нет. Станьте первым!';

  @override
  String get attractionAddReview => 'Оставить отзыв';

  @override
  String get attractionReviewSheetTitle => 'Поделитесь впечатлением';

  @override
  String get attractionReviewRatingLabel => 'Оценка';

  @override
  String get attractionReviewCommentLabel => 'Комментарий';

  @override
  String get attractionReviewCommentHint =>
      'Что понравилось, что посоветуете и что важно знать другим?';

  @override
  String get attractionReviewAddPhoto => 'Фото';

  @override
  String get attractionReviewAddVideo => 'Видео';

  @override
  String get attractionReviewSubmit => 'Опубликовать отзыв';

  @override
  String get attractionReviewSubmitting => 'Публикуем...';

  @override
  String attractionReviewMediaLimit(int count) {
    return 'Можно прикрепить до $count файлов';
  }

  @override
  String get attractionReviewPickFailed => 'Не удалось прикрепить файл';

  @override
  String get attractionReviewMediaTooLarge => 'Файл слишком большой';

  @override
  String get attractionReviewUnsupportedFormat =>
      'Формат файла не поддерживается';

  @override
  String get attractionReviewSubmitFailed => 'Не удалось опубликовать отзыв';

  @override
  String get attractionReviewSubmitSuccess => 'Отзыв опубликован';

  @override
  String get attractionReviewCommentRequired => 'Напишите короткий комментарий';

  @override
  String get attractionReviewRemoveMedia => 'Удалить файл';

  @override
  String get attractionReviewVideoPreview => 'Видео';

  @override
  String get attractionFindExcursions => 'Найти экскурсии';

  @override
  String get attractionMapLink => 'Открыть на карте';

  @override
  String get attractionVerifiedNomad => 'Проверенный путешественник';

  @override
  String get attractionReviewsTitle => 'Отзывы';

  @override
  String get attractionTravelerFallback => 'Путешественник';

  @override
  String get attractionPriceVaries => 'Цена варьируется';

  @override
  String get attractionPriceVariesShort => 'Варьируется';

  @override
  String attractionDurationHours(int hours) {
    return '$hours ч';
  }

  @override
  String attractionDurationDays(int days) {
    return '$days дн';
  }

  @override
  String get attractionBackTooltip => 'Назад';

  @override
  String get attractionNotificationsTooltip => 'Уведомления';

  @override
  String get attractionBookmarkTooltip => 'Сохранить место';

  @override
  String get attractionTagFamilyLabel => 'Для семьи';

  @override
  String get attractionTagFamilySubtitle => 'Подходит для всех возрастов';

  @override
  String get attractionTagSunsetLabel => 'Лучше на закате';

  @override
  String get attractionTagSunsetSubtitle => 'Красивые сумеречные виды';

  @override
  String get attractionTagAccessibilityLabel => 'Доступность';

  @override
  String get attractionTagAccessibilitySubtitle => 'Подходит для колясок';

  @override
  String get attractionTagDiningLabel => 'Рестораны';

  @override
  String get attractionTagDiningSubtitle => 'Гастрономические места';

  @override
  String get attractionTagOutdoorLabel => 'На природе';

  @override
  String get attractionTagOutdoorSubtitle => 'Свежий воздух и виды';

  @override
  String get attractionTagPhotoLabel => 'Фотолокация';

  @override
  String get attractionTagPhotoSubtitle => 'Для запоминающихся кадров';

  @override
  String get attractionTagHistoryLabel => 'История';

  @override
  String get attractionTagHistorySubtitle => 'Культурное наследие';

  @override
  String get attractionTagAdventureLabel => 'Приключения';

  @override
  String get attractionTagAdventureSubtitle => 'Активные впечатления';

  @override
  String get attractionTagUniqueSubtitle => 'Уникальное впечатление';

  @override
  String get activitiesEntryTitle => 'Активности';

  @override
  String get activitiesEntrySubtitle =>
      'Найдите офлайн и онлайн события, к которым можно присоединиться';

  @override
  String get comingSoon => 'Скоро появится';

  @override
  String get change => 'Изменить';

  @override
  String get select => 'Выбрать';

  @override
  String get confirm => 'Подтвердить';

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
  String get excursionsDiscoverTitle => 'Экскурсии';

  @override
  String get excursionsSearchHint => 'Поиск экскурсий и впечатлений';

  @override
  String get excursionsSortLabel => 'Сортировать';

  @override
  String get excursionsSortPopular => 'Популярные';

  @override
  String get excursionsSortNewest => 'Новинки';

  @override
  String get excursionsSortAffordable => 'Дешевле';

  @override
  String get excursionsSortCreatedAt => 'Дата создания';

  @override
  String get excursionsSortRating => 'Рейтинг';

  @override
  String get excursionsSortPrice => 'Цена';

  @override
  String get excursionsSortDuration => 'Продолжительность';

  @override
  String get excursionsFiltersTitle => 'Фильтры';

  @override
  String get excursionsFiltersClear => 'Очистить';

  @override
  String excursionsFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count экскурсии',
      many: '$count экскурсий',
      few: '$count экскурсии',
      one: '$count экскурсия',
      zero: '0 экскурсий',
    );
    return 'Показать $_temp0';
  }

  @override
  String get excursionsFilterCountry => 'Страна';

  @override
  String get excursionsFilterCountryAll => 'Все страны';

  @override
  String get excursionsFilterCountrySearchHint =>
      'Поиск страны, кода или телефона';

  @override
  String get excursionsFilterCountryNoResults => 'Страна не найдена';

  @override
  String get excursionsFilterCategories => 'Категории';

  @override
  String get excursionsFilterPriceRange => 'Диапазон цены';

  @override
  String get excursionsFilterPriceFrom => 'От';

  @override
  String get excursionsFilterPriceTo => 'До';

  @override
  String get excursionsFilterBudget => 'Бюджетно';

  @override
  String get excursionsFilterPremium => 'Премиум';

  @override
  String get excursionsFilterDuration => 'Длительность';

  @override
  String get excursionsFilterShortDuration => 'Короткий (< 3 ч)';

  @override
  String get excursionsFilterHalfDayDuration => 'Полдня (3–6 ч)';

  @override
  String get excursionsFilterFullDayDuration => 'День (6 ч+)';

  @override
  String get excursionsFilterMultiDayDuration => 'Несколько дней';

  @override
  String get excursionsFilterLanguage => 'Язык';

  @override
  String get excursionsLoadFailed => 'Не удалось загрузить экскурсии';

  @override
  String get excursionsEmptyTitle => 'Экскурсий пока нет';

  @override
  String get excursionsEmptySubtitle =>
      'Здесь появятся маршруты проверенных гидов.';

  @override
  String get excursionsEmptySearchSubtitle =>
      'Попробуйте другой город, категорию или название экскурсии.';

  @override
  String get guidesTitle => 'Гиды';

  @override
  String get guidesSearchHint => 'Поиск гидов';

  @override
  String get guidesSortLabel => 'Сортировать';

  @override
  String get guidesSortRating => 'Рейтинг';

  @override
  String get guidesSortExperience => 'Опыт';

  @override
  String get guidesViewProfile => 'Профиль';

  @override
  String get guidesFiltersTitle => 'Фильтры';

  @override
  String get guidesFiltersClear => 'Очистить';

  @override
  String get guidesFilterExpertise => 'Экспертиза';

  @override
  String get guidesFilterLanguage => 'Язык';

  @override
  String get guidesFilterRating => 'Рейтинг';

  @override
  String get guidesFilterExperience => 'Опыт';

  @override
  String guidesFilterRatingAtLeast(Object value) {
    return '$value+ звезд';
  }

  @override
  String guidesFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гида',
      many: '$count гидов',
      few: '$count гида',
      one: '$count гид',
      zero: '0 гидов',
    );
    return 'Показать $_temp0';
  }

  @override
  String get guidesLoadFailed => 'Не удалось загрузить гидов';

  @override
  String get guidesEmptyTitle => 'Гидов пока нет';

  @override
  String get guidesEmptySubtitle =>
      'Здесь появятся проверенные локальные эксперты.';

  @override
  String get guidesNoResultsTitle => 'Гиды не найдены';

  @override
  String get guidesNoResultsSubtitle =>
      'Попробуйте другое имя, специализацию, язык или фильтр.';

  @override
  String get guidesSpecialtyMountainGuide => 'Горный гид';

  @override
  String get guidesSpecialtyCityHistorian => 'Городской историк';

  @override
  String get guidesSpecialtyCulinaryExpert => 'Кулинарный эксперт';

  @override
  String get guidesSpecialtyNaturePhotographer => 'Фотограф природы';

  @override
  String get guidesRoleLocalExpert => 'Локальный эксперт';

  @override
  String get guidesFilterPrivateExcursions => 'Частные экскурсии';

  @override
  String get guidesFilterActivities => 'Активности';

  @override
  String get guidesFilterExcursions => 'Экскурсии';

  @override
  String guidesExperienceYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count года',
      many: '$count лет',
      few: '$count года',
      one: '$count год',
    );
    return '$_temp0';
  }

  @override
  String get excursionsCreateFab => 'Создать экскурсию';

  @override
  String get excursionsFreePrice => 'Бесплатно';

  @override
  String excursionsPriceFrom(Object price) {
    return 'От $price';
  }

  @override
  String excursionsOffersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гида',
      many: '$count гидов',
      few: '$count гида',
      one: '$count гид',
      zero: 'Гидов пока нет',
    );
    return '$_temp0';
  }

  @override
  String get excursionsDurationHourShort => 'ч';

  @override
  String get excursionsDurationMinuteShort => 'мин';

  @override
  String get excursionDetailsTitle => 'Детали экскурсии';

  @override
  String get excursionDetailsPrice => 'Цена';

  @override
  String get excursionDetailsPerPerson => '/чел';

  @override
  String get excursionDetailsIntensity => 'Нагрузка';

  @override
  String get excursionDetailsIntensityModerate => 'Средняя';

  @override
  String get excursionDetailsGroupSize => 'Размер группы';

  @override
  String excursionDetailsGroupSizeUpTo(Object count) {
    return 'До $count';
  }

  @override
  String get excursionDetailsLanguage => 'Язык';

  @override
  String get excursionLanguageEnglish => 'Английский';

  @override
  String get excursionLanguageRussian => 'Русский';

  @override
  String get excursionLanguageKazakh => 'Казахский';

  @override
  String get excursionLanguageFrench => 'Французский';

  @override
  String get excursionLanguageJapanese => 'Японский';

  @override
  String get excursionLanguageGerman => 'Немецкий';

  @override
  String get excursionLanguageSpanish => 'Испанский';

  @override
  String get excursionLanguageTurkish => 'Турецкий';

  @override
  String get excursionDetailsExperience => 'Описание';

  @override
  String get excursionDetailsWhatToExpect => 'Что входит';

  @override
  String get excursionDetailsSelectedOfferIncluded =>
      'Что входит у выбранного гида';

  @override
  String get excursionDetailsLeadGuide => 'Ваш гид';

  @override
  String get excursionDetailsGuideName => 'Гид';

  @override
  String get excursionDetailsGuideSubtitle => 'Проверенный локальный эксперт';

  @override
  String get excursionDetailsGuideQuote =>
      'Маршрут запоминается сильнее, когда у него есть локальный контекст, правильный ритм и гид, который знает, когда замедлиться.';

  @override
  String get excursionDetailsMessageGuide => 'Написать гиду';

  @override
  String get excursionDetailsOffersTitle => 'Доступные гиды';

  @override
  String get excursionDetailsOffersEmpty => 'Доступных гидов пока нет';

  @override
  String get excursionDetailsOfferSelected => 'Выбран';

  @override
  String get excursionDetailsOfferCurrentUser => 'Это вы';

  @override
  String get excursionDetailsOffersSearchHint => 'Поиск гидов и предложений';

  @override
  String get excursionDetailsOffersLoadMore => 'Показать ещё гидов';

  @override
  String get excursionDetailsOffersLoadFailed => 'Не удалось загрузить гидов';

  @override
  String get excursionDetailsOffersSortRating => 'Рейтинг';

  @override
  String get excursionDetailsOffersSortExperience => 'Опыт';

  @override
  String get excursionDetailsOffersSortPrice => 'Цена';

  @override
  String get excursionDetailsOffersFiltersTitle => 'Фильтры гидов';

  @override
  String get excursionDetailsOffersMaxPrice => 'Цена до';

  @override
  String get excursionDetailsOffersMaxPriceHint => 'Например, 50000';

  @override
  String get excursionDetailsOffersMinGroup => 'Мин. размер группы';

  @override
  String get excursionDetailsOffersMinGroupHint => 'Например, 4';

  @override
  String get excursionDetailsOffersLanguageAny => 'Любой язык';

  @override
  String get excursionDetailsOffersLanguageSearchHint => 'Поиск языка или кода';

  @override
  String get excursionDetailsOffersLanguageNoResults => 'Язык не найден';

  @override
  String get excursionDetailsOffersApplyFilters => 'Применить фильтры';

  @override
  String get excursionDetailsMapPreview => 'Точка встречи';

  @override
  String get excursionDetailsItinerary => 'Маршрут';

  @override
  String get excursionDetailsMeetingPoint => 'Место встречи';

  @override
  String get excursionDetailsTotal => 'Итого';

  @override
  String get excursionDetailsBook => 'Забронировать';

  @override
  String get excursionDetailsEditOffer => 'Редактировать предложение';

  @override
  String get excursionDetailsLoadFailed => 'Не удалось загрузить экскурсию';

  @override
  String get excursionDetailsBookingComingSoon =>
      'Бронирование экскурсии скоро будет доступно.';

  @override
  String get excursionDetailsGuideChatComingSoon =>
      'Чат с гидом скоро будет доступен.';

  @override
  String get excursionBookingTitle => 'Бронирование экскурсии';

  @override
  String get excursionBookingSchedule => 'Расписание';

  @override
  String get excursionBookingChange => 'Изменить';

  @override
  String get excursionBookingDate => 'Дата';

  @override
  String get excursionBookingTimeSlot => 'Время';

  @override
  String get excursionBookingTravelers => 'Путешественники';

  @override
  String get excursionBookingAdults => 'Взрослые';

  @override
  String get excursionBookingChildren => 'Дети';

  @override
  String get excursionBookingSummary => 'Итог';

  @override
  String excursionBookingAdultSummary(Object count, Object price) {
    return 'Взрослые ($count × $price)';
  }

  @override
  String excursionBookingChildrenSummary(Object count, Object price) {
    return 'Дети ($count × $price)';
  }

  @override
  String get excursionBookingServiceFeeSummary => 'Сервисный сбор (5%)';

  @override
  String get excursionBookingTotalPrice => 'Итоговая стоимость';

  @override
  String get excursionBookingConfirmPay => 'Подтвердить и оплатить';

  @override
  String get excursionBookingSecurePayment => 'Безопасная оплата через FlyFy';

  @override
  String get excursionBookingSubmitted =>
      'Заявка на бронирование готова. Онлайн-оплата будет подключена скоро.';

  @override
  String get excursionBookingLoadFailed =>
      'Не удалось загрузить бронирование экскурсии';

  @override
  String get excursionBookingPerPerson => '/ чел.';

  @override
  String get excursionDetailsNoDescription =>
      'Гид скоро добавит подробное описание.';

  @override
  String get createExcursionTitle => 'Создать экскурсию';

  @override
  String get createExcursionEditTitle => 'Редактировать предложение';

  @override
  String get createExcursionSubmit => 'Опубликовать';

  @override
  String get createExcursionSaveChanges => 'Сохранить';

  @override
  String get createExcursionSuccess => 'Экскурсия опубликована';

  @override
  String get createExcursionUpdateSuccess => 'Предложение обновлено';

  @override
  String get createExcursionFailed => 'Не удалось создать экскурсию';

  @override
  String get createExcursionUpdateFailed => 'Не удалось обновить предложение';

  @override
  String get createExcursionCoverSection => 'Обложка экскурсии';

  @override
  String get createExcursionCoverUploadTitle =>
      'Загрузить изображение экскурсии';

  @override
  String get createExcursionCoverChangeAction =>
      'Изменить изображение экскурсии';

  @override
  String get createExcursionCoverUploadHint =>
      'JPG, PNG или WEBP. Если выбрана достопримечательность, ее фото подставится автоматически, пока вы не загрузите свое.';

  @override
  String get createExcursionSelectedLandmark => 'Достопримечательность';

  @override
  String get createExcursionLandmarkNameLabel => 'Локация';

  @override
  String get createExcursionLandmarkNameHint => 'Например, Медеу';

  @override
  String get createExcursionLandmarkValidation =>
      'Выберите достопримечательность';

  @override
  String get createExcursionCountryValidation => 'Сначала выберите страну';

  @override
  String get createExcursionSelectCountryFirst => 'Сначала выберите страну';

  @override
  String get createExcursionManualLocationHint =>
      'Можно указать свою локацию или выбрать достопримечательность этой страны.';

  @override
  String get createExcursionLocationLockedByAttraction =>
      'Локация взята из справочника достопримечательностей. Чтобы изменить ее, выберите другую достопримечательность.';

  @override
  String get createExcursionAttractionCatalogHint =>
      'Каталог достопримечательностей выбранной страны';

  @override
  String get createExcursionAttractionCatalogSource =>
      'Из каталога достопримечательностей';

  @override
  String get excursionSelectLocationTitle => 'Выбор локации';

  @override
  String get excursionSelectLocationCountrySection => 'Выберите страну';

  @override
  String get excursionSelectLocationCountrySearchHint => 'Поиск стран...';

  @override
  String get excursionCountryKazakhstan => 'Казахстан';

  @override
  String get excursionCountryFrance => 'Франция';

  @override
  String get excursionCountryJapan => 'Япония';

  @override
  String get excursionCountryItaly => 'Италия';

  @override
  String get excursionSelectLocationAttractionSection =>
      'Выберите достопримечательность';

  @override
  String get excursionSelectLocationAttractionSearchHint =>
      'Поиск достопримечательностей...';

  @override
  String get excursionSelectLocationSelected => 'Выбрано';

  @override
  String excursionSelectLocationPageCaption(Object current, Object total) {
    return 'СТРАНИЦА $current ИЗ $total';
  }

  @override
  String get createExcursionCategorization => 'Категория путешествия';

  @override
  String get createExcursionCategoryAdventure => 'Приключения';

  @override
  String get createExcursionCategoryCultural => 'Культура';

  @override
  String get createExcursionCategoryCulinary => 'Гастро';

  @override
  String get createExcursionCategoryWellness => 'Велнес';

  @override
  String get createExcursionDetailedItinerary => 'Детальный маршрут';

  @override
  String get createExcursionAddTimeSlot => 'Добавить слот';

  @override
  String get createExcursionItineraryEmpty =>
      'Добавьте хотя бы один пункт маршрута. Он будет показан туристам в деталях экскурсии.';

  @override
  String get createExcursionAutosaveHint =>
      'Прогресс автосохраняется в профиль гида';

  @override
  String get createExcursionItineraryValidation =>
      'Добавьте хотя бы один полный слот маршрута';

  @override
  String get createExcursionDurationLabel => 'Длительность';

  @override
  String get createExcursionDurationHint => 'Например, 4 часа';

  @override
  String get createExcursionDurationUnitLabel => 'Единица';

  @override
  String get createExcursionDurationUnitMinutes => 'Минуты';

  @override
  String get createExcursionDurationUnitHours => 'Часы';

  @override
  String get createExcursionDurationUnitDays => 'Дни';

  @override
  String get createExcursionDurationValidation =>
      'Укажите длительность не менее 15 минут';

  @override
  String get createExcursionMaxGroupSizeLabel => 'Максимум гостей';

  @override
  String get createExcursionMaxGroupSizeHint => 'Например, 12';

  @override
  String get createExcursionGroupSizeValidation =>
      'Укажите размер группы от 1 до 100';

  @override
  String get createExcursionLanguagesLabel => 'Языки экскурсии';

  @override
  String get createExcursionLanguagesHint =>
      'Английский, французский, японский...';

  @override
  String get createExcursionLanguagesValidation =>
      'Добавьте хотя бы один язык экскурсии';

  @override
  String createExcursionLanguagesPickerHint(Object count) {
    return 'Можно выбрать до $count языков';
  }

  @override
  String createExcursionLanguagesLimitValidation(Object count) {
    return 'Можно выбрать до $count языков';
  }

  @override
  String get createExcursionVisibilityTitle => 'Видимость экскурсии';

  @override
  String get createExcursionVisibilityPublicDescription =>
      'Виден всем пользователям маркетплейса FlyFy.';

  @override
  String get createExcursionVisibilityUnlistedDescription =>
      'Экскурсию увидят и смогут забронировать только пользователи с прямой ссылкой.';

  @override
  String get createExcursionMeetingPointHint =>
      'Введите адрес встречи или ориентир...';

  @override
  String get createExcursionSoulTitle => 'Душа путешествия';

  @override
  String get createExcursionNameLabel => 'Название экскурсии';

  @override
  String get createExcursionNameHint => 'Например, Горный побег в Алматы';

  @override
  String get createExcursionSummaryLabel => 'Краткое описание';

  @override
  String get createExcursionSummaryHint =>
      'Короткое обещание для путешественников';

  @override
  String get createExcursionSummaryValidation =>
      'Краткое описание должно быть не менее 3 символов';

  @override
  String get createExcursionSoulHint =>
      'Опишите атмосферу маршрута, скрытые детали и ощущение от путешествия...';

  @override
  String get createExcursionDescriptionValidation =>
      'Описание должно быть не менее 20 символов';

  @override
  String get createExcursionInvestmentTitle => 'Стоимость за человека';

  @override
  String get createExcursionCurrencyValidation => 'Укажите код валюты';

  @override
  String get createCurrencyKzt => 'тенге';

  @override
  String get createCurrencyUsd => 'доллар США';

  @override
  String get createCurrencyEur => 'евро';

  @override
  String get createCurrencyRub => 'рубль';

  @override
  String get createCurrencyGbp => 'фунт стерлингов';

  @override
  String get createExcursionIncludedItemsLabel => 'Что включено';

  @override
  String get createExcursionIncludedItemsHint =>
      'Через запятую: внедорожник, пикник, билеты';

  @override
  String get createExcursionIncludedItemsEmpty =>
      'Добавьте точные пункты: транспорт, питание, входные билеты или снаряжение';

  @override
  String get createExcursionIncludedItemsEditorTitle => 'Что включено';

  @override
  String get createExcursionIncludedItemsAdd => 'Добавить пункт';

  @override
  String get createExcursionIncludedItemsRemove => 'Удалить пункт';

  @override
  String get createExcursionIncludedItemsTypeLabel => 'Тип';

  @override
  String get createExcursionIncludedItemsValueLabel => 'Что именно включено';

  @override
  String get createExcursionIncludedItemsValueHint =>
      'Например, трансфер на внедорожнике';

  @override
  String get createExcursionIncludedItemsValidation =>
      'Заполните каждый пункт или удалите пустые строки';

  @override
  String get createExcursionIncludedTypeTransport => 'Транспорт';

  @override
  String get createExcursionIncludedTypeFood => 'Питание';

  @override
  String get createExcursionIncludedTypeTickets => 'Билеты';

  @override
  String get createExcursionIncludedTypeEquipment => 'Снаряжение';

  @override
  String get createExcursionIncludedTypeGuide => 'Гид';

  @override
  String get createExcursionIncludedTypePhoto => 'Фото';

  @override
  String get createExcursionIncludedTypeOther => 'Другое';

  @override
  String get createExcursionStartOffsetLabel => 'Старт через, мин';

  @override
  String get createExcursionSlotDurationLabel => 'Длительность, мин';

  @override
  String get createExcursionItineraryTitleLabel => 'Название';

  @override
  String get createExcursionItineraryTitleHint => 'Например, Подъем к вершине';

  @override
  String get createExcursionItineraryDescriptionLabel => 'Описание';

  @override
  String get createExcursionItineraryDescriptionHint =>
      'Что происходит на этой части маршрута';

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
  String createStartAtMonthLimitValidation(String date) {
    return 'Дата начала должна быть не позднее $date';
  }

  @override
  String createEndAtMonthLimitValidation(String date) {
    return 'Дата окончания должна быть не позднее $date';
  }

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
      'Укажите максимум от 1 до 100 участников';

  @override
  String get createMinParticipantsValidation =>
      'Укажите минимум не меньше 2 участников';

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
      'Цену нельзя изменить, если записались другие участники';

  @override
  String get myActivitiesTitle => 'Мои активности';

  @override
  String get myStoriesTitle => 'Мои истории';

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
  String get activitiesFiltersTitle => 'Фильтры';

  @override
  String get activitiesSortLabel => 'Сортировать';

  @override
  String get activitiesSortDate => 'Дата';

  @override
  String get activitiesSortPrice => 'Цена';

  @override
  String get activitiesFilterCategory => 'Категория';

  @override
  String get activitiesFilterDate => 'Дата';

  @override
  String get activitiesFilterStartDatePlaceholder => '15.05.2026';

  @override
  String get activitiesFilterEndDatePlaceholder => '22.05.2026';

  @override
  String get activitiesFilterPricing => 'Стоимость';

  @override
  String get activitiesFilterVisibility => 'Видимость';

  @override
  String get activitiesDiscoverTitle => 'Активности';

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
  String get qrScannerNotRegistered =>
      'Вы не являетесь участником данной активности';

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

  @override
  String get retry => 'Повторить';

  @override
  String get backButtonLabel => 'Назад';

  @override
  String get storiesDiscoverTitle => 'Истории';

  @override
  String get storiesNavLabel => 'Истории';

  @override
  String get storiesActivitiesNavLabel => 'Активности';

  @override
  String get storySearchHint => 'Поиск историй, авторов или мест';

  @override
  String get storyFiltersTitle => 'Фильтры';

  @override
  String get storyFilterCategory => 'Категория';

  @override
  String get storyFilterCountry => 'Страна';

  @override
  String get storyFilterAll => 'Все';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count истории',
      many: '$count историй',
      few: '$count истории',
      one: '$count историю',
      zero: '0 историй',
    );
    return 'Показать $_temp0';
  }

  @override
  String get storySortLabel => 'Сортировать';

  @override
  String get storySortDate => 'Дата';

  @override
  String get storySortViews => 'Просмотры';

  @override
  String get storySortComments => 'Комментарии';

  @override
  String get storyCreateCta => 'Поделиться историей';

  @override
  String get storyCreateFirst => 'Создать первую историю';

  @override
  String get storyEmptyTitle => 'Историй пока нет';

  @override
  String get storyEmptySubtitle =>
      'Станьте первым, кто опубликует travel-note, локальный гид или визуальное эссе.';

  @override
  String get storyLoadFailed => 'Не удалось загрузить истории';

  @override
  String get storyViewsSuffix => 'просмотров';

  @override
  String get storyCategoryJournal => 'Журнал';

  @override
  String get storyCategoryGuide => 'Гид';

  @override
  String get storyCategoryPhotoEssay => 'Фотоэссе';

  @override
  String get storyCategoryCulinary => 'Гастрономия';

  @override
  String get storyDetailsTitle => 'Детали истории';

  @override
  String get storyLinkCopied => 'Ссылка на историю скопирована';

  @override
  String get storyShareFailed =>
      'Не удалось открыть окно отправки ссылки. Попробуйте еще раз.';

  @override
  String get storyAuthorLabel => 'Автор';

  @override
  String get storyFollowAction => 'Подписаться';

  @override
  String get storyFollowingAction => 'Подписаны';

  @override
  String get storyStatViews => 'Просмотры';

  @override
  String get storyStatLikes => 'Лайки';

  @override
  String get storyStatComments => 'Комменты';

  @override
  String get storyStatShares => 'Шеры';

  @override
  String get storyTagsLabel => 'Теги';

  @override
  String get storyCommentHint => 'Оставьте комментарий';

  @override
  String get storyCommentsTitle => 'Комментарии';

  @override
  String get storyCommentsEmpty =>
      'Комментариев пока нет. Начните обсуждение первым.';

  @override
  String get storyCommentRateLimit =>
      'Можно оставлять только один комментарий раз в 3 часа.';

  @override
  String storyCommentCooldownUntil(Object time) {
    return 'Следующий комментарий можно оставить после $time.';
  }

  @override
  String get storyCommentLinkCopied => 'Ссылка на комментарий скопирована';

  @override
  String get storyCommentShareFailed =>
      'Не удалось открыть окно отправки комментария. Попробуйте еще раз.';

  @override
  String get storyCommentEditingTitle => 'Редактирование комментария';

  @override
  String get storyCommentSaveAction => 'Сохранить';

  @override
  String get storyCommentShareAction => 'Поделиться';

  @override
  String get storyDeleteCommentTitle => 'Удалить комментарий?';

  @override
  String get storyDeleteCommentMessage =>
      'Комментарий будет удален без возможности восстановления.';

  @override
  String get storyDeleteCommentAction => 'Удалить';

  @override
  String get storyRelatedEyebrow => 'Исследуйте дальше';

  @override
  String get storyRelatedTitle => 'Похожие истории';

  @override
  String get storyRelatedEmpty => 'Похожих историй пока нет';

  @override
  String get storyViewAll => 'Смотреть все';

  @override
  String get storyEditAction => 'Редактировать';

  @override
  String get storyDeleteTitle => 'Удалить историю?';

  @override
  String get storyDeleteMessage => 'История будет убрана из публичной ленты.';

  @override
  String get storyDeleteAction => 'Удалить';

  @override
  String get storyCreateTitle => 'Новая история';

  @override
  String get storyContinueAction => 'Продолжить';

  @override
  String get storyUpdateAction => 'Обновить историю';

  @override
  String get storyPublishAction => 'Опубликовать историю';

  @override
  String get storySaveDraftAction => 'Сохранить черновик';

  @override
  String get storySaveFailed => 'Не удалось сохранить историю';

  @override
  String get storyCoverUploadTitle => 'Загрузите обложку';

  @override
  String get storyCoverUploadSubtitle =>
      'Желательно использовать качественное горизонтальное изображение';

  @override
  String get storyCoverRequired => 'Добавьте обложку';

  @override
  String get storyCoverUnsupported =>
      'Этот формат изображения не поддерживается';

  @override
  String get storyCoverTooLarge =>
      'Файл обложки слишком большой. Используйте изображение до 20 МБ.';

  @override
  String get storyCoverUploadFailed => 'Не удалось загрузить обложку';

  @override
  String get storyTitleLabel => 'Заголовок истории';

  @override
  String get storyTitleHint => 'Например: Закатная йога у пирса';

  @override
  String get storyTitleRequired => 'Введите заголовок истории';

  @override
  String storyTitleTooLong(Object count) {
    return 'Заголовок не должен превышать $count символов';
  }

  @override
  String get storyPlacePrompt => 'Где произошла эта история?';

  @override
  String get storyPlaceHint => 'Введите город или страну';

  @override
  String get storyCountryHint => 'Поиск страны';

  @override
  String get storyCityHint => 'Поиск города';

  @override
  String get storyTagsFieldLabel => 'Теги';

  @override
  String get storyTagHint => 'Добавить тег';

  @override
  String get storyTagsLimit => 'Можно добавить не более 8 тегов';

  @override
  String get storyCategoryLabel => 'Выберите категорию';

  @override
  String get storyCategoryRequired => 'Выберите категорию истории';

  @override
  String get storyContentHint => 'Начните свой рассказ здесь...';

  @override
  String get storyContinueSectionHint => 'Продолжите историю здесь...';

  @override
  String get storyContentRequired => 'Напишите текст истории';

  @override
  String storyContentTooLong(Object count) {
    return 'Текст истории не должен превышать $count символов';
  }

  @override
  String get storyCharacterCountLabel => 'Количество символов';

  @override
  String get storyInlineImageAddAction => 'Добавить фото';

  @override
  String get storyInlineImageHint =>
      'Изображения будут показаны между абзацами истории.';

  @override
  String get storyContinueSectionLabel =>
      'Можно продолжить текст ниже или добавить еще фото.';

  @override
  String get storyInlineImageUnsupported =>
      'Этот формат изображения не поддерживается для тела истории.';

  @override
  String get storyInlineImageTooLarge =>
      'Изображение слишком большое. Выберите файл до 20 МБ.';

  @override
  String get storyInlineImageUploadFailed =>
      'Не удалось загрузить изображение в историю. Попробуйте еще раз.';

  @override
  String get storyAiHintUnavailable =>
      'AI-подсказки для текста пока недоступны';

  @override
  String get storyWritersNoteTitle => 'Совет автору';

  @override
  String get storyWritersNoteBody =>
      'Попробуйте начать с чувственной детали. Вместо «Я приехал в Токио» опишите неоновое свечение, отражающееся в мокром асфальте Сибуи.';

  @override
  String get chatListTitle => 'Чаты';

  @override
  String get chatListLoadFailed => 'Не удалось загрузить чаты';

  @override
  String get chatListEmpty => 'Диалогов пока нет';

  @override
  String get chatFallbackTitle => 'Чат';

  @override
  String get chatGroupFallbackTitle => 'Групповой чат';

  @override
  String get chatActivityFallbackTitle => 'Чат активности';

  @override
  String get chatActiveNow => 'СЕЙЧАС В СЕТИ';

  @override
  String get chatPresenceOnline => 'в сети';

  @override
  String get chatPresenceOffline => 'не в сети';

  @override
  String get chatPresenceLastSeenJustNow => 'был(а) в сети только что';

  @override
  String chatPresenceLastSeenMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был(а) в сети $count минуты назад',
      many: 'был(а) в сети $count минут назад',
      few: 'был(а) в сети $count минуты назад',
      one: 'был(а) в сети $count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был(а) в сети $count часа назад',
      many: 'был(а) в сети $count часов назад',
      few: 'был(а) в сети $count часа назад',
      one: 'был(а) в сети $count час назад',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'был(а) в сети $count дня назад',
      many: 'был(а) в сети $count дней назад',
      few: 'был(а) в сети $count дня назад',
      one: 'был(а) в сети $count день назад',
    );
    return '$_temp0';
  }

  @override
  String chatParticipantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
      zero: 'Нет участников',
    );
    return '$_temp0';
  }

  @override
  String get chatPinnedMessageLabel => 'ЗАКРЕПЛЕННОЕ СООБЩЕНИЕ';

  @override
  String get chatPinAction => 'Закрепить';

  @override
  String get chatUnpinAction => 'Открепить';

  @override
  String get chatPinFailed =>
      'Не удалось закрепить сообщение. Попробуйте еще раз.';

  @override
  String get chatUnpinFailed =>
      'Не удалось открепить сообщение. Попробуйте еще раз.';

  @override
  String get chatDateToday => 'Сегодня';

  @override
  String get chatDateYesterday => 'Вчера';

  @override
  String get chatMessageDeleted => 'Сообщение удалено';

  @override
  String get chatDeleteAction => 'Удалить';

  @override
  String get chatDeleteFailed =>
      'Не удалось удалить сообщение. Попробуйте еще раз.';

  @override
  String get chatEditedLabel => 'изменено';

  @override
  String get chatUserFallbackName => 'Пользователь';

  @override
  String get chatReplyPreviewFallback => 'Сообщение';

  @override
  String chatSystemUserJoined(Object name) {
    return '$name присоединился';
  }

  @override
  String chatSystemUserLeft(Object name) {
    return '$name вышел';
  }

  @override
  String get chatSystemUpdate => 'Системное событие';

  @override
  String get chatAttachmentPhotoVideo => 'Фото / видео';

  @override
  String get chatAttachmentFile => 'Файл';

  @override
  String get chatLastMessagePhoto => 'Фотография';

  @override
  String get chatLastMessageVideo => 'Видео';

  @override
  String get chatAttachmentLocation => 'Локация';

  @override
  String get chatAttachmentAudio => 'Аудио';

  @override
  String get chatAttachmentTakePhoto => 'Сделать фото';

  @override
  String get chatAttachmentTakeVideo => 'Снять видео';

  @override
  String get chatAttachmentChooseFromGallery => 'Выбрать из галереи';

  @override
  String get chatAttachmentCameraTitle => 'Камера';

  @override
  String get chatAttachmentAttachTitle => 'Вложение';

  @override
  String get chatAttachmentCancel => 'Отмена';

  @override
  String get chatAttachmentVideoTooLong =>
      'Видео слишком длинное. Используйте ролик до 5 минут.';

  @override
  String get chatComposerCameraButtonLabel => 'Камера';

  @override
  String get chatComposerAttachButtonLabel => 'Прикрепить файл';

  @override
  String get chatComposerEmojiButtonLabel => 'Эмодзи и стикеры';

  @override
  String get chatComposerEmojiTab => 'Эмодзи';

  @override
  String get chatComposerStickerTab => 'Стикеры';

  @override
  String get chatStickerMessage => 'Стикер';

  @override
  String get chatStickerCreateAction => 'Создать';

  @override
  String get chatStickerCreated => 'Стикер добавлен';

  @override
  String get chatStickerCreateFailed =>
      'Не удалось создать стикер. Попробуйте еще раз.';

  @override
  String get chatStickerSendFailed =>
      'Не удалось отправить стикер. Попробуйте еще раз.';

  @override
  String get chatStickerLoadFailed => 'Не удалось загрузить ваши стикеры.';

  @override
  String get chatComposerPaste => 'Вставить';

  @override
  String get chatComposerPasteImage => 'Вставить изображение';

  @override
  String get chatClipboardEmpty => 'В буфере обмена нет данных для вставки';

  @override
  String get chatPasteImagePreviewTitle => 'Отправить вставленное изображение';

  @override
  String get chatPasteSendImage => 'Отправить фото';

  @override
  String get chatPasteSendSticker => 'Добавить как стикер';

  @override
  String get stickersTabRecent => 'Недавние';

  @override
  String get stickersSearchHint => 'Поиск стикеров';

  @override
  String get stickersEmptyRecent => 'Недавних стикеров пока нет';

  @override
  String get stickersEmptySearch => 'Стикеры не найдены';

  @override
  String get stickersLoadFailed => 'Не удалось загрузить стикеры';

  @override
  String get stickersRetry => 'Повторить';

  @override
  String get stickersOpenPicker => 'Открыть стикеры';

  @override
  String get chatStickerUnsupported =>
      'Для стикеров используйте изображение JPG, PNG или WebP.';

  @override
  String get chatStickerTooLarge =>
      'Изображение стикера слишком большое. Используйте файл до 5 МБ.';

  @override
  String get chatCameraPhotoMode => 'Фото';

  @override
  String get chatCameraVideoMode => 'Видео';

  @override
  String get chatCameraRecording => 'REC';

  @override
  String get chatCameraPermissionDenied =>
      'Для съемки медиа в чате нужен доступ к камере и микрофону.';

  @override
  String get chatCameraUnavailable => 'Камера недоступна на этом устройстве.';

  @override
  String get chatCameraCaptureFailed =>
      'Не удалось снять медиа. Попробуйте еще раз.';

  @override
  String get chatCameraFlipButtonLabel => 'Переключить камеру';

  @override
  String get chatCameraFlashOffButtonLabel => 'Вспышка выключена';

  @override
  String get chatCameraFlashAutoButtonLabel => 'Автовспышка';

  @override
  String get chatCameraFlashOnButtonLabel => 'Вспышка включена';

  @override
  String get chatCameraCloseButtonLabel => 'Закрыть камеру';

  @override
  String get chatCameraCapturePhotoButtonLabel => 'Сделать фото';

  @override
  String get chatCameraRecordVideoButtonLabel => 'Записать видео';

  @override
  String get chatCameraStopRecordingButtonLabel => 'Остановить запись';

  @override
  String get chatCameraReviewCancelButtonLabel => 'Отменить';

  @override
  String get chatCameraReviewSendButtonLabel => 'Отправить';

  @override
  String get chatCameraReviewPlayButtonLabel => 'Воспроизвести видео';

  @override
  String get chatCameraReviewPauseButtonLabel => 'Поставить видео на паузу';

  @override
  String get chatCameraReviewTrimLabel => 'Обрезка';

  @override
  String get chatCameraReviewProcessing => 'Обработка...';

  @override
  String get chatCameraTrimFailed =>
      'Не удалось обрезать это видео. Попробуйте другой диапазон или отправьте оригинал.';

  @override
  String get chatAttachmentUploading => 'Загрузка вложения...';

  @override
  String get chatAttachmentDownloading => 'Скачивание...';

  @override
  String get chatAttachmentDownloaded =>
      'Файл скачан. Нажмите еще раз, чтобы открыть.';

  @override
  String get chatAttachmentDownloadedStatus => 'Скачано';

  @override
  String get chatAttachmentNotDownloadedStatus => 'Нажмите, чтобы скачать';

  @override
  String get chatAttachmentDownloadFailed =>
      'Не удалось скачать файл. Попробуйте еще раз.';

  @override
  String get chatAttachmentOpenFailed =>
      'Не удалось открыть этот файл на устройстве.';

  @override
  String get chatAttachmentUploadFailed =>
      'Не удалось загрузить вложение. Попробуйте еще раз.';

  @override
  String get chatAttachmentUnsupported =>
      'Этот тип файла не поддерживается для вложений в чате.';

  @override
  String get chatAttachmentTooLarge =>
      'Вложение слишком большое. Используйте файл до 25 МБ.';

  @override
  String get chatComposerHint => 'Сообщение...';

  @override
  String get chatComposerClosedHint => 'Чат закрыт';

  @override
  String get chatActivityChatClosed =>
      'Чат активности теперь доступен только для чтения.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'Активность завершена. Сообщения в этот чат больше нельзя отправлять.';

  @override
  String get chatVoiceMessage => 'Голосовое сообщение';

  @override
  String get chatVoiceRecording => 'Запись голосового сообщения';

  @override
  String get chatVoiceRecordingLocked => 'Запись закреплена';

  @override
  String get chatVoicePreparingPreview => 'Готовим предпрослушивание...';

  @override
  String get chatVoicePreview => 'Предпрослушивание';

  @override
  String get chatVoiceSlideUpToLock => 'Смахните вверх, чтобы закрепить запись';

  @override
  String get chatVoiceRecordPermissionDenied =>
      'Для записи голосовых сообщений нужен доступ к микрофону.';

  @override
  String get chatVoiceRecordFailed =>
      'Не удалось записать голосовое сообщение. Попробуйте еще раз.';

  @override
  String get chatVoicePlaybackFailed =>
      'Не удалось воспроизвести это голосовое сообщение.';

  @override
  String get chatVoiceTooShort => 'Голосовое сообщение слишком короткое.';

  @override
  String get chatReactionSheetTitle => 'Реакция';

  @override
  String get chatReactionFailed =>
      'Не удалось обновить реакцию. Попробуйте еще раз.';

  @override
  String get chatCopyAction => 'Скопировать';

  @override
  String get chatForwardAction => 'Переслать';

  @override
  String get chatMessageCopied => 'Текст скопирован';

  @override
  String get chatForwardSheetTitle => 'Переслать в';

  @override
  String get chatForwardFailed =>
      'Не удалось переслать сообщение. Попробуйте еще раз.';

  @override
  String get chatForwardSuccess => 'Сообщение переслано';

  @override
  String get chatNoForwardTargets => 'Нет доступных чатов';

  @override
  String get chatForwardedLabel => 'Переслано';

  @override
  String chatForwardedFrom(Object name) {
    return 'Переслано от $name';
  }

  @override
  String chatForwardCount(Object count) {
    return 'Переслали $count';
  }

  @override
  String get chatReactionsByTitle => 'Реакции';

  @override
  String chatReactionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count реакции',
      many: '$count реакций',
      few: '$count реакции',
      one: '$count реакция',
    );
    return '$_temp0';
  }

  @override
  String get chatReadByTitle => 'Прочитали';

  @override
  String chatReadByCount(Object count) {
    return 'Прочитали: $count';
  }

  @override
  String get chatReadAtSeparator => 'в';

  @override
  String get chatNoStatusDetails => 'Деталей статуса пока нет';

  @override
  String get chatLoadFailed => 'Не удалось загрузить чат';

  @override
  String get chatParticipantsHostSection => 'ОРГАНИЗАТОР';

  @override
  String get chatParticipantsJoinedSection => 'УЧАСТНИКИ';

  @override
  String get chatParticipantHostStatus => 'организатор';

  @override
  String get chatParticipantYouStatus => 'вы';

  @override
  String get chatParticipantJoinedStatus => 'участник';

  @override
  String get chatParticipantsEmpty => 'Других участников пока нет';

  @override
  String get chatSharedMediaTab => 'Медиа';

  @override
  String get chatSharedLinksTab => 'Ссылки';

  @override
  String get chatSharedFilesTab => 'Файлы';

  @override
  String get chatSharedVoiceTab => 'Аудиосообщения';

  @override
  String get chatSharedNoMediaTitle => 'Медиа пока нет';

  @override
  String get chatSharedNoMediaSubtitle =>
      'Фото и видео из этого чата появятся здесь.';

  @override
  String get chatSharedNoLinksTitle => 'Ссылок пока нет';

  @override
  String get chatSharedNoLinksSubtitle =>
      'Сообщения со ссылками будут собраны здесь.';

  @override
  String get chatSharedNoFilesTitle => 'Файлов пока нет';

  @override
  String get chatSharedNoFilesSubtitle =>
      'Документы и архивы из этого чата появятся здесь.';

  @override
  String get chatSharedNoVoiceTitle => 'Голосовых пока нет';

  @override
  String get chatSharedNoVoiceSubtitle =>
      'Голосовые сообщения из этого чата появятся здесь.';

  @override
  String chatSharedFileFallback(Object id) {
    return 'Файл $id';
  }

  @override
  String get chatSharedUnknownFile => 'Неизвестный файл';

  @override
  String get chatSharedGoToMessageAction => 'Перейти к сообщению';

  @override
  String get chatExternalLinkTitle => 'Открыть внешнюю ссылку?';

  @override
  String chatExternalLinkMessage(Object url) {
    return 'Эта ссылка ведет на сторонний ресурс:\n$url';
  }

  @override
  String get chatExternalLinkOpenAction => 'Открыть';

  @override
  String get chatExternalLinkOpenFailed => 'Не удалось открыть эту ссылку.';

  @override
  String get chatSharedLoadFailed => 'Не удалось загрузить контент';

  @override
  String get chatSharedLoadFailedSubtitle =>
      'Проверьте подключение и попробуйте снова.';

  @override
  String get chatSharedPartialLoadWarning =>
      'Часть старых вложений не удалось загрузить.';
}
