// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlyFy';

  @override
  String get welcomeToFlyFy => 'Welcome to FlyFy';

  @override
  String get enterPhoneToContinue => 'Enter your phone number to continue';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get sendCode => 'Send Code';

  @override
  String get enterAuthCode => 'Enter Auth Code';

  @override
  String get verifyAndLogin => 'Verify & Login';

  @override
  String get or => 'OR';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get googleLoginFailed => 'Failed to sign in with Google.';

  @override
  String get appleLoginFailed => 'Failed to sign in with Apple ID.';

  @override
  String get otpSendFailed => 'Failed to send code.';

  @override
  String get otpInvalid => 'Invalid verification code.';

  @override
  String get homeWelcomeBack => 'Welcome back!';

  @override
  String get homeTravelQuestion => 'Where do you want to travel next?';

  @override
  String get homeExploreServices => 'Explore Services';

  @override
  String get serviceTours => 'Tours';

  @override
  String get serviceGuides => 'Guides';

  @override
  String get serviceHotels => 'Hotels';

  @override
  String get serviceTransport => 'Transport';

  @override
  String get logoutDialogTitle => 'Sign out?';

  @override
  String get logoutDialogMessage =>
      'Are you sure you want to sign out? You may need to authenticate again next time.';

  @override
  String get logoutConfirmButton => 'Sign out';

  @override
  String get cancel => 'Cancel';

  @override
  String get loginButton => 'Log in';
}
