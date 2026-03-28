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
      'Face ID немесе биометрия арқылы кіруді растаңыз. 3 сәтсіз әрекеттен кейін PIN-код сұралады.';

  @override
  String get appLockUsePinButton => 'PIN-код енгізу';

  @override
  String get appLockUnlockButton => 'Құлыпты ашу';

  @override
  String get appLockRetryBiometricButton => 'Бетті сканерлеу';

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
  String get activityStatusReviewRequired => 'Тексеруде';

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
  String get activityStatusCancelled => 'Бас тартылды';

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
  String get homeSearchHint => 'Бағыттарды, тұрғын орынды немесе көлікті іздеу';

  @override
  String get homeTopDestinations => 'Үздік бағыттар';

  @override
  String get homeSeeAll => 'Барлығын көру';

  @override
  String get homeRecommendedBlogs => 'Ұсынылатын блогтар';

  @override
  String get homeEditorialBadge => 'Редакция';

  @override
  String get homeStoryTitle => 'Орталық Азияның жасырын інжу-маржандары';

  @override
  String get homeStoryDescription =>
      'Алматы маңындағы құпия соқпақтар мен мәдени бұрыштарды ашыңыз.';

  @override
  String get homeReadStory => 'Оқу';

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
  String get createJoinModeSection => 'ҚОСЫЛУ РЕЖИМІ';

  @override
  String get createJoinModeAuto => 'Автоматты мақұлдау';

  @override
  String get createJoinModeManual => 'Қолмен мақұлдау';

  @override
  String get createJoinApprovalTitle => 'Қатысуды мақұлдау';

  @override
  String get createJoinModeAutomaticShort => 'Автоматты';

  @override
  String get createJoinModeManualShort => 'Қолмен';

  @override
  String get createJoinModePickerTitle => 'Мақұлдау режимін таңдаңыз';

  @override
  String get createJoinModeApply => 'Қолдану';

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
      'Дұрыс максималды санды енгізіңіз';

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
  String get createPriceDeposit => 'Депозит';

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
      'Қатысушылар жазылғаннан кейін бағаны өзгерту мүмкін емес';

  @override
  String get myActivitiesTitle => 'Менің белсенділіктерім';

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
  String get myActivitiesRestrictedButton => 'Өңдеу шектелген';

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
  String get activitiesFilterCategory => 'Санат';

  @override
  String get activitiesFilterDate => 'Күні';

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
  String get qrScannerNotRegistered => 'Сіз бұл белсенділікке жазылмағансыз';

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
}
