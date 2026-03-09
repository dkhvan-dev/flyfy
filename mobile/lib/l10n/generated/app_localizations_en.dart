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

  @override
  String codeSentTo(Object phone) {
    return 'Code sent to $phone';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNotAvailable => 'Profile is not available';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileLocale => 'Language';

  @override
  String get profileTimezone => 'Time zone';

  @override
  String get profileCountry => 'Country';

  @override
  String get profileCurrency => 'Currency';

  @override
  String get profileVisibility => 'Profile visibility';

  @override
  String get profilePublic => 'Public';

  @override
  String get profilePrivate => 'Private';

  @override
  String get editProfileButton => 'Edit profile';

  @override
  String get becomeGuideButton => 'Become a guide';

  @override
  String get logoutButton => 'Log out';

  @override
  String welcomeUser(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get openProfileHint => 'Tap to open profile';

  @override
  String get userFallbackName => 'friend';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get loginWithBiometrics => 'Sign in with biometrics';

  @override
  String get biometricLoginFailed => 'Failed to sign in with biometrics';

  @override
  String get profileIncompleteTitle => 'Profile is incomplete';

  @override
  String get profileIncompleteDescription =>
      'Fill in your first and last name to unlock all FlyFy features';

  @override
  String get fillNowButton => 'Fill now';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get saveProfileButton => 'Save';

  @override
  String get profileSaveFailed => 'Failed to save profile';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get bioLabel => 'About';

  @override
  String get firstNameRequired => 'Enter first name';

  @override
  String get lastNameRequired => 'Enter last name';

  @override
  String get profileRequiredTitle => 'Complete your profile';

  @override
  String get profileRequiredDescription =>
      'To continue, enter your first and last name in your profile. This helps reduce fake accounts and increases trust between users.';

  @override
  String get laterButton => 'Later';
}
