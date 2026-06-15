// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Inflap';

  @override
  String get welcomeTitle => 'Сіздің жеке әлеміңіз.';

  @override
  String get welcomeDescription =>
      'Заманауи зерттеушіге арналған мінсіз саяхат суперқосымшасының барлық мүмкіндіктерін бағалаңыз.';

  @override
  String get welcomeToInflap => 'Inflap қосымшасына қош келдіңіз';

  @override
  String get authByPhone => 'Телефон нөмірі арқылы кіру';

  @override
  String get authLoginTab => 'Кіру';

  @override
  String get authRegisterTab => 'Тіркелу';

  @override
  String get authLoginTitle => 'Аккаунтқа кіріңіз';

  @override
  String get authRegisterTitle => 'Аккаунт жасаңыз';

  @override
  String get authIdentifierLabel => 'Никнейм немесе email';

  @override
  String get authIdentifierHint => '@nomad немесе traveler@example.com';

  @override
  String get authIdentifierRequiredError => 'Никнейм немесе email енгізіңіз';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'traveler@example.com';

  @override
  String get passwordLabel => 'Құпиясөз';

  @override
  String get passwordHint => 'Кемінде 8 таңба';

  @override
  String get authConfirmPasswordLabel => 'Құпиясөзді қайталаңыз';

  @override
  String get authLoginAction => 'Кіру';

  @override
  String get authRegisterAction => 'Тіркелу';

  @override
  String get authShowPassword => 'Құпиясөзді көрсету';

  @override
  String get authHidePassword => 'Құпиясөзді жасыру';

  @override
  String get authLoginFailed =>
      'Кіру мүмкін болмады. Деректерді тексеріп, қайта көріңіз.';

  @override
  String get authRegistrationFailed =>
      'Тіркеуді бастау мүмкін болмады. Деректерді тексеріп, қайта көріңіз.';

  @override
  String get authPasswordMismatchError => 'Құпиясөздер сәйкес емес';

  @override
  String get authForgotPasswordAction => 'Құпиясөзді ұмыттыңыз ба?';

  @override
  String get passwordResetTitle => 'Қолжетімділікті қалпына келтіру';

  @override
  String get passwordResetRequestDescription =>
      'Email немесе никнейм енгізіңіз. Аккаунт табылса, код байланыстырылған поштаға жіберіледі.';

  @override
  String get passwordResetVerifyDescription =>
      'Хаттағы кодты енгізіп, аккаунтқа жаңа құпиясөз қойыңыз.';

  @override
  String get passwordResetIdentifierLabel => 'Email немесе никнейм';

  @override
  String get passwordResetIdentifierHint =>
      '@nomad немесе traveler@example.com';

  @override
  String get passwordResetIdentifierRequiredError =>
      'Email немесе никнейм енгізіңіз';

  @override
  String get passwordResetCodeLabel => 'Растау коды';

  @override
  String get passwordResetCodeHint => '6 цифр';

  @override
  String get passwordResetCodeRequiredError => 'Растау кодын енгізіңіз';

  @override
  String get passwordResetNewPasswordLabel => 'Жаңа құпиясөз';

  @override
  String get passwordResetConfirmPasswordLabel => 'Жаңа құпиясөзді қайталаңыз';

  @override
  String get passwordResetSendCodeAction => 'Код жіберу';

  @override
  String get passwordResetResendCodeAction => 'Қайта жіберу';

  @override
  String passwordResetResendCodeCountdown(String time) {
    return '$time кейін қайта жіберу';
  }

  @override
  String get passwordResetSavePasswordAction => 'Құпиясөзді сақтау';

  @override
  String get passwordResetBackToLogin => 'Кіруге оралу';

  @override
  String get passwordResetStartFailed =>
      'Қалпына келтіру кодын жіберу мүмкін болмады. Қайталап көріңіз.';

  @override
  String get passwordResetVerifyFailed =>
      'Құпиясөзді жаңарту мүмкін болмады. Кодты тексеріп, қайта көріңіз.';

  @override
  String get passwordResetSentNotice =>
      'Аккаунт табылса, код байланыстырылған поштаға жіберілді.';

  @override
  String get passwordResetSuccess =>
      'Құпиясөз жаңартылды. Жаңа құпиясөзбен кіріңіз.';

  @override
  String get emailRequiredError => 'Email енгізіңіз';

  @override
  String get emailInvalidError => 'Дұрыс email енгізіңіз';

  @override
  String get passwordRequiredError => 'Құпиясөз енгізіңіз';

  @override
  String get passwordWeakError =>
      'Құпиясөз кемінде 8 таңбадан, әріптерден және сандардан тұруы керек';

  @override
  String get skip => 'Өткізу';

  @override
  String get termsAgreementText =>
      '<terms>Пайдалану шарттары</terms> мен <privacy>Құпиялылық саясаты</privacy> арқылы жалғастыра отырып, сіз келісесіз';

  @override
  String get enterPhoneToContinue =>
      'Жалғастыру үшін телефон нөмірін енгізіңіз';

  @override
  String get verifyAndLogin => 'Растап кіру';

  @override
  String get verifyYourPhone => 'Телефон нөміріңізді растаңыз';

  @override
  String get verifyYourEmail => 'Email-ді растаңыз';

  @override
  String get enterAuthCode =>
      'Жаңа ғана мына нөмірге жіберген 6 таңбалы кодты енгізіңіз:\n';

  @override
  String get enterEmailAuthCode =>
      'Жаңа ғана мына email-ге жіберген 6 таңбалы кодты енгізіңіз:\n';

  @override
  String get didntReceiveOTP => 'Кодты алмадыңыз ба?';

  @override
  String get resendCode => 'Кодты қайта жіберу';

  @override
  String get or => 'НЕМЕСЕ';

  @override
  String get error => 'Қате';

  @override
  String get ok => 'Түсінікті';

  @override
  String get googleLoginFailed => 'Google арқылы кіру мүмкін болмады.';

  @override
  String get appleLoginFailed => 'Apple ID арқылы кіру мүмкін болмады.';

  @override
  String get otpSendFailed => 'Кодты жіберу мүмкін болмады.';

  @override
  String get otpInvalid => 'Растау коды қате.';

  @override
  String get phoneRequiredError => 'Телефон нөмірін енгізіңіз';

  @override
  String get phoneInvalidError => 'Дұрыс телефон нөмірін енгізіңіз';

  @override
  String get homeWelcomeBack => 'Қайта келгеніңізге қуаныштымыз!';

  @override
  String get homeTravelQuestion =>
      'Келесі сапарыңызды қайда жоспарлап отырсыз?';

  @override
  String get homeExploreServices => 'Қызметтер';

  @override
  String get serviceExcursions => 'Экскурсиялар';

  @override
  String get serviceGuides => 'Гидтер';

  @override
  String get serviceHotels => 'Қонақ үйлер';

  @override
  String get serviceTransport => 'Көлік';

  @override
  String get logoutDialogTitle => 'Аккаунттан шығасыз ба?';

  @override
  String get logoutDialogMessage =>
      'Аккаунттан шығатыныңызға сенімдісіз бе? Келесі жолы қайта авторизациядан өту қажет болуы мүмкін.';

  @override
  String get logoutConfirmButton => 'Шығу';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get loginButton => 'Кіру';

  @override
  String get commonPaginationPrevious => 'Алдыңғы бет';

  @override
  String get commonPaginationNext => 'Келесі бет';

  @override
  String commonPaginationLabel(Object current, Object total) {
    return '$total беттің $current-беті';
  }

  @override
  String codeSentTo(Object phone) {
    return '$phone нөміріне код жіберілді';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get drawerStatusVerifiedGuide => 'Расталған гид';

  @override
  String get drawerStatusGuide => 'Гид';

  @override
  String get drawerStatusGuideRevoked => 'Гид мәртебесі қайтарылды';

  @override
  String get drawerStatusTraveler => 'Саяхатшы';

  @override
  String get drawerStatusCompleteProfile => 'Профильді толтырыңыз';

  @override
  String get profileNotAvailable => 'Профиль қолжетімсіз';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profilePhoneVerificationSection => 'Телефонды растау';

  @override
  String get profilePhoneVerificationTitle => 'Байланыс нөмірі';

  @override
  String get profilePhoneVerificationDescription =>
      'Брондау және маңызды әрекеттерді қорғау үшін нөміріңізді SMS арқылы растаңыз.';

  @override
  String get profilePhoneVerifiedTitle => 'Телефон расталды';

  @override
  String get profilePhoneVerifiedDescription =>
      'Бұл нөмір маңызды әрекеттер үшін сенімді байланыс ретінде қолданылады.';

  @override
  String profilePhoneVerifiedAs(Object phone) {
    return 'Расталды: $phone';
  }

  @override
  String profilePhoneCurrentVerifiedAs(Object phone) {
    return 'Ағымдағы нөмір: $phone';
  }

  @override
  String get profilePhoneSendCode => 'Код жіберу';

  @override
  String profilePhoneCodeSentTo(Object phone) {
    return 'Код $phone нөміріне жіберілді';
  }

  @override
  String get profilePhoneCodeHint => 'SMS коды';

  @override
  String get profilePhoneVerifyCode => 'Телефонды растау';

  @override
  String get profilePhoneResendCode => 'Қайта жіберу';

  @override
  String profilePhoneResendIn(Object seconds) {
    return '$seconds с кейін қайта';
  }

  @override
  String get profilePhoneChangeNumber => 'Нөмірді өзгерту';

  @override
  String get profilePhoneCancelChange => 'Ағымдағы нөмірді қалдыру';

  @override
  String get profilePhoneInvalid =>
      'Нөмірді халықаралық форматта енгізіңіз, мысалы +77011234567.';

  @override
  String get profilePhoneAlreadyVerified =>
      'Бұл нөмір әлдеқашан расталған. Басқа нөмір енгізіңіз.';

  @override
  String get profilePhoneUnavailable =>
      'Бұл нөмір қолданыста немесе қолжетімсіз.';

  @override
  String get profilePhoneCodeExpired =>
      'Кодтың мерзімі өтті. Жаңа код жіберіңіз.';

  @override
  String get profilePhoneCodeInvalid => 'Растау коды қате.';

  @override
  String get profilePhoneVerificationLocked =>
      'Қате әрекет тым көп. Жаңа кодты кейін сұраңыз.';

  @override
  String get profilePhoneRateLimited =>
      'Тым жиі. Қайта жібермес бұрын күтіңіз.';

  @override
  String get profilePhoneVerificationUnavailable =>
      'Телефонды растау уақытша қолжетімсіз.';

  @override
  String get profilePhoneVerificationFailed =>
      'Телефонды растау мүмкін болмады. Қайта көріңіз.';

  @override
  String get profilePhoneCodeRequired => 'SMS кодын енгізіңіз.';

  @override
  String get profilePhoneStartRequired =>
      'Алдымен телефон нөміріне код жіберіңіз.';

  @override
  String get profileFullName => 'Аты-жөні';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Тіл';

  @override
  String get profileTimezone => 'Уақыт белдеуі';

  @override
  String get profileTimezoneSearchHint =>
      'Уақыт белдеуін, қаланы немесе UTC іздеу';

  @override
  String get profileTimezoneNoResults => 'Уақыт белдеулері табылмады';

  @override
  String profileTimezoneRecommendedForCountry(Object country) {
    return '$country үшін ұсынылады';
  }

  @override
  String timeDisplayYourTime(Object time) {
    return 'Сіздің уақытыңыз: $time';
  }

  @override
  String get profileCountry => 'Ел';

  @override
  String get profileCurrency => 'Валюта';

  @override
  String get profileCurrencySearchHint =>
      'Валютаны, кодты немесе таңбаны іздеу';

  @override
  String get profileCurrencyNoResults => 'Валюталар табылмады';

  @override
  String get editProfileButton => 'Профильді өңдеу';

  @override
  String get becomeGuideButton => 'Гид болу';

  @override
  String get guideVerificationTitle => 'Гид мәртебесіне өтінім';

  @override
  String guideVerificationStepCounter(Object current, Object total) {
    return '$total қадамның $current-қадамы';
  }

  @override
  String get guideVerificationStepIdentity => 'Жеке дерек';

  @override
  String get guideVerificationStepDocument => 'Құжат';

  @override
  String get guideVerificationStepLicense => 'Біліктілік';

  @override
  String get guideVerificationStepSubmit => 'Жіберу';

  @override
  String get guideVerificationHeroTitle => 'Гид мәртебесін растаңыз';

  @override
  String get guideVerificationHeroSubtitle =>
      'Профильді тексеріп, кәсіби мүмкіндіктерді ашу үшін анкетаны толтырып, құжаттарды жүктеңіз.';

  @override
  String get guideVerificationIdentitySection => 'Негізгі ақпарат';

  @override
  String get guideVerificationFullNameLabel => 'Толық аты-жөні';

  @override
  String get guideVerificationFullNameHint => 'Жеке куәліктегі сияқты';

  @override
  String get guideVerificationBirthDateLabel => 'Туған күні';

  @override
  String get guideVerificationBirthDateHint => 'КК.АА.ЖЖЖЖ';

  @override
  String get guideVerificationNationalityLabel => 'Азаматтығы';

  @override
  String get guideVerificationSelectCountry => 'Елді таңдаңыз';

  @override
  String get guideVerificationIdentityNotice =>
      'Бұл деректер тек жеке басыңызды және гид мәртебесін растау үшін қолданылады.';

  @override
  String get guideVerificationContinueToDocuments => 'Құжаттарға өту';

  @override
  String get guideVerificationDocumentTypeLabel => 'Құжат түрі';

  @override
  String get guideVerificationPassport => 'Паспорт';

  @override
  String get guideVerificationNationalId => 'Жеке куәлік';

  @override
  String get guideVerificationUploadPhotoTitle => 'Жеке құжатты жүктеңіз';

  @override
  String get guideVerificationUploadPhotoSubtitle =>
      'Құжаттың алдыңғы жағының анық фотосын немесе сканын жүктеңіз.';

  @override
  String get guideVerificationNoGlare => 'Жарқылсыз';

  @override
  String get guideVerificationNoGlareHint =>
      'Мәтін анық көрінуі үшін суретті біркелкі жарықта түсіріңіз.';

  @override
  String get guideVerificationFullFrame => 'Толық кадр';

  @override
  String get guideVerificationFullFrameHint =>
      'Құжаттың барлық шеттері суретте анық көрінуі керек.';

  @override
  String get guideVerificationTapToCapturePassport =>
      'Құжат файлын таңдау үшін басыңыз';

  @override
  String get guideVerificationFileFormatsShort => 'JPG, PNG, PDF, 10 МБ дейін';

  @override
  String get guideVerificationChooseFile => 'Файл таңдау';

  @override
  String get guideVerificationDocumentConfirm =>
      'Бұл құжаттың жарамды екенін, мерзімі өтпегенін және ұсынылған фото автоматтандырылған тексеру жүйелері үшін анық оқылатынын растаймын.';

  @override
  String get guideVerificationVerifyContinue => 'Тексеруді жалғастыру';

  @override
  String get guideVerificationCredentialsTitle => 'Біліктілік пен лицензия';

  @override
  String get guideVerificationCredentialsSubtitle =>
      'Тәжірибеңіз бен гид ретінде жұмыс істеу құқығын растайтын құжатты көрсетіңіз.';

  @override
  String get guideVerificationLicenseLabel => 'Растайтын құжат түрі';

  @override
  String get guideVerificationSelectLicenseType => 'Құжат түрін таңдаңыз';

  @override
  String get guideVerificationOfficialExcursionGuideLicense =>
      'Ресми экскурсия гиді лицензиясы';

  @override
  String get guideVerificationCityGuidePermit => 'Қалалық гид рұқсаты';

  @override
  String get guideVerificationMuseumAccreditation =>
      'Мұражай немесе нысан аккредитациясы';

  @override
  String get guideVerificationUploadLicenseTitle =>
      'Растайтын құжатты жүктеңіз';

  @override
  String get guideVerificationUploadLicenseSubtitle =>
      'Мұнда сертификат, лицензия немесе басқа кәсіби құжат жарайды.';

  @override
  String get guideVerificationAdditionalCertifications => 'Қосымша дағдылар';

  @override
  String get guideVerificationUploadFirstAidTitle =>
      'Алғашқы көмек сертификатын жүктеңіз';

  @override
  String get guideVerificationUploadFirstAidSubtitle =>
      'Міндетті емес: өтінімді күшейту үшін сертификат қоса аласыз.';

  @override
  String get guideVerificationUploadLanguageTitle =>
      'Тіл сертификатын жүктеңіз';

  @override
  String get guideVerificationUploadLanguageSubtitle =>
      'Міндетті емес: тіл білу деңгейін растайтын сертификат қоса аласыз.';

  @override
  String get guideVerificationFirstAid => 'Алғашқы көмек';

  @override
  String get guideVerificationFirstAidHint =>
      'Сізде алғашқы көмек бойынша жарамды курс немесе сертификат бар.';

  @override
  String get guideVerificationLanguageProficiency => 'Шет тілдері';

  @override
  String get guideVerificationLanguageProficiencyHint =>
      'Сіз белсенділіктер мен экскурсияларды бірнеше тілде өткізе аласыз.';

  @override
  String get guideVerificationTimelineTitle => 'Қарау мерзімі';

  @override
  String get guideVerificationTimelineText =>
      'Әдетте өтінімдер 1–3 жұмыс күні ішінде қаралады. Қосымша ақпарат керек болса, оны профильде көрсетеміз.';

  @override
  String get guideVerificationReviewHeroTitle =>
      'Жіберер алдында деректерді тексеріңіз';

  @override
  String get guideVerificationReviewHeroSubtitle =>
      'Барлығы дұрыс толтырылғанына көз жеткізіңіз. Жібергеннен кейін өтінім тексеруге кетеді.';

  @override
  String get guideVerificationReviewTitle => 'Өтінім қорытындысы';

  @override
  String get guideVerificationEditInfo => 'Өңдеу';

  @override
  String get guideVerificationIdentityDocumentCard => 'Жеке құжат';

  @override
  String get guideVerificationProfessionalLicenseCard => 'Кәсіби құжат';

  @override
  String get guideVerificationFirstAidCertificateCard =>
      'Алғашқы көмек сертификаты';

  @override
  String get guideVerificationLanguageCertificateCard => 'Тіл сертификаты';

  @override
  String get guideVerificationVerifiedUpload => 'Файл жүктелді';

  @override
  String get guideVerificationTermsTitle => 'Растау';

  @override
  String get guideVerificationTermsHeading =>
      'Деректердің дұрыстығын растаймын';

  @override
  String get guideVerificationTermsBody =>
      'Егер ақпарат шындыққа сәйкес келмесе немесе құжаттар талапқа сай болмаса, Inflap өтінімді кері қайтара алатынын түсінемін.';

  @override
  String get guideVerificationAgreement =>
      'Гид мәртебесін растау үшін құжаттарды тексеруге және деректерді өңдеуге келісемін.';

  @override
  String get guideVerificationSubmit => 'Өтінімді жіберу';

  @override
  String get guideVerificationReviewNote =>
      'Жібергеннен кейін өтінім мәртебесін профильден бақылай аласыз.';

  @override
  String get guideVerificationPendingTitle => 'Өтінім тексеріліп жатыр';

  @override
  String get guideVerificationPendingSubtitle =>
      'Біз құжаттарыңызды алдық және қазір қарап жатырмыз. Мәртебе өзгерсе, ол профильде көрінеді.';

  @override
  String get guideVerificationActiveTitle =>
      'Гид мәртебесі әлдеқашан расталған';

  @override
  String get guideVerificationActiveSubtitle =>
      'Профиліңіз гид профилі ретінде әлдеқашан белсенді. Қайта жіберудің қажеті жоқ.';

  @override
  String get guideVerificationRejectedTitle => 'Өтінімді толықтыру қажет';

  @override
  String get guideVerificationRejectedSubtitle =>
      'Алдыңғы өтінім қабылданбады. Деректерді жаңартып, құжаттарды қайта жібере аласыз.';

  @override
  String get guideVerificationDraftSubtitle =>
      'Сізде өтінімнің черновигі бар. Ағымдағы деректермен жалғастырып, дайын болғанда тексеруге жібере аласыз.';

  @override
  String get guideVerificationViewApplicationButton => 'Өтінімді көру';

  @override
  String get guideVerificationContinueButton => 'Жалғастыру';

  @override
  String get guideVerificationBackToProfile => 'Профильге оралу';

  @override
  String get guideVerificationFullNameRequired =>
      'Толық аты-жөніңізді енгізіңіз';

  @override
  String get guideVerificationFullNameInvalid =>
      'Аты мен тегін толық енгізіңіз';

  @override
  String get guideVerificationBirthDateRequired => 'Туған күніңізді енгізіңіз';

  @override
  String get guideVerificationBirthDateInvalid =>
      'ДД.ММ.ЖЖЖЖ форматында дұрыс күнді енгізіңіз';

  @override
  String get guideVerificationNationalityRequired => 'Азаматтығыңызды таңдаңыз';

  @override
  String get guideVerificationIdentityFileRequired => 'Жеке құжатты жүктеңіз';

  @override
  String get guideVerificationProfessionalFileRequired =>
      'Кәсіби құжатты жүктеңіз';

  @override
  String get guideVerificationConfirmationRequired =>
      'Құжаттың жарамды екенін және фотоның анық оқылатынын растаңыз';

  @override
  String get guideVerificationAgreementRequired =>
      'Құжаттарды тексеруге келісім беру қажет';

  @override
  String get guideVerificationUploadFailed => 'Файлды жүктеу мүмкін болмады';

  @override
  String get guideVerificationUnsupportedFormat =>
      'Тек JPG, PNG, WEBP және PDF форматтары қолдау табады';

  @override
  String get guideVerificationSubmitFailed => 'Өтінімді жіберу мүмкін болмады';

  @override
  String get guideVerificationDocumentsRequired =>
      'Өтінім үшін жеке құжат пен кәсіби құжат міндетті';

  @override
  String get logoutButton => 'Шығу';

  @override
  String welcomeUser(Object name) {
    return 'Қош келдіңіз, $name';
  }

  @override
  String get openProfileHint => 'Профильді ашу үшін басыңыз';

  @override
  String get userFallbackName => 'дос';

  @override
  String get notSpecified => 'Көрсетілмеген';

  @override
  String get profileIncompleteTitle => 'Профиль толық толтырылмаған';

  @override
  String get profileIncompleteDescription =>
      'Inflap мүмкіндіктерін толық пайдалану үшін никнеймді, атыңызды, тегіңізді және еліңізді толтырыңыз';

  @override
  String get fillNowButton => 'Толтыру';

  @override
  String get appLanguageTitle => 'Қолданба тілі';

  @override
  String get saveProfileButton => 'Сақтау';

  @override
  String get profileSaveFailed => 'Профильді сақтау сәтсіз аяқталды';

  @override
  String get profileNicknameTaken => 'Бұл никнейм бос емес';

  @override
  String get profileNicknameOneTimeHint =>
      'Никнеймді тек бір рет қоюға болады. Сақталғаннан кейін оны өзгерту мүмкін емес.';

  @override
  String get profileNicknameChecking => 'Никнейм тексеріліп жатыр...';

  @override
  String get profileNicknameAvailable => 'Никнейм бос';

  @override
  String get profileNicknameCheckFailed =>
      'Никнеймді тексеру мүмкін болмады. Қайталап көріңіз.';

  @override
  String get firstNameLabel => 'Аты';

  @override
  String get lastNameLabel => 'Тегі';

  @override
  String get nicknameLabel => 'Никнейм';

  @override
  String get nicknameRequired => 'Никнеймді енгізіңіз';

  @override
  String get profileNicknameLockedDescription =>
      'Никнеймді тек бір рет қоюға болады. Сақталғаннан кейін оны өзгерту мүмкін емес.';

  @override
  String get bioLabel => 'Өзі туралы';

  @override
  String get firstNameRequired => 'Атыңызды енгізіңіз';

  @override
  String get lastNameRequired => 'Тегіңізді енгізіңіз';

  @override
  String get profileCountryRequired => 'Елді таңдаңыз';

  @override
  String get profileRequiredTitle => 'Профильді толтырыңыз';

  @override
  String get profileRequiredDescription =>
      'Жалғастыру үшін профиліңізде никнеймді, атыңызды, тегіңізді және еліңізді көрсетіңіз. Бұл жалған аккаунттарды азайтып, пайдаланушылар арасындағы сенімді арттырады.';

  @override
  String get myProfileTitle => 'Менің профилім';

  @override
  String get profileLinkCopied => 'Профиль сілтемесі көшірілді';

  @override
  String get profileVerifiedExplorer => 'РАСТАЛҒАН ГИД';

  @override
  String get profileGuideTitle => 'Inflap гиді';

  @override
  String get profileGuideRatingLabel => 'Гид рейтингі';

  @override
  String get profileEmptyBioPlaceholder =>
      'Қазір мұнда сипаттама жоқ. Профиль толтырылған кезде қысқаша ақпарат осы жерде көрсетіледі.';

  @override
  String get profileBecomeGuideTitle => 'Гид болыңыз';

  @override
  String get profileBecomeGuideSubtitle =>
      'Жақында осы жерден өтінім беріп, кәсіби гид профилін аша аласыз.';

  @override
  String get guideVerificationRevokedTitle => 'Гид мәртебесі қайтарылды';

  @override
  String get guideVerificationRevokedSubtitle =>
      'Модерация сіздің гид мәртебеңізді қайтарды. Гид функциялары мен жария ұсыныстар қолжетімсіз.';

  @override
  String guideVerificationRevokedSubtitleWithReason(Object reason) {
    return 'Модерация сіздің гид мәртебеңізді қайтарды. Себебі: $reason';
  }

  @override
  String get guideVerificationRevokedButton => 'Мәртебе қайтарылды';

  @override
  String get profileActivitiesStat => 'Белсенділіктер';

  @override
  String get profileHostedCompletedStat => 'Автор ретінде аяқталды';

  @override
  String get profileJoinedCompletedStat => 'Қатысушы ретінде аяқталды';

  @override
  String get profileReviewsStat => 'Пікірлер';

  @override
  String get profileStoriesStat => 'Хикаялар';

  @override
  String get profileFollowersStat => 'Фолловеры';

  @override
  String get profileFollowersTitle => 'Фолловерлер';

  @override
  String get profileFollowersSearchHint => 'Фолловерлерді іздеу';

  @override
  String get profileFollowersEmptyTitle => 'Әзірге фолловерлер жоқ';

  @override
  String get profileFollowersEmptySubtitle =>
      'Бұл профильге пайдаланушылар жазылған кезде, олар осында көрсетіледі.';

  @override
  String get profileFollowersSearchEmptyTitle => 'Ештеңе табылмады';

  @override
  String get profileFollowersSearchEmptySubtitle =>
      'Сұрауды өзгертіп көріңіз немесе іздеуді тазалаңыз.';

  @override
  String get profileFollowersLoadFailed =>
      'Фолловерлерді жүктеу мүмкін болмады';

  @override
  String get profileConnectionsTitle => 'Достар және жазылымдар';

  @override
  String get profileConnectionsSubtitle =>
      'Достарыңызды және бақылап жүрген пайдаланушыларды басқарыңыз.';

  @override
  String get profileConnectionsSearchHint => 'Адамдарды іздеу';

  @override
  String get profileConnectionsFriendsTab => 'Достар';

  @override
  String get profileConnectionsFollowingTab => 'Жазылымдар';

  @override
  String get profileConnectionsFriendsEmptyTitle => 'Әзірге достар жоқ';

  @override
  String get profileConnectionsFriendsEmptySubtitle =>
      'Достық сұрауы қабылданғанда, пайдаланушы осында шығады.';

  @override
  String get profileConnectionsFollowingEmptyTitle => 'Әзірге жазылымдар жоқ';

  @override
  String get profileConnectionsFollowingEmptySubtitle =>
      'Сіз бақылап жүрген пайдаланушылар осында шығады.';

  @override
  String get profileConnectionsLoadFailed => 'Тізімді жүктеу мүмкін болмады';

  @override
  String get profileConnectionsSortRecent => 'Жаңалары';

  @override
  String get profileConnectionsSortName => 'Аты';

  @override
  String get profileConnectionsFiltersTitle => 'Сүзгілер';

  @override
  String get profileConnectionsFiltersShowResults => 'Нәтижелерді көрсету';

  @override
  String get profileConnectionsFilterOnlineOnly => 'Тек онлайн';

  @override
  String get profileConnectionsFilterOnlineOnlySubtitle =>
      'Қазір желіде отырған пайдаланушыларды көрсету.';

  @override
  String get profileConnectionsFriendRequestsTitle => 'Достық сұраулары';

  @override
  String get profileConnectionsFriendRequestsViewAll => 'Барлық сұраулар';

  @override
  String get profileConnectionsFriendRequestsEmptyTitle => 'Сұраулар жоқ';

  @override
  String get profileConnectionsFriendRequestsEmptySubtitle =>
      'Жаңа кіріс достық сұраулары осы жерде көрсетіледі.';

  @override
  String get profileJourneyTitle => 'Менің жолым';

  @override
  String get profileSavedItemsTitle => 'Сақталғандар';

  @override
  String get profileSavedItemsSubtitle =>
      'Сақталған белсенділіктер, орындар мен жинақтар кейінірек осында пайда болады.';

  @override
  String get profileBookingsTitle => 'Менің броньдарым';

  @override
  String get profileBookingsSubtitle =>
      'Тапсырыстар мен расталған броньдар жақында осы жерде көрсетіледі.';

  @override
  String get profileMyActivitiesSubtitle =>
      'Өз белсенділіктеріңізді басқарып, қатысуларыңызды бақылаңыз.';

  @override
  String get profilePreferencesTitle => 'Қалаулар';

  @override
  String get profileNotificationsRowTitle => 'Хабарландырулар';

  @override
  String get profileNotificationsRowSubtitle =>
      'Белсенділіктерге қатысты push, email және SMS жаңартулары.';

  @override
  String get profileSecurityRowTitle => 'Қауіпсіздік және деректер';

  @override
  String get profileSecurityRowSubtitle =>
      'Аккаунт қорғанысы, деректерді экспорттау және құпиялылық баптаулары.';

  @override
  String get profileHostedActivitiesTitle => 'Автор белсенділіктері';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Backend автордың ашық витринасын бергенде, жарияланған белсенділіктер осы жерде көрсетіледі.';

  @override
  String get profileRecentActivitiesTitle => 'Соңғы белсенділіктер';

  @override
  String get profileViewAllActivities => 'Барлығы';

  @override
  String get profileActivitiesLoadFailed =>
      'Белсенділіктерді жүктеу мүмкін болмады';

  @override
  String get profileActivitiesLoadFailedHint =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get profileActivitiesEmptyTitle => 'Әзірге белсенділіктер жоқ';

  @override
  String get profileActivitiesEmptySubtitle =>
      'Пайдаланушының аяқталған ашық белсенділіктері осы жерде көрсетіледі.';

  @override
  String get profileUserActivitiesTitle => 'Пайдаланушы белсенділіктері';

  @override
  String get profileUserActivitiesHostedTab => 'Өткізген';

  @override
  String get profileUserActivitiesVisitedTab => 'Қатысқан';

  @override
  String get profileUserActivitiesHostedEmptyTitle =>
      'Әзірге өткізген белсенділіктер жоқ';

  @override
  String get profileUserActivitiesHostedEmptySubtitle =>
      'Пайдаланушы автор ретінде ашық белсенділікті аяқтағанда, ол осы жерде көрсетіледі.';

  @override
  String get profileUserActivitiesVisitedEmptyTitle =>
      'Әзірге қатысқан белсенділіктер жоқ';

  @override
  String get profileUserActivitiesVisitedEmptySubtitle =>
      'Пайдаланушы аяқталған ашық белсенділікке қатысқанда, ол осы жерде көрсетіледі.';

  @override
  String get profilePopularStoriesTitle => 'Танымал посттар';

  @override
  String get profileViewAllStories => 'Барлығы';

  @override
  String get profileStoriesLoadFailed => 'Посттарды жүктеу мүмкін болмады';

  @override
  String get profileStoriesLoadFailedHint =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get profileStoriesEmptyTitle => 'Әзірге посттар жоқ';

  @override
  String get profileStoriesEmptySubtitle =>
      'Пайдаланушының жарияланған посттары осы жерде көрсетіледі.';

  @override
  String get profileUserStoriesTitle => 'Пайдаланушы посттары';

  @override
  String get profileStoriesTitle => 'Соңғы посттар';

  @override
  String get profileStoriesUnavailable =>
      'Ашық посттар мен саяхат мақалалары қолданбада әлі қолжетімді емес.';

  @override
  String get profileUnavailableTitle => 'Жақында';

  @override
  String get profileFollowAction => 'Қадағалау';

  @override
  String get profileFollowingAction => 'Жазылған';

  @override
  String get profileUnfollowTitle => 'Пайдаланушыдан бас тарту керек пе?';

  @override
  String get profileUnfollowDescription =>
      'Бұл пайдаланушының жаңартуларын лентаңызда бақыламайсыз.';

  @override
  String get profileUnfollowConfirm => 'Бас тарту';

  @override
  String get profileUnfollowAction => 'Бақылауды тоқтату';

  @override
  String get profileFollowUpdateFailed => 'Жазылу күйін жаңарту мүмкін болмады';

  @override
  String get profileAddFriendAction => 'Дос қосу';

  @override
  String get profileFriendRequestSentAction => 'Өтінім жіберілді';

  @override
  String get profileFriendRequestTitle => 'Достық сұрауы';

  @override
  String get profileFriendRequestAcceptAction => 'Қосу';

  @override
  String get profileFriendRequestDeclineAction => 'Қабылдамау';

  @override
  String get profileAcceptFriendAction => 'Қабылдау';

  @override
  String get profileDeclineFriendAction => 'Қабылдамау';

  @override
  String get profileFriendsAction => 'Достар';

  @override
  String get profileRemoveFriendAction => 'Досты жою';

  @override
  String get profileRemoveFriendTitle => 'Досты жою керек пе?';

  @override
  String get profileRemoveFriendDescription =>
      'Жаңа өтінім қабылданғанша, бұл пайдаланушыны дос ретінде шақыра алмайсыз.';

  @override
  String get profileRemoveFriendConfirm => 'Жою';

  @override
  String get profileFriendshipUpdateFailed =>
      'Достық күйін жаңарту мүмкін болмады';

  @override
  String get profileMessageAction => 'Жазу';

  @override
  String get profileMessageOpenFailed =>
      'Чатты ашу мүмкін болмады. Қайта көріңіз.';

  @override
  String get profileSettingsPageTitle => 'Баптаулар';

  @override
  String get profileSaveChangesButton => 'Өзгерістерді сақтау';

  @override
  String get profileDeactivateAccountLabel => 'Аккаунтты өшіру';

  @override
  String get profileSettingsAvatarDisabledHint =>
      'Профиль суретін өзгерту келесі жаңартулардың бірінде қосылады.';

  @override
  String get profileSettingsAvatarUploadHint =>
      'Профиль суретін таңдау үшін аватарды немесе өңдеу белгішесін басыңыз.';

  @override
  String get profileSettingsAvatarUploading =>
      'Жаңа профиль суреті жүктелуде...';

  @override
  String get profileSettingsAvatarUploadFailed =>
      'Профиль суретін жүктеу мүмкін болмады';

  @override
  String get profileSettingsAvatarUnsupportedFormat =>
      'Профиль суреті JPG, PNG немесе WEBP форматында болуы керек';

  @override
  String get profileSettingsDescriptionSection => 'Сипаттама';

  @override
  String get profileSettingsDetailsSection => 'Профиль деректері';

  @override
  String get profileSettingsServiceCitiesSection => 'Қызмет қалалары';

  @override
  String get profileSettingsServiceCitiesUnavailable =>
      'Қызмет қалалары backend-та әлі қолдау таппаған, сондықтан бұл блок әзірге белсенді емес.';

  @override
  String get profileSettingsAddNew => 'Қосу';

  @override
  String get profileAccountSectionTitle => 'Аккаунт';

  @override
  String get profileSettingsEditSubtitle =>
      'Атыңызды, фотоңызды, биоңызды және негізгі профиль деректерін өзгертіңіз.';

  @override
  String get profileOverviewSectionTitle => 'Профиль шолуы';

  @override
  String get profileMoreSectionTitle => 'Қосымша';

  @override
  String get profileGuideWorkspaceTitle => 'Гид кабинеті';

  @override
  String get profileGuideWorkspaceSubtitle =>
      'Кәсіби гид құралдары мобильді қосымшада әзірге қолжетімді емес.';

  @override
  String get profileGuideDashboardTitle => 'Гид кабинеті';

  @override
  String get profileGuideDashboardSubtitle =>
      'Ұсыныстарды, клиент брондарын және өткен экскурсияларды басқарыңыз.';

  @override
  String get profileSupportTitle => 'Көмек және қолдау';

  @override
  String get profileSupportSubtitle =>
      'Көмек орталығы мен қолдау сұраулары кейінірек қосылады.';

  @override
  String get profileNotificationsPageTitle => 'Хабарландырулар';

  @override
  String get profileNotificationsHeroTitle => 'Барлығынан хабардар болыңыз';

  @override
  String get profileNotificationsHeroSubtitle =>
      'Inflap маңыздысын уақытында жіберіп, артық мазаламауы үшін push, тыныш сағаттар және қосымша арналарды баптаңыз.';

  @override
  String get profileNotificationsDeliverySection => 'Push жеткізу';

  @override
  String get profileNotificationsCategoriesSection => 'Push санаттары';

  @override
  String get profileNotificationsQuietHoursSection => 'Тыныш сағаттар';

  @override
  String get profileNotificationsChannelsSection => 'Қосымша арналар';

  @override
  String get profileNotificationsActivitySection =>
      'Белсенділіктер және қатысу';

  @override
  String get profileNotificationsDiscoverySection => 'Ұсыныстар мен топтамалар';

  @override
  String get profileNotificationsPushTitle => 'Push-хабарламалар';

  @override
  String get profileNotificationsPushSubtitle =>
      'Осы құрылғыдағы push үшін негізгі қосқыш. Қолданба ішіндегі inbox хабарландыруларды сақтай береді.';

  @override
  String get profileNotificationsPushPausedTitle => 'Push уақытша тоқтатылды';

  @override
  String get profileNotificationsPushPausedSubtitle =>
      'Құрылғыға push жібермейміз, бірақ маңызды оқиғалар қолданбадағы хабарландыру орталығында қалады.';

  @override
  String get profileNotificationsPushEnabledStatus => 'Push қосулы';

  @override
  String get profileNotificationsPushPausedStatus => 'Push үзілісте';

  @override
  String get profileNotificationsEmailTitle => 'Email-хабарламалар';

  @override
  String get profileNotificationsEmailSubtitle =>
      'Растау хаттары, еске салғыштар және пайдалы жаңартулар поштаңызға жіберіледі.';

  @override
  String get profileNotificationsSmsTitle => 'SMS-хабарламалар';

  @override
  String get profileNotificationsSmsSubtitle =>
      'Маңызды жаңартулар мен растаулар қысқа хабарлама арқылы келеді.';

  @override
  String get profileNotificationsActivityPushTitle => 'Белсенділіктер';

  @override
  String get profileNotificationsActivityPushSubtitle =>
      'Жаңа қатысушылар, статус өзгерістері, уақыт ауысуы және белсенділік еске салғыштары.';

  @override
  String get profileNotificationsExcursionPushTitle => 'Экскурсиялар';

  @override
  String get profileNotificationsExcursionPushSubtitle =>
      'Брондаулар, кесте, өтінімдер, жариялау статустары және экскурсия оқиғалары.';

  @override
  String get profileNotificationsChatPushTitle => 'Хабарламалар';

  @override
  String get profileNotificationsChatPushSubtitle =>
      'Чаттардағы жаңа хабарламалар, шақырулар және маңызды жауаптар.';

  @override
  String get profileNotificationsMarketingTitle => 'Топтамалар мен ұсыныстар';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Саяхат идеялары, орындар топтамасы және жеке ұсыныстар. Мұны өшірсеңіз де, сервистік хабарламалар қалады.';

  @override
  String get profileNotificationsSystemTitle =>
      'Жүйелік және қауіпсіздік хабарламалары';

  @override
  String get profileNotificationsSystemSubtitle =>
      'Аккаунт қауіпсіздігі, төлемдер және қолжетімділік туралы маңызды хабарламаларды қолданба ішінде өшіруге болмайды.';

  @override
  String get profileNotificationsQuietHoursTitle => 'Мазаламау';

  @override
  String profileNotificationsQuietHoursSubtitle(Object start, Object end) {
    return 'Кәдімгі push $start - $end аралығында тыныш болады. Шұғыл high-priority хабарламалар бірден жеткізіледі.';
  }

  @override
  String get profileNotificationsQuietHoursStart => 'Басталуы';

  @override
  String get profileNotificationsQuietHoursEnd => 'Аяқталуы';

  @override
  String profileNotificationsQuietHoursTimezone(Object timezone) {
    return 'Профиль уақыт белдеуі қолданылады: $timezone';
  }

  @override
  String get profileNotificationsQuietHoursEnabledStatus =>
      'Тыныш сағаттар қосулы';

  @override
  String get profileNotificationsQuietHoursDisabledStatus =>
      'Тыныш сағаттар жоқ';

  @override
  String get profileNotificationsPreferencesLoadFailedTitle =>
      'Push баптауларын жүктеу мүмкін болмады';

  @override
  String get profileNotificationsPreferencesLoadFailedSubtitle =>
      'Қосылымды тексеріңіз. Email және SMS бөлек өзгере береді, бірақ push баптаулары уақытша қолжетімсіз.';

  @override
  String get profileNotificationsDarkModeTitle => 'Қараңғы режим';

  @override
  String get profileNotificationsDarkModeSubtitle =>
      'Бұл баптау кейінірек қосылады. Әзірге қолданба ағымдағы палитраны пайдаланады.';

  @override
  String get profileNotificationsSaveFailed =>
      'Хабарландыру баптауларын жаңарту мүмкін болмады';

  @override
  String get profileSecurityPageTitle => 'Қауіпсіздік және деректер';

  @override
  String get profileSecurityHeroTitle => 'Қолжетімділікті қорғаңыз';

  @override
  String get profileSecurityHeroSubtitle =>
      'Мұнда аккаунт қорғанысы, деректерді экспорттау және құпиялылық баптаулары жиналады.';

  @override
  String get profileSecurityAccountSection => 'Аккаунт қорғанысы';

  @override
  String get profileSecurityDataSection => 'Деректер және құпиялылық';

  @override
  String get profileSecurityPasswordTitle => 'Құпиясөзді ауыстыру';

  @override
  String get profileSecurityPasswordSubtitle =>
      'Қазіргі құпиясөзді және поштадағы бір реттік кодты растаңыз.';

  @override
  String get profileSecurityPasswordAction => 'Ауыстыру';

  @override
  String get profileSecurityPasswordSheetTitle => 'Құпиясөзді ауыстыру';

  @override
  String get profileSecurityPasswordSheetSubtitle =>
      'Алдымен қазіргі құпиясөзді растаңыз. Содан кейін байланыстырылған поштаға код жібереміз.';

  @override
  String get profileSecurityPasswordCurrentLabel => 'Қазіргі құпиясөз';

  @override
  String get profileSecurityPasswordCurrentHint =>
      'Қазіргі құпиясөзді енгізіңіз';

  @override
  String get profileSecurityPasswordCodeNotice =>
      'Код аккаунттың расталған поштасына жіберілді.';

  @override
  String get profileSecurityPasswordNewLabel => 'Жаңа құпиясөз';

  @override
  String get profileSecurityPasswordConfirmLabel =>
      'Жаңа құпиясөзді қайталаңыз';

  @override
  String get profileSecurityPasswordSendCode => 'Код жіберу';

  @override
  String get profileSecurityPasswordSave => 'Құпиясөзді сақтау';

  @override
  String get profileSecurityPasswordSuccess => 'Құпиясөз өзгертілді.';

  @override
  String get profileSecurityPasswordChangeFailed =>
      'Құпиясөзді ауыстыру мүмкін болмады. Деректерді тексеріп, қайта көріңіз.';

  @override
  String get profileSecurityPasswordMismatchError => 'Құпиясөздер сәйкес емес';

  @override
  String get profileSecurityPasswordUnchangedError =>
      'Жаңа құпиясөз қазіргі құпиясөзден өзгеше болуы керек';

  @override
  String profileSecurityPasswordResendCodeCountdown(String time) {
    return '$time кейін қайта жіберу';
  }

  @override
  String get profileSecurityTwoFactorTitle => 'Қосымша тексеру';

  @override
  String get profileSecurityTwoFactorSubtitle =>
      'Қосымша кіру тексерістері мен сезімтал әрекеттерді растау кейінірек қосылады.';

  @override
  String get profileSecurityDataExportTitle => 'Деректерді экспорттау';

  @override
  String get profileSecurityDataExportSubtitle =>
      'Деректерді экспорттау backend-та әлі іске асырылмаған.';

  @override
  String get profileSecurityDeleteTitle => 'Аккаунтты жою';

  @override
  String get profileSecurityDeleteSubtitle =>
      'Аккаунтты басқарылатын жою backend процесі дайын болғаннан кейін қосылады.';

  @override
  String get profileStatusEnabled => 'Белсенді';

  @override
  String get profileStatusDisabled => 'Белсенді емес';

  @override
  String get profileDisabledSoon => 'Жақында';

  @override
  String get laterButton => 'Кейінірек';

  @override
  String get detectLocationButton => 'Геолокация бойынша анықтау';

  @override
  String get useDetectedLocationTitle => 'Анықталған локацияны қолданасыз ба?';

  @override
  String useDetectedLocationDescription(Object location) {
    return 'Біз сіздің локацияңызды былай анықтадық: $location. Профиль үшін қолданасыз ба?';
  }

  @override
  String get locationDetectFailed => 'Локацияны анықтау сәтсіз аяқталды';

  @override
  String get locationServicesDisabled =>
      'Құрылғыда геолокация қызметтері өшірілген';

  @override
  String get locationPermissionDenied => 'Геолокацияға рұқсат берілмеген';

  @override
  String get locationPermissionDeniedForever =>
      'Геолокацияға қолжетімсіз. Құрылғы баптауларында рұқсат беріңіз';

  @override
  String get cancelButton => 'Бас тарту';

  @override
  String get useButton => 'Қолдану';

  @override
  String get activitiesTitle => 'Белсенділіктер';

  @override
  String get activitiesLoadFailed => 'Белсенділіктерді жүктеу мүмкін болмады';

  @override
  String get noActivitiesYet => 'Әзірге белсенділіктер жоқ';

  @override
  String get activitiesWillAppearHere =>
      'Жаңа белсенділіктер пайда болғанда, олар осы жерде көрсетіледі';

  @override
  String get activityDetailsComingSoon =>
      'Белсенділік беті жақында пайда болады';

  @override
  String get detailsButton => 'Толығырақ';

  @override
  String get retryButton => 'Қайталау';

  @override
  String get freeLabel => 'Тегін';

  @override
  String get fromLabel => 'бастап';

  @override
  String get activityStatusDraft => 'Нобай';

  @override
  String get activityStatusPublished => 'Жарияланған';

  @override
  String get activityStatusEnrollmentOpen => 'Жазылу ашық';

  @override
  String get activityStatusFull => 'Орын жоқ';

  @override
  String get activityStatusStarted => 'Басталды';

  @override
  String get activityStatusCompleted => 'Аяқталды';

  @override
  String get activityStatusCompletedEarly => 'Жоспардан ерте аяқталды';

  @override
  String get activityStatusCancelled => 'Бас тартылды';

  @override
  String get activityStatusArchived => 'Мұрағатта';

  @override
  String get activityFormatOffline => 'Офлайн';

  @override
  String get activityFormatOnline => 'Онлайн';

  @override
  String get activityFormatHybrid => 'Гибрид';

  @override
  String get activityFormatLabel => 'Формат';

  @override
  String get activityDetailsTitle => 'Белсенділік';

  @override
  String get activityDetailsLoadFailed => 'Белсенділікті жүктеу мүмкін болмады';

  @override
  String get activityNotFound => 'Белсенділік табылмады';

  @override
  String get activityAboutSection => 'Сипаттама';

  @override
  String get activityInfoSection => 'Ақпарат';

  @override
  String get activityTagsSection => 'Тегтер';

  @override
  String get activityAccessSection => 'Қолжетімділік және қауіпсіздік';

  @override
  String get activitySensitiveDetailsProtected =>
      'Нақты мекенжай, онлайн-кездесу сілтемесі және сезімтал мәліметтер тек қатысқаннан немесе расталғаннан кейін қолжетімді болады.';

  @override
  String get activitySensitiveDetailsHint =>
      'Бұл қатысушылар мен ұйымдастырушының қауіпсіздігі үшін жасалған.';

  @override
  String get activityDateAndTime => 'Күні мен уақыты';

  @override
  String get activityCategory => 'Санат';

  @override
  String get activityLanguage => 'Тіл';

  @override
  String get activityCapacity => 'Орын саны';

  @override
  String get activityPrice => 'Бағасы';

  @override
  String get activityLocation => 'Орналасуы';

  @override
  String get activityUnlimitedCapacity => 'Қатысушылар саны шектелмеген';

  @override
  String get activityLimitedCapacity => 'Орын саны шектеулі';

  @override
  String get activityJoinButton => 'Жазылу';

  @override
  String get activityLeaveButton => 'Шығу';

  @override
  String get activityLeaveInlineButton => 'Белсенділіктен шығу';

  @override
  String get activityCancelButton => 'Белсенділікті тоқтату';

  @override
  String get activityCancelConfirmTitle => 'Осы белсенділікті тоқтатасыз ба?';

  @override
  String get activityCancelConfirmDescription =>
      'Қатысушылар белсенділіктің тоқтатылғанын көреді. Не болғанын түсінуі үшін себебін көрсетіңіз.';

  @override
  String get activityCancelReasonLabel => 'Тоқтату себебі';

  @override
  String get activityCancelReasonPlaceholder =>
      'Мысалы: ұйымдастырушы ауырып қалды немесе орын өзгерді';

  @override
  String get activityCancelReasonRequired =>
      'Белсенділікті тоқтату себебін көрсетіңіз';

  @override
  String get activityCancelKeepButton => 'Артқа';

  @override
  String get activityCancelConfirmButton => 'Тоқтатуды растау';

  @override
  String get activityJoinSuccess => 'Сіз белсенділікке жазылдыңыз';

  @override
  String get activityLeaveSuccess => 'Сіз белсенділіктен шықтыңыз';

  @override
  String get activityCancelSuccess => 'Белсенділік тоқтатылды';

  @override
  String get activityJoinFailed => 'Белсенділікке жазылу мүмкін болмады';

  @override
  String get activityJoinAlreadyJoined =>
      'Сіз бұл белсенділікке әлдеқашан жазылғансыз';

  @override
  String get activityJoinScheduleConflict =>
      'Жазылу мүмкін емес: уақыты қабаттасатын басқа белсенділікке жазылып қойғансыз';

  @override
  String get activityLeaveFailed => 'Белсенділіктен шығу мүмкін болмады';

  @override
  String get activityCancelFailed => 'Белсенділікті тоқтату мүмкін болмады';

  @override
  String get activityCancelAlreadyCancelled =>
      'Белсенділік әлдеқашан тоқтатылған';

  @override
  String get activityCancelNotAllowed =>
      'Бұл белсенділікті енді тоқтату мүмкін емес';

  @override
  String get activityExtend30MinutesButton => '30 мин ұзарту';

  @override
  String get activityExtend60MinutesButton => '1 сағатқа ұзарту';

  @override
  String get activityExtendSuccess =>
      'Белсенділіктің аяқталу уақыты жаңартылды';

  @override
  String get activityExtendFailed => 'Белсенділікті ұзарту мүмкін болмады';

  @override
  String get activityExtendNotAllowed =>
      'Бұл белсенділікті енді ұзарту мүмкін емес';

  @override
  String get activityCompleteNowButton => 'Қазір аяқтау';

  @override
  String get activityCompleteSuccess => 'Белсенділік аяқталды';

  @override
  String get activityCompleteEarlySuccess =>
      'Белсенділік жоспарланған уақыттан ерте аяқталды';

  @override
  String get activityCompleteFailed => 'Белсенділікті аяқтау мүмкін болмады';

  @override
  String get activityCompleteTooEarly =>
      'Белсенділікті тек жоспарланған уақыттың соңғы 25%-ында аяқтауға болады';

  @override
  String get activityCompleteNotAllowed =>
      'Бұл белсенділікті қазір аяқтау мүмкін емес';

  @override
  String get activityCompleteAlreadyCompleted =>
      'Белсенділік әлдеқашан аяқталған';

  @override
  String get activityCompleteConfirmTitle =>
      'Белсенділікті ертерек аяқтайсыз ба?';

  @override
  String get activityCompleteConfirmDescription =>
      'Белсенділік жоспарланған уақыттан ерте аяқталады. Қатысушылар неге ерте аяқталғанын түсінуі үшін себебін көрсетіңіз.';

  @override
  String get activityCompleteReasonLabel => 'Ерте аяқтау себебі';

  @override
  String get activityCompleteReasonPlaceholder =>
      'Мысалы: бағдарлама жоспардан ерте аяқталды';

  @override
  String get activityCompleteReasonRequired => 'Ерте аяқтау себебін көрсетіңіз';

  @override
  String get activityCompleteConfirmButton => 'Аяқтауды растау';

  @override
  String get activityCompleteCancelInsteadTitle =>
      'Қазір белсенділік тоқтатылады';

  @override
  String get activityCompleteCancelInsteadDescription =>
      'Жоспарланған аяқталуға дейін әлі көп уақыт бар. Қазір жалғастырсаңыз, қатысушылар белсенділіктің аяқталғанын емес, тоқтатылғанын көреді. Тоқтату себебін көрсетіңіз.';

  @override
  String activityGoingTitle(int count) {
    return 'Қатысушылар ($count)';
  }

  @override
  String get activityDetailsViewAll => 'Барлығын көру';

  @override
  String get activityInviteFriendsButton => 'Достарды шақыру';

  @override
  String get activityInviteFriendsTitle => 'Достарды шақыру';

  @override
  String get activityInviteFriendsSearchHint => 'Достарды іздеу';

  @override
  String get activityInviteFriendsEmptyTitle => 'Шақыратын дос жоқ';

  @override
  String get activityInviteFriendsEmptySubtitle =>
      'Достар қосыңыз немесе басқа іздеу жасап көріңіз.';

  @override
  String get activityInviteFriendsLoadFailed =>
      'Достарды жүктеу мүмкін болмады';

  @override
  String get activityInviteFriendsRetryHint =>
      'Қосылымды тексеріп, қайталап көріңіз.';

  @override
  String activityInviteFriendsSend(int count) {
    return 'Шақыру ($count)';
  }

  @override
  String get activityInviteFriendsSuccess => 'Шақырулар жіберілді';

  @override
  String get activityInviteFriendsFailed => 'Шақыруларды жіберу мүмкін болмады';

  @override
  String get activityInviteFriendsAuthRequired =>
      'Достарды шақыру үшін кіріңіз';

  @override
  String get activityDetailsLinkCopied => 'Сілтеме көшірілді';

  @override
  String get activityDetailsHostedBadge => 'Сіздің белсенділігіңіз';

  @override
  String get activityDetailsJoinedBadge => 'Сіз қатысасыз';

  @override
  String get activityDetailsTotalLabel => 'Барлығы';

  @override
  String get activityDetailsChatButton => 'Белсенділік чаты';

  @override
  String get activityDetailsHostFallbackName => 'Inflap ұйымдастырушысы';

  @override
  String get activityPaymentScreenTitle => 'INFLAP CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Белсенділік туралы мәлімет';

  @override
  String get activityPaymentBreakdownTitle => 'Сома құрамы';

  @override
  String get activityPaymentMethodTitle => 'Төлем тәсілі';

  @override
  String get activityPaymentMockNoticeTitle => 'Тест checkout';

  @override
  String get activityPaymentMockNoticeBody =>
      'Нақты төлем жүйесі әлі қосылған жоқ. Бұл экран белсенділік flow-ын толық тексеру үшін сәтті төлемді ғана имитациялайды.';

  @override
  String get activityPaymentSandboxMethodLabel => 'Тест растауы';

  @override
  String activityPaymentHostedBy(Object host) {
    return 'Ұйымдастырушы: $host';
  }

  @override
  String get activityPaymentAdmissionLabel => '1x белсенділікке қатысу';

  @override
  String get activityPaymentServiceFeeLabel => 'Сервис ақысы';

  @override
  String get activityPaymentSavedCardLabel => 'Сақталған карта';

  @override
  String get activityPaymentCardHolderFallback => 'Inflap қатысушысы';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return '$amount тест төлемін растау';
  }

  @override
  String get activityPaymentSecureNote =>
      '256-биттік SSL шифрлауымен қорғалған төлем';

  @override
  String get activityPaymentMockSecureNote =>
      'Тест режимінде картадан ақша алынбайды.';

  @override
  String get activityPaymentPayButton => 'Тест төлемі';

  @override
  String get activityPaymentSuccess => 'Тест төлемі сәтті деп белгіленді';

  @override
  String get activityPaymentStatusLabel => 'Төлем';

  @override
  String get activityPaymentPaidValue => 'ТӨЛЕНДІ';

  @override
  String get activityParticipantFallbackName => 'Қатысушы';

  @override
  String get activityParticipantsEmpty => 'Әзірге қатысушы жоқ';

  @override
  String get activityParticipantsLoadFailed =>
      'Қатысушыларды жүктеу мүмкін болмады';

  @override
  String get participantStatusInvited => 'Шақырылды';

  @override
  String get participantStatusRequested => 'Сұрау жіберілді';

  @override
  String get participantStatusApproved => 'Расталды';

  @override
  String get participantStatusWaitlisted => 'Күту тізімінде';

  @override
  String get participantStatusPendingPayment => 'Төлем күтілуде';

  @override
  String get participantStatusConfirmed => 'Расталған';

  @override
  String get participantStatusDeclined => 'Қабылданбады';

  @override
  String get participantStatusCancelled => 'Бас тартылды';

  @override
  String get participantStatusExpired => 'Мерзімі өтті';

  @override
  String get participantStatusCheckedIn => 'Келгені белгіленді';

  @override
  String get participantStatusNoShow => 'Келмеді';

  @override
  String get activityPrivateJoinTitle => 'Жеке белсенділік';

  @override
  String get activityPrivateJoinDescription =>
      'Бұл белсенділік тек шақырылғандарға арналған. Қосылу үшін құпиясөзді енгізіңіз.';

  @override
  String get activityPrivateJoinPasswordLabel => 'Қол жеткізу құпиясөзі';

  @override
  String get activityPrivateJoinPasswordPlaceholder =>
      'Қол жеткізу құпиясөзін енгізіңіз';

  @override
  String get activityPrivateJoinPasswordValidation =>
      '4-тен 64 таңбаға дейінгі құпиясөзді енгізіңіз';

  @override
  String get activityPrivateJoinInvalidPassword =>
      'Қате құпиясөз. Қайта көріңіз.';

  @override
  String get activityPrivateJoinSubmit => 'Тексеру және қосылу';

  @override
  String get homeTitle => 'Inflap';

  @override
  String get homeSubtitle =>
      'Саяхаттап, белсенділіктерді тауып, жаңа әсерлер ашыңыз';

  @override
  String get servicesSectionTitle => 'Сервистер';

  @override
  String get servicesAllButton => 'Барлығы';

  @override
  String get homeExcursionsTitle => 'Экскурсиялар';

  @override
  String get homeExcursionsSubtitle =>
      'Қызықты бағыттар мен сапарларды таңдаңыз';

  @override
  String get homeGuidesTitle => 'Гидтер';

  @override
  String get homeGuidesSubtitle => 'Жергілікті гидтер мен сарапшыларды табыңыз';

  @override
  String get homeHotelsTitle => 'Қонақ үйлер';

  @override
  String get homeHotelsSubtitle => 'Тұру орнын ыңғайлы әрі жылдам брондаңыз';

  @override
  String get homeTransportTitle => 'Көлік';

  @override
  String get homeTransportSubtitle => 'Қозғалысты алдын ала жоспарлаңыз';

  @override
  String get homeCurrentLocationLabel => 'Ағымдағы локация';

  @override
  String get homeLocationSheetTitle => 'Локацияны таңдау';

  @override
  String get homeLocationSelected => 'Таңдалған локация';

  @override
  String get homeLocationUseCurrent => 'Қазіргі локациямды пайдалану';

  @override
  String get homeLocationDetecting => 'Локация анықталуда...';

  @override
  String get homeLocationSearchHint => 'Қаланы іздеу';

  @override
  String get homeLocationNoResults => 'Қалалар табылмады';

  @override
  String get homeLocationSearchFailed =>
      'Локацияларды іздеу сәтсіз аяқталды. Қайталап көріңіз.';

  @override
  String get homeLocationDetectionFailed =>
      'Локацияңызды анықтау мүмкін болмады. Геолокация рұқсаттарын тексеріп, қайта көріңіз.';

  @override
  String get homeLocationApply => 'Локацияны қолдану';

  @override
  String get locationFilterCitySection => 'Қала';

  @override
  String get locationFilterAllCities => 'Барлық қалалар';

  @override
  String get locationFilterCitySearchHint => 'Қаланы іздеу';

  @override
  String get locationFilterCityNoResults => 'Қала табылмады';

  @override
  String get cityFilterEmptyHint => 'Сүзгілерден басқа қаланы таңдаңыз.';

  @override
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint =>
      'Белсенділіктерді, орындарды, экскурсияларды іздеу...';

  @override
  String get homeTopDestinations => 'Үздік бағыттар';

  @override
  String get homeSeeAll => 'Барлығын көру';

  @override
  String get homeTopStories => 'Үздік посттар';

  @override
  String get homeFeaturedStays => 'Ұсынылған тұру орындары';

  @override
  String get homeCarRentals => 'Көлік жалдау';

  @override
  String get homeRecommendedActivities => 'Ұсынылатын белсенділіктер';

  @override
  String get homeFilterButton => 'Сүзгі';

  @override
  String get homeMoreButton => 'Көбірек';

  @override
  String get homeServiceActivities => 'Белсенділіктер';

  @override
  String get homeServiceStories => 'Хикаялар';

  @override
  String get homeServiceAttractions => 'Көрікті жерлер';

  @override
  String get homeServiceCurrencyConverter => 'Валюта бағамдары';

  @override
  String get homeServiceStays => 'Тұру';

  @override
  String get homeServiceDelivery => 'Жеткізу';

  @override
  String get homeServiceTaxi => 'Такси';

  @override
  String get homePromoExclusive => 'Эксклюзив';

  @override
  String get homePromoAdventure => 'Шытырман';

  @override
  String get homePromoYachtTitle => 'Yacht Parties';

  @override
  String get homePromoYachtDescription =>
      'Толқын үстіндегі сәнді демалыс, арнайы іріктелген...';

  @override
  String get homePromoMountainTitle => 'Тау экскурсиялары';

  @override
  String get homePromoMountainDescription =>
      'Жергілікті сарапшылармен көркем маршруттар...';

  @override
  String get homePromoExplore => 'Ашу';

  @override
  String get currencyConverterTitle => 'Валюта конвертері';

  @override
  String get currencyConverterSubtitle =>
      'Сапар бағасын Inflap ішінен-ақ аударыңыз.';

  @override
  String get currencyConverterAmountLabel => 'Сома';

  @override
  String get currencyConverterFromLabel => 'Қай валютадан';

  @override
  String get currencyConverterToLabel => 'Қай валютаға';

  @override
  String get currencyConverterYouSend => 'Жібересіз';

  @override
  String get currencyConverterYouReceive => 'Аласыз';

  @override
  String get currencyConverterQuickSwitch => 'Жылдам таңдау';

  @override
  String get currencyConverterSelectCurrencyTitle => 'Валютаны таңдау';

  @override
  String get currencyConverterSearchCurrencyHint => 'Валютаны іздеу';

  @override
  String get currencyConverterRecentSection => 'Соңғылар';

  @override
  String get currencyConverterAllCurrenciesSection => 'Барлық валюталар';

  @override
  String get currencyConverterNoCurrenciesFound => 'Валюта табылмады';

  @override
  String get currencyConverterSwapTooltip => 'Валюталарды ауыстыру';

  @override
  String get currencyConverterConvertButton => 'Конвертациялау';

  @override
  String get currencyConverterLoading => 'Есептелуде...';

  @override
  String get currencyConverterResultTitle => 'Нәтиже';

  @override
  String currencyConverterUpdatedAt(Object value) {
    return 'Курс жаңартылды $value';
  }

  @override
  String currencyConverterProvider(Object value) {
    return 'Провайдер: $value';
  }

  @override
  String get currencyConverterStaleWarning =>
      'Live-провайдер қолжетімсіз болғандықтан, резервтік анықтамалық курс көрсетілді.';

  @override
  String get currencyConverterPopularPairs => 'Танымал жұптар';

  @override
  String get currencyConverterInfoNotice =>
      'Курстар ақпараттық сипатта және төлем кезіндегі провайдер курсынан өзгеше болуы мүмкін.';

  @override
  String get currencyConverterAmountValidation => 'Дұрыс соманы енгізіңіз';

  @override
  String get currencyConverterLoadFailed =>
      'Қазір конвертациялау мүмкін болмады. Байланысты тексеріп, қайта көріңіз.';

  @override
  String get homeDestinationCharynTitle => 'Шарын шатқалы';

  @override
  String get homeDestinationCharynSubtitle => 'Табиғат пен шытырман';

  @override
  String get homeDestinationLakeTitle => 'Үлкен Алматы көлі';

  @override
  String get homeDestinationLakeSubtitle => 'Көркем көріністер';

  @override
  String get homeDestinationKolsaiTitle => 'Көлсай көлдері';

  @override
  String get homeDestinationKolsaiSubtitle => 'Таудағы демалыс';

  @override
  String homeDurationHours(Object hours) {
    return '$hours сағ';
  }

  @override
  String get homeBookNow => 'Брондау';

  @override
  String get homeNavHome => 'Басты';

  @override
  String get feedNavLabel => 'Лента';

  @override
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Карта';

  @override
  String get homeNavChats => 'Чаттар';

  @override
  String get homeNavMy => 'Менің';

  @override
  String get feedTitle => 'Лента';

  @override
  String get feedTabForYou => 'Сіз үшін';

  @override
  String get feedTabFollowing => 'Жазылымдар';

  @override
  String get feedStoriesSectionTitle => 'Хикаялар';

  @override
  String get feedCreateStoryAction => 'Сіздің хикаяңыз';

  @override
  String get storyCaptureTitle => 'Хикаяға қосу';

  @override
  String get storyCapturePreviewTitle => 'Алдын ала қарау';

  @override
  String get storyCaptureCloseLabel => 'Жабу';

  @override
  String get storyCaptureSettingsLabel => 'Баптаулар';

  @override
  String get storyCaptureGalleryAction => 'Галерея';

  @override
  String get storyCapturePhotoFromGallery => 'Фото таңдау';

  @override
  String get storyCaptureVideoFromGallery => 'Видео таңдау';

  @override
  String get storyCaptureCameraUnavailable =>
      'Камера қолжетімсіз. Рұқсаттарды тексеріп, қайта көріңіз.';

  @override
  String get storyCapturePermissionDenied =>
      'Камераға немесе микрофонға рұқсат жоқ.';

  @override
  String get storyCaptureCaptureFailed =>
      'Хикая түсіру мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyCaptureFlashOffLabel => 'Жарқыл өшірулі';

  @override
  String get storyCaptureFlashAutoLabel => 'Жарқыл авто';

  @override
  String get storyCaptureFlashOnLabel => 'Жарқыл қосулы';

  @override
  String get storyCaptureFlashUnsupported => 'Бұл камерада жарқыл қолжетімсіз.';

  @override
  String get storyCapturePhotoMode => 'Фото';

  @override
  String get storyCaptureVideoMode => 'Видео';

  @override
  String get storyCaptureCaptureButtonLabel => 'Фото түсіру';

  @override
  String get storyCaptureRecordButtonLabel => 'Видео жазу';

  @override
  String get storyCaptureStopButtonLabel => 'Жазуды тоқтату';

  @override
  String get storyCaptureFlipCameraLabel => 'Камераны ауыстыру';

  @override
  String get storyCaptureCaptionHint => 'Қолтаңба қосыңыз...';

  @override
  String get storyCaptureRetakeAction => 'Қайта түсіру';

  @override
  String get storyCapturePublishAction => 'Жариялау';

  @override
  String get storyCapturePublishing => 'Жариялануда...';

  @override
  String get storyCapturePublishFailed =>
      'Хикаяны жариялау мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyReplyInputHint => 'Жауап беру';

  @override
  String get storyReplySendAction => 'Жауап жіберу';

  @override
  String get storyReplySentMessage => 'Жауап жіберілді';

  @override
  String get storyReplySendFailed =>
      'Жауап жіберу мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyLikeAction => 'Хикая ұнады';

  @override
  String get storyLikeSendFailed =>
      'Хикаяға лайк қою мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyCaptureDefaultTitle => 'Менің хикаям';

  @override
  String get storyCaptureDefaultBody => 'Жаңа хикая';

  @override
  String get storyCaptureDefaultPlace => 'Хикая';

  @override
  String get storyCapturePublishedMessage => 'Хикая жарияланды';

  @override
  String get feedSuggestedCommunitiesTitle => 'Жазылуға ұсынылады';

  @override
  String get feedJoinCommunityAction => 'Жазылу';

  @override
  String get feedCommunityJoinedAction => 'Жазылған';

  @override
  String get feedCommunityModerationAction => 'Модерация';

  @override
  String get feedCommunityActionFailed =>
      'Жазылымды жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String feedCommunityMembersLabel(String count) {
    return '$count жазылушы';
  }

  @override
  String get feedMySubscriptionsTitle => 'Менің жазылымдарым';

  @override
  String feedMySubscriptionsSummary(int communities, int people) {
    return '$communities қауымдастық · $people адам';
  }

  @override
  String get feedMySubscriptionsViewAll => 'Барлығын көру';

  @override
  String get feedMySubscriptionsCommunitiesTab => 'Қауымдастықтар';

  @override
  String get feedMySubscriptionsPeopleTab => 'Адамдар';

  @override
  String get feedMySubscriptionsSearchHint => 'Жазылымдарды іздеу';

  @override
  String get feedMySubscriptionsSheetSubtitle =>
      'Лентада жақын ұстайтын қауымдастықтар, достар және жазылған адамдар.';

  @override
  String get feedMySubscriptionsFilterAll => 'Барлығы';

  @override
  String get feedMySubscriptionsFilterStatusSection => 'Жазылым күйі';

  @override
  String get feedMySubscriptionsFilterPeopleSection => 'Байланыс түрі';

  @override
  String get feedMySubscriptionsFilterCommunityActivitySection => 'Белсенділік';

  @override
  String get feedMySubscriptionsFilterCommunityTopicSection => 'Тақырыптар';

  @override
  String get feedMySubscriptionsFilterPeopleConnectionSection => 'Байланыс';

  @override
  String get feedMySubscriptionsFilterPeopleActivitySection => 'Белсенділік';

  @override
  String get feedMySubscriptionsFilterSortSection => 'Сұрыптау';

  @override
  String get feedMySubscriptionsFilterSubscribed => 'Жазылған';

  @override
  String get feedMySubscriptionsFilterUnsubscribed => 'Жазылмаған';

  @override
  String get feedMySubscriptionsFilterCurrentCity => 'Менің қалам';

  @override
  String get feedMySubscriptionsFilterActive => 'Посттары бар';

  @override
  String get feedMySubscriptionsFilterPopular => 'Танымал';

  @override
  String get feedMySubscriptionsFilterFriends => 'Достар';

  @override
  String get feedMySubscriptionsFilterFollowing => 'Жазылымдар';

  @override
  String get feedMySubscriptionsFilterOnline => 'Онлайн';

  @override
  String get feedMySubscriptionsSortRelevant => 'Ұсынылған';

  @override
  String get feedMySubscriptionsSortMostActive => 'Ең белсенді';

  @override
  String get feedMySubscriptionsSortMostPopular => 'Жазылушысы көп';

  @override
  String get feedMySubscriptionsSortName => 'А-Я';

  @override
  String get feedMySubscriptionsSortOnlineFirst => 'Алдымен онлайн';

  @override
  String get feedPostSortRecommended => 'Ұсынылған';

  @override
  String get feedPostSortNewest => 'Жаңа';

  @override
  String get feedPostSortPopular => 'Танымал';

  @override
  String get feedPostSortDiscussed => 'Талқыланатын';

  @override
  String get feedMySubscriptionsApplyFilters => 'Сүзгілерді қолдану';

  @override
  String feedMySubscriptionsShowCommunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қауымдастықты көрсету',
    );
    return '$_temp0';
  }

  @override
  String feedMySubscriptionsShowPeopleCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count адамды көрсету',
    );
    return '$_temp0';
  }

  @override
  String get feedMySubscriptionsEmptyMessage =>
      'Бұл сүзгілер бойынша ештеңе табылмады.';

  @override
  String get feedMySubscriptionsFriendBadge => 'Дос';

  @override
  String get feedMySubscriptionsFollowingBadge => 'Жазылым';

  @override
  String get feedMySubscriptionsOnlineBadge => 'Онлайн';

  @override
  String get feedMySubscriptionsUnknownPerson => 'Пайдаланушы';

  @override
  String get feedSystemPostsTitle => 'Ресми жаңалықтар';

  @override
  String get feedSystemPostsViewAll => 'Барлығын көру';

  @override
  String get feedSystemPostsSheetTitle => 'Ресми посттар';

  @override
  String get communityDiscoveryTitle => 'Қауымдастықтар';

  @override
  String get communityDiscoveryEmptyTitle => 'Әзірге қауымдастық жоқ';

  @override
  String get communityDiscoveryEmptyMessage =>
      'Ресми қауымдастықтар іске қосылған кезде осында пайда болады.';

  @override
  String get communityDiscoveryLoadFailedTitle =>
      'Қауымдастықтарды жүктеу мүмкін болмады';

  @override
  String get communityDiscoveryLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get communityDiscoverySearchHint => 'Қауымдастық іздеу';

  @override
  String get communityDiscoveryFiltersTitle => 'Сүзгілер';

  @override
  String get communityDiscoveryShowResults => 'Қауымдастықтарды көрсету';

  @override
  String communityDiscoveryShowResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қауымдастықты',
      one: '1 қауымдастықты',
      zero: '0 қауымдастықты',
    );
    return '$_temp0 көрсету';
  }

  @override
  String get communityDiscoveryRequiredLocationMessage =>
      'Белсенді жергілікті қауымдастықтарды табу үшін ел мен қаланы таңдаңыз.';

  @override
  String get communityDiscoveryTopicSection => 'Қауымдастық түрі';

  @override
  String get communityDiscoveryTopicAll => 'Барлығы';

  @override
  String get communityDiscoveryTopicTravel => 'Саяхат';

  @override
  String get communityDiscoveryTopicCity => 'Қалалар';

  @override
  String get communityDiscoveryTopicGuides => 'Гидтер мен турлар';

  @override
  String get communityDiscoveryTopicAppNews => 'Inflap жаңалықтары';

  @override
  String get communityTopicLanguages => 'Тілдер';

  @override
  String get communityTopicHousing => 'Тұрғын үй';

  @override
  String get communityTopicTransport => 'Көлік';

  @override
  String get communityTopicSports => 'Спорт';

  @override
  String get communityTopicOutdoor => 'Сапарлар және табиғат';

  @override
  String get communityTopicHobbies => 'Хобби және шеберлік сабақтары';

  @override
  String get communityTopicWellness => 'Wellness және денсаулық';

  @override
  String get communityTopicPets => 'Үй жануарлары';

  @override
  String get communityTopicCityLife => 'Қала өмірі';

  @override
  String get communityTopicContent => 'Жаңалықтар және гидтер';

  @override
  String get communityTopicFamily => 'Отбасылар';

  @override
  String get communityTopicGeneral => 'Жалпы';

  @override
  String get communityProfileTitle => 'Қауымдастық';

  @override
  String get communityProfileActionsTooltip => 'Қауымдастық әрекеттері';

  @override
  String get communityProfileCreatePostAction => 'Пост жасау';

  @override
  String get communityPostModeSelectorLabel => 'Жариялау режимі';

  @override
  String get communityPostModeArticle => 'Посттар';

  @override
  String get communityPostModeQuickPost => 'Талқылаулар';

  @override
  String get communityPostModeListing => 'Хабарландырулар';

  @override
  String get communityPostModeEventAnnouncement => 'Афиша';

  @override
  String get communityPostModeQuestionAnswer => 'Сұрақтар';

  @override
  String get communityPostModeTripPlan => 'Сапарлар';

  @override
  String get communityProfileUnfollowConfirmTitle =>
      'Қауымдастықтан жазылымды тоқтату керек пе?';

  @override
  String get communityProfileRulesTitle => 'Қауымдастық ережелері';

  @override
  String get communityProfilePostsSectionTitle => 'Посттар';

  @override
  String get communityProfileNoPostsTitle => 'Әзірге пост жоқ';

  @override
  String get communityProfileNoPostsMessage =>
      'Бұл қауымдастықтың жаңа посттары осында пайда болады.';

  @override
  String get communityProfilePostsLoadFailedTitle =>
      'Посттарды жүктеу мүмкін болмады';

  @override
  String communityProfilePostsLabel(String count) {
    return '$count пост';
  }

  @override
  String get communityProfileLoadFailedTitle =>
      'Қауымдастықты жүктеу мүмкін болмады';

  @override
  String get communityProfileLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get communityTrustReportAction => 'Қауымдастыққа шағымдану';

  @override
  String get communityTrustMuteAction => 'Қауымдастықты жасыру';

  @override
  String get communityTrustUnmuteAction => 'Қауымдастықты қайтару';

  @override
  String get communityTrustBlockedTitle => 'Жариялау бұғатталған';

  @override
  String get communityTrustBlockedMessage =>
      'Модераторлар шектеуді алып тастамайынша, бұл қауымдастықта пост жариялай алмайсыз.';

  @override
  String get communityTrustMutedTitle => 'Қауымдастық жасырылды';

  @override
  String get communityTrustMutedMessage =>
      'Бұл қауымдастық лентаңыздан жасырылды. Оны кез келген уақытта қайтара аласыз.';

  @override
  String get communityTrustAppealPendingTitle => 'Апелляция қаралуда';

  @override
  String get communityTrustAppealPendingMessage =>
      'Модераторлар осы қауымдастық бойынша апелляцияңызды қарап жатыр.';

  @override
  String get communityTrustAppealRejectedTitle => 'Апелляция қабылданбады';

  @override
  String get communityTrustAppealRejectedMessage =>
      'Модераторлар тексергеннен кейін шектеу белсенді болып қалады.';

  @override
  String get communityTrustAppealAction => 'Апелляция';

  @override
  String get communityTrustAppealMessage =>
      'Қауымдастықтағы шектеуімді қайта қарап шығыңыз.';

  @override
  String get communityTrustReportSubmitted =>
      'Қауымдастық модерацияға жіберілді.';

  @override
  String get communityTrustMutedSubmitted => 'Қауымдастық жасырылды.';

  @override
  String get communityTrustUnmutedSubmitted => 'Қауымдастық қайтарылды.';

  @override
  String get communityTrustAppealSubmitted =>
      'Апелляция модераторларға жіберілді.';

  @override
  String get communityTrustActionUnavailable =>
      'Бұл trust әрекеті әзірге қолжетімсіз.';

  @override
  String get communityTrustActionFailed =>
      'Trust әрекетін орындау мүмкін болмады. Қайта көріңіз.';

  @override
  String get feedEmptyTitle => 'Лентада әзірге ештеңе жоқ';

  @override
  String get feedEmptyMessage =>
      'Лентаңызды қалыптастыру үшін саяхатшылар мен қауымдастықтарға жазылыңыз.';

  @override
  String get feedLoadFailedTitle => 'Лентаны жүктеу мүмкін болмады';

  @override
  String get feedLoadFailedMessage => 'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get feedRetryAction => 'Қайталау';

  @override
  String get communityModerationTitle => 'Модерация кезегі';

  @override
  String communityModerationSubtitle(int count) {
    return '$count тексерісте';
  }

  @override
  String get communityModerationEmptyTitle => 'Тексерілетін пост жоқ';

  @override
  String get communityModerationEmptyMessage =>
      'Тексеруді қажет ететін жаңа қауымдастық посттары осында шығады.';

  @override
  String get communityModerationLoadFailedTitle =>
      'Модерация кезегін жүктеу мүмкін болмады';

  @override
  String get communityModerationLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get communityModerationApproveAction => 'Мақұлдау';

  @override
  String get communityModerationRejectAction => 'Қабылдамау';

  @override
  String get communityModerationHistoryAction => 'Тарих';

  @override
  String get communityModerationApprovedMessage => 'Пост мақұлданды';

  @override
  String get communityModerationRejectedMessage => 'Пост қабылданбады';

  @override
  String get communityModerationActionFailed =>
      'Постты жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String get communityModerationDecisionHistoryTitle => 'Шешімдер тарихы';

  @override
  String get communityModerationDecisionHistoryEmpty =>
      'Модерация шешімдері әлі жоқ.';

  @override
  String get communityModerationDecisionHistoryFailed =>
      'Шешімдер тарихын жүктеу мүмкін болмады.';

  @override
  String get communityModerationRejectReasonLabel => 'Қабылдамау себебі';

  @override
  String get communityModerationRejectConfirmAction => 'Постты қабылдамау';

  @override
  String get communityModerationRejectCancelAction => 'Бас тарту';

  @override
  String get communityMembersTitle => 'Қатысушылар';

  @override
  String get communityMembersSubtitle => 'Қолжетімділік пен рөлдерді басқару';

  @override
  String get communityMembersAction => 'Қатысушылар';

  @override
  String get communityMembersEmptyTitle => 'Қатысушылар табылмады';

  @override
  String get communityMembersEmptyMessage =>
      'Таңдалған сүзгілерге сай қатысушылар осында шығады.';

  @override
  String get communityMembersLoadFailedTitle =>
      'Қатысушыларды жүктеу мүмкін болмады';

  @override
  String get communityMembersLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get communityMembersRoleFilterLabel => 'Рөл';

  @override
  String get communityMembersStatusFilterLabel => 'Мәртебе';

  @override
  String get communityMembersAllFilter => 'Барлығы';

  @override
  String get communityMembersActiveStatus => 'Белсенді';

  @override
  String get communityMembersMutedStatus => 'Шектелген';

  @override
  String get communityMembersBannedStatus => 'Бұғатталған';

  @override
  String get communityMembersLeftStatus => 'Шыққан';

  @override
  String get communityMembersTrustedRole => 'Сенімді қатысушы';

  @override
  String get communityMembersModeratorRole => 'Модератор';

  @override
  String get communityMembersAdminRole => 'Админ';

  @override
  String get communityMembersMemberRole => 'Қатысушы';

  @override
  String get communityMembersChangeRoleAction => 'Рөлді өзгерту';

  @override
  String get communityMembersRoleHistoryAction => 'Рөлдер тарихы';

  @override
  String get communityMembersRoleHistoryTitle => 'Рөлдер тарихы';

  @override
  String get communityMembersRoleHistoryChangedBy => 'Өзгерткен';

  @override
  String get communityMembersRoleHistoryEmptyTitle => 'Рөл өзгерістері жоқ';

  @override
  String get communityMembersRoleHistoryEmptyMessage =>
      'Бұл қатысушының рөл жаңартулары осында шығады.';

  @override
  String get communityMembersRoleHistoryLoadFailedTitle =>
      'Рөлдер тарихын жүктеу мүмкін болмады';

  @override
  String get communityMembersRoleHistoryLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get communityMembersChangeStatusAction => 'Мәртебені өзгерту';

  @override
  String get communityMembersMuteAction => 'Қатысушыны шектеу';

  @override
  String get communityMembersBanAction => 'Қатысушыны бұғаттау';

  @override
  String get communityMembersRemoveAction => 'Қатысушыны өшіру';

  @override
  String get communityMembersRestoreAction => 'Қатысушыны қалпына келтіру';

  @override
  String get communityMembersStatusUpdatedMessage => 'Мәртебе жаңартылды';

  @override
  String get communityMembersStatusUpdateFailed =>
      'Қатысушы мәртебесін жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String get communityMembersRoleUpdatedMessage => 'Рөл жаңартылды';

  @override
  String get communityMembersRoleUpdateFailed =>
      'Қатысушыны жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String get mapNearbyPlacesLabel => 'Жақын жерлер';

  @override
  String get mapSearchingNearbyPlaces =>
      'Жақын маңдағы орындар мен мекемелерді іздеп жатырмыз';

  @override
  String get mapPlacesLoadFailed => 'Жақын жерлерді жүктеу сәтсіз аяқталды';

  @override
  String get mapNoPlacesTitle => 'Жақын маңда орындар табылмады';

  @override
  String get mapNoPlacesSubtitle =>
      'Басқа жақын мекемелер мен қызықты нүктелерді көру үшін картаны жылжытыңыз немесе геолокацияны жаңартыңыз.';

  @override
  String get mapTapPlaceHint =>
      'Орынды қарап, сілтемесін көшіру үшін маркерді немесе карточканы басыңыз.';

  @override
  String get mapCopyPlaceLink => 'Сілтемені көшіру';

  @override
  String get mapPlaceLinkCopied => 'Орынға сілтеме көшірілді';

  @override
  String get mapUsingFallbackLocation =>
      'Карта резервтік локация бойынша көрсетіліп тұр';

  @override
  String get mapDistancePending => 'Қашықтықты анықтап жатырмыз';

  @override
  String mapPlacesCount(int count) {
    return 'Табылған орындар: $count';
  }

  @override
  String mapActivitiesCount(int count) {
    return 'Белсенділіктер: $count';
  }

  @override
  String get mapTapActivityHint =>
      'Қысқаша ақпаратты көріп, мәліметтерін ашу үшін белсенділік маркерін басыңыз.';

  @override
  String get attractionsTitle => 'Көрікті жерлер';

  @override
  String get attractionsSearchHint => 'Қайда барамыз?';

  @override
  String get attractionsLoadFailed => 'Көрікті жерлерді жүктеу сәтсіз аяқталды';

  @override
  String get attractionsSeeAll => 'Барлығын көру';

  @override
  String get attractionsNoResults => 'Көрікті жерлер табылмады';

  @override
  String get attractionsNoResultsSubtitle =>
      'Сүзгілерден басқа қаланы таңдаңыз.';

  @override
  String get attractionsFiltersTitle => 'Сүзгілер';

  @override
  String get attractionsSortLabel => 'Сұрыптау';

  @override
  String get attractionsSortRating => 'Рейтинг';

  @override
  String get attractionsSortDuration => 'Ұзақтығы';

  @override
  String get attractionsSortPrice => 'Баға';

  @override
  String get attractionFilterClearAll => 'Барлығын тазалау';

  @override
  String get attractionFilterCategoriesSection => 'Санаттар';

  @override
  String get attractionFilterCategoryAll => 'Барлық орындар';

  @override
  String get attractionFilterCategoryParks => 'Саябақтар';

  @override
  String get attractionFilterCategoryMuseums => 'Мұражайлар';

  @override
  String get attractionFilterCategoryNature => 'Табиғат';

  @override
  String get attractionFilterCategoryArchitecture => 'Сәулет';

  @override
  String get attractionFilterCategoryBeach => 'Жағажай';

  @override
  String get attractionFilterCategoryTemple => 'Ғибадат орындары';

  @override
  String get attractionFilterCategoryEntertainment => 'Ойын-сауық';

  @override
  String get attractionFilterCategoryFood => 'Тағам';

  @override
  String get attractionFilterCategoryMarket => 'Базар';

  @override
  String get attractionFilterCategoryShopping => 'Шопинг';

  @override
  String get attractionFilterCategoryOther => 'Басқа';

  @override
  String get attractionFilterCategoryHistory => 'Тарих';

  @override
  String get attractionFilterCategoryAdventure => 'Шытырман';

  @override
  String get attractionFilterCountrySection => 'Ел';

  @override
  String get attractionFilterCountryAll => 'Барлық елдер';

  @override
  String get attractionFilterCountrySearchHint =>
      'Ел, код немесе телефон бойынша іздеу';

  @override
  String get attractionFilterCountryNoResults => 'Ел табылмады';

  @override
  String get attractionFilterMinRatingSection => 'Минимум рейтинг';

  @override
  String get attractionFilterRatingAny => 'Кез келген';

  @override
  String get attractionFilterDurationSection => 'Ұзақтығы';

  @override
  String get attractionFilterDurationShort => 'Қысқа < 2 сағ';

  @override
  String get attractionFilterDurationMedium => 'Орташа 2–5 сағ';

  @override
  String get attractionFilterDurationFullDay => 'Толық күн 5 сағ+';

  @override
  String get attractionFilterDurationMultiDay => 'Бірнеше күн';

  @override
  String get attractionFilterRangeSection => 'Нақты ауқым';

  @override
  String attractionFilterRangeValue(int min, int max) {
    return '$min сағ – $max сағ';
  }

  @override
  String get attractionFilterRangeMinTick => '1 сағ';

  @override
  String get attractionFilterRangeMaxTick => '12 сағ+';

  @override
  String get attractionFilterPriceRangeSection => 'Баға ауқымы';

  @override
  String attractionFilterShowSpots(int count) {
    return '$count орын көрсету';
  }

  @override
  String get attractionFilterClear => 'Тазалау';

  @override
  String get attractionMinPriceLabel => 'Мин. баға';

  @override
  String get attractionMaxPriceLabel => 'Макс. баға';

  @override
  String get attractionPriceValidationError => 'Дұрыс баға енгізіңіз';

  @override
  String get attractionPriceRangeValidationError =>
      'Максималды баға минималды бағадан жоғары болуы керек';

  @override
  String get attractionHoursUnit => 'Сағат';

  @override
  String get attractionDaysUnit => 'Күн';

  @override
  String get attractionHoursUnitShort => 'сағ';

  @override
  String get attractionDaysUnitShort => 'күн';

  @override
  String get attractionMinLabel => 'Мин.';

  @override
  String get attractionMaxLabel => 'Макс.';

  @override
  String get attractionDurationValidationError => 'Дұрыс ұзақтық енгізіңіз';

  @override
  String get attractionDurationRangeValidationError =>
      'Максималды ұзақтық минималды ұзақтықтан жоғары болуы керек';

  @override
  String get attractionDetailsLoadFailed =>
      'Көрікті жерді жүктеу сәтсіз аяқталды';

  @override
  String get attractionDetailsTitle => 'Жер туралы';

  @override
  String get attractionMustVisitBadge => 'Бару керек';

  @override
  String get attractionStatRating => 'Рейтинг';

  @override
  String get attractionStatDuration => 'Ұзақтығы';

  @override
  String get attractionStatPrice => 'Баға';

  @override
  String get attractionExperienceSection => 'Әсер';

  @override
  String get attractionExpectSection => 'Не күтуге болады';

  @override
  String get attractionVisitPlanSection => 'Сапар жоспары';

  @override
  String get attractionInflapTipTitle => 'Inflap кеңесі';

  @override
  String get attractionVisitDurationLabel => 'Орынға уақыт';

  @override
  String get attractionVisitDurationFlexible => 'Икемді';

  @override
  String get attractionVisitTicketsLabel => 'Билеттер';

  @override
  String get attractionVisitFreeEntry => 'Тегін немесе маусымға байланысты';

  @override
  String get attractionVisitBookingRecommended => 'алдын ала брондаған дұрыс';

  @override
  String get attractionVisitBestTimeLabel => 'Ең жақсы уақыт';

  @override
  String get attractionVisitBestTimeEarlyMorning => 'Ерте таң';

  @override
  String get attractionVisitBestTimeMorning => 'Таңертең';

  @override
  String get attractionVisitBestTimeAfternoon => 'Күндіз';

  @override
  String get attractionVisitBestTimeSunset => 'Күн батқанда';

  @override
  String get attractionVisitBestTimeAnytime => 'Кез келген уақытта';

  @override
  String get attractionVisitGoodForLabel => 'Кімге қолайлы';

  @override
  String get attractionVisitAccessLabel => 'Қолжетімділік';

  @override
  String get attractionVisitAccessGood => 'Жету ыңғайлы';

  @override
  String get attractionVisitAccessLimited => 'Қолжетімділігі шектеулі';

  @override
  String get attractionVisitAccessUnknown => 'Орнында нақтылаңыз';

  @override
  String get attractionVisitSafetyLabel => 'Дайындық';

  @override
  String get attractionVisitSafetyCheckWeather => 'Ауа райын тексеріңіз';

  @override
  String get attractionVisitSafetyBringWater => 'Су алыңыз';

  @override
  String get attractionVisitSafetyCheckHours => 'Жұмыс уақытын тексеріңіз';

  @override
  String get attractionVisitAudienceCouples => 'Жұптар';

  @override
  String get attractionVisitAudienceWellness => 'Сауықтыру';

  @override
  String get attractionVisitTipNature =>
      'Жолға шығар алдында көлік пен ауа райын тексеріңіз: гидпен бағыт әдетте қауіпсіз әрі болжамды.';

  @override
  String get attractionVisitTipCulture =>
      'Ертерек келіңіз: фотоға ыңғайлырақ, әрі жақын мәдени орындарға уақыт қалады.';

  @override
  String get attractionVisitTipDefault =>
      'Ағымдағы кестені тексеріп, жолға уақыт жоғалтпау үшін жақын белсенділіктермен біріктіріңіз.';

  @override
  String get attractionReviewsSection => 'Саяхатшылар пікірі';

  @override
  String attractionSeeAllReviews(int count) {
    return 'Барлық пікірлер ($count)';
  }

  @override
  String get attractionNoReviews => 'Әзірге пікір жоқ. Бірінші болыңыз!';

  @override
  String get attractionAddReview => 'Пікір қалдыру';

  @override
  String get attractionReviewSheetTitle => 'Әсеріңізбен бөлісіңіз';

  @override
  String get attractionReviewRatingLabel => 'Баға';

  @override
  String get attractionReviewCommentLabel => 'Пікір';

  @override
  String get attractionReviewCommentHint =>
      'Не ұнады, не ұсынар едіңіз және басқалар нені білуі керек?';

  @override
  String get attractionReviewAddPhoto => 'Фото';

  @override
  String get attractionReviewAddVideo => 'Видео';

  @override
  String get attractionReviewSubmit => 'Пікірді жариялау';

  @override
  String get attractionReviewSubmitting => 'Жариялануда...';

  @override
  String attractionReviewMediaLimit(int count) {
    return '$count файлға дейін тіркей аласыз';
  }

  @override
  String get attractionReviewPickFailed => 'Файлды тіркеу мүмкін болмады';

  @override
  String get attractionReviewMediaTooLarge => 'Файл тым үлкен';

  @override
  String get attractionReviewUnsupportedFormat =>
      'Файл пішімі қолдау көрсетілмейді';

  @override
  String get attractionReviewSubmitFailed => 'Пікірді жариялау мүмкін болмады';

  @override
  String get attractionReviewSubmitSuccess => 'Пікір жарияланды';

  @override
  String get attractionReviewCommentRequired => 'Қысқа пікір жазыңыз';

  @override
  String get attractionReviewRemoveMedia => 'Файлды жою';

  @override
  String get attractionReviewVideoPreview => 'Видео';

  @override
  String get attractionFindExcursions => 'Экскурсиялар табу';

  @override
  String get attractionMapLink => 'Картадан көру';

  @override
  String get attractionVerifiedNomad => 'Тексерілген саяхатшы';

  @override
  String get attractionReviewsTitle => 'Пікірлер';

  @override
  String get attractionTravelerFallback => 'Саяхатшы';

  @override
  String get profileGuideReviewsTitle => 'Экскурсиялар бойынша үздік пікірлер';

  @override
  String get profileGuideReviewsLatestTitle =>
      'Экскурсиялар бойынша соңғы пікірлер';

  @override
  String get profileDirectGuideReviewsTitle => 'Гид рейтингі';

  @override
  String get profileActivityOrganizerReviewsTitle =>
      'Белсенділік ұйымдастырушысы рейтингі';

  @override
  String get profileActivityReviewsTitle => 'Белсенділік пікірлері';

  @override
  String get profileGuideReviewsEmptyTitle => 'Әзірге пікір жоқ';

  @override
  String get profileGuideReviewsEmpty =>
      'Саяхатшылар өткізілген экскурсияларды бағалағаннан кейін пікірлер осында шығады.';

  @override
  String get profileDirectGuideReviewsEmpty =>
      'Гид туралы тікелей пікірлер саяхатшылар бөлек бағалағаннан кейін осында шығады.';

  @override
  String get profileActivityOrganizerReviewsEmpty =>
      'Ұйымдастырушы туралы пікірлер аяқталған белсенділіктерден кейін қатысушылар бағалағанда осында шығады.';

  @override
  String get profileActivityReviewsEmpty =>
      'Белсенділік пікірлері аяқталған белсенділіктерден кейін қатысушылар бағалағанда осында шығады.';

  @override
  String get profileGuideReviewsLoadFailed =>
      'Пікірлерді жүктеу мүмкін болмады';

  @override
  String get profileGuideReviewsLoadFailedHint =>
      'Жаңарту үшін төмен тартыңыз немесе профильді қайта ашыңыз.';

  @override
  String get attractionPriceVaries => 'Баға өзгеруі мүмкін';

  @override
  String get attractionPriceVariesShort => 'Өзгеруі мүмкін';

  @override
  String attractionDurationHours(int hours) {
    return '$hours сағ';
  }

  @override
  String attractionDurationDays(int days) {
    return '$days күн';
  }

  @override
  String get attractionBackTooltip => 'Артқа';

  @override
  String get attractionNotificationsTooltip => 'Хабарландырулар';

  @override
  String get attractionBookmarkTooltip => 'Жерді сақтау';

  @override
  String get attractionTagFamilyLabel => 'Отбасына қолайлы';

  @override
  String get attractionTagFamilySubtitle => 'Барлық жасқа жарайды';

  @override
  String get attractionTagSunsetLabel => 'Күн батқанда жақсы';

  @override
  String get attractionTagSunsetSubtitle => 'Әдемі кешкі көріністер';

  @override
  String get attractionTagAccessibilityLabel => 'Қолжетімділік';

  @override
  String get attractionTagAccessibilitySubtitle => 'Арбаға қолайлы';

  @override
  String get attractionTagDiningLabel => 'Мейрамханалар';

  @override
  String get attractionTagDiningSubtitle => 'Гастрономиялық орындар';

  @override
  String get attractionTagOutdoorLabel => 'Табиғатта';

  @override
  String get attractionTagOutdoorSubtitle => 'Таза ауа мен көріністер';

  @override
  String get attractionTagPhotoLabel => 'Фото орын';

  @override
  String get attractionTagPhotoSubtitle => 'Есте қаларлық кадрлар';

  @override
  String get attractionTagHistoryLabel => 'Тарихи';

  @override
  String get attractionTagHistorySubtitle => 'Бай мәдени мұра';

  @override
  String get attractionTagAdventureLabel => 'Шытырман';

  @override
  String get attractionTagAdventureSubtitle => 'Белсенді әсерлер';

  @override
  String get attractionTagUniqueSubtitle => 'Ерекше әсер';

  @override
  String get activitiesEntryTitle => 'Белсенділіктер';

  @override
  String get activitiesEntrySubtitle =>
      'Қосылуға болатын офлайн және онлайн іс-шараларды табыңыз';

  @override
  String get comingSoon => 'Жақында пайда болады';

  @override
  String get change => 'Өзгерту';

  @override
  String get select => 'Таңдау';

  @override
  String get confirm => 'Растау';

  @override
  String get createActivityFab => 'Жасау';

  @override
  String get createActivityTitle => 'Белсенділік құру';

  @override
  String get createActivitySubmit => 'Белсенділік жасау';

  @override
  String get createActivitySuccess => 'Белсенділік сәтті жасалды';

  @override
  String get createActivityFailed => 'Белсенділікті жасау сәтсіз аяқталды';

  @override
  String get excursionsDiscoverTitle => 'Экскурсиялар';

  @override
  String get excursionsSearchHint => 'Экскурсиялар мен әсерлерді іздеу';

  @override
  String get excursionsSortLabel => 'Сұрыптау';

  @override
  String get excursionsSortPopular => 'Танымал';

  @override
  String get excursionsSortNewest => 'Жаңа';

  @override
  String get excursionsSortAffordable => 'Арзанырақ';

  @override
  String get excursionsSortCreatedAt => 'Құрылған күн';

  @override
  String get excursionsSortRating => 'Рейтинг';

  @override
  String get excursionsSortPrice => 'Баға';

  @override
  String get excursionsSortDuration => 'Ұзақтығы';

  @override
  String get excursionsFiltersTitle => 'Сүзгілер';

  @override
  String get excursionsFiltersClear => 'Тазалау';

  @override
  String excursionsFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count экскурсияны',
      one: '1 экскурсияны',
      zero: '0 экскурсияны',
    );
    return '$_temp0 көрсету';
  }

  @override
  String get excursionsFilterCountry => 'Ел';

  @override
  String get excursionsFilterCountryAll => 'Барлық елдер';

  @override
  String get excursionsFilterCountrySearchHint =>
      'Ел, код немесе телефон бойынша іздеу';

  @override
  String get excursionsFilterCountryNoResults => 'Ел табылмады';

  @override
  String get excursionsFilterCategories => 'Санаттар';

  @override
  String get excursionsFilterPriceRange => 'Баға аралығы';

  @override
  String get excursionsFilterPriceFrom => 'Бастап';

  @override
  String get excursionsFilterPriceTo => 'Дейін';

  @override
  String get excursionsFilterBudget => 'Үнемді';

  @override
  String get excursionsFilterPremium => 'Премиум';

  @override
  String get excursionsFilterDuration => 'Ұзақтығы';

  @override
  String get excursionsFilterShortDuration => 'Қысқа (< 3 сағ)';

  @override
  String get excursionsFilterHalfDayDuration => 'Жарты күн (3–6 сағ)';

  @override
  String get excursionsFilterFullDayDuration => 'Толық күн (6 сағ+)';

  @override
  String get excursionsFilterMultiDayDuration => 'Бірнеше күн';

  @override
  String get excursionsFilterLanguage => 'Тіл';

  @override
  String get excursionsFilterLanguageAll => 'Барлық тілдер';

  @override
  String get excursionsFilterLanguageSearchHint =>
      'Тіл немесе код бойынша іздеу';

  @override
  String get excursionsFilterLanguageNoResults => 'Тіл табылмады';

  @override
  String get excursionsLoadFailed => 'Экскурсияларды жүктеу мүмкін болмады';

  @override
  String get excursionsEmptyTitle => 'Әзірге экскурсиялар жоқ';

  @override
  String get excursionsEmptySubtitle =>
      'Мұнда тексерілген гидтердің маршруттары пайда болады. Сүзгілерден басқа қаланы таңдаңыз.';

  @override
  String get excursionsEmptySearchSubtitle =>
      'Басқа қаланы, санатты немесе экскурсия атауын қолданып көріңіз.';

  @override
  String get excursionsNoAttractionExcursionsTitle =>
      'Бұл көрікті орын бойынша экскурсиялар әзірге жоқ';

  @override
  String get excursionsNoAttractionExcursionsSubtitle =>
      'Басқа қолжетімді экскурсияларды көрсетіп тұрмыз. Гидтер осы көрікті орынға маршрут қосқанда, ол осында пайда болады.';

  @override
  String get guidesTitle => 'Гидтер';

  @override
  String get guidesSearchHint => 'Гидтерді іздеу';

  @override
  String get guidesSortLabel => 'Сұрыптау';

  @override
  String get guidesSortRating => 'Рейтинг';

  @override
  String get guidesSortExperience => 'Тәжірибе';

  @override
  String get guidesViewProfile => 'Профильді көру';

  @override
  String get guidesFiltersTitle => 'Сүзгілер';

  @override
  String get guidesFiltersClear => 'Тазалау';

  @override
  String get guidesClearSearch => 'Іздеуді тазалау';

  @override
  String get guidesFilterCountry => 'Ел';

  @override
  String get guidesFilterCountryAll => 'Барлық елдер';

  @override
  String get guidesFilterCountrySearchHint =>
      'Ел, код немесе телефон бойынша іздеу';

  @override
  String get guidesFilterCountryNoResults => 'Ел табылмады';

  @override
  String get guidesFilterExpertise => 'Мамандану';

  @override
  String get guidesFilterLanguage => 'Тіл';

  @override
  String get guidesFilterLanguageAll => 'Барлық тілдер';

  @override
  String get guidesFilterLanguageSearchHint => 'Тілді немесе кодты іздеу';

  @override
  String get guidesFilterLanguageNoResults => 'Тіл табылмады';

  @override
  String get guidesFilterRating => 'Рейтинг';

  @override
  String get guidesFilterExperience => 'Тәжірибе';

  @override
  String guidesFilterRatingAtLeast(Object value) {
    return '$value+ жұлдыз';
  }

  @override
  String guidesFiltersShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гидті',
      one: '1 гидті',
      zero: '0 гидті',
    );
    return '$_temp0 көрсету';
  }

  @override
  String get guidesLoadFailed => 'Гидтерді жүктеу мүмкін болмады';

  @override
  String get guidesEmptyTitle => 'Әзірге гидтер жоқ';

  @override
  String get guidesEmptySubtitle =>
      'Мұнда тексерілген жергілікті сарапшылар пайда болады. Сүзгілерден басқа қаланы таңдаңыз.';

  @override
  String get guidesNoResultsTitle => 'Гидтер табылмады';

  @override
  String get guidesNoResultsSubtitle =>
      'Басқа қаланы, атты, мамандануды, тілді немесе сүзгіні қолданып көріңіз.';

  @override
  String get guidesRatingNew => 'Жаңа гид';

  @override
  String guidesReviewsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пікір',
      one: '1 пікір',
    );
    return '$_temp0';
  }

  @override
  String get guidesSpecialtyMountainGuide => 'Тау гиді';

  @override
  String get guidesSpecialtyCityHistorian => 'Қала тарихшысы';

  @override
  String get guidesSpecialtyCulinaryExpert => 'Аспаздық сарапшы';

  @override
  String get guidesSpecialtyNaturePhotographer => 'Табиғат фотографы';

  @override
  String get guidesRoleLocalExpert => 'Жергілікті сарапшы';

  @override
  String get guidesFilterPrivateExcursions => 'Жеке экскурсиялар';

  @override
  String get guidesFilterActivities => 'Іс-шаралар';

  @override
  String get guidesFilterExcursions => 'Экскурсиялар';

  @override
  String guidesExperienceYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жыл',
      one: '1 жыл',
    );
    return '$_temp0';
  }

  @override
  String get excursionsCreateFab => 'Экскурсия құру';

  @override
  String get excursionsFreePrice => 'Тегін';

  @override
  String excursionsPriceFrom(Object price) {
    return '$price бастап';
  }

  @override
  String excursionsOffersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гид',
      one: '1 гид',
      zero: 'Әзірге гид жоқ',
    );
    return '$_temp0';
  }

  @override
  String get excursionsDurationHourShort => 'сағ';

  @override
  String get excursionsDurationMinuteShort => 'мин';

  @override
  String get excursionDetailsTitle => 'Экскурсия мәліметтері';

  @override
  String get excursionDetailsPrice => 'Баға';

  @override
  String get excursionDetailsPerPerson => '/адам';

  @override
  String get excursionDetailsIntensity => 'Қарқын';

  @override
  String get excursionDetailsIntensityModerate => 'Орташа';

  @override
  String get excursionDetailsGroupSize => 'Топ өлшемі';

  @override
  String excursionDetailsGroupSizeUpTo(Object count) {
    return '$count дейін';
  }

  @override
  String get excursionDetailsLanguage => 'Тіл';

  @override
  String get excursionLanguageEnglish => 'Ағылшын';

  @override
  String get excursionLanguageRussian => 'Орыс';

  @override
  String get excursionLanguageKazakh => 'Қазақ';

  @override
  String get excursionLanguageFrench => 'Француз';

  @override
  String get excursionLanguageJapanese => 'Жапон';

  @override
  String get excursionLanguageGerman => 'Неміс';

  @override
  String get excursionLanguageSpanish => 'Испан';

  @override
  String get excursionLanguageTurkish => 'Түрік';

  @override
  String get excursionDetailsExperience => 'Сипаттама';

  @override
  String get excursionDetailsWhatToExpect => 'Не күтуге болады';

  @override
  String get excursionDetailsSelectedOfferIncluded =>
      'Таңдалған гидте не кіреді';

  @override
  String get excursionDetailsLeadGuide => 'Сіздің гидіңіз';

  @override
  String get excursionDetailsGuideName => 'Гид';

  @override
  String get excursionDetailsGuideSubtitle => 'Тексерілген жергілікті сарапшы';

  @override
  String get excursionDetailsGuideQuote =>
      'Жергілікті контексті, дұрыс ырғағы және қашан баяулау керегін білетін гиді бар маршрут есте жақсы сақталады.';

  @override
  String get excursionDetailsMessageGuide => 'Гидке жазу';

  @override
  String get excursionDetailsOffersTitle => 'Қолжетімді гидтер';

  @override
  String get excursionDetailsOffersEmpty => 'Әзірге қолжетімді гидтер жоқ';

  @override
  String get excursionDetailsOfferSelected => 'Таңдалды';

  @override
  String get excursionDetailsOfferCurrentUser => 'Бұл сіз';

  @override
  String get excursionDetailsOffersSearchHint => 'Гидтер мен ұсыныстарды іздеу';

  @override
  String get excursionDetailsOffersLoadMore => 'Тағы гидтерді көрсету';

  @override
  String get excursionDetailsOffersLoadFailed =>
      'Гидтерді жүктеу мүмкін болмады';

  @override
  String get excursionDetailsOffersSortRating => 'Рейтинг';

  @override
  String get excursionDetailsOffersSortExperience => 'Тәжірибе';

  @override
  String get excursionDetailsOffersSortPrice => 'Баға';

  @override
  String get excursionDetailsOffersFiltersTitle => 'Гид сүзгілері';

  @override
  String get excursionDetailsOffersMaxPrice => 'Ең жоғары баға';

  @override
  String get excursionDetailsOffersMaxPriceHint => 'Мысалы, 50000';

  @override
  String get excursionDetailsOffersAvailableDate => 'Қолжетімді күн';

  @override
  String get excursionDetailsOffersAvailableDateHint => 'кк.аа.жжжж';

  @override
  String get excursionDetailsOffersAvailableDateInvalid =>
      'Күнді кк.аа.жжжж форматында енгізіңіз';

  @override
  String get excursionDetailsOffersMinGroup => 'Мин. топ өлшемі';

  @override
  String get excursionDetailsOffersMinGroupHint => 'Мысалы, 4';

  @override
  String get excursionDetailsOffersLanguageAny => 'Кез келген тіл';

  @override
  String get excursionDetailsOffersLanguageSearchHint =>
      'Тілді немесе кодты іздеу';

  @override
  String get excursionDetailsOffersLanguageNoResults => 'Тіл табылмады';

  @override
  String get excursionDetailsOffersApplyFilters => 'Сүзгілерді қолдану';

  @override
  String get excursionDetailsMapPreview => 'Кездесу нүктесі';

  @override
  String get excursionDetailsItinerary => 'Маршрут';

  @override
  String get excursionDetailsMeetingPoint => 'Кездесу орны';

  @override
  String get excursionDetailsTotal => 'Барлығы';

  @override
  String get excursionDetailsBook => 'Брондау';

  @override
  String get excursionDetailsBookingSeatCheckNote =>
      'Тобыңызға нақты орын саны брондау экранында тексеріледі.';

  @override
  String get excursionDetailsCheckingSchedule =>
      'Қолжетімді уақыттарды тексеріп жатырмыз...';

  @override
  String get excursionDetailsNoAvailableSlots =>
      'Бұл гидте осы экскурсияға әзірге қолжетімді уақыттар жоқ.';

  @override
  String get excursionDetailsEditOffer => 'Ұсынысты өзгерту';

  @override
  String get excursionDetailsLoadFailed => 'Экскурсияны жүктеу мүмкін болмады';

  @override
  String get excursionDetailsBookingComingSoon =>
      'Экскурсияны брондау жақында қолжетімді болады.';

  @override
  String get excursionDetailsGuideChatComingSoon =>
      'Гидпен чат жақында қолжетімді болады.';

  @override
  String get excursionBookingTitle => 'Экскурсияны брондау';

  @override
  String get excursionBookingSchedule => 'Кесте';

  @override
  String get excursionBookingChange => 'Өзгерту';

  @override
  String get excursionBookingDate => 'Күні';

  @override
  String get excursionBookingTimeSlot => 'Уақыт';

  @override
  String get excursionBookingTravelers => 'Саяхатшылар';

  @override
  String get excursionBookingAdults => 'Ересектер';

  @override
  String get excursionBookingChildren => 'Балалар';

  @override
  String get excursionBookingSummary => 'Қорытынды';

  @override
  String excursionBookingAdultSummary(Object count, Object price) {
    return 'Ересектер ($count × $price)';
  }

  @override
  String excursionBookingChildrenSummary(Object count, Object price) {
    return 'Балалар ($count × $price)';
  }

  @override
  String get excursionBookingServiceFeeSummary => 'Қызмет ақысы (5%)';

  @override
  String get excursionBookingTotalPrice => 'Жалпы баға';

  @override
  String get excursionBookingConfirmReservation => 'Брондауды растау';

  @override
  String excursionBookingPaymentPendingNote(Object amount) {
    return 'Қазір төлем алынбайды. Онлайн төлем қосылғаннан кейін пайда болады. Барлығы: $amount';
  }

  @override
  String get excursionBookingSubmitted =>
      'Брондау расталды. Онлайн төлем жақында қосылады.';

  @override
  String get excursionBookingAlreadyBookedTitle => 'Бұл уақытқа бронь бар';

  @override
  String get excursionBookingAlreadyBookedMessage =>
      'Қонақтар санын «Менің экскурсияларым» бөлімінде өзгертуге болады.';

  @override
  String get excursionBookingOpenMyExcursions => 'Менің экскурсияларымды ашу';

  @override
  String get excursionBookingLoadFailed =>
      'Экскурсия брондауын жүктеу мүмкін болмады';

  @override
  String get excursionBookingPerPerson => '/ адам';

  @override
  String get excursionBookingSelectSlot => 'Қолжетімді уақытты таңдаңыз';

  @override
  String excursionBookingSelectedSlotUnavailable(Object count) {
    return 'Таңдалған уақыт $count қонаққа енді қолжетімсіз. Басқа уақытты таңдаңыз.';
  }

  @override
  String get excursionBookingScheduleLoadFailed =>
      'Қолжетімді уақыттарды жүктеу мүмкін болмады';

  @override
  String get excursionBookingNoSlots =>
      'Гид бұл ұсыныс үшін қолжетімді уақыттарды әлі қоспады.';

  @override
  String excursionBookingSeatsLeft(Object count) {
    return 'Қалған орын: $count';
  }

  @override
  String get excursionDetailsNoDescription =>
      'Гид жақында толық сипаттаманы қосады.';

  @override
  String excursionDetailsRouteStopsCount(Object count) {
    return 'Аялдама саны: $count';
  }

  @override
  String excursionDetailsTravelFromPrevious(Object minutes) {
    return 'Алдыңғы аялдамадан $minutes мин';
  }

  @override
  String get createExcursionTitle => 'Экскурсия құру';

  @override
  String get createExcursionEditTitle => 'Ұсынысты өзгерту';

  @override
  String get createExcursionSubmit => 'Тексеруге жіберу';

  @override
  String get createExcursionSaveDraft => 'Черновикті сақтау';

  @override
  String get createExcursionSaveChanges => 'Сақтау';

  @override
  String get createExcursionSuccess => 'Экскурсия тексеруге жіберілді';

  @override
  String get createExcursionDraftSaved => 'Черновик сақталды';

  @override
  String get createExcursionUpdateSuccess => 'Ұсыныс жаңартылды';

  @override
  String get createExcursionFailed => 'Экскурсияны жасау мүмкін болмады';

  @override
  String get createExcursionUpdateFailed => 'Ұсынысты жаңарту мүмкін болмады';

  @override
  String get createExcursionCoverSection => 'Экскурсия қаптамасы';

  @override
  String get createExcursionCoverUploadTitle => 'Экскурсия суретін жүктеу';

  @override
  String get createExcursionCoverChangeAction => 'Экскурсия суретін өзгерту';

  @override
  String get createExcursionCoverUploadHint =>
      'JPG, PNG немесе WEBP. Көрікті орын таңдалса, өз суретіңізді жүктемейінше оның суреті қолданылады.';

  @override
  String get createExcursionSelectedLandmark => 'Көрікті жер';

  @override
  String get createExcursionLandmarkNameLabel => 'Орын';

  @override
  String get createExcursionLandmarkNameHint => 'Мысалы, Медеу';

  @override
  String get createExcursionLandmarkValidation => 'Көрікті жерді таңдаңыз';

  @override
  String get createExcursionCountryValidation => 'Алдымен елді таңдаңыз';

  @override
  String get createExcursionSelectCountryFirst => 'Алдымен елді таңдаңыз';

  @override
  String get createExcursionManualLocationHint =>
      'Өз локацияңызды енгізуге немесе осы елдегі көрікті жерді таңдауға болады.';

  @override
  String get createExcursionLocationLockedByAttraction =>
      'Локация көрікті жерлер анықтамалығынан алынды. Өзгерту үшін басқа көрікті жерді таңдаңыз.';

  @override
  String get createExcursionAttractionCatalogHint =>
      'Таңдалған елдің көрікті жерлер каталогы';

  @override
  String get createExcursionAttractionCatalogSource =>
      'Көрікті жерлер каталогынан';

  @override
  String get createExcursionSingleAttractionMode => 'Бір көрікті жер';

  @override
  String get createExcursionCombinedRouteMode => 'Бірнеше аялдамалы маршрут';

  @override
  String createExcursionCombinedRouteMinStopsValidation(Object count) {
    return 'Кемінде $count көрікті жер аялдамасын қосыңыз';
  }

  @override
  String createExcursionCombinedRouteMaxStopsValidation(Object count) {
    return '$count-тен көп көрікті жер аялдамасын қоспаңыз';
  }

  @override
  String get createExcursionDuplicateRouteStopValidation =>
      'Бұл көрікті жер маршрутта бар.';

  @override
  String get excursionSelectLocationTitle => 'Орын таңдау';

  @override
  String get excursionSelectLocationCountrySection => 'Елді таңдаңыз';

  @override
  String get excursionSelectLocationCountrySearchHint => 'Елдерді іздеу...';

  @override
  String get excursionCountryKazakhstan => 'Қазақстан';

  @override
  String get excursionCountryFrance => 'Франция';

  @override
  String get excursionCountryJapan => 'Жапония';

  @override
  String get excursionCountryItaly => 'Италия';

  @override
  String get excursionSelectLocationAttractionSection =>
      'Көрікті жерді таңдаңыз';

  @override
  String get excursionSelectLocationAttractionSearchHint =>
      'Көрікті жерлерді іздеу...';

  @override
  String get excursionSelectLocationSelected => 'Таңдалды';

  @override
  String excursionSelectLocationPageCaption(Object current, Object total) {
    return '$current / $total БЕТ';
  }

  @override
  String get createExcursionCategorization => 'Саяхат санаты';

  @override
  String get createExcursionCategoryAdventure => 'Шытырман';

  @override
  String get createExcursionCategoryCultural => 'Мәдениет';

  @override
  String get createExcursionCategoryCulinary => 'Гастро';

  @override
  String get createExcursionCategoryWellness => 'Wellness';

  @override
  String get createExcursionDetailedItinerary => 'Толық маршрут';

  @override
  String get createExcursionAddTimeSlot => 'Уақыт слотын қосу';

  @override
  String get createExcursionEditTimeSlot => 'Уақыт слотын өңдеу';

  @override
  String get createExcursionItineraryEmpty =>
      'Кемінде екі маршрут пунктін қосыңыз. Олар туристерге экскурсия мәліметінде көрсетіледі.';

  @override
  String get createExcursionAutosaveHint =>
      'Ұсынысты жасау кезінде прогресс жергілікті сақталады';

  @override
  String get createExcursionAutosaveRestored =>
      'Жергілікті черновик қалпына келтірілді';

  @override
  String get createExcursionItineraryValidation =>
      'Маршрут пунктінің уақытын, атауын және сипаттамасын толтырыңыз';

  @override
  String createExcursionItineraryMinSlotsValidation(Object count) {
    return 'Кемінде $count маршрут пунктін қосыңыз';
  }

  @override
  String createExcursionItineraryDescriptionMinLengthValidation(Object count) {
    return 'Маршрут пунктінің сипаттамасы кемінде $count таңба болуы керек';
  }

  @override
  String get createExcursionStartOffsetValidation =>
      'Маршрут пунктінің басталу уақытын көрсетіңіз';

  @override
  String get createExcursionItineraryTitleValidation =>
      'Маршрут пунктінің атауы кемінде 2 таңба болуы керек';

  @override
  String createExcursionOffsetMinutesShort(Object minutes) {
    return '+$minutes мин';
  }

  @override
  String createExcursionOffsetHoursShort(Object hours) {
    return '+$hours сағ';
  }

  @override
  String createExcursionOffsetHoursMinutesShort(Object hours, Object minutes) {
    return '+$hours сағ $minutes мин';
  }

  @override
  String get createExcursionDurationLabel => 'Ұзақтығы';

  @override
  String get createExcursionDurationHint => 'Мысалы, 4 сағат';

  @override
  String get createExcursionDurationUnitLabel => 'Бірлік';

  @override
  String get createExcursionDurationUnitMinutes => 'Минут';

  @override
  String get createExcursionDurationUnitHours => 'Сағат';

  @override
  String get createExcursionDurationUnitDays => 'Күн';

  @override
  String get createExcursionDurationValidation =>
      'Ұзақтығы кемінде 15 минут болуы керек';

  @override
  String get createExcursionMaxGroupSizeLabel => 'Қонақтар саны';

  @override
  String get createExcursionMaxGroupSizeHint => 'Мысалы, 12';

  @override
  String get createExcursionGroupSizeValidation =>
      'Топ өлшемін 1-ден 100-ге дейін енгізіңіз';

  @override
  String get createExcursionLanguagesLabel => 'Экскурсия тілдері';

  @override
  String get createExcursionLanguagesHint => 'Ағылшын, француз, жапон...';

  @override
  String get createExcursionLanguagesValidation =>
      'Кемінде бір экскурсия тілін қосыңыз';

  @override
  String createExcursionLanguagesPickerHint(Object count) {
    return '$count тілге дейін таңдауға болады';
  }

  @override
  String get createExcursionLanguagesSearchHint =>
      'Тіл немесе код бойынша іздеу';

  @override
  String get createExcursionLanguagesNoResults => 'Тіл табылмады';

  @override
  String createExcursionLanguagesLimitValidation(Object count) {
    return '$count тілге дейін таңдауға болады';
  }

  @override
  String get createExcursionVisibilityTitle => 'Экскурсия көрінуі';

  @override
  String get createExcursionVisibilityPublicDescription =>
      'Inflap маркетплейсіндегі барлық пайдаланушыларға көрінеді.';

  @override
  String get createExcursionVisibilityUnlistedDescription =>
      'Экскурсияны тек тікелей сілтемесі бар пайдаланушылар көріп, брондай алады.';

  @override
  String get createExcursionMeetingPointHint =>
      'Кездесу мекенжайын немесе бағдарды енгізіңіз...';

  @override
  String get createExcursionSoulTitle => 'Саяхат рухы';

  @override
  String get createExcursionNameLabel => 'Экскурсия атауы';

  @override
  String get createExcursionNameHint => 'Мысалы, Алматы таулы саяхаты';

  @override
  String get createExcursionSummaryLabel => 'Қысқа сипаттама';

  @override
  String get createExcursionSummaryHint => 'Саяхатшыларға қысқа уәде';

  @override
  String get createExcursionSummaryValidation =>
      'Қысқа сипаттама кемінде 3 таңбадан тұруы керек';

  @override
  String get createExcursionSoulHint =>
      'Маршрут атмосферасын, жасырын детальдарды және саяхат сезімін сипаттаңыз...';

  @override
  String get createExcursionDescriptionValidation =>
      'Сипаттама кемінде 20 таңбадан тұруы керек';

  @override
  String get createExcursionInvestmentTitle => 'Бір адамға құны';

  @override
  String get createExcursionCurrencyValidation => 'Валюта кодын енгізіңіз';

  @override
  String get createCurrencyKzt => 'теңге';

  @override
  String get createCurrencyUsd => 'АҚШ доллары';

  @override
  String get createCurrencyEur => 'еуро';

  @override
  String get createCurrencyRub => 'рубль';

  @override
  String get createCurrencyGbp => 'фунт стерлинг';

  @override
  String get createExcursionIncludedItemsLabel => 'Не кіреді';

  @override
  String get createExcursionIncludedItemsHint =>
      'Үтір арқылы: SUV, пикник, билеттер';

  @override
  String get createExcursionIncludedItemsEmpty =>
      'Көлік, тамақ, кіру билеттері немесе жабдық сияқты нақты пункттерді қосыңыз';

  @override
  String get createExcursionIncludedItemsEditorTitle => 'Не кіреді';

  @override
  String get createExcursionIncludedItemsAdd => 'Пункт қосу';

  @override
  String get createExcursionIncludedItemsRemove => 'Пунктті жою';

  @override
  String get createExcursionIncludedItemsTypeLabel => 'Түрі';

  @override
  String get createExcursionIncludedItemsValueLabel => 'Нақты не кіреді';

  @override
  String get createExcursionIncludedItemsValueHint =>
      'Мысалы, жол талғамайтын көлікпен трансфер';

  @override
  String get createExcursionIncludedItemsValidation =>
      'Әр пунктті толтырыңыз немесе бос жолдарды өшіріңіз';

  @override
  String get createExcursionIncludedTypeTransport => 'Көлік';

  @override
  String get createExcursionIncludedTypeFood => 'Тамақ';

  @override
  String get createExcursionIncludedTypeTickets => 'Билеттер';

  @override
  String get createExcursionIncludedTypeEquipment => 'Жабдық';

  @override
  String get createExcursionIncludedTypeGuide => 'Гид';

  @override
  String get createExcursionIncludedTypePhoto => 'Фото';

  @override
  String get createExcursionIncludedTypeOther => 'Басқа';

  @override
  String get createExcursionStartOffsetLabel => 'Басталуы, мин';

  @override
  String get createExcursionSlotDurationLabel => 'Ұзақтығы, мин';

  @override
  String get createExcursionItineraryTitleLabel => 'Атауы';

  @override
  String get createExcursionItineraryTitleHint => 'Мысалы, Тауға көтерілу';

  @override
  String get createExcursionItineraryDescriptionLabel => 'Сипаттама';

  @override
  String get createExcursionItineraryDescriptionHint =>
      'Маршруттың осы бөлігінде не болады';

  @override
  String get createStepBasic => 'Негізгі ақпарат';

  @override
  String get createStepDetailsLogistics => 'Детальдар мен логистика';

  @override
  String get createStepRulesPricing => 'Ережелер мен құны';

  @override
  String get createStepSchedule => 'Формат және кесте';

  @override
  String get createStepParticipation => 'Қатысу';

  @override
  String get createStepLocation => 'Орналасу';

  @override
  String createStepCounter(Object current, Object total) {
    return '$current / $total қадам';
  }

  @override
  String get createActivityDiscardTitle => 'Сақтамай шығасыз ба?';

  @override
  String get createActivityDiscardDescription =>
      'Белсенділік черновигіндегі өзгерістер жоғалады.';

  @override
  String get createActivityDiscardConfirm => 'Шығу';

  @override
  String get createHelpAction => 'Көмек';

  @override
  String get createStepNext => 'Келесі қадам';

  @override
  String get createStepBack => 'Артқа';

  @override
  String get createCoverSection => 'Белсенділік қаптамасын жүктеңіз';

  @override
  String get createCoverUploadTitle => 'Сапалы сурет жүктеу';

  @override
  String get createCoverChangeAction => 'Қаптаманы өзгерту';

  @override
  String get createCoverUploadHint =>
      'JPG, PNG немесе WEBP. Ұсынылатын өлшем 1600x900px, ең көбі 20MB';

  @override
  String get createCoverUploadFailed =>
      'Қаптаманы жүктеу мүмкін болмады. Қайта көріңіз.';

  @override
  String get createCoverUploadTooLarge =>
      'Сурет тым үлкен. Ең үлкен өлшемі — 20MB.';

  @override
  String get createCoverUploadUnsupportedFormat =>
      'Сурет форматы қолдау таппайды. JPG, PNG немесе WEBP пайдаланыңыз.';

  @override
  String get createCoverUploadInProgress =>
      'Қаптама жүктеліп болғанша күтіңіз.';

  @override
  String get createCoverUploadRetryRequired =>
      'Жалғастырмас бұрын қаптаманы қайта жүктеңіз.';

  @override
  String get createBasicSection => 'НЕГІЗГІ АҚПАРАТ';

  @override
  String get createTitleLabel => 'Белсенділік атауы';

  @override
  String get createTitleHint => 'Мысалы, пирс жанындағы күн батуы йогасы';

  @override
  String get createTitleValidation => 'Атау кемінде 3 таңбадан тұруы керек';

  @override
  String get createDescriptionLabel => 'Сипаттама';

  @override
  String get createDescriptionHint => 'Белсенділік туралы толығырақ жазыңыз...';

  @override
  String get createDescriptionValidation =>
      'Сипаттама кемінде 10 таңбадан тұруы керек';

  @override
  String get createCategoryLabel => 'Санат';

  @override
  String get createCategoryHint => 'Санат таңдаңыз';

  @override
  String get createCategoryValidation => 'Санатты таңдаңыз';

  @override
  String get createCategoryLoading => 'Санаттар жүктелуде';

  @override
  String get createCategoryLoadFailed => 'Санаттарды жүктеу мүмкін болмады';

  @override
  String get createCategoryEmpty => 'Санаттар әзірге қолжетімсіз';

  @override
  String get createCategoryRetry => 'Қайталау';

  @override
  String get createCategoryPickerTitle => 'Санатты таңдаңыз';

  @override
  String get createCategoryApply => 'Қолдану';

  @override
  String get createSubcategoryLabel => 'Ішкі санат';

  @override
  String get createSubcategoryHint => 'Ішкі санатты таңдаңыз';

  @override
  String get createSubcategoryPickerTitle => 'Ішкі санатты таңдаңыз';

  @override
  String get createSubcategoryApply => 'Қолдану';

  @override
  String get createTagsLabel => 'Тегтер';

  @override
  String get createTagsHint => 'Үтір арқылы: жүгіру, таңғы, саябақ';

  @override
  String get createEventFormatLabel => 'Оқиға форматы';

  @override
  String get createFormatSection => 'ӨТКІЗУ ФОРМАТЫ';

  @override
  String get createScheduleSection => 'КЕСТЕ';

  @override
  String get createDatePartLabel => 'Күні';

  @override
  String get createTimePartLabel => 'Уақыты';

  @override
  String get createStartAtLabel => 'Басталуы';

  @override
  String get createEndAtLabel => 'Аяқталуы';

  @override
  String get createStartDateLabel => 'Басталу күні';

  @override
  String get createEndDateLabel => 'Аяқталу күні';

  @override
  String get createStartTimeLabel => 'Басталу уақыты';

  @override
  String get createEndTimeLabel => 'Аяқталу уақыты';

  @override
  String get createScheduleInputValidation => 'Күн мен уақытты дұрыс енгізіңіз';

  @override
  String get createRegistrationDeadlineLabel => 'Тіркелу мерзімі';

  @override
  String get createEndDateValidation =>
      'Аяқталу уақыты басталудан кейін болуы керек';

  @override
  String get createStartAtTooSoonValidation =>
      'Басталу уақыты кемінде 1 сағаттан кейін болуы керек';

  @override
  String createStartAtMonthLimitValidation(String date) {
    return 'Басталу күні $date-тен кеш болмауы керек';
  }

  @override
  String createEndAtMonthLimitValidation(String date) {
    return 'Аяқталу күні $date-тен кеш болмауы керек';
  }

  @override
  String get createRegistrationDeadlineValidation =>
      'Тіркелу мерзімі басталу уақытынан бұрын болуы керек';

  @override
  String get createRegistrationAutoHint =>
      'Тіркелу белсенділік басталғанға дейін 1 сағат бұрын автоматты түрде жабылады';

  @override
  String get createSaveDraft => 'Жобаны сақтау';

  @override
  String get createAndPublish => 'Жариялау';

  @override
  String get createPublishActivityCta => 'Белсенділікті жариялау';

  @override
  String get createLanguageSection => 'БЕЛСЕНДІЛІК ТІЛІ';

  @override
  String get createVisibilitySection => 'КӨРІНУІ';

  @override
  String get createVisibilityPublic => 'Жалпыға қолжетімді';

  @override
  String get createVisibilityPrivate => 'Жабық';

  @override
  String get createVisibilityUnlisted => 'Сілтеме бойынша';

  @override
  String get createActivityPrivacyTitle => 'Белсенділік құпиялығы';

  @override
  String get createVisibilityPrivateWithPassword => 'Құпиясөзбен жабық';

  @override
  String get createVisibilityByLink => 'Сілтеме арқылы';

  @override
  String get createVisibilityPublicDescription =>
      'Inflap-дегі баршаға көрінеді';

  @override
  String get createVisibilityPrivateDescription =>
      'Коды бар адамдар ғана көре алады';

  @override
  String get createVisibilityUnlistedDescription =>
      'Тек шақыру сілтемесі арқылы қолжетімді';

  @override
  String get createVisibilityPickerTitle => 'Құпиялықты таңдаңыз';

  @override
  String get createVisibilityApply => 'Қолдану';

  @override
  String get createVisibilityPasswordLabel => 'Белсенділік құпиясөзі';

  @override
  String get createVisibilityPasswordPlaceholder => 'Құпиясөзді енгізіңіз';

  @override
  String get createVisibilityPasswordValidation =>
      '4-тен 64 таңбаға дейінгі құпиясөзді енгізіңіз';

  @override
  String get createVisibilityPasswordAsciiValidation =>
      'Тек ағылшын әріптерін, сандарды және символдарды қолданыңыз';

  @override
  String get createVisibilityPasswordEditHint =>
      'Ағымдағы құпиясөзді сақтау үшін өрісті бос қалдырыңыз';

  @override
  String get createCapacitySection => 'ОРЫН САНЫ';

  @override
  String get createCapacityUnlimited => 'Шектеусіз';

  @override
  String get createCapacityLimited => 'Шектеулі';

  @override
  String get createMinParticipantsLabel => 'Минимум';

  @override
  String get createMaxParticipantsLabel => 'Максимум';

  @override
  String get createParticipantLimitsTitle => 'Қатысушылар лимиті';

  @override
  String get createUnlimitedParticipantsLabel => 'Қатысушылар саны шектеусіз';

  @override
  String get createAllowParticipantInvitesLabel =>
      'Қатысушыларға достарын шақыруға рұқсат беру';

  @override
  String get createAllowParticipantInvitesHint =>
      'Белсенділік авторы өз достарын әрқашан шақыра алады. Басқа пайдаланушылар бұл опция қосылған кезде ғана өз достарын шақыра алады.';

  @override
  String get createParticipantsMinShort => 'МИН';

  @override
  String get createParticipantsMaxShort => 'МАКС';

  @override
  String get createNoLimitPlaceholder => 'Шектеу жоқ';

  @override
  String get createMaxParticipantsValidation =>
      '1 мен 100 қатысушы аралығындағы максимумды енгізіңіз';

  @override
  String get createMinParticipantsValidation =>
      'Кемінде 2 қатысушыдан тұратын минимумды енгізіңіз';

  @override
  String get createMinExceedsMaxValidation =>
      'Минимум максимумнан асып кетпеуі керек';

  @override
  String get createPriceSection => 'ҚҰНЫ';

  @override
  String get createPriceFree => 'Тегін';

  @override
  String get createPricePaid => 'Ақылы';

  @override
  String get createPricingModelTitle => 'Баға моделі';

  @override
  String get createPriceAmountLabel => 'Сома';

  @override
  String get createPriceAmountOptionalLabel => 'Баға мөлшері (міндетті емес)';

  @override
  String get createPriceAmountPlaceholder => '\$ 0.00';

  @override
  String get createCurrencyLabel => 'Валюта';

  @override
  String get createPricePerPersonHint => 'адамға';

  @override
  String get createPriceValidation => 'Дұрыс соманы енгізіңіз';

  @override
  String get createOnlineSection => 'ОНЛАЙН ҚАТЫНАУ';

  @override
  String get createOnlineAccessHint =>
      'Қатысушылар онлайн қосылу үшін пайдаланатын сілтемені көрсетіңіз';

  @override
  String get createMeetingUrlLabel => 'Кездесу сілтемесі';

  @override
  String get createMeetingUrlHint => 'https://zoom.us/...';

  @override
  String get createMeetingUrlValidation =>
      'Онлайн кездесу сілтемесін көрсетіңіз';

  @override
  String get createMeetingPointLocationLabel => 'Кездесу орны / локация';

  @override
  String get createMeetingPointTitle => 'КЕЗДЕСУ НҮКТЕСІ';

  @override
  String get createVenueOrAddressHint =>
      'Өтетін жерді немесе мекенжайды енгізіңіз';

  @override
  String get createMapLinkLabel => 'Карта сілтемесі';

  @override
  String get createMapLinkHint => 'Карта сілтемесін қойыңыз';

  @override
  String get createMapLinkInvalidError =>
      'Сілтеме бойынша координаттарды анықтай алмадық. Нүктені біздің картадан таңдаңыз немесе басқа картадан координаттары бар сілтемені қойыңыз.';

  @override
  String get createMapLinkResolvingError =>
      'Сілтеме бойынша координаттарды анықтап жатырмыз. Бірнеше секунд күтіңіз.';

  @override
  String get createMapLinkRequiredError =>
      'Карта сілтемесін қосыңыз немесе біздің картадан нүктені таңдаңыз.';

  @override
  String get createMapEarlyStageNotice =>
      'Қолданбадағы карта әзірге ерте кезеңде: басқа картадан сілтемені қойыңыз немесе біздің картадан нүкте белгілеңіз. Жақында картаны жақсартып, кездесу нүктесін басқа карталарға өтпей-ақ осы жерден таңдауға мүмкіндік береміз.';

  @override
  String get createOfflineSection => 'ӨТКІЗУ ОРНЫ';

  @override
  String get createLocationPreviewHint =>
      'Қатысушылар қай жерде кездесетінін түсінуі үшін қала немесе мекенжай қосыңыз';

  @override
  String get createAuthorLocationMismatchHint =>
      'Кездесу орны ағымдағы локацияңыздан өзгеше. Белсенділік басқа жерде жоспарланса, осылай қалдырыңыз.';

  @override
  String get createCountryLabel => 'Ел';

  @override
  String get createCityLabel => 'Қала';

  @override
  String get createCityHint => 'Мысалы: Алматы';

  @override
  String get createAddressLabel => 'Мекенжай';

  @override
  String get createAddressHint => 'Көше, үй, корпус';

  @override
  String get createMapTapHint =>
      'Кездесу нүктесін белгілеу үшін картаға түртіңіз';

  @override
  String get createMapResolvingHint => 'Мекенжай анықталып жатыр...';

  @override
  String get createMapUnavailable =>
      'Google Maps бапталған iOS және Android жинақтарында қолжетімді';

  @override
  String get createLocationValidation => 'Қала немесе мекенжайды көрсетіңіз';

  @override
  String get editActivityTitle => 'Өңдеу';

  @override
  String get editActivityButton => 'Өңдеу';

  @override
  String get editActivitySubmit => 'Сақтау';

  @override
  String get editActivitySuccess => 'Белсенділік жаңартылды';

  @override
  String get editActivityFailed => 'Белсенділікті жаңарту сәтсіз аяқталды';

  @override
  String get activityPublishButton => 'Жариялау';

  @override
  String get activityPublishSuccess => 'Белсенділік жарияланды';

  @override
  String get activityPublishFailed => 'Белсенділікті жариялау сәтсіз аяқталды';

  @override
  String get editFormatLocked =>
      'Форматты жасалғаннан кейін өзгерту мүмкін емес';

  @override
  String get editLocationLocked =>
      'Кездесу мекенжайын белсенділік басталғанға дейін кемінде 1 сағат қалғанда ғана өзгертуге болады';

  @override
  String get editPriceRestrictionHint =>
      'Басқа қатысушылар жазылғаннан кейін бағаны өзгерту мүмкін емес';

  @override
  String get myActivitiesTitle => 'Менің белсенділіктерім';

  @override
  String get myStoriesTitle => 'Менің посттарым';

  @override
  String get myStoryArchiveTitle => 'Менің хикаяларым';

  @override
  String get myActivitiesEmpty => 'Сізде әлі жасалған белсенділіктер жоқ';

  @override
  String get myActivitiesEmptyHint =>
      'Бірінші белсенділігіңізді жасаңыз, ол осы жерде пайда болады';

  @override
  String get myActivitiesLoadFailed =>
      'Белсенділіктеріңізді жүктеу мүмкін болмады';

  @override
  String get myActivitiesFilterAll => 'Барлығы';

  @override
  String myActivitiesLastUpdated(Object date) {
    return 'Жаңартылды $date';
  }

  @override
  String get myActivitiesContinueButton => 'Жалғастыру';

  @override
  String get myActivitiesAttendedTab => 'Қатысқан';

  @override
  String get myActivitiesAttendedEmpty =>
      'Сіз әлі ешқандай белсенділікке қатысқан жоқсыз';

  @override
  String get myActivitiesAttendedEmptyHint =>
      'Сіз қосылған белсенділіктер осы жерде пайда болады';

  @override
  String get myActivitiesAttendedLoadFailed =>
      'Қатысқан белсенділіктерді жүктеу мүмкін болмады';

  @override
  String get myActivitiesFilterButton => 'Сүзгілер';

  @override
  String get myActivitiesFilterTitle => 'Сүзгілер';

  @override
  String get myActivitiesFilterDateRange => 'Күн аралығы';

  @override
  String get myActivitiesFilterStartDate => 'Басталу күні';

  @override
  String get myActivitiesFilterEndDate => 'Аяқталу күні';

  @override
  String get myActivitiesFilterDatePlaceholder => 'dd.mm.yyyy';

  @override
  String get myActivitiesFilterDateHint =>
      'Күнді dd.mm.yyyy форматында қолмен енгізіңіз';

  @override
  String get myActivitiesFilterInvalidDate => 'Дұрыс күнді енгізіңіз';

  @override
  String get myActivitiesFilterInvalidRange =>
      'Аяқталу күні басталу күнінен ерте болмауы керек';

  @override
  String get myActivitiesFilterStatus => 'Мәртебе бойынша сүзу';

  @override
  String get myActivitiesFilterClear => 'Тазалау';

  @override
  String get myActivitiesFilterApply => 'Сүзгілерді қолдану';

  @override
  String get myActivitiesRecreateButton => 'Қайта жасау';

  @override
  String get myActivitiesRetryButton => 'Қайталау';

  @override
  String get myActivitiesPriceNoteFree => 'тегін';

  @override
  String get myExcursionsTitle => 'Менің экскурсияларым';

  @override
  String get myExcursionsSearchHint => 'Экскурсия, гид және қала бойынша іздеу';

  @override
  String get myExcursionsFilterTitle => 'Экскурсия сүзгілері';

  @override
  String get myExcursionsReviewSuccess => 'Пікір жарияланды';

  @override
  String get myExcursionsSortLabel => 'Сұрыптау';

  @override
  String get myExcursionsSortDate => 'Күні бойынша';

  @override
  String get myExcursionsSortPrice => 'Бағасы бойынша';

  @override
  String get myExcursionsLoadFailed =>
      'Экскурсияларыңызды жүктеу мүмкін болмады';

  @override
  String get myExcursionsBookedEmpty => 'Сізде әлі брондалған экскурсиялар жоқ';

  @override
  String get myExcursionsVisitedEmpty => 'Сіз әлі экскурсияға барған жоқсыз';

  @override
  String get myExcursionsBookedEmptyHint =>
      'Брондалған экскурсиялар осы жерде пайда болады';

  @override
  String get myExcursionsVisitedEmptyHint =>
      'Экскурсиядан кейін осы жерде пікір қалдыра аласыз';

  @override
  String get myExcursionsBookedTab => 'Брондалған';

  @override
  String get myExcursionsVisitedTab => 'Барған';

  @override
  String get myExcursionsGuideFallback => 'Inflap гиді';

  @override
  String get myExcursionsUntitled => 'Экскурсия';

  @override
  String myExcursionsGuideLine(Object guide) {
    return 'Гид: $guide';
  }

  @override
  String myExcursionsGuests(Object count) {
    return 'Қонақтар: $count';
  }

  @override
  String get myExcursionsReviewButton => 'Бағалау';

  @override
  String get myExcursionsReviewed => 'Бағаланған';

  @override
  String get myExcursionsEditGuestsButton => 'Қонақтарды өзгерту';

  @override
  String get myExcursionsEditGuestsTitle => 'Қонақтар санын өзгерту';

  @override
  String get myExcursionsEditGuestsHint =>
      'Біз бос орындарды тексеріп, жаңа бронь жасамай броньды жаңартамыз.';

  @override
  String get myExcursionsUpdateGuestsSuccess => 'Қонақтар саны жаңартылды';

  @override
  String get myExcursionsUpdateGuestsFailed =>
      'Қонақтар санын жаңарту мүмкін болмады. Бос орындарды тексеріп, қайталап көріңіз.';

  @override
  String myExcursionsGuestsAdditionalCharge(Object amount) {
    return 'Қосымша төлем: $amount';
  }

  @override
  String myExcursionsGuestsRefundDue(Object amount) {
    return 'Қайтарым: $amount';
  }

  @override
  String get myExcursionsGuestsNoPaymentChange => 'Баға өзгермейді';

  @override
  String get myExcursionsGuestsPaymentQuoteHint =>
      'Есеп серверде жасалды. Нақты қосымша төлем немесе қайтарым төлем сервисі арқылы қосылады.';

  @override
  String get myExcursionsGuestsQuoteLoading =>
      'Баға өзгерісін есептеп жатырмыз...';

  @override
  String get myExcursionsGuestsQuoteFailed =>
      'Баға өзгерісін есептеу мүмкін болмады. Бос орындарды тексеріп, қайталап көріңіз.';

  @override
  String get myExcursionsPayAndSaveGuests => 'Төлеп сақтау';

  @override
  String get myExcursionsRefundAndSaveGuests => 'Қайтарып сақтау';

  @override
  String get myExcursionsCancelBookingButton => 'Броньды болдырмау';

  @override
  String get myExcursionsCancelBookingTitle => 'Броньды болдырмау керек пе?';

  @override
  String get myExcursionsCancelBookingHint =>
      'Біз сіздің орныңызды болдырмаймыз және гидке броньды сіз болдырмағаныңызды көрсетеміз.';

  @override
  String get myExcursionsCancelQuoteLoading =>
      'Қайтарым шарттарын есептеп жатырмыз...';

  @override
  String get myExcursionsCancelQuoteFailed =>
      'Қайтарым шарттарын есептеу мүмкін болмады. Қайталап көріңіз.';

  @override
  String myExcursionsCancelBookingRefund(Object amount, int percent) {
    return 'Қайтарым: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelBookingNoRefund => 'Қайтарым қолжетімсіз';

  @override
  String get myExcursionsCancelBookingRefundHint =>
      'Соңғы қайтарым сомасын сервер бекітеді. Нақты ақша қайтару төлем сервисі арқылы қосылады.';

  @override
  String get myExcursionsCancelPolicyTitle => 'Болдырмау ережелері';

  @override
  String get myExcursionsCancelPolicyFull =>
      'Басталуына 24+ сағат қалғанда: 100%';

  @override
  String get myExcursionsCancelPolicySeventyFive =>
      'Басталуына 12-24 сағат қалғанда: 75%';

  @override
  String get myExcursionsCancelPolicyHalf =>
      'Басталуына 6-12 сағат қалғанда: 50%';

  @override
  String get myExcursionsCancelPolicyQuarter =>
      'Басталуына 2-6 сағат қалғанда: 25%';

  @override
  String get myExcursionsCancelPolicyZero =>
      'Басталуына 2 сағаттан аз қалғанда: 0%';

  @override
  String get myExcursionsCancelBookingReasonLabel => 'Себебі (міндетті емес)';

  @override
  String get myExcursionsCancelBookingReasonPlaceholder =>
      'Мысалы: жоспар өзгерді';

  @override
  String get myExcursionsCancelBookingConfirm => 'Броньды болдырмау';

  @override
  String get myExcursionsCancelBookingSuccess => 'Бронь болдырылмады';

  @override
  String get myExcursionsCancelBookingFailed =>
      'Броньды болдырмау мүмкін болмады';

  @override
  String myExcursionsCancelledWithRefund(Object amount, int percent) {
    return 'Болдырылмады. Қайтарым: $amount ($percent%)';
  }

  @override
  String get myExcursionsCancelledWithoutRefund => 'Қайтарымсыз болдырылмады';

  @override
  String get myExcursionsFilterStatus => 'Мәртебе';

  @override
  String get myExcursionsStatusRequested => 'Брондалған';

  @override
  String get myExcursionsFilterReview => 'Пікірлер';

  @override
  String get myExcursionsFilterReviewAll => 'Барлығы';

  @override
  String get myExcursionsFilterUnreviewed => 'Пікірсіз';

  @override
  String get myExcursionsFilterReviewed => 'Пікір бар';

  @override
  String get myExcursionsReviewTitle => 'Экскурсияны бағалаңыз';

  @override
  String get myExcursionsReviewCommentError => 'Қысқа пікір жазыңыз';

  @override
  String get myExcursionsReviewFailed => 'Пікірді жариялау мүмкін болмады';

  @override
  String get myExcursionsReviewDeleteFailed => 'Пікірді жою мүмкін болмады';

  @override
  String get myExcursionsReviewRating => 'Баға';

  @override
  String get myExcursionsReviewHint => 'Не ұнады, нені жақсартуға болады?';

  @override
  String get myExcursionsExcursionReviewSectionTitle => 'Экскурсия пікірі';

  @override
  String get myExcursionsExcursionReviewSectionSubtitle =>
      'Бағытты, ұйымдастыруды және жалпы әсерді бағалаңыз.';

  @override
  String get myExcursionsExcursionReviewOptional =>
      'Тек гидті бағалағыңыз келсе, мұны өшіріңіз.';

  @override
  String get myExcursionsGuideReviewSectionTitle => 'Гид пікірі';

  @override
  String get myExcursionsGuideReviewSectionSubtitle =>
      'Қаласаңыз, болашақ саяхатшылар үшін гидті бөлек бағалаңыз.';

  @override
  String get myExcursionsGuideReviewRating => 'Гид бағасы';

  @override
  String get myExcursionsGuideReviewHint =>
      'Гидтің қарым-қатынасы, қамқорлығы және әңгімелеуі қандай болды?';

  @override
  String get myExcursionsGuideReviewOptional =>
      'Міндетті емес, бірақ гидтің сенімді профилін дамытуға көмектеседі.';

  @override
  String get myExcursionsReviewSelectOneError =>
      'Жариялау үшін кемінде бір пікір таңдаңыз';

  @override
  String get myExcursionsReviewDeleteExcursion => 'Экскурсия пікірін жою';

  @override
  String get myExcursionsReviewDeleteGuide => 'Гид пікірін жою';

  @override
  String get myExcursionsReviewPublish => 'Жариялау';

  @override
  String get excursionReviewActionsTitle => 'Пікір әрекеттері';

  @override
  String get excursionReviewEditAction => 'Пікірді өңдеу';

  @override
  String get excursionReviewDeleteAction => 'Пікірді жою';

  @override
  String get excursionReviewEditTitle => 'Пікірді өңдеу';

  @override
  String get excursionReviewEditSave => 'Пікірді сақтау';

  @override
  String get excursionReviewUpdated => 'Пікір жаңартылды';

  @override
  String get excursionReviewDeleted => 'Пікір жойылды';

  @override
  String get guideDashboardTitle => 'Гид кабинеті';

  @override
  String get guideDashboardReviewsTitle => 'Пікірлер';

  @override
  String get guideDashboardExcursionReviewsTab => 'Экскурсиялар';

  @override
  String get guideDashboardDirectGuideReviewsTab => 'Гид';

  @override
  String get guideDashboardOffersStat => 'Барлық ұсыныс';

  @override
  String get guideDashboardBookingsStat => 'Брондар';

  @override
  String get guideDashboardRevenueStat => 'Түсім';

  @override
  String get guideDashboardRatingStat => 'Рейтинг';

  @override
  String get guideDashboardSearchHint =>
      'Ұсыныс, қонақ, қала және күн бойынша іздеу';

  @override
  String get guideDashboardOffersTab => 'Ұсыныстар';

  @override
  String get guideDashboardBookingsTab => 'Брондалған';

  @override
  String get guideDashboardCompletedTab => 'Өткізілген';

  @override
  String get guideDashboardActiveTab => 'Белсенді';

  @override
  String get guideDashboardDraftTab => 'Черновиктер';

  @override
  String get guideDashboardArchiveTab => 'Архив';

  @override
  String get guideDashboardReviewTab => 'Тексеру';

  @override
  String get guideDashboardRejectedTab => 'Қабылданбады';

  @override
  String get guideDashboardCancelledTab => 'Бас тартылды';

  @override
  String get guideDashboardLoadFailed => 'Гид кабинетін жүктеу мүмкін болмады';

  @override
  String get guideDashboardOffersEmpty => 'Әзірге белсенді ұсыныстар жоқ';

  @override
  String get guideDashboardOffersEmptyHint =>
      'Саяхатшылар брондай алуы үшін алғашқы экскурсия ұсынысын жариялаңыз.';

  @override
  String get guideDashboardBookingsEmpty => 'Жақын брондар жоқ';

  @override
  String get guideDashboardBookingsEmptyHint =>
      'Клиенттердің жаңа брондары күні, қонақ саны және сомасымен осында шығады.';

  @override
  String get guideDashboardCompletedEmpty => 'Әзірге өткізілген экскурсия жоқ';

  @override
  String get guideDashboardCompletedEmptyHint =>
      'Аяқталған экскурсиялар жоспарланған күнінен кейін осында көшеді.';

  @override
  String get guideDashboardDraftEmpty => 'Черновик ұсыныстар жоқ';

  @override
  String get guideDashboardDraftEmptyHint =>
      'Сақталған черновиктер тексеруге жіберілгенге дейін жеке болып қалады.';

  @override
  String get guideDashboardReviewEmpty => 'Тексеруде ештеңе жоқ';

  @override
  String get guideDashboardReviewEmptyHint =>
      'Модерацияны немесе жариялауды күтіп тұрған ұсыныстар осында шығады.';

  @override
  String get guideDashboardDirectGuideReviewsEmpty =>
      'Сіз туралы тікелей пікірлер саяхатшылар бөлек бағалағаннан кейін осында шығады.';

  @override
  String get guideDashboardArchiveEmpty => 'Архив әзірге бос';

  @override
  String get guideDashboardArchiveEmptyHint =>
      'Уақытша өзекті емес ұсыныстарды белсенді тізімнен алып, кейін өңдеп қайта жариялау үшін архивке жіберіңіз.';

  @override
  String get guideDashboardRejectedEmpty => 'Қабылданбаған ұсыныстар жоқ';

  @override
  String get guideDashboardRejectedEmptyHint =>
      'Модерациядан өтпеген ұсыныстар түзетуге қолжетімді болып осында шығады.';

  @override
  String get guideDashboardCancelledEmpty => 'Бас тартылған брондар жоқ';

  @override
  String get guideDashboardCancelledEmptyHint =>
      'Клиент бас тартқан брондар тарих пен байланыс үшін осында сақталады.';

  @override
  String get guideDashboardCreateOffer => 'Ұсыныс жасау';

  @override
  String get guideDashboardEditOffer => 'Өңдеу';

  @override
  String get guideDashboardArchiveOffer => 'Архивке';

  @override
  String get guideDashboardPublishOffer => 'Жариялау';

  @override
  String get guideDashboardSubmitOffer => 'Тексеруге жіберу';

  @override
  String get guideDashboardDeleteDraftOffer => 'Черновикті жою';

  @override
  String get guideDashboardDeleteDraftTitle => 'Черновикті жою керек пе?';

  @override
  String get guideDashboardDeleteDraftMessage =>
      'Бұл черновик толық жойылады және оны қалпына келтіру мүмкін болмайды.';

  @override
  String get guideDashboardDeleteDraftConfirm => 'Черновикті жою';

  @override
  String get guideDashboardDeleteDraftSuccess => 'Черновик жойылды';

  @override
  String get guideDashboardDeleteDraftFailed => 'Черновикті жою мүмкін болмады';

  @override
  String get guideDashboardArchiveFailed =>
      'Ұсынысты архивке жіберу мүмкін болмады';

  @override
  String get guideDashboardPublishFailed => 'Ұсынысты жариялау мүмкін болмады';

  @override
  String get guideDashboardSubmitFailed =>
      'Ұсынысты тексеруге жіберу мүмкін болмады';

  @override
  String get guideDashboardViewBooking => 'Бронды ашу';

  @override
  String get guideDashboardShowAttendanceQr => 'Белгілеу QR-ы';

  @override
  String get guideDashboardAttendanceParticipants => 'Қатысушылар';

  @override
  String get guideDashboardAttendanceCheckedIn => 'Белгіленді';

  @override
  String get guideDashboardAttendanceWaiting => 'Белгілеуді күтуде';

  @override
  String get guideDashboardViewDetails => 'Толығырақ';

  @override
  String get guideDashboardCancelExcursion => 'Экскурсиядан бас тарту';

  @override
  String get guideDashboardCancelTitle => 'Экскурсиядан бас тартасыз ба?';

  @override
  String get guideDashboardCancelDescription =>
      'Бұл слот қонақтар үшін тоқтатылады және әсер еткен брондар бойынша қайтарылатын сома көрсетіледі.';

  @override
  String get guideDashboardCancelReasonLabel => 'Бас тарту себебі';

  @override
  String get guideDashboardCancelReasonPlaceholder =>
      'Мысалы: гид ауырып қалды немесе ауа райы маршрутты өткізуге мүмкіндік бермейді';

  @override
  String get guideDashboardCancelReasonRequired =>
      'Бас тарту себебін көрсетіңіз';

  @override
  String get guideDashboardCancelConfirm => 'Бас тартуды растау';

  @override
  String get guideDashboardCancelSuccess => 'Экскурсия тоқтатылды';

  @override
  String get guideDashboardCancelFailed =>
      'Экскурсиядан бас тарту мүмкін болмады';

  @override
  String get guideDashboardCancelNoSlot =>
      'Бұл бронда бас тартатын кесте слоты жоқ';

  @override
  String guideDashboardRefundAmount(Object amount) {
    return 'Қонақтарға қайтару: $amount';
  }

  @override
  String get guideDashboardCancelledByTourist => 'Турист болдырмады';

  @override
  String get guideDashboardCancelledByGuide => 'Гид болдырмады';

  @override
  String guideDashboardCancellationReason(Object reason) {
    return 'Себебі: $reason';
  }

  @override
  String get guideDashboardBookingSheetTitle => 'Брон туралы ақпарат';

  @override
  String get guideDashboardBookingAuthorsTitle => 'Брон авторлары';

  @override
  String get guideDashboardAdults => 'Ересектер';

  @override
  String get guideDashboardChildren => 'Балалар';

  @override
  String get guideDashboardTotalGuests => 'Барлық қонақ';

  @override
  String guideDashboardGuestBreakdown(
    Object adults,
    Object children,
    Object total,
  ) {
    return 'Ересектер: $adults · Балалар: $children · Барлығы: $total';
  }

  @override
  String get guideDashboardStatusActive => 'Белсенді';

  @override
  String get guideDashboardStatusDraft => 'Черновик';

  @override
  String get guideDashboardStatusArchived => 'Архив';

  @override
  String get guideDashboardStatusReview => 'Тексеруде';

  @override
  String get guideDashboardStatusRejected => 'Қабылданбады';

  @override
  String get guideDashboardStatusBooked => 'Брон';

  @override
  String get guideDashboardStatusCompleted => 'Өткізілді';

  @override
  String get guideDashboardStatusCancelled => 'Бас тартылды';

  @override
  String get guideDashboardFlexibleGroup => 'Икемді топ';

  @override
  String guideDashboardMaxGuests(Object count) {
    return '$count қонаққа дейін';
  }

  @override
  String guideDashboardBookingCount(Object count) {
    return '$count брон';
  }

  @override
  String get excursionReviewsTitle => 'Экскурсиядан кейінгі пікірлер';

  @override
  String get excursionReviewsEmpty => 'Бұл экскурсия бойынша пікірлер әлі жоқ';

  @override
  String excursionReviewViaGuide(Object guide) {
    return 'Гид арқылы: $guide';
  }

  @override
  String get excursionReviewSourceAttractionBadge =>
      'Пікір барған экскурсия негізінде';

  @override
  String get activityReviewsSectionTitle => 'Пікірлер';

  @override
  String get activityReviewsTitle => 'Белсенділік пікірлері';

  @override
  String get activityOrganizerReviewsTitle => 'Ұйымдастырушы пікірлері';

  @override
  String get activityReviewsEmpty => 'Бұл белсенділік бойынша пікірлер әлі жоқ';

  @override
  String get activityReviewsLoadFailed =>
      'Белсенділік пікірлерін жүктеу мүмкін болмады';

  @override
  String get activityReviewSheetTitle => 'Белсенділікті бағалаңыз';

  @override
  String get activityReviewActivityLabel => 'Белсенділік';

  @override
  String get activityReviewOrganizerLabel => 'Ұйымдастырушы';

  @override
  String get activityReviewWriteButton => 'Пікір қалдыру';

  @override
  String get activityReviewEditButton => 'Пікірді өзгерту';

  @override
  String get activityReviewUnavailable =>
      'Пікірлер белсенділік аяқталғаннан кейін тек келгені белгіленген қатысушыларға қолжетімді.';

  @override
  String get activityReviewSaved => 'Пікір сақталды';

  @override
  String get activityReviewSaveFailed => 'Пікірді сақтау мүмкін болмады';

  @override
  String get activityReviewPublishConfirmTitle => 'Пікірді жариялау керек пе?';

  @override
  String get activityReviewPublishConfirmDescription =>
      'Жарияланғаннан кейін белсенділік пен ұйымдастырушыға берген бағаларыңыз пікірлерде көрінеді.';

  @override
  String get activityReviewPublishConfirmButton => 'Жариялау';

  @override
  String get activityPerPerson => '/ адам';

  @override
  String activitySpotsLeft(Object count) {
    return '$count орын қалды';
  }

  @override
  String get activityUnlimitedSpots => 'Шектеусіз';

  @override
  String get activityMeetingPoint => 'Кездесу орны';

  @override
  String get activityGetDirections => 'Жол көрсету';

  @override
  String get activityHostSection => 'Ұйымдастырушы';

  @override
  String get activityTotalCapacity => 'Жалпы орын';

  @override
  String get activityPricing => 'Құны';

  @override
  String activityPeopleMax(Object count) {
    return 'Макс. $count адам';
  }

  @override
  String get activityJoinActivity => 'Жазылу';

  @override
  String get activitiesSearchHint =>
      'Белсенділіктер, ұйымдастырушылар, қалалар іздеу';

  @override
  String get activitiesFiltersTitle => 'Сүзгілер';

  @override
  String get activitiesFilterCountrySection => 'Ел';

  @override
  String get activitiesFilterCountryAll => 'Барлық елдер';

  @override
  String get activitiesFilterCountrySearchHint =>
      'Ел, код немесе телефон бойынша іздеу';

  @override
  String get activitiesFilterCountryNoResults => 'Ел табылмады';

  @override
  String get activitiesSortLabel => 'Сұрыптау';

  @override
  String get activitiesSortDate => 'Күні';

  @override
  String get activitiesSortPrice => 'Бағасы';

  @override
  String get activitiesFilterCategory => 'Санат';

  @override
  String get activitiesFilterDate => 'Күні';

  @override
  String get activitiesFilterStartDatePlaceholder => '15.05.2026';

  @override
  String get activitiesFilterEndDatePlaceholder => '22.05.2026';

  @override
  String get activitiesFilterPricing => 'Құны';

  @override
  String get activitiesFilterVisibility => 'Көрінуі';

  @override
  String get activitiesDiscoverTitle => 'Белсенділіктер';

  @override
  String get activitiesNearbyTitle => 'Жақын белсенділіктер';

  @override
  String get activitiesNearbyMapEmpty =>
      'Белсенділіктерде әзірге кездесу нүктелері жоқ';

  @override
  String get activitiesFilteredEmptyTitle =>
      'Бұл сүзгілерге сай белсенділік табылмады';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Санатты, күн аралығын, баға шегін кеңейтіп немесе басқа қаланы таңдаңыз';

  @override
  String activitiesResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count белсенділік',
      one: '1 белсенділік',
      zero: 'Белсенділік жоқ',
    );
    return '$_temp0';
  }

  @override
  String get activitiesFiltersCategoriesTitle => 'Санаттар';

  @override
  String get activitiesFiltersSelectedCategories => 'Таңдалған санаттар';

  @override
  String activitiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count белсенділікті',
      one: '1 белсенділікті',
      zero: '0 белсенділікті',
    );
    return '$_temp0 көрсету';
  }

  @override
  String get activitiesAllCategories => 'Барлық санат';

  @override
  String get activitiesFiltersPriceRangeTitle => 'Баға ауқымы';

  @override
  String get activitiesFiltersVisibilityTitle => 'Көрінуі';

  @override
  String get activitiesFilterMinPrice => 'Ең төмен баға';

  @override
  String get activitiesFilterMaxPrice => 'Ең жоғары баға';

  @override
  String get activitiesDatePresetToday => 'Бүгін';

  @override
  String get activitiesDatePresetTomorrow => 'Ертең';

  @override
  String get activitiesDatePresetThisWeekend => 'Осы демалыста';

  @override
  String get activitiesDatePresetThisWeek => 'Осы аптада';

  @override
  String get activitiesDatePresetThisMonth => 'Осы айда';

  @override
  String get activityViewDetails => 'Толығырақ';

  @override
  String get activityJoinSession => 'Қосылу';

  @override
  String get activityGetLink => 'Сілтемені алу';

  @override
  String get activityAttendanceQrButton => 'Белгілеу QR-ы';

  @override
  String get activityAttendanceQrTitle => 'Белсенділік QR-ы';

  @override
  String get activityAttendanceQrFallbackTitle => 'Белсенділік';

  @override
  String get activityAttendanceQrSubtitle =>
      'Қатысушы қолданба арқылы келгенін растауы үшін осы QR-ды көрсетіңіз.';

  @override
  String get activityAttendanceQrHelper =>
      'QR автоматты түрде жаңарады. Қатысушы төменгі панельдегі QR батырмасы арқылы өзекті кодты сканерлеуі керек.';

  @override
  String get activityAttendanceQrLoadFailed =>
      'Белсенділік QR-ын жүктеу мүмкін болмады';

  @override
  String get activityAttendanceQrRefreshHint =>
      'Код қайталанулар мен скриншоттарды азайту үшін автоматты түрде жаңарады.';

  @override
  String get activityAttendanceQrRefreshing => 'QR жаңартылып жатыр…';

  @override
  String activityAttendanceQrExpiresIn(Object seconds) {
    return '$seconds сек. кейін жаңарады';
  }

  @override
  String get qrScannerTitle => 'QR сканерлеу';

  @override
  String get qrScannerSubtitle =>
      'Белсенділікке келгеніңізді растау үшін камераны ұйымдастырушының QR кодының үстіне апарыңыз.';

  @override
  String get qrScannerReady => 'Камераны QR кодқа бағыттаңыз';

  @override
  String get qrScannerInvalidCode => 'Бұл Inflap белсенділігінің QR коды емес';

  @override
  String get qrScannerSessionUnavailable =>
      'Ағымдағы сессияны анықтау мүмкін болмады. Экранды қайта ашып көріңіз.';

  @override
  String get qrScannerAlreadyQueued => 'Бұл белгілеу синхрондауды күтіп тұр';

  @override
  String get qrScannerQueuedOffline =>
      'Белгілеу сақталды. Байланыс пайда болғанда синхрондалады.';

  @override
  String get qrScannerSuccess => 'Келу расталды';

  @override
  String get qrScannerAlreadyCheckedIn =>
      'Сіз бұл белсенділікке әлдеқашан белгілендіңіз';

  @override
  String get qrScannerNotRegistered =>
      'Сіз бұл белсенділіктің қатысушысы емессіз';

  @override
  String get qrScannerNotEligible =>
      'Бұл жазба үшін белгілеу әзірге қолжетімсіз';

  @override
  String get qrScannerQrExpired =>
      'Бұл QR ескірген. Ұйымдастырушыдан жаңасын ашуын сұраңыз.';

  @override
  String get qrScannerHostNotAllowed =>
      'Ұйымдастырушы өзінің QR кодын сканерлей алмайды';

  @override
  String get qrScannerActivityUnavailable =>
      'Бұл белсенділік үшін белгілеу қазір қолжетімсіз';

  @override
  String get qrScannerCameraUnavailable =>
      'Камера қолжетімсіз. Камера рұқсатын тексеріп, қайта көріңіз.';

  @override
  String get qrScannerSyncNow => 'Синхрондау';

  @override
  String get qrScannerScanAgain => 'Қайта сканерлеу';

  @override
  String qrScannerPendingCount(Object count) {
    return 'Синхрондауды күтіп тұрғаны: $count';
  }

  @override
  String get qrScannerNoPending => 'Күтіп тұрған белгілеулер жоқ';

  @override
  String get retry => 'Қайталау';

  @override
  String get backButtonLabel => 'Артқа';

  @override
  String get storiesDiscoverTitle => 'Посттар';

  @override
  String get storiesNavLabel => 'Посттар';

  @override
  String get storiesActivitiesNavLabel => 'Белсенділіктер';

  @override
  String get storySearchHint => 'Посттарды, авторларды немесе орындарды іздеу';

  @override
  String get storySearchCompactHint => 'Посттарды іздеу';

  @override
  String get storyFiltersTitle => 'Сүзгілер';

  @override
  String get storyFiltersActiveSummary => 'Таңдалған сүзгілер';

  @override
  String get storyFilterFormat => 'Материал түрі';

  @override
  String get storyFilterCategory => 'Тақырып';

  @override
  String get storyFilterCountry => 'Ел';

  @override
  String get storyFilterCountryAll => 'Барлық елдер';

  @override
  String get storyFilterCountrySearchHint =>
      'Ел, код немесе телефон бойынша іздеу';

  @override
  String get storyFilterCountryNoResults => 'Ел табылмады';

  @override
  String get storyFilterAll => 'Барлығы';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count постты',
      one: '1 постты',
      zero: '0 постты',
    );
    return '$_temp0 көрсету';
  }

  @override
  String get storySortLabel => 'Сұрыптау';

  @override
  String get storySortDate => 'Күні';

  @override
  String get storySortViews => 'Қаралымдар';

  @override
  String get storySortComments => 'Пікірлер';

  @override
  String get storyCreateCta => 'Пост жасау';

  @override
  String get storyCreateFirst => 'Алғашқы постты жасау';

  @override
  String get storyEmptyTitle => 'Әзірге пост жоқ';

  @override
  String get storyEmptySubtitle =>
      'Travel-note, жергілікті гид немесе визуалды эссе жариялаған алғашқы адам болыңыз.';

  @override
  String get storyEmptyAuthenticatedSubtitle =>
      'Лентаны бастау үшін пост, мақала, гид немесе визуалды эссе жасаңыз.';

  @override
  String get storyFilteredEmptyTitle => 'Бұл сүзгілер бойынша пост жоқ';

  @override
  String get storyFilteredEmptySubtitle =>
      'Басқа іздеу, ел, қала немесе санатты қолданып көріңіз.';

  @override
  String get storyResetFiltersAction => 'Тазалау';

  @override
  String get storyLoginCreateAction => 'Кіріп, жасау';

  @override
  String get myStoriesDraftsTab => 'Нобайлар';

  @override
  String get myStoriesPendingReviewTab => 'Тексерілуде';

  @override
  String get myStoriesPublishedTab => 'Жарияланған';

  @override
  String get myStoriesArchivedTab => 'Архив';

  @override
  String get myStoriesDraftEmptyTitle => 'Әзірге нобай жоқ';

  @override
  String get myStoriesDraftEmptySubtitle =>
      'Идеяларды посттар лентасына жарияламас бұрын нобай ретінде сақтаңыз.';

  @override
  String get myStoriesPendingReviewEmptyTitle => 'Тексерілудегі посттар жоқ';

  @override
  String get myStoriesPendingReviewEmptySubtitle =>
      'Модератор тексеруін күтіп тұрған посттар осы жерде көрсетіледі.';

  @override
  String get myStoriesPublishedEmptyTitle => 'Әзірге жарияланған пост жоқ';

  @override
  String get myStoriesPublishedEmptySubtitle =>
      'Жарияланған посттар, гидтер, мақалалар және визуалды эсселер осы жерде көрсетіледі.';

  @override
  String get myStoriesArchivedEmptyTitle => 'Әзірге архивтегі пост жоқ';

  @override
  String get myStoriesArchivedEmptySubtitle =>
      'Архивтегі посттар тарих және қайта пайдалану үшін осы жерде сақталады.';

  @override
  String get myStoriesCreateDraftAction => 'Нобай жасау';

  @override
  String get storyArchiveActiveTab => 'Белсенді';

  @override
  String get storyArchiveArchiveTab => 'Архив';

  @override
  String get storyArchiveActiveSubtitle =>
      'Мұнда басқа пайдаланушыларға әлі көрінетін хикаяларыңыз сақталады.';

  @override
  String get storyArchiveActiveEmptyTitle => 'Әзірге белсенді хикая жоқ';

  @override
  String get storyArchiveActiveEmptySubtitle =>
      'Хикая 24 сағат осы жерде тұруы үшін фото немесе видео түсіріңіз.';

  @override
  String get storyArchiveActiveUntilPrefix => 'Белсенді';

  @override
  String get storyArchiveSubtitle =>
      'Хикаялар 24 сағат өмір сүреді, содан кейін осында тек сіз үшін сақталады.';

  @override
  String get storyArchiveEmptyTitle => 'Әзірге архивтегі хикая жоқ';

  @override
  String get storyArchiveEmptySubtitle =>
      'Камерамен түсірген хикаяларыңыз жарияланғаннан кейін 24 сағаттан соң осы жерде көрсетіледі.';

  @override
  String get storyArchiveLoadFailedTitle => 'Хикаяларды жүктеу мүмкін болмады';

  @override
  String get storyArchiveLoadFailedMessage =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get storyArchiveRetryAction => 'Қайталап көру';

  @override
  String get storyArchiveLoadMoreAction => 'Тағы жүктеу';

  @override
  String get storyArchiveExpiredPrefix => 'Архивке өтті';

  @override
  String get storyStateSeenLabel => 'Көрілді';

  @override
  String get storyStateExpiredLabel => 'Мерзімі өтті';

  @override
  String get storyStatePendingLabel => 'Тексерілуде';

  @override
  String get storyStateHiddenLabel => 'Жасырылды';

  @override
  String get storyLoadFailed => 'Посттарды жүктеу мүмкін болмады';

  @override
  String get storyViewsSuffix => 'қаралым';

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
  String get storyFormatArticle => 'Мақала';

  @override
  String get storyFormatCulinary => 'Гастрономия';

  @override
  String get storyDetailsTitle => 'Пост туралы';

  @override
  String get storyLinkCopied => 'Пост сілтемесі көшірілді';

  @override
  String get storyShareFailed =>
      'Сілтемені бөлісу терезесін ашу мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyReportAction => 'Шағымдану';

  @override
  String get storyReportSending => 'Жіберілуде...';

  @override
  String get storyReportTitle => 'Постқа шағымдану';

  @override
  String get storyReportSubtitle =>
      'Мәселені сипаттаңыз. Шағымдар модераторларға travel-контентті қауіпсіз әрі пайдалы ұстауға көмектеседі.';

  @override
  String get storyReportDetailsLabel => 'Толығырақ';

  @override
  String get storyReportDetailsHint => 'Модераторларға контекст қосыңыз';

  @override
  String get storyReportSubmitAction => 'Шағым жіберу';

  @override
  String get storyReportSubmitted => 'Рақмет. Пост модерацияға жіберілді.';

  @override
  String get storyReportAutoHidden =>
      'Рақмет. Пост модераторлар тексергенше жасырылды.';

  @override
  String get storyReportReasonSpam => 'Спам немесе жаңылыстыру';

  @override
  String get storyReportReasonHarassment => 'Қорлау немесе қудалау';

  @override
  String get storyReportReasonHate => 'Өшпенділік немесе кемсіту';

  @override
  String get storyReportReasonSexualContent => 'Сексуалдық контент';

  @override
  String get storyReportReasonViolence => 'Зорлық немесе шок контент';

  @override
  String get storyReportReasonMisinformation => 'Жалған ақпарат';

  @override
  String get storyReportReasonIllegal => 'Заңсыз әрекет';

  @override
  String get storyReportReasonOther => 'Басқа';

  @override
  String get storyAuthorLabel => 'Автор';

  @override
  String get storyFollowAction => 'Жазылу';

  @override
  String get storyFollowingAction => 'Жазылған';

  @override
  String get storyStatViews => 'Қаралым';

  @override
  String get storyStatLikes => 'Лайк';

  @override
  String get storyStatComments => 'Пікір';

  @override
  String get storyStatShares => 'Бөлісу';

  @override
  String get storyTagsLabel => 'Тегтер';

  @override
  String get storyCommentHint => 'Пікір қалдырыңыз';

  @override
  String get storyCommentsTitle => 'Пікірлер';

  @override
  String get storyCommentsEmpty =>
      'Әзірге пікір жоқ. Алғашқы болып пікір жазыңыз.';

  @override
  String get storyCommentRateLimit =>
      '3 сағат ішінде тек бір пікір ғана қалдыруға болады.';

  @override
  String storyCommentCooldownUntil(Object time) {
    return 'Келесі пікірді $time кейін қалдыруға болады.';
  }

  @override
  String get storyCommentLinkCopied => 'Пікірге сілтеме көшірілді';

  @override
  String get storyCommentShareFailed =>
      'Пікірді бөлісу терезесін ашу мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyLikeActionFailed =>
      'Лайкты жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyCommentEditingTitle => 'Пікірді өңдеу';

  @override
  String get storyCommentSaveAction => 'Сақтау';

  @override
  String get storyCommentShareAction => 'Бөлісу';

  @override
  String get storyDeleteCommentTitle => 'Пікірді өшіру керек пе?';

  @override
  String get storyDeleteCommentMessage => 'Пікір қайтарымсыз өшіріледі.';

  @override
  String get storyDeleteCommentAction => 'Өшіру';

  @override
  String get storyRelatedEyebrow => 'Әрі қарай зерттеңіз';

  @override
  String get storyRelatedTitle => 'Ұқсас посттар';

  @override
  String get storyRelatedEmpty => 'Әзірге ұқсас пост жоқ';

  @override
  String get storyViewAll => 'Барлығын көру';

  @override
  String get storyEditAction => 'Өңдеу';

  @override
  String get storyDeleteTitle => 'Постты өшіру керек пе?';

  @override
  String get storyDeleteMessage => 'Пост ашық лентадан алынып тасталады.';

  @override
  String get storyDeleteAction => 'Өшіру';

  @override
  String get storyCreateTitle => 'Жаңа хикая';

  @override
  String get storyContinueAction => 'Жалғастыру';

  @override
  String get storyUpdateAction => 'Хикаяны жаңарту';

  @override
  String get storyPublishAction => 'Хикаяны жариялау';

  @override
  String get storySaveDraftAction => 'Қаралымға сақтау';

  @override
  String get storySaveFailed => 'Хикаяны сақтау мүмкін болмады';

  @override
  String get storyCoverUploadTitle => 'Мұқаба жүктеңіз';

  @override
  String get storyCoverUploadSubtitle =>
      'Сапалы көлденең форматтағы сурет қолданған дұрыс';

  @override
  String get storyCoverRequired => 'Мұқаба қосыңыз';

  @override
  String get storyCoverUnsupported => 'Бұл сурет форматына қолдау жоқ';

  @override
  String get storyCoverTooLarge =>
      'Мұқаба файлы тым үлкен. 20 МБ-тан аспайтын сурет таңдаңыз.';

  @override
  String get storyCoverUploadFailed => 'Мұқабаны жүктеу мүмкін болмады';

  @override
  String get storyTitleLabel => 'Хикая атауы';

  @override
  String get storyTitleHint => 'Мысалы: Пирстегі кешкі йога';

  @override
  String get storyTitleRequired => 'Хикая атауын енгізіңіз';

  @override
  String storyTitleTooLong(Object count) {
    return 'Атау $count таңбадан аспауы керек';
  }

  @override
  String get storyPlacePrompt => 'Бұл хикая қай жерде өтті?';

  @override
  String get storyPlaceHint => 'Қала немесе елді енгізіңіз';

  @override
  String get storyCountryHint => 'Елді іздеу';

  @override
  String get storyCityHint => 'Қаланы іздеу';

  @override
  String get storyTagsFieldLabel => 'Тегтер';

  @override
  String get storyTagHint => 'Тег қосу';

  @override
  String get storyTagsLimit => 'Ең көбі 8 тег қосуға болады';

  @override
  String get storyCategoryLabel => 'Санатты таңдаңыз';

  @override
  String get storyCategoryRequired => 'Хикая санатын таңдаңыз';

  @override
  String get storyContentHint => 'Әңгімеңізді осы жерден бастаңыз...';

  @override
  String get storyContinueSectionHint => 'Хикаяны осы жерден жалғастырыңыз...';

  @override
  String get storyContentRequired => 'Хикая мәтінін жазыңыз';

  @override
  String storyContentTooLong(Object count) {
    return 'Хикая мәтіні $count таңбадан аспауы керек';
  }

  @override
  String get storyCharacterCountLabel => 'Таңба саны';

  @override
  String get storyInlineImageAddAction => 'Фото қосу';

  @override
  String get storyInlineImageHint =>
      'Суреттер хикая абзацтарының арасында көрсетіледі.';

  @override
  String get storyContinueSectionLabel =>
      'Мәтінді төменде жалғастыруға немесе тағы фото қосуға болады.';

  @override
  String get storyInlineImageUnsupported =>
      'Бұл сурет форматына хикая мәтіні үшін қолдау жоқ.';

  @override
  String get storyInlineImageTooLarge =>
      'Сурет тым үлкен. 20 МБ-қа дейінгі файл таңдаңыз.';

  @override
  String get storyInlineImageUploadFailed =>
      'Суретті хикаяға жүктеу мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyAiHintUnavailable => 'AI мәтін кеңестері әзірге қолжетімсіз';

  @override
  String get storyWritersNoteTitle => 'Авторға кеңес';

  @override
  String get storyWritersNoteBody =>
      'Әңгімеңізді сезімдік детальдан бастаңыз. «Мен Токиоға келдім» деудің орнына, Сибуяның дымқыл асфальтында шағылысқан неон жарығын суреттеңіз.';

  @override
  String get storyEditorTitle => 'Хикая редакторы';

  @override
  String get storyEditorQuickPostTitle => 'Жылдам пост';

  @override
  String get storyEditorQuickPostSubtitle =>
      'Қауымдастықпен қысқа жаңалық, сұрақ немесе жергілікті кеңес бөлісіңіз.';

  @override
  String get storyEditorQuickPostHint => 'Не бөліскіңіз келеді?';

  @override
  String get storyEditorLoading => 'Хикая жүктелуде';

  @override
  String get storyEditorLoadFailed =>
      'Хикаяны өңдеу үшін жүктеу мүмкін болмады.';

  @override
  String get storyEditorEditMode => 'Өңдеу';

  @override
  String get storyEditorPreviewMode => 'Алдын ала көру';

  @override
  String get storyEditorRecoveryTitle =>
      'Сақталмаған нобайды қалпына келтіру керек пе?';

  @override
  String get storyEditorRecoveryMessage =>
      'Бұл хикая үшін жергілікті қалпына келтіру көшірмесі бар.';

  @override
  String get storyEditorRecoveryDiscard => 'Бас тарту';

  @override
  String get storyEditorRecoveryRestore => 'Қалпына келтіру';

  @override
  String get storyEditorDiscardChangesTitle =>
      'Хикая өзгерістерінен бас тарту керек пе?';

  @override
  String get storyEditorDiscardChangesMessage =>
      'Сақталмаған түзетулер жоғалуы мүмкін.';

  @override
  String get storyEditorKeepEditing => 'Өңдеуді жалғастыру';

  @override
  String get storyEditorMetadataTitle => 'Жариялау баптаулары';

  @override
  String get storyEditorTitleFieldHint => 'Іздеуге ыңғайлы нақты атау';

  @override
  String get storyEditorTemplateAction => 'Үлгілер';

  @override
  String get storyEditorTemplateSemantic => 'Хикая үлгісін таңдау';

  @override
  String get storyEditorTemplatePlaceholder => 'Үлгіні таңдаңыз';

  @override
  String get storyEditorTemplateWeekendGuide => 'Демалыс күнгі гид';

  @override
  String get storyEditorTemplatePhotoEssay => 'Фотоэссе';

  @override
  String get storyEditorTemplateFoodNotes => 'Тағам жазбалары';

  @override
  String get storyEditorTemplateCityWalk => 'Қала серуені';

  @override
  String get storyEditorTemplateHiddenGems => 'Жасырын орындар';

  @override
  String get storyEditorTemplatePracticalTips => 'Практикалық кеңестер';

  @override
  String get storyEditorTemplateCultureRoute => 'Мәдени маршрут';

  @override
  String get storyEditorTemplateWeekendHeading => 'Демалыс күн жоспары';

  @override
  String get storyEditorTemplateWeekendList =>
      'Таңғы аялдама\nЖергілікті тағам\nКешкі көрініс';

  @override
  String get storyEditorTemplatePhotoHeading => 'Фото хикая';

  @override
  String get storyEditorTemplateFoodHeading => 'Қайда тамақтану керек';

  @override
  String get storyEditorTemplateFoodParagraph =>
      'Тағамды, баға деңгейін және баруға қолайлы уақытты сипаттаңыз.';

  @override
  String get storyEditorTemplateCityWalkHeading => 'Серуен маршруты';

  @override
  String get storyEditorTemplateCityWalkList =>
      'Бастау нүктесі\nНегізгі көше\nДемалатын орын\nСоңғы көрініс';

  @override
  String get storyEditorTemplateCityWalkParagraph =>
      'Қашықтықты, шамамен уақытты және бастау нүктесіне жетудің ең ыңғайлы жолын қосыңыз.';

  @override
  String get storyEditorTemplateHiddenGemsHeading =>
      'Көп адам біле бермейтін орындар';

  @override
  String get storyEditorTemplateHiddenGemsList =>
      'Неге тоқтауға тұрарлық\nҚашан тынышырақ\nЖақын жерде не көруге болады';

  @override
  String get storyEditorTemplateHiddenGemsCallout =>
      'Кіру, кесте, қауіпсіздік, қолма-қол ақша немесе брондау туралы маңызды мәлімет қосыңыз.';

  @override
  String get storyEditorTemplatePracticalTipsHeading =>
      'Сапар алдында білген пайдалы';

  @override
  String get storyEditorTemplatePracticalTipsList =>
      'Қашан бару\nҚалай жету\nҚанша бюджет жоспарлау\nӨзіңізбен не алу';

  @override
  String get storyEditorTemplatePracticalTipsCallout =>
      'Уақыт үнемдейтін немесе жиі кездесетін қателіктен сақтайтын нақты кеңес қосыңыз.';

  @override
  String get storyEditorTemplateCultureRouteHeading => 'Мәдени маршрут';

  @override
  String get storyEditorTemplateCultureRouteParagraph =>
      'Бұл жерді түсінуге көмектесетін дәстүрлер, ғимараттар, музейлер немесе жергілікті оқиғалар туралы жазыңыз.';

  @override
  String get storyEditorTemplateCultureRouteQuote =>
      'Маршруттың көңіл күйін беретін қысқа фраза, бақылау немесе факт қосыңыз.';

  @override
  String get storyEditorTemplateConflictTitle =>
      'Жаңа құрылымды қолдану керек пе?';

  @override
  String storyEditorTemplateConflictMessage(Object format, Object category) {
    return 'Бұл құрылым $format / $category ұсынады. Нобайды жоғалтпай қалай қолданатынын таңдаңыз.';
  }

  @override
  String get storyEditorTemplateConflictReplace => 'Үлгіні ауыстыру';

  @override
  String get storyEditorTemplateConflictReplaceDescription =>
      'Өзгертілмеген үлгі блоктарын өшіріп, мәтініңізді сақтап, жаңа құрылымды қосамыз.';

  @override
  String get storyEditorTemplateConflictAppend => 'Қазіргі хикаяға қосу';

  @override
  String get storyEditorTemplateConflictAppendDescription =>
      'Барлық ағымдағы мазмұнды сақтап, жаңа құрылымды төменге қосамыз.';

  @override
  String get storyEditorTemplateConflictMetadataOnly =>
      'Түрі мен тақырыбын жаңарту';

  @override
  String get storyEditorTemplateConflictMetadataOnlyDescription =>
      'Блоктарды өзгертпей, тек материал түрі мен тақырыбын өзгертеміз.';

  @override
  String get storyEditorFormatLabel => 'Материал түрі';

  @override
  String get storyEditorPlaceLabel => 'Орын';

  @override
  String get storyEditorCountryCodeLabel => 'Ел коды';

  @override
  String get storyEditorCountryCodeHint => 'KZ';

  @override
  String get storyEditorCityPlaceIdLabel => 'Қала/орын ID';

  @override
  String get storyEditorTagsHint => 'тау, тағам, демалыс';

  @override
  String get storyEditorCoverSelected => 'Мұқаба таңдалды';

  @override
  String get storyEditorCoverRequired => 'Мұқаба қажет';

  @override
  String get storyEditorReplaceCover => 'Мұқабаны ауыстыру';

  @override
  String get storyEditorAddCover => 'Мұқаба қосу';

  @override
  String get storyEditorClear => 'Тазалау';

  @override
  String get storyEditorToolbarAddBlock => 'Блок қосу';

  @override
  String get storyEditorToolbarHeading => 'Тақырып';

  @override
  String get storyEditorToolbarBold => 'Қалың';

  @override
  String get storyEditorToolbarItalic => 'Курсив';

  @override
  String get storyEditorToolbarStrikethrough => 'Сызылған';

  @override
  String get storyEditorToolbarUnderline => 'Асты сызылған';

  @override
  String get storyEditorToolbarList => 'Тізім';

  @override
  String get storyEditorToolbarQuote => 'Дәйексөз';

  @override
  String get storyEditorToolbarImage => 'Сурет';

  @override
  String get storyEditorToolbarUndo => 'Болдырмау';

  @override
  String get storyEditorToolbarRedo => 'Қайталау';

  @override
  String get storyEditorAddBlockTitle => 'Блок қосу';

  @override
  String get storyEditorBlockParagraph => 'Абзац';

  @override
  String get storyEditorBlockParagraphDescription => 'Хикаяның негізгі мәтіні';

  @override
  String get storyEditorBlockHeading => 'Тақырып';

  @override
  String get storyEditorBlockHeadingDescription => 'Бөлім атауы';

  @override
  String get storyEditorBlockList => 'Тізім';

  @override
  String get storyEditorBlockListDescription =>
      'Пайдалы кеңестер немесе қадамдар';

  @override
  String get storyEditorBlockImage => 'Сурет';

  @override
  String get storyEditorBlockImageDescription => 'Бір медиа жүктеу';

  @override
  String get storyEditorBlockGallery => 'Галерея';

  @override
  String get storyEditorBlockGalleryDescription => 'Бірнеше сурет';

  @override
  String get storyEditorBlockQuote => 'Дәйексөз';

  @override
  String get storyEditorBlockQuoteDescription => 'Ерекшеленген сөйлем';

  @override
  String get storyEditorBlockCallout => 'Ескерту';

  @override
  String get storyEditorBlockCalloutDescription => 'Маңызды саяхат жазбасы';

  @override
  String get storyEditorBlockDivider => 'Бөлгіш';

  @override
  String get storyEditorBlockDividerDescription => 'Бөлімдерді визуалды бөлу';

  @override
  String get storyEditorBlockPlaceReference => 'Орын сілтемесі';

  @override
  String get storyEditorBlockPlaceReferenceDescription =>
      'Орынды хикаямен байланыстыру';

  @override
  String get storyEditorBlockNumberedList => 'Нөмірленген тізім';

  @override
  String get storyEditorStartWithBlockTitle => 'Блоктан бастаңыз';

  @override
  String get storyEditorStartWithBlockSubtitle =>
      'Хикаяны құрастыру үшін мәтін, медиа, орындар, ескертулер немесе бөлгіштер қосыңыз.';

  @override
  String get storyEditorPlaceNameHint => 'Орын атауы';

  @override
  String get storyEditorTextHintHeading => 'Түсінікті бөлім тақырыбын жазыңыз';

  @override
  String get storyEditorTextHintBulletedList =>
      'Тізім тармақтарын әр жолға бірден қосыңыз';

  @override
  String get storyEditorTextHintNumberedList =>
      'Қадамдарды әр жолға бірден қосыңыз';

  @override
  String get storyEditorTextHintQuote =>
      'Дәйексөз немесе есте қаларлық сөйлем қосыңыз';

  @override
  String get storyEditorTextHintCallout => 'Практикалық кеңесті ерекшелеу';

  @override
  String get storyEditorTextHintParagraph => 'Хикаяңызды жазыңыз';

  @override
  String storyEditorDeleteBlockSemantic(Object block) {
    return '«$block» блогын өшіру';
  }

  @override
  String storyEditorReorderBlockSemantic(Object block) {
    return '«$block» блогының орнын өзгерту үшін сүйреңіз';
  }

  @override
  String get storyEditorPublishReadiness => 'Жариялауға дайындық';

  @override
  String get storyEditorChecklistTitle => 'Атау';

  @override
  String get storyEditorChecklistFormat => 'Материал түрі';

  @override
  String get storyEditorChecklistCategory => 'Тақырып';

  @override
  String get storyEditorChecklistCover => 'Мұқаба';

  @override
  String get storyEditorChecklistPlace => 'Орын';

  @override
  String get storyEditorChecklistCountry => 'Ел';

  @override
  String get storyEditorChecklistContent => 'Контент';

  @override
  String get storyEditorChecklistMedia => 'Медиа';

  @override
  String get storyEditorChecklistReady => 'Дайын';

  @override
  String get storyEditorChecklistNeedsAttention => 'Назар қажет';

  @override
  String get storyEditorChecklistOpen => 'Ашу';

  @override
  String get storyEditorConflictFallback => 'Хикая басқа жерде өзгертілген.';

  @override
  String get storyEditorSaveDraft => 'Нобайды сақтау';

  @override
  String get storyEditorPublish => 'Жариялау';

  @override
  String get storyEditorPublishSemantic => 'Хикаяны жариялау';

  @override
  String get storyEditorAutosaveIdle => 'Күту';

  @override
  String get storyEditorAutosaveSaving => 'Сақталуда';

  @override
  String get storyEditorAutosaveSaved => 'Сақталды';

  @override
  String get storyEditorAutosaveFailed => 'Назар қажет';

  @override
  String get storyEditorAutosaveConflict => 'Қайшылық';

  @override
  String get storyEditorPublishNotReady => 'Хикая жариялауға дайын емес.';

  @override
  String get storyEditorMediaRetrySemantic => 'Медиа жүктеуді қайталау';

  @override
  String get storyEditorMediaRemoveSemantic => 'Медиа жүктеуді өшіру';

  @override
  String get storyEditorMediaRetry => 'Қайталау';

  @override
  String get storyEditorMediaRemove => 'Өшіру';

  @override
  String get storyEditorMediaQueued => 'Жүктеу кезегінде';

  @override
  String get storyEditorMediaUploading => 'Жүктелуде';

  @override
  String get storyEditorMediaFailed => 'Жүктеу сәтсіз аяқталды';

  @override
  String get storyEditorMediaComplete => 'Жүктеу аяқталды';

  @override
  String get storyEditorMediaRemoved => 'Өшірілді';

  @override
  String get storyEditorMediaLocalPreviewUnavailable =>
      'Жергілікті алдын ала көру қолжетімсіз. Бұл медианы өшіріп, қайта қосыңыз.';

  @override
  String get storyEditorMediaErrorRetryUpload => 'Медиа жүктеуді қайталаңыз.';

  @override
  String get storyEditorMediaErrorInterrupted =>
      'Жүктеу үзілді. Жалғастыру үшін қайталаңыз.';

  @override
  String get storyEditorMediaErrorMissingSource =>
      'Жергілікті медиа көзі қолжетімсіз. Бұл медианы өшіріп, қайта қосыңыз.';

  @override
  String get storyEditorMediaErrorUploadFailed =>
      'Медианы жүктеу мүмкін болмады. Қайта көріңіз.';

  @override
  String get storyEditorImagePickTooLarge =>
      'Сурет тым үлкен. 20 МБ-қа дейінгі файлды таңдаңыз.';

  @override
  String get storyEditorImagePickUnsupported =>
      'JPG, PNG немесе WebP форматындағы суретті таңдаңыз.';

  @override
  String get storyEditorImagePickFailed =>
      'Бұл суретті ашу мүмкін болмады. Басқасын таңдаңыз.';

  @override
  String get storyEditorValidationTitleRequired => 'Хикая атауын көрсетіңіз.';

  @override
  String get storyEditorValidationFormatRequired => 'Хикая форматын таңдаңыз.';

  @override
  String get storyEditorValidationCategoryRequired => 'Хикая санатын таңдаңыз.';

  @override
  String get storyEditorValidationCoverRequired => 'Хикая мұқабасын қосыңыз.';

  @override
  String get storyEditorValidationPlaceRequired => 'Хикая орнын көрсетіңіз.';

  @override
  String get storyEditorValidationCountryRequired => 'Хикая елін таңдаңыз.';

  @override
  String get storyEditorValidationDraftRequired =>
      'Черновикті сақтау үшін тақырып немесе кемінде бір хикая блогын қосыңыз.';

  @override
  String get storyEditorValidationContentRequired =>
      'Жарияламас бұрын кемінде бір хикая блогын қосыңыз.';

  @override
  String get storyEditorValidationMediaPending =>
      'Медиа жүктеліп болғанша күтіңіз.';

  @override
  String get postCreateRateLimitTitle => 'Пост лимиті';

  @override
  String postCreateRateLimitMessage(int minutes) {
    return 'Соңғы бір сағатта ең көп пост санын жасадыңыз. Жаңа постты шамамен $minutes мин. кейін жасауға болады.';
  }

  @override
  String get postCreateRateLimitAction => 'Түсінікті';

  @override
  String get postCreatePreflightFailed =>
      'Пост лимитін тексеру мүмкін болмады. Жариялау кезінде қайта тексереміз.';

  @override
  String get chatListTitle => 'Чаттар';

  @override
  String get chatListLoadFailed => 'Чаттарды жүктеу мүмкін болмады';

  @override
  String get chatListEmpty => 'Әзірге диалог жоқ';

  @override
  String get chatListPersonalTab => 'Жеке';

  @override
  String get chatListActivitiesTab => 'Белсенділіктер';

  @override
  String get chatListExcursionsTab => 'Экскурсиялар';

  @override
  String get chatListSearchHint => 'Чаттарды іздеу';

  @override
  String get chatListSearchEmpty => 'Чаттар табылмады';

  @override
  String get chatMuteNotificationsAction => 'Хабарландыруларды өшіру';

  @override
  String get chatUnmuteNotificationsAction => 'Хабарландыруларды қосу';

  @override
  String get chatMuteUpdateFailed =>
      'Чат хабарландыруларын жаңарту мүмкін болмады';

  @override
  String get chatBlockUserAction => 'Бұғаттау';

  @override
  String get chatUnblockUserAction => 'Бұғаттан шығару';

  @override
  String get chatUserBlockUpdateFailed =>
      'Пайдаланушыны бұғаттау күйін жаңарту мүмкін болмады';

  @override
  String get chatFallbackTitle => 'Чат';

  @override
  String get chatGroupFallbackTitle => 'Топтық чат';

  @override
  String get chatActivityFallbackTitle => 'Іс-шара чаты';

  @override
  String get chatActiveNow => 'ҚАЗІР ЖЕЛІДЕ';

  @override
  String get chatPresenceOnline => 'желіде';

  @override
  String get chatPresenceOffline => 'желіде емес';

  @override
  String get chatPresenceLastSeenJustNow => 'желіде жаңа ғана болды';

  @override
  String chatPresenceLastSeenMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'желіде $count минут бұрын болды',
      one: 'желіде 1 минут бұрын болды',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'желіде $count сағат бұрын болды',
      one: 'желіде 1 сағат бұрын болды',
    );
    return '$_temp0';
  }

  @override
  String chatPresenceLastSeenDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'желіде $count күн бұрын болды',
      one: 'желіде 1 күн бұрын болды',
    );
    return '$_temp0';
  }

  @override
  String chatParticipantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қатысушы',
      zero: 'Қатысушылар жоқ',
    );
    return '$_temp0';
  }

  @override
  String get chatPinnedMessageLabel => 'БЕКІТІЛГЕН ХАБАР';

  @override
  String get chatPinAction => 'Бекіту';

  @override
  String get chatUnpinAction => 'Бекітуден алу';

  @override
  String get chatPinFailed => 'Хабарды бекіту мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatUnpinFailed =>
      'Хабарды бекітуден алу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatDateToday => 'Бүгін';

  @override
  String get chatDateYesterday => 'Кеше';

  @override
  String get chatMessageDeleted => 'Хабар өшірілді';

  @override
  String get chatMessageRemovedByModerator => 'Хабарды модератор өшірді';

  @override
  String chatModeratorComment(Object comment) {
    return 'Модератор түсіндірмесі: $comment';
  }

  @override
  String get chatDeleteAction => 'Өшіру';

  @override
  String get chatDeleteFailed => 'Хабарды өшіру мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatEditedLabel => 'өзгертілді';

  @override
  String get chatUserFallbackName => 'Пайдаланушы';

  @override
  String get chatReplyPreviewFallback => 'Хабар';

  @override
  String chatSystemUserJoined(Object name) {
    return '$name қосылды';
  }

  @override
  String chatSystemUserLeft(Object name) {
    return '$name шықты';
  }

  @override
  String get chatSystemUpdate => 'Жүйелік оқиға';

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
  String get chatAttachmentTakePhoto => 'Фото түсіру';

  @override
  String get chatAttachmentTakeVideo => 'Видео түсіру';

  @override
  String get chatAttachmentChooseFromGallery => 'Галереядан таңдау';

  @override
  String get chatAttachmentCameraTitle => 'Камера';

  @override
  String get chatAttachmentAttachTitle => 'Тіркеме';

  @override
  String get chatAttachmentCancel => 'Бас тарту';

  @override
  String get chatAttachmentVideoTooLong =>
      'Видео тым ұзақ. 5 минутқа дейінгі бейнені пайдаланыңыз.';

  @override
  String get chatComposerCameraButtonLabel => 'Камера';

  @override
  String get chatComposerAttachButtonLabel => 'Файл тіркеу';

  @override
  String get chatComposerEmojiButtonLabel => 'Эмодзи мен стикерлер';

  @override
  String get chatComposerEmojiTab => 'Эмодзи';

  @override
  String get chatComposerStickerTab => 'Стикерлер';

  @override
  String get chatStickerMessage => 'Стикер';

  @override
  String get chatStickerCreateAction => 'Жасау';

  @override
  String get chatStickerCreated => 'Стикер қосылды';

  @override
  String get chatStickerCreateFailed =>
      'Стикер жасау мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatStickerSendFailed =>
      'Стикерді жіберу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatStickerLoadFailed => 'Стикерлеріңізді жүктеу мүмкін болмады.';

  @override
  String get chatComposerPaste => 'Қою';

  @override
  String get chatComposerPasteImage => 'Суретті қою';

  @override
  String get chatClipboardEmpty => 'Қоюға болатын дерек жоқ';

  @override
  String get chatPasteImagePreviewTitle => 'Қойылған суретті жіберу';

  @override
  String get chatPasteSendImage => 'Сурет жіберу';

  @override
  String get chatPasteSendSticker => 'Стикер ретінде қосу';

  @override
  String get stickersTabRecent => 'Жуырдағы';

  @override
  String get stickersSearchHint => 'Стикерлерді іздеу';

  @override
  String get stickersEmptyRecent => 'Жуырдағы стикерлер әлі жоқ';

  @override
  String get stickersEmptySearch => 'Стикерлер табылмады';

  @override
  String get stickersLoadFailed => 'Стикерлерді жүктеу мүмкін болмады';

  @override
  String get stickersRetry => 'Қайталау';

  @override
  String get stickersOpenPicker => 'Стикерлерді ашу';

  @override
  String get chatStickerUnsupported =>
      'Стикерлер үшін JPG, PNG немесе WebP кескінін пайдаланыңыз.';

  @override
  String get chatStickerTooLarge =>
      'Стикер кескіні тым үлкен. 5 МБ-қа дейінгі файлды пайдаланыңыз.';

  @override
  String get chatCameraPhotoMode => 'Фото';

  @override
  String get chatCameraVideoMode => 'Видео';

  @override
  String get chatCameraRecording => 'REC';

  @override
  String get chatCameraPermissionDenied =>
      'Чатта медиа түсіру үшін камера мен микрофонға рұқсат қажет.';

  @override
  String get chatCameraUnavailable => 'Бұл құрылғыда камера қолжетімді емес.';

  @override
  String get chatCameraCaptureFailed =>
      'Медиа түсіру мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatCameraFlipButtonLabel => 'Камераны ауыстыру';

  @override
  String get chatCameraFlashOffButtonLabel => 'Жарқыл өшірулі';

  @override
  String get chatCameraFlashAutoButtonLabel => 'Автоматты жарқыл';

  @override
  String get chatCameraFlashOnButtonLabel => 'Жарқыл қосулы';

  @override
  String get chatCameraCloseButtonLabel => 'Камераны жабу';

  @override
  String get chatCameraCapturePhotoButtonLabel => 'Фото түсіру';

  @override
  String get chatCameraRecordVideoButtonLabel => 'Видео жазу';

  @override
  String get chatCameraStopRecordingButtonLabel => 'Жазуды тоқтату';

  @override
  String get chatCameraReviewCancelButtonLabel => 'Бас тарту';

  @override
  String get chatCameraReviewSendButtonLabel => 'Жіберу';

  @override
  String get chatCameraReviewPlayButtonLabel => 'Видеоны ойнату';

  @override
  String get chatCameraReviewPauseButtonLabel => 'Видеоны кідірту';

  @override
  String get chatCameraReviewTrimLabel => 'Қию';

  @override
  String get chatCameraReviewProcessing => 'Өңделуде...';

  @override
  String get chatCameraTrimFailed =>
      'Бұл видеоны қию мүмкін болмады. Басқа аралықты таңдаңыз немесе түпнұсқасын жіберіңіз.';

  @override
  String get chatAttachmentUploading => 'Тіркеме жүктелуде...';

  @override
  String get chatAttachmentDownloading => 'Жүктеп алынуда...';

  @override
  String get chatAttachmentDownloaded =>
      'Файл жүктелді. Ашу үшін қайта басыңыз.';

  @override
  String get chatAttachmentDownloadedStatus => 'Жүктелді';

  @override
  String get chatAttachmentNotDownloadedStatus => 'Жүктеу үшін басыңыз';

  @override
  String get chatAttachmentDownloadFailed =>
      'Файлды жүктеу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatAttachmentOpenFailed =>
      'Бұл файлды құрылғыда ашу мүмкін болмады.';

  @override
  String get chatAttachmentUploadFailed =>
      'Тіркемені жүктеу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatAttachmentUnsupported =>
      'Бұл файл түрі чат тіркемелері үшін қолдау таппайды.';

  @override
  String get chatAttachmentTooLarge =>
      'Тіркеме тым үлкен. 25 МБ-қа дейінгі файлды пайдаланыңыз.';

  @override
  String get chatComposerHint => 'Хабар...';

  @override
  String get chatComposerClosedHint => 'Чат жабылды';

  @override
  String get chatActivityChatClosed => 'Бұл чат енді тек оқуға қолжетімді.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'Оқиға аяқталды. Бұл чатқа енді хабар жіберу мүмкін емес.';

  @override
  String get chatVoiceMessage => 'Дауыстық хабар';

  @override
  String get chatVoiceRecording => 'Дауыстық хабар жазылуда';

  @override
  String get chatVoiceRecordingLocked => 'Жазу бекітілді';

  @override
  String get chatVoicePreparingPreview => 'Алдын ала тыңдау дайындалуда...';

  @override
  String get chatVoicePreview => 'Алдын ала тыңдау';

  @override
  String get chatVoiceSlideUpToLock => 'Жазуды бекіту үшін жоғары сырғытыңыз';

  @override
  String get chatVoiceRecordPermissionDenied =>
      'Дауыстық хабар жазу үшін микрофонға рұқсат қажет.';

  @override
  String get chatVoiceRecordFailed =>
      'Дауыстық хабарды жазу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatVoicePlaybackFailed =>
      'Бұл дауыстық хабарды ойнату мүмкін болмады.';

  @override
  String get chatVoiceTooShort => 'Дауыстық хабар тым қысқа.';

  @override
  String get chatReactionSheetTitle => 'Реакция';

  @override
  String get chatReactionFailed =>
      'Реакцияны жаңарту мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatCopyAction => 'Көшіру';

  @override
  String get chatForwardAction => 'Жіберу';

  @override
  String get chatMessageCopied => 'Хабар мәтіні көшірілді';

  @override
  String get chatForwardSheetTitle => 'Қай чатқа жіберу';

  @override
  String get chatForwardFailed =>
      'Хабарды жіберу мүмкін болмады. Қайта көріңіз.';

  @override
  String get chatForwardSuccess => 'Хабар жіберілді';

  @override
  String get chatNoForwardTargets => 'Қолжетімді чаттар жоқ';

  @override
  String get chatForwardedLabel => 'Жіберілген';

  @override
  String get chatStoryReplyLabel => 'Хикаяға жауап';

  @override
  String get chatStoryReplyUnavailable => 'Хикая енді қолжетімсіз';

  @override
  String chatForwardedFrom(Object name) {
    return '$name жіберген хабар';
  }

  @override
  String chatForwardCount(Object count) {
    return '$count рет жіберілді';
  }

  @override
  String get chatReactionsByTitle => 'Реакциялар';

  @override
  String chatReactionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count реакция',
      one: '1 реакция',
    );
    return '$_temp0';
  }

  @override
  String get chatReadByTitle => 'Оқығандар';

  @override
  String chatReadByCount(Object count) {
    return 'Оқығандар: $count';
  }

  @override
  String get chatReadAtSeparator => 'сағ.';

  @override
  String get chatNoStatusDetails => 'Статус мәліметтері әзірге жоқ';

  @override
  String get chatLoadFailed => 'Чатты жүктеу мүмкін болмады';

  @override
  String get chatParticipantsHostSection => 'ҰЙЫМДАСТЫРУШЫ';

  @override
  String get chatParticipantsJoinedSection => 'ҚАТЫСУШЫЛАР';

  @override
  String get chatParticipantHostStatus => 'ұйымдастырушы';

  @override
  String get chatParticipantYouStatus => 'сіз';

  @override
  String get chatParticipantJoinedStatus => 'қатысушы';

  @override
  String get chatParticipantsEmpty => 'Басқа қатысушылар әзірге жоқ';

  @override
  String get chatSharedMediaTab => 'Медиа';

  @override
  String get chatSharedLinksTab => 'Сілтемелер';

  @override
  String get chatSharedFilesTab => 'Файлдар';

  @override
  String get chatSharedVoiceTab => 'Аудиохабарлар';

  @override
  String get chatSharedNoMediaTitle => 'Медиа әзірге жоқ';

  @override
  String get chatSharedNoMediaSubtitle =>
      'Осы чаттағы фото мен видеолар осында шығады.';

  @override
  String get chatSharedNoLinksTitle => 'Сілтемелер әзірге жоқ';

  @override
  String get chatSharedNoLinksSubtitle =>
      'Сілтемесі бар хабарлар осында жиналады.';

  @override
  String get chatSharedNoFilesTitle => 'Файлдар әзірге жоқ';

  @override
  String get chatSharedNoFilesSubtitle =>
      'Осы чаттағы құжаттар мен архивтер осында шығады.';

  @override
  String get chatSharedNoVoiceTitle => 'Дауыстық хабарлар әзірге жоқ';

  @override
  String get chatSharedNoVoiceSubtitle =>
      'Осы чаттағы дауыстық хабарлар осында шығады.';

  @override
  String chatSharedFileFallback(Object id) {
    return 'Файл $id';
  }

  @override
  String get chatSharedUnknownFile => 'Белгісіз файл';

  @override
  String get chatSharedGoToMessageAction => 'Хабарға өту';

  @override
  String get chatExternalLinkTitle => 'Сыртқы сілтемені ашу керек пе?';

  @override
  String chatExternalLinkMessage(Object url) {
    return 'Бұл сілтеме бөгде ресурсқа апарады:\n$url';
  }

  @override
  String get chatExternalLinkOpenAction => 'Ашу';

  @override
  String get chatExternalLinkOpenFailed => 'Бұл сілтемені ашу мүмкін болмады.';

  @override
  String get chatSharedLoadFailed => 'Контентті жүктеу мүмкін болмады';

  @override
  String get chatSharedLoadFailedSubtitle =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get chatSharedPartialLoadWarning =>
      'Кейбір ескі ортақ элементтерді жүктеу мүмкін болмады.';

  @override
  String get guideCalendarTitle => 'Гид күнтізбесі';

  @override
  String get guideCalendarAddSlot => 'Слот';

  @override
  String get guideCalendarEditSlot => 'Слотты өңдеу';

  @override
  String get guideCalendarEmptyDay => 'Бұл күнге слоттар жоқ';

  @override
  String get guideCalendarAvailable => 'Бос';

  @override
  String get guideCalendarBooked => 'Бронь бар';

  @override
  String get guideCalendarClosed => 'Жабық';

  @override
  String get guideCalendarCancelled => 'Бас тартылды';

  @override
  String get guideCalendarCompleted => 'Аяқталды';

  @override
  String get guideCalendarViewSlot => 'Слот мәліметтері';

  @override
  String get guideCalendarReadonlyCompletedSlot =>
      'Бұл слот аяқталды. Ол тарих үшін күнтізбеде қалады және тек қарауға қолжетімді.';

  @override
  String guideCalendarCancelReason(Object reason) {
    return 'Себебі: $reason';
  }

  @override
  String get guideCalendarAutoCancelNoBookings =>
      'басталуына 2 сағат қалғанға дейін ешкім бронь жасамады';

  @override
  String get guideCalendarRepeatWeekly => 'Апта сайын қайталау';

  @override
  String get guideCalendarConflictTitle =>
      'Бұл уақыт басқа экскурсиямен қабаттасады';

  @override
  String get guideCalendarSuggestNextTime => 'Келесі бос уақытты таңдаңыз';

  @override
  String get guideCalendarDeleteSlot => 'Жою';

  @override
  String get guideCalendarCancelSlot => 'Бас тарту';

  @override
  String get guideCalendarCloseSlot => 'Жабу';

  @override
  String get guideCalendarOfferLabel => 'Жарияланған ұсыныс';

  @override
  String get guideCalendarNoPublishedOffers =>
      'Кестеге қосу үшін алдымен экскурсия ұсынысын жариялаңыз.';

  @override
  String get guideCalendarOfferRequired => 'Экскурсия ұсынысын таңдаңыз';

  @override
  String get guideCalendarCurrentOfferFallback => 'Ағымдағы ұсыныс';

  @override
  String guideCalendarOfferDuration(Object minutes) {
    return '$minutes мин';
  }

  @override
  String guideCalendarOfferCapacity(Object count) {
    return '$count орын';
  }

  @override
  String get guideCalendarDateLabel => 'Күні';

  @override
  String get guideCalendarDateHint => 'кк.аа.жжжж';

  @override
  String get guideCalendarInvalidDate =>
      'Күнді кк.аа.жжжж форматында енгізіңіз';

  @override
  String get guideCalendarTimeLabel => 'Уақыты';

  @override
  String get guideCalendarTimeHint => 'сс:мм';

  @override
  String get guideCalendarInvalidTime => 'Уақытты сс:мм форматында енгізіңіз';

  @override
  String get guideCalendarCapacityLabel => 'Орын';

  @override
  String guideCalendarCapacityMax(Object count) {
    return 'Бұл ұсыныс үшін максимум: $count';
  }

  @override
  String guideCalendarCapacityTooHigh(Object count) {
    return 'Бұл ұсыныста $count орынға дейін ғана қолжетімді';
  }

  @override
  String get guideCalendarSlotLeadTimeTooSoon =>
      'Басталуына кемінде 3 сағат қалатындай күн мен уақытты таңдаңыз.';

  @override
  String get guideCalendarSaveSlot => 'Сақтау';

  @override
  String get notificationsTitle => 'Хабарландырулар';

  @override
  String get notificationsSubtitle =>
      'Сапарлар, белсенділіктер және экскурсиялар бойынша маңызды жаңартулар';

  @override
  String get notificationsCategoriesEmptyTitle => 'Әзірге тыныш';

  @override
  String get notificationsCategoriesEmptySubtitle =>
      'Санаттар бойынша соңғы жаңартулар осы жерде пайда болады.';

  @override
  String get notificationsLoadFailedTitle =>
      'Хабарландыруларды жүктеу мүмкін болмады';

  @override
  String get notificationsLoadFailedSubtitle =>
      'Қосылымды тексеріп, қайта көріңіз.';

  @override
  String get notificationsCategoryEmptyTitle =>
      'Бұл санатта әзірге хабарландыру жоқ';

  @override
  String get notificationsCategoryEmptySubtitle =>
      'Жаңа оқиғалар осы жерде автоматты түрде пайда болады.';

  @override
  String get notificationsReadAll => 'Барлығын оқылған деп белгілеу';

  @override
  String get notificationsReadAllDone =>
      'Осы санаттағы барлық хабарландыру оқылды';

  @override
  String notificationsUnreadCount(Object count) {
    return '$count жаңа';
  }

  @override
  String get notificationsCategoryActivity => 'Белсенділіктер';

  @override
  String get notificationsCategoryExcursion => 'Экскурсиялар';

  @override
  String get notificationsCategoryBooking => 'Брондаулар';

  @override
  String get notificationsCategoryChat => 'Хабарламалар';

  @override
  String get notificationsCategoryContent => 'Посттар мен хикаялар';

  @override
  String get notificationsCategorySystem => 'Жүйе';

  @override
  String get notificationsCategoryGeneral => 'Жалпы';

  @override
  String notificationsCategoryFallback(Object category) {
    return '$category санаты';
  }

  @override
  String get notificationsJustNow => 'жаңа ғана';

  @override
  String notificationsMinutesAgo(Object minutes) {
    return '$minutes мин бұрын';
  }

  @override
  String notificationsHoursAgo(Object hours) {
    return '$hours сағ бұрын';
  }

  @override
  String notificationsDaysAgo(Object days) {
    return '$days күн бұрын';
  }
}
