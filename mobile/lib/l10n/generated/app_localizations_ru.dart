// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Inflap';

  @override
  String get welcomeTitle => 'Ваш персональный мир.';

  @override
  String get welcomeDescription =>
      'Оцените все возможности идеального суперприложения для путешествий, созданного для современного исследователя.';

  @override
  String get welcomeToInflap => 'Добро пожаловать в Inflap';

  @override
  String get authByPhone => 'Войти по номеру телефона';

  @override
  String get authLoginTab => 'Вход';

  @override
  String get authRegisterTab => 'Регистрация';

  @override
  String get authLoginTitle => 'Войдите в аккаунт';

  @override
  String get authRegisterTitle => 'Создайте аккаунт';

  @override
  String get authIdentifierLabel => 'Никнейм или email';

  @override
  String get authIdentifierHint => '@nomad или traveler@example.com';

  @override
  String get authIdentifierRequiredError => 'Введите никнейм или email';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'traveler@example.com';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get passwordHint => 'Минимум 8 символов';

  @override
  String get authConfirmPasswordLabel => 'Повторите пароль';

  @override
  String get authLoginAction => 'Войти';

  @override
  String get authRegisterAction => 'Зарегистрироваться';

  @override
  String get authShowPassword => 'Показать пароль';

  @override
  String get authHidePassword => 'Скрыть пароль';

  @override
  String get authLoginFailed =>
      'Не удалось войти. Проверьте данные и попробуйте снова.';

  @override
  String get authRegistrationFailed =>
      'Не удалось начать регистрацию. Проверьте данные и попробуйте снова.';

  @override
  String get authPasswordMismatchError => 'Пароли не совпадают';

  @override
  String get authForgotPasswordAction => 'Забыли пароль?';

  @override
  String get passwordResetTitle => 'Восстановление доступа';

  @override
  String get passwordResetRequestDescription =>
      'Введите email или никнейм. Если аккаунт найден, мы отправим код на привязанную почту.';

  @override
  String get passwordResetVerifyDescription =>
      'Введите код из письма и задайте новый пароль для аккаунта.';

  @override
  String get passwordResetIdentifierLabel => 'Email или никнейм';

  @override
  String get passwordResetIdentifierHint => '@nomad или traveler@example.com';

  @override
  String get passwordResetIdentifierRequiredError =>
      'Введите email или никнейм';

  @override
  String get passwordResetCodeLabel => 'Код подтверждения';

  @override
  String get passwordResetCodeHint => '6 цифр';

  @override
  String get passwordResetCodeRequiredError => 'Введите код подтверждения';

  @override
  String get passwordResetNewPasswordLabel => 'Новый пароль';

  @override
  String get passwordResetConfirmPasswordLabel => 'Повторите новый пароль';

  @override
  String get passwordResetSendCodeAction => 'Отправить код';

  @override
  String get passwordResetResendCodeAction => 'Отправить повторно';

  @override
  String passwordResetResendCodeCountdown(String time) {
    return 'Повторно через $time';
  }

  @override
  String get passwordResetSavePasswordAction => 'Сохранить пароль';

  @override
  String get passwordResetBackToLogin => 'Вернуться ко входу';

  @override
  String get passwordResetStartFailed =>
      'Не удалось отправить код восстановления. Попробуйте еще раз.';

  @override
  String get passwordResetVerifyFailed =>
      'Не удалось обновить пароль. Проверьте код и попробуйте снова.';

  @override
  String get passwordResetSentNotice =>
      'Если аккаунт найден, код отправлен на привязанную почту.';

  @override
  String get passwordResetSuccess =>
      'Пароль обновлен. Войдите с новым паролем.';

  @override
  String get emailRequiredError => 'Введите email';

  @override
  String get emailInvalidError => 'Введите корректный email';

  @override
  String get passwordRequiredError => 'Введите пароль';

  @override
  String get passwordWeakError =>
      'Пароль должен содержать минимум 8 символов, буквы и цифры';

  @override
  String get skip => 'Пропустить';

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
  String get verifyYourEmail => 'Подтвердите email';

  @override
  String get enterAuthCode =>
      'Введите 6-значный код, который мы только что отправили на номер\n';

  @override
  String get enterEmailAuthCode =>
      'Введите 6-значный код, который мы только что отправили на email\n';

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
  String get drawerStatusVerifiedGuide => 'Подтвержденный гид';

  @override
  String get drawerStatusGuide => 'Гид';

  @override
  String get drawerStatusGuideRevoked => 'Статус гида отозван';

  @override
  String get drawerStatusTraveler => 'Путешественник';

  @override
  String get drawerStatusCompleteProfile => 'Заполните профиль';

  @override
  String get profileNotAvailable => 'Профиль недоступен';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profilePhoneVerificationSection => 'Подтверждение телефона';

  @override
  String get profilePhoneVerificationTitle => 'Номер для связи';

  @override
  String get profilePhoneVerificationDescription =>
      'Подтвердите номер по SMS, чтобы мы могли защищать бронирования и важные действия.';

  @override
  String get profilePhoneVerifiedTitle => 'Телефон подтвержден';

  @override
  String get profilePhoneVerifiedDescription =>
      'Этот номер используется как доверенный контакт для важных действий.';

  @override
  String profilePhoneVerifiedAs(Object phone) {
    return 'Подтвержден: $phone';
  }

  @override
  String profilePhoneCurrentVerifiedAs(Object phone) {
    return 'Текущий номер: $phone';
  }

  @override
  String get profilePhoneSendCode => 'Отправить код';

  @override
  String profilePhoneCodeSentTo(Object phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get profilePhoneCodeHint => 'Код из SMS';

  @override
  String get profilePhoneVerifyCode => 'Подтвердить телефон';

  @override
  String get profilePhoneResendCode => 'Отправить повторно';

  @override
  String profilePhoneResendIn(Object seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get profilePhoneChangeNumber => 'Изменить номер';

  @override
  String get profilePhoneCancelChange => 'Оставить текущий номер';

  @override
  String get profilePhoneInvalid =>
      'Введите номер в международном формате, например +77011234567.';

  @override
  String get profilePhoneAlreadyVerified =>
      'Этот номер уже подтвержден. Введите другой номер.';

  @override
  String get profilePhoneUnavailable =>
      'Этот номер уже используется или недоступен.';

  @override
  String get profilePhoneCodeExpired => 'Код истек. Отправьте новый код.';

  @override
  String get profilePhoneCodeInvalid => 'Неверный код подтверждения.';

  @override
  String get profilePhoneVerificationLocked =>
      'Слишком много неверных попыток. Запросите новый код позже.';

  @override
  String get profilePhoneRateLimited =>
      'Слишком часто. Подождите перед повторной отправкой.';

  @override
  String get profilePhoneVerificationUnavailable =>
      'Подтверждение телефона временно недоступно.';

  @override
  String get profilePhoneVerificationFailed =>
      'Не удалось подтвердить телефон. Попробуйте еще раз.';

  @override
  String get profilePhoneCodeRequired => 'Введите код из SMS.';

  @override
  String get profilePhoneStartRequired =>
      'Сначала отправьте код на номер телефона.';

  @override
  String get profileFullName => 'ФИО';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Язык';

  @override
  String get profileTimezone => 'Часовой пояс';

  @override
  String get profileTimezoneSearchHint => 'Часовой пояс, город или UTC';

  @override
  String get profileTimezoneNoResults => 'Часовые пояса не найдены';

  @override
  String profileTimezoneRecommendedForCountry(Object country) {
    return 'Рекомендуется для $country';
  }

  @override
  String timeDisplayYourTime(Object time) {
    return 'Ваше время: $time';
  }

  @override
  String get profileCountry => 'Страна';

  @override
  String get profileCurrency => 'Валюта';

  @override
  String get profileCurrencySearchHint => 'Валюта, код или символ';

  @override
  String get profileCurrencyNoResults => 'Валюты не найдены';

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
      'Я понимаю, что Inflap может отклонить заявку при обнаружении недостоверной информации или неподходящих документов.';

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
  String get profileIncompleteTitle => 'Профиль заполнен не полностью';

  @override
  String get profileIncompleteDescription =>
      'Заполните никнейм, имя, фамилию и страну, чтобы пользоваться всеми возможностями Inflap';

  @override
  String get fillNowButton => 'Заполнить';

  @override
  String get appLanguageTitle => 'Язык приложения';

  @override
  String get saveProfileButton => 'Сохранить';

  @override
  String get profileSaveFailed => 'Не удалось сохранить профиль';

  @override
  String get profileNicknameTaken => 'Этот никнейм уже занят';

  @override
  String get profileNicknameOneTimeHint =>
      'Никнейм можно задать только один раз. После сохранения он не меняется.';

  @override
  String get profileNicknameChecking => 'Проверяем никнейм...';

  @override
  String get profileNicknameAvailable => 'Никнейм свободен';

  @override
  String get profileNicknameCheckFailed =>
      'Не удалось проверить никнейм. Попробуйте еще раз.';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get nicknameLabel => 'Никнейм';

  @override
  String get nicknameRequired => 'Укажите никнейм';

  @override
  String get profileNicknameLockedDescription =>
      'Никнейм можно задать только один раз. После сохранения он не меняется.';

  @override
  String get bioLabel => 'О себе';

  @override
  String get firstNameRequired => 'Укажите имя';

  @override
  String get lastNameRequired => 'Укажите фамилию';

  @override
  String get profileCountryRequired => 'Выберите страну';

  @override
  String get profileRequiredTitle => 'Заполните профиль';

  @override
  String get profileRequiredDescription =>
      'Чтобы продолжить, укажите никнейм, имя, фамилию и страну в профиле. Это помогает снизить количество фейковых аккаунтов и повышает доверие между пользователями.';

  @override
  String get myProfileTitle => 'Мой профиль';

  @override
  String get profileLinkCopied => 'Ссылка на профиль скопирована';

  @override
  String get profileVerifiedExplorer => 'ПОДТВЕРЖДЕННЫЙ ГИД';

  @override
  String get profileGuideTitle => 'Гид Inflap';

  @override
  String get profileGuideRatingLabel => 'Рейтинг гида';

  @override
  String get profileEmptyBioPlaceholder =>
      'Пока здесь нет описания. Когда профиль будет заполнен, здесь появится краткая информация о пользователе.';

  @override
  String get profileBecomeGuideTitle => 'Станьте гидом';

  @override
  String get profileBecomeGuideSubtitle =>
      'Скоро здесь можно будет подать заявку и открыть доступ к профессиональному профилю гида.';

  @override
  String get guideVerificationRevokedTitle => 'Статус гида отозван';

  @override
  String get guideVerificationRevokedSubtitle =>
      'Модерация отозвала ваш статус гида. Функции гида и публичные предложения недоступны.';

  @override
  String guideVerificationRevokedSubtitleWithReason(Object reason) {
    return 'Модерация отозвала ваш статус гида. Причина: $reason';
  }

  @override
  String get guideVerificationRevokedButton => 'Статус отозван';

  @override
  String get profileActivitiesStat => 'Активности';

  @override
  String get profileHostedCompletedStat => 'Завершено как автор';

  @override
  String get profileJoinedCompletedStat => 'Завершено как участник';

  @override
  String get profileReviewsStat => 'Отзывы';

  @override
  String get profileStoriesStat => 'Истории';

  @override
  String get profileFollowersStat => 'Фолловеры';

  @override
  String get profileFollowersTitle => 'Фолловеры';

  @override
  String get profileFollowersSearchHint => 'Фолловеры';

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
  String get profileConnectionsTitle => 'Друзья и подписки';

  @override
  String get profileConnectionsSubtitle =>
      'Управляйте друзьями и пользователями, которых вы отслеживаете.';

  @override
  String get profileConnectionsSearchHint => 'Люди';

  @override
  String get profileConnectionsFriendsTab => 'Друзья';

  @override
  String get profileConnectionsFollowingTab => 'Подписки';

  @override
  String get profileConnectionsFriendsEmptyTitle => 'Друзей пока нет';

  @override
  String get profileConnectionsFriendsEmptySubtitle =>
      'Когда заявка в друзья будет принята, пользователь появится здесь.';

  @override
  String get profileConnectionsFollowingEmptyTitle => 'Подписок пока нет';

  @override
  String get profileConnectionsFollowingEmptySubtitle =>
      'Пользователи, которых вы отслеживаете, появятся здесь.';

  @override
  String get profileConnectionsLoadFailed => 'Не удалось загрузить список';

  @override
  String get profileConnectionsSortRecent => 'Новые';

  @override
  String get profileConnectionsSortName => 'Имя';

  @override
  String get profileConnectionsFiltersTitle => 'Фильтры';

  @override
  String get profileConnectionsFiltersShowResults => 'Показать результаты';

  @override
  String get profileConnectionsFilterOnlineOnly => 'Только онлайн';

  @override
  String get profileConnectionsFilterOnlineOnlySubtitle =>
      'Показывать пользователей, которые сейчас в сети.';

  @override
  String get profileConnectionsFriendRequestsTitle => 'Запросы в друзья';

  @override
  String get profileConnectionsFriendRequestsViewAll => 'Все запросы';

  @override
  String get profileConnectionsFriendRequestsEmptyTitle => 'Запросов нет';

  @override
  String get profileConnectionsFriendRequestsEmptySubtitle =>
      'Новые входящие запросы в друзья появятся здесь.';

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
      'Защита аккаунта, экспорт данных и настройки приватности.';

  @override
  String get profileHostedActivitiesTitle => 'Активности пользователя';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Список опубликованных активностей появится здесь, когда backend отдаст публичную витрину автора.';

  @override
  String get profileRecentActivitiesTitle => 'Последние активности';

  @override
  String get profileViewAllActivities => 'Все';

  @override
  String get profileActivitiesLoadFailed => 'Не удалось загрузить активности';

  @override
  String get profileActivitiesLoadFailedHint =>
      'Проверьте подключение и попробуйте еще раз.';

  @override
  String get profileActivitiesEmptyTitle => 'Активностей пока нет';

  @override
  String get profileActivitiesEmptySubtitle =>
      'Завершенные публичные активности пользователя появятся здесь.';

  @override
  String get profileUserActivitiesTitle => 'Активности пользователя';

  @override
  String get profileUserActivitiesHostedTab => 'Проведенные';

  @override
  String get profileUserActivitiesVisitedTab => 'Посещенные';

  @override
  String get profileUserActivitiesHostedEmptyTitle =>
      'Проведенных активностей пока нет';

  @override
  String get profileUserActivitiesHostedEmptySubtitle =>
      'Когда пользователь завершит публичную активность как автор, она появится здесь.';

  @override
  String get profileUserActivitiesVisitedEmptyTitle =>
      'Посещенных активностей пока нет';

  @override
  String get profileUserActivitiesVisitedEmptySubtitle =>
      'Когда пользователь посетит публичную завершенную активность, она появится здесь.';

  @override
  String get profilePopularStoriesTitle => 'Популярные посты';

  @override
  String get profileViewAllStories => 'Все';

  @override
  String get profileStoriesLoadFailed => 'Не удалось загрузить посты';

  @override
  String get profileStoriesLoadFailedHint =>
      'Проверьте подключение и попробуйте еще раз.';

  @override
  String get profileStoriesEmptyTitle => 'Постов пока нет';

  @override
  String get profileStoriesEmptySubtitle =>
      'Опубликованные посты пользователя появятся здесь.';

  @override
  String get profileUserStoriesTitle => 'Посты пользователя';

  @override
  String get profileStoriesTitle => 'Последние посты';

  @override
  String get profileStoriesUnavailable =>
      'Публичные посты и travel-статьи пока недоступны в приложении.';

  @override
  String get profileUnavailableTitle => 'Скоро появится';

  @override
  String get profileFollowAction => 'Подписаться';

  @override
  String get profileFollowingAction => 'Вы подписаны';

  @override
  String get profileUnfollowTitle => 'Отписаться от пользователя?';

  @override
  String get profileUnfollowDescription =>
      'Вы перестанете отслеживать обновления этого пользователя в своей ленте.';

  @override
  String get profileUnfollowConfirm => 'Отписаться';

  @override
  String get profileUnfollowAction => 'Перестать отслеживать';

  @override
  String get profileFollowUpdateFailed => 'Не удалось обновить подписку';

  @override
  String get profileAddFriendAction => 'Добавить в друзья';

  @override
  String get profileFriendRequestSentAction => 'Заявка отправлена';

  @override
  String get profileFriendRequestTitle => 'Запрос в друзья';

  @override
  String get profileFriendRequestAcceptAction => 'Добавить';

  @override
  String get profileFriendRequestDeclineAction => 'Отклонить';

  @override
  String get profileAcceptFriendAction => 'Принять';

  @override
  String get profileDeclineFriendAction => 'Отклонить';

  @override
  String get profileFriendsAction => 'В друзьях';

  @override
  String get profileRemoveFriendAction => 'Удалить друга';

  @override
  String get profileRemoveFriendTitle => 'Удалить друга?';

  @override
  String get profileRemoveFriendDescription =>
      'Вы больше не сможете приглашать этого пользователя как друга, пока новая заявка не будет принята.';

  @override
  String get profileRemoveFriendConfirm => 'Удалить';

  @override
  String get profileFriendshipUpdateFailed =>
      'Не удалось обновить статус дружбы';

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
  String get profileGuideDashboardTitle => 'Кабинет гида';

  @override
  String get profileGuideDashboardSubtitle =>
      'Управляйте предложениями, бронями клиентов и проведенными экскурсиями.';

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
      'Настройте push, тихие часы и резервные каналы так, чтобы Inflap сообщал важное вовремя и не отвлекал лишним.';

  @override
  String get profileNotificationsDeliverySection => 'Push-доставка';

  @override
  String get profileNotificationsCategoriesSection => 'Категории push';

  @override
  String get profileNotificationsQuietHoursSection => 'Тихие часы';

  @override
  String get profileNotificationsChannelsSection => 'Дополнительные каналы';

  @override
  String get profileNotificationsActivitySection => 'Активности и участие';

  @override
  String get profileNotificationsDiscoverySection => 'Подборки и предложения';

  @override
  String get profileNotificationsPushTitle => 'Push-уведомления';

  @override
  String get profileNotificationsPushSubtitle =>
      'Главный переключатель push на этом устройстве. Inbox внутри приложения продолжит сохранять уведомления.';

  @override
  String get profileNotificationsPushPausedTitle => 'Push приостановлены';

  @override
  String get profileNotificationsPushPausedSubtitle =>
      'Мы не будем отправлять push на устройство, но важные события останутся в центре уведомлений приложения.';

  @override
  String get profileNotificationsPushEnabledStatus => 'Push включены';

  @override
  String get profileNotificationsPushPausedStatus => 'Push на паузе';

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
  String get profileNotificationsActivityPushTitle => 'Активности';

  @override
  String get profileNotificationsActivityPushSubtitle =>
      'Новые участники, изменения статуса, переносы и напоминания по вашим активностям.';

  @override
  String get profileNotificationsExcursionPushTitle => 'Экскурсии';

  @override
  String get profileNotificationsExcursionPushSubtitle =>
      'Бронирования, расписание, заявки, статусы публикации и события по экскурсиям.';

  @override
  String get profileNotificationsChatPushTitle => 'Сообщения';

  @override
  String get profileNotificationsChatPushSubtitle =>
      'Новые сообщения, приглашения и важные ответы в чатах.';

  @override
  String get profileNotificationsMarketingTitle => 'Подборки и спецпредложения';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Идеи для поездок, подборки мест и персональные предложения. Можно отключить без потери сервисных уведомлений.';

  @override
  String get profileNotificationsSystemTitle =>
      'Системные и безопасностные уведомления';

  @override
  String get profileNotificationsSystemSubtitle =>
      'Важные сообщения о безопасности аккаунта, платежах и доступе не отключаются в приложении.';

  @override
  String get profileNotificationsQuietHoursTitle => 'Не беспокоить';

  @override
  String profileNotificationsQuietHoursSubtitle(Object start, Object end) {
    return 'Обычные push будут тихими с $start до $end. Срочные high-priority уведомления доставим сразу.';
  }

  @override
  String get profileNotificationsQuietHoursStart => 'Начало';

  @override
  String get profileNotificationsQuietHoursEnd => 'Конец';

  @override
  String profileNotificationsQuietHoursTimezone(Object timezone) {
    return 'Используется часовой пояс профиля: $timezone';
  }

  @override
  String get profileNotificationsQuietHoursEnabledStatus =>
      'Тихие часы включены';

  @override
  String get profileNotificationsQuietHoursDisabledStatus => 'Без тихих часов';

  @override
  String get profileNotificationsPreferencesLoadFailedTitle =>
      'Не удалось загрузить push-настройки';

  @override
  String get profileNotificationsPreferencesLoadFailedSubtitle =>
      'Проверьте подключение. Email и SMS можно менять отдельно, но push-настройки временно недоступны.';

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
      'Здесь будут собраны инструменты защиты аккаунта, экспорт данных и настройки приватности.';

  @override
  String get profileSecurityAccountSection => 'Защита аккаунта';

  @override
  String get profileSecurityDataSection => 'Данные и конфиденциальность';

  @override
  String get profileSecurityPasswordTitle => 'Смена пароля';

  @override
  String get profileSecurityPasswordSubtitle =>
      'Подтвердите текущий пароль и одноразовый код с почты.';

  @override
  String get profileSecurityPasswordAction => 'Сменить';

  @override
  String get profileSecurityPasswordSheetTitle => 'Смена пароля';

  @override
  String get profileSecurityPasswordSheetSubtitle =>
      'Сначала подтвердите текущий пароль. Затем мы отправим код на привязанную почту.';

  @override
  String get profileSecurityPasswordCurrentLabel => 'Текущий пароль';

  @override
  String get profileSecurityPasswordCurrentHint => 'Введите текущий пароль';

  @override
  String get profileSecurityPasswordCodeNotice =>
      'Код отправлен на подтвержденную почту аккаунта.';

  @override
  String get profileSecurityPasswordNewLabel => 'Новый пароль';

  @override
  String get profileSecurityPasswordConfirmLabel => 'Повторите новый пароль';

  @override
  String get profileSecurityPasswordSendCode => 'Отправить код';

  @override
  String get profileSecurityPasswordSave => 'Сохранить пароль';

  @override
  String get profileSecurityPasswordSuccess => 'Пароль изменен.';

  @override
  String get profileSecurityPasswordChangeFailed =>
      'Не удалось сменить пароль. Проверьте данные и попробуйте снова.';

  @override
  String get profileSecurityPasswordMismatchError => 'Пароли не совпадают';

  @override
  String get profileSecurityPasswordUnchangedError =>
      'Новый пароль должен отличаться от текущего';

  @override
  String profileSecurityPasswordResendCodeCountdown(String time) {
    return 'Повторно через $time';
  }

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
  String get activityInviteFriendsButton => 'Пригласить друзей';

  @override
  String get activityInviteFriendsTitle => 'Пригласить друзей';

  @override
  String get activityInviteFriendsSearchHint => 'Друзья';

  @override
  String get activityInviteFriendsEmptyTitle => 'Нет друзей для приглашения';

  @override
  String get activityInviteFriendsEmptySubtitle =>
      'Добавьте друзей или попробуйте другой поиск.';

  @override
  String get activityInviteFriendsLoadFailed => 'Не удалось загрузить друзей';

  @override
  String get activityInviteFriendsRetryHint =>
      'Проверьте подключение и попробуйте еще раз.';

  @override
  String activityInviteFriendsSend(int count) {
    return 'Пригласить ($count)';
  }

  @override
  String get activityInviteFriendsSuccess => 'Приглашения отправлены';

  @override
  String get activityInviteFriendsFailed => 'Не удалось отправить приглашения';

  @override
  String get activityInviteFriendsAuthRequired =>
      'Войдите, чтобы приглашать друзей';

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
  String get activityDetailsHostFallbackName => 'Организатор Inflap';

  @override
  String get activityPaymentScreenTitle => 'INFLAP CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Сводка активности';

  @override
  String get activityPaymentBreakdownTitle => 'Состав суммы';

  @override
  String get activityPaymentMethodTitle => 'Способ оплаты';

  @override
  String get activityPaymentMockNoticeTitle => 'Тестовый checkout';

  @override
  String get activityPaymentMockNoticeBody =>
      'Реальная платежная система пока не подключена. Этот экран только имитирует успешную оплату, чтобы можно было проверить flow активности до конца.';

  @override
  String get activityPaymentSandboxMethodLabel => 'Тестовое подтверждение';

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
  String get activityPaymentCardHolderFallback => 'Участник Inflap';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return 'Подтвердить тестовую оплату $amount';
  }

  @override
  String get activityPaymentSecureNote =>
      'Безопасная оплата с 256-битным SSL-шифрованием';

  @override
  String get activityPaymentMockSecureNote =>
      'Пока включен тестовый режим, карта не будет списана.';

  @override
  String get activityPaymentPayButton => 'Тестовая оплата';

  @override
  String get activityPaymentSuccess => 'Тестовая оплата отмечена как успешная';

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
  String get participantStatusInvited => 'Приглашен';

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
  String get homeTitle => 'Inflap';

  @override
  String get homeSubtitle =>
      'Путешествуйте, находите активности и открывайте новые впечатления';

  @override
  String get servicesSectionTitle => 'Сервисы';

  @override
  String get servicesAllButton => 'Все';

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
  String get homeLocationSheetTitle => 'Выбор локации';

  @override
  String get homeLocationSelected => 'Выбранная локация';

  @override
  String get homeLocationUseCurrent => 'Использовать мою текущую локацию';

  @override
  String get homeLocationDetecting => 'Определяем локацию...';

  @override
  String get homeLocationSearchHint => 'Город';

  @override
  String get homeLocationNoResults => 'Города не найдены';

  @override
  String get homeLocationSearchFailed =>
      'Не удалось найти локации. Попробуйте ещё раз.';

  @override
  String get homeLocationDetectionFailed =>
      'Не удалось определить локацию. Проверьте разрешения геолокации и попробуйте снова.';

  @override
  String get homeLocationApply => 'Применить локацию';

  @override
  String get locationFilterCitySection => 'Город';

  @override
  String get locationFilterAllCities => 'Все города';

  @override
  String get locationFilterCitySearchHint => 'Город';

  @override
  String get locationFilterCityNoResults => 'Город не найден';

  @override
  String get cityFilterEmptyHint =>
      'Попробуйте выбрать другой город в фильтрах.';

  @override
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint => 'Активности, места, экскурсии...';

  @override
  String get homeTopDestinations => 'Топ направления';

  @override
  String get homeSeeAll => 'Смотреть все';

  @override
  String get homeTopStories => 'Сейчас обсуждают';

  @override
  String get homeSmartPostsTitle => 'Для вас';

  @override
  String get homeSmartPostsEmpty => 'Подобранные для вас посты появятся здесь.';

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
  String get homeServiceAttractions => 'Достопримечательности';

  @override
  String get homeServiceCurrencyConverter => 'Курсы валют';

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
  String get currencyConverterTitle => 'Конвертер валют';

  @override
  String get currencyConverterSubtitle =>
      'Переводите цены для поездок, не выходя из Inflap.';

  @override
  String get currencyConverterAmountLabel => 'Сумма';

  @override
  String get currencyConverterFromLabel => 'Из';

  @override
  String get currencyConverterToLabel => 'В';

  @override
  String get currencyConverterYouSend => 'Вы отправляете';

  @override
  String get currencyConverterYouReceive => 'Вы получите';

  @override
  String get currencyConverterQuickSwitch => 'Быстрый выбор';

  @override
  String get currencyConverterSelectCurrencyTitle => 'Выбор валюты';

  @override
  String get currencyConverterSearchCurrencyHint => 'Валюта';

  @override
  String get currencyConverterRecentSection => 'Недавние';

  @override
  String get currencyConverterAllCurrenciesSection => 'Все валюты';

  @override
  String get currencyConverterNoCurrenciesFound => 'Валюты не найдены';

  @override
  String get currencyConverterSwapTooltip => 'Поменять валюты местами';

  @override
  String get currencyConverterConvertButton => 'Конвертировать';

  @override
  String get currencyConverterLoading => 'Конвертируем...';

  @override
  String get currencyConverterResultTitle => 'Результат';

  @override
  String currencyConverterUpdatedAt(Object value) {
    return 'Курс обновлен $value';
  }

  @override
  String currencyConverterProvider(Object value) {
    return 'Провайдер: $value';
  }

  @override
  String get currencyConverterStaleWarning =>
      'Показан резервный справочный курс, потому что live-провайдер недоступен.';

  @override
  String get currencyConverterPopularPairs => 'Популярные пары';

  @override
  String get currencyConverterInfoNotice =>
      'Курсы справочные и могут отличаться от курса платежного провайдера при оплате.';

  @override
  String get currencyConverterAmountValidation => 'Введите корректную сумму';

  @override
  String get currencyConverterLoadFailed =>
      'Не удалось конвертировать сейчас. Проверьте соединение и попробуйте снова.';

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
  String get feedNavLabel => 'Лента';

  @override
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Карта';

  @override
  String get homeNavChats => 'Чаты';

  @override
  String get homeNavMy => 'Мои';

  @override
  String get feedTitle => 'Лента';

  @override
  String get feedTabForYou => 'Для вас';

  @override
  String get feedTabFollowing => 'Подписки';

  @override
  String get feedStoriesSectionTitle => 'Истории';

  @override
  String get feedCreateStoryAction => 'Ваша история';

  @override
  String get storyCaptureTitle => 'Добавить в историю';

  @override
  String get storyCapturePreviewTitle => 'Предпросмотр';

  @override
  String get storyCaptureCloseLabel => 'Закрыть';

  @override
  String get storyCaptureSettingsLabel => 'Настройки';

  @override
  String get storyCaptureGalleryAction => 'Галерея';

  @override
  String get storyCapturePhotoFromGallery => 'Выбрать фото';

  @override
  String get storyCaptureVideoFromGallery => 'Выбрать видео';

  @override
  String get storyCaptureCameraUnavailable =>
      'Камера недоступна. Проверьте разрешения и попробуйте снова.';

  @override
  String get storyCapturePermissionDenied =>
      'Нет доступа к камере или микрофону.';

  @override
  String get storyCaptureCaptureFailed =>
      'Не удалось снять историю. Попробуйте еще раз.';

  @override
  String get storyCaptureFlashOffLabel => 'Вспышка выключена';

  @override
  String get storyCaptureFlashAutoLabel => 'Вспышка авто';

  @override
  String get storyCaptureFlashOnLabel => 'Вспышка включена';

  @override
  String get storyCaptureFlashUnsupported =>
      'Вспышка недоступна для этой камеры.';

  @override
  String get storyCapturePhotoMode => 'Фото';

  @override
  String get storyCaptureVideoMode => 'Видео';

  @override
  String get storyCaptureCaptureButtonLabel => 'Снять фото';

  @override
  String get storyCaptureRecordButtonLabel => 'Записать видео';

  @override
  String get storyCaptureStopButtonLabel => 'Остановить запись';

  @override
  String get storyCaptureFlipCameraLabel => 'Переключить камеру';

  @override
  String get storyCaptureCaptionHint => 'Добавьте подпись...';

  @override
  String get storyCaptureRetakeAction => 'Переснять';

  @override
  String get storyCapturePublishAction => 'Опубликовать';

  @override
  String get storyCapturePublishing => 'Публикуем...';

  @override
  String get storyCapturePublishFailed =>
      'Не удалось опубликовать историю. Попробуйте еще раз.';

  @override
  String get storyReplyInputHint => 'Ответить';

  @override
  String get storyReplySendAction => 'Отправить ответ';

  @override
  String get storyReplySentMessage => 'Ответ отправлен';

  @override
  String get storyReplySendFailed =>
      'Не удалось отправить ответ. Попробуйте еще раз.';

  @override
  String get storyLikeAction => 'Нравится история';

  @override
  String get storyLikeSendFailed =>
      'Не удалось поставить лайк истории. Попробуйте еще раз.';

  @override
  String get storyCaptureDefaultTitle => 'Моя история';

  @override
  String get storyCaptureDefaultBody => 'Новая история';

  @override
  String get storyCaptureDefaultPlace => 'История';

  @override
  String get storyCapturePublishedMessage => 'История опубликована';

  @override
  String get feedSuggestedCommunitiesTitle => 'Рекомендуем подписаться';

  @override
  String get feedJoinCommunityAction => 'Подписаться';

  @override
  String get feedCommunityJoinedAction => 'Вы подписаны';

  @override
  String get feedCommunityModerationAction => 'Модерация';

  @override
  String get feedCommunityActionFailed =>
      'Не удалось обновить подписку. Попробуйте еще раз.';

  @override
  String feedCommunityMembersLabel(String count) {
    return '$count подписчиков';
  }

  @override
  String get feedMySubscriptionsTitle => 'Мои подписки';

  @override
  String feedMySubscriptionsSummary(int communities, int people) {
    return '$communities сообществ · $people людей';
  }

  @override
  String get feedMySubscriptionsViewAll => 'Смотреть все';

  @override
  String get feedMySubscriptionsCommunitiesTab => 'Сообщества';

  @override
  String get feedMySubscriptionsPeopleTab => 'Люди';

  @override
  String get feedMySubscriptionsSearchHint => 'Подписки';

  @override
  String get feedMySubscriptionsSheetSubtitle =>
      'Сообщества, друзья и люди, которых вы держите ближе в ленте.';

  @override
  String get feedMySubscriptionsFilterAll => 'Все';

  @override
  String get feedMySubscriptionsFilterStatusSection => 'Статус подписки';

  @override
  String get feedMySubscriptionsFilterPeopleSection => 'Тип связи';

  @override
  String get feedMySubscriptionsFilterCommunityActivitySection => 'Активность';

  @override
  String get feedMySubscriptionsFilterCommunityTopicSection => 'Темы';

  @override
  String get feedMySubscriptionsFilterPeopleConnectionSection => 'Связь';

  @override
  String get feedMySubscriptionsFilterPeopleActivitySection => 'Активность';

  @override
  String get feedMySubscriptionsFilterSortSection => 'Сортировка';

  @override
  String get feedMySubscriptionsFilterSubscribed => 'Подписан';

  @override
  String get feedMySubscriptionsFilterUnsubscribed => 'Отписан';

  @override
  String get feedMySubscriptionsFilterCurrentCity => 'Мой город';

  @override
  String get feedMySubscriptionsFilterActive => 'Есть посты';

  @override
  String get feedMySubscriptionsFilterPopular => 'Популярные';

  @override
  String get feedMySubscriptionsFilterFriends => 'Друзья';

  @override
  String get feedMySubscriptionsFilterFollowing => 'Подписки';

  @override
  String get feedMySubscriptionsFilterOnline => 'Онлайн';

  @override
  String get feedMySubscriptionsSortRelevant => 'Рекомендованные';

  @override
  String get feedMySubscriptionsSortMostActive => 'Самые активные';

  @override
  String get feedMySubscriptionsSortMostPopular => 'Больше подписчиков';

  @override
  String get feedMySubscriptionsSortName => 'А-Я';

  @override
  String get feedMySubscriptionsSortOnlineFirst => 'Сначала онлайн';

  @override
  String get feedPostSortRecommended => 'Рекомендованные';

  @override
  String get feedPostSortNewest => 'Новые';

  @override
  String get feedPostSortPopular => 'Популярные';

  @override
  String get feedPostSortDiscussed => 'Обсуждаемые';

  @override
  String get feedPostLikeAction => 'Нравится пост';

  @override
  String get feedPostUnlikeAction => 'Убрать лайк';

  @override
  String get feedPostShareAction => 'Поделиться постом';

  @override
  String get feedPostMoreActions => 'Действия с постом';

  @override
  String get feedPostHideAction => 'Скрыть пост';

  @override
  String get feedPostNotInterestedAction => 'Не интересно';

  @override
  String get feedPostActionFailed =>
      'Не удалось обновить пост. Попробуйте еще раз.';

  @override
  String get feedMySubscriptionsApplyFilters => 'Применить фильтры';

  @override
  String feedMySubscriptionsShowCommunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показать $count сообщества',
      many: 'Показать $count сообществ',
      few: 'Показать $count сообщества',
      one: 'Показать $count сообщество',
    );
    return '$_temp0';
  }

  @override
  String feedMySubscriptionsShowPeopleCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показать $count людей',
      many: 'Показать $count людей',
      few: 'Показать $count людей',
      one: 'Показать $count человека',
    );
    return '$_temp0';
  }

  @override
  String get feedMySubscriptionsEmptyMessage =>
      'Под эти фильтры ничего не найдено.';

  @override
  String get feedMySubscriptionsFriendBadge => 'Друг';

  @override
  String get feedMySubscriptionsFollowingBadge => 'Подписка';

  @override
  String get feedMySubscriptionsOnlineBadge => 'Онлайн';

  @override
  String get feedMySubscriptionsUnknownPerson => 'Пользователь';

  @override
  String get feedSystemPostsTitle => 'Официальные новости';

  @override
  String get feedSystemPostsViewAll => 'Смотреть все';

  @override
  String get feedSystemPostsSheetTitle => 'Официальные посты';

  @override
  String get communityDiscoveryTitle => 'Сообщества';

  @override
  String get communityDiscoveryEmptyTitle => 'Сообществ пока нет';

  @override
  String get communityDiscoveryEmptyMessage =>
      'Официальные сообщества появятся здесь после запуска.';

  @override
  String get communityDiscoveryLoadFailedTitle =>
      'Не удалось загрузить сообщества';

  @override
  String get communityDiscoveryLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get communityDiscoverySearchHint => 'Сообщества';

  @override
  String get communityDiscoveryFiltersTitle => 'Фильтры';

  @override
  String get communityDiscoveryShowResults => 'Показать сообщества';

  @override
  String communityDiscoveryShowResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщества',
      many: '$count сообществ',
      few: '$count сообщества',
      one: '$count сообщество',
      zero: '0 сообществ',
    );
    return 'Показать $_temp0';
  }

  @override
  String get communityDiscoveryRequiredLocationMessage =>
      'Выберите страну и город, чтобы найти активные локальные сообщества.';

  @override
  String get communityDiscoveryTopicSection => 'Тип сообщества';

  @override
  String get communityDiscoveryTopicAll => 'Все';

  @override
  String get communityDiscoveryTopicTravel => 'Путешествия';

  @override
  String get communityDiscoveryTopicCity => 'Города';

  @override
  String get communityDiscoveryTopicGuides => 'Гиды и туры';

  @override
  String get communityDiscoveryTopicAppNews => 'Новости Inflap';

  @override
  String get communityTopicLanguages => 'Языки';

  @override
  String get communityTopicHousing => 'Жилье';

  @override
  String get communityTopicTransport => 'Транспорт';

  @override
  String get communityTopicSports => 'Спорт';

  @override
  String get communityTopicOutdoor => 'Поездки и природа';

  @override
  String get communityTopicHobbies => 'Хобби и мастер-классы';

  @override
  String get communityTopicWellness => 'Здоровье и wellness';

  @override
  String get communityTopicPets => 'Питомцы';

  @override
  String get communityTopicCityLife => 'Городская жизнь';

  @override
  String get communityTopicContent => 'Новости и гайды';

  @override
  String get communityTopicFamily => 'Семьи';

  @override
  String get communityTopicGeneral => 'Общее';

  @override
  String get communityProfileTitle => 'Сообщество';

  @override
  String get communityProfileActionsTooltip => 'Действия сообщества';

  @override
  String get communityProfileCreatePostAction => 'Создать пост';

  @override
  String get communityPostModeSelectorLabel => 'Режим публикации';

  @override
  String get communityPostModeArticle => 'Посты';

  @override
  String get communityPostModeQuickPost => 'Обсуждения';

  @override
  String get communityPostModeListing => 'Объявления';

  @override
  String get communityPostModeEventAnnouncement => 'Афиша';

  @override
  String get communityPostModeQuestionAnswer => 'Вопросы';

  @override
  String get communityPostModeTripPlan => 'Поездки';

  @override
  String get communityProfileUnfollowConfirmTitle =>
      'Отписаться от сообщества?';

  @override
  String get communityProfileRulesTitle => 'Правила сообщества';

  @override
  String get communityProfilePostsSectionTitle => 'Посты';

  @override
  String get communityProfileNoPostsTitle => 'Постов пока нет';

  @override
  String get communityProfileNoPostsMessage =>
      'Здесь появятся новые посты этого сообщества.';

  @override
  String get communityProfilePostsLoadFailedTitle =>
      'Не удалось загрузить посты';

  @override
  String communityProfilePostsLabel(String count) {
    return '$count постов';
  }

  @override
  String get communityProfileLoadFailedTitle =>
      'Не удалось загрузить сообщество';

  @override
  String get communityProfileLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get communityTrustReportAction => 'Пожаловаться на сообщество';

  @override
  String get communityTrustMuteAction => 'Скрыть сообщество';

  @override
  String get communityTrustUnmuteAction => 'Вернуть сообщество';

  @override
  String get communityTrustBlockedTitle => 'Публикация заблокирована';

  @override
  String get communityTrustBlockedMessage =>
      'Вы не можете публиковать посты в этом сообществе, пока модераторы не снимут ограничение.';

  @override
  String get communityTrustMutedTitle => 'Сообщество скрыто';

  @override
  String get communityTrustMutedMessage =>
      'Это сообщество скрыто из вашей ленты. Его можно вернуть в любой момент.';

  @override
  String get communityTrustAppealPendingTitle => 'Апелляция на проверке';

  @override
  String get communityTrustAppealPendingMessage =>
      'Модераторы рассматривают вашу апелляцию по этому сообществу.';

  @override
  String get communityTrustAppealRejectedTitle => 'Апелляция отклонена';

  @override
  String get communityTrustAppealRejectedMessage =>
      'Ограничение остается активным после проверки модераторами.';

  @override
  String get communityTrustAppealAction => 'Апелляция';

  @override
  String get communityTrustAppealMessage =>
      'Пожалуйста, пересмотрите мое ограничение в сообществе.';

  @override
  String get communityTrustReportSubmitted =>
      'Сообщество отправлено на модерацию.';

  @override
  String get communityTrustMutedSubmitted => 'Сообщество скрыто.';

  @override
  String get communityTrustUnmutedSubmitted => 'Сообщество возвращено.';

  @override
  String get communityTrustAppealSubmitted =>
      'Апелляция отправлена модераторам.';

  @override
  String get communityTrustActionUnavailable =>
      'Это trust-действие пока недоступно.';

  @override
  String get communityTrustActionFailed =>
      'Не удалось выполнить trust-действие. Попробуйте еще раз.';

  @override
  String get feedEmptyTitle => 'В ленте пока пусто';

  @override
  String get feedEmptyMessage =>
      'Подпишитесь на путешественников и сообщества, чтобы собрать свою ленту.';

  @override
  String get feedLoadFailedTitle => 'Не удалось загрузить ленту';

  @override
  String get feedLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get feedRetryAction => 'Повторить';

  @override
  String get communityModerationTitle => 'Очередь модерации';

  @override
  String communityModerationSubtitle(int count) {
    return '$count на проверке';
  }

  @override
  String get communityModerationEmptyTitle => 'Постов на проверке нет';

  @override
  String get communityModerationEmptyMessage =>
      'Новые посты сообщества, которым нужна проверка, появятся здесь.';

  @override
  String get communityModerationLoadFailedTitle =>
      'Не удалось загрузить очередь модерации';

  @override
  String get communityModerationLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get communityModerationApproveAction => 'Одобрить';

  @override
  String get communityModerationRejectAction => 'Отклонить';

  @override
  String get communityModerationHistoryAction => 'История';

  @override
  String get communityModerationApprovedMessage => 'Пост одобрен';

  @override
  String get communityModerationRejectedMessage => 'Пост отклонен';

  @override
  String get communityModerationActionFailed =>
      'Не удалось обновить пост. Попробуйте еще раз.';

  @override
  String get communityModerationDecisionHistoryTitle => 'История решений';

  @override
  String get communityModerationDecisionHistoryEmpty =>
      'Решений по модерации пока нет.';

  @override
  String get communityModerationDecisionHistoryFailed =>
      'Не удалось загрузить историю решений.';

  @override
  String get communityModerationRejectReasonLabel => 'Причина отклонения';

  @override
  String get communityModerationRejectConfirmAction => 'Отклонить пост';

  @override
  String get communityModerationRejectCancelAction => 'Отмена';

  @override
  String get communityMembersTitle => 'Участники';

  @override
  String get communityMembersSubtitle => 'Управление доступом и ролями';

  @override
  String get communityMembersAction => 'Участники';

  @override
  String get communityMembersEmptyTitle => 'Участники не найдены';

  @override
  String get communityMembersEmptyMessage =>
      'Участники по выбранным фильтрам появятся здесь.';

  @override
  String get communityMembersLoadFailedTitle =>
      'Не удалось загрузить участников';

  @override
  String get communityMembersLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get communityMembersRoleFilterLabel => 'Роль';

  @override
  String get communityMembersStatusFilterLabel => 'Статус';

  @override
  String get communityMembersAllFilter => 'Все';

  @override
  String get communityMembersActiveStatus => 'Активные';

  @override
  String get communityMembersMutedStatus => 'Ограниченные';

  @override
  String get communityMembersBannedStatus => 'Заблокированные';

  @override
  String get communityMembersLeftStatus => 'Покинувшие';

  @override
  String get communityMembersTrustedRole => 'Доверенный участник';

  @override
  String get communityMembersModeratorRole => 'Модератор';

  @override
  String get communityMembersAdminRole => 'Админ';

  @override
  String get communityMembersMemberRole => 'Участник';

  @override
  String get communityMembersChangeRoleAction => 'Изменить роль';

  @override
  String get communityMembersRoleHistoryAction => 'История ролей';

  @override
  String get communityMembersRoleHistoryTitle => 'История ролей';

  @override
  String get communityMembersRoleHistoryChangedBy => 'Изменил';

  @override
  String get communityMembersRoleHistoryEmptyTitle => 'Изменений ролей нет';

  @override
  String get communityMembersRoleHistoryEmptyMessage =>
      'Обновления ролей этого участника появятся здесь.';

  @override
  String get communityMembersRoleHistoryLoadFailedTitle =>
      'Не удалось загрузить историю ролей';

  @override
  String get communityMembersRoleHistoryLoadFailedMessage =>
      'Проверьте соединение и попробуйте снова.';

  @override
  String get communityMembersChangeStatusAction => 'Изменить статус';

  @override
  String get communityMembersMuteAction => 'Ограничить участника';

  @override
  String get communityMembersBanAction => 'Заблокировать участника';

  @override
  String get communityMembersRemoveAction => 'Удалить участника';

  @override
  String get communityMembersRestoreAction => 'Восстановить участника';

  @override
  String get communityMembersStatusUpdatedMessage => 'Статус обновлен';

  @override
  String get communityMembersStatusUpdateFailed =>
      'Не удалось обновить статус участника. Попробуйте еще раз.';

  @override
  String get communityMembersRoleUpdatedMessage => 'Роль обновлена';

  @override
  String get communityMembersRoleUpdateFailed =>
      'Не удалось обновить участника. Попробуйте еще раз.';

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
  String get mapDistancePending => 'Определяем расстояние';

  @override
  String mapPlacesCount(int count) {
    return 'Найдено мест: $count';
  }

  @override
  String mapActivitiesCount(int count) {
    return 'Активностей: $count';
  }

  @override
  String get mapTapActivityHint =>
      'Нажмите на маркер активности, чтобы посмотреть краткую информацию и открыть детали.';

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
  String get attractionsNoResultsSubtitle =>
      'Попробуйте выбрать другой город в фильтрах.';

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
  String get attractionFilterCategoryArchitecture => 'Архитектура';

  @override
  String get attractionFilterCategoryBeach => 'Пляж';

  @override
  String get attractionFilterCategoryTemple => 'Храмы';

  @override
  String get attractionFilterCategoryEntertainment => 'Развлечения';

  @override
  String get attractionFilterCategoryFood => 'Еда';

  @override
  String get attractionFilterCategoryMarket => 'Рынок';

  @override
  String get attractionFilterCategoryShopping => 'Шопинг';

  @override
  String get attractionFilterCategoryOther => 'Другое';

  @override
  String get attractionFilterCategoryHistory => 'История';

  @override
  String get attractionFilterCategoryAdventure => 'Приключения';

  @override
  String get attractionFilterCountrySection => 'Страна';

  @override
  String get attractionFilterCountryAll => 'Все страны';

  @override
  String get attractionFilterCountrySearchHint => 'Страна, код или телефон';

  @override
  String get attractionFilterCountryNoResults => 'Страна не найдена';

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
  String get attractionInflapTipTitle => 'Совет Inflap';

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
  String get profileGuideReviewsTitle => 'Лучшие отзывы об экскурсиях';

  @override
  String get profileGuideReviewsLatestTitle => 'Последние отзывы об экскурсиях';

  @override
  String get profileDirectGuideReviewsTitle => 'Рейтинг гида';

  @override
  String get profileActivityOrganizerReviewsTitle =>
      'Рейтинг организатора активностей';

  @override
  String get profileActivityReviewsTitle => 'Отзывы об активностях';

  @override
  String get profileGuideReviewsEmptyTitle => 'Отзывов пока нет';

  @override
  String get profileGuideReviewsEmpty =>
      'Отзывы появятся здесь после того, как путешественники оценят проведенные экскурсии.';

  @override
  String get profileDirectGuideReviewsEmpty =>
      'Прямые отзывы о гиде появятся здесь после отдельных оценок путешественников.';

  @override
  String get profileActivityOrganizerReviewsEmpty =>
      'Отзывы об организаторе появятся здесь после оценок участников завершенных активностей.';

  @override
  String get profileActivityReviewsEmpty =>
      'Отзывы об активностях появятся здесь после оценок участников завершенных активностей.';

  @override
  String get profileGuideReviewsLoadFailed => 'Не удалось загрузить отзывы';

  @override
  String get profileGuideReviewsLoadFailedHint =>
      'Потяните для обновления или откройте профиль снова.';

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
  String get excursionsSearchHint => 'Экскурсии и впечатления';

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
  String get excursionsFilterCountrySearchHint => 'Страна, код или телефон';

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
  String get excursionsFilterLanguageAll => 'Все языки';

  @override
  String get excursionsFilterLanguageSearchHint => 'Язык или код';

  @override
  String get excursionsFilterLanguageNoResults => 'Язык не найден';

  @override
  String get excursionsLoadFailed => 'Не удалось загрузить экскурсии';

  @override
  String get excursionsEmptyTitle => 'Экскурсий пока нет';

  @override
  String get excursionsEmptySubtitle =>
      'Здесь появятся маршруты проверенных гидов. Попробуйте выбрать другой город в фильтрах.';

  @override
  String get excursionsEmptySearchSubtitle =>
      'Попробуйте другой город, категорию или название экскурсии.';

  @override
  String get excursionsNoAttractionExcursionsTitle =>
      'Экскурсий по этой достопримечательности пока нет';

  @override
  String get excursionsNoAttractionExcursionsSubtitle =>
      'Показываем другие доступные экскурсии. Как только гиды добавят маршрут по этой достопримечательности, он появится здесь.';

  @override
  String get guidesTitle => 'Гиды';

  @override
  String get guidesSearchHint => 'Гиды';

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
  String get guidesClearSearch => 'Очистить поиск';

  @override
  String get guidesFilterCountry => 'Страна';

  @override
  String get guidesFilterCountryAll => 'Все страны';

  @override
  String get guidesFilterCountrySearchHint => 'Страна, код или телефон';

  @override
  String get guidesFilterCountryNoResults => 'Страна не найдена';

  @override
  String get guidesFilterExpertise => 'Экспертиза';

  @override
  String get guidesFilterLanguage => 'Язык';

  @override
  String get guidesFilterLanguageAll => 'Все языки';

  @override
  String get guidesFilterLanguageSearchHint => 'Язык или код';

  @override
  String get guidesFilterLanguageNoResults => 'Язык не найден';

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
      'Здесь появятся проверенные локальные эксперты. Попробуйте выбрать другой город в фильтрах.';

  @override
  String get guidesNoResultsTitle => 'Гиды не найдены';

  @override
  String get guidesNoResultsSubtitle =>
      'Попробуйте другой город, имя, специализацию, язык или фильтр.';

  @override
  String get guidesRatingNew => 'Новый гид';

  @override
  String guidesReviewsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отзыва',
      many: '$count отзывов',
      few: '$count отзыва',
      one: '$count отзыв',
    );
    return '$_temp0';
  }

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
  String get excursionDetailsOffersSearchHint => 'Гиды и предложения';

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
  String get excursionDetailsOffersAvailableDate => 'Доступная дата';

  @override
  String get excursionDetailsOffersAvailableDateHint => 'дд.мм.гггг';

  @override
  String get excursionDetailsOffersAvailableDateInvalid =>
      'Введите дату в формате дд.мм.гггг';

  @override
  String get excursionDetailsOffersMinGroup => 'Мин. размер группы';

  @override
  String get excursionDetailsOffersMinGroupHint => 'Например, 4';

  @override
  String get excursionDetailsOffersLanguageAny => 'Любой язык';

  @override
  String get excursionDetailsOffersLanguageSearchHint => 'Язык или код';

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
  String get excursionDetailsBookingSeatCheckNote =>
      'Точное число мест проверим на экране бронирования.';

  @override
  String get excursionDetailsCheckingSchedule => 'Проверяем доступное время...';

  @override
  String get excursionDetailsNoAvailableSlots =>
      'У этого гида пока нет доступных слотов для этой экскурсии.';

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
  String get excursionBookingConfirmReservation => 'Подтвердить бронь';

  @override
  String excursionBookingPaymentPendingNote(Object amount) {
    return 'Сейчас оплата не списывается. Онлайн-оплата появится после подключения. Итого: $amount';
  }

  @override
  String get excursionBookingSubmitted =>
      'Бронь подтверждена. Онлайн-оплата будет подключена скоро.';

  @override
  String get excursionBookingAlreadyBookedTitle =>
      'Вы уже забронировали это время';

  @override
  String get excursionBookingAlreadyBookedMessage =>
      'Изменить количество гостей можно в разделе «Мои экскурсии».';

  @override
  String get excursionBookingOpenMyExcursions => 'Открыть Мои экскурсии';

  @override
  String get excursionBookingLoadFailed =>
      'Не удалось загрузить бронирование экскурсии';

  @override
  String get excursionBookingPerPerson => '/ чел.';

  @override
  String get excursionBookingSelectSlot => 'Выберите доступное время';

  @override
  String excursionBookingSelectedSlotUnavailable(Object count) {
    return 'Выбранное время больше недоступно для $count гостей. Выберите другое время.';
  }

  @override
  String get excursionBookingScheduleLoadFailed =>
      'Не удалось загрузить доступное время';

  @override
  String get excursionBookingNoSlots =>
      'Гид пока не добавил доступное время для этого предложения.';

  @override
  String excursionBookingSeatsLeft(Object count) {
    return 'Осталось мест: $count';
  }

  @override
  String get excursionDetailsNoDescription =>
      'Гид скоро добавит подробное описание.';

  @override
  String excursionDetailsRouteStopsCount(Object count) {
    return 'Остановок: $count';
  }

  @override
  String excursionDetailsTravelFromPrevious(Object minutes) {
    return '$minutes мин от предыдущей остановки';
  }

  @override
  String get createExcursionTitle => 'Создать экскурсию';

  @override
  String get createExcursionEditTitle => 'Редактировать предложение';

  @override
  String get createExcursionSubmit => 'Отправить на проверку';

  @override
  String get createExcursionSaveDraft => 'Сохранить черновик';

  @override
  String get createExcursionSaveChanges => 'Сохранить';

  @override
  String get createExcursionSuccess => 'Экскурсия отправлена на проверку';

  @override
  String get createExcursionDraftSaved => 'Черновик сохранен';

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
  String get createExcursionSingleAttractionMode =>
      'Одна достопримечательность';

  @override
  String get createExcursionCombinedRouteMode => 'Составной маршрут';

  @override
  String createExcursionCombinedRouteMinStopsValidation(Object count) {
    return 'Добавьте минимум $count остановки с достопримечательностями';
  }

  @override
  String createExcursionCombinedRouteMaxStopsValidation(Object count) {
    return 'Добавьте не больше $count остановок с достопримечательностями';
  }

  @override
  String get createExcursionDuplicateRouteStopValidation =>
      'Эта достопримечательность уже есть в маршруте.';

  @override
  String get excursionSelectLocationTitle => 'Выбор локации';

  @override
  String get excursionSelectLocationCountrySection => 'Выберите страну';

  @override
  String get excursionSelectLocationCountrySearchHint => 'Страны';

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
      'Достопримечательности';

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
  String get createExcursionEditTimeSlot => 'Редактировать слот';

  @override
  String get createExcursionItineraryEmpty =>
      'Добавьте минимум два пункта маршрута. Они будут показаны туристам в деталях экскурсии.';

  @override
  String get createExcursionAutosaveHint =>
      'Прогресс сохраняется локально, пока вы создаете предложение';

  @override
  String get createExcursionAutosaveRestored =>
      'Локальный черновик восстановлен';

  @override
  String get createExcursionDiscardTitle => 'Выйти без сохранения?';

  @override
  String get createExcursionDiscardDescription =>
      'Данные черновика экскурсии будут потеряны. При следующем входе форма откроется пустой.';

  @override
  String get createExcursionDiscardConfirm => 'Выйти и очистить';

  @override
  String get createExcursionModeSwitchTitle => 'Сменить тип маршрута?';

  @override
  String get createExcursionModeSwitchDescription =>
      'Данные текущего варианта будут очищены. Остальные детали экскурсии останутся.';

  @override
  String get createExcursionModeSwitchCancel => 'Остаться';

  @override
  String get createExcursionModeSwitchConfirm => 'Сменить и очистить';

  @override
  String get createExcursionItineraryValidation =>
      'Заполните время, название и описание пункта маршрута';

  @override
  String createExcursionItineraryMinSlotsValidation(Object count) {
    return 'Добавьте минимум $count пункта маршрута';
  }

  @override
  String createExcursionItineraryDescriptionMinLengthValidation(Object count) {
    return 'Описание пункта маршрута должно быть не короче $count символов';
  }

  @override
  String get createExcursionStartOffsetValidation =>
      'Укажите время начала пункта маршрута';

  @override
  String get createExcursionItineraryTitleValidation =>
      'Название пункта маршрута должно быть не короче 2 символов';

  @override
  String createExcursionOffsetMinutesShort(Object minutes) {
    return '+$minutes мин';
  }

  @override
  String createExcursionOffsetHoursShort(Object hours) {
    return '+$hours ч';
  }

  @override
  String createExcursionOffsetHoursMinutesShort(Object hours, Object minutes) {
    return '+$hours ч $minutes мин';
  }

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
  String get createExcursionLanguagesSearchHint => 'Язык или код';

  @override
  String get createExcursionLanguagesNoResults => 'Язык не найден';

  @override
  String createExcursionLanguagesLimitValidation(Object count) {
    return 'Можно выбрать до $count языков';
  }

  @override
  String get createExcursionVisibilityTitle => 'Видимость экскурсии';

  @override
  String get createExcursionVisibilityPublicDescription =>
      'Виден всем пользователям маркетплейса Inflap.';

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
  String get createActivityDiscardTitle => 'Выйти без сохранения?';

  @override
  String get createActivityDiscardDescription =>
      'Изменения в черновике активности будут потеряны.';

  @override
  String get createActivityDiscardConfirm => 'Выйти';

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
  String get createSubcategoryLabel => 'Подкатегория';

  @override
  String get createSubcategoryHint => 'Выберите подкатегорию';

  @override
  String get createSubcategoryPickerTitle => 'Выберите подкатегорию';

  @override
  String get createSubcategoryApply => 'Применить';

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
      'Видно всем пользователям Inflap';

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
  String get createVisibilityPasswordAsciiValidation =>
      'Используйте только английские буквы, цифры и символы';

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
  String get createAllowParticipantInvitesLabel =>
      'Разрешить участникам приглашать друзей';

  @override
  String get createAllowParticipantInvitesHint =>
      'Автор активности всегда может приглашать своих друзей. Другие пользователи смогут приглашать только своих друзей, если эта опция включена.';

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
  String get createMapLinkInvalidError =>
      'Не удалось определить координаты по ссылке. Выберите точку на нашей карте или вставьте ссылку с координатами из другой карты.';

  @override
  String get createMapLinkResolvingError =>
      'Определяем координаты по ссылке. Подождите несколько секунд.';

  @override
  String get createMapLinkRequiredError =>
      'Добавьте ссылку на карту или выберите точку на нашей карте.';

  @override
  String get createMapEarlyStageNotice =>
      'Карта в приложении пока на ранней стадии: вставьте ссылку из другой карты или поставьте точку на нашей карте. Скоро мы улучшим карту, чтобы выбирать точку встречи прямо здесь без перехода в другие карты.';

  @override
  String get createOfflineSection => 'МЕСТО ПРОВЕДЕНИЯ';

  @override
  String get createLocationPreviewHint =>
      'Добавьте город или адрес, чтобы участники понимали, где встречаться';

  @override
  String get createAuthorLocationMismatchHint =>
      'Локация встречи отличается от вашей текущей локации. Оставьте так, если активность запланирована в другом месте.';

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
      'Адрес встречи можно изменить не позднее чем за час до начала активности';

  @override
  String get editPriceRestrictionHint =>
      'Цену нельзя изменить, если записались другие участники';

  @override
  String get myActivitiesTitle => 'Мои активности';

  @override
  String get myStoriesTitle => 'Мои посты';

  @override
  String get myStoryArchiveTitle => 'Мои истории';

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
  String get myActivitiesRetryButton => 'Повторить';

  @override
  String get myActivitiesPriceNoteFree => 'без оплаты';

  @override
  String get myExcursionsTitle => 'Мои экскурсии';

  @override
  String get myExcursionsSearchHint => 'Экскурсии, гиды и города';

  @override
  String get myExcursionsFilterTitle => 'Фильтры экскурсий';

  @override
  String get myExcursionsReviewSuccess => 'Отзыв опубликован';

  @override
  String get myExcursionsSortLabel => 'Сортировка';

  @override
  String get myExcursionsSortDate => 'По дате';

  @override
  String get myExcursionsSortPrice => 'По цене';

  @override
  String get myExcursionsLoadFailed => 'Не удалось загрузить ваши экскурсии';

  @override
  String get myExcursionsBookedEmpty =>
      'У вас пока нет забронированных экскурсий';

  @override
  String get myExcursionsVisitedEmpty => 'Вы пока не посещали экскурсии';

  @override
  String get myExcursionsBookedEmptyHint =>
      'Забронированные экскурсии появятся здесь';

  @override
  String get myExcursionsVisitedEmptyHint =>
      'После посещения экскурсии вы сможете оставить отзыв';

  @override
  String get myExcursionsBookedTab => 'Забронированные';

  @override
  String get myExcursionsVisitedTab => 'Посещенные';

  @override
  String get myExcursionsGuideFallback => 'Гид Inflap';

  @override
  String get myExcursionsUntitled => 'Экскурсия';

  @override
  String myExcursionsGuideLine(Object guide) {
    return 'Гид: $guide';
  }

  @override
  String myExcursionsGuests(Object count) {
    return 'Гостей: $count';
  }

  @override
  String get myExcursionsReviewButton => 'Оценить';

  @override
  String get myExcursionsReviewed => 'Оценено';

  @override
  String get myExcursionsEditGuestsButton => 'Изменить гостей';

  @override
  String get myExcursionsEditGuestsTitle => 'Изменить количество гостей';

  @override
  String get myExcursionsEditGuestsHint =>
      'Мы проверим доступные места и обновим бронь без повторного создания.';

  @override
  String get myExcursionsUpdateGuestsSuccess => 'Количество гостей обновлено';

  @override
  String get myExcursionsUpdateGuestsFailed =>
      'Не удалось обновить количество гостей. Проверьте доступные места и попробуйте снова.';

  @override
  String myExcursionsGuestsAdditionalCharge(Object amount) {
    return 'К доплате: $amount';
  }

  @override
  String myExcursionsGuestsRefundDue(Object amount) {
    return 'К возврату: $amount';
  }

  @override
  String get myExcursionsGuestsNoPaymentChange => 'Стоимость не изменится';

  @override
  String get myExcursionsGuestsPaymentQuoteHint =>
      'Расчет выполнен на сервере. Реальная доплата или возврат подключатся через платежный сервис.';

  @override
  String get myExcursionsGuestsQuoteLoading => 'Считаем изменение стоимости...';

  @override
  String get myExcursionsGuestsQuoteFailed =>
      'Не удалось рассчитать изменение стоимости. Проверьте доступные места и попробуйте снова.';

  @override
  String get myExcursionsPayAndSaveGuests => 'Доплатить и сохранить';

  @override
  String get myExcursionsRefundAndSaveGuests => 'Вернуть и сохранить';

  @override
  String get myExcursionsCancelBookingButton => 'Отменить бронь';

  @override
  String get myExcursionsCancelBookingTitle => 'Отменить бронь?';

  @override
  String get myExcursionsCancelBookingHint =>
      'Мы отменим ваше место и покажем гиду, что бронь отменена вами.';

  @override
  String get myExcursionsCancelQuoteLoading => 'Считаем условия возврата...';

  @override
  String get myExcursionsCancelQuoteFailed =>
      'Не удалось рассчитать условия возврата. Попробуйте еще раз.';

  @override
  String myExcursionsCancelBookingRefund(Object amount, int percent) {
    return 'К возврату: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelBookingNoRefund => 'Возврат недоступен';

  @override
  String get myExcursionsCancelBookingRefundHint =>
      'Итоговую сумму возврата зафиксирует сервер. Реальный возврат средств будет подключен через платежный сервис.';

  @override
  String get myExcursionsCancelPolicyTitle => 'Правила отмены';

  @override
  String get myExcursionsCancelPolicyFull => 'За 24+ часа до начала: 100%';

  @override
  String get myExcursionsCancelPolicySeventyFive =>
      'За 12-24 часа до начала: 75%';

  @override
  String get myExcursionsCancelPolicyHalf => 'За 6-12 часов до начала: 50%';

  @override
  String get myExcursionsCancelPolicyQuarter => 'За 2-6 часов до начала: 25%';

  @override
  String get myExcursionsCancelPolicyZero =>
      'Менее чем за 2 часа до начала: 0%';

  @override
  String get myExcursionsCancelBookingReasonLabel => 'Причина (необязательно)';

  @override
  String get myExcursionsCancelBookingReasonPlaceholder =>
      'Например: изменились планы';

  @override
  String get myExcursionsCancelBookingConfirm => 'Отменить бронь';

  @override
  String get myExcursionsCancelBookingSuccess => 'Бронь отменена';

  @override
  String get myExcursionsCancelBookingFailed => 'Не удалось отменить бронь';

  @override
  String myExcursionsCancelledWithRefund(Object amount, int percent) {
    return 'Отменено. К возврату: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelledWithoutRefund => 'Отменено без возврата';

  @override
  String get myExcursionsFilterStatus => 'Статус';

  @override
  String get myExcursionsStatusRequested => 'Забронировано';

  @override
  String get myExcursionsFilterReview => 'Отзывы';

  @override
  String get myExcursionsFilterReviewAll => 'Все';

  @override
  String get myExcursionsFilterUnreviewed => 'Без отзыва';

  @override
  String get myExcursionsFilterReviewed => 'С отзывом';

  @override
  String get myExcursionsReviewTitle => 'Оцените экскурсию';

  @override
  String get myExcursionsReviewCommentError => 'Напишите короткий отзыв';

  @override
  String get myExcursionsReviewFailed => 'Не удалось опубликовать отзыв';

  @override
  String get myExcursionsReviewDeleteFailed => 'Не удалось удалить отзыв';

  @override
  String get myExcursionsReviewRating => 'Оценка';

  @override
  String get myExcursionsReviewHint => 'Что понравилось, что можно улучшить?';

  @override
  String get myExcursionsExcursionReviewSectionTitle => 'Отзыв об экскурсии';

  @override
  String get myExcursionsExcursionReviewSectionSubtitle =>
      'Оцените маршрут, организацию и общее впечатление.';

  @override
  String get myExcursionsExcursionReviewOptional =>
      'Выключите, если хотите оценить только гида.';

  @override
  String get myExcursionsGuideReviewSectionTitle => 'Отзыв о гиде';

  @override
  String get myExcursionsGuideReviewSectionSubtitle =>
      'При желании оцените гида отдельно для будущих путешественников.';

  @override
  String get myExcursionsGuideReviewRating => 'Оценка гида';

  @override
  String get myExcursionsGuideReviewHint =>
      'Как гид общался, заботился о группе и рассказывал истории?';

  @override
  String get myExcursionsGuideReviewOptional =>
      'Необязательно, но помогает гиду развивать доверенный профиль.';

  @override
  String get myExcursionsReviewSelectOneError =>
      'Выберите хотя бы один отзыв для публикации';

  @override
  String get myExcursionsReviewDeleteExcursion => 'Удалить отзыв об экскурсии';

  @override
  String get myExcursionsReviewDeleteGuide => 'Удалить отзыв о гиде';

  @override
  String get myExcursionsReviewPublish => 'Опубликовать';

  @override
  String get excursionReviewActionsTitle => 'Действия с отзывом';

  @override
  String get excursionReviewEditAction => 'Редактировать отзыв';

  @override
  String get excursionReviewDeleteAction => 'Удалить отзыв';

  @override
  String get excursionReviewEditTitle => 'Редактировать отзыв';

  @override
  String get excursionReviewEditSave => 'Сохранить отзыв';

  @override
  String get excursionReviewUpdated => 'Отзыв обновлен';

  @override
  String get excursionReviewDeleted => 'Отзыв удален';

  @override
  String get guideDashboardTitle => 'Кабинет гида';

  @override
  String get guideDashboardReviewsTitle => 'Отзывы';

  @override
  String get guideDashboardExcursionReviewsTab => 'Экскурсии';

  @override
  String get guideDashboardDirectGuideReviewsTab => 'Гид';

  @override
  String get guideDashboardOffersStat => 'Всего предложений';

  @override
  String get guideDashboardBookingsStat => 'Брони';

  @override
  String get guideDashboardRevenueStat => 'Выручка';

  @override
  String get guideDashboardRatingStat => 'Рейтинг';

  @override
  String get guideDashboardSearchHint => 'Предложения, гости, города и даты';

  @override
  String get guideDashboardOffersTab => 'Предложения';

  @override
  String get guideDashboardBookingsTab => 'Брони';

  @override
  String get guideDashboardCompletedTab => 'Проведено';

  @override
  String get guideDashboardActiveTab => 'Активные';

  @override
  String get guideDashboardDraftTab => 'Черновики';

  @override
  String get guideDashboardArchiveTab => 'Архив';

  @override
  String get guideDashboardReviewTab => 'Проверка';

  @override
  String get guideDashboardRejectedTab => 'Отклонено';

  @override
  String get guideDashboardCancelledTab => 'Отменено';

  @override
  String get guideDashboardLoadFailed => 'Не удалось загрузить кабинет гида';

  @override
  String get guideDashboardOffersEmpty => 'Активных предложений пока нет';

  @override
  String get guideDashboardOffersEmptyHint =>
      'Опубликуйте первое предложение экскурсии, чтобы путешественники могли его забронировать.';

  @override
  String get guideDashboardBookingsEmpty => 'Нет ближайших броней';

  @override
  String get guideDashboardBookingsEmptyHint =>
      'Новые брони клиентов появятся здесь с датой, гостями и суммой.';

  @override
  String get guideDashboardCompletedEmpty => 'Проведенных экскурсий пока нет';

  @override
  String get guideDashboardCompletedEmptyHint =>
      'Завершенные экскурсии переместятся сюда после даты проведения.';

  @override
  String get guideDashboardDraftEmpty => 'Черновиков пока нет';

  @override
  String get guideDashboardDraftEmptyHint =>
      'Сохраненные черновики остаются приватными, пока вы не отправите их на проверку.';

  @override
  String get guideDashboardReviewEmpty => 'На проверке ничего нет';

  @override
  String get guideDashboardReviewEmptyHint =>
      'Предложения, ожидающие модерации или публикации, появятся здесь.';

  @override
  String get guideDashboardDirectGuideReviewsEmpty =>
      'Прямые отзывы о вас появятся здесь после отдельных оценок путешественников.';

  @override
  String get guideDashboardArchiveEmpty => 'В архиве пока пусто';

  @override
  String get guideDashboardArchiveEmptyHint =>
      'Архивируйте временно неактуальные предложения, чтобы убрать их из активных, но сохранить возможность редактировать и опубликовать снова.';

  @override
  String get guideDashboardRejectedEmpty => 'Отклоненных предложений нет';

  @override
  String get guideDashboardRejectedEmptyHint =>
      'Предложения, отклоненные на модерации, появятся здесь с доступом к правкам.';

  @override
  String get guideDashboardCancelledEmpty => 'Отмененных броней нет';

  @override
  String get guideDashboardCancelledEmptyHint =>
      'Отмененные брони клиентов сохраняются здесь для истории и связи с гостями.';

  @override
  String get guideDashboardCreateOffer => 'Создать предложение';

  @override
  String get guideDashboardEditOffer => 'Редактировать';

  @override
  String get guideDashboardArchiveOffer => 'В архив';

  @override
  String get guideDashboardPublishOffer => 'Опубликовать';

  @override
  String get guideDashboardSubmitOffer => 'Отправить на проверку';

  @override
  String get guideDashboardDeleteDraftOffer => 'Удалить черновик';

  @override
  String get guideDashboardDeleteDraftTitle => 'Удалить черновик?';

  @override
  String get guideDashboardDeleteDraftMessage =>
      'Черновик будет удален полностью и без возможности восстановления.';

  @override
  String get guideDashboardDeleteDraftConfirm => 'Удалить черновик';

  @override
  String get guideDashboardDeleteDraftSuccess => 'Черновик удален';

  @override
  String get guideDashboardDeleteDraftFailed => 'Не удалось удалить черновик';

  @override
  String get guideDashboardArchiveFailed =>
      'Не удалось перенести предложение в архив';

  @override
  String get guideDashboardPublishFailed =>
      'Не удалось опубликовать предложение';

  @override
  String get guideDashboardSubmitFailed =>
      'Не удалось отправить предложение на проверку';

  @override
  String get guideDashboardViewBooking => 'Открыть бронь';

  @override
  String get guideDashboardShowAttendanceQr => 'QR отметки';

  @override
  String get guideDashboardAttendanceParticipants => 'Участники';

  @override
  String get guideDashboardAttendanceCheckedIn => 'Отметился';

  @override
  String get guideDashboardAttendanceWaiting => 'Ожидает отметки';

  @override
  String get guideDashboardViewDetails => 'Подробнее';

  @override
  String get guideDashboardCancelExcursion => 'Отменить экскурсию';

  @override
  String get guideDashboardCancelTitle => 'Отменить экскурсию?';

  @override
  String get guideDashboardCancelDescription =>
      'Мы отменим этот слот для гостей и покажем сумму, которую нужно вернуть по затронутым броням.';

  @override
  String get guideDashboardCancelReasonLabel => 'Причина отмены';

  @override
  String get guideDashboardCancelReasonPlaceholder =>
      'Например: гид заболел или погодные условия не позволяют провести маршрут';

  @override
  String get guideDashboardCancelReasonRequired => 'Укажите причину отмены';

  @override
  String get guideDashboardCancelConfirm => 'Подтвердить отмену';

  @override
  String get guideDashboardCancelSuccess => 'Экскурсия отменена';

  @override
  String get guideDashboardCancelFailed => 'Не удалось отменить экскурсию';

  @override
  String get guideDashboardCancelNoSlot =>
      'У этой брони нет слота расписания для отмены';

  @override
  String guideDashboardRefundAmount(Object amount) {
    return 'К возврату гостям: $amount';
  }

  @override
  String get guideDashboardCancelledByTourist => 'Отменено туристом';

  @override
  String get guideDashboardCancelledByGuide => 'Отменено гидом';

  @override
  String guideDashboardCancellationReason(Object reason) {
    return 'Причина: $reason';
  }

  @override
  String get guideDashboardBookingSheetTitle => 'Информация по бронированию';

  @override
  String get guideDashboardBookingAuthorsTitle => 'Авторы бронирования';

  @override
  String get guideDashboardAdults => 'Взрослые';

  @override
  String get guideDashboardChildren => 'Дети';

  @override
  String get guideDashboardTotalGuests => 'Итого гостей';

  @override
  String guideDashboardGuestBreakdown(
    Object adults,
    Object children,
    Object total,
  ) {
    return 'Взрослые: $adults · Дети: $children · Итого: $total';
  }

  @override
  String get guideDashboardStatusActive => 'Активно';

  @override
  String get guideDashboardStatusDraft => 'Черновик';

  @override
  String get guideDashboardStatusArchived => 'Архив';

  @override
  String get guideDashboardStatusReview => 'На проверке';

  @override
  String get guideDashboardStatusRejected => 'Отклонено';

  @override
  String get guideDashboardStatusBooked => 'Бронь';

  @override
  String get guideDashboardStatusCompleted => 'Проведено';

  @override
  String get guideDashboardStatusCancelled => 'Отменено';

  @override
  String get guideDashboardFlexibleGroup => 'Гибкая группа';

  @override
  String guideDashboardMaxGuests(Object count) {
    return 'До $count гостей';
  }

  @override
  String guideDashboardBookingCount(Object count) {
    return '$count броней';
  }

  @override
  String get excursionReviewsTitle => 'Отзывы после экскурсий';

  @override
  String get excursionReviewsEmpty => 'Отзывов по этой экскурсии пока нет';

  @override
  String excursionReviewViaGuide(Object guide) {
    return 'Через гида: $guide';
  }

  @override
  String get excursionReviewSourceAttractionBadge =>
      'Отзыв на основе посещенной экскурсии';

  @override
  String get activityReviewsSectionTitle => 'Отзывы';

  @override
  String get activityReviewsTitle => 'Отзывы активности';

  @override
  String get activityOrganizerReviewsTitle => 'Отзывы организатора';

  @override
  String get activityReviewsEmpty => 'По этой активности пока нет отзывов';

  @override
  String get activityReviewsLoadFailed =>
      'Не удалось загрузить отзывы активности';

  @override
  String get activityReviewSheetTitle => 'Оцените активность';

  @override
  String get activityReviewActivityLabel => 'Активность';

  @override
  String get activityReviewOrganizerLabel => 'Организатор';

  @override
  String get activityReviewWriteButton => 'Оставить отзыв';

  @override
  String get activityReviewEditButton => 'Изменить отзыв';

  @override
  String get activityReviewUnavailable =>
      'Отзывы доступны только участникам, которые отметились, после завершения активности.';

  @override
  String get activityReviewSaved => 'Отзыв сохранен';

  @override
  String get activityReviewSaveFailed => 'Не удалось сохранить отзыв';

  @override
  String get activityReviewPublishConfirmTitle => 'Опубликовать отзыв?';

  @override
  String get activityReviewPublishConfirmDescription =>
      'После публикации ваши оценки активности и организатора будут видны в отзывах.';

  @override
  String get activityReviewPublishConfirmButton => 'Опубликовать';

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
  String get activitiesSearchHint => 'Активности, организаторы, города';

  @override
  String get activitiesFiltersTitle => 'Фильтры';

  @override
  String get activitiesFilterCountrySection => 'Страна';

  @override
  String get activitiesFilterCountryAll => 'Все страны';

  @override
  String get activitiesFilterCountrySearchHint => 'Страна, код или телефон';

  @override
  String get activitiesFilterCountryNoResults => 'Страна не найдена';

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
  String get activitiesNearbyTitle => 'Активности рядом';

  @override
  String get activitiesNearbyMapEmpty => 'У активностей пока нет точек встречи';

  @override
  String get activitiesFilteredEmptyTitle =>
      'По этим фильтрам ничего не найдено';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Попробуйте расширить категорию, диапазон дат, стоимость или выбрать другой город';

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
  String get qrScannerInvalidCode => 'Это не QR активности Inflap';

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
  String get storiesDiscoverTitle => 'Посты';

  @override
  String get storiesNavLabel => 'Посты';

  @override
  String get storiesActivitiesNavLabel => 'Активности';

  @override
  String get storySearchHint => 'Посты, авторы или места';

  @override
  String get storySearchCompactHint => 'Посты';

  @override
  String get storyFiltersTitle => 'Фильтры';

  @override
  String get storyFiltersActiveSummary => 'Выбрано';

  @override
  String get storyFilterFormat => 'Тип материала';

  @override
  String get storyFilterCategory => 'Тема';

  @override
  String get storyFilterCountry => 'Страна';

  @override
  String get storyFilterCountryAll => 'Все страны';

  @override
  String get storyFilterCountrySearchHint => 'Страна, код или телефон';

  @override
  String get storyFilterCountryNoResults => 'Страна не найдена';

  @override
  String get storyFilterAll => 'Все';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поста',
      many: '$count постов',
      few: '$count поста',
      one: '$count пост',
      zero: '0 постов',
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
  String get storyCreateCta => 'Создать пост';

  @override
  String get storyCreateFirst => 'Создать первый пост';

  @override
  String get storyEmptyTitle => 'Постов пока нет';

  @override
  String get storyEmptySubtitle =>
      'Станьте первым, кто опубликует travel-note, локальный гид или визуальное эссе.';

  @override
  String get storyEmptyAuthenticatedSubtitle =>
      'Создайте пост, статью, гид или визуальное эссе, чтобы запустить ленту.';

  @override
  String get storyFilteredEmptyTitle => 'По этим фильтрам постов нет';

  @override
  String get storyFilteredEmptySubtitle =>
      'Попробуйте другой поиск, страну, город или категорию.';

  @override
  String get storyResetFiltersAction => 'Очистить';

  @override
  String get storyLoginCreateAction => 'Войти и создать';

  @override
  String get myStoriesDraftsTab => 'Черновики';

  @override
  String get myStoriesPendingReviewTab => 'На проверке';

  @override
  String get myStoriesPublishedTab => 'Опубликовано';

  @override
  String get myStoriesArchivedTab => 'Архив';

  @override
  String get myStoriesDraftEmptyTitle => 'Черновиков пока нет';

  @override
  String get myStoriesDraftEmptySubtitle =>
      'Сохраняйте идеи как черновики перед публикацией в ленту постов.';

  @override
  String get myStoriesPendingReviewEmptyTitle => 'Постов на проверке пока нет';

  @override
  String get myStoriesPendingReviewEmptySubtitle =>
      'Посты, ожидающие проверки модератором, появятся здесь.';

  @override
  String get myStoriesPublishedEmptyTitle => 'Опубликованных постов пока нет';

  @override
  String get myStoriesPublishedEmptySubtitle =>
      'Опубликованные посты, гиды, статьи и визуальные эссе появятся здесь.';

  @override
  String get myStoriesArchivedEmptyTitle => 'Архивных постов пока нет';

  @override
  String get myStoriesArchivedEmptySubtitle =>
      'Архивные посты хранятся здесь для истории и повторного использования.';

  @override
  String get myStoriesCreateDraftAction => 'Создать черновик';

  @override
  String get storyArchiveActiveTab => 'Активные';

  @override
  String get storyArchiveArchiveTab => 'Архив';

  @override
  String get storyArchiveActiveSubtitle =>
      'Здесь ваши истории, которые еще видны другим пользователям.';

  @override
  String get storyArchiveActiveEmptyTitle => 'Активных историй пока нет';

  @override
  String get storyArchiveActiveEmptySubtitle =>
      'Снимите фото или видео в кружочке, чтобы история появилась здесь на 24 часа.';

  @override
  String get storyArchiveActiveUntilPrefix => 'Активна до';

  @override
  String get storyArchiveSubtitle =>
      'Истории живут 24 часа, а затем остаются здесь только для вас.';

  @override
  String get storyArchiveEmptyTitle => 'Архивных историй пока нет';

  @override
  String get storyArchiveEmptySubtitle =>
      'Ваши истории с камеры появятся здесь через 24 часа после публикации.';

  @override
  String get storyArchiveLoadFailedTitle => 'Не удалось загрузить истории';

  @override
  String get storyArchiveLoadFailedMessage =>
      'Проверьте соединение и попробуйте еще раз.';

  @override
  String get storyArchiveRetryAction => 'Попробовать снова';

  @override
  String get storyArchiveLoadMoreAction => 'Загрузить еще';

  @override
  String get storyArchiveExpiredPrefix => 'В архиве с';

  @override
  String get storyStateSeenLabel => 'Просмотрено';

  @override
  String get storyStateExpiredLabel => 'Истекла';

  @override
  String get storyStatePendingLabel => 'На проверке';

  @override
  String get storyStateHiddenLabel => 'Скрыта';

  @override
  String get storyLoadFailed => 'Не удалось загрузить посты';

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
  String get storyFormatStory => 'Пост';

  @override
  String get storyFormatGuide => 'Гид';

  @override
  String get storyFormatPhotoEssay => 'Фотоэссе';

  @override
  String get storyFormatArticle => 'Статья';

  @override
  String get storyFormatCulinary => 'Гастрономия';

  @override
  String get storyDetailsTitle => 'Детали поста';

  @override
  String get storyLinkCopied => 'Ссылка на пост скопирована';

  @override
  String get storyShareFailed =>
      'Не удалось открыть окно отправки ссылки. Попробуйте еще раз.';

  @override
  String get storyReportAction => 'Пожаловаться';

  @override
  String get storyReportSending => 'Отправляем...';

  @override
  String get storyReportTitle => 'Пожаловаться на пост';

  @override
  String get storyReportSubtitle =>
      'Расскажите, что не так. Жалобы помогают модераторам сохранять travel-контент безопасным и полезным.';

  @override
  String get storyReportDetailsLabel => 'Детали';

  @override
  String get storyReportDetailsHint => 'Добавьте контекст для модераторов';

  @override
  String get storyReportSubmitAction => 'Отправить жалобу';

  @override
  String get storyReportSubmitted => 'Спасибо. Мы отправили пост на модерацию.';

  @override
  String get storyReportAutoHidden =>
      'Спасибо. Пост скрыт до проверки модераторами.';

  @override
  String get storyReportReasonSpam => 'Спам или вводит в заблуждение';

  @override
  String get storyReportReasonHarassment => 'Травля или оскорбления';

  @override
  String get storyReportReasonHate => 'Ненависть или дискриминация';

  @override
  String get storyReportReasonSexualContent => 'Сексуальный контент';

  @override
  String get storyReportReasonViolence => 'Насилие или шокирующий контент';

  @override
  String get storyReportReasonMisinformation => 'Недостоверная информация';

  @override
  String get storyReportReasonIllegal => 'Незаконная активность';

  @override
  String get storyReportReasonOther => 'Другое';

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
  String get storyLikeActionFailed =>
      'Не удалось обновить лайк. Попробуйте еще раз.';

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
  String get storyRelatedTitle => 'Похожие посты';

  @override
  String get storyRelatedEmpty => 'Похожих постов пока нет';

  @override
  String get storyViewAll => 'Смотреть все';

  @override
  String get storyEditAction => 'Редактировать';

  @override
  String get storyDeleteTitle => 'Удалить пост?';

  @override
  String get storyDeleteMessage => 'Пост будет убран из публичной ленты.';

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
  String get storyCountryHint => 'Страна';

  @override
  String get storyCityHint => 'Город';

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
  String get storyEditorTitle => 'Редактор поста';

  @override
  String get storyEditorQuickPostTitle => 'Быстрый пост';

  @override
  String get storyEditorQuickPostSubtitle =>
      'Поделитесь коротким обновлением, вопросом или локальным советом с сообществом.';

  @override
  String get storyEditorQuickPostHint => 'Что хотите рассказать?';

  @override
  String get storyEditorLoading => 'Загрузка истории';

  @override
  String get storyEditorLoadFailed =>
      'Не удалось загрузить историю для редактирования.';

  @override
  String get storyEditorEditMode => 'Редактирование';

  @override
  String get storyEditorPreviewMode => 'Предпросмотр';

  @override
  String get storyEditorRecoveryTitle => 'Восстановить несохраненный черновик?';

  @override
  String get storyEditorRecoveryMessage =>
      'Для этой истории доступна локальная копия восстановления.';

  @override
  String get storyEditorRecoveryDiscard => 'Отклонить';

  @override
  String get storyEditorRecoveryRestore => 'Восстановить';

  @override
  String get storyEditorDiscardChangesTitle => 'Отменить изменения поста?';

  @override
  String get storyEditorDiscardChangesMessage =>
      'Несохраненные правки могут быть потеряны.';

  @override
  String get storyEditorKeepEditing => 'Продолжить редактирование';

  @override
  String get storyEditorMetadataTitle => 'Настройки публикации';

  @override
  String get storyEditorTitleFieldHint =>
      'Точный заголовок, который легко найти';

  @override
  String get storyEditorTemplateAction => 'Шаблоны';

  @override
  String get storyEditorTemplateSemantic => 'Выбрать шаблон истории';

  @override
  String get storyEditorTemplatePlaceholder => 'Выберите шаблон';

  @override
  String get storyEditorTemplateWeekendGuide => 'Гид на выходные';

  @override
  String get storyEditorTemplatePhotoEssay => 'Фотоэссе';

  @override
  String get storyEditorTemplateFoodNotes => 'Заметки о еде';

  @override
  String get storyEditorTemplateCityWalk => 'Прогулка по городу';

  @override
  String get storyEditorTemplateHiddenGems => 'Скрытые места';

  @override
  String get storyEditorTemplatePracticalTips => 'Практические советы';

  @override
  String get storyEditorTemplateCultureRoute => 'Культурный маршрут';

  @override
  String get storyEditorTemplateWeekendHeading => 'План выходных';

  @override
  String get storyEditorTemplateWeekendList =>
      'Утренняя точка\nЛокальная еда\nВечерний вид';

  @override
  String get storyEditorTemplatePhotoHeading => 'Фотоистория';

  @override
  String get storyEditorTemplateFoodHeading => 'Где поесть';

  @override
  String get storyEditorTemplateFoodParagraph =>
      'Опишите блюдо, уровень цен и лучшее время для визита.';

  @override
  String get storyEditorTemplateCityWalkHeading => 'Маршрут прогулки';

  @override
  String get storyEditorTemplateCityWalkList =>
      'Стартовая точка\nГлавная улица\nМесто для паузы\nФинальный вид';

  @override
  String get storyEditorTemplateCityWalkParagraph =>
      'Добавьте расстояние, примерное время и самый удобный способ добраться до старта.';

  @override
  String get storyEditorTemplateHiddenGemsHeading =>
      'Места, о которых знают не все';

  @override
  String get storyEditorTemplateHiddenGemsList =>
      'Почему стоит зайти\nКогда меньше людей\nЧто посмотреть рядом';

  @override
  String get storyEditorTemplateHiddenGemsCallout =>
      'Укажите нюансы: вход, расписание, безопасность, наличные или бронирование.';

  @override
  String get storyEditorTemplatePracticalTipsHeading =>
      'Полезно знать перед поездкой';

  @override
  String get storyEditorTemplatePracticalTipsList =>
      'Когда ехать\nКак добраться\nСколько заложить денег\nЧто взять с собой';

  @override
  String get storyEditorTemplatePracticalTipsCallout =>
      'Добавьте честный совет, который сэкономит время или поможет избежать ошибки.';

  @override
  String get storyEditorTemplateCultureRouteHeading => 'Культурный маршрут';

  @override
  String get storyEditorTemplateCultureRouteParagraph =>
      'Расскажите, какие традиции, здания, музеи или локальные истории помогают понять это место.';

  @override
  String get storyEditorTemplateCultureRouteQuote =>
      'Добавьте фразу, наблюдение или короткий факт, который задает настроение маршрута.';

  @override
  String get storyEditorTemplateConflictTitle => 'Применить новую структуру?';

  @override
  String storyEditorTemplateConflictMessage(Object format, Object category) {
    return 'Эта структура предлагает: $format / $category. Выберите, как применить ее без потери черновика.';
  }

  @override
  String get storyEditorTemplateConflictReplace => 'Заменить шаблон';

  @override
  String get storyEditorTemplateConflictReplaceDescription =>
      'Удалим нетронутые шаблонные блоки, сохраним ваш текст и добавим новую структуру.';

  @override
  String get storyEditorTemplateConflictAppend => 'Добавить к истории';

  @override
  String get storyEditorTemplateConflictAppendDescription =>
      'Сохраним все текущее содержимое и добавим новую структуру ниже.';

  @override
  String get storyEditorTemplateConflictMetadataOnly => 'Обновить тип и тему';

  @override
  String get storyEditorTemplateConflictMetadataOnlyDescription =>
      'Изменим только тип материала и тему, не трогая блоки.';

  @override
  String get storyEditorFormatLabel => 'Тип материала';

  @override
  String get storyEditorPlaceLabel => 'Место';

  @override
  String get storyEditorCountryCodeLabel => 'Код страны';

  @override
  String get storyEditorCountryCodeHint => 'KZ';

  @override
  String get storyEditorCityPlaceIdLabel => 'ID города/места';

  @override
  String get storyEditorTagsHint => 'горы, еда, выходные';

  @override
  String get storyEditorCoverSelected => 'Обложка выбрана';

  @override
  String get storyEditorCoverRequired => 'Нужна обложка';

  @override
  String get storyEditorReplaceCover => 'Заменить обложку';

  @override
  String get storyEditorAddCover => 'Добавить обложку';

  @override
  String get storyEditorClear => 'Очистить';

  @override
  String get storyEditorToolbarAddBlock => 'Добавить блок';

  @override
  String get storyEditorToolbarHeading => 'Заголовок';

  @override
  String get storyEditorToolbarBold => 'Жирный';

  @override
  String get storyEditorToolbarItalic => 'Курсив';

  @override
  String get storyEditorToolbarStrikethrough => 'Зачеркнутый';

  @override
  String get storyEditorToolbarUnderline => 'Подчеркнутый';

  @override
  String get storyEditorToolbarList => 'Список';

  @override
  String get storyEditorToolbarQuote => 'Цитата';

  @override
  String get storyEditorToolbarImage => 'Изображение';

  @override
  String get storyEditorToolbarUndo => 'Отменить';

  @override
  String get storyEditorToolbarRedo => 'Повторить';

  @override
  String get storyEditorAddBlockTitle => 'Добавить блок';

  @override
  String get storyEditorBlockParagraph => 'Абзац';

  @override
  String get storyEditorBlockParagraphDescription => 'Основной текст истории';

  @override
  String get storyEditorBlockHeading => 'Заголовок';

  @override
  String get storyEditorBlockHeadingDescription => 'Название раздела';

  @override
  String get storyEditorBlockList => 'Список';

  @override
  String get storyEditorBlockListDescription => 'Полезные советы или шаги';

  @override
  String get storyEditorBlockImage => 'Изображение';

  @override
  String get storyEditorBlockImageDescription => 'Одиночная загрузка медиа';

  @override
  String get storyEditorBlockGallery => 'Галерея';

  @override
  String get storyEditorBlockGalleryDescription => 'Несколько изображений';

  @override
  String get storyEditorBlockQuote => 'Цитата';

  @override
  String get storyEditorBlockQuoteDescription => 'Выделенная фраза';

  @override
  String get storyEditorBlockCallout => 'Выноска';

  @override
  String get storyEditorBlockCalloutDescription => 'Важная travel-заметка';

  @override
  String get storyEditorBlockDivider => 'Разделитель';

  @override
  String get storyEditorBlockDividerDescription => 'Визуальный разрыв раздела';

  @override
  String get storyEditorBlockPlaceReference => 'Ссылка на место';

  @override
  String get storyEditorBlockPlaceReferenceDescription =>
      'Связать место с историей';

  @override
  String get storyEditorBlockNumberedList => 'Нумерованный список';

  @override
  String get storyEditorStartWithBlockTitle => 'Начните с блока';

  @override
  String get storyEditorStartWithBlockSubtitle =>
      'Добавляйте текст, медиа, места, выноски или разделители, чтобы собрать историю.';

  @override
  String get storyEditorPlaceNameHint => 'Название места';

  @override
  String get storyEditorTextHintHeading =>
      'Напишите понятный заголовок раздела';

  @override
  String get storyEditorTextHintBulletedList =>
      'Добавляйте пункты списка по одному в строке';

  @override
  String get storyEditorTextHintNumberedList =>
      'Добавляйте шаги по одному в строке';

  @override
  String get storyEditorTextHintQuote =>
      'Добавьте цитату или запоминающуюся фразу';

  @override
  String get storyEditorTextHintCallout => 'Выделите практический совет';

  @override
  String get storyEditorTextHintParagraph => 'Напишите свою историю';

  @override
  String storyEditorDeleteBlockSemantic(Object block) {
    return 'Удалить блок «$block»';
  }

  @override
  String storyEditorReorderBlockSemantic(Object block) {
    return 'Перетащите, чтобы изменить порядок блока «$block»';
  }

  @override
  String get storyEditorPublishReadiness => 'Готовность к публикации';

  @override
  String get storyEditorChecklistTitle => 'Заголовок';

  @override
  String get storyEditorChecklistFormat => 'Тип материала';

  @override
  String get storyEditorChecklistCategory => 'Тема';

  @override
  String get storyEditorChecklistCover => 'Обложка';

  @override
  String get storyEditorChecklistPlace => 'Место';

  @override
  String get storyEditorChecklistCountry => 'Страна';

  @override
  String get storyEditorChecklistContent => 'Контент';

  @override
  String get storyEditorChecklistMedia => 'Медиа';

  @override
  String get storyEditorChecklistReady => 'Готово';

  @override
  String get storyEditorChecklistNeedsAttention => 'Требует внимания';

  @override
  String get storyEditorChecklistOpen => 'Открыть';

  @override
  String get storyEditorConflictFallback =>
      'История была изменена в другом месте.';

  @override
  String get storyEditorSaveDraft => 'Сохранить черновик';

  @override
  String get storyEditorPublish => 'Опубликовать';

  @override
  String get storyEditorPublishSemantic => 'Опубликовать историю';

  @override
  String get storyEditorAutosaveIdle => 'Ожидание';

  @override
  String get storyEditorAutosaveSaving => 'Сохранение';

  @override
  String get storyEditorAutosaveSaved => 'Сохранено';

  @override
  String get storyEditorAutosaveFailed => 'Требует внимания';

  @override
  String get storyEditorAutosaveConflict => 'Конфликт';

  @override
  String get storyEditorPublishNotReady => 'История не готова к публикации.';

  @override
  String get storyEditorMediaRetrySemantic => 'Повторить загрузку медиа';

  @override
  String get storyEditorMediaRemoveSemantic => 'Удалить загрузку медиа';

  @override
  String get storyEditorMediaRetry => 'Повторить';

  @override
  String get storyEditorMediaRemove => 'Удалить';

  @override
  String get storyEditorMediaQueued => 'В очереди на загрузку';

  @override
  String get storyEditorMediaUploading => 'Загрузка';

  @override
  String get storyEditorMediaFailed => 'Загрузка не удалась';

  @override
  String get storyEditorMediaComplete => 'Загрузка завершена';

  @override
  String get storyEditorMediaRemoved => 'Удалено';

  @override
  String get storyEditorMediaLocalPreviewUnavailable =>
      'Локальный предпросмотр недоступен. Удалите и добавьте это медиа снова.';

  @override
  String get storyEditorMediaErrorRetryUpload => 'Повторите загрузку медиа.';

  @override
  String get storyEditorMediaErrorInterrupted =>
      'Загрузка была прервана. Повторите, чтобы продолжить.';

  @override
  String get storyEditorMediaErrorMissingSource =>
      'Локальный источник медиа недоступен. Удалите и добавьте это медиа снова.';

  @override
  String get storyEditorMediaErrorUploadFailed =>
      'Не удалось загрузить медиа. Попробуйте еще раз.';

  @override
  String get storyEditorImagePickTooLarge =>
      'Изображение слишком большое. Выберите файл до 20 МБ.';

  @override
  String get storyEditorImagePickUnsupported =>
      'Выберите изображение в формате JPG, PNG или WebP.';

  @override
  String get storyEditorImagePickFailed =>
      'Не удалось открыть изображение. Попробуйте выбрать другое.';

  @override
  String get storyEditorValidationTitleRequired => 'Укажите заголовок истории.';

  @override
  String get storyEditorValidationFormatRequired => 'Выберите формат истории.';

  @override
  String get storyEditorValidationCategoryRequired =>
      'Выберите категорию истории.';

  @override
  String get storyEditorValidationCoverRequired => 'Добавьте обложку истории.';

  @override
  String get storyEditorValidationPlaceRequired => 'Укажите место истории.';

  @override
  String get storyEditorValidationCountryRequired => 'Выберите страну истории.';

  @override
  String get storyEditorValidationDraftRequired =>
      'Добавьте заголовок или хотя бы один блок истории, чтобы сохранить черновик.';

  @override
  String get storyEditorValidationContentRequired =>
      'Добавьте хотя бы один блок истории перед публикацией.';

  @override
  String get storyEditorValidationMediaPending =>
      'Дождитесь завершения загрузки медиа.';

  @override
  String get postCreateRateLimitTitle => 'Лимит постов';

  @override
  String postCreateRateLimitMessage(int minutes) {
    return 'Вы уже создали максимум постов за последний час. Новый пост можно будет создать примерно через $minutes мин.';
  }

  @override
  String get postCreateRateLimitAction => 'Понятно';

  @override
  String get postCreatePreflightFailed =>
      'Не удалось проверить лимит. Проверим при публикации.';

  @override
  String get chatListTitle => 'Чаты';

  @override
  String get chatListLoadFailed => 'Не удалось загрузить чаты';

  @override
  String get chatListEmpty => 'Диалогов пока нет';

  @override
  String get chatListPersonalTab => 'Личные';

  @override
  String get chatListActivitiesTab => 'Активности';

  @override
  String get chatListExcursionsTab => 'Экскурсии';

  @override
  String get chatListSearchHint => 'Чаты';

  @override
  String get chatListSearchEmpty => 'Чаты не найдены';

  @override
  String get chatMuteNotificationsAction => 'Выключить уведомления';

  @override
  String get chatUnmuteNotificationsAction => 'Включить уведомления';

  @override
  String get chatMuteUpdateFailed => 'Не удалось обновить уведомления чата';

  @override
  String get chatBlockUserAction => 'Заблокировать';

  @override
  String get chatUnblockUserAction => 'Разблокировать';

  @override
  String get chatUserBlockUpdateFailed =>
      'Не удалось обновить блокировку пользователя';

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
  String get chatMessageRemovedByModerator => 'Сообщение удалено модератором';

  @override
  String chatModeratorComment(Object comment) {
    return 'Комментарий модератора: $comment';
  }

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
  String get stickersSearchHint => 'Стикеры';

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
  String get chatActivityChatClosed => 'Чат теперь доступен только для чтения.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'Событие завершено. Сообщения в этот чат больше нельзя отправлять.';

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
  String get chatStoryReplyLabel => 'Ответ на историю';

  @override
  String get chatStoryReplyUnavailable => 'История больше недоступна';

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

  @override
  String get guideCalendarTitle => 'Календарь гида';

  @override
  String get guideCalendarAddSlot => 'Слот';

  @override
  String get guideCalendarEditSlot => 'Редактировать слот';

  @override
  String get guideCalendarEmptyDay => 'На этот день нет слотов';

  @override
  String get guideCalendarAvailable => 'Свободно';

  @override
  String get guideCalendarBooked => 'Есть бронь';

  @override
  String get guideCalendarClosed => 'Закрыто';

  @override
  String get guideCalendarCancelled => 'Отменено';

  @override
  String get guideCalendarCompleted => 'Завершено';

  @override
  String get guideCalendarViewSlot => 'Детали слота';

  @override
  String get guideCalendarReadonlyCompletedSlot =>
      'Этот слот уже завершен. Он остается в календаре для истории и доступен только для просмотра.';

  @override
  String guideCalendarCancelReason(Object reason) {
    return 'Причина: $reason';
  }

  @override
  String get guideCalendarAutoCancelNoBookings =>
      'никто не забронировал слот за 2 часа до начала';

  @override
  String get guideCalendarRepeatWeekly => 'Повторять еженедельно';

  @override
  String get guideCalendarConflictTitle =>
      'Время пересекается с другой экскурсией';

  @override
  String get guideCalendarSuggestNextTime =>
      'Выберите ближайшее свободное время';

  @override
  String get guideCalendarDeleteSlot => 'Удалить';

  @override
  String get guideCalendarCancelSlot => 'Отменить';

  @override
  String get guideCalendarCloseSlot => 'Закрыть';

  @override
  String get guideCalendarOfferLabel => 'Опубликованное предложение';

  @override
  String get guideCalendarNoPublishedOffers =>
      'Сначала опубликуйте предложение по экскурсии, чтобы добавить его в расписание.';

  @override
  String get guideCalendarOfferRequired => 'Выберите предложение по экскурсии';

  @override
  String get guideCalendarCurrentOfferFallback => 'Текущее предложение';

  @override
  String guideCalendarOfferDuration(Object minutes) {
    return '$minutes мин';
  }

  @override
  String guideCalendarOfferCapacity(Object count) {
    return '$count мест';
  }

  @override
  String get guideCalendarDateLabel => 'Дата';

  @override
  String get guideCalendarDateHint => 'дд.мм.гггг';

  @override
  String get guideCalendarInvalidDate => 'Введите дату в формате дд.мм.гггг';

  @override
  String get guideCalendarTimeLabel => 'Время';

  @override
  String get guideCalendarTimeHint => 'чч:мм';

  @override
  String get guideCalendarInvalidTime => 'Введите время в формате чч:мм';

  @override
  String get guideCalendarCapacityLabel => 'Мест';

  @override
  String guideCalendarCapacityMax(Object count) {
    return 'Максимум для этого предложения: $count';
  }

  @override
  String guideCalendarCapacityTooHigh(Object count) {
    return 'В этом предложении доступно до $count мест';
  }

  @override
  String get guideCalendarSlotLeadTimeTooSoon =>
      'Выберите дату и время минимум за 3 часа до начала.';

  @override
  String get guideCalendarSaveSlot => 'Сохранить';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsSubtitle =>
      'Важные обновления по поездкам, активностям и экскурсиям';

  @override
  String get notificationsCategoriesEmptyTitle => 'Пока тихо';

  @override
  String get notificationsCategoriesEmptySubtitle =>
      'Здесь появятся последние обновления по вашим категориям.';

  @override
  String get notificationsLoadFailedTitle => 'Не удалось загрузить уведомления';

  @override
  String get notificationsLoadFailedSubtitle =>
      'Проверьте подключение и попробуйте снова.';

  @override
  String get notificationsCategoryEmptyTitle =>
      'В этой категории пока нет уведомлений';

  @override
  String get notificationsCategoryEmptySubtitle =>
      'Новые события появятся здесь автоматически.';

  @override
  String get notificationsReadAll => 'Прочитать все';

  @override
  String get notificationsReadAllDone =>
      'Все уведомления в категории прочитаны';

  @override
  String notificationsUnreadCount(Object count) {
    return '$count новых';
  }

  @override
  String get notificationsCategoryActivity => 'Активности';

  @override
  String get notificationsCategoryExcursion => 'Экскурсии';

  @override
  String get notificationsCategoryBooking => 'Бронирования';

  @override
  String get notificationsCategoryChat => 'Сообщения';

  @override
  String get notificationsCategoryContent => 'Посты и истории';

  @override
  String get notificationsCategorySystem => 'Система';

  @override
  String get notificationsCategoryGeneral => 'Общее';

  @override
  String notificationsCategoryFallback(Object category) {
    return 'Категория $category';
  }

  @override
  String get notificationsSomeone => 'Кому-то';

  @override
  String get notificationsPriorityHigh => 'Важное';

  @override
  String notificationsStoryLikeTitle(Object actor) {
    return '$actor нравится ваша история';
  }

  @override
  String get notificationsStoryLikeBody =>
      'Откройте историю, чтобы посмотреть реакцию.';

  @override
  String notificationsStoryReplyTitle(Object actor) {
    return '$actor ответил на вашу историю';
  }

  @override
  String get notificationsStoryReplyBody => 'Ответ отправлен в ваш чат.';

  @override
  String notificationsPostLikeTitle(Object actor) {
    return '$actor нравится ваш пост';
  }

  @override
  String get notificationsPostLikeBody =>
      'Откройте пост, чтобы посмотреть реакцию.';

  @override
  String notificationsPostCommentTitle(Object actor) {
    return '$actor прокомментировал ваш пост';
  }

  @override
  String get notificationsPostCommentBody =>
      'Откройте пост, чтобы продолжить обсуждение.';

  @override
  String notificationsChatMessageTitle(Object actor) {
    return 'Новое сообщение от $actor';
  }

  @override
  String get notificationsChatMessageBody => 'Откройте чаты, чтобы ответить.';

  @override
  String notificationsActivityJoinedTitle(Object actor) {
    return '$actor присоединился к вашей активности';
  }

  @override
  String get notificationsActivityJoinedBody =>
      'Откройте активность, чтобы посмотреть участников.';

  @override
  String get notificationsActivityParticipantWaitlistedTitle =>
      'Участник в списке ожидания';

  @override
  String get notificationsActivityParticipantWaitlistedBody =>
      'Откройте активность, чтобы управлять списком ожидания.';

  @override
  String get notificationsActivityParticipantLeftTitle =>
      'Участник вышел из активности';

  @override
  String get notificationsActivityParticipantLeftBody =>
      'Откройте активность, чтобы проверить актуальный список участников.';

  @override
  String get notificationsActivityLateCancellationTitle => 'Поздняя отмена';

  @override
  String get notificationsActivityLateCancellationBody =>
      'Участник отменил участие незадолго до начала.';

  @override
  String get notificationsActivityCancelledTitle => 'Активность отменена';

  @override
  String notificationsActivityCancelledBody(Object activity) {
    return 'Активность «$activity» отменена.';
  }

  @override
  String get notificationsActivityCancelledBodyGeneric =>
      'Эта активность отменена.';

  @override
  String get notificationsActivityConfirmedTitle => 'Активность подтверждена';

  @override
  String get notificationsActivityConfirmedBody =>
      'Откройте активность, чтобы посмотреть актуальные детали.';

  @override
  String get notificationsActivityCompletedTitle => 'Активность завершена';

  @override
  String get notificationsActivityCompletedBody =>
      'Теперь можно оставить отзыв о впечатлении.';

  @override
  String get notificationsExcursionBookingCreatedTitle =>
      'Новая бронь экскурсии';

  @override
  String get notificationsExcursionBookingCreatedBody =>
      'Откройте кабинет гида, чтобы посмотреть детали брони.';

  @override
  String get notificationsExcursionBookingCancelledTitle =>
      'Бронь экскурсии отменена';

  @override
  String get notificationsExcursionBookingCancelledBody =>
      'Путешественник отменил эту экскурсию.';

  @override
  String get notificationsExcursionGuestsUpdatedTitle =>
      'Количество гостей изменено';

  @override
  String get notificationsExcursionGuestsUpdatedBody =>
      'Откройте кабинет гида, чтобы проверить обновленную бронь.';

  @override
  String get notificationsExcursionAttendanceTitle => 'Гость отметился';

  @override
  String get notificationsExcursionAttendanceBody =>
      'Путешественник отметился на этой экскурсии.';

  @override
  String get notificationsExcursionCancelledTitle => 'Экскурсия отменена';

  @override
  String get notificationsExcursionCancelledBody =>
      'Гид отменил эту экскурсию.';

  @override
  String get notificationsExcursionStartsSoonTitle =>
      'Экскурсия скоро начнется';

  @override
  String get notificationsExcursionStartsSoonBody =>
      'Окно бронирования закрыто. Откройте экскурсию, чтобы проверить гостей.';

  @override
  String get notificationsExcursionCompletedTitle => 'Как прошла экскурсия?';

  @override
  String get notificationsExcursionCompletedBody =>
      'Экскурсия завершена. Теперь можно оставить отзыв.';

  @override
  String get notificationsExcursionPublishedTitle => 'Экскурсия опубликована';

  @override
  String get notificationsExcursionPublishedBody =>
      'Ваша экскурсия теперь видна путешественникам.';

  @override
  String get notificationsExcursionRejectedTitle => 'Экскурсию нужно исправить';

  @override
  String get notificationsExcursionRejectedBody =>
      'Откройте кабинет гида, чтобы посмотреть замечания модерации.';

  @override
  String get notificationsJustNow => 'только что';

  @override
  String notificationsMinutesAgo(Object minutes) {
    return '$minutes мин назад';
  }

  @override
  String notificationsHoursAgo(Object hours) {
    return '$hours ч назад';
  }

  @override
  String notificationsDaysAgo(Object days) {
    return '$days дн назад';
  }
}
