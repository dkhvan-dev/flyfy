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
  String get activityJoinSuccess => 'Сіз белсенділікке жазылдыңыз';

  @override
  String get activityLeaveSuccess => 'Сіз белсенділіктен шықтыңыз';

  @override
  String get activityJoinFailed => 'Белсенділікке жазылу мүмкін болмады';

  @override
  String get activityLeaveFailed => 'Белсенділіктен шығу мүмкін болмады';

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
  String get homeEditorialBadge => 'Редакция';

  @override
  String get homeStoryTitle => 'Орталық Азияның жасырын інжу-маржандары';

  @override
  String get homeStoryDescription =>
      'Алматы маңындағы құпия соқпақтар мен мәдени бұрыштарды ашыңыз.';

  @override
  String get homeReadStory => 'Оқиғаны оқу';

  @override
  String get homeFeaturedStays => 'Ұсынылған тұру орындары';

  @override
  String get homeCarRentals => 'Көлік жалдау';

  @override
  String get homeRecommendedActivities => 'Ұсынылатын белсенділіктер';

  @override
  String get homeFilterButton => 'Сүзгі';

  @override
  String get homeNavHome => 'Басты';

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
  String get createCoverUploadHint => 'Кемінде 1600x900px, ең көбі 5MB';

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
  String get activityViewDetails => 'Толығырақ';

  @override
  String get activityJoinSession => 'Қосылу';

  @override
  String get activityGetLink => 'Сілтемені алу';
}
