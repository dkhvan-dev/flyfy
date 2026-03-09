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
  String get welcomeToFlyFy => 'Добро пожаловать в FlyFy';

  @override
  String get enterPhoneToContinue => 'Введите номер телефона, чтобы продолжить';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get enterAuthCode => 'Введите код';

  @override
  String get verifyAndLogin => 'Подтвердить и войти';

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
}
