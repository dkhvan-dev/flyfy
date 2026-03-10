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
  String get welcomeToFlyFy => 'FlyFy қосымшасына қош келдіңіз';

  @override
  String get enterPhoneToContinue =>
      'Жалғастыру үшін телефон нөмірін енгізіңіз';

  @override
  String get phoneNumber => 'Телефон нөмірі';

  @override
  String get sendCode => 'Код жіберу';

  @override
  String get enterAuthCode => 'Кодты енгізіңіз';

  @override
  String get verifyAndLogin => 'Растап кіру';

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
  String get activitiesEntryTitle => 'Белсенділіктер';

  @override
  String get activitiesEntrySubtitle =>
      'Қосылуға болатын офлайн және онлайн іс-шараларды табыңыз';

  @override
  String get comingSoon => 'Жақында пайда болады';
}
