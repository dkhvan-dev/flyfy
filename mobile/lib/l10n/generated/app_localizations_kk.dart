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
}
