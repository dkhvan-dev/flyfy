// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'FlyFy';

  @override
  String get welcomeTitle => 'Сіздің жеке әлеміңіз.';

  @override
  String get welcomeDescription =>
      'Заманауи зерттеушіге арналған мінсіз саяхат суперқосымшасының барлық мүмкіндіктерін бағалаңыз.';

  @override
  String get welcomeToFlyFy => 'FlyFy қосымшасына қош келдіңіз';

  @override
  String get authByPhone => 'Телефон нөмірі арқылы кіру';

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
  String get enterAuthCode =>
      'Жаңа ғана мына нөмірге жіберген 6 таңбалы кодты енгізіңіз:\n';

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
  String get serviceTours => 'Турлар';

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
  String get profileNotAvailable => 'Профиль қолжетімсіз';

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Тіл';

  @override
  String get profileTimezone => 'Уақыт белдеуі';

  @override
  String get profileCountry => 'Ел';

  @override
  String get profileCurrency => 'Валюта';

  @override
  String get profileVisibility => 'Профиль көрінуі';

  @override
  String get profilePublic => 'Ашық';

  @override
  String get profilePrivate => 'Жабық';

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
  String get guideVerificationOfficialTourGuideLicense =>
      'Ресми тур гиді лицензиясы';

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
      'Сіз белсенділіктер мен турларды бірнеше тілде өткізе аласыз.';

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
      'Егер ақпарат шындыққа сәйкес келмесе немесе құжаттар талапқа сай болмаса, FlyFy өтінімді кері қайтара алатынын түсінемін.';

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
  String get loginWithBiometrics => 'Биометрия арқылы кіру';

  @override
  String get biometricLoginFailed => 'Биометрия арқылы кіру сәтсіз аяқталды';

  @override
  String get appLockLoading => 'Қорғалған сессия тексерілуде';

  @override
  String get appLockSetupTitle => 'PIN-код жасаңыз';

  @override
  String get appLockSetupDescription =>
      'Қосымшаны қайта ашқаннан кейін сессия аяқталса, жылдам кіру үшін осы PIN-код қажет болады.';

  @override
  String get appLockSetupConfirmDescription =>
      'Растау және сақтау үшін PIN-кодты қайта енгізіңіз.';

  @override
  String get appLockSetupCreateButton => 'Жалғастыру';

  @override
  String get appLockSetupConfirmButton => 'PIN-кодты сақтау';

  @override
  String get appLockSetupMismatch => 'PIN-кодтар сәйкес келмейді';

  @override
  String get appLockPinInvalid => '4 таңбалы PIN-код енгізіңіз';

  @override
  String get appLockPinIncorrect => 'PIN-код қате';

  @override
  String get appLockUnlockTitle => 'Кіруді растаңыз';

  @override
  String get appLockPinUnlockDescription =>
      'Қосымшада жалғастыру үшін PIN-кодты енгізіңіз.';

  @override
  String get appLockBiometricUnlockDescription =>
      'Face ID, саусақ ізі немесе басқа қолжетімді биометрия арқылы кіруді растаңыз. 3 сәтсіз әрекеттен кейін PIN-код сұралады.';

  @override
  String get appLockUsePinButton => 'PIN-код енгізу';

  @override
  String get appLockUnlockButton => 'Құлыпты ашу';

  @override
  String get appLockRetryBiometricButton => 'Биометрия арқылы кіру';

  @override
  String get appLockBiometricEnableTitle =>
      'Биометрия арқылы кіруді қосасыз ба?';

  @override
  String get appLockBiometricEnableDescription =>
      'Келесі жолы қолжетімділікті Face ID немесе саусақ ізі арқылы жылдам растауға болады.';

  @override
  String get appLockBiometricEnableButton => 'Қосу';

  @override
  String get appLockBiometricSkipButton => 'Әзірге емес';

  @override
  String get appLockBiometricFailed =>
      'Биометрия расталмады. Қайта көріңіз немесе PIN-кодқа ауысыңыз.';

  @override
  String get appLockBiometricFallback =>
      'Биометрия арқылы кіру уақытша қолжетімсіз. PIN-кодты енгізіңіз.';

  @override
  String get profileIncompleteTitle => 'Профиль толық толтырылмаған';

  @override
  String get profileIncompleteDescription =>
      'FlyFy мүмкіндіктерін толық пайдалану үшін атыңыз бен тегіңізді толтырыңыз';

  @override
  String get fillNowButton => 'Толтыру';

  @override
  String get appLanguageTitle => 'Қолданба тілі';

  @override
  String get saveProfileButton => 'Сақтау';

  @override
  String get profileSaveFailed => 'Профильді сақтау сәтсіз аяқталды';

  @override
  String get profileDisplayNameTaken => 'Бұл көрсетілетін ат бос емес';

  @override
  String get firstNameLabel => 'Аты';

  @override
  String get lastNameLabel => 'Тегі';

  @override
  String get displayNameLabel => 'Көрсетілетін ат';

  @override
  String get bioLabel => 'Өзі туралы';

  @override
  String get firstNameRequired => 'Атыңызды енгізіңіз';

  @override
  String get lastNameRequired => 'Тегіңізді енгізіңіз';

  @override
  String get profileRequiredTitle => 'Профильді толтырыңыз';

  @override
  String get profileRequiredDescription =>
      'Жалғастыру үшін профиліңізде атыңыз бен тегіңізді көрсетіңіз. Бұл жалған аккаунттарды азайтып, пайдаланушылар арасындағы сенімді арттырады.';

  @override
  String get myProfileTitle => 'Менің профилім';

  @override
  String get profileLinkCopied => 'Профиль сілтемесі көшірілді';

  @override
  String get profileVerifiedExplorer => 'РАСТАЛҒАН ГИД';

  @override
  String get profileGuideTitle => 'FlyFy гиді';

  @override
  String get profileEmptyBioPlaceholder =>
      'Қазір мұнда сипаттама жоқ. Профиль толтырылған кезде қысқаша ақпарат осы жерде көрсетіледі.';

  @override
  String get profileBecomeGuideTitle => 'Гид болыңыз';

  @override
  String get profileBecomeGuideSubtitle =>
      'Жақында осы жерден өтінім беріп, кәсіби гид профилін аша аласыз.';

  @override
  String get profileActivitiesStat => 'Белсенділіктер';

  @override
  String get profileHostedCompletedStat => 'Автор ретінде аяқталды';

  @override
  String get profileJoinedCompletedStat => 'Қатысушы ретінде аяқталды';

  @override
  String get profileReviewsStat => 'Пікірлер';

  @override
  String get profileBlogsStat => 'Блогтар';

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
      'PIN, биометрия және қорғалған жергілікті сессия.';

  @override
  String get profileHostedActivitiesTitle => 'Автор белсенділіктері';

  @override
  String get profileHostedActivitiesUnavailable =>
      'Backend автордың ашық витринасын бергенде, жарияланған белсенділіктер осы жерде көрсетіледі.';

  @override
  String get profileBlogsTitle => 'Соңғы блогтар';

  @override
  String get profileBlogsUnavailable =>
      'Ашық жазбалар мен саяхат тарихтары қолданбада әлі қолжетімді емес.';

  @override
  String get profileUnavailableTitle => 'Жақында';

  @override
  String get profileFollowAction => 'Қадағалау';

  @override
  String get profileFollowingAction => 'Жазылған';

  @override
  String get profileFollowUpdateFailed => 'Жазылу күйін жаңарту мүмкін болмады';

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
  String get profileSettingsSecuritySection => 'Қауіпсіздік';

  @override
  String get profileSettingsSecurityPinTitle => 'PIN-код және биометрия';

  @override
  String get profileSettingsSecurityPinSubtitle =>
      'Жергілікті кіру қорғанысын басқару үшін қауіпсіздік экранын ашыңыз.';

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
      'FlyFy белсенділіктер, қатысу және жаңа мүмкіндіктер туралы қалай хабарлайтынын басқарыңыз.';

  @override
  String get profileNotificationsActivitySection =>
      'Белсенділіктер және қатысу';

  @override
  String get profileNotificationsDiscoverySection => 'Ұсыныстар мен топтамалар';

  @override
  String get profileNotificationsPushTitle => 'Push-хабарламалар';

  @override
  String get profileNotificationsPushSubtitle =>
      'Белсенділіктер, статус өзгерістері және жаңа хабарламалар туралы жедел жаңартулар.';

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
  String get profileNotificationsMarketingTitle => 'Топтамалар мен ұсыныстар';

  @override
  String get profileNotificationsMarketingSubtitle =>
      'Саяхат идеялары, орындар топтамасы және арнайы FlyFy ұсыныстары.';

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
      'Мұнда жергілікті кіру тәсілдері мен болашақ аккаунт қорғау құралдары біріктірілген.';

  @override
  String get profileSecurityLocalAccessSection => 'Жергілікті қолжетімділік';

  @override
  String get profileSecurityAccountSection => 'Аккаунт қорғанысы';

  @override
  String get profileSecurityDataSection => 'Деректер және құпиялылық';

  @override
  String get profileSecurityPinTitle => 'Қосымша PIN-коды';

  @override
  String get profileSecurityPinEnabledSubtitle =>
      'PIN-код бапталған және қосымшаны жылдам ашу үшін қолданылады.';

  @override
  String get profileSecurityPinMissingSubtitle =>
      'PIN-код әлі бапталмаған. Келесі авторизациядан кейін қолданба оны жасауды ұсынады.';

  @override
  String get profileSecurityBiometricTitle => 'Биометрия арқылы ашу';

  @override
  String get profileSecurityBiometricSubtitle =>
      'Қосымшаны Face ID, саусақ ізі немесе қолжетімді биометрия арқылы ашуға рұқсат беріңіз.';

  @override
  String get profileSecurityBiometricNeedsPin =>
      'Алдымен қосымша PIN-коды бапталуы керек.';

  @override
  String get profileSecurityBiometricUnavailable =>
      'Бұл құрылғыда биометрия қолжетімсіз немесе бапталмаған.';

  @override
  String get profileSecurityProtectedSessionTitle => 'Қорғалған сессия';

  @override
  String get profileSecurityProtectedSessionSubtitle =>
      'Жергілікті сессия сақталған. Қайта іске қосқаннан кейін қолданбаны тез ашуға болады.';

  @override
  String get profileSecurityNoStoredSessionSubtitle =>
      'Белсенді сақталған сессия табылмады. Қорғаныс келесі кіргеннен кейін автоматты түрде қосылады.';

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
  String get activityDetailsHostFallbackName => 'FlyFy ұйымдастырушысы';

  @override
  String get activityPaymentScreenTitle => 'FLYFY CHECKOUT';

  @override
  String get activityPaymentSummaryTitle => 'Белсенділік туралы мәлімет';

  @override
  String get activityPaymentBreakdownTitle => 'Сома құрамы';

  @override
  String get activityPaymentMethodTitle => 'Төлем тәсілі';

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
  String get activityPaymentCardHolderFallback => 'FlyFy қатысушысы';

  @override
  String get activityPaymentApplePayLabel => 'Apple Pay';

  @override
  String get activityPaymentGooglePayLabel => 'Google Pay';

  @override
  String activityPaymentConfirmButton(Object amount) {
    return '$amount сомасын растау және төлеу';
  }

  @override
  String get activityPaymentSecureNote =>
      '256-биттік SSL шифрлауымен қорғалған төлем';

  @override
  String get activityPaymentPayButton => 'Төлеу';

  @override
  String get activityPaymentSuccess => 'Төлем сәтті деп белгіленді';

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
  String get participantStatusAttended => 'Қатысты';

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
  String get homeTitle => 'FlyFy';

  @override
  String get homeSubtitle =>
      'Саяхаттап, белсенділіктерді тауып, жаңа әсерлер ашыңыз';

  @override
  String get servicesSectionTitle => 'Сервистер';

  @override
  String get homeToursTitle => 'Турлар';

  @override
  String get homeToursSubtitle => 'Қызықты бағыттар мен сапарларды таңдаңыз';

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
  String homeExploringLocation(Object location) {
    return '$location';
  }

  @override
  String get homeSearchHint => 'Белсенділіктерді, орындарды, турларды іздеу...';

  @override
  String get homeTopDestinations => 'Үздік бағыттар';

  @override
  String get homeSeeAll => 'Барлығын көру';

  @override
  String get homeTopStories => 'Үздік хикаялар';

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
  String get homeServiceAttractions => 'Орындар';

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
  String get homePromoMountainTitle => 'Тау турлары';

  @override
  String get homePromoMountainDescription =>
      'Жергілікті сарапшылармен көркем маршруттар...';

  @override
  String get homePromoExplore => 'Ашу';

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
  String get homeNavQr => 'QR';

  @override
  String get homeNavMap => 'Карта';

  @override
  String get homeNavChats => 'Чаттар';

  @override
  String get homeNavMy => 'Менің';

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
  String mapPlacesCount(int count) {
    return 'Табылған орындар: $count';
  }

  @override
  String get attractionsTitle => 'Көрікті жерлер';

  @override
  String get attractionsSearchHint => 'Қайда барамыз?';

  @override
  String get attractionsLoadFailed => 'Көрікті жерлерді жүктеу сәтсіз аяқталды';

  @override
  String get attractionsRecommendedTitle => 'Ұсынылады';

  @override
  String get attractionsCuratedListEyebrow => 'Таңдаулылар';

  @override
  String get attractionsSeeAll => 'Барлығын көру';

  @override
  String get attractionsNoResults => 'Көрікті жерлер табылмады';

  @override
  String get attractionsFiltersTitle => 'Сүзгілер';

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
  String get attractionFilterCategoryHistory => 'Тарих';

  @override
  String get attractionFilterCategoryAdventure => 'Шытырман';

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
  String get attractionFlyFyTipTitle => 'FlyFy кеңесі';

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
  String get attractionFindTours => 'Турлар табу';

  @override
  String get attractionMapLink => 'Картадан көру';

  @override
  String get attractionVerifiedNomad => 'Тексерілген саяхатшы';

  @override
  String get attractionReviewsTitle => 'Пікірлер';

  @override
  String get attractionTravelerFallback => 'Саяхатшы';

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
  String get createVisibilityPublicDescription => 'FlyFy-дегі баршаға көрінеді';

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
  String get createOfflineSection => 'ӨТКІЗУ ОРНЫ';

  @override
  String get createLocationPreviewHint =>
      'Қатысушылар қай жерде кездесетінін түсінуі үшін қала немесе мекенжай қосыңыз';

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
      'Жарияланғаннан кейін орналасқан жерді өзгерту мүмкін емес';

  @override
  String get editPriceRestrictionHint =>
      'Басқа қатысушылар жазылғаннан кейін бағаны өзгерту мүмкін емес';

  @override
  String get myActivitiesTitle => 'Менің белсенділіктерім';

  @override
  String get myStoriesTitle => 'Менің тарихтарым';

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
  String get myActivitiesOpenButton => 'Белсенділікті ашу';

  @override
  String get myActivitiesRetryButton => 'Қайталау';

  @override
  String get myActivitiesPriceNoteFree => 'тегін';

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
  String get activitiesDiscoverTitle => 'Белсенділіктерді табу';

  @override
  String get activitiesFilteredEmptyTitle =>
      'Бұл сүзгілерге сай белсенділік табылмады';

  @override
  String get activitiesFilteredEmptySubtitle =>
      'Санатты, күн аралығын немесе баға шегін кеңейтіп көріңіз';

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
  String get qrScannerInvalidCode => 'Бұл FlyFy белсенділігінің QR коды емес';

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
  String get storiesDiscoverTitle => 'Хикаялар';

  @override
  String get storiesNavLabel => 'Хикаялар';

  @override
  String get storiesActivitiesNavLabel => 'Белсенділіктер';

  @override
  String get storySearchHint => 'Хикаяларды, авторларды немесе орындарды іздеу';

  @override
  String get storyFilterCategory => 'Санат';

  @override
  String get storyFilterCountry => 'Ел';

  @override
  String get storyFilterAll => 'Барлығы';

  @override
  String storiesShowResults(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хикаяны',
      one: '1 хикаяны',
      zero: '0 хикаяны',
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
  String get storyCreateCta => 'Хикаямен бөлісу';

  @override
  String get storyCreateFirst => 'Алғашқы хикаяны жасау';

  @override
  String get storyEmptyTitle => 'Әзірге хикая жоқ';

  @override
  String get storyEmptySubtitle =>
      'Travel-note, жергілікті гид немесе визуалды эссе жариялаған алғашқы адам болыңыз.';

  @override
  String get storyLoadFailed => 'Хикаяларды жүктеу мүмкін болмады';

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
  String get storyDetailsTitle => 'Хикая туралы';

  @override
  String get storyLinkCopied => 'Хикая сілтемесі көшірілді';

  @override
  String get storyShareFailed =>
      'Сілтемені бөлісу терезесін ашу мүмкін болмады. Қайта көріңіз.';

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
  String get storyRelatedTitle => 'Ұқсас хикаялар';

  @override
  String get storyRelatedEmpty => 'Әзірге ұқсас хикая жоқ';

  @override
  String get storyViewAll => 'Барлығын көру';

  @override
  String get storyEditAction => 'Өңдеу';

  @override
  String get storyDeleteTitle => 'Хикаяны өшіру керек пе?';

  @override
  String get storyDeleteMessage => 'Хикая ашық лентадан алынып тасталады.';

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
  String get chatListTitle => 'Чаттар';

  @override
  String get chatListLoadFailed => 'Чаттарды жүктеу мүмкін болмады';

  @override
  String get chatListEmpty => 'Әзірге диалог жоқ';

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
  String get chatCameraCloseButtonLabel => 'Камераны жабу';

  @override
  String get chatCameraCapturePhotoButtonLabel => 'Фото түсіру';

  @override
  String get chatCameraRecordVideoButtonLabel => 'Видео жазу';

  @override
  String get chatCameraStopRecordingButtonLabel => 'Жазуды тоқтату';

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
  String get chatActivityChatClosed =>
      'Бұл белсенділік чаты енді тек оқуға қолжетімді.';

  @override
  String get chatActivityChatClosedHistoryNotice =>
      'Белсенділік аяқталды. Бұл чатқа енді хабар жіберу мүмкін емес.';

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
  String chatSharedFileFallback(Object id) {
    return 'Файл $id';
  }

  @override
  String get chatSharedUnknownFile => 'Белгісіз файл';

  @override
  String get chatSharedLoadFailed => 'Контентті жүктеу мүмкін болмады';

  @override
  String get chatSharedLoadFailedSubtitle =>
      'Байланысты тексеріп, қайта көріңіз.';

  @override
  String get chatSharedPartialLoadWarning =>
      'Кейбір ескі ортақ элементтерді жүктеу мүмкін болмады.';
}
